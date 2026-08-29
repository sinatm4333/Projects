db.use_db("0000000")

local sql = [[

SELECT

    si.ID,
    si.TITLE,
    si.INVOICE_CODE,
    dd.JNDATE AS RunDate,
    (si.RECEPTION_AMOUNT + si.REMAINED_AMOUNT) AS Amount,
    p.REFFERE_ID,
    p.NAME AS CustomerName

FROM sales_invoice si

LEFT JOIN pa_client p
       ON p.ID = si.CLIENT_ID

LEFT JOIN report_dimdate dd
       ON si.RUN_DATE >= dd.DATEKEY
      AND si.RUN_DATE < dd.DATEKEY + (60*60*24*10000000)

WHERE si.DELETED = 0
  AND si.TITLE IS NOT NULL
  AND si.TITLE IN
(
    SELECT TITLE
    FROM sales_invoice
    WHERE DELETED = 0
      AND TITLE IS NOT NULL
    GROUP BY TITLE
    HAVING COUNT(*) > 1
)

ORDER BY
    si.TITLE,
    si.RUN_DATE DESC

]]

local ok, err = pcall(function()
    db.query({ query = sql })
end)

if not ok then
    teamyar.write_result(err)
    return
end

local html = [[
<html>
<head>
<meta charset="utf-8">
<style>
body{
    font-family:tahoma;
    margin:20px;
    background:#f5f5f5;
}
table{
    width:100%;
    border-collapse:collapse;
    background:white;
}
th,td{
    border:1px solid #ccc;
    padding:8px;
    text-align:center;
}
th{
    background:#e8e8e8;
}
</style>
</head>
<body>

<table>
<tr>
    <th>ID</th>
    <th>Title</th>
    <th>Invoice Code</th>
    <th>Run Date</th>
    <th>Amount</th>
    <th>Customer ID</th>
    <th>Customer Name</th>
</tr>
]]

local row = {}

while db.query_fetch(row) do
    html = html ..
    "<tr>" ..
    "<td>" .. tostring(row[1] or "") .. "</td>" ..
    "<td>" .. tostring(row[2] or "") .. "</td>" ..
    "<td>" .. tostring(row[3] or "") .. "</td>" ..
    "<td>" .. tostring(row[4] or "") .. "</td>" ..
    "<td>" .. tostring(row[5] or 0) .. "</td>" ..
    "<td>" .. tostring(row[6] or "") .. "</td>" ..
    "<td>" .. tostring(row[7] or "") .. "</td>" ..
    "</tr>"
end

db.query_free()

html = html .. [[
</table>
</body>
</html>
]]

teamyar.write_result(html)