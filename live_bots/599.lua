-- تحلیل و ایجاد توسط مهدی جهانی 09125632329
-- Last Edit = 1405/05/22 00:00

-- Bot: داشبورد عملکرد ماژول باتی (Bot Module Performance Dashboard)
-- Developer: Sina Taghavi Moghadam
--
-- استثنای عمدی از راهنمای سبک HTML (تأییدشده توسط کاربر، 1405/05/20-22):
--   ظاهر این بات آگاهانه و یک‌به‌یک از روی بات 594 «مرکز فرماندهی باتی»
--   (dashboard تیرهٔ glassmorphism، KPI cardهای دارای mini-chart، نمودار SVG
--   دستی با tooltip، drawer جزئیات، chip filter، جستجوی زنده، سه نمای
--   کارت/جدول/درخت) کپی شده. به همین دلیل، فقط همین بات از قوانین الزامی
--   «HTML report styling» در CLAUDE.md مستثنی است:
--     - پالت رنگ محدود به #16509D/سفید/خاکستری/مشکی  → اینجا رعایت نشده
--     - حداقل فونت 14px                                → اینجا رعایت نشده
--     - فونت Peyda embedd شده                          → اینجا رعایت نشده (فونت سیستمی)
--   بقیهٔ بات‌های HTML این پروژه همچنان باید کامل از آن راهنما پیروی کنند؛
--   این استثنا عمومی نیست و نباید الگوی بات‌های بعدی قرار گیرد.
--
-- تاریخچهٔ این بات (برای فهم اینکه چرا این بات به‌جای ویرایش بات 565 ساخته شد):
--   1405/05/20: یک تلاش اول UI بات 594 مستقیماً روی بات 565 «آنالیزور بات»
--   deploy شد و ویژگی تحلیل «نوع اقدام» (todo_task/todo_task_steps — مال
--   ماژول اقدام، نه ماژول باتی) در آن نگه داشته شد. کاربر این را رد کرد:
--   «بات 565 مربوط به آنلیز بات‌هاست، من داده ماژول اقدام رو ندادم». بات 565
--   به نسخهٔ اصلی‌اش برگردانده شد (بدون تغییر) و این بات جدید — که کاملاً
--   منحصر به دادهٔ ماژول باتی (bot_command/bot_command_run/bot_history) است،
--   بدون هیچ ارجاعی به todo_task — به‌جایش ساخته شد. این بات دادهٔ بات 565
--   (آمار اجرا/میانگین زمان/هرگز-اجرا-نشده) و بات 594 (دسته/بخش، روند روزانه
--   و ساعتی، جریان رویدادها، drawer جزئیات) را با هم تلفیق می‌کند.
--
-- الگوی لینک‌ها (طبق درخواست صریح کاربر، 1405/05/22):
--   فهرست یک رده  : /?page=/bot/index&cat_id={cat_id}
--   صفحهٔ خود بات  : /?page=/bot/command/view&id={id}&cat_id={cat_id}&tab=0
--   اجرای بات      : /bot/run/{run_path}   (مثلاً 443/AnalysBot)
--
-- نکتهٔ فنی (تاریخ/ساعت): REPORT_FN_JDATE زیر برخی SID/Connection با خطای
-- عمومی «sql error» fail می‌شود (کشف‌شده حین ساخت بات 565 v2 و مستند در
-- سربرگ بات 592). برای اجتناب کامل از این ریسک، تبدیل FILETIME->شمسی همیشه
-- کاملاً سمت Lua انجام می‌شود (civil_from_civil_days/gregorian_to_jalali —
-- عیناً از action_management_dashboard_report_bot.lua کپی شده، طبق قانون
-- «Reuse ... do not rewrite» در CLAUDE.md).
--
-- نکتهٔ فنی (پرفورمنس): bot_history میلیون‌ها ردیف دارد و ایندکس مفیدی روی
-- DATE_CREATE/command_id ندارد. هر کوئری جداگانهٔ WHERE DATE_CREATE>=... روی
-- آن یک scan کامل جدول است، پس تعداد کوئری‌های جدا مستقیماً روی زمان کل اثر
-- می‌گذارد (تجربه: ۸ کوئری جدا ~۳۲-۵۵ ثانیه). راه‌حل: آمار بازه/روزانه/
-- ساعتی/نوع‌اجرا/رویدادهای اخیر/آخرین‌اجرا همه از **یک** fetch خام روی
-- bot_history در یک پاس Lua محاسبه می‌شوند (زمان نهایی اندازه‌گیری‌شده روی
-- این دیتابیس: ~۳.۳ ثانیه).

teamyar.set_http_header("Content-Type", "text/html; charset=utf-8", true)
teamyar.set_http_status(200, "OK")

local input = teamyar.get_input() or {}

local days = tonumber(input["days"]) or 30
if days < 1 then
    days = 1
elseif days > 365 then
    days = 365
end

local include_disabled = input["include_disabled"] == true
    or input["include_disabled"] == 1
    or input["include_disabled"] == "1"
    or input["includeDisabled"] == true
    or input["includeDisabled"] == 1
    or input["includeDisabled"] == "1"

local SPARK_WINDOW = 30  -- محور نمودار روزانه، مستقل از فیلتر days
local HOUR_WINDOW = 7
local KIND_WINDOW = 30

-- ============================================================
-- انتخاب دستی بات از querystring (پشتیبانی دیپ‌لینک)
-- ============================================================

local function append_unique_bot_id(ids, seen, value)
    local id = tonumber(value)
    if id == nil or id <= 0 or seen[id] then
        return
    end
    seen[id] = true
    table.insert(ids, id)
end

local function collect_bot_ids(raw, ids, seen)
    if raw == nil then
        return
    end

    local value_type = type(raw)
    if value_type == "number" then
        append_unique_bot_id(ids, seen, raw)
        return
    end

    if value_type == "string" then
        local trimmed = raw:match("^%s*(.-)%s*$")
        if trimmed == "" then
            return
        end
        if trimmed:sub(1, 1) == "[" then
            local ok, decoded = pcall(json.decode, trimmed)
            if ok and decoded ~= nil then
                collect_bot_ids(decoded, ids, seen)
                return
            end
        end
        for part in trimmed:gmatch("[^,;]+") do
            append_unique_bot_id(ids, seen, part:match("^%s*(.-)%s*$"))
        end
        return
    end

    if value_type == "table" then
        for key, item in pairs(raw) do
            if type(item) == "table" then
                collect_bot_ids(
                    item.id or item.ID or item.bot_id or item.botId
                        or item.command_id or item.commandId,
                    ids,
                    seen
                )
            elseif type(key) == "number" then
                collect_bot_ids(item, ids, seen)
            else
                collect_bot_ids(item, ids, seen)
            end
        end
    end
end

local function parse_bot_ids(source)
    local ids = {}
    local seen = {}
    collect_bot_ids(source["bot_ids"] or source["botIds"], ids, seen)
    collect_bot_ids(source["command_ids"] or source["commandIds"], ids, seen)
    collect_bot_ids(source["bot_id"] or source["botId"], ids, seen)
    collect_bot_ids(source["command_id"] or source["commandId"], ids, seen)
    table.sort(ids)
    return ids
end

local selected_bot_ids = parse_bot_ids(input)

-- ============================================================
-- helpers مشترک
-- ============================================================

local function escape_html(value)
    if value == nil then
        return ""
    end
return tostring(value)
    :gsub("&", "&amp;")
    :gsub("<", "&lt;")
    :gsub(">", "&gt;")
    :gsub('"', "&quot;")
    :gsub("'", "&#39;")
end

local function fmt_num(value)
    return tostring(tonumber(value) or 0)
end

local JMONTH = { "فروردین", "اردیبهشت", "خرداد", "تیر", "مرداد", "شهریور",
                 "مهر", "آبان", "آذر", "دی", "بهمن", "اسفند" }

-- الگوریتم استاندارد Howard Hinnant (proleptic Gregorian) — روز از epoch 1970-01-01 -> سال/ماه/روز
-- میلادی. عیناً از action_management_dashboard_report_bot.lua (بات 592) کپی شده — نگاه کنید به
-- یادداشت فنی بالای فایل. صحت‌سنجی‌شده روی 1405/05/20 <-> 2026-08-11.
local function civil_from_civil_days(z)
    z = z + 719468
    local era
    if z >= 0 then era = math.floor(z / 146097) else era = math.floor((z - 146096) / 146097) end
    local doe = z - era * 146097
    local yoe = math.floor((doe - math.floor(doe / 1460) + math.floor(doe / 36524) - math.floor(doe / 146096)) / 365)
    local y = yoe + era * 400
    local doy = doe - (365 * yoe + math.floor(yoe / 4) - math.floor(yoe / 100))
    local mp = math.floor((5 * doy + 2) / 153)
    local d = doy - math.floor((153 * mp + 2) / 5) + 1
    local m = mp + ((mp < 10) and 3 or (-9))
    y = y + ((m <= 2) and 1 or 0)
    return y, m, d
end

local function gregorian_to_jalali(gy, gm, gd)
    local g_days_in_month = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
    local gy2 = (gm > 2) and (gy + 1) or gy
    local days = 355666 + (365 * gy) + math.floor((gy2 + 3) / 4) - math.floor((gy2 + 99) / 100) +
        math.floor((gy2 + 399) / 400) + gd
    for i = 1, gm - 1 do
        days = days + g_days_in_month[i]
    end

    local jy = -1595 + (33 * math.floor(days / 12053))
    days = days % 12053
    jy = jy + 4 * math.floor(days / 1461)
    days = days % 1461
    if days > 365 then
        jy = jy + math.floor((days - 1) / 365)
        days = (days - 1) % 365
    end

    local jm, jd
    if days < 186 then
        jm = 1 + math.floor(days / 31)
        jd = 1 + (days % 31)
    else
        jm = 7 + math.floor((days - 186) / 30)
        jd = 1 + ((days - 186) % 30)
    end
    return jy, jm, jd
end

-- FILETIME (تیک ۱۰۰ns از ۱۶۰۱) -> {y,m,d,hh,mi,ss} شمسی، کاملاً سمت Lua
local function filetime_to_jalali(raw)
    raw = tonumber(raw)
    if raw == nil or raw <= 0 then return nil end
    local unix_seconds = raw / 10000000 - 11644473600
    local days = math.floor(unix_seconds / 86400)
    local sec_of_day = unix_seconds - days * 86400
    local gy, gm, gd = civil_from_civil_days(days)
    local jy, jm, jd = gregorian_to_jalali(gy, gm, gd)
    local hh = math.floor(sec_of_day / 3600)
    local mi = math.floor((sec_of_day % 3600) / 60)
    local ss = math.floor(sec_of_day % 60)
    return { y = jy, m = jm, d = jd, hh = hh, mi = mi, ss = ss }
end

local function jalali_short_label(raw)
    local j = filetime_to_jalali(raw)
    if j == nil then return "" end
    return j.d .. " " .. (JMONTH[j.m] or j.m)
end

local function jalali_full_label(raw)
    local j = filetime_to_jalali(raw)
    if j == nil then return "" end
    return j.d .. " " .. (JMONTH[j.m] or j.m) .. " " .. j.y
end

local function jalali_time_label(raw)
    local j = filetime_to_jalali(raw)
    if j == nil then return "" end
    return string.format("%02d:%02d", j.hh, j.mi)
end

local function fetch_now_unix()
    local record = {}
    local ok = pcall(function()
        db.query({ query = "SELECT UNIX_TIMESTAMP()", params = {} })
    end)
    local now_unix = nil
    if ok and db.query_fetch(record) and record[1] ~= nil then
        now_unix = tonumber(record[1])
    end
    db.query_free()
    return now_unix
end

local NOW_UNIX = fetch_now_unix()
local NOW_FILETIME = NOW_UNIX and ((NOW_UNIX + 11644473600) * 10000000) or nil

