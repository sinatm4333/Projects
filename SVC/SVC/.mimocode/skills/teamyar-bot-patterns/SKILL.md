---
name: teamyar-bot-patterns
description: Common Lua patterns and helper functions for Teamyar bots. Use when creating new Teamyar bots to avoid duplicating utility code.
---

# Teamyar Bot Patterns

Reusable helper functions and patterns for Teamyar Lua bots. Copy the needed helpers into new bot files.

## Input Parsing

```lua
local input = teamyar.get_input() or {}

-- Multi-key input parsing
local start_date = input["startDate"] or input["start_date"]
    or input["from_date"] or input["fromDate"]
local end_date = input["endDate"] or input["end_date"]
    or input["to_date"] or input["toDate"]
local product_code = input["product_code"] or input["productCode"]
local receipt_no = input["receipt_no"] or input["receiptNo"] or input["code"]
```

## Date Normalization

```lua
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
```

## Date Filtering

```lua
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
```

## Output Formatting

```lua
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
```

## Text Normalization

```lua
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

local function normalize_entity_id(value)
    local n = tonumber(value)
    if n ~= nil and n > 0 then
        return n
    end
    return nil
end

local function normalize_product_code(code)
    if code == nil or code == "" then
        return nil
    end
    return tostring(code):match("^%s*(.-)%s*$")
end
```

## SQL Helpers

```lua
local MONEY_SCALE = 10000000.0

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

local function build_in_clause(values)
    local placeholders = {}
    for _ = 1, #values do
        table.insert(placeholders, "?")
    end
    return table.concat(placeholders, ", ")
end
```

## Database Access

```lua
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
```

## Map Helpers

```lua
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
```

## COGS Calculation

```lua
local function purchase_invoice_filter_sql()
    return [[
  COALESCE(pi.DELETED, 0) = 0
  AND COALESCE(pi.CANCELED, 0) = 0
  AND COALESCE(pi.REJECT, 0) = 0]]
end

local function load_product_unit_cogs(product_ids)
    local cogs_by_product = {}
    if #product_ids == 0 then
        return cogs_by_product
    end

    local id_in_clause = build_in_clause(product_ids)
    local id_params = {}
    for _, id in ipairs(product_ids) do
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
                cogs_by_product[product_id] = unit_cogs
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
            if product_id ~= nil and unit_cogs > 0 and cogs_by_product[product_id] == nil then
                cogs_by_product[product_id] = unit_cogs
            end
        end
    end

    return cogs_by_product
end
```

## Sales Query Pattern

```lua
-- DO NOT CHANGE without testing product_code 32030020282
-- Filter: DELETED/CANCELED/REJECT=0 + TYPE NOT IN (1,5)
local function sales_invoice_filter_sql()
    return [[
  COALESCE(si.DELETED, 0) = 0
  AND COALESCE(si.CANCELED, 0) = 0
  AND COALESCE(si.REJECT, 0) = 0
  AND COALESCE(si.TYPE, 0) NOT IN (1, 5)]]
end

local function fetch_sales_by_product_code(product_codes)
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
    local where_parts = { sales_invoice_filter_sql() }
    table.insert(where_parts, "TRIM(wp.FULL_CODE) IN (" .. code_in_clause .. ")")

    local sales_query = [[
SELECT
    TRIM(wp.FULL_CODE) AS FULL_CODE,
    SUM(CASE
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
    END) AS sales_quantity
FROM sales_invoice_product sip
INNER JOIN sales_invoice si
    ON si.ID = sip.INVOICE_ID
INNER JOIN wh_product wp
    ON wp.id = COALESCE(NULLIF(sip.PRODUCT_ID, 0), NULLIF(sip.product_id_info, 0))
WHERE ]] .. table.concat(where_parts, "\n  AND ") .. [[
GROUP BY TRIM(wp.FULL_CODE)
]]

    local sales_rows = fetch_rows(sales_query, normalized_codes)
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
```

