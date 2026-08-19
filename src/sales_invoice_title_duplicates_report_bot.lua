-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/05/20 16:30

-- عناوین تکراری فاکتور فروش
-- تاریخ‌ها: همیشه سال مالی جاری
-- org_id: پیش‌فرض 2 (قابل override فقط برای فیلتر سازمان)
-- خروجی HTML سبک و محدود (MAX_DISPLAY_ROWS) برای جلوگیری از مشکل لود در Teamyar

local input = teamyar.get_input() or {}

local function normalize_entity_id(value)
    local n = tonumber(value)
    if n ~= nil and n > 0 then return n end
    return nil
end

local org_id = normalize_entity_id(input["org_id"] or input["orgId"] or 2)

local MAX_DISPLAY_ROWS = 500
local myArray = {}

local function normalize_jalali_date(value)
    if value == nil or value == "" then return nil end
    local s = tostring(value):gsub("/", "-"):gsub("%.", "-"):match("^%s*(.-)%s*$")
    local y, m, d = s:match("^(%d%d%d%d)-(%d%d)-(%d%d)$")
    if y then return string.format("%04d-%02d-%02d", tonumber(y), tonumber(m), tonumber(d)) end
    y, m, d = s:match("^(%d%d%d%d)(%d%d)(%d%d)$")
    if y then return string.format("%04d-%02d-%02d", tonumber(y), tonumber(m), tonumber(d)) end
    return nil
end

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
    if not ok then return nil, err end

    local rows = {}
    local record = {}
    while db.query_fetch(record) do
        local row = {}
        for i = 1, #record do row[i] = record[i] end
        table.insert(rows, row)
    end
    db.query_free()
    return rows
end

local function fetch_default_dates()
    -- سال مالی جاری (بر اساس org_id)
    local params = {}
    local org_clause = ""
    if org_id ~= nil then
        org_clause = " AND fy.ORG_ID = ?"
        table.insert(params, org_id)
    end

    local rows = fetch_rows([[
SELECT
    REPORT_FN_JDATE(fy.START_DATE, '-') AS fiscal_start_jalali,
    REPORT_FN_JDATE(fy.END_DATE, '-') AS fiscal_end_jalali
FROM pa_fiscal_year fy
WHERE (UNIX_TIMESTAMP() + 11644473600) * 10000000 >= fy.START_DATE
  AND (UNIX_TIMESTAMP() + 11644473600) * 10000000 <= fy.END_DATE
]] .. org_clause .. [[
ORDER BY fy.START_DATE DESC
LIMIT 1
]], params)

    if rows ~= nil and #rows > 0 and rows[1][1] ~= nil and rows[1][2] ~= nil then
        return tostring(rows[1][1]), tostring(rows[1][2])
    end
    return nil, nil
end

local function escape_html(value)
    if value == nil then return '' end
    return tostring(value)
end

local start_jalali, end_jalali = fetch_default_dates()
if start_jalali == nil or end_jalali == nil then
    teamyar.write_result("تاریخ سال مالی جاری مشخص نشد.")
    return
end

-- اعمال فقط برای بازه درست (اگر معکوس شد)
local dates_swapped = false
if start_jalali > end_jalali then
    start_jalali, end_jalali = end_jalali, start_jalali
    dates_swapped = true
end