local function ago_seconds(raw)
    local ft = tonumber(raw)
    if ft == nil or ft <= 0 or NOW_UNIX == nil then
        return -1
    end
    local unix_seconds = ft / 10000000 - 11644473600
    return math.floor(NOW_UNIX - unix_seconds)
end

-- ============================================================
-- کوئری اصلی: فهرست کامل بات‌ها + تنظیمات (بدون JOIN به bot_history)
-- ============================================================

local main_query = [[
SELECT
    bc.ID,
    bc.NAME,
    bc.run_path,
    LEFT(COALESCE(bc.DESCRIPTION, ''), 240) AS descr,
    bc.DISABLED,
    bc.public_access,
    bc.RESULT_TYPE,
    bc.PERIOD_TIME,
    bc.show_in_widget,
    bc.show_in_portal_menu,
    bc.async_run,
    bc.cache_time,
    bc.max_execute_time,
    bc.db_prefix,
    bc.MODIFIER,
    bc.src_domain,
    bc.MODIFY_DATE,
    COALESCE(bcr.RUN_COUNT, 0) AS total_runs,
    bs.NAME AS cat_name,
    bp.NAME AS sec_name,
    COALESCE(bcc.CAT_ID, 0) AS cat_id,
    COALESCE(bs.REF_ID, 0) AS sec_id
FROM bot_command bc
LEFT JOIN bot_command_run bcr
    ON bcr.COMMAND_ID = bc.ID
LEFT JOIN bot_command_categories bcc
    ON bcc.COMMAND_ID = bc.ID AND bcc.IS_DEFAULT = 1
LEFT JOIN bot_section bs
    ON bs.ID = bcc.CAT_ID
LEFT JOIN bot_section bp
    ON bp.ID = bs.REF_ID
ORDER BY total_runs DESC, bc.ID DESC
]]

local LAST_QUERY_ERROR = nil

local function q(sql, params)
    local ok, err = pcall(function()
        db.query({ query = sql, params = params or {} })
    end)
    if not ok then
        LAST_QUERY_ERROR = tostring(err) .. " | sql: " .. tostring(sql):sub(1, 300)
        pcall(teamyar.write_log, "bot_module_performance_report query failed: " .. LAST_QUERY_ERROR)
        db.query_free()
        return {}
    end
    local rows = {}
    local record = {}
    while db.query_fetch(record) do
        local copy = {}
        for i = 1, #record do
            copy[i] = record[i]
        end
        table.insert(rows, copy)
    end
    db.query_free()
    return rows
end

local main_rows = q(main_query, {})

if #main_rows == 0 then
    -- ممکن است واقعاً صفر بات باشد؛ اما اگر کوئری خطا داده باشد هم q() آرایهٔ
    -- خالی برمی‌گرداند، پس یک بار جداگانه برای تشخیص خطای واقعی امتحان می‌کنیم.
    local probe_ok = pcall(function()
        db.query({ query = "SELECT COUNT(*) FROM bot_command", params = {} })
    end)
    db.query_free()
    if not probe_ok then
        teamyar.write_result([[
<!DOCTYPE html>
<html dir="rtl" lang="fa">
<head><meta charset="UTF-8"><title>خطا</title></head>
<body style="font-family:Tahoma,sans-serif;background:#0b1020;color:#e8edff;padding:40px;text-align:center;">
<h2 style="color:#fb7185;">خطا در دریافت عملکرد ماژول باتی</h2>
</body></html>
]])
        return
    end
end

-- نسخه‌های ثبت‌شدهٔ هر بات (برچسب vN در UI)
local ver_rows = q([[
SELECT COMMAND_ID AS id, COUNT(*) AS n
FROM bot_command_version
GROUP BY COMMAND_ID
]], {})
local ver_by = {}
for _, r in ipairs(ver_rows) do
    ver_by[tonumber(r[1])] = tonumber(r[2]) or 0
end

local section_rows = q([[
SELECT ID AS id, REF_ID AS ref, NAME AS name
FROM bot_section
ORDER BY REF_ID, NAME
LIMIT 400
]], {})

-- ============================================================
-- یک fetch خام واحد روی bot_history — نگاه کنید به یادداشت فنی پرفورمنس
-- بالای فایل. آمار بازه/روزانه/ساعتی/نوع‌اجرا/رویدادهای اخیر/آخرین‌اجرا همه
-- از همین یک نتیجه در یک پاس Lua محاسبه می‌شوند.
-- ============================================================

local RUN_TICK = "The command was run."
local ERR_PREFIX = "Error"
local RAW_FETCH_CAP = 500000 -- سقف ایمنی در برابر بازهٔ خیلی بزرگ (days تا ۳۶۵)

-- بازهٔ خام باید هم SPARK_WINDOW (نمودارها) و هم days (KPI/جدول) را بپوشاند؛
-- برای جلوگیری از یک scan خیلی بزرگ وقتی کاربر days=365 می‌خواهد، به ۹۰ روز
-- سقف می‌خورد (آمار «بازه» برای days>90 در این حالت روی همان ۹۰ روز محاسبه
-- می‌شود — تبعیض مستند و قابل قبول در برابر تایم‌اوت کامل صفحه).
local RAW_WINDOW_DAYS = math.min(math.max(SPARK_WINDOW, days), 90)

local raw_history_rows = q([[
SELECT
    ID,
    command_id,
    DATE_CREATE,
    CONTENT,
    running_time,
    run_type
FROM bot_history
WHERE DATE_CREATE >= ((UNIX_TIMESTAMP() - (? * 86400)) + 11644473600) * 10000000
ORDER BY ID DESC
LIMIT ]] .. RAW_FETCH_CAP, { RAW_WINDOW_DAYS })

-- --- محور روزانهٔ ثابت (SPARK_WINDOW روز) — کاملاً سمت Lua
local today_day_index = NOW_UNIX and math.floor(NOW_UNIX / 86400) or 0
local first_day_index = today_day_index - (SPARK_WINDOW - 1)
local pulse_days = {}
local day_pos = {} -- day-index صحیح -> 1..SPARK_WINDOW
for i = 1, SPARK_WINDOW do
    local day_index = first_day_index + (i - 1)
    day_pos[day_index] = i
    local raw_ft = (day_index * 86400 + 43200 + 11644473600) * 10000000 -- ظهر همان روز، برای برچسب پایدار
    pulse_days[i] = {
        lbl = jalali_short_label(raw_ft),
        full = jalali_full_label(raw_ft),
        runs = 0,
        errs = 0
    }
end

local period_threshold_unix = NOW_UNIX and (NOW_UNIX - days * 86400) or nil
local hour_threshold_unix = NOW_UNIX and (NOW_UNIX - HOUR_WINDOW * 86400) or nil
local kind_threshold_unix = NOW_UNIX and (NOW_UNIX - KIND_WINDOW * 86400) or nil

local period_by = {}
local spark_by = {}
local hours = {}
for i = 1, 24 do hours[i] = 0 end
local kinds_by = {}
local feed = {}
local error_list = {}
local last_run_by = {}

