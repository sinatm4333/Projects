-- تحلیل و ایجاد توسط مهدی جهانی 09125632329

local KNOWN_INPUT_KEYS = {
    "startDate", "start_date", "from_date", "fromDate", "StartDate", "FROM_DATE",
    "endDate", "end_date", "to_date", "toDate", "EndDate", "TO_DATE",
    "center_code", "centerCode", "CenterCode", "CENTER_CODE",
    "branch_code", "branchCode", "BranchCode", "BRANCH_CODE", "center", "branch",
    "account_code", "accountCode", "AccountCode", "ACCOUNT_CODE", "account", "code",
    "org_id", "orgId", "OrgId", "ORG_ID",
    "organization_id", "organizationId", "organization",
    "format", "output", "question", "prompt", "query", "text", "message"
}

local function try_decode_json(text)
    if text == nil then
        return nil
    end

    local trimmed = tostring(text):match("^%s*(.-)%s*$") or ""
    if trimmed == "" then
        return nil
    end

    local candidates = { trimmed }
    if trimmed:sub(1, 1) ~= "{" and trimmed:sub(1, 1) ~= "[" then
        table.insert(candidates, "{" .. trimmed .. "}")
    end

    for _, candidate in ipairs(candidates) do
        local ok, decoded = pcall(json.decode, candidate)
        if ok and type(decoded) == "table" then
            return decoded
        end
    end

    return nil
end

local function table_key_count(source)
    local count = 0
    if type(source) ~= "table" then
        return 0
    end
    for _ in pairs(source) do
        count = count + 1
    end
    return count
end

local function probe_known_keys(source, target)
    if type(source) ~= "table" or type(target) ~= "table" then
        return
    end
    for _, key in ipairs(KNOWN_INPUT_KEYS) do
        local ok, value = pcall(function()
            return source[key]
        end)
        if ok and value ~= nil and target[key] == nil then
            target[key] = value
        end
    end
end

local function merge_tables(target, source)
    if type(source) ~= "table" then
        return
    end
    for key, value in pairs(source) do
        if target[key] == nil then
            target[key] = value
        end
    end
    probe_known_keys(source, target)
end

local function normalize_input(raw)
    local merged = {}
    local meta = {
        raw_type = type(raw),
        raw_preview = "",
        decode_used = false
    }

    if raw == nil then
        meta.raw_preview = "nil"
        return merged, meta
    end

    if type(raw) == "string" then
        meta.raw_preview = raw:sub(1, 240)
        local decoded = try_decode_json(raw)
        if decoded ~= nil then
            meta.decode_used = true
            merge_tables(merged, decoded)
            return merged, meta
        end
        return merged, meta
    end

    meta.raw_preview = tostring(raw):sub(1, 240)

    if type(raw) ~= "table" then
        return merged, meta
    end

    -- Direct copy via pairs
    merge_tables(merged, raw)

    -- Teamyar objects may support key access but not pairs()
    if table_key_count(merged) == 0 then
        probe_known_keys(raw, merged)
    end

    -- Array of {name,value}
    if raw[1] ~= nil and table_key_count(merged) == 0 then
        local from_list = {}
        local looks_like_param_list = true
        for _, item in ipairs(raw) do
            if type(item) ~= "table" then
                looks_like_param_list = false
                break
            end
            local name = item.name or item.NAME or item.key or item.KEY
                or item.id or item.ID or item.param or item.PARAM
            local value = item.value or item.VALUE or item.val or item.VAL
            if name == nil then
                looks_like_param_list = false
                break
            end
            from_list[tostring(name)] = value
        end
        if looks_like_param_list then
            merge_tables(merged, from_list)
        end
    end

    local nest_keys = {
        "params", "param", "data", "form", "values", "input", "args", "body", "payload"
    }
    for _, nest_key in ipairs(nest_keys) do
        local nested = raw[nest_key]
        if type(nested) == "string" then
            nested = try_decode_json(nested)
        end
        if type(nested) == "table" then
            merge_tables(merged, nested)
        end
    end

    return merged, meta
end

local function normalize_key(key)
    return tostring(key):lower():gsub("[^%w]", "")
end

local function is_present(value)
    if value == nil then
        return false
    end
    if type(value) == "string" then
        return value:match("^%s*(.-)%s*$") ~= ""
    end
    return true