## HTML Escape

```lua
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
```

## Receipt Status Labels

```lua
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
```

## Chunking Large IN Clauses

```lua
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
```

## Warranty Stats

```lua
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
```

## Input Validation

Common input validation patterns:

```lua
-- Validate date format
if start_date ~= nil and start_date ~= "" and start_jalali == nil and not is_filetime(start_date) then
    fail("تاریخ شروع نامعتبر است. فرمت: 1404-04-01")
    return
end

-- Validate required input
if receipt_no == nil or receipt_no == "" then
    fail("شماره رسید (receipt_no) وارد نشده است")
    return
end

-- Validate numeric input
local function validate_positive_number(value, name)
    local n = tonumber(value)
    if n == nil or n <= 0 then
        return nil, name .. " باید عدد مثبت باشد"
    end
    return n, nil
end
```

## Common SQL Patterns

### Service Request Status Filter
```lua
-- Filter for completed/replaced service requests
"sr.FINAL_STATUS IN (8, 9)"
```

### Parts Query Pattern
```lua
-- Get parts used in a service request
[[SELECT
    parts.PRODUCT_ID,
    parts.product_code,
    parts.product_name,
    parts.qty
FROM (
    SELECT
        rpd.PRODUCT_ID,
        TRIM(wp.FULL_CODE) AS product_code,
        wp.full_name AS product_name,
        COALESCE(rpd.QUANTITY_VALID_MAIN, rpd.QUANTITY_VALID, 0) AS qty
    FROM WH_REQ_PRODUCT rp
    INNER JOIN wh_req_product_details rpd ON rpd.REQUEST_ID = rp.ID
    INNER JOIN pm_service_request sr ON sr.id = rp.REF_ID
    LEFT JOIN wh_product wp ON wp.id = rpd.PRODUCT_ID
    WHERE rp.DELETED = 0
      AND rp.REQUEST_TYPE = 5
      AND rp.REF_TYPE = 101
      AND REPLACE(COALESCE(rpd.reason_of_cancellation, ''), ' ', '') = ''
      AND sr.id = ?
    UNION ALL
    SELECT
        rpd.PRODUCT_ID,
        TRIM(wp.FULL_CODE) AS product_code,
        wp.full_name AS product_name,
        COALESCE(rpd.QUANTITY_VALID_MAIN, rpd.QUANTITY_VALID, 0) AS qty
    FROM WH_REQ_PRODUCT rp
    INNER JOIN wh_req_product_details rpd ON rpd.REQUEST_ID = rp.ID
    INNER JOIN pm_cost_declaration_detail cd ON cd.ID = rp.REF_ID
    INNER JOIN pm_cost_declaration c ON c.ID = cd.COST_DECLARATION_ID
    INNER JOIN pm_service_request sr ON sr.id = c.SERVICE_REQUEST_ID
    LEFT JOIN wh_product wp ON wp.id = rpd.PRODUCT_ID
    WHERE rp.DELETED = 0
      AND rp.REQUEST_TYPE = 5
      AND rp.REF_TYPE = 109
      AND REPLACE(COALESCE(rpd.reason_of_cancellation, ''), ' ', '') = ''
      AND sr.id = ?
) parts
WHERE COALESCE(parts.qty, 0) > 0
]]
```

### Swap Detail Query Pattern
```lua
-- Get swap/replacement details for a service request
[[SELECT
    ps.SERVICE_REQUEST_ID,
    psd.PRODUCT_ID,
    TRIM(repl.FULL_CODE) AS product_code,
    repl.full_name AS product_name,
    psd.SWAP_TYPE,
    psd.AMOUNT,
    psd.VALUE,
    REPORT_FN_JDATE(ps.SWAP_DATE, '-') AS swap_date
FROM pm_swap ps
INNER JOIN pm_swap_detail psd ON psd.SWAP_ID = ps.ID
LEFT JOIN wh_product repl ON repl.id = psd.PRODUCT_ID
WHERE ps.SERVICE_REQUEST_ID = ?
]]
```

