-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/06/07 15:13

-- botName = hr_companion
-- description = همراه ۱۴۰ — پنل پرسنلی (تردد و کارکرد، درخواست‌ها، اطلاعات پرسنلی، همراهِ روز و تولدها)
-- version = 1
--
-- این بات نسخهٔ «دادهٔ واقعی» از پنل پرسنلی HTML نمونهٔ کاربر (hrcompanionv01.html) است. ساختار
-- سایدبار/تب‌ها/کارت‌ها از همان نمونه بازسازی شده، ولی طبق قوانین اجباری این ریپو پالت رنگ فقط
-- #16509D (نه سبز/لیمویی نمونه)، فونت Peyda embedded و لوگوی برند ۱۴۰ در هدر است.
--
-- تفاوت بنیادی با نمونه: در نمونه همهٔ اعداد hardcode بود («داده نمونه»). اینجا هر عدد از جدول واقعی
-- خوانده می‌شود و هر جا منبع دادهٔ تاییدشده نداشتیم، اصلاً نمایش داده نمی‌شود (نه عدد حدسی، نه
-- placeholder). مواردی که عمداً حذف شدند و دلیلشان در «محدودیت‌های شناخته‌شده» پایین آمده است.
--
-- منابع داده (همگی جدول واقعی schema 0000000، الگوی JOIN از بات‌های HR موجود cat_id=57 و از
-- hr_dashboard_report_bot.lua این ریپو کپی/تایید شده):
--   hr_personnels / hr_personnel_order  → هویت پرسنل، واحد، سرپرست، تقویم کاری، موظفی، سقف مرخصی
--   hr_work_time                        → کارکرد روزانه (FIRST_IN/LAST_OUT/TOTAL_WORK/OVER_TIME/ABSENCE)
--   hr_day_details                      → شیفت واقعی همان روز (ساعت شروع/پایان و موظفی روز)
--   hr_ext_time                         → رویدادهای تردد (بازه‌های ثبت‌شده، دستگاه مبدأ/مقصد)
--   hr_machine                          → نام دستگاه تردد
--   hr_vacation + hr_vacation_type      → درخواست مرخصی/ماموریت (روزانه و ساعتی)
--   hr_leave_verify                     → زنجیرهٔ تایید هر درخواست مرخصی/ماموریت
--   hr_overtime_request                 → درخواست اضافه‌کاری
--   hr_telework_request                 → درخواست دورکاری
--   hr_leave_remained_records           → مانده مرخصی (آخرین دورهٔ محاسبه‌شده)
--   profile_main / profile_user_info    → نام، جنسیت، تاریخ تولد
--   hr_education                        → آخرین مدرک تحصیلی
--   org_organization_unit / org_units   → نام واحد سازمانی
--   report_dimdate                      → تبدیل تاریخ شمسی (JNDATE/JTDAY/JMONTH/JMDAY/JYDAY)
--   hr_birth_setting                    → تنظیم تبریک تولد سازمان (فعال بودن پاپ‌آپ/پیامک/ایمیل)
--   todo_task / todo_task_steps / todo_task_comments → «گفتگوی تبریک تولد» (پایین را ببینید)
--
-- «گفتگوی تبریک» چطور کار می‌کند (create-or-join، بدون هیچ INSERT مستقیم روی جداول هسته):
--   هیچ بات این ریپو مستقیماً روی جداول Teamyar نمی‌نویسد و این بات هم نمی‌نویسد. نوشتن فقط از راه
--   API رسمی داخلی انجام می‌شود (teamyar.call_api ماژول ۹ = گفتگو):
--     ۱) عنوان گفتگو قطعی (deterministic) ساخته می‌شود: «تبریک تولد <نام> — <تاریخ شمسی>»
--     ۲) با یک SELECT روی chat_dialogs.TOPIC دنبال همان عنوان می‌گردیم (تطبیق دقیق با =، نه LIKE —
--        طبق باگ تاییدشدهٔ پلتفرم، LIKE پارامتری روی این لایه db.query کار نمی‌کند)
--     ۳) اگر گفتگو نبود → با /api/dialog/add ساخته می‌شود (شناسهٔ گروه از bot_config یا /api/group/get)
--     ۴) کاربر با /api/assign/add به همان گفتگو اضافه («جوین») می‌شود
--   تبریک‌ها بعد از آن داخل خودِ ماژول گفتگو نوشته می‌شوند و این پنل فقط آن‌ها را از chat_message
--   می‌خواند و نمایش می‌دهد. یعنی همه در یک گفتگوی مشترک جمع می‌شوند، نه چند گفتگوی جدا.
--
--   ⚠️ schema درخواست این سه endpoint در TeamyarInternalApiReference.md موجود نیست. نام فیلدهای
--   payload بر پایهٔ ستون‌های تاییدشدهٔ chat_dialogs/chat_dialog_view نوشته شده و باید با schema
--   واقعی تطبیق داده شود؛ هر سه payload عمداً در یک جا جمع شده‌اند و پاسخ خام API در خروجی JSON
--   برمی‌گردد تا در اولین اجرای واقعی دیده و اصلاح شود.
--
--   مسیر فراخوانی: تابع call_teamyar_api. اگر api_caller_path در bot_config تنظیم شده باشد، همهٔ
--   فراخوانی‌ها از بات عمومی api_caller_json_bot.lua رد می‌شوند (همان الگوی call_api_1_bot.lua:
--   teamyar.call_api(module_id, url, params) با کنترل secret-key و allowlist)؛ وگرنه مستقیم
--   teamyar.call_api صدا زده می‌شود. bot_config برای حالت اول:
--     { "api_caller_path": "443/api_caller", "api_caller_secret": "...", "celebration_group_id": 3 }
--
-- هویت کاربر: خروجی همیشه مربوط به همان کاربری است که بات را اجرا کرده. هیچ ورودی
-- personnel_id/profile_id پذیرفته نمی‌شود تا کسی نتواند با عوض کردن یک عدد، کارکرد و مرخصی و
-- اطلاعات پرسنلی دیگران را ببیند.
--
-- پیام روز: جدول DAILY_MESSAGES دقیقاً ۳۶۶ پیام دارد و با روزِ سالِ شمسی (report_dimdate.JYDAY)
-- اندیس می‌شود؛ پس هر روزِ سال پیام یکتای خودش را دارد و تا پایان سال هیچ پیامی تکرار نمی‌شود.
--
-- محدودیت‌های شناخته‌شده (عمداً پیاده نشده — منبع دادهٔ تاییدشده نداشتند، نه کارت خالی و نه عدد حدسی):
--   - «تردد ناموفق / عدم تطبیق اثر انگشت» نمونه: hr_machine_requests جدول درخواست‌های همگام‌سازی
--     دستگاه است، نه لاگ تلاش ناموفق هر نفر. رویدادهای تردد از hr_ext_time نمایش داده می‌شوند
--     (بازه‌های واقعی + دستگاه)، بدون برچسب «موفق/ناموفق» ساختگی.
--   - ثبت درخواست جدید (فرم نمونه): این بات فقط خواندنی است. ثبت مرخصی/ماموریت باید از فرم رسمی
--     ماژول منابع انسانی انجام شود؛ ساختن رکورد hr_vacation از بات، گردش تایید (hr_leave_verify /
--     hr_hierarchial_confirm) را دور می‌زند و نباید انجام شود.
--   - فیش حقوقی: عمداً در این پنل نیست. hr_payslip دادهٔ حساس است و نمایش آن نیازمند کنترل دسترسی
--     سطح‌فیلد است که در لایهٔ بات وجود ندارد.
--   - hr_personnel_order.WORKING_HOURS و LEAVE_PER_MONTH: واحد ذخیره‌سازی این دو ستون تایید نشده
--     (tick یا ساعت یا دقیقه؟) و نمایش آن‌ها به‌صورت ساعت می‌توانست عدد بی‌معنی بدهد، پس از رابط
--     کاربری حذف شدند. جای آن‌ها «موظفی محاسبه‌شدهٔ بازه» نشسته که از خودِ تقویم کاری
--     (hr_day_details.TIME_FROM/TIME_TO) درمی‌آید و واحدش قطعی است. هر دو ستون هنوز در خروجی
--     format=json هستند تا هر وقت واحدشان روی دادهٔ زنده تایید شد، بشود به UI برشان گرداند.
--
-- نکتهٔ استنتاجی (نه تاییدشده روی دادهٔ زنده): واحد hr_leave_remained_records.LEAVE_REMAINED مثل
-- بقیهٔ مدت‌های این اسکیما tick فرض شده است. چون منبع جایگزینی برای «مانده مرخصی» وجود ندارد،
-- نمایش داده می‌شود ولی در اولین اجرای واقعی باید با پنل رسمی منابع انسانی مقایسه شود.

local input = teamyar.get_input() or {}

-- ── helpers ──────────────────────────────────────────────────────────

-- طبق قانون canonical این ریپو (تایید‌شده زنده ۱۴۰۵/۰۵/۲۳): رشتهٔ پیوستهٔ literal یک entity هنگام
-- ذخیرهٔ command توسط سرور Teamyar خطا می‌دهد/decode می‌شود. هر entity با پیوند رشته ساخته می‌شود.
local HTML_AMP = "&" .. "amp;"
local HTML_LT = "&" .. "lt;"
local HTML_GT = "&" .. "gt;"
local HTML_QUOT = "&" .. "quot;"
local HTML_APOS = "&" .. "#39;"

-- پرانتزِ دور کل زنجیره عمدی است: gsub دو مقدار برمی‌گرداند (رشته و تعداد جایگزینی) و بدون این
-- پرانتز، escape_html هم دو مقدار برمی‌گرداند. آن‌وقت table.insert(t, escape_html(x)) با خطای
-- "number expected, got string" کرش می‌کند و در هر table constructor یک عضو اضافه می‌سازد.
local function escape_html(value)
    if value == nil then return "" end
    return (tostring(value)
        :gsub("&", HTML_AMP)
        :gsub("<", HTML_LT)
        :gsub(">", HTML_GT)
        :gsub('"', HTML_QUOT)
        :gsub("'", HTML_APOS))
end

local function js_str(value)
    local s = tostring(value or "")
    return (s:gsub("\\", "\\\\"):gsub("'", "\\'"):gsub("\n", " "):gsub("\r", ""))
end

local function fmt_num(value)
    local n = tonumber(value)
    if n == nil then return "0" end
    local neg = n < 0
    n = math.abs(n)
    -- %.0f به‌جای tostring: tostring روی عدد بزرگ نماد علمی می‌دهد («1e+15») که گروه‌بندی را خراب می‌کند
    local s = string.format("%.0f", n)
    local grouped = s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    return (neg and "-" or "") .. grouped
end

local function fmt_decimal(value, decimals)
    local n = tonumber(value)
    if n == nil then return "0" end
    return string.format("%." .. (decimals or 1) .. "f", n)
end

-- مدت‌زمان‌های HR در این پلتفرم بر حسب tick (۱۰۰ نانوثانیه) ذخیره می‌شوند؛ همان تبدیلی که
-- hr_dashboard_report_bot.lua برای ABSENCE/FINAL_ABSENCE استفاده می‌کند: /10000000 → ثانیه
local function minutes_to_hm(minutes)
    local m = tonumber(minutes)
    if m == nil then return "—" end
    if m < 0 then m = 0 end
    m = math.floor(m + 0.5)
    return string.format("%02d:%02d", math.floor(m / 60), m % 60)
end

-- واحد tick برای hr_work_time.TOTAL_WORK با دادهٔ زنده تایید شد (۱۴۰۵/۰۶/۰۷: مقادیر خام
-- ۲۱۶۰۰۰۰۰۰۰۰۰ و ۱۴۲۸۰۰۰۰۰۰۰۰ دقیقاً ۶٫۰۰ و ۳٫۹۷ ساعت شدند). ستون‌های مدت‌دارِ جدول احکام
-- جداگانه تایید نشده‌اند، فقط هم‌خانواده‌اند. برای اینکه یک واحدِ متفاوت هرگز به‌شکل «عددی
-- باورپذیر ولی غلط» جلوی کارمند ننشیند، هر کدام یک سقف منطقی دارد: بیرون از بازه → «—».
local function plausible_minutes(minutes, max_minutes)
    local m = tonumber(minutes)
    if m == nil or m <= 0 or m > max_minutes then return nil end
    return m
end

local function minutes_to_hm_or_dash(minutes)
    local m = tonumber(minutes)
    if m == nil or m <= 0 then return "—" end
    return minutes_to_hm(m)
end

-- حرف اول نام و نام خانوادگی برای آواتار متنی (به‌جای تکرار لوگوی برند برای هر نفر)
local function name_initials(full_name)
    local parts = {}
    for word in tostring(full_name or ""):gmatch("%S+") do
        table.insert(parts, word)
        if #parts == 2 then break end
    end
    if #parts == 0 then return "؟" end
    local letters = {}
    for _, word in ipairs(parts) do
        -- حروف فارسی چندبایتی‌اند؛ اولین کاراکتر UTF-8 برداشته می‌شود، نه اولین بایت
        -- بدون %z نوشته شده: %z در Lua 5.2 حذف شد و نسخهٔ Lua این پلتفرم معلوم نیست.
        -- بایت صفر هم در نام نمی‌آید، پس بازهٔ \1-\127 کافی است.
        local first = word:match("^[\1-\127\194-\244][\128-\191]*") or word:sub(1, 1)
        table.insert(letters, first)
    end
    return table.concat(letters, " ")
end

-- column_count اجباری است و عمدی: نسخهٔ قبلی طول هر ردیف را با #record می‌گرفت، ولی اگر درایور
-- برای یک ستون NULL مقدار nil بگذارد، جدول «سوراخ» می‌شود و طول #record در Lua تعریف‌نشده است —
-- یعنی یک NULL وسط SELECT می‌توانست ردیف را ببُرد و همهٔ ستون‌های بعدی را یک خانه جابه‌جا کند.
-- با شمارش صریح ستون‌ها، هر ردیف همیشه دقیقاً به همان اندازه‌ای خوانده می‌شود که کوئری دارد.
-- علاوه بر این، هر عبارت nullable در کوئری‌های این بات با COALESCE به رشتهٔ خالی تبدیل شده است.
local function fetch_rows(query, params, column_count)
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
        local width = column_count or #record
        for i = 1, width do row[i] = record[i] end
        table.insert(rows, row)
    end
    db.query_free()
    return rows
end

-- ⚠️ REPORT_FN_JDATE همیشه با جداکنندهٔ '-' صدا زده می‌شود، هرگز '/'.
-- تاییدشده روی سرور زنده (بات ۶۲۲، گام ۶ حالت sqlprobe): شکل '/' با «sql error» رد می‌شود، در
-- حالی که همهٔ بات‌های مستقر و سالم این ریپو شکل '-' را استفاده می‌کنند و این بات تنها جایی بود
-- که '/' داشت. با هشدار CLAUDE.md هم می‌خواند: ذخیرهٔ command گاهی کاراکتر اسلش را خراب می‌کند.
-- نمایش فارسی همچنان با اسلش است؛ تبدیل در همین‌جا انجام می‌شود، نه در SQL.
local function jalali_date(value)
    if value == nil then return nil end
    local text = tostring(value)
    if text == "" then return nil end
    return (text:gsub("%-", "/"))
end

-- ثانیهٔ روز → HH:MM. مقدار صفر/منفی یعنی «ثبت نشده» و nil برمی‌گرداند.
local function seconds_to_hm(value)
    local sec = tonumber(value)
    if sec == nil or sec <= 0 then return nil end
    sec = math.floor(sec)
    local h = math.floor(sec / 3600) % 24
    local m = math.floor((sec % 3600) / 60)
    return string.format("%02d:%02d", h, m)
end

-- ستون‌های متنی این بات با COALESCE هرگز NULL نمی‌شوند؛ رشتهٔ خالی یعنی «مقدار ندارد»
local function blank_to_nil(value)
    if value == nil then return nil end
    local text = tostring(value)
    if text == "" then return nil end
    return text
end

local FT_DAY = 864000000000 -- 86400 * 10000000

-- ⚠️ «امروز» از خود دیتابیس گرفته می‌شود، نه از محاسبهٔ Lua روی FILETIME. این همان الگویی است که
-- بات ۶۰۹ (مستقر و سالم) استفاده می‌کند. روی بات ۶۲۲ دیده شد که مقدار محاسبه‌شده در Lua به رکورد
-- report_dimdate نمی‌خورد (تاریخ صفحه «—» می‌شد و پیام روز به آخرین روز سال می‌افتاد).
-- محاسبهٔ Lua فقط به‌عنوان آخرین fallback باقی مانده است.
local function today_filetime()
    local rows = fetch_rows(
        "SELECT ((UNIX_TIMESTAMP() + 11644473600) * 10000000) " ..
        "- MOD((UNIX_TIMESTAMP() + 11644473600) * 10000000, 864000000000) AS today_key", {}, 1)
    if rows ~= nil and #rows > 0 then
        local value = tonumber(rows[1][1])
        if value ~= nil and value > 0 then return value end
    end
    local ok, fallback = pcall(function()
        local now = time.current()
        local ft = time.get_filetime(string.format(
            '{"year":%d,"month":%d,"day":%d,"hour":0,"minute":0,"second":0}',
            time.get_year(now), time.get_month(now), time.get_day(now)))
        return tonumber(string.format("%18.0f", ft))
    end)
    if ok and tonumber(fallback) ~= nil then return tonumber(fallback) end
    return 0
end

-- ساعتِ روز از یک ستون FILETIME یا tick-since-midnight، بدون فرض دربارهٔ این‌که کدام‌یک است:
-- MOD(col, ticks_of_day) برای FILETIME کامل «ساعت همان روز» را می‌دهد و برای مقدار درون‌روزی
-- خودِ مقدار را دست‌نخورده برمی‌گرداند. پس هر دو حالت درست رندر می‌شوند.
-- ⚠️ ساعتِ روز در SQL قالب‌بندی نمی‌شود؛ فقط «ثانیه از ابتدای روز» برگردانده می‌شود و خودِ Lua
-- آن را به HH:MM تبدیل می‌کند. علتش تجربهٔ زندهٔ بات ۶۲۲ است: هر کوئری‌ای که
-- TIME_FORMAT(SEC_TO_TIME(...)) داشت با «sql error» رد شد و هر کوئری‌ای که نداشت کار کرد. هیچ
-- باتِ مستقر و سالمی در این ریپو از این دو تابع استفاده نمی‌کند. در مقابل، MOD و FLOOR حساب
-- ساده‌اند و در بات ۶۰۹ (مستقر و سالم) استفاده شده‌اند.
local function sql_seconds_of_day(col)
    return "FLOOR(MOD(COALESCE(" .. col .. ", 0), 864000000000) / 10000000)"
end

-- ⚠️ تاریخ‌ها هرگز به‌عنوان پارامتر «?» فرستاده نمی‌شوند (تاییدشده روی سرور زنده ۱۴۰۵/۰۶/۰۷).
-- FILETIME یک عدد ۱۸ رقمی است (مثل 133700000000000000) و لایهٔ db.query این پلتفرم نمی‌تواند
-- عددی با این اندازه را bind کند: کوئری با همان خطای عمومی «sql error» رد می‌شود، دقیقاً مثل باگ
-- تاییدشدهٔ «LIKE ?». روی بات ۶۲۲ همبستگی کامل دیده شد: هر کوئری که تاریخ پارامتری داشت شکست و هر
-- کوئری که نداشت کار کرد. همهٔ بات‌های مستقر و سالم این ریپو هم تاریخ را داخل خود SQL می‌سازند
-- (الگوی (UNIX_TIMESTAMP() + 11644473600) * 10000000).
-- این کار امن است چون مقدار هرگز رشتهٔ کاربر نیست: یا از time.get_filetime می‌آید یا از ورودی‌ای
-- که قبلش با tonumber و بازهٔ معتبر اعتبارسنجی شده. خروجی همیشه فقط رقم است.
-- خروجی عمداً با فاصله در دو طرف پد می‌شود. Lua اولین newline بعد از [[ را حذف می‌کند، پس بدون
-- این فاصله عدد به کلمهٔ بعدی می‌چسبید و «...000000ORDER BY» می‌شد — یک sql error دیگر.
local function sql_filetime(value)
    local n = tonumber(value)
    if n == nil or n ~= n or n < 0 then n = 0 end
    return " " .. string.format("%.0f", n) .. " "
end

local function sql_ticks_to_minutes(col)
    return "ROUND(COALESCE(" .. col .. ", 0) / 10000000 / 60, 0)"
end

-- صفحهٔ خطای تمیز فارسی — به‌جای اینکه کاربر یک traceback خام Lua ببیند
local function render_error_page(message, detail)
    local body = '<p style="font-size:15px;">' .. escape_html(message) .. '</p>'
    if detail ~= nil and tostring(detail) ~= "" then
        body = body .. '<p style="font-size:14px;color:#666;overflow-wrap:anywhere;">' ..
            escape_html(tostring(detail)) .. '</p>'
    end
    return '<!DOCTYPE html><html lang="fa" dir="rtl"><head><meta charset="utf-8">' ..
        '<meta name="viewport" content="width=device-width,initial-scale=1">' ..
        '<title>همراه ۱۴۰</title></head><body style="font-family:Tahoma,Arial,sans-serif;' ..
        'background:#f4f7fb;padding:40px;font-size:15px;color:#000;">' ..
        '<div style="max-width:640px;margin:0 auto;background:#fff;border:1px solid #e5eaf2;' ..
        'border-radius:14px;padding:24px;line-height:2;">' ..
        '<h1 style="font-size:18px;color:#16509D;margin:0 0 12px;">پنل پرسنلی باز نشد</h1>' ..
        body ..
        '<p style="font-size:14px;color:#666;margin-top:14px;">اگر این پیام تکرار شد، لطفاً همین ' ..
        'متن را به واحد فناوری اطلاعات بدهید.</p>' ..
        '</div></body></html>'
end

-- ── inputs / config ──────────────────────────────────────────────────

local config_data = {}
do
    local ok = pcall(function()
        local config = teamyar.get_config()
        if config ~= nil and config.data ~= nil then config_data = config.data end
    end)
    if not ok then config_data = {} end
end

local function config_number(key)
    local raw = input[key]
    if raw == nil then raw = config_data[key] end
    local n = tonumber(raw)
    -- getParamToNumber مقدار غیرعددی را به 0 تبدیل می‌کند، پس 0 هم یعنی «تنظیم نشده»
    if n == nil or n <= 0 then return nil end
    return n
end

local action_type = input.type
local format_out = input.format

-- اعتبارسنجی بازهٔ تاریخ. بدون این، یک to_date بی‌معنی (مثلاً 0 یا 1 که پلتفرم برای فیلد عددیِ
-- پرنشده می‌سازد) کوئری‌ها را بی‌سروصدا خالی برمی‌گرداند و پنل «خراب» به نظر می‌رسد بدون هیچ خطایی.
-- کف بازه ۱۳۰۰/۰۱/۰۱ شمسی (تقریباً ۱۹۲۱ میلادی) و سقف آن ۵ سال بعد از امروز است.
local FT_MIN_VALID = 116000000000000000 -- حدود ۱۹۲۰ میلادی
local today_ft = today_filetime()

local to_date = tonumber(input.to_date)
if to_date == nil or to_date < FT_MIN_VALID or to_date > (today_ft + 1826 * FT_DAY) then
    to_date = today_ft
end

local days_back = tonumber(input.days) or 31
if days_back ~= days_back then days_back = 31 end -- NaN
if days_back < 1 then days_back = 1 end
if days_back > 190 then days_back = 190 end
days_back = math.floor(days_back)

local from_date = tonumber(input.from_date)
if from_date == nil or from_date < FT_MIN_VALID or from_date > to_date then
    from_date = to_date - ((days_back - 1) * FT_DAY)
else
    days_back = math.floor((to_date - from_date) / FT_DAY) + 1
end

-- ── type=sqlprobe — تشخیص گام‌به‌گام علت «sql error» ─────────────────
-- لایهٔ db.query این پلتفرم فقط رشتهٔ عمومی «sql error» برمی‌گرداند و هیچ جزئیاتی نمی‌دهد، پس
-- تنها راه قطعیِ پیدا کردن قطعهٔ مقصر، اجرای کوئری به‌صورت تکه‌تکه و دیدن اولین تکه‌ای است که
-- می‌شکند. هر گام دقیقاً یک ساختار SQL بیشتر از گام قبل دارد.
if action_type == "sqlprobe" then
    local steps = {}

    local function probe(label, query, params)
        local rows, err = fetch_rows(query, params, 1)
        table.insert(steps, {
            step = #steps + 1,
            label = label,
            ok = (rows ~= nil),
            rows = rows and #rows or 0,
            value = (rows ~= nil and #rows > 0) and tostring(rows[1][1]) or nil,
            error = (rows == nil) and tostring(err) or nil,
            sql = query
        })
    end

    probe("01 SELECT 1", "SELECT 1", {})
    probe("02 UNIX_TIMESTAMP filetime",
        "SELECT (UNIX_TIMESTAMP() + 11644473600) * 10000000", {})
    probe("03 MOD big literal",
        "SELECT MOD((UNIX_TIMESTAMP() + 11644473600) * 10000000, 864000000000)", {})
    probe("04 FLOOR", "SELECT FLOOR(864000000000 / 10000000)", {})
    probe("05 ROUND", "SELECT ROUND(864000000000 / 10000000 / 60, 0)", {})
    probe("06 JDATE expr + DASH (was slash)",
        "SELECT COALESCE(REPORT_FN_JDATE((UNIX_TIMESTAMP() + 11644473600) * 10000000, '/'), '')", {})
    -- گام‌های اختصاصی جداکننده: دقیقاً ثابت می‌کنند اسلش مقصر بوده یا نه
    probe("06a JDATE literal + dash", "SELECT REPORT_FN_JDATE(" ..
        sql_filetime(133700000000000000) .. ", '-')", {})
    probe("06b JDATE literal + SLASH", "SELECT REPORT_FN_JDATE(" ..
        sql_filetime(133700000000000000) .. ", '/')", {})
    probe("06c JDATE column + dash",
        "SELECT REPORT_FN_JDATE(w.WORK_DATE, '-') FROM hr_work_time w LIMIT 1", {})
    probe("06d JDATE column + SLASH",
        "SELECT REPORT_FN_JDATE(w.WORK_DATE, '/') FROM hr_work_time w LIMIT 1", {})
    probe("07 N-literal persian", "SELECT COALESCE(NULL, N'نامشخص')", {})
    probe("08 hr_work_time count", "SELECT COUNT(*) FROM hr_work_time", {})
    probe("09 small param",
        "SELECT COUNT(*) FROM hr_work_time w WHERE w.PERSONNEL_ID = ?", { 1 })
    probe("10 date range literal",
        "SELECT COUNT(*) FROM hr_work_time w WHERE w.WORK_DATE BETWEEN " ..
        sql_filetime(0) .. " AND " .. sql_filetime(133700000000000000), {})
    probe("11 FIRST_IN floor/mod",
        "SELECT " .. sql_seconds_of_day("w.FIRST_IN") .. " FROM hr_work_time w LIMIT 1", {})
    probe("12 TOTAL_WORK round",
        "SELECT " .. sql_ticks_to_minutes("w.TOTAL_WORK") .. " FROM hr_work_time w LIMIT 1", {})
    probe("13 CASE final_over_time",
        "SELECT " .. sql_ticks_to_minutes(
            "CASE WHEN w.FINAL_OVER_TIME = -1 THEN w.OVER_TIME ELSE w.FINAL_OVER_TIME END") ..
        " FROM hr_work_time w LIMIT 1", {})
    probe("14 mission sum",
        "SELECT " .. sql_ticks_to_minutes("w.MISSION + w.MISSION_OUT_CITY + w.MISSION_OUT_COUNTRY") ..
        " FROM hr_work_time w LIMIT 1", {})
    probe("15 ABSENT", "SELECT COALESCE(w.ABSENT, 0) FROM hr_work_time w LIMIT 1", {})
    probe("16 join report_dimdate",
        "SELECT COALESCE(rd.JTDAY, '') FROM hr_work_time w " ..
        "LEFT JOIN report_dimdate rd ON rd.DATEKEY = w.WORK_DATE LIMIT 1", {})
    probe("17 CTE", "WITH t AS (SELECT 1 AS a) SELECT a FROM t", {})
    probe("18 CTE hr_day_details",
        "WITH shift_day AS (SELECT d.CALENDAR_ID, d.DAY_DATE, MIN(d.TIME_FROM) AS shift_from " ..
        "FROM hr_day_details d WHERE d.CALENDAR_ID = ? GROUP BY d.CALENDAR_ID, d.DAY_DATE) " ..
        "SELECT COUNT(*) FROM shift_day", { 1 })
    probe("19 hr_ext_time count", "SELECT COUNT(*) FROM hr_ext_time", {})
    probe("20 hr_vacation count", "SELECT COUNT(*) FROM hr_vacation", {})
    probe("21 hr_vacation join type",
        "SELECT COUNT(*) FROM hr_vacation v " ..
        "LEFT JOIN hr_vacation_type vt ON vt.TYPE = v.TYPE", {})
    probe("22 correlated subquery",
        "SELECT (SELECT COUNT(*) FROM hr_leave_verify lv WHERE lv.LEAVE_ID = v.ID) " ..
        "FROM hr_vacation v LIMIT 1", {})
    probe("23 hr_machine", "SELECT COALESCE(m.NAME, N'—') FROM hr_machine m LIMIT 1", {})
    probe("24 GREATEST",
        "SELECT " .. sql_ticks_to_minutes("GREATEST(e.TIME_TO - e.TIME_FROM, 0)") ..
        " FROM hr_ext_time e LIMIT 1", {})

    local first_failure = nil
    for _, st in ipairs(steps) do
        if not st.ok and first_failure == nil then first_failure = st.step end
    end

    teamyar.write_result(json.encode({
        ok = true,
        first_failing_step = first_failure,
        total_steps = #steps,
        steps = steps
    }))
    return
end

-- ── resolve the signed-in user ───────────────────────────────────────
-- قانون این پنل: خروجی همیشه مربوط به همان کاربری است که بات را اجرا کرده — نه کسی که در ورودی
-- نامش را بفرستد. به همین دلیل هیچ ورودی personnel_id/profile_id پذیرفته نمی‌شود؛ اگر پذیرفته
-- می‌شد، هر کاربری می‌توانست با عوض کردن یک عدد، کارکرد و مرخصی و اطلاعات پرسنلی بقیه را ببیند
-- (IDOR). شناسه فقط از نشستِ خودِ کاربر می‌آید.
--
-- teamyar.get_user_info() روی این پلتفرم مستند نیست (تنها استفادهٔ تاییدشده در این ریپو
-- user_info.timezone است)، پس به‌جای فرضِ یک نام کلید، سه لایه پشت‌سرهم امتحان می‌شود:
--   ۱) کلیدهای عددی محتمل (profile_id / user_id / id / ...)
--   ۲) کلیدهای عددی تودرتو (user.id، profile.id، ...)
--   ۳) کلیدهای متنی هویتی (username / email / mobile / کد ملی) با جست‌وجو در جدول پروفایل
-- type=whoami ساختار خام get_user_info را برمی‌گرداند تا روی سرور واقعی در یک اجرا مشخص شود
-- کدام کلید وجود دارد و در صورت نیاز همین‌جا اضافه شود.

local user_info = {}
do
    local ok, result = pcall(function() return teamyar.get_user_info() end)
    if ok and type(result) == "table" then user_info = result end
end

local USER_ID_KEYS = {
    "profile_id", "PROFILE_ID", "profileId",
    "user_id", "USER_ID", "userId", "userid",
    "id", "ID", "uid", "UID", "person_id", "PERSON_ID"
}
local USER_LOGIN_KEYS = {
    "username", "USERNAME", "user_name", "login", "LOGIN",
    "email", "EMAIL", "mobile", "MOBILE", "cell", "national_code", "NATIONAL_CODE"
}
local NESTED_KEYS = { "user", "USER", "profile", "PROFILE", "data", "DATA", "info", "INFO" }

local function first_positive_number(source, keys)
    if type(source) ~= "table" then return nil, nil end
    for _, key in ipairs(keys) do
        local n = tonumber(source[key])
        if n ~= nil and n > 0 then return n, key end
    end
    return nil, nil
end

local function first_non_empty_string(source, keys)
    if type(source) ~= "table" then return nil, nil end
    for _, key in ipairs(keys) do
        local value = source[key]
        if type(value) == "string" and value ~= "" and tonumber(value) == nil then
            return value, key
        end
    end
    return nil, nil
end

local current_profile_id, profile_id_key = first_positive_number(user_info, USER_ID_KEYS)

if current_profile_id == nil then
    for _, container in ipairs(NESTED_KEYS) do
        local nested = user_info[container]
        local value, key = first_positive_number(nested, USER_ID_KEYS)
        if value ~= nil then
            current_profile_id = value
            profile_id_key = container .. "." .. key
            break
        end
    end
end

local login_value, login_key = first_non_empty_string(user_info, USER_LOGIN_KEYS)

if action_type == "whoami" then
    local seen_keys = {}
    for key, value in pairs(user_info) do
        table.insert(seen_keys, tostring(key) .. " (" .. type(value) .. ")")
    end
    teamyar.write_result(json.encode({
        ok = true,
        user_info = user_info,
        user_info_keys = seen_keys,
        resolved_profile_id = current_profile_id,
        resolved_from_key = profile_id_key,
        login_candidate = login_value,
        login_candidate_key = login_key,
        note = "اگر resolved_profile_id خالی است، کلید درست را از user_info_keys بردارید و به USER_ID_KEYS بات اضافه کنید"
    }))
    return
end

-- ── personnel identity ───────────────────────────────────────────────

local personnel = nil
local identity_err = nil

local PERSONNEL_SELECT = [[
SELECT h.PERSONNEL_ID, h.PERSONNEL_CODE, h.PROFILE_ID, h.ORG_ID, p.FULLNAME,
       h.MARITAL_STATUS, h.WORK_PLACE, h.HIRING_STATUS, h.START_DATE, uf.SEX, uf.BIRTHDAY
FROM hr_personnels h
JOIN profile_main p ON p.id = h.PROFILE_ID
LEFT JOIN profile_user_info uf ON uf.id = p.id
]]

do
    local ok, err = pcall(function()
        local rows, query_err
        if current_profile_id ~= nil then
            rows, query_err = fetch_rows(PERSONNEL_SELECT .. [[
WHERE h.PROFILE_ID = ?
ORDER BY h.PERSONNEL_ID DESC
LIMIT 1
]], { current_profile_id }, 11)
        elseif login_value ~= nil then
            -- لایهٔ آخر: نشست فقط یک شناسهٔ متنی داده است (ایمیل/موبایل/کد ملی). جدول لاگین
            -- جداگانه‌ای در این اسکیما نیست؛ این سه، جدول‌های تاییدشدهٔ نگه‌دارندهٔ همین مقادیرند و
            -- همگی با USER_ID به شناسهٔ پروفایل وصل می‌شوند. تطبیق دقیق با = انجام می‌شود
            -- (نه LIKE — باگ تاییدشدهٔ پلتفرم).
            rows, query_err = fetch_rows(PERSONNEL_SELECT .. [[
JOIN (
  SELECT USER_ID FROM profile_email WHERE EMAIL = ?
  UNION
  SELECT USER_ID FROM profile_mobile WHERE MOBILE = ?
  UNION
  SELECT USER_ID FROM profile_nationalcode WHERE NATIONAL_CODE = ?
) login_match ON login_match.USER_ID = p.id
ORDER BY h.PERSONNEL_ID DESC
LIMIT 1
]], { login_value, login_value, login_value }, 11)
        else
            identity_err = "کاربر جاری از نشست شناسایی نشد. یک‌بار بات را با ورودی type=whoami " ..
                "اجرا کنید تا کلید شناسهٔ کاربر در این سرور مشخص شود."
            return
        end

        if rows == nil then
            identity_err = "خطا در خواندن اطلاعات پرسنلی: " .. tostring(query_err)
            return
        end
        if #rows == 0 then
            identity_err = "برای این کاربر پروندهٔ پرسنلی فعالی یافت نشد."
            return
        end

        local r = rows[1]
        personnel = {
            personnel_id = tonumber(r[1]),
            personnel_code = r[2],
            profile_id = tonumber(r[3]),
            org_id = tonumber(r[4]),
            fullname = r[5] or "-",
            marital_status = tonumber(r[6]),
            work_place = r[7],
            hiring_status = tonumber(r[8]),
            start_date = tonumber(r[9]),
            sex = tonumber(r[10]),
            birthday = tonumber(r[11])
        }
    end)
    if not ok then identity_err = tostring(err) end
end

-- ── celebration dialog (create-or-join, ماژول گفتگو) ─────────────────
-- گفتگوی تبریک یک «گفتگوی گروهی» واقعی در ماژول گفتگوی Teamyar است (module_id = 9)، نه یک اقدام
-- و نه یک لیست داخل خود بات. جریان کار:
--   ۱) عنوان قطعی ساخته می‌شود: «تبریک تولد <نام> — <تاریخ شمسی>»
--   ۲) با یک SELECT روی chat_dialogs دنبال همان TOPIC می‌گردیم (تطبیق دقیق با =، نه LIKE —
--      طبق باگ تاییدشدهٔ پلتفرم، LIKE پارامتری روی این لایهٔ db.query کار نمی‌کند)
--   ۳) اگر نبود، با /api/dialog/add ساخته می‌شود (در صورت نیاز group_id از /api/group/get)
--   ۴) کاربر با /api/assign/add به همان گفتگو اضافه («جوین») می‌شود
-- بعد از آن، تبریک‌ها داخل خودِ ماژول گفتگو نوشته می‌شوند و این پنل فقط آن‌ها را از chat_message
-- می‌خواند و نمایش می‌دهد. یعنی بات هیچ‌وقت مستقیماً روی جداول هسته نمی‌نویسد.
--
-- ⚠️ نکتهٔ صریح: schema درخواست این سه endpoint در docs/context/TeamyarInternalApiReference.md
-- موجود نیست (نه dialog/add، نه group/get، نه assign/add ماژول گفتگو). نام فیلدهای payload زیر
-- بر پایهٔ ستون‌های تاییدشدهٔ chat_dialogs/chat_dialog_view حدس زده شده و باید با schema واقعی
-- تطبیق داده شود. هر سه payload عمداً در یک تابع جدا و در یک جا جمع شده‌اند تا اصلاحشان یک تغییر
-- چندخطی باشد، و پاسخ خام هر فراخوانی در خروجی برمی‌گردد تا در اولین اجرای واقعی دیده شود.

local CHAT_MODULE_ID = 9
local HR_MODULE_ID = 13 -- ماژول «پرسنلی» طبق جدول HOME_MODULE_LIST

local celebration_group_id = config_number("celebration_group_id")
-- show_in_portal یکی از فیلدهای تاییدشدهٔ /api/dialog/add است. معنای دقیقش مستند نشده، پس
-- پیش‌فرض ۰ (محافظه‌کارانه) است و از bot_config قابل تغییر.
local celebration_show_in_portal = tonumber(config_data.celebration_show_in_portal) or 0

-- آدرس ماژول گفتگو. نسبی نوشته شده تا روی هر میزبانی که بات از آن سرو می‌شود کار کند و دامنه
-- جایی hardcode نشود. عمداً هیچ پارامتر اضافه‌ای ندارد: پارامترهای widget_* که در لینک کامل
-- پورتال دیده می‌شوند تنظیمات ظاهری ویجت‌اند و به گفتگو ربطی ندارند.
-- ⚠️ محدودیت واقعی: گفتگوها در این ماژول به‌صورت پاپ‌آپ باز می‌شوند، پس **لینک مستقیم به یک
-- گفتگوی مشخص وجود ندارد**. بیشترین کاری که می‌شود کرد باز کردن خود ماژول است؛ به همین دلیل
-- عنوان قطعی گفتگو هم به کاربر نشان داده می‌شود تا در فهرست پیدایش کند.
local chat_module_url = config_data.chat_module_url
if chat_module_url == nil or tostring(chat_module_url) == "" then
    chat_module_url = "/?page=/chat/index"
end
chat_module_url = tostring(chat_module_url)

-- قالب لینک مستقیم به یک گفتگوی مشخص. {id} با شناسهٔ گفتگو جایگزین می‌شود.
-- ⚠️ رشتهٔ پیش‌فرض عمداً با پیوند ساخته می‌شود و نه به‌صورت یک literal پیوسته: در متن پیوسته،
-- نام پارامتر با «and» شروع می‌شود که پیشوند یک entity نام‌دار است و طبق باگ تاییدشدهٔ
-- این پلتفرم، هنگام ذخیرهٔ command بی‌سروصدا decode و خراب می‌شد.
-- این پلتفرم دو الگوی لینک‌دهی دارد (هر دو در بات‌های زندهٔ همین ریپو دیده می‌شوند):
--   شناسه در مسیر    → /?page=/sales/invoice/view_invoice/{id}
--   شناسه در پارامتر → /?page=/pm/service_request/view/view_request/ + and + id={id}
-- اگر شکل واقعی ماژول گفتگو با پیش‌فرض زیر فرق داشت، فقط کافی است
-- chat_dialog_url_template در bot_config عوض شود؛ نیازی به تغییر کد نیست.
-- پیش‌فرض عمداً خالی است. شکل واقعی این آدرس هنوز تایید نشده و سه حالت ممکن دارد که هر سه در
-- بات‌های زندهٔ همین ریپو دیده می‌شوند؛ یک لینک اشتباه روی باتی که با دادهٔ پرسنلی کار می‌کند بدتر
-- از نبودِ لینک است. تا وقتی این مقدار در bot_config ثبت نشود، دکمه همان ماژول گفتگو را باز می‌کند
-- و عنوان قطعی گفتگو هم کنارش نشان داده می‌شود. نمونهٔ مقدار پس از تایید:
--   chat_dialog_url_template = مسیر ماژول + and + dialog_id={id}
local chat_dialog_url_template = config_data.chat_dialog_url_template
if chat_dialog_url_template == nil then chat_dialog_url_template = "" end
chat_dialog_url_template = tostring(chat_dialog_url_template)
if celebration_show_in_portal ~= 1 then celebration_show_in_portal = 0 end

-- ⛔ کلید ایمنی نوشتن روی ماژول گفتگو — پیش‌فرض خاموش.
-- schema هر سه endpoint حالا تایید شده است (۱۴۰۵/۰۶/۰۷)، پس دلیل اولیهٔ این کلید (payload حدسی)
-- دیگر برقرار نیست. ولی این عملیات‌ها روی سامانهٔ زندهٔ سازمان رکورد واقعی می‌سازند (یک گروه گفتگو
-- و یک گفتگو به ازای هر تولد)، و این بات با دادهٔ پرسنلی کار می‌کند. پس کلید عمداً باقی ماند تا
-- شروع نوشتن یک تصمیم آگاهانه باشد، نه اثر جانبی استقرار. تا وقتی celebration_enabled = 1 نشود:
--   • فهرست تولدها، پیام روز و کل بقیهٔ پنل کاملاً کار می‌کند (همه خواندنی‌اند)
--   • خواندن گفتگوی موجود از chat_message هم کار می‌کند (باز هم خواندنی)
--   • فقط ساخت گفتگو و پیوستن (تنها دو عملیات نوشتنی این بات) انجام نمی‌شود
-- بعد از تایید schema، یک بار مقدار را ۱ کنید؛ نیازی به تغییر کد نیست.
local celebration_enabled = (tonumber(input.celebration_enabled)
    or tonumber(config_data.celebration_enabled) or 0) == 1

local function celebration_topic(person_name, jalali_date)
    return "تبریک تولد " .. tostring(person_name) .. " — " .. tostring(jalali_date)
end

-- لایهٔ فراخوانی API — همان الگوی call_api_1_bot.lua این ریپو
-- (teamyar.call_api(module_id, url, params) + کنترل secret-key)، ولی با دو مسیر:
--   ۱) اگر api_caller_path در bot_config تنظیم شده باشد، فراخوانی از بات عمومی
--      api_caller_json_bot.lua رد می‌شود (teamyar.run_command). مزیتش این است که کل ترافیک API
--      از یک نقطه با allowlist و کلید مشترک عبور می‌کند و همان‌جا هم قابل لاگ گرفتن است.
--   ۲) اگر تنظیم نشده باشد، مستقیم teamyar.call_api صدا زده می‌شود.
-- هر دو مسیر دقیقاً یک شکل خروجی می‌دهند تا بقیهٔ کد فرقی نکند.

local api_caller_path = config_data.api_caller_path
local api_caller_secret = config_data.api_caller_secret

-- توجه: نمونهٔ رسمی پورتال برای success مقدار عددی 0/1 نشان می‌دهد، ولی جدول schema نوعش را
-- boolean اعلام کرده. هر دو حالت اینجا «ناموفق» شمرده می‌شوند (در Lua مقایسهٔ 0 == false غلط است).
local function api_failed(result)
    if type(result) ~= "table" then return false end
    if result.success == false then return true end
    if tonumber(result.success) ~= nil and tonumber(result.success) == 0 then return true end
    return false
end

local function unwrap_api_error(result)
    if api_failed(result) then
        local detail = "نامشخص"
        if type(result.error) == "table" and result.error.message ~= nil then
            detail = tostring(result.error.message)
        elseif type(result.error) == "string" then
            detail = result.error
        end
        return detail
    end
    return nil
end

local function call_teamyar_api(module_id, path, payload)
    if api_caller_path ~= nil and tostring(api_caller_path) ~= "" then
        local ok, envelope = pcall(function()
            return teamyar.run_command(tostring(api_caller_path), {
                module_id = module_id,
                url = path,
                params = payload,
                secret_key = api_caller_secret
            })
        end)
        if not ok then
            return nil, "خطا در فراخوانی بات api_caller: " .. tostring(envelope)
        end
        -- بعضی نسخه‌ها رشتهٔ JSON برمی‌گردانند و بعضی جدول
        if type(envelope) == "string" then
            local decoded_ok, decoded = pcall(function() return json.decode(envelope) end)
            if decoded_ok and type(decoded) == "table" then envelope = decoded end
        end
        if type(envelope) ~= "table" then
            return nil, "پاسخ بات api_caller قابل خواندن نبود"
        end
        if envelope.ok == false then
            return envelope, tostring(envelope.error or "نامشخص")
        end
        local response = envelope.response
        return response, unwrap_api_error(response)
    end

    local ok, result = pcall(function()
        return teamyar.call_api(module_id, path, payload)
    end)
    if not ok then
        return nil, tostring(result)
    end
    return result, unwrap_api_error(result)
end

local function call_chat_api(path, payload)
    return call_teamyar_api(CHAT_MODULE_ID, path, payload)
end

-- استخراج شناسه از پاسخ API بدون فرض دربارهٔ شکل دقیق پاسخ (data.id / data.dialog_id / id / ...)
local function extract_id(response, keys)
    if type(response) ~= "table" then return nil end
    local containers = { response, response.data, response.result }
    for _, container in ipairs(containers) do
        if type(container) == "table" then
            for _, key in ipairs(keys) do
                local n = tonumber(container[key])
                if n ~= nil and n > 0 then return n end
            end
        end
    end
    return nil
end

local function find_celebration_dialog(topic)
    local rows, err = fetch_rows([[
SELECT cd.ID, COALESCE(cd.GROUP_ID, 0) AS group_id
FROM chat_dialogs cd
WHERE cd.TOPIC = ? AND COALESCE(cd.deleted, 0) = 0
ORDER BY cd.ID DESC
LIMIT 1
]], { topic }, 2)
    if rows == nil then return nil, tostring(err) end
    if #rows == 0 then return nil, nil end
    return tonumber(rows[1][1]), nil
end

local function load_celebration_messages(dialog_id)
    local rows = fetch_rows([[
SELECT COALESCE(pm.fullname, N'همکار') AS author_name, cm.CONTENT,
  COALESCE(REPORT_FN_JDATE(cm.DATE_CREATE, '-'), '') AS jdate,
  ]] .. sql_seconds_of_day("cm.DATE_CREATE") .. [[ AS jtime
FROM chat_message cm
LEFT JOIN profile_main pm ON pm.id = cm.USER_ID
WHERE cm.DIALOG_ID = ?
ORDER BY cm.DATE_CREATE ASC, cm.ID ASC
LIMIT 200
]], { dialog_id }, 4)
    local messages = {}
    if rows ~= nil then
        for _, r in ipairs(rows) do
            table.insert(messages, {
                author = r[1] or "همکار",
                text = r[2] or "",
                date = jalali_date(r[3]) or "",
                clock = seconds_to_hm(r[4]) or ""
            })
        end
    end
    return messages
end

local function load_celebration_members(dialog_id)
    local rows = fetch_rows([[
SELECT COALESCE(pm.fullname, N'همکار') AS member_name
FROM chat_dialog_view cdv
LEFT JOIN profile_main pm ON pm.id = cdv.USER_ID
WHERE cdv.DIALOG_ID = ?
ORDER BY pm.fullname
LIMIT 200
]], { dialog_id }, 1)
    local members = {}
    if rows ~= nil then
        for _, r in ipairs(rows) do table.insert(members, r[1] or "همکار") end
    end
    return members
end

-- گروه گفتگوی تبریک.
-- ⚠️ نکتهٔ مهمِ schema (تاییدشده ۱۴۰۵/۰۶/۰۷): /api/group/get ورودی {id} می‌گیرد، یعنی یک گروه
-- مشخص را می‌خواند و **فهرست گروه‌ها را نمی‌دهد**. پس با آن نمی‌شود گروه را «کشف» کرد؛ فقط
-- می‌شود گروهی که شناسه‌اش را داریم راستی‌آزمایی کرد. ترتیب کار:
--   ۱) اگر celebration_group_id در bot_config باشد، همان استفاده می‌شود
--   ۲) وگرنه گروهی با نام قطعی در جدول chat_group جست‌وجو می‌شود (تطبیق دقیق با =، نه LIKE)
--   ۳) اگر نبود، یک بار با /api/group/add ساخته می‌شود و دفعات بعد در گام ۲ پیدا می‌شود
local CELEBRATION_GROUP_NAME = "گفتگوهای تبریک تولد — همراه ۱۴۰"

local function find_group_by_name(name)
    local rows, err = fetch_rows([[
SELECT g.ID FROM chat_group g WHERE g.NAME = ? ORDER BY g.ID DESC LIMIT 1
]], { name }, 1)
    if rows == nil then return nil, tostring(err) end
    if #rows == 0 then return nil, nil end
    return tonumber(rows[1][1]), nil
end

local function resolve_group_id()
    if celebration_group_id ~= nil then return celebration_group_id, nil end

    local existing, lookup_err = find_group_by_name(CELEBRATION_GROUP_NAME)
    if lookup_err ~= nil then return nil, lookup_err end
    if existing ~= nil then return existing, nil end

    local response, api_err = call_chat_api("/api/group/add", {
        name = CELEBRATION_GROUP_NAME,
        public_name = CELEBRATION_GROUP_NAME,
        status = 0,
        keywords = {}
    })
    if api_err ~= nil then return nil, "ساخت گروه گفتگو انجام نشد: " .. api_err end

    local created = extract_id(response, { "id", "ID", "group_id", "GROUP_ID" })
    if created == nil then
        -- بعضی APIها فقط success می‌دهند؛ گروه تازه‌ساخته را با همان نام پیدا می‌کنیم
        created = select(1, find_group_by_name(CELEBRATION_GROUP_NAME))
    end
    if created == nil then
        return nil, "گروه ساخته شد ولی شناسه‌اش برگردانده نشد"
    end
    return created, nil
end

-- POST type=celebrate → «به گفتگوی تبریک بپیوند» (اگر گفتگو نبود، ساخته می‌شود)
if action_type == "celebrate" then
    local target_name = tostring(input.person_name or "")
    local target_date = tostring(input.person_date or "")

    if target_name == "" or target_date == "" then
        teamyar.write_result(json.encode({ ok = false, error = "نام و تاریخ تولد مشخص نشده است" }))
        return
    end
    if personnel == nil then
        teamyar.write_result(json.encode({ ok = false, error = identity_err or "کاربر شناسایی نشد" }))
        return
    end
    if not celebration_enabled then
        teamyar.write_result(json.encode({
            ok = false,
            error = "ساخت و پیوستن به گفتگوی تبریک هنوز فعال نشده است. " ..
                "برای فعال کردن، celebration_enabled را در bot_config این بات برابر ۱ بگذارید."
        }))
        return
    end

    local topic = celebration_topic(target_name, target_date)
    local dialog_id, lookup_err = find_celebration_dialog(topic)
    if lookup_err ~= nil then
        teamyar.write_result(json.encode({ ok = false, error = "خطا در جست‌وجوی گفتگو: " .. lookup_err }))
        return
    end

    local created = false
    local create_response = nil
    if dialog_id == nil then
        local group_id, group_err = resolve_group_id()
        if group_id == nil then
            teamyar.write_result(json.encode({
                ok = false,
                error = "گفتگو ساخته نشد: " .. tostring(group_err) ..
                    " — می‌توانید celebration_group_id را در bot_config این بات تنظیم کنید."
            }))
            return
        end
        -- فیلدهای تاییدشدهٔ schema؛ type و status که قبلاً حدس زده بودم اصلاً در این API نیستند
        local response, api_err = call_chat_api("/api/dialog/add", {
            topic = topic,
            group_id = group_id,
            author_id = personnel.profile_id,
            show_in_portal = celebration_show_in_portal
        })
        create_response = response
        if api_err ~= nil then
            teamyar.write_result(json.encode({
                ok = false,
                error = "ساخت گفتگو انجام نشد: " .. api_err,
                api_response = response
            }))
            return
        end
        dialog_id = extract_id(response, { "dialog_id", "id", "ID", "DIALOG_ID" })
        if dialog_id == nil then
            -- بعضی APIها فقط success برمی‌گردانند؛ گفتگوی تازه‌ساخته را با همان TOPIC پیدا می‌کنیم
            dialog_id = select(1, find_celebration_dialog(topic))
        end
        if dialog_id == nil then
            teamyar.write_result(json.encode({
                ok = false,
                error = "گفتگو ساخته شد ولی شناسهٔ آن برگردانده نشد",
                api_response = response
            }))
            return
        end
        created = true
    end

    -- فیلدهای تاییدشدهٔ schema. نسخهٔ قبلی user_id/user_ids می‌فرستاد که هیچ‌کدام در این API
    -- وجود ندارند و assigned/author_id را نمی‌فرستاد — یعنی قطعاً کار نمی‌کرد.
    local assign_response, assign_err = call_chat_api("/api/assign/add", {
        assigned = { personnel.profile_id },
        author_id = personnel.profile_id,
        dialog_id = dialog_id
    })
    if assign_err ~= nil then
        teamyar.write_result(json.encode({
            ok = false,
            error = "پیوستن به گفتگو انجام نشد: " .. assign_err,
            dialog_id = dialog_id,
            created = created,
            api_response = assign_response
        }))
        return
    end

    teamyar.write_result(json.encode({
        ok = true,
        created = created,
        joined = true,
        dialog_id = dialog_id,
        members = load_celebration_members(dialog_id),
        messages = load_celebration_messages(dialog_id),
        create_response = create_response,
        assign_response = assign_response
    }))
    return
end

-- GET type=celebration_thread → وضعیت و پیام‌های یک گفتگوی تبریک
if action_type == "celebration_thread" then
    local target_name = tostring(input.person_name or "")
    local target_date = tostring(input.person_date or "")
    if target_name == "" or target_date == "" then
        teamyar.write_result(json.encode({ ok = false, error = "نام و تاریخ تولد مشخص نشده است" }))
        return
    end
    local topic = celebration_topic(target_name, target_date)
    local dialog_id, lookup_err = find_celebration_dialog(topic)
    if lookup_err ~= nil then
        teamyar.write_result(json.encode({ ok = false, error = "خطا در جست‌وجوی گفتگو: " .. lookup_err }))
        return
    end
    teamyar.write_result(json.encode({
        ok = true,
        exists = (dialog_id ~= nil),
        dialog_id = dialog_id,
        members = dialog_id and load_celebration_members(dialog_id) or {},
        messages = dialog_id and load_celebration_messages(dialog_id) or {}
    }))
    return
end

if personnel == nil then
    if format_out == "json" then
        teamyar.write_result(json.encode({ ok = false, error = identity_err or "کاربر شناسایی نشد" }))
        return
    end
    -- در حالت HTML هم به‌جای صفحهٔ سفید، پیام روشن فارسی برگردانده می‌شود
    teamyar.write_result(render_error_page(identity_err or "کاربر شناسایی نشد"))
    return
end

-- ── section: current order (unit, supervisor, calendar, settings) ────
-- منبع اول: API رسمی /api/hr/orderInDateGet (ماژول ۱۳، schema تاییدشده ۱۴۰۵/۰۶/۰۶)
--   درخواست: {date, org_id, personnel_id}
--   پاسخ:   data شامل کل رکورد حکم فعال در آن تاریخ (id, unit_id, calendar_id, supervisor,
--           date_from/date_to, و دوجین تنظیم حکم مثل telework_request/overtime_disabled/...)
-- API فقط شناسه برمی‌گرداند نه نام، پس نام واحد/تقویم/سرپرست با یک کوئری کوچک resolve می‌شود.
-- منبع دوم (fallback): همان SELECT قبلی روی hr_personnel_order، اگر API خطا داد یا حکمی نداد.

local employment = {}
local employment_settings = nil
local employment_source = nil
local employment_err = nil

local ORDER_SETTING_LABELS = {
    { key = "telework_request", label = "درخواست دورکاری", on = "فعال", off = "غیرفعال" },
    { key = "overtime_disabled", label = "اضافه‌کاری", on = "غیرفعال", off = "فعال" },
    { key = "overtime_confirm", label = "اضافه‌کاری نیاز به تایید دارد", on = "بله", off = "خیر" },
    { key = "pre_overtime_disabled", label = "اضافه‌کاری ابتدای کار", on = "غیرفعال", off = "فعال" },
    { key = "pre_overtime_confirm", label = "اضافه‌کاری ابتدای کار نیاز به تایید دارد", on = "بله", off = "خیر" },
    { key = "floating_enabled", label = "شناوری ساعت کاری", on = "فعال", off = "غیرفعال" },
    { key = "cal_daily_vacation", label = "محاسبهٔ مرخصی و ماموریت روزانه", on = "فعال", off = "غیرفعال" },
    { key = "insurable", label = "مشمول بیمه", on = "بله", off = "خیر" },
    { key = "taxable", label = "مشمول مالیات", on = "بله", off = "خیر" },
    { key = "unemployment_insurance_exemption", label = "معافیت بیمهٔ بیکاری", on = "دارد", off = "ندارد" }
}

-- نام واحد/تقویم/سرپرست و تاریخ شمسی حکم را برای شناسه‌هایی که API برگردانده resolve می‌کند
local function resolve_order_names(unit_id, calendar_id, supervisor_id, date_from, date_to)
    local rows = fetch_rows([[
SELECT COALESCE(ou.NAME, N'نامشخص') AS unit_name,
       COALESCE(hc.NAME, N'—') AS calendar_name,
       COALESCE(sup.FULLNAME, N'—') AS supervisor_name,
       COALESCE(REPORT_FN_JDATE(]] .. sql_filetime(date_from) .. [[, '/'), '') AS date_from_j,
       COALESCE(REPORT_FN_JDATE(]] .. sql_filetime(date_to) .. [[, '/'), '') AS date_to_j
FROM (SELECT 1) seed
LEFT JOIN org_organization_unit oou ON oou.ID = ?
LEFT JOIN org_units ou ON ou.ID = oou.UNIT_ID
LEFT JOIN hr_calendar hc ON hc.ID = ?
LEFT JOIN profile_main sup ON sup.id = ?
LIMIT 1
]], { unit_id or 0, calendar_id or 0, supervisor_id or 0 }, 5)
    if rows == nil or #rows == 0 then return nil end
    return {
        unit_name = rows[1][1] or "نامشخص",
        calendar_name = rows[1][2] or "—",
        supervisor_name = rows[1][3] or "—",
        date_from = jalali_date(rows[1][4]) or "—",
        date_to = jalali_date(rows[1][5]) or "—"
    }
end

local ORDER_SELECT = [[
SELECT o.ID, o.UNIT_ID, COALESCE(ou.NAME, N'نامشخص') AS unit_name,
       o.SUPERVISOR, COALESCE(sup.FULLNAME, N'—') AS supervisor_name,
       o.CALENDAR_ID, COALESCE(hc.NAME, N'—') AS calendar_name,
       ]] .. sql_ticks_to_minutes("o.WORKING_HOURS") .. [[ AS working_minutes,
       ]] .. sql_ticks_to_minutes("o.LEAVE_PER_MONTH") .. [[ AS leave_per_month_minutes,
       COALESCE(REPORT_FN_JDATE(o.DATE_FROM, '-'), '') AS date_from_j,
       COALESCE(REPORT_FN_JDATE(o.DATE_TO, '-'), '') AS date_to_j
FROM hr_personnel_order o
LEFT JOIN org_organization_unit oou ON oou.ID = o.UNIT_ID
LEFT JOIN org_units ou ON ou.ID = oou.UNIT_ID
LEFT JOIN profile_main sup ON sup.id = o.SUPERVISOR
LEFT JOIN hr_calendar hc ON hc.ID = o.CALENDAR_ID
]]

do
    local ok, err = pcall(function()
        local response, api_err = call_teamyar_api(HR_MODULE_ID, "/api/hr/orderInDateGet", {
            personnel_id = personnel.personnel_id,
            org_id = personnel.org_id or 0,
            date = to_date
        })

        local order = nil
        if api_err == nil and type(response) == "table" and type(response.data) == "table" then
            if tonumber(response.data.id) ~= nil and tonumber(response.data.id) > 0 then
                order = response.data
            end
        elseif api_err ~= nil then
            employment_err = "API حکم فعال: " .. tostring(api_err)
        end

        if order ~= nil then
            local names = resolve_order_names(
                tonumber(order.unit_id), tonumber(order.calendar_id), tonumber(order.supervisor),
                tonumber(order.date_from), tonumber(order.date_to))
            employment.order_id = tonumber(order.id)
            employment.unit_id = tonumber(order.unit_id)
            employment.calendar_id = tonumber(order.calendar_id)
            employment.unit_name = names and names.unit_name or "نامشخص"
            employment.calendar_name = names and names.calendar_name or "—"
            employment.supervisor_name = names and names.supervisor_name or "—"
            employment.date_from = names and names.date_from or "—"
            employment.date_to = names and names.date_to or "—"
            employment.is_current = true
            -- واحد این دو در پورتال اعلام نشده؛ فقط در خروجی JSON می‌مانند، نه در رابط کاربری
            employment.working_hours_raw = tonumber(order.working_hours)
            employment.leave_per_month_raw = tonumber(order.leave_per_month)
            employment.max_delay_month_raw = tonumber(order.max_delay_month)
            employment.rest_during_work_raw = tonumber(order.rest_during_work)
            employment.max_hourly_leave_raw = tonumber(order.max_hourly_leave)
            employment.min_hourly_leave_raw = tonumber(order.min_hourly_leave)
            -- تنظیمات پرچمی حکم: بدون ابهام واحد، مستقیماً قابل نمایش‌اند
            employment_settings = {}
            for _, setting in ipairs(ORDER_SETTING_LABELS) do
                local raw = tonumber(order[setting.key])
                if raw ~= nil then
                    table.insert(employment_settings, {
                        label = setting.label,
                        value = (raw == 1) and setting.on or setting.off
                    })
                end
            end
            employment_source = "api"
            return
        end

        local rows, query_err = fetch_rows(ORDER_SELECT .. [[
WHERE o.PERSONNEL_ID = ? AND o.DATE_FROM <= ]] .. sql_filetime(to_date) .. [[
  AND o.DATE_TO >= ]] .. sql_filetime(to_date) .. [[
ORDER BY o.ID DESC
LIMIT 1
]], { personnel.personnel_id }, 11)
        if rows == nil then
            employment_err = (employment_err and (employment_err .. " | ") or "") .. tostring(query_err)
            return
        end
        if #rows == 0 then
            -- بدون حکم جاری: آخرین حکم را نشان بده (پرسنل ممکن است در بازهٔ بین دو حکم باشد)
            rows, query_err = fetch_rows(ORDER_SELECT .. [[
WHERE o.PERSONNEL_ID = ?
ORDER BY o.ID DESC
LIMIT 1
]], { personnel.personnel_id }, 11)
            if rows == nil or #rows == 0 then return end
            employment.is_current = false
        else
            employment.is_current = true
        end

        local r = rows[1]
        employment.order_id = tonumber(r[1])
        employment.unit_id = tonumber(r[2])
        employment.unit_name = r[3] or "نامشخص"
        employment.supervisor_name = r[5] or "—"
        employment.calendar_id = tonumber(r[6])
        employment.calendar_name = r[7] or "—"
        employment.working_hours_raw = tonumber(r[8])
        employment.leave_per_month_raw = tonumber(r[9])
        employment.date_from = jalali_date(r[10]) or "—"
        employment.date_to = jalali_date(r[11]) or "—"
        employment_source = "db"
    end)
    if not ok then employment_err = tostring(err) end
end

-- ── section: direct supervisor (profileSupervisorGet) ────────────────
-- API رسمی /api/hr/profileSupervisorGet (ماژول ۱۳، schema تاییدشده ۱۴۰۵/۰۶/۰۶)
--   درخواست: {org_id, profile_id}  — توجه: profile_id، نه personnel_id
--   پاسخ:   {data:{id, name}, error, success}
-- برخلاف orderInDateGet که فقط شناسهٔ سرپرست را می‌دهد و نیاز به join دارد، این API خودِ نام را
-- برمی‌گرداند و منطقش شعبه‌محور است. پس وقتی جواب بدهد، منبع ارجحِ «سرپرست مستقیم» است.
--
-- ⚠️ محدودیت مهم: توضیح پورتال می‌گوید «... در شعبهٔ مربوطه **برای زمان حاضر**». یعنی این API
-- سرپرستِ همین لحظه را می‌دهد، نه سرپرست در یک تاریخ گذشته. پس فقط وقتی استفاده می‌شود که گزارش
-- برای امروز باشد؛ اگر کاربر بازهٔ گذشته را ببیند، سرپرستِ همان حکم (از orderInDateGet یا جدول)
-- دست‌نخورده می‌ماند تا عدد تاریخی با یک مقدار امروزی جایگزین نشود.

local supervisor_source = employment_source
local supervisor_id = nil

-- «همان روز» با اختلاف کمتر از یک روز سنجیده می‌شود، نه تساوی دقیق دو عدد بزرگ FILETIME
local viewing_today = math.abs(to_date - today_ft) < FT_DAY

if personnel.profile_id ~= nil and viewing_today then
    local ok = pcall(function()
        local response, api_err = call_teamyar_api(HR_MODULE_ID, "/api/hr/profileSupervisorGet", {
            org_id = personnel.org_id or 0,
            profile_id = personnel.profile_id
        })
        if api_err ~= nil or type(response) ~= "table" or type(response.data) ~= "table" then
            return
        end
        local name = response.data.name
        if type(name) == "string" and name ~= "" then
            employment.supervisor_name = name
            supervisor_id = tonumber(response.data.id)
            supervisor_source = "api_supervisor"
        end
    end)
    if not ok then supervisor_source = employment_source end
end

-- ── section: daily attendance (hr_work_time + real shift) ────────────

local daily = {}
local totals = { work = 0, overtime = 0, delay = 0, leave = 0, mission = 0, deficit = 0,
                 present_days = 0, absent_days = 0, incomplete_days = 0, expected = 0 }
local attendance_err = nil

do
    local ok, err = pcall(function()
        -- شیفت واقعی هر روز از hr_day_details تقویم همان پرسنل خوانده می‌شود: بازهٔ شیفت
        -- (اولین شروع تا آخرین پایان) و موظفی روز (جمع مدت بازه‌ها)
        local rows, query_err = fetch_rows([[
WITH shift_day AS (
  SELECT d.CALENDAR_ID, d.DAY_DATE,
         MIN(d.TIME_FROM) AS shift_from,
         MAX(d.TIME_TO) AS shift_to,
         SUM(GREATEST(d.TIME_TO - d.TIME_FROM, 0)) AS shift_duration
  FROM hr_day_details d
  WHERE d.CALENDAR_ID = ? AND d.DAY_DATE BETWEEN ]] .. sql_filetime(from_date) ..
        [[ AND ]] .. sql_filetime(to_date) .. [[
  GROUP BY d.CALENDAR_ID, d.DAY_DATE
)
SELECT
  COALESCE(REPORT_FN_JDATE(w.WORK_DATE, '-'), '') AS jdate,
  COALESCE(rd.JTDAY, '—') AS jday_name,
  COALESCE(rd.JMDAY, 0) AS jmday,
  ]] .. sql_seconds_of_day("w.FIRST_IN") .. [[ AS first_in,
  ]] .. sql_seconds_of_day("w.LAST_OUT") .. [[ AS last_out,
  ]] .. sql_ticks_to_minutes("w.TOTAL_WORK") .. [[ AS work_minutes,
  ]] .. sql_ticks_to_minutes("CASE WHEN w.FINAL_OVER_TIME = -1 THEN w.OVER_TIME ELSE w.FINAL_OVER_TIME END") .. [[ AS overtime_minutes,
  ]] .. sql_ticks_to_minutes("CASE WHEN w.FINAL_ABSENCE = -1 THEN w.ABSENCE ELSE w.FINAL_ABSENCE END") .. [[ AS delay_minutes,
  ]] .. sql_ticks_to_minutes("w.TOTAL_LEAVE") .. [[ AS leave_minutes,
  ]] .. sql_ticks_to_minutes("w.MISSION + w.MISSION_OUT_CITY + w.MISSION_OUT_COUNTRY") .. [[ AS mission_minutes,
  COALESCE(w.ABSENT, 0) AS absent_flag,
  COALESCE(rd.JWEEKEND, 0) AS is_weekend,
  ]] .. sql_seconds_of_day("sd.shift_from") .. [[ AS shift_from,
  ]] .. sql_seconds_of_day("sd.shift_to") .. [[ AS shift_to,
  ]] .. sql_ticks_to_minutes("sd.shift_duration") .. [[ AS shift_minutes,
  w.WORK_DATE AS work_date_raw
FROM hr_work_time w
LEFT JOIN report_dimdate rd ON rd.DATEKEY = w.WORK_DATE
LEFT JOIN shift_day sd ON sd.DAY_DATE = w.WORK_DATE
WHERE w.PERSONNEL_ID = ? AND w.WORK_DATE BETWEEN ]] .. sql_filetime(from_date) ..
      [[ AND ]] .. sql_filetime(to_date) .. [[
ORDER BY w.WORK_DATE DESC
LIMIT 200
]], { employment.calendar_id or 0, personnel.personnel_id }, 16)

        if rows == nil then
            attendance_err = tostring(query_err)
            return
        end

        for _, r in ipairs(rows) do
            local work_minutes = tonumber(r[6]) or 0
            local shift_minutes = tonumber(r[15]) or 0
            local leave_minutes = tonumber(r[9]) or 0
            local mission_minutes = tonumber(r[10]) or 0
            local absent_flag = tonumber(r[11]) or 0
            local first_in, last_out = seconds_to_hm(r[4]), seconds_to_hm(r[5])
            local incomplete = (first_in ~= nil and last_out == nil) or (first_in == nil and last_out ~= nil)

            local deficit = 0
            if shift_minutes > 0 and absent_flag == 0 and not incomplete then
                deficit = shift_minutes - (work_minutes + leave_minutes + mission_minutes)
                if deficit < 0 then deficit = 0 end
            end

            local status
            if absent_flag == 1 then
                status = "غیبت"
            elseif incomplete then
                status = "ناقص"
            elseif work_minutes > 0 then
                status = "کامل"
            elseif leave_minutes > 0 then
                status = "مرخصی"
            elseif mission_minutes > 0 then
                status = "ماموریت"
            elseif shift_minutes == 0 then
                status = "تعطیل"
            else
                status = "بدون تردد"
            end

            table.insert(daily, {
                jdate = jalali_date(r[1]) or "—",
                jday_name = r[2] or "—",
                first_in = first_in,
                last_out = last_out,
                work_minutes = work_minutes,
                overtime_minutes = tonumber(r[7]) or 0,
                delay_minutes = tonumber(r[8]) or 0,
                leave_minutes = leave_minutes,
                mission_minutes = mission_minutes,
                shift_from = seconds_to_hm(r[13]),
                shift_to = seconds_to_hm(r[14]),
                shift_minutes = shift_minutes,
                deficit_minutes = deficit,
                incomplete = incomplete,
                status = status,
                work_date_raw = r[16]
            })

            totals.work = totals.work + work_minutes
            totals.overtime = totals.overtime + (tonumber(r[7]) or 0)
            totals.delay = totals.delay + (tonumber(r[8]) or 0)
            totals.leave = totals.leave + leave_minutes
            totals.mission = totals.mission + mission_minutes
            totals.deficit = totals.deficit + deficit
            totals.expected = totals.expected + shift_minutes
            if absent_flag == 1 then
                totals.absent_days = totals.absent_days + 1
            elseif incomplete then
                totals.incomplete_days = totals.incomplete_days + 1
            elseif work_minutes > 0 then
                totals.present_days = totals.present_days + 1
            end
        end
    end)
    if not ok then attendance_err = tostring(err) end
end

-- سطر «امروز» = جدیدترین روزِ برگشتی، اگر همان روزِ to_date باشد (daily نزولی مرتب است)
local today_row = nil
if #daily > 0 then
    local newest = daily[1]
    local raw = tonumber(newest.work_date_raw)
    if raw ~= nil and math.abs(raw - to_date) < FT_DAY then
        today_row = newest
    end
end

-- ── section: attendance events (hr_ext_time) ─────────────────────────

local events = {}
local events_err = nil

do
    local ok, err = pcall(function()
        local rows, query_err = fetch_rows([[
SELECT
  COALESCE(REPORT_FN_JDATE(e.EXT_DATE, '-'), '') AS jdate,
  ]] .. sql_seconds_of_day("e.TIME_FROM") .. [[ AS time_from,
  ]] .. sql_seconds_of_day("e.TIME_TO") .. [[ AS time_to,
  ]] .. sql_ticks_to_minutes("GREATEST(e.TIME_TO - e.TIME_FROM, 0)") .. [[ AS duration_minutes,
  COALESCE(e.TYPE, 0) AS ext_type,
  COALESCE(e.ENABLE, 0) AS enabled,
  COALESCE(mf.NAME, N'—') AS machine_from,
  COALESCE(mt.NAME, N'—') AS machine_to,
  COALESCE(e.COMMENT, '') AS ext_comment
FROM hr_ext_time e
LEFT JOIN hr_machine mf ON mf.ID = e.MACHINE_ID_FROM
LEFT JOIN hr_machine mt ON mt.ID = e.MACHINE_ID_TO
WHERE e.PERSONNEL_ID = ? AND e.EXT_DATE BETWEEN ]] .. sql_filetime(from_date) ..
      [[ AND ]] .. sql_filetime(to_date) .. [[
ORDER BY e.EXT_DATE DESC, e.TIME_FROM DESC
LIMIT 300
]], { personnel.personnel_id }, 9)
        if rows == nil then
            events_err = tostring(query_err)
            return
        end
        for _, r in ipairs(rows) do
            table.insert(events, {
                jdate = jalali_date(r[1]) or "—",
                time_from = seconds_to_hm(r[2]),
                time_to = seconds_to_hm(r[3]),
                duration_minutes = tonumber(r[4]) or 0,
                ext_type = tonumber(r[5]) or 0,
                enabled = tonumber(r[6]) or 0,
                machine_from = r[7] or "—",
                machine_to = r[8] or "—",
                comment = r[9] or ""
            })
        end
    end)
    if not ok then events_err = tostring(err) end
end

-- ── section: requests (leave / mission / overtime / telework) ────────

local requests = {}
local requests_err = nil

-- برچسب وضعیت‌ها: کدها روی این پلتفرم در مستندات بات‌های HR (۳۷۹ اضافه‌کاری: پیش‌نویس/تایید/رد)
-- همین ترتیب را دارند. برای این‌که هیچ برچسبی «حدسی و غیرقابل‌راستی‌آزمایی» نباشد، کد خام هم در
-- ستون جداگانه نمایش داده می‌شود تا با پنل رسمی قابل تطبیق باشد.
local function request_status_label(code)
    local n = tonumber(code)
    if n == nil then return "نامشخص" end
    if n == 0 then return "در انتظار تایید" end
    if n == 1 then return "تایید شده" end
    if n == 2 then return "رد شده" end
    if n == 3 then return "لغو شده" end
    return "وضعیت " .. n
end

do
    local ok, err = pcall(function()
        -- مرخصی و ماموریت: hr_vacation. نام نوع از hr_vacation_type خوانده می‌شود؛ چون در این
        -- جدول هم ستون ID و هم ستون TYPE وجود دارد و مشخص نیست hr_vacation.TYPE به کدام ارجاع
        -- می‌دهد، هر دو LEFT JOIN می‌شوند و اولین نام غیرخالی برداشته می‌شود.
        local rows, query_err = fetch_rows([[
SELECT
  v.ID,
  COALESCE(NULLIF(vt_by_type.NAME, ''), NULLIF(vt_by_id.NAME, ''), N'مرخصی/ماموریت') AS type_name,
  COALESCE(REPORT_FN_JDATE(v.DATE_VACATOIN, '-'), '') AS jdate,
  ]] .. sql_seconds_of_day("v.TIME_FROM") .. [[ AS time_from,
  ]] .. sql_seconds_of_day("v.TIME_TO") .. [[ AS time_to,
  ]] .. sql_ticks_to_minutes("v.TOTAL_TIME") .. [[ AS total_minutes,
  COALESCE(v.STATUS, 0) AS status_code,
  COALESCE(v.DESCRIPTION, '') AS description,
  COALESCE(REPORT_FN_JDATE(v.DATE_CREATE, '-'), '') AS created_j,
  COALESCE(v.KIND, 0) AS kind_code,
  (SELECT COUNT(*) FROM hr_leave_verify lv WHERE lv.LEAVE_ID = v.ID) AS verify_count,
  (SELECT COUNT(*) FROM hr_leave_verify lv WHERE lv.LEAVE_ID = v.ID AND lv.STATUS = 1) AS verify_done,
  v.DATE_VACATOIN AS day_raw
FROM hr_vacation v
LEFT JOIN hr_vacation_type vt_by_type ON vt_by_type.TYPE = v.TYPE
LEFT JOIN hr_vacation_type vt_by_id ON vt_by_id.ID = v.TYPE
WHERE v.PERSONNEL_ID = ? AND v.DATE_VACATOIN BETWEEN ]] .. sql_filetime(from_date) ..
      [[ AND ]] .. sql_filetime(to_date) .. [[
ORDER BY v.DATE_VACATOIN DESC, v.ID DESC
LIMIT 200
]], { personnel.personnel_id }, 13)
        if rows == nil then
            requests_err = tostring(query_err)
        else
            for _, r in ipairs(rows) do
                table.insert(requests, {
                    id = tonumber(r[1]),
                    family = "مرخصی و ماموریت",
                    type_name = r[2] or "مرخصی/ماموریت",
                    jdate = jalali_date(r[3]) or "—",
                    time_from = seconds_to_hm(r[4]),
                    time_to = seconds_to_hm(r[5]),
                    total_minutes = tonumber(r[6]) or 0,
                    status_code = tonumber(r[7]) or 0,
                    status = request_status_label(r[7]),
                    description = r[8] or "",
                    created = jalali_date(r[9]) or "—",
                    verify_count = tonumber(r[11]) or 0,
                    verify_done = tonumber(r[12]) or 0,
                    sort_key = tonumber(r[13]) or 0
                })
            end
        end

        local ot_rows = fetch_rows([[
SELECT r.ID,
  COALESCE(REPORT_FN_JDATE(r.DAY_DATE, '-'), '') AS jdate,
  ]] .. sql_seconds_of_day("r.TIME_FROM") .. [[ AS time_from,
  ]] .. sql_seconds_of_day("r.TIME_TO") .. [[ AS time_to,
  ]] .. sql_ticks_to_minutes("GREATEST(r.TIME_TO - r.TIME_FROM, 0)") .. [[ AS total_minutes,
  COALESCE(r.STATUS, 0) AS status_code,
  COALESCE(r.DESCRIPTION, '') AS description,
  COALESCE(REPORT_FN_JDATE(r.DATE_CREATE, '-'), '') AS created_j,
  r.DAY_DATE AS day_raw
FROM hr_overtime_request r
WHERE r.PERSONNEL_ID = ? AND r.DAY_DATE BETWEEN ]] .. sql_filetime(from_date) ..
      [[ AND ]] .. sql_filetime(to_date) .. [[
ORDER BY r.DAY_DATE DESC, r.ID DESC
LIMIT 100
]], { personnel.personnel_id }, 9)
        if ot_rows ~= nil then
            for _, r in ipairs(ot_rows) do
                table.insert(requests, {
                    id = tonumber(r[1]),
                    family = "اضافه‌کاری",
                    type_name = "درخواست اضافه‌کاری",
                    jdate = jalali_date(r[2]) or "—",
                    time_from = seconds_to_hm(r[3]),
                    time_to = seconds_to_hm(r[4]),
                    total_minutes = tonumber(r[5]) or 0,
                    status_code = tonumber(r[6]) or 0,
                    status = request_status_label(r[6]),
                    description = r[7] or "",
                    created = jalali_date(r[8]) or "—",
                    verify_count = 0,
                    verify_done = 0,
                    sort_key = tonumber(r[9]) or 0
                })
            end
        end

        local tw_rows = fetch_rows([[
SELECT r.ID,
  COALESCE(REPORT_FN_JDATE(r.DAY_DATE, '-'), '') AS jdate,
  ]] .. sql_seconds_of_day("r.TIME_FROM") .. [[ AS time_from,
  ]] .. sql_seconds_of_day("r.TIME_TO") .. [[ AS time_to,
  ]] .. sql_ticks_to_minutes("GREATEST(r.TIME_TO - r.TIME_FROM, 0)") .. [[ AS total_minutes,
  COALESCE(r.STATUS, 0) AS status_code,
  COALESCE(r.DESCRIPTION, '') AS description,
  COALESCE(REPORT_FN_JDATE(r.DATE_CREATE, '-'), '') AS created_j,
  r.DAY_DATE AS day_raw
FROM hr_telework_request r
WHERE r.PERSONNEL_ID = ? AND r.DAY_DATE BETWEEN ]] .. sql_filetime(from_date) ..
      [[ AND ]] .. sql_filetime(to_date) .. [[
ORDER BY r.DAY_DATE DESC, r.ID DESC
LIMIT 100
]], { personnel.personnel_id }, 9)
        if tw_rows ~= nil then
            for _, r in ipairs(tw_rows) do
                table.insert(requests, {
                    id = tonumber(r[1]),
                    family = "دورکاری",
                    type_name = "درخواست دورکاری",
                    jdate = jalali_date(r[2]) or "—",
                    time_from = seconds_to_hm(r[3]),
                    time_to = seconds_to_hm(r[4]),
                    total_minutes = tonumber(r[5]) or 0,
                    status_code = tonumber(r[6]) or 0,
                    status = request_status_label(r[6]),
                    description = r[7] or "",
                    created = jalali_date(r[8]) or "—",
                    verify_count = 0,
                    verify_done = 0,
                    sort_key = tonumber(r[9]) or 0
                })
            end
        end

        table.sort(requests, function(a, b) return (a.sort_key or 0) > (b.sort_key or 0) end)
    end)
    if not ok then requests_err = tostring(err) end
end

local request_counts = { pending = 0, approved = 0, rejected = 0, total = #requests }
for _, r in ipairs(requests) do
    if r.status_code == 1 then
        request_counts.approved = request_counts.approved + 1
    elseif r.status_code == 2 then
        request_counts.rejected = request_counts.rejected + 1
    elseif r.status_code == 0 then
        request_counts.pending = request_counts.pending + 1
    end
end

-- ── section: leave balance ───────────────────────────────────────────
-- منبع اول: API رسمی /api/hr/leaveTransferGet (ماژول ۱۳، schema تاییدشده ۱۴۰۵/۰۶/۰۶)
--   درخواست: {id, org_id, date_to, personnel_ids[]} — id (شناسهٔ حکم) و date_to اجباری نیستند
--   پاسخ:   {data:[{value, personnel_id}], error:{status,message}, success}
-- منبع دوم (fallback): جدول hr_leave_remained_records، اگر API خطا داد یا رکوردی برنگرداند.
-- واحد value در پورتال اعلام نشده؛ مثل بقیهٔ مدت‌های این اسکیما tick در نظر گرفته می‌شود. مقدار خام
-- در خروجی format=json می‌ماند تا در اولین اجرای واقعی با پنل رسمی مقایسه و در صورت نیاز اصلاح شود.

local leave_balance = nil
local leave_balance_period = nil
local leave_balance_source = nil
local leave_balance_raw = nil
local leave_balance_err = nil

do
    local ok, err = pcall(function()
        local response, api_err = call_teamyar_api(HR_MODULE_ID, "/api/hr/leaveTransferGet", {
            personnel_ids = { personnel.personnel_id },
            org_id = personnel.org_id or 0,
            date_to = to_date
        })
        if api_err == nil and type(response) == "table" then
            local rows = response.data
            if type(rows) == "table" then
                for _, item in ipairs(rows) do
                    if type(item) == "table" then
                        local item_personnel = tonumber(item.personnel_id)
                        if item_personnel == nil or item_personnel == personnel.personnel_id then
                            local raw_value = tonumber(item.value)
                            if raw_value ~= nil then
                                leave_balance_raw = raw_value
                                leave_balance = {
                                    remained_minutes = math.floor((raw_value / 10000000 / 60) + 0.5)
                                }
                                leave_balance_source = "api"
                                break
                            end
                        end
                    end
                end
            end
        elseif api_err ~= nil then
            leave_balance_err = "API مانده مرخصی: " .. tostring(api_err)
        end

        if leave_balance ~= nil then return end

        local rows, query_err = fetch_rows([[
SELECT ]] .. sql_ticks_to_minutes("rec.LEAVE_REMAINED") .. [[ AS remained_minutes,
       ]] .. sql_ticks_to_minutes("rec.PAID_LEAVE_REMAINED") .. [[ AS paid_remained_minutes,
       COALESCE(REPORT_FN_JDATE(lst.DATE_FROM, '-'), '') AS date_from_j,
       COALESCE(REPORT_FN_JDATE(lst.DATE_TO, '-'), '') AS date_to_j
FROM hr_leave_remained_records rec
JOIN hr_leave_remained lst ON lst.ID = rec.LIST_ID
WHERE rec.PERSONNEL_ID = ?
ORDER BY lst.DATE_TO DESC, lst.ID DESC
LIMIT 1
]], { personnel.personnel_id }, 4)
        if rows == nil then
            leave_balance_err = (leave_balance_err and (leave_balance_err .. " | ") or "") ..
                tostring(query_err)
            return
        end
        if #rows > 0 then
            leave_balance = {
                remained_minutes = tonumber(rows[1][1]) or 0,
                paid_remained_minutes = tonumber(rows[1][2]) or 0
            }
            leave_balance_period = (jalali_date(rows[1][3]) or "—") .. " تا " ..
                (jalali_date(rows[1][4]) or "—")
            leave_balance_source = "db"
        end
    end)
    if not ok then leave_balance_err = tostring(err) end
end

local leave_balance_note = "برای این پرسنل دوره‌ای برای محاسبهٔ مانده ثبت نشده است"
if leave_balance_source == "api" then
    leave_balance_note = "منبع: API رسمی مانده مرخصی سامانه"
elseif leave_balance_source == "db" then
    leave_balance_note = "دورهٔ محاسبه: " .. (leave_balance_period or "—")
end

-- ── section: profile extras (education) ──────────────────────────────

local education_label = nil
do
    pcall(function()
        local rows = fetch_rows([[
SELECT MAX(CASE e.education
        WHEN 5 THEN 5 WHEN 4 THEN 4 WHEN 3 THEN 3 WHEN 2 THEN 2 WHEN 1 THEN 1 WHEN 6 THEN 0
        ELSE -1 END) AS rnk
FROM hr_education e
WHERE e.PERSONNEL_ID = ?
]], { personnel.personnel_id }, 1)
        if rows ~= nil and #rows > 0 then
            local rnk = tonumber(rows[1][1])
            local labels = { [0] = "زیر دیپلم", [1] = "دیپلم", [2] = "کاردانی",
                             [3] = "کارشناسی", [4] = "کارشناسی ارشد", [5] = "دکتری" }
            if rnk ~= nil then education_label = labels[rnk] end
        end
    end)
end

-- ── section: today, birthdays and the daily message ──────────────────

local today_meta = { jdate = "—", jday_name = "—", jyday = 0, jmonth = 0, jmday = 0 }
local birthdays_today = {}
local birthdays_month = {}
local birth_setting = nil
local celebration_err = nil

do
    local ok, err = pcall(function()
        local rows = fetch_rows([[
SELECT COALESCE(REPORT_FN_JDATE(rd.DATEKEY, '-'), '') AS jdate, COALESCE(rd.JTDAY, '—') AS jday_name,
       COALESCE(rd.JYDAY, 0) AS jyday, COALESCE(rd.JMONTH, 0) AS jmonth,
       COALESCE(rd.JMDAY, 0) AS jmday, COALESCE(rd.JTMONTH, '—') AS jmonth_name
FROM report_dimdate rd
WHERE rd.DATEKEY = (]] .. sql_filetime(to_date) .. [[ - MOD(]] .. sql_filetime(to_date) ..
      [[, 864000000000))
LIMIT 1
]], {}, 6)
        if rows ~= nil and #rows > 0 then
            today_meta.jdate = jalali_date(rows[1][1]) or "—"
            today_meta.jday_name = rows[1][2] or "—"
            today_meta.jyday = tonumber(rows[1][3]) or 0
            today_meta.jmonth = tonumber(rows[1][4]) or 0
            today_meta.jmday = tonumber(rows[1][5]) or 0
            today_meta.jmonth_name = rows[1][6] or "—"
        end

        if today_meta.jmonth > 0 then
            -- تولد همکاران فعال سازمانِ همین پرسنل، بر پایهٔ ماه/روز شمسی تاریخ تولد
            -- (profile_user_info.BIRTHDAY → report_dimdate). HIRING_STATUS = 2 همان فیلتر
            -- «شاغل» است که بات ۴۴۴ و hr_dashboard_report_bot استفاده می‌کنند.
            local bd_rows = fetch_rows([[
SELECT p.FULLNAME, COALESCE(rd.JMDAY, 0) AS jmday, COALESCE(rd.JTMONTH, '—') AS jmonth_name,
       COALESCE(rd.JMONTH, 0) AS jmonth, COALESCE(REPORT_FN_JDATE(uf.BIRTHDAY, '-'), '') AS birth_j,
       COALESCE(ou.NAME, N'—') AS unit_name, h.PERSONNEL_ID
FROM hr_personnels h
JOIN profile_main p ON p.id = h.PROFILE_ID
JOIN profile_user_info uf ON uf.id = p.id
JOIN report_dimdate rd ON rd.DATEKEY = (uf.BIRTHDAY - MOD(uf.BIRTHDAY, 864000000000))
LEFT JOIN hr_personnel_order o ON o.ID = (
  SELECT o2.ID FROM hr_personnel_order o2
  WHERE o2.PERSONNEL_ID = h.PERSONNEL_ID
    AND o2.DATE_FROM <= ]] .. sql_filetime(to_date) .. [[
    AND o2.DATE_TO >= ]] .. sql_filetime(to_date) .. [[
  ORDER BY o2.ID DESC LIMIT 1)
LEFT JOIN org_organization_unit oou ON oou.ID = o.UNIT_ID
LEFT JOIN org_units ou ON ou.ID = oou.UNIT_ID
WHERE h.HIRING_STATUS = 2 AND h.ORG_ID = ? AND uf.BIRTHDAY > 0 AND rd.JMONTH = ?
ORDER BY rd.JMDAY, p.FULLNAME
LIMIT 200
]], { personnel.org_id or 0, today_meta.jmonth }, 7)
            if bd_rows ~= nil then
                for _, r in ipairs(bd_rows) do
                    local entry = {
                        name = r[1] or "-",
                        jmday = tonumber(r[2]) or 0,
                        jmonth_name = r[3] or "—",
                        birth_date = jalali_date(r[5]) or "—",
                        unit_name = r[6] or "—",
                        personnel_id = tonumber(r[7]),
                        is_self = (tonumber(r[7]) == personnel.personnel_id)
                    }
                    entry.display_date = tostring(entry.jmday) .. " " .. entry.jmonth_name
                    table.insert(birthdays_month, entry)
                    if entry.jmday == today_meta.jmday then
                        table.insert(birthdays_today, entry)
                    end
                end
            end
        end

        local bs_rows = fetch_rows([[
SELECT COALESCE(ENABLE_POPUP, 0), COALESCE(ENABLE_SMS, 0), COALESCE(ENABLE_EMAIL, 0)
FROM hr_birth_setting WHERE ORG_ID = ? LIMIT 1
]], { personnel.org_id or 0 }, 3)
        if bs_rows ~= nil and #bs_rows > 0 then
            birth_setting = {
                popup = tonumber(bs_rows[1][1]) == 1,
                sms = tonumber(bs_rows[1][2]) == 1,
                email = tonumber(bs_rows[1][3]) == 1
            }
        end
    end)
    if not ok then celebration_err = tostring(err) end
end

-- پیام روزانه: چرخشی و قطعی بر پایهٔ روزِ سال شمسی (JYDAY از report_dimdate) — نه تصادفی، تا همهٔ
-- همکاران در یک روز پیام یکسان ببینند و پیام هر روز عوض شود.
local DAILY_MESSAGES = {
    -- فروردین
    "سال نو مبارک. امسال قرار نیست همه‌چیز یک‌شبه عوض شود؛ یک قدم بهتر از پارسال کافی است.", -- 1
    "روزهای اول سال برای برنامه‌ریزی است، نه برای فشار آوردن به خودت.", -- 2
    "یک هدف کوچک برای امسال بنویس که واقعاً به آن برسی؛ بهتر از ده هدف بزرگ روی کاغذ است.", -- 3
    "دید و بازدید عید هم بخشی از کار است: رابطه‌های خوب، کار سال را راحت‌تر می‌کنند.", -- 4
    "اگر این روزها ریتم کارت کند است، طبیعی است. ریتم برمی‌گردد.", -- 5
    "بهار یعنی همه‌چیز از نو شروع می‌شود؛ پروژه‌ای که پارسال زمین ماند هم می‌تواند.", -- 6
    "امسال یک مهارت تازه یاد بگیر — حتی اگر ماهی یک ساعت.", -- 7
    "تعطیلات برای برگشتن با انرژی است، نه برای عقب افتادن. عقب نیفتادی.", -- 8
    "اولین روز کاری بعد از تعطیلات را با ساده‌ترین کار شروع کن.", -- 9
    "میز کارت را مرتب کن؛ ذهن مرتب از همین‌جا شروع می‌شود.", -- 10
    "اگر همکار تازه‌ای به تیم اضافه شده، اولین کسی باش که به او خوش‌آمد می‌گوید.", -- 11
    "سالی که گذشت را یک بار مرور کن: چه چیزی واقعاً جواب داد؟", -- 12
    "روز طبیعت مبارک. یک روز دور از صفحه‌نمایش، بهترین هدیه به ذهنت است.", -- 13
    "برگشتن به کار بعد از یک روز در طبیعت، همیشه آسان‌تر است.", -- 14
    "نیمهٔ فروردین است؛ یکی از هدف‌های امسالت را همین هفته شروع کن.", -- 15
    "روز را با تقویم شروع کن، نه با ایمیل. تقویم می‌گوید چه چیزی مهم است.", -- 16
    "اگر کاری را مدام عقب می‌اندازی، شاید فقط باید کوچکش کنی.", -- 17
    "بهار وقت خوبی است برای مرتب کردن فایل‌ها و پوشه‌هایی که سال قبل رها شدند.", -- 18
    "هفته‌ای یک بار با کسی که کمتر می‌بینی‌اش قهوه بخور؛ بهترین ایده‌ها همان‌جا می‌آیند.", -- 19
    "پیشرفت همیشه دیدنی نیست؛ گاهی فقط یعنی امروز کمتر گیر کردی.", -- 20
    "اگر امروز خسته‌ای، کارهای فکری را بگذار برای فردا و کارهای ساده را ببند.", -- 21
    "هوای خوب بهار را از دست نده؛ ناهار را بیرون بخور.", -- 22
    "سوال پرسیدن در روزهای اول یک کار، ارزان‌تر از اصلاح کردن در روزهای آخر است.", -- 23
    "یک کار نیمه‌تمام از پارسال را انتخاب کن و همین هفته تمامش کن.", -- 24
    "تیم خوب یعنی کسی تنها گیر نمی‌کند. اگر گیر کردی، بگو.", -- 25
    "برنامهٔ امروزت را صبح بنویس و شب تیک بزن. همین دو دقیقه، روزت را عوض می‌کند.", -- 26
    "کاری که بلدی را به یک نفر دیگر هم یاد بده؛ دانش وقتی تقسیم شود، بیشتر می‌شود.", -- 27
    "آخر فروردین است؛ ببین از برنامهٔ اول سال چقدر جلو رفته‌ای — بدون سرزنش، فقط برای اصلاح.", -- 28
    "کار تکراری داری که می‌شود خودکارش کرد؟ همین امروز نیم ساعت رویش بگذار.", -- 29
    "تشکر از کسی که کارش را خوب انجام داد، هیچ هزینه‌ای ندارد و همه‌چیز را عوض می‌کند.", -- 30
    "ماه اول سال تمام شد. شروع خوب یعنی همین‌که هنوز اینجایی.", -- 31
    -- اردیبهشت
    "اردیبهشت، بهترین ماه سال است. یک بار هم که شده کار را زودتر تمام کن و از هوا لذت ببر.", -- 32
    "امروز به‌جای ایمیل، حضوری حرف بزن. سریع‌تر است.", -- 33
    "یک جلسهٔ اضافه را حذف کن؛ به همه لطف کرده‌ای.", -- 34
    "اگر کاری بیشتر از دو دقیقه وقت نمی‌برد، همین حالا انجامش بده.", -- 35
    "نه گفتن به کار اضافه، یعنی بله گفتن به کاری که واقعاً مهم است.", -- 36
    "کیفیت کار با ساعت کار یکی نیست. هشت ساعت متمرکز از دوازده ساعت پراکنده بهتر است.", -- 37
    "یک نفر امروز به کمکت نیاز دارد و رویش نمی‌شود بگوید. تو بپرس.", -- 38
    "کار تیمی یعنی وقتی کار خوب پیش رفت، اسم همه برده شود.", -- 39
    "تمرکز یعنی بستن ده تب اضافه. همین حالا امتحان کن.", -- 40
    "کار، وقتی معنا دارد که کسی از نتیجه‌اش راحت‌تر شود. امروز کارِ چه کسی را راحت می‌کنی؟", -- 41
    "روز کارگر مبارک — به همهٔ کسانی که کار با دستشان ساخته می‌شود.", -- 42
    "روز معلم مبارک. هرکسی چیزی به تو یاد داده معلم توست؛ امروز یادی از او کن.", -- 43
    "یاد گرفتن تمام نمی‌شود. هر پروژه یک کلاس است.", -- 44
    "نصف اردیبهشت گذشت؛ هنوز وقت هست برای کاری که می‌خواستی شروع کنی.", -- 45
    "اگر جلسه‌ای بدون نتیجه تمام شد، ایراد از آدم‌ها نیست، از نداشتن دستور جلسه است.", -- 46
    "بازخورد دادن سخت است، نگفتنش سخت‌تر. محترمانه بگو.", -- 47
    "بازخورد گرفتن هم مهارت است: اول گوش کن، بعد توضیح بده.", -- 48
    "کارت را طوری بنویس که اگر فردا نبودی، کسی گیج نشود.", -- 49
    "مستندسازی، هدیه‌ای است که به خودِ شش‌ماه‌بعدت می‌دهی.", -- 50
    "یک کار سخت را صبح انجام بده؛ بقیهٔ روز سبک می‌شود.", -- 51
    "اگر خسته‌ای، ده دقیقه پیاده‌روی بهتر از یک قهوهٔ دیگر است.", -- 52
    "تفاوت آدم حرفه‌ای، در روزهای بی‌حوصلگی معلوم می‌شود.", -- 53
    "یک کار خوبِ امروز، بهتر از یک برنامهٔ عالی برای فرداست.", -- 54
    "اگر می‌توانی کار کسی را راحت‌تر کنی، همان مهم‌ترین کار امروزت است.", -- 55
    "جواب دادن سریع به همکار، خودش یک نوع احترام است.", -- 56
    "تقویمت را نگاه کن: وقتی برای فکر کردن گذاشته‌ای یا فقط جلسه؟", -- 57
    "کمال‌گرایی دشمن تحویل دادن است. خوب و تمام‌شده، بهتر از عالی و نیمه‌کاره است.", -- 58
    "اگر امروز چیزی یاد گرفتی، یک خط بنویسش. سال دیگر ممنون خودت می‌شوی.", -- 59
    "آدم‌ها یادشان می‌ماند چطور با آن‌ها رفتار کردی، نه اینکه چقدر سریع بودی.", -- 60
    "یک کار را کامل ببند، بعد سراغ بعدی برو. نیمه‌کارهای زیاد انرژی می‌برند.", -- 61
    "اردیبهشت رو به پایان است؛ یک عکس از این هوا بگیر، وسط تابستان لازمت می‌شود.", -- 62
    -- خرداد
    "خرداد شروع می‌شود و هوا گرم‌تر؛ کار سنگین را برای ساعت‌های خنک‌تر بگذار.", -- 63
    "آب بیشتری بخور. ساده است ولی روی تمرکزت اثر دارد.", -- 64
    "اگر بچه‌ات امتحان دارد، بگو؛ تیم می‌فهمد.", -- 65
    "حواست به همکاری باشد که این روزها ساکت‌تر از همیشه است.", -- 66
    "کار خوب تکرارشدنی است. اگر یک بار جواب داد، بنویس چطور.", -- 67
    "سه ماه از سال گذشت؛ یک ربع‌سال کامل. چه چیزی واقعاً جلو رفت؟", -- 68
    "برنامهٔ سه‌ماههٔ بعدی را ساده بگیر: سه کار، نه سی کار.", -- 69
    "جلسه‌ای که می‌شد ایمیل باشد، وقت همه را گرفته. دفعهٔ بعد ایمیل بفرست.", -- 70
    "اگر کاری را دوست نداری ولی لازم است، اولش انجامش بده تا فکرت را نخورد.", -- 71
    "کسی که سوال می‌پرسد ضعیف نیست؛ کسی که نمی‌پرسد و اشتباه می‌کند گران‌تر تمام می‌شود.", -- 72
    "یک ساعت بدون اعلان کار کن. ببین چقدر فرق دارد.", -- 73
    "کارِ درست را انجام دادن، از سریع انجام دادن مهم‌تر است.", -- 74
    "نیمهٔ خرداد است؛ اگر مرخصی تابستان می‌خواهی، همین حالا هماهنگ کن.", -- 75
    "مرخصی گرفتن حق توست، نه لطف کسی. ولی زودتر هماهنگ کن تا کار کسی نخوابد.", -- 76
    "ذهن هم مثل بدن، بعد از تلاش زیاد به ریکاوری نیاز دارد.", -- 77
    "یک کار قدیمی که همه از آن می‌نالند را امروز درست کن.", -- 78
    "اگر همه‌چیز فوری است، یعنی هیچ‌چیز فوری نیست. اولویت‌بندی کن.", -- 79
    "صادق بودن دربارهٔ زمان‌بندی، از خوش‌بین بودن بهتر است.", -- 80
    "تحویل به‌موقعِ کار متوسط، از تحویل دیرِ کار عالی ارزشمندتر است.", -- 81
    "یک نفر امروز کارش را بی‌سروصدا خوب انجام داد. پیدایش کن و بگو دیدی.", -- 82
    "با خودت هم صادق باش: کدام کار را داری از آن فرار می‌کنی؟", -- 83
    "تغییر عادت سخت است؛ از یک عادت کوچک شروع کن.", -- 84
    "کار گروهی یعنی گاهی راه دیگری را قبول کنی، حتی اگر راه خودت بهتر بود.", -- 85
    "اگر پروژه‌ای بوی خطر می‌دهد، همین حالا بگو. زودتر گفتن یعنی ارزان‌تر حل کردن.", -- 86
    "فهرستی از کارهایی بنویس که دیگر لازم نیست انجام شوند. حذف هم پیشرفت است.", -- 87
    "آخر هفته را واقعاً آخر هفته کن؛ ذهن خاموش‌نشده، شنبه گران تمام می‌شود.", -- 88
    "کسی که تازه آمده هنوز سوال‌های ساده دارد. صبور باش؛ تو هم داشتی.", -- 89
    "کیفیت رابطه‌های کاری، سرعت کار را تعیین می‌کند.", -- 90
    "آخرین روزهای بهار است؛ یک کار نیمه‌تمام بهاری را ببند.", -- 91
    "تابستان دارد می‌آید و ریتم کار عوض می‌شود. آماده باش، غافلگیر نشو.", -- 92
    "بهار تمام شد. ربع اول سال را بستی — همین یعنی جلو رفتی.", -- 93
    -- تیر
    "تابستان شروع شد. گرما بهانه نیست، ولی حواست به خودت باشد.", -- 94
    "ساعت‌های اول صبح بهترین ساعت‌های تابستان‌اند. کار مهم را همان‌جا بگذار.", -- 95
    "اگر همکارت مرخصی است، کارش را زمین نگذار — و از او هم همین انتظار را داشته باش.", -- 96
    "جای خالی یک نفر در تیم، فرصت یاد گرفتن کار اوست.", -- 97
    "یک لیوان آب، یک کشش کوتاه، و برگرد سر کار.", -- 98
    "کار از راه دور یا حضوری فرقی نمی‌کند؛ قابل‌اعتماد بودن مهم است.", -- 99
    "صدمین روز سال است. صد روز دیگر هم می‌گذرد؛ امروز را حساب کن.", -- 100
    "اگر برنامهٔ سالت را فراموش کرده‌ای، همین حالا یک بار بازش کن.", -- 101
    "کارهای تکراری را دسته‌بندی کن و یکجا انجام بده؛ وقت کمتری می‌برد.", -- 102
    "تمرکز مهارت است نه استعداد. با تمرین بیشتر می‌شود.", -- 103
    "یک کار سخت را به سه کار کوچک بشکن. ترسش می‌ریزد.", -- 104
    "اگر جلسه طول کشید، احتمالاً تصمیم‌گیرنده در جلسه نبوده.", -- 105
    "تصمیم گرفتن با اطلاعات ناقص بخشی از کار است. منتظر کامل شدن نمان.", -- 106
    "اشتباه را زود اعلام کن؛ پنهانش کنی بزرگ‌تر می‌شود.", -- 107
    "کسی که اشتباهش را می‌گوید قابل‌اعتمادتر است، نه ضعیف‌تر.", -- 108
    "یک روز در هفته را بدون جلسه نگه دار. کار عمیق همان‌جا اتفاق می‌افتد.", -- 109
    "نیمهٔ تیر است؛ گرمای اوج نزدیک است. برنامهٔ کاری‌ات را واقع‌بینانه ببند.", -- 110
    "سلام کردن به همه، حتی کسانی که با آن‌ها کار نداری، فضا را عوض می‌کند.", -- 111
    "یک کار خوبِ کوچک، از یک ایدهٔ بزرگِ اجرانشده ارزشمندتر است.", -- 112
    "اگر امروز حالت خوب نیست، لازم نیست وانمود کنی. فقط کارِ سبک‌تر انتخاب کن.", -- 113
    "به قولت دربارهٔ زمان، مثل قولت دربارهٔ کیفیت پایبند باش.", -- 114
    "ماهی یک بار مسیر کارت را با مدیرت مرور کن. حدس زدن انرژی می‌برد.", -- 115
    "هیچ‌کس ذهن تو را نمی‌خواند. اگر چیزی می‌خواهی، بگو.", -- 116
    "کارِ دیده‌نشده هم اثر دارد؛ زیربنا همیشه زیر خاک است.", -- 117
    "یک همکار را امروز به ناهار دعوت کن. همین.", -- 118
    "کاری که بلد نیستی را قبول کن، ولی بگو که بلد نیستی و می‌خواهی یاد بگیری.", -- 119
    "سرعت بدون جهت فقط خستگی است. مطمئن شو مسیر درست است.", -- 120
    "یک ساعت مرتب کردن اطلاعات، ده ساعت جست‌وجو را حذف می‌کند.", -- 121
    "اگر روزت خراب شد، لازم نیست هفته‌ات را هم خراب کنی.", -- 122
    "آخر تیر است؛ نصف تابستان مانده. برنامهٔ مرخصی‌ات را قطعی کن.", -- 123
    "ماه چهارم تمام شد؛ یک‌سوم سال گذشت.", -- 124
    -- مرداد
    "مرداد، گرم‌ترین ماه. انتظار زیاد از خودت در گرما منصفانه نیست.", -- 125
    "کولر خنک است ولی هوای تازه لازم داری؛ چند دقیقه بیرون برو.", -- 126
    "تابستان وقت خوبی برای کارهای عقب‌افتاده است، چون جلسه‌ها کمترند.", -- 127
    "یک فرایند کاری را ساده کن؛ همه سال بعد ازت ممنون می‌شوند.", -- 128
    "تمرکز روی چیزی که در کنترل توست، آرامش می‌آورد.", -- 129
    "نگرانی برای چیزی که هنوز نشده، انرژی امروز را می‌گیرد.", -- 130
    "یک کار را امروز کامل تمام کن، حتی اگر کوچک باشد.", -- 131
    "کسی که همیشه در دسترس است، معمولاً وقت فکر کردن ندارد. مرزت را داشته باش.", -- 132
    "«الان نمی‌توانم، دو ساعت دیگر» هم یک جواب محترمانه است.", -- 133
    "اگر پیام کاری بعد از ساعت کار می‌فرستی، بنویس «فوری نیست».", -- 134
    "استراحت ناهار را واقعاً استراحت کن؛ پشت میز غذا خوردن استراحت نیست.", -- 135
    "نصف مرداد گذشت. یک کار خوب برای خودت انجام بده، نه فقط برای کار.", -- 136
    "یاد گرفتن از همکار، سریع‌ترین راه یاد گرفتن است.", -- 137
    "اگر کسی کارش را بهتر از تو انجام می‌دهد، ازش بپرس چطور.", -- 138
    "رقابت درون تیم، تیم را کند می‌کند. همکاری سریع‌ترش می‌کند.", -- 139
    "ایدهٔ کوچکی برای بهتر شدن کارت داری؟ بنویس و بفرست.", -- 140
    "هیچ ایده‌ای احمقانه نیست وقتی هدفش بهتر شدن کار باشد.", -- 141
    "صبر هم مهارت است؛ بعضی کارها فقط زمان می‌خواهند.", -- 142
    "اگر امروز کند پیش رفتی، شاید داری چیز سختی یاد می‌گیری.", -- 143
    "سکوت طولانی در کار تیمی معمولاً یعنی کسی گیر کرده. بپرس.", -- 144
    "یک نفر امروز به یک تشویق ساده نیاز دارد. حدس بزن کیست.", -- 145
    "کاری که به تعویق می‌اندازی هر روز سنگین‌تر می‌شود. امروز شروعش کن.", -- 146
    "تفاوت شلوغی و بهره‌وری را بدان؛ شلوغی خستگی می‌آورد، بهره‌وری نتیجه.", -- 147
    "جلسهٔ تکراری‌ای در تقویمت هست که دیگر لازم نیست؟ حذفش کن.", -- 148
    "اگر کارت را دوست داری، مراقب باش زیاده‌روی نکنی. فرسودگی سراغ همه می‌آید.", -- 149
    "صد و پنجاهمین روز سال. ایستادن و نگاه کردن به مسیر، ضرر نیست.", -- 150
    "تشکر کتبی از یک همکار، بیشتر از تشکر شفاهی می‌ماند.", -- 151
    "یک کار را طوری انجام بده که سال بعد هم به آن افتخار کنی.", -- 152
    "کیفیت، جمعِ تصمیم‌های کوچکِ درست است.", -- 153
    "آخر مرداد است؛ گرما کم‌کم می‌شکند. ریتمت را دوباره تنظیم کن.", -- 154
    "ماه پنجم تمام شد. دو ماه دیگر، نصف سال پشت سر است.", -- 155
    -- شهریور
    "شهریور، آخرین ماه تابستان. کارهای تابستانی‌ات را ببند.", -- 156
    "مدرسه‌ها نزدیک است؛ اگر بچه داری، برنامه‌ات را از حالا تنظیم کن.", -- 157
    "نیمهٔ دوم سال نزدیک است. هدف‌های اول سال را یک بار مرور کن.", -- 158
    "اگر به هدفی نرسیدی، یا هدف بزرگ بوده یا مسیر اشتباه. هیچ‌کدام یعنی تو ناتوانی نیست.", -- 159
    "کار خوب نتیجهٔ تکرار است، نه الهام.", -- 160
    "یک مهارت را انتخاب کن و تا آخر سال رویش کار کن.", -- 161
    "مرتب کردن ایمیل‌های عقب‌افتاده، ذهن را سبک می‌کند.", -- 162
    "کارهایی که هیچ‌وقت انجام نمی‌دهی را از فهرست حذف کن.", -- 163
    "اگر پروژه‌ای بی‌نتیجه مانده، تمامش کن یا رسماً ببندش. بلاتکلیفی بدترین حالت است.", -- 164
    "یک ساعت برنامه‌ریزی، ده ساعت دوباره‌کاری را حذف می‌کند.", -- 165
    "با کسی که با او اختلاف داشتی حرف بزن. کدورت کاری، کار را کند می‌کند.", -- 166
    "عذرخواهی کردن اعتبار را کم نمی‌کند؛ زیادش می‌کند.", -- 167
    "کسی که همیشه حق با اوست، معمولاً کسی است که کم می‌پرسد.", -- 168
    "یک تصمیم قدیمی را بازبینی کن؛ شرایط عوض شده است.", -- 169
    "نیمهٔ شهریور. سه ماه تا پایان پاییز؛ برنامهٔ واقع‌بینانه بریز.", -- 170
    "کاری که فقط تو بلدی، ریسک تیم است. به یک نفر دیگر هم یادش بده.", -- 171
    "تعطیلات تابستان تمام شد؛ انرژی‌اش را برای پاییز نگه دار.", -- 172
    "یک روز بدون شکایت. فقط امتحان کن.", -- 173
    "کار سخت را با یک همکار انجام بده؛ نصف می‌شود.", -- 174
    "اگر خسته‌ای، بگو خسته‌ام. تظاهر به انرژی، خسته‌کننده‌تر است.", -- 175
    "یک جلسه را کوتاه‌تر تمام کن؛ همه ممنونت می‌شوند.", -- 176
    "یاد گرفتن ابزار جدید اول کند است و بعد همه‌چیز را سریع می‌کند.", -- 177
    "یک گزارش را ساده‌تر بنویس؛ اگر کسی نفهمد، گزارش کار نکرده.", -- 178
    "نوشتن خوب، فکر کردن خوب است روی کاغذ.", -- 179
    "کارِ نیمه‌تمامِ زیاد یعنی شروع کردن آسان‌تر از تمام کردن است. یکی را ببند.", -- 180
    "یک نفر امسال خیلی به تو کمک کرده. امروز بهش بگو.", -- 181
    "آخرین روزهای تابستان است؛ یک بار دیگر آفتاب را ببین.", -- 182
    "برای پاییز یک هدف مشخص بنویس، نه یک آرزو.", -- 183
    "مرور کارکرد ماهت را جدی بگیر؛ عدد درست حق توست.", -- 184
    "اگر در کارکردت مغایرتی دیدی، همین حالا پیگیری کن، نه آخر سال.", -- 185
    "تابستان تمام شد. نیمهٔ اول سال بسته شد — نصف راه را آمده‌ای.", -- 186
    -- مهر
    "مهر آمد. حال‌وهوای شروع دوباره فقط مال مدرسه نیست.", -- 187
    "اول پاییز، بهترین وقت برای یک شروع تازه در کار است.", -- 188
    "اگر بچه‌ات امروز اولین روز مدرسه‌اش است، روز مهمی داری. مبارک باشد.", -- 189
    "پاییز یعنی ریتم منظم‌تر. از همین هفته برنامه‌ات را ثابت کن.", -- 190
    "هوای خنک تمرکز را برمی‌گرداند. از این فرصت استفاده کن.", -- 191
    "یک عادت خوب کاری را از امروز شروع کن؛ سه ماه تا پایان فصل وقت داری.", -- 192
    "لباس گرم بردار؛ سرماخوردگی بهره‌وری را بیشتر از هر چیزی کم می‌کند.", -- 193
    "اگر مریضی، بمان خانه. هم برای خودت بهتر است، هم برای بقیه.", -- 194
    "مرخصی استعلاجی یعنی سلامت مهم‌تر از حضور است.", -- 195
    "همکار جدیدی در تیم داری؟ اسمش را درست یاد بگیر و درست صدایش کن.", -- 196
    "جزئیات کوچک، احترام بزرگ می‌سازند.", -- 197
    "یک فرایند را مستند کن تا تازه‌واردها زودتر راه بیفتند.", -- 198
    "آموزش دادن، بهترین راه فهمیدن است.", -- 199
    "دویستمین روز سال. یک نفس عمیق و ادامه بده.", -- 200
    "اگر کاری بیش از حد طول کشید، شاید تعریفش واضح نبوده. دوباره تعریفش کن.", -- 201
    "سوال خوب، نصف جواب است.", -- 202
    "برنامهٔ هفتگی داشته باش، نه فقط روزانه. تصویر بزرگ‌تر آرامش می‌دهد.", -- 203
    "کاری را که سال‌هاست همان‌طور انجام می‌دهید، یک بار زیر سوال ببر.", -- 204
    "«همیشه همین‌طور بوده» دلیل نیست.", -- 205
    "نیمهٔ مهر است؛ هدف پاییزی‌ات چقدر جلو رفته؟", -- 206
    "یک بازخورد مثبت به کسی بده که انتظارش را ندارد.", -- 207
    "بازخورد منفی را خصوصی بده، تشویق را جلوی جمع.", -- 208
    "حواست به تعادل باشد: کاری که همهٔ زندگی‌ات شود، دیر یا زود خسته‌ات می‌کند.", -- 209
    "یک شب زودتر بخواب؛ فردا کل روزت فرق می‌کند.", -- 210
    "کارت را با انرژی کامل شروع کن، نه با آخرین توان.", -- 211
    "اگر جلسه‌ای برایت مفید نیست، محترمانه بگو و وقتت را پس بگیر.", -- 212
    "نه گفتن محترمانه، مهارتی است که همه لازم داریم.", -- 213
    "یک کار عقب‌افتاده را امروز ببند و خودت را راحت کن.", -- 214
    "پاییز وقت جمع‌بندی است؛ فایل‌های امسالت را مرتب کن.", -- 215
    "ماه اول پاییز تمام شد.", -- 216
    -- آبان
    "آبان، وسط پاییز. ریتم کار حالا باید جا افتاده باشد.", -- 217
    "اگر هنوز ریتم پیدا نکرده‌ای، از یک برنامهٔ ساده شروع کن: سه کار در روز.", -- 218
    "سه کار مهم در روز، از بیست کار در فهرست بهتر است.", -- 219
    "هوای ابری دلیل نمی‌شود روزت خاکستری باشد.", -- 220
    "یک موسیقی آرام هنگام کار، گاهی معجزه می‌کند.", -- 221
    "اگر تمرکزت پریده، پنج دقیقه چشم‌هایت را از صفحه بگیر.", -- 222
    "کار پشت میز بدن را خسته می‌کند حتی وقتی حرکت نمی‌کنی. هر ساعت بلند شو.", -- 223
    "یک همکار امروز خبر خوبی دارد؛ برایش خوشحال باش.", -- 224
    "حسادت کاری، انرژی خودت را می‌سوزاند نه دیگری را.", -- 225
    "موفقیت همکارت، تهدید تو نیست.", -- 226
    "یاد بگیر از دیگران بدون «ولی» تعریف کنی.", -- 227
    "یک کار سخت را امروز شروع کن، حتی ده دقیقه.", -- 228
    "شروع کردن سخت‌ترین بخش است. ادامه‌اش آسان‌تر می‌شود.", -- 229
    "نیمهٔ آبان است. تا پایان سال کمتر از پنج ماه مانده.", -- 230
    "اگر برنامهٔ امسالت جواب نداد، برنامهٔ سال بعد را از حالا واقع‌بینانه‌تر بنویس.", -- 231
    "هفته‌ای یک ساعت برای یاد گرفتن بگذار؛ همین یک ساعت، سال بعد را می‌سازد.", -- 232
    "کاری که امروز یاد می‌گیری، فردا وقتت را آزاد می‌کند.", -- 233
    "مرتب بودن اطلاعات، احترام به وقت بقیه است.", -- 234
    "یک فایل با اسم درست، ساعت‌ها جست‌وجو را حذف می‌کند.", -- 235
    "اگر کسی از کارت تعریف کرد، فقط بگو ممنون. لازم نیست کوچکش کنی.", -- 236
    "پذیرفتن تعریف هم مهارت است.", -- 237
    "ماهی یک بار به خودت بگو چه کاری را خوب انجام دادی.", -- 238
    "سخت‌گیری بی‌جا به خودت کیفیت را بالا نمی‌برد؛ فقط انرژی را می‌گیرد.", -- 239
    "مقایسه کردن خودت با کسی که مسیرش فرق دارد، بی‌فایده است.", -- 240
    "همکار قدیمی‌ای که مدت‌هاست ندیده‌ای را یک پیام بده.", -- 241
    "رابطه‌های کاری هم مثل گیاه‌اند: بی‌رسیدگی خشک می‌شوند.", -- 242
    "یک کار را امروز به کسی بسپار که بتواند یاد بگیرد.", -- 243
    "سپردن کار ضعف نیست؛ ساختن تیم است.", -- 244
    "آخر آبان است؛ هوا سردتر می‌شود، مراقب سلامتی‌ات باش.", -- 245
    "ماه هشتم تمام شد.", -- 246
    -- آذر
    "آذر آمد و سرما جدی شد. صبح‌ها زودتر راه بیفت.", -- 247
    "تاریکی زودهنگام غروب حالِ آدم را می‌گیرد؛ محیط کارت را روشن‌تر کن.", -- 248
    "کم‌نور بودن محیط خستگی می‌آورد. جای روشن‌تری برای کار پیدا کن.", -- 249
    "یک چای گرم با یک همکار وسط یک روز سرد، ارزشش را دارد.", -- 250
    "آخر سال نزدیک است؛ کارهای بلاتکلیف را دسته‌بندی کن.", -- 251
    "فهرستی از کارهایی بنویس که باید تا پایان سال تمام شوند.", -- 252
    "واقع‌بین باش: هر چیزی که در فهرست است تا پایان سال تمام نمی‌شود.", -- 253
    "حذف کردن از فهرست، به‌اندازهٔ اضافه کردن مهم است.", -- 254
    "اگر پروژه‌ای تا پایان سال تمام نمی‌شود، همین حالا بگو، نه اسفند.", -- 255
    "خبر بد را زود بده؛ زود گفتن راه‌حل می‌سازد.", -- 256
    "نیمهٔ آذر است. سه هفته تا زمستان.", -- 257
    "یک کار خوب برای سلامتی‌ات انجام بده؛ زمستان سخت‌تر می‌گذرد اگر بی‌حال باشی.", -- 258
    "آب خوردن در زمستان هم مهم است، حتی وقتی تشنه نیستی.", -- 259
    "اگر همکارت سرما خورده، به‌جای اصرار به آمدن، بگو استراحت کن.", -- 260
    "تیم سالم، از تیم پرکار مهم‌تر است.", -- 261
    "تصمیمی را که مدت‌هاست عقب انداخته‌ای، امروز بگیر.", -- 262
    "تصمیم نگرفتن هم یک تصمیم است، معمولاً بدترینش.", -- 263
    "کارِ خوبِ امروز را جشن بگیر، حتی کوچک.", -- 264
    "جشن گرفتن پیروزی‌های کوچک، تیم را زنده نگه می‌دارد.", -- 265
    "یک نفر امسال خیلی زحمت کشیده و کسی ندیده. تو ببین.", -- 266
    "آخر سال وقت قدردانی است، نه فقط ارزیابی.", -- 267
    "کارنامهٔ امسالت را خودت بنویس، قبل از اینکه کسی برایت بنویسد.", -- 268
    "مرور کارکرد و مرخصی‌ات را عقب نینداز؛ آخر سال شلوغ می‌شود.", -- 269
    "اگر مانده مرخصی داری، برنامه‌ریزی کن؛ سوختنش حیف است.", -- 270
    "یک روز مرخصی در زمستان، به‌اندازهٔ یک هفته در تابستان می‌ارزد.", -- 271
    "شب‌های بلند، وقت خوبی برای کتاب خواندن است.", -- 272
    "یاد گرفتن فقط از کار نیست؛ از کتاب و آدم‌ها هم هست.", -- 273
    "آخرین روزهای پاییز است؛ یک کار پاییزی را ببند.", -- 274
    "فردا شب بلندترین شب سال است. زودتر کارت را جمع کن.", -- 275
    "شب یلدا مبارک؛ امشب کنار خانواده باش، نه کنار لپ‌تاپ.", -- 276
    -- دی
    "زمستان شروع شد. سه ماه تا پایان سال.", -- 277
    "اولین روز زمستان، وقت خوبی برای یک تصمیم کوچک و شدنی است.", -- 278
    "سرما بهانه نیست، ولی بدنت را گرم نگه دار.", -- 279
    "زمستان یعنی کارهای عمیق؛ جلسه‌ها کمترند، تمرکز بیشتر.", -- 280
    "پروژهٔ فکری‌ای که وقت می‌خواست را همین حالا شروع کن.", -- 281
    "اگر صبح‌ها بلند شدن سخت شده، شب زودتر بخواب. راه دیگری ندارد.", -- 282
    "کار در سرما کندتر است؛ برنامه‌ات را واقع‌بینانه ببند.", -- 283
    "یک قهوهٔ گرم و یک کار تمام‌شده، ترکیب خوبی است.", -- 284
    "اگر امروز فقط یک کار مهم را تمام کنی، روز موفقی داشته‌ای.", -- 285
    "کار زیاد نشانهٔ ارزشمند بودن نیست. نتیجه است که مهم است.", -- 286
    "سالی یک بار، کل روند کارت را از بیرون نگاه کن.", -- 287
    "اگر مسیرت را دوست نداری، حالا وقت گفتن است، نه سال بعد.", -- 288
    "با مدیرت دربارهٔ سال بعد حرف بزن؛ حدس زدن به نفع کسی نیست.", -- 289
    "هدفی برای سال بعد بنویس که کاملاً در کنترل خودت باشد.", -- 290
    "نیمهٔ دی است. برنامهٔ سال بعد دارد بسته می‌شود؛ حرفت را بزن.", -- 291
    "سکوت در جلسهٔ برنامه‌ریزی یعنی موافقت. اگر موافق نیستی، بگو.", -- 292
    "ایده‌ای برای کم کردن هزینه یا وقت داری؟ همین امروز مطرحش کن.", -- 293
    "کارِ ساده‌شده، بهترین هدیه به تیم سال بعد است.", -- 294
    "مستندات را قبل از پایان سال به‌روز کن.", -- 295
    "کارِ تحویل‌دادنی را زودتر از موعد آماده کن؛ آخر سال همه‌چیز شلوغ می‌شود.", -- 296
    "اگر روزت خراب شد، فردا از نو. هر روز یک صفحهٔ تازه است.", -- 297
    "مقایسهٔ امروزت با دیروزت، تنها مقایسهٔ منصفانه است.", -- 298
    "یک همکار امروز به شنیده شدن نیاز دارد، نه به راه‌حل. فقط گوش کن.", -- 299
    "سیصدمین روز سال. کمتر از دو ماه مانده.", -- 300
    "اگر امسال چیزی یاد گرفتی که پارسال نمی‌دانستی، سال موفقی داشته‌ای.", -- 301
    "فهرست دستاوردهای امسالت را بنویس؛ بیشتر از آن است که فکر می‌کنی.", -- 302
    "فراموش نکن که خیلی از کارهای امسال بی‌سروصدا انجام شدند.", -- 303
    "کسی را که امسال کمکت کرد، رسماً از او تشکر کن.", -- 304
    "آخر دی است؛ ماه دهم هم تمام شد.", -- 305
    "ده ماه پشت سر، دو ماه پیش رو. تمامش کن.", -- 306
    -- بهمن
    "بهمن آمد؛ سردترین روزها معمولاً همین‌جاست.", -- 307
    "دو ماه تا سال نو. کارهای واقعی را از آرزوها جدا کن.", -- 308
    "یک کار بزرگ را انتخاب کن و تا آخر سال تمامش کن. فقط یکی.", -- 309
    "تمرکز روی یک چیز، بهتر از پراکندگی روی ده چیز است.", -- 310
    "اگر کاری تا امروز شروع نشده، شاید اصلاً مهم نبوده. حذفش کن.", -- 311
    "حذف کردن کارهای بی‌اهمیت، بزرگ‌ترین افزایش بهره‌وری است.", -- 312
    "یک نفر در تیم امسال خیلی رشد کرده. بهش بگو که دیده‌ای.", -- 313
    "دیدن رشد دیگران، خودش یک مهارت مدیریتی است.", -- 314
    "اگر امسال کسی به تو یاد داد، سال بعد تو به کسی یاد بده.", -- 315
    "نیمهٔ بهمن. برنامهٔ نوروز و مرخصی‌ها را از حالا هماهنگ کن.", -- 316
    "هماهنگی زودهنگام مرخصی یعنی کسی آخر سال غافلگیر نشود.", -- 317
    "کارهای تحویلی پایان سال را از امروز تکه‌تکه جلو ببر.", -- 318
    "تلنبار کردن کار برای اسفند، یعنی اسفند بدی داشته باشی.", -- 319
    "یک فایل، یک گزارش، یک فرایند: هر روز یکی را مرتب کن.", -- 320
    "نظم، جمعِ کارهای کوچک روزانه است، نه یک نظافت بزرگ سالانه.", -- 321
    "اگر چیزی امسال خوب پیش نرفت، بنویس چرا. همین یادداشت سال بعد را نجات می‌دهد.", -- 322
    "شکستِ مستندنشده، دوباره تکرار می‌شود.", -- 323
    "یک ریسک کوچک بپذیر؛ یاد گرفتن بدون ریسک سخت است.", -- 324
    "اشتباه کردن در کارِ جدید طبیعی است؛ تکرارش نه.", -- 325
    "کار تیمی یعنی هیچ‌کس تنها شکست نمی‌خورد.", -- 326
    "اگر تیم به نتیجه رسید، نتیجهٔ همه است.", -- 327
    "یک تشکر کوچک، ماه‌ها در ذهن آدم می‌ماند.", -- 328
    "امروز به یک نفر بگو کارش چه تاثیری روی کار تو داشته.", -- 329
    "آدم‌ها وقتی بدانند کارشان به چه درد می‌خورد، بهتر کار می‌کنند.", -- 330
    "هدف روشن، از انگیزهٔ زیاد مهم‌تر است.", -- 331
    "اگر نمی‌دانی چرا کاری را انجام می‌دهی، بپرس. حق توست.", -- 332
    "یک ماه تا سال نو. جمع‌بندی را از همین حالا شروع کن.", -- 333
    "آخرین ماه سال، ماه بستن است نه شروع کردن.", -- 334
    "آخر بهمن است؛ ماه یازدهم هم گذشت.", -- 335
    "یازده ماه پشت سر گذاشتی. ماه آخر را با آرامش تمام کن.", -- 336
    -- اسفند
    "اسفند آمد. آخرین ماه سال شلوغ‌ترین ماه است؛ آرام و منظم پیش برو.", -- 337
    "فهرست کارهای پایان سال را بنویس و اولویت‌بندی کن.", -- 338
    "هر کاری را نمی‌شود تا عید تمام کرد؛ همین حالا انتخاب کن کدام‌ها.", -- 339
    "صادق بودن دربارهٔ آنچه تمام نمی‌شود، از قول دادن الکی بهتر است.", -- 340
    "کارِ عقب‌افتاده را با یک همکار تقسیم کن؛ تنهایی سخت‌تر است.", -- 341
    "یک روز را فقط به بستن کارهای کوچک اختصاص بده.", -- 342
    "کارهای کوچکِ باز، بیشتر از کارهای بزرگ ذهن را مشغول می‌کنند.", -- 343
    "خانه‌تکانی فقط برای خانه نیست؛ فایل‌ها و ایمیل‌هایت را هم تکان بده.", -- 344
    "اشتراک‌ها و دسترسی‌های بی‌استفاده را همین حالا ببند.", -- 345
    "یک گزارش سالانه از کارت بنویس، حتی اگر کسی نخواسته.", -- 346
    "نوشتن دستاوردها، اعتمادبه‌نفس سال بعد را می‌سازد.", -- 347
    "مانده مرخصی‌ات را بررسی کن؛ فرصت استفاده دارد تمام می‌شود.", -- 348
    "کارکرد سالت را یک بار کامل مرور کن و مغایرت‌ها را پیگیری کن.", -- 349
    "حقِ خودت را با آرامش و مستند پیگیری کن، نه با عجله در روزهای آخر.", -- 350
    "نیمهٔ اسفند. بازار شلوغ است و ذهن‌ها پراکنده؛ حواست به کیفیت کار باشد.", -- 351
    "در روزهای شلوغ اشتباه بیشتر می‌شود. یک بار بیشتر چک کن.", -- 352
    "عجله دشمن کیفیت است. یک نفس عمیق و دوباره.", -- 353
    "اگر امسال سخت گذشت، تو تنها نبودی. تمامش کردی.", -- 354
    "یک نفر امسال کنارت بوده؛ قبل از عید ازش تشکر کن.", -- 355
    "تحویل کار قبل از تعطیلات یعنی تعطیلات راحت‌تر.", -- 356
    "کاری را نیمه‌کاره تحویل تعطیلات نده؛ بعد از عید سنگین‌تر می‌شود.", -- 357
    "یادداشتی برای خودت بگذار که بعد از تعطیلات از کجا شروع کنی.", -- 358
    "میزت را قبل از تعطیلات مرتب کن؛ برگشتن به میز مرتب حال خوبی دارد.", -- 359
    "یک بار دیگر به همکارانت سر بزن و خداحافظی کن؛ دو هفته نمی‌بینی‌شان.", -- 360
    "سال کاری خوبی داشتی یا نه، تمامش کردی. همین کم نیست.", -- 361
    "آنچه امسال یاد گرفتی، سال بعد با تو می‌آید.", -- 362
    "برای سال بعد یک قول کوچک به خودت بده، نه یک فهرست بلند.", -- 363
    "سال نو فرصت دوباره است؛ نه برای عوض شدن، برای ادامه دادن.", -- 364
    "سال کهنه تمام شد. ممنون که امسال بخشی از این تیم بودی.", -- 365
    "آخرین روز سال؛ سال نو پیشاپیش مبارک. با آرامش وارد سال تازه شو.", -- 366
}

-- انتخاب پیام روز: مستقیماً با روزِ سالِ شمسی (JYDAY از report_dimdate) اندیس می‌شود، پس برای هر
-- روزِ سال یک پیام یکتا وجود دارد و تا پایان سال هیچ پیامی تکرار نمی‌شود. جدول ۳۶۶ عضوی است تا
-- سال کبیسه هم پوشش داده شود؛ mod فقط یک محافظ در برابر مقدار خارج از بازه است.
local daily_message
do
    local day_index = tonumber(today_meta.jyday) or 0
    if day_index < 1 or day_index > #DAILY_MESSAGES then
        day_index = ((day_index - 1) % #DAILY_MESSAGES) + 1
    end
    if day_index < 1 then day_index = 1 end
    daily_message = DAILY_MESSAGES[day_index] or DAILY_MESSAGES[1]
end

local first_name = tostring(personnel.fullname):match("^%S+") or tostring(personnel.fullname)
local greeting = "سلام " .. first_name .. "، روزت بخیر"
local is_my_birthday = false
for _, b in ipairs(birthdays_today) do
    if b.is_self then is_my_birthday = true end
end
if is_my_birthday then
    greeting = "تولدت مبارک " .. first_name
end

-- ── JSON output (debug / API) ───────────────────────────────────────

if format_out == "json" then
    teamyar.write_result(json.encode({
        ok = true,
        personnel = personnel,
        employment = employment,
        employment_settings = employment_settings,
        employment_source = employment_source,
        supervisor_source = supervisor_source,
        supervisor_id = supervisor_id,
        today = today_meta,
        today_row = today_row,
        totals = totals,
        daily = daily,
        events = events,
        requests = requests,
        request_counts = request_counts,
        leave_balance = leave_balance,
        leave_balance_period = leave_balance_period,
        leave_balance_source = leave_balance_source,
        leave_balance_raw = leave_balance_raw,
        education = education_label,
        birthdays_today = birthdays_today,
        birthdays_month = birthdays_month,
        birth_setting = birth_setting,
        daily_message = daily_message,
        celebration_group_id = celebration_group_id,
        celebration_enabled = celebration_enabled,
        errors = {
            identity = identity_err,
            employment = employment_err,
            attendance = attendance_err,
            events = events_err,
            requests = requests_err,
            leave_balance = leave_balance_err,
            celebration = celebration_err
        }
    }))
    return
end

-- ── HTML building blocks ─────────────────────────────────────────────
-- کل مرحلهٔ رندر داخل یک pcall است. بارگذاری داده از قبل بخش‌به‌بخش pcall داشت، ولی خودِ ساختِ
-- HTML محافظ نداشت؛ یعنی یک خطای غیرمنتظره در این مرحله، به‌جای صفحه، traceback خام Lua را جلوی
-- کاربر می‌گذاشت. حالا در بدترین حالت هم یک صفحهٔ خطای تمیز فارسی برگردانده می‌شود.
local render_ok, render_output = pcall(function()

local function pill(text, tone)
    local cls = "pill"
    if tone == "solid" then cls = "pill pill-solid" end
    if tone == "muted" then cls = "pill pill-muted" end
    return '<span class="' .. cls .. '">' .. escape_html(text) .. '</span>'
end

local function status_pill(status)
    if status == "کامل" or status == "تایید شده" then return pill(status, "solid") end
    if status == "غیبت" or status == "رد شده" or status == "ناقص" then return pill(status, "muted") end
    return pill(status, nil)
end

local function kpi_card(label, value, sub)
    return '<article class="card kpi"><div class="label">' .. escape_html(label) ..
        '</div><div class="value">' .. value .. '</div><div class="sub">' ..
        escape_html(sub or "") .. '</div></article>'
end

local function empty_row(colspan, message)
    return '<tr><td class="empty-msg" colspan="' .. colspan .. '">' ..
        escape_html(message) .. '</td></tr>'
end

-- KPI strip
local kpi_html = {}
table.insert(kpi_html, kpi_card("کارکرد خالص بازه",
    minutes_to_hm(totals.work) .. ' <small>ساعت</small>',
    "روزهای حضور: " .. fmt_num(totals.present_days)))
table.insert(kpi_html, kpi_card("اضافه‌کاری محاسبه‌شده",
    minutes_to_hm(totals.overtime) .. ' <small>ساعت</small>',
    "مبنا: مقدار نهایی حکم"))
if leave_balance ~= nil then
    table.insert(kpi_html, kpi_card("مانده مرخصی",
        minutes_to_hm(leave_balance.remained_minutes) .. ' <small>ساعت</small>',
        leave_balance_note))
else
    table.insert(kpi_html, kpi_card("مانده مرخصی", '<span class="dash">—</span>',
        leave_balance_note))
end
table.insert(kpi_html, kpi_card("تاخیر محاسبه‌شده",
    minutes_to_hm(totals.delay) .. ' <small>ساعت</small>',
    "روزهای ناقص: " .. fmt_num(totals.incomplete_days)))
table.insert(kpi_html, kpi_card("مرخصی و ماموریت بازه",
    minutes_to_hm(totals.leave + totals.mission) .. ' <small>ساعت</small>',
    "مرخصی " .. minutes_to_hm(totals.leave) .. " + ماموریت " .. minutes_to_hm(totals.mission)))
table.insert(kpi_html, kpi_card("درخواست‌های در انتظار",
    fmt_num(request_counts.pending),
    "کل درخواست‌های بازه: " .. fmt_num(request_counts.total)))

-- Hero (today)
local hero_html
do
    local shift_text = "شیفت این روز در تقویم کاری ثبت نشده است"
    local clock_text = "—"
    local inout_text = "ترددی برای امروز ثبت نشده است"
    local status_text = "امروز هنوز کارکردی ثبت نشده است"

    if today_row ~= nil then
        if today_row.shift_from ~= nil and today_row.shift_to ~= nil then
            shift_text = "شیفت امروز: " .. today_row.shift_from .. " تا " .. today_row.shift_to ..
                " • موظفی " .. minutes_to_hm(today_row.shift_minutes)
        end
        clock_text = minutes_to_hm_or_dash(today_row.work_minutes)
        if today_row.first_in ~= nil or today_row.last_out ~= nil then
            inout_text = "ورود " .. (today_row.first_in or "—") ..
                " ← خروج " .. (today_row.last_out or "ثبت نشده")
        end
        status_text = "وضعیت امروز: " .. today_row.status
    end

    local ring_pct = 0
    if totals.expected > 0 then
        ring_pct = math.floor((totals.work * 100 / totals.expected) + 0.5)
        if ring_pct > 100 then ring_pct = 100 end
    end

    hero_html = '<section class="hero">' ..
        '<div class="hero-main">' ..
        '<div class="hero-badges">' .. pill(today_meta.jday_name .. " " .. today_meta.jdate, "solid") ..
        ' ' .. pill(status_text, nil) .. '</div>' ..
        '<h2>' .. escape_html(daily_message) .. '</h2>' ..
        '<p>' .. escape_html(shift_text) .. '</p>' ..
        '<div class="hero-actions">' ..
        '<button type="button" class="btn-hero" data-goto="attendance">تردد و کارکرد من</button>' ..
        '<button type="button" class="btn-hero" data-goto="requests">درخواست‌های من</button>' ..
        '<button type="button" class="btn-hero" data-goto="celebration">همراهِ روز و تولدها</button>' ..
        '</div></div>' ..
        '<div class="hero-side">' ..
        '<div><small>کارکرد خالص امروز</small>' ..
        '<div class="clock">' .. clock_text .. '</div>' ..
        '<p>' .. escape_html(inout_text) .. '</p></div>' ..
        '<div class="ring" style="background:conic-gradient(#fff 0 ' .. ring_pct ..
        '%,rgba(255,255,255,0.18) ' .. ring_pct .. '%);">' ..
        '<div><b>' .. ring_pct .. '%</b><span>از موظفی</span></div></div>' ..
        '</div></section>'
end

-- Weekly rhythm chart (last 7 rows of daily, chronological)
local chart_html
do
    -- daily نزولی است؛ ۷ روز آخر را به ترتیب صعودی (قدیمی → جدید) برمی‌گردانیم
    local ordered = {}
    for i = 1, math.min(7, #daily) do table.insert(ordered, 1, daily[i]) end

    local max_minutes = 1
    for _, d in ipairs(ordered) do
        local total = d.work_minutes + d.overtime_minutes
        if total > max_minutes then max_minutes = total end
    end

    local bars = {}
    for _, d in ipairs(ordered) do
        local total = d.work_minutes + d.overtime_minutes
        local height = math.floor((total * 100 / max_minutes) + 0.5)
        if height < 2 then height = 2 end
        local overtime_pct = 0
        if total > 0 then overtime_pct = math.floor((d.overtime_minutes * 100 / total) + 0.5) end
        table.insert(bars,
            '<div class="barcol" title="' .. escape_html(d.jdate .. " — کارکرد " ..
                minutes_to_hm(d.work_minutes)) .. '">' ..
            '<div class="bar" style="height:' .. height .. '%;">' ..
            '<div class="bar-extra" style="height:' .. overtime_pct .. '%;"></div>' ..
            '<div class="bar-work"></div></div>' ..
            '<span>' .. escape_html(d.jday_name) .. '</span></div>')
    end
    if #bars == 0 then
        chart_html = '<div class="empty-msg">در این بازه کارکردی ثبت نشده است</div>'
    else
        chart_html = '<div class="chart">' .. table.concat(bars, "") .. '</div>' ..
            '<div class="chartfoot"><div class="legend">' ..
            '<span><i></i>کارکرد عادی</span><span><i class="light"></i>اضافه‌کاری</span></div>' ..
            '<span>مبنا: ' .. fmt_num(#ordered) .. ' روز آخرِ دارای رکورد</span></div>'
    end
end

-- Daily attendance table
local daily_rows = {}
for _, d in ipairs(daily) do
    table.insert(daily_rows,
        '<tr><td>' .. escape_html(d.jdate) .. '</td><td>' .. escape_html(d.jday_name) .. '</td>' ..
        '<td>' .. escape_html(d.first_in or "—") .. '</td>' ..
        '<td>' .. escape_html(d.last_out or "ثبت نشده") .. '</td>' ..
        '<td>' .. minutes_to_hm_or_dash(d.work_minutes) .. '</td>' ..
        '<td>' .. minutes_to_hm_or_dash(d.overtime_minutes) .. '</td>' ..
        '<td>' .. minutes_to_hm_or_dash(d.delay_minutes) .. '</td>' ..
        '<td>' .. minutes_to_hm_or_dash(d.leave_minutes) .. '</td>' ..
        '<td>' .. minutes_to_hm_or_dash(d.mission_minutes) .. '</td>' ..
        '<td>' .. minutes_to_hm_or_dash(d.deficit_minutes) .. '</td>' ..
        '<td>' .. status_pill(d.status) .. '</td></tr>')
end
if #daily_rows == 0 then
    table.insert(daily_rows, empty_row(11, attendance_err and ("خطا: " .. attendance_err) or
        "در این بازه رکورد کارکردی ثبت نشده است"))
end

-- Attendance events table
local EXT_TYPE_LABELS = { [0] = "تردد عادی", [1] = "مرخصی", [2] = "ماموریت", [3] = "ثبت دستی" }
local event_rows = {}
for _, e in ipairs(events) do
    local type_label = EXT_TYPE_LABELS[e.ext_type] or ("نوع " .. e.ext_type)
    table.insert(event_rows,
        '<tr><td>' .. escape_html(e.jdate) .. '</td>' ..
        '<td>' .. escape_html(e.time_from or "—") .. '</td>' ..
        '<td>' .. escape_html(e.time_to or "—") .. '</td>' ..
        '<td>' .. minutes_to_hm_or_dash(e.duration_minutes) .. '</td>' ..
        '<td>' .. escape_html(type_label) .. '</td>' ..
        '<td>' .. escape_html(e.machine_from) .. '</td>' ..
        '<td>' .. escape_html(e.machine_to) .. '</td>' ..
        '<td>' .. (e.enabled == 1 and pill("فعال", "solid") or pill("غیرفعال", "muted")) .. '</td>' ..
        '<td>' .. escape_html(e.comment) .. '</td></tr>')
end
if #event_rows == 0 then
    table.insert(event_rows, empty_row(9, events_err and ("خطا: " .. events_err) or
        "در این بازه رویداد ترددی ثبت نشده است"))
end

-- Requests table
local request_rows = {}
for _, r in ipairs(requests) do
    local verify_text = "—"
    if r.verify_count > 0 then
        verify_text = fmt_num(r.verify_done) .. " از " .. fmt_num(r.verify_count)
    end
    local hours_text = "—"
    if r.time_from ~= nil and r.time_to ~= nil then
        hours_text = r.time_from .. " تا " .. r.time_to
    end
    table.insert(request_rows,
        '<tr data-status="' .. escape_html(r.status) .. '">' ..
        '<td>' .. escape_html(r.jdate) .. '</td>' ..
        '<td>' .. escape_html(r.family) .. '</td>' ..
        '<td>' .. escape_html(r.type_name) .. '</td>' ..
        '<td>' .. escape_html(hours_text) .. '</td>' ..
        '<td>' .. minutes_to_hm_or_dash(r.total_minutes) .. '</td>' ..
        '<td>' .. status_pill(r.status) .. '</td>' ..
        '<td>' .. tostring(r.status_code) .. '</td>' ..
        '<td>' .. escape_html(verify_text) .. '</td>' ..
        '<td>' .. escape_html(r.created) .. '</td>' ..
        '<td class="cell-wrap">' .. escape_html(r.description) .. '</td></tr>')
end
if #request_rows == 0 then
    table.insert(request_rows, empty_row(10, requests_err and ("خطا: " .. requests_err) or
        "در این بازه درخواستی ثبت نشده است"))
end

-- نسخهٔ فشرده برای «نمای کلی»: جدول کامل ۱۰ ستونی در ستون نصف‌عرض خوانا نیست
local request_rows_compact = {}
for index, r in ipairs(requests) do
    if index > 6 then break end
    table.insert(request_rows_compact,
        '<tr><td>' .. escape_html(r.jdate) .. '</td>' ..
        '<td>' .. escape_html(r.type_name) .. '</td>' ..
        '<td>' .. minutes_to_hm_or_dash(r.total_minutes) .. '</td>' ..
        '<td>' .. status_pill(r.status) .. '</td></tr>')
end
if #request_rows_compact == 0 then
    table.insert(request_rows_compact, empty_row(4, requests_err and ("خطا: " .. requests_err) or
        "در این بازه درخواستی ثبت نشده است"))
end

-- Profile details
local MARITAL_LABELS = { [1] = "مجرد", [2] = "متاهل" }
local SEX_LABELS = { [1] = "مرد", [2] = "زن" }

local function detail_row(label, value)
    return '<div class="detail"><span>' .. escape_html(label) .. '</span><b>' ..
        escape_html(value == nil and "—" or tostring(value)) .. '</b></div>'
end

-- مقادیر مدت‌دارِ حکم، هر کدام با سقف منطقی خودش (بالا را ببینید)
local function order_hm(raw_ticks, max_minutes)
    if raw_ticks == nil then return nil end
    local minutes = plausible_minutes(math.floor((tonumber(raw_ticks) or 0) / 10000000 / 60 + 0.5), max_minutes)
    if minutes == nil then return nil end
    return minutes_to_hm(minutes)
end

local order_working_hm = order_hm(employment.working_hours_raw, 500 * 60)      -- تا ۵۰۰ ساعت (ماهانه)
local order_leave_month_hm = order_hm(employment.leave_per_month_raw, 60 * 60) -- تا ۶۰ ساعت
local order_max_delay_hm = order_hm(employment.max_delay_month_raw, 100 * 60)  -- تا ۱۰۰ ساعت
local order_rest_hm = order_hm(employment.rest_during_work_raw, 8 * 60)        -- تا ۸ ساعت
local order_max_hourly_hm = order_hm(employment.max_hourly_leave_raw, 24 * 60) -- تا ۲۴ ساعت


local profile_left = detail_row("نام و نام خانوادگی", personnel.fullname) ..
    detail_row("کد پرسنلی", personnel.personnel_code) ..
    detail_row("واحد سازمانی", employment.unit_name) ..
    detail_row("سرپرست مستقیم", employment.supervisor_name) ..
    detail_row("محل خدمت", (personnel.work_place ~= nil and personnel.work_place ~= "") and
        personnel.work_place or "—") ..
    detail_row("جنسیت", SEX_LABELS[personnel.sex]) ..
    detail_row("وضعیت تاهل", MARITAL_LABELS[personnel.marital_status]) ..
    detail_row("بالاترین مدرک تحصیلی", education_label)

local profile_right = detail_row("تقویم کاری", employment.calendar_name) ..
    detail_row("موظفی محاسبه‌شدهٔ بازه", totals.expected > 0 and minutes_to_hm(totals.expected) or nil) ..
    detail_row("موظفی طبق حکم", order_working_hm) ..
    detail_row("سقف مرخصی ماهانه طبق حکم", order_leave_month_hm) ..
    detail_row("بازهٔ حکم جاری", (employment.date_from or "—") .. " تا " .. (employment.date_to or "—")) ..
    detail_row("وضعیت حکم", employment.is_current == false and
        "حکم جاری فعال نیست (آخرین حکم نمایش داده شده)" or "حکم جاری فعال") ..
    detail_row("مانده مرخصی", leave_balance and minutes_to_hm(leave_balance.remained_minutes) or nil) ..
    detail_row("منبع مانده مرخصی", leave_balance_note)

-- Celebration section
local celebration_html
do
    local today_cards = {}
    for _, b in ipairs(birthdays_today) do
        local action
        if b.is_self then
            action = '<span class="muted-note">امروز روز توست — همکارانت خبردار شدند</span>'
        else
            action = '<button type="button" class="btn-action" ' ..
                'onclick="openCelebration(\'' .. js_str(b.name) .. '\',\'' ..
                js_str(today_meta.jdate) .. '\')">پیوستن به گفتگوی تبریک</button>'
        end
        table.insert(today_cards,
            '<div class="birthday-card"><div class="birthday-avatar">' ..
            escape_html(name_initials(b.name)) .. '</div>' ..
            '<div class="birthday-body"><b>' .. escape_html(b.name) .. '</b>' ..
            '<p>' .. escape_html(b.unit_name) .. ' • ' .. escape_html(b.display_date) .. '</p>' ..
            action .. '</div></div>')
    end

    local month_rows = {}
    for _, b in ipairs(birthdays_month) do
        local action = "—"
        if not b.is_self then
            action = '<button type="button" class="link-btn" onclick="openCelebration(\'' ..
                js_str(b.name) .. '\',\'' .. js_str(b.display_date) .. '\')">تبریک ←</button>'
        end
        local is_today_mark = (b.jmday == today_meta.jmday) and pill("امروز", "solid") or ""
        table.insert(month_rows,
            '<tr><td>' .. escape_html(b.display_date) .. ' ' .. is_today_mark .. '</td>' ..
            '<td>' .. escape_html(b.name) .. '</td>' ..
            '<td>' .. escape_html(b.unit_name) .. '</td>' ..
            '<td>' .. escape_html(b.birth_date) .. '</td>' ..
            '<td>' .. action .. '</td></tr>')
    end
    if #month_rows == 0 then
        table.insert(month_rows, empty_row(5, celebration_err and ("خطا: " .. celebration_err) or
            "در این ماه تولدی در سازمان شما ثبت نشده است"))
    end

    local today_block
    if #today_cards == 0 then
        today_block = '<div class="empty-msg">امروز تولد کسی در سازمان شما ثبت نشده است</div>'
    else
        today_block = '<div class="birthday-grid">' .. table.concat(today_cards, "") .. '</div>'
    end

    local setting_note = "تنظیم تبریک تولد سازمان خوانده نشد."
    if birth_setting ~= nil then
        local channels = {}
        if birth_setting.popup then table.insert(channels, "پیام درون‌سازمانی") end
        if birth_setting.sms then table.insert(channels, "پیامک") end
        if birth_setting.email then table.insert(channels, "ایمیل") end
        if #channels == 0 then
            setting_note = "در تنظیمات سازمان، تبریک خودکار تولد فعال نیست؛ این پنل جای آن را نمی‌گیرد و فقط یادآوری می‌کند."
        else
            setting_note = "تبریک خودکار سازمان فعال است از راه: " .. table.concat(channels, "، ") .. "."
        end
    end

    local celebration_config_note = ""
    if not celebration_enabled then
        celebration_config_note = '<div class="notice">گفتگوی تبریک فعلاً فقط خواندنی است: ' ..
            'فهرست تولدها و پیام‌های گفتگوهای موجود نمایش داده می‌شوند، ولی ساخت گفتگوی تازه و ' ..
            'پیوستن به آن انجام نمی‌شود. علتش این است که ساختار درخواست APIهای ماژول گفتگو هنوز ' ..
            'تایید شده است؛ چون این کار روی سامانهٔ زنده گروه و گفتگوی واقعی می‌سازد، ' ..
            '<code>celebration_enabled</code> را در تنظیمات همین بات برابر ۱ بگذارید.</div>'
    elseif celebration_group_id == nil then
        celebration_config_note = '<div class="notice">گروه گفتگوی پیش‌فرض تنظیم نشده است؛ هنگام ' ..
            'ساخت گفتگوی تبریک، اولین گروه فعالِ ماژول گفتگو استفاده می‌شود. برای انتخاب گروه ' ..
            'مشخص، مقدار <code>celebration_group_id</code> را در تنظیمات همین بات ثبت کنید.</div>'
    end

    celebration_html = '<section id="celebration" class="page">' ..
        '<article class="card message-card">' ..
        '<div class="message-logo"><img alt="140" src="data:image/png;base64,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"></div>' ..
        '<div><div class="title">پیام امروز</div>' ..
        '<p class="message-text">' .. escape_html(daily_message) .. '</p>' ..
        '<p class="note">' .. escape_html(today_meta.jday_name .. " " .. today_meta.jdate) ..
        ' • پیام هر روز عوض می‌شود و برای همهٔ همکاران یکسان است.</p></div></article>' ..
        celebration_config_note ..
        '<div class="grid2">' ..
        '<article class="card"><div class="title">تولد امروز</div>' .. today_block ..
        '<p class="note">' .. escape_html(setting_note) .. '</p></article>' ..
        '<article class="card"><div class="title">تولدهای ' ..
        escape_html(tostring(today_meta.jmonth_name or "این ماه")) .. '</div>' ..
        '<div class="table-wrap"><table class="data-table"><thead><tr>' ..
        '<th>روز</th><th>نام همکار</th><th>واحد</th><th>تاریخ تولد</th><th>تبریک</th>' ..
        '</tr></thead><tbody>' .. table.concat(month_rows, "") .. '</tbody></table></div>' ..
        '</article></div></section>'
end

-- نوار خطا — فقط وقتی چیزی واقعاً از قلم افتاده باشد.
-- نسخهٔ قبلی هر خطای داخلی را نشان می‌داد، از جمله ACCESS_DENIED فراخوانی APIهایی که fallback
-- دیتابیس‌شان موفق شده بود. نتیجه‌اش یک نوار قرمزِ ترسناک بود در حالی که هیچ داده‌ای کم نبود.
-- حالا اگر منبع جایگزین جواب داده باشد، خطای همان بخش گزارش نمی‌شود.
local error_html = ""
do
    local messages = {}
    local function report(label, err, data_is_present)
        if err ~= nil and not data_is_present then
            table.insert(messages, label .. ": " .. tostring(err))
        end
    end
    report("حکم کاری", employment_err, employment.order_id ~= nil)
    report("کارکرد", attendance_err, #daily > 0)
    report("رویدادهای تردد", events_err, #events > 0)
    report("درخواست‌ها", requests_err, #requests > 0)
    report("مانده مرخصی", leave_balance_err, leave_balance ~= nil)
    report("تولدها", celebration_err, today_meta.jyday > 0)
    if #messages > 0 then
        error_html = '<div class="error-box"><b>بخشی از اطلاعات بارگذاری نشد:</b> ' ..
            escape_html(table.concat(messages, " | ")) ..
            '<br>بقیهٔ بخش‌های این صفحه سالم‌اند. لطفاً همین متن را به واحد فناوری اطلاعات بدهید.</div>'
    end
end

-- ── page shell ───────────────────────────────────────────────────────

local html_head = [==[<!DOCTYPE html>
<html lang="fa" dir="rtl">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>همراه ۱۴۰ | پنل پرسنلی</title>
<style>
@font-face {
    font-family: "PeydaReport";
    src: url(data:font/truetype;charset=utf-8;base64,AAEAAAAOAIAAAwBgRFNJRwAAAAEAASFUAAAACEdERUYrBC3XAADcNAAAAHxHUE9TKUGIwAAA3LAAADTIR1NVQk+rAWsAARF4AAAP2k9TLzJ2gVbcAAABaAAAAGBjbWFwh/GYyAAADSAAAAeaZ2x5ZmvrPHUAABpsAACfzmhlYWQnUViOAAAA7AAAADZoaGVhCDcSFgAAASQAAAAkaG10eD9fZe0AAAHIAAALWGxvY2EviwdzAAAUvAAABa5tYXhwA1MBBAAAAUgAAAAgbmFtZXvHsAoAALo8AAAFPnBvc3RoWZoTAAC/fAAAHLcAAQAAAAMAAGLmoqxfDzz1AAMD6AAAAADflRqKAAAAAOO0+jP/S/3XBaMFFgAAAAcAAgAAAAAAAAABAAADRv5wAAASx/9L/ggFowABAAAAAAAAAAAAAAAAAAAC1gABAAAC1gBhAAcAgQAGAAEAAgAeAAYAAABkAAAAAwADAAQCZAGQAAUACAKKAlgAAABLAooCWAAAAV4AMgEsAAAAAAAAAAAAAAAAAAAgAQAAAAAAAAAIAAAAAEtIRE0AwAAN/vwD6P4MAAAEsAH0AAAAQAAAAAABaQK/AAAAIAAEAiwASwJYAAACWAAAAIMAAAJnABgCaABTAh4AOgKCAFMCLgBUAgwAVAJgADYCogBTAP4AUwE3ABMCVwBTAc8AUwNJAFMCjQBTAqgANQJTAFMCqAA1AosAUwIuADACJAAPApYATgJnABgDkwAdAjQAEwI1ABMCFQAoAdkAJwIYAEkBsAAwAhgALwIHAC8BdwAeAe0AMAIpAEkA6gBJANkAAQINAEkA6wBKA08ASQIpAEkCFAAwAhgASAIYADABcgBJAbkALgFvAB4CKQBAAeQAGAK0ABgB0QAYAcsAGAHFACgCOgApAaIAMwI6AEMCLAA1AjoAKAI1AEECNwAxAhsASgIxACwCNwAxARAAWAEKAEEBEQBYAREAQwG+AEkCVgBJAh4ANAIYACgByQAYAZUASAHtACgCRQBJAe4AKADYADsB2wAxANwAQwGNAEMC9ABhBAkASQJEAEkCqwAlAukAQwFZAEYBWQAyAcEAVwEWAF8BxABUAVsASAGXADEBWwAvAREALAD4ACgB7AArAecAKwDZAEIB1wAoAaUAhAI+AEkChgBJBHoASQKQAEYCogBGAqIARgJbAEkB8ABJAigASQKdAEYCQABJAlcASQI1AEkB8gBJARYAXwLuAE0A8ABNAPAARAH6AEoBuABGAdAASgKQAEYCGgBiAiwARgIuAEYCtwBmAacATAGnADgAAP94AAD/eAJnABgCZwAYAmcAGAJnABgCZwAYAmcAGAJnABgCZwAYAmcAGAN/ABgCHgA6Ah4AOgIeADoCHgA6AtQAUgKCAFMC1ABSAi4AVAIuAFQCLgBUAi4AVAIuAFQCLgBUAi4AVAIuAFQCdAAsAmAANgJgADYCYAA2Ap4ANQD+AFMA/v/ZAP4AGwD+AFMA/v+9AP7/8QD+//ICVwBTAc8AUwHP/9cBzwBTAd0ADAKNAFMCjQBTAo0AUwJ6AFMCjQBTAqgANQKoADUCqAA1AqgANQKoADUCqAA1AqcANQKoADUD+gA1AlgAUwKLAFMCiwBTAosAUwIuADACLgAwAi4AMAIuADACZABKAlAAJQIkAA8CJAAPAiQADwKWAE4ClgBOApYATgKWAE4ClgBOApYATgKWAE4ClgBOA5MAHQOTAB0DkwAdA5MAHQI1ABMCNQATAjUAEwI1ABMCFQAoAhUAKAIVACgB2QAnAdkAJwHZACcB2QAnAdkAJwHZACcB2QAnAdkAJwHZACcDHgAnAbAAMAGwADABsAAwAbAAMAI9ADECGAAvAhgALwIMAC8CBwAvAgwALwH7AC8CBwAvAfsALwIHAC8CBwAvAgcAKgHtADAB7QAwAe0AMAIpACMA6gBJAPsASQEB/9AA+gAVAOgARwDpAAAA5//mAOr/6AINAEkA6wBKAOv/ywDrADUA6//tAikASQIpAEkCKQBJAisASQIpAEkCFAAwAhQAMAIUADACFAAwAhQAMAIUADACFAAwAhQAMANoADACGABIAXIASQFyAA4BcgA7AbkALgG5AC4BuQAuAbkALgJoAEgBbwAeAW//8QFvAB4BbwAeAikAQAIpAEACKQBAAikAQAIpAEACKQBAAikAQAIpAEACtAAYArQAGAK0ABgCtAAYAcsAGAHLABgBywAYAcUAKAHFACgBxQAoAdgAQQDRAEcBCABIAM3/5QEO/+4A3P/wAQsAAAD//+8BKf/vAUH/1QE3/8kDUgBHA3oARwFe//IBM//yAUv/8gGT//IB3f/yA1IARwN6AEcBXv/yATP/8gGT//IDUgBHA3oARwFe//IBS//yAZP/8gHd//IDUgBHA3oARwFe//IBS//yAZP/8gG///IDUgBHA3oARwFe//IBS//yAZP/8gGW//IDUgBHA3oARwFe//IBM//yApsASAKzAEgCrf/yAp3/8gKhAEgCsQBIAq3/8gKd//ICkgBIArMASAKt//ICmP/yApsASAKzAEgCrf/yAp3/8gIlAEgCRgBIAiUASAJGAEgCJQBIAkYASAFE/9gBAv/eAWf/2AEk/94BRP/YAWf/2AEk/94BAv/eAUT/2AFn/9gBRP/YAWf/2AFE/9gBAv/eAbP/2AEk/94EhQBHBLwASAL5//ICx//yBIUARwS8AEgC+f/yAsf/8gTHAEcE9QBHAzH/8gME//IExwBHBPUARwMx//IDBP/yAt0ASQMLAEkCzP/yAp7/8gLdAEkDCwBJAsz/8gKe//ICMABJAlkASQJS//IB2f/yAjAASQJZAEkCUv/yAdn/8gNTAEkDnwBJAcP/8gHH//IDUwBJA58ASQHD//IBx//yA1MASQOfAEkBw//yAcf/8gK7AEkC3ABJArsASQLcAEkBw//yAcf/8gNSAEkDegBJAgD/8gGH//IDaQBHA2oARwRRAEkD4ABHBIQASQIA//IDJP/yAYf/8gGH//IC8v/yA2kARwNoAEcEUQBJA+AARwSEAEkCAP/yAyT/8QGH//IBg//yAvL/8QK5AEgC8QBIAU3/8gEK//MCugBIAvEASAFN//IBCv/zAo8ARwLkAEcCMP/yAgb/8gK3AEcC5gBHAV7/8gEz//ICtwBHAuYARwHnAEcCBABJAm7/8gKw//IB5wBHAgQASQHnAEcCKwA7AkX/8gEz//IB5wBHAgQASQKw//ICVQBBAuz/8gKw//IB5wBHAgQASQHnAEcCKwA7AeAAQQHtAEEB4QBBAewAQQHhAEEB7ABBAeEAQQHsAEEC1wBHAuEARwLXAEcC4QBHApgARwFe//IBS//yAZP/8gHT//IC2AAuAuIARwKYAEcBXv/yATP/8gGT//IC2AA8AtcARwLhAEcCmABHAV7/8gFL//IBk//yAdD/8gJsAEcCmABHArgARwLnAEcAwQAAAhAAMQJGADECEAAWAkYAFwIQADACRgAxAiIAAAJV//wCEP/ZA4kARwPRAEcDjwBHA48ARwOTAC4DjwBHAkb/2gPRAEcD0QBHA+QAUAPRAEcDjwBH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AQ0BDgEUAQ8AdAETASYBIwEkASUBLwEWATEAigDiAIYA3gCLAOMAjwDnAJIA6gCQAOgAlADsAJUA7QCcAPQAmgDyAJ0A9QCXAO8AnwD3AKEA+QCgAPgAogD6AKgBAQCpAQIApgD7AKoBAwCrAQQArQEGAKwBBQCuAQcArwEIALEBCgCwAQkAswEMALkBEgC4AREAvAEVAL4BFwDAARkAvwEYAMEBGgDDARwAwgEbAMgBIQDHASAAxgEfAM8BKADRASoAzgEnANABKQDTASwA1wEwANgA2gEyANwBNADbATMAxAEdAMkBIgLEAsUCxwLLAswCyQLDAsICygLGAsgBNQE8ATgB+gE6AgkBNgFHAfQBUgFYAWIBagFuAXIBdAF4AXwBiAGMAZABlAGYAZwBoAGkAhsBqAG2AboB0gHaAd4B5AH4AgACAgKtAq4CrwKwArECsgKzArsCvAKrAqwCqgKXAmQCZQKRAUABtAKpAT4B6AHqAe4B9gH8Af4A1QEuANIBKwDUAS0ChAKCAoUCgwKLAoYCiQKKAocCjAKBAoACfgJ/AGAAYQBkAGIAYwBlAH4AfwBmAUwBTQFPAU4BXgFfAWEBYAGtAa8BrgFmAWcBaQFoAXYBdwGEAYYBgAGBAb4BwQHFAcMByAHLAc8BzQHoAekB6gHrAe0B7AHxAfMB8gIXAhACEQIUAhMCOAI6AkACQgJIAkoCUQJTAjkCOwJBAkMCSQJLAlICVAE1ATwBPQE4ATkB+gH7AToBOwIJAgoCDQIMATYBNwFHAUgBSgFJAfQB9QFSAVMBVQFUAVgBWQFbAVoBYgFjAWUBZAFqAWsBbQFsAW4BbwFxAXABcgFzAXQBdQF4AXoBfAF9AYgBiQGLAYoBjAGNAY8BjgGQAZEBkwGSAZQBlQGXAZYBmAGZAZsBmgGcAZ0BnwGeAaABoQGjAaIBpAGlAacBpgGoAakBqwGqAbYBtwG5AbgBugG7Ab0BvAHSAdMB1QHUAdoB2wHdAdwB3gHfAeEB4AHkAeUB5wHmAfgB+QIAAgECAgIDAgYCBQIiAiMCHgIfAiACIQIcAh0AAAAAAEIAQgBCAEIAXACNALgA2gDyAQcBOQFRAV0BdAGZAakBxAHbAgMCJAJWAoYCwwLVAvMDBwMkAz8DVANqA6sD2QP8BCoEXQSHBQIFLgVABVkFfAWJBdMGAAYz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AAEACgB2AAMAAQQJAAIADgCAAAMAAQQJAAMAMACOAAMAAQQJAAQAGgC+AAMAAQQJAAUAGgDYAAMAAQQJAAYAGgDyAAMAAQQJAAcAUAEMAAMAAQQJAAgAGAFcAAMAAQQJAAkAGAFcAAMAAQQJAAoAmgF0AAMAAQQJAAsAIAIOAAMAAQQJAAwAQAIuAAMAAQQJAA0AmgF0AAMAAQQJAA4AKgJuAAMAAQQJABAACgB2AAMAAQQJABEADgCAAAMAAQQJAGQByAKYAEMAbwBwAHkAcgBpAGcAaAB0ACAAKABjACkAIAAyADAAMgAxACAAYgB5ACAAdwB3AHcALgBmAG8AbgB0AGkAcgBhAG4ALgBjAG8AbQAgAEEAbABsACAAcgBpAGcAaAB0AHMAIAByAGUAcwBlAHIAdgBlAGQALgBQAGUAeQBkAGEAUgBlAGcAdQBsAGEAcgAzAC4AMAAwADAAOwBLAEgARABNADsAUABlAHkAZABhAC0AUgBlAGcAdQBsAGEAcgBQAGUAeQBkAGEAIABSAGUAZwB1AGwAYQByAFYAZQByAHMAaQBvAG4AIAAzAC4AMAAwADAAUABlAHkAZABhAC0AUgBlAGcAdQBsAGEAcgBQAGUAeQBkAGEAIABpAHMAIABhACAAdAByAGEAZABlAG0AYQByAGsAIABvAGYAIAB3AHcAdwAuAGYAbwBuAHQAaQByAGEAbgAuAGMAbwBtAE4AYQBzAGUAcgAgAEsAaABhAGQAZQBtAFQAbwAgAHUAcwBlACAAdABoAGkAcwAgAGYAbwBuAHQALAAgAGkAdAAgAGkAcwAgAG4AZQBjAGUAcwBzAGEAcgB5ACAAdABvACAAbwBiAHQAYQBpAG4AIAB0AGgAZQAgAGwAaQBjAGUAbgBzAGUAIABmAHIAbwBtACAAdwB3AHcALgBmAG8AbgB0AGkAcgBhAG4ALgBjAG8AbQB3AHcAdwAuAGYAbwBuAHQAaQByAGEAbgAuAGMAbwBtAGgAdAB0AHAAcwA6AC8ALwBkAHIAaQBiAGIAYgBsAGUALgBjAG8AbQAvAG4AYQBzAGUAcgBrAGgAYQBkAGUAbQBmAG8AbgB0AGkAcgBhAG4ALgBjAG8AbQAvAGwAaQBjAGUAbgBzAGUAcwBlAHkASgBwAGQAaQBJADYASQBtAGQAawBNADIATQByAFMARgBNAHYAUQBWAGcAMABPAEgAcABHAGUAaQA4ADMAZQBHADkASABRAGwARQA5AFAAUwBJAHMASQBuAFoAaABiAEgAVgBsAEkAagBvAGkAYQBtADEAVQBXAFcAVgBXAFYAMAA1AHIAWgAxAEIAMQBMADAAcABhAFIAbABZADUAUwBqAGwAQwBUAG0AOQBEAFEAVgBWAHEAUwBUAFoARgBSAG4ATgBIAFUAWABwAGgAYgB6AGgAdABUAEYAbABxAGMAegAwAGkATABDAEoAdABZAFcATQBpAE8AaQBJADAAWgBXAFkAegBNAEQAZABtAFkAMgBaAGwAWQB6AEYAaQBZAFQAaABpAFkAVABZAHcATwBHAEYAbQBZAFQAQQB5AE4ARABVAHkATgBUAFYAagBNAG0AWgBtAE0AagBKAGsATgB6AGcANABZAGoARQA0AFoAagBBADIAWgBXAEYAaABNAGoAawB5AE0ARABFAHkAWQBUAFYAbABNADIAVgBtAE0ARwBRAHoASQBpAHcAaQBkAEcARgBuAEkAagBvAGkASQBuADAAPQAAAAIAAAAAAAD/nAAyAAAAAAAAAAAAAAAAAAAAAAAAAAAC1gAAAAEAAgADACQAJQAmACcAKAApACoAKwAsAC0ALgAvADAAMQAyADMANAA1ADYANwA4ADkAOgA7ADwAPQBEAEUARgBHAEgASQBKAEsATABNAE4ATwBQAFEAUgBTAFQAVQBWAFcAWABZAFoAWwBcAF0AEwAUABUAFgAXABgAGQAaABsAHAARAA8AHQAeABAADgANAEEA2QASAB8AIAAhAAQAIgAKAAUABgAjAAcACAAJAAsADABeAF8AYAA+AD8AQAC2ALcAtAC1AMQAxQCHAEIAsgCzAIwAigCLAL0AhACFAJYA7wCTAPAAuADoAKsAwwCjAKIAgwC8AIgAhgCCAMIAYQC+AL8BAgEDAMkBBADHAGIArQEFAQYAYwCuAJAA/QD/AGQBBwDpAQgBCQBlAQoAyADKAQsAywEMAQ0BDgD4AQ8BEAERAMwAzQDOAPoAzwESARMBFAEVARYBFwDiARgBGQEaAGYBGwDQANEAZwDTARwBHQCRAK8AsADtAR4BHwEgASEA5AD7ASIBIwEkASUBJgEnANQA1QBoANYBKAEpASoBKwEsAS0BLgEvAOsBMAC7ATEBMgDmATMAaQE0AGsAbABqATUBNgBuAG0AoAD+AQAAbwE3AOoBOAEBAHABOQByAHMBOgBxATsBPAE9APkBPgE/AUAA1wB0AHYAdwFBAHUBQgFDAUQBRQFGAUcA4wFIAUkBSgB4AUsAeQB7AHwAegFMAU0AoQB9ALEA7gFOAU8BUAFRAOUA/AFSAIkBUwFUAVUBVgB+AIAAgQB/AVcBWAFZAVoBWwFcAV0BXgDsAV8AugFgAOcBYQFiAWMBZAFlAWYBZwFoAWkBagFrAWwBbQFuAW8BcAFxAXIBcwF0AXUBdgF3AXgBeQF6AXsBfAF9AX4BfwGAAYEBggGDAYQBhQGGAYcBiAGJAYoBiwGMAY0BjgGPAZABkQGSAZMBlAGVAZYBlwGYAZkBmgGbAZwBnQGeAZ8BoAGhAaIBowGkAaUBpgGnAagBqQGqAasBrAGtAa4BrwGwAbEBsgGzAbQBtQG2AbcBuAG5AboBuwG8Ab0BvgG/AcABwQHCAcMBxAHFAcYBxwHIAckBygHLAcwBzQHOAc8B0AHRAdIB0wHUAdUB1gHXAdgB2QHaAdsB3AHdAd4B3wHgAeEB4gHjAeQB5QHmAecB6AHpAeoB6wHsAe0B7gHvAfAB8QHyAfMB9AH1AfYB9wH4AfkB+gH7AfwB/QH+Af8CAAIBAgICAwIEAgUCBgIHAggCCQIKAgsCDAINAg4CDwIQAhECEgITAhQCFQIWAhcCGAIZAhoCGwIcAh0CHgIfAiACIQIiAiMCJAIlAiYCJwIoAikCKgIrAiwCLQIuAi8CMAIxAjICMwI0AjUCNgI3AjgCOQI6AjsCPAI9Aj4CPwJAAkECQgJDAkQCRQJGAkcCSAJJAkoCSwJMAk0CTgJPAlACUQJSAlMCVAJVAlYCVwJYAlkCWgJbAlwCXQJeAl8CYAJhAmICYwJkAmUCZgJnAmgCaQJqAmsCbAJtAm4CbwJwAnECcgJzAnQCdQJ2AncCeAJ5AnoCewJ8An0CfgJ/AoACgQKCAoMChAKFAoYChwKIAokCigKLAowCjQKOAo8CkAKRApICkwKUApUClgKXApgCmQKaApsCnAKdAp4CnwKgAqECogKjAqQCpQKmAqcCqAKpAqoCqwKsAq0CrgKvArACsQKyArMCtAK1ArYCtwK4ArkCugK7ArwCvQK+Ar8CwACpAKoCwQLCAsMCxALFAsYCxwLIAskCygLLAswCzQLOAs8C0ALRAtIC0wLUAtUC1gLXAtgC2QLaAtsC3ALdAt4C3wLgAuEC4gLjAuQC5QLmAucC6ALpAuoC6wLsAu0C7gLvAvAC8QLyAvMC9AL1AvYC9wL4AvkC+gL7AOEC/AL9Av4C/wd1bmkwNjVBB3VuaTA2NUIGQWJyZXZlB0FtYWNyb24HQW9nb25lawpDZG90YWNjZW50BkRjYXJvbgZEY3JvYXQGRWNhcm9uCkVkb3RhY2NlbnQHRW1hY3JvbgdFb2dvbmVrB3VuaTAxOEYHdW5pMDEyMgpHZG90YWNjZW50BEhiYXIHSW1hY3JvbgdJb2dvbmVrB3VuaTAxMzYGTGFjdXRlBkxjYXJvbgd1bmkwMTNCBk5hY3V0ZQZOY2Fyb24HdW5pMDE0NQNFbmcNT2h1bmdhcnVtbGF1dAdPbWFjcm9uBlJhY3V0ZQZSY2Fyb24HdW5pMDE1NgZTYWN1dGUHdW5pMDIxOAd1bmkxRTlFBFRiYXIGVGNhcm9uB3VuaTAxNjIHdW5pMDIxQQ1VaHVuZ2FydW1sYXV0B1VtYWNyb24HVW9nb25lawVVcmluZwZXYWN1dGULV2NpcmN1bWZsZXgJV2RpZXJlc2lzBldncmF2ZQtZY2lyY3VtZmxleAZZZ3JhdmUGWmFjdXRlClpkb3RhY2NlbnQGYWJyZXZlB2FtYWNyb24HYW9nb25lawpjZG90YWNjZW50BmRjYXJvbgZlY2Fyb24KZWRvdGFjY2VudAdlbWFjcm9uB2VvZ29uZWsHdW5pMDI1OQd1bmkwMTIzCmdkb3RhY2NlbnQEaGJhcglpLmxvY2xUUksHaW1hY3Jvbgdpb2dvbmVrB3VuaTAxMzcGbGFjdXRlBmxjYXJvbgd1bmkwMTNDBm5hY3V0ZQZuY2Fyb24HdW5pMDE0NgNlbmcNb2h1bmdhcnVtbGF1dAdvbWFjcm9uBnJhY3V0ZQZyY2Fyb24HdW5pMDE1NwZzYWN1dGUHdW5pMDIxOQR0YmFyBnRjYXJvbgd1bmkwMTYzB3VuaTAyMUINdWh1bmdhcnVtbGF1dAd1bWFjcm9uB3VvZ29uZWsFdXJpbmcGd2FjdXRlC3djaXJjdW1mbGV4CXdkaWVyZXNpcwZ3Z3JhdmULeWNpcmN1bWZsZXgGemFjdXRlCnpkb3RhY2NlbnQHdW5pMDYyMQd1bmkwNjI3DHVuaTA2MjcuZmluYQd1bmkwNjIzDHVuaTA2MjMuZmluYQd1bmkwNjI1DHVuaTA2MjUuZmluYQd1bmkwNjIyDHVuaTA2MjIuZmluYQd1bmkwNjcxDHVuaTA2NzEuZmluYQd1bmkwNjZFDHVuaTA2NkUuZmluYQx1bmkwNjZFLm1lZGkMdW5pMDY2RS5pbml0EHVuaTA2NkUuaW5pdC5hbHQRdW5pMDY2RS5pbml0LmFsdDIRdW5pMDY2RS5pbml0LmFsdDMHdW5pMDYyOAx1bmkwNjI4LmZpbmEMdW5pMDYyOC5tZWRpDHVuaTA2MjguaW5pdBB1bmkwNjI4LmluaXQuYWx0B3VuaTA2N0UMdW5pMDY3RS5maW5hDHVuaTA2N0UubWVkaQx1bmkwNjdFLmluaXQQdW5pMDY3RS5pbml0LmFsdBF1bmkwNjdFLmluaXQuYWx0Mgd1bmkwNjJBDHVuaTA2MkEuZmluYQx1bmkwNjJBLm1lZGkMdW5pMDYyQS5pbml0EHVuaTA2MkEuaW5pdC5hbHQRdW5pMDYyQS5pbml0LmFsdDIHdW5pMDYyQgx1bmkwNjJCLmZpbmEMdW5pMDYyQi5tZWRpDHVuaTA2MkIuaW5pdBB1bmkwNjJCLmluaXQuYWx0EXVuaTA2MkIuaW5pdC5hbHQyB3VuaTA2NzkMdW5pMDY3OS5maW5hDHVuaTA2NzkubWVkaQx1bmkwNjc5LmluaXQHdW5pMDYyQwx1bmkwNjJDLmZpbmEMdW5pMDYyQy5tZWRpDHVuaTA2MkMuaW5pdAd1bmkwNjg2DHVuaTA2ODYuZmluYQx1bmkwNjg2Lm1lZGkMdW5pMDY4Ni5pbml0B3VuaTA2MkQMdW5pMDYyRC5maW5hDHVuaTA2MkQubWVkaQx1bmkwNjJELmluaXQHdW5pMDYyRQx1bmkwNjJFLmZpbmEMdW5pMDYyRS5tZWRpDHVuaTA2MkUuaW5pdAd1bmkwNjJGDHVuaTA2MkYuZmluYQd1bmkwNjMwDHVuaTA2MzAuZmluYQd1bmkwNjg4DHVuaTA2ODguZmluYQd1bmkwNjMxC3VuaTA2MzEuYWx0DHVuaTA2MzEuZmluYRB1bmkwNjMxLmZpbmEuYWx0B3VuaTA2MzIMdW5pMDYzMi5maW5hEHVuaTA2MzIuZmluYS5hbHQLdW5pMDYzMi5hbHQHdW5pMDY5MQx1bmkwNjkxLmZpbmEHdW5pMDY5NQx1bmkwNjk1LmZpbmEHdW5pMDY5OAt1bmkwNjk4LmFsdAx1bmkwNjk4LmZpbmEQdW5pMDY5OC5maW5hLmFsdAd1bmkwNjMzDHVuaTA2MzMuZmluYQx1bmkwNjMzLm1lZGkMdW5pMDYzMy5pbml0B3VuaTA2MzQMdW5pMDYzNC5maW5hDHVuaTA2MzQubWVkaQx1bmkwNjM0LmluaXQHdW5pMDYzNQx1bmkwNjM1LmZpbmEMdW5pMDYzNS5tZWRpDHVuaTA2MzUuaW5pdAd1bmkwNjM2DHVuaTA2MzYuZmluYQx1bmkwNjM2Lm1lZGkMdW5pMDYzNi5pbml0B3VuaTA2MzcMdW5pMDYzNy5maW5hDHVuaTA2MzcubWVkaQx1bmkwNjM3LmluaXQHdW5pMDYzOAx1bmkwNjM4LmZpbmEMdW5pMDYzOC5tZWRpDHVuaTA2MzguaW5pdAd1bmkwNjM5DHVuaTA2MzkuZmluYQx1bmkwNjM5Lm1lZGkMdW5pMDYzOS5pbml0B3VuaTA2M0EMdW5pMDYzQS5maW5hDHVuaTA2M0EubWVkaQx1bmkwNjNBLmluaXQHdW5pMDY0MQx1bmkwNjQxLmZpbmEMdW5pMDY0MS5tZWRpDHVuaTA2NDEuaW5pdAd1bmkwNkE0DHVuaTA2QTQuZmluYQx1bmkwNkE0Lm1lZGkMdW5pMDZBNC5pbml0B3VuaTA2QTEMdW5pMDZBMS5maW5hDHVuaTA2QTEubWVkaQx1bmkwNkExLmluaXQHdW5pMDY2Rgx1bmkwNjZGLmZpbmEHdW5pMDY0Mgx1bmkwNjQyLmZpbmEMdW5pMDY0Mi5tZWRpDHVuaTA2NDIuaW5pdAd1bmkwNjQzDHVuaTA2NDMuZmluYQx1bmkwNjQzLm1lZGkMdW5pMDY0My5pbml0B3VuaTA2QTkLdW5pMDZBOS5hbHQMdW5pMDZBOS5zczAxDHVuaTA2QTkuZmluYRF1bmkwNkE5LmZpbmEuc3MwMQx1bmkwNkE5Lm1lZGkRdW5pMDZBOS5tZWRpLnNzMDEMdW5pMDZBOS5pbml0EHVuaTA2QTkuaW5pdC5hbHQRdW5pMDZBOS5pbml0LnNzMDEHdW5pMDZBRgt1bmkwNkFGLmFsdAx1bmkwNkFGLnNzMDEMdW5pMDZBRi5maW5hEXVuaTA2QUYuZmluYS5zczAxDHVuaTA2QUYubWVkaRF1bmkwNkFGLm1lZGkuc3MwMQx1bmkwNkFGLmluaXQQdW5pMDZBRi5pbml0LmFsdBF1bmkwNkFGLmluaXQuc3MwMQd1bmkwNjQ0DHVuaTA2NDQuZmluYQx1bmkwNjQ0Lm1lZGkMdW5pMDY0NC5pbml0B3VuaTA2QjUMdW5pMDZCNS5maW5hDHVuaTA2QjUubWVkaQx1bmkwNkI1LmluaXQHdW5pMDY0NQx1bmkwNjQ1LmZpbmEMdW5pMDY0NS5tZWRpDHVuaTA2NDUuaW5pdAd1bmkwNjQ2DHVuaTA2NDYuZmluYQx1bmkwNjQ2Lm1lZGkMdW5pMDY0Ni5pbml0B3VuaTA2QkEMdW5pMDZCQS5maW5hB3VuaTA2NDcMdW5pMDY0Ny5maW5hDHVuaTA2NDcubWVkaQx1bmkwNjQ3LmluaXQHdW5pMDZDMAx1bmkwNkMwLmZpbmEHdW5pMDZDMQx1bmkwNkMxLmZpbmEMdW5pMDZDMS5tZWRpDHVuaTA2QzEuaW5pdAd1bmkwNkMyDHVuaTA2QzIuZmluYQd1bmkwNkJFDHVuaTA2QkUuZmluYQx1bmkwNkJFLm1lZGkMdW5pMDZCRS5pbml0B3VuaTA2MjkMdW5pMDYyOS5maW5hB3VuaTA2QzMMdW5pMDZDMy5maW5hB3VuaTA2NDgMdW5pMDY0OC5maW5hB3VuaTA2MjQMdW5pMDYyNC5maW5hB3VuaTA2QzYMdW5pMDZDNi5maW5hB3VuaTA2QzcMdW5pMDZDNy5maW5hB3VuaTA2NDkMdW5pMDY0OS5maW5hB3VuaTA2NEEMdW5pMDY0QS5maW5hEXVuaTA2NEEuZmluYS5zczAxDHVuaTA2NEEubWVkaQx1bmkwNjRBLmluaXQQdW5pMDY0QS5pbml0LmFsdBF1bmkwNjRBLmluaXQuYWx0Mgd1bmkwNjI2DHVuaTA2MjYuZmluYRF1bmkwNjI2LmZpbmEuc3MwMQx1bmkwNjI2Lm1lZGkMdW5pMDYyNi5pbml0EHVuaTA2MjYuaW5pdC5hbHQHdW5pMDZDRQd1bmkwNkNDDHVuaTA2Q0MuZmluYRF1bmkwNkNDLmZpbmEuc3MwMQx1bmkwNkNDLm1lZGkMdW5pMDZDQy5pbml0EHVuaTA2Q0MuaW5pdC5hbHQRdW5pMDZDQy5pbml0LmFsdDIHdW5pMDZEMgx1bmkwNkQyLmZpbmEHdW5pMDc2OQx1bmkwNzY5LmZpbmEHdW5pMDY0MAt1bmkwNjQ0MDYyNxB1bmkwNjQ0MDYyNy5maW5hC3VuaTA2NDQwNjIzEHVuaTA2NDQwNjIzLmZpbmELdW5pMDY0NDA2MjUQdW5pMDY0NDA2MjUuZmluYQt1bmkwNjQ0MDYyMhB1bmkwNjQ0MDYyMi5maW5hC3VuaTA2NDQwNjcxEHVuaTA2NkUwNkNDLmZpbmEVdW5pMDY2RTA2Q0MuX2ZpbmEuYWx0EHVuaTA2MjgwNjQ5LmZpbmEQdW5pMDYyODA2NEEuZmluYRB1bmkwNjI4MDYyNi5maW5hEHVuaTA2MjgwNkNDLmZpbmEQdW5pMDY0NDA2NzEuZmluYRB1bmkwNjdFMDY0OS5maW5hEHVuaTA2N0UwNjRBLmZpbmEQdW5pMDY3RTA2MjYuZmluYRB1bmkwNjdFMDZDQy5maW5hEHVuaTA2MkEwNjQ5LmZpbmEQdW5pMDYyQTA2NEEuZmluYRB1bmkwNjJBMDYyNi5maW5hEHVuaTA2MkEwNkNDLmZpbmEQdW5pMDYyQjA2NDkuZmluYRB1bmkwNjJCMDY0QS5maW5hEHVuaTA2MkIwNjI2LmZpbmEQdW5pMDYyQjA2Q0MuZmluYQt1bmkwNjMzMDY0ORB1bmkwNjMzMDY0OS5maW5hC3VuaTA2MzMwNjRBEHVuaTA2MzMwNjRBLmZpbmELdW5pMDYzMzA2MjYQdW5pMDYzMzA2MjYuZmluYQt1bmkwNjMzMDZDQxB1bmkwNjMzMDZDQy5maW5hC3VuaTA2MzQwNjQ5EHVuaTA2MzQwNjQ5LmZpbmELdW5pMDYzNDA2NEEQdW5pMDYzNDA2NEEuZmluYQt1bmkwNjM0MDYyNhB1bmkwNjM0MDYyNi5maW5hC3VuaTA2MzQwNkNDEHVuaTA2MzQwNkNDLmZpbmELdW5pMDYzNTA2NDkQdW5pMDYzNTA2NDkuZmluYQt1bmkwNjM1MDY0QRB1bmkwNjM1MDY0QS5maW5hC3VuaTA2MzUwNjI2EHVuaTA2MzUwNjI2LmZpbmELdW5pMDYzNTA2Q0MQdW5pMDYzNTA2Q0MuZmluYRp1bmkwNjM2X2ZhcnNpX3VuaTA2Q0MuZmluYQt1bmkwNjM2MDY0ORB1bmkwNjM2MDY0OS5maW5hC3VuaTA2MzYwNjRBEHVuaTA2MzYwNjRBLmZpbmELdW5pMDYzNjA2MjYQdW5pMDYzNjA2MjYuZmluYQt1bmkwNjM2MDZDQxB1bmkwNjQ2MDY0OS5maW5hEHVuaTA2NDYwNjRBLmZpbmEQdW5pMDY0NjA2MjYuZmluYRB1bmkwNjQ2MDZDQy5maW5hEHVuaTA2NEEwNjRBLmZpbmEQdW5pMDY0QTA2Q0MuZmluYRB1bmkwNjI2MDY0OS5maW5hEHVuaTA2MjYwNjRBLmZpbmEQdW5pMDYyNjA2MjYuZmluYRB1bmkwNjI2MDZDQy5maW5hEHVuaTA2Q0MwNkNDLmZpbmEHdW5pRkRGMgd1bmkwNjZCB3VuaTA2NkMHdW5pMDY2MAd1bmkwNjYxB3VuaTA2NjIHdW5pMDY2Mwd1bmkwNjY0B3VuaTA2NjUHdW5pMDY2Ngd1bmkwNjY3B3VuaTA2NjgHdW5pMDY2OQd1bmkwNkYwB3VuaTA2RjEHdW5pMDZGMgd1bmkwNkYzB3VuaTA2RjQHdW5pMDZGNQd1bmkwNkY2B3VuaTA2RjcHdW5pMDZGOAd1bmkwNkY5DHVuaTA2RjQudXJkdQx1bmkwNkY3LnVyZHUHdW5pMzAwMAd1bmkyMDVGB3VuaTIwMEUHdW5pMjAwRgd1bmkyMDBEB3VuaTIwMEMHdW5pMjAwMQd1bmkyMDAzB3VuaTIwMDAHdW5pMjAwMgd1bmkyMDA1B3VuaTIwMEEHdW5pMjAyRgd1bmkyMDA2B3VuaTIwMDkHdW5pMjAwNAd1bmkyMDBCB3VuaTA2RDQHdW5pMDYwQwd1bmkwNjFCB3VuaTA2MUYHdW5pMDY2RAd1bmlGRDNFB3VuaUZEM0YHdW5pRkRGQwd1bmkwNjZBB3VuaTA2MTUKZG90YWJvdmVhcgpkb3RiZWxvd2FyC2RvdGNlbnRlcmFyFnR3b2RvdHN2ZXJ0aWNhbGFib3ZlYXIWdHdvZG90c3ZlcnRpY2FsYmVsb3dhchh0d29kb3RzaG9yaXpvbnRhbGFib3ZlYXIYdHdvZG90c2hvcml6b250YWxiZWxvd2FyFHRocmVlZG90c2Rvd25hYm92ZWFyFHRocmVlZG90c2Rvd25iZWxvd2FyEnRocmVlZG90c3VwYWJvdmVhchJ0aHJlZWRvdHN1cGJlbG93YXIHd2FzbGFhcgttaW5pS2VoZWhhchFnYWZzYXJrYXNoYWJvdmVhchVnYWZzYXJrYXNoYWJvdmVhci5hbHQSZ2Fmc2Fya2FzaGNlbnRlcmFyB3VuaTA2NzAHdW5pMDY1Ngd1bmkwNjU0B3VuaTA2NTUHdW5pMDY0Qgd1bmkwNjRDB3VuaTA2NEQHdW5pMDY0RQd1bmkwNjRGB3VuaTA2NTAHdW5pMDY1MQt1bmkwNjUxMDY0Qgt1bmkwNjUxMDY0Qwt1bmkwNjUxMDY0RAt1bmkwNjUxMDY0RQt1bmkwNjUxMDY0Rgt1bmkwNjUxMDY1MAt1bmkwNjUxMDY3MAd1bmkwNjUyB3VuaTA2NTMIc2FyZXlhYXIRc2V2ZW5zYW1sbC5ib3R0b20Qc2V2ZW5zbWFsbC5hYm92ZQ55ZWhzYW1sLmJvdHRvbQ15ZWhzbWFsLmFib3ZlB3VuaTAzMDgHdW5pMDMwNwlncmF2ZWNvbWIJYWN1dGVjb21iB3VuaTAzMEIHdW5pMDMwMgd1bmkwMzBDB3VuaTAzMDYHdW5pMDMwQQl0aWxkZWNvbWIHdW5pMDMwNAd1bmkwMzEyB3VuaTAzMjYHdW5pMDMyNwd1bmkwMzI4DHVuaTA2Y2UuZmluYQx1bmkwNmNlLmluaXQMdW5pMDZjZS5tZWRpDHVuaTA2ZDUuZmluYQAAAQACAA4AAAAAAAAANgACAAYAgwCEAAMBNQIbAAECHAJjAAICmAK8AAMCwgLQAAMC0gLVAAEAAQACAAAADAAAABgAAQAEAqoCrAKvArIAAQAVAIMAhAKYAqQCpQKpAqsCrQKuArACsQKzArQCtQK2ArcCuAK5AroCuwK8AAEAAAAKAH4AugADREZMVAAUYXJhYgAYbGF0bgAuAFQAAAAKAAFVUkQgAFAAAP//AAMAAAADAAQALgAHQVpFIAA6Q1JUIAA6S0FaIAA6TU9MIAA6Uk9NIAA6VEFUIAA6VFJLIAA6AAD//wADAAEAAgAEAAD//wADAAAAAgAEAAVrZXJuACBrZXJuACBtYXJrACptYXJrACpta21rADQAAAADAAAAAQACAAAAAwADAAQABQAAAAIABgAHAAgAEgXyFvgZmhpOJ3wx9jJsAAIACAACAAoEKgABAEQABAAAAB0C5ALkAIIAggLyAIgAtgEYARgBJgGAAYoB/AIKAnwC1gLWAuQC5ALyAvIDCAMOAxwD6gPwBAYEEAQWAAEAHQBCAEMARABFAEYASABLAFEAUgBYAFkAWgBcAF0AXgBhAGMAZABlAGgAaQB3AHgAeQCBAIICcAJ2AncAAQAZ//MACwAE/9sADf/tABcABQAd//cAIP/wACH/7AAi//AAJP/yACz/8AAu/+wAMP/1ABgABP/WAAb/+gAK//kADf/tABL/+QAU//kAHv/qACD/3wAh/94AIv/fACT/4AAq/+wAK//sACz/3wAt/+wALv/eAC//7AAw/+UAMv/uADP/+QA0//oANv/4ADf/9wBLAAAAAwBL/8AAVP/0AFf/5QAWAAb/9AAK//MAEv/zABT/8wAe//oAIP/uACH/7QAi/+4AI//7ACcACwAq//sAK//7ACz/7gAt//sALv/tAC//+wAw//sAMv/xADP/+wA0//gANv/7AFr/9QACAFz/+gBf//oAHAAE/+8ABv/qAAr/6QAS/+kAFP/pABb/9wAe/+cAIP/hACH/4QAi/+EAI//3ACcACgAq/+wAK//sACz/4QAt/+wALv/hAC//7AAw/+4AMf/xADL/5AAz/+gANP/mADX/8wA2/+kAN//yAFj/+gBa/+4AAwBZ//UAXP/uAF//6wAcAAT/7AAG/+gACv/mABL/5gAU/+YAFv/3AB7/4wAg/9wAIf/dACL/3AAj//EAJwAEACr/6wAr/+sALP/cAC3/6wAu/90AL//rADD/6wAx/+kAMv/gADP/4gA0/+EANf/xADb/5AA3/+8AWP/6AFr/6wAWAAb/9gAK//YAEv/2ABT/9gAW//sAF//IABj/9QAZ/9MAGv/hABz/vAAg//sAIv/7ACP/+gAs//sAMf/zADP/6QA0/+8ANv/qAFH/ugBS/7oAYf+8AGP/vAADAEv/uQBU/+gAV//jAAMAGf/NACP/9QAz/98ABQAZ/+IAG//aACP/9QAz//QANf/jAAEAKf/IAAMAF//TABn/+gAc/+AAMwAE/94ABf/mAAb/5gAH/+YACP/mAAn/5gAK/+YAC//mAAz/5gAN//UADv/mAA//5gAQ/+YAEf/mABL/5gAT/+YAFP/mABX/5gAW/+cAF/+0ABj/5QAZ/9YAGv/d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ABn/4gAb//gAM//4ADX//QBQ/+0AWf/6AFz/6ABe/90AX//rAGr/8gAYAAT/5AAN/+oAF//mABv/9QAc//kAHf/3ACD/9wAh//gAIv/3ACT/+wAs//cALv/4AEL/2ABD/9gARv/YAEv/5QBX//gAZP/YAGX/2ABo/9gAaf/YAHb/2ACB/+AAgv/uAAMAGf/4ACcAEwBe//kABQAZ//gAUP/6AFz/9QBe//cAX//yAAEAd//IAAkAGf/jADP//ABI//0AUP/sAFn/+wBc/+wAXv/bAF//6gBq//AACwAZ/+AAG//rADP/9wA1//QASP/9AFD/6wBZ/+4AXP/hAF7/2gBf/9wAav/yAAsAGf/iABv/7AAz//gANf/1AEj/+ABQ/+gAWf/tAFz/4QBe/9sAX//dAGr/7wAHABv/5QBL/98AV//4AFn/+wBc/+sAXv/7AF//5QAKABn/6wAb//0AM//5ADX//QBQ//UAWf/5AFz/5wBe/+kAX//iAGr/9QAEABn/9gBc//oAXv/3AF//9wAIABn/5gAb//gAUP/1AFn/+wBc/+wAXv/pAF//6wBq//UAHgAE/+8ADf/oABf/wAAZ//gAG//nABz/2QAd//MAHv/4ACD/9wAh//gAIv/3ACT/9wAs//cALv/4ADD/+wBC/98AQ//fAEb/9ABL/+wAUP/4AFn/+wBc/+cAXv/3AF//4gBk/98AZf/fAGj/9ABp//QAdv/fAIH/9AAIABn/9wAb/+cAS//vAFD/+ABZ//gAXP/mAF7/9wBf/+EAEgAN//0AF/+8ABn/+gAc/9oAHv/9ACD/9AAh//QAIv/0ACT/9gAs//QALv/0AEb/4gBc//MAXv/5AF//8ABo/+IAaf/iAIH/5gAHABn/+AAb/+cAS//rAFD/+ABc/+oAXv/3AF//5QAGABn/8wBQ//oAXP/yAF7/9ABf/+8Aav/7AAQADf/6ABf/8wAZ//oAHP/kABEABv/6AAr/+gAS//oAFP/6ABf/2QAY//sAGf/hABr/7QAc/8sAMf/6ADP/9QA0//gANv/1AFH/0QBS/9EAYf/SAGP/0gADAAT/5QAN/+wAHf/7AAcABP/mAA3/6gAX//gAGf/6ABv/+AAc/+oAHf/1AAIHUAAEAAAHZggkACAAHQAA//r/9f/9//b/9//x/+P//f/7//X/8f/zAAAAAAAA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CE4IVAhaCGAIZghsCJYIcgh4CH4IrgiECIoIkAiWCJwIogioCK4ItAi6CMAIxgjMCNII2AkgCN4I5AjqCPAI9gj8CQIJCAkOCRQJGgkgCSYAAAksAAAJMgl6CTgJegk+CUQJSgnCCVAJVglcCWIJaAluCXQJegmACYYJjAmSCZgJngmkCaoJsAm2CbwJwgnICc4J1AnaCeAJ5gnsCfIJ+An+CgQKCgoQChYKHAoiCigKLgo0CjoKQApGCkwMegpSAAAKWAAACl4AAApkAAAKagpwCnYKfAqCCogKjgqUCpoKoAqmCqwKsgq4Cr4KxArKCtAK1grcCuIK6AruCvQK+gsACwYLfgsMAAALEgAACxgLHgskCyoLMAs2CzwLQgtIAAALTgAAC1QLWgtgC2YLbAtyC3gLfguEC4oLkAuWC5wLoguoC64LtAu6C8ALxgvMAAAL0gAAC9gAAAveAAAL5AAAC+oAAAvwC/YL/AykDAIMCAwODBQMGgwgDCYMLAwyDDgMPgxEDEoMUAxWAAAMXAAADGIAAAxoDG4MdAx6DIAMhgyMAAAMkgyYDJ4MpAyqDLAMtgy8DMIMyAzODNQM2gzgDOYAAAzsAAAM8gAADPgAAAz+DQQNCgABAP//6wABAQAB6gABAHH/nAABAGwC+gABAI//nAABAHMDAQABAGwD/QABAH4EBwABAHv+mQABAJD+mAABAJEDKAABAI8DMgABAMID0AABAKYD2QABAbr/nAABAbgBuAABAcf/nAABAb0BvAABALP/nAABALcBmwABAJP/nAABAJIBzQABAJX/nAABAJ4B0QABALABvQABAJn/nAABALkBvgABAbP+xAABAbYBwwABAbL+xgABAbABxwABAK4BoAABAGr+vwABAJABywABAH7+0AABAK0BxAABAbL+TAABAcMBxwABAcb+RwABAb8BxwABAK/+SAABALMBmwABAIT+SgABAJEBwAABALP+QwABAKcBsQABALf+gQABAL8BbgABAcD/lQABAaoB3AABAbn/lQABAaoB5QABAK7/nAABALMCaAABAI7/nAABAJgCjQABAJj/mgABALwCigABAKL/nAABAKECkAABAa7/nAABAb7/nAABAa4CmwABAKj/nAABAK0C6wABAJb/nAABAJcDDQABAJz/nAABAOEDCwABAJf/nAABAJ0DBwABAZ4CwwABAaYCwwABALIC7QABAIsDBgABASn+WAABAPICAQABAQD+VwABAPAB/wABATv+wgABAMMB7AABAT3+ygABAM0B7AABAP7+WAABANwCAQABAQv+UwABAOIBvwABATj+SgABANcB5wABATb+SAABAMgB6gABAQX+UAABAPb+TAABANACAAABAL0B7AABAOb/nAABALkB6wABAN7+WgABANUC3AABAOf+WwABANYC7AABAMn/nAABAL4CygABAMP/nAABAL8CzgABASMCRQABAR7/lwABATECUwABAQP/mAABAQ0DAQABAP//lAABAVUDHQABATADhgABAVcDqAABAHf+zgABALoBpAABAGb+0gABAJIBpAABAG7+0AABANYBoAABAIn+6AABAJcBqAABAID+5AABAM4CcgABAJL+5AABANcCdQABAH/+8gABAJcCcwABAHP+3AABAJQCbgABAMYC9wABANoC+wABAID9fgABAIH9fwABAIH+0wABAM4C7gABAHn+5wABAJYC7gABAIn+4QABANYC7wABAH7+7QABAJMC7wABAzL/nQABA0MBpAABA0n/mgABA0YBmQABAYYBoAABAXf/nAABAYYBoQABAzT/nAABAzsC5wABAzz/nAABAzkC3wABAXn/nAABAXgC5gABAXH/nAABAXkC5wABA27/nQABA8sBzgABA3v/nAABA8cByQABAbP/nAABAgMBzQABAar/nAABAgEB0AABA3P/nAABA9ACowABA3r/nAABA9ECoQABAaH/nAABAhACnQABAab/nAABAhMCmwABAhQByAABAW7/nAABAhIBygABARn/nAABAc8BwAABARv/nAABAc4BxQABAVz/nAABAeQCjAABAWL/nAABAegCjQABAUL/nAABAawCjgABATP/nAABAawCjwABAQr+DQABAQMB6wABARn+CwABASoB8wABASz/nAABASgB8QABANT/oAABAOUCCwABANL+IQABARUCsAABAOn+EQABASUCqQABASn/nAABASQCsgABALH/nAABAO4CsgABAZD/nAABAnQDPgABAr0CxgABAN7/nAABANkCygABAOQDRAABAZz/nAABAmkDpgABAZH/nAABAsUDKwABAOv/nAABAN0DKAABALn/nAABAOQDqwABAan/mAABAm4CcAABAZ3/mAABAsMB+AABAOj/nAABAOAB9AABAOoCaAABATX+uQABAc0BzQABAS7+tgABAc0BygABASX+uwABAc4ClwABASX+ugABAc8CjwABAOP/nAABAOECvgABAM3/nAABAN0DNwABAbICpwABAbgCowABALUC8QABAK4C4wABAaT/mgABAhMCkwABAhkCjAABAhz/nAABAUUB0QABAa3/mgABAhkCjgABAib/nAABAR4BzwABAMn/mQABAJ4C7AABATb/mgABAHwCdwABAKT/mwABAKQC1wABAIr/mwABAI8CzgABARr/nAABAIQCkAABAaf/mAABAgQDCQABAa7/mAABAgADDgABAjv/nAABAT0CZQABAbn/mAABAgsDBwABAhb/nAABATcCXQABAMP/mQABAH8DRgABAV//nAABAGcCvgABAH//mQABAHgDKwABAHf/mQABAIMDMQABASr/nAABAGcCzQABAWr+5QABAS8BhgABAWH+8AABATsBiwABAKH/nAABAKgC+gABAKIDAQABASoB1AABATwBnQABALYEDQABAKUEDwABAYP/qQABAUgBzQABAav/nAABAVYBxgABARz/nAABAR0ByQABARb/nAABARsB0AABAWX+5gABAV8B9QABAT3+8gABAWEB+AABAKv/nAABALMCZAABAJH/nAABAL4CgwABAWf+4QABAVkBYgABAWj+3wABAWABnwABAPr/lgABAOsCHwABAPr/zgABAQACTQABAPX+5gABAQoBvQABAQwCNAABAOUDqAABANgDxQABAPD/nAABANUCHQABAQX/ywABATIBkQABAPP+0QABAQABdQABAIP+FgABAJEB2QABAO0DhQABAPMDfwABASv/nAABAQkCLgABAVH+lgABAToBvAABAWX/lgABAUYCCAABAST/nAABAUkCJAABAPH/nAABAO0C4gABAPT/zgABAOoDGQABAP3/nAABAPgC6gABAQv/rQABAS8CTAABAPL+zQABAPIBzAABAPf+zAABAO4B1AABAPgDJAABAQMDLwABAQAC/wABAP0C+wABAPoDLQABAPkDPAABAXX+5wABAMABjQABAVwBAgABAWz+RAABAMABigABAWX+BQABAU4A/wABAVL99QABAUUAwAABAKr+0wABAK8BoQABAJL+0wABAKABvAABAKT+xgABAKkBvwABALT+xgABAL8BqwABANgDCAABAPYCygABAO0CIAABALL/nAABAL8DIgABAIb/nAABAJoDYgABAKP/nAABAKsDOwABAMACpgABAXP+7QABAMYBmQABAWT+owABAXUA/AABAU3+pAABAToAyQABAKz+ygABALsBoQABAIb+ywABAJ8ByAABAKz+xgABAJ8BuAABAKf+xwABALABtQABATYCBAABATYAvAABAWIDAQABAWMDCQABAGP/nAABAGAA5QAFAAAAAQAIAAEADAAoAAIAMgCYAAIABACDAIQAAAKYApgAAgKkAqUAAwKpArwABQACAAECHAJiAAAAGQABC4QAAQuEAAELlgABC5YAAQuWAAELigAACoQAAQuWAAAKhAABC5YAAQuQAAAKhAABC5YAAQuWAAAKhAABC5YAAQuWAAELlgABC5YAAQuWAAELlgABC5YAAQuWAAELlgABC5YARwCQALIA1AD2ARgBOgFcAX4BoAHCAeQCBgIoAkoCbAKOArAC0gL0AxYDOANaA3wDngPAA+IEBAQmBEgEagSMBKgEygTmBQgFKgVMBW4FkAWsBc4F8AYSBjQGVgZ4BpQGtgbSBvQHFgc4B1oHfAeeB8AH4ggECCYISAhqCIwIrgjQCPIJFAk2CVIJdAmWCbgAAgAKABAAFgAcAAEBlv+0AAEBtAMaAAEAiP9wAAEAewKsAAIACgAQABYAHAABAZr/qwABAb0DGAABAHz/eAABAHwCswACAAoAEAAWABwAAQGU/7gAAQG5Ax0AAQB9/5AAAQCbA+MAAgAKABAAFgAcAAEBtv+nAAEBxQMhAAEAnP+PAAEAmwQFAAIACgAQABYAHAABAbb/ogABAakDCwABAMT+UwABAIkCoQACAAoAEAAWABwAAQHd/5wAAQGzAxsAAQDc/mMAAQCFArgAAgAKABAAFgAcAAEBr/+9AAEBywM2AAEAjP92AAEAhgNfAAIACgAQABYAHAABAar/swABAdADMAABAJb/dwABAKQDYAACAAoAEAAWABwAAQGd/7QAAQHqA2AAAQCa/2IAAQCgA6QAAgAKABAAFgAcAAEC4f8sAAECgQHvAAEBWf6jAAEAvAGdAAIACgAQABYAHAABAvL/QgABAoYB5gABAV3+qwABALsBnQACAAoAEAAWABwAAQL+/s4AAQJ1AbgAAQFY/roAAQC8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AbIBsQABAbUAAwG5AbgBtwAFAb0BvAG7AcABvwAFAcUBwwHBAcABvwABAcAAAQHCAAEBxAACAccBxgABAccABQHPAc0BywHKAckAAQHMAAEBzgACAdEB0AADAdUB1AHTAAMB2QHYAdcAAwHdAdwB2wADAeEB4AHfAAEB4wADAecB5gHlAAEB6QADAe0B7AHrAAEB7wADAfMB8gHxAAEB9QABAfcAAQH5AAEB+wABAgEAAwIGAgUCAwABAgQAAgIIAgcAAwINAgwCCgABAgsAAQIOAAMC0wLUAtIAAwIUAhMCEQABAhIAAgIWAhUAAQIYAAECGgABAh0AAQIfAAECIQABAiMAAQIrAAECOQABAjsAAQI9AAECQQABAkMAAQJFAAECSQABAksAAQJNAAECUgABAlQAAQJWAAECegABAmwAAQJ7AAEAbQAmAMMAyAEcASEBNgE4AToBPAE+AUABRwFKAUwBTwFSAVUBWAFbAV4BYgFmAWoBbgFyAXQBdgF4AXoBfAF9AYABggGEAYYBiAGMAZABlAGYAZwBoAGkAagBrAGwAbQBtgG6AbsBvAG9Ab4BvwHBAcMBxQHGAcgBywHNAc8B0gHWAdoB3gHiAeQB6AHqAe4B8AH0AfYB+AH6AgACAgIDAgYCCQIKAg0CDwIQAhECFAIXAhkCHAIeAiACIgIkAjgCOgI8AkACQgJEAkgCSgJMAlECUwJVAnQCdgJ3AAYAAAACAAoAHAADAAAAAQisAAEALgABAAAADgADAAAAAQiaAAIAFAAcAAEAAAAOAAEAAgLPAtAAAgABAsICzQAAAAQAAAABAAgAAQCWAAgAFgAgACoANAA+AEgAUgBcAAEABAK6AAICswABAAQCtAACArMAAQAEArUAAgKzAAEABAK2AAICswABAAQCtwACArMAAQAEArgAAgKzAAEABAK5AAICswAHABAAFgAcACIAKAAuADQCugACAqkCtAACAq0CtQACAq4CtgACAq8CtwACArACuAACArECuQACArIAAgACAqkCqQAAAq0CswABAAEAAAABAAgAAQe+ANkAAQAAAAEACAABAAYAAQABAAQAwwDIARwBIQABAAAAAQAIAAIADAADAnoCbAJ7AAEAAwJ0AnYCdwABAAAAAQAIAAIApAAkAUMBSgFPAVUBWwFhAWUBaQFtAXEBiwGPAZMBlwGbAZ8BowGnAasBrwGzAbkBvQHFAc8B1QHZAd0B4QHnAe0B8wIGAg0C0wIUAAEAAAABAAgAAgBOACQBQgFJAU4BVAFaAWABZAFoAWwBcAGKAY4BkgGWAZoBngGiAaYBqgGuAbIBuAG8AcMBzQHUAdgB3AHgAeYB7AHyAgUCDALUAhMAAQAkAUABRwFMAVIBWAFeAWIBZgFqAW4BiAGMAZABlAGYAZwBoAGkAagBrAGwAbYBugG+AcgB0gHWAdoB3gHkAeoB8AICAgkCDwIQAAEAAAABAAgAAgCgAE0BNwE5ATsBPQE/AUEBSAFNAVMBWQFfAWMBZwFrAW8BcwF1AXcBegF9AYEBgwGGAYkBjQGRAZUBmQGdAaEBpQGpAa0BsQG1AbcBuwHBAcsB0wHXAdsB3wHjAeUB6QHrAe8B8QH1AfcB+QH7AgECAwIKAtICEQIYAhoCHQIfAiECIwIrAjkCOwI9AkECQwJFAkkCSwJNAlICVAJWAAEATQE2ATgBOgE8AT4BQAFHAUwBUgFYAV4BYgFmAWoBbgFyAXQBdgF4AXwBgAGCAYQBiAGMAZABlAGYAZwBoAGkAagBrAGwAbQBtgG6Ab4ByAHSAdYB2gHeAeIB5AHoAeoB7gHwAfQB9gH4AfoCAAICAgkCDwIQAhcCGQIcAh4CIAIiAiQCOAI6AjwCQAJCAkQCSAJKAkwCUQJTAlUABAAIAAEACAABAGAAAwCaAAwANgAFAAwAEgAYAB4AJAIdAAIBNwIfAAIBOQIhAAIBOwIjAAIBPQIrAAIBPwAFAAwAEgAYAB4AJAIcAAIBNwIeAAIBOQIgAAIBOwIiAAIBPQIkAAIBPwABAAMBNgHUAdUABAAJAAEACAABAh4AEQAoADYAWAB6AJwAvgDgAQIBJAFGAWgBigGkAcYB6AHyAhQAAQAEAmMABAHVAdQB5QAEAAoAEAAWABwCJwACAgECKAACAgMCKQACAgoCKgACAhEABAAKABAAFgAcAiwAAgIBAi0AAgIDAi4AAgIKAi8AAgIRAAQACgAQABYAHAIwAAICAQIxAAICAwIyAAICCgIzAAICEQAEAAoAEAAWABwCNAACAgECNQACAgMCNgACAgoCNwACAhEABAAKABAAFgAcAjkAAgIBAjsAAgIDAj0AAgIKAj8AAgIRAAQACgAQABYAHAI4AAICAQI6AAICAwI8AAICCgI+AAICEQAEAAoAEAAWABwCQQACAgECQwACAgMCRQACAgoCRwACAhEABAAKABAAFgAcAkAAAgIBAkIAAgIDAkQAAgIKAkYAAgIRAAQACgAQABYAHAJJAAICAQJLAAICAwJNAAICCgJPAAICEQAEAAoAEAAWABwCSAACAgECSgACAgMCTAACAgoCTgACAhEAAwAIAA4AFAJSAAICAQJUAAICAwJWAAICCgAEAAoAEAAWABwCUQACAgECUwACAgMCVQACAgoCVwACAhEABAAKABAAFgAcAlgAAgIBAlkAAgIDAloAAgIKAlsAAgIRAAEABAJdAAICEQAEAAoAEAAWABwCXgACAgECXwACAgMCYAACAgoCYQACAhEAAQAEAmIAAgIRAAEAEQE2AUkBTgFUAVoBigGLAY4BjwGSAZMBlgGXAeACBQIMAhMAAQAJAAEACAACACgAEQHAAcIBxAHHAcABwAHCAcQBxwHHAcoBzAHOAdECBAILAhIAAQARAboBuwG8Ab0BvgG/AcEBwwHFAcYByAHLAc0BzwIDAgoCEQABAAkAAQAIAAIAIgAOAcABwgHEAccBwAHAAcIBxAHHAccBygHMAc4B0QABAA4BugG7AbwBvQG+Ab8BwQHDAcUBxgHIAcsBzQHPAAYACQAKABoAPABWAHIAmAC+AQABIgFgAZoAAwABABIAAQHsAAAAAQAAAA8AAgACAXgBfwAAAYQBhwAIAAMAAAABAfAAAQASAAEAAAAQAAEAAgGGAYcAAwAAAAEB1gABABIAAQAAABEAAQADAVQBWgIMAAMAAAABABIAAQAcAAEAAAARAAEAAwFPAgYCFAABAAMBTgIFAhMAAwABABIAAQGUAAAAAQAAABIAAQAIATwBPQE+AT8CIgIjAiQCKwADAAAAAQB2AAEAEgABAAAAEgABABYBNgE4AToBPAE+AUoBSwFPAVEBVQFWAVsBXAHhAfgB+QIGAggCDQIOAhQCFgADAAAAAQA0AAEAEgABAAAAEgABAAYBeAF5AXwBfwGEAYUAAwAAAAEAEgABACIAAQAAABIAAQAGAXgBegF8AX0BhAGGAAEADAFiAWYBagFuAaABpAG2Ad4CAAICAgkCEAADAAEAEgABAC4AAAABAAAAEgACAAQBNgE/AAABhAGHAAoCHAIkAA4CKwIrABcAAQAEAb4BxQHIAc8AAwABABIAAQA0AAAAAQAAABIAAgAFATYBPwAAAXwBfwAKAYQBhwAOAhwCJAASAisCKwAbAAEAAgG6Ab0AAQAAAAEACAABAAYA1QABAAEAJgABAAkAAQAIAAIAFAAHAUsBUQFWAVwCCAIOAhYAAQAHAUoBTwFVAVsCBgINAhQAAQAJAAEACAACAAwAAwFXAV0CDgABAAMBVQFbAg0AAQAJAAEACAABAAYAAQABAAYBTwFVAVsCBgINAhQAAQAJAAEACAACACQADwFXAV0BeQF7AX8BfgGFAYcBvwHGAb8BxgHJAdACDgABAA8BVQFbAXgBegF8AX0BhAGGAboBvQG+AcUByAHPAg0AAAAAAAEAAAAAClExXk1eMEBoN0RvQHh0MnU3VWpyTUo0WDJYRUA=) format("truetype");
    font-weight: 400; font-style: normal; font-display: swap;
}
@font-face {
    font-family: "PeydaReport";
    src: url(data:font/truetype;charset=utf-8;base64,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AowAPgKMAD4CjAA+AowAPgKMAD4D5QARA+UAEQPlABED5QARAkoABwJKAAcCSgAHAkoABwIUACQCFAAkAhQAJAHsAB8B7AAfAewAHwHsAB8B7AAfAewAHwHsAB8B7AAfAewAGQMeAB8BugAgAboAGAG6ACABugAgAlUAJQIdAB8CHQAfAhEAHwIQAB8CEQAfAfEAHwIQAB8B8QAfAhAAHwIQAB8CEAAdAhoAIAIaACACGgAgAjgAGwD9ADkBEAA5ATj/zgE7ABkA9QA0ARL/+gD0/+UA/f/nAggAOQEHAD4BB/+5AQcALQEH/9kCOAA5AjgAOQI4ADkCOAA2AjgAOQIIACACCAAgAggAIAIIACACCAAgAggAIAIIACACCAAgA08AIAIdADgBmgA5AZr//AGaADABvgAgAb4AGgG+ACABvgAgAlUALAGPABoBj//ZAY8AGgGPABoCOAA1AjgANQI4ADUCOAA1AjgANQI4ADUCOAA1AjgANQMKABADCgAQAwoAEAMKABAB8wAMAfMADAHzAAwB1gAoAdYAKAHWACgB0wAxANoANAEIADUA0f/UARX/5gDq/+UBCgAGATb/7QFL/+0BS//QAUr/ywNiADQDgQA0AX7/8gFN//IBff/yAc3/8gJD//IDYgA0A4EANAF+//IBTf/yAc3/8gNiADQDgQA0AX7/8gF9//IBzf/yAkP/8gNiADQDgQA0AX7/8gF9//IBzf/yAgX/8gNiADQDgQA0AX7/8gF9//IBzf/yAfP/8gNiADQDgQA0AX7/8gFN//ICrwA2Ar4ANgKt//ICmf/yAr0ANgK+ADYCrf/yApn/8gKrADYCvgA2Aq3/8gKX//ICrwA2Ar4ANgKt//ICmf/yAjgANgJPADYCOAA2Ak8ANgI4ADYCTwA2AWj/2AEj/9oBiv/YAUX/2gFo/9gBiv/YAUX/2gEj/9oBaP/YAYr/2AFo/9gBiv/YAWj/2AEj/9oBxv/YAUX/2gSoADQE0wA2AwL/8gLh//IEqAA0BNMANgMC//IC4f/yBN8ANAUEADQDRf/yAx3/8gTfADQFBAA0A0X/8gMd//IC4gA2Aw4ANgLi//ICtv/yAuIANgMOADYC4v/yArb/8gI6ADYCdgA2Akb/8QHv//ICOgA2AnYANgJG//EB7//yA2YANgOyADYB9P/yAeP/8gNmADYDsgA2AfT/8gHj//IDZgA2A7IANgH0//IB4//yAssANgLjADYCywA2AuMANgH0//IB4//yA2MANgOBADYCAf/yAZj/8gOCADQDgwA0BGIANgPpADQEpQA2AgH/8gN2//IBmP/yAZj/8gMz//IDggA0A4QANARiADYD6QA0BKUANgIB//IDdv/NAZj/8gGY//IDM//NAskANQMCADUBVv/yAQ//8gLLADUDBAA1AVb/8gEP//ICsgA0AuAANAI1//ICEf/yAskANAL5ADQBfv/yAU3/8gLJADQC+QA0AfoANAIMADYCfv/yAwP/8gH6ADQCDAA2AfoANAI7ACoCXf/yAU3/8gH6ADQCDAA2AwP/8gJUADIDQf/yAwP/8gH6ADQCDAA2AfoANAI7ACoB9gAyAgkAMgH2ADICBgAyAfYAMgIGADIB9gAyAgYAMgLnADQC6AA0AucANALoADQCmgA0AX7/8gF9//IBzf/yAe//8gLoABYC6QA0ApoANAF+//IBTf/yAc3/8gLoABQC5wA0AugANAKaADQBfv/yAX3/8gHN//IB5v/yAmYANAKaADQCywA0AvoANAC0AAACLwAlAmwAJQIvAAgCbAAOAi8AJQJsACUCUv/7Aov/9wIv/+QDlwA0BAUANAObADQDmwA0A6AACwObADQCbP/UA/8ANAP/ADQEBAA5A/8ANAObADQDmwA0A54ANAObADQDnAA0A5wANAOcADQDnAA0BUkANAVsADQFSQA0BWwANAVJADQFbAA0BUkANAVsADQFSQA0BWwANAVJADQFbAA0BUkANAVsADQFSQA0BWwANAWLADQFrgA0BYsANAWuADQFiwA0BbAANAWLADQFrgA0Ba4ANAWLADQFrgA0BYsANAWuADQFiwA0Ba4ANAWLADQDmwA0A5cANAOXADQDlwA0BAUANAQFADQDlwA0A5cANAOXAC0DlwA0BAUANAUPADQBXwAtAQ4AKgEfADkA8wAjAi8AJwLzACcB1QAyAp4AIgItABkCZAANAmQADQIMAB4B6gA0APMAIwIvACcC8wAnAo0AJwKcACICUQAnAmQADQJkAA0CDAAeAlIAKQJkAA0COgAAB30AAAAAAAAAAAAAAAAAAAAAAAACOgAAAjoAAAJfAAACXwAAAn4AAAK3AAACYQAAAqsAAAKZAAACbAAAAwUAAAFKABkBDgAt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AGEAQgBvAGwAZAAzAC4AMAAwADAAOwBLAEgARABNADsAUABlAHkAZABhAC0AQgBvAGwAZABQAGUAeQBkAGEAIABCAG8AbABkAFYAZQByAHMAaQBvAG4AIAAzAC4AMAAwADAAUABlAHkAZABhAC0AQgBvAGwAZABQAGUAeQBkAGEAIABpAHMAIABhACAAdAByAGEAZABlAG0AYQByAGsAIABvAGYAIAB3AHcAdwAuAGYAbwBuAHQAaQByAGEAbgAuAGMAbwBtAE4AYQBzAGUAcgAgAEsAaABhAGQAZQBtAFQAbwAgAHUAcwBlACAAdABoAGkAcwAgAGYAbwBuAHQALAAgAGkAdAAgAGkAcwAgAG4AZQBjAGUAcwBzAGEAcgB5ACAAdABvACAAbwBiAHQAYQBpAG4AIAB0AGgAZQAgAGwAaQBjAGUAbgBzAGUAIABmAHIAbwBtACAAdwB3AHcALgBmAG8AbgB0AGkAcgBhAG4ALgBjAG8AbQB3AHcAdwAuAGYAbwBuAHQAaQByAGEAbgAuAGMAbwBtAGgAdAB0AHAAcwA6AC8ALwBkAHIAaQBiAGIAYgBsAGUALgBjAG8AbQAvAG4AYQBzAGUAcgBrAGgAYQBkAGUAbQBmAG8AbgB0AGkAcgBhAG4ALgBjAG8AbQAvAGwAaQBjAGUAbgBzAGUAcwAAAAIAAAAAAAD/nAAyAAAAAAAAAAAAAAAAAAAAAAAAAAAC1gAAAAEAAgADACQAJQAmACcAKAApACoAKwAsAC0ALgAvADAAMQAyADMANAA1ADYANwA4ADkAOgA7ADwAPQBEAEUARgBHAEgASQBKAEsATABNAE4ATwBQAFEAUgBTAFQAVQBWAFcAWABZAFoAWwBcAF0AEwAUABUAFgAXABgAGQAaABsAHAARAA8AHQAeABAADgANAEEA2QASAB8AIAAhAAQAIgAKAAUABgAjAAcACAAJAAsADABeAF8AYAA+AD8AQAC2ALcAtAC1AMQAxQCHAEIAsgCzAIwAigCLAL0AhACFAJYA7wCTAPAAuADoAKsAwwCjAKIAgwC8AIgAhgCCAMIAYQC+AL8BAgEDAMkBBADHAGIArQEFAQYAYwCuAJAA/QD/AGQBBwDpAQgBCQBlAQoAyADKAQsAywEMAQ0BDgD4AQ8BEAERAMwAzQDOAPoAzwESARMBFAEVARYBFwDiARgBGQEaAGYBGwDQANEAZwDTARwBHQCRAK8AsADtAR4BHwEgASEA5AD7ASIBIwEkASUBJgEnANQA1QBoANYBKAEpASoBKwEsAS0BLgEvAOsBMAC7ATEBMgDmATMAaQE0AGsAbABqATUBNgBuAG0AoAD+AQAAbwE3AOoBOAEBAHABOQByAHMBOgBxATsBPAE9APkBPgE/AUAA1wB0AHYAdwFBAHUBQgFDAUQBRQFGAUcA4wFIAUkBSgB4AUsAeQB7AHwAegFMAU0AoQB9ALEA7gFOAU8BUAFRAOUA/AFSAIkBUwFUAVUBVgB+AIAAgQB/AVcBWAFZAVoBWwFcAV0BXgDsAV8AugFgAOcBYQFiAWMBZAFlAWYBZwFoAWkBagFrAWwBbQFuAW8BcAFxAXIBcwF0AXUBdgF3AXgBeQF6AXsBfAF9AX4BfwGAAYEBggGDAYQBhQGGAYcBiAGJAYoBiwGMAY0BjgGPAZABkQGSAZMBlAGVAZYBlwGYAZkBmgGbAZwBnQGeAZ8BoAGhAaIBowGkAaUBpgGnAagBqQGqAasBrAGtAa4BrwGwAbEBsgGzAbQBtQG2AbcBuAG5AboBuwG8Ab0BvgG/AcABwQHCAcMBxAHFAcYBxwHIAckBygHLAcwBzQHOAc8B0AHRAdIB0wHUAdUB1gHXAdgB2QHaAdsB3AHdAd4B3wHgAeEB4gHjAeQB5QHmAecB6AHpAeoB6wHsAe0B7gHvAfAB8QHyAfMB9AH1AfYB9wH4AfkB+gH7AfwB/QH+Af8CAAIBAgICAwIEAgUCBgIHAggCCQIKAgsCDAINAg4CDwIQAhECEgITAhQCFQIWAhcCGAIZAhoCGwIcAh0CHgIfAiACIQIiAiMCJAIlAiYCJwIoAikCKgIrAiwCLQIuAi8CMAIxAjICMwI0AjUCNgI3AjgCOQI6AjsCPAI9Aj4CPwJAAkECQgJDAkQCRQJGAkcCSAJJAkoCSwJMAk0CTgJPAlACUQJSAlMCVAJVAlYCVwJYAlkCWgJbAlwCXQJeAl8CYAJhAmICYwJkAmUCZgJnAmgCaQJqAmsCbAJtAm4CbwJwAnECcgJzAnQCdQJ2AncCeAJ5AnoCewJ8An0CfgJ/AoACgQKCAoMChAKFAoYChwKIAokCigKLAowCjQKOAo8CkAKRApICkwKUApUClgKXApgCmQKaApsCnAKdAp4CnwKgAqECogKjAqQCpQKmAqcCqAKpAqoCqwKsAq0CrgKvArACsQKyArMCtAK1ArYCtwK4ArkCugK7ArwCvQK+Ar8CwACpAKoCwQLCAsMCxALFAsYCxwLIAskCygLLAswCzQLOAs8C0ALRAtIC0wLUAtUC1gLXAtgC2QLaAtsC3ALdAt4C3wLgAuEC4gLjAuQC5QLmAucC6ALpAuoC6wLsAu0C7gLvAvAC8QLyAvMC9AL1AvYC9wL4AvkC+gL7AOEC/AL9Av4C/wd1bmkwNjVBB3VuaTA2NUIGQWJyZXZlB0FtYWNyb24HQW9nb25lawpDZG90YWNjZW50BkRjYXJvbgZEY3JvYXQGRWNhcm9uCkVkb3RhY2NlbnQHRW1hY3JvbgdFb2dvbmVrB3VuaTAxOEYHdW5pMDEyMgpHZG90YWNjZW50BEhiYXIHSW1hY3JvbgdJb2dvbmVrB3VuaTAxMzYGTGFjdXRlBkxjYXJvbgd1bmkwMTNCBk5hY3V0ZQZOY2Fyb24HdW5pMDE0NQNFbmcNT2h1bmdhcnVtbGF1dAdPbWFjcm9uBlJhY3V0ZQZSY2Fyb24HdW5pMDE1NgZTYWN1dGUHdW5pMDIxOAd1bmkxRTlFBFRiYXIGVGNhcm9uB3VuaTAxNjIHdW5pMDIxQQ1VaHVuZ2FydW1sYXV0B1VtYWNyb24HVW9nb25lawVVcmluZwZXYWN1dGULV2NpcmN1bWZsZXgJV2RpZXJlc2lzBldncmF2ZQtZY2lyY3VtZmxleAZZZ3JhdmUGWmFjdXRlClpkb3RhY2NlbnQGYWJyZXZlB2FtYWNyb24HYW9nb25lawpjZG90YWNjZW50BmRjYXJvbgZlY2Fyb24KZWRvdGFjY2VudAdlbWFjcm9uB2VvZ29uZWsHdW5pMDI1OQd1bmkwMTIzCmdkb3RhY2NlbnQEaGJhcglpLmxvY2xUUksHaW1hY3Jvbgdpb2dvbmVrB3VuaTAxMzcGbGFjdXRlBmxjYXJvbgd1bmkwMTNDBm5hY3V0ZQZuY2Fyb24HdW5pMDE0NgNlbmcNb2h1bmdhcnVtbGF1dAdvbWFjcm9uBnJhY3V0ZQZyY2Fyb24HdW5pMDE1NwZzYWN1dGUHdW5pMDIxOQR0YmFyBnRjYXJvbgd1bmkwMTYzB3VuaTAyMUINdWh1bmdhcnVtbGF1dAd1bWFjcm9uB3VvZ29uZWsFdXJpbmcGd2FjdXRlC3djaXJjdW1mbGV4CXdkaWVyZXNpcwZ3Z3JhdmULeWNpcmN1bWZsZXgGemFjdXRlCnpkb3RhY2NlbnQHdW5pMDYyMQd1bmkwNjI3DHVuaTA2MjcuZmluYQd1bmkwNjIzDHVuaTA2MjMuZmluYQd1bmkwNjI1DHVuaTA2MjUuZmluYQd1bmkwNjIyDHVuaTA2MjIuZmluYQd1bmkwNjcxDHVuaTA2NzEuZmluYQd1bmkwNjZFDHVuaTA2NkUuZmluYQx1bmkwNjZFLm1lZGkMdW5pMDY2RS5pbml0EHVuaTA2NkUuaW5pdC5hbHQRdW5pMDY2RS5pbml0LmFsdDIRdW5pMDY2RS5pbml0LmFsdDMHdW5pMDYyOAx1bmkwNjI4LmZpbmEMdW5pMDYyOC5tZWRpDHVuaTA2MjguaW5pdBB1bmkwNjI4LmluaXQuYWx0B3VuaTA2N0UMdW5pMDY3RS5maW5hDHVuaTA2N0UubWVkaQx1bmkwNjdFLmluaXQQdW5pMDY3RS5pbml0LmFsdBF1bmkwNjdFLmluaXQuYWx0Mgd1bmkwNjJBDHVuaTA2MkEuZmluYQx1bmkwNjJBLm1lZGkMdW5pMDYyQS5pbml0EHVuaTA2MkEuaW5pdC5hbHQRdW5pMDYyQS5pbml0LmFsdDIHdW5pMDYyQgx1bmkwNjJCLmZpbmEMdW5pMDYyQi5tZWRpDHVuaTA2MkIuaW5pdBB1bmkwNjJCLmluaXQuYWx0EXVuaTA2MkIuaW5pdC5hbHQyB3VuaTA2NzkMdW5pMDY3OS5maW5hDHVuaTA2NzkubWVkaQx1bmkwNjc5LmluaXQHdW5pMDYyQwx1bmkwNjJDLmZpbmEMdW5pMDYyQy5tZWRpDHVuaTA2MkMuaW5pdAd1bmkwNjg2DHVuaTA2ODYuZmluYQx1bmkwNjg2Lm1lZGkMdW5pMDY4Ni5pbml0B3VuaTA2MkQMdW5pMDYyRC5maW5hDHVuaTA2MkQubWVkaQx1bmkwNjJELmluaXQHdW5pMDYyRQx1bmkwNjJFLmZpbmEMdW5pMDYyRS5tZWRpDHVuaTA2MkUuaW5pdAd1bmkwNjJGDHVuaTA2MkYuZmluYQd1bmkwNjMwDHVuaTA2MzAuZmluYQd1bmkwNjg4DHVuaTA2ODguZmluYQd1bmkwNjMxC3VuaTA2MzEuYWx0DHVuaTA2MzEuZmluYRB1bmkwNjMxLmZpbmEuYWx0B3VuaTA2MzIMdW5pMDYzMi5maW5hEHVuaTA2MzIuZmluYS5hbHQLdW5pMDYzMi5hbHQHdW5pMDY5MQx1bmkwNjkxLmZpbmEHdW5pMDY5NQx1bmkwNjk1LmZpbmEHdW5pMDY5OAt1bmkwNjk4LmFsdAx1bmkwNjk4LmZpbmEQdW5pMDY5OC5maW5hLmFsdAd1bmkwNjMzDHVuaTA2MzMuZmluYQx1bmkwNjMzLm1lZGkMdW5pMDYzMy5pbml0B3VuaTA2MzQMdW5pMDYzNC5maW5hDHVuaTA2MzQubWVkaQx1bmkwNjM0LmluaXQHdW5pMDYzNQx1bmkwNjM1LmZpbmEMdW5pMDYzNS5tZWRpDHVuaTA2MzUuaW5pdAd1bmkwNjM2DHVuaTA2MzYuZmluYQx1bmkwNjM2Lm1lZGkMdW5pMDYzNi5pbml0B3VuaTA2MzcMdW5pMDYzNy5maW5hDHVuaTA2MzcubWVkaQx1bmkwNjM3LmluaXQHdW5pMDYzOAx1bmkwNjM4LmZpbmEMdW5pMDYzOC5tZWRpDHVuaTA2MzguaW5pdAd1bmkwNjM5DHVuaTA2MzkuZmluYQx1bmkwNjM5Lm1lZGkMdW5pMDYzOS5pbml0B3VuaTA2M0EMdW5pMDYzQS5maW5hDHVuaTA2M0EubWVkaQx1bmkwNjNBLmluaXQHdW5pMDY0MQx1bmkwNjQxLmZpbmEMdW5pMDY0MS5tZWRpDHVuaTA2NDEuaW5pdAd1bmkwNkE0DHVuaTA2QTQuZmluYQx1bmkwNkE0Lm1lZGkMdW5pMDZBNC5pbml0B3VuaTA2QTEMdW5pMDZBMS5maW5hDHVuaTA2QTEubWVkaQx1bmkwNkExLmluaXQHdW5pMDY2Rgx1bmkwNjZGLmZpbmEHdW5pMDY0Mgx1bmkwNjQyLmZpbmEMdW5pMDY0Mi5tZWRpDHVuaTA2NDIuaW5pdAd1bmkwNjQzDHVuaTA2NDMuZmluYQx1bmkwNjQzLm1lZGkMdW5pMDY0My5pbml0B3VuaTA2QTkLdW5pMDZBOS5hbHQMdW5pMDZBOS5zczAxDHVuaTA2QTkuZmluYRF1bmkwNkE5LmZpbmEuc3MwMQx1bmkwNkE5Lm1lZGkRdW5pMDZBOS5tZWRpLnNzMDEMdW5pMDZBOS5pbml0EHVuaTA2QTkuaW5pdC5hbHQRdW5pMDZBOS5pbml0LnNzMDEHdW5pMDZBRgt1bmkwNkFGLmFsdAx1bmkwNkFGLnNzMDEMdW5pMDZBRi5maW5hEXVuaTA2QUYuZmluYS5zczAxDHVuaTA2QUYubWVkaRF1bmkwNkFGLm1lZGkuc3MwMQx1bmkwNkFGLmluaXQQdW5pMDZBRi5pbml0LmFsdBF1bmkwNkFGLmluaXQuc3MwMQd1bmkwNjQ0DHVuaTA2NDQuZmluYQx1bmkwNjQ0Lm1lZGkMdW5pMDY0NC5pbml0B3VuaTA2QjUMdW5pMDZCNS5maW5hDHVuaTA2QjUubWVkaQx1bmkwNkI1LmluaXQHdW5pMDY0NQx1bmkwNjQ1LmZpbmEMdW5pMDY0NS5tZWRpDHVuaTA2NDUuaW5pdAd1bmkwNjQ2DHVuaTA2NDYuZmluYQx1bmkwNjQ2Lm1lZGkMdW5pMDY0Ni5pbml0B3VuaTA2QkEMdW5pMDZCQS5maW5hB3VuaTA2NDcMdW5pMDY0Ny5maW5hDHVuaTA2NDcubWVkaQx1bmkwNjQ3LmluaXQHdW5pMDZDMAx1bmkwNkMwLmZpbmEHdW5pMDZDMQx1bmkwNkMxLmZpbmEMdW5pMDZDMS5tZWRpDHVuaTA2QzEuaW5pdAd1bmkwNkMyDHVuaTA2QzIuZmluYQd1bmkwNkJFDHVuaTA2QkUuZmluYQx1bmkwNkJFLm1lZGkMdW5pMDZCRS5pbml0B3VuaTA2MjkMdW5pMDYyOS5maW5hB3VuaTA2QzMMdW5pMDZDMy5maW5hB3VuaTA2NDgMdW5pMDY0OC5maW5hB3VuaTA2MjQMdW5pMDYyNC5maW5hB3VuaTA2QzYMdW5pMDZDNi5maW5hB3VuaTA2QzcMdW5pMDZDNy5maW5hB3VuaTA2NDkMdW5pMDY0OS5maW5hB3VuaTA2NEEMdW5pMDY0QS5maW5hEXVuaTA2NEEuZmluYS5zczAxDHVuaTA2NEEubWVkaQx1bmkwNjRBLmluaXQQdW5pMDY0QS5pbml0LmFsdBF1bmkwNjRBLmluaXQuYWx0Mgd1bmkwNjI2DHVuaTA2MjYuZmluYRF1bmkwNjI2LmZpbmEuc3MwMQx1bmkwNjI2Lm1lZGkMdW5pMDYyNi5pbml0EHVuaTA2MjYuaW5pdC5hbHQHdW5pMDZDRQd1bmkwNkNDDHVuaTA2Q0MuZmluYRF1bmkwNkNDLmZpbmEuc3MwMQx1bmkwNkNDLm1lZGkMdW5pMDZDQy5pbml0EHVuaTA2Q0MuaW5pdC5hbHQRdW5pMDZDQy5pbml0LmFsdDIHdW5pMDZEMgx1bmkwNkQyLmZpbmEHdW5pMDc2OQx1bmkwNzY5LmZpbmEHdW5pMDY0MAt1bmkwNjQ0MDYyNxB1bmkwNjQ0MDYyNy5maW5hC3VuaTA2NDQwNjIzEHVuaTA2NDQwNjIzLmZpbmELdW5pMDY0NDA2MjUQdW5pMDY0NDA2MjUuZmluYQt1bmkwNjQ0MDYyMhB1bmkwNjQ0MDYyMi5maW5hC3VuaTA2NDQwNjcxEHVuaTA2NkUwNkNDLmZpbmEVdW5pMDY2RTA2Q0MuX2ZpbmEuYWx0EHVuaTA2MjgwNjQ5LmZpbmEQdW5pMDYyODA2NEEuZmluYRB1bmkwNjI4MDYyNi5maW5hEHVuaTA2MjgwNkNDLmZpbmEQdW5pMDY0NDA2NzEuZmluYRB1bmkwNjdFMDY0OS5maW5hEHVuaTA2N0UwNjRBLmZpbmEQdW5pMDY3RTA2MjYuZmluYRB1bmkwNjdFMDZDQy5maW5hEHVuaTA2MkEwNjQ5LmZpbmEQdW5pMDYyQTA2NEEuZmluYRB1bmkwNjJBMDYyNi5maW5hEHVuaTA2MkEwNkNDLmZpbmEQdW5pMDYyQjA2NDkuZmluYRB1bmkwNjJCMDY0QS5maW5hEHVuaTA2MkIwNjI2LmZpbmEQdW5pMDYyQjA2Q0MuZmluYQt1bmkwNjMzMDY0ORB1bmkwNjMzMDY0OS5maW5hC3VuaTA2MzMwNjRBEHVuaTA2MzMwNjRBLmZpbmELdW5pMDYzMzA2MjYQdW5pMDYzMzA2MjYuZmluYQt1bmkwNjMzMDZDQxB1bmkwNjMzMDZDQy5maW5hC3VuaTA2MzQwNjQ5EHVuaTA2MzQwNjQ5LmZpbmELdW5pMDYzNDA2NEEQdW5pMDYzNDA2NEEuZmluYQt1bmkwNjM0MDYyNhB1bmkwNjM0MDYyNi5maW5hC3VuaTA2MzQwNkNDEHVuaTA2MzQwNkNDLmZpbmELdW5pMDYzNTA2NDkQdW5pMDYzNTA2NDkuZmluYQt1bmkwNjM1MDY0QRB1bmkwNjM1MDY0QS5maW5hC3VuaTA2MzUwNjI2EHVuaTA2MzUwNjI2LmZpbmELdW5pMDYzNTA2Q0MQdW5pMDYzNTA2Q0MuZmluYRp1bmkwNjM2X2ZhcnNpX3VuaTA2Q0MuZmluYQt1bmkwNjM2MDY0ORB1bmkwNjM2MDY0OS5maW5hC3VuaTA2MzYwNjRBEHVuaTA2MzYwNjRBLmZpbmELdW5pMDYzNjA2MjYQdW5pMDYzNjA2MjYuZmluYQt1bmkwNjM2MDZDQxB1bmkwNjQ2MDY0OS5maW5hEHVuaTA2NDYwNjRBLmZpbmEQdW5pMDY0NjA2MjYuZmluYRB1bmkwNjQ2MDZDQy5maW5hEHVuaTA2NEEwNjRBLmZpbmEQdW5pMDY0QTA2Q0MuZmluYRB1bmkwNjI2MDY0OS5maW5hEHVuaTA2MjYwNjRBLmZpbmEQdW5pMDYyNjA2MjYuZmluYRB1bmkwNjI2MDZDQy5maW5hEHVuaTA2Q0MwNkNDLmZpbmEHdW5pRkRGMgd1bmkwNjZCB3VuaTA2NkMHdW5pMDY2MAd1bmkwNjYxB3VuaTA2NjIHdW5pMDY2Mwd1bmkwNjY0B3VuaTA2NjUHdW5pMDY2Ngd1bmkwNjY3B3VuaTA2NjgHdW5pMDY2OQd1bmkwNkYwB3VuaTA2RjEHdW5pMDZGMgd1bmkwNkYzB3VuaTA2RjQHdW5pMDZGNQd1bmkwNkY2B3VuaTA2RjcHdW5pMDZGOAd1bmkwNkY5DHVuaTA2RjQudXJkdQx1bmkwNkY3LnVyZHUHdW5pMzAwMAd1bmkyMDVGB3VuaTIwMEUHdW5pMjAwRgd1bmkyMDBEB3VuaTIwMEMHdW5pMjAwMQd1bmkyMDAzB3VuaTIwMDAHdW5pMjAwMgd1bmkyMDA1B3VuaTIwMEEHdW5pMjAyRgd1bmkyMDA2B3VuaTIwMDkHdW5pMjAwNAd1bmkyMDBCB3VuaTA2RDQHdW5pMDYwQwd1bmkwNjFCB3VuaTA2MUYHdW5pMDY2RAd1bmlGRDNFB3VuaUZEM0YHdW5pRkRGQwd1bmkwNjZBB3VuaTA2MTUKZG90YWJvdmVhcgpkb3RiZWxvd2FyC2RvdGNlbnRlcmFyFnR3b2RvdHN2ZXJ0aWNhbGFib3ZlYXIWdHdvZG90c3ZlcnRpY2FsYmVsb3dhchh0d29kb3RzaG9yaXpvbnRhbGFib3ZlYXIYdHdvZG90c2hvcml6b250YWxiZWxvd2FyFHRocmVlZG90c2Rvd25hYm92ZWFyFHRocmVlZG90c2Rvd25iZWxvd2FyEnRocmVlZG90c3VwYWJvdmVhchJ0aHJlZWRvdHN1cGJlbG93YXIHd2FzbGFhcgttaW5pS2VoZWhhchFnYWZzYXJrYXNoYWJvdmVhchVnYWZzYXJrYXNoYWJvdmVhci5hbHQSZ2Fmc2Fya2FzaGNlbnRlcmFyB3VuaTA2NzAHdW5pMDY1Ngd1bmkwNjU0B3VuaTA2NTUHdW5pMDY0Qgd1bmkwNjRDB3VuaTA2NEQHdW5pMDY0RQd1bmkwNjRGB3VuaTA2NTAHdW5pMDY1MQt1bmkwNjUxMDY0Qgt1bmkwNjUxMDY0Qwt1bmkwNjUxMDY0RAt1bmkwNjUxMDY0RQt1bmkwNjUxMDY0Rgt1bmkwNjUxMDY1MAt1bmkwNjUxMDY3MAd1bmkwNjUyB3VuaTA2NTMIc2FyZXlhYXIRc2V2ZW5zYW1sbC5ib3R0b20Qc2V2ZW5zbWFsbC5hYm92ZQ55ZWhzYW1sLmJvdHRvbQ15ZWhzbWFsLmFib3ZlB3VuaTAzMDgHdW5pMDMwNwlncmF2ZWNvbWIJYWN1dGVjb21iB3VuaTAzMEIHdW5pMDMwMgd1bmkwMzBDB3VuaTAzMDYHdW5pMDMwQQl0aWxkZWNvbWIHdW5pMDMwNAd1bmkwMzEyB3VuaTAzMjYHdW5pMDMyNwd1bmkwMzI4DHVuaTA2Y2UuZmluYQx1bmkwNmNlLmluaXQMdW5pMDZjZS5tZWRpDHVuaTA2ZDUuZmluYQAAAQACAA4AAAAAAAAANgACAAYAgwCEAAMBNQIbAAECHAJjAAICmAK8AAMCwgLQAAMC0gLVAAEAAQACAAAADAAAABgAAQAEAqoCrAKvArIAAQAVAIMAhAKYAqQCpQKpAqsCrQKuArACsQKzArQCtQK2ArcCuAK5AroCuwK8AAEAAAAKAH4AugADREZMVAAUYXJhYgAYbGF0bgAuAFQAAAAKAAFVUkQgAFAAAP//AAMAAAADAAQALgAHQVpFIAA6Q1JUIAA6S0FaIAA6TU9MIAA6Uk9NIAA6VEFUIAA6VFJLIAA6AAD//wADAAEAAgAEAAD//wADAAAAAgAEAAVrZXJuACBrZXJuACBtYXJrACptYXJrACpta21rADQAAAADAAAAAQACAAAAAwADAAQABQAAAAIABgAHAAgAEgXyFvgZmhpOJ5Qx8DJsAAIACAACAAoEKgABAEQABAAAAB0C5ALkAIIAggLyAIgAtgEYARgBJgGAAYoB/AIKAnwC1gLWAuQC5ALyAvIDCAMOAxwD6gPwBAYEEAQWAAEAHQBCAEMARABFAEYASABLAFEAUgBYAFkAWgBcAF0AXgBhAGMAZABlAGgAaQB3AHgAeQCBAIICcAJ2AncAAQAZ//gACwAE/+gADf/7ABcADQAdAAUAIP/xACH/7wAi//EAJP/yACz/8QAu/+8AMP/1ABgABP/eAAb/8AAK/+0ADf/0ABL/7QAU/+0AHv/gACD/2wAh/9sAIv/bACT/3QAq/+kAK//pACz/2wAt/+kALv/bAC//6QAw/+AAMv/rADP/7wA0//AANv/uADf/6gBLAAAAAwBL/78AVP/3AFf/7wAWAAb/8QAK//AAEv/wABT/8AAe//AAIP/rACH/7AAi/+sAI//zACcAHAAq//EAK//xACz/6wAt//EALv/sAC//8QAw//MAMv/wADP/8wA0/+4ANv/zAFr/8gACAFwABABfAAQAHAAEAAoABv/6AAr/9wAS//cAFP/3ABYABQAe//wAIP/0ACH/9gAi//QAIwAFACcAGwAqAAsAKwALACz/9AAtAAsALv/2AC8ACwAwAAsAMQAJADL/+QAz//sANP/3ADUACQA2//oANwAIAFgABABa//gAAwBZ//IAXP/4AF//7wAcAAQACwAG//UACv/wABL/8AAU//AAFgAFAB7/9gAg/+oAIf/rACL/6gAj//gAJwALACoADQArAA0ALP/qAC0ADQAu/+sALwANADAADQAx//wAMv/zADP/8gA0//EANQAJADb/8QA3AAoAWAAEAFr/7wAWAAb/6AAK/+YAEv/mABT/5gAW//MAF//JABj/5AAZ/9IAGv/cABz/uAAg//MAIv/zACP/8AAs//MAMf/uADP/7AA0//AANv/rAFH/tQBS/7UAYf+8AGP/vAADAEv/tgBU/+gAV//tAAMAGf/eACP/9AAz/+8ABQAZ/+wAG//kACP/9gAz//kANf/tAAEAKf+7AAMAF//rABkABAAc/+cAMwAE//sABf/5AAb/9gAH//kACP/5AAn/+QAK//QAC//5AAz/+QANAAYADv/5AA//+QAQ//kAEf/5ABL/9AAT//kAFP/0ABX/+QAW//0AF//PABj/8wAZ/+QAGv/rABv/+AAc/80AHf/6AB7/8wAf//QAIP/vACH/7wAi/+8AI//wACX/9AAm//QAJ//0ACj/9AAp//QAKv/0ACv/9AAs/+8ALf/0AC7/7wAv//QAMP/yADH/8AAy//EAM//sADT/7wA1//QANv/pADf/8wABABn/+QAFABn/6wAb/+4AI//zADMABAA1/+0AAgJ3AAACeAAAAAECcP+PAAICcAAAAnj/tQACAMgABAAAAOIBBAAEABcAAP/U/94AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD/y/+8AAUABf/4/+cAEf+O//X/9f/sAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA/8v/wwAAAAAAAP/zAAD/y//6AAT/+AAF//X/8v/xAAT/2wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP/KAAAAAAAAAAD/6P/5AAAAAAAAAAD/9/+P//b/+gACAAEACwBCAEMARABFAEYAUQBSAGcAaABpAHEAAgAFAEIAQwABAEYARgACAFEAUgADAGcAaQACAHEAcQACAAIAHQAEAAQADAAGAAYAAwAKAAoABAANAA0ADQASABIABAAUABQABAAWABYADgAXABcAAQAYABgABQAaABoABgAcABwAAgAdAB0ADwAeAB4AEAAgACAAEgAhACEAFAAiACIAEgAkACQAFQAsACwAEgAuAC4AFAAwADAAFgAxADEACQA0ADQACgA2ADYACwA3ADcAEQBCAEMAEwBGAEYABwBRAFIACABnAGkABwBxAHEABwACAAgAAgAKCAAAAQB0AAQAAAA1AJwAxgEIARYBPAFGAdwCMAIwAe4B9AICAjACMAKkAjYCpALGAtwC8gMQAxoDxAPOBDgEWgRoBaoEigSgBMoFLAVWBToFUAVWBVYFfAWqBjIF2AX2BiAGMgZUBs4G8Ac6B1gHcgeEB8oH2AACAAYABAAgAAAAIgAlAB0AKAA3ACEAVABUADEAVwBXADIAagBrADMACgAZ/7IAI//3ADP/9ABI/+kAUP/3AFwACgBe/9gAXwALAGr/5wBr//IAEAAE//kADQAJABcACQAZ//gAGgABABv/9gAc/+sAJP/6ADMAAgA0AAIANQACADYAAgBQAAQAXAAKAF7/6wBf//gAAwAj//wAMwAAAGsABgAJABn/9wAb/+8ANQABAEv/7QBQAAQAWf/yAFz/+wBe/+kAX//yAAIAIwABADMABQAlAAT/8QAGAAUACgAFAA3//gASAAUAFAAFABYABQAbAAIAHv/4ACD/8AAh/+8AIv/wACP//AAk/+sAKv/xACv/8QAs//AALf/xAC7/7wAv//EAMP/xADEABAAy//UAMwAFADT//gA1AAIANv//ADf/+wBC/9kAQ//ZAEb/9QBL/9YAZP/ZAGX/2QBo//UAaf/1AHb/2QAEABn/+QAj//oAM//8AF7/8wABACP/+AADACP/8QAz//MAawAFAAsAGf/LACP/9gAz/+YASP+8AFAABgBcAAUAXv+3AF8ABwBq/7sAa//NAHcAGwABACP/9gAbAAT/8wAN//8AGf/4ABv/7wAc/+wAHQAEAB7/+wAgAAIAIQACACIAAgAkAAIALAACAC4AAgBC/80AQ//NAEYABABL/9kAWf/zAFz/+wBe//AAX//4AGT/zQBl/80AaAAEAGkABAB2/80AgQAEAAgAGf/3ABv/8ABL/+4AUAAEAFn/7wBc//oAXv/oAF//8AAFABn/+AAb//YAXAAIAF7/7QBfAAgABQAZ//kAG//7ACP/9gAz//wANf/5AAcAI//wADP/2AA1/9oAS//QAFT/9gBX//sAawAEAAIAI//4AEv/6wAqAAT/5gAG//gACv/3AA3//gAS//cAFP/3ABb/+AAe/+sAIP/kACH/5gAi/+QAI//3ACT/5gAq/+0AK//tACz/5AAt/+0ALv/mAC//7QAw/+sAMv/yADP/+wA0//gANf/6ADb/+wA3//IAQv/eAEP/3gBE//gARf/4AEb/7ABL/9kAVP/1AFf/9ABk/94AZf/eAGj/7ABp/+wAawAEAHb/3gCB/+oAgv/5AAIAS//iAFcAAwAaAAb/8QAK//AAEv/wABT/8AAe//gAIP/kACH/6wAi/+QAI//1ACT/6gAq//gAK//4ACz/5AAt//gALv/rAC//+AAx//UAMv/sADP/7AA0/+kANv/rAEb/4wBo/+MAaf/jAGsABACB//AACAAj/+cAM//j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AKP/nAABALUCywABAKv/mwABAPQCyAABALL/nAABALoC1AABAbL/nAABAbUDFgABAcv/nAABAbMDFgABALf/nAABALoDUQABALIDbgABAKz/nAABAQMDaQABAKL/nAABALwDXwABAYsDJAABAZ8DIwABALsDWQABAIkDZAABARD+XAABAOcCNwABAOL+WwABAOUCNAABAUz+mgABAL4CIQABAU3+qAABAMYCIQABAPD+WQABAN0CNQABAOz+VQABAN4CGgABAT/+BwABANECHAABAT3+AgABAMkCGwABAPX+SgABANkCNAABAPD+QgABANgCNAABAQf/nAABALwCIQABAPL/nAABALcCIQABALz+WwABANwDJAABANr+WgABAN0DQgABALv/nAABAMcDGQABALb/nAABAMUDIAABAQz/jQABATAChAABAR3/kQABAU0ClwABAQ//lAABAQoDRwABAP3/jQABAU8DYwABATkD6AABAWoECgABAIr+ywABAN8B2AABAHn+0wABALEB2wABAHP+wwABAPYB1AABAKv+7gABALIB5AABAKP+4QABAOkCtQABAKj+3gABAPUCuQABAKL+/QABALMCswABAJf+0gABALgCqAABAOQDQwABAPgDTQABAJz9aAABAJ/9ZwABAJ3+yQABAOcDSAABAJX+4gABAK4DSAABAKj+4gABAPcDSQABAJz+7QABAKgDSAABA0L/nAABA0sB2gABA1//mwABA1MBzQABAWr/nAABAYcB3AABAX7/nAABAYcB3gABA0n/nAABAzgDRQABA03/nAABAzUDOAABAYT/nAABAWgDRAABAXb/nAABAWgDRgABA4n/nAABA+ECAgABA4//nAABA9oB+QABAcP/nAABAhsCAAABAhcCBwABA4P/nAABA9kC5wABA5T/nAABA90C4gABAar/nAABAh4C3QABAbz/nAABAiMC1QABAV3/nAABAisB9gABAWH/nAABAiwB+QABAR3/nAABAf0B5wABAR7/nAABAfsB8AABAUD/nAABAeACzgABAVb/nAABAecCzgABAUj/nAABAb0C0QABATT/nAABAcIC1QABARr99wABARwCHAABAPz+BQABATACKgABASn/nAABASkCKQABAPD/nQABAOwCPwABAMf+GwABASgC9gABANX+FwABATEC6QABASL/nAABASIC/QABAPIC+AABAnkDlAABArYDAAABAOwDCQABAPoDoQABAaL/nAABAmgEJQABAZD/nAABAscDhwABAPv/nAABAPYDgwABALn/nAABAPQEJAABAa//mAABAnICvQABAZz/mAABAssCLAABAPT/nAABAPwCJAABAP0CsAABAV3+tgABAdICBwABAVD+sgABAdECAQABAT7+uwABAdIC0AABAT7+uQABAdYCwAABAPX/nAABAPkC8gABAM3/nAABAOQDhAABAcIC1gABAcoC0gABAK8DCwABAKsDDgABAaX/mQABAgECvQABAg8CrgABAiD/nAABASYCFAABAbj/mQABAg4CsgABAiL/nAABARICBAABANn/mQABAKADEgABAVL/mwABAH8CpgABAMr/mgABAKMDAwABAJf/mgABAJQDAgABATD/nAABAJMCxAABAav/mAABAeYDPAABAbr/mAABAd8DRQABAi7/nAABAPQCnwABAc//mAABAeQDPQABAfX/nAABAN8CnAABAM3/mQABAH4DgAABAX//nAABAFQDAgABAHv/mQABAGEDYAABAH//mQABAIQDbwABAS//nAABAF4DHwABAW3+3gABASUBlwABAWP+5AABASUBnwABAKf/nAABAKoDFgABAIb/nAABAJsDIwABAQ4CMQABASEBxQABALUEPQABAJ4ETgABAYr/tgABAVICAAABAb//nAABAXIB8gABARn/nAABARsB+AABARb/nAABARoCBQABAWv+2gABAWMCRwABAVD+5wABAWgCSgABAL7/nAABAMkCngABAJD/nAABAMsCxwABAWz+1AABAWcBvQABAWv+0AABAWcB0gABAQD/mgABAPkCTAABAO3/zgABAPACcwABAQX+8wABAQcB6wABATACdQABAOkD8QABANcEBgABAPH/nAABANwCUQABARD/yQABATUBvAABAQz+ygABAQ8BlwABAIr97wABAJoB/gABAOYD3AABAP8D1AABAVH/nAABAR8CdAABAUT+lQABATACAgABAY//mgABAVgCVwABAUn/nAABAVwCbQABAPD/nAABAOkDKAABAP7/zgABAPMDcgABAQT/nAABAQIDMQABART/vQABAS0ChwABAPX+xQABAPkB/QABAP7+wwABAPgCDgABAPUDcwABAQ8DiAABAP8DTwABAP4DQwABAPMDfwABAPADnAABAWj+vAABAMUBnwABAWX+lwABAXcBLAABAXj+DAABANABlwABAXL96AABAV8BJwABAUT9yQABAUEA+AABALf+twABALIB3gABAKj+uAABALYB8wABANn+owABAMEB8QABAMf+oQABALoBzwABAM8DKwABAPcDHQABAOMCdgABAL//nAABAM8DegABAJP/nAABAKcDzQABAK//nAABALcDhAABALACxAABAXT+ygABAMoBrwABAWj+mAABAYwBJwABAU7+iwABASoBCQABAL3+qAABAMkB3QABAKP+rAABALQCCAABAN7+oQABAL0B6AABALf+pQABAMwB4wABATYCLAABATYA7wABAWcDegABAWgDiwABAFn/nAABAFMBQAAFAAAAAQAIAAEADAAoAAIAMgCYAAIABACDAIQAAAKYApgAAgKkAqUAAwKpArwABQACAAECHAJiAAAAGQABC2wAAQtsAAELeAABC3gAAQt4AAELeAAACmYAAQt4AAAKZgABC3gAAQtyAAAKZgABC3gAAQt4AAAKZgABC3gAAQt4AAELeAABC3gAAQt4AAELeAABC3gAAQt4AAELeAABC3gARwCQALIA1AD2ARgBOgFcAX4BoAHCAeQCBgIoAkoCbAKOArAC0gLuAxADMgNUA3YDmAO6A9wD/gQgBEIEZASGBKIExATgBQIFJAVGBWIFhAWmBcgF6gYMBi4GSgZsBogGpAbABtwG+AcaBzYHWAd6B5wHvgfgCAIIJAhGCGgIigisCM4I8AkSCTQJVgl4CZoAAgAKABAAFgAcAAEBmf+1AAEBwwNIAAEAd/90AAEAagLXAAIACgAQABYAHAABAar/sAABAdcDIgABAHL/fAABAG4C0QACAAoAEAAWABwAAQGZ/7kAAQHVAy4AAQBn/4MAAQCKBBsAAgAKABAAFgAcAAEB0f+yAAEB3QNDAAEAlv+CAAEAkgQ6AAIACgAQABYAHAABAdH/pwABAc0DKAABAMP+NQABAH0CwwACAAoAEAAWABwAAQH//5wAAQHUAzcAAQDi/icAAQB7As8AAgAKABAAFgAcAAEByP/KAAEB+gM/AAEAkv9yAAEApwOdAAIACgAQABYAHAABAcz/sQABAfADQAABAJr/bQABALEDoAACAAoAEAAWABwAAQGt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AAMBiwGKAYkAAwGPAY4BjQADAZMBkgGRAAMBlwGWAZUAAwGbAZoBmQADAZ8BngGdAAMBowGiAaEAAwGnAaYBpQADAasBqgGpAAMBrwGuAa0AAwGzAbIBsQABAbUAAwG5AbgBtwAFAb0BvAG7AcABvwAFAcUBwwHBAcABvwABAcAAAQHCAAEBxAACAccBxgABAccABQHPAc0BywHKAckAAQHMAAEBzgACAdEB0AADAdUB1AHTAAMB2QHYAdcAAwHdAdwB2wADAeEB4AHfAAEB4wADAecB5gHlAAEB6QADAe0B7AHrAAEB7wADAfMB8gHxAAEB9QABAfcAAQH5AAEB+wABAgEAAwIGAgUCAwABAgQAAgIIAgcAAwINAgwCCgABAgsAAQIOAAMC0wLUAtIAAwIUAhMCEQABAhIAAgIWAhUAAQIYAAECGgABAh0AAQIfAAECIQABAiMAAQIrAAECOQABAjsAAQI9AAECQQABAkMAAQJFAAECSQABAksAAQJNAAECUgABAlQAAQJWAAECegABAmwAAQJ7AAEAbQAmAMMAyAEcASEBNgE4AToBPAE+AUABRwFKAUwBTwFSAVUBWAFbAV4BYgFmAWoBbgFyAXQBdgF4AXoBfAF9AYABggGEAYYBiAGMAZABlAGYAZwBoAGkAagBrAGwAbQBtgG6AbsBvAG9Ab4BvwHBAcMBxQHGAcgBywHNAc8B0gHWAdoB3gHiAeQB6AHqAe4B8AH0AfYB+AH6AgACAgIDAgYCCQIKAg0CDwIQAhECFAIXAhkCHAIeAiACIgIkAjgCOgI8AkACQgJEAkgCSgJMAlECUwJVAnQCdgJ3AAYAAAACAAoAHAADAAAAAQisAAEALgABAAAADgADAAAAAQiaAAIAFAAcAAEAAAAOAAEAAgLPAtAAAgABAsICzQAAAAQAAAABAAgAAQCWAAgAFgAgACoANAA+AEgAUgBcAAEABAK6AAICswABAAQCtAACArMAAQAEArUAAgKzAAEABAK2AAICswABAAQCtwACArMAAQAEArgAAgKzAAEABAK5AAICswAHABAAFgAcACIAKAAuADQCugACAqkCtAACAq0CtQACAq4CtgACAq8CtwACArACuAACArECuQACArIAAgACAqkCqQAAAq0CswABAAEAAAABAAgAAQe+ANkAAQAAAAEACAABAAYAAQABAAQAwwDIARwBIQABAAAAAQAIAAIADAADAnoCbAJ7AAEAAwJ0AnYCdwABAAAAAQAIAAIApAAkAUMBSgFPAVUBWwFhAWUBaQFtAXEBiwGPAZMBlwGbAZ8BowGnAasBrwGzAbkBvQHFAc8B1QHZAd0B4QHnAe0B8wIGAg0C0wIUAAEAAAABAAgAAgBOACQBQgFJAU4BVAFaAWABZAFoAWwBcAGKAY4BkgGWAZoBngGiAaYBqgGuAbIBuAG8AcMBzQHUAdgB3AHgAeYB7AHyAgUCDALUAhMAAQAkAUABRwFMAVIBWAFeAWIBZgFqAW4BiAGMAZABlAGYAZwBoAGkAagBrAGwAbYBugG+AcgB0gHWAdoB3gHkAeoB8AICAgkCDwIQAAEAAAABAAgAAgCgAE0BNwE5ATsBPQE/AUEBSAFNAVMBWQFfAWMBZwFrAW8BcwF1AXcBegF9AYEBgwGGAYkBjQGRAZUBmQGdAaEBpQGpAa0BsQG1AbcBuwHBAcsB0wHXAdsB3wHjAeUB6QHrAe8B8QH1AfcB+QH7AgECAwIKAtICEQIYAhoCHQIfAiECIwIrAjkCOwI9AkECQwJFAkkCSwJNAlICVAJWAAEATQE2ATgBOgE8AT4BQAFHAUwBUgFYAV4BYgFmAWoBbgFyAXQBdgF4AXwBgAGCAYQBiAGMAZABlAGYAZwBoAGkAagBrAGwAbQBtgG6Ab4ByAHSAdYB2gHeAeIB5AHoAeoB7gHwAfQB9gH4AfoCAAICAgkCDwIQAhcCGQIcAh4CIAIiAiQCOAI6AjwCQAJCAkQCSAJKAkwCUQJTAlUABAAIAAEACAABAGAAAwCaAAwANgAFAAwAEgAYAB4AJAIdAAIBNwIfAAIBOQIhAAIBOwIjAAIBPQIrAAIBPwAFAAwAEgAYAB4AJAIcAAIBNwIeAAIBOQIgAAIBOwIiAAIBPQIkAAIBPwABAAMBNgHUAdUABAAJAAEACAABAh4AEQAoADYAWAB6AJwAvgDgAQIBJAFGAWgBigGkAcYB6AHyAhQAAQAEAmMABAHVAdQB5QAEAAoAEAAWABwCJwACAgECKAACAgMCKQACAgoCKgACAhEABAAKABAAFgAcAiwAAgIBAi0AAgIDAi4AAgIKAi8AAgIRAAQACgAQABYAHAIwAAICAQIxAAICAwIyAAICCgIzAAICEQAEAAoAEAAWABwCNAACAgECNQACAgMCNgACAgoCNwACAhEABAAKABAAFgAcAjkAAgIBAjsAAgIDAj0AAgIKAj8AAgIRAAQACgAQABYAHAI4AAICAQI6AAICAwI8AAICCgI+AAICEQAEAAoAEAAWABwCQQACAgECQwACAgMCRQACAgoCRwACAhEABAAKABAAFgAcAkAAAgIBAkIAAgIDAkQAAgIKAkYAAgIRAAQACgAQABYAHAJJAAICAQJLAAICAwJNAAICCgJPAAICEQAEAAoAEAAWABwCSAACAgECSgACAgMCTAACAgoCTgACAhEAAwAIAA4AFAJSAAICAQJUAAICAwJWAAICCgAEAAoAEAAWABwCUQACAgECUwACAgMCVQACAgoCVwACAhEABAAKABAAFgAcAlgAAgIBAlkAAgIDAloAAgIKAlsAAgIRAAEABAJdAAICEQAEAAoAEAAWABwCXgACAgECXwACAgMCYAACAgoCYQACAhEAAQAEAmIAAgIRAAEAEQE2AUkBTgFUAVoBigGLAY4BjwGSAZMBlgGXAeACBQIMAhMAAQAJAAEACAACACgAEQHAAcIBxAHHAcABwAHCAcQBxwHHAcoBzAHOAdECBAILAhIAAQARAboBuwG8Ab0BvgG/AcEBwwHFAcYByAHLAc0BzwIDAgoCEQABAAkAAQAIAAIAIgAOAcABwgHEAccBwAHAAcIBxAHHAccBygHMAc4B0QABAA4BugG7AbwBvQG+Ab8BwQHDAcUBxgHIAcsBzQHPAAYACQAKABoAPABWAHIAmAC+AQABIgFgAZoAAwABABIAAQHsAAAAAQAAAA8AAgACAXgBfwAAAYQBhwAIAAMAAAABAfAAAQASAAEAAAAQAAEAAgGGAYcAAwAAAAEB1gABABIAAQAAABEAAQADAVQBWgIMAAMAAAABABIAAQAcAAEAAAARAAEAAwFPAgYCFAABAAMBTgIFAhMAAwABABIAAQGUAAAAAQAAABIAAQAIATwBPQE+AT8CIgIjAiQCKwADAAAAAQB2AAEAEgABAAAAEgABABYBNgE4AToBPAE+AUoBSwFPAVEBVQFWAVsBXAHhAfgB+QIGAggCDQIOAhQCFgADAAAAAQA0AAEAEgABAAAAEgABAAYBeAF5AXwBfwGEAYUAAwAAAAEAEgABACIAAQAAABIAAQAGAXgBegF8AX0BhAGGAAEADAFiAWYBagFuAaABpAG2Ad4CAAICAgkCEAADAAEAEgABAC4AAAABAAAAEgACAAQBNgE/AAABhAGHAAoCHAIkAA4CKwIrABcAAQAEAb4BxQHIAc8AAwABABIAAQA0AAAAAQAAABIAAgAFATYBPwAAAXwBfwAKAYQBhwAOAhwCJAASAisCKwAbAAEAAgG6Ab0AAQAAAAEACAABAAYA1QABAAEAJgABAAkAAQAIAAIAFAAHAUsBUQFWAVwCCAIOAhYAAQAHAUoBTwFVAVsCBgINAhQAAQAJAAEACAACAAwAAwFXAV0CDgABAAMBVQFbAg0AAQAJAAEACAABAAYAAQABAAYBTwFVAVsCBgINAhQAAQAJAAEACAACACQADwFXAV0BeQF7AX8BfgGFAYcBvwHGAb8BxgHJAdACDgABAA8BVQFbAXgBegF8AX0BhAGGAboBvQG+AcUByAHPAg0AAAAAAAEAAAAA) format("truetype");
    font-weight: 700; font-style: normal; font-display: swap;
}
:root{--bg:#f4f7fb;--card:#fff;--text:#000;--muted:#666;--line:#e5eaf2;--accent:#16509D;--accent-dark:#0e3c73}
*{box-sizing:border-box}
*{font-family:"PeydaReport","Peyda","IRANSans","Tahoma","Arial",sans-serif !important}
body{margin:0;background:var(--bg);color:var(--text);font-size:14px;line-height:1.9}
button{font:inherit;cursor:pointer;border:0;background:none;color:inherit}
button:disabled{opacity:.55;cursor:default}
button:focus-visible,input:focus-visible,select:focus-visible,textarea:focus-visible{outline:3px solid var(--accent);outline-offset:2px}
.shell{display:grid;grid-template-columns:236px 1fr;min-height:100vh}
.shell.fullscreen{position:fixed;inset:0;z-index:9999;overflow-y:auto;background:var(--bg)}
.sidebar{background:var(--accent-dark);color:#fff;padding:22px 16px;position:sticky;top:0;height:100vh;overflow-y:auto}
.brand{display:flex;align-items:center;gap:11px;margin-bottom:6px}
.brand img{height:30px;width:auto}
.brand b{font-size:15px;font-weight:bold;display:block}
.brand small{display:block;font-size:14px;font-weight:400;color:#b8c7d9}
.nav{margin-top:28px;display:grid;gap:8px}
.nav button{color:#d9e4ef;text-align:right;padding:11px 12px;border-radius:10px;font-size:14px;display:flex;justify-content:space-between;align-items:center;gap:8px}
.nav button.active,.nav button:hover{background:#ffffff22;color:#fff}
.nav .count{background:#ffffff2e;border-radius:6px;padding:0 7px;font-size:14px}
.sidefoot{margin-top:26px;border:1px solid #ffffff33;border-radius:12px;padding:13px;font-size:14px;color:#c9d7e6}
.sidefoot b{display:block;color:#fff;font-size:14px}
.main{padding:22px}
.topbar{display:flex;justify-content:space-between;gap:16px;align-items:flex-start;margin-bottom:18px;flex-wrap:wrap}
h1{font-size:20px;margin:0;font-weight:bold}
.sub{font-size:14px;color:var(--muted);margin-top:5px}
.toolbar{display:flex;gap:8px;flex-wrap:wrap;justify-content:flex-end}
.btn-action{background:var(--accent);color:#fff;border:2px solid var(--accent);border-radius:9px;padding:9px 14px;font-size:14px;font-weight:bold}
.btn-action:hover{background:var(--accent-dark)}
.page{display:none}.page.active{display:block}
.hero{background:var(--accent);color:#fff;border-radius:18px;padding:24px;display:grid;grid-template-columns:1.15fr 1fr;gap:26px;margin-bottom:16px}
.hero h2{font-size:15px;font-weight:bold;margin:14px 0 0;line-height:2}
.hero p{font-size:14px;color:#d6e3f2;margin:8px 0 0}
.hero-badges{display:flex;gap:8px;flex-wrap:wrap}
.hero .pill{background:#ffffff26;color:#fff;border-color:transparent}
.hero .pill-solid{background:#fff;color:var(--accent)}
.hero-actions{display:flex;gap:9px;margin-top:20px;flex-wrap:wrap}
.btn-hero{background:#ffffff1a;border:2px solid #ffffff4d;color:#fff;border-radius:9px;padding:9px 14px;font-size:14px;font-weight:bold}
.btn-hero:hover{background:#fff;color:var(--accent)}
.hero-side{border-right:1px solid #ffffff33;padding-right:24px;display:flex;justify-content:space-between;align-items:center;gap:18px}
.hero-side small{font-size:14px;color:#d6e3f2}
.clock{font-size:32px;font-weight:bold;direction:ltr;letter-spacing:1px}
.ring{width:124px;height:124px;border-radius:50%;display:grid;place-items:center;flex-shrink:0}
.ring>div{background:var(--accent);width:102px;height:102px;border-radius:50%;display:grid;place-content:center;text-align:center;padding:0 6px}
.ring b{font-size:18px;display:block}
.ring span{font-size:14px;color:#d6e3f2;line-height:1.5}
.kpis{display:grid;grid-template-columns:repeat(6,1fr);gap:12px}
.card{background:var(--card);border:1px solid var(--line);border-radius:14px;padding:16px;min-width:0}
.kpi .label{font-size:14px;color:var(--muted)}
.kpi .value{font-size:24px;font-weight:bold;margin:7px 0;color:var(--accent)}
.kpi .value small{font-size:14px;font-weight:400;color:var(--muted)}
.kpi .sub{font-size:14px;color:var(--muted)}
.grid2{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1fr);gap:14px;margin-top:14px}
.grid2>*{min-width:0}
.kpis>*{min-width:0}
.title{font-weight:bold;font-size:15px;margin-bottom:13px;color:var(--accent)}
.note{font-size:14px;color:var(--muted);margin:12px 0 0}
.dash{color:var(--muted)}
.pill{display:inline-flex;align-items:center;border:1px solid var(--line);border-radius:7px;padding:3px 9px;font-size:14px;white-space:nowrap;background:#f5f5f5;color:var(--muted)}
.pill-solid{background:var(--accent);color:#fff;border-color:var(--accent)}
.pill-muted{background:#f5f5f5;color:#444;border-color:#ccc}
.chart{height:190px;display:flex;align-items:flex-end;gap:10px;padding:10px 4px 26px;border-bottom:1px solid var(--line);position:relative}
.barcol{flex:1;height:100%;display:flex;flex-direction:column;justify-content:flex-end;align-items:center;position:relative;min-width:24px}
.bar{width:100%;max-width:46px;display:flex;flex-direction:column;justify-content:flex-end;border-radius:6px 6px 0 0;overflow:hidden;background:var(--accent)}
.bar-extra{background:#9db6d6;width:100%}
.bar-work{flex:1;background:var(--accent)}
.barcol>span{position:absolute;top:calc(100% + 6px);font-size:14px;color:var(--muted);white-space:nowrap;max-width:100%;overflow:hidden;text-overflow:ellipsis}
.chartfoot{margin-top:34px;display:flex;justify-content:space-between;gap:10px;font-size:14px;color:var(--muted);flex-wrap:wrap}
.legend{display:flex;gap:14px}
.legend i{display:inline-block;width:9px;height:9px;border-radius:2px;background:var(--accent);margin-left:5px}
.legend i.light{background:#9db6d6}
.tabs{display:flex;gap:6px;background:#eef2f8;padding:4px;border-radius:10px;width:max-content;max-width:100%;flex-wrap:wrap;margin-bottom:14px}
.tabs button{border-radius:7px;padding:7px 14px;font-size:14px;color:var(--muted)}
.tabs button.active{background:#fff;color:var(--accent);font-weight:bold}
.table-wrap{overflow-x:auto;max-width:100%;border:1px solid var(--line);border-radius:10px}
.data-table{width:auto;min-width:100%;border-collapse:collapse}
.data-table th{background:var(--accent);color:#fff;padding:10px 9px;text-align:center;font-size:15px;font-weight:bold;white-space:nowrap;width:1%;position:sticky;top:0;cursor:pointer;user-select:none}
.data-table th.sort-asc::after{content:' ▲'}
.data-table th.sort-desc::after{content:' ▼'}
.data-table td{padding:9px;border-bottom:1px solid var(--line);font-size:14px;text-align:center;white-space:nowrap;width:1%}
.data-table td.cell-wrap{white-space:normal;min-width:220px;text-align:right}
.data-table tr:nth-child(even) td{background:#f5f5f5}
.data-table tr:hover td{background:#e8eef6}
.detail{display:flex;justify-content:space-between;gap:16px;padding:11px 0;border-bottom:1px solid var(--line);font-size:14px}
.detail:last-child{border-bottom:0}
.detail span{color:var(--muted)}
.empty-msg{text-align:center;color:var(--muted);padding:18px;font-size:14px}
.error-box{background:#f5f5f5;border:1px solid var(--accent);color:var(--accent-dark);border-radius:10px;padding:12px 14px;font-size:14px;margin-bottom:14px}
.notice{background:#f5f5f5;border:1px solid var(--line);border-right:4px solid var(--accent);border-radius:10px;padding:12px 14px;font-size:14px;margin:14px 0}
.notice code{background:#fff;border:1px solid var(--line);border-radius:5px;padding:1px 6px;font-size:14px}
.message-card{display:flex;gap:18px;align-items:flex-start}
.message-logo img{height:44px;width:auto}
.message-text{font-size:15px;font-weight:bold;margin:0;line-height:2.1}
.birthday-grid{display:grid;gap:12px}
.birthday-card{display:flex;gap:14px;align-items:center;border:1px solid var(--line);border-radius:12px;padding:13px}
.birthday-avatar{width:44px;height:44px;border-radius:50%;background:var(--accent);color:#fff;display:grid;place-items:center;font-size:15px;font-weight:bold;flex-shrink:0}
.birthday-body b{font-size:15px}
.birthday-body p{font-size:14px;color:var(--muted);margin:3px 0 9px}
.muted-note{font-size:14px;color:var(--muted)}
.link-btn{color:var(--accent);font-size:14px;font-weight:bold;text-decoration:underline}
.overlay{display:none;position:fixed;inset:0;background:rgba(0,0,0,0.5);z-index:10000;align-items:center;justify-content:center}
.overlay.open{display:flex}
.modal{background:#fff;border-radius:12px;max-width:720px;width:92%;max-height:86vh;overflow-y:auto}
.modal-header{display:flex;justify-content:space-between;align-items:center;gap:12px;background:var(--accent);color:#fff;padding:12px 16px;font-size:15px;font-weight:bold;position:sticky;top:0}
.modal-header img{height:24px;width:auto}
.modal-close{color:#fff;font-size:16px}
.modal-body{padding:16px;font-size:14px;text-align:right}
.modal-body p{margin:10px 0;line-height:2}
.modal-body ul{margin:6px 0 14px;padding-right:20px}
.modal-body li{margin:6px 0}
.thread{display:grid;gap:10px;margin:14px 0;max-height:34vh;overflow-y:auto}
.thread-item{border:1px solid var(--line);border-radius:10px;padding:10px 12px}
.thread-item b{font-size:14px;color:var(--accent)}
.thread-item p{margin:5px 0 0;font-size:14px;white-space:pre-wrap;overflow-wrap:anywhere}
.thread-item small{color:var(--muted);font-size:14px}
textarea{width:100%;border:1px solid var(--line);border-radius:9px;padding:10px 12px;font-size:14px;min-height:92px;resize:vertical}
.modal-foot{display:flex;gap:10px;justify-content:flex-start;margin-top:14px;flex-wrap:wrap}
.footer{text-align:center;color:var(--muted);font-size:14px;margin-top:16px}
@media(max-width:1250px){.kpis{grid-template-columns:repeat(3,1fr)}}
@media(max-width:1050px){.shell{grid-template-columns:1fr}.sidebar{position:relative;height:auto}.nav{grid-template-columns:repeat(2,1fr)}.hero{grid-template-columns:1fr}.hero-side{border-right:0;border-top:1px solid #ffffff33;padding:16px 0 0}.grid2{grid-template-columns:1fr}}
@media(max-width:700px){.kpis{grid-template-columns:1fr 1fr}.main{padding:14px}.ring{display:none}.message-card{flex-direction:column}}
@media print{.sidebar,.toolbar,.tabs,.overlay{display:none !important}.shell{grid-template-columns:1fr}.page{display:block !important}}
</style>
</head>
<body>
<div class="shell" id="reportRoot">
<aside class="sidebar">
  <div class="brand">
    <img alt="140" src="data:image/png;base64,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">
    <span><b>همراه ۱۴۰</b><small>فضای شخصی منابع انسانی</small></span>
  </div>
  <nav class="nav">
    <button type="button" class="active" data-page="overview">نمای کلی</button>
    <button type="button" data-page="attendance">تردد و کارکرد</button>
    <button type="button" data-page="requests">درخواست‌های من<span class="count">__PENDING_COUNT__</span></button>
    <button type="button" data-page="profile">اطلاعات پرسنلی</button>
    <button type="button" data-page="celebration">همراهِ روز و تولدها</button>
  </nav>
  <div class="sidefoot"><b>__PERSON_NAME__</b>__PERSON_UNIT__</div>
</aside>
<main class="main">
]==]

local topbar_html = '<div class="topbar"><div><h1>' .. escape_html(greeting) .. '</h1>' ..
    '<div class="sub">' .. escape_html(today_meta.jday_name .. " " .. today_meta.jdate) ..
    ' • بازهٔ گزارش: ' .. fmt_num(days_back) .. ' روز اخیر • کد پرسنلی ' ..
    escape_html(tostring(personnel.personnel_code or "—")) .. '</div></div>' ..
    '<div class="toolbar">' ..
    '<button type="button" class="btn-action" id="btnFullscreen" onclick="toggleFullScreen()">تمام صفحه</button>' ..
    '<button type="button" class="btn-action" onclick="exportActivePageToCsv()">خروجی Excel</button>' ..
    '<button type="button" class="btn-action" onclick="openHelp()">راهنما</button>' ..
    '</div></div>'

local section_overview = '<section id="overview" class="page active">' ..
    hero_html ..
    '<div class="kpis">' .. table.concat(kpi_html, "") .. '</div>' ..
    '<div class="grid2">' ..
    '<article class="card"><div class="title">ریتم کاری روزهای اخیر</div>' .. chart_html .. '</article>' ..
    '<article class="card"><div class="title">آخرین درخواست‌های من</div>' ..
    '<div class="table-wrap"><table class="data-table"><thead><tr>' ..
    '<th>تاریخ</th><th>نوع</th><th>مدت</th><th>وضعیت</th>' ..
    '</tr></thead><tbody>' .. table.concat(request_rows_compact, "") .. '</tbody></table></div>' ..
    '<p class="note">فهرست کامل با وضعیت زنجیرهٔ تایید در تب «درخواست‌های من» است.</p>' ..
    '</article></div></section>'

local section_attendance = '<section id="attendance" class="page">' ..
    '<article class="card">' ..
    '<div class="title">تردد و کارکرد من</div>' ..
    '<div class="tabs" role="group">' ..
    '<button type="button" class="active" data-report="daily">کارکرد روزانه</button>' ..
    '<button type="button" data-report="events">رویدادهای تردد</button>' ..
    '</div>' ..
    '<div id="reportDaily"><div class="table-wrap"><table class="data-table"><thead><tr>' ..
    '<th>تاریخ</th><th>روز</th><th>اولین ورود</th><th>آخرین خروج</th><th>کارکرد خالص</th>' ..
    '<th>اضافه‌کاری</th><th>تاخیر</th><th>مرخصی</th><th>ماموریت</th><th>کسری</th><th>وضعیت</th>' ..
    '</tr></thead><tbody>' .. table.concat(daily_rows, "") .. '</tbody></table></div></div>' ..
    '<div id="reportEvents" style="display:none;"><div class="table-wrap"><table class="data-table"><thead><tr>' ..
    '<th>تاریخ</th><th>از ساعت</th><th>تا ساعت</th><th>مدت</th><th>نوع</th>' ..
    '<th>دستگاه ورود</th><th>دستگاه خروج</th><th>وضعیت رکورد</th><th>توضیح</th>' ..
    '</tr></thead><tbody>' .. table.concat(event_rows, "") .. '</tbody></table></div></div>' ..
    '<p class="note">کارکرد خالص، اضافه‌کاری، تاخیر، مرخصی و ماموریت مستقیماً از رکورد محاسبه‌شدهٔ ' ..
    'حضور و غیاب همان روز خوانده می‌شوند. «کسری» ستون ذخیره‌شده ندارد و در همین گزارش از رابطهٔ ' ..
    'موظفی شیفت منهای (کارکرد + مرخصی + ماموریت) محاسبه می‌شود؛ برای روزهای غیبت و روزهای ناقص ' ..
    'محاسبه نمی‌شود.</p>' ..
    '</article>' ..
    '<div class="grid2">' ..
    '<article class="card"><div class="title">قواعد محاسبهٔ حکم من</div>' ..
    detail_row("تقویم کاری", employment.calendar_name) ..
    detail_row("بازهٔ حکم جاری", (employment.date_from or "—") .. " تا " .. (employment.date_to or "—")) ..
    detail_row("موظفی طبق حکم", order_working_hm) ..
    detail_row("سقف مرخصی ماهانه طبق حکم", order_leave_month_hm) ..
    detail_row("سقف تاخیر مجاز ماهانه", order_max_delay_hm) ..
    detail_row("استراحت حین کار", order_rest_hm) ..
    detail_row("سقف مرخصی ساعتی", order_max_hourly_hm) ..
    detail_row("مجموع موظفی بازه", totals.expected > 0 and minutes_to_hm(totals.expected) or nil) ..
    detail_row("مجموع کارکرد بازه", minutes_to_hm(totals.work)) ..
    detail_row("مانده مرخصی", leave_balance and minutes_to_hm(leave_balance.remained_minutes) or nil) ..
    '<p class="note">موظفی هر روز از تقویم کاری همان روز خوانده می‌شود (ساعت شروع و پایان شیفت ثبت‌شده ' ..
    'در تقویم)، نه از یک عدد ثابت ماهانه. مقادیر بالا از حکم فعال شما می‌آیند؛ هر مقداری که خارج از ' ..
    'بازهٔ منطقی باشد به‌جای عدد، «—» نشان داده می‌شود.</p>' ..
    '</article>' ..
    '<article class="card"><div class="title">خلاصهٔ بازه</div>' ..
    detail_row("روزهای حضور", fmt_num(totals.present_days)) ..
    detail_row("روزهای ناقص", fmt_num(totals.incomplete_days)) ..
    detail_row("روزهای غیبت", fmt_num(totals.absent_days)) ..
    detail_row("مجموع اضافه‌کاری", minutes_to_hm(totals.overtime)) ..
    detail_row("مجموع تاخیر", minutes_to_hm(totals.delay)) ..
    detail_row("مجموع کسری محاسبه‌شده", minutes_to_hm(totals.deficit)) ..
    '<p class="note">روز ناقص یعنی فقط یکی از دو رویداد ورود/خروج ثبت شده است. این حالت به‌خودی‌خود ' ..
    'غیبت نیست و باید با درخواست اصلاح در ماژول منابع انسانی بررسی شود.</p>' ..
    '</article></div></section>'

local section_requests = '<section id="requests" class="page">' ..
    '<article class="card"><div class="title">پیگیری درخواست‌ها</div>' ..
    '<div class="tabs" role="group">' ..
    '<button type="button" class="active" data-reqfilter="all">همه</button>' ..
    '<button type="button" data-reqfilter="در انتظار تایید">در انتظار</button>' ..
    '<button type="button" data-reqfilter="تایید شده">تایید شده</button>' ..
    '<button type="button" data-reqfilter="رد شده">رد شده</button>' ..
    '</div>' ..
    '<div class="table-wrap"><table class="data-table" id="requestsTable"><thead><tr>' ..
    '<th>تاریخ</th><th>دسته</th><th>نوع</th><th>ساعت</th><th>مدت</th><th>وضعیت</th>' ..
    '<th>کد وضعیت</th><th>تایید</th><th>ثبت</th><th>توضیحات</th>' ..
    '</tr></thead><tbody>' .. table.concat(request_rows, "") .. '</tbody></table></div>' ..
    '<p class="note">ستون «تایید» تعداد تاییدکنندگانی است که تا این لحظه درخواست مرخصی/ماموریت شما ' ..
    'را تایید کرده‌اند، نسبت به کل زنجیرهٔ تایید همان درخواست. ستون «کد وضعیت» عدد خام ثبت‌شده در ' ..
    'سامانه است تا با پنل رسمی منابع انسانی قابل تطبیق باشد.</p>' ..
    '</article></section>'

local settings_card = ""
if employment_settings ~= nil and #employment_settings > 0 then
    local setting_rows = {}
    for _, setting in ipairs(employment_settings) do
        table.insert(setting_rows, detail_row(setting.label, setting.value))
    end
    settings_card = '<div class="grid2"><article class="card">' ..
        '<div class="title">تنظیمات حکم من</div>' .. table.concat(setting_rows, "") ..
        '<p class="note">این تنظیم‌ها از حکم فعال شما در سامانه خوانده می‌شوند و تعیین می‌کنند چه ' ..
        'درخواست‌هایی برای شما فعال است و کدام‌ها نیاز به تایید دارند.</p>' ..
        '</article><article class="card"><div class="title">منبع اطلاعات این صفحه</div>' ..
        detail_row("حکم فعال", employment_source == "api" and
            "API رسمی حکم سامانه" or "جدول احکام پرسنلی") ..
        detail_row("سرپرست مستقیم", supervisor_source == "api_supervisor" and
            "API رسمی سرپرست شعبه" or "حکم فعال") ..
        detail_row("مانده مرخصی", leave_balance_note) ..
        detail_row("کارکرد و تردد", "رکورد حضور و غیاب و تقویم کاری") ..
        '<p class="note">هر عدد این پنل از منبع رسمی خودش خوانده می‌شود. اگر جایی با پنل رسمی منابع ' ..
        'انسانی اختلاف دیدید، همان پنل رسمی ملاک است و لطفاً گزارش کنید.</p>' ..
        '</article></div>'
end

local section_profile = '<section id="profile" class="page"><div class="grid2">' ..
    '<article class="card"><div class="title">اطلاعات پرسنلی</div>' .. profile_left .. '</article>' ..
    '<article class="card"><div class="title">حکم کاری و مرخصی</div>' .. profile_right ..
    '<p class="note">این صفحه فقط خواندنی است. اصلاح اطلاعات پرسنلی از مسیر رسمی ماژول منابع انسانی ' ..
    'انجام می‌شود. اطلاعات حقوق و دستمزد عمداً در این پنل نمایش داده نمی‌شود.</p>' ..
    '</article></div>' .. settings_card .. '</section>'

local html_tail = [==[
</main></div>

<div class="overlay" id="helpOverlay" onclick="if(event.target===this){closeHelp();}">
  <div class="modal">
    <div class="modal-header">
      <span><img alt="140" src="data:image/png;base64,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"> راهنمای پنل پرسنلی</span>
      <button type="button" class="modal-close" onclick="closeHelp()">✕</button>
    </div>
    <div class="modal-body">
      <p><b>این پنل چیست؟</b> فضای شخصی هر همکار در سامانهٔ منابع انسانی: کارکرد و تردد خودت،
      درخواست‌های خودت، اطلاعات پرسنلی خودت و بخش «همراهِ روز و تولدها». همهٔ اعداد از رکوردهای
      واقعی حضور و غیاب و احکام کاری خوانده می‌شوند.</p>
      <ul>
        <li><b>نمای کلی</b> — وضعیت امروز، شاخص‌های بازه، ریتم کاری روزهای اخیر و آخرین درخواست‌ها.</li>
        <li><b>تردد و کارکرد</b> — دو نما: «کارکرد روزانه» (رکورد محاسبه‌شدهٔ هر روز) و «رویدادهای
        تردد» (بازه‌های خام ثبت‌شده به‌همراه دستگاه مبدأ و مقصد).</li>
        <li><b>درخواست‌های من</b> — مرخصی و ماموریت، اضافه‌کاری و دورکاری در یک فهرست، با وضعیت و
        میزان پیشرفت زنجیرهٔ تایید.</li>
        <li><b>اطلاعات پرسنلی</b> — واحد، سرپرست، تقویم کاری، موظفی و سقف مرخصی طبق حکم جاری.</li>
        <li><b>همراهِ روز و تولدها</b> — پیام روز، تولدهای امروز و تولدهای این ماه، و گفتگوی تبریک.</li>
      </ul>
      <p><b>گفتگوی تبریک چطور کار می‌کند؟</b> با زدن «پیوستن به گفتگوی تبریک»، اگر برای تولد آن
      همکار در آن روز گفتگویی باز شده باشد شما به همان گفتگو اضافه می‌شوید؛ اگر هنوز باز نشده باشد،
      گفتگو ساخته می‌شود و شما اولین عضو آن هستید. گفتگو یک گفتگوی واقعی در ماژول «گفتگو»ی Teamyar
      است، پس پیام تبریک را همان‌جا بنویسید — پیام‌ها در همین پنل هم نمایش داده می‌شوند. همه در یک
      گفتگوی مشترک جمع می‌شوند، نه چند گفتگوی جدا.</p>
      <p><b>پیام امروز:</b> برای هر روزِ سالِ شمسی یک پیام یکتا وجود دارد (۳۶۶ پیام)، پس تا پایان
      سال هیچ پیامی تکرار نمی‌شود و همهٔ همکاران در یک روز پیام یکسان می‌بینند.</p>
      <p><b>ورودی‌ها:</b> <code>days</code> (طول بازه، پیش‌فرض ۳۱ روز)، <code>from_date</code> و
      <code>to_date</code> (FILETIME عددی)، <code>format=json</code> برای خروجی داده. پنل همیشه
      اطلاعات کاربرِ واردشده را نشان می‌دهد و شناسهٔ فرد دیگری را از ورودی نمی‌پذیرد.</p>
      <p><b>تعامل‌ها:</b> کلیک روی عنوان هر ستون جدول را مرتب می‌کند؛ «خروجی Excel» جدول‌های همین
      صفحه را به فایل CSV می‌دهد؛ «تمام صفحه» صفحه را بدون وابستگی به قابلیت fullscreen مرورگر
      بزرگ می‌کند؛ کلید Esc پنجره‌های باز را می‌بندد.</p>
      <p><b>موظفی و مانده مرخصی:</b> موظفی هر روز از تقویم کاری همان روز خوانده می‌شود، نه از یک عدد
      ثابت. «مانده مرخصی» از آخرین دورهٔ محاسبهٔ مانده در سامانه می‌آید؛ اگر با عدد پنل رسمی منابع
      انسانی اختلاف داشت، همان عدد پنل رسمی ملاک است.</p>
      <p><b>آنچه عمداً در این پنل نیست:</b> ثبت درخواست جدید (که باید از فرم رسمی و با گردش تایید
      انجام شود)، فیش حقوقی (دادهٔ حساس)، و برچسب «تردد ناموفق» (سامانه لاگ تلاش ناموفق هر نفر را
      به این شکل نگه نمی‌دارد؛ به‌جای آن رویدادهای واقعی تردد نمایش داده می‌شود).</p>
    </div>
  </div>
</div>

<div class="overlay" id="celebrationOverlay" onclick="if(event.target===this){closeCelebration();}">
  <div class="modal">
    <div class="modal-header">
      <span id="celebrationTitle">گفتگوی تبریک</span>
      <button type="button" class="modal-close" onclick="closeCelebration()">✕</button>
    </div>
    <div class="modal-body">
      <p class="note" id="celebrationHint">در حال بارگذاری گفتگو...</p>
      <p class="note" id="celebrationMembers"></p>
      <div class="thread" id="celebrationThread"></div>
      <p class="note" id="celebrationTopic"></p>
      <div class="modal-foot">
        <button type="button" class="btn-action" id="celebrationJoin" onclick="joinCelebration()">پیوستن به گفتگو</button>
        <button type="button" class="btn-action" id="celebrationOpenModule" onclick="openChatModule()">باز کردن گفتگو</button>
        <button type="button" class="btn-action" onclick="closeCelebration()">بستن</button>
      </div>
      <p class="note" id="celebrationResult">پس از پیوستن، پیام تبریک را داخل خودِ گفتگو بنویسید؛ همین‌جا هم نمایش داده می‌شود.</p>
    </div>
  </div>
</div>

<div class="footer">همراه ۱۴۰ — پنل پرسنلی منابع انسانی</div>

<script>
var RUN_URL = location.pathname;          // برای POSTهای داخلی بات
var SELF_URL = location.href;             // برای باز کردن همین گزارش در تب جدید (با query کامل)
var celebrationTarget = { name: '', date: '', dialogId: 0 };
var CELEBRATION_GROUP_ID = __CELEBRATION_GROUP_ID__;
var CELEBRATION_ENABLED = __CELEBRATION_ENABLED__;
var CHAT_MODULE_URL = '__CHAT_MODULE_URL__';
var CHAT_DIALOG_URL_TEMPLATE = '__CHAT_DIALOG_URL_TEMPLATE__';

document.querySelectorAll('.nav button').forEach(function (btn) {
  btn.addEventListener('click', function () { goToPage(btn.dataset.page); });
});
document.querySelectorAll('[data-goto]').forEach(function (btn) {
  btn.addEventListener('click', function () { goToPage(btn.dataset.goto); });
});
function goToPage(page) {
  document.querySelectorAll('.page').forEach(function (x) { x.classList.remove('active'); });
  document.querySelectorAll('.nav button').forEach(function (x) {
    x.classList.toggle('active', x.dataset.page === page);
  });
  var target = document.getElementById(page);
  if (target) target.classList.add('active');
  window.scrollTo({ top: 0, behavior: 'instant' });
}

document.querySelectorAll('[data-report]').forEach(function (btn) {
  btn.addEventListener('click', function () {
    document.querySelectorAll('[data-report]').forEach(function (x) {
      x.classList.toggle('active', x === btn);
    });
    document.getElementById('reportDaily').style.display = (btn.dataset.report === 'daily') ? '' : 'none';
    document.getElementById('reportEvents').style.display = (btn.dataset.report === 'events') ? '' : 'none';
  });
});

document.querySelectorAll('[data-reqfilter]').forEach(function (btn) {
  btn.addEventListener('click', function () {
    document.querySelectorAll('[data-reqfilter]').forEach(function (x) {
      x.classList.toggle('active', x === btn);
    });
    var wanted = btn.dataset.reqfilter;
    document.querySelectorAll('#requestsTable tbody tr').forEach(function (row) {
      if (!row.dataset.status) return;
      row.style.display = (wanted === 'all' || row.dataset.status === wanted) ? '' : 'none';
    });
  });
});

// این گزارش داخل iframe پنل تیم‌یار اجرا می‌شود و position:fixed نسبت به همان iframe محاسبه
// می‌شود، نه پنجرهٔ مرورگر — یعنی کلاس CSS فقط داخل قاب کوچک پخش می‌شد و عملاً تمام‌صفحه نمی‌شد.
// (تاییدشده روی بات ۶۲۲.) پس وقتی داخل iframe هستیم، همین گزارش را در تب جدید باز می‌کنیم که
// واقعاً تمام‌صفحه است و نه به iframe وابسته است نه به Fullscreen API که روی این پلتفرم
// غیرقابل‌اتکا بودنش قبلاً ثبت شده. اگر مستقیم (بدون iframe) باز شده باشد، همان کلاس CSS کافی است.
function isInsideFrame() {
  try { return window.self !== window.top; } catch (e) { return true; }
}
function toggleFullScreen() {
  if (isInsideFrame()) {
    window.open(SELF_URL, '_blank');
    return;
  }
  var root = document.getElementById('reportRoot');
  var btn = document.getElementById('btnFullscreen');
  var isFull = root.classList.toggle('fullscreen');
  btn.innerText = isFull ? 'خروج از تمام صفحه' : 'تمام صفحه';
}

function csvEscapeCell(text) {
  var t = (text == null ? '' : String(text)).replace(/\s+/g, ' ').trim();
  if (t.indexOf(',') !== -1 || t.indexOf('"') !== -1 || t.indexOf('\n') !== -1) {
    t = '"' + t.replace(/"/g, '""') + '"';
  }
  return t;
}
function exportActivePageToCsv() {
  var activePage = document.querySelector('.page.active');
  if (!activePage) return;
  var lines = [];
  var tables = activePage.querySelectorAll('table.data-table');
  for (var t = 0; t < tables.length; t++) {
    if (tables[t].closest('[style*="display:none"]')) continue;
    if (t > 0) lines.push('');
    var headers = tables[t].querySelectorAll('thead th');
    var headerLine = [];
    for (var h = 0; h < headers.length; h++) headerLine.push(csvEscapeCell(headers[h].innerText));
    lines.push(headerLine.join(','));
    var rows = tables[t].querySelectorAll('tbody tr');
    for (var i = 0; i < rows.length; i++) {
      if (rows[i].style.display === 'none') continue;
      if (rows[i].querySelector('td.empty-msg')) continue;
      var cells = rows[i].querySelectorAll('td');
      var line = [];
      for (var c = 0; c < cells.length; c++) line.push(csvEscapeCell(cells[c].innerText));
      lines.push(line.join(','));
    }
  }
  if (lines.length === 0) lines.push('این صفحه جدولی برای خروجی ندارد');
  var blob = new Blob(['\ufeff' + lines.join('\r\n')], { type: 'text/csv;charset=utf-8;' });
  var url = URL.createObjectURL(blob);
  var link = document.createElement('a');
  link.href = url;
  link.download = 'hamrah140-panel.csv';
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}

function getCellSortValue(cell) {
  var text = cell ? cell.innerText.trim() : '';
  var normalized = text.replace(/[,٪%]/g, '').trim();
  if (/^-?\d{1,2}:\d{2}$/.test(normalized)) {
    var parts = normalized.split(':');
    return parseInt(parts[0], 10) * 60 + parseInt(parts[1], 10);
  }
  if (normalized !== '' && /^-?\d+(\.\d+)?$/.test(normalized)) return parseFloat(normalized);
  return text;
}
function sortTableByColumn(table, colIndex, dir) {
  var tbody = table.querySelector('tbody');
  var rows = Array.prototype.slice.call(tbody.querySelectorAll('tr'));
  if (rows.length === 0 || rows[0].querySelectorAll('td').length < colIndex + 1) return;
  rows.sort(function (ra, rb) {
    var a = getCellSortValue(ra.children[colIndex]);
    var b = getCellSortValue(rb.children[colIndex]);
    var cmp;
    if (typeof a === 'number' && typeof b === 'number') cmp = a - b;
    else cmp = String(a).localeCompare(String(b), 'fa');
    return dir === 'asc' ? cmp : -cmp;
  });
  rows.forEach(function (row) { tbody.appendChild(row); });
}
function initSortableTables() {
  document.querySelectorAll('table.data-table').forEach(function (table) {
    var headers = table.querySelectorAll('thead th');
    headers.forEach(function (th, colIndex) {
      th.addEventListener('click', function () {
        var dir = th.classList.contains('sort-asc') ? 'desc' : 'asc';
        headers.forEach(function (h) { h.classList.remove('sort-asc', 'sort-desc'); });
        th.classList.add(dir === 'asc' ? 'sort-asc' : 'sort-desc');
        sortTableByColumn(table, colIndex, dir);
      });
    });
  });
}

function botRequest(payload, onDone, onFail) {
  if (typeof $ !== 'undefined' && $.Teamyar && $.Teamyar.ajax) {
    $.Teamyar.ajax({
      block_holder: 'body',
      options: {
        url: RUN_URL, type: 'POST', dataType: 'json',
        data: { customform: JSON.stringify(payload) }
      },
      events: { success: onDone, error: onFail }
    });
    return;
  }
  var form = new FormData();
  form.append('customform', JSON.stringify(payload));
  fetch(RUN_URL, { method: 'POST', body: form })
    .then(function (res) { return res.json(); })
    .then(onDone)
    .catch(onFail);
}

function renderThread(messages) {
  var box = document.getElementById('celebrationThread');
  if (!messages || messages.length === 0) {
    box.innerHTML = '<div class="empty-msg">هنوز کسی پیامی نگذاشته است. اولین نفر باش.</div>';
    return;
  }
  box.innerHTML = messages.map(function (m) {
    var author = document.createElement('div');
    author.textContent = m.author || '-';
    var text = document.createElement('div');
    text.textContent = (m.text || '').replace(/<[^>]*>/g, '');
    var when = document.createElement('div');
    when.textContent = (m.date || '') + ' ' + (m.clock || '');
    return '<div class="thread-item"><b>' + author.innerHTML + '</b> <small>' +
      when.innerHTML + '</small><p>' + text.innerHTML + '</p></div>';
  }).join('');
}

function setCelebrationState(res) {
  var hint = document.getElementById('celebrationHint');
  var members = document.getElementById('celebrationMembers');
  var joinBtn = document.getElementById('celebrationJoin');
  celebrationTarget.dialogId = (res && res.dialog_id) ? res.dialog_id : 0;
  if (res && res.exists === false && !res.created) {
    hint.textContent = 'هنوز گفتگویی برای این تولد باز نشده؛ با زدن دکمه، تو آن را باز می‌کنی و بقیه به همان می‌پیوندند.';
    joinBtn.textContent = 'باز کردن گفتگو و پیوستن';
  } else {
    hint.textContent = 'گفتگو باز است؛ با زدن دکمه به همان گفتگو می‌پیوندی.';
    joinBtn.textContent = 'پیوستن به گفتگو';
  }
  joinBtn.disabled = !CELEBRATION_ENABLED;
  if (!CELEBRATION_ENABLED) {
    joinBtn.textContent = 'پیوستن فعلاً غیرفعال است';
    hint.textContent = 'این گفتگو فقط خواندنی است؛ ساخت و پیوستن هنوز فعال نشده است.';
  }
  var topicBox = document.getElementById('celebrationTopic');
  if (celebrationTarget.dialogId) {
    var openBtn = document.getElementById('celebrationOpenModule');
    if (CHAT_DIALOG_URL_TEMPLATE) {
      openBtn.textContent = 'باز کردن گفتگو';
      topicBox.textContent = 'عنوان این گفتگو: «تبریک تولد ' + celebrationTarget.name +
        ' — ' + celebrationTarget.date + '» (شناسه ' + celebrationTarget.dialogId + ').';
    } else {
      openBtn.textContent = 'باز کردن ماژول گفتگو';
      topicBox.textContent = 'این گفتگو در ماژول گفتگو با همین عنوان پیدا می‌شود: «تبریک تولد ' +
        celebrationTarget.name + ' — ' + celebrationTarget.date + '».';
    }
  } else {
    topicBox.textContent = '';
  }
  var list = (res && res.members) ? res.members : [];
  members.textContent = list.length
    ? ('تا اینجا در گفتگو: ' + list.join('، '))
    : 'هنوز کسی به گفتگو نپیوسته است.';
  renderThread(res ? res.messages : []);
}

function openCelebration(name, dateLabel) {
  celebrationTarget = { name: name, date: dateLabel, dialogId: 0 };
  document.getElementById('celebrationTitle').textContent = 'گفتگوی تبریک تولد ' + name;
  document.getElementById('celebrationThread').innerHTML = '';
  document.getElementById('celebrationMembers').textContent = '';
  document.getElementById('celebrationHint').textContent = 'در حال بارگذاری گفتگو...';
  document.getElementById('celebrationResult').textContent =
    'پس از پیوستن، پیام تبریک را داخل خودِ گفتگو بنویسید؛ همین‌جا هم نمایش داده می‌شود.';
  document.getElementById('celebrationJoin').disabled = true;
  document.getElementById('celebrationOverlay').classList.add('open');

  botRequest({ type: 'celebration_thread', person_name: name, person_date: dateLabel },
    function (res) {
      if (!res || !res.ok) {
        document.getElementById('celebrationHint').textContent =
          (res && res.error) ? res.error : 'گفتگو بارگذاری نشد.';
        return;
      }
      setCelebrationState(res);
    },
    function () {
      document.getElementById('celebrationHint').textContent = 'خطا در ارتباط با سرور.';
    });
}

function openChatModule() {
  var url = CHAT_MODULE_URL;
  if (celebrationTarget.dialogId && CHAT_DIALOG_URL_TEMPLATE) {
    url = CHAT_DIALOG_URL_TEMPLATE.replace('{id}', String(celebrationTarget.dialogId));
  }
  window.open(url, '_blank');
}

function closeCelebration() {
  document.getElementById('celebrationOverlay').classList.remove('open');
}

function joinCelebration() {
  var joinBtn = document.getElementById('celebrationJoin');
  var result = document.getElementById('celebrationResult');
  joinBtn.disabled = true;
  result.textContent = 'در حال پیوستن...';
  botRequest({
    type: 'celebrate',
    person_name: celebrationTarget.name,
    person_date: celebrationTarget.date
  }, function (res) {
    if (!res || !res.ok) {
      joinBtn.disabled = false;
      result.textContent = (res && res.error) ? res.error : 'پیوستن به گفتگو انجام نشد.';
      return;
    }
    result.textContent = res.created
      ? 'گفتگو ساخته شد و تو عضو آن شدی. حالا پیام تبریکت را داخل گفتگو بنویس.'
      : 'به گفتگو پیوستی. پیام تبریکت را داخل گفتگو بنویس.';
    setCelebrationState({ exists: true, created: res.created, dialog_id: res.dialog_id,
                          members: res.members, messages: res.messages });
    joinBtn.textContent = 'عضو این گفتگو هستی';
    joinBtn.disabled = true;
  }, function () {
    joinBtn.disabled = false;
    result.textContent = 'خطا در ارتباط با سرور.';
  });
}

function openHelp() { document.getElementById('helpOverlay').classList.add('open'); }
function closeHelp() { document.getElementById('helpOverlay').classList.remove('open'); }
document.addEventListener('keydown', function (e) {
  if (e.key === 'Escape') { closeHelp(); closeCelebration(); }
});
initSortableTables();
</script>
</body>
</html>]==]

local person_unit = ""
if employment.unit_name ~= nil then
    person_unit = escape_html(employment.unit_name)
end

-- جایگزینی با تابع انجام می‌شود تا کاراکتر % داخل مقدار جایگزین، به‌عنوان الگوی gsub تفسیر نشود
local function replace_token(text, token, value)
    return (text:gsub(token, function() return value end))
end

html_head = replace_token(html_head, "__PENDING_COUNT__", fmt_num(request_counts.pending))
html_head = replace_token(html_head, "__PERSON_NAME__", escape_html(personnel.fullname))
html_head = replace_token(html_head, "__PERSON_UNIT__", person_unit)

html_tail = replace_token(html_tail, "__CELEBRATION_GROUP_ID__",
    celebration_group_id and tostring(celebration_group_id) or "0")
html_tail = replace_token(html_tail, "__CELEBRATION_ENABLED__",
    celebration_enabled and "true" or "false")
html_tail = replace_token(html_tail, "__CHAT_MODULE_URL__", js_str(chat_module_url))
html_tail = replace_token(html_tail, "__CHAT_DIALOG_URL_TEMPLATE__", js_str(chat_dialog_url_template))

local html = html_head .. topbar_html .. error_html ..
    section_overview .. section_attendance .. section_requests .. section_profile ..
    celebration_html .. html_tail

return html
end)

if render_ok and type(render_output) == "string" and render_output ~= "" then
    teamyar.write_result(render_output)
else
    teamyar.write_result(render_error_page(
        "در ساخت صفحه خطایی رخ داد. اطلاعات شما دست‌نخورده است و این خطا فقط در نمایش بوده است.",
        render_ok and "خروجی رندر خالی بود" or render_output))
end