end

local function pick_input(source, ...)
    local aliases = { ... }

    for i = 1, #aliases do
        local value = source[aliases[i]]
        if is_present(value) then
            return value
        end
    end

    local wanted = {}
    for i = 1, #aliases do
        wanted[normalize_key(aliases[i])] = true
    end

    for key, value in pairs(source) do
        if type(key) == "string" and wanted[normalize_key(key)] and is_present(value) then
            return value
        end
    end

    return nil
end

local function list_input_keys(source)
    local keys = {}
    for key, _ in pairs(source) do
        table.insert(keys, tostring(key))
    end
    table.sort(keys)
    if #keys == 0 then
        return "(خالی)"
    end
    return table.concat(keys, ", ")
end

local raw_input = nil
do
    local ok, value = pcall(function()
        return teamyar.get_input()
    end)
    if ok then
        raw_input = value
    end
end

-- Fallback APIs used by some Teamyar builds
if (raw_input == nil or (type(raw_input) == "table" and table_key_count(raw_input) == 0)) then
    local alt_names = { "get_params", "get_parameters", "get_form", "get_args", "input" }
    for _, name in ipairs(alt_names) do
        local fn = teamyar[name]
        if type(fn) == "function" then
            local ok, value = pcall(fn)
            if ok and value ~= nil then
                if type(value) ~= "table" or table_key_count(value) > 0 or type(value) == "string" then
                    raw_input = value
                    break
                end
            end
        end
    end
end

local input, input_meta = normalize_input(raw_input)

local start_date = pick_input(input,
    "startDate", "start_date", "from_date", "fromDate", "StartDate", "FROM_DATE")
local end_date = pick_input(input,
    "endDate", "end_date", "to_date", "toDate", "EndDate", "TO_DATE")
local center_code = pick_input(input,
    "center_code", "centerCode", "CenterCode", "CENTER_CODE",
    "branch_code", "branchCode", "BranchCode", "BRANCH_CODE",
    "center", "branch")
local account_code = pick_input(input,
    "account_code", "accountCode", "AccountCode", "ACCOUNT_CODE", "account", "code")
local org_id = pick_input(input,
    "org_id", "orgId", "OrgId", "ORG_ID",
    "organization_id", "organizationId", "organization")

local MAX_DETAIL_ROWS = 30000

local function has_scope_filter()
    return is_present(center_code) or is_present(account_code)
end

local JALALI_MONTHS = {
    "فروردین", "اردیبهشت", "خرداد", "تیر", "مرداد", "شهریور",
    "مهر", "آبان", "آذر", "دی", "بهمن", "اسفند"
}

local function normalize_jalali_date(value)
    if value == nil or value == "" then
        return nil
    end

    local s = tostring(value):gsub("/", "-"):gsub("%.", "-"):match("^%s*(.-)%s*$")
    local y, m, d = s:match("^(%d%d%d%d)-(%d%d)-(%d%d)$")
    if y then
        return string.format("%04d-%02d-%02d", tonumber(y), tonumber(m), tonumber(d))
    end

    y, m, d = s:match("^(%d%d%d%d)(%d%d)(%d%d)$")
    if y then
        return string.format("%04d-%02d-%02d", tonumber(y), tonumber(m), tonumber(d))
    end

    return nil
end

local function is_filetime(value)
    local n = tonumber(value)
    return n ~= nil and n > 100000000000
end

local function wants_json(source)
    local fmt = source["format"] or source["output"] or source["output_format"]
        or source["result_format"] or source["response_format"]
    if fmt ~= nil and tostring(fmt):lower() == "json" then
        return true
    end

    local question_fields = {
        "question", "prompt", "query", "text", "message", "user_message", "ask"
    }
    for _, key in ipairs(question_fields) do
        local value = source[key]
        if type(value) == "string" and value:lower():find("json", 1, true) then
            return true
        end
    end

    return false
end

local start_explicit = start_date ~= nil and start_date ~= ""
local end_explicit = end_date ~= nil and end_date ~= ""
local start_jalali = start_explicit and normalize_jalali_date(start_date) or nil
local end_jalali = end_explicit and normalize_jalali_date(end_date) or nil
local dates_defaulted = {
    from_date = false,
    to_date = false
}
local output_json = wants_json(input)

