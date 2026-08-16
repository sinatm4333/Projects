-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/05/20 16:30

-- Monthly KPI dashboard: 12 sets of 6 KPI cards (one set per month, 1405)

local input = teamyar.get_input() or {}
local org_id = input["org_id"] or input["orgId"] or "2"

-- ── helpers ──────────────────────────────────────────────────────────

local function escape_html(value)
    if value == nil then return "" end
    return tostring(value)
        :gsub("&", "&amp;")
        :gsub("<", "&lt;")
        :gsub(">", "&gt;")
        :gsub('"', '&quot;')
end

local function fmt_num(value)
    local n = tonumber(value)
    if n == nil then return "0" end
    local s = tostring(math.floor(n + 0.5))
    local grouped = s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    return grouped
end

local function fmt_decimal(value, decimals)
    local n = tonumber(value)
    if n == nil then return "0.0" end
    decimals = decimals or 1
    return string.format("%." .. decimals .. "f", n)
end

local function fetch_rows(query, params)
    db.use_db("0000000")
    local ok, err = pcall(function()
        db.query({ query = query, params = params or {} })
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

-- ── current Shamsi month (via MySQL date + Lua conversion) ───────────

local function g_to_j(gy, gm, gd)
    local g_d = 365*gy + math.floor((gy+3)/4) - math.floor((gy+99)/100) + math.floor((gy+399)/400)
    local g_md = {0,31,59,90,120,151,181,212,243,273,304,334}
    g_d = g_d + g_md[gm+1] + gd
    if gm > 2 then g_d = g_d + (((gy%4==0 and gy%100~=0) or (gy%400==0)) and 1 or 0) end
    local j_d = g_d - 79
    local j_np = math.floor(j_d / 12053)
    j_d = j_d % 12053
    local jy = 979 + 33*j_np + 4*math.floor(j_d/1461)
    j_d = j_d % 1461
    if j_d >= 366 then
        jy = jy + math.floor((j_d-1)/365)
        j_d = (j_d-1) % 365
    end
    local j_md = {0,31,62,93,124,155,186,216,246,276,306,336}
    local jm, jd = 1, 1
    for i = 11, 1, -1 do
        if j_d >= j_md[i] then
            jm = i
            jd = j_d - j_md[i] + 1
            break
        end
    end
    return jy, jm, jd
end

-- ── month definitions (1405) — تمام 12 ماه ─────────────────────────

local months = {
    { name = "فروردین",   start = "1405-01-01", ["end"] = "1405-01-31" },
    { name = "اردیبهشت", start = "1405-02-01", ["end"] = "1405-02-31" },
    { name = "خرداد",     start = "1405-03-01", ["end"] = "1405-03-31" },
    { name = "تیر",       start = "1405-04-01", ["end"] = "1405-04-31" },
    { name = "مرداد",     start = "1405-05-01", ["end"] = "1405-05-31" },
    { name = "شهریور",   start = "1405-06-01", ["end"] = "1405-06-31" },
    { name = "مهر",       start = "1405-07-01", ["end"] = "1405-07-30" },
    { name = "آبان",      start = "1405-08-01", ["end"] = "1405-08-30" },
    { name = "آذر",       start = "1405-09-01", ["end"] = "1405-09-30" },
    { name = "دی",        start = "1405-10-01", ["end"] = "1405-10-30" },
    { name = "بهمن",      start = "1405-11-01", ["end"] = "1405-11-29" },
    { name = "اسفند",     start = "1405-12-01", ["end"] = "1405-12-29" },
}

-- ── fetch KPIs for all months in one query ───────────────────────────

local kpi_rows = fetch_rows([[
SELECT
    LEFT(REPORT_FN_JDATE(sr.BREAK_DOWN_DATE, '-'), 7) AS month,
    COUNT(DISTINCT sr.ID) AS total,
    COUNT(DISTINCT CASE WHEN sr.FINAL_STATUS IN (3,6,8,9) THEN sr.ID END) AS completed,
    COUNT(DISTINCT CASE WHEN sr.FINAL_STATUS = 5 THEN sr.ID END) AS cancelled,
    COUNT(DISTINCT CASE WHEN sr.FINAL_STATUS IN (0,1,2) THEN sr.ID END) AS open_count,
    AVG(CASE
        WHEN sr.FINAL_STATUS IN (6,7,8) AND sr.BREAK_DOWN_DATE > 0
        THEN DATEDIFF(
            FROM_UNIXTIME((
                SELECT MAX(c.CREATION_DATE) FROM pm_service_request_content c
                WHERE c.SERVICE_REQUEST_ID = sr.ID
                  AND c.NEW_ID IN (6,7,8)
            ) / 10000000 - 11644473600),
            FROM_UNIXTIME(sr.BREAK_DOWN_DATE / 10000000 - 11644473600)
        )
    END) AS avg_days_to_ready,
    AVG(CASE
        WHEN sr.FINAL_STATUS IN (3,9) AND sr.BREAK_DOWN_DATE > 0
        THEN DATEDIFF(
            FROM_UNIXTIME((
                SELECT MAX(c.CREATION_DATE) FROM pm_service_request_content c
                WHERE c.SERVICE_REQUEST_ID = sr.ID
                  AND c.NEW_ID IN (3,9)
            ) / 10000000 - 11644473600),
            FROM_UNIXTIME(sr.BREAK_DOWN_DATE / 10000000 - 11644473600)
        )
    END) AS avg_days_to_complete
FROM pm_service_request sr
WHERE REPORT_FN_JDATE(sr.BREAK_DOWN_DATE, '-') >= '1405-01-01'
  AND REPORT_FN_JDATE(sr.BREAK_DOWN_DATE, '-') <= '1405-12-29'
GROUP BY month
ORDER BY month ASC
]], {})

-- index results by month key (e.g. "1405-01")
local kpi_map = {}
if kpi_rows then
    for _, r in ipairs(kpi_rows) do
        local mk = r[1] or ""
        kpi_map[mk] = {
            total       = tonumber(r[2]) or 0,
            completed   = tonumber(r[3]) or 0,
            cancelled   = tonumber(r[4]) or 0,
            open_count  = tonumber(r[5]) or 0,
            avg_ready   = tonumber(r[6]) or 0,
            avg_complete= tonumber(r[7]) or 0,
        }
    end
end

-- ── comparison badge helpers ─────────────────────────────────────────

local function cmp_badge(prev_val, curr_val, increase_is_good)
    if prev_val == nil or prev_val == 0 or curr_val == nil then return "" end
    local diff = curr_val - prev_val
    if diff == 0 then return "" end
    local pct = math.floor((diff / math.abs(prev_val) * 1000) + 0.5) / 10
    if pct == 0 then return "" end
    local sign = pct > 0 and "+" or ""
    local good = (pct > 0) == increase_is_good
    local bg = good and "#dcfce7" or "#fee2e2"
    local fg = good and "#166534" or "#991b1b"
    return '<span class="cmp-badge" style="background:' .. bg .. ';color:' .. fg .. ';">' .. sign .. tostring(pct) .. '%</span>'
end

local function cmp_badge_days(prev_val, curr_val, increase_is_good)
    if prev_val == nil or prev_val == 0 or curr_val == nil then return "" end
    local diff = math.floor((curr_val - prev_val) * 10 + 0.5) / 10
    if diff == 0 then return "" end
    local sign = diff > 0 and "+" or ""
    local good = (diff > 0) == increase_is_good
    local bg = good and "#dcfce7" or "#fee2e2"
    local fg = good and "#166534" or "#991b1b"
    return '<span class="cmp-badge" style="background:' .. bg .. ';color:' .. fg .. ';">' .. sign .. tostring(diff) .. '</span>'
end

-- ── fetch per-person performance (only months with KPI data) ─────────────

local person_map = {}
local person_order = {}
local person_seen = {}

for _, m in ipairs(months) do
    local mk = string.sub(m.start, 1, 7)
    if kpi_map[mk] and kpi_map[mk].total > 0 then  -- تنها اگر داده‌ای برای ماه موجود باشد
        local ok, rows = pcall(function()
            return fetch_rows([[
SELECT
    COALESCE(pm.FULLNAME, 'نامشخص') AS person_name,
    COUNT(DISTINCT sr.ID) AS accepted,
    COUNT(DISTINCT CASE WHEN sr.FINAL_STATUS IN (3,6,8,9) THEN sr.ID END) AS completed,
    COALESCE(SUM(rpd.QUANTITY_DEMAND), 0) AS total_parts,
    COUNT(DISTINCT CASE WHEN psc2.NEW_ID = 2 THEN psc2.ID END) AS qc_rejects
FROM pm_service_request sr
LEFT JOIN profile_main pm ON pm.ID = sr.CREATED_BY
LEFT JOIN pm_service_request_content psc2 ON psc2.SERVICE_REQUEST_ID = sr.ID AND psc2.NEW_ID = 2
LEFT JOIN wh_req_product rp ON rp.REF_ID = sr.ID AND rp.DELETED = 0 AND rp.REQUEST_TYPE = 5 AND rp.STATUS = 1
LEFT JOIN wh_req_product_details rpd ON rp.ID = rpd.REQUEST_ID
WHERE REPORT_FN_JDATE(sr.BREAK_DOWN_DATE, '-') >= ?
  AND REPORT_FN_JDATE(sr.BREAK_DOWN_DATE, '-') <= ?
  AND pm.FULLNAME IS NOT NULL
GROUP BY pm.FULLNAME
ORDER BY accepted DESC
]], { m.start, m["end"] })
        end)
        if ok and rows then
            for _, r in ipairs(rows) do
                local name = r[1] or "نامشخص"
                local accepted = tonumber(r[2]) or 0
                local completed = tonumber(r[3]) or 0
                local parts = tonumber(r[4]) or 0
                local rejects = tonumber(r[5]) or 0
                if not person_seen[name] then
                    person_seen[name] = true
                    table.insert(person_order, name)
                    person_map[name] = {}
                end
                person_map[name][mk] = { accepted = accepted, completed = completed, parts = parts, rejects = rejects }
            end
        end
    end
end

-- ── build person performance table ───────────────────────────────────

local person_html = ""
for _, name in ipairs(person_order) do
    local row_accepted = ""
    local row_completed = ""
    local row_parts = ""
    local row_rejects = ""
    for idx, m in ipairs(months) do
        local mk = string.sub(m.start, 1, 7)
        local d = (person_map[name] and person_map[name][mk]) or { accepted = 0, completed = 0, parts = 0, rejects = 0 }
        local prev_accepted = ""
        local prev_completed = ""
        local prev_parts = ""
        local prev_rejects = ""
        if idx > 1 then
            local prev_mk = string.sub(months[idx-1].start, 1, 7)
            local pd = (person_map[name] and person_map[name][prev_mk])
            if pd and pd.accepted > 0 and d.accepted > 0 then
                prev_accepted = cmp_badge(pd.accepted, d.accepted, true)
            end
            if pd and pd.completed > 0 and d.completed > 0 then
                prev_completed = cmp_badge(pd.completed, d.completed, true)
            end
            if pd and pd.parts > 0 and d.parts > 0 then
                prev_parts = cmp_badge(pd.parts, d.parts, true)
            end
            if pd and pd.rejects > 0 and d.rejects > 0 then
                prev_rejects = cmp_badge(pd.rejects, d.rejects, false)
            end
        end
        row_accepted = row_accepted .. '<td class="num-cell"><strong>' .. fmt_num(d.accepted) .. '</strong> ' .. prev_accepted .. '</td>'
        row_completed = row_completed .. '<td class="num-cell"><strong>' .. fmt_num(d.completed) .. '</strong> ' .. prev_completed .. '</td>'
        row_parts = row_parts .. '<td class="num-cell"><strong>' .. fmt_num(d.parts) .. '</strong> ' .. prev_parts .. '</td>'
        row_rejects = row_rejects .. '<td class="num-cell"><strong>' .. fmt_num(d.rejects) .. '</strong> ' .. prev_rejects .. '</td>'
    end
    person_html = person_html .. '<tr><td class="name-cell">' .. escape_html(name) .. '</td>' .. row_accepted .. row_completed .. row_parts .. row_rejects .. '</tr>'
end
if person_html == "" then
    person_html = '<tr><td colspan="50" class="empty-row">داده‌ای یافت نشد</td></tr>'
end

-- month header cells
local month_header_cells = ""
for _, m in ipairs(months) do
    month_header_cells = month_header_cells .. '<th colspan="4">' .. escape_html(m.name) .. '</th>'
end
local sub_header_cells = ""
for _ = 1, #months do
    sub_header_cells = sub_header_cells .. '<th>پذیرش</th><th>تکمیل</th><th>قطعات</th><th>ریجکت</th>'
end

-- ── build widgets HTML ───────────────────────────────────────────────

local widgets_html = ""
for idx, m in ipairs(months) do
    local mk = string.sub(m.start, 1, 7)
    local k = kpi_map[mk] or { total=0, completed=0, cancelled=0, open_count=0, avg_ready=0, avg_complete=0 }
    local cancel_rate = 0
    if k.total > 0 then cancel_rate = math.floor((k.cancelled * 1000 / k.total) + 0.5) / 10 end
    local completion_rate = 0
    if k.total > 0 then completion_rate = math.floor((k.completed * 1000 / k.total) + 0.5) / 10 end
    local open_of_total = 0
    if k.total > 0 then open_of_total = math.floor((k.open_count * 1000 / k.total) + 0.5) / 10 end

    local prev = nil
    local cmp_complete, cmp_ready, cmp_open, cmp_cancelled, cmp_completed, cmp_total = "", "", "", "", "", ""
    if idx > 1 then
        local prev_mk = string.sub(months[idx-1].start, 1, 7)
        prev = kpi_map[prev_mk]
        if prev then
            cmp_complete  = cmp_badge_days(prev.avg_complete, k.avg_complete, false)
            cmp_ready     = cmp_badge_days(prev.avg_ready, k.avg_ready, false)
            cmp_open      = cmp_badge(prev.open_count, k.open_count, false)
            cmp_cancelled = cmp_badge(prev.cancelled, k.cancelled, false)
            cmp_completed = cmp_badge(prev.completed, k.completed, true)
            cmp_total     = cmp_badge(prev.total, k.total, true)
        end
    end

    widgets_html = widgets_html
        .. '<div class="month-section">'
        .. '<div class="month-title">' .. escape_html(m.name) .. ' (' .. m.start .. ' الی ' .. m["end"] .. ')</div>'
        .. '<div class="kpi-grid">'
        .. '<div class="kpi-card"><div class="kpi-label">Avg Days to Complete</div><div class="kpi-value blue">' .. fmt_decimal(k.avg_complete, 1) .. '</div><div class="kpi-sub">to fully completed ' .. cmp_complete .. '</div></div>'
        .. '<div class="kpi-card"><div class="kpi-label">Avg Days to Ready</div><div class="kpi-value blue">' .. fmt_decimal(k.avg_ready, 1) .. '</div><div class="kpi-sub">to ready for delivery ' .. cmp_ready .. '</div></div>'
        .. '<div class="kpi-card"><div class="kpi-label">Open / In Progress</div><div class="kpi-value amber">' .. fmt_num(k.open_count) .. '</div><div class="kpi-sub">' .. fmt_decimal(open_of_total, 1) .. '% of total ' .. fmt_num(k.total) .. ' ' .. cmp_open .. '</div></div>'
        .. '<div class="kpi-card"><div class="kpi-label">Cancelled</div><div class="kpi-value red">' .. fmt_num(k.cancelled) .. '</div><div class="kpi-sub">cancel rate ' .. fmt_decimal(cancel_rate, 1) .. '% ' .. cmp_cancelled .. '</div></div>'
        .. '<div class="kpi-card"><div class="kpi-label">Completed</div><div class="kpi-value green">' .. fmt_num(k.completed) .. '</div><div class="kpi-sub">completion rate ' .. fmt_decimal(completion_rate, 1) .. '% ' .. cmp_completed .. '</div></div>'
        .. '<div class="kpi-card"><div class="kpi-label">Total Receipts</div><div class="kpi-value blue">' .. fmt_num(k.total) .. '</div><div class="kpi-sub">in ' .. escape_html(m.name) .. ' ' .. cmp_total .. '</div></div>'
        .. '</div></div>'
end

-- ── build final HTML via concatenation (no string.format) ────────────

local css = [[
<style>
@font-face {
    font-family: "ServiceReceiptReport";
    src: local("Yekan Bakh"), local("YekanBakh"), local("IRANSans");
    font-weight: 400; font-style: normal; font-display: swap;
}
* { font-family: "ServiceReceiptReport", "Yekan Bakh", "IRANSans", "Tahoma", "Arial", sans-serif !important; box-sizing: border-box; }
body { margin: 0; padding: 12px; font-size: 14px; font-weight: bold; background: linear-gradient(135deg, #f5f7fb 0%, #e8edf5 100%); color: #1e293b; }
#reportRoot:fullscreen { background: #f5f7fb; padding: 12px; overflow: auto; }
.toolbar { display: flex; justify-content: flex-end; gap: 8px; margin-bottom: 10px; }
.btn-toolbar { background: linear-gradient(135deg, #0073e6, #005bb5); color: #fff; border: none; border-radius: 8px; padding: 8px 16px; font-family: inherit; font-size: 14px; font-weight: bold; cursor: pointer; box-shadow: 0 2px 8px rgba(0,115,230,0.3); }
.btn-toolbar:hover { filter: brightness(0.95); transform: translateY(-1px); }
.report-header { background: linear-gradient(135deg, #D2E0FB 0%, #bcd4f7 100%); text-align: center; border: 1px dotted #000; border-radius: 12px; padding: 16px 12px 20px; margin-bottom: 14px; box-shadow: 0 2px 12px rgba(0,0,0,0.06); }
.report-header h2 { margin: 0 0 6px; font-size: 15px; font-weight: bold; color: #1e3a5f; }
.report-header p { margin: 3px 0; font-size: 14px; color: #334155; }
.month-section { margin-bottom: 18px; }
.month-title { font-size: 15px; font-weight: bold; color: #1e3a5f; margin-bottom: 8px; padding: 8px 12px; background: linear-gradient(135deg, #D2E0FB, #e0ecfb); border-radius: 8px; border-right: 4px solid #0073e6; }
.kpi-grid { display: grid; grid-template-columns: repeat(6, 1fr); gap: 8px; }
@media (max-width: 1200px) { .kpi-grid { grid-template-columns: repeat(3, 1fr); } }
@media (max-width: 600px) { .kpi-grid { grid-template-columns: repeat(2, 1fr); } }
.kpi-card { background: #fff; border-radius: 10px; padding: 12px 10px; text-align: center; border: 1px solid #e2e8f0; box-shadow: 0 2px 8px rgba(0,0,0,0.04); transition: transform 0.15s; }
.kpi-card:hover { transform: translateY(-2px); box-shadow: 0 4px 16px rgba(0,0,0,0.08); }
.kpi-value { font-size: 26px; font-weight: bold; margin: 5px 0 3px; }
.kpi-value.blue { background: linear-gradient(135deg, #0073e6, #06b6d4); -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text; }
.kpi-value.green { background: linear-gradient(135deg, #22c55e, #10b981); -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text; }
.kpi-value.red { background: linear-gradient(135deg, #ef4444, #f97316); -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text; }
.kpi-value.amber { background: linear-gradient(135deg, #f59e0b, #f97316); -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text; }
.kpi-label { font-size: 14px; font-weight: bold; color: #64748b; }
.kpi-sub { font-size: 14px; color: #94a3b8; margin-top: 2px; }
.cmp-badge { display: inline-block; padding: 1px 6px; border-radius: 4px; font-size: 14px; font-weight: bold; margin-top: 2px; }
.tab-bar { display: flex; gap: 6px; margin-bottom: 10px; }
.tab-btn { background: #fff; border: 2px solid #0073e6; color: #0073e6; border-radius: 8px; padding: 8px 16px; font-family: inherit; font-size: 14px; font-weight: bold; cursor: pointer; }
.tab-btn.active { background: #0073e6; color: #fff; }
.tab-panel { display: none; }
.tab-panel.active { display: block; }
.person-table-wrap { overflow-x: auto; border: 2px solid #000; border-radius: 8px; background: #fff; }
.person-table { width: 100%; border-collapse: collapse; text-align: center; }
.person-table thead th { position: sticky; top: 0; z-index: 2; background: linear-gradient(135deg, #0073e6, #005bb5); color: #fff; border: 1px dashed #000; padding: 8px 6px; font-size: 15px; font-weight: bold; white-space: nowrap; }
.person-table tbody td { border: 1px dashed #000; padding: 6px 5px; font-size: 14px; vertical-align: middle; }
.person-table tbody tr:nth-child(even) { background-color: #f8fafc; }
.person-table tbody tr:hover { filter: brightness(0.97); }
.person-table .name-cell { text-align: right; font-weight: bold; white-space: nowrap; }
.person-table .num-cell { white-space: nowrap; }
.person-table .empty-row { padding: 24px !important; color: #666; font-size: 14px; }
.modal { display: none; position: fixed; z-index: 1000; left: 0; top: 0; width: 100%; height: 100%; background-color: rgba(0,0,0,0.4); }
.modal.active { display: block; }
.modal-content { background-color: #fefefe; margin: auto; padding: 20px; border: 1px solid #888; border-radius: 8px; width: 90%; max-width: 600px; max-height: 80vh; overflow-y: auto; position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%); }
.modal-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px; }
.modal-header h3 { margin: 0; font-size: 15px; font-weight: bold; }
.modal-close { background: none; border: none; font-size: 28px; cursor: pointer; color: #aaa; }
.modal-close:hover { color: #000; }
.modal-body { font-size: 14px; line-height: 1.6; }
.modal-body h4 { font-size: 15px; font-weight: bold; margin: 12px 0 8px; }
.modal-body ul { margin: 8px 0; padding-right: 20px; }
.modal-body li { margin: 6px 0; font-size: 14px; }
.footer { text-align: center; color: #94a3b8; font-size: 14px; margin-top: 12px; }
</style>
]]

local js = [[
<script>
function switchTab(btn) {
    var tabs = document.getElementsByClassName('tab-btn');
    for (var i = 0; i < tabs.length; i++) tabs[i].classList.remove('active');
    btn.classList.add('active');
    var panels = document.getElementsByClassName('tab-panel');
    for (var j = 0; j < panels.length; j++) panels[j].classList.remove('active');
    document.getElementById(btn.getAttribute('data-tab')).classList.add('active');
}
function toggleFullScreen() {
    var root = document.getElementById('reportRoot');
    var isFull = document.fullscreenElement || document.webkitFullscreenElement || document.msFullscreenElement;
    if (!isFull) {
        if (root.requestFullscreen) root.requestFullscreen();
        else if (root.webkitRequestFullscreen) root.webkitRequestFullscreen();
        else if (root.msRequestFullscreen) root.msRequestFullscreen();
    } else {
        if (document.exitFullscreen) document.exitFullscreen();
        else if (document.webkitExitFullscreen) document.webkitExitFullscreen();
        else if (document.msExitFullscreen) document.msExitFullscreen();
    }
}
function openHelp() {
    document.getElementById('helpModal').classList.add('active');
}
function closeHelp() {
    document.getElementById('helpModal').classList.remove('active');
}
window.onclick = function(event) {
    var modal = document.getElementById('helpModal');
    if (event.target == modal) modal.classList.remove('active');
}
function exportToExcel() {
    var html = document.getElementById('reportRoot').innerHTML;
    var blob = new Blob([html], { type: 'application/vnd.ms-excel' });
    var link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = 'service_receipt_monthly_kpis_' + new Date().getTime() + '.xls';
    link.click();
}
</script>
]]

local html = '<!DOCTYPE html>\n<html dir="rtl" lang="fa">\n<head>\n<meta charset="UTF-8">\n<meta name="viewport" content="width=device-width, initial-scale=1.0">\n<title>داشبورد ماهانه پذیرش خدمات</title>\n'
    .. css
    .. '</head>\n<body>\n<div id="reportRoot">'
    .. '<div class="toolbar"><button type="button" class="btn-toolbar" onclick="toggleFullScreen()">تمام صفحه</button><button type="button" class="btn-toolbar" onclick="exportToExcel()">خروجی Excel</button><button type="button" class="btn-toolbar" onclick="openHelp()">راهنما</button></div>'
    .. '<div class="report-header"><h2>داشبورد ماهانه پذیرش خدمات — سال 1405</h2>'
    .. '<p style="font-size:14px;color:#475569;">سازمان: ' .. escape_html(org_id) .. '</p></div>'
    .. '<div class="tab-bar">'
    .. '<button type="button" class="tab-btn active" data-tab="tab-kpis" onclick="switchTab(this)">شاخص‌های کلیدی</button>'
    .. '<button type="button" class="tab-btn" data-tab="tab-persons" onclick="switchTab(this)">عملکرد افراد</button>'
    .. '</div>'
    .. '<div class="tab-panel active" id="tab-kpis">' .. widgets_html .. '</div>'
    .. '<div class="tab-panel" id="tab-persons"><div class="person-table-wrap"><table class="person-table"><thead><tr><th rowspan="2" style="min-width:120px;">نام</th>' .. month_header_cells .. '</tr><tr>' .. sub_header_cells .. '</tr></thead><tbody>' .. person_html .. '</tbody></table></div></div>'
    .. '<div class="footer">داشبورد ماهانه شاخص‌های عملکرد پذیرش خدمات</div>'
    .. '</div>'
    .. '<div id="helpModal" class="modal">'
    .. '<div class="modal-content">'
    .. '<div class="modal-header"><h3>راهنمای داشبورد</h3><button class="modal-close" onclick="closeHelp()">×</button></div>'
    .. '<div class="modal-body">'
    .. '<h4>درباره این گزارش</h4>'
    .. '<p>این داشبورد شاخص‌های کلیدی عملکرد پذیرش خدمات برای سال 1405 را نمایش می‌دهد.</p>'
    .. '<h4>تب «شاخص‌های کلیدی»</h4>'
    .. '<ul>'
    .. '<li><strong>Avg Days to Complete:</strong> میانگین روزهای لازم برای تکمیل کامل درخواست</li>'
    .. '<li><strong>Avg Days to Ready:</strong> میانگین روزهای لازم برای آماده‌سازی محصول</li>'
    .. '<li><strong>Open / In Progress:</strong> تعداد درخواست‌های باز یا در حال انجام</li>'
    .. '<li><strong>Cancelled:</strong> تعداد درخواست‌های لغو شده و درصد لغو</li>'
    .. '<li><strong>Completed:</strong> تعداد درخواست‌های تکمیل شده و درصد تکمیل</li>'
    .. '<li><strong>Total Receipts:</strong> کل تعداد درخواست‌های پذیرش شده</li>'
    .. '</ul>'
    .. '<h4>تب «عملکرد افراد»</h4>'
    .. '<p>این تب عملکرد هر فرد را بر اساس تعداد درخواست‌های پذیرفته شده و تکمیل شده نمایش می‌دهد.</p>'
    .. '<h4>بخش‌های اضافی</h4>'
    .. '<ul>'
    .. '<li><strong>نشان مقایسه:</strong> نشان‌هایی که تغییر درصدی یا تعدادی را نسبت به ماه قبل نمایش می‌دهند</li>'
    .. '<li><strong>تمام صفحه:</strong> گزارش را به حالت تمام صفحه باز می‌کند</li>'
    .. '<li><strong>خروجی Excel:</strong> گزارش را به فرمت Excel دانلود می‌کند</li>'
    .. '</ul>'
    .. '</div>'
    .. '</div>'
    .. '</div>'
    .. js
    .. '</body>\n</html>'

teamyar.write_result(html)
