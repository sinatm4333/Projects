-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/05/20 16:30

local input = teamyar.get_input() or {}

local start_date = input["startDate"] or input["start_date"]
    or input["from_date"] or input["fromDate"]
local end_date = input["endDate"] or input["end_date"]
    or input["to_date"] or input["toDate"]
local org_id = input["org_id"] or input["orgId"] or "2"
local product_code = input["product_code"] or input["productCode"]

-- ── helpers ──────────────────────────────────────────────────────────

local function normalize_jalali_date(value)
    if value == nil or value == "" then
        return nil
    end
    local s = tostring(value):gsub("/", "-"):match("^%s*(.-)%s*$")
    local y, m, d = s:match("^(%d%d%d%d)-(%d%d)-(%d%d)$")
    if y then
        return string.format("%04d-%02d-%02d", tonumber(y), tonumber(m), tonumber(d))
    end
    y, m, d = s:match("^(%d%d%d%d)(%d%d)(%d%d)$")
    if y then
        return string.format("%04d-%02d-%02d", tonumber(y), tonumber(m), tonumber(d))
    end
    return nil
end

local function is_filetime(value)
    local n = tonumber(value)
    return n ~= nil and n > 100000000000
end

local start_jalali = normalize_jalali_date(start_date)
local end_jalali = normalize_jalali_date(end_date)

local function escape_html(value)
    if value == nil then
        return ""
    end
    return tostring(value)
        :gsub("&", "&amp;")
        :gsub("<", "&lt;")
        :gsub(">", "&gt;")
        :gsub('"', '&quot;')
end

local function fmt_num(value)
    local n = tonumber(value)
    if n == nil then
        return "0"
    end
    local s = tostring(math.floor(n + 0.5))
    local grouped = s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    return grouped
end

local function fmt_decimal(value, decimals)
    local n = tonumber(value)
    if n == nil then
        return "0"
    end
    decimals = decimals or 1
    local fmt = "%." .. decimals .. "f"
    return string.format(fmt, n)
end

local function format_duration_hours(filetime_diff)
    local diff = tonumber(filetime_diff)
    if diff == nil or diff <= 0 then
        return "0"
    end
    local total_hours = diff / 10000000 / 3600
    if total_hours < 24 then
        return string.format("%.1f", total_hours) .. "h"
    end
    local days = math.floor(total_hours / 24)
    local hours = math.floor(total_hours % 24)
    return days .. "d " .. hours .. "h"
end

local function fetch_rows(query, params)
    db.use_db("0000000")
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

local function fail_html(message)
    teamyar.write_result(string.format([[
<!DOCTYPE html>
<html dir="rtl" lang="fa">
<head><meta charset="UTF-8"><title>خطا</title></head>
<body style="font-family:tahoma;padding:2rem;text-align:center;">
<h2 style="color:#b42318;">%s</h2>
</body></html>
]], message))
end

-- ── validate inputs ──────────────────────────────────────────────────

if start_date ~= nil and start_date ~= "" and start_jalali == nil and not is_filetime(start_date) then
    fail_html("تاریخ شروع نامعتبر است. فرمت: 1404-04-01")
    return
end
if end_date ~= nil and end_date ~= "" and end_jalali == nil and not is_filetime(end_date) then
    fail_html("تاریخ پایان نامعتبر است. فرمت: 1404-04-01")
    return
end

-- ── build date filter ────────────────────────────────────────────────

local function append_date_filters(where_parts, params, date_column)
    date_column = date_column or "sr.BREAK_DOWN_DATE"
    local has_start = start_jalali ~= nil or is_filetime(start_date)
    local has_end = end_jalali ~= nil or is_filetime(end_date)
    if not has_start and not has_end then
        table.insert(where_parts,
            date_column .. " >= ((UNIX_TIMESTAMP() - (90 * 86400)) + 11644473600) * 10000000")
        return
    end
    if start_jalali ~= nil then
        table.insert(where_parts, "REPORT_FN_JDATE(" .. date_column .. ", '-') >= ?")
        table.insert(params, start_jalali)
    elseif is_filetime(start_date) then
        table.insert(where_parts, date_column .. " >= ?")
        table.insert(params, tonumber(start_date))
    end
    if end_jalali ~= nil then
        table.insert(where_parts, "REPORT_FN_JDATE(" .. date_column .. ", '-') <= ?")
        table.insert(params, end_jalali)
    elseif is_filetime(end_date) then
        table.insert(where_parts, date_column .. " <= ?")
        table.insert(params, tonumber(end_date))
    end
end

-- ── query 1: summary KPIs ────────────────────────────────────────────

local kpi_where = {}
local kpi_params = {}
append_date_filters(kpi_where, kpi_params, "sr.BREAK_DOWN_DATE")