## HTML Report Template

For bots that generate HTML reports, use this base template:

```lua
local REPORT_CSS = [[
@font-face {
  font-family: "YekanBakhReport";
  src: local("Yekan Bakh"), local("YekanBakh");
  font-weight: 400;
  font-style: normal;
  font-display: swap;
}
html, body, body *, button, input, select, textarea, table, th, td {
  font-family: "YekanBakhReport", "Yekan Bakh", "IRANSans", "Tahoma", "Arial", sans-serif !important;
}
html, body {
  margin: 0;
  padding: 0;
  background: #eef1f6;
  color: #23262d;
  font-size: 14px;
  font-weight: 400;
}
.page { padding: 18px; }
.shell {
  max-width: 1180px;
  margin: 0 auto;
  background: #fff;
  border: 1px solid #dbe1ea;
  border-radius: 16px;
  box-shadow: 0 8px 24px rgba(15, 23, 42, .06);
  overflow: hidden;
}
.header {
  display: flex;
  justify-content: space-between;
  gap: 16px;
  align-items: flex-start;
  padding: 20px 22px;
  border-bottom: 1px solid #e6ebf2;
  background: linear-gradient(135deg, #f7f9fc, #eef5ff);
}
.header .title h1 {
  margin: 0 0 6px;
  font-size: 24px;
  font-weight: 800;
  line-height: 1.45;
}
.header .title p {
  margin: 0;
  color: #5b6472;
  font-size: 14px;
  font-weight: 700;
}
.actions { display: flex; gap: 8px; flex-wrap: wrap; }
.btn {
  border: 1px solid #cfd8e6;
  background: #fff;
  color: #23262d;
  border-radius: 10px;
  padding: 8px 14px;
  font-size: 14px;
  font-weight: 800;
  cursor: pointer;
}
.btn.primary {
  background: #1d4ed8;
  border-color: #1d4ed8;
  color: #fff;
}
.kpis {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
  gap: 12px;
  padding: 16px 22px;
  border-bottom: 1px solid #e6ebf2;
  background: #fbfcfe;
}
.kpi {
  background: #fff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 12px 14px;
  min-height: 78px;
}
.kpi .l {
  color: #667085;
  font-size: 13px;
  font-weight: 800;
  margin-bottom: 8px;
}
.kpi .v {
  color: #101828;
  font-size: 22px;
  font-weight: 800;
  line-height: 1.2;
  direction: ltr;
  text-align: right;
  font-variant-numeric: tabular-nums;
}
.kpi .s {
  margin-top: 6px;
  color: #98a2b3;
  font-size: 12px;
  font-weight: 700;
}
.tools {
  display: flex;
  justify-content: space-between;
  gap: 10px;
  flex-wrap: wrap;
  padding: 12px 22px;
  border-bottom: 1px solid #e6ebf2;
}
.badge {
  display: inline-block;
  background: #f2f4f7;
  border: 1px solid #e4e7ec;
  border-radius: 999px;
  padding: 6px 12px;
  margin-left: 6px;
  font-size: 13px;
  font-weight: 800;
  color: #344054;
}
.badge b { color: #1d4ed8; }
.table-wrap { padding: 0 0 8px; overflow: auto; }
table {
  width: 100%;
  border-collapse: collapse;
}
th, td {
  padding: 14px 22px;
  border-bottom: 1px solid #eef2f6;
  text-align: right;
  font-size: 14px;
}
th {
  width: 62%;
  color: #475467;
  font-weight: 800;
  background: #fafbfc;
}
td {
  width: 38%;
  color: #101828;
  font-weight: 800;
  direction: ltr;
  text-align: right;
  font-variant-numeric: tabular-nums;
}
tr:last-child th, tr:last-child td { border-bottom: none; }
.footer {
  padding: 14px 22px 18px;
  color: #98a2b3;
  font-size: 12px;
  font-weight: 700;
  border-top: 1px solid #e6ebf2;
  background: #fafbfc;
}
]]

local function build_html_report(title, subtitle, kpis, table_html, footer_text)
    local kpi_html = ""
    if kpis and #kpis > 0 then
        kpi_html = '<div class="kpis">'
        for _, kpi in ipairs(kpis) do
            kpi_html = kpi_html .. string.format([[
<div class="kpi">
  <div class="l">%s</div>
  <div class="v">%s</div>
  <div class="s">%s</div>
</div>
]], kpi.label or "", kpi.value or "", kpi.sub or "")
        end
        kpi_html = kpi_html .. '</div>'
    end

    return string.format([[
<!DOCTYPE html>
<html dir="rtl" lang="fa">
<head>
<meta charset="UTF-8">
<title>%s</title>
<style>%s</style>
</head>
<body>
<div class="page">
<div class="shell">
  <div class="header">
    <div class="title">
      <h1>%s</h1>
      <p>%s</p>
    </div>
  </div>
  %s
  <div class="table-wrap">
    %s
  </div>
  <div class="footer">%s</div>
</div>
</div>
</body>
</html>
]], title, REPORT_CSS, title, subtitle or "", kpi_html, table_html or "", footer_text or "")
end
```

