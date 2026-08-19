-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/05/20 16:30
-- بات تشخیصی موقت — بررسی TYPE breakdown برای 32030020282 (کد رگرسیون رسمی پروژه، انتظار ~108646)

local input = teamyar.get_input() or {}
local product_code = input["product_code"] or "32030020282"

local function fetch_rows(query, params)
    local ok, err = pcall(function()
        db.query({ query = query, params = params or {} })
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

pcall(function()
    db.use_db("0000000")
end)

local MONEY_SCALE = 10000000.0
local QTY_CASE_SQL = [[
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

local wh_rows = fetch_rows(
    "SELECT id, TRIM(FULL_CODE) FROM wh_product WHERE TRIM(FULL_CODE) = ?",
    { product_code }
)
local ids = {}
local wh_products = {}
if wh_rows ~= nil then
    for _, row in ipairs(wh_rows) do
        table.insert(ids, tonumber(row[1]))
        table.insert(wh_products, { id = tonumber(row[1]), full_code = row[2] })
    end
end

local placeholders = {}
local params = {}
for _, id in ipairs(ids) do
    table.insert(placeholders, "?")
    table.insert(params, id)
end
local in_clause = table.concat(placeholders, ", ")

local status_breakdown = nil
local no_type_filter_total = nil
local current_filter_total = nil
if #ids > 0 then
    status_breakdown = fetch_rows([[
SELECT si.TYPE, COALESCE(si.DELETED,0), COALESCE(si.CANCELED,0), COALESCE(si.REJECT,0), COUNT(*), SUM(]] .. QTY_CASE_SQL .. [[)
FROM sales_invoice_product sip
INNER JOIN sales_invoice si ON si.ID = sip.INVOICE_ID
WHERE COALESCE(NULLIF(sip.PRODUCT_ID, 0), NULLIF(sip.product_id_info, 0)) IN (]] .. in_clause .. [[)
GROUP BY si.TYPE, COALESCE(si.DELETED,0), COALESCE(si.CANCELED,0), COALESCE(si.REJECT,0)
]], params)

    local p2 = {}
    for _, id in ipairs(ids) do table.insert(p2, id) end
    no_type_filter_total = fetch_rows([[
SELECT COUNT(*), SUM(]] .. QTY_CASE_SQL .. [[)
FROM sales_invoice_product sip
INNER JOIN sales_invoice si ON si.ID = sip.INVOICE_ID
WHERE COALESCE(si.DELETED,0)=0 AND COALESCE(si.CANCELED,0)=0 AND COALESCE(si.REJECT,0)=0
  AND COALESCE(NULLIF(sip.PRODUCT_ID, 0), NULLIF(sip.product_id_info, 0)) IN (]] .. in_clause .. [[)
]], p2)

    local p3 = {}
    for _, id in ipairs(ids) do table.insert(p3, id) end
    current_filter_total = fetch_rows([[
SELECT COUNT(*), SUM(]] .. QTY_CASE_SQL .. [[)
FROM sales_invoice_product sip
INNER JOIN sales_invoice si ON si.ID = sip.INVOICE_ID
WHERE COALESCE(si.DELETED,0)=0 AND COALESCE(si.CANCELED,0)=0 AND COALESCE(si.REJECT,0)=0
  AND COALESCE(si.TYPE,0) NOT IN (1,5)
  AND COALESCE(NULLIF(sip.PRODUCT_ID, 0), NULLIF(sip.product_id_info, 0)) IN (]] .. in_clause .. [[)
]], p3)
end

local status_rows = {}
if status_breakdown ~= nil then
    for _, row in ipairs(status_breakdown) do
        table.insert(status_rows, { type = tonumber(row[1]), deleted = tonumber(row[2]), cancelled = tonumber(row[3]), rejected = tonumber(row[4]), count = tonumber(row[5]), qty = tonumber(row[6]) })
    end
end

local function fmt(rows)
    if rows == nil or #rows == 0 then return nil end
    return { count = tonumber(rows[1][1]), qty = tonumber(rows[1][2]) }
end

teamyar.write_result(json.encode({
    ok = true,
    wh_products = wh_products,
    status_breakdown = status_rows,
    no_type_filter_total = fmt(no_type_filter_total),
    current_filter_total = fmt(current_filter_total)
}))