local kpi_rows = fetch_rows([[
SELECT
    COUNT(DISTINCT sr.ID) AS total_receipts,
    COUNT(DISTINCT CASE WHEN sr.FINAL_STATUS IN (3,6,8,9) THEN sr.ID END) AS completed_receipts,
    COUNT(DISTINCT CASE WHEN sr.FINAL_STATUS = 5 THEN sr.ID END) AS cancelled_receipts,
    COUNT(DISTINCT CASE WHEN sr.FINAL_STATUS IN (0,1,2) THEN sr.ID END) AS open_receipts,
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
    END) AS avg_days_to_complete,
    MIN(CASE WHEN sr.FINAL_STATUS IN (3,6,8,9) THEN sr.BREAK_DOWN_DATE END) AS first_completed,
    MAX(CASE WHEN sr.FINAL_STATUS IN (3,6,8,9) THEN sr.BREAK_DOWN_DATE END) AS last_completed
FROM pm_service_request sr
WHERE ]] .. table.concat(kpi_where, " AND "),
    kpi_params
)

local kpi = {
    total = 0, completed = 0, cancelled = 0, ["open"] = 0,
    avg_days_ready = 0, avg_days_complete = 0,
    first_completed = "—", last_completed = "—"
}
if kpi_rows ~= nil and #kpi_rows > 0 then
    local r = kpi_rows[1]
    kpi.total = tonumber(r[1]) or 0
    kpi.completed = tonumber(r[2]) or 0
    kpi.cancelled = tonumber(r[3]) or 0
    kpi["open"] = tonumber(r[4]) or 0
    kpi.avg_days_ready = tonumber(r[5]) or 0
    kpi.avg_days_complete = tonumber(r[6]) or 0
    if r[7] ~= nil and tonumber(r[7]) and tonumber(r[7]) > 0 then
        kpi.first_completed = format_duration_hours(tonumber(r[7]))
    end
    if r[8] ~= nil and tonumber(r[8]) and tonumber(r[8]) > 0 then
        kpi.last_completed = format_duration_hours(tonumber(r[8]))
    end
end

-- ── query 2: status distribution ─────────────────────────────────────

local status_rows = fetch_rows([[
SELECT
    CASE sr.FINAL_STATUS
        WHEN 0 THEN 'پیش پذیرش'
        WHEN 1 THEN 'بررسی'
        WHEN 2 THEN 'اجرا'
        WHEN 3 THEN 'کامل (تعمیر شده)'
        WHEN 4 THEN 'کامل (رد هزینه)'
        WHEN 5 THEN 'باطل'
        WHEN 6 THEN 'آماده تحویل (تعمیر شده)'
        WHEN 7 THEN 'آماده تحویل (رد هزینه)'
        WHEN 8 THEN 'آماده تحویل (تعویض شده)'
        WHEN 9 THEN 'کامل (تعویض شده)'
        ELSE 'نامشخص'
    END AS status_label,
    sr.FINAL_STATUS AS status_code,
    COUNT(DISTINCT sr.ID) AS cnt
FROM pm_service_request sr
WHERE ]] .. table.concat(kpi_where, " AND ") .. [[
GROUP BY sr.FINAL_STATUS
ORDER BY cnt DESC
]], kpi_params
)

local statuses = {}
if status_rows ~= nil then
    for _, r in ipairs(status_rows) do
        table.insert(statuses, {
            label = r[1] or "نامشخص",
            code = tonumber(r[2]) or -1,
            count = tonumber(r[3]) or 0
        })
    end
end

local max_status_count = 0
for _, s in ipairs(statuses) do
    if s.count > max_status_count then
        max_status_count = s.count
    end
end

-- ── query 3: top 10 products by receipt count ────────────────────────

local product_rows = fetch_rows([[
SELECT
    COALESCE(wp.FULL_CODE, 'نامشخص') AS product_code,
    COALESCE(wp.full_name, 'نامشخص') AS product_name,
    COUNT(DISTINCT sr.ID) AS receipt_count,
    COUNT(DISTINCT CASE WHEN sr.FINAL_STATUS = 5 THEN sr.ID END) AS cancelled_count,
    LEFT(REPORT_FN_JDATE(sr.BREAK_DOWN_DATE, '-'), 7) AS month
FROM pm_service_request sr
LEFT JOIN wh_product wp ON wp.id = sr.PRODUCT_ID
WHERE sr.BREAK_DOWN_DATE > 0
GROUP BY COALESCE(wp.FULL_CODE, 'نامشخص'), COALESCE(wp.full_name, 'نامشخص'), LEFT(REPORT_FN_JDATE(sr.BREAK_DOWN_DATE, '-'), 7)
ORDER BY receipt_count DESC
LIMIT 120
]], {}
)

local products = {}
if product_rows ~= nil then
    for _, r in ipairs(product_rows) do
        table.insert(products, {
            code = r[1] or "—",
            name = r[2] or "—",
            count = tonumber(r[3]) or 0,
            cancelled = tonumber(r[4]) or 0,
            avg_days = tonumber(r[5]) or 0,
            month = r[6] or ""
        })
    end