local function fail(message)
    if output_json then
        teamyar.write_result(json.encode({
            ok = false,
            error = message
        }))
    else
        teamyar.write_result(string.format([[
<!DOCTYPE html>
<html dir="rtl" lang="fa">
<head><meta charset="UTF-8"><title>خطا</title></head>
<body style="font-family:tahoma;padding:2rem;text-align:center;">
<h2 style="color:#b42318;">%s</h2>
</body></html>
]], message))
    end
end

if start_explicit and start_jalali == nil and not is_filetime(start_date) then
    fail("تاریخ شروع نامعتبر است. فرمت: 1404-01-01")
    return
end

if end_explicit and end_jalali == nil and not is_filetime(end_date) then
    fail("تاریخ پایان نامعتبر است. فرمت: 1404-12-29")
    return
end

if org_id ~= nil and org_id ~= "" and tonumber(org_id) == nil then
    fail("شناسه سازمان نامعتبر است")
    return
end

local HTML_DQ = string.char(34)

local function escape_html(value)
    if value == nil then
        return ''
    end
    return tostring(value)
        :gsub('&', '&amp;')
        :gsub('<', '&lt;')
        :gsub('>', '&gt;')
        :gsub(HTML_DQ, '&quot;')
end

local function fmt_amount(value)
    local n = tonumber(value)
    if n == nil then
        return "0"
    end
    if math.type and math.type(n) == "integer" then
        return tostring(n)
    end
    if n == math.floor(n) then
        return tostring(math.floor(n))
    end
    return tostring(n)
end

local function jalali_month_name(jalali_date)
    if jalali_date == nil or jalali_date == '' then
        return ''
    end
    local month = jalali_date:match("%d%d%d%d%-(%d%d)%-%d%d")
        or jalali_date:match("%d%d%d%d%.(%d%d)%.%d%d")
    local month_no = tonumber(month)
    if month_no == nil or month_no < 1 or month_no > 12 then
        return ''
    end
    return JALALI_MONTHS[month_no]
end

local function diagnosis_label(balance)
    local n = tonumber(balance) or 0
    if n < 0 then
        return "بس"
    end
    return "بد"
end

local function run_query(query, params)
    pcall(function()
        db.use_db("0000000")
    end)
    db.query({
        query = query,
        params = params or {}
    })
end

