-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/05/20 16:30

local input = teamyar.get_input() or {}
local table_unpack = table.unpack or unpack

local start_date = input["startDate"] or input["start_date"]
    or input["from_date"] or input["fromDate"]
local end_date = input["endDate"] or input["end_date"]
    or input["to_date"] or input["toDate"]
local product_code = input["product_code"] or input["productCode"]
local receipt_no = input["receipt_no"] or input["receiptNo"] or input["code"]

local function normalize_jalali_date(value)
    if value == nil or value == "" then
        return nil
    end

    local s = tostring(value):gsub("/", "-"):match("^%s*(.-)%s*$")
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

local start_jalali = normalize_jalali_date(start_date)
local end_jalali = normalize_jalali_date(end_date)

local function wants_json(source)
    local fmt = source["format"] or source["output"] or source["output_format"]
        or source["result_format"] or source["response_format"]
    if fmt == nil then
        return false
    end
    return tostring(fmt):lower() == 'json'
end

local output_json = wants_json(input)
local HTML_DQ = string.char(34)

local function fail_html(message)
    teamyar.write_result(string.format([[
<!DOCTYPE html>
<html dir="rtl" lang="fa">
<head><meta charset="UTF-8"><title>خطا</title></head>
<body style="font-family:tahoma;padding:2rem;text-align:center;">
<h2 style="color:#b42318;">%s</h2>
</body></html>
]], message))
end

local function fail(message, detail)
    if detail ~= nil and detail ~= "" then
        message = message .. ": " .. tostring(detail)
    end
    if output_json then
        teamyar.write_result(json.encode({
            ok = false,
            error = message
        }))
    else
        fail_html(message)
    end
end

if start_date ~= nil and start_date ~= "" and start_jalali == nil and not is_filetime(start_date) then
    fail("تاریخ شروع نامعتبر است. فرمت: 1404-04-01")
    return
end

if end_date ~= nil and end_date ~= "" and end_jalali == nil and not is_filetime(end_date) then
    fail("تاریخ پایان نامعتبر است. فرمت: 1404-04-01")
    return
end

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

local function safe_format(fmt, ...)
    local args = { ... }
    for i, value in ipairs(args) do
        if type(value) == 'string' then
            args[i] = value:gsub('%%', '%%%%')
        end
    end
    return string.format(fmt, table_unpack(args))
end

local function fmt_num(value)
    local n = tonumber(value)
    if n == nil then
        return "—"
    end
    return tostring(math.floor(n + 0.5))
end

local function fmt_percent(value)
    local n = tonumber(value)
    if n == nil then
        return "—"
    end
    return tostring(math.floor(n + 0.5)) .. "٪"
end

local function return_analyze_label(rate)
    local n = tonumber(rate)
    if n == nil then
        return "نامشخص"
    end
    if n >= 7 then
        return "بحرانی"
    end
    if n > 3 then
        return "هشدار"
    end
    return "قابل قبول"
end

local function return_analyze_class(rate)
    local n = tonumber(rate)
    if n == nil then
        return "rate-neutral"
    end
    if n >= 7 then
        return "rate-critical"
    end
    if n > 3 then
        return "rate-warning"
    end
    return "rate-good"
end

local function append_date_filters(where_parts, params, date_column)
    date_column = date_column or "sr.BREAK_DOWN_DATE"

    local has_start = start_jalali ~= nil or is_filetime(start_date)
    local has_end = end_jalali ~= nil or is_filetime(end_date)

    if not has_start and not has_end then
        table.insert(where_parts,
            date_column .. " >= ((UNIX_TIMESTAMP() - (90 * 86400)) + 11644473600) * 10000000")
    end

    if start_jalali ~= nil then
        table.insert(where_parts, "REPORT_FN_JDATE(" .. date_column .. ", '-') >= ?")
        table.insert(params, start_jalali)
    elseif is_filetime(start_date) then
        table.insert(where_parts, date_column .. " >= ?")
        table.insert(params, tonumber(start_date))
    end

    if end_jalali ~= nil then
        table.insert(where_parts, "REPORT_FN_JDATE(" .. date_column .. ", '-') <= ?")
        table.insert(params, end_jalali)
    elseif is_filetime(end_date) then
        table.insert(where_parts, date_column .. " <= ?")
        table.insert(params, tonumber(end_date))
    end
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

local function get_current_filetime()
    local rows = fetch_rows([[
        SELECT REPORT_FN_GDATE_TO_FILETIME(YEAR(NOW()), MONTH(NOW()), DAY(NOW())) AS current_filetime
    ]])
    if rows ~= nil and #rows > 0 and rows[1][1] ~= nil then
        local ft = tonumber(rows[1][1])
        if ft ~= nil and ft > 0 then
            return ft
        end
    end

    rows = fetch_rows([[
        SELECT (UNIX_TIMESTAMP() + 11644473600) * 10000000 AS current_filetime
    ]])
    if rows ~= nil and #rows > 0 then
        return tonumber(rows[1][1]) or 0
    end
    return 0
end

local function append_in_params(params, values)
    for _, value in ipairs(values) do
        table.insert(params, value)
    end
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

local function build_in_clause(values)
    local placeholders = {}
    for _ = 1, #values do
        table.insert(placeholders, "?")
    end
    return table.concat(placeholders, ", ")
end

local function dedupe_codes(codes)
    local seen = {}
    local unique = {}
    for _, code in ipairs(codes) do
        if code ~= nil and code ~= "" and not seen[code] then
            seen[code] = true
            table.insert(unique, code)
        end
    end
    return unique
end

local MONEY_SCALE = 10000000.0

local function normalize_product_code(code)
    if code == nil or code == "" then
        return nil
    end
    return tostring(code):match("^%s*(.-)%s*$")
end

-- نکته: این تابع باید بعد از normalize_product_code و dedupe_codes تعریف شود
-- (باگ قبلی: تعریف زودتر باعث می‌شد به global نامعتبر اشاره کند و همیشه silent-fail شود)
local function normalize_product_code_list(product_codes)
    local normalized_codes = {}
    for _, code in ipairs(product_codes or {}) do
        local normalized = normalize_product_code(code)
        if normalized ~= nil then
            table.insert(normalized_codes, normalized)
        end
    end
    return dedupe_codes(normalized_codes)
end

-- فاکتور فروش: فقط حذف‌شده / باطل / رد‌شده
--[[
  SALES QUERY — DO NOT CHANGE without testing product_code 32030020282
  - Filter: DELETED/CANCELED/REJECT=0 only. (تاریخ ۱۴۰۵/۰۴/۳۰: شرط TYPE NOT IN (1,5)
    که قبلاً اینجا بود عمداً برداشته شد — خودش باعث افت فروش این کد از ۱۰۸۶۴۶ به ۴۰۹۹
    می‌شد. عدد انتظار رگرسیون ۱۰۸۶۴۶ فقط بدون فیلتر TYPE دوباره تکرار می‌شود.)
  - Join wh_product via PRODUCT_ID or product_id_info
  - Sales must load independently from warranty (see load_product_sales_stats)
]]
local function sales_invoice_filter_sql()
    -- نکته: فیلتر «TYPE NOT IN (1,5)» عمداً حذف شد. تست مستقیم روی کد رگرسیون رسمی
    -- پروژه (32030020282) ثابت کرد که همین شرط TYPE باعث افت جمع فروش از ۱۰۸,۶۴۶
    -- (مقدار مستند و تایید‌شده در CLAUDE.md) به فقط ۴,۰۹۹ می‌شد — یعنی این فیلتر
    -- خودش باگ بود، نه محافظ. بدون این شرط، عدد دقیقاً با ۱۰۸,۶۴۶ برابر شد.
    return [[
  COALESCE(si.DELETED, 0) = 0
  AND COALESCE(si.CANCELED, 0) = 0
  AND COALESCE(si.REJECT, 0) = 0]]
end

local function sales_quantity_case_sql()
    return [[
        CASE
            WHEN COALESCE(sip.QUANTITY_CONFIRMED, 0) >= ]] .. tostring(MONEY_SCALE) .. [[
                THEN COALESCE(sip.QUANTITY_CONFIRMED, 0) / ]] .. tostring(MONEY_SCALE) .. [[
            WHEN COALESCE(sip.QUANTITY_CONFIRMED, 0) > 0
                THEN COALESCE(sip.QUANTITY_CONFIRMED, 0)
            WHEN COALESCE(sip.QUANTITY, 0) >= ]] .. tostring(MONEY_SCALE) .. [[
                THEN COALESCE(sip.QUANTITY, 0) / ]] .. tostring(MONEY_SCALE) .. [[
            WHEN COALESCE(sip.QUANTITY, 0) > 0
                THEN COALESCE(sip.QUANTITY, 0)
            WHEN COALESCE(sip.QUANTITY_SEC, 0) >= ]] .. tostring(MONEY_SCALE) .. [[
                THEN COALESCE(sip.QUANTITY_SEC, 0) / ]] .. tostring(MONEY_SCALE) .. [[
            ELSE COALESCE(sip.QUANTITY_SEC, 0)
        END]]
end

local function normalize_entity_id(value)
    if value == nil then
        return nil
    end
    return tonumber(value) or value
end

local function get_map_value(map, key)
    if map == nil or key == nil then
        return nil
    end
    local normalized = normalize_entity_id(key)
    return map[normalized] or map[tostring(normalized)] or map[key]
end

local function set_map_value(map, key, value)
    local normalized = normalize_entity_id(key)
    if normalized ~= nil then
        map[normalized] = value
    end
end

local function normalize_money_value(value)
    local n = tonumber(value) or 0
    if n <= 0 then
        return 0
    end
    if n >= MONEY_SCALE then
        return n / MONEY_SCALE
    end
    return n
end

local function purchase_invoice_filter_sql()
    return [[
  COALESCE(pi.DELETED, 0) = 0
  AND COALESCE(pi.CANCELED, 0) = 0
  AND COALESCE(pi.REJECT, 0) = 0]]
end


local function append_sales_date_filters(where_parts, params)
    local has_start = start_jalali ~= nil or is_filetime(start_date)
    local has_end = end_jalali ~= nil or is_filetime(end_date)

    if not has_start and not has_end then
        table.insert(where_parts,
            "si.RUN_DATE >= ((UNIX_TIMESTAMP() - (90 * 86400)) + 11644473600) * 10000000")
        return
    end

    if start_jalali ~= nil then
        table.insert(where_parts, "REPORT_FN_JDATE(si.RUN_DATE, '-') >= ?")
        table.insert(params, start_jalali)
    elseif is_filetime(start_date) then
        table.insert(where_parts, "si.RUN_DATE >= ?")
        table.insert(params, tonumber(start_date))
    end

    if end_jalali ~= nil then
        table.insert(where_parts, "REPORT_FN_JDATE(si.RUN_DATE, '-') <= ?")
        table.insert(params, end_jalali)
    elseif is_filetime(end_date) then
        table.insert(where_parts, "si.RUN_DATE <= ?")
        table.insert(params, tonumber(end_date))
    end
end

local function fetch_sales_by_product_code(product_codes, with_date_filter)
    if product_codes == nil or #product_codes == 0 then
        return {}
    end

    local normalized_codes = {}
    for _, code in ipairs(product_codes) do
        local normalized = normalize_product_code(code)
        if normalized ~= nil then
            table.insert(normalized_codes, normalized)
        end
    end
    normalized_codes = dedupe_codes(normalized_codes)
    if #normalized_codes == 0 then
        return {}
    end

    local code_in_clause = build_in_clause(normalized_codes)
    local code_params = {}
    local where_parts = { sales_invoice_filter_sql() }
    if with_date_filter then
        append_sales_date_filters(where_parts, code_params)
    end
    table.insert(where_parts, "TRIM(wp.FULL_CODE) IN (" .. code_in_clause .. ")")
    append_in_params(code_params, normalized_codes)

    local sales_query = [[
SELECT
    TRIM(wp.FULL_CODE) AS FULL_CODE,
    SUM(]] .. sales_quantity_case_sql() .. [[) AS sales_quantity
FROM sales_invoice_product sip
INNER JOIN sales_invoice si
    ON si.ID = sip.INVOICE_ID
INNER JOIN wh_product wp
    ON wp.id = COALESCE(NULLIF(sip.PRODUCT_ID, 0), NULLIF(sip.product_id_info, 0))
WHERE ]] .. table.concat(where_parts, "\n  AND ") .. [[
GROUP BY TRIM(wp.FULL_CODE)
]]

    local sales_rows = fetch_rows(sales_query, code_params)
    local sales_by_code = {}
    if sales_rows ~= nil then
        for _, row in ipairs(sales_rows) do
            local code = normalize_product_code(row[1])
            if code ~= nil then
                sales_by_code[code] = (sales_by_code[code] or 0) + (tonumber(row[2]) or 0)
            end
        end
    end
    return sales_by_code
end

local function format_thousands(value)
    local n = math.floor(math.abs(value) + 0.5)
    local s = tostring(n)
    local grouped = s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    if value < 0 then
        return "-" .. grouped
    end
    return grouped
end

local function fmt_money(value)
    local n = tonumber(value)
    if n == nil or n <= 0 then
        return "—"
    end
    return tostring(math.floor(n + 0.5))
end

local function fmt_total_cost(value)
    local n = tonumber(value)
    if n == nil or n <= 0 then
        return "—"
    end
    return format_thousands(n)
end

local function empty_cost_stats()
    return {
        declared_cost = 0,
        replacement_value = 0,
        parts_cost = 0,
        total_cost = 0
    }
end

local function finalize_cost_stats(stats)
    stats.declared_cost = tonumber(stats.declared_cost) or 0
    stats.replacement_value = tonumber(stats.replacement_value) or 0
    stats.parts_cost = tonumber(stats.parts_cost) or 0
    stats.total_cost = stats.declared_cost + stats.replacement_value + stats.parts_cost
    return stats
end

local function collect_service_request_ids(replacements)
    local ids = {}
    local seen = {}
    for _, entry in ipairs(replacements) do
        local id = normalize_entity_id(entry.service_request_id)
        if id ~= nil and not seen[id] then
            seen[id] = true
            table.insert(ids, id)
        end
    end
    return ids
end

local function merge_product_ids(existing_ids, extra_ids)
    local seen = {}
    local merged = {}
    for _, id in ipairs(existing_ids or {}) do
        local normalized = normalize_entity_id(id)
        if normalized ~= nil and not seen[normalized] then
            seen[normalized] = true
            table.insert(merged, normalized)
        end
    end
    for _, id in ipairs(extra_ids or {}) do
        local normalized = normalize_entity_id(id)
        if normalized ~= nil and not seen[normalized] then
            seen[normalized] = true
            table.insert(merged, normalized)
        end
    end
    return merged
end

local function resolve_product_ids_by_codes(product_codes)
    local id_by_code = {}
    local ids = {}
    local seen = {}
    if product_codes == nil or #product_codes == 0 then
        return id_by_code, ids
    end

    local normalized_codes = {}
    for _, code in ipairs(product_codes) do
        local normalized = normalize_product_code(code)
        if normalized ~= nil then
            table.insert(normalized_codes, normalized)
        end
    end
    normalized_codes = dedupe_codes(normalized_codes)
    if #normalized_codes == 0 then
        return id_by_code, ids
    end

    local code_in_clause = build_in_clause(normalized_codes)
    local rows = fetch_rows(
        "SELECT id, TRIM(FULL_CODE) AS product_code FROM wh_product WHERE TRIM(FULL_CODE) IN ("
            .. code_in_clause .. ")",
        normalized_codes
    )
    if rows ~= nil then
        for _, row in ipairs(rows) do
            local product_id = normalize_entity_id(row[1])
            local code = normalize_product_code(row[2])
            if product_id ~= nil and code ~= nil then
                id_by_code[code] = product_id
                if not seen[product_id] then
                    seen[product_id] = true
                    table.insert(ids, product_id)
                end
            end
        end
    end
    return id_by_code, ids
end

local function build_product_family_maps(product_codes)
    local id_by_code = {}
    local family_ids_by_code = {}
    local all_family_ids = {}
    local seen_all = {}

    if product_codes == nil or #product_codes == 0 then
        return id_by_code, family_ids_by_code, all_family_ids
    end

    local normalized_codes = {}
    for _, code in ipairs(product_codes) do
        local normalized = normalize_product_code(code)
        if normalized ~= nil then
            table.insert(normalized_codes, normalized)
        end
    end
    normalized_codes = dedupe_codes(normalized_codes)
    if #normalized_codes == 0 then
        return id_by_code, family_ids_by_code, all_family_ids
    end

    local code_in_clause = build_in_clause(normalized_codes)
    local rows = fetch_rows(
        [[SELECT
    TRIM(wp_anchor.FULL_CODE) AS FULL_CODE,
    wp_anchor.id AS anchor_id,
    wp_family.id AS family_id
FROM wh_product wp_anchor
INNER JOIN wh_product wp_family ON (
    wp_family.id = wp_anchor.id
    OR wp_family.id = wp_anchor.PARENT
    OR wp_family.PARENT = wp_anchor.id
    OR (
        COALESCE(wp_anchor.PARENT, 0) > 0
        AND wp_family.PARENT = wp_anchor.PARENT
    )
    OR TRIM(wp_family.FULL_CODE) = TRIM(wp_anchor.FULL_CODE)
)
WHERE TRIM(wp_anchor.FULL_CODE) IN (]] .. code_in_clause .. [[)]],
        normalized_codes
    )

    if rows ~= nil then
        for _, row in ipairs(rows) do
            local code = normalize_product_code(row[1])
            local anchor_id = normalize_entity_id(row[2])
            local family_id = normalize_entity_id(row[3])
            if code ~= nil and family_id ~= nil then
                if id_by_code[code] == nil and anchor_id ~= nil then
                    id_by_code[code] = anchor_id
                end

                local family_ids = family_ids_by_code[code]
                if family_ids == nil then
                    family_ids = {}
                    family_ids_by_code[code] = family_ids
                end

                local seen_for_code = {}
                for _, existing_id in ipairs(family_ids) do
                    seen_for_code[existing_id] = true
                end
                if not seen_for_code[family_id] then
                    table.insert(family_ids, family_id)
                end
                if not seen_all[family_id] then
                    seen_all[family_id] = true
                    table.insert(all_family_ids, family_id)
                end
            end
        end
    end

    return id_by_code, family_ids_by_code, all_family_ids
end

local PRODUCT_ID_BATCH_SIZE = 200

local function chunk_entity_ids(ids, batch_size)
    local chunks = {}
    local current = {}
    for _, id in ipairs(ids or {}) do
        local normalized = normalize_entity_id(id)
        if normalized ~= nil then
            table.insert(current, normalized)
            if #current >= batch_size then
                table.insert(chunks, current)
                current = {}
            end
        end
    end
    if #current > 0 then
        table.insert(chunks, current)
    end
    return chunks
end

local function fetch_warranty_counts_by_product_ids(product_ids, current_filetime)
    local counts_by_product = {}
    if product_ids == nil or #product_ids == 0 then
        return counts_by_product
    end

    for _, batch in ipairs(chunk_entity_ids(product_ids, PRODUCT_ID_BATCH_SIZE)) do
        local id_in_clause = build_in_clause(batch)
        local params = { current_filetime }
        for _, id in ipairs(batch) do
            table.insert(params, id)
        end

        local rows = fetch_rows([[
SELECT
    gs.PRODUCT_ID,
    COUNT(DISTINCT gs.ID) AS warranty_issued_count,
    COUNT(DISTINCT CASE
        WHEN gs.END_DATE IS NULL OR gs.END_DATE = 0 OR gs.END_DATE > ?
        THEN gs.ID
    END) AS active_warranty_count
FROM pm_guaranty_serial gs
WHERE gs.PRODUCT_ID IN (]] .. id_in_clause .. [[)
GROUP BY gs.PRODUCT_ID
]], params)

        if rows ~= nil then
            for _, row in ipairs(rows) do
                local product_id = normalize_entity_id(row[1])
                if product_id ~= nil then
                    counts_by_product[product_id] = {
                        warranty_issued_count = tonumber(row[2]) or 0,
                        active_warranty_count = tonumber(row[3]) or 0
                    }
                end
            end
        end
    end

    return counts_by_product
end

local function fetch_receipt_counts_by_product_ids(product_ids)
    local counts_by_product = {}
    if product_ids == nil or #product_ids == 0 then
        return counts_by_product
    end

    for _, batch in ipairs(chunk_entity_ids(product_ids, PRODUCT_ID_BATCH_SIZE)) do
        local id_in_clause = build_in_clause(batch)
        local params = {}
        for _, id in ipairs(batch) do
            table.insert(params, id)
        end

        local rows = fetch_rows([[
SELECT
    sr.PRODUCT_ID,
    COUNT(DISTINCT sr.ID) AS receipt_count
FROM pm_service_request sr
WHERE sr.PRODUCT_ID IN (]] .. id_in_clause .. [[)
  AND sr.FINAL_STATUS <> 5
GROUP BY sr.PRODUCT_ID
]], params)

        if rows ~= nil then
            for _, row in ipairs(rows) do
                local product_id = normalize_entity_id(row[1])
                if product_id ~= nil then
                    counts_by_product[product_id] = tonumber(row[2]) or 0
                end
            end
        end
    end

    return counts_by_product
end

-- تعمیر شده در بازه (بدون تعویض): FINAL_STATUS IN (3,6) = «کامل (تعمیر شده)» / «آماده تحویل (تعمیر شده)»
local function fetch_repaired_counts_by_product_ids(product_ids)
    local counts_by_product = {}
    if product_ids == nil or #product_ids == 0 then
        return counts_by_product
    end

    for _, batch in ipairs(chunk_entity_ids(product_ids, PRODUCT_ID_BATCH_SIZE)) do
        local id_in_clause = build_in_clause(batch)
        local where_parts = {
            "sr.PRODUCT_ID IN (" .. id_in_clause .. ")",
            "sr.FINAL_STATUS IN (3, 6)"
        }
        local params = {}
        for _, id in ipairs(batch) do
            table.insert(params, id)
        end
        append_date_filters(where_parts, params, "sr.BREAK_DOWN_DATE")

        local rows = fetch_rows([[
SELECT
    sr.PRODUCT_ID,
    COUNT(DISTINCT sr.ID) AS repaired_count
FROM pm_service_request sr
WHERE ]] .. table.concat(where_parts, "\n  AND ") .. [[
GROUP BY sr.PRODUCT_ID
]], params)

        if rows ~= nil then
            for _, row in ipairs(rows) do
                local product_id = normalize_entity_id(row[1])
                if product_id ~= nil then
                    counts_by_product[product_id] = tonumber(row[2]) or 0
                end
            end
        end
    end

    return counts_by_product
