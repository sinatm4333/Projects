-- تحلیل و ایجاد توسط مهدی جهانی 09125632329

local input = teamyar.get_input()
local task_id = input["task_id"] or input["taskId"] or input["id"]

if task_id == nil or task_id == "" then
    teamyar.write_result(json.encode({
        ok = false,
        error = "شناسه اقدام (task_id) وارد نشده است"
    }))
    return
end

local COMMENT_TABLE_CANDIDATES = {
    "todo_task_comments",
    "todo_content",
    "todo_task_content",
    "todo_comment",
    "todo_task_comment",
    "todo_task_steps_comment"
}

-- تبدیل filetime به تاریخ-ساعت شمسی (خروجی رشته‌ای، بدون عدد علمی)
local function fmt_jalali_datetime(col)
    return [[
CASE
    WHEN ]] .. col .. [[ IS NULL OR ]] .. col .. [[ = 0 THEN NULL
    ELSE CONCAT(
        REPORT_FN_JDATE(]] .. col .. [[, '-'),
        ' ',
        DATE_FORMAT(FROM_UNIXTIME(]] .. col .. [[ / 10000000 - 11644473600), '%H:%i:%s')
    )
END]]
end

local function sql_ident(name)
    return "`" .. string.gsub(name, "`", "``") .. "`"
end

local function format_duration(filetime_diff)
    local diff = tonumber(filetime_diff)
    if diff == nil or diff <= 0 then
        return nil
    end

    local total_sec = math.floor(diff / 10000000)
    local days = math.floor(total_sec / 86400)
    local hours = math.floor((total_sec % 86400) / 3600)
    local mins = math.floor((total_sec % 3600) / 60)
    local secs = total_sec % 60

    local parts = {}
    if days > 0 then
        table.insert(parts, days .. " روز")
    end
    if hours > 0 then
        table.insert(parts, hours .. " ساعت")
    end
    if mins > 0 then
        table.insert(parts, mins .. " دقیقه")
    end
    if secs > 0 or #parts == 0 then
        table.insert(parts, secs .. " ثانیه")
    end

    return table.concat(parts, " و ")
end

local function fail_query(context, err)
    teamyar.write_result(json.encode({
        ok = false,
        error = "خطا در اجرای کوئری" .. (context and (": " .. context) or ""),
        detail = tostring(err)
    }))
end

local function fetch_rows(query, params)
    local ok, err = pcall(function()
        db.query({
            query = query,
            params = params or {}
        })
    end)
    if not ok then
        return nil, err
    end

    local rows = {}
    local record = {}
    while db.query_fetch(record) do
        local row = {}
        for i = 1, #record do
            row[i] = record[i]
        end
        table.insert(rows, row)
    end
    db.query_free()
    return rows
end

local function fetch_table_columns(table_name)
    local columns = {}
    local rows = fetch_rows([[
        SELECT COLUMN_NAME
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = ?
        ORDER BY ORDINAL_POSITION
    ]], { table_name })

    if rows == nil then
        return nil
    end

    for _, row in ipairs(rows) do
        columns[string.upper(row[1] or "")] = row[1]
    end
    return columns
end

local function pick_column(columns, candidates)
    for _, name in ipairs(candidates) do
        local col = columns[string.upper(name)]
        if col then
            return col
        end
    end
    return nil
end

local function discover_step_text_column()
    local columns = fetch_table_columns("todo_task_steps")
    if columns == nil then
        return nil
    end
    return pick_column(columns, {
        "DESCRIPTION",
        "STEP_DESC",
        "BODY",
        "CONTENT",
        "COMMENT",
        "NOTE",
        "STEP_TEXT",
        "STEP_COMMENT"
    })
end