end

-- ── query 4: monthly trend ───────────────────────────────────────────

local monthly_rows = fetch_rows([[
SELECT
    LEFT(REPORT_FN_JDATE(sr.BREAK_DOWN_DATE, '-'), 7) AS month,
    COUNT(DISTINCT sr.ID) AS total,
    COUNT(DISTINCT CASE WHEN sr.FINAL_STATUS IN (3,6,8,9) THEN sr.ID END) AS completed,
    COUNT(DISTINCT CASE WHEN sr.FINAL_STATUS = 5 THEN sr.ID END) AS cancelled,
    COUNT(DISTINCT CASE WHEN sr.FINAL_STATUS IN (0,1,2) THEN sr.ID END) AS open_count,
    AVG(CASE
        WHEN sr.FINAL_STATUS IN (6,7,8) AND sr.BREAK_DOWN_DATE > 0
        THEN DATEDIFF(
            FROM_UNIXTIME((SELECT MAX(c.CREATION_DATE) FROM pm_service_request_content c WHERE c.SERVICE_REQUEST_ID = sr.ID AND c.NEW_ID IN (6,7,8)) / 10000000 - 11644473600),
            FROM_UNIXTIME(sr.BREAK_DOWN_DATE / 10000000 - 11644473600)
        )
    END) AS avg_ready,
    AVG(CASE
        WHEN sr.FINAL_STATUS IN (3,9) AND sr.BREAK_DOWN_DATE > 0
        THEN DATEDIFF(
            FROM_UNIXTIME((SELECT MAX(c.CREATION_DATE) FROM pm_service_request_content c WHERE c.SERVICE_REQUEST_ID = sr.ID AND c.NEW_ID IN (3,9)) / 10000000 - 11644473600),
            FROM_UNIXTIME(sr.BREAK_DOWN_DATE / 10000000 - 11644473600)
        )
    END) AS avg_complete
FROM pm_service_request sr
WHERE ]] .. table.concat(kpi_where, " AND ") .. [[
  AND sr.BREAK_DOWN_DATE > 0
GROUP BY month
ORDER BY month ASC
]], kpi_params
)

local monthly = {}
if monthly_rows ~= nil then
    for _, r in ipairs(monthly_rows) do
        table.insert(monthly, {
            month = r[1] or "—",
            total = tonumber(r[2]) or 0,
            completed = tonumber(r[3]) or 0,
            cancelled = tonumber(r[4]) or 0,
            open_count = tonumber(r[5]) or 0,
            avg_ready = tonumber(r[6]) or 0,
            avg_complete = tonumber(r[7]) or 0
        })
    end
end

-- monthly tabs (server-side rendered)
local month_names = {
    [1]="فروردین",[2]="اردیبهشت",[3]="خرداد",[4]="تیر",
    [5]="مرداد",[6]="شهریور",[7]="مهر",[8]="آبان",
    [9]="آذر",[10]="دی",[11]="بهمن",[12]="اسفند"
}

local function cmp_lua(prev_val, curr_val)
    if prev_val == nil or prev_val == 0 or curr_val == nil then return "" end
    local diff = curr_val - prev_val
    local pct = math.floor((diff / math.abs(prev_val) * 1000) + 0.5) / 10
    if diff > 0 then
        return string.format('<span style="background:#dcfce7;color:#166534;padding:2px 6px;border-radius:4px;font-size:12px;font-weight:bold;">+%s%%</span>', tostring(pct))
    elseif diff < 0 then
        return string.format('<span style="background:#fee2e2;color:#991b1b;padding:2px 6px;border-radius:4px;font-size:12px;font-weight:bold;">%s%%</span>', tostring(pct))
    else
        return '<span style="color:#94a3b8;">0%%</span>'
    end
end

local function cmp_days_lua(prev_val, curr_val)
    if prev_val == nil or prev_val == 0 or curr_val == nil then return "" end
    local diff = math.floor((curr_val - prev_val) * 10 + 0.5) / 10
    if diff > 0 then
        return string.format('<span style="background:#fee2e2;color:#991b1b;padding:2px 6px;border-radius:4px;font-size:12px;font-weight:bold;">+%sd</span>', tostring(diff))
    elseif diff < 0 then
        return string.format('<span style="background:#dcfce7;color:#166534;padding:2px 6px;border-radius:4px;font-size:12px;font-weight:bold;">%sd</span>', tostring(diff))
    else
        return '<span style="color:#94a3b8;">0d</span>'
    end
