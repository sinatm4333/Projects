local DB_NAME = "0000000"
db.use_db(DB_NAME)

local DEV_NAME = "سینا تقوی مقدم"
local PRODUCT_INFO = "گزارش بررسی سری بودن شماره فاکتور "

local BASE_URL = "https://mobile140.com/dashboard/sell/orders?serial="

local sql = [[
SELECT ID, TITLE
FROM sales_invoice
WHERE TITLE IS NOT NULL
]]

db.query({ query = sql, params = {} })

local rows = {}
local rec = {}
local total_invoices = 0

while db.query_fetch(rec) do
    total_invoices = total_invoices + 1
    local title = tostring(rec[2] or "")
    local number = string.match(title, "(%d%d%d%d%d+)")
    if number ~= nil then
        rows[#rows+1] = tonumber(number)
    end
end

db.query_free()

if #rows == 0 then
    teamyar.write_result("هیچ شماره‌ای استخراج نشد")
    return
end

table.sort(rows)

local missing = {}
for i = 2, #rows do
    local prev = rows[i-1]
    local curr = rows[i]
    if curr - prev > 1 then
        for n = prev + 1, curr - 1 do
            missing[#missing+1] = n
        end
    end
end

local ranges = {}
if #missing > 0 then
    local start_num = missing[1]
    local prev_num = missing[1]
    for i = 2, #missing do
        if missing[i] == prev_num + 1 then
            prev_num = missing[i]
        else
            ranges[#ranges+1] = {start = start_num, finish = prev_num}
            start_num = missing[i]
            prev_num = missing[i]
        end
    end
    ranges[#ranges+1] = {start = start_num, finish = prev_num}
end

local html = [[
<div style="font-family:tahoma;direction:rtl;padding:20px;box-sizing:border-box;">

<!-- Header -->
<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:15px;">
<h2 style="margin:0;">گزارش بررسی سری بودن شماره فاکتور</h2>
<div>
<button onclick="alert('توسعه‌دهنده: ]]..DEV_NAME..[[\n]]..PRODUCT_INFO..[[')"
style="margin-left:8px;padding:6px 12px;border-radius:8px;border:1px solid #ccc;background:#f5f5f5;cursor:pointer;">i</button>
<button onclick="downloadExcel()"
style="padding:6px 12px;border-radius:8px;border:1px solid #4caf50;background:#e8f5e9;cursor:pointer;">دانلود اکسل</button>
</div>
</div>

<!-- Main Layout -->
<div style="display:flex;gap:20px;width:100%;align-items:stretch;">

<!-- Table Column -->
<div style="flex:1;min-width:400px;max-width:55%;overflow:auto;">

<table id="resultTable"
style="width:100%;border-collapse:separate;border-spacing:0;font-size:13px;
border-radius:12px;overflow:hidden;box-shadow:0 6px 18px rgba(0,0,0,0.08);">

<thead style="background:linear-gradient(90deg,#f5f7fa,#e4eaf1);">
<tr>
<th style="padding:10px;">ردیف</th>
<th style="padding:10px;">از شماره</th>
<th style="padding:10px;">تا شماره</th>
<th style="padding:10px;">تعداد</th>
</tr>
</thead>
<tbody>
]]

for i=1,#ranges do
    local r = ranges[i]
    local count_range = r.finish - r.start + 1

    html = html .. "<tr style='text-align:center;'>"
    html = html .. "<td>"..i.."</td>"
    html = html .. "<td><a href='#' onclick=\"loadFrame('"..BASE_URL..r.start.."')\" style='color:#1976d2;font-weight:600;text-decoration:none;'>"..r.start.."</a></td>"
    html = html .. "<td><a href='#' onclick=\"loadFrame('"..BASE_URL..r.finish.."')\" style='color:#1976d2;font-weight:600;text-decoration:none;'>"..r.finish.."</a></td>"
    html = html .. "<td style='color:#d32f2f;font-weight:600'>"..count_range.."</td>"
    html = html .. "</tr>"
end

html = html .. [[
</tbody>
</table>
</div>

<!-- iframe Column -->
<div style="flex:1.2;min-width:600px;border:1px solid #e0e0e0;border-radius:12px;overflow:hidden;">
<iframe id="resultFrame"
style="width:100%;height:800px;border:0;background:white;"></iframe>
</div>

</div>

<script>
function loadFrame(url){
 document.getElementById('resultFrame').src = url;
}

function downloadExcel(){
 var table=document.getElementById('resultTable');
 var rows=[];
 for(var i=0;i<table.rows.length;i++){
  var cols=table.rows[i].cells;
  var row=[];
  for(var j=0;j<cols.length;j++){
   row.push('"' + cols[j].innerText.replace(/"/g,'""') + '"');
  }
  rows.push(row.join(','));
 }
 var csv="\ufeff"+rows.join("\n");
 var blob=new Blob([csv],{type:'text/csv;charset=utf-8;'});
 var link=document.createElement('a');
 link.href=URL.createObjectURL(blob);
 link.download='invoice_series_report.csv';
 link.click();
}
</script>

</div>
]]

teamyar.write_result(html)
