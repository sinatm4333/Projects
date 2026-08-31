-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/06/09 20:05
--
-- بات زندهٔ 294 «Bot Higher Profit Dealer» (run/2/m_higher_profit) — نام قدیمی‌اش مانده ولی
-- محتوایش ویجت «تردد دورکاری امروز» است. مسیر JSON (ctype=3) دست‌نخورده است.
--
-- مسیر قالب ویجت (write_widget_template) بازنویسی شد: دیگر از res_bot (2/res_bot) عبور
-- نمی‌کند. علت: پلتفرم Teamyar هنگام embed کردن نتیجهٔ یک ویجت داخل صفحهٔ داشبورد
-- (`/home/index`) آن را به‌صورت رشتهٔ JS داخل یک <script> inline قرار می‌دهد و دنبالهٔ
-- </script> را escape نمی‌کند؛ چون خروجی res_bot همیشه چند </script> واقعی دارد (تگ‌های
-- main.js/xlsx.full.min.js/botTPL/botTplhtml)، اولین </script> باعث بسته‌شدن زودهنگام
-- <script> بیرونی صفحه و کرش جاوااسکریپت («Unexpected token 'var'») می‌شود — تأییدشده زنده
-- روی بات‌های 199 و 294 با بازتولید کامل (jQuery + 000_top.js + teamyar.js واقعی). این باگ
-- در هستهٔ کامپایل‌شدهٔ پلتفرم است، نه در res_bot/بات‌های Lua، و از پنل/دیتابیس قابل اصلاح
-- نیست. راه‌حل این بات: محاسبات وضعیت/ساعت که قبلاً سمت کلاینت (main.js پیوست) با جاوااسکریپت
-- انجام می‌شد، به سرور (Lua) منتقل شد و خروجی HTML ایستا و بدون هیچ تگ <script> برگردانده
-- می‌شود — چون هیچ </script>ای در خروجی نیست، از مسیر باگ‌دار پلتفرم عبور نمی‌کند.
-- پیوست‌های main.js/main.css/Persian.js/English.js دیگر استفاده نمی‌شوند (می‌توانند بمانند،
-- بی‌ضررند).

local TZ_OFFSET_TICKS = 126000000000 -- ‏+3:30؛ زمان‌های درون‌روزی HR سه‌ساعت‌ونیم عقب‌تر از زمان محلی ذخیره می‌شوند (تاییدشدهٔ زنده روی بات 624)
local TICKS_PER_MINUTE = 60 * 10000000

local input = teamyar.get_input()
local ctype = tonumber(input and input.type)
local uinfo = teamyar.get_user_info()
local user_id = tonumber(uinfo and uinfo.id) or 0

local now = time.current()
local year = time.get_year(now)
local month = time.get_month(now)
local day = time.get_day(now)
local hour = time.get_hour(now)
local min = time.get_minute(now)
local sec = time.get_second(now)

local currentdate_time = time.get_filetime([[{"year":]] .. year .. [[,"month":]] .. month ..
    [[,"day":]] .. day .. [[,"hour":]] .. hour .. [[,"minute":]] .. min .. [[,"second":]] .. sec .. [[}]])
local day_start = time.get_filetime([[{"year":]] .. year .. [[,"month":]] .. month ..
    [[,"day":]] .. day .. [[,"hour":0,"minute":0,"second":0}]])

local function get_query_first_row(query, query_params)
    db.use_db("0000000")
    db.query({ query = query, params = query_params })
    local rows = db.query_fetch()
    db.query_free()
    return rows and rows[1] or nil
end

local function shifted_time_sql(column)
    return "CASE WHEN COALESCE(" .. column .. ", 0) = 0 THEN 0 ELSE " ..
        column .. " + " .. TZ_OFFSET_TICKS .. " END"
end

local function fetch_today_telework_data()
    local telework_query = [[
SELECT COALESCE(
    JSON_ARRAYAGG(JSON_OBJECT('personnel_id', personnel_id, 'timef', timef, 'timet', timet)),
    JSON_ARRAY()
) AS result
FROM (
    SELECT
        p.PERSONNEL_ID AS personnel_id,
        ]] .. shifted_time_sql("e.TIME_FROM") .. [[ AS timef,
        ]] .. shifted_time_sql("e.TIME_TO") .. [[ AS timet
    FROM hr_personnels p
    INNER JOIN hr_ext_time e ON e.PERSONNEL_ID = p.PERSONNEL_ID
    WHERE e.not_telework = 0
      AND p.PROFILE_ID = ?
      AND e.EXT_DATE = ?
    ORDER BY e.TIME_FROM
) tmp
]]
    local session_query =
        "SELECT COALESCE(MAX(s.last_activity), 0) AS last_activity FROM admin_view_session s WHERE s.user_id = ?"

    local telework_row = get_query_first_row(telework_query, { user_id, day_start })
    local session_row = get_query_first_row(session_query, { user_id })

    -- get_query_first_row برای کوئری تک‌ستونی مقدار را مستقیم (نه در آرایه) برمی‌گرداند
    local data_json = telework_row or "[]"
    local last_act = tonumber(session_row) or 0

    return data_json, last_act
