-- تحلیل و ایجاد توسط مهدی جهانی 09125632329
-- Last Edit = 1405/06/02 10:00

local input = teamyar.get_input() or {}
local product_code = input["product_code"] or input["code"]

if product_code == nil or tostring(product_code) == "" then
    teamyar.write_result(json.encode({
        ok = false,
        error = "کد کالا (product_code) وارد نشده است"
    }))
    return
end

product_code = tostring(product_code)

local query = [[
SELECT
    id,
    TRIM(FULL_CODE) AS product_code,
    NAME
FROM wh_product
WHERE TRIM(FULL_CODE) = ?
LIMIT 1
]]

local ok, err = pcall(function()
    db.query({
        query = query,
        params = { product_code }
    })
end)

if not ok then
    teamyar.write_result(json.encode({
        ok = false,
        error = "خطا در اجرای کوئری",
        detail = tostring(err)
    }))
    return
end

local record = {}
local found = db.query_fetch(record)
db.query_free()

if not found then
    teamyar.write_result(json.encode({
        ok = false,
        error = "کالایی با این کد یافت نشد"
    }))
    return
end

teamyar.write_result(json.encode({
    ok = true,
    product_id = tonumber(record[1]) or record[1],
    product_code = record[2],
    product_name = record[3]
}))