-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/06/14 13:30
-- version= 8.1 (درخواست کاربر: کنترل دسترسی ارسال پیامک/ایمیل — فهرست کاربران/گروه‌های مجاز از «پیکربندی بات»، fallback به دسترسی ماژول بومی؛ اعمال در سرور و پنهان‌سازی دکمه‌ها در UI)
-- version= 8.0 (درخواست کاربر: سوییچ نمای جدولی/کارتی/خودکار برای همهٔ جدول‌ها (نوار بالا + کنار هر جدول، ذخیره در مرورگر) و حالت روز/شب با همان پالت)
-- version= 7.1 (رفع: صندوق‌های ایمیل با TRASH_STATUS=1 (مثل info@) واقعاً فعال‌اند — فیلتر حذف شد؛ مرتب‌سازی صندوق‌ها بر اساس پیش‌فرض و تعداد ارسال)
-- version= 7.0 (درخواست کاربر: ارسال واقعی ایمیل از پروفایل/لیست با /api/email/emailmsgadd (ماژول ۱۲) — پنجرهٔ نگارش با گیرنده از ایمیل‌های مشتری، صندوق شخصی کاربر، موضوع و متن؛ ایمیل گروهی)
-- version= 6.0 (درخواست کاربر: ارسال واقعی پیامک از پروفایل/لیست با /api/sms/send (ماژول ۱۶) — پنجرهٔ نگارش با انتخاب شماره و صندوق، شمارندهٔ نویسه، ارسال گروهی از انتخاب لیست)
-- version= 5.3 (بازخورد کاربر: سورت قابل مشاهده روی همهٔ سرستون‌ها (نشانهٔ ⇅) + کنترل «مرتب‌سازی» ستون/جهت بالای هر جدول برای موبایل که سرستون ندارد)
-- version= 5.2 (اعتبار لاگین سایت = ۲ روز (نشست mobile140) و ذخیره در localStorage — بات ۳۹۸ فقط بعد از انقضا یا با «ورود مجدد» دوباره اجرا می‌شود)
-- version= 5.1 (پیشنهاد کاربر: اجرای خودکار بات ۳۹۸ (لاگین سایت) در پس‌زمینه هنگام باز شدن ماژول و پیش از «نمایش در سایت» + دکمهٔ ورود مجدد)
-- version= 5.0 (درخواست کاربر: اجرای بات ۴۸۶ «نمایش مشتری در سایت» از هدر پروفایل، عملیات ردیف، منوی ⋯ و تب ابزارها — در پنجرهٔ هم‌مبدأ با گزینهٔ تب جدید)
-- version= 4.1 (ستون‌های اضافی فقط در صورت انتخاب محاسبه می‌شوند (cols)، سورت سروری فقط ستون‌های مستقیم — رفع کندی ۵ ثانیه‌ای و Timeout سورت)
-- version= 4.0 (درخواست کاربر: انتخابگر ستون کامل — همهٔ فیلدهای جزئیات مشتری (شناسنامه‌ای، تماس، آدرس، حقوقی، حسابداری، آمار فروش/اقدام/رویداد، آخرین توضیح) به‌عنوان ستون لیست + پنهان‌کردن ستون روی هر جدول)
-- version= 3.0 (بازخورد کاربر: ناوبری مستقل از hash (رفع باز نشدن جزئیات مشتری در پرتال)، کلیک روی کل ردیف، درخت رده جمع‌شونده + دراپ‌داون رده، قانون جدید: همهٔ جدول‌ها سورت + فیلتر، ظاهر موبایل‌محور با نمای کارتی)
-- version= 2.4 (پس از تست بصری: شمارش توضیحات = یادداشت‌ها + فایل‌های قدیمی، KPI/تب مطلعین از فهرست API، حذف شمارندهٔ گمراه‌کنندهٔ تب «مطلع» لیست)
-- version= 2.3 (مطلع/مسئول: خواندن از API با شکل واقعی پاسخ assigns/responsibles، نوشتن با POST هم‌مبدأ ماژول بومی (type 0/2)؛ حذف اکشن‌های بی‌اثر API)
-- version= 2.2 (تست نوشتن زنده: توضیحات = crm_history متن ساده + بخش الزامی، رده با ID/PROFILE_ID، مطلع/مسئول فقط از API، create + update تکمیلی، ترجمهٔ خطاهای API)
-- version= 2.1 (رفع پس از تست زنده: پارامتر section/tab لینک‌های پرتال، شمارش اقدام فقط لینک‌های معتبر، نرمال‌سازی آرایه‌های خالی در UI)
-- version= 2.0 (بازطراحی کامل ماژول مشتری: لیست با درخت بخش/رده، فیلتر پیشرفته، پروفایل ۳۶۰ با همهٔ تب‌ها، عملیات نوشتن از طریق API رسمی CRM)

-- Bot 606 — CRM Customer 360 UI  (run_path: 443/crm_customer_ui_v01)
--
-- معماری v2:
--   * این فایل فقط «سرور» است: مسیریاب action، لایهٔ SQL، لایهٔ API (teamyar.call_api ماژول ۱۴) و شل HTML.
--   * رابط کاربری (SPA) در پیوست‌های همین بات است: app.js + app.css — سرو می‌شوند از
--     /bot/run/443/crm_customer_ui_v01/app.js  (پیوست‌های بات همان‌جا سرو می‌شوند؛ CSP پرتال 'self' را مجاز می‌داند).
--   * همهٔ درخواست‌های داده POST با فیلدهای ساده (action=...) به آدرس مطلق اجرای بات هستند (الگوی بات ۶۰۹)؛
--     هرگز فیلدی به نام customform ارسال نمی‌شود (۴۰۰ پلتفرم).
--
-- نگاشت شناسه‌ها (روی دادهٔ زنده ۱۴۰۵/۰۶/۱۲ با کوئری تأیید شد — چیزی حدس زده نشده):
--   شناسهٔ مشتری = crm_info.ID = profile_main.ID = profile_user_info.ID  (همان عدد URLهای پرتال)
--   crm_notify / crm_favorite / crm_history / crm_contacts / crm_address / crm_cross / crm_custom_form
--       .CLIENT_ID = crm_info.ID  (۱۰۰٪ join؛ نه pa_client.ID — یافتهٔ قبلی نادرست بود)
--   crm_cross(CLIENT_ID, REFERE_ID): عضویت مشتری در رده؛ REFERE_ID = crm_classify_person.PROFILE_ID
--   crm_classify_person.section_id -> crm_section.ID  (بخش)
--   sales_invoice / purchase_invoice .CLIENT_ID = pa_client.ID و pa_client.REFFERE_ID = شناسهٔ مشتری (Bridge حسابداری)
--   crm_ty_links(SRC_MODULE_ID=14, SRC_LINK_ID=مشتری) -> DST_MODULE_ID: 8 اقدام، 12 ایمیل، 7 اسناد/توضیحات، 20 پروژه، 19 تقویم
--   «توضیحات» = فایل‌های .tyhtm (documents_main، MIME text-html) لینک‌شده به مشتری؛ نمایش: /crm/history/comment/show_file/
--   «اسناد» = documents_main.PARENT_ID = crm_info.FOLDER_ID (اگر پوشه ساخته شده باشد) + اسناد لینک‌شدهٔ غیر-توضیح
--   رویدادها = cal_invite_user.USER_ID = شناسهٔ مشتری ؛ نظرسنجی = poll_related.USER_ID (related_type=1)
--   پیامک = تطبیق ۱۰ رقم آخر موبایل با sms_phone_book.PHONE_NUMBER ؛ گفتگو = chat_dialogs.AUTHOR_ID
--   crm_history = لاگ فعالیت (TYPE=1، NOTE = جدول HTML) — نه متن توضیحات کاربر
--
-- عملیاتی که API رسمی ندارند (برگزیده، انتقال به حذف‌شده‌ها، بازگرداندن، تأیید، حذف نهایی، تغییر گروهی رده،
-- مطلع) در سمت مرورگر با همان GET/POST هم‌مبدأ ماژول بومی انجام می‌شوند (/crm/index/set_favorite/ ...)،
-- پس سطح دسترسی کاربر دقیقاً همان ماژول بومی است. عملیاتی که API دارند (ثبت توضیح، ویرایش/ایجاد مشتری،
-- رابط، رده) از این‌جا با teamyar.call_api(14, ...) انجام می‌شوند.

-- =========================================
-- CONFIG
-- =========================================
local CONFIG = {
    DB_SCHEMA        = "0000000",
    BASE_URL         = "https://erp.bimehland.com",
    BOT_RUN_PATH     = "443/crm_customer_ui_v01",
    ASSET_VERSION    = "8.1.0",
    CRM_MODULE_ID    = 14,
    -- بات ۴۸۶ «show crm saite»: با client_id، صفحهٔ مشتری در سایت (mobile140.com/dashboard/users/customer/<شناسه سایت>) را
    -- از روی crm_info.COMMENT («شناسه سایت:NNN») در iframe نشان می‌دهد. GET با query هم کار می‌کند (تست زنده ۱۴۰۵/۰۶/۱۲).
    SITE_VIEW_BOT_PATH = "443/crm_saite_show",
    SITE_ID_MARKER     = "شناسه سایت",
    -- بات ۳۹۸ «show_site»: iframe به آدرس سایت با کلید کاربر جاری => لاگین سایت در مرورگر (کوکی mobile140).
    -- باید قبل از بات ۴۸۶ در همان مرورگر بارگذاری شود؛ app.js آن را در پس‌زمینه (iframe پنهان) اجرا می‌کند.
    SITE_LOGIN_BOT_PATH = "2/show_site",
    PAGE_SIZE        = 30,
    MAX_PAGE_SIZE    = 200,
    EXPORT_MAX_ROWS  = 3000,
    TAB_ROW_LIMIT    = 300,
    HISTORY_LIMIT    = 150,
    TREE_CACHE       = nil,
    -- لوگوی «۱۴۰» نسخهٔ White (روی نوار Accent هدر) — در مرحلهٔ build جایگزین می‌شود
    LOGO140_WHITE_B64 = "{{LOGO140_WHITE_B64}}",
}
CONFIG.BOT_RUN_URL   = CONFIG.BASE_URL .. "/bot/run/" .. CONFIG.BOT_RUN_PATH
CONFIG.ASSET_BASE    = "/bot/run/" .. CONFIG.BOT_RUN_PATH

local AMP = "&"   -- «&» همیشه از این ثابت ساخته می‌شود تا decode حریصانهٔ entity در ذخیرهٔ command رخ ندهد

-- =========================================
-- HTML ESCAPE (پیاده‌سازی الزامی — entity ها با الحاق ساخته می‌شوند)
-- =========================================
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

