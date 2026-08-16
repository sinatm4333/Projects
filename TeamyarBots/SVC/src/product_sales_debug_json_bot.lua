-- تحلیل و ایجاد توسط مهدی جهانی 09125632329
-- Last Edit = 1405/04/29 09:00
-- بات تشخیصی موقت — بررسی 32010010144 (پاوربانک TP957) در برابر گزارش تامین‌شده اکسل

local input = teamyar.get_input() or {}
local product_code = input["product_code"] or "32010010144"

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

-- ستون‌های WH_REQ_PRODUCT برای پیدا کردن ستون «شماره برگه» و «وضعیت»
local cols_rows = fetch_rows([[
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'WH_REQ_PRODUCT'
ORDER BY ORDINAL_POSITION
]], {})
local columns = {}
if cols_rows ~= nil then
    for _, row in ipairs(cols_rows) do
        table.insert(columns, row[1] .. ":" .. row[2])
    end
end

-- شماره‌های برگه حواله از اکسل کاربر
local request_numbers = { 828,1483,1491,1609,1731,2211,2756,2890,2902,3405,3489,3548,4009,4322,5566,6020,6534,8598,8606,9188,9937,10603,11816,12296,12836,14934,16130,16365,17586,19620,19621,19794,21060,21311 }

local placeholders = {}
local params = {}
for _, n in ipairs(request_numbers) do
    table.insert(placeholders, "?")
    table.insert(params, n)
end
local in_clause = table.concat(placeholders, ", ")

-- تلاش با فرض این‌که «شماره برگه درخواست کالا» = WH_REQ_PRODUCT.ID
local by_id, by_id_err = fetch_rows([[
SELECT rp.ID, rp.REF_ID, rp.REF_TYPE, rp.REQUEST_TYPE, rp.DELETED, rpd.PRODUCT_ID, TRIM(wp.FULL_CODE)
FROM WH_REQ_PRODUCT rp
LEFT JOIN wh_req_product_details rpd ON rpd.REQUEST_ID = rp.ID
LEFT JOIN wh_product wp ON wp.id = rpd.PRODUCT_ID
WHERE rp.ID IN (]] .. in_clause .. [[)
]], params)

-- تلاش با فرض این‌که «شماره برگه درخواست کالا» = یک ستون CODE در WH_REQ_PRODUCT
local by_code, by_code_err = fetch_rows([[
SELECT rp.ID, rp.`CODE`, rp.REF_ID, rp.REF_TYPE, rp.REQUEST_TYPE, rp.DELETED, rpd.PRODUCT_ID, TRIM(wp.FULL_CODE)
FROM WH_REQ_PRODUCT rp
LEFT JOIN wh_req_product_details rpd ON rpd.REQUEST_ID = rp.ID
LEFT JOIN wh_product wp ON wp.id = rpd.PRODUCT_ID
WHERE rp.`CODE` IN (]] .. in_clause .. [[)
]], params)

teamyar.write_result(json.encode({
    ok = true,
    columns = columns,
    by_id_count = by_id ~= nil and #by_id or 0,
    by_id_err = by_id_err,
    by_id_sample = by_id,
    by_code_count = by_code ~= nil and #by_code or 0,
    by_code_err = by_code_err,
    by_code_sample = by_code
}))