local function discover_comment_source()
    for _, table_name in ipairs(COMMENT_TABLE_CANDIDATES) do
        local columns = fetch_table_columns(table_name)
        if columns ~= nil and next(columns) ~= nil then
            local step_col = pick_column(columns, {
                "TASK_STEP_ID",
                "STEP_ROW_ID",
                "TASK_STEP_ROW_ID",
                "REF_ID"
            })
            local content_col = pick_column(columns, {
                "DESCRIPTION",
                "CONTENT",
                "BODY",
                "COMMENT_TEXT",
                "TEXT",
                "COMMENT"
            })

            if step_col and content_col then
                return {
                    table_name = table_name,
                    id_col = pick_column(columns, { "ID" }) or "id",
                    step_col = step_col,
                    content_col = content_col,
                    author_col = pick_column(columns, {
                        "AUTHOR_ID",
                        "CREATOR_ID",
                        "PROFILE_ID",
                        "OWNER_ID",
                        "USER_ID"
                    }),
                    author_name_col = pick_column(columns, {
                        "AUTHOR_NAME",
                        "FULLNAME",
                        "CREATOR_NAME"
                    }),
                    date_col = pick_column(columns, {
                        "DATE_CREATE",
                        "DATE_CREATED",
                        "CREATE_DATE",
                        "CREATED_AT"
                    }),
                    private_col = pick_column(columns, {
                        "IS_PRIVATE",
                        "PRIVATE",
                        "IS_CONFIDENTIAL"
                    }),
                    type_col = pick_column(columns, {
                        "TYPE",
                        "CONTENT_TYPE",
                        "COMMENT_TYPE"
                    }),
                    task_col = pick_column(columns, { "TASK_ID" })
                }
            end
        end
    end
    return nil
end

local function normalize_text(value)
    if value == nil then
        return nil
    end

    local text = tostring(value)
    if text == "" then
        return nil
    end

    return text
end

local function utf8_from_codepoint(cp)
    if cp < 0x80 then
        return string.char(cp)
    elseif cp < 0x800 then
        return string.char(0xC0 + math.floor(cp / 0x40), 0x80 + (cp % 0x40))
    elseif cp < 0x10000 then
        return string.char(
            0xE0 + math.floor(cp / 0x1000),
            0x80 + (math.floor(cp / 0x40) % 0x40),
            0x80 + (cp % 0x40)
        )
    else
        return string.char(
            0xF0 + math.floor(cp / 0x40000),
            0x80 + (math.floor(cp / 0x1000) % 0x40),
            0x80 + (math.floor(cp / 0x40) % 0x40),
            0x80 + (cp % 0x40)
        )
    end
end

local HTML_ENTITIES = {
    nbsp = " ",
    amp = "&",
    lt = "<",
    gt = ">",
    quot = "\"",
    apos = "'",
    laquo = "«",
    raquo = "»",
    mdash = "—",
    ndash = "–",
    hellip = "…",
    zwnj = utf8_from_codepoint(0x200C)
}

local function decode_html_entities(text)
    text = text:gsub("&#[xX](%x+);", function(hex)
        return utf8_from_codepoint(tonumber(hex, 16))
    end)
    text = text:gsub("&#(%d+);", function(dec)
        return utf8_from_codepoint(tonumber(dec))
    end)
    text = text:gsub("&(%a+);", function(name)
        return HTML_ENTITIES[name] or ("&" .. name .. ";")
    end)
    return text
end

-- تبدیل محتوای HTML کامنت به متن ساده و خوانا
local function html_to_text(html)
    if html == nil then
        return nil
    end

    local text = html
    text = text:gsub("<[bB][rR]%s*/?>", "\n")
    text = text:gsub("</[pP]%s*>", "\n")
    text = text:gsub("</[dD][iI][vV]%s*>", "\n")
    text = text:gsub("</[lL][iI]%s*>", "\n")
    text = text:gsub("</[hH]%d%s*>", "\n")
    text = text:gsub("</[sS][eE][cC][tT][iI][oO][nN]%s*>", "\n")
    text = text:gsub("<[^>]*>", "")
    text = decode_html_entities(text)
    text = text:gsub("[ \t\r]+", " ")
    text = text:gsub(" *\n *", "\n")
    text = text:gsub("\n\n+", "\n")
    text = text:gsub("^%s+", "")
    text = text:gsub("%s+$", "")

    if text == "" then
        return nil
    end
    return text