-- =========================================
-- GENERIC HELPERS
-- =========================================
local function trim(s)
    if s == nil then return "" end
    return (tostring(s):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function scalar_input(value)
    if value == nil then return nil end
    local t = _G.type(value)
    if t ~= "string" and t ~= "number" then return nil end
    return value
end

local function to_int(v)
    local n = tonumber(v)
    if n == nil then return nil end
    return math.floor(n)
end

local function to_positive_int(v)
    local n = to_int(v)
    if n == nil or n <= 0 then return nil end
    return n
end

local function nz(value, default)
    if value == nil or value == "" or (_G.type(value) == "userdata") then
        return default or ""
    end
    return tostring(value)
end

local function is_all_digits(s)
    return s ~= nil and s ~= "" and s:match("^%d+$") ~= nil
end

-- فقط برای الگوهای LIKE: چون بایند کردن LIKE ? در لایهٔ db.query این پلتفرم بی‌صدا شکست می‌خورد (CLAUDE.md)،
-- ورودی کاربر قبل از الحاق به SQL «سفیدلیستی» پاک می‌شود: تنها حروف (هر زبان، بایت‌های UTF-8 >= 128)،
-- ارقام، فاصله، «-»، «_» و «.» باقی می‌مانند. کوتیشن، بک‌اسلش، درصد، نقطه‌ویرگول و هر نویسهٔ کنترلی حذف می‌شود؛
-- پس رشتهٔ نهایی نمی‌تواند از داخل literal خارج شود.
local function sanitize_like_literal(s)
    local out = {}
    for i = 1, #s do
        local b = s:byte(i)
        if b >= 128 or (b >= 48 and b <= 57) or (b >= 65 and b <= 90) or (b >= 97 and b <= 122)
            or b == 32 or b == 45 or b == 95 or b == 46 or b == 64 then
            table.insert(out, string.char(b))
        end
    end
    return table.concat(out)
end

local function digits_only(s)
    return (tostring(s or ""):gsub("%D", ""))
end

local function fmt_num(value)
    local n = tonumber(value)
    if n == nil then return "0" end
    local s = tostring(math.floor(math.abs(n) + 0.5))
    local sign = n < 0 and "-" or ""
    return sign .. s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function strip_tags(html)
    if html == nil then return "" end
    local s = tostring(html)
    s = s:gsub("</td>", " | "):gsub("</tr>", " ‹› "):gsub("<br%s*/?>", " ")
    s = s:gsub("<[^>]+>", " ")
    s = s:gsub("&" .. "nbsp;", " ")
    s = s:gsub("%s+", " ")
    s = s:gsub(" ‹› ", "  ")
    return trim(s)
end

-- =========================================
-- DATE HELPERS (FILETIME <-> شمسی، خالص Lua — REPORT_FN_JDATE روی این سرور وجود ندارد)
-- =========================================
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

local function days_from_civil(y, m, d)
    if m <= 2 then y = y - 1 end
    local era = floor_div(y, 400)
    local yoe = y - era * 400
    local mp = (m + 9) % 12
    local doy = floor_div(153 * mp + 2, 5) + d - 1
    local doe = yoe * 365 + floor_div(yoe, 4) - floor_div(yoe, 100) + doy
    return era * 146097 + doe - 719468
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

local function jalali_to_gregorian(jy, jm, jd)
    jy = jy + 1595
    local days = -355668 + (365 * jy) + (math.floor(jy / 33) * 8) + math.floor(((jy % 33) + 3) / 4) + jd
    if jm < 7 then
        days = days + (jm - 1) * 31
    else
        days = days + ((jm - 7) * 30) + 186
    end
    local gy = 400 * math.floor(days / 146097)
    days = days % 146097
    if days > 36524 then
        days = days - 1
        gy = gy + 100 * math.floor(days / 36524)
        days = days % 36524
        if days >= 365 then days = days + 1 end
    end
    gy = gy + 4 * math.floor(days / 1461)
    days = days % 1461
    if days > 365 then
        gy = gy + math.floor((days - 1) / 365)
        days = (days - 1) % 365
    end
    local gd = days + 1
    local is_leap = (gy % 4 == 0 and gy % 100 ~= 0) or (gy % 400 == 0)
    local g_days_in_month = { 31, is_leap and 29 or 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
    local gm = 1
    while gm <= 12 and gd > g_days_in_month[gm] do
        gd = gd - g_days_in_month[gm]
        gm = gm + 1
    end
    return gy, gm, gd
end

local EPOCH_DIFF_SECONDS = 11644473600
local TICKS_PER_SECOND   = 10000000
local DAY_TICKS          = 864000000000

local function fmt_jalali_from_filetime(filetime, with_time)
    local ft = tonumber(filetime)
    if ft == nil or ft <= 0 then return nil end
    local unixtime = floor_div(ft, TICKS_PER_SECOND) - EPOCH_DIFF_SECONDS
    if unixtime < 0 then return nil end
    -- ساعت ایران (+03:30) برای نمایش زمان
    local local_time = unixtime + 12600
    local days = floor_div(local_time, 86400)
    local gy, gm, gd = civil_from_days(days)
    local jy, jm, jd = gregorian_to_jalali(gy, gm, gd)
    local out = string.format("%04d/%02d/%02d", jy, jm, jd)
    if with_time then
        local secs_in_day = local_time % 86400
        out = out .. string.format(" %02d:%02d", floor_div(secs_in_day, 3600), floor_div(secs_in_day % 3600, 60))
    end
    return out
end

-- "1405/06/12" -> FILETIME ابتدای روز (UTC)؛ nil اگر نامعتبر
local function jalali_string_to_filetime(s)
    if s == nil then return nil end
    local jy, jm, jd = tostring(s):match("^%s*(%d%d%d%d)[/%-](%d%d?)[/%-](%d%d?)%s*$")
    if jy == nil then return nil end
    jy, jm, jd = tonumber(jy), tonumber(jm), tonumber(jd)
    if jm < 1 or jm > 12 or jd < 1 or jd > 31 then return nil end
    local gy, gm, gd = jalali_to_gregorian(jy, jm, jd)
    local days = days_from_civil(gy, gm, gd)
    return (days * 86400 + EPOCH_DIFF_SECONDS) * TICKS_PER_SECOND
end

local function now_filetime()
    return (os.time() + EPOCH_DIFF_SECONDS) * TICKS_PER_SECOND
end

-- =========================================
-- DB HELPERS
-- =========================================
local function fetch_rows(query, params)
    pcall(function() db.use_db(CONFIG.DB_SCHEMA) end)
    local ok, err = pcall(function()
        db.query({ query = query, params = params or {} })
    end)
    if not ok then
        teamyar.write_log("crm_customer_ui SQL error: " .. tostring(err) .. " | query: " .. query:sub(1, 400))
        return nil, err
    end
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

local function fetch_row(query, params)
    local rows, err = fetch_rows(query, params)
    if rows == nil then return nil, err end
    return rows[1]
end

local function fetch_scalar(query, params)
    local row, err = fetch_row(query, params)
    if row == nil then return nil, err end
    return row[1]
end

local function id_list_sql(ids)
    -- ids همیشه از خروجی DB (bigint) یا tonumber() می‌آیند — هرگز رشتهٔ خام کاربر
    local clean = {}
    for _, v in ipairs(ids or {}) do
        local n = to_int(v)
        if n ~= nil then table.insert(clean, tostring(n)) end
    end
    if #clean == 0 then return "(NULL)" end
    return "(" .. table.concat(clean, ",") .. ")"
end

-- =========================================
-- INPUT + CURRENT USER
-- =========================================
local input = teamyar.get_input() or {}
local function inp(name) return scalar_input(input[name]) end

local action = trim(inp("action") or inp("cu_action") or "")

local permissions_summary -- تعریف در بخش ACCESS CONTROL (پایین‌تر)؛ اعلان پیشین چون action_tree زودتر آن را صدا می‌زند
local current_user_id = 0
do
    local ok, uinfo = pcall(function() return teamyar.get_user_info() end)
    if ok and _G.type(uinfo) == "table" then
        current_user_id = to_int(uinfo.id) or 0
    end
end

-- =========================================
-- NATIVE ROUTE BUILDERS (لینک به صفحات خود پرتال)
-- =========================================
local function portal_page(path)
    return CONFIG.BASE_URL .. "/?page=" .. path
end

local ROUTES = {
    -- پارامترهای section/tab در URL پرتال هم‌سطح page هستند (?page=/crm/...&section=2)، نه داخل مسیر
    client_edit  = function(id, tab) return portal_page("/crm/client/edit/" .. id .. (tab and (AMP .. "tab=" .. tab) or "")) end,
    history      = function(action_name, id, section) return portal_page("/crm/history/" .. action_name .. "/" .. id .. AMP .. "section=" .. (section or "2")) end,
    invoice_view = function(id) return portal_page("/sales/invoice/view_invoice/" .. id) end,
    todo_report  = function(id) return portal_page("/todo/report/" .. id) end,
    email_view   = function(id) return portal_page("/email/message/edit/" .. id) end,
    chat_view    = function(id) return portal_page("/chat/dialog/" .. id) end,
    poll_view    = function(id) return portal_page("/poll/index/questionnaire/view/" .. id) end,
    project_view = function(id) return portal_page("/project/view" .. AMP .. "project_id=" .. id) end,
    comment_file = function(client_id, file_id)
        return CONFIG.BASE_URL .. "/crm/history/comment/show_file/?client_id=" .. client_id .. AMP .. "file_id=" .. file_id
    end,
    list_native  = function(category) return portal_page("/crm/index/all/" .. (category and (AMP .. "category=" .. category) or "")) end,
}

-- =========================================
-- USER TYPE / STATUS LABELS
-- =========================================
local USER_TYPE_LABELS = { [3] = "حقیقی", [4] = "حقوقی" }
local function user_type_label(v)
    local n = to_int(v)
    if n == nil then return "—" end
    return USER_TYPE_LABELS[n] or ("نوع " .. tostring(n))
end

local SEX_LABELS = { [1] = "مرد", [2] = "زن" }
local PHONE_TYPE_LABELS = { [2] = "تلفن منزل", [3] = "تلفن محل کار", [4] = "فکس" }
local INVOICE_TYPE_LABELS = { [1] = "فاکتور فروش", [3] = "برگشت از فروش", [5] = "پیش‌فاکتور" }
local TODO_STATUS_LABELS = { [0] = "باز", [1] = "در حال انجام", [2] = "بسته شده", [3] = "موکول شده" }
local SMS_DIRECTION_LABELS = { [0] = "ارسالی", [1] = "دریافتی" }

-- =========================================
-- LIST: WHERE BUILDER
-- =========================================
local SCOPE_SQL = {
    all         = "",
    person      = " AND ui.USER_TYPE = 3",
    business    = " AND ui.USER_TYPE = 4",
    favorite    = " AND EXISTS (SELECT 1 FROM crm_favorite f WHERE f.CLIENT_ID = ci.ID AND f.USER_ID = ? AND f.FLAG = 1)",
    assign      = " AND EXISTS (SELECT 1 FROM crm_notify n WHERE n.CLIENT_ID = ci.ID AND n.USER_ID = ?)",
    events      = " AND EXISTS (SELECT 1 FROM cal_invite_user ciu WHERE ciu.USER_ID = ci.ID)",
    unconfirmed = " AND COALESCE(ci.CONFIRM, 0) = 0",
    nocat       = " AND NOT EXISTS (SELECT 1 FROM crm_cross x0 WHERE x0.CLIENT_ID = ci.ID)",
    trash       = "",
}
local SCOPES_WITH_USER = { favorite = true, assign = true }

-- فیلدهای فیلتر پیشرفته — سفیدلیست کامل؛ هر فیلد یا یک ستون مستقیم دارد یا یک EXISTS الگودار
local ADV_FIELDS = {
    name          = { kind = "text",   col = "pm.FULLNAME" },
    company       = { kind = "text",   col = "ci.COMPANY" },
    job           = { kind = "text",   col = "ci.JOB" },
    tin           = { kind = "text",   col = "ci.TIN" },
    kpp           = { kind = "text",   col = "ci.KPP" },
    comment       = { kind = "text",   col = "ci.COMMENT" },
    lable         = { kind = "text",   col = "ci.LABLE" },
    website       = { kind = "text",   col = "ci.WEBSAITE" },
    reg_number    = { kind = "text",   col = "ci.REG_NUMBER" },
    industry      = { kind = "text",   col = "ci.INDUSTRY" },
    mobile        = { kind = "exists", sql = "SELECT 1 FROM profile_mobile m WHERE m.USER_ID = ci.ID AND m.MOBILE %s" },
    email         = { kind = "exists", sql = "SELECT 1 FROM profile_email e WHERE e.USER_ID = ci.ID AND e.EMAIL %s" },
    national_code = { kind = "exists", sql = "SELECT 1 FROM profile_nationalcode nc WHERE nc.USER_ID = ci.ID AND nc.NATIONAL_CODE %s" },
    phone         = { kind = "exists", sql = "SELECT 1 FROM profile_phone ph WHERE ph.USER_ID = ci.ID AND ph.PHONE %s" },
    city          = { kind = "exists", sql = "SELECT 1 FROM profile_user_address a WHERE a.USER_ID = ci.ID AND a.TYPE = 1 AND a.CITY %s" },
    state         = { kind = "exists", sql = "SELECT 1 FROM profile_user_address a WHERE a.USER_ID = ci.ID AND a.TYPE = 1 AND a.STATE %s" },
    address       = { kind = "exists", sql = "SELECT 1 FROM profile_user_address a WHERE a.USER_ID = ci.ID AND a.TYPE = 1 AND a.ADDRESS %s" },
    zip_code      = { kind = "exists", sql = "SELECT 1 FROM profile_user_address a WHERE a.USER_ID = ci.ID AND a.TYPE = 1 AND a.POSTAL_CODE %s" },
    author        = { kind = "exists", sql = "SELECT 1 FROM profile_main au WHERE au.ID = ci.AUTHOR_ID AND au.FULLNAME %s" },
    create_date   = { kind = "date",   col = "ci.CREATE_DATE" },
    modified_date = { kind = "date",   col = "ci.MODIFIED_DATE" },
    birth_date    = { kind = "date",   col = "ui.BIRTHDAY" },
    type          = { kind = "number", col = "ui.USER_TYPE" },
    gender        = { kind = "number", col = "ui.SEX" },
    confirm       = { kind = "number", col = "COALESCE(ci.CONFIRM, 0)" },
    category      = { kind = "member", sql = "SELECT 1 FROM crm_cross x1 WHERE x1.CLIENT_ID = ci.ID AND x1.REFERE_ID = ?" },
    has_sales     = { kind = "flag",   sql = "EXISTS (SELECT 1 FROM sales_invoice si JOIN pa_client pc ON pc.ID = si.CLIENT_ID WHERE pc.REFFERE_ID = ci.ID AND si.DELETED = 0)" },
    has_events    = { kind = "flag",   sql = "EXISTS (SELECT 1 FROM cal_invite_user ciu WHERE ciu.USER_ID = ci.ID)" },
    has_todo      = { kind = "flag",   sql = "EXISTS (SELECT 1 FROM crm_ty_links lk WHERE lk.SRC_MODULE_ID = 14 AND lk.DST_MODULE_ID = 8 AND lk.SRC_LINK_ID = ci.ID)" },
    is_favorite   = { kind = "flag",   sql = "EXISTS (SELECT 1 FROM crm_favorite f WHERE f.CLIENT_ID = ci.ID AND f.USER_ID = " .. tostring(current_user_id) .. " AND f.FLAG = 1)" },
    is_notified   = { kind = "flag",   sql = "EXISTS (SELECT 1 FROM crm_notify n WHERE n.CLIENT_ID = ci.ID AND n.USER_ID = " .. tostring(current_user_id) .. ")" },
}

-- یک شرط فیلتر پیشرفته -> (sql, params). nil اگر شرط نامعتبر باشد (بی‌صدا نادیده نمی‌گیریم: به کلاینت برمی‌گردد)
local function build_adv_condition(cond)
    local def = ADV_FIELDS[tostring(cond.field or "")]
    if def == nil then return nil, "فیلد فیلتر نامعتبر: " .. tostring(cond.field) end
    local op = tostring(cond.op or "eq")
    local raw_value = cond.value
    local value = trim(raw_value)
    local params = {}

    if def.kind == "flag" then
        if op == "neq" or op == "empty" then return "NOT " .. def.sql, params end
        return def.sql, params
    end

    if def.kind == "member" then
        local cat = to_positive_int(value)
        if cat == nil then return nil, "رده انتخاب نشده است" end
        table.insert(params, cat)
        if op == "neq" then return "NOT EXISTS (" .. def.sql .. ")", params end
        return "EXISTS (" .. def.sql .. ")", params
    end

    if def.kind == "number" then
        if op == "empty" then return "(" .. def.col .. " IS NULL OR " .. def.col .. " = 0)", params end
        if op == "not_empty" then return "(" .. def.col .. " IS NOT NULL AND " .. def.col .. " <> 0)", params end
        local n = to_int(value)
        if n == nil then return nil, "مقدار عددی نامعتبر" end
        table.insert(params, n)
        if op == "neq" then return def.col .. " <> ?", params end
        if op == "gt" then return def.col .. " > ?", params end
        if op == "lt" then return def.col .. " < ?", params end
        return def.col .. " = ?", params
    end

    if def.kind == "date" then
        if op == "empty" then return "(" .. def.col .. " IS NULL OR " .. def.col .. " = 0)", params end
        if op == "not_empty" then return "(" .. def.col .. " IS NOT NULL AND " .. def.col .. " <> 0)", params end
        if op == "last_days" or op == "before_days" then
            local days = to_positive_int(value)
            if days == nil then return nil, "تعداد روز نامعتبر" end
            local threshold = now_filetime() - days * DAY_TICKS
            table.insert(params, threshold)
            if op == "last_days" then return def.col .. " >= ?", params end
            return "(" .. def.col .. " > 0 AND " .. def.col .. " < ?)", params
        end
        local ft = jalali_string_to_filetime(value)
        if ft == nil then return nil, "تاریخ نامعتبر (قالب 1405/06/12)" end
        if op == "gt" or op == "gte" then table.insert(params, ft); return def.col .. " >= ?", params end
        if op == "lt" or op == "lte" then table.insert(params, ft + DAY_TICKS); return def.col .. " < ?", params end
        if op == "neq" then
            table.insert(params, ft); table.insert(params, ft + DAY_TICKS)
            return "NOT (" .. def.col .. " >= ? AND " .. def.col .. " < ?)", params
        end
        table.insert(params, ft); table.insert(params, ft + DAY_TICKS)
        return "(" .. def.col .. " >= ? AND " .. def.col .. " < ?)", params
    end

    -- text / exists
    local literal = sanitize_like_literal(value)
    local expr
    if op == "empty" then
        expr = def.kind == "text" and ("(" .. def.col .. " IS NULL OR " .. def.col .. " = '')") or nil
        if def.kind == "exists" then
            expr = "NOT EXISTS (" .. string.format(def.sql, "<> ''") .. ")"
        end
        return expr, params
    elseif op == "not_empty" then
        if def.kind == "text" then return "(" .. def.col .. " IS NOT NULL AND " .. def.col .. " <> '')", params end
        return "EXISTS (" .. string.format(def.sql, "<> ''") .. ")", params
    end
    if literal == "" then return nil, "مقدار فیلتر خالی است" end
    local comparator
    if op == "eq" then
        table.insert(params, value); comparator = "= ?"
    elseif op == "neq" then
        table.insert(params, value); comparator = "<> ?"
    elseif op == "not_contains" then
        comparator = "NOT LIKE '%" .. literal .. "%'"
    elseif op == "starts" then
        comparator = "LIKE '" .. literal .. "%'"
    else -- contains (default)
        comparator = "LIKE '%" .. literal .. "%'"
    end
    if def.kind == "text" then
        return "COALESCE(" .. def.col .. ",'') " .. comparator, params
    end
    return "EXISTS (" .. string.format(def.sql, comparator) .. ")", params
end

local function decode_adv(adv_json)
    if adv_json == nil or trim(adv_json) == "" then return {} end
    local ok, decoded = pcall(function() return json.decode(adv_json) end)
    if not ok or _G.type(decoded) ~= "table" then return {} end
    local out = {}
    for _, c in ipairs(decoded) do
        if _G.type(c) == "table" then table.insert(out, c) end
    end
    return out
end

local function build_list_where(opts)
    local where = { "1=1" }
    local params = {}
    local warnings = {}

    if opts.scope == "trash" then
        table.insert(where, "ci.DELETED = 1")
    else
        table.insert(where, "ci.DELETED = 0")
    end

    local scope_sql = SCOPE_SQL[opts.scope]
    if scope_sql ~= nil and scope_sql ~= "" then
        table.insert(where, scope_sql:sub(6)) -- بدون " AND " ابتدایی
        if SCOPES_WITH_USER[opts.scope] then table.insert(params, current_user_id) end
    end

    if opts.category_id ~= nil then
        table.insert(where, "EXISTS (SELECT 1 FROM crm_cross xc WHERE xc.CLIENT_ID = ci.ID AND xc.REFERE_ID = ?)")
        table.insert(params, opts.category_id)
    elseif opts.section_id ~= nil then
        table.insert(where, "EXISTS (SELECT 1 FROM crm_cross xs JOIN crm_classify_person cs ON cs.PROFILE_ID = xs.REFERE_ID WHERE xs.CLIENT_ID = ci.ID AND cs.section_id = ?)")
        table.insert(params, opts.section_id)
    end

    local q = trim(opts.q or "")
    if q ~= "" then
        if is_all_digits(q) then
            local n = tonumber(q)
            local parts = { "ci.ID = ?" }
            table.insert(params, n)
            if #q >= 7 then
                table.insert(parts, "EXISTS (SELECT 1 FROM profile_mobile qm WHERE qm.USER_ID = ci.ID AND RIGHT(qm.MOBILE, 10) = RIGHT(?, 10))")
                table.insert(params, q)
                table.insert(parts, "EXISTS (SELECT 1 FROM profile_phone qp WHERE qp.USER_ID = ci.ID AND RIGHT(qp.PHONE, 8) = RIGHT(?, 8))")
                table.insert(params, q)
            end
            table.insert(parts, "EXISTS (SELECT 1 FROM profile_nationalcode qn WHERE qn.USER_ID = ci.ID AND qn.NATIONAL_CODE = ?)")
            table.insert(params, q)
            table.insert(where, "(" .. table.concat(parts, " OR ") .. ")")
        else
            local literal = sanitize_like_literal(q)
            if literal ~= "" then
                local parts = { "pm.FULLNAME LIKE '%" .. literal .. "%'", "COALESCE(ci.COMPANY,'') LIKE '%" .. literal .. "%'" }
                if q:find("@", 1, true) then
                    table.insert(parts, "EXISTS (SELECT 1 FROM profile_email qe WHERE qe.USER_ID = ci.ID AND qe.EMAIL LIKE '%" .. literal .. "%')")
                end
                table.insert(where, "(" .. table.concat(parts, " OR ") .. ")")
            end
        end
    end

    for _, cond in ipairs(opts.adv or {}) do
        local sql, extra_or_err = build_adv_condition(cond)
        if sql == nil then
            table.insert(warnings, tostring(extra_or_err))
        else
            table.insert(where, sql)
            for _, p in ipairs(extra_or_err) do table.insert(params, p) end
        end
    end

    return table.concat(where, " AND "), params, warnings
end

-- سورت سروری فقط روی ستون‌های مستقیم جدول‌های اصلی؛ سورت روی ستون‌های محاسبه‌ای (زیرکوئری) روی ۸۱هزار ردیف
-- عملاً به Timeout می‌خورد (تست زنده ۱۴۰۵/۰۶/۱۲: sort=balance بیش از ۲ دقیقه) — آن ستون‌ها در کلاینت روی صفحهٔ جاری سورت می‌شوند.
local SORT_COLUMNS = {
    id = "ci.ID", name = "pm.FULLNAME", type = "ui.USER_TYPE", gender = "ui.SEX", created = "ci.CREATE_DATE",
    modified = "ci.MODIFIED_DATE", confirm = "ci.CONFIRM", company = "ci.COMPANY", job = "ci.JOB", tin = "ci.TIN",
    kpp = "ci.KPP", reg_number = "ci.REG_NUMBER", industry = "ci.INDUSTRY", website = "ci.WEBSAITE", lable = "ci.LABLE",
    birthday = "ui.BIRTHDAY", number_personnel = "ci.NUMBER_PERSONNEL",
}

local LIST_SELECT = [[
SELECT ci.ID, pm.FULLNAME, ui.USER_TYPE, ui.SEX, ci.CREATE_DATE, ci.MODIFIED_DATE, ci.AUTHOR_ID,
       (SELECT au.FULLNAME FROM profile_main au WHERE au.ID = ci.AUTHOR_ID) AS author_name,
       COALESCE(ci.CONFIRM, 0) AS confirm_flag, ci.COMMENT, ci.COMPANY, ci.JOB, ci.TIN,
       (SELECT m.MOBILE FROM profile_mobile m WHERE m.USER_ID = ci.ID ORDER BY m.ID ASC LIMIT 1) AS mobile,
       (SELECT e.EMAIL FROM profile_email e WHERE e.USER_ID = ci.ID ORDER BY e.ID ASC LIMIT 1) AS email,
       (SELECT n.NATIONAL_CODE FROM profile_nationalcode n WHERE n.USER_ID = ci.ID ORDER BY n.ID ASC LIMIT 1) AS national_code,
       (SELECT a.STATE FROM profile_user_address a WHERE a.USER_ID = ci.ID AND a.TYPE = 1 LIMIT 1) AS state,
       (SELECT a.CITY FROM profile_user_address a WHERE a.USER_ID = ci.ID AND a.TYPE = 1 LIMIT 1) AS city,
       (SELECT a.ADDRESS FROM profile_user_address a WHERE a.USER_ID = ci.ID AND a.TYPE = 1 LIMIT 1) AS address,
       (SELECT a.POSTAL_CODE FROM profile_user_address a WHERE a.USER_ID = ci.ID AND a.TYPE = 1 LIMIT 1) AS zip_code,
       (SELECT GROUP_CONCAT(CONCAT(s.SECTION_NAME, '/', c.name) SEPARATOR '، ')
          FROM crm_cross x JOIN crm_classify_person c ON c.PROFILE_ID = x.REFERE_ID JOIN crm_section s ON s.ID = c.section_id
         WHERE x.CLIENT_ID = ci.ID) AS classify,
       EXISTS (SELECT 1 FROM crm_favorite f WHERE f.CLIENT_ID = ci.ID AND f.USER_ID = ? AND f.FLAG = 1) AS is_fav,
       EXISTS (SELECT 1 FROM crm_notify nn WHERE nn.CLIENT_ID = ci.ID AND nn.USER_ID = ?) AS is_notified,
       (SELECT COUNT(*) FROM crm_notify n2 WHERE n2.CLIENT_ID = ci.ID) AS notify_count,
       ci.DELETED]]

-- ستون‌های اضافی (فیلدهای جزئیات مشتری) فقط وقتی محاسبه می‌شوند که کاربر آن‌ها را انتخاب کرده باشد (پارامتر cols)؛
-- محاسبهٔ همهٔ آن‌ها برای هر صفحه، زمان لیست را از ~۱ ثانیه به ۵+ ثانیه می‌رساند (تست زنده ۱۴۰۵/۰۶/۱۲).
local EXTRA_COLUMNS = {
    birthday         = { sql = "ui.BIRTHDAY", fmt = "date" },
    patronymic       = { sql = "ui.PATRONYMIC" },
    birthplace       = { sql = "ui.BIRTHPLACE" },
    identity_no      = { sql = "ui.identity_no" },
    nationality      = { sql = "ui.nationality" },
    passport_no      = { sql = "ui.passport_no" },
    kpp              = { sql = "ci.KPP" },
    reg_number       = { sql = "ci.REG_NUMBER" },
    industry         = { sql = "ci.INDUSTRY" },
    number_personnel = { sql = "ci.NUMBER_PERSONNEL" },
    personality_type = { sql = "ci.PERSONALITY_TYPE" },
    website          = { sql = "ci.WEBSAITE" },
    lable            = { sql = "ci.LABLE" },
    issue_activity   = { sql = "ci.ISSUE_ACTIVITY" },
    property_code    = { sql = "ci.PROPERTY_CODE" },
    mobiles_all      = { sql = "(SELECT GROUP_CONCAT(m2.MOBILE SEPARATOR '، ') FROM profile_mobile m2 WHERE m2.USER_ID = ci.ID)" },
    emails_all       = { sql = "(SELECT GROUP_CONCAT(e2.EMAIL SEPARATOR '، ') FROM profile_email e2 WHERE e2.USER_ID = ci.ID)" },
    work_phone       = { sql = "(SELECT p3.PHONE FROM profile_phone p3 WHERE p3.USER_ID = ci.ID AND p3.TYPE = 3 ORDER BY p3.ID LIMIT 1)" },
    home_phone       = { sql = "(SELECT p2.PHONE FROM profile_phone p2 WHERE p2.USER_ID = ci.ID AND p2.TYPE = 2 ORDER BY p2.ID LIMIT 1)" },
    fax              = { sql = "(SELECT p4.PHONE FROM profile_phone p4 WHERE p4.USER_ID = ci.ID AND p4.TYPE = 4 ORDER BY p4.ID LIMIT 1)" },
    balance          = { sql = "(SELECT SUM(pc.BALANCE) FROM pa_client pc WHERE pc.REFFERE_ID = ci.ID AND (pc.DELETED IS NULL OR pc.DELETED = 0))", fmt = "money" },
    account_code     = { sql = "(SELECT GROUP_CONCAT(pc2.ACCOUNT_CODE SEPARATOR '، ') FROM pa_client pc2 WHERE pc2.REFFERE_ID = ci.ID AND (pc2.DELETED IS NULL OR pc2.DELETED = 0))" },
    sales_count      = { sql = "(SELECT COUNT(*) FROM sales_invoice s JOIN pa_client pc3 ON pc3.ID = s.CLIENT_ID WHERE pc3.REFFERE_ID = ci.ID AND s.DELETED = 0)", fmt = "int" },
    last_invoice     = { sql = "(SELECT MAX(s2.RUN_DATE) FROM sales_invoice s2 JOIN pa_client pc4 ON pc4.ID = s2.CLIENT_ID WHERE pc4.REFFERE_ID = ci.ID AND s2.DELETED = 0 AND s2.CANCELED = 0)", fmt = "date" },
    last_comment     = { sql = "(SELECT h.NOTE FROM crm_history h WHERE h.CLIENT_ID = ci.ID AND h.TYPE = 1 AND COALESCE(h.NOTE,'') <> '' AND h.NOTE NOT LIKE '<%' ORDER BY h.ID DESC LIMIT 1)" },
    modifier         = { sql = "(SELECT mo.FULLNAME FROM profile_main mo WHERE mo.ID = ci.MODIFIER)" },
    contacts_count   = { sql = "(SELECT COUNT(*) FROM crm_contacts cc WHERE cc.CLIENT_ID = ci.ID)", fmt = "int" },
    events_count     = { sql = "(SELECT COUNT(*) FROM cal_invite_user ciu WHERE ciu.USER_ID = ci.ID)", fmt = "int" },
    todo_count       = { sql = "(SELECT COUNT(*) FROM crm_ty_links l JOIN todo_task t ON t.ID = l.DST_LINK_ID WHERE l.SRC_MODULE_ID = 14 AND l.DST_MODULE_ID = 8 AND l.SRC_LINK_ID = ci.ID)", fmt = "int" },
    has_folder       = { sql = "(COALESCE(ci.FOLDER_ID, 0) > 0)", fmt = "bool" },
    phone            = { sql = "(SELECT p5.PHONE FROM profile_phone p5 WHERE p5.USER_ID = ci.ID ORDER BY p5.ID LIMIT 1)" },
}
local BASE_COLUMN_COUNT = 25

-- پارامتر cols: فهرست کاماجدای کلیدهای EXTRA_COLUMNS؛ کلید ناشناخته نادیده گرفته می‌شود (سفیدلیست)
local function parse_extra_cols(raw)
    local keys = {}
    for key in tostring(raw or ""):gmatch("[%w_]+") do
        if EXTRA_COLUMNS[key] ~= nil then table.insert(keys, key) end
    end
    return keys
end

local function extra_select_sql(keys)
    local parts = {}
    for _, key in ipairs(keys) do table.insert(parts, ", " .. EXTRA_COLUMNS[key].sql .. " AS x_" .. key) end
    return table.concat(parts)
end

local function format_extra(fmt, value)
    if fmt == "date" then return nz(fmt_jalali_from_filetime(value), "") end
    if fmt == "money" then return fmt_num(value) end
    if fmt == "int" then return to_int(value) or 0 end
    if fmt == "bool" then return to_int(value) == 1 end
    return nz(value, "")
end

local LIST_FROM = [[

FROM crm_info ci
INNER JOIN profile_main pm ON pm.ID = ci.ID
LEFT JOIN profile_user_info ui ON ui.ID = ci.ID
WHERE ]]

local function map_list_row(r)
    return {
        id            = tostring(r[1]),
        name          = nz(r[2], "—"),
        type          = to_int(r[3]),
        type_label    = user_type_label(r[3]),
        gender        = SEX_LABELS[to_int(r[4]) or 0] or "",
        created       = nz(fmt_jalali_from_filetime(r[5], true), ""),
        modified      = nz(fmt_jalali_from_filetime(r[6], true), ""),
        author_id     = tostring(r[7] or ""),
        author        = nz(r[8], ""),
        confirm       = to_int(r[9]) == 1,
        comment       = nz(r[10], ""),
        company       = nz(r[11], ""),
        job           = nz(r[12], ""),
        tin           = nz(r[13], ""),
        mobile        = nz(r[14], ""),
        email         = nz(r[15], ""),
        national_code = nz(r[16], ""),
        state         = nz(r[17], ""),
        city          = nz(r[18], ""),
        address       = nz(r[19], ""),
        zip_code      = nz(r[20], ""),
        classify      = nz(r[21], ""),
        is_fav        = to_int(r[22]) == 1,
        is_notified   = to_int(r[23]) == 1,
        notify_count  = to_int(r[24]) or 0,
        deleted       = to_int(r[25]) == 1,
    }
end

-- ستون‌های اضافی انتخاب‌شده (به ترتیب keys، بعد از BASE_COLUMN_COUNT ستون پایه)
local function map_extra_columns(row, r, keys)
    for i, key in ipairs(keys) do
        local def = EXTRA_COLUMNS[key]
        row[key] = format_extra(def.fmt, r[BASE_COLUMN_COUNT + i])
        if key == "balance" then row.balance_fmt = row[key]; row.balance = tonumber(r[BASE_COLUMN_COUNT + i]) or 0 end
    end
    return row
end

local function action_list()
    local scope = trim(inp("scope") or "all")
    if SCOPE_SQL[scope] == nil then scope = "all" end
    local page = to_positive_int(inp("page")) or 1
    local per_page = to_positive_int(inp("per_page")) or CONFIG.PAGE_SIZE
    if per_page > CONFIG.MAX_PAGE_SIZE then per_page = CONFIG.MAX_PAGE_SIZE end
    local sort_key = trim(inp("sort") or "id")
    local sort_col = SORT_COLUMNS[sort_key] or "ci.ID"
    local dir = trim(inp("dir") or "desc"):lower() == "asc" and "ASC" or "DESC"

    local where, params, warnings = build_list_where({
        scope = scope,
        section_id = to_positive_int(inp("section_id")),
        category_id = to_positive_int(inp("category_id")),
        q = inp("q"),
        adv = decode_adv(inp("adv")),
    })

    local total, count_err = fetch_scalar("SELECT COUNT(*) FROM crm_info ci INNER JOIN profile_main pm ON pm.ID = ci.ID LEFT JOIN profile_user_info ui ON ui.ID = ci.ID WHERE " .. where, params)
    if total == nil then return { ok = false, error = "خطا در شمارش مشتریان: " .. tostring(count_err) } end

    local list_params = { current_user_id, current_user_id }
    for _, p in ipairs(params) do table.insert(list_params, p) end
    table.insert(list_params, per_page)
    table.insert(list_params, (page - 1) * per_page)

    local extra_keys = parse_extra_cols(inp("cols"))
    local rows, err = fetch_rows(LIST_SELECT .. extra_select_sql(extra_keys) .. LIST_FROM .. where .. " ORDER BY " .. sort_col .. " " .. dir .. ", ci.ID DESC LIMIT ? OFFSET ?", list_params)
    if rows == nil then return { ok = false, error = "خطا در دریافت لیست مشتریان: " .. tostring(err) } end

    local out = {}
    for _, r in ipairs(rows) do table.insert(out, map_extra_columns(map_list_row(r), r, extra_keys)) end
    local result = {
        ok = true, rows = out, total = tonumber(total) or 0, page = page, per_page = per_page,
        scope = scope, sort = sort_key, dir = dir:lower(), warnings = warnings,
    }
    if inp("debug") == "1" then
        -- عیب‌یابی: متن WHERE و پارامترها (بدون دادهٔ حساس)
        result.debug = { where = where, params = params, q_raw = inp("q"), q_bytes = #tostring(inp("q") or "") }
    end
    return result
end

-- خروجی Excel: همان فیلترها، بدون صفحه‌بندی (تا سقف EXPORT_MAX_ROWS)
local function action_export()
    local scope = trim(inp("scope") or "all")
    if SCOPE_SQL[scope] == nil then scope = "all" end
    local where, params = build_list_where({
        scope = scope,
        section_id = to_positive_int(inp("section_id")),
        category_id = to_positive_int(inp("category_id")),
        q = inp("q"),
        adv = decode_adv(inp("adv")),
    })
    local list_params = { current_user_id, current_user_id }
    for _, p in ipairs(params) do table.insert(list_params, p) end
    table.insert(list_params, CONFIG.EXPORT_MAX_ROWS)
    local extra_keys = parse_extra_cols(inp("cols"))
    local rows, err = fetch_rows(LIST_SELECT .. extra_select_sql(extra_keys) .. LIST_FROM .. where .. " ORDER BY ci.ID DESC LIMIT ?", list_params)
    if rows == nil then return { ok = false, error = "خطا در خروجی: " .. tostring(err) } end
    local out = {}
    for _, r in ipairs(rows) do table.insert(out, map_extra_columns(map_list_row(r), r, extra_keys)) end
    return { ok = true, rows = out, truncated = (#rows >= CONFIG.EXPORT_MAX_ROWS), max_rows = CONFIG.EXPORT_MAX_ROWS }
end

-- =========================================
-- TREE: بخش‌ها و رده‌ها با شمارش
-- =========================================
local function action_tree()
    local rows, err = fetch_rows([[
SELECT c.PROFILE_ID, c.name, c.section_id, s.SECTION_NAME, s.S_ORDER, c.sort_id, c.TYPE, c.DEFULT,
       (SELECT COUNT(*) FROM crm_cross x JOIN crm_info i ON i.ID = x.CLIENT_ID AND i.DELETED = 0 WHERE x.REFERE_ID = c.PROFILE_ID) AS members
FROM crm_classify_person c
INNER JOIN crm_section s ON s.ID = c.section_id
ORDER BY s.S_ORDER, s.ID, c.sort_id, c.ID]], {})
    if rows == nil then return { ok = false, error = "خطا در دریافت درخت رده‌ها: " .. tostring(err) } end

    local totals = fetch_row([[
SELECT (SELECT COUNT(*) FROM crm_info WHERE DELETED = 0),
       (SELECT COUNT(*) FROM crm_info ci WHERE ci.DELETED = 0 AND NOT EXISTS (SELECT 1 FROM crm_cross x WHERE x.CLIENT_ID = ci.ID)),
       (SELECT COUNT(*) FROM crm_info WHERE DELETED = 1),
       (SELECT COUNT(*) FROM crm_info WHERE DELETED = 0 AND COALESCE(CONFIRM,0) = 0),
       (SELECT COUNT(*) FROM crm_favorite f JOIN crm_info i ON i.ID = f.CLIENT_ID AND i.DELETED = 0 WHERE f.USER_ID = ? AND f.FLAG = 1),
       (SELECT COUNT(*) FROM crm_notify n JOIN crm_info i ON i.ID = n.CLIENT_ID AND i.DELETED = 0 WHERE n.USER_ID = ?),
       (SELECT COUNT(*) FROM crm_info ci JOIN profile_user_info ui ON ui.ID = ci.ID WHERE ci.DELETED = 0 AND ui.USER_TYPE = 3),
       (SELECT COUNT(*) FROM crm_info ci JOIN profile_user_info ui ON ui.ID = ci.ID WHERE ci.DELETED = 0 AND ui.USER_TYPE = 4)]],
        { current_user_id, current_user_id }) or {}

    local sections, by_id = {}, {}
    for _, r in ipairs(rows) do
        local sid = tostring(r[3])
        if by_id[sid] == nil then
            by_id[sid] = { id = to_int(r[3]), name = nz(r[4], "—"), categories = {}, members = 0 }
            table.insert(sections, by_id[sid])
        end
        local members = to_int(r[9]) or 0
        table.insert(by_id[sid].categories, {
            id = to_int(r[1]), name = nz(r[2], "—"), members = members,
            is_default = to_int(r[8]) == 1, type = to_int(r[7]) or 0,
        })
        by_id[sid].members = by_id[sid].members + members
    end

    return {
        ok = true, sections = sections,
        totals = {
            all = tonumber(totals[1]) or 0, nocat = tonumber(totals[2]) or 0, trash = tonumber(totals[3]) or 0,
            unconfirmed = tonumber(totals[4]) or 0, favorite = tonumber(totals[5]) or 0, assign = tonumber(totals[6]) or 0,
            person = tonumber(totals[7]) or 0, business = tonumber(totals[8]) or 0,
        },
        current_user_id = current_user_id,
        perms = permissions_summary(),
    }
end

-- =========================================
-- CLIENT PROFILE
-- =========================================
local function resolve_pa_client_ids(client_id)
    local rows = fetch_rows("SELECT ID FROM pa_client WHERE REFFERE_ID = ? AND (DELETED IS NULL OR DELETED = 0)", { client_id }) or {}
    local ids = {}
    for _, r in ipairs(rows) do table.insert(ids, to_int(r[1])) end
    return ids
end

local function rows_to_objects(rows, mapper)
    local out = {}
    for _, r in ipairs(rows or {}) do table.insert(out, mapper(r)) end
    return out
end

local function load_client(client_id)
    local base = fetch_row([[
SELECT ci.ID, pm.FULLNAME, ui.NAME, ui.SURNAME, ui.USER_TYPE, ui.SEX, ui.BIRTHDAY, ui.PATRONYMIC, ui.BIRTHPLACE,
       ui.identity_no, ui.identity_serial_no, ui.nationality, ui.passport_no, ui.PLACEOFISSUE, ui.dateofissue,
       ci.DELETED, COALESCE(ci.CONFIRM,0), ci.CREATE_DATE, ci.MODIFIED_DATE, ci.AUTHOR_ID,
       (SELECT au.FULLNAME FROM profile_main au WHERE au.ID = ci.AUTHOR_ID),
       ci.MODIFIER, (SELECT mo.FULLNAME FROM profile_main mo WHERE mo.ID = ci.MODIFIER),
       ci.COMMENT, ci.COMPANY, ci.JOB, ci.TIN, ci.KPP, ci.REG_NUMBER, ci.INDUSTRY, ci.NUMBER_PERSONNEL,
       ci.PERSONALITY_TYPE, ci.WEBSAITE, ci.LABLE, ci.ISSUE_ACTIVITY, ci.PROPERTY_CODE, ci.PROPERTY_DATE,
       ci.state_code, ci.city_code, ci.FOLDER_ID, ci.IMPORT_ID, ci.DOMAIN, ci.LANGUAGE, ci.ACCOUNT,
       EXISTS (SELECT 1 FROM crm_favorite f WHERE f.CLIENT_ID = ci.ID AND f.USER_ID = ? AND f.FLAG = 1),
       EXISTS (SELECT 1 FROM crm_notify n WHERE n.CLIENT_ID = ci.ID AND n.USER_ID = ?)
FROM crm_info ci
INNER JOIN profile_main pm ON pm.ID = ci.ID
LEFT JOIN profile_user_info ui ON ui.ID = ci.ID
WHERE ci.ID = ?]], { current_user_id, current_user_id, client_id })
    if base == nil then return nil end

    local client = {
        id = tostring(base[1]), full_name = nz(base[2], "—"), name = nz(base[3], ""), surname = nz(base[4], ""),
        type = to_int(base[5]), type_label = user_type_label(base[5]), gender = to_int(base[6]),
        gender_label = SEX_LABELS[to_int(base[6]) or 0] or "",
        birthday = nz(fmt_jalali_from_filetime(base[7]), ""), patronymic = nz(base[8], ""), birthplace = nz(base[9], ""),
        identity_no = nz(base[10], ""), identity_serial = nz(base[11], ""), nationality = nz(base[12], ""),
        passport_no = nz(base[13], ""), place_of_issue = nz(base[14], ""), date_of_issue = nz(fmt_jalali_from_filetime(base[15]), ""),
        deleted = to_int(base[16]) == 1, confirm = to_int(base[17]) == 1,
        created = nz(fmt_jalali_from_filetime(base[18], true), ""), modified = nz(fmt_jalali_from_filetime(base[19], true), ""),
        author_id = tostring(base[20] or ""), author = nz(base[21], ""), modifier_id = tostring(base[22] or ""), modifier = nz(base[23], ""),
        comment = nz(base[24], ""), company = nz(base[25], ""), job = nz(base[26], ""), tin = nz(base[27], ""), kpp = nz(base[28], ""),
        reg_number = nz(base[29], ""), industry = nz(base[30], ""), number_personnel = nz(base[31], ""),
        personality_type = nz(base[32], ""), website = nz(base[33], ""), lable = nz(base[34], ""), issue_activity = nz(base[35], ""),
        property_code = nz(base[36], ""), property_date = nz(fmt_jalali_from_filetime(base[37]), ""),
        state_code = nz(base[38], ""), city_code = nz(base[39], ""), folder_id = to_int(base[40]) or 0,
        import_id = nz(base[41], ""), domain = nz(base[42], ""), language = nz(base[43], ""), account_manager = nz(base[44], ""),
        is_fav = to_int(base[45]) == 1, is_notified = to_int(base[46]) == 1,
    }

    client.mobiles = rows_to_objects(fetch_rows("SELECT ID, MOBILE, COUNTRY_CODE FROM profile_mobile WHERE USER_ID = ? ORDER BY ID", { client_id }),
        function(r) return { id = tostring(r[1]), value = nz(r[2], ""), country = to_int(r[3]) or 364 } end)
    client.emails = rows_to_objects(fetch_rows("SELECT ID, EMAIL, verified FROM profile_email WHERE USER_ID = ? ORDER BY ID", { client_id }),
        function(r) return { id = tostring(r[1]), value = nz(r[2], ""), verified = to_int(r[3]) == 1 } end)
    client.phones = rows_to_objects(fetch_rows("SELECT ID, TYPE, PHONE, COUNTRY_CODE FROM profile_phone WHERE USER_ID = ? ORDER BY ID", { client_id }),
        function(r) return { id = tostring(r[1]), type = to_int(r[2]) or 2, type_label = PHONE_TYPE_LABELS[to_int(r[2]) or 0] or "تلفن", value = nz(r[3], "") } end)
    client.national_codes = rows_to_objects(fetch_rows("SELECT ID, NATIONAL_CODE, COUNTRY_CODE FROM profile_nationalcode WHERE USER_ID = ? ORDER BY ID", { client_id }),
        function(r) return { id = tostring(r[1]), value = nz(r[2], ""), country = to_int(r[3]) or 364 } end)
    client.profile_addresses = rows_to_objects(fetch_rows("SELECT TYPE, COUNTRY_CODE, STATE, CITY, POSTAL_CODE, ADDRESS, LOC_X, LOC_Y FROM profile_user_address WHERE USER_ID = ? ORDER BY TYPE", { client_id }),
        function(r) return { type = to_int(r[1]) or 1, type_label = (to_int(r[1]) == 2) and "آدرس محل کار" or "آدرس", country = nz(r[2], ""), state = nz(r[3], ""), city = nz(r[4], ""), zip_code = nz(r[5], ""), address = nz(r[6], ""), loc_x = tonumber(r[7]) or 0, loc_y = tonumber(r[8]) or 0 } end)
    client.crm_addresses = rows_to_objects(fetch_rows("SELECT ID, TITLE, PROVINCE, STATE_STR, CITY, POSTAL_CODE, HOME_PHONE, WORK_PHONE, MOBILE, FAX, ADDRESS, COMMENT, LATITUDE, LONGITUDE, CONFIRM FROM crm_address WHERE CLIENT_ID = ? ORDER BY ID", { client_id }),
        function(r) return { id = tostring(r[1]), title = nz(r[2], ""), province = nz(r[3], ""), state = nz(r[4], ""), city = nz(r[5], ""), zip_code = nz(r[6], ""), home_phone = nz(r[7], ""), work_phone = nz(r[8], ""), mobile = nz(r[9], ""), fax = nz(r[10], ""), address = nz(r[11], ""), comment = nz(r[12], ""), lat = nz(r[13], ""), lng = nz(r[14], ""), confirm = to_int(r[15]) == 1 } end)
    client.categories = rows_to_objects(fetch_rows([[
SELECT c.PROFILE_ID, c.name, c.section_id, s.SECTION_NAME FROM crm_cross x
JOIN crm_classify_person c ON c.PROFILE_ID = x.REFERE_ID JOIN crm_section s ON s.ID = c.section_id
WHERE x.CLIENT_ID = ? ORDER BY s.S_ORDER, c.sort_id]], { client_id }),
        function(r) return { id = to_int(r[1]), name = nz(r[2], ""), section_id = to_int(r[3]), section_name = nz(r[4], "") } end)
    client.notify_users = rows_to_objects(fetch_rows("SELECT n.USER_ID, pm.FULLNAME FROM crm_notify n LEFT JOIN profile_main pm ON pm.ID = n.USER_ID WHERE n.CLIENT_ID = ? ORDER BY pm.FULLNAME", { client_id }),
        function(r) return { id = tostring(r[1]), name = nz(r[2], "کاربر #" .. tostring(r[1])) } end)
    client.favorite_users = rows_to_objects(fetch_rows("SELECT f.USER_ID, pm.FULLNAME FROM crm_favorite f LEFT JOIN profile_main pm ON pm.ID = f.USER_ID WHERE f.CLIENT_ID = ? AND f.FLAG = 1", { client_id }),
        function(r) return { id = tostring(r[1]), name = nz(r[2], "کاربر #" .. tostring(r[1])) } end)
    client.contacts = rows_to_objects(fetch_rows([[
SELECT c.CONTACT_ID, c.TYPE, c.CONTACT_TEXT, c.POST, c.PHONE_TEXT, c.DESCRIPTION, pm.FULLNAME,
       (SELECT m.MOBILE FROM profile_mobile m WHERE m.USER_ID = c.CONTACT_ID ORDER BY m.ID LIMIT 1)
FROM crm_contacts c LEFT JOIN profile_main pm ON pm.ID = c.CONTACT_ID WHERE c.CLIENT_ID = ? ORDER BY c.TYPE, pm.FULLNAME]], { client_id }),
        function(r)
            local ctype = to_int(r[2]) or 1
            return { contact_id = tostring(r[1]), type = ctype,
                type_label = (ctype == 3 and "معرف") or (ctype == 2 and "غیر تیم‌یاری") or "مشتری تیم‌یار",
                name = nz(r[7], nz(r[3], "—")), text = nz(r[3], ""), post = nz(r[4], ""), phone = nz(r[5], nz(r[8], "")), description = nz(r[6], "") }
        end)
    client.custom_fields = rows_to_objects(fetch_rows([[
SELECT fe.ID, fe.NAME, fe.TYPE, fv.VALUE_CHAR FROM crm_field_ext fe
LEFT JOIN crm_field_ext_value fv ON fv.FIELD_ID = fe.ID AND fv.CLIENT_ID = ?
WHERE COALESCE(fe.NAME,'') <> '' ORDER BY fe.ID]], { client_id }),
        function(r) return { id = to_int(r[1]), name = nz(r[2], ""), type = to_int(r[3]) or 0, value = nz(r[4], "") } end)
    client.custom_forms = rows_to_objects(fetch_rows("SELECT cf.SECTION_ID, s.SECTION_NAME, cf.FORM_DATA FROM crm_custom_form cf LEFT JOIN crm_section s ON s.ID = cf.SECTION_ID WHERE cf.CLIENT_ID = ?", { client_id }),
        function(r) return { section_id = to_int(r[1]), section_name = nz(r[2], ""), data = nz(r[3], "") } end)
    client.cards = rows_to_objects(fetch_rows("SELECT ID, BANK_NAME, CARD_NUMBER, CARD_HOLDER, EXPIRY_DATE, CART_TYPE, DEPOSIT_TYPE, iban, COMMENT FROM crm_card_info WHERE CLIENT_ID = ? ORDER BY ID", { client_id }),
        function(r) return { id = tostring(r[1]), bank = nz(r[2], ""), card_number = nz(r[3], ""), holder = nz(r[4], ""), expiry = nz(r[5], ""), card_type = nz(r[6], ""), deposit_type = nz(r[7], ""), iban = nz(r[8], ""), comment = nz(r[9], "") } end)
    client.bank_accounts = rows_to_objects(fetch_rows("SELECT ID, BANK_NAME, BRANCH, ACCOUNT_NUMBER, SHABA, IBAN, SWIFT_CODE, COUNTRY_STR, CITY, COMMENT FROM crm_account_info WHERE CLIENT_ID = ? ORDER BY ID", { client_id }),
        function(r) return { id = tostring(r[1]), bank = nz(r[2], ""), branch = nz(r[3], ""), account_number = nz(r[4], ""), shaba = nz(r[5], ""), iban = nz(r[6], ""), swift = nz(r[7], ""), country = nz(r[8], ""), city = nz(r[9], ""), comment = nz(r[10], "") } end)
    client.accounting = rows_to_objects(fetch_rows([[
SELECT p.ID, p.ORG_ID, o.NAME, p.CODE, p.ACCOUNT_CODE, p.BALANCE, p.STATUS FROM pa_client p
LEFT JOIN org_info o ON o.ID = p.ORG_ID WHERE p.REFFERE_ID = ? AND (p.DELETED IS NULL OR p.DELETED = 0) ORDER BY p.ORG_ID]], { client_id }),
        function(r) return { pa_client_id = tostring(r[1]), org_id = to_int(r[2]), org_name = nz(r[3], "سازمان " .. tostring(r[2])), code = nz(r[4], ""), account_code = nz(r[5], ""), balance = tonumber(r[6]) or 0, balance_fmt = fmt_num(r[6]) } end)
    client.family = rows_to_objects(fetch_rows("SELECT FIRST_NAME, LAST_NAME, RELATION, NATIONAL_CODE, BIRTH_DATE, PHONE, JOB FROM crm_person_family WHERE PROFILE_ID = ? ORDER BY ID", { client_id }),
        function(r) return { name = trim(nz(r[1], "") .. " " .. nz(r[2], "")), relation = nz(r[3], ""), national_code = nz(r[4], ""), birth_date = nz(fmt_jalali_from_filetime(r[5]), nz(r[5], "")), phone = nz(r[6], ""), job = nz(r[7], "") } end)

    client.links = {
        native_edit = ROUTES.client_edit(client.id, 1), native_view = ROUTES.client_edit(client.id),
        todo = ROUTES.history("show_todo", client.id, "0"), documents = ROUTES.history("show_documents", client.id),
        emails = ROUTES.history("show_emails", client.id), chats = ROUTES.history("show_chats", client.id),
        events = ROUTES.history("show_events", client.id, "0"), sms = ROUTES.history("show_sms", client.id),
        sales = ROUTES.history("show_sales", client.id), purchase = ROUTES.history("show_purchase", client.id),
        poll = ROUTES.history("show_poll", client.id), audio = ROUTES.history("audio_files", client.id) .. AMP .. "tab=3" .. AMP .. "type=audio" .. AMP .. "call_id=0",
        comments = ROUTES.history("show_comments", client.id) .. AMP .. "tab=2" .. AMP .. "type=comment",
        project = ROUTES.history("show_project", client.id),
        print = CONFIG.BASE_URL .. "/crm/client/print/" .. client.id,
        envelope = CONFIG.BASE_URL .. "/crm/client/envelope_print/" .. client.id,
    }
    return client
end

local function action_client()
    local client_id = to_positive_int(inp("id"))
    if client_id == nil then return { ok = false, error = "شناسهٔ مشتری نامعتبر است" } end
    local client = load_client(client_id)
    if client == nil then return { ok = false, error = "مشتری با شناسهٔ " .. tostring(client_id) .. " یافت نشد" } end
    return { ok = true, client = client }
end

-- =========================================
-- CLIENT COUNTS (نشان تب‌ها + KPI)
-- =========================================
local INVOICE_AMOUNT_SUBQUERY = [[
SELECT ip.INVOICE_ID AS invoice_id,
       SUM(COALESCE((ip.QUANTITY / POW(10, COALESCE(sc.DECIMAL_NUM, 0))) * (ip.FEE / POW(10, COALESCE(dd.digit_fee, 0))), 0)
           - COALESCE(ip.DISCOUNT, 0) + COALESCE(ip.VALUE_ADDED, 0)
           + COALESCE(ip.TAX / POW(10, COALESCE(dd.digit_fee, 0)), 0) + COALESCE(ip.TOLL / POW(10, COALESCE(dd.digit_fee, 0)), 0)) AS amount
FROM sales_invoice_product ip
INNER JOIN sales_invoice i2 ON i2.ID = ip.INVOICE_ID
LEFT JOIN wh_product wp ON wp.ID = ip.PRODUCT_ID
LEFT JOIN wh_stock_capacity sc ON sc.ID = wp.CAPACITY_ID
LEFT JOIN (
    SELECT po.ORG_ID, (CASE WHEN COALESCE(ps.FEE_DECIMAL, 0) = 0 THEN COALESCE(ps.DECIMAL_COUNT, 0) ELSE COALESCE(ps.FEE_DECIMAL, 0) END) AS digit_fee
    FROM pa_organizations po INNER JOIN pa_symbols ps ON ps.ID = po.BASE_CURRENCY AND ps.ORG_ID = po.ORG_ID
) dd ON dd.ORG_ID = i2.ORG_ID
WHERE i2.CLIENT_ID IN %s
GROUP BY ip.INVOICE_ID]]

local function action_counts()
    local client_id = to_positive_int(inp("id"))
    if client_id == nil then return { ok = false, error = "شناسهٔ مشتری نامعتبر است" } end
    local pa_ids = resolve_pa_client_ids(client_id)
    local pa_in = id_list_sql(pa_ids)

    local mobile_rows = fetch_rows("SELECT RIGHT(MOBILE, 10) FROM profile_mobile WHERE USER_ID = ?", { client_id }) or {}
    local mobile_tails = {}
    for _, r in ipairs(mobile_rows) do
        local t = digits_only(r[1])
        if #t >= 7 then table.insert(mobile_tails, "'" .. t .. "'") end
    end
    local sms_where = "b.user_id = ?"
    if #mobile_tails > 0 then sms_where = sms_where .. " OR RIGHT(b.PHONE_NUMBER, 10) IN (" .. table.concat(mobile_tails, ",") .. ")" end

    local counts = fetch_row([[
SELECT (SELECT COUNT(*) FROM sales_invoice s WHERE s.CLIENT_ID IN ]] .. pa_in .. [[ AND s.DELETED = 0),
       (SELECT COUNT(*) FROM purchase_invoice p WHERE p.CLIENT_ID IN ]] .. pa_in .. [[ AND p.DELETED = 0),
       (SELECT COUNT(*) FROM crm_ty_links l JOIN todo_task t0 ON t0.ID = l.DST_LINK_ID WHERE l.SRC_MODULE_ID = 14 AND l.DST_MODULE_ID = 8 AND l.SRC_LINK_ID = ?),
       (SELECT COUNT(*) FROM crm_history h WHERE h.CLIENT_ID = ? AND h.TYPE = 1 AND COALESCE(h.NOTE,'') <> '' AND h.NOTE NOT LIKE '<%')
         + (SELECT COUNT(*) FROM crm_ty_links l JOIN documents_main d ON d.ID = l.DST_LINK_ID WHERE l.SRC_MODULE_ID = 14 AND l.DST_MODULE_ID = 7 AND l.SRC_LINK_ID = ? AND d.MIME_TYPE IN ('text-html','text/html')),
       (SELECT COUNT(*) FROM crm_ty_links l JOIN documents_main d ON d.ID = l.DST_LINK_ID WHERE l.SRC_MODULE_ID = 14 AND l.DST_MODULE_ID = 7 AND l.SRC_LINK_ID = ? AND d.MIME_TYPE NOT IN ('text-html','text/html'))
         + (SELECT COUNT(*) FROM documents_main d2 JOIN crm_info c2 ON c2.FOLDER_ID = d2.PARENT_ID WHERE c2.ID = ? AND c2.FOLDER_ID > 0),
       (SELECT COUNT(*) FROM crm_ty_links l WHERE l.SRC_MODULE_ID = 14 AND l.DST_MODULE_ID = 12 AND l.SRC_LINK_ID = ?),
       (SELECT COUNT(*) FROM chat_dialogs cd WHERE cd.AUTHOR_ID = ? AND COALESCE(cd.deleted,0) = 0),
       (SELECT COUNT(*) FROM cal_invite_user ciu WHERE ciu.USER_ID = ?),
       (SELECT COUNT(*) FROM sms_message m JOIN sms_phone_book b ON b.ID = m.NUMBER_ID WHERE ]] .. sms_where .. [[),
       (SELECT COUNT(*) FROM poll_related pr WHERE pr.USER_ID = ? AND pr.related_type = 1),
       (SELECT COUNT(*) FROM crm_ty_links l WHERE l.SRC_MODULE_ID = 14 AND l.DST_MODULE_ID = 20 AND l.SRC_LINK_ID = ?),
       (SELECT COUNT(*) FROM crm_history h WHERE h.CLIENT_ID = ?),
       (SELECT COUNT(*) FROM crm_contacts c WHERE c.CLIENT_ID = ?),
       (SELECT COUNT(*) FROM crm_notify n WHERE n.CLIENT_ID = ?),
       (SELECT MAX(s.RUN_DATE) FROM sales_invoice s WHERE s.CLIENT_ID IN ]] .. pa_in .. [[ AND s.DELETED = 0 AND s.CANCELED = 0),
       (SELECT COUNT(*) FROM crm_ty_links l JOIN todo_task t ON t.ID = l.DST_LINK_ID WHERE l.SRC_MODULE_ID = 14 AND l.DST_MODULE_ID = 8 AND l.SRC_LINK_ID = ? AND t.STATUS IN (0,1))]],
        { client_id, client_id, client_id, client_id, client_id, client_id, client_id, client_id, client_id, client_id, client_id, client_id, client_id, client_id, client_id })
    if counts == nil then return { ok = false, error = "خطا در شمارش تب‌ها" } end

    local sales_total, returns_total = 0, 0
    if #pa_ids > 0 then
        local sums = fetch_row([[
SELECT SUM(CASE WHEN s.TYPE = 3 THEN 0 ELSE COALESCE(ia.amount,0) END), SUM(CASE WHEN s.TYPE = 3 THEN COALESCE(ia.amount,0) ELSE 0 END)
FROM sales_invoice s LEFT JOIN (]] .. string.format(INVOICE_AMOUNT_SUBQUERY, pa_in) .. [[) ia ON ia.invoice_id = s.ID
WHERE s.CLIENT_ID IN ]] .. pa_in .. [[ AND s.DELETED = 0 AND s.CANCELED = 0 AND s.PRE_INVOICE = 0]], {})
        if sums ~= nil then
            sales_total = tonumber(sums[1]) or 0
            returns_total = tonumber(sums[2]) or 0
        end
    end

    return {
        ok = true,
        counts = {
            sales = tonumber(counts[1]) or 0, purchase = tonumber(counts[2]) or 0, todo = tonumber(counts[3]) or 0,
            comments = tonumber(counts[4]) or 0, documents = tonumber(counts[5]) or 0, emails = tonumber(counts[6]) or 0,
            chats = tonumber(counts[7]) or 0, events = tonumber(counts[8]) or 0, sms = tonumber(counts[9]) or 0,
            polls = tonumber(counts[10]) or 0, projects = tonumber(counts[11]) or 0, history = tonumber(counts[12]) or 0,
            contacts = tonumber(counts[13]) or 0, notify = tonumber(counts[14]) or 0, calls = 0,
        },
        kpi = {
            sales_total = sales_total, sales_total_fmt = fmt_num(sales_total),
            returns_total = returns_total, returns_total_fmt = fmt_num(returns_total),
            net_sales_fmt = fmt_num(sales_total - returns_total),
            last_invoice = nz(fmt_jalali_from_filetime(counts[15]), "—"),
            open_todos = tonumber(counts[16]) or 0,
        },
    }
end

-- =========================================
-- TABS
-- =========================================
local TAB_LOADERS = {}

TAB_LOADERS.sales = function(client_id)
    local pa_ids = resolve_pa_client_ids(client_id)
    if #pa_ids == 0 then return {} end
    local pa_in = id_list_sql(pa_ids)
    local rows = fetch_rows([[
SELECT s.ID, s.TITLE, s.TYPE, s.RUN_DATE, s.STATUS, s.INVOICE_CODE, s.CANCELED, s.PRE_INVOICE, s.REMAINED_AMOUNT,
       COALESCE(ia.amount, 0), s.PAYMENT_TYPE, s.DATE_CREATE, s.REJECT, pc.NAME AS sales_center, s.delivery_date,
       (SELECT au.FULLNAME FROM profile_main au WHERE au.ID = s.USER_CREATE)
FROM sales_invoice s
LEFT JOIN (]] .. string.format(INVOICE_AMOUNT_SUBQUERY, pa_in) .. [[) ia ON ia.invoice_id = s.ID
LEFT JOIN pa_center pc ON pc.ID = s.SALES_CENTER
WHERE s.CLIENT_ID IN ]] .. pa_in .. [[ AND s.DELETED = 0
ORDER BY s.RUN_DATE DESC, s.ID DESC LIMIT ]] .. CONFIG.TAB_ROW_LIMIT, {}) or {}
    return rows_to_objects(rows, function(r)
        local itype = to_int(r[3]) or 1
        return { id = tostring(r[1]), title = nz(r[2], ""), type = itype, type_label = INVOICE_TYPE_LABELS[itype] or ("نوع " .. itype),
            date = nz(fmt_jalali_from_filetime(r[4]), ""), status = to_int(r[5]) or 0, code = nz(r[6], ""),
            canceled = to_int(r[7]) == 1, pre_invoice = to_int(r[8]) or 0, remained = fmt_num(r[9]), amount = tonumber(r[10]) or 0,
            amount_fmt = fmt_num(r[10]), payment_type = to_int(r[11]) or 0, created = nz(fmt_jalali_from_filetime(r[12], true), ""),
            reject = to_int(r[13]) == 1, center = nz(r[14], ""), delivery = nz(fmt_jalali_from_filetime(r[15]), ""), creator = nz(r[16], ""),
            url = ROUTES.invoice_view(tostring(r[1])) }
    end)
end

TAB_LOADERS.purchase = function(client_id)
    local pa_ids = resolve_pa_client_ids(client_id)
    if #pa_ids == 0 then return {} end
    local rows = fetch_rows([[
SELECT p.ID, p.TITLE, p.TYPE, p.RUN_DATE, p.STATUS, p.INVOICE_NUM, p.CANCELED, p.pre_payment_amount, p.DATE_CREATE,
       (SELECT au.FULLNAME FROM profile_main au WHERE au.ID = p.USER_CREATE)
FROM purchase_invoice p WHERE p.CLIENT_ID IN ]] .. id_list_sql(pa_ids) .. [[ AND p.DELETED = 0
ORDER BY p.RUN_DATE DESC, p.ID DESC LIMIT ]] .. CONFIG.TAB_ROW_LIMIT, {}) or {}
    return rows_to_objects(rows, function(r)
        return { id = tostring(r[1]), title = nz(r[2], ""), type = to_int(r[3]) or 0, date = nz(fmt_jalali_from_filetime(r[4]), ""),
            status = to_int(r[5]) or 0, number = nz(r[6], ""), canceled = to_int(r[7]) == 1, pre_payment = fmt_num(r[8]),
            created = nz(fmt_jalali_from_filetime(r[9], true), ""), creator = nz(r[10], "") }
    end)
end

TAB_LOADERS.todo = function(client_id)
    local rows = fetch_rows([[
SELECT t.ID, t.TASK_TITLE, t.STATUS, t.T_START_DATE, t.T_END_DATE, t.T_REAL_END_DATE, t.progress, t.T_PRIORITY,
       COALESCE(NULLIF(t.AUTHOR_NAME,''), (SELECT au.FULLNAME FROM profile_main au WHERE au.ID = t.AUTHOR_ID)),
       (SELECT ow.FULLNAME FROM profile_main ow WHERE ow.ID = t.OWNER_ID), t.LAST_MODIFY_DATE, l.DATE_CREATE
FROM crm_ty_links l INNER JOIN todo_task t ON t.ID = l.DST_LINK_ID
WHERE l.SRC_MODULE_ID = 14 AND l.DST_MODULE_ID = 8 AND l.SRC_LINK_ID = ?
ORDER BY t.ID DESC LIMIT ]] .. CONFIG.TAB_ROW_LIMIT, { client_id }) or {}
    return rows_to_objects(rows, function(r)
        local st = to_int(r[3]) or 0
        return { id = tostring(r[1]), title = nz(r[2], ""), status = st, status_label = TODO_STATUS_LABELS[st] or ("وضعیت " .. st),
            start = nz(fmt_jalali_from_filetime(r[4]), ""), deadline = nz(fmt_jalali_from_filetime(r[5]), ""),
            finished = nz(fmt_jalali_from_filetime(r[6]), ""), progress = to_int(r[7]) or 0, priority = to_int(r[8]) or 0,
            author = nz(r[9], ""), owner = nz(r[10], ""), modified = nz(fmt_jalali_from_filetime(r[11], true), ""),
            linked = nz(fmt_jalali_from_filetime(r[12], true), ""), url = ROUTES.todo_report(tostring(r[1])) }
    end)
end

local function map_document_row(client_id, r, source)
    local mime = nz(r[3], "")
    return { id = tostring(r[1]), name = nz(r[2], ""), mime = mime, size = to_int(r[4]) or 0, size_fmt = fmt_num(r[4]),
        created = nz(fmt_jalali_from_filetime(r[5], true), ""), author = nz(r[6], ""), file_type = to_int(r[7]) or 0,
        is_folder = to_int(r[8]) == 1, source = source, version = to_int(r[9]) or 0,
        url = ROUTES.comment_file(client_id, tostring(r[1])) }
end

TAB_LOADERS.documents = function(client_id)
    local out = {}
    local folder = fetch_rows([[
SELECT d.ID, d.NAME, d.MIME_TYPE, d.SIZE, d.DATE_CREATE, (SELECT au.FULLNAME FROM profile_main au WHERE au.ID = d.AUTHOR_ID), d.FILE_TYPE, (d.TYPE = 1), d.VERSION
FROM documents_main d INNER JOIN crm_info c ON c.FOLDER_ID = d.PARENT_ID
WHERE c.ID = ? AND c.FOLDER_ID > 0 ORDER BY d.TYPE, d.DATE_CREATE DESC LIMIT ]] .. CONFIG.TAB_ROW_LIMIT, { client_id }) or {}
    for _, r in ipairs(folder) do table.insert(out, map_document_row(client_id, r, "folder")) end
    local linked = fetch_rows([[
SELECT d.ID, d.NAME, d.MIME_TYPE, d.SIZE, d.DATE_CREATE, (SELECT au.FULLNAME FROM profile_main au WHERE au.ID = d.AUTHOR_ID), d.FILE_TYPE, (d.TYPE = 1), d.VERSION
FROM crm_ty_links l INNER JOIN documents_main d ON d.ID = l.DST_LINK_ID
WHERE l.SRC_MODULE_ID = 14 AND l.DST_MODULE_ID = 7 AND l.SRC_LINK_ID = ? AND d.MIME_TYPE NOT IN ('text-html','text/html')
ORDER BY d.DATE_CREATE DESC LIMIT ]] .. CONFIG.TAB_ROW_LIMIT, { client_id }) or {}
    for _, r in ipairs(linked) do table.insert(out, map_document_row(client_id, r, "linked")) end
    return out
end

-- «توضیحات» (تأیید زنده ۱۴۰۵/۰۶/۱۲ با /crm/history/change_comments): ردیف‌های crm_history با TYPE=1 که NOTE متن
-- ساده است. ردیف‌های لاگ سیستمی همان TYPE را دارند ولی NOTE آن‌ها HTML است (با <table یا <span شروع می‌شود؛
-- AUTHOR_ID=3 «TeamYar») — پس هر NOTE که با «<» شروع شود لاگ است، نه توضیح کاربر. بخش = section_id.
TAB_LOADERS.comments = function(client_id)
    local notes = fetch_rows([[
SELECT h.ID, h.NOTE, h.DATE_MODIFY, h.AUTHOR_ID, (SELECT au.FULLNAME FROM profile_main au WHERE au.ID = h.AUTHOR_ID), h.section_id,
       (SELECT s.SECTION_NAME FROM crm_section s WHERE s.ID = h.section_id)
FROM crm_history h
WHERE h.CLIENT_ID = ? AND h.TYPE = 1 AND COALESCE(h.NOTE,'') <> '' AND h.NOTE NOT LIKE '<%'
ORDER BY h.ID DESC LIMIT ]] .. CONFIG.TAB_ROW_LIMIT, { client_id }) or {}
    local out = rows_to_objects(notes, function(r)
        return { id = tostring(r[1]), kind = "note", text = nz(r[2], ""), created = nz(fmt_jalali_from_filetime(r[3], true), ""),
            author_id = tostring(r[4] or ""), author = nz(r[5], ""), section_id = to_int(r[6]) or 0, section_name = nz(r[7], ""),
            url = ROUTES.history("show_comments", tostring(client_id)) .. AMP .. "tab=2" .. AMP .. "type=comment" }
    end)
    -- فایل‌های توضیح قدیمی/پیوست‌شده (.tyhtm در ماژول اسناد، لینک‌شده به مشتری)
    local rows = fetch_rows([[
SELECT d.ID, d.NAME, d.MIME_TYPE, d.SIZE, d.DATE_CREATE, (SELECT au.FULLNAME FROM profile_main au WHERE au.ID = d.AUTHOR_ID), d.FILE_TYPE, (d.TYPE = 1), d.VERSION, l.DATE_CREATE
FROM crm_ty_links l INNER JOIN documents_main d ON d.ID = l.DST_LINK_ID
WHERE l.SRC_MODULE_ID = 14 AND l.DST_MODULE_ID = 7 AND l.SRC_LINK_ID = ? AND d.MIME_TYPE IN ('text-html','text/html')
ORDER BY d.DATE_CREATE DESC LIMIT ]] .. CONFIG.TAB_ROW_LIMIT, { client_id }) or {}
    local files = rows_to_objects(rows, function(r)
        local row = map_document_row(client_id, r, "comment")
        row.kind = "file"
        -- نام فایل توضیح: «نام مشتری-موضوع-نویسنده.tyhtm» -> موضوع را جدا می‌کنیم
        local title = row.name:gsub("%.tyhtm$", ""):gsub("%.html?$", "")
        local parts = {}
        for piece in title:gmatch("[^%-]+") do table.insert(parts, trim(piece)) end
        if #parts >= 3 then
            row.subject = table.concat(parts, "-", 2, #parts - 1)
        elseif #parts == 2 then
            row.subject = parts[2]
        else
            row.subject = title
        end
        row.linked = nz(fmt_jalali_from_filetime(r[10], true), "")
        return row
    end)
    for _, f in ipairs(files) do table.insert(out, f) end
    return out
end

TAB_LOADERS.emails = function(client_id)
    local rows = fetch_rows([[
SELECT e.ID, e.SUBJECT, e.DATE_CRAETE, e.date_sent, e.CATEGORY, e.SEND_FLAG,
       (SELECT au.FULLNAME FROM profile_main au WHERE au.ID = e.AUTHOR_ID), e.ARCHIVE_FLAG, l.DATE_CREATE
FROM crm_ty_links l INNER JOIN email_message e ON e.ID = l.DST_LINK_ID
WHERE l.SRC_MODULE_ID = 14 AND l.DST_MODULE_ID = 12 AND l.SRC_LINK_ID = ?
ORDER BY e.ID DESC LIMIT ]] .. CONFIG.TAB_ROW_LIMIT, { client_id }) or {}
    return rows_to_objects(rows, function(r)
        return { id = tostring(r[1]), subject = nz(r[2], "(بدون موضوع)"), created = nz(fmt_jalali_from_filetime(r[3], true), ""),
            sent = nz(fmt_jalali_from_filetime(r[4], true), ""), category = to_int(r[5]) or 0, sent_flag = to_int(r[6]) or 0,
            author = nz(r[7], ""), archived = to_int(r[8]) == 1, linked = nz(fmt_jalali_from_filetime(r[9], true), ""),
            url = ROUTES.email_view(tostring(r[1])) }
    end)
end

TAB_LOADERS.chats = function(client_id)
    local rows = fetch_rows([[
SELECT c.ID, c.TOPIC, c.DATE_CREATE, c.DATE_END, c.LAST_MODIFIED, c.STATUS, c.TYPE, c.AUTHOR_NAME, c.AUTHOR_MOBILE,
       (SELECT COUNT(*) FROM chat_message cm WHERE cm.DIALOG_ID = c.ID)
FROM chat_dialogs c WHERE c.AUTHOR_ID = ? AND COALESCE(c.deleted,0) = 0
ORDER BY c.ID DESC LIMIT ]] .. CONFIG.TAB_ROW_LIMIT, { client_id })
    if rows == nil then
        rows = fetch_rows([[
SELECT c.ID, c.TOPIC, c.DATE_CREATE, c.DATE_END, c.LAST_MODIFIED, c.STATUS, c.TYPE, c.AUTHOR_NAME, c.AUTHOR_MOBILE, 0
FROM chat_dialogs c WHERE c.AUTHOR_ID = ? AND COALESCE(c.deleted,0) = 0
ORDER BY c.ID DESC LIMIT ]] .. CONFIG.TAB_ROW_LIMIT, { client_id }) or {}
    end
    return rows_to_objects(rows, function(r)
        return { id = tostring(r[1]), topic = nz(r[2], "(بدون عنوان)"), created = nz(fmt_jalali_from_filetime(r[3], true), ""),
            ended = nz(fmt_jalali_from_filetime(r[4], true), ""), modified = nz(fmt_jalali_from_filetime(r[5], true), ""),
            status = to_int(r[6]) or 0, type = to_int(r[7]) or 0, author = nz(r[8], ""), mobile = nz(r[9], ""),
            messages = to_int(r[10]) or 0, url = ROUTES.chat_view(tostring(r[1])) }
    end)
end

TAB_LOADERS.events = function(client_id)
    local rows = fetch_rows([[
SELECT ce.ID, ce.NAME, ce.DATE_START, ce.DATE_FINISH, ciu.STATUS, ce.PLACE, ce.DESCRIPTION,
       (SELECT au.FULLNAME FROM profile_main au WHERE au.ID = ce.CREATOR_ID), ce.STATUS, ce.online_meeting
FROM cal_invite_user ciu INNER JOIN cal_event ce ON ce.ID = ciu.EVENT_ID
WHERE ciu.USER_ID = ? ORDER BY ce.DATE_START DESC LIMIT ]] .. CONFIG.TAB_ROW_LIMIT, { client_id }) or {}
    return rows_to_objects(rows, function(r)
        return { id = tostring(r[1]), name = nz(r[2], ""), start = nz(fmt_jalali_from_filetime(r[3], true), ""),
            finish = nz(fmt_jalali_from_filetime(r[4], true), ""), invite_status = to_int(r[5]) or 0, place = nz(r[6], ""),
            description = strip_tags(nz(r[7], "")):sub(1, 200), creator = nz(r[8], ""), status = to_int(r[9]) or 0,
            online = to_int(r[10]) == 1 }
    end)
end

TAB_LOADERS.sms = function(client_id)
    local mobile_rows = fetch_rows("SELECT RIGHT(MOBILE, 10) FROM profile_mobile WHERE USER_ID = ?", { client_id }) or {}
    local tails = {}
    for _, r in ipairs(mobile_rows) do
        local t = digits_only(r[1])
        if #t >= 7 then table.insert(tails, "'" .. t .. "'") end
    end
    local where = "b.user_id = ?"
    if #tails > 0 then where = where .. " OR RIGHT(b.PHONE_NUMBER, 10) IN (" .. table.concat(tails, ",") .. ")" end
    local rows = fetch_rows([[
SELECT m.ID, m.CONTENT, m.DIRECTION, m.STATUS, m.CATEGORY, m.DATE_CREATE, b.PHONE_NUMBER,
       (SELECT au.FULLNAME FROM profile_main au WHERE au.ID = m.AUTHOR_ID), m.SENDRESULT
FROM sms_message m INNER JOIN sms_phone_book b ON b.ID = m.NUMBER_ID
WHERE ]] .. where .. [[ ORDER BY m.ID DESC LIMIT ]] .. CONFIG.TAB_ROW_LIMIT, { client_id }) or {}
    return rows_to_objects(rows, function(r)
        local dir = to_int(r[3]) or 0
        return { id = tostring(r[1]), content = nz(r[2], ""), direction = dir, direction_label = SMS_DIRECTION_LABELS[dir] or "",
            status = to_int(r[4]) or 0, category = to_int(r[5]) or 0, date = nz(fmt_jalali_from_filetime(r[6], true), ""),
            number = nz(r[7], ""), author = nz(r[8], ""), result = nz(r[9], "") }
    end)
end

TAB_LOADERS.polls = function(client_id)
    local rows = fetch_rows([[
SELECT q.ID, q.NAME, q.STATUS, q.START_DATE, q.END_DATE, q.DATE_CREATE, q.TYPE, pr.TYPE,
       (SELECT au.FULLNAME FROM profile_main au WHERE au.ID = q.AUTHOR_ID)
FROM poll_related pr INNER JOIN poll_questionnaire q ON q.ID = pr.QUESTIONNAIRE_ID
WHERE pr.USER_ID = ? AND pr.related_type = 1 AND COALESCE(q.FLAG_DELETED,0) = 0
ORDER BY q.ID DESC LIMIT ]] .. CONFIG.TAB_ROW_LIMIT, { client_id }) or {}
    return rows_to_objects(rows, function(r)
        return { id = tostring(r[1]), name = nz(r[2], ""), status = to_int(r[3]) or 0, start = nz(fmt_jalali_from_filetime(r[4]), ""),
            finish = nz(fmt_jalali_from_filetime(r[5]), ""), created = nz(fmt_jalali_from_filetime(r[6], true), ""),
            type = to_int(r[7]) or 0, relation_type = to_int(r[8]) or 0, author = nz(r[9], ""), url = ROUTES.poll_view(tostring(r[1])) }
    end)
end

TAB_LOADERS.projects = function(client_id)
    local rows = fetch_rows([[
SELECT pp.ID, pp.TITLE, pp.PROGRESS, pp.STATUS, pp.DATE_START, pp.DATE_LIMIT, pp.DATE_CREATE
FROM crm_ty_links l INNER JOIN project_project pp ON pp.ID = l.DST_LINK_ID
WHERE l.SRC_MODULE_ID = 14 AND l.DST_MODULE_ID = 20 AND l.SRC_LINK_ID = ?
ORDER BY pp.ID DESC LIMIT ]] .. CONFIG.TAB_ROW_LIMIT, { client_id }) or {}
    return rows_to_objects(rows, function(r)
        return { id = tostring(r[1]), title = nz(r[2], ""), progress = to_int(r[3]) or 0, status = to_int(r[4]) or 0,
            start = nz(fmt_jalali_from_filetime(r[5]), ""), deadline = nz(fmt_jalali_from_filetime(r[6]), ""),
            created = nz(fmt_jalali_from_filetime(r[7], true), ""), url = ROUTES.project_view(tostring(r[1])) }
    end)
end

TAB_LOADERS.history = function(client_id)
    local rows = fetch_rows([[
SELECT h.ID, h.TYPE, h.DATE_MODIFY, COALESCE(NULLIF(h.NOTE,''), h.CONTENT, ''), h.AUTHOR_ID,
       (SELECT au.FULLNAME FROM profile_main au WHERE au.ID = h.AUTHOR_ID), h.section_id
FROM crm_history h WHERE h.CLIENT_ID = ? ORDER BY h.ID DESC LIMIT ]] .. CONFIG.HISTORY_LIMIT, { client_id }) or {}
    return rows_to_objects(rows, function(r)
        return { id = tostring(r[1]), type = to_int(r[2]) or 0, date = nz(fmt_jalali_from_filetime(r[3], true), ""),
            text = strip_tags(r[4]):sub(1, 400), author_id = tostring(r[5] or ""), author = nz(r[6], ""), section_id = to_int(r[7]) or 0 }
    end)
end

TAB_LOADERS.calls = function(client_id)
    local rows = fetch_rows([[
SELECT c.ID, c.DATE, c.CALL_DURATION, c.COST, c.TYPE, c.STATUS, c.CID, c.RECORDINGFILE
FROM crm_calllog c WHERE c.profile_src_id = ? OR c.profile_dst_id = ? OR c.CUSTOMER_ID = ?
ORDER BY c.ID DESC LIMIT ]] .. CONFIG.TAB_ROW_LIMIT, { client_id, client_id, client_id }) or {}
    return rows_to_objects(rows, function(r)
        return { id = tostring(r[1]), date = nz(fmt_jalali_from_filetime(r[2], true), ""), duration = to_int(r[3]) or 0,
            cost = fmt_num(r[4]), type = to_int(r[5]) or 0, status = to_int(r[6]) or 0, cid = nz(r[7], ""), has_file = nz(r[8], "") ~= "" }
    end)
end

local function action_tab()
    local client_id = to_positive_int(inp("id"))
    local tab = trim(inp("tab") or "")
    if client_id == nil then return { ok = false, error = "شناسهٔ مشتری نامعتبر است" } end
    local loader = TAB_LOADERS[tab]
    if loader == nil then return { ok = false, error = "تب ناشناخته: " .. tab } end
    local ok, rows_or_err = pcall(loader, client_id)
    if not ok then return { ok = false, error = "خطا در بارگذاری تب «" .. tab .. "»: " .. tostring(rows_or_err) } end
    return { ok = true, tab = tab, rows = rows_or_err, limit = CONFIG.TAB_ROW_LIMIT }
end

-- =========================================
-- LOOKUPS (برای فرم‌ها)
-- =========================================
local function action_lookup()
    local kind = trim(inp("kind") or "")
    local q = trim(inp("q") or "")
    local literal = sanitize_like_literal(q)
    if kind == "users" then
        -- کاربران داخلی (پرسنل) برای «مطلع»/«مسئول»
        local where = literal ~= "" and (" AND pm.FULLNAME LIKE '%" .. literal .. "%'") or ""
        local rows = fetch_rows([[
SELECT DISTINCT pm.ID, pm.FULLNAME FROM hr_personnels hp INNER JOIN profile_main pm ON pm.ID = hp.profile_id
WHERE pm.FULLNAME <> '']] .. where .. [[ ORDER BY pm.FULLNAME LIMIT 40]], {}) or {}
        return { ok = true, rows = rows_to_objects(rows, function(r) return { id = tostring(r[1]), name = nz(r[2], "") } end) }
    elseif kind == "clients" then
        local where = ""
        local params = {}
        if is_all_digits(q) then
            where = " AND ci.ID = ?"
            table.insert(params, tonumber(q))
        elseif literal ~= "" then
            where = " AND pm.FULLNAME LIKE '%" .. literal .. "%'"
        end
        local rows = fetch_rows([[
SELECT ci.ID, pm.FULLNAME, (SELECT m.MOBILE FROM profile_mobile m WHERE m.USER_ID = ci.ID ORDER BY m.ID LIMIT 1)
FROM crm_info ci INNER JOIN profile_main pm ON pm.ID = ci.ID WHERE ci.DELETED = 0]] .. where .. [[ ORDER BY ci.ID DESC LIMIT 30]], params) or {}
        return { ok = true, rows = rows_to_objects(rows, function(r) return { id = tostring(r[1]), name = nz(r[2], ""), mobile = nz(r[3], "") } end) }
    elseif kind == "cities" then
        local where = literal ~= "" and (" WHERE STATE_NAME LIKE '%" .. literal .. "%' OR CITY_NAME LIKE '%" .. literal .. "%'") or ""
        local rows = fetch_rows("SELECT STATE_CODE, STATE_NAME, CITY_CODE, CITY_NAME FROM crm_state_city" .. where .. " ORDER BY STATE_NAME, CITY_NAME LIMIT 60", {}) or {}
        return { ok = true, rows = rows_to_objects(rows, function(r) return { state_code = nz(r[1], ""), state = nz(r[2], ""), city_code = nz(r[3], ""), city = nz(r[4], "") } end) }
    end
    return { ok = false, error = "نوع جستجوی نامعتبر" }
end

-- =========================================
-- WRITE ACTIONS — از طریق API رسمی CRM (module_id 14)
-- =========================================
local function call_crm_api(path, payload)
    local ok, res = pcall(function() return teamyar.call_api(CONFIG.CRM_MODULE_ID, path, payload) end)
    if not ok then
        teamyar.write_log("crm_customer_ui call_api error " .. path .. ": " .. tostring(res))
        return { ok = false, error = "خطا در فراخوانی API «" .. path .. "»: " .. tostring(res) }
    end
    if _G.type(res) == "string" then
        local decoded_ok, decoded = pcall(function() return json.decode(res) end)
        if decoded_ok and _G.type(decoded) == "table" then res = decoded end
    end
    if _G.type(res) ~= "table" then
        return { ok = false, error = "پاسخ نامعتبر از API «" .. path .. "»", raw = tostring(res) }
    end
    local success = res.success
    if success == nil then success = res.ok end
    if success == false then
        -- خطای API یا رشته است یا جدول {message, status} (مثل SECTION_ID_NOT_FOUND)
        local msg = res.error or res.message or res.msg or (res.data and res.data.message) or "عملیات توسط سرور رد شد"
        if _G.type(msg) == "table" then msg = msg.message or msg.error or json.encode(msg) end
        local translations = {
            SECTION_ID_NOT_FOUND = "بخش (section) نامعتبر است — بخش را انتخاب کنید",
            ACCESS_DENIED = "برای این عملیات دسترسی ندارید",
            ERROR_EXIST_SEVERAL_CLASSIFY_FOR_USER = "مشتری نمی‌تواند در چند رده از یک بخش باشد",
            ERROR_DELETE_SEVERAL_USER_FOR_CLASSIFY = "تنظیمات رده دارای پیش‌فرض است، امکان حذف وجود ندارد",
        }
        local text = tostring(msg)
        return { ok = false, error = translations[text] or text, api = res }
    end
    return { ok = true, api = res }
end

local function decode_json_input(name)
    local raw = inp(name)
    if raw == nil or trim(raw) == "" then return nil, "دادهٔ «" .. name .. "» ارسال نشده است" end
    local ok, decoded = pcall(function() return json.decode(raw) end)
    if not ok or _G.type(decoded) ~= "table" then return nil, "دادهٔ «" .. name .. "» JSON معتبر نیست" end
    return decoded
end

local function action_api_get()
    local client_id = to_positive_int(inp("id"))
    if client_id == nil then return { ok = false, error = "شناسهٔ مشتری نامعتبر است" } end
    return call_crm_api("/api/client/get", { id = client_id })
end

local function action_comment_add()
    local client_id = to_positive_int(inp("id"))
    local comment = trim(inp("comment") or "")
    if client_id == nil then return { ok = false, error = "شناسهٔ مشتری نامعتبر است" } end
    if comment == "" then return { ok = false, error = "متن توضیح خالی است" } end
    if #comment > 4000 then return { ok = false, error = "متن توضیح بیش از حد بلند است (حداکثر ۴۰۰۰ نویسه)" } end
    -- مشتری باید وجود داشته باشد و حذف‌شده نباشد (لایهٔ اعتبارسنجی قبل از هر نوشتن)
    local exists = fetch_scalar("SELECT COUNT(*) FROM crm_info WHERE ID = ? AND DELETED = 0", { client_id })
    if tonumber(exists) ~= 1 then return { ok = false, error = "مشتری یافت نشد یا حذف شده است" } end
    -- API بخش معتبر می‌خواهد (section_id=0 => SECTION_ID_NOT_FOUND، تست زندهٔ ۱۴۰۵/۰۶/۱۲). ترتیب انتخاب:
    -- بخش انتخاب‌شده در فرم -> بخش اولین ردهٔ مشتری -> اولین بخش فعال سیستم
    local section_id = to_positive_int(inp("section_id"))
    if section_id == nil then
        section_id = to_positive_int(fetch_scalar([[
SELECT c.section_id FROM crm_cross x JOIN crm_classify_person c ON c.PROFILE_ID = x.REFERE_ID
WHERE x.CLIENT_ID = ? ORDER BY c.section_id LIMIT 1]], { client_id }))
    end
    if section_id == nil then
        section_id = to_positive_int(fetch_scalar("SELECT ID FROM crm_section ORDER BY S_ORDER, ID LIMIT 1"))
    end
    if section_id == nil then return { ok = false, error = "هیچ بخشی برای ثبت توضیح تعریف نشده است" } end
    local res = call_crm_api("/api/client/add/comment", { id = client_id, comment = comment, section_id = section_id })
    res.section_id = section_id
    if res.ok then
        teamyar.write_log("crm_customer_ui comment_add ok client=" .. client_id .. " by user=" .. current_user_id)
    end
    return res
end

-- اعتبارسنجی پروفایل: هر فیلد ناقص => کل درخواست رد می‌شود (نه ثبت ناقص)
local function validate_profile(profile, is_create)
    if _G.type(profile) ~= "table" then return "ساختار پروفایل نامعتبر است" end
    local user_type = to_int(profile.user_type)
    if user_type ~= 3 and user_type ~= 4 then return "نوع مشتری (حقیقی/حقوقی) مشخص نیست" end
    if trim(profile.name or "") == "" then return "نام الزامی است" end
    if user_type == 3 and trim(profile.last_name or "") == "" then return "نام خانوادگی برای مشتری حقیقی الزامی است" end
    for _, m in ipairs(profile.mobile or {}) do
        local d = digits_only(m.value)
        if d ~= "" and #d < 10 then return "شمارهٔ همراه «" .. tostring(m.value) .. "» نامعتبر است" end
        m.value = d
        m.country = to_int(m.country) or 364
    end
    for _, e in ipairs(profile.email or {}) do
        local v = trim(e.value or "")
        if v ~= "" and not v:match("^[%w%.%%%+%-_]+@[%w%.%-]+%.%a+$") then return "ایمیل «" .. v .. "» نامعتبر است" end
        e.value = v
    end
    for _, n in ipairs(profile.national_code or {}) do
        local d = digits_only(n.value)
        if d ~= "" and user_type == 3 and #d ~= 10 then return "کد ملی باید ۱۰ رقم باشد" end
        if d ~= "" and user_type == 4 and #d ~= 11 then return "شناسهٔ ملی حقوقی باید ۱۱ رقم باشد" end
        n.value = d
        n.country = to_int(n.country) or 364
    end
    for _, p in ipairs(profile.phone or {}) do
        p.value = digits_only(p.value)
        p.type = to_int(p.type) or 3
        p.country = to_int(p.country) or 364
    end
    -- تاریخ‌های شمسی فرم -> FILETIME (API عدد int64 می‌گیرد)؛ تاریخ نامعتبر = رد کل درخواست
    local date_fields = { { "birth_date_jalali", "birth_date", "تاریخ تولد" }, { "date_of_issue_jalali", "date_of_issue", "تاریخ صدور" } }
    for _, df in ipairs(date_fields) do
        local raw = profile[df[1]]
        if raw ~= nil and trim(raw) ~= "" then
            local ft = jalali_string_to_filetime(raw)
            if ft == nil then return df[3] .. " نامعتبر است (قالب 1370/01/01)" end
            profile[df[2]] = ft
        end
        profile[df[1]] = nil
    end
    if is_create then
        local has_contact = false
        for _, m in ipairs(profile.mobile or {}) do if m.value ~= "" then has_contact = true end end
        for _, e in ipairs(profile.email or {}) do if e.value ~= "" then has_contact = true end end
        if not has_contact then return "برای ایجاد مشتری دست‌کم یک شمارهٔ همراه یا ایمیل لازم است" end
    end
    return nil
end

local function action_client_update()
    local client_id = to_positive_int(inp("id"))
    if client_id == nil then return { ok = false, error = "شناسهٔ مشتری نامعتبر است" } end
    local payload, err = decode_json_input("payload")
    if payload == nil then return { ok = false, error = err } end
    local exists = fetch_scalar("SELECT COUNT(*) FROM crm_info WHERE ID = ? AND DELETED = 0", { client_id })
    if tonumber(exists) ~= 1 then return { ok = false, error = "مشتری یافت نشد یا حذف شده است" } end
    -- قانون کسب‌وکار (بات ۵۵۹): نوشتن CRM هرگز روی پروفایل پرسنل انجام نمی‌شود
    local is_staff = fetch_scalar("SELECT COUNT(*) FROM hr_personnels WHERE profile_id = ?", { client_id })
    if tonumber(is_staff) and tonumber(is_staff) > 0 then return { ok = false, error = "این پروفایل متعلق به پرسنل است و از این‌جا ویرایش نمی‌شود" } end
    if payload.profile ~= nil then
        local verr = validate_profile(payload.profile, false)
        if verr ~= nil then return { ok = false, error = verr } end
    end
    payload.id = client_id
    local res = call_crm_api("/api/client/update", payload)
    if res.ok then teamyar.write_log("crm_customer_ui client_update ok client=" .. client_id .. " by user=" .. current_user_id) end
    return res
end

local function action_client_check()
    local payload, err = decode_json_input("payload")
    if payload == nil then return { ok = false, error = err } end
    return call_crm_api("/api/client/check", payload)
end

local function action_client_create()
    local payload, err = decode_json_input("payload")
    if payload == nil then return { ok = false, error = err } end
    local verr = validate_profile(payload.profile, true)
    if verr ~= nil then return { ok = false, error = verr } end
    payload.id = 0
    payload.section_id = to_int(payload.section_id) or 0
    local res = call_crm_api("/api/client/create", payload)
    if res.ok then
        local new_id = nil
        if _G.type(res.api) == "table" and _G.type(res.api.data) == "table" then
            new_id = res.api.data.profile_id or res.api.data.id
        end
        res.new_id = new_id and tostring(new_id) or nil
        teamyar.write_log("crm_customer_ui client_create ok new_id=" .. tostring(new_id) .. " by user=" .. current_user_id)
        -- تست زنده ۱۴۰۵/۰۶/۱۲: create فیلدهای سطح بالا (comment/job/company/...) را ذخیره نمی‌کند — فقط update.
        -- پس همان فیلدها بلافاصله با update روی شناسهٔ جدید ثبت می‌شوند.
        if new_id ~= nil then
            local top_fields = { "comment", "company", "job", "website", "tin", "kpp", "industry", "number_personnel", "reg_number", "lable", "issue_activity", "property_code" }
            local follow = { id = to_int(new_id) }
            local has_any = false
            for _, k in ipairs(top_fields) do
                local v = payload[k]
                if v ~= nil and trim(v) ~= "" then follow[k] = v; has_any = true end
            end
            if has_any then res.followup_update = call_crm_api("/api/client/update", follow) end
        end
        -- عضویت در رده (اگر انتخاب شده بود) — category/add
        local category_id = to_positive_int(payload.category_id)
        if new_id ~= nil and category_id ~= nil then
            local cat = call_crm_api("/api/client/category/add", { id = to_int(new_id), category_id = category_id, category_profile_id = category_id })
            res.category_result = cat
        end
    end
    return res
end

local function action_contact_add()
    local client_id = to_positive_int(inp("id"))
    local contact, err = decode_json_input("contact")
    if client_id == nil then return { ok = false, error = "شناسهٔ مشتری نامعتبر است" } end
    if contact == nil then return { ok = false, error = err } end
    contact.type = to_int(contact.type) or 1
    contact.contact_id = to_int(contact.contact_id) or 0
    if contact.type ~= 2 and contact.contact_id <= 0 then return { ok = false, error = "رابط انتخاب نشده است" } end
    if contact.type == 2 and trim(contact.contact_text or "") == "" then return { ok = false, error = "عنوان رابط غیر تیم‌یاری الزامی است" } end
    return call_crm_api("/api/client/contact/add", { id = client_id, contact = { contact } })
end

local function action_contact_del()
    local client_id = to_positive_int(inp("id"))
    local contact_id = to_int(inp("contact_id"))
    local ctype = to_int(inp("type")) or 1
    if client_id == nil or contact_id == nil then return { ok = false, error = "شناسه‌ها نامعتبرند" } end
    return call_crm_api("/api/client/contact/del", { id = client_id, contact = { { type = ctype, contact_id = contact_id } } })
end

local function action_category_change(mode)
    local client_id = to_positive_int(inp("id"))
    local category_id = to_positive_int(inp("category_id"))
    if client_id == nil or category_id == nil then return { ok = false, error = "شناسهٔ مشتری یا رده نامعتبر است" } end
    -- تست زنده ۱۴۰۵/۰۶/۱۲: category_id = crm_classify_person.ID (شناسهٔ رده) و category_profile_id = PROFILE_ID
    -- (همان عددی که در crm_cross.REFERE_ID و URL رده استفاده می‌شود). ارسال PROFILE_ID به‌جای ID => INVALID_CATEGORY_ID
    local cat_row = fetch_row("SELECT ID, PROFILE_ID FROM crm_classify_person WHERE PROFILE_ID = ? OR ID = ? LIMIT 1", { category_id, category_id })
    if cat_row == nil then return { ok = false, error = "رده یافت نشد" } end
    local path = mode == "add" and "/api/client/category/add" or "/api/client/category/del"
    return call_crm_api(path, { id = client_id, category_id = to_int(cat_row[1]), category_profile_id = to_int(cat_row[2]) })
end

-- «مطلع» (assign) و «مسئول» (responsible): در هیچ جدول قابل‌کوئری این پایگاه‌داده پیدا نشدند (crm_assign خالی است،
-- crm_notify فهرست اعلان‌گیران رده است، نه مطلع) — پس خواندن از API رسمی (assign/get, responsible/get) انجام می‌شود.
-- نوشتن (تست زنده ۱۴۰۵/۰۶/۱۲): /api/client/assign/add کار می‌کند ولی assign/del و responsible/add|del با success=true
-- بی‌اثرند؛ راه معتبر همان POST هم‌مبدأ ماژول بومی /crm/client/assign/ با فهرست کاملِ جایگزین است
-- (type=0 مطلع، type=2 مسئول) که در app.js انجام می‌شود، با نشست و سطح دسترسی خودِ کاربر.
local function normalize_user_list(api_res)
    -- پاسخ assign/get یا responsible/get: آرایه‌ای از {id, name, ...} در data یا data.list
    local out = {}
    if not api_res.ok or _G.type(api_res.api) ~= "table" then return out end
    local data = api_res.api.data
    -- شکل واقعی پاسخ (تست زنده ۱۴۰۵/۰۶/۱۲): assign/get -> data.assigns[] ، responsible/get -> data.responsibles[]
    if _G.type(data) == "table" then
        if _G.type(data.assigns) == "table" then data = data.assigns
        elseif _G.type(data.responsibles) == "table" then data = data.responsibles
        elseif _G.type(data.list) == "table" then data = data.list
        elseif data.id ~= nil then data = {} end
    end
    if _G.type(data) ~= "table" then return out end
    for _, u in pairs(data) do
        if _G.type(u) == "table" then
            local uid = u.id or u.user_id or u.USER_ID
            if uid ~= nil then table.insert(out, { id = tostring(math.floor(tonumber(uid) or 0)), name = nz(u.name or u.title or u.FULLNAME, "کاربر #" .. tostring(uid)), type = to_int(u.type) or 0 }) end
        elseif tonumber(u) ~= nil then
            table.insert(out, { id = tostring(math.floor(tonumber(u))), name = "کاربر #" .. tostring(u), type = 0 })
        end
    end
    return out
end

local function fetch_relation_users(client_id, relation)
    return normalize_user_list(call_crm_api("/api/client/" .. relation .. "/get", { id = client_id }))
end

local function action_relation_get(relation)
    local client_id = to_positive_int(inp("id"))
    if client_id == nil then return { ok = false, error = "شناسهٔ مشتری نامعتبر است" } end
    local res = call_crm_api("/api/client/" .. relation .. "/get", { id = client_id })
    if not res.ok then return res end
    return { ok = true, users = normalize_user_list(res), api = res.api }
end

-- =========================================
-- ACCESS CONTROL — حق ارسال پیامک/ایمیل (قابل تنظیم از پنل «پیکربندی بات»)
-- =========================================
-- دسترسی ماژول‌های بومی جداست (sms_ty_permission روی هر صندوق پیامک، email_ty_permission روی هر صندوق ایمیل)، ولی
-- تحلیل زنده (۱۴۰۵/۰۶/۱۴) نشان داد بسیاری از فرستنده‌های واقعی هیچ ردیف مجوز روی صندوق ندارند و معنی بیت‌های PERM/ارث‌بری
-- گروهی معلوم نیست — پس آن جدول‌ها «حق ارسال» را قابل‌اعتماد نمی‌گویند. قاعدهٔ این بات:
--   ۱) اگر در پیکربندی بات فهرست مجاز تعریف شده باشد (sms_users/sms_groups، email_users/email_groups؛ شناسه‌های
--      کاماجدا)، فقط همان کاربران یا اعضای همان گروه‌ها (profile_group_member) مجازند.
--   ۲) در غیر این صورت (فهرست خالی) fallback = «دسترسی به ماژول»: داشتن هر ردیف در sms_ty_permission (پیامک) یا
--      هر ردیف در email_ty_permission یا مالکیت یک صندوق ایمیل (ایمیل).
-- کنترل هم در سرور (هر ارسال) و هم در UI (پنهان‌کردن دکمه‌ها) اعمال می‌شود؛ سرور مرجع است.
local function parse_id_list(raw)
    local ids = {}
    for token in tostring(raw or ""):gmatch("%d+") do table.insert(ids, tonumber(token)) end
    return ids
end

local access_config = nil
local function get_access_config()
    if access_config ~= nil then return access_config end
    access_config = { sms_users = {}, sms_groups = {}, email_users = {}, email_groups = {} }
    local ok, cfg = pcall(function() return teamyar.get_config() end)
    if ok and _G.type(cfg) == "table" and _G.type(cfg.data) == "table" then
        for key, _ in pairs(access_config) do access_config[key] = parse_id_list(cfg.data[key]) end
    end
    return access_config
end

local function user_in_lists(user_ids, group_ids)
    for _, uid in ipairs(user_ids) do if uid == current_user_id then return true end end
    if #group_ids > 0 then
        local n = fetch_scalar("SELECT COUNT(*) FROM profile_group_member WHERE USER_ID = ? AND GROUP_ID IN " .. id_list_sql(group_ids), { current_user_id })
        if tonumber(n) and tonumber(n) > 0 then return true end
    end
    return false
end

local perm_cache = {}
local function can_send(kind)
    if perm_cache[kind] ~= nil then return perm_cache[kind] end
    local cfg = get_access_config()
    local users, groups = cfg[kind .. "_users"], cfg[kind .. "_groups"]
    local allowed
    if #users > 0 or #groups > 0 then
        allowed = user_in_lists(users, groups)
    elseif kind == "sms" then
        allowed = (tonumber(fetch_scalar("SELECT COUNT(*) FROM sms_ty_permission WHERE USER_ID = ?", { current_user_id })) or 0) > 0
    else
        allowed = (tonumber(fetch_scalar("SELECT (SELECT COUNT(*) FROM email_ty_permission WHERE USER_ID = ?) + (SELECT COUNT(*) FROM email_box WHERE AUTHOR_ID = ? AND COALESCE(EMAIL,'') <> '')", { current_user_id, current_user_id })) or 0) > 0
    end
    perm_cache[kind] = allowed and true or false
    return perm_cache[kind]
end

permissions_summary = function()
    local cfg = get_access_config()
    return {
        can_sms = can_send("sms"), can_email = can_send("email"),
        sms_mode = (#cfg.sms_users > 0 or #cfg.sms_groups > 0) and "list" or "module",
        email_mode = (#cfg.email_users > 0 or #cfg.email_groups > 0) and "list" or "module",
    }
end

local ACCESS_DENIED_SMS = "شما مجوز ارسال پیامک از این ماژول را ندارید (تنظیم در پیکربندی بات یا دسترسی ماژول پیامک)"
local ACCESS_DENIED_EMAIL = "شما مجوز ارسال ایمیل از این ماژول را ندارید (تنظیم در پیکربندی بات یا دسترسی ماژول پست)"

-- =========================================
-- SMS (ماژول ۱۶) — ارسال پیامک از پروفایل/لیست با API رسمی؛ همان payload تأییدشدهٔ بات‌های ۵۰۱/۳۷۱/۳۵۲
-- =========================================
local SMS_MAX_CHARS = 1000
local SMS_MODULE_SENDER = 26 -- «باتی»: همان module_id که بات‌های پیامکی این سامانه ارسال می‌کنند

local function action_sms_boxes()
    if not can_send("sms") then return { ok = false, error = ACCESS_DENIED_SMS } end
    local rows = fetch_rows("SELECT ID, NAME, IS_DEFAULT FROM sms_box WHERE ENABLE = 1 ORDER BY IS_DEFAULT DESC, ID", {}) or {}
    return { ok = true, boxes = rows_to_objects(rows, function(r) return { id = to_int(r[1]), name = nz(r[2], "صندوق " .. tostring(r[1])), is_default = to_int(r[3]) == 1 } end) }
end

local function action_sms_send()
    local client_id = to_positive_int(inp("id"))
    local content = trim(inp("content") or "")
    local box_id = to_positive_int(inp("box_id"))
    local mobile = digits_only(inp("mobile"))
    if not can_send("sms") then return { ok = false, error = ACCESS_DENIED_SMS } end
    if client_id == nil then return { ok = false, error = "شناسهٔ مشتری نامعتبر است" } end
    if content == "" then return { ok = false, error = "متن پیامک خالی است" } end
    if #content > SMS_MAX_CHARS then return { ok = false, error = "متن پیامک بیش از حد بلند است" } end
    -- اعتبارسنجی: مشتری فعال باشد، شماره متعلق به همان مشتری باشد (یا اولین شمارهٔ ثبت‌شده‌اش)، صندوق فعال باشد
    local exists = fetch_scalar("SELECT COUNT(*) FROM crm_info WHERE ID = ? AND DELETED = 0", { client_id })
    if tonumber(exists) ~= 1 then return { ok = false, error = "مشتری یافت نشد یا حذف شده است" } end
    local mobile_rows = fetch_rows("SELECT MOBILE, COUNTRY_CODE FROM profile_mobile WHERE USER_ID = ? ORDER BY ID", { client_id }) or {}
    if #mobile_rows == 0 then return { ok = false, error = "برای این مشتری شمارهٔ همراهی ثبت نشده است" } end
    local chosen, country = nil, 364
    for _, r in ipairs(mobile_rows) do
        local m = digits_only(r[1])
        if mobile == "" or m == mobile or m:sub(-10) == mobile:sub(-10) then chosen = m; country = to_int(r[2]) or 364; break end
    end
    if chosen == nil then return { ok = false, error = "شمارهٔ انتخاب‌شده متعلق به این مشتری نیست" } end
    if box_id ~= nil then
        local box_ok = fetch_scalar("SELECT COUNT(*) FROM sms_box WHERE ID = ? AND ENABLE = 1", { box_id })
        if tonumber(box_ok) ~= 1 then return { ok = false, error = "صندوق پیامک نامعتبر است" } end
    end
    local payload = { module_id = SMS_MODULE_SENDER, messages = { { content = content, send_to = { mobile_numbers = { { value = chosen, country = country } } } } } }
    if box_id ~= nil then payload.box_id = box_id end
    local ok, res = pcall(function() return teamyar.call_api(16, "/api/sms/send", payload) end)
    if not ok or _G.type(res) ~= "table" then
        teamyar.write_log("crm_customer_ui sms_send call error: " .. tostring(res))
        return { ok = false, error = "خطا در فراخوانی سرویس پیامک: " .. tostring(res) }
    end
    if res.success ~= true then
        local msg = res.error
        if _G.type(msg) == "table" then msg = msg.message or json.encode(msg) end
        return { ok = false, error = "ارسال ناموفق: " .. tostring(msg or "خطای نامشخص"), api = res }
    end
    local ids = (res.data and res.data.message_ids) or {}
    teamyar.write_log("crm_customer_ui sms_send ok client=" .. client_id .. " to=" .. chosen .. " by user=" .. current_user_id .. " ids=" .. json.encode(ids))
    return { ok = true, mobile = chosen, message_ids = ids }
end

-- =========================================
-- EMAIL (ماژول ۱۲) — ارسال از پروفایل/لیست با /api/email/emailmsgadd (همان payload کارکردهٔ بات‌های ۳۵۲/۳۹۱/۴۴۲)
-- =========================================
local EMAIL_MAX_CHARS = 20000

local function action_email_boxes()
    if not can_send("email") then return { ok = false, error = ACCESS_DENIED_EMAIL } end
    -- صندوق‌های ایمیل کاربر جاری (email_box.AUTHOR_ID). TRASH_STATUS فیلتر نمی‌شود: صندوق ۱۹ (info@) با TRASH_STATUS=1
    -- فعال‌ترین فرستنده است (۶۷۳ ارسال) — آن ستون «حذف‌شده» نیست. DEFAULT_BOX=1 پیش‌فرض؛ پرکارترین‌ها اول.
    local rows = fetch_rows([[
SELECT b.ID, b.NAME, b.EMAIL, b.DEFAULT_BOX,
       (SELECT COUNT(*) FROM email_message m WHERE m.BOX_ID = b.ID AND m.SEND_FLAG = 1) AS sent
FROM email_box b
WHERE b.AUTHOR_ID = ? AND COALESCE(b.EMAIL,'') <> ''
ORDER BY b.DEFAULT_BOX DESC, sent DESC, b.ID]], { current_user_id }) or {}
    return { ok = true, boxes = rows_to_objects(rows, function(r) return { id = to_int(r[1]), name = nz(r[2], "") , email = nz(r[3], ""), is_default = to_int(r[4]) == 1 } end) }
end

local function action_email_send()
    local client_id = to_positive_int(inp("id"))
    local address = trim(inp("address") or "")
    local subject = trim(inp("subject") or "")
    local content = trim(inp("content") or "")
    local box_id = to_positive_int(inp("box_id"))
    if not can_send("email") then return { ok = false, error = ACCESS_DENIED_EMAIL } end
    if client_id == nil then return { ok = false, error = "شناسهٔ مشتری نامعتبر است" } end
    if subject == "" then return { ok = false, error = "موضوع ایمیل خالی است" } end
    if content == "" then return { ok = false, error = "متن ایمیل خالی است" } end
    if #content > EMAIL_MAX_CHARS then return { ok = false, error = "متن ایمیل بیش از حد بلند است" } end
    local exists = fetch_scalar("SELECT COUNT(*) FROM crm_info WHERE ID = ? AND DELETED = 0", { client_id })
    if tonumber(exists) ~= 1 then return { ok = false, error = "مشتری یافت نشد یا حذف شده است" } end
    -- گیرنده باید یکی از ایمیل‌های ثبت‌شدهٔ همان مشتری باشد (خالی => اولین ایمیل)
    local email_rows = fetch_rows("SELECT EMAIL FROM profile_email WHERE USER_ID = ? ORDER BY ID", { client_id }) or {}
    if #email_rows == 0 then return { ok = false, error = "برای این مشتری ایمیلی ثبت نشده است" } end
    local chosen = nil
    for _, r in ipairs(email_rows) do
        local e = trim(r[1] or "")
        if e ~= "" and (address == "" or e:lower() == address:lower()) then chosen = e; break end
    end
    if chosen == nil then return { ok = false, error = "ایمیل انتخاب‌شده متعلق به این مشتری نیست" } end
    if box_id ~= nil then
        local box_ok = fetch_scalar("SELECT COUNT(*) FROM email_box WHERE ID = ? AND AUTHOR_ID = ? AND COALESCE(EMAIL,'') <> ''", { box_id, current_user_id })
        if tonumber(box_ok) ~= 1 then return { ok = false, error = "صندوق ایمیل نامعتبر است یا متعلق به شما نیست" } end
    end
    -- متن ساده به HTML امن (خطوط جدید => <br>)؛ هیچ HTML خام کاربر عبور نمی‌کند
    local html_content = escape_html(content):gsub("\r\n", "\n"):gsub("\n", "<br>")
    local payload = { address = chosen, email_subject = subject, email_content = html_content }
    if box_id ~= nil then payload.box_id = box_id end
    local ok, res = pcall(function() return teamyar.call_api(12, "/api/email/emailmsgadd", payload) end)
    if not ok or _G.type(res) ~= "table" then
        teamyar.write_log("crm_customer_ui email_send call error: " .. tostring(res))
        return { ok = false, error = "خطا در فراخوانی سرویس ایمیل: " .. tostring(res) }
    end
    if res.success ~= true then
        local msg = res.error
        if _G.type(msg) == "table" then msg = msg.message or json.encode(msg) end
        local translations = { ERR_INVALID_BOX = "صندوق ایمیل نامعتبر است (تنظیمات ارسال صندوق را در ماژول پست بررسی کنید)", SUBJECT_EMPTY = "موضوع ایمیل خالی است" }
        return { ok = false, error = "ارسال ناموفق: " .. (translations[tostring(msg)] or tostring(msg or "خطای نامشخص")), api = res }
    end
    local message_id = res.data and res.data.email_message_id or nil
    teamyar.write_log("crm_customer_ui email_send ok client=" .. client_id .. " to=" .. chosen .. " by user=" .. current_user_id .. " msg=" .. tostring(message_id))
    return { ok = true, address = chosen, message_id = message_id }
end

-- =========================================
-- SHELL HTML
-- =========================================
local function render_shell()
    local v = CONFIG.ASSET_VERSION
    local css_url = CONFIG.ASSET_BASE .. "/app.css?v=" .. v
    local js_url = CONFIG.ASSET_BASE .. "/app.js?v=" .. v
    local parts = {}
    table.insert(parts, '<!DOCTYPE html>\n<html dir="rtl" lang="fa">\n<head>\n<meta charset="UTF-8">\n')
    table.insert(parts, '<meta name="viewport" content="width=device-width, initial-scale=1">\n')
    table.insert(parts, '<title>CRM مشتریان</title>\n')
    table.insert(parts, '<link rel="stylesheet" href="' .. escape_html(css_url) .. '">\n')
    table.insert(parts, '</head>\n<body>\n')
    table.insert(parts, '<div id="crm606" class="crm606-root" data-crm606-root="1"')
    table.insert(parts, ' data-run-url="' .. escape_html(CONFIG.BOT_RUN_URL) .. '"')
    table.insert(parts, ' data-base-url="' .. escape_html(CONFIG.BASE_URL) .. '"')
    table.insert(parts, ' data-user-id="' .. escape_html(current_user_id) .. '"')
    table.insert(parts, ' data-version="' .. escape_html(v) .. '"')
    table.insert(parts, ' data-page-size="' .. escape_html(CONFIG.PAGE_SIZE) .. '"')
    table.insert(parts, ' data-site-bot="' .. escape_html("/bot/run/" .. CONFIG.SITE_VIEW_BOT_PATH) .. '"')
    table.insert(parts, ' data-site-marker="' .. escape_html(CONFIG.SITE_ID_MARKER) .. '"')
    table.insert(parts, ' data-site-login="' .. escape_html("/bot/run/" .. CONFIG.SITE_LOGIN_BOT_PATH) .. '"')
    table.insert(parts, ' data-logo="data:image/png;base64,' .. CONFIG.LOGO140_WHITE_B64 .. '">\n')
    table.insert(parts, '  <div class="crm606-boot">در حال بارگذاری ماژول مشتریان…</div>\n')
    table.insert(parts, '</div>\n')
    table.insert(parts, '<script src="' .. escape_html(js_url) .. '"></script>\n')
    table.insert(parts, '<script>\n')
    table.insert(parts, 'if (!window.CRM606) { var b = document.querySelector("#crm606 .crm606-boot"); if (b) { b.textContent = "فایل رابط کاربری (app.js) بارگذاری نشد — پیوست‌های بات را بررسی کنید."; } }\n')
    table.insert(parts, '</script>\n</body>\n</html>')
    return table.concat(parts)
end

-- =========================================
-- DISPATCH
-- =========================================
local ACTIONS = {
    list          = action_list,
    export        = action_export,
    tree          = action_tree,
    client        = function()
        local res = action_client()
        if res.ok then
            -- «مطلع» و «مسئول» فقط از API خوانده می‌شوند (جدول قابل‌کوئری ندارند)
            res.client.assigned = fetch_relation_users(to_int(res.client.id), "assign")
            res.client.responsible = fetch_relation_users(to_int(res.client.id), "responsible")
            res.client.is_assigned = false
            for _, u in ipairs(res.client.assigned) do if tostring(u.id) == tostring(current_user_id) then res.client.is_assigned = true end end
        end
        return res
    end,
    counts        = action_counts,
    tab           = action_tab,
    lookup        = action_lookup,
    api_get       = action_api_get,
    comment_add   = action_comment_add,
    client_update = action_client_update,
    client_create = action_client_create,
    client_check  = action_client_check,
    contact_add   = action_contact_add,
    contact_del   = action_contact_del,
    category_add  = function() return action_category_change("add") end,
    category_del  = function() return action_category_change("del") end,
    -- مطلع/مسئول: فقط خواندن از API؛ نوشتن در کلاینت با POST هم‌مبدأ /crm/client/assign/ (type 0 مطلع، 2 مسئول)
    assign_get    = function() return action_relation_get("assign") end,
    responsible_get = function() return action_relation_get("responsible") end,
    whoami        = function() return { ok = true, user_id = current_user_id, version = CONFIG.ASSET_VERSION, perms = permissions_summary() } end,
    sms_boxes     = action_sms_boxes,
    sms_send      = action_sms_send,
    email_boxes   = action_email_boxes,
    email_send    = action_email_send,
}

local function main()
    if action == "" then
        teamyar.write_result(render_shell())
        return
    end
    local handler = ACTIONS[action]
    if handler == nil then
        teamyar.write_result(json.encode({ ok = false, error = "عملیات ناشناخته: " .. action }))
        return
    end
    local ok, result = pcall(handler)
    if not ok then
        teamyar.write_log("crm_customer_ui action error [" .. action .. "]: " .. tostring(result))
        teamyar.write_result(json.encode({ ok = false, error = "خطای داخلی بات: " .. tostring(result) }))
        return
    end
    teamyar.write_result(json.encode(result))
end

local main_ok, main_err = pcall(main)
if not main_ok then
    teamyar.write_log("crm_customer_ui fatal: " .. tostring(main_err))
    if action ~= "" then
        teamyar.write_result(json.encode({ ok = false, error = "خطای داخلی بات" }))
    else
        teamyar.write_result('<!DOCTYPE html><html dir="rtl" lang="fa"><head><meta charset="UTF-8"><title>خطا</title></head><body style="font-family:tahoma;padding:2rem;text-align:center;font-size:14px;"><h2 style="color:#16509D;font-size:15px;">خطایی در بارگذاری صفحه رخ داد. لطفاً دوباره تلاش کنید.</h2></body></html>')
    end
end
