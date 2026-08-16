-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/05/20 16:30

local input = teamyar.get_input() or {}

-- ورودی فرم: startDate، end_date، org_id (پیش‌فرض 2 = واحد فروش اکسسوری موبایل)
local start_date = input["startDate"]
local end_date = input["end_date"]
local org_id_raw = input["org_id"]

local table_unpack = table.unpack or unpack
local MONEY_SCALE = 10000000.0
local HTML_DQ = string.char(34)
local DEFAULT_ORG_ID = 2
local MAX_PRODUCT_ROWS = 500

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

local function fmt_qty(value)
    local n = tonumber(value)
    if n == nil then
        return '—'
    end
    if n == 0 then
        return '0'
    end
    if n == math.floor(n + 0.0001) then
        return format_thousands(n)
    end
    return tostring(math.floor(n * 1000 + 0.5) / 1000)
end

local function fmt_percent(value)
    local n = tonumber(value)
    if n == nil then
        return '—'
    end
    local signed = ''
    if n > 0 then
        signed = '+'
    end
    return signed .. tostring(math.floor(n * 10 + 0.5) / 10) .. '٪'
end

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

local function normalize_entity_id(value)
    local n = tonumber(value)
    if n ~= nil and n > 0 then
        return n
    end
    return nil
end

local function normalize_org_id(value)
    if value == nil then
        return nil
    end
    if type(value) == "table" then
        value = value[1] or value.id or value.value
    end
    local s = tostring(value):match("^%s*(.-)%s*$")
    if s == nil or s == "" then
        return nil
    end
    return normalize_entity_id(s)
end

local function normalize_text(value)
    if value == nil then
        return nil
    end
    local s = tostring(value):match("^%s*(.-)%s*$")
    if s == "" then
        return nil
    end
    return s
end

local function normalize_product_code(code)
    if code == nil or code == "" then
        return nil
    end
    return tostring(code):match("^%s*(.-)%s*$")
end

local org_id = normalize_org_id(org_id_raw) or DEFAULT_ORG_ID

local function run_query(query, params)
    pcall(function()
        db.use_db("0000000")
    end)
    db.query({ query = query, params = params or {} })
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
            DATE_FORMAT(NOW(), '%%H:%%i:%%s')
        ) AS generated_at
    ]])
    if rows == nil or #rows == 0 or rows[1][1] == nil then
        return "—"
    end
    return tostring(rows[1][1])
end

local function fetch_default_dates()
    local rows = fetch_rows([[
SELECT
    REPORT_FN_JDATE(fy.START_DATE, '-') AS fiscal_start_jalali,
    REPORT_FN_JDATE(fy.END_DATE, '-') AS fiscal_end_jalali
FROM pa_fiscal_year fy
WHERE fy.ORG_ID = ]] .. tostring(org_id) .. [[
  AND (UNIX_TIMESTAMP() + 11644473600) * 10000000 >= fy.START_DATE
  AND (UNIX_TIMESTAMP() + 11644473600) * 10000000 <= fy.END_DATE
ORDER BY fy.START_DATE DESC
LIMIT 1]])
    if rows ~= nil and #rows > 0 and rows[1][1] ~= nil and rows[1][2] ~= nil then
        return tostring(rows[1][1]), tostring(rows[1][2])
    end

    rows = fetch_rows([[
SELECT
    REPORT_FN_JDATE(fy.START_DATE, '-') AS fiscal_start_jalali,
    REPORT_FN_JDATE(fy.END_DATE, '-') AS fiscal_end_jalali
FROM pa_fiscal_year fy
WHERE (UNIX_TIMESTAMP() + 11644473600) * 10000000 >= fy.START_DATE
  AND (UNIX_TIMESTAMP() + 11644473600) * 10000000 <= fy.END_DATE
ORDER BY fy.START_DATE DESC
LIMIT 1]])
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
        dates_defaulted.startDate = not start_explicit
    end
    if (not end_explicit or end_jalali == nil) and de ~= nil then
        end_jalali = de
        dates_defaulted.end_date = not end_explicit
    end