end

-- قرارداد خروجی JSON (ctype=3) عمداً دست‌نخورده مانده: data همان رشتهٔ JSON خام است، نه
-- جدول decode‌شده — main.js قدیمی خودش JSON.parse می‌کند. فقط ویجت جدید (write_widget_template)
-- برای محاسبه به جدول decode‌شده نیاز دارد.
local function write_today_telework_json()
    local data_json, last_act = fetch_today_telework_data()
    local listdata = {
        data = data_json,
        cur_date = currentdate_time,
        last_act = last_act
    }
    teamyar.write_result(json.encode(listdata))
end

local function escape_html(value)
    if value == nil then return "" end
    local amp_entity = "&" .. "amp;"
    local lt_entity = "&" .. "lt;"
    local gt_entity = "&" .. "gt;"
    local quot_entity = "&" .. "quot;"
    local apos_entity = "&" .. "#39;"
    return tostring(value)
        :gsub("&", amp_entity)
        :gsub("<", lt_entity)
        :gsub(">", gt_entity)
        :gsub('"', quot_entity)
        :gsub("'", apos_entity)
end

-- تبدیل شمسی — پیاده‌سازی خالص Lua (بدون وابستگی به REPORT_FN_JDATE که روی این DB با
-- «sql error» شکست می‌خورد؛ همان الگوریتم reuse‌شده از crm_customer_ui_bot.lua)
local function floor_div(a, b) return math.floor(a / b) end

local function civil_from_days(z)
    z = z + 719468
    local era = floor_div(z, 146097)
    local doe = z - era * 146097
    local yoe = floor_div(doe - floor_div(doe, 1460) + floor_div(doe, 36524) - floor_div(doe, 146096), 365)
    local y = yoe + era * 400
    local doy = doe - (365 * yoe + floor_div(yoe, 4) - floor_div(yoe, 100))
    local mp = floor_div(5 * doy + 2, 153)
    local d = doy - floor_div(153 * mp + 2, 5) + 1
    local m = mp + (mp < 10 and 3 or -9)
    if m <= 2 then y = y + 1 end
    return y, m, d
end

local G_D_M = { 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334 }

local function gregorian_to_jalali(gy, gm, gd)
    local jy
    if gy <= 1600 then
        jy = 0
        gy = gy - 621
    else
        jy = 979
        gy = gy - 1600
    end
    local gy2 = (gm > 2) and (gy + 1) or gy
    local days = 365 * gy + floor_div(gy2 + 3, 4) - floor_div(gy2 + 99, 100)
        + floor_div(gy2 + 399, 400) - 80 + gd + G_D_M[gm]
    jy = jy + 33 * floor_div(days, 12053)
    days = days % 12053
    jy = jy + 4 * floor_div(days, 1461)
    days = days % 1461
    if days > 365 then
        jy = jy + floor_div(days - 1, 365)
        days = (days - 1) % 365
    end
    local jm, jd
    if days < 186 then
        jm = 1 + floor_div(days, 31)
        jd = 1 + (days % 31)
    else
        jm = 7 + floor_div(days - 186, 30)
        jd = 1 + ((days - 186) % 30)
    end
    return jy, jm, jd
end

local function format_filetime(ft)
    ft = tonumber(ft) or 0
    if ft <= 0 then return "--" end
    local unixtime = floor_div(ft, 10000000) - 11644473600
    if unixtime < 0 then return "--" end
    local days = floor_div(unixtime, 86400)
    local gy, gm, gd = civil_from_days(days)
    local jy, jm, jd = gregorian_to_jalali(gy, gm, gd)
    local secs_in_day = unixtime % 86400
    return string.format("%04d/%02d/%02d %02d:%02d", jy, jm, jd,
        floor_div(secs_in_day, 3600), floor_div(secs_in_day % 3600, 60))
end