local function fetch_rows(query, params)
    local ok, err = pcall(function()
        run_query(query, params)
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

local function fetch_generated_at()
    local rows = fetch_rows([[
        SELECT CONCAT(
            REPORT_FN_JDATE((UNIX_TIMESTAMP() + 11644473600) * 10000000, '-'),
            ' ',
            DATE_FORMAT(NOW(), '%H:%i:%s')
        ) AS generated_at
    ]])
    if rows == nil or #rows == 0 or rows[1][1] == nil then
        return "—"
    end
    return tostring(rows[1][1])
end

local function fetch_default_dates()
    local params = {}
    local org_clause = ''
    if org_id ~= nil and org_id ~= "" then
        org_clause = " AND fy.ORG_ID = ?"
        table.insert(params, tonumber(org_id))
    end

    local rows = fetch_rows([[
SELECT
    REPORT_FN_JDATE(fy.START_DATE, '-') AS fiscal_start_jalali,
    REPORT_FN_JDATE((UNIX_TIMESTAMP() + 11644473600) * 10000000, '-') AS today_jalali
FROM pa_fiscal_year fy
WHERE (UNIX_TIMESTAMP() + 11644473600) * 10000000 >= fy.START_DATE
  AND (UNIX_TIMESTAMP() + 11644473600) * 10000000 <= fy.END_DATE
]] .. org_clause .. [[
ORDER BY fy.START_DATE DESC
LIMIT 1
]], params)

    if rows ~= nil and #rows > 0 and rows[1][1] ~= nil and rows[1][2] ~= nil then
        return tostring(rows[1][1]), tostring(rows[1][2])
    end

    rows = fetch_rows([[
SELECT
    CONCAT(
        SUBSTRING(REPORT_FN_JDATE((UNIX_TIMESTAMP() + 11644473600) * 10000000, '-'), 1, 4),
        '-01-01'
    ) AS fiscal_start_jalali,
    REPORT_FN_JDATE((UNIX_TIMESTAMP() + 11644473600) * 10000000, '-') AS today_jalali
]])
    if rows ~= nil and #rows > 0 and rows[1][1] ~= nil and rows[1][2] ~= nil then
        return tostring(rows[1][1]), tostring(rows[1][2])
    end

    return nil, nil
end

local function resolve_default_dates()
    local default_start, default_end = fetch_default_dates()

    if not start_explicit then
        if default_start ~= nil then
            start_jalali = default_start
            start_date = default_start
            dates_defaulted.from_date = true
        end
    end

    if not end_explicit then
        if default_end ~= nil then
            end_jalali = default_end
            end_date = default_end
            dates_defaulted.to_date = true
        end
    end
end

resolve_default_dates()

if start_jalali == nil and not is_filetime(start_date) then
    fail("تاریخ شروع مشخص نیست و سال مالی فعال یافت نشد")
    return
end

if end_jalali == nil and not is_filetime(end_date) then
    fail("تاریخ پایان مشخص نیست")
    return
end

if not has_scope_filter() then
    local preview = (input_meta and input_meta.raw_preview) or ""
    if preview ~= "" then
        preview = preview:gsub("[%c]", " ")
        if #preview > 160 then
            preview = preview:sub(1, 160) .. "..."
        end
    else
        preview = "(خالی)"
    end
    fail("برای دریافت ریز هزینه‌ها حداقل center_code یا account_code لازم است"
        .. " | کلیدها: " .. list_input_keys(input)
        .. " | نوع ورودی: " .. tostring(input_meta and input_meta.raw_type or "?")
        .. " | پیش‌نمایش: " .. preview
        .. " | نکته: JSON باید با { شروع و با } تمام شود؛ بعد از ویرایش دکمه تأیید را بزنید")
    return
end

local function append_opening_date_filter(where_parts, params)
    if start_jalali ~= nil then
        table.insert(where_parts, "REPORT_FN_JDATE(v.RUN_DATE, '-') < ?")
        table.insert(params, start_jalali)
    elseif is_filetime(start_date) then
        table.insert(where_parts, "v.RUN_DATE < ?")
        table.insert(params, tonumber(start_date))
    end
end

local function append_range_date_filters(where_parts, params)
    if start_jalali ~= nil then
        table.insert(where_parts, "REPORT_FN_JDATE(v.RUN_DATE, '-') >= ?")
        table.insert(params, start_jalali)
    elseif is_filetime(start_date) then
        table.insert(where_parts, "v.RUN_DATE >= ?")
        table.insert(params, tonumber(start_date))
    end

    if end_jalali ~= nil then
        table.insert(where_parts, "REPORT_FN_JDATE(v.RUN_DATE, '-') <= ?")
        table.insert(params, end_jalali)
    elseif is_filetime(end_date) then
        table.insert(where_parts, "v.RUN_DATE <= ?")
        table.insert(params, tonumber(end_date))
    end
end

local function append_common_filters(where_parts, params)
    table.insert(where_parts, "vr.DELETED = 0")
    table.insert(where_parts, "v.DELETED = 0")
    table.insert(where_parts, "v.STATUS NOT IN (0, 3)")

    if org_id ~= nil and org_id ~= "" then
        table.insert(where_parts, "v.ORG_ID = ?")
        table.insert(params, tonumber(org_id))
    end

    if center_code ~= nil and center_code ~= "" then
        local code = tostring(center_code):match("^%s*(.-)%s*$")
        if code:find("%%", 1, true) then
            table.insert(where_parts, "COALESCE(NULLIF(ce.CENTER_CODE, ''), ce.CODE) LIKE ?")
            table.insert(params, code)
        else
            table.insert(where_parts, "COALESCE(NULLIF(ce.CENTER_CODE, ''), ce.CODE) = ?")
            table.insert(params, code)
        end
    end

    if account_code ~= nil and account_code ~= "" then
        local code = tostring(account_code):match("^%s*(.-)%s*$")
        if code:find("%%", 1, true) then
            table.insert(where_parts, "COALESCE(NULLIF(a.CODE, ''), a.ACCOUNT_CODE) LIKE ?")
            table.insert(params, code)
        else
            table.insert(where_parts, "COALESCE(NULLIF(a.CODE, ''), a.ACCOUNT_CODE) = ?")
            table.insert(params, code)
        end
    end
end

local function build_from_clause()
    return [[
FROM pa_voucher_record vr
INNER JOIN pa_voucher v
    ON v.ID = vr.VOUCHER_ID
   AND v.ORG_ID = vr.ORG_ID
INNER JOIN pa_account a
    ON a.ID = vr.ACCOUNT_ID
LEFT JOIN pa_client c
    ON c.ID = vr.CLIENT_ID
   AND c.ORG_ID = vr.ORG_ID
LEFT JOIN pa_floating f
    ON f.ID = vr.FLOATING_ACCOUNT_ID
LEFT JOIN pa_center ce
    ON ce.ID = vr.CENTER_ID
   AND ce.ORG_ID = vr.ORG_ID
]]
end

local base_from = build_from_clause()

local select_columns = [[
    vr.ID AS system_id,
    COALESCE(NULLIF(v.VOUCHER_ID, 0), v.ID) AS voucher_ref,
    REPORT_FN_JDATE(v.RUN_DATE, '-') AS voucher_date,
    COALESCE(NULLIF(a.CODE, ''), a.ACCOUNT_CODE) AS account_code,
    a.NAME AS account_name,
    c.CODE AS client_code,
    c.NAME AS client_name,
    f.CODE AS floating_code,
    f.NAME AS floating_name,
    COALESCE(NULLIF(ce.CENTER_CODE, ''), ce.CODE) AS center_code,
    ce.NAME AS center_name,
    vr.CONTENT AS description_text,
    COALESCE(vr.DEB, 0) AS debit_amount,
    COALESCE(vr.CRD, 0) AS credit_amount,
    v.RUN_DATE AS run_date_sort,
    COALESCE(vr.RECORD_SORT, 0) AS record_sort_value
]]

local minimal_from = [[
FROM pa_voucher_record vr
INNER JOIN pa_voucher v
    ON v.ID = vr.VOUCHER_ID
   AND v.ORG_ID = vr.ORG_ID
INNER JOIN pa_account a
    ON a.ID = vr.ACCOUNT_ID
LEFT JOIN pa_center ce
    ON ce.ID = vr.CENTER_ID
   AND ce.ORG_ID = vr.ORG_ID
]]

local minimal_select_columns = [[
    vr.ID AS system_id,
    COALESCE(NULLIF(v.VOUCHER_ID, 0), v.ID) AS voucher_ref,
    REPORT_FN_JDATE(v.RUN_DATE, '-') AS voucher_date,
    COALESCE(NULLIF(a.CODE, ''), a.ACCOUNT_CODE) AS account_code,
    a.NAME AS account_name,
    NULL AS client_code,
    NULL AS client_name,
    NULL AS floating_code,
    NULL AS floating_name,
    COALESCE(NULLIF(ce.CENTER_CODE, ''), ce.CODE) AS center_code,
    ce.NAME AS center_name,
    vr.CONTENT AS description_text,
    COALESCE(vr.DEB, 0) AS debit_amount,
    COALESCE(vr.CRD, 0) AS credit_amount,
    v.RUN_DATE AS run_date_sort,
    COALESCE(vr.RECORD_SORT, 0) AS record_sort_value
]]

local function fetch_opening_balance()
    if start_jalali == nil and not is_filetime(start_date) then
        return 0
    end

    local where_parts = {}
    local params = {}
    append_common_filters(where_parts, params)
    append_opening_date_filter(where_parts, params)

    local query = [[
SELECT COALESCE(SUM(COALESCE(vr.CRD, 0) - COALESCE(vr.DEB, 0)), 0)
]] .. base_from .. [[
WHERE ]] .. table.concat(where_parts, " AND ")

    local rows, err = fetch_rows(query, params)
    if rows == nil then
        return nil, err
    end
    return tonumber(rows[1][1]) or 0
end

local function trim_detail_rows(rows)
    if rows == nil then
        return {}
    end
    if #rows <= MAX_DETAIL_ROWS then
        return rows
    end

    local trimmed = {}
    for index = 1, MAX_DETAIL_ROWS do
        trimmed[index] = rows[index]
    end
    return trimmed
end

local function run_detail_query(from_clause, columns, where_clause, params)
    local query = [[
SELECT
]] .. columns .. from_clause .. [[
WHERE ]] .. where_clause

    return fetch_rows(query, params)
end

local function sort_detail_rows(rows)
    table.sort(rows, function(left, right)
        local run_left = tonumber(left[15]) or 0
        local run_right = tonumber(right[15]) or 0
        if run_left ~= run_right then
            return run_left < run_right
        end

        local sort_left = tonumber(left[16]) or 0
        local sort_right = tonumber(right[16]) or 0
        if sort_left ~= sort_right then
            return sort_left < sort_right
        end

        return (tonumber(left[1]) or 0) < (tonumber(right[1]) or 0)
    end)
    return rows
end

local function fetch_detail_rows()
    local where_parts = {}
    local params = {}
    append_common_filters(where_parts, params)
    append_range_date_filters(where_parts, params)

    local where_clause = table.concat(where_parts, " AND ")

    local rows, err = run_detail_query(minimal_from, minimal_select_columns, where_clause, params)
    if rows == nil then
        rows, err = run_detail_query(base_from, select_columns, where_clause, params)
    end
    if rows == nil then
        return nil, err
    end
    if #rows == 0 then
        return {}
    end

    return sort_detail_rows(trim_detail_rows(rows))
end

local opening_balance, opening_err = fetch_opening_balance()
if opening_balance == nil then
    fail("خطا در محاسبه مانده ابتدای دوره: " .. tostring(opening_err))
    return
end

local raw_rows, query_err = fetch_detail_rows()
if raw_rows == nil then
    fail("خطا در دریافت ریز هزینه‌ها: " .. tostring(query_err)
        .. " — center_code یا account_code و بازه تاریخ را مشخص کنید")
    return
end

local detail_truncated = #raw_rows >= MAX_DETAIL_ROWS

local report_rows = {}
local running_balance = opening_balance
local total_debit = 0
local total_credit = 0

if start_jalali ~= nil or is_filetime(start_date) then
    table.insert(report_rows, {
        row_no = 0,
        is_opening = true,
        system_id = nil,
        voucher_ref = nil,
        voucher_date = nil,
        month_name = nil,
        account_code = nil,
        account_name = nil,
        client_code = nil,
        client_name = nil,
        floating_code = nil,
        floating_name = nil,
        center_code = nil,
        center_name = nil,
        description = "مانده ابتدای دوره",
        debit = 0,
        credit = 0,
        balance = running_balance,
        diagnosis = diagnosis_label(running_balance)
    })
end

for _, row in ipairs(raw_rows) do
    local debit = tonumber(row[13]) or 0
    local credit = tonumber(row[14]) or 0
    running_balance = running_balance + credit - debit
    total_debit = total_debit + debit
    total_credit = total_credit + credit

    local voucher_date = row[3]
    table.insert(report_rows, {
        row_no = #report_rows + 1,
        is_opening = false,
        system_id = row[1],
        voucher_ref = row[2],
        voucher_date = voucher_date,
        month_name = jalali_month_name(voucher_date),
        account_code = row[4],
        account_name = row[5],
        client_code = row[6],
        client_name = row[7],
        floating_code = row[8],
        floating_name = row[9],
        center_code = row[10],
        center_name = row[11],
        description = row[12],
        debit = debit,
        credit = credit,
        balance = running_balance,
        diagnosis = diagnosis_label(running_balance)
    })
end

local display_no = 0
for _, item in ipairs(report_rows) do
    if item.is_opening then
        item.row_no = nil
    else
        display_no = display_no + 1
        item.row_no = display_no
    end
end

local filters = {
    from_date = start_jalali or start_date or nil,
    to_date = end_jalali or end_date or nil,
    from_date_defaulted = dates_defaulted.from_date,
    to_date_defaulted = dates_defaulted.to_date,
    center_code = center_code,
    account_code = account_code,
    org_id = org_id ~= nil and org_id ~= "" and tonumber(org_id) or nil,
    detail_truncated = detail_truncated,
    max_detail_rows = MAX_DETAIL_ROWS
}

if output_json then
    teamyar.write_result(json.encode({
        ok = true,
        report_title = "گزارش ریز هزینه شعبات گارانتی",
        filters = filters,
        generated_at = fetch_generated_at(),
        opening_balance = opening_balance,
        total_debit = total_debit,
        total_credit = total_credit,
        closing_balance = running_balance,
        row_count = #report_rows,
        rows = report_rows
    }))
    return
end

local detail_rows_html = {}
for _, item in ipairs(report_rows) do
    local row_class = item.is_opening and 'opening-row' or ''
    table.insert(detail_rows_html, string.format(
        [[<tr class="%s">
            <td>%s</td>
            <td>%s</td>
            <td>%s</td>
            <td>%s</td>
            <td>%s</td>
            <td>%s</td>
            <td class="name-cell">%s</td>
            <td>%s</td>
            <td class="name-cell">%s</td>
            <td>%s</td>
            <td class="name-cell">%s</td>
            <td>%s</td>
            <td class="name-cell">%s</td>
            <td class="desc-cell">%s</td>
            <td>%s</td>
            <td>%s</td>
            <td>%s</td>
            <td>%s</td>
        </tr>]],
        row_class,
        item.is_opening and "—" or escape_html(item.row_no),
        escape_html(item.system_id),
        escape_html(item.voucher_ref),
        escape_html(item.voucher_date),
        escape_html(item.month_name),
        escape_html(item.account_code),
        escape_html(item.account_name),
        escape_html(item.client_code),
        escape_html(item.client_name),
        escape_html(item.floating_code),
        escape_html(item.floating_name),
        escape_html(item.center_code),
        escape_html(item.center_name),
        escape_html(item.description),
        escape_html(fmt_amount(item.debit)),
        escape_html(fmt_amount(item.credit)),
        escape_html(fmt_amount(item.balance)),
        escape_html(item.diagnosis)
    ))
end

if #detail_rows_html == 0 then
    detail_rows_html = {
        [[<tr><td colspan="18" class="empty-row">در بازه و فیلترهای انتخاب‌شده رکوردی یافت نشد</td></tr>]]
    }
end

local filter_from = start_jalali or start_date or "—"
local filter_to = end_jalali or end_date or "—"
local filter_center = center_code or "—"
local filter_account = account_code or "—"
local filter_org = org_id or "—"
local generated_at = fetch_generated_at()
local truncation_note = detail_truncated
    and (" | هشدار: فقط " .. tostring(MAX_DETAIL_ROWS) .. " ردیف اول نمایش داده شد")
    or ""

local html = string.format([[
<!DOCTYPE html>
<html dir="rtl" lang="fa">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>گزارش ریز هزینه شعبات گارانتی</title>
<style>
* { box-sizing: border-box; }
body {
    margin: 0;
    padding: 12px;
    font-family: IRANSansWeb_Light, Tahoma, sans-serif;
    font-size: 12px;
    font-weight: bold;
    background: #f5f7fb;
}
#reportRoot:fullscreen {
    background: #f5f7fb;
    padding: 12px;
    overflow: auto;
}
.toolbar {
    display: flex;
    justify-content: flex-start;
    gap: 8px;
    margin-bottom: 10px;
}
.btn-fullscreen {
    background: #0073e6;
    color: #fff;
    border: 2px solid #005bb5;
    border-radius: 8px;
    padding: 8px 16px;
    font-family: IRANSansWeb_Light, Tahoma, sans-serif;
    font-size: 12px;
    font-weight: bold;
    cursor: pointer;
}
.btn-fullscreen:hover { background: #005bb5; }
.report-header {
    background-color: #D2E0FB;
    text-align: center;
    border: 1px dotted #000;
    border-radius: 10px;
    padding: 12px 10px 16px;
    margin-bottom: 12px;
}
.report-header p { margin: 4px 0; }
.meta-line {
    font-size: 11px;
    color: #333;
    margin-top: 8px;
}
.summary-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
    gap: 8px;
    margin-bottom: 12px;
}
.summary-card {
    background: #fff;
    border: 1px solid #d0d7e2;
    border-radius: 8px;
    padding: 10px;
    text-align: center;
}
.summary-card .label { font-size: 11px; color: #555; }
.summary-card .value { font-size: 14px; margin-top: 4px; }
.table-wrap {
    overflow: auto;
    background: #fff;
    border: 2px solid #7d0000;
    border-radius: 8px;
}
table {
    border-collapse: collapse;
    width: 100%%;
    min-width: 1600px;
    text-align: center;
}
th, td {
    border: 1px solid #dddddd;
    padding: 6px 4px;
    font-size: 11px;
    white-space: nowrap;
}
th {
    background-color: #0073e6;
    color: #fff;
    position: sticky;
    top: 0;
    z-index: 1;
}
tr:nth-child(even):not(.opening-row) { background-color: #eef4ff; }
.opening-row { background-color: #fff4ce; font-weight: bold; }
.name-cell { min-width: 120px; }
.desc-cell {
    min-width: 280px;
    max-width: 420px;
    white-space: normal;
    text-align: right;
}
.empty-row { padding: 24px; color: #666; }
.footer {
    margin-top: 10px;
    text-align: center;
    font-size: 10px;
    color: #666;
}
</style>
</head>
<body>
<div id="reportRoot">
    <div class="toolbar">
        <button type="button" class="btn-fullscreen" id="btnFullscreen" onclick="toggleFullScreen()">تمام صفحه</button>
    </div>

    <div class="report-header">
        <p>گزارش ریز هزینه شعبات گارانتی</p>
        <p class="meta-line">از تاریخ: %s | تا تاریخ: %s | کد مرکز: %s | کد حساب: %s | سازمان: %s</p>
        <p class="meta-line">زمان تولید: %s | تعداد ردیف: %s%s</p>
    </div>

    <div class="summary-grid">
        <div class="summary-card"><div class="label">مانده ابتدای دوره</div><div class="value">%s</div></div>
        <div class="summary-card"><div class="label">جمع بدهکار</div><div class="value">%s</div></div>
        <div class="summary-card"><div class="label">جمع بستانکار</div><div class="value">%s</div></div>
        <div class="summary-card"><div class="label">مانده پایان دوره</div><div class="value">%s</div></div>
    </div>

    <div class="table-wrap">
        <table>
            <thead>
                <tr>
                    <th>ردیف</th>
                    <th>شماره سیستمی</th>
                    <th>شناسه سند</th>
                    <th>تاریخ سند</th>
                    <th>ماه</th>
                    <th>کد حساب</th>
                    <th>نام حساب</th>
                    <th>شناسه شخص</th>
                    <th>شخص</th>
                    <th>کد شناور</th>
                    <th>شناور</th>
                    <th>کد مرکز</th>
                    <th>شعبات</th>
                    <th>شرح</th>
                    <th>بدهکار</th>
                    <th>بستانکار</th>
                    <th>مانده کل</th>
                    <th>تشخیص</th>
                </tr>
            </thead>
            <tbody>%s</tbody>
        </table>
    </div>

    <div class="footer">Teamyar Warranty Branch Expense Detail Report</div>
</div>

<script>
function toggleFullScreen() {
    var root = document.getElementById('reportRoot');
    var btn = document.getElementById('btnFullscreen');
    var isFull = document.fullscreenElement || document.webkitFullscreenElement || document.msFullscreenElement;

    if (!isFull) {
        if (root.requestFullscreen) root.requestFullscreen();
        else if (root.webkitRequestFullscreen) root.webkitRequestFullscreen();
        else if (root.msRequestFullscreen) root.msRequestFullscreen();
        btn.innerText = 'خروج از تمام صفحه';
    } else {
        if (document.exitFullscreen) document.exitFullscreen();
        else if (document.webkitExitFullscreen) document.webkitExitFullscreen();
        else if (document.msExitFullscreen) document.msExitFullscreen();
        btn.innerText = 'تمام صفحه';
    }
}

document.addEventListener('fullscreenchange', syncFullscreenButton);
document.addEventListener('webkitfullscreenchange', syncFullscreenButton);

function syncFullscreenButton() {
    var btn = document.getElementById('btnFullscreen');
    var isFull = document.fullscreenElement || document.webkitFullscreenElement || document.msFullscreenElement;
    btn.innerText = isFull ? 'خروج از تمام صفحه' : 'تمام صفحه';
}
</script>
</body>
</html>
]],
    escape_html(filter_from),
    escape_html(filter_to),
    escape_html(filter_center),
    escape_html(filter_account),
    escape_html(filter_org),
    escape_html(generated_at),
    escape_html(#report_rows),
    escape_html(truncation_note),
    escape_html(fmt_amount(opening_balance)),
    escape_html(fmt_amount(total_debit)),
    escape_html(fmt_amount(total_credit)),
    escape_html(fmt_amount(running_balance)),
    table.concat(detail_rows_html, "\n")
)

teamyar.write_result(html)
