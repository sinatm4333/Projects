-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/05/20 16:30

local input = teamyar.get_input() or {}

-- ورودی فرم Teamyar: startDate، end_date، org_id
local start_date = input["startDate"]
local end_date = input["end_date"]
local org_id_raw = input["org_id"]

local MAX_RECEIPTS = 5000
local MAX_HTML_DETAIL_ROWS = 500
local limit = MAX_RECEIPTS
local table_unpack = table.unpack or unpack

local MONEY_SCALE = 10000000.0
local HTML_DQ = string.char(34)

local function wants_json(source)
    local fmt = source["format"] or source["output"] or source["output_format"]
    if fmt == nil then
        return false
    end
    return tostring(fmt):lower() == "json"
end

local output_json = wants_json(input)

local function fail_html(message)
    teamyar.write_result(string.format([[
<!DOCTYPE html>
<html dir="rtl" lang="fa">
<head><meta charset="UTF-8"><title>خطا</title></head>
<body style="font-family:IRANSansWeb_Light,Tahoma,sans-serif;padding:2rem;text-align:center;">
<h2 style="color:#b42318;">%s</h2>
</body></html>
]], message))
end

local function fail(message, detail)
    if detail ~= nil and detail ~= "" then
        message = message .. ": " .. tostring(detail)
    end
    if output_json then
        teamyar.write_result(json.encode({ ok = false, error = message }))
    else
        fail_html(message)
    end
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
        if type(value) == "string" then
            args[i] = value:gsub("%%", "%%%%")
        end
    end
    return string.format(fmt, table_unpack(args))
end

local function format_thousands(value)
    local n = math.floor(math.abs(value) + 0.5)
    local s = tostring(n)
    local grouped = s:reverse():gsub('(%d%d%d)', '%1,'):reverse():gsub('^,', '')
    if value < 0 then
        return '-' .. grouped
    end
    return grouped
end

local function fmt_num(value)
    local n = tonumber(value)
    if n == nil then
        return '—'
    end
    return format_thousands(n)
end

local function fmt_money(value)
    local n = tonumber(value)
    if n == nil or n <= 0 then
        return '—'
    end
    return format_thousands(n)
end

local function fmt_qty(value)
    local n = tonumber(value)
    if n == nil or n <= 0 then
        return '—'
    end
    if n == math.floor(n + 0.0001) then
        return format_thousands(n)
    end
    return tostring(n)
end

local function normalize_jalali_date(value)
    if value == nil or value == "" then return nil end
    local s = tostring(value):gsub("/", "-"):gsub("%.", "-"):match("^%s*(.-)%s*$")
    local y, m, d = s:match("^(%d%d%d%d)-(%d%d)-(%d%d)$")
    if y then return string.format("%04d-%02d-%02d", tonumber(y), tonumber(m), tonumber(d)) end
    y, m, d = s:match("^(%d%d%d%d)(%d%d)(%d%d)$")
    if y then return string.format("%04d-%02d-%02d", tonumber(y), tonumber(m), tonumber(d)) end
    return nil
end

local function normalize_text(value)
    if value == nil then return nil end
    local s = tostring(value):match("^%s*(.-)%s*$")
    if s == "" then return nil end
    return s
end

local function normalize_entity_id(value)
    local n = tonumber(value)
    if n ~= nil and n > 0 then return n end
    return nil
end

local function normalize_org_id(value)
    if value == nil then return nil end
    if type(value) == "table" then
        value = value[1] or value.id or value.value
    end
    local s = tostring(value):match("^%s*(.-)%s*$")
    if s == nil or s == "" then return nil end
    return normalize_entity_id(s)
end

local org_id = normalize_org_id(org_id_raw)

local function normalize_product_code(code)
    if code == nil or code == "" then return nil end
    return tostring(code):match("^%s*(.-)%s*$")
end

local function normalize_money_value(value)
    local n = tonumber(value) or 0
    if n <= 0 then return 0 end
    if n >= MONEY_SCALE then return math.floor(n / MONEY_SCALE + 0.5) end
    return math.floor(n + 0.5)
end

local function normalize_quantity_value(value)
    local n = tonumber(value) or 0
    if n <= 0 then return 0 end
    if n >= MONEY_SCALE then return n / MONEY_SCALE end
    return n
end

local function multiply_cogs(unit_cogs, quantity_raw)
    return normalize_money_value(unit_cogs) * normalize_quantity_value(quantity_raw)
end

local function build_in_clause(values)
    local placeholders = {}
    for _ = 1, #values do table.insert(placeholders, "?") end
    return table.concat(placeholders, ", ")
end

local function run_query(query, params)
    pcall(function() db.use_db("0000000") end)
    db.query({ query = query, params = params or {} })
end

local function fetch_rows(query, params)
    local ok, err = pcall(function() run_query(query, params) end)
    if not ok then return nil, err end
    local rows = {}
    local record = {}
    while db.query_fetch(record) do
        local row = {}
        for i = 1, #record do row[i] = record[i] end
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
            DATE_FORMAT(NOW(), '%%H:%%i:%%s')
        ) AS generated_at
    ]])
    if rows == nil or #rows == 0 or rows[1][1] == nil then
        return "—"
    end
    return tostring(rows[1][1])
end

local function purchase_invoice_filter_sql()
    return [[
  COALESCE(pi.DELETED, 0) = 0
  AND COALESCE(pi.CANCELED, 0) = 0
  AND COALESCE(pi.REJECT, 0) = 0
  AND COALESCE(pi.TYPE, 0) NOT IN (1, 5)]]
end