end

if start_jalali == nil then
    fail("startDate مشخص نیست. فرمت: 1405-01-01")
    return
end
if end_jalali == nil then
    fail("end_date مشخص نیست. فرمت: 1405-12-29")
    return
end

if start_jalali > end_jalali then
    start_jalali, end_jalali = end_jalali, start_jalali
    dates_swapped = true
end

-- فاکتور فروش: حذف/باطل/رد + بدون پیش‌فاکتور و برگشت
local function sales_invoice_filter_sql()
    return [[
  COALESCE(si.DELETED, 0) = 0
  AND COALESCE(si.CANCELED, 0) = 0
  AND COALESCE(si.REJECT, 0) = 0
  AND COALESCE(si.TYPE, 0) NOT IN (1, 5)]]
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

local sales_params = { start_jalali, end_jalali }
local sales_query = [[
SELECT
    SUBSTRING(REPORT_FN_JDATE(si.RUN_DATE, '-'), 1, 7) AS sales_month,
    TRIM(wp.FULL_CODE) AS product_code,
    wp.full_name AS product_name,
    wp.id AS product_id,
    SUM(]] .. sales_quantity_case_sql() .. [[) AS sales_qty,
    COUNT(DISTINCT si.ID) AS invoice_count,
    COUNT(DISTINCT si.CLIENT_ID) AS customer_count
FROM sales_invoice_product sip
INNER JOIN sales_invoice si
    ON si.ID = sip.INVOICE_ID
INNER JOIN wh_product wp
    ON wp.id = COALESCE(NULLIF(sip.PRODUCT_ID, 0), NULLIF(sip.product_id_info, 0))
WHERE ]] .. sales_invoice_filter_sql() .. [[
  AND si.ORG_ID = ]] .. tostring(org_id) .. [[
  AND REPORT_FN_JDATE(si.RUN_DATE, '-') >= ?
  AND REPORT_FN_JDATE(si.RUN_DATE, '-') <= ?
GROUP BY
    SUBSTRING(REPORT_FN_JDATE(si.RUN_DATE, '-'), 1, 7),
    TRIM(wp.FULL_CODE),
    wp.full_name,
    wp.id
HAVING sales_qty > 0
ORDER BY sales_month, sales_qty DESC
]]

local sales_rows, sales_err = fetch_rows(sales_query, sales_params)
if sales_rows == nil then
    fail("خطا در دریافت حجم فروش", sales_err)
    return
end

local by_month = {}
local by_product = {}
local by_product_month = {}
local summary = {
    sales_volume_total = 0,
    invoice_count = 0,
    customer_count = 0,
    product_count = 0,
    month_count = 0
}

for _, row in ipairs(sales_rows) do
    local month = normalize_text(row[1]) or "unknown"
    local product_code = normalize_product_code(row[2]) or "—"
    local product_name = normalize_text(row[3]) or "—"
    local product_id = normalize_entity_id(row[4])
    local qty = tonumber(row[5]) or 0
    local invoice_count = tonumber(row[6]) or 0
    local customer_count = tonumber(row[7]) or 0
    if qty > 0 then
        summary.sales_volume_total = summary.sales_volume_total + qty

        local month_bucket = by_month[month]
        if month_bucket == nil then
            month_bucket = {
                month = month,
                sales_volume = 0,
                invoice_count = 0,
                customer_count = 0,
                product_count = 0,
                _products = {}
            }
            by_month[month] = month_bucket
        end
        month_bucket.sales_volume = month_bucket.sales_volume + qty
        month_bucket.invoice_count = month_bucket.invoice_count + invoice_count
        month_bucket.customer_count = month_bucket.customer_count + customer_count
        month_bucket._products[product_code] = true

        local product_bucket = by_product[product_code]
        if product_bucket == nil then
            product_bucket = {
                product_id = product_id,
                product_code = product_code,
                product_name = product_name,
                sales_volume = 0,
                invoice_count = 0,
                customer_count = 0,
                month_count = 0,
                _months = {}
            }
            by_product[product_code] = product_bucket
        end
        product_bucket.sales_volume = product_bucket.sales_volume + qty
        product_bucket.invoice_count = product_bucket.invoice_count + invoice_count
        product_bucket.customer_count = product_bucket.customer_count + customer_count
        product_bucket._months[month] = true

        local pivot_key = month .. "|" .. product_code
        by_product_month[pivot_key] = {
            month = month,
            product_id = product_id,
            product_code = product_code,
            product_name = product_name,
            sales_volume = qty,
            invoice_count = invoice_count,
            customer_count = customer_count
        }
    end
