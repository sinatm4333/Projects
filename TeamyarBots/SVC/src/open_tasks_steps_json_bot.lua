-- تحلیل و ایجاد توسط مهدی جهانی 09125632329

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

local function step_active_start_ts(step)
    if step.status_code == 0 and step.date_modify_raw > step.date_create_raw then
        return step.date_modify_raw
    end
    return step.date_create_raw
end

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
        status_code = tonumber(record[27]) or 0
    }
end

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
WHERE (tt.t_real_end_date IS NULL OR tt.t_real_end_date = 0)
  AND EXISTS (
        SELECT 1
        FROM todo_task_steps tts_open
        WHERE tts_open.TASK_ID = tt.id
          AND tts_open.STATUS = 0
    )
ORDER BY tt.id, tts.id
    ]],
    params = {}
}

local tasks_map = {}
local task_ids = {}
local now_raw = 0

db.query(param)

local record = {}
while db.query_fetch(record) do
    if now_raw == 0 then
        now_raw = tonumber(record[28]) or 0
    end

    local task_id = tonumber(record[1]) or record[1]
    if tasks_map[task_id] == nil then
        tasks_map[task_id] = {
            task_id = task_id,
            task_title = record[4],
            steps = {}
        }
        table.insert(task_ids, task_id)
    end

    table.insert(tasks_map[task_id].steps, record_to_step(record))
end
db.query_free()

local tasks = {}
for _, task_id in ipairs(task_ids) do
    local task = tasks_map[task_id]
    apply_step_gaps(task.steps, now_raw)
    task.step_count = #task.steps
    table.insert(tasks, task)
end

local output = {
    ok = true,
    task_count = #tasks,
    tasks = tasks
}

if #tasks == 0 then
    output.ok = false
    output.error = "هیچ اقدام بازی یافت نشد"
end

teamyar.write_result(json.encode(output))