local function load_product_unit_cogs(product_ids)
    local cogs_by_product = {}
    local normalized_ids = {}
    local seen = {}
    for _, id in ipairs(product_ids or {}) do
        local normalized = normalize_entity_id(id)
        if normalized ~= nil and not seen[normalized] then
            seen[normalized] = true
            table.insert(normalized_ids, normalized)
        end
    end
    if #normalized_ids == 0 then return cogs_by_product end

    local id_in_clause = build_in_clause(normalized_ids)
    local id_params = {}
    for _, id in ipairs(normalized_ids) do table.insert(id_params, id) end

    local cardindex_rows = fetch_rows(
        [[SELECT PRODUCT_ID, MAX(COALESCE(RATE_CARDINDEX, 0)) AS RATE_CARDINDEX
FROM wh_product_cardindex WHERE PRODUCT_ID IN (]] .. id_in_clause .. [[)
GROUP BY PRODUCT_ID HAVING MAX(COALESCE(RATE_CARDINDEX, 0)) > 0]], id_params)
    if cardindex_rows ~= nil then
        for _, row in ipairs(cardindex_rows) do
            local product_id = normalize_entity_id(row[1])
            local unit_cogs = normalize_money_value(row[2])
            if product_id ~= nil and unit_cogs > 0 then
                cogs_by_product[product_id] = unit_cogs
            end
        end
    end

    local purchase_query = [[
SELECT pip.PRODUCT_ID,
    SUM(COALESCE(NULLIF(pip.fee_sales, 0), NULLIF(pip.FEE, 0),
        CASE WHEN COALESCE(pip.PRICE, 0) > 0
             AND COALESCE(NULLIF(pip.QUANTITY, 0), NULLIF(pip.QUANTITY_SEC, 0), 0) > 0
        THEN pip.PRICE / COALESCE(NULLIF(pip.QUANTITY, 0), pip.QUANTITY_SEC, 1) ELSE 0 END)
        * GREATEST(COALESCE(NULLIF(pip.QUANTITY, 0), NULLIF(pip.QUANTITY_SEC, 0), 1), 1))
    / NULLIF(SUM(GREATEST(COALESCE(NULLIF(pip.QUANTITY, 0), NULLIF(pip.QUANTITY_SEC, 0), 1), 1)), 0) AS raw_unit_cost
FROM purchase_invoice_product pip
INNER JOIN purchase_invoice pi ON pi.ID = pip.INVOICE_ID
WHERE ]] .. purchase_invoice_filter_sql() .. [[
  AND pip.PRODUCT_ID IN (]] .. id_in_clause .. [[)
GROUP BY pip.PRODUCT_ID HAVING raw_unit_cost > 0]]

    local purchase_rows = fetch_rows(purchase_query, id_params)
    if purchase_rows ~= nil then
        for _, row in ipairs(purchase_rows) do
            local product_id = normalize_entity_id(row[1])
            local unit_cogs = normalize_money_value(row[2])
            if product_id ~= nil and unit_cogs > 0 and cogs_by_product[product_id] == nil then
                cogs_by_product[product_id] = unit_cogs
            end
        end
    end

    local missing_ids = {}
    for _, id in ipairs(normalized_ids) do
        if cogs_by_product[id] == nil then table.insert(missing_ids, id) end
    end
    if #missing_ids > 0 then
        local missing_clause = build_in_clause(missing_ids)
        local missing_params = {}
        for _, id in ipairs(missing_ids) do table.insert(missing_params, id) end
        local price_rows = fetch_rows(
            "SELECT PRODUCT_ID, MAX(COALESCE(PRICE, 0)) FROM wh_product_price WHERE PRODUCT_ID IN ("
                .. missing_clause .. ") GROUP BY PRODUCT_ID HAVING MAX(COALESCE(PRICE, 0)) > 0",
            missing_params)
        if price_rows ~= nil then
            for _, row in ipairs(price_rows) do
                local product_id = normalize_entity_id(row[1])
                local unit_cogs = normalize_money_value(row[2])
                if product_id ~= nil and unit_cogs > 0 then
                    cogs_by_product[product_id] = unit_cogs
                end
            end
        end
    end
    return cogs_by_product
end

local function get_unit_cogs(cogs_by_product, product_id)
    local id = normalize_entity_id(product_id)
    if id == nil then return 0 end
    return cogs_by_product[id] or 0
end

local function build_section()
    return { exists = false, count = 0, total_cogs = 0, items = {} }
end

local function add_item(section, item)
    section.exists = true
    section.count = section.count + 1
    section.total_cogs = section.total_cogs + (tonumber(item.line_cogs) or 0)
    table.insert(section.items, item)
end

local function finalize_section(section)
    section.total_cogs = math.floor((section.total_cogs or 0) + 0.5)
    return section
end

local function month_key_from_date(breakdown_date)
    if breakdown_date == nil or breakdown_date == "" then
        return "unknown"
    end
    return tostring(breakdown_date):sub(1, 7)
end

local function product_group_key(product_id, product_code)
    local id = normalize_entity_id(product_id)
    if id ~= nil then
        return "id:" .. tostring(id)
    end
    local code = normalize_product_code(product_code)
    if code ~= nil then
        return "code:" .. code
    end
    return "unknown"
end

local function init_cost_bucket()
    return {
        consumed_parts_total = 0,
        replacement_total = 0,
        refund_total = 0,
        grand_total_cogs = 0,
        quantity_total = 0,
        line_count = 0,
        receipt_ids = {}
    }
end

local function track_receipt_in_bucket(bucket, sr_id)
    if sr_id ~= nil then
        bucket.receipt_ids[sr_id] = true
    end
end

local function receipt_count_in_bucket(bucket)
    local count = 0
    for _ in pairs(bucket.receipt_ids or {}) do
        count = count + 1
    end
    return count
end

local function add_line_to_product_bucket(bucket, product_id, product_code, product_name, cost_type, line_cogs, quantity, sr_id)
    if bucket.product_id == nil then
        bucket.product_id = normalize_entity_id(product_id)
        bucket.product_code = normalize_product_code(product_code)
        bucket.product_name = normalize_text(product_name)
    end
    track_receipt_in_bucket(bucket, sr_id)
    bucket.line_count = bucket.line_count + 1
    bucket.quantity_total = bucket.quantity_total + (tonumber(quantity) or 0)
    bucket[cost_type] = (bucket[cost_type] or 0) + line_cogs
    bucket.grand_total_cogs = bucket.grand_total_cogs + line_cogs
end