-- منطق وضعیت/محاسبهٔ ساعات معادل main.js قدیمی (hdp_loadData)، منتقل‌شده به سرور
local function compute_status(data, last_act)
    local len = #data
    local min_in, max_out, sum_en, kind_status = 0, 0, 0, 0

    if len > 0 then
        min_in = tonumber(data[1].timef) or 0
        max_out = tonumber(data[len].timet) or 0

        for i = 1, len do
            local timef = tonumber(data[i].timef) or 0
            local timet = tonumber(data[i].timet) or 0
            sum_en = sum_en + math.ceil((timet - timef) / TICKS_PER_MINUTE)
            if currentdate_time >= timef and currentdate_time <= timet then
                kind_status = 2
            elseif kind_status ~= 2 then
                kind_status = 0
            end
        end

        local last_timef = tonumber(data[len].timef) or 0
        local last_timet = tonumber(data[len].timet) or 0
        if last_timet == last_timef then
            max_out = 0
            sum_en = sum_en + math.ceil((currentdate_time - last_timef) / TICKS_PER_MINUTE)
            kind_status = 2
        end
    end

    local dif_act = math.ceil((currentdate_time - last_act) / TICKS_PER_MINUTE)
    if dif_act > 60 and kind_status == 2 then
        kind_status = 1
    end

    return {
        min_in = min_in,
        max_out = max_out,
        sum_en = sum_en,
        dif_act = dif_act,
        kind_status = kind_status
    }
end

local function write_widget_template()
    local data_json, last_act = fetch_today_telework_data()
    local ok, decoded = pcall(json.decode, data_json)
    local data = (ok and decoded) or {}
    local s = compute_status(data, last_act)

    local str_status, circle_color
    if s.kind_status == 1 then
        str_status = "غیر فعال"
        circle_color = "orange"
    elseif s.kind_status == 2 then
        str_status = "فعال"
        circle_color = "green"
    else
        str_status = "خروج از سیستم"
        circle_color = "red"
    end

    local hw = math.max(math.floor(s.sum_en / 60), 0)
    local sw = math.max(s.sum_en % 60, 0)
    local hr = math.max(math.floor(s.dif_act / 60), 0)
    local sr = math.max(s.dif_act % 60, 0)

    -- "ساعت و دقیقه" با برچسب صریح — نه فقط "NN:NN"، چون داخل صفحهٔ RTL بدون dir صریح،
    -- ترتیب دو عدد کنار هم می‌تواند در نمایش با bidi جابه‌جا به‌نظر برسد
    local function fmt_duration(hours, minutes)
        return string.format("%d ساعت و %d دقیقه", hours, minutes)
    end
    local work_duration = fmt_duration(hw, sw)
    local rest_duration = fmt_duration(hr, sr)

    local finput = format_filetime(s.min_in)
    local lout = format_filetime(s.max_out)

    local html = [[
<div style="text-align:center;font-family:Tahoma,IRANSansWeb,sans-serif;padding:15px 10px;">
  <img src="/home/users/photo/]] .. escape_html(user_id) .. [[?large=1"
       style="border-radius:50%;width:64px;height:64px;object-fit:cover;" alt="">
  <div style="display:inline-block;border:3px solid gray;border-radius:6px;padding:10px 15px;font-size:15px;font-weight:bold;margin:12px 0;">
    وضعیت : ]] .. escape_html(str_status) .. [[
    <span style="display:inline-block;width:14px;height:14px;border-radius:50%;background-color:]] ..
        circle_color .. [[;margin:0 8px;"></span>
  </div>
  <div style="font-weight:bold;font-size:14px;margin:4px;">مدت زمان کار : ]] .. escape_html(work_duration) .. [[</div>
  <div style="font-weight:bold;font-size:14px;margin:4px;">زمان استراحت : ]] .. escape_html(rest_duration) .. [[</div>
  <div style="font-weight:bold;font-size:14px;margin:4px;">اولین ورود : ]] .. escape_html(finput) .. [[</div>
  <div style="font-weight:bold;font-size:14px;margin:4px;">آخرین خروج : ]] .. escape_html(lout) .. [[</div>
</div>
]]
    teamyar.write_result(html)
end

if ctype == 3 then
    local ok, err = pcall(write_today_telework_json)
    if not ok then
        teamyar.write_log("m_higher_profit telework widget error: " .. tostring(err))
        teamyar.write_result(json.encode({ ok = false, error = "خطا در دریافت اطلاعات تردد دورکاری امروز" }))
    end
else
    local ok, err = pcall(write_widget_template)
    if not ok then
        teamyar.write_log("m_higher_profit widget template error: " .. tostring(err))
        teamyar.write_result("<div>خطا در بارگذاری ویجت تردد دورکاری</div>")
    end
end
