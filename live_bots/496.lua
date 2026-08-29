-- botName = rfm3
-- version = v05_SQL_GREGORIAN

local input = teamyar.get_input()
db.use_db("0000000")

local sql = [[
SELECT
    p.REFFERE_ID AS client_id,
    p.NAME,
    FROM_UNIXTIME((MAX(s.DATE_CREATE)/10000000) - 11644473600) AS LastInvoiceDate,
    COUNT(s.ID) AS Frequency,
    SUM(s.RECEPTION_AMOUNT + s.REMAINED_AMOUNT) AS Monetary
FROM sales_invoice s
INNER JOIN pa_client p 
    ON p.ID = s.CLIENT_ID
WHERE s.DELETED = 0
  AND s.CANCELED = 0
  AND s.PRE_INVOICE = 0
GROUP BY p.REFFERE_ID, p.NAME
ORDER BY Monetary DESC
LIMIT 500
]]

local ok, err = pcall(function()
    db.query({ query = sql })
end)

if not ok then
    teamyar.write_result("SQL ERROR: "..tostring(err))
    return
end

local data = {}
local r = {}

while db.query_fetch(r) do
    table.insert(data,{
        client_id = r[1],
        name = r[2],
        last_invoice_date = r[3], -- 👈 مستقیم میلادی از SQL
        frequency = tonumber(r[4]) or 0,
        monetary = tonumber(r[5]) or 0
    })
end

db.query_free()

local total_monetary = 0
for _,v in ipairs(data) do
    total_monetary = total_monetary + v.monetary
end

local output = {
    success = true,
    total_customers = #data,
    total_monetary = total_monetary,
    list = data
}

teamyar.write_result(json.encode(output))