local function add_receipt_to_month_bucket(bucket, item, sr_id)
    track_receipt_in_bucket(bucket, sr_id)
    bucket.consumed_parts_total = bucket.consumed_parts_total + item.consumed_parts.total_cogs
    bucket.replacement_total = bucket.replacement_total + item.replacement.total_cogs
    bucket.refund_total = bucket.refund_total + item.refund.total_cogs
    bucket.grand_total_cogs = bucket.grand_total_cogs + item.grand_total_cogs
end

local function finalize_group_bucket(bucket)
    bucket.consumed_parts_total = math.floor((bucket.consumed_parts_total or 0) + 0.5)
    bucket.replacement_total = math.floor((bucket.replacement_total or 0) + 0.5)
    bucket.refund_total = math.floor((bucket.refund_total or 0) + 0.5)
    bucket.grand_total_cogs = math.floor((bucket.grand_total_cogs or 0) + 0.5)
    bucket.quantity_total = math.floor((bucket.quantity_total or 0) * 1000 + 0.5) / 1000
    bucket.receipt_count = receipt_count_in_bucket(bucket)
    bucket.receipt_ids = nil
    return bucket
end

local function sort_by_desc_total(a, b)
    return (a.grand_total_cogs or 0) > (b.grand_total_cogs or 0)
end

local function sort_by_month(a, b)
    return tostring(a.month or "") < tostring(b.month or "")
end

local function sort_by_month_then_product(a, b)
    local ma = tostring(a.month or "")
    local mb = tostring(b.month or "")
    if ma ~= mb then
        return ma < mb
    end
    return tostring(a.product_code or a.product_name or "") < tostring(b.product_code or b.product_name or "")
end

local function map_to_sorted_list(map, sorter)
    local list = {}
    for _, bucket in pairs(map) do
        table.insert(list, finalize_group_bucket(bucket))
    end
    table.sort(list, sorter)
    return list
end

local function accumulate_cost_groups(item, sr_id, by_product, by_month, by_product_month)
    local month_key = month_key_from_date(item.breakdown_date)

    local month_bucket = by_month[month_key]
    if month_bucket == nil then
        month_bucket = init_cost_bucket()
        month_bucket.month = month_key
        by_month[month_key] = month_bucket
    end
    add_receipt_to_month_bucket(month_bucket, item, sr_id)

    local function add_line(section_name, line)
        local line_cogs = tonumber(line.line_cogs) or 0
        if line_cogs <= 0 then
            return
        end
        local product_key = product_group_key(line.product_id, line.product_code)
        local product_bucket = by_product[product_key]
        if product_bucket == nil then
            product_bucket = init_cost_bucket()
            by_product[product_key] = product_bucket
        end
        add_line_to_product_bucket(
            product_bucket,
            line.product_id,
            line.product_code,
            line.product_name,
            section_name,
            line_cogs,
            line.quantity,
            sr_id
        )

        local pivot_key = month_key .. "|" .. product_key
        local pivot_bucket = by_product_month[pivot_key]
        if pivot_bucket == nil then
            pivot_bucket = init_cost_bucket()
            pivot_bucket.month = month_key
            pivot_bucket.product_id = normalize_entity_id(line.product_id)
            pivot_bucket.product_code = normalize_product_code(line.product_code)
            pivot_bucket.product_name = normalize_text(line.product_name)
            by_product_month[pivot_key] = pivot_bucket
        end
        add_line_to_product_bucket(
            pivot_bucket,
            line.product_id,
            line.product_code,
            line.product_name,
            section_name,
            line_cogs,
            line.quantity,
            sr_id
        )
    end

    for _, line in ipairs(item.consumed_parts.items or {}) do
        add_line("consumed_parts_total", line)
    end
    for _, line in ipairs(item.replacement.items or {}) do
        add_line("replacement_total", line)
    end
    for _, line in ipairs(item.refund.items or {}) do
        add_line("refund_total", line)
    end
end