end

local function comment_visibility_label(is_private)
    if tonumber(is_private) == 1 then
        return "محرمانه"
    end
    return "عمومی"
end

local function comment_type_label(content_type)
    local type_code = tonumber(content_type)
    if type_code == nil then
        return "کامنت"
    end
    if type_code == 0 or type_code == 1 then
        return "کامنت"
    end
    if type_code == 2 then
        return "توضیح"
    end
    if type_code == 3 then
        return "دستورالعمل"
    end
    return "متن"
end

local function is_user_comment(content_type)
    local type_code = tonumber(content_type)
    return type_code == 0 or type_code == 1
end

local function is_step_instruction(content_type)
    return tonumber(content_type) == 3
end

local function append_comment(comments_by_step, step_row_id, comment)
    if comments_by_step[step_row_id] == nil then
        comments_by_step[step_row_id] = {}
    end
    table.insert(comments_by_step[step_row_id], comment)
end

local function build_comment_record(row)
    local is_private = tonumber(row[6]) or 0
    local content_type = row[7]
    local content = normalize_text(row[5])

    if content == nil then
        return nil
    end

    return {
        comment_id = row[2],
        author_id = row[3],
        author_name = row[4],
        content = content,
        content_text = html_to_text(content),
        comment_number = tonumber(row[9]) or row[9],
        is_private = is_private == 1,
        visibility = comment_visibility_label(is_private),
        content_type = content_type,
        content_type_label = comment_type_label(content_type),
        date_create = row[8]
    }
end

local function load_todo_task_comments(task_id_value)
    local comments_by_step = {}
    local query = [[
        SELECT
            tc.TASK_STEP_ID AS step_row_id,
            tc.ID AS comment_id,
            tc.AUTHOR_ID AS author_id,
            COALESCE(pm.fullname, tc.AUTHOR_NAME) AS author_name,
            tc.DESCRIPTION AS content,
            COALESCE(tc.IS_PRIVATE, 0) AS is_private,
            tc.TYPE AS content_type,
            ]] .. fmt_jalali_datetime("tc.DATE_CREATE") .. [[ AS date_create,
            tc.COMMENT_NUMBER AS comment_number
        FROM todo_task_comments tc
        LEFT JOIN profile_main pm
            ON pm.id = tc.AUTHOR_ID
        WHERE tc.TASK_ID = ?
        ORDER BY tc.TASK_STEP_ID, tc.COMMENT_NUMBER, tc.ID
    ]]

    local comment_rows = fetch_rows(query, { task_id_value })
    if comment_rows == nil then
        return comments_by_step, false
    end

    for _, row in ipairs(comment_rows) do
        local step_row_id = tonumber(row[1]) or row[1]
        local comment = build_comment_record(row)
        if comment ~= nil then
            append_comment(comments_by_step, step_row_id, comment)
        end
    end

    return comments_by_step, true
end