## Common Bot Structure

Most Teamyar bots follow this structure:

```lua
-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/04/25 14:55

-- 1. Input parsing
local input = teamyar.get_input() or {}
local start_date = input["startDate"] or input["start_date"]
    or input["from_date"] or input["fromDate"]
-- ... more input parsing

-- 2. Helper functions (copy from this skill as needed)
local function normalize_jalali_date(value) ... end
local function fetch_rows(query, params) ... end
local function escape_html(value) ... end
-- ... more helpers

-- 3. Main query
local query = [[...]]
local params = {...}

-- 4. Execute and fetch
local rows, err = fetch_rows(query, params)
if rows == nil then
    fail("خطا در دریافت اطلاعات", err)
    return
end

-- 5. Process and format output
local result = {}
for _, row in ipairs(rows) do
    -- process row
end

-- 6. Return result
teamyar.write_result(json.encode({
    ok = true,
    data = result
}))
```

## Advanced Input Normalization

For bots that receive JSON strings or complex input structures:

```lua
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
    merge_tables(merged, raw)
    return merged, meta
end
```

## Bot Types

| Type | Pattern | Example |
|------|---------|---------|
| **JSON Bot** | Simple JSON output, no HTML | `bot_commands_json_bot.lua` |
| **HTML Report** | Full HTML report with CSS | `user_activity_stats_report_bot.lua` |
| **HTML/JSON Hybrid** | Default HTML, `format=json` for JSON | `service_replaced_products_json_bot.lua` |
| **Period Report** | Date range with Jalali dates | `service_receipt_cost_period_json_bot.lua` |
| **Single Item Detail** | One item with related data | `service_receipt_cost_json_bot.lua` |
| **Pivot Report** | Cross-tabulation with heat map | `tat_pivot_report_bot.lua` |

## Usage

When creating a new Teamyar bot:

1. **Read the catalog**: `docs/context/TeamyarBotsCatalog.md`
2. **Read a similar bot**: Pick one from `src/` that matches your task type
3. **Copy needed helpers**: Use this skill as a reference for common patterns
4. **Follow the header**: First line must be `-- تحلیل و ایجاد توسط سینا مقدم 09121011778`
5. **Add edit timestamp**: `-- Last Edit = YYYY/MM/DD HH:MM` (Shamsi date)
6. **Parameterized SQL**: Always use `db.query()` with `params = {}`
7. **Error handling**: Use `pcall()` and return `{ ok, error }` with Persian messages
8. **Deploy**: Use `scripts/deploy_teamyar_bot.ps1`