end

local function sum_family_repaired_count(family_ids, repaired_by_product)
    local repaired = 0
    for _, product_id in ipairs(family_ids or {}) do
        repaired = repaired + (get_map_value(repaired_by_product, product_id) or 0)
    end
    return repaired
end

local function sum_family_warranty_stats(family_ids, warranty_by_product)
    local issued = 0
    local active = 0
    for _, product_id in ipairs(family_ids or {}) do
        local stats = get_map_value(warranty_by_product, product_id)
        if stats ~= nil then
            issued = issued + (stats.warranty_issued_count or 0)
            active = active + (stats.active_warranty_count or 0)
        end
    end
    return issued, active
end

local function sum_family_receipt_count(family_ids, receipt_by_product)
    local receipts = 0
    for _, product_id in ipairs(family_ids or {}) do
        receipts = receipts + (get_map_value(receipt_by_product, product_id) or 0)
    end
    return receipts
end

local function family_ids_for_code(code, family_ids_by_code, id_by_code)
    local family_ids = family_ids_by_code[code]
    if family_ids ~= nil and #family_ids > 0 then
        return family_ids
    end

    local direct_id = id_by_code[code]
    if direct_id ~= nil then
        return { direct_id }
    end

    return {}
end

local function build_cogs_by_code(family_ids_by_code, cogs_by_product)
    local cogs_by_code = {}
    for code, family_ids in pairs(family_ids_by_code) do
        local best_unit = 0
        for _, product_id in ipairs(family_ids) do
            local unit_cogs = get_map_value(cogs_by_product, product_id) or 0
            if unit_cogs > best_unit then
                best_unit = unit_cogs
            end
        end
        if best_unit > 0 then
            cogs_by_code[code] = best_unit
        end
    end
    return cogs_by_code
end

local function get_unit_cogs(cogs_by_product, cogs_by_code, product_id, product_code, family_ids_by_code)
    if product_id ~= nil then
        local direct = get_map_value(cogs_by_product, product_id)
        if direct ~= nil and direct > 0 then
            return direct
        end
    end

    local code = normalize_product_code(product_code)
    if code ~= nil and cogs_by_code[code] ~= nil and cogs_by_code[code] > 0 then
        return cogs_by_code[code]
    end

    if code ~= nil and family_ids_by_code ~= nil then
        local family_ids = family_ids_by_code[code]
        if family_ids ~= nil then
            for _, family_id in ipairs(family_ids) do
                local unit_cogs = get_map_value(cogs_by_product, family_id) or 0
                if unit_cogs > 0 then
                    return unit_cogs
                end
            end
        end
    end

    return 0
end

local function apply_entry_cost_fallback(entry, cogs_by_product, cogs_by_code, family_ids_by_code)
    if (entry.total_cost or 0) > 0 then
        return
    end

    local original_code = normalize_product_code(entry.original_product_code)
    local original_unit = get_unit_cogs(
        cogs_by_product,
        cogs_by_code,
        nil,
        original_code,
        family_ids_by_code
    )
    if original_unit <= 0 then
        return
    end

    entry.declared_cost = math.floor(original_unit + 0.5)
    entry.replacement_value = 0
    for _, product in ipairs(entry.replaced_products or {}) do
        local repl_unit = get_unit_cogs(
            cogs_by_product,
            cogs_by_code,
            nil,
            product.product_code,
            family_ids_by_code
        )
        entry.replacement_value = entry.replacement_value
            + math.floor(multiply_cogs(repl_unit, product.amount) + 0.5)
    end
    entry.total_cost = entry.declared_cost + entry.replacement_value + (entry.parts_cost or 0)
end

local function collect_product_codes_from_replacements(replacements)
    local codes = {}
    local seen = {}
    for _, entry in ipairs(replacements or {}) do
        local orig = normalize_product_code(entry.original_product_code)
        if orig ~= nil and not seen[orig] then
            seen[orig] = true
            table.insert(codes, orig)
        end
        for _, product in ipairs(entry.replaced_products or {}) do
            local repl = normalize_product_code(product.product_code)
            if repl ~= nil and not seen[repl] then
                seen[repl] = true
                table.insert(codes, repl)
            end
        end
    end
    return codes
end

local function fill_cogs_from_parents(cogs_by_product, product_ids)
    local missing_ids = {}
    for _, id in ipairs(product_ids) do
        local normalized = normalize_entity_id(id)
        if normalized ~= nil and get_map_value(cogs_by_product, normalized) == nil then
            table.insert(missing_ids, normalized)
        end
    end
    missing_ids = merge_product_ids(missing_ids, {})
    if #missing_ids == 0 then
        return
    end

    local missing_clause = build_in_clause(missing_ids)
    local parent_rows = fetch_rows(
        "SELECT id, PARENT FROM wh_product WHERE id IN (" .. missing_clause .. ") AND COALESCE(PARENT, 0) > 0",
        missing_ids
    )
    if parent_rows == nil or #parent_rows == 0 then
        return
    end

    local parent_by_child = {}
    local parent_ids = {}
    for _, row in ipairs(parent_rows) do
        local child_id = normalize_entity_id(row[1])
        local parent_id = normalize_entity_id(row[2])
        if child_id ~= nil and parent_id ~= nil then
            parent_by_child[child_id] = parent_id
            table.insert(parent_ids, parent_id)
        end
    end
    parent_ids = merge_product_ids(parent_ids, {})
    if #parent_ids == 0 then
        return
    end

    local parent_clause = build_in_clause(parent_ids)
    local parent_params = {}
    for _, id in ipairs(parent_ids) do
        table.insert(parent_params, id)
    end

    local parent_cardindex_rows = fetch_rows(
        [[SELECT PRODUCT_ID, MAX(COALESCE(RATE_CARDINDEX, 0)) AS RATE_CARDINDEX
FROM wh_product_cardindex
WHERE PRODUCT_ID IN (]] .. parent_clause .. [[)
GROUP BY PRODUCT_ID
HAVING MAX(COALESCE(RATE_CARDINDEX, 0)) > 0]],
        parent_params
    )
    local parent_cogs = {}
    if parent_cardindex_rows ~= nil then
        for _, row in ipairs(parent_cardindex_rows) do
            local product_id = normalize_entity_id(row[1])
            local unit_cogs = normalize_money_value(row[2])
            if product_id ~= nil and unit_cogs > 0 then
                set_map_value(parent_cogs, product_id, unit_cogs)
            end
        end
    end

    local still_missing_parents = {}
    for _, parent_id in ipairs(parent_ids) do
        if get_map_value(parent_cogs, parent_id) == nil then
            table.insert(still_missing_parents, parent_id)
        end
    end
    if #still_missing_parents > 0 then
        local sm_clause = build_in_clause(still_missing_parents)
        local sm_params = {}
        for _, id in ipairs(still_missing_parents) do
            table.insert(sm_params, id)
        end
        local purchase_rows = fetch_rows(
            [[SELECT
    pip.PRODUCT_ID,
    SUM(
        COALESCE(
            NULLIF(pip.fee_sales, 0),
            NULLIF(pip.FEE, 0),
            CASE
                WHEN COALESCE(pip.PRICE, 0) > 0
                     AND COALESCE(NULLIF(pip.QUANTITY, 0), NULLIF(pip.QUANTITY_SEC, 0), 0) > 0
                THEN pip.PRICE / COALESCE(NULLIF(pip.QUANTITY, 0), pip.QUANTITY_SEC, 1)
                ELSE 0
            END
        ) * GREATEST(COALESCE(NULLIF(pip.QUANTITY, 0), NULLIF(pip.QUANTITY_SEC, 0), 1), 1)
    ) / NULLIF(SUM(GREATEST(COALESCE(NULLIF(pip.QUANTITY, 0), NULLIF(pip.QUANTITY_SEC, 0), 1), 1)), 0) AS raw_unit_cost
FROM purchase_invoice_product pip
INNER JOIN purchase_invoice pi
    ON pi.ID = pip.INVOICE_ID
WHERE ]] .. purchase_invoice_filter_sql() .. [[
  AND pip.PRODUCT_ID IN (]] .. sm_clause .. [[)
GROUP BY pip.PRODUCT_ID
HAVING raw_unit_cost > 0]],
            sm_params
        )
        if purchase_rows ~= nil then
            for _, row in ipairs(purchase_rows) do
                local product_id = normalize_entity_id(row[1])
                local unit_cogs = normalize_money_value(row[2])
                if product_id ~= nil and unit_cogs > 0 then
                    set_map_value(parent_cogs, product_id, unit_cogs)
                end
            end
        end
    end

    for child_id, parent_id in pairs(parent_by_child) do
        local unit_cogs = get_map_value(parent_cogs, parent_id)
        if unit_cogs ~= nil and unit_cogs > 0 then
            set_map_value(cogs_by_product, child_id, unit_cogs)
        end
    end
end

local function load_product_unit_cogs(product_ids, product_codes)
    local cogs_by_product = {}
    local _, ids_from_codes = resolve_product_ids_by_codes(product_codes)
    local normalized_ids = merge_product_ids(product_ids, ids_from_codes)
    if #normalized_ids == 0 then
        return cogs_by_product
    end

    local id_in_clause = build_in_clause(normalized_ids)
    local id_params = {}
    for _, id in ipairs(normalized_ids) do
        table.insert(id_params, id)
    end

    local cardindex_rows = fetch_rows(
        [[SELECT PRODUCT_ID, MAX(COALESCE(RATE_CARDINDEX, 0)) AS RATE_CARDINDEX
FROM wh_product_cardindex
WHERE PRODUCT_ID IN (]] .. id_in_clause .. [[)
GROUP BY PRODUCT_ID
HAVING MAX(COALESCE(RATE_CARDINDEX, 0)) > 0]],
        id_params
    )
    if cardindex_rows ~= nil then
        for _, row in ipairs(cardindex_rows) do
            local product_id = normalize_entity_id(row[1])
            local unit_cogs = normalize_money_value(row[2])
            if product_id ~= nil and unit_cogs > 0 then
                set_map_value(cogs_by_product, product_id, unit_cogs)
            end
        end
    end

    local purchase_query = [[
SELECT
    pip.PRODUCT_ID,
    SUM(
        COALESCE(
            NULLIF(pip.fee_sales, 0),
            NULLIF(pip.FEE, 0),
            CASE
                WHEN COALESCE(pip.PRICE, 0) > 0
                     AND COALESCE(NULLIF(pip.QUANTITY, 0), NULLIF(pip.QUANTITY_SEC, 0), 0) > 0
                THEN pip.PRICE / COALESCE(NULLIF(pip.QUANTITY, 0), pip.QUANTITY_SEC, 1)
                ELSE 0
            END
        ) * GREATEST(COALESCE(NULLIF(pip.QUANTITY, 0), NULLIF(pip.QUANTITY_SEC, 0), 1), 1)
    ) / NULLIF(SUM(GREATEST(COALESCE(NULLIF(pip.QUANTITY, 0), NULLIF(pip.QUANTITY_SEC, 0), 1), 1)), 0) AS raw_unit_cost
FROM purchase_invoice_product pip
INNER JOIN purchase_invoice pi
    ON pi.ID = pip.INVOICE_ID
WHERE ]] .. purchase_invoice_filter_sql() .. [[
  AND pip.PRODUCT_ID IN (]] .. id_in_clause .. [[)
GROUP BY pip.PRODUCT_ID
HAVING raw_unit_cost > 0
]]

    local purchase_rows = fetch_rows(purchase_query, id_params)
    if purchase_rows ~= nil then
        for _, row in ipairs(purchase_rows) do
            local product_id = normalize_entity_id(row[1])
            local unit_cogs = normalize_money_value(row[2])
            if product_id ~= nil and unit_cogs > 0 and get_map_value(cogs_by_product, product_id) == nil then
                set_map_value(cogs_by_product, product_id, unit_cogs)
            end
        end
    end

    local missing_ids = {}
    for _, id in ipairs(normalized_ids) do
        if get_map_value(cogs_by_product, id) == nil then
            table.insert(missing_ids, id)
        end
    end

    if #missing_ids > 0 then
        local missing_clause = build_in_clause(missing_ids)
        local missing_params = {}
        for _, id in ipairs(missing_ids) do
            table.insert(missing_params, id)
        end
        local price_rows = fetch_rows(
            "SELECT PRODUCT_ID, MAX(COALESCE(PRICE, 0)) AS PRICE FROM wh_product_price WHERE PRODUCT_ID IN ("
                .. missing_clause .. ") GROUP BY PRODUCT_ID HAVING MAX(COALESCE(PRICE, 0)) > 0",
            missing_params
        )
        if price_rows ~= nil then
            for _, row in ipairs(price_rows) do
                local product_id = normalize_entity_id(row[1])
                local unit_cogs = normalize_money_value(row[2])
                if product_id ~= nil and unit_cogs > 0 then
                    set_map_value(cogs_by_product, product_id, unit_cogs)
                end
            end
        end
    end

    fill_cogs_from_parents(cogs_by_product, normalized_ids)

    return cogs_by_product
end

local function normalize_quantity_value(value)
    local n = tonumber(value) or 0
    if n <= 0 then
        return 0
    end
    if n >= MONEY_SCALE then
        return n / MONEY_SCALE
    end
    return n
end

local function multiply_cogs(unit_cogs, quantity_raw)
    return normalize_money_value(unit_cogs) * normalize_quantity_value(quantity_raw)
end

local function is_delivered_swap_detail(swap_type, swap_type_label)
    local swap_type_num = tonumber(swap_type)
    if swap_type_num == 0 then
        return true
    end
    if swap_type_label ~= nil and tostring(swap_type_label):find("تحویلی", 1, true) then
        return true
    end
    return false
end

local function is_replacement_swap_detail(swap_type, swap_type_label, product_code)
    if is_delivered_swap_detail(swap_type, swap_type_label) then
        return false
    end

    local code = normalize_product_code(product_code)
    if code ~= nil and code ~= "" then
        return true
    end

    local swap_type_num = tonumber(swap_type)
    if swap_type_num == 1 then
        return true
    end
    if swap_type_label ~= nil and tostring(swap_type_label):find("جایگزین", 1, true) then
        return true
    end
    return false
end

local function append_replaced_product_entry(products, product_code, product_name, amount, swap_type, swap_type_label)
    local code = normalize_product_code(product_code) or product_code
    if code == nil or code == "" then
        return
    end

    for _, existing in ipairs(products) do
        local existing_code = normalize_product_code(existing.product_code) or existing.product_code
        if existing_code == code then
            existing.amount = (tonumber(existing.amount) or 0) + (tonumber(amount) or 0)
            if (existing.product_name == nil or existing.product_name == "")
                and product_name ~= nil and product_name ~= "" then
                existing.product_name = product_name
            end
            return
        end
    end

    table.insert(products, {
        swap_type = swap_type,
        swap_type_label = swap_type_label,
        amount = amount,
        product_code = code,
        product_name = product_name
    })
end

local function load_replaced_products_by_service_request(service_request_ids)
    local products_by_sr = {}
    if service_request_ids == nil or #service_request_ids == 0 then
        return products_by_sr
    end

    local sr_in_clause = build_in_clause(service_request_ids)
    local sr_params = {}
    for _, id in ipairs(service_request_ids) do
        table.insert(sr_params, id)
    end

    local rows = fetch_rows([[
SELECT
    ps.SERVICE_REQUEST_ID,
    psd.SWAP_TYPE,
    CASE
        WHEN psd.SWAP_TYPE = 0 THEN 'کالای تحویلی'
        WHEN psd.SWAP_TYPE = 1 THEN 'کالای جایگزین'
        WHEN psd.SWAP_TYPE IS NULL THEN NULL
        ELSE 'سایر'
    END,
    psd.AMOUNT,
    COALESCE(repl.FULL_CODE, wp_direct.FULL_CODE) AS product_code,
    COALESCE(repl.full_name, wp_direct.full_name) AS product_name
FROM pm_swap ps
INNER JOIN pm_swap_detail psd
    ON psd.SWAP_ID = ps.ID
LEFT JOIN wh_product repl
    ON repl.id = psd.PRODUCT_ID
LEFT JOIN wh_product wp_direct
    ON wp_direct.id = psd.PRODUCT_ID
WHERE ps.SERVICE_REQUEST_ID IN (]] .. sr_in_clause .. [[)
]], sr_params)

    if rows == nil then
        return products_by_sr
    end

    for _, row in ipairs(rows) do
        local sr_id = normalize_entity_id(row[1])
        local swap_type = tonumber(row[2]) or row[2]
        local swap_type_label = row[3]
        local product_code = row[5]
        if sr_id ~= nil and is_replacement_swap_detail(swap_type, swap_type_label, product_code) then
            local list = get_map_value(products_by_sr, sr_id)
            if list == nil then
                list = {}
                set_map_value(products_by_sr, sr_id, list)
            end
            append_replaced_product_entry(
                list,
                product_code,
                row[6],
                row[4],
                swap_type,
                swap_type_label
            )
        end
    end

    return products_by_sr
end

local function attach_replaced_products(replacements, products_by_sr)
    for _, entry in ipairs(replacements or {}) do
        local sr_id = normalize_entity_id(entry.service_request_id)
        local loaded = get_map_value(products_by_sr, sr_id)
        if loaded ~= nil and #loaded > 0 then
            if entry.replaced_products == nil then
                entry.replaced_products = {}
            end

            if #entry.replaced_products == 0 then
                entry.replaced_products = loaded
            else
                for _, product in ipairs(loaded) do
                    append_replaced_product_entry(
                        entry.replaced_products,
                        product.product_code,
                        product.product_name,
                        product.amount,
                        product.swap_type,
                        product.swap_type_label
                    )
                end
            end
        end
    end
end

--[[
  تایید فیزیکی تعویض از انبار — DO NOT BREAK
  - pm_swap/pm_swap_detail فقط "ثبت شده به عنوان تعویض" را می‌گوید؛ خروج واقعی کالا از
    انبار در WH_REQ_PRODUCT/wh_req_product_details (ستون STOCK_ID = انبار) ثبت می‌شود.
  - بدون این فیلتر، تعداد تعویض بیشتر از واقعیت کاردکس انبار می‌شود (رکوردهایی که در
    pm_swap ثبت شده‌اند ولی هرگز کالا واقعاً از انبار خارج نشده).
  - تست شد: کالای 31030150001 در بازه 1405-01-01..1405-04-20 → کاردکس=47،
    قبل از این فیلتر بات=49 (بعد از فیکس تکرار sr)، بعد از این فیلتر=47.
]]
local function filter_confirmed_replacements(replacements)
    local sr_ids = {}
    local codes = {}
    local seen_codes = {}
    for _, entry in ipairs(replacements) do
        local sr_id = normalize_entity_id(entry.service_request_id)
        if sr_id ~= nil then
            table.insert(sr_ids, sr_id)
        end
        for _, product in ipairs(entry.replaced_products or {}) do
            local code = normalize_product_code(product.product_code)
            if code ~= nil and not seen_codes[code] then
                seen_codes[code] = true
                table.insert(codes, code)
            end
        end
    end

    if #sr_ids == 0 or #codes == 0 then
        return replacements
    end

    local sr_clause = build_in_clause(sr_ids)
    local code_clause = build_in_clause(codes)
    local params = {}
    for _, id in ipairs(sr_ids) do
        table.insert(params, id)
    end
    for _, code in ipairs(codes) do
        table.insert(params, code)
    end

    local confirm_rows = fetch_rows([[
SELECT DISTINCT rp.REF_ID, TRIM(wp.FULL_CODE)
FROM WH_REQ_PRODUCT rp
INNER JOIN wh_req_product_details rpd
    ON rpd.REQUEST_ID = rp.ID
INNER JOIN wh_product wp
    ON wp.id = rpd.PRODUCT_ID
WHERE COALESCE(rp.DELETED, 0) = 0
  AND REPLACE(COALESCE(rpd.reason_of_cancellation, ''), ' ', '') = ''
  AND rp.REF_ID IN (]] .. sr_clause .. [[)
  AND TRIM(wp.FULL_CODE) IN (]] .. code_clause .. [[)
]], params)

    if confirm_rows == nil then
        -- خطا در کوئری تاییدیه انبار: فهرست اصلی را دست‌نخورده برگردان (fail-open)
        return replacements
    end

    local confirmed = {}
    for _, row in ipairs(confirm_rows) do
        local sr_id = normalize_entity_id(row[1])
        local code = normalize_product_code(row[2])
        if sr_id ~= nil and code ~= nil then
            if confirmed[sr_id] == nil then
                confirmed[sr_id] = {}
            end
            confirmed[sr_id][code] = true
        end
    end

    local filtered = {}
    for _, entry in ipairs(replacements) do
        local sr_id = normalize_entity_id(entry.service_request_id)
        local confirmed_for_sr = confirmed[sr_id]
        local kept_products = {}
        if confirmed_for_sr ~= nil then
            for _, product in ipairs(entry.replaced_products or {}) do
                local code = normalize_product_code(product.product_code)
                if code ~= nil and confirmed_for_sr[code] then
                    table.insert(kept_products, product)
                end
            end
        end
        if #kept_products > 0 then
            entry.replaced_products = kept_products
            table.insert(filtered, entry)
        end
    end

    return filtered
end

local function merge_matrix_replaced_products(matrix_row, replaced_products)
    local seen = matrix_row._replaced_seen
    if seen == nil then
        seen = {}
        matrix_row._replaced_seen = seen
        matrix_row.replaced_products_summary = {}
    end

    for _, product in ipairs(replaced_products or {}) do
        local code = normalize_product_code(product.product_code) or product.product_code
        if code ~= nil and code ~= "" and not seen[code] then
            seen[code] = true
            table.insert(matrix_row.replaced_products_summary, {
                product_code = code,
                product_name = product.product_name,
                amount = product.amount
            })
        end
    end
end