local function load_step_comments(task_id_value, source)
    local comments_by_step = {}
    if source == nil then
        return comments_by_step
    end

    local author_join = ""
    local author_select = "NULL AS author_id, NULL AS author_name"
    local step_col = sql_ident(source.step_col)
    local id_col = sql_ident(source.id_col)
    local content_col = sql_ident(source.content_col)

    if source.author_col then
        local author_col = sql_ident(source.author_col)
        author_join = "LEFT JOIN profile_main pm ON pm.id = tc." .. author_col
        if source.author_name_col then
            local author_name_col = sql_ident(source.author_name_col)
            author_select = "tc." .. author_col .. " AS author_id, COALESCE(pm.fullname, tc." .. author_name_col .. ") AS author_name"
        else
            author_select = "tc." .. author_col .. " AS author_id, pm.fullname AS author_name"
        end
    end

    local date_select = "NULL AS date_create"
    if source.date_col then
        date_select = fmt_jalali_datetime("tc." .. sql_ident(source.date_col)) .. " AS date_create"
    end

    local private_select = "0 AS is_private"
    if source.private_col then
        private_select = "COALESCE(tc." .. sql_ident(source.private_col) .. ", 0) AS is_private"
    end

    local type_select = "NULL AS content_type"
    if source.type_col then
        type_select = "tc." .. sql_ident(source.type_col) .. " AS content_type"
    end

    local where_clause = ""
    local params = {}
    if source.task_col then
        where_clause = "WHERE tc." .. sql_ident(source.task_col) .. " = ?"
        params = { task_id_value }
    else
        where_clause = "WHERE tc." .. step_col .. " IN (" ..
            "SELECT tts2.id FROM todo_task_steps tts2 WHERE tts2.TASK_ID = ?)"
        params = { task_id_value }
    end

    local order_col = source.date_col and ("tc." .. sql_ident(source.date_col)) or ("tc." .. id_col)
    local query = [[
        SELECT
            tc.]] .. step_col .. [[ AS step_row_id,
            tc.]] .. id_col .. [[ AS comment_id,
            ]] .. author_select .. [[,
            tc.]] .. content_col .. [[ AS content,
            ]] .. private_select .. [[,
            ]] .. type_select .. [[,
            ]] .. date_select .. [[
        FROM ]] .. sql_ident(source.table_name) .. [[ tc
        ]] .. author_join .. [[
        ]] .. where_clause .. [[
        ORDER BY tc.]] .. step_col .. [[, ]] .. order_col .. [[
    ]]

    local comment_rows = fetch_rows(query, params)
    if comment_rows == nil then
        return comments_by_step
    end

    for _, row in ipairs(comment_rows) do
        local step_row_id = tonumber(row[1]) or row[1]
        local comment = build_comment_record(row)
        if comment ~= nil then
            append_comment(comments_by_step, step_row_id, comment)
        end
    end

    return comments_by_step
end

local function load_step_texts(task_id_value, column_name)
    local texts_by_step = {}
    if column_name == nil then
        return texts_by_step
    end

    local col = sql_ident(column_name)
    local rows = fetch_rows(
        "SELECT id, NULLIF(TRIM(" .. col .. "), '') AS step_text FROM todo_task_steps WHERE TASK_ID = ?",
        { task_id_value }
    )
    if rows == nil then
        return texts_by_step
    end

    for _, row in ipairs(rows) do
        local text = normalize_text(row[2])
        if text ~= nil then
            texts_by_step[tonumber(row[1]) or row[1]] = text
        end
    end

    return texts_by_step
end

local function attach_step_texts_and_comments(steps, texts_by_step, comments_by_step)
    for _, step in ipairs(steps) do
        local step_row_id = step.step_row_id
        step._all_comments = comments_by_step[step_row_id] or {}

        if step.step_text == nil then
            step.step_text = texts_by_step[step_row_id]
        end

        if step.step_text == nil then
            for _, comment in ipairs(step._all_comments) do
                if comment.content_type_label == "توضیح" and comment.content ~= nil then
                    step.step_text = comment.content_text or comment.content
                    break
                end
            end
        end
    end
end

