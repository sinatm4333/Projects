-- =========================================
-- Bot: RFM Dashboard
-- Version: v01 (Stable + Excel Fix Only)
-- Developer: سینا تقوی مقدم
-- =========================================

local DB_NAME = "0000000"
db.use_db(DB_NAME)

-- ===============================
-- SQL (Stable Version)
-- ===============================
local sql = [[
WITH base AS (
    SELECT
        p.REFFERE_ID AS client_id,
        p.NAME,
        MAX(s.RUN_DATE) AS LastRunDate,
        COUNT(s.ID) AS Frequency,
        SUM(IFNULL(s.RECEPTION_AMOUNT,0) + IFNULL(s.REMAINED_AMOUNT,0)) AS Monetary
    FROM sales_invoice s
    INNER JOIN pa_client p ON p.ID = s.CLIENT_ID
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
    data[#data+1] = {
        client_id = r[1],
        name = r[2],
        last_invoice_date = r[3],
        last = tonumber(r[4]) or 0,
        frequency = tonumber(r[5]) or 0,
        monetary = tonumber(r[6]) or 0
    }
end
db.query_free()

if #data == 0 then
    teamyar.write_result("No Data Found")
    return
end

-- ===============================
-- Days Calculation (Stable Logic)
-- ===============================
local function div(a,b) return math.floor(a/b) end

local function gregorian_to_jdn(y,m,d)
    local a = div(14 - m, 12)
    local y2 = y + 4800 - a
    local m2 = m + 12*a - 3
    return d + div(153*m2 + 2, 5) + 365*y2 + div(y2,4) - div(y2,100) + div(y2,400) - 32045
end

local function jalali_to_gregorian(jy, jm, jd)
    jy = jy - 979
    jm = jm - 1
    jd = jd - 1

    local j_day_no = 365*jy + div(jy,33)*8 + div((jy%33 + 3),4)
    local j_days = {31,31,31,31,31,31,30,30,30,30,30,29}

    for i=1, jm do
        j_day_no = j_day_no + j_days[i]
    end

    j_day_no = j_day_no + jd

    local g_day_no = j_day_no + 79
    local gy = 1600 + 400*div(g_day_no,146097)
    g_day_no = g_day_no % 146097

    local leap = true

    if g_day_no >= 36525 then
        g_day_no = g_day_no - 1
        gy = gy + 100*div(g_day_no,36524)
        g_day_no = g_day_no % 36524
        if g_day_no >= 365 then
            g_day_no = g_day_no + 1
        else
            leap = false
        end
    end

    gy = gy + 4*div(g_day_no,1461)
    g_day_no = g_day_no % 1461

    if g_day_no >= 366 then
        leap = false
        g_day_no = g_day_no - 1
        gy = gy + div(g_day_no,365)
        g_day_no = g_day_no % 365
    end

    local gd = g_day_no + 1
    local g_days = {31,28,31,30,31,30,31,31,30,31,30,31}
    if leap then g_days[2] = 29 end

    local gm = 1
    while gm<=12 and gd > g_days[gm] do
        gd = gd - g_days[gm]
        gm = gm + 1
    end

    return gy,gm,gd
end

-- today
db.query({ query = "SELECT DATE_FORMAT(CURDATE(), '%Y-%m-%d')" })
local rt = {}
local today_g = ""
if db.query_fetch(rt) then today_g = tostring(rt[1] or "") end
db.query_free()

local gy,gm,gd = today_g:match("^(%d+)%-(%d+)%-(%d+)$")
gy,gm,gd = tonumber(gy),tonumber(gm),tonumber(gd)
local today_jdn = gregorian_to_jdn(gy,gm,gd)

for _,v in ipairs(data) do
    local y,m,d = tostring(v.last_invoice_date or ""):match("^(%d+)%/(%d+)%/(%d+)$")
    if y then
        local gyy,gmm,gdd = jalali_to_gregorian(tonumber(y),tonumber(m),tonumber(d))
        local last_jdn = gregorian_to_jdn(gyy,gmm,gdd)
        local diff = today_jdn - last_jdn
        if diff < 0 then diff = 0 end
        v.days = diff
    else
        v.days = 0
    end
end

-- ===============================
-- RFM Stable Weighted Logic
-- ===============================
table.sort(data,function(a,b) return a.last < b.last end)
for i,v in ipairs(data) do v.r = math.ceil((i/#data)*5) end

table.sort(data,function(a,b) return a.frequency < b.frequency end)
for i,v in ipairs(data) do v.f = math.ceil((i/#data)*5) end

table.sort(data,function(a,b) return a.monetary < b.monetary end)
for i,v in ipairs(data) do v.m = math.ceil((i/#data)*5) end

local WR,WF,WM = 0.20,0.45,0.35
local W_SUM = WR + WF + WM

local function segment(score)
    if score>=4.2 then return "Champions"
    elseif score>=3.5 then return "Loyal"
    elseif score>=2.5 then return "Potential"
    elseif score>=1.8 then return "At Risk"
    else return "Dormant" end
end

for _,v in ipairs(data) do
    v.final = ((v.r*WR)+(v.f*WF)+(v.m*WM))/W_SUM
    v.segment = segment(v.final)
end

local total = 0
for _,v in ipairs(data) do total = total + v.monetary end

local function formatNumber(num)
    local formatted=tostring(math.floor(num))
    while true do
        formatted,k=string.gsub(formatted,"^(-?%d+)(%d%d%d)","%1,%2")
        if k==0 then break end
    end
    return formatted
end

local count = #data

-- ===============================
-- UI + Excel Export (Only Change)
-- ===============================
local html = [[
<div style="padding:30px;font-family:tahoma;background:#f8fafc">
<h2 style="margin-bottom:8px;font-size:22px">📊 RFM CRM Dashboard</h2>

<div style="margin-bottom:15px">
<button onclick="downloadRFMCSV()"
style="background:#16a34a;color:white;
padding:8px 14px;border-radius:6px;
border:none;font-size:14px;cursor:pointer">
⬇ Download Excel
</button>
</div>

<div style="margin-bottom:20px;color:#555;font-size:14px">
Total Customers: <strong>]]..count..[[</strong>
</div>

<table id="rfmTable" width="100%" 
style="border-collapse:collapse;background:white;
font-size:16px;
box-shadow:0 4px 12px rgba(0,0,0,0.08);
border-radius:10px;overflow:hidden">

<thead>
<tr style="background:#eef2f7;border-bottom:2px solid #d9e2ec">
<th onclick="sortTable(0)" style="padding:14px;cursor:pointer;text-align:right">Customer ⬍</th>
<th style="padding:14px;text-align:center">Last Invoice</th>
<th onclick="sortTable(2)" style="padding:14px;cursor:pointer;text-align:center">Frequency ⬍</th>
<th onclick="sortTable(3)" style="padding:14px;cursor:pointer;text-align:center">Monetary ⬍</th>
<th onclick="sortTable(4)" style="padding:14px;cursor:pointer;text-align:center">Share % ⬍</th>
<th onclick="sortTable(5)" style="padding:14px;cursor:pointer;text-align:center">Days ⬍</th>
<th onclick="sortTable(6)" style="padding:14px;cursor:pointer;text-align:center">Final Score ⬍</th>
<th onclick="sortTable(7)" style="padding:14px;cursor:pointer;text-align:center">Segment ⬍</th>
</tr>
</thead>
<tbody>
]]

for _,v in ipairs(data) do
    local share=0
    if total>0 then share=(v.monetary/total)*100 end

    html = html .. "<tr style='border-bottom:1px solid #f0f0f0'>"
    html = html .. "<td style='padding:12px;text-align:right'>"
    html = html .. "<a href='?page=/crm/history/show_sales/"..v.client_id.."§ion=2' target='_blank' style='color:#2563eb;text-decoration:none;font-weight:600'>"
    html = html .. v.name .. "</a></td>"
    html = html .. "<td style='padding:12px;text-align:center'>"..(v.last_invoice_date or "").."</td>"
    html = html .. "<td style='padding:12px;text-align:center'>"..v.frequency.."</td>"
    html = html .. "<td style='padding:12px;text-align:center;font-weight:600'>"..formatNumber(v.monetary).."</td>"
    html = html .. "<td style='padding:12px;text-align:center'>"..string.format("%.2f",share).."%</td>"
    html = html .. "<td style='padding:12px;text-align:center'>"..v.days.."</td>"
    html = html .. "<td style='padding:12px;text-align:center;font-weight:700'>"..string.format("%.2f",v.final).."</td>"
    html = html .. "<td style='padding:12px;text-align:center;font-weight:bold'>"..v.segment.."</td>"
    html = html .. "</tr>"
end

html = html .. [[
</tbody></table></div>

<script>
function downloadRFMCSV(){
  const table=document.getElementById('rfmTable');
  const rows=[];
  const ths=table.querySelectorAll('thead th');
  rows.push(Array.from(ths).map(th=>`"${th.innerText}"`));
  table.querySelectorAll('tbody tr').forEach(tr=>{
    const tds=tr.querySelectorAll('td');
    rows.push(Array.from(tds).map((td,i)=>{
      let v=td.innerText.trim();
      if(i===3) v=v.replace(/,/g,'');
      return `"${v.replace(/"/g,'""')}"`;
    }));
  });
  const csv="\\ufeff"+rows.map(r=>r.join(",")).join("\\n");
  const blob=new Blob([csv],{type:'text/csv;charset=utf-8;'});
  const url=URL.createObjectURL(blob);
  const a=document.createElement('a');
  a.href=url;
  a.download='RFM_Dashboard.csv';
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
}
</script>
]]

teamyar.write_result(html)