end

local group_by_month = {}
for _, bucket in pairs(by_month) do
    local product_count = 0
    for _ in pairs(bucket._products) do
        product_count = product_count + 1
    end
    bucket.product_count = product_count
    bucket._products = nil
    bucket.sales_volume = math.floor(bucket.sales_volume * 1000 + 0.5) / 1000
    table.insert(group_by_month, bucket)
end
table.sort(group_by_month, function(a, b)
    return tostring(a.month) < tostring(b.month)
end)

for i, bucket in ipairs(group_by_month) do
    local prev = group_by_month[i - 1]
    if prev ~= nil and (prev.sales_volume or 0) > 0 then
        bucket.growth_percent = ((bucket.sales_volume - prev.sales_volume) * 100.0) / prev.sales_volume
    else
        bucket.growth_percent = nil
    end
end

local group_by_product = {}
for _, bucket in pairs(by_product) do
    local month_count = 0
    for _ in pairs(bucket._months) do
        month_count = month_count + 1
    end
    bucket.month_count = month_count
    bucket._months = nil
    bucket.sales_volume = math.floor(bucket.sales_volume * 1000 + 0.5) / 1000
    table.insert(group_by_product, bucket)
end
table.sort(group_by_product, function(a, b)
    if a.sales_volume == b.sales_volume then
        return tostring(a.product_code) < tostring(b.product_code)
    end
    return a.sales_volume > b.sales_volume
end)

local group_by_product_month = {}
for _, bucket in pairs(by_product_month) do
    bucket.sales_volume = math.floor(bucket.sales_volume * 1000 + 0.5) / 1000
    table.insert(group_by_product_month, bucket)
end
table.sort(group_by_product_month, function(a, b)
    if a.month ~= b.month then
        return tostring(a.month) < tostring(b.month)
    end
    if a.sales_volume == b.sales_volume then
        return tostring(a.product_code) < tostring(b.product_code)
    end
    return a.sales_volume > b.sales_volume
end)

summary.sales_volume_total = math.floor(summary.sales_volume_total * 1000 + 0.5) / 1000
summary.product_count = #group_by_product
summary.month_count = #group_by_month

local invoice_total_rows = fetch_rows([[
SELECT
    COUNT(DISTINCT si.ID) AS invoice_count,
    COUNT(DISTINCT si.CLIENT_ID) AS customer_count
FROM sales_invoice si
WHERE ]] .. sales_invoice_filter_sql() .. [[
  AND si.ORG_ID = ]] .. tostring(org_id) .. [[
  AND REPORT_FN_JDATE(si.RUN_DATE, '-') >= ?
  AND REPORT_FN_JDATE(si.RUN_DATE, '-') <= ?
]], { start_jalali, end_jalali })
if invoice_total_rows ~= nil and #invoice_total_rows > 0 then
    summary.invoice_count = tonumber(invoice_total_rows[1][1]) or 0
    summary.customer_count = tonumber(invoice_total_rows[1][2]) or 0
end

local top_product = group_by_product[1]
local best_month = nil
for _, bucket in ipairs(group_by_month) do
    if best_month == nil or bucket.sales_volume > best_month.sales_volume then
        best_month = bucket
    end
end

local function growth_class(value)
    local n = tonumber(value)
    if n == nil then
        return "rate-neutral"
    end
    if n > 0 then
        return "rate-good"
    end
    if n < 0 then
        return "rate-critical"
    end
    return "rate-neutral"