local function render_period_result(payload)
    if output_json then
        teamyar.write_result(json.encode(payload))
        return
    end

    local summary = payload.summary or {}
    local group_by_product = payload.group_by_product or {}
    local group_by_month = payload.group_by_month or {}
    local group_by_product_month = payload.group_by_product_month or {}
    local receipts = payload.receipts or {}
    local generated_at = fetch_generated_at()
    local org_label = payload.org_id ~= nil and tostring(payload.org_id) or "—"
    local truncated_note = payload.truncated and safe_format(
        " (حداکثر %s رسید — برای دوره کامل‌تر بازه را کوچک‌تر کنید)",
        fmt_num(payload.limit_applied)
    ) or ""

    local product_rows = {}
    if #group_by_product == 0 then
        table.insert(product_rows, [[<tr><td colspan="10" class="empty-row">داده‌ای یافت نشد</td></tr>]])
    else
        for i, row in ipairs(group_by_product) do
            table.insert(product_rows, safe_format(
                [[<tr>
                    <td>%d</td>
                    <td class="mono">%s</td>
                    <td class="name-cell">%s</td>
                    <td>%s</td>
                    <td>%s</td>
                    <td>%s</td>
                    <td>%s</td>
                    <td>%s</td>
                    <td>%s</td>
                    <td>%s</td>
                </tr>]],
                i,
                escape_html(row.product_code),
                escape_html(row.product_name),
                fmt_num(row.line_count),
                fmt_num(row.receipt_count),
                fmt_qty(row.quantity_total),
                fmt_money(row.consumed_parts_total),
                fmt_money(row.replacement_total),
                fmt_money(row.refund_total),
                fmt_money(row.grand_total_cogs)
            ))
        end
    end

    local month_rows = {}
    if #group_by_month == 0 then
        table.insert(month_rows, [[<tr><td colspan="8" class="empty-row">داده‌ای یافت نشد</td></tr>]])
    else
        for i, row in ipairs(group_by_month) do
            table.insert(month_rows, safe_format(
                [[<tr>
                    <td>%d</td>
                    <td class="mono">%s</td>
                    <td>%s</td>
                    <td>%s</td>
                    <td>%s</td>
                    <td>%s</td>
                    <td>%s</td>
                    <td>%s</td>
                </tr>]],
                i,
                escape_html(row.month),
                fmt_num(row.receipt_count),
                fmt_money(row.consumed_parts_total),
                fmt_money(row.replacement_total),
                fmt_money(row.refund_total),
                fmt_money(row.grand_total_cogs),
                fmt_num(row.line_count)
            ))
        end
    end

    local pivot_rows = {}
    if #group_by_product_month == 0 then
        table.insert(pivot_rows, [[<tr><td colspan="10" class="empty-row">داده‌ای یافت نشد</td></tr>]])
    else
        for i, row in ipairs(group_by_product_month) do
            table.insert(pivot_rows, safe_format(
                [[<tr>
                    <td>%d</td>
                    <td class="mono">%s</td>
                    <td class="mono">%s</td>
                    <td class="name-cell">%s</td>
                    <td>%s</td>
                    <td>%s</td>
                    <td>%s</td>
                    <td>%s</td>
                    <td>%s</td>
                    <td>%s</td>
                </tr>]],
                i,
                escape_html(row.month),
                escape_html(row.product_code),
                escape_html(row.product_name),
                fmt_num(row.receipt_count),
                fmt_qty(row.quantity_total),
                fmt_money(row.consumed_parts_total),
                fmt_money(row.replacement_total),
                fmt_money(row.refund_total),
                fmt_money(row.grand_total_cogs)
            ))
        end
    end

    local detail_limit = math.min(#receipts, MAX_HTML_DETAIL_ROWS)
    local detail_rows = {}
    for i = 1, detail_limit do
        local item = receipts[i]
        table.insert(detail_rows, safe_format(
            [[<tr>
                <td>%d</td>
                <td class="mono">%s</td>
                <td>%s</td>
                <td>%s</td>
                <td class="mono">%s</td>
                <td class="name-cell">%s</td>
                <td>%s</td>
                <td>%s</td>
                <td>%s</td>
                <td>%s</td>
            </tr>]],
            i,
            escape_html(item.receipt_no),
            escape_html(item.breakdown_date),
            escape_html(item.status_label),
            escape_html(item.original_product_code),
            escape_html(item.original_product_name),
            fmt_money(item.consumed_parts.total_cogs),
            fmt_money(item.replacement.total_cogs),
            fmt_money(item.refund.total_cogs),
            fmt_money(item.grand_total_cogs)
        ))
    end
    if #detail_rows == 0 then
        table.insert(detail_rows, [[<tr><td colspan="10" class="empty-row">در بازه انتخاب‌شده رسیدی یافت نشد</td></tr>]])
    elseif #receipts > detail_limit then
        table.insert(detail_rows, safe_format(
            [[<tr><td colspan="10" class="empty-row">نمایش %s از %s رسید — برای JSON کامل format=json بفرستید</td></tr>]],
            fmt_num(detail_limit),
            fmt_num(#receipts)
        ))
    end

    local ok_html, html_or_err = pcall(function()
        return string.format([[
<!DOCTYPE html>
<html dir="rtl" lang="fa">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>گزارش تجمیعی هزینه رسیدها</title>
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
#reportRoot:fullscreen { background: #f5f7fb; padding: 12px; overflow: auto; }
.toolbar { display: flex; justify-content: flex-start; gap: 8px; margin-bottom: 10px; }
.btn-fullscreen {
    background: #0073e6; color: #fff; border: 2px solid #005bb5; border-radius: 8px;
    padding: 8px 16px; font-family: IRANSansWeb_Light, Tahoma, sans-serif;
    font-size: 12px; font-weight: bold; cursor: pointer;
}
.btn-fullscreen:hover { background: #005bb5; }
.report-header {
    background-color: #D2E0FB; text-align: center; border: 1px dotted #000;
    border-radius: 10px; padding: 12px 10px 16px; margin-bottom: 12px;
}
.report-header p { margin: 4px 0; }
.meta-line { font-size: 11px; color: #333; margin-top: 8px; }
.tab-bar { display: flex; flex-wrap: wrap; gap: 6px; margin-bottom: 10px; }
.tab-btn {
    background: #fff; border: 2px solid #0073e6; color: #0073e6; border-radius: 8px;
    padding: 8px 14px; font-family: IRANSansWeb_Light, Tahoma, sans-serif;
    font-size: 12px; font-weight: bold; cursor: pointer;
}
.tab-btn.active { background: #0073e6; color: #fff; }
.tab-panel { display: none; }
.tab-panel.active { display: block; }
.table-wrap {
    overflow: auto; max-height: 72vh; border: 2px solid #000;
    border-radius: 8px; background: #fff;
}
table { width: 100%%; border-collapse: collapse; text-align: center; font-family: IRANSansWeb_Light, Tahoma, sans-serif; }
thead th {
    position: sticky; top: 0; z-index: 2; background-color: #0073e6; color: #fff;
    border: 1px dashed #000; padding: 10px 8px; font-size: 11px; white-space: nowrap;
    font-family: IRANSansWeb_Light, Tahoma, sans-serif;
}
tbody td {
    border: 1px dashed #000; padding: 8px; font-size: 11px; vertical-align: middle;
    font-family: IRANSansWeb_Light, Tahoma, sans-serif;
}
tbody tr:nth-child(even) { background-color: #eeeeee; }
tbody tr:hover { filter: brightness(0.97); }
.summary-table {
    width: 100%%; border-collapse: collapse; margin-bottom: 12px;
    border: 2px solid #000; border-radius: 8px; overflow: hidden;
}
.summary-table td {
    border: 1px dashed #000; padding: 10px 8px; text-align: center; font-size: 11px;
    font-family: IRANSansWeb_Light, Tahoma, sans-serif;
}
.summary-table .summary-head { background: #4472C4; color: #fff; font-size: 12px; }
.summary-table .summary-value { background: #5B9BD5; color: #fff; font-size: 16px; font-weight: bold; }
.mono { font-family: IRANSansWeb_Light, Tahoma, sans-serif; direction: ltr; unicode-bidi: isolate; }
.num-cell { font-family: IRANSansWeb_Light, Tahoma, sans-serif; direction: ltr; unicode-bidi: isolate; }
.name-cell { text-align: right; font-weight: bold; white-space: normal; }
.empty-row { padding: 24px !important; color: #666; }
.footer { text-align: center; color: #666; font-size: 11px; margin-top: 10px; }
</style>
</head>
<body>
<div id="reportRoot">
    <div class="toolbar">
        <button type="button" class="btn-fullscreen" id="btnFullscreen" onclick="toggleFullScreen()">تمام صفحه</button>
    </div>
    <div class="report-header">
        <p><strong>گزارش تجمیعی هزینه رسیدهای خدمات</strong></p>
        <p>ماتریس کالا و ماه — بهای تمام‌شده قطعات، تعویض و عودت</p>
        <div class="meta-line">
            از تاریخ: %s | تا تاریخ: %s | سازمان: %s | تعداد رسید: %s%s | زمان تولید: %s
        </div>
    </div>
    <table class="summary-table">
        <tr class="summary-head">
            <td>رسید با هزینه</td>
            <td>قطعات مصرفی</td>
            <td>تعویض</td>
            <td>عودت وجه</td>
            <td>جمع COGS</td>
            <td>تعداد کالا</td>
            <td>تعداد ماه</td>
        </tr>
        <tr>
            <td class="summary-value">%s</td>
            <td class="summary-value">%s</td>
            <td class="summary-value">%s</td>
            <td class="summary-value">%s</td>
            <td class="summary-value">%s</td>
            <td class="summary-value">%s</td>
            <td class="summary-value">%s</td>
        </tr>
    </table>
    <div class="tab-bar">
        <button type="button" class="tab-btn active" data-tab="tab-product" onclick="switchTab(this)">ماتریس کالا</button>
        <button type="button" class="tab-btn" data-tab="tab-month" onclick="switchTab(this)">ماتریس ماه</button>
        <button type="button" class="tab-btn" data-tab="tab-pivot" onclick="switchTab(this)">کالا × ماه</button>
        <button type="button" class="tab-btn" data-tab="tab-detail" onclick="switchTab(this)">جزئیات رسید</button>
    </div>
    <div class="tab-panel active" id="tab-product">
        <div class="table-wrap">
            <table>
                <thead><tr>
                    <th>ردیف</th><th>کد کالا</th><th>نام کالا</th><th>تعداد خط</th><th>تعداد رسید</th>
                    <th>مقدار</th><th>قطعات</th><th>تعویض</th><th>عودت</th><th>جمع COGS</th>
                </tr></thead>
                <tbody>%s</tbody>
            </table>
        </div>
    </div>
    <div class="tab-panel" id="tab-month">
        <div class="table-wrap">
            <table>
                <thead><tr>
                    <th>ردیف</th><th>ماه</th><th>تعداد رسید</th><th>قطعات</th><th>تعویض</th>
                    <th>عودت</th><th>جمع COGS</th><th>تعداد خط</th>
                </tr></thead>
                <tbody>%s</tbody>
            </table>
        </div>
    </div>
    <div class="tab-panel" id="tab-pivot">
        <div class="table-wrap">
            <table>
                <thead><tr>
                    <th>ردیف</th><th>ماه</th><th>کد کالا</th><th>نام کالا</th><th>تعداد رسید</th>
                    <th>مقدار</th><th>قطعات</th><th>تعویض</th><th>عودت</th><th>جمع COGS</th>
                </tr></thead>
                <tbody>%s</tbody>
            </table>
        </div>
    </div>
    <div class="tab-panel" id="tab-detail">
        <div class="table-wrap">
            <table>
                <thead><tr>
                    <th>ردیف</th><th>شماره رسید</th><th>تاریخ خرابی</th><th>وضعیت</th><th>کد کالا</th>
                    <th>نام کالا</th><th>قطعات</th><th>تعویض</th><th>عودت</th><th>جمع COGS</th>
                </tr></thead>
                <tbody>%s</tbody>
            </table>
        </div>
    </div>
    <div class="footer">Teamyar Service Receipt Cost Period Report</div>
</div>
<script>
function switchTab(btn) {
    var tabs = document.getElementsByClassName('tab-btn');
    for (var i = 0; i < tabs.length; i++) { tabs[i].classList.remove('active'); }
    btn.classList.add('active');
    var panels = document.getElementsByClassName('tab-panel');
    for (var j = 0; j < panels.length; j++) { panels[j].classList.remove('active'); }
    document.getElementById(btn.getAttribute('data-tab')).classList.add('active');
}
function toggleFullScreen() {
    var root = document.getElementById('reportRoot');
    var btn = document.getElementById('btnFullscreen');
    var isFull = document.fullscreenElement || document.webkitFullscreenElement || document.msFullscreenElement;
    if (!isFull) {
        if (root.requestFullscreen) { root.requestFullscreen(); }
        else if (root.webkitRequestFullscreen) { root.webkitRequestFullscreen(); }
        else if (root.msRequestFullscreen) { root.msRequestFullscreen(); }
        btn.innerText = 'خروج از تمام صفحه';
    } else {
        if (document.exitFullscreen) { document.exitFullscreen(); }
        else if (document.webkitExitFullscreen) { document.webkitExitFullscreen(); }
        else if (document.msExitFullscreen) { document.msExitFullscreen(); }
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
            escape_html(payload.startDate),
            escape_html(payload.end_date),
            escape_html(org_label),
            fmt_num(payload.receipt_count),
            escape_html(truncated_note),
            escape_html(generated_at),
            fmt_num(summary.receipts_with_any_cost),
            fmt_money(summary.consumed_parts_total),
            fmt_money(summary.replacement_total),
            fmt_money(summary.refund_total),
            fmt_money(summary.grand_total_cogs),
            fmt_num(#group_by_product),
            fmt_num(#group_by_month),
            table.concat(product_rows, "\n"),
            table.concat(month_rows, "\n"),
            table.concat(pivot_rows, "\n"),
            table.concat(detail_rows, "\n")
        )
    end)

    if not ok_html then
        fail("خطا در ساخت گزارش HTML", tostring(html_or_err))
        return
    end

    teamyar.write_result(html_or_err)
end

local function receipt_status_label(status)
    local n = tonumber(status)
    if n == 0 then return "پیش پذیرش" end
    if n == 1 then return "بررسی" end
    if n == 2 then return "اجرا" end
    if n == 3 then return "کامل (تعمیر شده)" end
    if n == 4 then return "کامل (رد هزینه)" end
    if n == 5 then return "باطل" end
    if n == 6 then return "آماده تحویل (تعمیر شده)" end
    if n == 7 then return "آماده تحویل (رد هزینه)" end
    if n == 8 then return "آماده تحویل (تعویض شده)" end
    if n == 9 then return "کامل (تعویض شده)" end
    return "نامشخص"
end

local function swap_type_label(swap_type)
    local n = tonumber(swap_type)
    if n == 0 then return "کالای تحویلی" end
    if n == 1 then return "کالای جایگزین" end
    return "سایر"
end

local function fetch_default_dates()
    local params = {}
    local org_clause = ""
    if org_id ~= nil then
        org_clause = " AND fy.ORG_ID = " .. tostring(org_id)
    end
    local rows = fetch_rows([[
SELECT
    REPORT_FN_JDATE(fy.START_DATE, '-') AS fiscal_start_jalali,
    REPORT_FN_JDATE(fy.END_DATE, '-') AS fiscal_end_jalali
FROM pa_fiscal_year fy
WHERE (UNIX_TIMESTAMP() + 11644473600) * 10000000 >= fy.START_DATE
  AND (UNIX_TIMESTAMP() + 11644473600) * 10000000 <= fy.END_DATE
]] .. org_clause .. [[
ORDER BY fy.START_DATE DESC
LIMIT 1]], params)
    if rows ~= nil and #rows > 0 and rows[1][1] ~= nil and rows[1][2] ~= nil then
        return tostring(rows[1][1]), tostring(rows[1][2])
    end
    rows = fetch_rows([[
SELECT
    CONCAT(SUBSTRING(REPORT_FN_JDATE((UNIX_TIMESTAMP() + 11644473600) * 10000000, '-'), 1, 4), '-01-01'),
    CONCAT(SUBSTRING(REPORT_FN_JDATE((UNIX_TIMESTAMP() + 11644473600) * 10000000, '-'), 1, 4), '-12-29')
]])
    if rows ~= nil and #rows > 0 then
        return tostring(rows[1][1]), tostring(rows[1][2])
    end
    return nil, nil
end

local start_explicit = start_date ~= nil and start_date ~= ""
local end_explicit = end_date ~= nil and end_date ~= ""
local start_jalali = start_explicit and normalize_jalali_date(start_date) or nil
local end_jalali = end_explicit and normalize_jalali_date(end_date) or nil
local dates_defaulted = { startDate = false, end_date = false }
local dates_swapped = false

if not start_explicit or start_jalali == nil then
    local ds, de = fetch_default_dates()
    if ds ~= nil then
        start_jalali = ds
        start_date = ds
        dates_defaulted.startDate = not start_explicit
    end
    if (not end_explicit or end_jalali == nil) and de ~= nil then
        end_jalali = de
        end_date = de
        dates_defaulted.end_date = not end_explicit
    end
end

if start_jalali == nil then
    fail("startDate مشخص نیست. فرمت: 1404-01-01")
    return
end
if end_jalali == nil then
    fail("end_date مشخص نیست. فرمت: 1404-12-29")
    return
end

if start_jalali > end_jalali then
    start_jalali, end_jalali = end_jalali, start_jalali
    start_date, end_date = end_date, start_date
    dates_swapped = true
end

local receipt_params = { start_jalali, end_jalali }
local receipt_where = [[
  REPORT_FN_JDATE(sr.BREAK_DOWN_DATE, '-') >= ?
  AND REPORT_FN_JDATE(sr.BREAK_DOWN_DATE, '-') <= ?
]]
if org_id ~= nil then
    receipt_where = receipt_where .. [[
  AND EXISTS (
    SELECT 1 FROM pm_service_order so
    WHERE so.SERVICE_REQUEST_ID = sr.ID
      AND so.ORG_ID = ]] .. tostring(org_id) .. [[
  )]]
end
table.insert(receipt_params, limit)

local receipt_rows, receipt_err = fetch_rows([[
SELECT
    sr.ID,
    sr.CODE,
    sr.FINAL_STATUS,
    sr.PRODUCT_SERIAL,
    REPORT_FN_JDATE(sr.BREAK_DOWN_DATE, '-') AS breakdown_date,
    TRIM(orig.FULL_CODE) AS product_code,
    orig.full_name AS product_name,
    orig.id AS product_id
FROM pm_service_request sr
LEFT JOIN wh_product orig ON orig.id = sr.PRODUCT_ID
WHERE ]] .. receipt_where .. [[
ORDER BY sr.BREAK_DOWN_DATE, sr.CODE
LIMIT ?
]], receipt_params)

if receipt_rows == nil then
    fail("خطا در دریافت رسیدهای دوره", receipt_err)
    return
end

if #receipt_rows == 0 then
    render_period_result({
        ok = true,
        startDate = start_jalali,
        end_date = end_jalali,
        org_id = org_id,
        dates_defaulted = dates_defaulted,
        dates_swapped = dates_swapped,
        receipt_count = 0,
        limit_applied = limit,
        truncated = false,
        summary = {
            consumed_parts_total = 0,
            replacement_total = 0,
            refund_total = 0,
            grand_total_cogs = 0,
            receipts_with_parts = 0,
            receipts_with_replacement = 0,
            receipts_with_refund = 0,
            receipts_with_any_cost = 0
        },
        group_by_product = {},
        group_by_month = {},
        group_by_product_month = {},
        receipts = {}
    })
    return
end

local sr_ids = {}
local sr_meta = {}
for _, row in ipairs(receipt_rows) do
    local sr_id = normalize_entity_id(row[1])
    if sr_id ~= nil then
        table.insert(sr_ids, sr_id)
        sr_meta[sr_id] = {
            receipt_no = tonumber(row[2]) or row[2],
            final_status = tonumber(row[3]) or row[3],
            product_serial = normalize_text(row[4]),
            breakdown_date = normalize_text(row[5]),
            product_code = normalize_product_code(row[6]),
            product_name = normalize_text(row[7]),
            product_id = normalize_entity_id(row[8])
        }
    end
end

local sr_in = build_in_clause(sr_ids)
local sr_params = {}
for _, id in ipairs(sr_ids) do table.insert(sr_params, id) end

local function push_map_list(map, key, item)
    local list = map[key]
    if list == nil then
        list = {}
        map[key] = list
    end
    table.insert(list, item)
end

local parts_by_sr = {}
local parts_rows = fetch_rows([[
SELECT parts.SERVICE_REQUEST_ID, parts.PRODUCT_ID, parts.product_code, parts.product_name, parts.qty
FROM (
    SELECT sr.id AS SERVICE_REQUEST_ID, rpd.PRODUCT_ID,
        TRIM(wp.FULL_CODE) AS product_code, wp.full_name AS product_name,
        COALESCE(rpd.QUANTITY_VALID_MAIN, rpd.QUANTITY_VALID, 0) AS qty
    FROM WH_REQ_PRODUCT rp
    INNER JOIN wh_req_product_details rpd ON rpd.REQUEST_ID = rp.ID
    INNER JOIN pm_service_request sr ON sr.id = rp.REF_ID
    LEFT JOIN wh_product wp ON wp.id = rpd.PRODUCT_ID
    WHERE rp.DELETED = 0 AND rp.REQUEST_TYPE = 5 AND rp.REF_TYPE = 101
      AND REPLACE(COALESCE(rpd.reason_of_cancellation, ''), ' ', '') = ''
      AND sr.id IN (]] .. sr_in .. [[)
    UNION ALL
    SELECT sr.id, rpd.PRODUCT_ID, TRIM(wp.FULL_CODE), wp.full_name,
        COALESCE(rpd.QUANTITY_VALID_MAIN, rpd.QUANTITY_VALID, 0)
    FROM WH_REQ_PRODUCT rp
    INNER JOIN wh_req_product_details rpd ON rpd.REQUEST_ID = rp.ID
    INNER JOIN pm_cost_declaration_detail cd ON cd.ID = rp.REF_ID
    INNER JOIN pm_cost_declaration c ON c.ID = cd.COST_DECLARATION_ID
    INNER JOIN pm_service_request sr ON sr.id = c.SERVICE_REQUEST_ID
    LEFT JOIN wh_product wp ON wp.id = rpd.PRODUCT_ID
    WHERE rp.DELETED = 0 AND rp.REQUEST_TYPE = 5 AND rp.REF_TYPE = 109
      AND REPLACE(COALESCE(rpd.reason_of_cancellation, ''), ' ', '') = ''
      AND sr.id IN (]] .. sr_in .. [[)
) parts
WHERE COALESCE(parts.qty, 0) > 0
]], (function()
    local p = {}
    for _, id in ipairs(sr_ids) do table.insert(p, id) end
    for _, id in ipairs(sr_ids) do table.insert(p, id) end
    return p
end)())

if parts_rows ~= nil then
    for _, row in ipairs(parts_rows) do
        local sr_id = normalize_entity_id(row[1])
        push_map_list(parts_by_sr, sr_id, {
            product_id = normalize_entity_id(row[2]),
            product_code = normalize_product_code(row[3]),
            product_name = normalize_text(row[4]),
            qty = row[5]
        })
    end
end

local swap_by_sr = {}
local swap_rows = fetch_rows([[
SELECT ps.SERVICE_REQUEST_ID, psd.PRODUCT_ID, TRIM(repl.FULL_CODE), repl.full_name,
    psd.SWAP_TYPE, psd.AMOUNT, REPORT_FN_JDATE(ps.SWAP_DATE, '-')
FROM pm_swap ps
INNER JOIN pm_swap_detail psd ON psd.SWAP_ID = ps.ID
LEFT JOIN wh_product repl ON repl.id = psd.PRODUCT_ID
WHERE ps.SERVICE_REQUEST_ID IN (]] .. sr_in .. [[)
]], sr_params)

if swap_rows ~= nil then
    for _, row in ipairs(swap_rows) do
        local sr_id = normalize_entity_id(row[1])
        push_map_list(swap_by_sr, sr_id, {
            product_id = normalize_entity_id(row[2]),
            product_code = normalize_product_code(row[3]),
            product_name = normalize_text(row[4]),
            swap_type = tonumber(row[5]) or row[5],
            amount = row[6],
            swap_date = row[7]
        })
    end
end

local refund_by_sr = {}
local refund_rows = fetch_rows([[
SELECT cd.SERVICE_REQUEST_ID, cdd.PRODUCT_ID, TRIM(wp.FULL_CODE), wp.full_name,
    cdd.AMOUNT, cdd.COST,
    CASE cd.FINAL_STATUS WHEN 5 THEN 'رد هزینه' ELSE 'سایر' END
FROM pm_cost_declaration cd
INNER JOIN pm_cost_declaration_detail cdd ON cdd.COST_DECLARATION_ID = cd.ID
LEFT JOIN wh_product wp ON wp.id = cdd.PRODUCT_ID
WHERE cd.SERVICE_REQUEST_ID IN (]] .. sr_in .. [[)
  AND cd.FINAL_STATUS = 5
]], sr_params)

if refund_rows ~= nil then
    for _, row in ipairs(refund_rows) do
        local sr_id = normalize_entity_id(row[1])
        push_map_list(refund_by_sr, sr_id, {
            product_id = normalize_entity_id(row[2]),
            product_code = normalize_product_code(row[3]),
            product_name = normalize_text(row[4]),
            amount = row[5],
            cost = row[6],
            status_label = normalize_text(row[7])
        })
    end
end

local all_product_ids = {}
local seen_products = {}
local function track_product(product_id)
    local id = normalize_entity_id(product_id)
    if id ~= nil and not seen_products[id] then
        seen_products[id] = true
        table.insert(all_product_ids, id)
    end
end

for _, sr_id in ipairs(sr_ids) do
    local meta = sr_meta[sr_id]
    if meta ~= nil then track_product(meta.product_id) end
    for _, line in ipairs(parts_by_sr[sr_id] or {}) do track_product(line.product_id) end
    for _, line in ipairs(swap_by_sr[sr_id] or {}) do track_product(line.product_id) end
    for _, line in ipairs(refund_by_sr[sr_id] or {}) do track_product(line.product_id) end
end

local cogs_by_product = load_product_unit_cogs(all_product_ids)

local function compute_receipt_costs(sr_id)
    local meta = sr_meta[sr_id] or {}
    local consumed_parts = build_section()
    local replacement = build_section()
    local refund = build_section()

    for _, line in ipairs(parts_by_sr[sr_id] or {}) do
        local qty = normalize_quantity_value(line.qty)
        if qty > 0 then
            local unit_cogs = get_unit_cogs(cogs_by_product, line.product_id)
            add_item(consumed_parts, {
                product_id = line.product_id,
                product_code = line.product_code,
                product_name = line.product_name,
                quantity = qty,
                unit_cogs = unit_cogs,
                line_cogs = math.floor(multiply_cogs(unit_cogs, line.qty) + 0.5)
            })
        end
    end

    for _, line in ipairs(swap_by_sr[sr_id] or {}) do
        if tonumber(line.swap_type) == 1 then
            local qty = normalize_quantity_value(line.amount)
            if qty <= 0 then qty = 1 end
            local unit_cogs = get_unit_cogs(cogs_by_product, line.product_id)
            add_item(replacement, {
                product_id = line.product_id,
                product_code = line.product_code,
                product_name = line.product_name,
                swap_type_label = swap_type_label(line.swap_type),
                quantity = qty,
                unit_cogs = unit_cogs,
                line_cogs = math.floor(multiply_cogs(unit_cogs, line.amount) + 0.5),
                swap_date = line.swap_date
            })
        end
    end

    local refund_lines = refund_by_sr[sr_id] or {}
    if #refund_lines > 0 then
        for _, line in ipairs(refund_lines) do
            local qty = normalize_quantity_value(line.amount)
            if qty <= 0 then qty = 1 end
            local declared_cost = normalize_money_value(line.cost)
            local unit_cogs = get_unit_cogs(cogs_by_product, line.product_id)
            local line_cogs = declared_cost
            if line_cogs <= 0 then
                line_cogs = math.floor(multiply_cogs(unit_cogs, line.amount) + 0.5)
            end
            add_item(refund, {
                product_id = line.product_id,
                product_code = line.product_code,
                product_name = line.product_name,
                quantity = qty,
                unit_cogs = unit_cogs,
                line_cogs = line_cogs,
                status_label = line.status_label
            })
        end
    elseif meta.final_status == 4 or meta.final_status == 7 then
        local unit_cogs = get_unit_cogs(cogs_by_product, meta.product_id)
        if unit_cogs > 0 then
            add_item(refund, {
                product_id = meta.product_id,
                product_code = meta.product_code,
                product_name = meta.product_name,
                quantity = 1,
                unit_cogs = unit_cogs,
                line_cogs = unit_cogs,
                status_label = receipt_status_label(meta.final_status)
            })
        end
    end

    consumed_parts = finalize_section(consumed_parts)
    replacement = finalize_section(replacement)
    refund = finalize_section(refund)

    return {
        receipt_no = meta.receipt_no,
        service_request_id = sr_id,
        status_code = meta.final_status,
        status_label = receipt_status_label(meta.final_status),
        product_serial = meta.product_serial,
        breakdown_date = meta.breakdown_date,
        original_product_code = meta.product_code,
        original_product_name = meta.product_name,
        consumed_parts = consumed_parts,
        replacement = replacement,
        refund = refund,
        grand_total_cogs = consumed_parts.total_cogs + replacement.total_cogs + refund.total_cogs
    }
end

local receipts = {}
local by_product = {}
local by_month = {}
local by_product_month = {}
local summary = {
    consumed_parts_total = 0,
    replacement_total = 0,
    refund_total = 0,
    grand_total_cogs = 0,
    receipts_with_parts = 0,
    receipts_with_replacement = 0,
    receipts_with_refund = 0,
    receipts_with_any_cost = 0
}

for _, sr_id in ipairs(sr_ids) do
    local item = compute_receipt_costs(sr_id)
    table.insert(receipts, item)
    accumulate_cost_groups(item, sr_id, by_product, by_month, by_product_month)
    summary.consumed_parts_total = summary.consumed_parts_total + item.consumed_parts.total_cogs
    summary.replacement_total = summary.replacement_total + item.replacement.total_cogs
    summary.refund_total = summary.refund_total + item.refund.total_cogs
    summary.grand_total_cogs = summary.grand_total_cogs + item.grand_total_cogs
    if item.consumed_parts.exists then summary.receipts_with_parts = summary.receipts_with_parts + 1 end
    if item.replacement.exists then summary.receipts_with_replacement = summary.receipts_with_replacement + 1 end
    if item.refund.exists then summary.receipts_with_refund = summary.receipts_with_refund + 1 end
    if item.grand_total_cogs > 0 then summary.receipts_with_any_cost = summary.receipts_with_any_cost + 1 end
end

local group_by_product = map_to_sorted_list(by_product, sort_by_desc_total)
local group_by_month = map_to_sorted_list(by_month, sort_by_month)
local group_by_product_month = map_to_sorted_list(by_product_month, sort_by_month_then_product)

render_period_result({
    ok = true,
    startDate = start_jalali,
    end_date = end_jalali,
    org_id = org_id,
    dates_defaulted = dates_defaulted,
    dates_swapped = dates_swapped,
    receipt_count = #receipts,
    limit_applied = limit,
    truncated = #receipt_rows >= limit,
    summary = summary,
    group_by_product = group_by_product,
    group_by_month = group_by_month,
    group_by_product_month = group_by_product_month,
    receipts = receipts
})
