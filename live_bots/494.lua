-- botName = rfm3
-- version = STABLE_FINAL_REFFERE_ID_WITH_SHAMSI_RUNDATE_FIXED

db.use_db("0000000")

-- ===============================
-- گرفتن دیتا با RUN_DATE صحیح + تبدیل دقیق شمسی
-- ===============================

local sql = [[
WITH base AS (
    SELECT
        p.REFFERE_ID AS client_id,
        p.NAME,
        MAX(s.RUN_DATE) AS LastRunDate,
        COUNT(s.ID) AS Frequency,
        SUM(s.RECEPTION_AMOUNT + s.REMAINED_AMOUNT) AS Monetary
    FROM sales_invoice s
    INNER JOIN pa_client p 
        ON p.ID = s.CLIENT_ID
    WHERE s.DELETED = 0
      AND s.CANCELED = 0
      AND s.PRE_INVOICE = 0
      AND s.RUN_DATE > 0
    GROUP BY p.REFFERE_ID, p.NAME
)

SELECT
    b.client_id,
    b.NAME,
    dd.JNDATE AS LastInvoiceDate,
    b.LastRunDate,
    b.Frequency,
    b.Monetary
FROM base b
LEFT JOIN report_dimdate dd
    ON b.LastRunDate >= dd.DATEKEY
   AND b.LastRunDate <  dd.DATEKEY + (60*60*24*10000000)
ORDER BY b.Monetary DESC
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
        last_invoice_date = r[3],
        last = tonumber(r[4]) or 0,
        frequency = tonumber(r[5]) or 0,
        monetary = tonumber(r[6]) or 0
    })
end

db.query_free()

-- ===============================
-- RFM Scoring
-- ===============================

table.sort(data, function(a,b) return a.last < b.last end)
for i,v in ipairs(data) do
    v.r_score = math.ceil((i/#data)*5)
end

table.sort(data, function(a,b) return a.frequency < b.frequency end)
for i,v in ipairs(data) do
    v.f_score = math.ceil((i/#data)*5)
end

table.sort(data, function(a,b) return a.monetary < b.monetary end)
for i,v in ipairs(data) do
    v.m_score = math.ceil((i/#data)*5)
end

local total = 0
for _,v in ipairs(data) do
    total = total + v.monetary
end

local function formatNumber(num)
    if not num then return "0" end
    local formatted = tostring(math.floor(num))
    while true do  
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return formatted
end

local count = #data

local html = [[
<div style="padding:30px;font-family:tahoma;background:#f8fafc">
<h2 style="margin-bottom:8px;font-size:22px">📊 RFM CRM Dashboard</h2>
<div style="margin-bottom:20px;color:#555;font-size:14px">
Total Customers: <strong>]]..count..[[</strong>
</div>

<table id="rfmTable" width="100%" 
style="border-collapse:collapse;background:white;
font-size:16px;
box-shadow:0 4px 12px rgba(0,0,0,0.08);
border-radius:10px;
overflow:hidden">

<thead>
<tr style="background:#eef2f7;border-bottom:2px solid #d9e2ec">
<th onclick="sortTable(0)" style="padding:14px;cursor:pointer;text-align:right">Customer ⬍</th>
<th style="padding:14px;text-align:center">Last Invoice (شمسی)</th>
<th onclick="sortTable(2)" style="padding:14px;cursor:pointer;text-align:center">Frequency ⬍</th>
<th onclick="sortTable(3)" style="padding:14px;cursor:pointer;text-align:center">Monetary ⬍</th>
<th onclick="sortTable(4)" style="padding:14px;cursor:pointer;text-align:center">Share % ⬍</th>
<th onclick="sortTable(5)" style="padding:14px;cursor:pointer;text-align:center">RFM ⬍</th>
<th onclick="sortTable(6)" style="padding:14px;cursor:pointer;text-align:center">Segment ⬍</th>
</tr>
</thead>
<tbody>
]]

for _,v in ipairs(data) do

    local share = 0
    if total > 0 then
        share = (v.monetary / total) * 100
    end

    local rfm = tostring(v.r_score)..tostring(v.f_score)..tostring(v.m_score)

    local segment = "Others"
    if v.r_score>=4 and v.f_score>=4 and v.m_score>=4 then
        segment = "Champions"
    elseif v.r_score>=4 and v.f_score>=3 then
        segment = "Loyal"
    elseif v.r_score<=2 and v.f_score>=3 then
        segment = "At Risk"
    elseif v.f_score==1 then
        segment = "One-Time"
    end

    local color = "#444"
    if segment=="Champions" then color="#16a34a" end
    if segment=="At Risk" then color="#dc2626" end
    if segment=="Loyal" then color="#2563eb" end

    html = html .. "<tr style='border-bottom:1px solid #f0f0f0'>"
    html = html .. "<td style='padding:12px;text-align:right'>"
    html = html .. "<a href='?page=/crm/history/show_sales/"..v.client_id.."&section=2' target='_blank' style='color:#2563eb;text-decoration:none;font-weight:600'>"
    html = html .. v.name
    html = html .. "</a></td>"
    html = html .. "<td style='padding:12px;text-align:center'>"..(v.last_invoice_date or "").."</td>"
    html = html .. "<td style='padding:12px;text-align:center'>"..v.frequency.."</td>"
    html = html .. "<td style='padding:12px;text-align:center;font-weight:600'>"..formatNumber(v.monetary).."</td>"
    html = html .. "<td style='padding:12px;text-align:center'>"..string.format("%.2f", share).."%".."</td>"
    html = html .. "<td style='padding:12px;text-align:center'>"..rfm.."</td>"
    html = html .. "<td style='padding:12px;text-align:center;font-weight:bold;color:"..color.."'>"..segment.."</td>"
    html = html .. "</tr>"
end

html = html .. [[
</tbody>
</table>
</div>

<script>
function sortTable(n) {
  var table = document.getElementById("rfmTable");
  var rows = Array.from(table.rows).slice(1);
  var asc = table.getAttribute("data-sort") !== "asc";
  table.setAttribute("data-sort", asc ? "asc" : "desc");

  rows.sort(function(a, b) {
    var x = a.cells[n].innerText.replace(/,/g,'');
    var y = b.cells[n].innerText.replace(/,/g,'');

    if(!isNaN(x) && !isNaN(y)){
        return asc ? x - y : y - x;
    }
    return asc ? x.localeCompare(y) : y.localeCompare(x);
  });

  rows.forEach(row => table.tBodies[0].appendChild(row));
}
</script>
]]

teamyar.write_result(html)