end
local month_tab_btns = ""
local month_tab_panels = ""
for i, m in ipairs(monthly) do
    local mnum = tonumber(string.sub(m.month, 6, 7)) or 0
    local mname = month_names[mnum] or m.month
    local tab_id = "tab-m-" .. mnum
    local active = (i == 1) and " active" or ""
    month_tab_btns = month_tab_btns .. string.format(
        '<button type="button" class="tab-btn%s" data-tab="%s" onclick="switchTab(this)">%s</button>',
        active, tab_id, mname)
    local prev = (i > 1) and monthly[i - 1] or nil
    local comp_total = cmp_lua(prev and prev.total or 0, m.total)
    local comp_completed = cmp_lua(prev and prev.completed or 0, m.completed)
    local comp_cancelled = cmp_lua(prev and prev.cancelled or 0, m.cancelled)
    local comp_open = cmp_lua(prev and prev.open_count or 0, m.open_count)
    local comp_ready = cmp_days_lua(prev and prev.avg_ready or 0, m.avg_ready)
    local comp_complete = cmp_days_lua(prev and prev.avg_complete or 0, m.avg_complete)
    local cr = m.total > 0 and string.format("%.1f", m.completed * 1000 / m.total / 10) or "0.0"
    local cnr = m.total > 0 and string.format("%.1f", m.cancelled * 1000 / m.total / 10) or "0.0"
    local opr = m.total > 0 and string.format("%.1f", m.open_count * 1000 / m.total / 10) or "0.0"
    local avg_r = m.avg_ready > 0 and string.format("%.1f", m.avg_ready) or "—"
    local avg_c = m.avg_complete > 0 and string.format("%.1f", m.avg_complete) or "—"
    -- filter products for this month
    local month_products = {}
    for _, p in ipairs(products) do
        if p.month == m.month then
            table.insert(month_products, p)
        end
    end
    table.sort(month_products, function(a, b) return a.count > b.count end)
    local mp_rows = ""
    for j = 1, math.min(12, #month_products) do
        local p = month_products[j]
        local cpct = p.count > 0 and string.format("%.1f", p.cancelled * 1000 / p.count / 10) or "0.0"
        mp_rows = mp_rows .. string.format(
            '<tr><td>%d</td><td class="mono">%s</td><td class="name-cell">%s</td><td><strong>%s</strong></td><td>%s</td><td>%s%%</td></tr>',
            j, escape_html(p.code), escape_html(p.name), fmt_num(p.count), fmt_num(p.cancelled), cpct)
    end
    if mp_rows == "" then mp_rows = '<tr><td colspan="6" class="empty-row">داده‌ای یافت نشد</td></tr>' end
    -- filter technicians for this month
    local month_techs = {}
    for _, t in ipairs(technicians) do
        if t.month == m.month then
            table.insert(month_techs, t)
        end
    end
    table.sort(month_techs, function(a, b) return a.count > b.count end)
    local mt_rows = ""
    for j = 1, math.min(12, #month_techs) do
        local t = month_techs[j]
        mt_rows = mt_rows .. string.format(
            '<tr><td>%d</td><td class="name-cell">%s</td><td><strong>%s</strong></td><td>%s</td></tr>',
            j, escape_html(t.name), fmt_num(t.count), format_duration_hours(t.avg_days * 86400 * 10000000))
    end
    if mt_rows == "" then mt_rows = '<tr><td colspan="4" class="empty-row">داده‌ای یافت نشد</td></tr>' end
    month_tab_panels = month_tab_panels .. string.format(
        [[<div class="tab-panel%s" id="%s">
<div class="kpi-grid" style="margin-bottom:10px;">
<div class="kpi-card"><div class="kpi-label">Total</div><div class="kpi-value">%s</div><div class="kpi-sub">%s</div></div>
<div class="kpi-card"><div class="kpi-label">Completed</div><div class="kpi-value green">%s</div><div class="kpi-sub">%s%% %s</div></div>
<div class="kpi-card"><div class="kpi-label">Cancelled</div><div class="kpi-value red">%s</div><div class="kpi-sub">%s%% %s</div></div>
<div class="kpi-card"><div class="kpi-label">Open</div><div class="kpi-value amber">%s</div><div class="kpi-sub">%s%% %s</div></div>
<div class="kpi-card"><div class="kpi-label">Avg Ready</div><div class="kpi-value">%s</div><div class="kpi-sub">days %s</div></div>
<div class="kpi-card"><div class="kpi-label">Avg Complete</div><div class="kpi-value">%s</div><div class="kpi-sub">days %s</div></div>
</div>
<div style="display:flex;gap:10px;flex-wrap:wrap;">
<div style="flex:1;min-width:300px;">
<div style="font-size:12px;font-weight:bold;color:#1e3a5f;margin-bottom:6px;">Top Products</div>
<div style="background:#fff;border:2px solid #000;border-radius:8px;overflow:auto;max-height:300px;">
<table style="width:100%%;border-collapse:collapse;"><thead><tr><th>#</th><th>Code</th><th>Name</th><th>Receipts</th><th>Cancelled</th><th>Cancel%</th></tr></thead><tbody>%s</tbody></table>
</div></div>
<div style="flex:1;min-width:300px;">
<div style="font-size:12px;font-weight:bold;color:#1e3a5f;margin-bottom:6px;">Technicians</div>
<div style="background:#fff;border:2px solid #000;border-radius:8px;overflow:auto;max-height:300px;">
<table style="width:100%%;border-collapse:collapse;"><thead><tr><th>#</th><th>Name</th><th>Receipts</th><th>Avg Time</th></tr></thead><tbody>%s</tbody></table>
</div></div>
</div>
</div>]],
        active, tab_id,
        fmt_num(m.total), comp_total,
        fmt_num(m.completed), cr, comp_completed,
        fmt_num(m.cancelled), cnr, comp_cancelled,
        fmt_num(m.open_count), opr, comp_open,
        avg_r, comp_ready,
        avg_c, comp_complete
    )
end

-- ── query 5: top technicians ─────────────────────────────────────────

local tech_rows = fetch_rows([[
SELECT
    COALESCE(pm.FULLNAME, 'نامشخص') AS tech_name,
    COUNT(DISTINCT sr.ID) AS receipt_count,
    AVG(CASE
        WHEN sr.FINAL_STATUS IN (3,6,8,9)
        THEN DATEDIFF(
            FROM_UNIXTIME((
                SELECT MAX(c.CREATION_DATE) FROM pm_service_request_content c
                WHERE c.SERVICE_REQUEST_ID = sr.ID
            ) / 10000000 - 11644473600),
            FROM_UNIXTIME(sr.BREAK_DOWN_DATE / 10000000 - 11644473600)
        )
    END) AS avg_days,
    LEFT(REPORT_FN_JDATE(sr.BREAK_DOWN_DATE, '-'), 7) AS month
FROM pm_service_request sr
LEFT JOIN pm_service_request_content psc ON psc.SERVICE_REQUEST_ID = sr.ID
LEFT JOIN profile_main pm ON pm.ID = psc.AUTHOR_ID
WHERE ]] .. table.concat(kpi_where, " AND ") .. [[
  AND psc.TYPE = 11
GROUP BY pm.FULLNAME, LEFT(REPORT_FN_JDATE(sr.BREAK_DOWN_DATE, '-'), 7)
ORDER BY receipt_count DESC
]], kpi_params
)

local technicians = {}
if tech_rows ~= nil then
    for _, r in ipairs(tech_rows) do
        table.insert(technicians, {
            name = r[1] or "—",
            count = tonumber(r[2]) or 0,
            avg_days = tonumber(r[3]) or 0,
            month = r[4] or ""
        })
    end
end

-- ── build HTML ───────────────────────────────────────────────────────

local completion_rate = 0
if kpi.total > 0 then
    completion_rate = math.floor((kpi.completed * 1000 / kpi.total) + 0.5) / 10
end

local cancel_rate = 0
if kpi.total > 0 then
    cancel_rate = math.floor((kpi.cancelled * 1000 / kpi.total) + 0.5) / 10
end

local open_rate = 0
if kpi.total > 0 then
    open_rate = math.floor((kpi["open"] * 1000 / kpi.total) + 0.5) / 10
end

local filter_from = start_jalali or start_date or "90 روز اخیر"
local filter_to = end_jalali or end_date or "امروز"

local status_colors = {
    [0] = "#94a3b8", [1] = "#3b82f6", [2] = "#f59e0b",
    [3] = "#22c55e", [4] = "#ef4444", [5] = "#6b7280",
    [6] = "#10b981", [7] = "#f97316", [8] = "#8b5cf6", [9] = "#06b6d4"
}

local function get_status_color(code)
    return status_colors[tonumber(code)] or "#94a3b8"
end

local function bar_width(count, max_count)
    if max_count <= 0 then return 0 end
    return math.floor((count * 100 / max_count) + 0.5)
end

-- status bars
local status_bars_html = {}
for _, s in ipairs(statuses) do
    local color = get_status_color(s.code)
    local pct = 0
    if kpi.total > 0 then
        pct = math.floor((s.count * 1000 / kpi.total) + 0.5) / 10
    end
    local w = bar_width(s.count, max_status_count)
    table.insert(status_bars_html, string.format(
        [[<div class="status-bar-row">
            <span class="status-label">%s</span>
            <div class="status-bar-track">
                <div class="status-bar-fill" style="width:%d%%;background:%s;"></div>
            </div>
            <span class="status-count">%s</span>
            <span class="status-pct">%s%%</span>
        </div>]],
        escape_html(s.label), w, color, fmt_num(s.count), fmt_decimal(pct, 1)
    ))
end

-- product rows
local product_html_rows = {}
for i, p in ipairs(products) do
    local cancel_pct = 0
    if p.count > 0 then
        cancel_pct = math.floor((p.cancelled * 1000 / p.count) + 0.5) / 10
    end
    local rate_class = "rate-good"
    if cancel_pct > 10 then rate_class = "rate-critical"
    elseif cancel_pct > 5 then rate_class = "rate-warning"
    end
    table.insert(product_html_rows, string.format(
        [[<tr>
            <td>%d</td>
            <td class="mono">%s</td>
            <td class="name-cell">%s</td>
            <td><strong>%s</strong></td>
            <td>%s</td>
            <td class="%s">%s%%</td>
        </tr>]],
        i,
        escape_html(p.code),
        escape_html(p.name),
        fmt_num(p.count),
        fmt_num(p.cancelled),
        rate_class, fmt_decimal(cancel_pct, 1)
    ))
end
if #product_html_rows == 0 then
    product_html_rows = { [[<tr><td colspan="6" class="empty-row">داده‌ای یافت نشد</td></tr>]] }
end

-- monthly chart rows
local monthly_json = json.encode(monthly)

-- technician rows
local tech_html_rows = {}
for i, t in ipairs(technicians) do
    local search_text = escape_html(t.name):lower()
    table.insert(tech_html_rows, string.format(
        [[<tr class="tech-row" data-search="%s">
            <td>%d</td>
            <td class="name-cell">%s</td>
            <td><strong>%s</strong></td>
            <td>%s</td>
        </tr>]],
        search_text,
        i,
        escape_html(t.name),
        fmt_num(t.count),
        format_duration_hours(t.avg_days * 86400 * 10000000)
    ))
end
if #tech_html_rows == 0 then
    tech_html_rows = { [[<tr><td colspan="4" class="empty-row">داده‌ای یافت نشد</td></tr>]] }
end

local html = string.format([[<!DOCTYPE html>
<html dir="rtl" lang="fa">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>داشبورد خلاصه پذیرش خدمات</title>
<style>
* { box-sizing: border-box; }
body {
    margin: 0; padding: 12px;
    font-family: IRANSansWeb_Light, Tahoma, sans-serif;
    font-size: 12px; font-weight: bold;
    background: linear-gradient(135deg, #f5f7fb 0%%, #e8edf5 100%%);
    color: #1e293b;
}
#reportRoot:fullscreen { background: #f5f7fb; padding: 12px; overflow: auto; }
#reportRoot:fullscreen .table-wrap { max-height: none; overflow: visible; }

.toolbar { display: flex; justify-content: flex-start; gap: 8px; margin-bottom: 10px; }
.btn-fullscreen {
    background: linear-gradient(135deg, #0073e6, #005bb5);
    color: #fff; border: none; border-radius: 8px;
    padding: 8px 16px; font-family: inherit; font-size: 12px; font-weight: bold;
    cursor: pointer; box-shadow: 0 2px 8px rgba(0,115,230,0.3);
}
.btn-fullscreen:hover { filter: brightness(0.95); transform: translateY(-1px); }

.report-header {
    background: linear-gradient(135deg, #D2E0FB 0%%, #bcd4f7 100%%);
    text-align: center; border: 1px dotted #000; border-radius: 12px;
    padding: 16px 12px 20px; margin-bottom: 14px;
    box-shadow: 0 2px 12px rgba(0,0,0,0.06);
}
.report-header h2 { margin: 0 0 6px; font-size: 16px; color: #1e3a5f; }
.report-header p { margin: 3px 0; font-size: 12px; color: #334155; }
.meta-line { font-size: 11px; color: #475569; margin-top: 8px; }

.kpi-grid {
    display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
    gap: 10px; margin-bottom: 14px;
}
.kpi-card {
    background: #fff; border-radius: 10px; padding: 14px 12px;
    text-align: center; border: 1px solid #e2e8f0;
    box-shadow: 0 2px 8px rgba(0,0,0,0.04);
    transition: transform 0.15s;
}
.kpi-card:hover { transform: translateY(-2px); box-shadow: 0 4px 16px rgba(0,0,0,0.08); }
.kpi-value {
    font-size: 28px; font-weight: bold; margin: 6px 0 4px;
    background: linear-gradient(135deg, #0073e6, #06b6d4);
    -webkit-background-clip: text; -webkit-text-fill-color: transparent;
    background-clip: text;
}
.kpi-value.green { background: linear-gradient(135deg, #22c55e, #10b981); -webkit-background-clip: text; background-clip: text; }
.kpi-value.red { background: linear-gradient(135deg, #ef4444, #f97316); -webkit-background-clip: text; background-clip: text; }
.kpi-value.amber { background: linear-gradient(135deg, #f59e0b, #f97316); -webkit-background-clip: text; background-clip: text; }
.kpi-label { font-size: 11px; color: #64748b; }
.kpi-sub { font-size: 10px; color: #94a3b8; margin-top: 2px; }

.section { margin-bottom: 14px; }
.section-title {
    font-size: 13px; font-weight: bold; color: #1e3a5f;
    margin-bottom: 8px; padding-bottom: 4px;
    border-bottom: 2px solid #0073e6;
}

.status-bar-row { display: flex; align-items: center; gap: 8px; margin-bottom: 5px; }
.status-label { width: 160px; text-align: right; font-size: 11px; flex-shrink: 0; }
.status-bar-track {
    flex: 1; height: 22px; background: #f1f5f9; border-radius: 6px; overflow: hidden;
}
.status-bar-fill { height: 100%%; border-radius: 6px; transition: width 0.5s ease; }
.status-count { width: 50px; text-align: center; font-size: 12px; font-weight: bold; }
.status-pct { width: 45px; text-align: left; font-size: 11px; color: #64748b; }

.tab-bar { display: flex; flex-wrap: wrap; gap: 6px; margin-bottom: 10px; }
.tab-btn {
    background: #fff; border: 2px solid #0073e6; color: #0073e6;
    border-radius: 8px; padding: 8px 14px;
    font-family: inherit; font-size: 12px; font-weight: bold; cursor: pointer;
}
.tab-btn.active { background: #0073e6; color: #fff; }
.tab-panel { display: none; }
.tab-panel.active { display: block; }

.table-wrap {
    overflow: auto; max-height: 50vh;
    border: 2px solid #000; border-radius: 8px; background: #fff;
}
table { width: 100%%; border-collapse: collapse; text-align: center; }
thead th {
    position: sticky; top: 0; z-index: 2;
    background: linear-gradient(135deg, #0073e6, #005bb5);
    color: #fff; border: 1px dashed #000;
    padding: 10px 8px; font-size: 11px; white-space: nowrap;
}
tbody td { border: 1px dashed #000; padding: 8px; font-size: 11px; vertical-align: middle; }
tbody tr:nth-child(even) { background-color: #f8fafc; }
tbody tr:hover { filter: brightness(0.97); }

.mono { font-family: Consolas, monospace; }
.name-cell { text-align: right; font-weight: bold; }
.empty-row { padding: 24px !important; color: #666; }

.rate-good { background: #c6efce; color: #006100; font-weight: bold; border-radius: 4px; }
.rate-warning { background: #ffeb9c; color: #9c6500; font-weight: bold; border-radius: 4px; }
.rate-critical { background: #ffc7ce; color: #9c0006; font-weight: bold; border-radius: 4px; }

.chart-container {
    background: #fff; border: 2px solid #000; border-radius: 8px;
    padding: 16px; overflow-x: auto;
}
.chart-bar-group { display: flex; align-items: flex-end; gap: 4px; height: 180px; min-width: 100%%; }
.chart-col {
    display: flex; flex-direction: column; align-items: center; flex: 1; min-width: 40px;
    justify-content: flex-end;
}
.chart-bar {
    width: 100%%; max-width: 32px; border-radius: 4px 4px 0 0;
    transition: height 0.4s ease; position: relative;
}
.chart-bar:hover { filter: brightness(0.9); }
.chart-bar-tooltip {
    display: none; position: absolute; top: -28px; left: 50%%; transform: translateX(-50%%);
    background: #1e293b; color: #fff; padding: 3px 8px; border-radius: 4px;
    font-size: 10px; white-space: nowrap; z-index: 10;
}
.chart-bar:hover .chart-bar-tooltip { display: block; }
.chart-label { font-size: 9px; color: #64748b; margin-top: 4px; writing-mode: vertical-rl; text-orientation: mixed; }
.chart-legend { display: flex; gap: 12px; justify-content: center; margin-top: 8px; font-size: 10px; }
.chart-legend-item { display: flex; align-items: center; gap: 4px; }
.chart-legend-dot { width: 10px; height: 10px; border-radius: 3px; }

.footer { text-align: center; color: #94a3b8; font-size: 11px; margin-top: 12px; }
</style>
</head>
<body>
<div id="reportRoot">
    <div class="toolbar">
        <button type="button" class="btn-fullscreen" id="btnFullscreen" onclick="toggleFullScreen()">Full Screen</button>
    </div>

    <div class="report-header">
        <h2>Service Receipt Summary Dashboard</h2>
        <p>KPIs, status distribution, top products, monthly trends, and technician performance</p>
        <div class="meta-line">From: %s | To: %s | Org: %s | Generated: %s</div>
    </div>

    <!-- KPI Cards -->
    <div class="kpi-grid">
        <div class="kpi-card">
            <div class="kpi-label">Total Receipts</div>
            <div class="kpi-value">%s</div>
            <div class="kpi-sub">in selected period</div>
        </div>
        <div class="kpi-card">
            <div class="kpi-label">Completed</div>
            <div class="kpi-value green">%s</div>
            <div class="kpi-sub">%s%% completion rate</div>
        </div>
        <div class="kpi-card">
            <div class="kpi-label">Cancelled</div>
            <div class="kpi-value red">%s</div>
            <div class="kpi-sub">%s%% cancel rate</div>
        </div>
        <div class="kpi-card">
            <div class="kpi-label">Open / In Progress</div>
            <div class="kpi-value amber">%s</div>
            <div class="kpi-sub">%s%% of total</div>
        </div>
        <div class="kpi-card">
            <div class="kpi-label">Avg Days to Ready</div>
            <div class="kpi-value">%s</div>
            <div class="kpi-sub">to ready for delivery</div>
        </div>
        <div class="kpi-card">
            <div class="kpi-label">Avg Days to Complete</div>
            <div class="kpi-value">%s</div>
            <div class="kpi-sub">to fully completed</div>
        </div>
    </div>

    <!-- Status Distribution -->
    <div class="section">
        <div class="section-title">Status Distribution</div>
        <div style="background:#fff;border:2px solid #000;border-radius:8px;padding:14px;">
            %s
        </div>
    </div>

    <!-- Tabs for detailed data -->
    <div class="tab-bar" id="mainTabBar">
        <button type="button" class="tab-btn active" data-tab="tab-products" onclick="switchTab(this)">Top Products</button>
        <button type="button" class="tab-btn" data-tab="tab-tech" onclick="switchTab(this)">Technicians</button>
    </div>
    <div id="monthTabBar" class="tab-bar">%s</div>

    <div class="tab-panel active" id="tab-products">
        <div class="table-wrap">
            <table>
                <thead><tr>
                    <th>#</th><th>Product Code</th><th>Product Name</th>
                    <th>Receipts</th><th>Cancelled</th><th>Cancel Rate</th>
                </tr></thead>
                <tbody>%s</tbody>
            </table>
        </div>
    </div>

    <div id="monthPanels">%s</div>

    <div class="tab-panel" id="tab-tech">
        <div style="padding:10px 12px;background:#fff;border:2px solid #000;border-bottom:0;border-radius:8px 8px 0 0;">
            <input type="text" id="techSearch" placeholder="Search technician name..."
                   oninput="filterTechs()"
                   style="width:100%%;padding:8px 12px;border:2px solid #9eb7d8;border-radius:8px;font-family:inherit;font-size:12px;font-weight:bold;outline:none;" />
        </div>
        <div class="table-wrap" style="border-top:none;border-radius:0 0 8px 8px;">
            <table>
                <thead><tr>
                    <th>#</th><th>Technician</th><th>Receipts</th><th>Avg Time</th>
                </tr></thead>
                <tbody>%s</tbody>
            </table>
        </div>
    </div>

    <div class="footer">Teamyar Service Receipt Summary Dashboard</div>
</div>

<script>
function switchTab(btn) {
    var tabs = document.getElementsByClassName('tab-btn');
    for (var i = 0; i < tabs.length; i++) tabs[i].classList.remove('active');
    btn.classList.add('active');
    var panels = document.getElementsByClassName('tab-panel');
    for (var j = 0; j < panels.length; j++) panels[j].classList.remove('active');
    document.getElementById(btn.getAttribute('data-tab')).classList.add('active');
}

function filterTechs() {
    var q = (document.getElementById('techSearch').value || '').toLowerCase().trim();
    var rows = document.querySelectorAll('#tab-tech .tech-row');
    for (var i = 0; i < rows.length; i++) {
        var s = rows[i].getAttribute('data-search') || '';
        rows[i].style.display = (!q || s.indexOf(q) !== -1) ? '' : 'none';
    }
}

function toggleFullScreen() {
    var root = document.getElementById('reportRoot');
    var btn = document.getElementById('btnFullscreen');
    var isFull = document.fullscreenElement || document.webkitFullscreenElement || document.msFullscreenElement;
    if (!isFull) {
        if (root.requestFullscreen) root.requestFullscreen();
        else if (root.webkitRequestFullscreen) root.webkitRequestFullscreen();
        else if (root.msRequestFullscreen) root.msRequestFullscreen();
        btn.innerText = 'Exit Fullscreen';
    } else {
        if (document.exitFullscreen) document.exitFullscreen();
        else if (document.webkitExitFullscreen) document.webkitExitFullscreen();
        else if (document.msExitFullscreen) document.msExitFullscreen();
        btn.innerText = 'Full Screen';
    }
}

document.addEventListener('DOMContentLoaded', function() {
});
</script>
</body>
</html>]],
    escape_html(filter_from),
    escape_html(filter_to),
    escape_html(org_id),
    "—",
    fmt_num(kpi.total),
    fmt_num(kpi.completed), fmt_decimal(completion_rate, 1),
    fmt_num(kpi.cancelled), fmt_decimal(cancel_rate, 1),
    fmt_num(kpi["open"]), fmt_decimal(open_rate, 1),
    fmt_decimal(kpi.avg_days_ready, 1),
    fmt_decimal(kpi.avg_days_complete, 1),
    table.concat(status_bars_html, "\n"),
    table.concat(product_html_rows, "\n"),
    table.concat(tech_html_rows, "\n"),
    month_tab_btns,
    month_tab_panels
)

teamyar.write_result(html)