end

local function share_percent(part, total)
    local p = tonumber(part) or 0
    local t = tonumber(total) or 0
    if t <= 0 then
        return nil
    end
    return (p * 100.0) / t
end

local payload = {
    ok = true,
    unit_name = "فروش اکسسوری موبایل",
    metric = "sales_volume",
    startDate = start_jalali,
    end_date = end_jalali,
    org_id = org_id,
    dates_defaulted = dates_defaulted,
    dates_swapped = dates_swapped,
    summary = summary,
    top_product = top_product,
    best_month = best_month,
    group_by_month = group_by_month,
    group_by_product = group_by_product,
    group_by_product_month = group_by_product_month
}

if output_json then
    teamyar.write_result(json.encode(payload))
    return
end

local generated_at = fetch_generated_at()

local month_rows = {}
if #group_by_month == 0 then
    table.insert(month_rows, [[<tr><td colspan="6" class="empty-row">داده‌ای یافت نشد</td></tr>]])
else
    for i, row in ipairs(group_by_month) do
        table.insert(month_rows, safe_format(
            [[<tr>
                <td>%d</td>
                <td class="mono">%s</td>
                <td>%s</td>
                <td>%s</td>
                <td>%s</td>
                <td class="%s">%s</td>
            </tr>]],
            i,
            escape_html(row.month),
            fmt_qty(row.sales_volume),
            fmt_num(row.invoice_count),
            fmt_num(row.product_count),
            growth_class(row.growth_percent),
            fmt_percent(row.growth_percent)
        ))
    end
end