local function format_matrix_replaced_products(matrix_row)
    local parts = {}
    for _, product in ipairs(matrix_row.replaced_products_summary or {}) do
        local label = product.product_code or "—"
        if product.product_name ~= nil and product.product_name ~= "" then
            label = label .. " | " .. product.product_name
        end
        if product.amount ~= nil and tonumber(product.amount) and tonumber(product.amount) > 0 then
            label = label .. " (" .. tostring(product.amount) .. ")"
        end
        table.insert(parts, label)
    end
    if #parts == 0 then
        return "—"
    end
    return table.concat(parts, " ؛ ")
end

local function add_replacement_line_cost(stats, line, cogs_by_product, cogs_by_code, family_ids_by_code, code_to_product_id)
    local swap_type = tonumber(line.swap_type)
    if swap_type ~= 1 then
        return
    end

    local product_id = normalize_entity_id(line.product_id)
    if product_id == nil or product_id == 0 then
        local code = normalize_product_code(line.product_code)
        if code ~= nil and code_to_product_id ~= nil then
            product_id = code_to_product_id[code]
        end
    end

    local unit_cogs = get_unit_cogs(
        cogs_by_product,
        cogs_by_code,
        product_id,
        line.product_code,
        family_ids_by_code
    )
    if unit_cogs <= 0 then
        return
    end

    stats.replacement_value = stats.replacement_value + multiply_cogs(unit_cogs, line.amount)
end

local function load_replacement_costs(service_request_ids, replacements)
    if service_request_ids == nil or #service_request_ids == 0 then
        return {
            costs_by_sr = {},
            cogs_by_product = {},
            cogs_by_code = {},
            family_ids_by_code = {}
        }
    end

    local costs_by_sr = {}
    for _, id in ipairs(service_request_ids) do
        set_map_value(costs_by_sr, id, empty_cost_stats())
    end

    local sr_in_clause = build_in_clause(service_request_ids)
    local sr_params = {}
    for _, id in ipairs(service_request_ids) do
        table.insert(sr_params, id)
    end

    local product_ids = {}
    local seen_product_ids = {}
    local codes_from_entries = collect_product_codes_from_replacements(replacements)
    local code_to_product_id, ids_from_codes = resolve_product_ids_by_codes(codes_from_entries)
    local _, family_ids_by_code, all_family_ids = build_product_family_maps(codes_from_entries)
    local original_code_by_sr = {}

    for _, entry in ipairs(replacements or {}) do
        local sr_id = normalize_entity_id(entry.service_request_id)
        local code = normalize_product_code(entry.original_product_code)
        if sr_id ~= nil and code ~= nil then
            set_map_value(original_code_by_sr, sr_id, code)
        end
    end

    local original_rows = fetch_rows(
        "SELECT ID, PRODUCT_ID FROM pm_service_request WHERE ID IN (" .. sr_in_clause .. ")",
        sr_params
    )
    local original_product_by_sr = {}
    if original_rows ~= nil then
        for _, row in ipairs(original_rows) do
            local sr_id = normalize_entity_id(row[1])
            local product_id = normalize_entity_id(row[2])
            if product_id == nil or product_id == 0 then
                local code = get_map_value(original_code_by_sr, sr_id)
                if code ~= nil then
                    product_id = code_to_product_id[code]
                end
            end
            set_map_value(original_product_by_sr, sr_id, product_id)
            if product_id ~= nil and not seen_product_ids[product_id] then
                seen_product_ids[product_id] = true
                table.insert(product_ids, product_id)
            end
        end
    end

    local replacement_rows = fetch_rows([[
SELECT
    ps.SERVICE_REQUEST_ID,
    psd.PRODUCT_ID,
    repl.FULL_CODE,
    psd.SWAP_TYPE,
    psd.AMOUNT,
    psd.VALUE
FROM pm_swap ps
INNER JOIN pm_swap_detail psd
    ON psd.SWAP_ID = ps.ID
LEFT JOIN wh_product repl
    ON repl.id = psd.PRODUCT_ID
WHERE ps.SERVICE_REQUEST_ID IN (]] .. sr_in_clause .. [[)
]], sr_params)

    local replacement_lines_by_sr = {}
    if replacement_rows ~= nil then
        for _, row in ipairs(replacement_rows) do
            local sr_id = normalize_entity_id(row[1])
            local product_id = normalize_entity_id(row[2])
            local product_code = normalize_product_code(row[3])
            if (product_id == nil or product_id == 0) and product_code ~= nil then
                product_id = code_to_product_id[product_code]
            end
            local lines = replacement_lines_by_sr[sr_id]
            if lines == nil then
                lines = {}
                replacement_lines_by_sr[sr_id] = lines
            end
            table.insert(lines, {
                product_id = product_id,
                product_code = product_code,
                swap_type = tonumber(row[4]) or row[4],
                amount = row[5],
                value = row[6]
            })
            if product_id ~= nil and product_id ~= 0 and not seen_product_ids[product_id] then
                seen_product_ids[product_id] = true
                table.insert(product_ids, product_id)
            end
        end
    end

    local parts_query = [[
SELECT
    parts.SERVICE_REQUEST_ID,
    parts.PRODUCT_ID,
    parts.qty
FROM (
    SELECT
        sr.id AS SERVICE_REQUEST_ID,
        rpd.PRODUCT_ID,
        wp.FULL_CODE,
        COALESCE(rpd.QUANTITY_VALID_MAIN, rpd.QUANTITY_VALID, 0) AS qty
    FROM WH_REQ_PRODUCT rp
    INNER JOIN wh_req_product_details rpd
        ON rpd.REQUEST_ID = rp.ID
    INNER JOIN pm_service_request sr
        ON sr.id = rp.REF_ID
    LEFT JOIN wh_product wp
        ON wp.id = rpd.PRODUCT_ID
    WHERE rp.DELETED = 0
      AND rp.REQUEST_TYPE = 5
      AND rp.REF_TYPE = 101
      AND REPLACE(COALESCE(rpd.reason_of_cancellation, ''), ' ', '') = ''
      AND sr.id IN (]] .. sr_in_clause .. [[)

    UNION ALL

    SELECT
        sr.id AS SERVICE_REQUEST_ID,
        rpd.PRODUCT_ID,
        wp.FULL_CODE,
        COALESCE(rpd.QUANTITY_VALID_MAIN, rpd.QUANTITY_VALID, 0) AS qty
    FROM WH_REQ_PRODUCT rp
    INNER JOIN wh_req_product_details rpd
        ON rpd.REQUEST_ID = rp.ID
    INNER JOIN pm_cost_declaration_detail cd
        ON cd.ID = rp.REF_ID
    INNER JOIN pm_cost_declaration c
        ON c.ID = cd.COST_DECLARATION_ID
    INNER JOIN pm_service_request sr
        ON sr.id = c.SERVICE_REQUEST_ID
    LEFT JOIN wh_product wp
        ON wp.id = rpd.PRODUCT_ID
    WHERE rp.DELETED = 0
      AND rp.REQUEST_TYPE = 5
      AND rp.REF_TYPE = 109
      AND REPLACE(COALESCE(rpd.reason_of_cancellation, ''), ' ', '') = ''
      AND sr.id IN (]] .. sr_in_clause .. [[)
) parts
]]

    local parts_params = {}
    for _, id in ipairs(service_request_ids) do
        table.insert(parts_params, id)
    end
    for _, id in ipairs(service_request_ids) do
        table.insert(parts_params, id)
    end

    local parts_rows = fetch_rows(parts_query, parts_params)
    local parts_lines_by_sr = {}
    if parts_rows ~= nil then
        for _, row in ipairs(parts_rows) do
            local sr_id = normalize_entity_id(row[1])
            local product_id = normalize_entity_id(row[2])
            local part_code = normalize_product_code(row[3])
            if (product_id == nil or product_id == 0) and part_code ~= nil then
                product_id = code_to_product_id[part_code]
            end
            local lines = parts_lines_by_sr[sr_id]
            if lines == nil then
                lines = {}
                parts_lines_by_sr[sr_id] = lines
            end
            table.insert(lines, {
                product_id = product_id,
                qty = row[4]
            })
            if product_id ~= nil and not seen_product_ids[product_id] then
                seen_product_ids[product_id] = true
                table.insert(product_ids, product_id)
            end
        end
    end

    local cogs_by_product = load_product_unit_cogs(
        merge_product_ids(product_ids, all_family_ids),
        codes_from_entries
    )
    local cogs_by_code = build_cogs_by_code(family_ids_by_code, cogs_by_product)

    for _, sr_id_raw in ipairs(service_request_ids) do
        local sr_id = normalize_entity_id(sr_id_raw)
        local stats = get_map_value(costs_by_sr, sr_id)
        if stats == nil then
            stats = empty_cost_stats()
            set_map_value(costs_by_sr, sr_id, stats)
        end

        local original_product_id = get_map_value(original_product_by_sr, sr_id)
        local original_code = get_map_value(original_code_by_sr, sr_id)
        if original_product_id == nil or original_product_id == 0 then
            if original_code ~= nil then
                original_product_id = code_to_product_id[original_code]
            end
        end
        if original_product_id ~= nil or original_code ~= nil then
            stats.declared_cost = normalize_money_value(get_unit_cogs(
                cogs_by_product,
                cogs_by_code,
                original_product_id,
                original_code,
                family_ids_by_code
            ))
        end

        local replacement_lines = replacement_lines_by_sr[sr_id]
        if replacement_lines ~= nil then
            for _, line in ipairs(replacement_lines) do
                add_replacement_line_cost(
                    stats,
                    line,
                    cogs_by_product,
                    cogs_by_code,
                    family_ids_by_code,
                    code_to_product_id
                )
            end
        end

        local part_lines = parts_lines_by_sr[sr_id]
        if part_lines ~= nil then
            for _, line in ipairs(part_lines) do
                local unit_cogs = get_unit_cogs(
                    cogs_by_product,
                    cogs_by_code,
                    line.product_id,
                    nil,
                    family_ids_by_code
                )
                stats.parts_cost = stats.parts_cost + multiply_cogs(unit_cogs, line.qty)
            end
        end

        stats.declared_cost = math.floor(stats.declared_cost + 0.5)
        stats.replacement_value = math.floor(stats.replacement_value + 0.5)
        stats.parts_cost = math.floor(stats.parts_cost + 0.5)
        finalize_cost_stats(stats)
    end

    return {
        costs_by_sr = costs_by_sr,
        cogs_by_product = cogs_by_product,
        cogs_by_code = cogs_by_code,
        family_ids_by_code = family_ids_by_code
    }
end

local function empty_product_stats()
    return {
        warranty_issued_count = 0,
        active_warranty_count = 0,
        sales_quantity = 0,
        sales_quantity_total = 0,
        sales_quantity_in_range = 0,
        receipt_count = 0,
        repaired_in_range_count = 0,
        return_rate_percent = nil,
        direct_warranty_issued_count = 0,
        direct_active_warranty_count = 0,
        direct_receipt_count = 0,
        direct_repaired_in_range_count = 0,
        direct_return_rate_percent = nil
    }
end

local function ensure_stats_entry(stats_by_code, code)
    local normalized = normalize_product_code(code) or code
    local stats = stats_by_code[normalized]
    if stats == nil then
        stats = empty_product_stats()
        stats_by_code[normalized] = stats
    end
    return stats
end

local function load_product_sales_stats(product_codes)
    local stats_by_code = {}
    if product_codes == nil or #product_codes == 0 then
        return stats_by_code
    end

    local normalized_codes = {}
    for _, code in ipairs(product_codes) do
        local normalized = normalize_product_code(code)
        if normalized ~= nil then
            table.insert(normalized_codes, normalized)
        end
    end
    normalized_codes = dedupe_codes(normalized_codes)
    if #normalized_codes == 0 then
        return stats_by_code
    end

    local sales_total_by_code = fetch_sales_by_product_code(normalized_codes, false)
    local sales_in_range_by_code = fetch_sales_by_product_code(normalized_codes, true)

    for code, total in pairs(sales_total_by_code) do
        local stats = ensure_stats_entry(stats_by_code, code)
        stats.sales_quantity_total = total
        stats.sales_quantity = total
    end

    for code, range_qty in pairs(sales_in_range_by_code) do
        local stats = ensure_stats_entry(stats_by_code, code)
        stats.sales_quantity_in_range = range_qty
    end

    return stats_by_code
end

local function merge_product_stats(warranty_stats, sales_stats)
    local merged = {}
    for code, stats in pairs(warranty_stats or {}) do
        local normalized = normalize_product_code(code) or code
        merged[normalized] = {
            warranty_issued_count = stats.warranty_issued_count or 0,
            active_warranty_count = stats.active_warranty_count or 0,
            sales_quantity = 0,
            sales_quantity_total = 0,
            sales_quantity_in_range = 0,
            receipt_count = stats.receipt_count or 0,
            repaired_in_range_count = stats.repaired_in_range_count or 0,
            return_rate_percent = stats.return_rate_percent,
            direct_warranty_issued_count = stats.direct_warranty_issued_count or 0,
            direct_active_warranty_count = stats.direct_active_warranty_count or 0,
            direct_receipt_count = stats.direct_receipt_count or 0,
            direct_repaired_in_range_count = stats.direct_repaired_in_range_count or 0,
            direct_return_rate_percent = stats.direct_return_rate_percent
        }
    end
    for code, stats in pairs(sales_stats or {}) do
        local entry = ensure_stats_entry(merged, code)
        entry.sales_quantity_total = stats.sales_quantity_total or 0
        entry.sales_quantity_in_range = stats.sales_quantity_in_range or 0
        entry.sales_quantity = entry.sales_quantity_total
    end
    return merged
end

--[[
  WARRANTY STATS — batch by PRODUCT_ID via build_product_family_maps
  - Never use nested product_family_sql (timeouts → zero warranty)
  - Test with product_code 32030020282 before changing
]]
local function load_product_warranty_stats(product_codes, current_filetime)
    local stats_by_code = {}
    local normalized_codes = normalize_product_code_list(product_codes)
    if #normalized_codes == 0 then
        return stats_by_code
    end

    local id_by_code, family_ids_by_code, all_family_ids = build_product_family_maps(normalized_codes)
    local resolved_id_by_code, resolved_ids = resolve_product_ids_by_codes(normalized_codes)
    for code, product_id in pairs(resolved_id_by_code) do
        if id_by_code[code] == nil then
            id_by_code[code] = product_id
        end
    end

    local all_query_ids = merge_product_ids(all_family_ids, resolved_ids)
    local warranty_by_product = fetch_warranty_counts_by_product_ids(all_query_ids, current_filetime)
    local receipt_by_product = fetch_receipt_counts_by_product_ids(all_query_ids)
    local repaired_by_product = fetch_repaired_counts_by_product_ids(all_query_ids)

    for _, code in ipairs(normalized_codes) do
        local family_ids = family_ids_for_code(code, family_ids_by_code, id_by_code)
        local issued, active = sum_family_warranty_stats(family_ids, warranty_by_product)
        local receipts = sum_family_receipt_count(family_ids, receipt_by_product)
        local repaired_in_range = sum_family_repaired_count(family_ids, repaired_by_product)
        local return_rate = nil
        if issued > 0 then
            return_rate = math.floor((receipts * 1000.0 / issued) + 0.5) / 10
        end

        -- آمار «مختص همین کالا» (بدون خانواده/PARENT) — چون PARENT اغلب یک دستهٔ کلی
        -- است (مثلاً «هدست بلوتوث» با ۲۰۰+ مدل)، نه فقط رنگ‌های همان مدل
        local direct_id = id_by_code[code]
        local direct_warranty = get_map_value(warranty_by_product, direct_id)
        local direct_issued = direct_warranty and (direct_warranty.warranty_issued_count or 0) or 0
        local direct_active = direct_warranty and (direct_warranty.active_warranty_count or 0) or 0
        local direct_receipts = get_map_value(receipt_by_product, direct_id) or 0
        local direct_repaired = get_map_value(repaired_by_product, direct_id) or 0
        local direct_return_rate = nil
        if direct_issued > 0 then
            direct_return_rate = math.floor((direct_receipts * 1000.0 / direct_issued) + 0.5) / 10
        end

        stats_by_code[code] = {
            warranty_issued_count = issued,
            active_warranty_count = active,
            sales_quantity = 0,
            sales_quantity_total = 0,
            sales_quantity_in_range = 0,
            receipt_count = receipts,
            repaired_in_range_count = repaired_in_range,
            return_rate_percent = return_rate,
            direct_warranty_issued_count = direct_issued,
            direct_active_warranty_count = direct_active,
            direct_receipt_count = direct_receipts,
            direct_repaired_in_range_count = direct_repaired,
            direct_return_rate_percent = direct_return_rate
        }
    end

    return stats_by_code
end

local function build_filters(date_column)
    local where_parts = {
        "sr.FINAL_STATUS IN (8, 9)",
        [[EXISTS (
            SELECT 1
            FROM pm_service_request_content c
            WHERE c.SERVICE_REQUEST_ID = sr.ID
              AND (c.TYPE = 11 OR c.NEW_ID IN (6, 8))
        )]]
    }
    local params = {}
    append_date_filters(where_parts, params, date_column)

    if receipt_no ~= nil and receipt_no ~= "" then
        table.insert(where_parts, "sr.`CODE` = ?")
        table.insert(params, receipt_no)
    end

    return where_parts, params
end

local function build_query(where_clause)
    return [[
SELECT
    sr.ID,
    sr.`CODE`,
    sr.PRODUCT_SERIAL,
    sr.FINAL_STATUS,
    CASE sr.FINAL_STATUS
        WHEN 8 THEN 'آماده تحویل (تعویض شده)'
        WHEN 9 THEN 'کامل (تعویض شده)'
        ELSE 'نامشخص'
    END,
    REPORT_FN_JDATE(sr.BREAK_DOWN_DATE, '-'),
    ps.ID,
    REPORT_FN_JDATE(ps.SWAP_DATE, '-'),
    cause.TITLE,
    orig.FULL_CODE,
    orig.full_name,
    psd.ID,
    psd.SWAP_TYPE,
    CASE
        WHEN psd.SWAP_TYPE = 0 THEN 'کالای تحویلی'
        WHEN psd.SWAP_TYPE = 1 THEN 'کالای جایگزین'
        WHEN psd.SWAP_TYPE IS NULL THEN NULL
        ELSE 'سایر'
    END,
    psd.AMOUNT,
    repl.FULL_CODE,
    repl.full_name
FROM pm_service_request sr
INNER JOIN (
    SELECT DISTINCT c.SERVICE_REQUEST_ID
    FROM pm_service_request_content c
    WHERE c.TYPE = 11 OR c.NEW_ID IN (6, 8)
) rep ON rep.SERVICE_REQUEST_ID = sr.ID
LEFT JOIN pm_swap ps
    ON ps.SERVICE_REQUEST_ID = sr.ID
LEFT JOIN pm_swap_detail psd
    ON psd.SWAP_ID = ps.ID
LEFT JOIN wh_product orig
    ON orig.id = sr.PRODUCT_ID
LEFT JOIN wh_product repl
    ON repl.id = psd.PRODUCT_ID
LEFT JOIN pm_short_description cause
    ON cause.ID = ps.SWAP_CAUSE_ID
WHERE ]] .. where_clause
end

local where_parts, base_params = build_filters("sr.BREAK_DOWN_DATE")
local where_clause = table.concat(where_parts, " AND ")
local query = build_query(where_clause)
local query_params = {}

for _, value in ipairs(base_params) do
    table.insert(query_params, value)
end

if product_code ~= nil and product_code ~= "" then
    query = query .. " AND (orig.FULL_CODE LIKE ? OR repl.FULL_CODE LIKE ?)"
    local pattern = "%" .. product_code .. "%"
    table.insert(query_params, pattern)
    table.insert(query_params, pattern)
end

query = query .. " ORDER BY sr.`CODE` DESC, ps.ID DESC, psd.ID"

local ok, err = pcall(function()
    run_query(query, query_params)
end)

if not ok then
    fail("خطا در دریافت کالاهای تعویض‌شده", tostring(err))
    return
end

local replacements_map = {}
local replacement_ids = {}
local record = {}

while db.query_fetch(record) do
    local swap_id = tonumber(record[7]) or record[7]
    local service_request_id = tonumber(record[1]) or record[1]
    -- نکته: کلید گروه‌بندی باید service_request_id باشد نه swap_id.
    -- یک درخواست خدمات گاهی دو رکورد pm_swap جداگانه دارد (مثلاً یکی با
    -- SWAP_DATE نامعتبر/خراب) که با گروه‌بندی بر اساس swap_id، همان تعویض
    -- فیزیکی واحد را دو بار می‌شمرد (باعث مغایرت با کاردکس انبار می‌شد).
    local map_key = "sr:" .. tostring(service_request_id)
    local entry = replacements_map[map_key]

    if entry == nil then
        entry = {
            service_request_id = service_request_id,
            receipt_no = tonumber(record[2]) or record[2],
            product_serial = record[3],
            status_label = record[5],
            breakdown_date = record[6],
            swap_date = record[8],
            swap_cause = record[9],
            original_product_code = record[10],
            original_product_name = record[11],
            replaced_products = {}
        }
        replacements_map[map_key] = entry
        table.insert(replacement_ids, map_key)
    end

    local detail_id = record[12]
    local swap_type = tonumber(record[13]) or record[13]
    local swap_type_label = record[14]
    if detail_id ~= nil and detail_id ~= "" and tonumber(detail_id) ~= 0
        and is_replacement_swap_detail(swap_type, swap_type_label, record[16]) then
        local product_code = normalize_product_code(record[16]) or record[16]
        local product_name = record[17]
        local amount = tonumber(record[15]) or record[15]
        append_replaced_product_entry(
            entry.replaced_products,
            product_code,
            product_name,
            amount,
            swap_type,
            swap_type_label
        )
    end
end

db.query_free()

local replacements = {}
for _, map_key in ipairs(replacement_ids) do
    table.insert(replacements, replacements_map[map_key])
end

local product_codes = {}
local seen_codes = {}
for _, entry in ipairs(replacements) do
    local code = normalize_product_code(entry.original_product_code)
    if code ~= nil and code ~= "" and not seen_codes[code] then
        seen_codes[code] = true
        table.insert(product_codes, code)
    end
end

if product_code ~= nil and product_code ~= "" then
    local has_filter_code = false
    for _, code in ipairs(product_codes) do
        if code:find(product_code, 1, true) then
            has_filter_code = true
            break
        end
    end
    if not has_filter_code then
        local rows = fetch_rows(
            "SELECT FULL_CODE FROM wh_product WHERE FULL_CODE LIKE ? LIMIT 20",
            { "%" .. product_code .. "%" }
        )
        if rows ~= nil then
            for _, row in ipairs(rows) do
                if row[1] ~= nil and row[1] ~= "" then
                    table.insert(product_codes, row[1])
                end
            end
        end
    end