local function finalize_step_comments(steps)
    for _, step in ipairs(steps) do
        local all_comments = step._all_comments or {}
        local user_comments = {}
        local step_instruction = nil

        for _, comment in ipairs(all_comments) do
            if is_user_comment(comment.content_type) then
                if step.step_order and comment.comment_number then
                    comment.comment_label = step.step_order .. "_" .. comment.comment_number
                end
                table.insert(user_comments, comment)
            elseif is_step_instruction(comment.content_type) and step_instruction == nil then
                step_instruction = {
                    comment_id = comment.comment_id,
                    comment_number = comment.comment_number,
                    author_id = comment.author_id,
                    author_name = comment.author_name,
                    content_text = comment.content_text,
                    date_create = comment.date_create
                }
            end
        end

        if step.step_text == nil and step_instruction ~= nil then
            step.step_text = step_instruction.content_text
        end

        step.comments = user_comments
        step.comment_count = #user_comments
        step.step_instruction = step_instruction
        step._all_comments = nil
    end
end

-- زمان فعال‌شدن واقعی مرحله در جریان کار
local function step_active_start_ts(step)
    if step.status_code == 0 and step.date_modify_raw > step.date_create_raw then
        return step.date_modify_raw
    end
    return step.date_create_raw
end

-- پایان مرحله جاری (برای محاسبه فاصله تا مرحله بعد)
local function step_finished_ts(step)
    if step.status_code ~= 0 and step.date_modify_raw > 0 then
        return step.date_modify_raw
    end
    return step.date_create_raw
end

local function step_workflow_sort_key(step)
    return step_active_start_ts(step)
end

local function apply_step_gaps(steps, now_raw)
    if #steps == 0 then
        return
    end

    now_raw = tonumber(now_raw) or 0
    if now_raw <= 0 then
        return
    end

    table.sort(steps, function(a, b)
        local ka = step_workflow_sort_key(a)
        local kb = step_workflow_sort_key(b)
        if ka == kb then
            return (a.step_row_id or 0) < (b.step_row_id or 0)
        end
        return ka < kb
    end)

    for i, step in ipairs(steps) do
        local gap_raw = nil
        local gap_type = nil
        local is_current = step.status_code == 0

        if is_current then
            local start_ts = step_active_start_ts(step)
            if start_ts and start_ts > 0 then
                gap_raw = now_raw - start_ts
                gap_type = "to_now"
            end
        elseif i < #steps then
            local next_step = steps[i + 1]
            local start_ts = step_finished_ts(step)
            local end_ts = step_active_start_ts(next_step)
            if start_ts and start_ts > 0 and end_ts and end_ts > 0 then
                gap_raw = end_ts - start_ts
                gap_type = "to_next_step"
            end
        end

        step.step_order = i
        step.is_current_step = is_current
        step.gap_to_next_type = gap_type
        step.gap_to_next_seconds = gap_raw and math.max(0, math.floor(gap_raw / 10000000)) or nil
        step.gap_to_next_label = format_duration(gap_raw and math.max(0, gap_raw) or nil)

        step.step_row_id = nil
        step.date_create_raw = nil
        step.date_modify_raw = nil
        step.status_code = nil
    end
end

local function record_to_step(record)
    return {
        task_id = record[1],
        profile_main_id = record[2],
        profile_main_fullname = record[3],
        task_title = record[4],
        t_start_date = record[5],
        t_return_date = record[6],
        t_end_date = record[7],
        t_real_end_date = record[8],
        step_name = record[9],
        duration = record[10],
        time_unit_label = record[11],
        microsecond_duration = record[12],
        time_unit = record[13],
        DATE_NOW = record[14],
        DATE_MODIFY = record[15],
        DATE_CREATE = record[16],
        status = record[17],
        unit_id = record[18],
        unit_name = record[19],
        a_hh_mm = record[20],
        wf_id = record[21],
        wf_title = record[22],
        hiring_status = record[23],
        step_row_id = record[24],
        date_create_raw = tonumber(record[25]) or 0,
        date_modify_raw = tonumber(record[26]) or 0,
        status_code = tonumber(record[27]) or 0,
        step_text = nil
    }
end

local step_text_column = discover_step_text_column()
local comment_source = discover_comment_source()