-- =========================================================
-- HTML (سبک و دارای محدودیت ردیف)
-- =========================================================
local Res_chart = [[
<html dir="rtl" lang="fa">
<head><meta charset="UTF-8"></head>
<body>
<div class="toolbar">
  <button type="button" class="btn-fullscreen" id="btnFullscreen" onclick="toggleFullScreen()">تمام صفحه</button>
</div>
<div id="reportRoot">
<h3 class="report-header">
  <p>عناوین تکراری فاکتور فروش</p>
  <p>سال مالی جاری | org_id: %s</p>
  <p>بازه: <span id="fromDate">—</span> تا <span id="toDate">—</span></p>
  <p>نمایش حداکثر %d ردیف برتر | تعداد عنوان تکراری کل: <span id="dupCount">—</span> | جمع فاکتور: <span id="invCount">—</span></p>
</h3>
<table>
  <thead>
    <tr style="background-color:#0073e6;color:white;">
      <th>ردیف</th>
      <th>عنوان فاکتور</th>
      <th>تعداد</th>
    </tr>
  </thead>
  <tbody id="result"></tbody>
</table>
</div>
<style>
body {
  font-family: IRANSansWeb_Light, Tahoma, sans-serif;
  font-size: 12px;
  font-weight: bold;
  margin: 0;
  padding: 12px;
  background: #f5f7fb;
}
#reportRoot:fullscreen { background: #f5f7fb; padding: 12px; overflow: auto; }
.toolbar { margin-bottom: 10px; }
.btn-fullscreen {
  background: #0073e6;
  color: #fff;
  border: 2px solid #005bb5;
  border-radius: 8px;
  padding: 8px 16px;
  font-family: IRANSansWeb_Light, Tahoma, sans-serif;
  font-size: 12px;
  font-weight: bold;
  cursor: pointer;
}
.report-header {
  background-color: #D2E0FB;
  text-align: center;
  border: 1px dotted black;
  border-radius: 10px;
  padding: 12px 10px;
  margin-bottom: 12px;
}
table {
  font-family: IRANSansWeb_Light, Tahoma, sans-serif;
  border-collapse: collapse;
  width: 100%%;
  text-align: center;
  border: 2px solid #000;
  border-radius: 8px;
  background: #fff;
}
td, th {
  border: 1px dashed #000;
  text-align: center;
  padding: 8px;
  font-size: 11px;
}
th { position: sticky; top: 0; z-index: 2; }
tr:nth-child(even) { background-color: #eeeeee; }
tr:hover { background-color: #D2E0FB; }
.title-cell { text-align: right; }
.count-cell { direction: ltr; unicode-bidi: isolate; }
</style>
<script>
function formatNum(n) {
  n = Math.floor(Number(n) || 0);
  return String(n).replace(/\\B(?=(\\d{3})+(?!\\d))/g, ',');
}
function escapeHtml(s) {
  return String(s == null ? '' : s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/\"/g, '&quot;');
}
function toggleFullScreen() {
  var root = document.getElementById('reportRoot');
  var btn = document.getElementById('btnFullscreen');
  var isFull = document.fullscreenElement || document.webkitFullscreenElement || document.msFullscreenElement;
  if (!isFull) {
    if (root.requestFullscreen) root.requestFullscreen();
    else if (root.webkitRequestFullscreen) root.webkitRequestFullscreen();
    else if (root.msRequestFullscreen) root.msRequestFullscreen();
    btn.innerText = 'خروج از تمام صفحه';
  } else {
    if (document.exitFullscreen) document.exitFullscreen();
    else if (document.webkitExitFullscreen) document.webkitExitFullscreen();
    else if (document.msExitFullscreen) document.msExitFullscreen();
    btn.innerText = 'تمام صفحه';
  }
}
var payload = %s;
var data = payload.rows || [];
var str = '';
for (var i = 0; i < data.length; i++) {
  str += '<tr>';
  str += '<td>' + (i + 1) + '</td>';
  str += '<td class="title-cell">' + escapeHtml(data[i][0]) + '</td>';
  str += '<td class="count-cell">' + formatNum(data[i][1]) + '</td>';
  str += '</tr>';
}
if (data.length === 0) {
  str = '<tr><td colspan="3">عنوان تکراری یافت نشد</td></tr>';
}
document.getElementById('result').innerHTML = str;
document.getElementById('fromDate').innerText = payload.startDate || '—';
document.getElementById('toDate').innerText = payload.end_date || '—';
document.getElementById('dupCount').innerText = formatNum(payload.duplicate_title_count);
document.getElementById('invCount').innerText = formatNum(payload.invoice_count);
</script>
</body>
</html>
]]

local query = [[
SELECT
    TRIM(si.TITLE) AS invoice_title,
    COUNT(*) AS title_count
FROM sales_invoice si
WHERE COALESCE(si.DELETED, 0) = 0
  AND si.ORG_ID = ?
  AND si.TITLE IS NOT NULL
  AND TRIM(si.TITLE) <> ''
  AND REPORT_FN_JDATE(si.RUN_DATE, '-') >= ?
  AND REPORT_FN_JDATE(si.RUN_DATE, '-') <= ?
GROUP BY TRIM(si.TITLE)
HAVING COUNT(*) > 1
ORDER BY title_count DESC, invoice_title
]]

local ok, err = pcall(function()
    run_query(query, { org_id, start_jalali, end_jalali })
end)

if not ok then
    teamyar.write_result("خطا در دریافت عناوین تکراری فاکتور فروش: " .. tostring(err))
    return
end

local duplicate_title_count = 0
local invoice_count = 0
local record = {}

while db.query_fetch(record) do
    duplicate_title_count = duplicate_title_count + 1
    local title_count = tonumber(record[2]) or 0
    invoice_count = invoice_count + title_count
    if #myArray < MAX_DISPLAY_ROWS then
        table.insert(myArray, { tostring(record[1] or ''), title_count })
    end
end

db.query_free()

local payload = {
    org_id = org_id,
    startDate = start_jalali,
    end_date = end_jalali,
    dates_swapped = dates_swapped,
    duplicate_title_count = duplicate_title_count,
    invoice_count = invoice_count,
    displayed_count = #myArray,
    rows = myArray
}

local formatted = string.format(Res_chart, tostring(org_id), MAX_DISPLAY_ROWS, json.encode(payload))
teamyar.write_result(formatted)