end

product_codes = dedupe_codes(product_codes)

local warranty_stats = {}
local sales_stats = {}
local warranty_error = nil
local ok_warranty, warranty_result = pcall(function()
    return load_product_warranty_stats(product_codes, get_current_filetime() or 0)
end)
local ok_sales, sales_result = pcall(function()
    return load_product_sales_stats(product_codes)
end)
if ok_warranty and type(warranty_result) == 'table' then
    warranty_stats = warranty_result
else
    warranty_error = tostring(warranty_result)
end
if ok_sales and type(sales_result) == 'table' then
    sales_stats = sales_result
end
local stats_by_code = merge_product_stats(warranty_stats, sales_stats)

local service_request_ids = collect_service_request_ids(replacements)
attach_replaced_products(
    replacements,
    load_replaced_products_by_service_request(service_request_ids)
)

-- فقط تعویض‌هایی که واقعاً از انبار خارج شده‌اند (تایید WH_REQ_PRODUCT) شمرده شوند
replacements = filter_confirmed_replacements(replacements)

local costs_by_sr = {}
local cogs_by_product = {}
local cogs_by_code = {}
local family_ids_by_code = {}
local costs_error = nil
local ok_costs, costs_result = pcall(function()
    return load_replacement_costs(service_request_ids, replacements)
end)
if ok_costs and type(costs_result) == 'table' then
    costs_by_sr = costs_result.costs_by_sr or {}
    cogs_by_product = costs_result.cogs_by_product or {}
    cogs_by_code = costs_result.cogs_by_code or {}
    family_ids_by_code = costs_result.family_ids_by_code or {}
else
    costs_error = tostring(costs_result)
end

for _, entry in ipairs(replacements) do
    local sr_id = normalize_entity_id(entry.service_request_id)
    local costs = get_map_value(costs_by_sr, sr_id)
    if costs == nil then
        costs = empty_cost_stats()
    end
    entry.declared_cost = costs.declared_cost
    entry.replacement_value = costs.replacement_value
    entry.parts_cost = costs.parts_cost
    entry.total_cost = costs.total_cost
    apply_entry_cost_fallback(entry, cogs_by_product, cogs_by_code, family_ids_by_code)
end

local product_matrix_map = {}
for _, entry in ipairs(replacements) do
    local code = normalize_product_code(entry.original_product_code)
        or entry.original_product_code
        or "—"
    local matrix_row = product_matrix_map[code]
    if matrix_row == nil then
        local stats = stats_by_code[code]
            or stats_by_code[entry.original_product_code]
            or {
            warranty_issued_count = 0,
            active_warranty_count = 0,
            sales_quantity = 0,
            sales_quantity_total = 0,
            sales_quantity_in_range = 0,
            receipt_count = 0,
            repaired_in_range_count = 0,
            return_rate_percent = nil,
            direct_warranty_issued_count = 0,
            direct_active_warranty_count = 0,
            direct_receipt_count = 0,
            direct_repaired_in_range_count = 0,
            direct_return_rate_percent = nil
        }
        matrix_row = {
            product_code = code,
            product_name = entry.original_product_name or "—",
            replaced_products_summary = {},
            replacement_count = 0,
            warranty_issued_count = stats.warranty_issued_count,
            active_warranty_count = stats.active_warranty_count,
            sales_quantity = stats.sales_quantity_total,
            sales_quantity_total = stats.sales_quantity_total,
            sales_quantity_in_range = stats.sales_quantity_in_range,
            receipt_count = stats.receipt_count or 0,
            repaired_in_range_count = stats.repaired_in_range_count or 0,
            return_rate_percent = stats.return_rate_percent,
            direct_warranty_issued_count = stats.direct_warranty_issued_count or 0,
            direct_active_warranty_count = stats.direct_active_warranty_count or 0,
            direct_receipt_count = stats.direct_receipt_count or 0,
            direct_repaired_in_range_count = stats.direct_repaired_in_range_count or 0,
            direct_return_rate_percent = stats.direct_return_rate_percent,
            total_declared_cost = 0,
            total_replacement_value = 0,
            total_parts_cost = 0,
            total_cost = 0
        }
        product_matrix_map[code] = matrix_row
    end
    matrix_row.replacement_count = matrix_row.replacement_count + 1
    merge_matrix_replaced_products(matrix_row, entry.replaced_products)
    matrix_row.total_declared_cost = matrix_row.total_declared_cost + (entry.declared_cost or 0)
    matrix_row.total_replacement_value = matrix_row.total_replacement_value + (entry.replacement_value or 0)
    matrix_row.total_parts_cost = matrix_row.total_parts_cost + (entry.parts_cost or 0)
    matrix_row.total_cost = matrix_row.total_cost + (entry.total_cost or 0)
end

local product_matrix = {}
for _, row in pairs(product_matrix_map) do
    table.insert(product_matrix, row)
end

table.sort(product_matrix, function(a, b)
    if a.replacement_count == b.replacement_count then
        return (a.product_code or "") < (b.product_code or "")
    end
    return a.replacement_count > b.replacement_count
end)

local matrix_codes = {}
for _, row in ipairs(product_matrix) do
    local code = normalize_product_code(row.product_code)
    if code ~= nil and code ~= "" and code ~= "—" then
        table.insert(matrix_codes, code)
    end
end
local _, matrix_family_ids_by_code, matrix_all_family_ids = build_product_family_maps(matrix_codes)
local matrix_code_to_id, matrix_product_ids = resolve_product_ids_by_codes(matrix_codes)
local matrix_unit_cogs = load_product_unit_cogs(
    merge_product_ids(matrix_product_ids, matrix_all_family_ids),
    matrix_codes
)
local matrix_cogs_by_code = build_cogs_by_code(matrix_family_ids_by_code, matrix_unit_cogs)
for _, row in ipairs(product_matrix) do
    local code = normalize_product_code(row.product_code)
    if code ~= nil then
        local product_id = matrix_code_to_id[code]
        local unit_cogs = get_unit_cogs(
            matrix_unit_cogs,
            matrix_cogs_by_code,
            product_id,
            code,
            matrix_family_ids_by_code
        )
        if unit_cogs > 0 and (row.replacement_count or 0) > 0 then
            if (row.total_declared_cost or 0) <= 0 then
                row.total_declared_cost = math.floor(unit_cogs * row.replacement_count + 0.5)
            end
            if (row.total_cost or 0) <= 0 then
                row.total_cost = (row.total_declared_cost or 0)
                    + (row.total_replacement_value or 0)
                    + (row.total_parts_cost or 0)
            end
        end
    end
end

local function format_replaced_products(products)
    local parts = {}
    for _, product in ipairs(products) do
        local label = product.product_code or "—"
        if product.product_name ~= nil and product.product_name ~= "" then
            label = label .. " | " .. product.product_name
        end
        if product.amount ~= nil then
            label = label .. " (" .. tostring(product.amount) .. ")"
        end
        table.insert(parts, label)
    end
    if #parts == 0 then
        return "—"
    end
    return table.concat(parts, " ؛ ")
end

local function heat_style(value, min_value, max_value)
    local v = tonumber(value) or 0
    local min_v = tonumber(min_value) or 0
    local max_v = tonumber(max_value) or 0
    if max_v <= min_v or v <= 0 then
        return "background-color:#ffffff;"
    end

    local n = (v - min_v) / (max_v - min_v)
    local r
    local g
    local b
    if n < 0.5 then
        r = math.floor(255 * n * 2)
        g = 255
        b = math.floor(255 * (1 - n * 2))
    else
        r = 255
        g = math.floor(255 * (2 - n * 2))
        b = 0
    end

    return string.format("background-color:rgb(%d,%d,%d);", r, g, b)
end

local min_replacements = 0
local max_replacements = 0
for i, row in ipairs(product_matrix) do
    local count = row.replacement_count or 0
    if i == 1 or count > max_replacements then
        max_replacements = count
    end
    if i == 1 or count < min_replacements then
        min_replacements = count
    end
end

for i, row in ipairs(product_matrix) do
    row.replaced_products_text = format_matrix_replaced_products(row)
    row._replaced_seen = nil
end

local matrix_rows_html = {}
for i, row in ipairs(product_matrix) do
    local rate = row.return_rate_percent
    local js_code = (escape_html(row.product_code):gsub("'", "\\'"))
    local direct_rate = row.direct_return_rate_percent
    table.insert(matrix_rows_html, safe_format(
        [[<tr class="clickable-row" data-code="%s" onclick="filterDetailByCode(%s)" title="مشاهده جزئیات تعویض این کالا">
            <td>%d</td>
            <td class="mono">%s</td>
            <td class="name-cell">%s</td>
            <td class="name-cell col-replaced">%s</td>
            <td style="%s"><strong>%s</strong></td>
            <td>%s</td>
            <td>%s</td>
            <td>%s</td>
            <td>%s</td>
            <td>%s</td>
            <td>%s</td>
            <td class="%s">%s</td>
            <td>%s</td>
            <td>%s</td>
            <td>%s</td>
            <td>%s</td>
            <td class="%s">%s</td>
            <td>%s</td>
            <td>%s</td>
            <td>%s</td>
            <td>%s</td>
            <td class="%s">%s</td>
        </tr>]],
        escape_html(row.product_code),
        "'" .. js_code .. "'",
        i,
        escape_html(row.product_code),
        escape_html(row.product_name),
        escape_html(row.replaced_products_text),
        heat_style(row.replacement_count, min_replacements, max_replacements),
        fmt_num(row.replacement_count),
        fmt_num(row.sales_quantity_total),
        fmt_num(row.sales_quantity_in_range),
        fmt_num(row.warranty_issued_count),
        fmt_num(row.active_warranty_count),
        fmt_num(row.receipt_count),
        fmt_num(row.repaired_in_range_count),
        return_analyze_class(rate),
        fmt_percent(rate),
        fmt_num(row.direct_warranty_issued_count),
        fmt_num(row.direct_active_warranty_count),
        fmt_num(row.direct_receipt_count),
        fmt_num(row.direct_repaired_in_range_count),
        return_analyze_class(direct_rate),
        fmt_percent(direct_rate),
        fmt_money(row.total_declared_cost),
        fmt_money(row.total_replacement_value),
        fmt_money(row.total_parts_cost),
        fmt_total_cost(row.total_cost),
        return_analyze_class(rate),
        escape_html(return_analyze_label(rate))
    ))
end

if #matrix_rows_html == 0 then
    matrix_rows_html = { [[<tr><td colspan="22" class="empty-row">داده‌ای یافت نشد</td></tr>]] }
end

local detail_rows_html = {}
for i, entry in ipairs(replacements) do
    local code = entry.original_product_code
    local stats = stats_by_code[code] or {
        warranty_issued_count = 0,
        active_warranty_count = 0,
        sales_quantity = 0,
        sales_quantity_total = 0,
        sales_quantity_in_range = 0,
        receipt_count = 0,
        repaired_in_range_count = 0,
        return_rate_percent = nil,
        direct_warranty_issued_count = 0,
        direct_active_warranty_count = 0,
        direct_receipt_count = 0,
        direct_repaired_in_range_count = 0,
        direct_return_rate_percent = nil
    }
    local rate = stats.return_rate_percent
    local direct_rate = stats.direct_return_rate_percent

    local receipt_url = "https://erp.bimehland.com/?page=/pm/service_request/view/view_request/&id="
        .. escape_html(entry.service_request_id)

    table.insert(detail_rows_html, safe_format(
        [[<tr data-code="%s">
            <td>%d</td>
            <td class="mono"><a href="%s" target="_blank" class="receipt-link">%s</a></td>
            <td class="mono">%s</td>
            <td>%s</td>
            <td>%s</td>
            <td>%s</td>
            <td class="mono">%s</td>
            <td class="name-cell">%s</td>
            <td class="name-cell col-replaced">%s</td>
            <td>%s</td>
            <td>%s</td>
            <td>%s</td>
            <td>%s</td>
            <td>%s</td>
            <td>%s</td>
            <td class="%s">%s</td>
            <td>%s</td>
            <td>%s</td>
            <td>%s</td>
            <td>%s</td>
            <td class="%s">%s</td>
            <td>%s</td>
            <td>%s</td>
            <td>%s</td>
            <td>%s</td>
            <td>%s</td>
        </tr>]],
        escape_html(entry.original_product_code),
        i,
        receipt_url,
        escape_html(entry.receipt_no),
        escape_html(entry.product_serial),
        escape_html(entry.breakdown_date),
        escape_html(entry.swap_date),
        escape_html(entry.swap_cause),
        escape_html(entry.original_product_code),
        escape_html(entry.original_product_name),
        escape_html(format_replaced_products(entry.replaced_products)),
        fmt_num(stats.sales_quantity_total),
        fmt_num(stats.sales_quantity_in_range),
        fmt_num(stats.warranty_issued_count),
        fmt_num(stats.active_warranty_count),
        fmt_num(stats.receipt_count),
        fmt_num(stats.repaired_in_range_count),
        return_analyze_class(rate),
        fmt_percent(rate),
        fmt_num(stats.direct_warranty_issued_count),
        fmt_num(stats.direct_active_warranty_count),
        fmt_num(stats.direct_receipt_count),
        fmt_num(stats.direct_repaired_in_range_count),
        return_analyze_class(direct_rate),
        fmt_percent(direct_rate),
        fmt_money(entry.declared_cost),
        fmt_money(entry.replacement_value),
        fmt_money(entry.parts_cost),
        fmt_total_cost(entry.total_cost),
        escape_html(entry.status_label)
    ))
end

if #detail_rows_html == 0 then
    detail_rows_html = { [[<tr><td colspan="26" class="empty-row">در بازه انتخاب‌شده پذیرش تعویض‌شده‌ای یافت نشد</td></tr>]] }
end

local filter_from = start_jalali or start_date or "—"
local filter_to = end_jalali or end_date or "—"
local filter_product = product_code or "—"
local filter_receipt = receipt_no or "—"
local generated_at = fetch_generated_at()

local avg_return_rate = nil
local return_rate_sum = 0
local return_rate_count = 0
local critical_product_count = 0

for _, row in ipairs(product_matrix) do
    if row.return_rate_percent ~= nil then
        return_rate_sum = return_rate_sum + row.return_rate_percent
        return_rate_count = return_rate_count + 1
    end
    if return_analyze_label(row.return_rate_percent) == "بحرانی" then
        critical_product_count = critical_product_count + 1
    end
end

if return_rate_count > 0 then
    avg_return_rate = return_rate_sum / return_rate_count
end

if output_json then
    local json_replacements = {}
    for _, entry in ipairs(replacements) do
        local code = normalize_product_code(entry.original_product_code) or entry.original_product_code
        local stats = stats_by_code[code]
            or stats_by_code[entry.original_product_code]
            or {
            warranty_issued_count = 0,
            active_warranty_count = 0,
            sales_quantity = 0,
            sales_quantity_total = 0,
            sales_quantity_in_range = 0,
            receipt_count = 0,
            repaired_in_range_count = 0,
            return_rate_percent = nil,
            direct_warranty_issued_count = 0,
            direct_active_warranty_count = 0,
            direct_receipt_count = 0,
            direct_repaired_in_range_count = 0,
            direct_return_rate_percent = nil
        }
        table.insert(json_replacements, {
            service_request_id = entry.service_request_id,
            receipt_no = entry.receipt_no,
            product_serial = entry.product_serial,
            status_label = entry.status_label,
            breakdown_date = entry.breakdown_date,
            swap_date = entry.swap_date,
            swap_cause = entry.swap_cause,
            original_product_code = entry.original_product_code,
            original_product_name = entry.original_product_name,
            sales_quantity = stats.sales_quantity_total,
            sales_quantity_total = stats.sales_quantity_total,
            sales_quantity_in_range = stats.sales_quantity_in_range,
            warranty_issued_count = stats.warranty_issued_count,
            active_warranty_count = stats.active_warranty_count,
            receipt_count = stats.receipt_count,
            repaired_in_range_count = stats.repaired_in_range_count,
            return_rate_percent = stats.return_rate_percent,
            direct_warranty_issued_count = stats.direct_warranty_issued_count,
            direct_active_warranty_count = stats.direct_active_warranty_count,
            direct_receipt_count = stats.direct_receipt_count,
            direct_repaired_in_range_count = stats.direct_repaired_in_range_count,
            direct_return_rate_percent = stats.direct_return_rate_percent,
            declared_cost = entry.declared_cost,
            replacement_value = entry.replacement_value,
            parts_cost = entry.parts_cost,
            total_cost = entry.total_cost,
            replaced_product_label = format_replaced_products(entry.replaced_products),
            replaced_products = entry.replaced_products
        })
    end

    teamyar.write_result(json.encode({
        ok = true,
        replacement_count = #replacements,
        message = #replacements == 0
            and "در بازه انتخاب‌شده پذیرش تعویض‌شده‌ای یافت نشد."
            or nil,
        filters = {
            from_date = start_jalali or start_date,
            to_date = end_jalali or end_date,
            product_code = product_code,
            receipt_no = receipt_no
        },
        product_matrix = product_matrix,
        replacements = json_replacements,
        costs_error = costs_error,
        warranty_error = warranty_error
    }))
    return
end