for _, r in ipairs(raw_history_rows) do
    local cid = tonumber(r[2])
    local ft = tonumber(r[3])
    local content = r[4] or ""
    local running_time = tonumber(r[5])
    local run_type = tonumber(r[6]) or 0
    if cid ~= nil and ft ~= nil then
        local is_run = content == RUN_TICK
        local is_err = content:sub(1, #ERR_PREFIX) == ERR_PREFIX
        local unix_seconds = ft / 10000000 - 11644473600

        -- ردیف‌ها بر اساس ID نزولی می‌آیند؛ اولین باری که یک command_id دیده
        -- می‌شود همان جدیدترین رویدادش (در همین بازهٔ خام) است.
        if last_run_by[cid] == nil then
            last_run_by[cid] = ft
        end

        if period_threshold_unix and unix_seconds >= period_threshold_unix then
            local p = period_by[cid]
            if not p then
                p = { runs = 0, errs = 0, sum = 0, n = 0, max = 0 }
                period_by[cid] = p
            end
            if is_run then p.runs = p.runs + 1 end
            if is_err then p.errs = p.errs + 1 end
            if is_run and running_time ~= nil and running_time > 0 then
                p.sum = p.sum + running_time
                p.n = p.n + 1
                if running_time > p.max then p.max = running_time end
            end
        end

        local day_index = math.floor(unix_seconds / 86400)
        local slot = day_pos[day_index]
        if slot then
            local s = spark_by[cid]
            if not s then
                s = { runs = {}, errs = {} }
                for i = 1, SPARK_WINDOW do s.runs[i] = 0; s.errs[i] = 0 end
                spark_by[cid] = s
            end
            if is_run then
                s.runs[slot] = s.runs[slot] + 1
                pulse_days[slot].runs = pulse_days[slot].runs + 1
            end
            if is_err then
                s.errs[slot] = s.errs[slot] + 1
                pulse_days[slot].errs = pulse_days[slot].errs + 1
            end
        end

        if is_run and hour_threshold_unix and unix_seconds >= hour_threshold_unix then
            local sec_of_day = unix_seconds - math.floor(unix_seconds / 86400) * 86400
            local h = math.floor(sec_of_day / 3600) + 1
            hours[h] = hours[h] + 1
        end

        if is_run and kind_threshold_unix and unix_seconds >= kind_threshold_unix then
            kinds_by[run_type] = (kinds_by[run_type] or 0) + 1
        end

        if (is_run or is_err) and #feed < 80 then
            table.insert(feed, {
                bid = cid,
                rt = run_type,
                err = is_err,
                ms = running_time and math.floor(running_time / 10000) or 0,
                d = jalali_short_label(ft),
                t = jalali_time_label(ft),
                ago = ago_seconds(ft),
                msg = is_err and content:sub(1, 200) or ""
            })
        end
        if is_err and kind_threshold_unix and unix_seconds >= kind_threshold_unix and #error_list < 60 then
            table.insert(error_list, {
                bid = cid,
                rt = run_type,
                d = jalali_short_label(ft),
                t = jalali_time_label(ft),
                ago = ago_seconds(ft),
                msg = content:sub(1, 260)
            })
        end
    end
end

local kinds = {}
for rt, n in pairs(kinds_by) do
    table.insert(kinds, { rt = rt, n = n })
end

-- ============================================================
-- شکل‌دهی نهایی آرایهٔ بات‌ها + KPI تجمیعی
-- ============================================================

local has_bot_selection = #selected_bot_ids > 0
local selected_bot_lookup = {}
for _, bot_id in ipairs(selected_bot_ids) do
    selected_bot_lookup[tonumber(bot_id)] = true
end

local all_bots = {}
local kpi = {
    total = 0, active = 0, disabled = 0, never = 0, failing = 0,
    runs_period = 0, errs_period = 0, avg_sum = 0, avg_n = 0
}

for _, r in ipairs(main_rows) do
    local id = tonumber(r[1])
    local total_runs = tonumber(r[18]) or 0
    local off = tonumber(r[5]) == 1
    local include_row = (not has_bot_selection and (include_disabled or not off))
        or (has_bot_selection and selected_bot_lookup[id])

    if include_row then
        local p = period_by[id]
        local runs_period = p and p.runs or 0
        local errs_period = p and p.errs or 0
        local avg_ms = (p and p.n and p.n > 0) and math.floor(p.sum / p.n / 10000) or 0
        local max_ms = (p and p.max and p.max > 0) and math.floor(p.max / 10000) or 0
        local last_raw = last_run_by[id]
        local modify_raw = tonumber(r[17])

        local bot = {
            id = id,
            name = r[2],
            path = r[3] or "",
            descr = r[4] or "",
            off = off,
            pub = tonumber(r[6]) == 1,
            html = tonumber(r[7]) == 1,
            timer = tonumber(r[8]) ~= nil and tonumber(r[8]) > 0,
            widget = tonumber(r[9]) == 1,
            portal = tonumber(r[10]) == 1,
            async = tonumber(r[11]) == 1,
            cache = tonumber(r[12]) or 0,
            maxexec = tonumber(r[13]) or 0,
            dbp = r[14] or "",
            creator = r[15] or "",
            srcdom = r[16] or "",
            total = total_runs,
            cat = r[19] or "",
            sec = r[20] or "",
            catId = tonumber(r[21]) or 0,
            secId = tonumber(r[22]) or 0,
            runs = runs_period,
            errs = errs_period,
            avg = avg_ms,
            max = max_ms,
            last = last_raw and (jalali_short_label(last_raw) .. " " .. jalali_time_label(last_raw)) or "",
            lastAgo = ago_seconds(last_raw),
            mod = modify_raw and jalali_short_label(modify_raw) or "—",
            modAgo = ago_seconds(modify_raw),
            ver = ver_by[id] or 0
        }
        local sp = spark_by[id]
        bot.spark = sp and sp.runs or nil
        bot.espark = sp and sp.errs or nil

        kpi.total = kpi.total + 1
        kpi.runs_period = kpi.runs_period + runs_period
        kpi.errs_period = kpi.errs_period + errs_period
        if off then kpi.disabled = kpi.disabled + 1 else kpi.active = kpi.active + 1 end
        if total_runs == 0 then kpi.never = kpi.never + 1 end
        if errs_period > 0 then kpi.failing = kpi.failing + 1 end
        if avg_ms > 0 and runs_period > 0 then
            kpi.avg_sum = kpi.avg_sum + avg_ms * runs_period
            kpi.avg_n = kpi.avg_n + runs_period
        end

        table.insert(all_bots, bot)
    end
end

kpi.avg = kpi.avg_n > 0 and math.floor(kpi.avg_sum / kpi.avg_n) or 0
kpi.avg_sum, kpi.avg_n = nil, nil
-- برچسب واقعی «بازه» — اگر days بزرگ‌تر از سقف RAW_WINDOW_DAYS باشد (نگاه کنید
-- به یادداشت فنی پرفورمنس بالای فایل)، عدد واقعاً واکشی‌شده نمایش داده می‌شود
kpi.period_days = math.min(days, RAW_WINDOW_DAYS)

local sections = {}
for _, r in ipairs(section_rows) do
    table.insert(sections, { id = tonumber(r[1]) or 0, ref = tonumber(r[2]) or 0, name = r[3] or "" })
end

local generated_at = NOW_FILETIME
    and (jalali_full_label(NOW_FILETIME) .. " " .. jalali_time_label(NOW_FILETIME))
    or "—"

local report_data = {
    bots = all_bots,
    days = pulse_days,
    feed = feed,
    errors = error_list,
    hours = hours,
    kinds = kinds,
    sections = sections,
    kpi = kpi,
    window = SPARK_WINDOW,
    selectedBots = selected_bot_ids,
    includeDisabledDefault = include_disabled,
    genAt = generated_at
}

local ok_encode, encoded = pcall(json.encode, report_data)
if not ok_encode or type(encoded) ~= "string" then
    encoded = '{"bots":[],"days":[],"feed":[],"errors":[],"hours":[],"kinds":[],"sections":[],"kpi":{}}'
end
-- امن‌سازی JSON درون <script>: کاراکترهای < > & به یونیکد اسکیپ تبدیل می‌شوند
encoded = encoded:gsub("<", "\\u003C"):gsub(">", "\\u003E"):gsub("&", "\\u0026")

-- ============================================================
-- HTML/CSS/JS — الگوی UI کپی‌شده از بات 594 «مرکز فرماندهی باتی»
-- ============================================================

local HEAD = [==[<!DOCTYPE html>
<html lang="fa" dir="rtl">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>عملکرد ماژول باتی</title>
<style>
:root{
  --bg:#070b16; --bg2:#0c1224; --panel:rgba(255,255,255,.045);
  --panel2:rgba(255,255,255,.025); --line:rgba(255,255,255,.09);
  --line2:rgba(255,255,255,.05);
  --fg:#e8edff; --fg2:#a3b0d4; --fg3:#6d7ba3;
  --brand:#7c5cff; --brand2:#22d3ee;
  --ok:#34d399; --warn:#fbbf24; --err:#fb7185; --info:#60a5fa;
  --shadow:0 18px 48px rgba(0,0,0,.45);
  --r:16px;
}
body.lite{
  --bg:#eef1f8; --bg2:#f7f9fd; --panel:#ffffff; --panel2:#fbfcff;
  --line:#dfe5f2; --line2:#eef1f8;
  --fg:#131a2e; --fg2:#4d5a7a; --fg3:#8c98b6;
  --shadow:0 12px 32px rgba(20,30,70,.10);
}
*{box-sizing:border-box;margin:0;padding:0}
html,body{background:var(--bg);}
body{
  font-family:Vazirmatn,"IRANSans","IRANYekan","Segoe UI",Tahoma,system-ui,sans-serif;
  color:var(--fg); line-height:1.65; min-height:100vh;
  -webkit-font-smoothing:antialiased;
  background:
    radial-gradient(1100px 620px at 82% -12%, rgba(124,92,255,.20), transparent 62%),
    radial-gradient(900px 520px at 6% 4%, rgba(34,211,238,.14), transparent 60%),
    var(--bg);
  transition:background .35s ease,color .25s ease;
}
body.lite{
  background:
    radial-gradient(1100px 620px at 82% -12%, rgba(124,92,255,.13), transparent 62%),
    radial-gradient(900px 520px at 6% 4%, rgba(34,211,238,.12), transparent 60%),
    var(--bg);
}
#reportRoot:fullscreen{ background:var(--bg); overflow:auto; }
.num{font-variant-numeric:tabular-nums;font-feature-settings:"tnum";direction:ltr;display:inline-block}
.mono{font-family:ui-monospace,"Cascadia Mono",Consolas,monospace;direction:ltr;unicode-bidi:embed}
.wrap{max-width:1560px;margin:0 auto;padding:18px 20px 56px;position:relative}

.panel{
  background:var(--panel); border:1px solid var(--line); border-radius:var(--r);
  backdrop-filter:blur(14px); -webkit-backdrop-filter:blur(14px);
}
.ph{display:flex;align-items:center;gap:10px;padding:13px 16px;border-bottom:1px solid var(--line2)}
.ph h2{font-size:14px;font-weight:700;letter-spacing:.1px}
.ph .sub{font-size:11.5px;color:var(--fg3);font-weight:500}
.ph .grow{flex:1}

.top{display:flex;align-items:center;gap:14px;flex-wrap:wrap;margin-bottom:18px}
.brand{display:flex;align-items:center;gap:12px}
.orb{
  width:42px;height:42px;border-radius:13px;position:relative;flex:none;
  background:linear-gradient(140deg,var(--brand),var(--brand2));
  box-shadow:0 8px 26px rgba(124,92,255,.42);
  display:grid;place-items:center;
}
.orb::after{
  content:"";position:absolute;inset:-5px;border-radius:17px;
  border:1.5px solid rgba(124,92,255,.42);animation:ping 2.6s ease-out infinite;
}
@keyframes ping{0%{transform:scale(.9);opacity:.9}70%{transform:scale(1.18);opacity:0}100%{opacity:0}}
.orb svg{width:22px;height:22px}
.brand h1{font-size:19px;font-weight:800;letter-spacing:-.2px}
.brand .meta{font-size:11.5px;color:var(--fg3)}
.top .grow{flex:1}
.tbtn{
  display:inline-flex;align-items:center;gap:7px;height:36px;padding:0 13px;
  border-radius:11px;border:1px solid var(--line);background:var(--panel);
  color:var(--fg2);font:inherit;font-size:12.5px;font-weight:600;cursor:pointer;
  transition:.16s;
}
.tbtn:hover{color:var(--fg);border-color:var(--brand);transform:translateY(-1px)}
.tbtn svg{width:15px;height:15px}
.clock{
  display:flex;flex-direction:column;align-items:flex-end;line-height:1.25;
  padding:0 13px;border-radius:11px;border:1px solid var(--line);background:var(--panel);
  height:36px;justify-content:center;
}
.clock b{font-size:13px}
.clock span{font-size:10.5px;color:var(--fg3)}
a.tbtn{text-decoration:none}

.go{
  width:26px;height:26px;flex:none;display:grid;place-items:center;border-radius:8px;
  border:1px solid var(--line);background:var(--panel2);color:var(--fg3);
  text-decoration:none;opacity:0;transition:.15s
}
.go svg{width:13px;height:13px}
.go:hover{color:#fff;background:var(--brand);border-color:var(--brand)}
.card:hover .go,.ev:hover .go,.nb:hover .go,.go:focus{opacity:1}
@media(hover:none){.go{opacity:.7}}
.tbl a.tlink{color:inherit;text-decoration:none;border-bottom:1px dotted var(--line)}
.tbl a.tlink:hover{color:var(--brand2);border-bottom-color:var(--brand2)}

.kpis{display:grid;grid-template-columns:repeat(6,1fr);gap:12px;margin-bottom:16px}
.kpi{
  position:relative;overflow:hidden;padding:14px 15px 12px;border-radius:var(--r);
  background:var(--panel);border:1px solid var(--line);
}
.kpi::before{content:"";position:absolute;inset:0 auto 0 0;width:3px;background:var(--c,var(--brand))}
.kpi .lbl{font-size:11.5px;color:var(--fg3);font-weight:600;display:flex;align-items:center;gap:6px}
.kpi .val{font-size:30px;font-weight:800;letter-spacing:-1px;line-height:1.2;margin-top:2px}
.kpi .sub{font-size:11px;color:var(--fg2)}
.kpi .viz{position:absolute;inset-inline-end:12px;top:12px;opacity:.95}
.dot{width:7px;height:7px;border-radius:50%;background:var(--c,var(--brand));flex:none}

.row{display:grid;gap:12px;margin-bottom:16px}
.row.a{grid-template-columns:1fr 340px}
.row.b{grid-template-columns:1fr 380px}

.chartbox{padding:8px 14px 14px}
.seg{display:flex;gap:4px;background:var(--panel2);border:1px solid var(--line2);border-radius:10px;padding:3px}
.seg button{
  border:0;background:transparent;color:var(--fg3);font:inherit;font-size:11.5px;font-weight:600;
  padding:4px 11px;border-radius:7px;cursor:pointer;transition:.15s
}
.seg button.on{background:var(--brand);color:#fff}
.tip{
  position:fixed;z-index:60;pointer-events:none;opacity:0;transform:translateY(4px);
  background:var(--bg2);border:1px solid var(--line);border-radius:10px;padding:8px 11px;
  font-size:11.5px;box-shadow:var(--shadow);transition:opacity .12s;min-width:130px;color:var(--fg)
}
.tip.on{opacity:1;transform:none}
.tip b{display:block;font-size:12px;margin-bottom:4px}
.tip i{font-style:normal;color:var(--fg3)}

.cmd{display:flex;align-items:center;gap:10px;flex-wrap:wrap;margin-bottom:12px}
.search{position:relative;flex:1;min-width:240px}
.search input{
  width:100%;height:44px;border-radius:13px;border:1px solid var(--line);
  background:var(--panel);color:var(--fg);font:inherit;font-size:14px;
  padding:0 44px 0 78px;transition:.18s;outline:none
}
.search input:focus{border-color:var(--brand);box-shadow:0 0 0 4px rgba(124,92,255,.16)}
.search .ic{position:absolute;inset-inline-start:15px;top:50%;transform:translateY(-50%);color:var(--fg3)}
.search .ic svg{width:17px;height:17px;display:block}
.search .kbd{
  position:absolute;inset-inline-end:12px;top:50%;transform:translateY(-50%);
  font-size:10.5px;color:var(--fg3);border:1px solid var(--line);border-radius:6px;
  padding:2px 7px;background:var(--panel2)
}
select.sel{
  height:44px;border-radius:13px;border:1px solid var(--line);background:var(--panel);
  color:var(--fg2);font:inherit;font-size:12.5px;font-weight:600;padding:0 12px;cursor:pointer;outline:none
}
.views{display:flex;gap:3px;background:var(--panel);border:1px solid var(--line);border-radius:13px;padding:4px;height:44px}
.views button{
  width:38px;border:0;background:transparent;border-radius:9px;color:var(--fg3);cursor:pointer;
  display:grid;place-items:center;transition:.15s
}
.views button svg{width:17px;height:17px}
.views button.on{background:var(--brand);color:#fff}
.chips{display:flex;gap:7px;flex-wrap:wrap;margin-bottom:14px}
.chip{
  border:1px solid var(--line);background:var(--panel);color:var(--fg2);
  font:inherit;font-size:11.5px;font-weight:600;padding:6px 12px;border-radius:999px;
  cursor:pointer;transition:.15s;display:inline-flex;align-items:center;gap:6px
}
.chip:hover{border-color:var(--brand);color:var(--fg)}
.chip.on{background:var(--brand);border-color:var(--brand);color:#fff}
.chip .n{font-size:10.5px;opacity:.7}
.chip.sec.on{background:var(--brand2);border-color:var(--brand2);color:#04222b}
.count{font-size:12px;color:var(--fg3);font-weight:600;margin-inline-start:auto}

.cards{display:grid;grid-template-columns:repeat(auto-fill,minmax(288px,1fr));gap:12px}
.card{
  position:relative;padding:14px;border-radius:var(--r);background:var(--panel);
  border:1px solid var(--line);cursor:pointer;transition:.18s;overflow:hidden
}
.card:hover{transform:translateY(-3px);border-color:var(--brand);box-shadow:var(--shadow)}
.card.off{opacity:.55}
.card .rail{position:absolute;inset:0 auto 0 0;width:3px;background:var(--h,var(--ok))}
.card h3{font-size:14px;font-weight:700;line-height:1.45;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.card .path{font-size:10.5px;color:var(--fg3);margin-top:1px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.card .spark{height:34px;margin:10px 0 8px}
.card .stats{display:flex;gap:12px;font-size:11px;color:var(--fg2)}
.card .stats b{color:var(--fg);font-weight:700}
.card .tags{display:flex;gap:4px;flex-wrap:wrap;margin-top:9px}
.tag{
  font-size:10px;font-weight:700;padding:2px 7px;border-radius:6px;
  background:var(--panel2);border:1px solid var(--line2);color:var(--fg2)
}
.tag.pub{color:#04222b;background:var(--brand2);border-color:transparent}
.tag.timer{color:#2b1a00;background:var(--warn);border-color:transparent}
.tag.err{color:#320712;background:var(--err);border-color:transparent}
.tag.off{color:#fff;background:var(--fg3);border-color:transparent}
.hpill{
  font-size:10px;font-weight:800;padding:2px 8px;border-radius:999px;flex:none;
  background:var(--panel2);color:var(--h);border:1px solid var(--line);
  background:color-mix(in srgb,var(--h) 18%,transparent);
  border-color:color-mix(in srgb,var(--h) 34%,transparent)
}
mark{background:rgba(124,92,255,.32);color:inherit;border-radius:3px;padding:0 1px}

.tbl{width:100%;border-collapse:collapse;font-size:12.5px}
.tbl th{
  text-align:right;font-size:11px;color:var(--fg3);font-weight:700;padding:9px 12px;
  border-bottom:1px solid var(--line);cursor:pointer;white-space:nowrap;user-select:none
}
.tbl th:hover{color:var(--fg)}
.tbl td{padding:9px 12px;border-bottom:1px solid var(--line2);white-space:nowrap}
.tbl tr{cursor:pointer}
.tbl tbody tr:hover{background:var(--panel2)}
.tbl .nm{max-width:280px;overflow:hidden;text-overflow:ellipsis}

.tree{padding:6px 14px 14px}
.tsec{margin-top:12px}
.tsec>h3{font-size:12.5px;font-weight:800;color:var(--fg2);display:flex;align-items:center;gap:8px;margin-bottom:6px}
.tsec>h3 .ln{flex:1;height:1px;background:var(--line)}
.tcat{border:1px solid var(--line2);border-radius:12px;margin-bottom:6px;overflow:hidden;background:var(--panel2)}
.tcat>button{
  width:100%;display:flex;align-items:center;gap:10px;padding:9px 12px;border:0;
  background:transparent;color:var(--fg);font:inherit;font-size:12.5px;font-weight:600;cursor:pointer;text-align:right
}
.tcat>button:hover{background:var(--panel)}
.tcat .bar{flex:1;height:5px;border-radius:3px;background:var(--line);overflow:hidden;max-width:220px}
.tcat .bar i{display:block;height:100%;background:linear-gradient(90deg,var(--brand),var(--brand2))}
.tcat .n{font-size:11px;color:var(--fg3)}
.tcat .kids{display:none;padding:2px 12px 11px;flex-wrap:wrap;gap:6px}
.tcat.open .kids{display:flex}
.mini{
  border:1px solid var(--line);background:var(--panel);border-radius:9px;padding:5px 10px;
  font-size:11.5px;cursor:pointer;color:var(--fg2);display:inline-flex;align-items:center;gap:6px;transition:.15s
}
.mini:hover{border-color:var(--brand);color:var(--fg)}
.mini .go{width:18px;height:18px;border:0;background:transparent}
.mini .go svg{width:11px;height:11px}
.mini:hover .go{opacity:1}

.feed{max-height:430px;overflow:auto;padding:6px 6px 8px}
.ev{display:flex;align-items:flex-start;gap:9px;padding:7px 9px;border-radius:10px;cursor:pointer;transition:.13s}
.ev:hover{background:var(--panel2)}
.ev .bd{width:6px;height:6px;border-radius:50%;margin-top:7px;flex:none;background:var(--ok)}
.ev.bad .bd{background:var(--err)}
.ev .b{flex:1;min-width:0}
.ev .nm{font-size:12px;font-weight:600;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.ev .ms{font-size:10.5px;color:var(--fg3);overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.ev.bad .ms{color:var(--err)}
.ev .tm{font-size:10.5px;color:var(--fg3);flex:none;text-align:left}
.newlist{padding:6px}
.nb{display:flex;align-items:center;gap:10px;padding:8px 9px;border-radius:10px;cursor:pointer;transition:.13s}
.nb:hover{background:var(--panel2)}
.nb .idx{
  width:24px;height:24px;border-radius:8px;display:grid;place-items:center;flex:none;
  font-size:11px;font-weight:800;background:var(--panel2);border:1px solid var(--line2);color:var(--fg3)
}
.nb:first-child .idx{background:linear-gradient(140deg,var(--brand),var(--brand2));color:#fff;border-color:transparent}
.nb .b{flex:1;min-width:0}
.nb .nm{font-size:12.5px;font-weight:600;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.nb .mt{font-size:10.5px;color:var(--fg3)}
.scroll::-webkit-scrollbar{width:8px;height:8px}
.scroll::-webkit-scrollbar-thumb{background:var(--line);border-radius:8px}
.scroll::-webkit-scrollbar-track{background:transparent}

.scrim{position:fixed;inset:0;background:rgba(3,6,14,.62);backdrop-filter:blur(3px);opacity:0;pointer-events:none;transition:.25s;z-index:70}
.scrim.on{opacity:1;pointer-events:auto}
.draw{
  position:fixed;top:0;bottom:0;right:0;width:min(520px,94vw);z-index:80;
  background:var(--bg2);border-left:1px solid var(--line);
  transform:translateX(100%);transition:transform .3s cubic-bezier(.2,.8,.2,1);
  display:flex;flex-direction:column;box-shadow:var(--shadow)
}
.draw.on{transform:translateX(0)}
.dh{padding:16px 18px;border-bottom:1px solid var(--line);display:flex;gap:12px;align-items:flex-start}
.dh h2{font-size:16px;font-weight:800;line-height:1.5}
.dh .path{font-size:11px;color:var(--fg3);margin-top:2px}
.dx{border:1px solid var(--line);background:var(--panel);color:var(--fg2);border-radius:10px;width:32px;height:32px;cursor:pointer;font-size:16px;flex:none;line-height:1}
.dx:hover{color:var(--err);border-color:var(--err)}
.db{flex:1;overflow:auto;padding:16px 18px 26px}
.dgrid{display:grid;grid-template-columns:repeat(3,1fr);gap:9px;margin:14px 0}
.dstat{background:var(--panel);border:1px solid var(--line);border-radius:12px;padding:10px 12px}
.dstat .l{font-size:10.5px;color:var(--fg3);font-weight:600}
.dstat .v{font-size:19px;font-weight:800;letter-spacing:-.5px}
.dsec{font-size:11.5px;font-weight:800;color:var(--fg3);margin:18px 0 8px;display:flex;align-items:center;gap:8px}
.dsec .ln{flex:1;height:1px;background:var(--line)}
.kv{display:flex;justify-content:space-between;gap:12px;padding:6px 0;border-bottom:1px dashed var(--line2);font-size:12px}
.kv span{color:var(--fg3)}
.kv b{font-weight:600;text-align:left;overflow:hidden;text-overflow:ellipsis}
.acts{display:flex;gap:8px;flex-wrap:wrap;margin-top:14px}
.act{
  flex:1;min-width:120px;height:38px;border-radius:11px;border:1px solid var(--line);
  background:var(--panel);color:var(--fg2);font:inherit;font-size:12px;font-weight:700;cursor:pointer;
  display:inline-flex;align-items:center;justify-content:center;gap:7px;transition:.15s;text-decoration:none
}
.act:hover{border-color:var(--brand);color:var(--fg)}
.act.pri{background:linear-gradient(120deg,var(--brand),var(--brand2));color:#fff;border-color:transparent}
.errline{
  font-size:11px;background:color-mix(in srgb,var(--err) 12%,transparent);
  border:1px solid color-mix(in srgb,var(--err) 26%,transparent);
  border-radius:9px;padding:7px 10px;margin-bottom:6px;color:var(--fg)
}
.errline i{display:block;font-style:normal;color:var(--fg3);font-size:10px;margin-bottom:2px}
.empty{text-align:center;padding:42px 20px;color:var(--fg3);font-size:13px}
.empty svg{width:44px;height:44px;opacity:.4;margin-bottom:10px}
.foot{margin-top:22px;text-align:center;font-size:11px;color:var(--fg3)}
</style>
</head>
<body>
<div id="reportRoot">
<div class="wrap">

  <div class="top">
    <div class="brand">
      <div class="orb">
        <svg viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round">
          <rect x="4" y="8" width="16" height="11" rx="3"/><path d="M12 8V4"/><circle cx="12" cy="3" r="1.2" fill="#fff"/>
          <path d="M9 13h.01M15 13h.01"/><path d="M9.5 16.2h5"/>
        </svg>
      </div>
      <div>
        <h1>عملکرد ماژول باتی</h1>
        <div class="meta" id="brandMeta"></div>
      </div>
    </div>
    <div class="grow"></div>
    <div class="clock"><b id="ck">—</b><span id="ckd"></span></div>
    <a class="tbtn" href="/bot" target="_blank" rel="noopener" title="صفحه اصلی ماژول باتی">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M14 4h6v6"/><path d="M20 4 10 14"/><path d="M19 14v5a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1h5"/></svg>
      ماژول باتی
    </a>
    <button class="tbtn" id="theme" title="روشن / تاریک">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round"><path d="M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8z"/></svg>
      <span id="themeTxt">روشن</span>
    </button>
    <button class="tbtn" id="btnFullscreen" onclick="toggleFullScreen()">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M8 3H5a2 2 0 0 0-2 2v3"/><path d="M21 8V5a2 2 0 0 0-2-2h-3"/><path d="M3 16v3a2 2 0 0 0 2 2h3"/><path d="M16 21h3a2 2 0 0 0 2-2v-3"/></svg>
      تمام صفحه
    </button>
    <button class="tbtn" onclick="location.reload()">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12a9 9 0 1 1-2.6-6.4"/><path d="M21 3v6h-6"/></svg>
      بروزرسانی
    </button>
  </div>

  <div class="kpis" id="kpis"></div>

  <div class="row a">
    <div class="panel">
      <div class="ph">
        <span class="dot" style="--c:var(--brand)"></span>
        <h2>نبض اجرا</h2>
        <span class="sub" id="pulseSub"></span>
        <span class="grow"></span>
        <div class="seg" id="rangeSeg">
          <button data-r="7">۷ روز</button>
          <button data-r="14">۱۴ روز</button>
          <button data-r="30" class="on">۳۰ روز</button>
        </div>
      </div>
      <div class="chartbox"><div id="mainChart"></div></div>
    </div>
    <div style="display:grid;gap:12px;align-content:start">
      <div class="panel">
        <div class="ph"><span class="dot" style="--c:var(--brand2)"></span><h2>ریتم شبانه‌روز</h2><span class="sub">۷ روز اخیر</span></div>
        <div class="chartbox"><div id="hourChart"></div></div>
      </div>
      <div class="panel">
        <div class="ph"><span class="dot" style="--c:var(--info)"></span><h2>از کجا اجرا می‌شوند</h2></div>
        <div class="chartbox" id="kindChart"></div>
      </div>
    </div>
  </div>

  <div class="cmd">
    <div class="search">
      <span class="ic"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="11" cy="11" r="7"/><path d="m20 20-3.2-3.2"/></svg></span>
      <input id="q" type="search" placeholder="جستجو در نام، مسیر، توضیح یا دسته…" autocomplete="off">
      <span class="kbd">/</span>
    </div>
    <select class="sel" id="sort">
      <option value="recent">تازه‌ترین تغییر</option>
      <option value="runs">پراجراترین (بازه)</option>
      <option value="total">بیشترین اجرای کل</option>
      <option value="errs">پرخطاترین</option>
      <option value="slow">کندترین</option>
      <option value="lastrun">آخرین اجرا</option>
      <option value="name">الفبا</option>
    </select>
    <div class="views" id="views">
      <button data-v="cards" class="on" title="کارت"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="7" height="7" rx="2"/><rect x="14" y="3" width="7" height="7" rx="2"/><rect x="3" y="14" width="7" height="7" rx="2"/><rect x="14" y="14" width="7" height="7" rx="2"/></svg></button>
      <button data-v="table" title="جدول"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 5h18M3 12h18M3 19h18"/></svg></button>
      <button data-v="tree" title="دسته‌بندی"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M4 5h6M4 12h10M4 19h14"/><circle cx="19" cy="5" r="1.6"/></svg></button>
    </div>
  </div>

  <div class="chips" id="chips"></div>
  <div id="stage"></div>

  <div class="row b" style="margin-top:16px">
    <div class="panel">
      <div class="ph">
        <span class="dot" style="--c:var(--ok)"></span><h2>جریان رویدادها</h2>
        <span class="grow"></span>
        <div class="seg" id="feedSeg">
          <button data-f="all" class="on">همه</button>
          <button data-f="err">فقط خطا</button>
        </div>
      </div>
      <div class="feed scroll" id="feed"></div>
    </div>
    <div class="panel">
      <div class="ph"><span class="dot" style="--c:var(--warn)"></span><h2>تازه‌ترین ویرایش‌ها</h2><span class="sub">بر اساس آخرین تغییر</span></div>
      <div class="newlist scroll" id="newest" style="max-height:430px;overflow:auto"></div>
    </div>
  </div>

  <div class="foot" id="foot"></div>
</div>
</div>

<div class="tip" id="tip"></div>
<div class="scrim" id="scrim"></div>
<aside class="draw" id="draw">
  <div class="dh">
    <div style="flex:1;min-width:0">
      <h2 id="dName">—</h2>
      <div class="path mono" id="dPath"></div>
    </div>
    <button class="dx" id="dClose">×</button>
  </div>
  <div class="db scroll" id="dBody"></div>
</aside>

<script>
window.__REPORT__ = ]==]

local TAIL = [==[;
(function(){
"use strict";
var D = window.__REPORT__ || {};
function arr(v){ return Array.isArray(v) ? v : []; }
var BOTS = arr(D.bots), DAYS = arr(D.days), FEED = arr(D.feed),
    ERRS = arr(D.errors), HOURS = arr(D.hours), KINDS = arr(D.kinds),
    SECS = arr(D.sections), K = D.kpi || {}, WIN = D.window || 30;

var RT = {0:"داخلی",1:"API",2:"عمومی",3:"تایمر",4:"دستور",5:"ویجت",6:"ویجت پورتال",7:"منوی پورتال",8:"دیباگ"};

/* الگوی لینک‌ها طبق درخواست کاربر (1405/05/22):
   رده  -> /?page=/bot/index&cat_id=X
   بات  -> /?page=/bot/command/view&id=X&cat_id=Y&tab=0
   اجرا -> /bot/run/{run_path} */
function botPage(b){ return location.origin + "/?page=/bot/command/view&id=" + b.id + "&cat_id=" + (b.catId || 79) + "&tab=0"; }
function botRun(b){ return location.origin + "/bot/run/" + b.path; }
function botExport(b){ return location.origin + "/bot/command/export?id=" + b.id; }
function botHistory(b){ return location.origin + "/bot/command/history?id=" + b.id; }
function catIndex(catId){ return location.origin + "/?page=/bot/index&cat_id=" + (catId || 79); }
var GO_ICON = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 4h6v6"/><path d="M20 4 10 14"/><path d="M19 14v5a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1h5"/></svg>';
function goLink(b, title){
  return '<a class="go" href="'+esc(botPage(b))+'" target="_blank" rel="noopener" title="'+esc(title||("باز کردن «"+b.name+"» در ماژول باتی"))+'">'+GO_ICON+'</a>';
}
function catGoLink(catId, title){
  return '<a class="go" href="'+esc(catIndex(catId))+'" target="_blank" rel="noopener" title="'+esc(title||"فهرست این رده")+'">'+GO_ICON+'</a>';
}
var byId = {}; BOTS.forEach(function(b){ byId[b.id] = b; });
var Z = []; for (var i=0;i<WIN;i++) Z.push(0);

function esc(s){ return String(s==null?"":s).replace(/[&<>"']/g,function(c){
  return {"&":"&","<":"<",">":">",'"':""","'":"'"}[c]; }); }
function nf(n){ n = Number(n)||0; return n.toLocaleString("en-US"); }
function ago(s){
  if (s==null || s<0) return "—";
  if (s<60) return "همین حالا";
  if (s<3600) return Math.floor(s/60)+" دقیقه پیش";
  if (s<86400) return Math.floor(s/3600)+" ساعت پیش";
  var d=Math.floor(s/86400);
  if (d<30) return d+" روز پیش";
  if (d<365) return Math.floor(d/30)+" ماه پیش";
  return Math.floor(d/365)+" سال پیش";
}
function ms(n){ n=Number(n)||0; return n>=1000 ? (n/1000).toFixed(1)+" ثانیه" : n+" م‌ث"; }
function health(b){
  if (b.off) return {c:"var(--fg3)", t:"خاموش", s:-1};
  var r = b.runs||0, e = b.errs||0;
  if (r===0 && e===0) return {c:"var(--fg3)", t:"بی‌حرکت", s:0};
  var rate = e/Math.max(1,r+e);
  if (rate===0) return {c:"var(--ok)", t:"سالم", s:100};
  if (rate<0.05) return {c:"var(--ok)", t:Math.round((1-rate)*100)+"٪", s:Math.round((1-rate)*100)};
  if (rate<0.25) return {c:"var(--warn)", t:Math.round((1-rate)*100)+"٪", s:Math.round((1-rate)*100)};
  return {c:"var(--err)", t:Math.round((1-rate)*100)+"٪", s:Math.round((1-rate)*100)};
}
function hl(text, q){
  var t = esc(text);
  if (!q) return t;
  var i = String(text||"").toLowerCase().indexOf(q);
  if (i < 0) return t;
  return esc(String(text).slice(0,i)) + "<mark>" + esc(String(text).slice(i,i+q.length)) + "</mark>" + esc(String(text).slice(i+q.length));
}

var TIP = document.getElementById("tip");
function tipOn(html, ev){
  TIP.innerHTML = html; TIP.classList.add("on");
  var r = TIP.getBoundingClientRect();
  var x = ev.clientX - r.width/2, y = ev.clientY - r.height - 14;
  x = Math.max(8, Math.min(x, innerWidth - r.width - 8));
  if (y < 8) y = ev.clientY + 18;
  TIP.style.left = x+"px"; TIP.style.top = y+"px";
}
function tipOff(){ TIP.classList.remove("on"); }

function ring(pct, color, size){
  size = size||42;
  var r = size/2-4, c = 2*Math.PI*r, off = c*(1-Math.max(0,Math.min(100,pct))/100);
  return '<svg width="'+size+'" height="'+size+'" viewBox="0 0 '+size+' '+size+'">'+
    '<circle cx="'+size/2+'" cy="'+size/2+'" r="'+r+'" fill="none" stroke="var(--line)" stroke-width="4"/>'+
    '<circle cx="'+size/2+'" cy="'+size/2+'" r="'+r+'" fill="none" stroke="'+color+'" stroke-width="4" '+
    'stroke-linecap="round" stroke-dasharray="'+c.toFixed(1)+'" stroke-dashoffset="'+off.toFixed(1)+'" '+
    'transform="rotate(-90 '+size/2+' '+size/2+')"/></svg>';
}
function microBars(vals, color){
  var m = Math.max.apply(null, vals.concat([1])), n = vals.length, w = 60, h = 24, bw = w/n;
  var s = "";
  for (var i=0;i<n;i++){
    var bh = Math.max(1.5, vals[i]/m*h);
    s += '<rect x="'+(i*bw).toFixed(2)+'" y="'+(h-bh).toFixed(2)+'" width="'+(bw*0.68).toFixed(2)+'" height="'+bh.toFixed(2)+'" rx="0.8" fill="'+color+'" opacity="'+(0.35+0.65*i/n).toFixed(2)+'"/>';
  }
  return '<svg width="'+w+'" height="'+h+'" viewBox="0 0 '+w+' '+h+'">'+s+'</svg>';
}
function renderKpis(){
  var runsSeries = DAYS.map(function(d){ return d.runs; });
  var errsSeries = DAYS.map(function(d){ return d.errs; });
  var totalR = K.runs_period||0, totalE = K.errs_period||0;
  var healthPct = totalR+totalE > 0 ? Math.round(totalR/(totalR+totalE)*100) : 100;

  var cards = [
    { c:"var(--brand)", l:"باتی‌های ثبت‌شده", v:nf(K.total),
      s:nf(K.active)+" فعال · "+nf(K.disabled)+" غیرفعال",
      viz: ring(K.total? K.active/K.total*100:0, "var(--brand)") },
    { c:"var(--brand2)", l:"اجرا در "+nf(K.period_days||30)+" روز", v:nf(totalR),
      s:"میانگین وزنی "+nf(K.avg)+" م‌ث",
      viz: microBars(runsSeries, "var(--brand2)") },
    { c:"var(--fg3)", l:"هرگز اجرا نشده", v:nf(K.never),
      s: K.total ? Math.round((K.never||0)/K.total*100)+"٪ از کل" : "—",
      viz: microBars(runsSeries.slice(-7), "var(--fg3)") },
    { c:"var(--err)", l:"خطا در بازه", v:nf(totalE),
      s:nf(K.failing)+" باتی خطا داده‌اند",
      viz: microBars(errsSeries, "var(--err)") },
    { c: healthPct>=98?"var(--ok)":healthPct>=90?"var(--warn)":"var(--err)",
      l:"سلامت کلی", v:healthPct+"٪",
      s: healthPct>=98?"وضعیت پایدار":healthPct>=90?"نیازمند نگاه":"نیازمند رسیدگی",
      viz: ring(healthPct, healthPct>=98?"var(--ok)":healthPct>=90?"var(--warn)":"var(--err)") },
    { c:"var(--warn)", l:"میانگین زمان اجرا", v:nf(K.avg),
      s:"میلی‌ثانیه · وزنی بر تعداد اجرا",
      viz: microBars(HOURS.slice(8,20), "var(--warn)") }
  ];

  document.getElementById("kpis").innerHTML = cards.map(function(k){
    return '<div class="kpi" style="--c:'+k.c+'">'+
      '<div class="viz">'+k.viz+'</div>'+
      '<div class="lbl"><span class="dot" style="--c:'+k.c+'"></span>'+k.l+'</div>'+
      '<div class="val num">'+k.v+'</div>'+
      '<div class="sub">'+k.s+'</div></div>';
  }).join("");

  document.getElementById("pulseSub").textContent = nf(totalR)+" اجرا · "+nf(totalE)+" خطا";
}

var range = 30;
function renderMain(){
  var d = DAYS.slice(-range);
  if (!d.length){ document.getElementById("mainChart").innerHTML = '<div class="empty">داده‌ای برای نمایش نیست</div>'; return; }
  var W = 1000, H = 190, PB = 26, PT = 12;
  var maxR = Math.max.apply(null, d.map(function(x){return x.runs;}).concat([1]));
  var maxE = Math.max.apply(null, d.map(function(x){return x.errs;}).concat([1]));
  var n = d.length, bw = W/n, ih = H-PB-PT;
  var bars = "", errs = "", grid = "", labels = "";

  for (var g=1; g<=3; g++){
    var y = PT + ih*(g/4);
    grid += '<line x1="0" y1="'+y.toFixed(1)+'" x2="'+W+'" y2="'+y.toFixed(1)+'" stroke="var(--line2)" stroke-width="1"/>';
  }
  var pts = [];
  for (var i=0;i<n;i++){
    var x = i*bw, bh = d[i].runs/maxR*ih;
    bars += '<rect class="bar" data-i="'+i+'" x="'+(x+bw*0.16).toFixed(2)+'" y="'+(PT+ih-bh).toFixed(2)+
            '" width="'+(bw*0.68).toFixed(2)+'" height="'+Math.max(bh,0.6).toFixed(2)+'" rx="2" fill="url(#gb)"/>';
    var ey = PT + ih - (d[i].errs/maxE*ih*0.55);
    pts.push((x+bw/2).toFixed(1)+","+ey.toFixed(1));
    if (d[i].errs>0)
      errs += '<circle cx="'+(x+bw/2).toFixed(1)+'" cy="'+ey.toFixed(1)+'" r="2.6" fill="var(--err)"/>';
    var step = n>20?5:n>10?2:1;
    if (i%step===0 || i===n-1)
      labels += '<text x="'+(x+bw/2).toFixed(1)+'" y="'+(H-8)+'" text-anchor="middle" font-size="10" fill="var(--fg3)">'+esc(d[i].lbl)+'</text>';
  }
  var line = d.some(function(x){return x.errs>0;})
    ? '<polyline points="'+pts.join(" ")+'" fill="none" stroke="var(--err)" stroke-width="1.4" opacity=".55"/>' : "";

  var html = '<svg viewBox="0 0 '+W+' '+H+'" style="width:100%;height:210px;display:block;overflow:visible">'+
    '<defs><linearGradient id="gb" x1="0" y1="0" x2="0" y2="1">'+
    '<stop offset="0%" stop-color="var(--brand2)"/><stop offset="100%" stop-color="var(--brand)" stop-opacity=".55"/>'+
    '</linearGradient></defs>'+ grid + bars + line + errs + labels +
    '<rect id="hit" x="0" y="0" width="'+W+'" height="'+H+'" fill="transparent"/></svg>';

  var box = document.getElementById("mainChart");
  box.innerHTML = html;
  var sv = box.querySelector("svg");
  sv.addEventListener("mousemove", function(ev){
    var r = sv.getBoundingClientRect();
    var rel = (ev.clientX - r.left) / r.width * W;
    var i = Math.max(0, Math.min(n-1, Math.floor(rel/bw)));
    tipOn('<b>'+esc(d[i].full)+'</b>'+
          '<i>اجرا</i> <span class="num">'+nf(d[i].runs)+'</span><br>'+
          '<i>خطا</i> <span class="num" style="color:var(--err)">'+nf(d[i].errs)+'</span>', ev);
  });
  sv.addEventListener("mouseleave", tipOff);
}

function renderHours(){
  var W=340, H=104, n=24, bw=W/n, ih=H-20;
  var m = Math.max.apply(null, HOURS.concat([1])), s="";
  for (var i=0;i<n;i++){
    var bh = Math.max(2, HOURS[i]/m*ih);
    var peak = HOURS[i]===m;
    s += '<rect data-h="'+i+'" x="'+(i*bw+bw*0.14).toFixed(2)+'" y="'+(ih-bh+6).toFixed(2)+'" width="'+(bw*0.72).toFixed(2)+
         '" height="'+bh.toFixed(2)+'" rx="2" fill="'+(peak?"var(--brand2)":"var(--brand)")+'" opacity="'+(peak?1:0.42+0.5*HOURS[i]/m)+'"/>';
    if (i%6===0) s += '<text x="'+(i*bw+bw/2).toFixed(1)+'" y="'+(H-2)+'" text-anchor="middle" font-size="9.5" fill="var(--fg3)">'+i+'</text>';
  }
  var box = document.getElementById("hourChart");
  box.innerHTML = '<svg viewBox="0 0 '+W+' '+H+'" style="width:100%;height:110px;display:block">'+s+'</svg>';
  var sv = box.querySelector("svg");
  sv.addEventListener("mousemove", function(ev){
    var r = sv.getBoundingClientRect();
    var i = Math.max(0, Math.min(23, Math.floor((ev.clientX-r.left)/r.width*24)));
    tipOn('<b>ساعت '+i+':00</b><i>اجرا</i> <span class="num">'+nf(HOURS[i])+'</span>', ev);
  });
  sv.addEventListener("mouseleave", tipOff);
}

function renderKinds(){
  var tot = KINDS.reduce(function(a,b){return a+b.n;},0) || 1;
  var sorted = KINDS.slice().sort(function(a,b){return b.n-a.n;});
  var cols = ["var(--brand)","var(--brand2)","var(--ok)","var(--warn)","var(--info)","var(--err)","#a78bfa","#f472b6","#4ade80"];
  document.getElementById("kindChart").innerHTML = sorted.length ? sorted.map(function(k,i){
    var p = k.n/tot*100;
    return '<div style="margin:9px 0 0">'+
      '<div style="display:flex;justify-content:space-between;font-size:11.5px;color:var(--fg2)">'+
        '<span>'+esc(RT[k.rt]||("نوع "+k.rt))+'</span>'+
        '<span class="num">'+nf(k.n)+' · '+p.toFixed(0)+'٪</span></div>'+
      '<div style="height:6px;border-radius:3px;background:var(--line);margin-top:4px;overflow:hidden">'+
        '<i style="display:block;height:100%;width:'+p.toFixed(1)+'%;background:'+cols[i%cols.length]+'"></i></div></div>';
  }).join("") : '<div class="empty">داده‌ای نیست</div>';
}

var state = { q:"", view:"cards", sort:"recent", flags:{}, sec:0, sortCol:null, sortDir:1 };
if (D.includeDisabledDefault) { state.flags.off = false; }

var FLAGS = [
  { k:"active", t:"فعال",       f:function(b){return !b.off;} },
  { k:"off",    t:"غیرفعال",    f:function(b){return b.off;} },
  { k:"pub",    t:"عمومی",      f:function(b){return b.pub;} },
  { k:"timer",  t:"تایمردار",   f:function(b){return b.timer;} },
  { k:"html",   t:"HTML",       f:function(b){return b.html;} },
  { k:"live",   t:"فعال بازه",  f:function(b){return (b.runs||0)>0;} },
  { k:"idle",   t:"بی‌حرکت",    f:function(b){return (b.total||0)===0;} },
  { k:"bad",    t:"خطادار",     f:function(b){return (b.errs||0)>0;} }
];

function renderChips(){
  var host = document.getElementById("chips");
  var h = FLAGS.map(function(f){
    var n = BOTS.filter(f.f).length;
    return '<button class="chip'+(state.flags[f.k]?" on":"")+'" data-flag="'+f.k+'">'+esc(f.t)+'<span class="n num">'+n+'</span></button>';
  }).join("");
  var tops = SECS.filter(function(s){ return s.ref===0; });
  if (tops.length){
    h += '<span style="width:1px;height:22px;background:var(--line);margin:0 4px"></span>';
    h += '<button class="chip sec'+(state.sec===0?" on":"")+'" data-sec="0">همه بخش‌ها</button>';
    h += tops.map(function(s){
      var n = BOTS.filter(function(b){ return b.secId===s.id; }).length;
      if (!n) return "";
      return '<button class="chip sec'+(state.sec===s.id?" on":"")+'" data-sec="'+s.id+'">'+esc(s.name)+'<span class="n num">'+n+'</span></button>';
    }).join("");
  }
  host.innerHTML = h;
}

function filtered(){
  var q = state.q.trim().toLowerCase();
  var act = FLAGS.filter(function(f){ return state.flags[f.k]; });
  var out = BOTS.filter(function(b){
    if (state.sec && b.secId !== state.sec) return false;
    for (var i=0;i<act.length;i++) if (!act[i].f(b)) return false;
    if (!q) return true;
    return (b.name+" "+b.path+" "+b.descr+" "+b.cat+" "+b.sec+" "+b.dbp).toLowerCase().indexOf(q) >= 0;
  });
  var s = state.sort;
  out.sort(function(a,b){
    if (s==="name")    return a.name.localeCompare(b.name,"fa");
    if (s==="runs")    return (b.runs||0)-(a.runs||0);
    if (s==="total")   return (b.total||0)-(a.total||0);
    if (s==="errs")    return (b.errs||0)-(a.errs||0);
    if (s==="slow")    return (b.avg||0)-(a.avg||0);
    if (s==="lastrun"){
      var A = a.lastAgo<0?1e12:a.lastAgo, B = b.lastAgo<0?1e12:b.lastAgo; return A-B;
    }
    var X = a.modAgo<0?1e12:a.modAgo, Y = b.modAgo<0?1e12:b.modAgo; return X-Y;
  });
  return out;
}

function sparkline(b){
  var v = b.spark || Z, e = b.espark || Z;
  var W=260, H=34, n=v.length, m=Math.max.apply(null, v.concat([1]));
  var step = W/(n-1||1), pts=[];
  for (var i=0;i<n;i++){
    var x=(i*step), y=H-2-(v[i]/m)*(H-6);
    pts.push(x.toFixed(1)+","+y.toFixed(1));
  }
  var area = "0,"+H+" " + pts.join(" ") + " "+W+","+H;
  var dots = "";
  for (var j=0;j<n;j++) if (e[j]>0){
    dots += '<circle cx="'+(j*step).toFixed(1)+'" cy="'+(H-3)+'" r="2" fill="var(--err)"/>';
  }
  var id = "g"+b.id;
  return '<svg viewBox="0 0 '+W+' '+H+'" preserveAspectRatio="none" style="width:100%;height:34px;display:block">'+
    '<defs><linearGradient id="'+id+'" x1="0" y1="0" x2="0" y2="1">'+
    '<stop offset="0%" stop-color="var(--brand2)" stop-opacity=".45"/>'+
    '<stop offset="100%" stop-color="var(--brand)" stop-opacity="0"/></linearGradient></defs>'+
    '<polygon points="'+area+'" fill="url(#'+id+')"/>'+
    '<polyline points="'+pts.join(" ")+'" fill="none" stroke="var(--brand2)" stroke-width="1.6" stroke-linejoin="round"/>'+
    dots+'</svg>';
}
function tagsOf(b){
  var t = [];
  if (b.off)    t.push('<span class="tag off">غیرفعال</span>');
  if (b.pub)    t.push('<span class="tag pub">عمومی</span>');
  if (b.timer)  t.push('<span class="tag timer">تایمر</span>');
  if (b.errs>0) t.push('<span class="tag err">'+b.errs+' خطا</span>');
  if (b.widget) t.push('<span class="tag">ویجت</span>');
  if (b.portal) t.push('<span class="tag">پورتال</span>');
  if (b.html)   t.push('<span class="tag">HTML</span>');
  if (b.async)  t.push('<span class="tag">ناهمزمان</span>');
  if (b.cache>0)t.push('<span class="tag">کش '+b.cache+'د</span>');
  if (b.ver>0)  t.push('<span class="tag">v'+b.ver+'</span>');
  return t.join("");
}
function renderCards(list, q){
  if (!list.length) return emptyBox();
  return '<div class="cards">' + list.map(function(b){
    var h = health(b);
    return '<article class="card'+(b.off?" off":"")+'" data-id="'+b.id+'" style="--h:'+h.c+'">'+
      '<div class="rail"></div>'+
      '<div style="display:flex;align-items:center;gap:8px">'+
        '<div style="flex:1;min-width:0">'+
          '<h3>'+hl(b.name,q)+'</h3>'+
          '<div class="path mono">'+hl(b.path,q)+'</div>'+
        '</div>'+
        '<span class="hpill">'+h.t+'</span>'+
        goLink(b)+
      '</div>'+
      '<div class="spark">'+sparkline(b)+'</div>'+
      '<div class="stats">'+
        '<span>اجرا <b class="num">'+nf(b.runs)+'</b></span>'+
        '<span>خطا <b class="num" style="color:'+(b.errs>0?"var(--err)":"inherit")+'">'+nf(b.errs)+'</b></span>'+
        '<span>زمان <b class="num">'+nf(b.avg)+'</b>م‌ث</span>'+
      '</div>'+
      '<div class="tags">'+ (b.cat? '<span class="tag">'+esc(b.cat)+'</span>':'') + tagsOf(b) +'</div>'+
    '</article>';
  }).join("") + '</div>';
}

var COLS = [
  { k:"name",  t:"نام",        v:function(b,q){ return '<div class="nm"><a class="tlink" href="'+esc(botPage(b))+'" target="_blank" rel="noopener">'+hl(b.name,q)+'</a></div>'; }, s:function(b){return b.name;} },
  { k:"path",  t:"مسیر اجرا",  v:function(b,q){ return '<a class="tlink mono" style="font-size:11px;color:var(--fg3)" href="'+esc(botRun(b))+'" target="_blank" rel="noopener">'+hl(b.path,q)+'</a>'; }, s:function(b){return b.path;} },
  { k:"cat",   t:"دسته",       v:function(b){ return b.cat ? ('<a class="tlink" href="'+esc(catIndex(b.catId))+'" target="_blank" rel="noopener">'+esc(b.cat)+'</a>') : "—"; }, s:function(b){return b.cat;} },
  { k:"runs",  t:"اجرا بازه",  v:function(b){ return '<span class="num">'+nf(b.runs)+'</span>'; }, s:function(b){return b.runs;} },
  { k:"total", t:"اجرای کل",   v:function(b){ return '<span class="num">'+nf(b.total)+'</span>'; }, s:function(b){return b.total;} },
  { k:"errs",  t:"خطا",        v:function(b){ return '<span class="num" style="color:'+(b.errs>0?"var(--err)":"var(--fg3)")+'">'+nf(b.errs)+'</span>'; }, s:function(b){return b.errs;} },
  { k:"avg",   t:"میانگین",    v:function(b){ return '<span class="num">'+nf(b.avg)+'</span>'; }, s:function(b){return b.avg;} },
  { k:"last",  t:"آخرین اجرا", v:function(b){ return '<span style="color:var(--fg3);font-size:11.5px">'+esc(ago(b.lastAgo))+'</span>'; }, s:function(b){return b.lastAgo<0?1e12:b.lastAgo;} },
  { k:"mod",   t:"ویرایش",     v:function(b){ return '<span style="color:var(--fg3);font-size:11.5px">'+esc(ago(b.modAgo))+'</span>'; }, s:function(b){return b.modAgo<0?1e12:b.modAgo;} },
  { k:"state", t:"وضعیت",      v:function(b){ var h=health(b); return '<span class="hpill" style="--h:'+h.c+'">'+h.t+'</span>'; }, s:function(b){return health(b).s;} }
];
function renderTable(list, q){
  if (!list.length) return emptyBox();
  var rows = list.slice();
  if (state.sortCol){
    var c = COLS.filter(function(x){return x.k===state.sortCol;})[0];
    if (c) rows.sort(function(a,b){
      var A=c.s(a), B=c.s(b);
      if (typeof A==="string") return state.sortDir*A.localeCompare(B,"fa");
      return state.sortDir*((A||0)-(B||0));
    });
  }
  return '<div class="panel" style="overflow:auto"><table class="tbl"><thead><tr>'+
    COLS.map(function(c){
      var a = state.sortCol===c.k ? (state.sortDir>0?" ▲":" ▼") : "";
      return '<th data-col="'+c.k+'">'+esc(c.t)+a+'</th>';
    }).join("")+'</tr></thead><tbody>'+
    rows.map(function(b){
      return '<tr data-id="'+b.id+'"'+(b.off?' style="opacity:.55"':'')+'>'+
        COLS.map(function(c){ return '<td>'+c.v(b,q)+'</td>'; }).join("")+'</tr>';
    }).join("")+'</tbody></table></div>';
}

function renderTree(list){
  if (!list.length) return emptyBox();
  var byCat = {}, uncat = [];
  list.forEach(function(b){
    if (!b.catId){ uncat.push(b); return; }
    (byCat[b.catId] = byCat[b.catId] || []).push(b);
  });
  var tops = SECS.filter(function(s){ return s.ref===0; });
  var maxN = Math.max.apply(null, Object.keys(byCat).map(function(k){return byCat[k].length;}).concat([1]));
  var h = '<div class="panel tree">';
  tops.forEach(function(sec){
    var cats = SECS.filter(function(c){ return c.ref===sec.id && byCat[c.id]; });
    if (!cats.length) return;
    var tot = cats.reduce(function(a,c){ return a+byCat[c.id].length; },0);
    h += '<div class="tsec"><h3><span class="dot" style="--c:var(--brand2)"></span>'+esc(sec.name)+
         ' <span style="color:var(--fg3);font-weight:600" class="num">'+tot+'</span><span class="ln"></span>'+
         catGoLink(sec.id, "فهرست بخش «"+sec.name+"»")+'</h3>';
    cats.sort(function(a,b){ return byCat[b.id].length - byCat[a.id].length; });
    cats.forEach(function(c){
      var arr = byCat[c.id];
      var runs = arr.reduce(function(a,b){return a+(b.runs||0);},0);
      var errs = arr.reduce(function(a,b){return a+(b.errs||0);},0);
      h += '<div class="tcat"><button data-cat="'+c.id+'">'+
        '<span style="min-width:120px">'+esc(c.name)+'</span>'+
        '<span class="bar"><i style="width:'+(arr.length/maxN*100).toFixed(1)+'%"></i></span>'+
        '<span class="n num">'+arr.length+' باتی · '+nf(runs)+' اجرا'+(errs?' · <span style="color:var(--err)">'+errs+' خطا</span>':'')+'</span>'+
        catGoLink(c.id, "فهرست دستهٔ «"+c.name+"»")+
        '</button><div class="kids">'+
        arr.map(function(b){
          var hh = health(b);
          return '<span class="mini" data-id="'+b.id+'"><span class="dot" style="--c:'+hh.c+'"></span>'+esc(b.name)+goLink(b)+'</span>';
        }).join("")+'</div></div>';
    });
    h += '</div>';
  });
  if (uncat.length){
    h += '<div class="tsec"><h3><span class="dot" style="--c:var(--fg3)"></span>بدون دسته‌بندی'+
         ' <span style="color:var(--fg3);font-weight:600" class="num">'+uncat.length+'</span><span class="ln"></span></h3>'+
         '<div class="tcat open"><div class="kids">'+
         uncat.map(function(b){
           var hh = health(b);
           return '<span class="mini" data-id="'+b.id+'"><span class="dot" style="--c:'+hh.c+'"></span>'+esc(b.name)+goLink(b)+'</span>';
         }).join("")+'</div></div></div>';
  }
  return h+'</div>';
}

function emptyBox(){
  return '<div class="panel empty">'+
    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><circle cx="11" cy="11" r="7"/><path d="m20 20-3.2-3.2"/></svg>'+
    '<div>هیچ باتی با این شرط پیدا نشد</div></div>';
}

var feedMode = "all";
function renderFeed(){
  var rows = feedMode==="err" ? FEED.filter(function(e){return e.err;}) : FEED;
  var host = document.getElementById("feed");
  if (!rows.length){ host.innerHTML = '<div class="empty">رویدادی ثبت نشده</div>'; return; }
  host.innerHTML = rows.map(function(e){
    var b = byId[e.bid];
    return '<div class="ev'+(e.err?" bad":"")+'" data-id="'+e.bid+'">'+
      '<span class="bd"></span>'+
      '<div class="b"><div class="nm">'+esc(b? b.name : ("باتی #"+e.bid))+'</div>'+
      '<div class="ms">'+ (e.err ? esc(e.msg) : (esc(RT[e.rt]||"") + " · " + ms(e.ms))) +'</div></div>'+
      '<div class="tm"><span class="num">'+esc(e.t)+'</span><br>'+esc(e.d)+'</div>'+
      (b ? goLink(b) : '') + '</div>';
  }).join("");
}
function renderNewest(){
  var list = BOTS.slice().sort(function(a,b){
    var A=a.modAgo<0?1e12:a.modAgo, B=b.modAgo<0?1e12:b.modAgo; return A-B;
  }).slice(0,12);
  document.getElementById("newest").innerHTML = list.map(function(b,i){
    return '<div class="nb" data-id="'+b.id+'">'+
      '<div class="idx num">'+(i+1)+'</div>'+
      '<div class="b"><div class="nm">'+esc(b.name)+'</div>'+
      '<div class="mt">'+esc(b.mod||"—")+' · '+esc(ago(b.modAgo))+'</div></div>'+
      '<span class="hpill" style="--h:'+health(b).c+'">'+health(b).t+'</span>'+
      goLink(b)+'</div>';
  }).join("");
}

var DRAW = document.getElementById("draw"), SCRIM = document.getElementById("scrim"), openId = null;
function openBot(id){
  var b = byId[id]; if (!b) return;
  openId = id;
  var h = health(b);
  document.getElementById("dName").innerHTML =
    '<a class="tlink" href="'+esc(botPage(b))+'" target="_blank" rel="noopener" style="color:inherit;text-decoration:none">'+esc(b.name)+'</a>';
  document.getElementById("dPath").innerHTML =
    '<a class="tlink" href="'+esc(botRun(b))+'" target="_blank" rel="noopener" style="color:inherit">/bot/run/'+esc(b.path)+'</a>';

  var myErrs = ERRS.filter(function(e){ return e.bid===b.id; }).slice(0,8);
  var myFeed = FEED.filter(function(e){ return e.bid===b.id; }).slice(0,10);
  var url = botRun(b);

  var body =
    (b.descr ? '<div style="font-size:12.5px;color:var(--fg2)">'+esc(b.descr)+'</div>' : '') +
    '<div class="tags" style="margin-top:10px">'+
      (b.cat? '<a class="tlink" href="'+esc(catIndex(b.catId))+'" target="_blank" rel="noopener"><span class="tag">'+esc(b.sec)+' › '+esc(b.cat)+'</span></a>':'') +
      tagsOf(b) +'</div>'+
    '<div class="acts">'+
      '<a class="act pri" href="'+esc(botPage(b))+'" target="_blank" rel="noopener">'+
        GO_ICON+' صفحهٔ باتی (منبع و تنظیمات)</a>'+
    '</div>'+
    '<div class="acts">'+
      '<a class="act" href="'+esc(url)+'" target="_blank" rel="noopener">'+
        '<svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="m5 3 14 9-14 9z"/></svg> اجرا</a>'+
      '<a class="act" href="'+esc(botHistory(b))+'" target="_blank" rel="noopener">'+
        '<svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M21 12a9 9 0 1 1-2.6-6.4"/><path d="M21 3v6h-6"/><path d="M12 7v5l3 2"/></svg> تاریخچه</a>'+
      '<a class="act" href="'+esc(botExport(b))+'" target="_blank" rel="noopener">'+
        '<svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3v12"/><path d="m7 10 5 5 5-5"/><path d="M5 21h14"/></svg> خروجی .tybot</a>'+
    '</div>'+
    '<div class="dgrid">'+
      '<div class="dstat"><div class="l">اجرا در بازه</div><div class="v num">'+nf(b.runs)+'</div></div>'+
      '<div class="dstat"><div class="l">خطا در بازه</div><div class="v num" style="color:'+(b.errs?"var(--err)":"inherit")+'">'+nf(b.errs)+'</div></div>'+
      '<div class="dstat"><div class="l">اجرای کل</div><div class="v num">'+nf(b.total)+'</div></div>'+
      '<div class="dstat"><div class="l">میانگین</div><div class="v num">'+nf(b.avg)+'</div></div>'+
      '<div class="dstat"><div class="l">کندترین</div><div class="v num">'+nf(b.max)+'</div></div>'+
      '<div class="dstat"><div class="l">سلامت</div><div class="v" style="color:'+h.c+'">'+h.t+'</div></div>'+
    '</div>'+
    '<div class="dsec">روند '+WIN+' روزهٔ اخیر<span class="ln"></span></div>'+
    '<div style="background:var(--panel);border:1px solid var(--line);border-radius:12px;padding:12px">'+ botChart(b) +'</div>'+
    '<div class="dsec">مشخصات<span class="ln"></span></div>'+
    kv("آخرین اجرا", b.last ? (b.last+" ("+ago(b.lastAgo)+")") : "—") +
    kv("آخرین ویرایش", (b.mod||"—")+" · "+ago(b.modAgo)) +
    kv("نوع خروجی", b.html ? "HTML" : "JSON / متن") +
    kv("حداکثر زمان اجرا", (b.maxexec||0) + " ثانیه") +
    kv("کش", b.cache>0 ? (b.cache+" دقیقه") : "ندارد") +
    kv("نسخه‌ها", b.ver>0 ? b.ver : "بدون نسخه‌بندی") +
    kv("پیشوند دیتابیس", b.dbp || "—") +
    kv("مبدأ", b.srcdom || "بومی") +
    kv("شناسه", "#"+b.id) +
    (myErrs.length ? '<div class="dsec" style="color:var(--err)">خطاهای اخیر<span class="ln"></span></div>'+
      myErrs.map(function(e){
        return '<div class="errline"><i>'+esc(e.d)+' · '+esc(e.t)+' · '+esc(RT[e.rt]||"")+'</i>'+esc(e.msg)+'</div>';
      }).join("") : '') +
    (myFeed.length ? '<div class="dsec">آخرین رویدادها<span class="ln"></span></div>'+
      myFeed.map(function(e){
        return '<div class="ev'+(e.err?" bad":"")+'" style="cursor:default"><span class="bd"></span>'+
          '<div class="b"><div class="nm" style="font-size:11.5px">'+esc(RT[e.rt]||"")+(e.err?" · خطا":" · "+ms(e.ms))+'</div></div>'+
          '<div class="tm"><span class="num">'+esc(e.t)+'</span> '+esc(e.d)+'</div></div>';
      }).join("") : '');

  document.getElementById("dBody").innerHTML = body;
  document.getElementById("dBody").scrollTop = 0;
  DRAW.classList.add("on"); SCRIM.classList.add("on");
}
function kv(k,v){ return '<div class="kv"><span>'+esc(k)+'</span><b>'+esc(v)+'</b></div>'; }
function botChart(b){
  var v = b.spark || Z, e = b.espark || Z;
  var W=440, H=110, n=v.length, m=Math.max.apply(null, v.concat([1])), bw=W/n, ih=H-22, s="";
  for (var i=0;i<n;i++){
    var bh = Math.max(1.5, v[i]/m*ih);
    s += '<rect x="'+(i*bw+bw*0.15).toFixed(2)+'" y="'+(ih-bh+6).toFixed(2)+'" width="'+(bw*0.7).toFixed(2)+
         '" height="'+bh.toFixed(2)+'" rx="1.6" fill="var(--brand)" opacity="'+(0.4+0.6*i/n).toFixed(2)+'"/>';
    if (e[i]>0) s += '<circle cx="'+(i*bw+bw/2).toFixed(1)+'" cy="'+(H-12)+'" r="2.4" fill="var(--err)"/>';
  }
  s += '<text x="2" y="'+(H-1)+'" font-size="9.5" fill="var(--fg3)">'+esc(DAYS[0]?DAYS[0].lbl:"")+'</text>';
  s += '<text x="'+(W-2)+'" y="'+(H-1)+'" text-anchor="end" font-size="9.5" fill="var(--fg3)">'+esc(DAYS[DAYS.length-1]?DAYS[DAYS.length-1].lbl:"")+'</text>';
  return '<svg viewBox="0 0 '+W+' '+H+'" style="width:100%;height:120px;display:block">'+s+'</svg>';
}
function closeDraw(){ DRAW.classList.remove("on"); SCRIM.classList.remove("on"); openId = null; }

function paint(){
  var list = filtered(), q = state.q.trim().toLowerCase();
  var stage = document.getElementById("stage");
  var html = state.view==="table" ? renderTable(list,q)
           : state.view==="tree"  ? renderTree(list)
           : renderCards(list,q);
  stage.innerHTML =
    '<div style="display:flex;align-items:center;margin-bottom:10px">'+
      '<span class="count">'+ (list.length===BOTS.length
          ? ('نمایش همه '+nf(list.length)+' باتی')
          : ('<b style="color:var(--fg)">'+nf(list.length)+'</b> از '+nf(BOTS.length)+' باتی')) +'</span></div>' + html;
}

document.getElementById("q").addEventListener("input", function(e){ state.q = e.target.value; paint(); });
document.getElementById("sort").addEventListener("change", function(e){ state.sort = e.target.value; state.sortCol=null; paint(); });
document.getElementById("views").addEventListener("click", function(e){
  var b = e.target.closest("button[data-v]"); if (!b) return;
  [].forEach.call(this.children, function(x){ x.classList.remove("on"); });
  b.classList.add("on"); state.view = b.dataset.v; paint();
});
document.getElementById("chips").addEventListener("click", function(e){
  var b = e.target.closest("button"); if (!b) return;
  if (b.dataset.flag){ state.flags[b.dataset.flag] = !state.flags[b.dataset.flag]; }
  else if (b.dataset.sec != null){ state.sec = Number(b.dataset.sec); }
  renderChips(); paint();
});
document.getElementById("rangeSeg").addEventListener("click", function(e){
  var b = e.target.closest("button"); if (!b) return;
  [].forEach.call(this.children, function(x){ x.classList.remove("on"); });
  b.classList.add("on"); range = Number(b.dataset.r); renderMain();
});
document.getElementById("feedSeg").addEventListener("click", function(e){
  var b = e.target.closest("button"); if (!b) return;
  [].forEach.call(this.children, function(x){ x.classList.remove("on"); });
  b.classList.add("on"); feedMode = b.dataset.f; renderFeed();
});
document.addEventListener("click", function(e){
  if (e.target.closest("a[href]")) return;
  var cat = e.target.closest("[data-cat]");
  if (cat){ cat.parentNode.classList.toggle("open"); return; }
  var th = e.target.closest("th[data-col]");
  if (th){
    if (state.sortCol===th.dataset.col) state.sortDir = -state.sortDir;
    else { state.sortCol = th.dataset.col; state.sortDir = -1; }
    paint(); return;
  }
  var t = e.target.closest("[data-id]");
  if (t && !e.target.closest(".draw")) openBot(Number(t.dataset.id));
});
document.getElementById("dClose").addEventListener("click", closeDraw);
SCRIM.addEventListener("click", closeDraw);
document.addEventListener("keydown", function(e){
  if (e.key==="Escape"){ closeDraw(); return; }
  if (e.key==="/" && document.activeElement.id!=="q"){
    e.preventDefault(); document.getElementById("q").focus();
  }
});

/* ---------------------------------------------------------------- theme */
var TH = document.getElementById("theme");
function applyTheme(t){
  document.body.classList.toggle("lite", t==="lite");
  document.getElementById("themeTxt").textContent = t==="lite" ? "تاریک" : "روشن";
  try{ localStorage.setItem("bmp.theme", t); }catch(x){}
}
TH.addEventListener("click", function(){
  applyTheme(document.body.classList.contains("lite") ? "dark" : "lite");
});
try{ applyTheme(localStorage.getItem("bmp.theme")==="lite" ? "lite" : "dark"); }catch(x){ applyTheme("dark"); }

function toggleFullScreen(){
  var root = document.getElementById("reportRoot");
  var btn = document.getElementById("btnFullscreen");
  var isFull = document.fullscreenElement || document.webkitFullscreenElement || document.msFullscreenElement;
  if (!isFull){
    if (root.requestFullscreen) root.requestFullscreen();
    else if (root.webkitRequestFullscreen) root.webkitRequestFullscreen();
    else if (root.msRequestFullscreen) root.msRequestFullscreen();
  } else {
    if (document.exitFullscreen) document.exitFullscreen();
    else if (document.webkitExitFullscreen) document.webkitExitFullscreen();
    else if (document.msExitFullscreen) document.msExitFullscreen();
  }
}
document.addEventListener("fullscreenchange", syncFsBtn);
document.addEventListener("webkitfullscreenchange", syncFsBtn);
function syncFsBtn(){
  var isFull = document.fullscreenElement || document.webkitFullscreenElement || document.msFullscreenElement;
  var btn = document.getElementById("btnFullscreen");
  btn.lastChild.textContent = isFull ? " خروج از تمام صفحه" : " تمام صفحه";
}

var t0 = Date.now();
function tick(){
  document.getElementById("ck").textContent = D.genAt || "";
  var s = Math.floor((Date.now()-t0)/1000);
  document.getElementById("ckd").textContent = s>60 ? "داده " + ago(s) : "هم‌اکنون";
}
setInterval(tick, 15000); tick();

document.getElementById("brandMeta").textContent =
  nf(K.total) + " باتی · بازهٔ " + nf(K.period_days||30) + " روزه";
document.getElementById("foot").textContent =
  "داده‌ها از bot_command و bot_history · محور روزانه " + WIN + " روزه · ساخته‌شده در " + (D.genAt||"");

/* پیش‌انتخاب از querystring (bot_ids) */
(function initSelection(){
  var selBots = arr(D.selectedBots);
  if (selBots.length){
    var set = {}; selBots.forEach(function(id){ set[id]=1; });
    var only = arr(D.bots).filter(function(b){ return set[b.id]; });
    if (only.length){
      document.getElementById("stage").innerHTML = renderCards(only, "");
    }
  }
})();

renderKpis(); renderMain(); renderHours(); renderKinds();
renderChips(); paint(); renderFeed(); renderNewest();
})();
</script>
</body>
</html>]==]

local ok_write, page_err = pcall(function()
    teamyar.write_result(HEAD .. encoded .. TAIL)
end)

if not ok_write then
    teamyar.write_log("bot_module_performance_report failed at write_result: " .. tostring(page_err))
    teamyar.write_result([[
<!DOCTYPE html>
<html dir="rtl" lang="fa">
<head><meta charset="UTF-8"><title>خطا</title></head>
<body style="font-family:Tahoma,sans-serif;background:#0b1020;color:#e8edff;padding:40px;text-align:center;">
<h2 style="color:#fb7185;">خطا در تولید گزارش</h2>
<p style="color:#8b97b8;font-size:13px;">جزئیات در لاگ باتی ثبت شد.</p>
</body></html>
]])
end