local param = {
    query = [[
WITH
LatestOrder AS (
    SELECT
        hpo.*,
        ROW_NUMBER() OVER (
            PARTITION BY hpo.personnel_id
            ORDER BY hpo.DATE_FROM DESC, hpo.DATE_TO DESC
        ) AS rn
    FROM HR_PERSONNEL_ORDER hpo
),

UnitIdToSingleOrgUnit AS (
    SELECT
        oou.UNIT_ID,
        MIN(oou.id) AS oou_id
    FROM org_organization_unit oou
    GROUP BY oou.UNIT_ID
),

PersonnelInfo AS (
    SELECT
        pm.id               AS personnel_profile_id,
        pu.NAME             AS name_fa,
        pu.SURNAME          AS family_fa,
        hp.PERSONNEL_CODE   AS personnel_code,
        hp.PERSONNEL_ID     AS personnel_id,
        oouA.id             AS oou_id_A,
        ouA.name            AS unit_name_A,
        ouB.id              AS ou_id_B,
        ouB.name            AS unit_name_B,
        oouB.oou_id         AS oou_id_B,
        oouP.id             AS oou_id_P,
        ouP.name            AS unit_name_P,
        COALESCE(oouA.id, oouB.oou_id, oouP.id) AS unit_org_unit_id,
        COALESCE(ouA.name, ouB.name, ouP.name, 'بدون واحد') AS unit_name,
        hp.HIRING_STATUS
    FROM PROFILE_MAIN pm
    JOIN PROFILE_USER_INFO pu
        ON pu.id = pm.id
    JOIN HR_PERSONNELS hp
        ON hp.PROFILE_ID = pm.ID
    LEFT JOIN LatestOrder hpo
        ON hpo.personnel_id = hp.personnel_id
       AND hpo.rn = 1
    LEFT JOIN org_organization_unit oouA
        ON oouA.id = hpo.unit_id
    LEFT JOIN org_units ouA
        ON ouA.id = oouA.UNIT_ID
    LEFT JOIN org_units ouB
        ON ouB.id = hpo.unit_id
    LEFT JOIN UnitIdToSingleOrgUnit oouB
        ON oouB.UNIT_ID = ouB.id
    LEFT JOIN org_organization_unit oouP
        ON oouP.id = hp.org_id
    LEFT JOIN org_units ouP
        ON ouP.id = oouP.UNIT_ID
),

LeaveByDay AS (
    SELECT
        het.personnel_id,
        TIMESTAMP(DATE(FROM_UNIXTIME(het.EXT_DATE / 10000000 - 11644473600))) AS g_dt,
        CONCAT(
            LPAD(FLOOR(FLOOR(FLOOR(SUM(het.time_to - het.time_from) / 10000000)) / 3600), 2, '0'),
            ':',
            LPAD(FLOOR(MOD(FLOOR(SUM(het.time_to - het.time_from) / 10000000), 3600) / 60), 2, '0')
        ) AS a_hh_mm
    FROM HR_EXT_TIME het
    WHERE het.enable = 1
      AND het.type IN (2, 3, 4, 5)
    GROUP BY
        het.personnel_id,
        TIMESTAMP(DATE(FROM_UNIXTIME(het.EXT_DATE / 10000000 - 11644473600)))
)

SELECT
    tts.task_id,
    pm.id AS profile_main_id,
    pm.fullname AS profile_main_fullname,
    tt.task_title,
    ]] .. fmt_jalali_datetime("tt.t_start_date") .. [[ AS t_start_date,
    ]] .. fmt_jalali_datetime("tt.t_return_date") .. [[ AS t_return_date,
    ]] .. fmt_jalali_datetime("tt.t_end_date") .. [[ AS t_end_date,
    ]] .. fmt_jalali_datetime("tt.t_real_end_date") .. [[ AS t_real_end_date,
    ts.step_name,
    ts.duration,
    CASE
        WHEN ts.time_unit = 0 THEN 'ندارد'
        WHEN ts.time_unit = 1 THEN 'دقیقه'
        WHEN ts.time_unit = 2 THEN 'ساعت'
        WHEN ts.time_unit = 3 THEN 'روز'
        ELSE 'نامشخص'
    END AS time_unit_label,
    CAST(
        CASE
            WHEN ts.time_unit = 1 THEN ts.duration * 60 * 10000000
            WHEN ts.time_unit = 2 THEN ts.duration * 60 * 60 * 10000000
            WHEN ts.time_unit = 3 THEN ts.duration * 24 * 60 * 60 * 10000000
            ELSE ts.duration
        END AS CHAR
    ) AS microsecond_duration,
    ts.time_unit,
    ]] .. fmt_jalali_datetime("(UNIX_TIMESTAMP() + 11644473600) * 10000000") .. [[ AS DATE_NOW,
    ]] .. fmt_jalali_datetime("tts.DATE_MODIFY") .. [[ AS DATE_MODIFY,
    ]] .. fmt_jalali_datetime("tts.DATE_CREATE") .. [[ AS DATE_CREATE,
    CASE
        WHEN tts.STATUS = 0 THEN 'پیش نویس'
        WHEN tts.STATUS = 1 THEN 'تایید شده'
        WHEN tts.STATUS = 2 THEN 'کامل شده'
        WHEN tts.STATUS = 3 THEN 'رد شده'
        ELSE 'نامشخص'
    END AS STATUS,
    pi.unit_org_unit_id AS unit_org_unit_id,
    pi.unit_name AS unit_name,
    COALESCE(lbd.a_hh_mm, '00:00') AS a_hh_mm,
    tw.id AS wf_id,
    tw.wf_title AS wf_title,
    pi.HIRING_STATUS,
    tts.id AS step_row_id,
    tts.DATE_CREATE AS date_create_raw,
    tts.DATE_MODIFY AS date_modify_raw,
    tts.STATUS AS status_code,
    (UNIX_TIMESTAMP() + 11644473600) * 10000000 AS now_raw
FROM todo_task_steps tts
JOIN profile_main pm
    ON pm.id = tts.RESPONSIBLE_ID
JOIN todo_task tt
    ON tt.id = tts.TASK_ID
JOIN todo_step ts
    ON ts.id = tts.STEP_ID
LEFT JOIN TODO_WORKFLOW tw
    ON tw.id = ts.wf_id
LEFT JOIN PersonnelInfo pi
    ON pi.personnel_profile_id = pm.id
LEFT JOIN LeaveByDay lbd
    ON lbd.personnel_id = pi.personnel_id
   AND lbd.g_dt = TIMESTAMP(DATE(FROM_UNIXTIME(tts.DATE_CREATE / 10000000 - 11644473600)))
WHERE tt.id = ?
ORDER BY tts.id
    ]],
    params = { task_id }
}

local steps = {}
local now_raw = 0

local ok, query_err = pcall(function()
    db.query(param)
end)
if not ok then
    fail_query("task_steps", query_err)
    return
end

local record = {}
while db.query_fetch(record) do
    if now_raw == 0 then
        now_raw = tonumber(record[28]) or 0
    end

    table.insert(steps, record_to_step(record))
end
db.query_free()

local texts_by_step = load_step_texts(task_id, step_text_column)
local comments_by_step, comments_loaded = load_todo_task_comments(task_id)
if not comments_loaded then
    comments_by_step = load_step_comments(task_id, comment_source)
end
attach_step_texts_and_comments(steps, texts_by_step, comments_by_step)
apply_step_gaps(steps, now_raw)
finalize_step_comments(steps)

local output = {
    ok = true,
    task_id = tonumber(task_id) or task_id,
    step_count = #steps,
    steps = steps
}

if #steps == 0 then
    output.ok = false
    output.error = "اقدامی با این شناسه یافت نشد یا مرحله‌ای ندارد"
end

teamyar.write_result(json.encode(output))