local ok_html, html_or_err = pcall(function()
    return string.format([[
<!DOCTYPE html>
<html dir="rtl" lang="fa">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>گزارش کالاهای تعویض‌شده</title>
<style>
@font-face {
    font-family: 'YekanBakh';
    font-weight: 400;
    font-style: normal;
    src: url(data:font/ttf;base64,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ACkAtAArADIAOAAoADwAKAA9ADwAQQA8AFEAMgBTADIAVQAyAHsAMgB+ADIAgwAeAIkAMgCMAB4AkQAyAJQAKACVADIAlwAyAKIAMgCmADIAqAAyAKsAKACsADIAsQAeALMAHgC1AB4AtwAeALkAHgFwADIBcgAyAXQAMgF2ADIBfAAyAX8AFAGAADIBggAyAYwAMgGPACgBlQAyABoAAwBQACkAyAA9ADwAQQA8AFEAPABTADwAVQA8AHsAPAB+ADwAiQA8AJEAPACVADwAlwA8AKIAPACmADwAqAA8AKwAPAFwADwBcgA8AXQAPAF2ADwBfAA8AYAAPAGCADwBjAA8AZUAPAAaAAMARgApALQAPQA8AEEAPABRADIAUwAyAFUAMgB7ADIAfgAyAIkAMgCRADIAlQAyAJcAMgCiADIApgAyAKgAMgCsADIBcAAyAXIAMgF0ADIBdgAyAXwAMgGAADIBggAyAYwAMgGVADIAGgADAFAAKQDIAD0AUABBAFAAUQA8AFMAPABVADwAewA8AH4APACJADwAkQA8AJUAPACXADwAogA8AKYAPACoADwArAA8AXAAPAFyADwBdAA8AXYAPAF8ADwBgAA8AYIAPAGMADwBlQA8ABoAAwBGACkAtAA9AFAAQQBQAFEAMgBTADIAVQAyAHsAMgB+ADIAiQAyAJEAMgCVADIAlwAyAKIAMgCmADIAqAAyAKwAMgFwADIBcgAyAXQAMgF2ADIBfAAyAYAAMgGCADIBjAAyAZUAMgACAAYAIwAsAAAAUQBWAAoAsQC6ABABbwF0ABoBdgF3ACABlAGVACIAAwABAGQAAgAUADAAAAABAAAABgACAAQBcAFwAAABcgFyAAEBdAF0AAIBlQGVAAMAAgAIAFEAUQAAAFMAUwABAFUAVQACAXABcAADAXIBcgAEAXQBdAAFAXYBdgAGAZUBlQAHAAIABAFwAXAAAAFyAXIAAQF0AXQAAgGVAZUAAwABAJoAAAAEAAQANABWABIAeAAIAFEAMgBTADIAVQAyAXAAMgFyADIBdAAyAXYAMgGVADIACABRADIAUwAyAFUAMgFwADIBcgAyAXQAMgF2ADIBlQAyAAgAUQAyAFMAMgBVADIBcAAyAXIAMgF0ADIBdgAyAZUAMgAIAFEAMgBTADIAVQAyAXAAMgFyADIBdAAyAXYAMgGV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AqQAMwK7ADMBVv/qASn/6gKkADMCuwAzAqQAMwK7ADMBVv/qASn/6gKkADMCuwAzAVb/6gEp/+oBswA5AecARQIFAEUB5//GAgX/xwHnAAYCBQAGAecAKAIFACgB5//0AgX/9AVXADQEygA1BAQANQAA/9YAAP/WAAD/mAAA/5gAAP+YAAD/mAHCADMA0AAmAaAAJgJuACYCFgAmAmQAMwGtADMCFQAbAhUAGwG4AC0BwgAzANYALAGoACwCdwAsAZEAMwIGADMBwAAgAioAJQIqACUBuAAvAggAPgJdAIACXQD2Al0AigJdACMCXQBNAl0AMAJdAIUCXQA/Al0APwJdAIcCXQCAAl0A9gJdAIoCXQAjAl0AlQJdAF4CXQByAl0APwJdAD8CXQCHAAD/mgAA/5oAAP9uAAD/mAAA/2UAAP+FAAD/ewAA/4UAAP+EAAD/SQAA/4QAAP/qAAD/6gAA/3sAAP9rAAD/ZQAA/2UAAP9lAAD/ZQAA/1IAAP9lAAD/ZgMEADgDMgA4Agn/6gHj/+oA3AA+ANwAPgDcAD4A3AA+AaMAPgDUAD4B+gAzAsUAMwQBADMFPAAzAY0AOgDUADoA1AA6AY0AOgCuADoBKQA6ASgAMwEoADIBKAAzASgAMgGeADMBngAyAP0AMwD9ADIBMAA6ATAAMgIiADMCIgAzAowAOwDUADsA1AA6AWcAOwFnADoCtAAzAfoAMwH4ADMB+AAzAfgAMwHXADMB+AAzAfgAMwH4ADMB+AAzAfgAMwHHADMBxwAzAfgAMwH4ADMDZgAzAWIAMwIiADMBYgAzAWIAMgC0ADoAtAA6A7IAEAHkABAB5AAQAbsAMwG7ADMD9wAyAbsAMwHlADMBvQAzAb0AOQJ6ADMCKAAxAVUAEgHqACEB+QAoAg4AFAHWACEB/wA0AcwAFwIAAC4B1gAcAWoAMwFqADMBjAAzAYoAMwGMADMBjAAzAbkAMwG5ADMBjQAzAYwAMwG5ADMBuQAzAcj/6gHI/+oByP/qAcj/6gHI/+oByP/qAcj/6gHI/+oBs//qAbD/6gGw/+oBsP/qAbD/6gGw/+oBsP/qAbD/6gEH/5kA4P+aAQf/mQDg/5oBB/+ZAOD/mgAA/5EA4f95AQj/eQNXADgDeAA4Agn/6gHj/+oClQAzArAAMwET/+oA9f/qAcEAKAHpACgBwQAo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YWtodGlhcmlmYXJkIC8gQmFraC4gQWxsIHJpZ2h0cyByZXNlcnZlZC5ZZWthbiBCYWtoUmVndWxhcjEuMDAwO0Jha2g7WWVrYW5CYWtoLVJlZ3VsYXJZZWthbiBCYWtoIFJlZ3VsYXJWZXJzaW9uIDEuMDAwOyB0dGZhdXRvaGludCAodjEuNilZZWthbkJha2gtUmVndWxhcllla2FuIEJha2ggaXMgYSBUcmFkZW1hcmsgb2YgUmV6YSBCYWtodGlhcmlmYXJkIHwgQmFraFJlemEgQmFraHRpYXJpZmFyZCAvIEJha2hSZXphIEJha2h0aWFyaWZhcmRDb250ZW1wb3JhcnkgUGVyc2lhbi9BcmFiaWMgdHlwZWZhY2UuIERlc2lnbmVkIGJ5IFJlemEgQmFraHRpYXJpZmFyZC5odHRwOi8vd3d3LmJha2h0aWFyaWZhcmQuaXJodHRwOi8vd3d3LmJha2h0aWFyaWZhcmQuaXIAQwBvAHAAeQByAGkAZwBoAHQAIACpACAAMgAwADEANQAgAGIAeQAgAFIAZQB6AGEAIABCAGEAawBoAHQAaQBhAHIAaQBmAGEAcgBkACAALwAgAEIAYQBrAGgALgAgAEEAbABsACAAcgBpAGcAaAB0AHMAIAByAGUAcwBlAHIAdgBlAGQALgBZAGUAawBhAG4AIABCAGEAawBoAFIAZQBnAHUAbABhAHIAMQAuADAAMAAwADsAQgBhAGsAaAA7AFkAZQBrAGEAbgBCAGEAawBoAC0AUgBlAGcAdQBsAGEAcgBZAGUAawBhAG4AQgBhAGsAaAAtAFIAZQBnAHUAbABhAHIAVgBlAHIAcwBpAG8AbgAgADEALgAwADAAMAA7ACAAdAB0AGYAYQB1AHQAbwBoAGkAbgB0ACAAKAB2ADEALgA2ACkAWQBlAGsAYQBuAEIAYQBrAGgALQBSAGUAZwB1AGwAYQByAFkAZQBrAGEAbgAgAEIAYQBrAGgAIABpAHMAIABhACAAVAByAGEAZABlAG0AYQByAGsAIABvAGYAIABSAGUAegBhACAAQgBhAGsAaAB0AGkAYQByAGkAZgBhAHIAZAAgAHwAIABCAGEAawBoAFIAZQB6AGEAIABCAGEAawBoAHQAaQBhAHIAaQBmAGEAcgBkACAALwAgAEIAYQBrAGgAUgBlAHoAYQAgAEIAYQBrAGgAdABpAGEAcgBpAGYAYQByAGQAQwBvAG4AdABlAG0AcABvAHIAYQByAHkAIABQAGUAcgBzAGkAYQBuAC8AQQByAGEAYgBpAGMAIAB0AHkAcABlAGYAYQBjAGUALgAgAEQAZQBzAGkAZwBuAGUAZAAgAGIAeQAgAFIAZQB6AGEAIABCAGEAawBoAHQAaQBhAHIAaQBmAGEAcgBkAC4AaAB0AHQAcAA6AC8ALwB3AHcAdwAuAGIAYQBrAGgAdABpAGEAcgBpAGYAYQByAGQALgBpAHIAaAB0AHQAcAA6AC8ALwB3AHcAdwAuAGIAYQBrAGgAdABpAGEAcgBpAGYAYQByAGQALgBpAHIAAgAAAAAAAP+KABkAAAAAAAAAAAAAAAAAAAAAAAAAAAHvAAABAgACAAMBAwEEAKwBBQEGAQcBCAEJAQoBCwEMAQ0BDgEPARABEQESARMBFAEVARYBFwEYARkBGgEbARwBHQEeAR8BIAEhASIBIwEkASUBJgEnASgBKQEqASsBLAEtAS4BLwEwATEBMgEzATQBNQE2ATcBOAE5AToBOwE8AT0BPgE/AUABQQFCAUMBRAFFAUYBRwFIAUkBSgFLAUwBTQFOAU8BUAFRAVIBUwFUAVUBVgFXAVgBWQFaAVsBXAFdAV4BXwFgAWEBYgFjAWQBZQFmAWcBaAFpAWoBawFsAW0BbgFvAXABcQFyAXMBdAF1AXYBdwF4AXkBegF7AXwBfQF+AX8BgAGBAYIBgwGEAYUBhgGHAYgBiQGKAYsBjAGNAY4BjwGQAZEBkgGTAZQBlQGWAZcBmAGZAZoBmwGcAZ0BngGfAaABoQGiAaMBpAGlAaYBpwGoAakBqgGrAawBrQGuAa8BsAGxAbIBswG0AbUBtgG3AbgBuQG6AbsBvAG9Ab4BvwHAAcEBwgHDAcQBxQHGAccByAHJAcoBywHMAc0BzgHPAdAB0QHSAdMB1AHVAdYB1wHYAdkB2gHbAdwB3QHeAd8B4AHhAeIB4wHkAeUB5gHnAegB6QHqAesB7AHtAe4B7wHwAfEB8gHzAfQB9QH2AfcB+AH5AfoB+wH8Af0B/gH/AgACAQICAgMCBAARAgUAHQIGAgcABAIIAgkCCgILAgwCDQIOAg8ACgAFAhACEQALAAwAqQCqAL4AvwA+AEAAEgA/AKsAtgC3ALQAtQAGAhIADgITAJMA8AC4ACAAjwCnAKQAHwAhAJQAlQCSAIMAvABeAGAAXwDoALMAsgIUABACFQIWAhcAQgCIAhgCGQATABQAFQAWABcAGAAZABoAGwAcAhoCGwCHAhwCHQIeAh8CIAIhAiICIwIkAiUCJgInAigCKQIqAisCLAItAi4CLwIwAjECMgIzAjQCNQI2AjcCOAI5AjoCOwI8Aj0CPgI/AkACQQJCAkMCRAJFAkYCRwJIAkkCSgJLAKACTAJNAk4CTwJQAlECUgJTAlQCVQJWAlcCWAJZAloAJAAlACYAJwAoACkAKgArACwALQAuAC8AMAAxADIAMwA0ADUANgA3ADgAOQA6ADsAPAA9AEQARQBGAEcASABJAEoASwBMAE0ATgBPAFAAUQBSAFMAVABVAFYAVwBYAFkAWgBbAFwAXQJbAlwCXQJeAl8CYAJhAmICYwJkAmUCZgJnAmgCaQJqAmsCbAJtAm4ADwAeACIACQANAAgAIwCLAIoAjAC9Am8ABwCEAIUAlgJwBS5udWxsCWxpbmVfZmVlZA9jYXJyaWFnZV9yZXR1cm4MZW5RdWFkX1NwYWNlDGVtUXVhZF9TcGFjZQgzX01zcGFjZQg0X01zcGFjZQg2X01zcGFjZQtmaWd1cmVTcGFjZRBwdW5jdHVhdGlvblNwYWNlDnRoaW5faGFpclNwYWNlB3p3c3BhY2ULendOT05qb2luZXIIendqb2luZXIObmFycm93X25ic3BhY2UJenduYnNwYWNlC3dvcmRfam9pbmVyA29iag5saW5lX3NlcGVyYXRvchNwYXJhZ3JhcGhfc2VwZXJhdG9yDExUUmVtYmVkZGluZwxSVExlbWJlZGRpbmcecG9wLmRpcmVjdGlvbmFsLmZvcm1hdHRpbmdfUERGC0xUUm92ZXJyaWRlC1JUTG92ZXJyaWRlCFJUTF9tYXJrCExUUl9tYXJrDnBlcmlvZGNlbnRlcmVkD2thc2hpZGFzLk5hcnJvdwhrYXNoaWRhcw1rYXNoaWRhcy5XaWRlBGFsZWYJYWxlZi5maW5hB2FsZWYuYWEMYWxlZi5hYS5maW5hCWFsZWYudGhteg5hbGVmLnRobXouZmluYQlhbGVmLmJobXoOYWxlZi5iaG16LmZpbmEKYWxlZi52YXNsYQ9hbGVmLnZhc2xhLmZpbmECYmUHYmUuZmluYQdiZS5tZWRpB2JlLmluaXQCcGUHcGUuZmluYQdwZS5tZWRpB3BlLmluaXQCdGUHdGUuZmluYQd0ZS5tZWRpB3RlLmluaXQDdGhlCHRoZS5maW5hCHRoZS5tZWRpCHRoZS5pbml0A2ppbQhqaW0uZmluYQhqaW0ubWVkaQhqaW0uaW5pdANjaGUIY2hlLmZpbmEIY2hlLm1lZGkIY2hlLmluaXQDaGltCGhpbS5maW5hCGhpbS5tZWRpCGhpbS5pbml0A2toZQhraGUuZmluYQhraGUubWVkaQhraGUuaW5pdANkYWwIZGFsLmZpbmEDemFsCHphbC5maW5hAnJlB3JlLmZpbmECemUHemUuZmluYQJqZQdqZS5maW5hA3NpbghzaW4uZmluYQhzaW4ubWVkaQhzaW4uaW5pdARzaGluCXNoaW4uZmluYQlzaGluLm1lZGkJc2hpbi5pbml0A3NhZAhzYWQuZmluYQhzYWQubWVkaQhzYWQuaW5pdAN6YWQIemFkLmZpbmEIemFkLm1lZGkIemFkLmluaXQCdGEHdGEuZmluYQd0YS5tZWRpB3RhLmluaXQCemEHemEuZmluYQd6YS5tZWRpB3phLmluaXQDZWluCGVpbi5maW5hCGVpbi5tZWRpCGVpbi5pbml0BHFlaW4JcWVpbi5maW5hCXFlaW4ubWVkaQlxZWluLmluaXQCZmUHZmUuZmluYQdmZS5tZWRpB2ZlLmluaXQDcWFmCHFhZi5maW5hCHFhZi5tZWRpCHFhZi5pbml0A2thZghrYWYuZmluYQhrYWYubWVkaQhrYWYuaW5pdAhrYWYuYXJhYg1rYWYuYXJhYi5maW5hA2dhZghnYWYuZmluYQhnYWYubWVkaQhnYWYuaW5pdANsYW0IbGFtLmZpbmEIbGFtLm1lZGkIbGFtLmluaXQDbWltCG1pbS5maW5hCG1pbS5tZWRpCG1pbS5pbml0A251bghudW4uZmluYQhudW4ubWVkaQhudW4uaW5pdAN2YXYIdmF2LmZpbmEIdmF2LnRobXoNdmF2LnRobXouZmluYQxoZS5hcmFiLmlzb2wCaGUHaGUuZmluYQdoZS5tZWRpB2hlLmluaXQKdGUubWFyYnV0YQ90ZS5tYXJidXRhLmZpbmEHaGUudGhtegxoZS50aG16LmZpbmECeWUHeWUuZmluYQd5ZS5tZWRpB3llLmluaXQHeWUuYXJhYgx5ZS5hcmFiLmZpbmEHeWUudGhtegx5ZS50aG16LmZpbmEMeWUudGhtei5tZWRpDHllLnRobXouaW5pdAxhbGVmLm1ha3N1cmERYWxlZi5tYWtzdXJhLmZpbmERYWxlZi5tYWtzdXJhLm1lZGkRYWxlZi5tYWtzdXJhLmluaXQDaG16AmxhB2xhLmZpbmEFbGEuYWEKbGEuYWEuZmluYQdsYS50aG16DGxhLnRobXouZmluYQdsYS5iaG16DGxhLmJobXouZmluYQlsYS50dmFzbGEObGEudHZhc2xhLmZpbmEEcmlhbAVhbGxhaAZsZWxsYWgDdDFwA2IxcAN0MnADYjJwA3QzcANiM3AEc2VmcgN5ZWsCZG8Cc2UEY2hhcgRwYW5qBXNoaXNoBGhhZnQFaGFzaHQDbm9oCXNlZnIuYXJhYgh5ZWsuYXJhYgdkby5hcmFiB3NlLmFyYWIJY2hhci5hcmFiCXBhbmouYXJhYgpzaGlzaC5hcmFiCWhhZnQuYXJhYgpoYXNodC5hcmFiCG5vaC5hcmFiCi5zZXBlcmF0b3IJc2Vmci50bnVtCHllay50bnVtB2RvLnRudW0Hc2UudG51bQljaGFyLnRudW0JcGFuai50bnVtCnNoaXNoLnRudW0JaGFmdC50bnVtCmhhc2h0LnRudW0Ibm9oLnRudW0Oc2Vmci5hcmFiLnRudW0NeWVrLmFyYWIudG51bQxkby5hcmFiLnRudW0Mc2UuYXJhYi50bnVtDmNoYXIuYXJhYi50bnVtDnBhbmouYXJhYi50bnVtD3NoaXNoLmFyYWIudG51bQ5oYWZ0LmFyYWIudG51bQ9oYXNodC5hcmFiLnRudW0Nbm9oLmFyYWIudG51bQUudGhtegUuYmhtegQubWFkBC5za24FLnNoZGQCLmECLm8CLmUDLmFuAy5vbgMuZW4DLmFhAi5pBlR2YXNsYQYua29sYWgHLnNoZGQuYQcuc2hkZC5vBy5zaGRkLmUILnNoZGQuYW4ILnNoZGQub24ILnNoZGQuZW4ILnNoZGQuYWEGYmUuZGxzC2JlLmRscy5maW5hC2ZlLmRscy5tZWRpC2ZlLmRscy5pbml0BnZpcmd1bAxub3F0ZV92aXJndWwEc29hbAZzZXRhcmUGZGFyc2FkCGRhcmhlemFyCmRhckRhaGV6YXIKdGFyaWtoLnNlcAloZXphci5zZXAMaGV6YXIuc2VwLnVwB3NhZC5zZXANcGFyYW50ZXpfbGVmdA5wYXJhbnRlel9yaWdodAdhc3RlcmlzDGh5cGhlbl9taW51cwpmaWd1cmVkYXNoCW5iX2h5cGhlbg5ob3Jpem9udGFsX2Jhcgpzb2Z0SHlwaGVuGnJldmVyc2VkX3BpbGNyb3dfcGFyYWdyYXBoC2RvdHRlZC5yaW5nEmJsYWNrX3NtYWxsX3NxdWFyZRJ3aGl0ZV9zbWFsbF9zcXVhcmUMd2hpdGVfYnVsbGV0GGJsYWNrX2xlZnRzbWFsbF90cmlhbmdsZRh3aGl0ZV9sZWZ0c21hbGxfdHJpYW5nbGUWYmxhY2tfdXBzbWFsbF90cmlhbmdsZRZ3aGl0ZV91cHNtYWxsX3RyaWFuZ2xlGWJsYWNrX3JpZ2h0c21hbGxfdHJpYW5nbGUZd2hpdGVfcmlnaHRzbWFsbF90cmlhbmdsZRhibGFja19kb3duc21hbGxfdHJpYW5nbGUYd2hpdGVfZG93bnNtYWxsX3RyaWFuZ2xlDHRvb3RoLmsubWVkaQliZS5rLm1lZGkJcGUuay5tZWRpCXRlLmsubWVkaQp0aGUuay5tZWRpCm51bi5rLm1lZGkJeWUuay5tZWRpCWllLmsubWVkaQx0b290aC5rLmluaXQJYmUuay5pbml0CXBlLmsuaW5pdAl0ZS5rLmluaXQKdGhlLmsuaW5pdApudW4uay5pbml0CXllLmsuaW5pdAlpZS5rLmluaXQJcmUuYy5maW5hBHJlLmMJemUuYy5maW5hBHplLmMJamUuYy5maW5hBGplLmMDLnR2BXJlLmJ2CnJlLmJ2LmZpbmEDdmVoCHZlaC5maW5hCHZlaC5tZWRpCHZlaC5pbml0BmxhbS50dgtsYW0udHYuZmluYQpsYW0udHZtZWRpC2xhbS50di5pbml0BnZhdi50dgt2YXYudHYuZmluYQd2YXYudDJwDHZhdi50MnAuZmluYQxoZS50aG16LmdvYWwRaGUudGhtei5nb2FsLmZpbmEHYWUuZmluYQxoZS5kb2NoYXNobWkRaGUuZG9jaGFzaG1pLmZpbmERaGUuZG9jaGFzaG1pLm1lZGkRaGUuZG9j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) format('truetype');
}
@font-face {
    font-family: 'YekanBakh';
    font-weight: 700;
    font-style: normal;
    src: url(data:font/ttf;base64,AAEAAAASAQAABAAgRFNJRwAAAAEAAPGkAAAACEdERUYJsgr4AADxrAAAAFJHUE9TTkcljAAA8gAAABG0R1NVQhOkadwAAQO0AAAMrk9TLzKcsvBFAAABqAAAAGBjbWFwYZIf0AAACGAAAAYQY3Z0IAHgAhwAABEwAAAAJmZwZ20GWZw3AAAOcAAAAXNnYXNw//8ABAAA8ZwAAAAIZ2x5Zj90aTAAABSIAADLbGhlYWQOV0E+AAABLAAAADZoaGVhB7cDgwAAAWQAAAAkaG10eJndD50AAAIIAAAGWGxvY2F1kkMMAAARWAAAAy5tYXhwA7wEfQAAAYgAAAAgbmFtZTjuZh8AAN/0AAACpnBvc3QL7tCdAADinAAADwBwcmVwErQL/wAAD+QAAAFKAAEAAAABAACE3KH5Xw889QAbA+gAAAAA07DkpAAAAADXeRol/1r+RASkA0sAAAAJAAIAAAAAAAAAAQAAA4T9qAAyBNL/Wv9yBKQAAQAAAAAAAAAAAAAAAAAAAZYAAQAAAZYAmAAQAGkABgABAAAAAAAKAAACAAN6AAUAAQADAdMBkAAFAAACJgImAAD/OAImAiYAAAHCABkAyAAAAQAFBAAAAAIABIAAIAEAAAAAAAAACAAAAABiYWtoAEAAAP/8A4T9qAAyA4QCWAAAAEEACAAAASwCKwAAACAABQHnADwDZgAAA2YAAACLAAAAAAAAAAAAAACDAAAB9AAAA+gAAAEsAAAA+gAAAJYAAAImAAAAlgAAAJYAAAAAAAAAAP/sAAD/nAAyAAAAAAAAAyAAAAMWABQAAAAAAAAAAAAA/6sAAP+rAAD/vwAA/5cAAP+XAV4ARgFeAEYBBABMAEv/7ACW/+wA4f/sAKsAOADKADgAq//CAMr/wgCr//cAyv/3AKv//gDKACEAq//uAMr/7gK0AC4C4wAuATf/7AEJ/+wCtAAuAuMALgE3/+wBCf/sArQALgLjAC4BN//sAQn/7AK0AC4C4wAuATf/7AEJ/+wB6gApAgMAKQIe/+wB+v/sAeoAKQIDACkCHv/sAfr/7AHqACkCAwApAh7/7AH6/+wB6gApAgMAKQIe/+wB+v/sAdsAJAHSACQB2wAkAdIAJAC7/3kA4/95ALv/eQDj/3kAu/95AOP/eQP6AC4EKAAuArr/7AKM/+wD+gAuBCgALgK6/+wCjP/sBDcALgRaAC4C6P/sAsX/7AQ3AC4EWgAuAuj/7ALF/+wCZAApAoYAKQJf/+wCPf/sAmQAKQKGACkCX//sAj3/7AHXACsB7AAuAgf/7AGw/+wB1wArAewALgIH/+wBsP/sAv8ALgMiAC4B2f/sAbn/7AJ/AC4CqAAuAdn/7AG5/+wCzAAuA1EALgIy/+wBrf/sAq8ALgLSAC4CzAAuA1EALgIy/+wBrf/sAk8ALgJyAC4A+//sANj/7AIzAC4CXAAuAdr/7AGy/+wCSQAuAnIALgE3/+wBCf/sAZMAJQG8ACUBkwAlAbwAJQJqADABngAuAboALgHn/+wCif/sAZ4ALgG6AC4BngAuAboALgJnAC4CfAAuATf/7AEJ/+wCZwAuAnwALgJnAC4CfAAuATf/7AEJ/+wCZwAuAnwALgE3/+wBCf/sAYwANAGtADgBzwA4Aa3/yAHP/8gBrQABAc8AAQGtAB0BzwAdAa3/8gHP//IE0gAuBEYALgOfAC4AAP/aAAD/2gAA/6IAAP+iAAD/ogAA/6IBmQAuAL0AIgF6ACICNgAiAeYAIgItAC4BhQAuAeUAGAHlABgBjwApAZkALgC9ACIBegAiAjYAIgHmACICLQAuAYUALgHlABgB5QAYAY8AKQHYADgCJgB1AiYA3wImAH0CJgAeAiYARgImACoCJgB5AiYAOAImADgCJgB7AiYAdQImAN8CJgB9AiYAHgImAHsCJgBVAiYAeQImADgCJgA4AiYAewAA/6MAAP+jAAD/ewAA/6EAAP9zAAD/kAAA/4cAAP+QAAD/jgAA/1oAAP+OAAD/7QAA/+0AAP+IAAD/eQAA/3MAAP9zAAD/cwAA/3MAAP9iAAD/cwAA/3QCtAAuAuMALgHZ/+wBuf/sAMgAOADIADgAyAA4AMgAOAF9ADgAwAA4AcwALgKEAC4DowAuBMIALgFpADQAwAA0AMAANAFpADQAngA0AQ8ANAEOAC4BDgAuAQ4ALgEOAC4BeAAuAXgALgDmAC4A5gAuARUANAEVAC4B8QAuAfEALgJQADQAwAA0AMAANAFGADQBRgA0AnUALgHMAC4ByQAuAckALgHJAC4BrQAuAckALgHJAC4ByQAuAckALgHJAC4BngAuAZ4ALwHJAC4ByQAuAxcALgFCAC4B8QAuAUIALgFCAC4ApAA0AKQANANcAA8BuAAP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AAADZQJHACsBR7sAIAALAB8ABCu7ABMADgAoAAQrugAMAAoAAyu6AAQAHwAMERI5QQUA2gAKAOoACgACXUEbAAkACgAZAAoAKQAKADkACgBJAAoAWQAKAGkACgB5AAoAiQAKAJkACgCpAAoAuQAKAMkACgANXUEFAMoAKADaACgAAl1BGQAJACgAGQAoACkAKAA5ACgASQAoAFkAKABpACgAeQAoAIkAKACZACgAqQAoALkAKAAMXbgADBC4AC3cALgAAi+4AABFWLgADi8buQAOABE+WbgAAEVYuAAYLxu5ABgAET5ZugAEAA4AAhESObgADhC5AAoAA/RBGQAHAAoAFwAKACcACgA3AAoARwAKAFcACgBnAAoAdwAKAIcACgCXAAoApwAKALcACgAMXUEFAMYACgDWAAoAAl26ABMADgACERI5uAAk0LgAJdAwMQE1JRcFFx4DMzIVFCMiLgInFg4CIyEiLgI9ATMVFBYzITI2NTQmJwFpATIN/vuqRVIzIxcUFBopKjMkAxEhLxv+piY1IRA7KTUBSCkfDBgBj0F3O2WqRU0lCB4gCRosIx4rHA0XJjMcemwqMiIYECYXAAAAAf/sAAACRgJHACQA2bgAJS+4ABEvuAAlELgAItC4ACIvQQUA2gARAOoAEQACXUEbAAkAEQAZABEAKQARADkAEQBJABEAWQARAGkAEQB5ABEAiQARAJkAEQCpABEAuQARAMkAEQANXbgAERC4ABPcugALACIAExESObgAERC4ABXQugAaACIAExESObgAIhC4ACDcuAAk0LgAExC4ACbcALgACS+4AABFWLgAFS8buQAVABE+WbgAAEVYuAAfLxu5AB8AET5ZuQAAAAP0ugALABUACRESObgAEdC6ABoAFQAJERI5MDE3MjY1NCYvATUlFwUXHgMzMhUUIyIuAicWDgIrASI1NDPwKR8MGMoBMwz++6pFUjMjFxQUGikqMiQCESEuG/YUFD4iGBAmF8pBdztlqkVNJQgeIAkaLCMeKxwNHiAAAf/sAAABiQJHABkAjrsAEQALAAMABCu6ABUAFwADK0EFAMoAAwDaAAMAAl1BGQAJAAMAGQADACkAAwA5AAMASQADAFkAAwBpAAMAeQADAIkAAwCZAAMAqQADALkAAwAMXboACwAXABEREjm4ABEQuAAb3AC4AAkvuAAA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AApxQQUApQARALUAEQACcbgADBC4AB7cALgAAEVYuAAQLxu5ABAAET5ZuwAJAAYAGgAEKzAxJzcuATU0PgIzMhYVFAYPATcUFhc+ATU0JiMiBnlyGBYNFyASJjAkLZBZGhUVIBkZGhgkLQ4qFBIgGA4yJh0xEzycEiEJCB0WFCAiAAAA////kP+EAHAAAAIGAPIAhP///44AAAByAO4CJgDyAgAABgDy/nIAAAAC/1oAAACAAPUAGgAmAVa7ABkADwARAAQruwAbAA8AAwAEK7sACwAPACEABCu6AAAAEQALERI5QSEABgAbABYAGwAmABsANgAbAEYAGwBWABsAZgAbAHYAGwCGABsAlgAbAKYAGwC2ABsAxgAbANYAGwDmABsA9gAbABBdQRUABgAbABYAGwAmABsANgAbAEYAGwBWABsAZgAbAHYAGwCGABsAlgAbAApxQQUApQAbALUAGwACcUEFAKoAIQC6ACEAAnFBIQAJACEAGQAhACkAIQA5ACEASQAhAFkAIQBpACEAeQAhAIkAIQCZACEAqQAhALkAIQDJACEA2QAhAOkAIQD5ACEAEF1BFQAJACEAGQAhACkAIQA5ACEASQAhAFkAIQBpACEAeQAhAIkAIQCZACEACnG4AAsQuAAo3AC4AABFWLgADy8buQAPABE+WbsACAAGACQABCu7ABUABgAUAAQrMDE3LgE1ND4CMzIWFRQGDwEnNTQrATUzMhYdATcUFhc+ATU0JiMiBgMZFg0XIBImMCMtkBARJTARFUgaFRUgGRkaGFEOKhQSIBgOMiYdMRM8IEoUJRIXSmwSIQkIHRYUICIAAP///47/EgByAAACJwDyAAL/EgAGAPL+hAAB/+0AAAATAJ0AAwAquwACAA8AAwAEK7gAAhC4AAXcALgAAS+4AABFWLgAAy8buQADABE+WTAxJzMVIxMmJp2dAAAA////7f9jABMAAAIHAPgAAP9jAAAAAv+IAAAAeACrAA8AGQDZuAAaL7gAEy9BBQCqABMAugATAAJxQSEACQATABkAEwApABMAOQATAEkAEwBZABMAaQATAHkAEwCJABMAmQATAKkAEwC5ABMAyQATANkAEwDpABMA+QATABBdQRUACQATABkAEwApABMAOQATAEkAEwBZABMAaQATAHkAEwCJABMAmQATAApxuQAGAA/0uAAaELgADtC4AA4vuQAPAA/0ugAZAA4ABhESObgABhC4ABvcALgAAEVYuAALLxu5AAsAET5ZuwADAAYAFgAEK7gACxC5ABAABvQwMSc+ATMyFhUUDgIrASc1NxcyNjU0JiMiBgdXJT8hHiwKFiUceRYhbxojFxUZLhgoSDsvIw4fGxEVVwVMGRoRHTYrAAAAAf95//0AhgB2AA0AHgC4AABFWLgABC8buQAEABE+WbsADAADAA0ABCswMSciBg8BJzc+AzsBBx8RFggSJxgHDhIXEKcCPwcSKRI0EBUKBDcAAAD///9zAAAAjQFIAicA8gAAAMwABgDxAAD///9zAAAAjQHDAicA8wAAAM4ABgDxAAD///9zAAAAjQFOAicA8QAAAKkABgDyAAD///9zAAAAjQG4AiYA8QAAACcA8gAAAMwABwDyAAABPP///2IAAACNAb8CJwD2AAgAygAGAPEAAP///3MAAACNAcsCJwDxAAABJgAmAPIAAAAGAPIAbgAA////dAAAAI4BfwImAPEBAAAHAPgAAADiAAEALgAAAoYBBgAXAEq4ABgvuAAQL7gAGBC4AAbQuAAGL7kABwAL9LgAEBC5ABEAC/S4ABncALgABi+4ABEvuAAARVi4AAAvG7kAAAARPlm5AAsAA/QwMTMiLgI9ATMVFBYzITI2PQEzFRQOAiO6JjUhEDspNQE2Jig7FSMvGhcmMxx6bCoyJyF/hx4vIBEAAAEALgAAAvcBBgAjAHO7AB8ACwAeAAQruwAFAAsABAAEK7oADgAMAAMrugAUAAQABRESObgADhC4ACXcALgABC+4AB8vuAAARVi4ABAvG7kAEAARPlm4AABFWLgAFy8buQAXABE+WbkAAAAD9LgAC9C4AAzQugAUABcAABESOTAxJTI2PQEzFRQeAjsBMhUUKwEiJicOASMhIi4CPQEzFRQWMwH9Jig7DhYcDg8UFBEhORIUNx7+vSY1IRA7KTU+JyF/fxQbEQgeIBgjIxgXJjMcemwqMgAAAAL/7AAAAe0BaAAiADIA+7sAJgALAAMABCu7AA0ACwAwAAQrugASABAAAyu6AB4AIAADK7oAAAAgABIREjlBGQAGACYAFgAmACYAJgA2ACYARgAmAFYAJgBmACYAdgAmAIYAJgCWACYApgAmALYAJgAMXUEFAMUAJgDVACYAAl1BBQDKADAA2gAwAAJdQRkACQAwABkAMAApADAAOQAwAEkAMABZADAAaQAwAHkAMACJADAAmQAwAKkAMAC5ADAADF24ABIQuAA03AC4AABFWLgAFC8buQAUABE+WbgAAEVYuAAdLxu5AB0AET5ZuwAIAAMAIwAEK7gAHRC5AAAAA/S4AA/QuAAQ0DAxNy4BNTQ+AjMyHgIVFAczMhUUKwEiJicOAiIrASI1NDM3IgYVFB4CFz4DNTQmrywyFio7JiU5JRNVphQUZSpAEw0lKCUNaxQU7S42FB8mEg4hGxI2PhpILR44KxoaKzYbWTseIAUJBQYDHiDrOioXJx8XBwcXHiYWLzgAAAAAAv/sAAABgwFwABsALACguwAhAAsACAAEK7sAEgALACoABCu6ABcAGQADK7oAAwAZABIREjlBGQAGACEAFgAhACYAIQA2ACEARgAhAFYAIQBmACEAdgAhAIYAIQCWACEApgAhALYAIQAMXUEFAMUAIQDVACEAAl24ABIQuAAu3AC4AABFWLgAFi8buQAWABE+WbsADQADABwABCu4ABYQuQAAAAP0uAAD0LgAAy8wMTcyNjMuAzU0PgIzMh4CHQEUBisBIjU0MzciDgIVFB4CFz4BPQE0JpoXIRQzPB4IFCY5JiI5KBZUW9QUFOYWIxgNByBCOw4RLz4BEiElKxoZNSsbEypDMShHUB4g9BAaIRESHh4hFQsmGB05QQABADgAAACQAGEABwBTuwAGAAwAAgAEK0EZAAYABgAWAAYAJgAGADYABgBGAAYAVgAGAGYABgB2AAYAhgAGAJYABgCmAAYAtgAGAAxdQQUAxQAGANUABgACXQC4AAQvMDEzIjU0MzIVFGQsLCwwMTEwAAAAAAEAOAAAAJAAywARAKK7AA0ADwACAAQruAACELkAEAAM9LgAB9C4AAcvQSEABgANABYADQAmAA0ANgANAEYADQBWAA0AZgANAHYADQCGAA0AlgANAKYADQC2AA0AxgANANYADQDmAA0A9gANABBdQRUABgANABYADQAmAA0ANgANAEYADQBWAA0AZgANAHYADQCGAA0AlgANAApxQQUApQANALUADQACcQC4AAcvMDEzIjU0PgI3FQ4DFTIWFRRkLAURIR0PEggCGBc0LTYgDwUoBAcNFxMXGjAAAP//ADgAAACQAT0CJwEHAAAA3AAG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OQAaAEkAGgBZABoAaQAaAHkAGgCJABoAmQAaAKkAGgC5ABoADF24ABoQuQAKAAv0uAAAELkAFAAL9EEZAAYAFAAWABQAJgAUADYAFABGABQAVgAUAGYAFAB2ABQAhgAUAJYAFACmABQAtgAUAAxdQQUAxQAUANUAFAACXbgAChC4ACHcALgAAEVYuAAPLxu5AA8AET5ZuwAFAAUAHQAEK7gADxC5ABcABfRBGQAHABcAFwAXACcAFwA3ABcARwAXAFcAFwBnABcAdwAXAIcAFwCXABcApwAXALcAFwAMXUEFAMYAFwDWABcAAl0wMTc0PgIzMh4CFRQOAiMiLgI3FBYzMjY1NCYjIgYuFSQxGxsxJBUVJDEbGzEkFTctISAuLiAhLYQbMSQVFSQxGxswJBUVJDAbIC4uICEuLgABAC7/+gE5AS4AAgAiALgAAC+4AABFWLgAAS8buQABABE+WboAAgABAAAREjkwMQERJQE5/vUBLv7MmgACAC7/+gE5AS4AAgAFAEq7AAAAEAAEAAQrALgAAC+4AABFWLgAAS8buQABABE+WboAAgABAAAREjm6AAMAAQAAERI5ugAEAAEAABESOboABQABAAAREjkwMQERJRc1BwE5/vXehwEu/syaTZpNAAAAAQAuAAABYgELAAIAGAC4AAIvuAAARVi4AAEvG7kAAQARPlkwMSkBEwFi/syaAQsAAgAuAAABYgELAAIABQAeALgAAi+4AABFWLgAAC8buQAAABE+WbkAAwAF9DAxKQETBzMnAWL+zJpNmUwBC96JAAEALv/6AToBLgACACIAuAABL7gAAEVYuAAALxu5AAAAET5ZugACAAAAARESOTAxFxEFLgEMBgE0mgAAAAIALv/6ATkBLgACAAUASrsABAAQAAIABCsAuAACL7gAAEVYuAABLxu5AAEAET5ZugAAAAEAAhESOboAAwABAAIREjm6AAQAAQACERI5ugAFAAEAAhESOTAxJQURFycVATn+9bWIlJoBNJpNmgAAAAABAC7/+gFiAQUAAgAYALgAAS+4AABFWLgAAi8buQACABE+WTAxEyEDLgE0mgEF/vUAAAAAAgAu//oBYgEFAAIABQAeALgAAEVYuAABLxu5AAEAET5ZuwACAAUABQAEKzAxAQsBFzcjAWKamppMmQEF/vUBC7aJAAAB/+wAAAGyAQUAHABxuwAKAAsACQAEK7oAAAACAAMrugATABEAAyu6ABkACQAKERI5uAATELgAHtwAuAAKL7gAAEVYuAAALxu5AAAAET5ZuAAARVi4ABUvG7kAFQARPlm4AAAQuQAEAAP0uAAQ0LgAEdC6ABkAAAAEERI5MDExIjU0OwEyNj0BMxUUHgI7ATIVFCsBIiYnDgEjFBSiJik6DhYcDiUUFCchORIUNx4eICchf38UGxEIHiAYIyMYAP///+z/VAGyAQUCJgFfAAAABwC/AKr/lv///+z+6QGyAQUCJgFfAAAABwDDAMD/lv///+wAAAGyAbgCJgFfAAAABwDAAMkBeP///+wAAAGyAiUCJgFfAAAABwDCAMkBeP///+wAAAGyAboCJgFfAAAABwC+AO0BeP///+z/VgGyAQUCJgFfAAAABwDBAMr/lv///+wAAAGyAhkCJgFfAAAABwDtANABPAAB/+wAAAFYAQUADgA4uwAKAAsACQAEK7oAAAACAAMruAAKELgAENwAuAAKL7gAAEVYuAAALxu5AAAAET5ZuQAEAAP0MDExIjU0OwEyNj0BMxUUBiMUFM8jKztIPR4gJyF/f0BGAAAA////7P9UAVgBBQImAWcAAAAGAL9xlgAA////7P7pAVgBBQImAWcAAAAHAMMAiP+W////7AAAAVgBuAImAWcAAAAHAMAA0wF4////7AAAAVgCJQImAWcAAAAHAMIA0wF4////7AAAAVgBugImAWcAAAAHAL4A+wF4////7P9WAVgBBQImAWcAAAAHAMEAi/+W////7AAAAVgCGQImAWcAAAAHAO0A7AE8AAH/mf8kAPcBBQAcAFy7ABwACwAbAAQrugAGAAQAAyu4ABwQuAAM0LgADC+4AAYQuAAe3AC4ABwvuAAARVi4AAgvG7kACAARPlm7ABQAAwATAAQruAAIELkAAwAD9LoADAAIAAMREjkwMTcUFjsBMhUUKwEiJicVFA4CKwEnMzI+Aj0BM40qIgoUFAoWKg4hOk4uFgUQLEApFDuDHyYeIBAUFTVXPSI+HTA/IfYAAAAAAf+Z/yQAjQEFAA8AI7sACAALAAcABCu4AAgQuAAR3AC4AAgvuwAAAAMADwAEKzAxBzMyPgI9ATMVFA4CKwFnECxAKRQ7IjpPLhaeHTA/Ifb2NVc9IgAA////mf8kAPcBugAmAW8AAAAHAL4AaAF4////mf8kAI4BugImAXAAAAAHAL4AaAF4////mf8kAPcCJQAmAW8AAAAHAMIAZgF4////mf8kAMQCJQImAXAAAAAHAMIAZgF4AAH/mwAAAGUAugAGACYAuAAAL7gABS+4AABFWLgAAy8buQADABE+WboABgADAAAREjkwMTcXByMnNxdFIFUgVSBFuhSmphSM////ef5EAI8BBQImAFEAAAAHAXUAKv5E////ef5EAPcBBQImAFIAAAAHAXUAKv5EAAUALgAAAtECeQAiADIANgA6AD4A/LsAFgALABUABCu7ACMACwAAAAQruwAKAAsAKwAEK7sANgAIADUABCtBBQDKAAAA2gAAAAJdQRkACQAAABkAAAApAAAAOQAAAEkAAABZAAAAaQAAAHkAAACJAAAAmQAAAKkAAAC5AAAADF26AB4ANQA2ERI5uAArELgAN9C4ADcvuAArELkAOQAN9LgAIxC4ADzQuAA8L7gAIxC5AD4ADfS4AAoQuABA3AC4AABFWLgADi8buQAOABE+WbsANQADADQABCu7ADkAAwA4AAQruwAFAAMALgAEK7gADhC5ABoAA/S4AB7QuAAeL7gAOBC4ADvQuAA5ELgAPdAwMSU0PgIzMh4CHQEUBiMhIi4CPQEzFRQWMyEyNhcuAzcUHgIXNj0BNCYjIg4CEyM1MxcjNTMHIzUzAZ4UJjkmIjkpFlRb/pgmNSEQOyk1ARMgJRUzPB8INwcgQzseLjYXIxgNhUhIOklJc0lJ3Bk1KxsTKkMxKEdQFyYzHHpsKjICARIhJSsUEh4eIRUYMR05QRAaIQFSQK1AQEAABQAuAAADNgJtAA8AOQA9AEEARQFXuwAtAAsALAAEK7sAAwALADUABCu7ABUACwANAAQrugAaABgAAyu7AD0ACAA8AAQrQQUAygANANoADQACXUEZAAkADQAZAA0AKQANADkADQBJAA0AWQANAGkADQB5AA0AiQANAJkADQCpAA0AuQANAAxduAADELkARQAN9LoAMgADAEUREjlBBQDKADUA2gA1AAJdQRkACQA1ABkANQApADUAOQA1AEkANQBZADUAaQA1AHkANQCJADUAmQA1AKkANQC5ADUADF24AA0QuAA+0LgAPi+4AA0QuQBAAA30uAADELgAQ9C4AEMvuAAaELgAR9wAuAAA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AGcAaAB0AHMAIAByAGUAcwBlAHIAdgBlAGQALgAxAC4AMAAwADAAOwBCAGEAawBoADsAWQBlAGsAYQBuAEIAYQBrAGgALQBSAGUAZwB1AGwAYQByAFYAZQByAHMAaQBvAG4AIAAxAC4AMAAwADAAWQBlAGsAYQBuACAAQgBhAGsAaAAgAGkAcwAgAGEAIABUAHIAYQBkAGUAbQBhAHIAawAgAG8AZgAgAFIAZQB6AGEAIABCAGEAawBoAHQAaQBhAHIAaQBmAGEAcgBkACAAfAAgAEIAYQBrAGgAQwBvAG4AdABlAG0AcABvAHIAYQByAHkAIABQAGUAcgBzAGkAYQBuAC8AQQByAGEAYgBpAGMAIAB0AHkAcABlAGYAYQBjAGUALgAgAEQAZQBzAGkAZwBuAGUAZAAgAGIAeQAgAFIAZQB6AGEAIABCAGEAawBoAHQAaQBhAHIAaQBmAGEAcgBkAC4AaAB0AHQAcAA6AC8ALwB3AHcAdwAuAGIAYQBrAGgAdABpAGEAcgBpAGYAYQByAGQALgBpAHIAAAACAAAAAAAA/4oAGQAAAAAAAAAAAAAAAAAAAAAAAAAAAZYAAAABAAIAAwECAQMBBAEFAQYBBwEIAQkBCgELAQwBDQEOAQ8BEAERARIBEwEUARUBFgEXARgBGQEaARsBHADDAR0BHgEfASABIQEiASMBJAElASYBJwEoASkBKgErASwBLQEuAS8BMAExATIBMwE0ATUBNgE3ATgBOQE6ATsBPAE9AT4BPwFAAUEBQgFDAUQBRQFGAUcBSAFJAUoBSwFMAU0BTgFPAVABUQFSAVMBVAFVAVYBVwFYAVkBWgFbAVwBXQFeAV8BYAFhAWIBYwFkAWUBZgFnAWgBaQFqAWsBbAFtAW4BbwFwAXEBcgFzAXQBdQF2AXcBeAF5AXoBewF8AX0BfgF/AYABgQGCAYMBhAGFAYYBhwGIAYkBigGLAYwBjQGOAY8BkAGRAZIBkwGUAZUBlgGXAZgBmQGaAZsBnAGdAZ4BnwGgAaEBogGjAaQBpQGmAacBqAGpAaoBqwGsAa0BrgGvAbABsQGyAbMBtAG1AbYBtwG4AbkBugG7AbwBvQG+Ab8BwAHBAcIBwwHEAcUBxgHHAcgByQHKAcsBzAHNAc4BzwHQAdEB0gHTAdQB1QHWAdcB2AHZAdoB2wHcAd0B3gHfAeAB4QHiAeMB5AHlAeYB5wHoAekB6gHrAewB7QHuAe8B8AHxAfIB8wH0AfUB9gH3AfgB+QH6AfsB/AH9Af4B/wIAAgECAgIDABECBAAdAgUCBgAEAgcCCAIJAgoCCwIMAg0CDgAKAAUCDwIQAAsADACpAKoAvgC/AD4AQAASAD8AqwC2ALcAtAC1AAYADQAOABAAkwDwALgAIACPAKcApAAfACEAlACVAJIAgwC8AF4AYABfAOgAswCyAhECEgITAhQCFQBCAIgCFgIXABMAFAAVABYAFwAYABkAGgAbABwCGAIZAIcCGgIbAhwCHQIeAh8CIAIhAiICIwIkAiUCJgInAigCKQIqAisCLAItAi4CLwIwAjECMgIzAjQCNQI2AjcCOAI5AjoCOwI8Aj0CPgI/AkACQQJCAkMCRAJFAkYCRwJIAkkCSgJLAkwCTQJOAk8CUAJRAlICUwJUAlUCVgJXAlgCWRJub25tYXJraW5ncmV0dXJuLjESbm9ubWFya2luZ3JldHVybi4yB3VuaTAwQTAHdW5pMjAwMAd1bmkyMDAxB3VuaTIwMDQHdW5pMjAwNQd1bmkyMDA2B3VuaTIwMDcHdW5pMjAwOAd1bmkyMDA5B3VuaTIwMEIHdW5pMjAwQwd1bmkyMDBEB3VuaTIwMkYHdW5pRkVGRgd1bmkyMDYwB3VuaUZGRkMHdW5pMjAyOAd1bmkyMDI5B3VuaTIwMkEHdW5pMjAyQgd1bmkyMDJDB3VuaTIwMkQHdW5pMjAyRQd1bmkyMDBGB3VuaTIwMEUPa2FzaGlkYXMuTmFycm93B3VuaTA2NDANa2FzaGlkYXMuV2lkZQd1bmkwNjI3B3VuaUZFOEUHdW5pMDYyMgd1bmlGRTgyB3VuaTA2MjMHdW5pRkU4NAd1bmkwNjI1B3VuaUZFODgHdW5pMDY3MQd1bmlGQjUxB3VuaTA2MjgHdW5pRkU5MAd1bmlGRTkyB3VuaUZFOTEHdW5pMDY3RQd1bmlGQjU3B3VuaUZCNTkHdW5pRkI1OAd1bmkwNjJBB3VuaUZFOTYHdW5pRkU5OAd1bmlGRTk3B3VuaTA2MkIHdW5pRkU5QQd1bmlGRTlDB3VuaUZFOUIHdW5pMDYyQwd1bmlGRTlFB3VuaUZFQTAHdW5pRkU5Rgd1bmkwNjg2B3VuaUZCN0IHdW5pRkI3RAd1bmlGQjdDB3VuaTA2MkQHdW5pRkVBMgd1bmlGRUE0B3VuaUZFQTMHdW5pMDYyRQd1bmlGRUE2B3VuaUZFQTgHdW5pRkVBNwd1bmkwNjJGB3VuaUZFQUEHdW5pMDYzMAd1bmlGRUFDB3VuaTA2MzEHdW5pRkVBRQd1bmkwNjMyB3VuaUZFQjAHdW5pMDY5OAd1bmlGQjhCB3VuaTA2MzMHdW5pRkVCMgd1bmlGRUI0B3VuaUZFQjMHdW5pMDYzNAd1bmlGRUI2B3VuaUZFQjgHdW5pRkVCNwd1bmkwNjM1B3VuaUZFQkEHdW5pRkVCQwd1bmlGRUJCB3VuaTA2MzYHdW5pRkVCRQd1bmlGRUMwB3VuaUZFQkYHdW5pMDYzNwd1bmlGRUMyB3VuaUZFQzQHdW5pRkVDMwd1bmkwNjM4B3VuaUZFQzYHdW5pRkVDOAd1bmlGRUM3B3VuaTA2MzkHdW5pRkVDQQd1bmlGRUNDB3VuaUZFQ0IHdW5pMDYzQQd1bmlGRUNFB3VuaUZFRDAHdW5pRkVDRgd1bmkwNjQxB3VuaUZFRDIHdW5pRkVENAd1bmlGRUQzB3VuaTA2NDIHdW5pRkVENgd1bmlGRUQ4B3VuaUZFRDcHdW5pMDZBOQd1bmlGQjhGB3VuaUZCOTEHdW5pRkI5MAd1bmkwNjQzB3VuaUZFREEHdW5pMDZBRgd1bmlGQjkzB3VuaUZCOTUHdW5pRkI5NAd1bmkwNjQ0B3VuaUZFREUHdW5pRkVFMAd1bmlGRURGB3VuaTA2NDUHdW5pRkVFMgd1bmlGRUU0B3VuaUZFRTMHdW5pMDY0Ngd1bmlGRUU2B3VuaUZFRTgHdW5pRkVFNwd1bmkwNjQ4B3VuaUZFRUUHdW5pMDYyNAd1bmlGRTg2DGhlLmFyYWIuaXNvbAd1bmkwNjQ3B3VuaUZFRUEHdW5pRkVFQwd1bmlGRUVCB3VuaTA2MjkHdW5pRkU5NAd1bmkwNkMwB3VuaUZCQTUHdW5pMDZDQwd1bmlGQkZEB3VuaUZCRkYHdW5pRkJGRQd1bmkwNjRBB3VuaUZFRjIHdW5pMDYyNgd1bmlGRThBB3VuaUZFOEMHdW5pRkU4Qgd1bmkwNjQ5B3VuaUZFRjAHdW5pRkJFOQd1bmlGQkU4B3VuaTA2MjEHdW5pRkVGQgd1bmlGRUZDB3VuaUZFRjUHdW5pRkVGNgd1bmlGRUY3B3VuaUZFRjgHdW5pRkVGOQd1bmlGRUZBCWxhLnR2YXNsYQ5sYS50dmFzbGEuZmluYQd1bmlGREZDB3VuaUZERjIGbGVsbGFoB3VuaUZCQjIHdW5pRkJCMwd1bmlGQkI0B3VuaUZCQjUHdW5pRkJCNgd1bmlGQkI5B3VuaTA2RjAHdW5pMDZGMQd1bmkwNkYyB3VuaTA2RjMHdW5pMDZGNAd1bmkwNkY1B3VuaTA2RjYHdW5pMDZGNwd1bmkwNkY4B3VuaTA2RjkHdW5pMDY2MAd1bmkwNjYxB3VuaTA2NjIHdW5pMDY2Mwd1bmkwNjY0B3VuaTA2NjUHdW5pMDY2Ngd1bmkwNjY3B3VuaTA2NjgHdW5pMDY2OQRfMjE2CXNlZnIudG51bQh5ZWsudG51bQdkby50bnVtB3NlLnRudW0JY2hhci50bnVtCXBhbmoudG51bQpzaGlzaC50bnVtCWhhZnQudG51bQpoYXNodC50bnVtCG5vaC50bnVtDnNlZnIuYXJhYi50bnVtDXllay5hcmFiLnRudW0MZG8uYXJhYi50bnVtDHNlLmFyYWIudG51bQ5jaGFyLmFyYWIudG51bQ5wYW5qLmFyYWIudG51bQ9zaGlzaC5hcmFiLnRudW0OaGFmdC5hcmFiLnRudW0PaGFzaHQuYXJhYi50bnVtDW5vaC5hcmFiLnRudW0HdW5pMDY1NAd1bmkwNjU1B3VuaTA2NTMHdW5pMDY1Mgd1bmkwNjUxB3VuaTA2NEUHdW5pMDY0Rgd1bmkwNjUwB3VuaTA2NEIHdW5pMDY0Qwd1bmkwNjREB3VuaTA2NzAHdW5pMDY1NgZUdmFzbGEEXzI1MQd1bmlGQzYwB3VuaUZDNjEHdW5pRkM2Mg91bmkwNjRCX3VuaTA2NTEHdW5pRkM1RQd1bmlGQzVGB3VuaUZDNjMGYmUuZGxzC2JlLmRscy5maW5hC2ZlLmRscy5tZWRpC2ZlLmRscy5pbml0B3VuaTA2MEMHdW5pMDYxQgd1bmkwNjFGB3VuaTA2NkQHdW5pMDY2QQd1bmkwNjA5B3VuaTA2MEEHdW5pMDYwRAd1bmkwNjZDDGhlemFyLnNlcC51cAd1bmkwNjZCB3VuaUZEM0UHdW5pRkQzRgpmaWd1cmVkYXNoB3VuaTIwMTAHdW5pMjAxMQd1bmkyMDE1B3VuaTAwQUQHdW5pMjA0Qgd1bmkyNUNDBkgxODU0MwZIMTg1NTEKb3BlbmJ1bGxldAd1bmkyNUMyB3VuaTI1QzMHdW5pMjVCNAd1bmkyNUI1B3VuaTI1QjgHdW5pMjVCOQd1bmkyNUJFB3VuaTI1QkYMdG9vdGguay5tZWRpCWJlLmsubWVkaQlwZS5rLm1lZGkJdGUuay5tZWRpCnRoZS5rLm1lZGkKbnVuLmsubWVkaQl5ZS5rLm1lZGkJaWUuay5tZWRpDHRvb3RoLmsuaW5pdAliZS5rLmluaXQJcGUuay5pbml0CXRlLmsuaW5pdAp0aGUuay5pbml0Cm51bi5rLmluaXQJeWUuay5pbml0CWllLmsuaW5pdAlyZS5jLmZpbmEEcmUuYwl6ZS5jLmZpbmEEemUuYwlqZS5jLmZpbmEEamUuYwRfMzczB3VuaTA2OTUKcmUuYnYuZmluYQd1bmkwNkE0B3VuaUZCNkIHdW5pRkI2RAd1bmlGQjZDB3VuaTA2QjULbGFtLnR2LmZpbmEKbGFtLnR2bWVkaQtsYW0udHYuaW5pdAd1bmkwNkM2B3VuaUZCREEHdW5pMDZDQQx2YXYudDJwLmZpbmEHdW5pMDZDMhFoZS50aG16LmdvYWwuZmluYQd1bmkwNkQ1B2FlLmZpbmEHdW5pMDZCRQd1bmlGQkFCB3VuaUZCQUQHdW5pRkJBQwd1bmkwNkNFCnllLnR2LmZpbmEKeWUudHYubWVkaQp5ZS50di5pbml0BWxhLnR2CmxhLnR2LmZpbmEMeWUudHYuay5tZWRpDHllLnR2LmsuaW5pdAxyZS5idi5jLmZpbmEHcmUuYnYuYwAAAAH//wADAAAAAQAAAAAAAQAAAAwAAAAAAAAAAgALAAAAsAABALEAugACALsAuwABALwAvAACAL0AvQABAL4AwwAEAMQA7AABAO0BAgADAQMBjwABAZABkQACAZIBlQABAAAAAQAAAAoAIgBMAAFhcmFiAAgABAAAAAD//wADAAAAAQACAANrZXJuABRtYXJrABpta21rACIAAAABAAQAAAACAAAAAQAAAAIAAgADAAUADAAUABwAJAAsAAQAAQABACgABQABAAEJCAAGAAEAAQtIAAYAAQABC/IAAgAJAAEMSAABAAwAHAACAFYArAACAAIA7QD6AAAA/AECAA4AAgAJACMAsAAAALsAuwCOAL0AvQCPAWABZgCQAWgBdACXAXYBewCkAYABhwCqAYkBjwCyAZIBlQC5ABUAAANMAAEDTAAAA0wAAANMAAADTAAAA0wAAANMAAEDTAAAA0wAAANMAAEDTAAAA0wAAQNMAAADTAAAA0wAAANMAAADTAAAA0wAAANMAAADTAAAA0wAvQL8AwIDCAMOAxQDGgMgAyYDLAMCAzIDOAM+A0QDSgNQA1YDXANiA2gDbgN0A24DdAN6A4ADhgOMA5IDmAOSA5gDngOkA6oDsAO2A7wDtgO8A8IDyAPOA9QD2gPgA9oD4APmA+wD8gP4A/4EBAP+BAQECgQQBAoEEAQWBBwEFgQcBCIEKAQiBCgELgQ0BC4ENAQiBDoEIgQ6BEAERgRABEYETARSBEwEUgRYBF4EZARqBHAEdgR8BGoEggSIBIIEiASOBJQEjgSUBJoEoASaBKAEpgSsBKYErASyBLgEsgS4BKYErASmBKwEvgTEBL4ExATKBKwEygSsBNAE1gTQBNYEygSsBMoErATcBOIE3ATiBOgE7gToBO4E9AT6BPQE+gUABQYFAAUGBQwFEgUMBRIFGAUeA/4FJAUqBTAFNgU8BUIFSAVOBVQFWgVgBU4FZgVsBXIFbAVyBXgFfgWEBYoFkAWWBZAFlgV4BX4FhAWKBZwD4AWcA+AFogWoBaIFqAWuBbQFrgW0BboD4AW6A+AFwAXGBcAFxgXMBdIFzAXSBdgF3gXYBd4F5AXqBeQF6gQiBfAEIgXwBfYF/AX2BfwGAgYIBg4GFAYaBiAGGgYgBiYGLAYmBiwGMgY4Bj4FxgZEBkoGUAZWBlwGYgZoBTwGbgZ0BnoFZgaABoYDngX8BowGkgaYBp4GpAaqBrAGtga8BrYGwgbIBs4G1AbaA8gG4ANcA54F/AaMBpIG5gYIBuwDGgbyBvgG/gSsBwQHCgN6BxAHFgccByIHKAcuBzQHOgdAB0YHTAdSBTwHWAdeB2QHagdwBggHdgPIB3wGCAeCB4gHjgeUBIIEiASCBIgEjgSUBI4ElASaBKAEmgSgB5oHoAeaB6AFbAVyBWwFcgemB6wHsge4B74HxAe+B8QHygfQB8oH0AfWB9wH4gfoBj4FxgZEBkoH7gf0BlAGVgZcBmIH+ggACAYIDAgSCBgIHggkCCoIMAgqCDYHmgegB5oHoAABAAAAAAABAEYCiwABAFT/pQABAFQCiwABAIz/lwABAE0ChAABAFv/ngABAE0CfQABAH7/ngABAEYDFwABAEYDEAABAHf/ngABAEYChAABAHf+fwABAE0CiwABAJr+hgABAE0C7QABAGL/ngABAFQC9AABAIX/pQABAVABZQABAVD+6AABAK8BXgABAKH+4QABAHABbAABAFv+0wABAVABVwABAVf+hgABAK8BZQABAJP+hgABAH4BbAABAGL+hgABAVAB6gABAWX/pQABALYCBgABAJr/pQABAIUCDQABAHD/lwABAVcCRQABAVf/pQABAK8CYQABAKH/swABAIUCaAABAE3/pQABAOABsgABAQP+QAABANkBuQABAOD+6AABAOABuQABAR/+QAABAPUBsgABAQP+jQABANIBsgABAQP+TgABAPX/ngABAOACWgABAQr+QAABAOACUwABAPX/rAABANkCBgABAMv/ngABAPwB8QABANL/pQABANICrgABANn/pQABAO4CtQABAGkBbAABAAD+zAABAGICDQABAA7+xQABAGICdgABAAf+0wABAPwBHwABARj+vgABAXMBXgABAWz/pQABAXMCdgABAWX/rAABAQMBNAABAJMBcwABAYH/pQABAccCWgABAZb/pQABAY8BuQABAS3/pQABAXoBsgABAQr/ngABAZYCYQABAR//lwABAXMCWgABARj/ngABAPUBqwABAPz+OQABAPz+QAABAQMBpAABAQr/swABAOcBpAABAMv/lwABAO4CUwABAPX+RwABANkCaAABAPz+RwABAQoCaAABAPz/rAABAMT/pQABAO4BpAABAV7/lwABAPwCWgABAO7/pQABAO4CbwABAKj/pQABAbICTAABAS3+zAABAKEBiAABAL0CbwABAJr/rAABATsCTAABAVD/rAABAJoBgQABAK8C5gABALb/pQABAOcBSQABARH+xQABAH4CiwABAHf/rAABATsBsgABAWX/ngABAOf/pQABAREBwAABAR/+zAABAK8CFAABAJr/ngABAJoCIgABAFv/lwABAMQBlgABAKH+zAABAKgCrgABAJr+vgABAL0BsgABAS3/WAABAMsCFAABANIB8QABAL3/ugABAOcBuQABAMT+xQABAO4BwAABAPz/pQABAL0CoAABAO4ChAABAMT/wQABAL0DEAABAMsC5gABAL3/zwABAVcAxAABAR/+0wABAK8BbAABAJr+/QABAGIBcwABAGn+9gABAJMBXgABARj+KwABAVcAqAABAH4CUwABASb+vgABARgB3AABARH+vgABAJMChAABAIwChAABAK8BcwABAHABZQABAKgBxwABAL3/pQABAQMBGAABAL0B3AABAMT/zwABAK/+6AABAKgBVwABAMv+hgABAMsCBgABANL/lwABAMsChAABAOD/ngABAO4CGwABAL3/ngABAKEBUAABANn+/QABAMsCdgABAJoBVwABAHf+7wABAJMBbAABAJP+jQABANkCDQABAOACbwABAPUCFAABAKgBXgABAJr/BAABAOcCbwABAJr/kAABAGYBYgABACT99gABAQICvgABAPD/pgABAPYCvgABAKj/pgABAMwCiAABAJz+zgABANICOgABAJb+vAABAMADQgABAMb/rAABAPwDJAABAMD/ygABAUEBpwABARr+zgABAJACNAABASD+wgABAQgBwgABASD+yAABALQCagABAJz+/gABAGYCUgABAGD/BAABAMYCXgABANL++AABAJD++AABAAwAHAACADIAiAACAAIA7QD6AAAA/AECAA4AAgADALEAugAAALwAvAAKAZABkQALABUAAAD8AAEA/AAAAPwAAAD8AAAA/AAAAPwAAAD8AAEA/AAAAPwAAAD8AAEA/AAAAPwAAQD8AAAA/AAAAPwAAAD8AAAA/AAAAPwAAAD8AAAA/AAAAPwADQAcACYAMAA6AEQATgBYAGIAbAB2AIAAkgCcAAIAkACWAJwAogACAIYAngCkAKoAAgCmAKwAsgC4AAIAtAC6AMAAxgACAMIAgADIAKQAAgCgAMQAygDQAAIAzADSANgA3gACANoA4ADmAOwAAgCCAOgA7gD0AAIAxgDwAPYA/AAEAPgA/gEEAQoBEAEWARwBIgACARYBHAEiASgAAgEMARIBGAEeAAEAAAAAAAEBVwKEAAEBSf+sAAEATQJ9AAEAaf+XAAEBUP+sAAEATQKEAAEAd/+eAAEBVwKZAAEBUP+XAAEARgKnAAEAhf+XAAEBXgKLAAEBZf+zAAEAVAKnAAEAhf+eAAEBXgKSAAEAWwMQAAEBbP+zAAEATQMJAAEAd/+lAAEBUAKEAAEBUP+lAAEAWwKEAAEAk/54AAEBVwKSAAEBbP+eAAEAVAKEAAEAjP6GAAEBV/+zAAEAfgLtAAEAfv+eAAEBZf+lAAEAcALmAAEAfv+sAAED9wKEAAED6f+lAAEDZAIiAAEC+/+zAAECUwOcAAEB6v+sAAEAywHVAAEAxP/IAAEBSgNCAAEBRP+4AAEATgM8AAEAbP+yAAEADAAkAAEAPABmAAEACgDtAO8A8ADxAPIA8wD1APYA+AD6AAEACgDtAO8A8ADxAPIA8wD1APYA+AD6AAoAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAoAHAAiABwAKAAuADQAHAA6AEAARgABAAAAAAABAAABJgABAAcAywAB//kBCgABAAAAxAABAAABOwABAAABNAABAAAA7gABAAcBCgABAAwAGAABACQANgABAAQA7gD0APcA+QABAAQA7gD0APcA+QAEAAAAHAAAABwAAAAcAAAAHAAEABAAFgAcACIAAQAAAAAAAQAH/uEAAQAH/0MAAQAA/uEAAQAA/xkAAQTMAAAABAAkAFIAUgBkAGQBAgECAUgBSAFeAV4ByAHIAcgByAIyAjIAUgBSAGQAZAECAQIBSAFIAV4BXgLgAuAC4ALgA0oDSgP4A/gEYgRiAAQAJQAyACsAMgBVABQBdAAUACcAIwA8ACUAggAnAFAAKQA8ACsAeAA4AEYAPABGAFMAMgBVAGQAewAUAH4AFAB/ADwAggA8AIMAPACFADwAiAA8AIkAPACMADwAlABGAJUAFACXABQAqwBGALEAPACzADwAtQA8ALcAPAC5ADwBagAyAWsAMgFsADIBbgAyAXIAMgF0AGQBfAA8AX8AUAGAABQBggAUAY8ARgGTADIAEQAlAGQAJwBGACsAeAA4ABQAPAAUAFMAFABVADIAfwAeAIIAHgCFAB4AiAAeAJQAFACrABQBcgAUAXQAMgF/AEYBjwAUAAUAJQAyACkARgArADwAVQAUAXQAFAAaACMAHgAlAHgAJwBaACkAHgArAIIAOAAUADwAFABVADwAfwAyAIIAMgCDAB4AhQAyAIgAMgCJAB4AjAAeAJQAFACrABQAsQAeALMAHgC1AB4AtwAeALkAHgF0ADwBfAAeAX8AWgGPABQAGgADAFAAKQDIAD0APABBADwAUQA8AFMAPABVADwAewA8AH4APACJADwAkQA8AJUAPACXADwAogA8AKYAPACoADwArAA8AXAAPAFyADwBdAA8AXYAPAF8ADwBgAA8AYIAPAGMADwBlQA8ACsAAwBQACMAHgAlAEYAJwAUACkAyAArADIAOAAoADwAKAA9ADwAQQA8AFEAPABTADwAVQA8AHsAPAB+ADwAgwAeAIkAPACMAB4AkQA8AJQAKACVADwAlwA8AKIAPACmADwAqAA8AKsAKACsADwAsQAeALMAHgC1AB4AtwAeALkAHgFwADwBcgA8AXQAPAF2ADwBfAA8AX8AFAGAADwBggA8AYwAPAGPACgBlQA8ABoAAwBGACkAtAA9ADwAQQA8AFEAMgBTADIAVQAyAHsAMgB+ADIAiQAyAJEAMgCVADIAlwAyAKIAMgCmADIAqAAyAKwAMgFwADIBcgAyAXQAMgF2ADIBfAAyAYAAMgGCADIBjAAyAZUAMgArAAMARgAjAB4AJQBGACcAFAApALQAKwAyADgAKAA8ACgAPQA8AEEAPABRADIAUwAyAFUAMgB7ADIAfgAyAIMAHgCJADIAjAAeAJEAMgCUACgAlQAyAJcAMgCiADIApgAyAKgAMgCrACgArAAyALEAHgCzAB4AtQAeALcAHgC5AB4BcAAyAXIAMgF0ADIBdgAyAXwAMgF/ABQBgAAyAYIAMgGMADIBjwAoAZUAMgAaAAMAUAApAMgAPQBQAEEAUABRADwAUwA8AFUAPAB7ADwAfgA8AIkAPACRADwAlQA8AJcAPACiADwApgA8AKgAPACsADwBcAA8AXIAPAF0ADwBdgA8AXwAPAGAADwBggA8AYwAPAGVADwAGgADAEYAKQC0AD0AUABBAFAAUQAyAFMAMgBVADIAewAyAH4AMgCJADIAkQAyAJUAMgCXADIAogAyAKYAMgCoADIArAAyAXAAMgFyADIBdAAyAXYAMgF8ADIBgAAyAYIAMgGMADIBlQAyAAIABgAjACwAAABRAFYACgCxALoAEAFvAXQAGgF2AXcAIAGUAZUAIgABAAAACgAqAI4AAWFyYWIACAAEAAAAAP//AAcAAAABAAMABAAFAAYAAgAHYWFsdAAsY2NtcAA0ZmluYQA6aW5pdABAbWVkaQBGcmxpZwBMdG51bQBeAAAAAgADAAQAAAABAAUAAAABAAIAAAABAAAAAAAB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) format('truetype');
}
* { box-sizing: border-box; font-family: 'YekanBakh', Tahoma, sans-serif !important; }
body {
    margin: 0;
    padding: 12px;
    font-family: 'YekanBakh', Tahoma, sans-serif;
    font-size: 14px;
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
    justify-content: flex-end;
    gap: 8px;
    margin-bottom: 10px;
}
.btn-fullscreen {
    background: #0073e6;
    color: #fff;
    border: 2px solid #005bb5;
    border-radius: 8px;
    padding: 8px 16px;
    font-family: 'YekanBakh', Tahoma, sans-serif;
    font-size: 14px;
    font-weight: bold;
    cursor: pointer;
}
.btn-fullscreen:hover { background: #005bb5; }
.help-overlay {
    display: none;
    position: fixed;
    top: 0; left: 0; right: 0; bottom: 0;
    background: rgba(0,0,0,0.5);
    z-index: 100;
    align-items: center;
    justify-content: center;
}
.help-overlay.open { display: flex; }
.help-modal {
    background: #fff;
    border-radius: 10px;
    max-width: 640px;
    width: 90%%;
    max-height: 80vh;
    overflow-y: auto;
    padding: 0;
    box-shadow: 0 8px 24px rgba(0,0,0,0.3);
}
.help-modal-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    background: #0073e6;
    color: #fff;
    padding: 12px 16px;
    border-radius: 10px 10px 0 0;
    font-size: 15px;
    position: sticky;
    top: 0;
}
.help-close {
    background: transparent;
    border: none;
    color: #fff;
    font-size: 16px;
    cursor: pointer;
    padding: 0 6px;
}
.help-modal-body { padding: 16px; text-align: right; }
.help-modal-body p { margin: 10px 0; line-height: 1.8; }
.help-modal-body ul { margin: 6px 0 14px; padding-right: 20px; }
.help-modal-body li { margin: 6px 0; line-height: 1.7; }
.help-modal-body code { background: #f0f2f5; padding: 2px 6px; border-radius: 4px; }
.report-header {
    background-color: #D2E0FB;
    text-align: center;
    border: 1px dotted #000;
    border-radius: 10px;
    padding: 12px 10px 16px;
    margin-bottom: 12px;
}
.report-header p { margin: 4px 0; font-size: 14px; }
.report-header p:first-child { font-size: 15px; font-weight: bold; }
.meta-line {
    font-size: 14px;
    color: #333;
    margin-top: 8px;
}
.tab-bar {
    display: flex;
    flex-wrap: wrap;
    gap: 6px;
    margin-bottom: 10px;
}
.tab-btn {
    background: #fff;
    border: 2px solid #0073e6;
    color: #0073e6;
    border-radius: 8px;
    padding: 8px 14px;
    font-family: 'YekanBakh', Tahoma, sans-serif;
    font-size: 14px;
    font-weight: bold;
    cursor: pointer;
}
.tab-btn.active {
    background: #0073e6;
    color: #fff;
}
.tab-panel { display: none; }
.tab-panel.active { display: block; }
.table-wrap {
    overflow: auto;
    max-height: 72vh;
    border: 2px solid #000;
    border-radius: 8px;
    background: #fff;
}
table {
    width: auto;
    table-layout: auto;
    border-collapse: collapse;
    text-align: center;
}
thead th {
    position: sticky;
    top: 0;
    z-index: 2;
    background-color: #0073e6;
    color: #fff;
    border: 1px dashed #000;
    padding: 10px 8px;
    font-size: 15px;
    font-weight: bold;
    white-space: nowrap;
    width: 1%%;
    cursor: pointer;
    user-select: none;
}
thead th.sort-asc::after { content: ' ▲'; }
thead th.sort-desc::after { content: ' ▼'; }
tbody td {
    border: 1px dashed #000;
    padding: 8px;
    font-size: 14px;
    vertical-align: middle;
    white-space: nowrap;
    width: 1%%;
}
tbody tr:nth-child(even) { background-color: #eeeeee; }
tbody tr:hover { filter: brightness(0.97); }
.summary-table {
    width: 100%%;
    border-collapse: collapse;
    margin-bottom: 12px;
    border: 2px solid #000;
    border-radius: 8px;
    overflow: hidden;
}
.summary-table td {
    border: 1px dashed #000;
    padding: 10px 8px;
    text-align: center;
    font-size: 14px;
}
.summary-table .summary-head {
    background: #4472C4;
    color: #fff;
    font-size: 15px;
    font-weight: bold;
}
.summary-table .summary-value {
    background: #5B9BD5;
    color: #fff;
    font-size: 14px;
    font-weight: bold;
}
.mono { letter-spacing: 0.3px; }
.clickable-row { cursor: pointer; }
.clickable-row:hover { filter: brightness(0.9); }
.receipt-link { color: #0073e6; text-decoration: underline; }
.receipt-link:hover { color: #b42318; }
.name-cell { text-align: right; font-weight: bold; white-space: nowrap; }
.col-replaced {
    text-align: right;
    white-space: nowrap;
}
.wrap-cell {
    white-space: normal !important;
    word-break: break-word;
    max-width: 480px;
}
.empty-row { padding: 24px !important; color: #666; }
.rate-good { background: #c6efce; color: #006100; font-weight: bold; }
.rate-warning { background: #ffeb9c; color: #9c6500; font-weight: bold; }
.rate-critical { background: #ffc7ce; color: #9c0006; font-weight: bold; }
.rate-neutral { color: #666; }
.footer {
    text-align: center;
    color: #666;
    font-size: 14px;
    margin-top: 10px;
}
</style>
</head>
<body>
<div id="reportRoot">
    <div class="toolbar">
        <button type="button" class="btn-fullscreen" id="btnFullscreen" onclick="toggleFullScreen()">تمام صفحه</button>
        <button type="button" class="btn-fullscreen" onclick="exportActiveTabToExcel()">خروجی Excel</button>
        <button type="button" class="btn-fullscreen" onclick="openHelpModal()">راهنما</button>
    </div>

    <div id="helpModalOverlay" class="help-overlay" onclick="if(event.target===this){closeHelpModal();}">
        <div class="help-modal">
            <div class="help-modal-header">
                <strong>راهنمای گزارش کالاهای تعویض‌شده</strong>
                <button type="button" class="help-close" onclick="closeHelpModal()">✕</button>
            </div>
            <div class="help-modal-body">
                <p><strong>این گزارش چیست؟</strong> ماتریس و جزئیات کالاهای تعویض‌شده در گارانتی، به‌همراه آمار فروش، گارانتی و بهای تمام‌شده. «تعداد تعویض» فقط مواردی را می‌شمارد که خروج فیزیکی‌شان از انبار تایید شده باشد (نه صرفاً ثبت اولیه در سیستم خدمات).</p>

                <p><strong>ستون‌های تب «ماتریس کالا»:</strong></p>
                <ul>
                    <li><b>کد کالا / نام کالا</b> — کالایی که مشتری با آن خراب آورده (original_product_code)</li>
                    <li><b>کالای جایگزین</b> — خلاصهٔ کالاهایی که به‌جای آن داده شده</li>
                    <li><b>تعداد تعویض</b> — تعداد تعویض‌های تایید‌شده از انبار برای این کد کالا</li>
                    <li><b>فروش کل / فروش در بازه</b> — مجموع فروش این کالا (کل تاریخچه / فقط بازهٔ انتخابی)</li>
                    <li><b>گارانتی‌شده / گارانتی فعال / کل پذیرش‌شده / تعمیرشده در بازه / میزان برگشتی — ستون‌های «(دسته)»</b> — این آمار روی کل خانواده/دسته‌بندی کالا (PARENT در wh_product) جمع زده می‌شود. برخی دسته‌ها (مثلاً «هدست بلوتوث») صدها مدل متفاوت را زیر یک PARENT دارند؛ این اعداد می‌توانند خیلی بزرگ‌تر از خود این کد کالا باشند.</li>
                    <li><b>همان ستون‌ها با برچسب «(این کالا)»</b> — دقیقاً همان آمار ولی فقط برای همین یک کد کالای دقیق (بدون احتساب سایر اعضای دسته). برای تحلیل دقیق «همین مدل»، این ستون‌ها را ببینید نه ستون‌های «(دسته)».</li>
                    <li><b>بهای تمام‌شده اصلی / جایگزین / قطعات / جمع</b> — اجزای هزینهٔ تعویض</li>
                    <li><b>میزان برگشتی (درصد خرابی) / وضعیت</b> — کل پذیرش‌شده ÷ گارانتی‌شده × ۱۰۰، و برچسب وضعیت (قابل قبول / هشدار / بحرانی)</li>
                </ul>

                <p><strong>ستون‌های تب «جزئیات تعویض»:</strong></p>
                <ul>
                    <li><b>شماره پذیرش</b> — لینک مستقیم به صفحهٔ پذیرش خدمات در تیمیار</li>
                    <li><b>سریال</b> — سریال کالای مشتری</li>
                    <li><b>تاریخ خرابی / تاریخ تعویض</b> — تاریخ‌های ثبت‌شده در پذیرش و در رکورد تعویض</li>
                    <li><b>علت تعویض</b> — علت ثبت‌شده برای تعویض</li>
                    <li>بقیهٔ ستون‌ها مشابه «ماتریس کالا» است، مختص همان یک رکورد پذیرش</li>
                </ul>

                <p><strong>تعامل‌های گزارش:</strong></p>
                <ul>
                    <li>کلیک روی هر ردیف در «ماتریس کالا» → تب «جزئیات تعویض» فقط برای همان کد کالا فیلتر می‌شود</li>
                    <li>کلیک روی «شماره پذیرش» → صفحهٔ پذیرش همان رکورد در تب جدید باز می‌شود</li>
                    <li>کلیک روی هر هدر ستون → مرتب‌سازی صعودی/نزولی بر اساس آن ستون</li>
                    <li>دکمهٔ «خروجی Excel» → جدول تب فعال (با احتساب فیلتر جاری) را به CSV/Excel خروجی می‌گیرد</li>
                </ul>

                <p><strong>پارامترهای ورودی:</strong> <code>product_code</code>، <code>from_date</code>/<code>to_date</code> (شمسی، مثل 1405-01-01)، <code>receipt_no</code>، <code>format=json</code> برای خروجی خام.</p>
            </div>
        </div>
    </div>

    <div class="report-header">
        <p><strong>گزارش کالاهای تعویض‌شده</strong></p>
        <p>ماتریس کالا و جزئیات تعویض با آمار فروش، گارانتی و بهای تمام‌شده</p>
        <div class="meta-line">
            از تاریخ: %s | تا تاریخ: %s | کد کالا: %s | شماره پذیرش: %s | زمان تولید: %s
        </div>
    </div>

    <table class="summary-table">
        <tr class="summary-head">
            <td>تعداد تعویض</td>
            <td>تعداد کالا</td>
            <td>میانگین برگشتی</td>
            <td>بحرانی</td>
        </tr>
        <tr>
            <td class="summary-value">%s</td>
            <td class="summary-value">%s</td>
            <td class="summary-value">%s</td>
            <td class="summary-value">%s</td>
        </tr>
    </table>

    <div class="tab-bar">
        <button type="button" class="tab-btn active" data-tab="tab-matrix" onclick="switchTab(this)">ماتریس کالا</button>
        <button type="button" class="tab-btn" data-tab="tab-detail" onclick="switchTab(this)">جزئیات تعویض</button>
    </div>

    <div class="tab-panel active" id="tab-matrix">
        <div class="table-wrap">
            <table>
                <thead>
                    <tr>
                        <th>ردیف</th>
                        <th>کد کالا</th>
                        <th>نام کالا</th>
                        <th class="col-replaced">کالای جایگزین</th>
                        <th>تعداد تعویض</th>
                        <th>فروش کل</th>
                        <th>فروش در بازه</th>
                        <th>گارانتی‌شده (دسته)</th>
                        <th>گارانتی فعال (دسته)</th>
                        <th>کل پذیرش‌شده (دسته)</th>
                        <th>تعمیرشده در بازه (دسته)</th>
                        <th>میزان برگشتی (دسته)</th>
                        <th>گارانتی‌شده (این کالا)</th>
                        <th>گارانتی فعال (این کالا)</th>
                        <th>کل پذیرش‌شده (این کالا)</th>
                        <th>تعمیرشده در بازه (این کالا)</th>
                        <th>میزان برگشتی (این کالا)</th>
                        <th>بهای تمام‌شده اصلی</th>
                        <th>بهای تمام‌شده جایگزین</th>
                        <th>بهای تمام‌شده قطعات</th>
                        <th>جمع بهای تمام‌شده</th>
                        <th>وضعیت</th>
                    </tr>
                </thead>
                <tbody id="matrixTbody">%s</tbody>
            </table>
        </div>
    </div>

    <div class="tab-panel" id="tab-detail">
        <div class="table-wrap">
            <table>
                <thead>
                    <tr>
                        <th>ردیف</th>
                        <th>شماره پذیرش</th>
                        <th>سریال</th>
                        <th>تاریخ خرابی</th>
                        <th>تاریخ تعویض</th>
                        <th>علت تعویض</th>
                        <th>کد کالای اصلی</th>
                        <th>نام کالای اصلی</th>
                        <th class="col-replaced">کالای جایگزین</th>
                        <th>فروش کل</th>
                        <th>فروش در بازه</th>
                        <th>گارانتی‌شده (دسته)</th>
                        <th>گارانتی فعال (دسته)</th>
                        <th>کل پذیرش‌شده (دسته)</th>
                        <th>تعمیرشده در بازه (دسته)</th>
                        <th>میزان برگشتی (دسته)</th>
                        <th>گارانتی‌شده (این کالا)</th>
                        <th>گارانتی فعال (این کالا)</th>
                        <th>کل پذیرش‌شده (این کالا)</th>
                        <th>تعمیرشده در بازه (این کالا)</th>
                        <th>میزان برگشتی (این کالا)</th>
                        <th>بهای تمام‌شده اصلی</th>
                        <th>بهای تمام‌شده جایگزین</th>
                        <th>بهای تمام‌شده قطعات</th>
                        <th>جمع بهای تمام‌شده</th>
                        <th>وضعیت</th>
                    </tr>
                </thead>
                <tbody id="detailTbody">%s</tbody>
            </table>
        </div>
    </div>

    <div class="footer">Teamyar Replaced Products Matrix Report</div>
</div>

<script>
function activateTab(tabId) {
    var tabs = document.getElementsByClassName('tab-btn');
    for (var i = 0; i < tabs.length; i++) {
        tabs[i].classList.toggle('active', tabs[i].getAttribute('data-tab') === tabId);
    }
    var panels = document.getElementsByClassName('tab-panel');
    for (var j = 0; j < panels.length; j++) {
        panels[j].classList.remove('active');
    }
    document.getElementById(tabId).classList.add('active');
}

function switchTab(btn) {
    activateTab(btn.getAttribute('data-tab'));
    if (btn.getAttribute('data-tab') === 'tab-detail') {
        filterDetailByCode(null);
    }
}

function filterDetailByCode(code) {
    activateTab('tab-detail');
    var rows = document.querySelectorAll('#detailTbody tr[data-code]');
    for (var k = 0; k < rows.length; k++) {
        var r = rows[k];
        r.style.display = (!code || r.getAttribute('data-code') === code) ? '' : 'none';
    }
}

function csvEscapeCell(text) {
    var t = (text || '').replace(/\s+/g, ' ').trim();
    if (t.indexOf(',') !== -1 || t.indexOf('"') !== -1 || t.indexOf('\n') !== -1) {
        t = '"' + t.replace(/"/g, '""') + '"';
    }
    return t;
}

function exportActiveTabToExcel() {
    var activePanel = document.querySelector('.tab-panel.active');
    if (!activePanel) {
        return;
    }
    var table = activePanel.querySelector('table');
    if (!table) {
        return;
    }

    var lines = [];
    var headerCells = table.querySelectorAll('thead th');
    var headerLine = [];
    for (var h = 0; h < headerCells.length; h++) {
        headerLine.push(csvEscapeCell(headerCells[h].innerText));
    }
    lines.push(headerLine.join(','));

    var rows = table.querySelectorAll('tbody tr');
    for (var i = 0; i < rows.length; i++) {
        var row = rows[i];
        if (row.style.display === 'none' || row.classList.contains('empty-row')
            || row.querySelector('td.empty-row')) {
            continue;
        }
        var cells = row.querySelectorAll('td');
        var line = [];
        for (var c = 0; c < cells.length; c++) {
            line.push(csvEscapeCell(cells[c].innerText));
        }
        lines.push(line.join(','));
    }

    var csvContent = '﻿' + lines.join('\r\n');
    var blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    var url = URL.createObjectURL(blob);
    var tabLabel = activePanel.id === 'tab-matrix' ? 'ماتریس-کالا' : 'جزئیات-تعویض';
    var link = document.createElement('a');
    link.href = url;
    link.download = 'گزارش-کالاهای-تعویض‌شده-' + tabLabel + '.csv';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
}

function toggleFullScreen() {
    var root = document.getElementById('reportRoot');
    var btn = document.getElementById('btnFullscreen');
    var isFull = document.fullscreenElement || document.webkitFullscreenElement || document.msFullscreenElement;

    if (!isFull) {
        if (root.requestFullscreen) {
            root.requestFullscreen();
        } else if (root.webkitRequestFullscreen) {
            root.webkitRequestFullscreen();
        } else if (root.msRequestFullscreen) {
            root.msRequestFullscreen();
        }
        btn.innerText = 'خروج از تمام صفحه';
    } else {
        if (document.exitFullscreen) {
            document.exitFullscreen();
        } else if (document.webkitExitFullscreen) {
            document.webkitExitFullscreen();
        } else if (document.msExitFullscreen) {
            document.msExitFullscreen();
        }
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

function getCellSortValue(cell) {
    var text = cell ? cell.innerText.trim() : '';
    var numText = text.replace(/[,٪%%]/g, '').trim();
    if (numText !== '' && /^-?\d+(\.\d+)?$/.test(numText)) {
        return parseFloat(numText);
    }
    return text;
}

function sortTableByColumn(table, colIndex, dir) {
    var tbody = table.querySelector('tbody');
    var rows = Array.prototype.slice.call(tbody.querySelectorAll('tr'));
    rows.sort(function (rowA, rowB) {
        var a = getCellSortValue(rowA.children[colIndex]);
        var b = getCellSortValue(rowB.children[colIndex]);
        var cmp;
        if (typeof a === 'number' && typeof b === 'number') {
            cmp = a - b;
        } else {
            cmp = String(a).localeCompare(String(b), 'fa');
        }
        return dir === 'asc' ? cmp : -cmp;
    });
    rows.forEach(function (row) { tbody.appendChild(row); });
}

function initSortableTables() {
    var tables = document.querySelectorAll('.table-wrap table');
    tables.forEach(function (table) {
        var headers = table.querySelectorAll('thead th');
        headers.forEach(function (th, colIndex) {
            th.addEventListener('click', function () {
                var dir = th.classList.contains('sort-asc') ? 'desc' : 'asc';
                headers.forEach(function (h) { h.classList.remove('sort-asc', 'sort-desc'); });
                th.classList.add(dir === 'asc' ? 'sort-asc' : 'sort-desc');
                sortTableByColumn(table, colIndex, dir);
            });
        });
    });
}

function wrapLongCells() {
    var cells = document.querySelectorAll('.table-wrap td');
    cells.forEach(function (td) {
        if (td.innerText && td.innerText.length > 150) {
            td.classList.add('wrap-cell');
        }
    });
}

function openHelpModal() {
    document.getElementById('helpModalOverlay').classList.add('open');
}

function closeHelpModal() {
    document.getElementById('helpModalOverlay').classList.remove('open');
}

document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') {
        closeHelpModal();
    }
});

initSortableTables();
wrapLongCells();
</script>
</body>
</html>
]],
    escape_html(filter_from),
    escape_html(filter_to),
    escape_html(filter_product),
    escape_html(filter_receipt),
    escape_html(generated_at),
    fmt_num(#replacements),
    fmt_num(#product_matrix),
    fmt_percent(avg_return_rate),
    fmt_num(critical_product_count),
    table.concat(matrix_rows_html, "\n"),
    table.concat(detail_rows_html, "\n")
    )
end)

if not ok_html then
    fail("خطا در ساخت گزارش HTML", tostring(html_or_err))
    return
end

teamyar.write_result(html_or_err)