local product_rows = {}
local product_limit = math.min(#group_by_product, MAX_PRODUCT_ROWS)
if product_limit == 0 then
    table.insert(product_rows, [[<tr><td colspan="7" class="empty-row">داده‌ای یافت نشد</td></tr>]])
else
    for i = 1, product_limit do
        local row = group_by_product[i]
        table.insert(product_rows, safe_format(
            [[<tr>
                <td>%d</td>
                <td class="mono">%s</td>
                <td class="name-cell">%s</td>
                <td>%s</td>
                <td>%s</td>
                <td>%s</td>
                <td>%s</td>
            </tr>]],
            i,
            escape_html(row.product_code),
            escape_html(row.product_name),
            fmt_qty(row.sales_volume),
            fmt_percent(share_percent(row.sales_volume, summary.sales_volume_total)),
            fmt_num(row.invoice_count),
            fmt_num(row.month_count)
        ))
    end
    if #group_by_product > product_limit then
        table.insert(product_rows, safe_format(
            [[<tr><td colspan="7" class="empty-row">نمایش %s از %s کالا</td></tr>]],
            fmt_num(product_limit),
            fmt_num(#group_by_product)
        ))
    end
end

local pivot_rows = {}
local pivot_limit = math.min(#group_by_product_month, MAX_PRODUCT_ROWS)
if pivot_limit == 0 then
    table.insert(pivot_rows, [[<tr><td colspan="6" class="empty-row">داده‌ای یافت نشد</td></tr>]])
else
    for i = 1, pivot_limit do
        local row = group_by_product_month[i]
        table.insert(pivot_rows, safe_format(
            [[<tr>
                <td>%d</td>
                <td class="mono">%s</td>
                <td class="mono">%s</td>
                <td class="name-cell">%s</td>
                <td>%s</td>
                <td>%s</td>
            </tr>]],
            i,
            escape_html(row.month),
            escape_html(row.product_code),
            escape_html(row.product_name),
            fmt_qty(row.sales_volume),
            fmt_num(row.invoice_count)
        ))
    end
end

local top_product_label = "—"
if top_product ~= nil then
    top_product_label = (top_product.product_code or "—") .. " | " .. fmt_qty(top_product.sales_volume)
end
local best_month_label = "—"
if best_month ~= nil then
    best_month_label = (best_month.month or "—") .. " | " .. fmt_qty(best_month.sales_volume)
end

local ok_html, html_or_err = pcall(function()
    return string.format([[
<!DOCTYPE html>
<html dir="rtl" lang="fa">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>ارزیابی عملکرد فروش اکسسوری موبایل</title>
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
.name-cell { text-align: right; font-weight: bold; white-space: normal; }
.empty-row { padding: 24px !important; color: #666; }
.rate-good { background: #c6efce; color: #006100; font-weight: bold; }
.rate-critical { background: #ffc7ce; color: #9c0006; font-weight: bold; }
.rate-neutral { color: #666; }
.footer { text-align: center; color: #666; font-size: 11px; margin-top: 10px; }
</style>
</head>
<body>
<div id="reportRoot">
    <div class="toolbar">
        <button type="button" class="btn-fullscreen" id="btnFullscreen" onclick="toggleFullScreen()">تمام صفحه</button>
    </div>
    <div class="report-header">
        <p><strong>ارزیابی عملکرد واحد فروش اکسسوری موبایل</strong></p>
        <p>شاخص اصلی: حجم فروش (تعداد)</p>
        <div class="meta-line">
            از تاریخ: %s | تا تاریخ: %s | org_id: %s | زمان تولید: %s
        </div>
    </div>
    <table class="summary-table">
        <tr class="summary-head">
            <td>حجم فروش</td>
            <td>تعداد فاکتور</td>
            <td>تعداد مشتری</td>
            <td>تعداد کالا</td>
            <td>تعداد ماه</td>
            <td>بهترین ماه</td>
            <td>کالای برتر</td>
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
        <button type="button" class="tab-btn active" data-tab="tab-month" onclick="switchTab(this)">روند ماهانه</button>
        <button type="button" class="tab-btn" data-tab="tab-product" onclick="switchTab(this)">رتبه‌بندی کالا</button>
        <button type="button" class="tab-btn" data-tab="tab-pivot" onclick="switchTab(this)">کالا × ماه</button>
    </div>
    <div class="tab-panel active" id="tab-month">
        <div class="table-wrap">
            <table>
                <thead><tr>
                    <th>ردیف</th><th>ماه</th><th>حجم فروش</th><th>تعداد فاکتور</th>
                    <th>تعداد کالا</th><th>رشد ماهانه</th>
                </tr></thead>
                <tbody>%s</tbody>
            </table>
        </div>
    </div>
    <div class="tab-panel" id="tab-product">
        <div class="table-wrap">
            <table>
                <thead><tr>
                    <th>ردیف</th><th>کد کالا</th><th>نام کالا</th><th>حجم فروش</th>
                    <th>سهم</th><th>تعداد فاکتور</th><th>تعداد ماه</th>
                </tr></thead>
                <tbody>%s</tbody>
            </table>
        </div>
    </div>
    <div class="tab-panel" id="tab-pivot">
        <div class="table-wrap">
            <table>
                <thead><tr>
                    <th>ردیف</th><th>ماه</th><th>کد کالا</th><th>نام کالا</th>
                    <th>حجم فروش</th><th>تعداد فاکتور</th>
                </tr></thead>
                <tbody>%s</tbody>
            </table>
        </div>
    </div>
    <div class="footer">Teamyar Sales Accessory Volume Performance Report</div>
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
        escape_html(start_jalali),
        escape_html(end_jalali),
        escape_html(org_id),
        escape_html(generated_at),
        fmt_qty(summary.sales_volume_total),
        fmt_num(summary.invoice_count),
        fmt_num(summary.customer_count),
        fmt_num(summary.product_count),
        fmt_num(summary.month_count),
        escape_html(best_month_label),
        escape_html(top_product_label),
        table.concat(month_rows, "\n"),
        table.concat(product_rows, "\n"),
        table.concat(pivot_rows, "\n")
    )
end)

if not ok_html then
    fail("خطا در ساخت گزارش HTML", tostring(html_or_err))
    return
end

teamyar.write_result(html_or_err)
