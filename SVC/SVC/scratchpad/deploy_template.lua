-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/05/24 12:15

-- Bot: CRM + Sales Geographic Dashboard
-- botName = crm_geo_sales_dashboard
-- version = v02
-- تغییرات v02 (طبق بازخورد کاربر روی v01): لوگو ۱۴۰ (نسخه White) به هدر اضافه شد؛ برچسب نوع مشتری
-- «حقیقی»/«حقوقی» شد (تأییدشده از بات‌های ۴۳۳/۴۴۰)؛ فرمول مبلغ فاکتور به فرمول واقعی Production تغییر
-- کرد (ر.ک. INVOICE_AMOUNT_JOIN و docs/context/SalesReportBotsReference.md)؛ کارت‌های KPI و کیفیت داده
-- بالای صفحه Clickable شدند (Drill-down به بخش مرتبط).

-- داشبورد مدیریتی توزیع جغرافیایی مشتریان CRM و فروش (استان/شهر) — بر پایهٔ دادهٔ زندهٔ
-- crm_info / profile_main / profile_user_address / pa_client / sales_invoice / report_dimdate.
--
-- Mapping اعتبارسنجی‌شده (Discovery در 1405/05/23 روی بات ۵۸۹ = schema_probe_v2، با Query واقعی
-- روی داده زنده تأیید شد — چیزی حدس زده نشده):
--   شناسه CRM     = crm_info.ID = profile_main.ID = pa_client.REFFERE_ID  (روی ۲۰ نمونه واقعی تأیید شد)
--   نام مشتری     = profile_main.FULLNAME   (crm_info هیچ ستون نامی ندارد — تست شد)
--   آدرس مشتری    = profile_user_address (USER_ID = شناسه CRM) — هر مشتری دقیقاً ۲ ردیف آدرس دارد:
--                    TYPE=1 آدرس واقعی (۹۱٪ موارد پر است) و TYPE=2 که عملاً همیشه خالی است (۹۹.۳٪ خالی).
--                    Rule قطعی: فقط addr.TYPE=1 به‌عنوان «آدرس مشتری» در نظر گرفته می‌شود. Validate شد:
--                    بدون این فیلتر Join مستقیم به آدرس، فروش را دقیقاً ۲برابر می‌کند (187,761→372,432
--                    فاکتور و مبلغ هم دقیقاً ۲برابر)؛ با addr.TYPE=1 دقیقاً برابر با قبل از Join است.
--   فاکتور معتبر  = sales_invoice: DELETED=0 AND CANCELED=0 AND PRE_INVOICE=0
--   مبلغ فاکتور   = دیگر RECEPTION_AMOUNT+REMAINED_AMOUNT نیست (v01 اولیه) — از v02 به بعد فرمول واقعی
--    Production از دو بات مستقل (id=433/440، ر.ک. INVOICE_AMOUNT_JOIN پایین‌تر و
--    docs/context/SalesReportBotsReference.md یافتهٔ ۳): SUM روی sales_invoice_product با علامت منفی
--    برای TYPE=3 (برگشت از فروش)، به تأیید صریح کاربر (1405/05/24).
--   کد فاکتور     = sales_invoice.INVOICE_CODE (تست شد، ستون واقعی موجود است)
--   pa_client.REFFERE_ID یکتا نیست (یک مشتری CRM می‌تواند چند ردیف pa_client داشته باشد — تست شد،
--    مثال REFFERE_ID=10053 چهار ردیف pa_client دارد). این مشکلی برای SUM/COUNT فروش ایجاد نمی‌کند چون
--    هر sales_invoice.CLIENT_ID دقیقاً به یک pa_client.ID متصل است؛ به همین دلیل همه‌جا برای شمارش
--    مشتری از COUNT(DISTINCT crm_info.ID) استفاده شده، نه از pa_client.ID.
--   مرجع استان/شهر = crm_state_city بررسی و رد شد: فقط ۲۷٪ از جفت‌های (استان,شهر) واقعاً مصرف‌شده در
--    profile_user_address با آن تطبیق داشت؛ شهرهایی مثل شیراز/تبریز/مشهد اصلاً در آن جدول نبودند
--    (آن جدول فهرست ریزمحله/کدپستی است، نه فهرست رسمی شهر). به تأیید صریح کاربر پروژه (1405/05/23)،
--    مخرج KPI «پوشش جغرافیایی» = عدد ثابت مستند CONFIG.TOTAL_CITIES_IRAN (منبع در همان‌جا نوشته شده).
--   تاریخ فاکتور  = sales_invoice.RUN_DATE (FILETIME، تیک ۱۰۰ns از ۱۶۰۱) — تبدیل شمسی فقط از طریق
--    report_dimdate.DATEKEY/JNDATE انجام می‌شود، نه REPORT_FN_JDATE (که در بات‌های دیگر این پروژه با
--    خطای عمومی مواجه شده) و نه تقویم دستی Lua. برای Join یک ردیف فاکتور به روز مربوطه از الگوی
--    تأییدشدهٔ hr_dashboard_report_bot.lua استفاده شده: rd.DATEKEY = (RUN_DATE - MOD(RUN_DATE, 864000000000)).
--    نکتهٔ حیاتی: FILETIME (~1.3e17) از سقف عدد صحیح دقیق double (2^53) عبور می‌کند — تفریق/باقیمانده
--    روی این مقادیر همیشه در SQL انجام می‌شود، هرگز در Lua؛ در Lua این مقادیر فقط به‌عنوان پارامتر
--    Opaque بین دو Query رد و بدل می‌شوند (نه محاسبه‌شده) — دقیقاً همان قرارداد بات‌های دیگر پروژه.
--   نوع مشتری     = profile_user_info.USER_TYPE (تست شد: فقط دو مقدار در دادهٔ زنده — 3 و 4). برچسب
--    فارسی دقیق هر کد در هیچ جدول Enum/کامنتی تأیید نشد؛ در این نسخه به‌صورت خام «نوع ۳»/«نوع ۴» نمایش
--    داده می‌شود تا برچسب حدسی ساخته نشود — اگر معنای دقیق را دارید، در v02 جایگزین می‌شود.
--   سال مالی جاری = پیش‌فرض فیلتر تاریخ، به‌صورت پویا از report_dimdate محاسبه می‌شود (نه hardcode)،
--    طبق درخواست صریح کاربر برای محدودکردن گزارش به سال مالی جاری.

-- ============================================================
-- CONFIG
-- ============================================================

local CONFIG = {
    -- منبع: آمار رسمی شهرهای ایران، سال ۱۴۰۴ — تأیید صریح کاربر پروژه در جلسهٔ طراحی این بات
    -- (1405/05/23). هیچ جدول مرجع معتبری در دیتابیس Teamyar برای این عدد پیدا نشد (ر.ک. یادداشت بالا)؛
    -- این تنها استثنای مصوب hardcode در کل این بات است.
    TOTAL_CITIES_IRAN = 1458,
    DAY_TICKS = 864000000000, -- یک روز بر حسب تیک FILETIME (10,000,000 * 86400) — فقط در SQL استفاده می‌شود
    CUSTOMER_PAGE_SIZE = 50,
    TOP_CITIES_ON_DASHBOARD = 20,
    OTHER_SLICE_THRESHOLD_PCT = 2.0, -- استان‌های زیر این سهم در نمودار Donut داخل «سایر» گروه می‌شوند
    ADDRESS_TYPE_PRIMARY = 1,
    CRM_EDIT_URL_PREFIX = "/?page=/crm/client/edit/",
    CRM_EDIT_URL_SUFFIX = "&section=2",
    INVOICE_VIEW_URL_PREFIX = "/?page=/sales/invoice/view_invoice/",
    -- تأییدشده (نه حدس) — از دو بات تولیدی مستقل («گزارش جامع فروش نسخه اصلی» id=433 و
    -- «گزارش فروش به تفکیک فاکتور» id=440، هر دو profile_user_info.USER_TYPE): 3=حقیقی، 4=حقوقی
    -- (ر.ک. docs/context/SalesReportBotsReference.md یافتهٔ ۱)
    USER_TYPE_LABELS = { ["3"] = "حقیقی", ["4"] = "حقوقی" },
    -- لوگو «۱۴۰» (الزام CLAUDE.md برای بات‌های HTML جدید) — نسخهٔ White، چون روی نوار Accent هدر می‌نشیند
    LOGO140_WHITE_B64 = "__LOGO140_WHITE_B64__",
}

-- ============================================================
-- HELPERS
-- ============================================================

-- پیاده‌سازی مرجع escape_html برای فایل‌های جدید (طبق CLAUDE.md) — literal مستقیم
local function escape_html(value)
    if value == nil then return "" end
    return tostring(value)
        :gsub("&", "&amp;")
        :gsub("<", "&lt;")
        :gsub(">", "&gt;")
        :gsub('"', "&quot;")
        :gsub("'", "&#39;")
end

local function fmt_num(value)
    local n = tonumber(value)
    if n == nil then return "0" end
    local s = tostring(math.floor(n + 0.5))
    local sign = ""
    if s:sub(1, 1) == "-" then
        sign = "-"
        s = s:sub(2)
    end
    return sign .. s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function fmt_dec1(value)
    local n = tonumber(value)
    if n == nil then return "0.0" end
    return string.format("%.1f", n)
end

local function fmt_pct(part, total)
    local t = tonumber(total) or 0
    if t <= 0 then return 0.0 end
    return (tonumber(part) or 0) / t * 100.0
end

local function safe_str(v, default_v)
    if v == nil or v == "" then return default_v or "—" end
    return tostring(v)
end

local function user_type_label(code)
    if code == nil then return "نامشخص" end
    return CONFIG.USER_TYPE_LABELS[tostring(code)] or ("نوع " .. tostring(code))
end

-- ============================================================
-- DATABASE HELPERS
-- ============================================================

local function fetch_rows(query, params)
    pcall(function() db.use_db("0000000") end)
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

-- ============================================================
-- DATE HELPERS (فقط report_dimdate — بدون REPORT_FN_JDATE و بدون محاسبهٔ دستی Lua)
-- ============================================================

local function fetch_now_raw()
    local rows, err = fetch_rows("SELECT (UNIX_TIMESTAMP() + 11644473600) * 10000000 AS now_raw", {})
    if rows == nil or #rows == 0 then return nil, err end
    return rows[1][1]
end

-- ابتدای سال مالی جاری (شمسی) را به‌صورت پویا از report_dimdate پیدا می‌کند — بدون hardcode سال
local function resolve_fiscal_year_start(now_raw)
    if now_raw == nil then return nil, nil end
    local year_rows = fetch_rows(
        "SELECT JYEAR FROM report_dimdate WHERE DATEKEY = (? - MOD(?, " .. CONFIG.DAY_TICKS .. ")) LIMIT 1",
        { now_raw, now_raw })
    if year_rows == nil or #year_rows == 0 then return nil, nil end
    local jyear = year_rows[1][1]
    local jndate = tostring(jyear) .. "/01/01"
    local key_rows = fetch_rows("SELECT DATEKEY FROM report_dimdate WHERE JNDATE = ? LIMIT 1", { jndate })
    if key_rows == nil or #key_rows == 0 then return nil, jndate end
    return key_rows[1][1], jndate
end

-- ورودی متنی کاربر (شمسی "1405/01/01") را به DATEKEY تبدیل می‌کند؛ نامعتبر/یافت‌نشده => nil (بدون خطا)
local function resolve_date_from_text(text)
    if text == nil then return nil end
    text = tostring(text):gsub("^%s+", ""):gsub("%s+$", "")
    if not text:match("^%d%d%d%d/%d%d?/%d%d?$") then return nil end
    local rows = fetch_rows("SELECT DATEKEY FROM report_dimdate WHERE JNDATE = ? LIMIT 1", { text })
    if rows == nil or #rows == 0 then return nil end
    return rows[1][1]
end

-- ============================================================
-- INPUT / FILTER PARSING
-- ============================================================

local function parse_filters(input)
    input = input or {}
    local state = input["state"]
    if state == "" then state = nil end
    local city = input["city"]
    if city == "" then city = nil end
    local user_type = tonumber(input["user_type"])
    local date_from_text = input["date_from"]
    if date_from_text == "" then date_from_text = nil end
    return {
        state = state,
        city = city,
        user_type = user_type,
        date_from_text = date_from_text,
    }
end

-- ============================================================
-- INVOICE AMOUNT (فرمول واقعی Production)
-- ============================================================
-- منبع: دو بات تولیدی مستقل («گزارش جامع فروش نسخه اصلی» id=433 و «گزارش فروش به تفکیک فاکتور» id=440 —
-- ر.ک. docs/context/SalesReportBotsReference.md یافتهٔ ۳). به تأیید صریح کاربر (1405/05/24) جایگزین
-- RECEPTION_AMOUNT+REMAINED_AMOUNT شد چون آن فرمول برگشت‌ازفروش (sales_invoice.TYPE=3) را کسر نمی‌کرد.
-- مبلغ هر فاکتور = SUM روی ردیف‌های sales_invoice_product: (FEE/۱۰^رقم‌اعشار × QUANTITY/۱۰^رقم‌اعشار‌انبار)
-- - DISCOUNT + VALUE_ADDED + TAX/۱۰^رقم‌اعشار + TOLL/۱۰^رقم‌اعشار — با علامت منفی برای TYPE=3 (برگشت از فروش).
-- توجه Performance: این Subquery روی کل sales_invoice_product (بدون فیلتر تاریخ) SUM می‌گیرد — چون GROUP BY
-- دارد، MySQL معمولاً آن را قبل از JOIN با si کامل می‌سازد (Derived Table Merge برای Query های Aggregate
-- تضمین‌شده نیست). قبل از اجرای زنده روی محیط Production، زمان اجرا را بررسی کنید؛ اگر کند بود، Index روی
-- sales_invoice_product(INVOICE_ID) (احتمالاً به‌عنوان FK از قبل موجود است) را تأیید کنید — بدون اجازهٔ کاربر
-- Index جدید ساخته نشود.
local INVOICE_AMOUNT_JOIN = [[
LEFT JOIN (
    SELECT
        ip.INVOICE_ID AS invoice_id,
        SUM(
            (CASE WHEN i2.TYPE = 3 THEN -1 ELSE 1 END) *
            (
                COALESCE((ip.QUANTITY / POW(10, COALESCE(sc.DECIMAL_NUM, 0))) * (ip.FEE / POW(10, COALESCE(dd.digit_fee, 0))), 0)
                - COALESCE(ip.DISCOUNT, 0)
                + COALESCE(ip.VALUE_ADDED, 0)
                + COALESCE(ip.TAX / POW(10, COALESCE(dd.digit_fee, 0)), 0)
                + COALESCE(ip.TOLL / POW(10, COALESCE(dd.digit_fee, 0)), 0)
            )
        ) AS amount
    FROM sales_invoice_product ip
    INNER JOIN sales_invoice i2 ON i2.ID = ip.INVOICE_ID
    LEFT JOIN wh_product wp ON wp.ID = ip.PRODUCT_ID
    LEFT JOIN wh_stock_capacity sc ON sc.ID = wp.CAPACITY_ID
    LEFT JOIN (
        SELECT po.ORG_ID,
            (CASE WHEN COALESCE(ps.FEE_DECIMAL, 0) = 0 THEN COALESCE(ps.DECIMAL_COUNT, 0) ELSE COALESCE(ps.FEE_DECIMAL, 0) END) AS digit_fee
        FROM pa_organizations po
        INNER JOIN pa_symbols ps ON ps.ID = po.BASE_CURRENCY AND ps.ORG_ID = po.ORG_ID
    ) dd ON dd.ORG_ID = i2.ORG_ID
    GROUP BY ip.INVOICE_ID
) ia ON ia.invoice_id = si.ID
]]

-- ============================================================
-- EXECUTIVE KPI QUERIES
-- ============================================================

-- سمت CRM/مشتری — بدون بازهٔ تاریخ (مستقل از فروش)
local function fetch_crm_kpi()
    local rows, err = fetch_rows([[
SELECT
    COUNT(DISTINCT ci.ID) AS total_crm_customers,
    COUNT(DISTINCT CASE WHEN addr.STATE IS NOT NULL AND addr.STATE <> '' THEN addr.STATE END) AS states_with_customers,
    COUNT(DISTINCT CASE WHEN addr.CITY IS NOT NULL AND addr.CITY <> '' THEN addr.CITY END) AS cities_with_customers,
    SUM(CASE WHEN addr.USER_ID IS NULL OR addr.STATE IS NULL OR addr.STATE = '' THEN 1 ELSE 0 END) AS customers_without_state,
    SUM(CASE WHEN addr.USER_ID IS NULL OR addr.CITY IS NULL OR addr.CITY = '' THEN 1 ELSE 0 END) AS customers_without_city
FROM crm_info ci
LEFT JOIN profile_user_address addr ON addr.USER_ID = ci.ID AND addr.TYPE = ]] .. CONFIG.ADDRESS_TYPE_PRIMARY .. [[
]], {})
    if rows == nil or #rows == 0 then return nil, err end
    local r = rows[1]
    return {
        total_crm_customers = tonumber(r[1]) or 0,
        states_with_customers = tonumber(r[2]) or 0,
        cities_with_customers = tonumber(r[3]) or 0,
        customers_without_state = tonumber(r[4]) or 0,
        customers_without_city = tonumber(r[5]) or 0,
    }
end

-- سمت فروش — پارامتری با بازهٔ تاریخ + فیلتر استان/شهر/نوع مشتری اختیاری
local function build_sales_filter_clause(filters)
    local extra = ""
    local params = {}
    if filters.state ~= nil then
        extra = extra .. " AND addr.STATE = ?"
        table.insert(params, filters.state)
    end
    if filters.city ~= nil then
        extra = extra .. " AND addr.CITY = ?"
        table.insert(params, filters.city)
    end
    if filters.user_type ~= nil then
        extra = extra .. " AND ui.USER_TYPE = ?"
        table.insert(params, filters.user_type)
    end
    return extra, params
end

local function fetch_sales_kpi(date_from_key, filters)
    local extra, extra_params = build_sales_filter_clause(filters)
    local params = { date_from_key }
    for _, p in ipairs(extra_params) do table.insert(params, p) end

    local rows, err = fetch_rows([[
SELECT
    COUNT(si.ID) AS total_valid_invoices,
    COUNT(DISTINCT ci.ID) AS buyer_customers,
    COALESCE(SUM(ia.amount), 0) AS total_sales_amount,
    COUNT(DISTINCT CASE WHEN addr.STATE IS NOT NULL AND addr.STATE <> '' THEN addr.STATE END) AS states_with_sales,
    COUNT(DISTINCT CASE WHEN addr.CITY IS NOT NULL AND addr.CITY <> '' THEN addr.CITY END) AS cities_with_sales,
    SUM(CASE WHEN addr.USER_ID IS NULL OR addr.STATE IS NULL OR addr.STATE = '' OR addr.CITY IS NULL OR addr.CITY = '' THEN 1 ELSE 0 END) AS invoices_without_geo_mapping
FROM sales_invoice si
INNER JOIN pa_client pc ON pc.ID = si.CLIENT_ID
INNER JOIN crm_info ci ON ci.ID = pc.REFFERE_ID
LEFT JOIN profile_user_address addr ON addr.USER_ID = pc.REFFERE_ID AND addr.TYPE = ]] .. CONFIG.ADDRESS_TYPE_PRIMARY .. [[

LEFT JOIN profile_user_info ui ON ui.ID = pc.REFFERE_ID
]] .. INVOICE_AMOUNT_JOIN .. [[
WHERE si.DELETED = 0 AND si.CANCELED = 0 AND si.PRE_INVOICE = 0
  AND si.RUN_DATE >= ?]] .. extra .. [[
]], params)
    if rows == nil or #rows == 0 then return nil, err end
    local r = rows[1]
    return {
        total_valid_invoices = tonumber(r[1]) or 0,
        buyer_customers = tonumber(r[2]) or 0,
        total_sales_amount = tonumber(r[3]) or 0,
        states_with_sales = tonumber(r[4]) or 0,
        cities_with_sales = tonumber(r[5]) or 0,
        invoices_without_geo_mapping = tonumber(r[6]) or 0,
    }
end

-- ============================================================
-- STATE / CITY AGGREGATION
-- ============================================================

local function fetch_state_aggregation(date_from_key, filters)
    local extra, extra_params = build_sales_filter_clause(filters)
    local params = { date_from_key, date_from_key }
    for _, p in ipairs(extra_params) do table.insert(params, p) end

    local rows, err = fetch_rows([[
SELECT
    addr.STATE AS state_name,
    COUNT(DISTINCT ci.ID) AS unique_customer_count,
    COUNT(DISTINCT CASE WHEN si.ID IS NOT NULL THEN ci.ID END) AS buyer_count,
    COUNT(si.ID) AS invoice_count,
    COALESCE(SUM(ia.amount), 0) AS total_sales_amount,
    COUNT(DISTINCT addr.CITY) AS city_count_with_customers,
    COUNT(DISTINCT CASE WHEN si.ID IS NOT NULL THEN addr.CITY END) AS city_count_with_sales
FROM crm_info ci
INNER JOIN profile_user_address addr ON addr.USER_ID = ci.ID AND addr.TYPE = ]] .. CONFIG.ADDRESS_TYPE_PRIMARY .. [[

LEFT JOIN profile_user_info ui ON ui.ID = ci.ID
LEFT JOIN pa_client pc ON pc.REFFERE_ID = ci.ID
LEFT JOIN sales_invoice si
       ON si.CLIENT_ID = pc.ID AND si.DELETED = 0 AND si.CANCELED = 0 AND si.PRE_INVOICE = 0
      AND si.RUN_DATE >= ?
]] .. INVOICE_AMOUNT_JOIN .. [[
WHERE addr.STATE IS NOT NULL AND addr.STATE <> ''
]] .. extra .. [[

GROUP BY addr.STATE
ORDER BY total_sales_amount DESC
]], params)
    if rows == nil then return nil, err end
    local list = {}
    for _, r in ipairs(rows) do
        table.insert(list, {
            state_name = r[1],
            unique_customer_count = tonumber(r[2]) or 0,
            buyer_count = tonumber(r[3]) or 0,
            invoice_count = tonumber(r[4]) or 0,
            total_sales_amount = tonumber(r[5]) or 0,
            city_count_with_customers = tonumber(r[6]) or 0,
            city_count_with_sales = tonumber(r[7]) or 0,
        })
    end
    return list
end

local function fetch_city_aggregation(date_from_key, filters)
    local extra, extra_params = build_sales_filter_clause(filters)
    local params = { date_from_key, date_from_key }
    for _, p in ipairs(extra_params) do table.insert(params, p) end

    local rows, err = fetch_rows([[
SELECT
    addr.STATE AS state_name,
    addr.CITY  AS city_name,
    COUNT(DISTINCT ci.ID) AS unique_customer_count,
    COUNT(DISTINCT CASE WHEN si.ID IS NOT NULL THEN ci.ID END) AS buyer_count,
    COUNT(si.ID) AS invoice_count,
    COALESCE(SUM(ia.amount), 0) AS total_sales_amount
FROM crm_info ci
INNER JOIN profile_user_address addr ON addr.USER_ID = ci.ID AND addr.TYPE = ]] .. CONFIG.ADDRESS_TYPE_PRIMARY .. [[

LEFT JOIN profile_user_info ui ON ui.ID = ci.ID
LEFT JOIN pa_client pc ON pc.REFFERE_ID = ci.ID
LEFT JOIN sales_invoice si
       ON si.CLIENT_ID = pc.ID AND si.DELETED = 0 AND si.CANCELED = 0 AND si.PRE_INVOICE = 0
      AND si.RUN_DATE >= ?
]] .. INVOICE_AMOUNT_JOIN .. [[
WHERE addr.STATE IS NOT NULL AND addr.STATE <> '' AND addr.CITY IS NOT NULL AND addr.CITY <> ''
]] .. extra .. [[

GROUP BY addr.STATE, addr.CITY
ORDER BY total_sales_amount DESC
]], params)
    if rows == nil then return nil, err end
    local list = {}
    for _, r in ipairs(rows) do
        table.insert(list, {
            state_name = r[1],
            city_name = r[2],
            unique_customer_count = tonumber(r[3]) or 0,
            buyer_count = tonumber(r[4]) or 0,
            invoice_count = tonumber(r[5]) or 0,
            total_sales_amount = tonumber(r[6]) or 0,
        })
    end
    return list
end

-- ============================================================
-- DRILL-DOWN QUERIES (Lazy — فقط هنگام کلیک صدا زده می‌شوند)
-- ============================================================

local function fetch_customers_count(state, city, filters)
    local extra = ""
    local params = { state, city }
    if filters.user_type ~= nil then
        extra = " AND ui.USER_TYPE = ?"
        table.insert(params, filters.user_type)
    end
    local rows, err = fetch_rows([[
SELECT COUNT(DISTINCT ci.ID)
FROM crm_info ci
INNER JOIN profile_user_address addr ON addr.USER_ID = ci.ID AND addr.TYPE = ]] .. CONFIG.ADDRESS_TYPE_PRIMARY .. [[

LEFT JOIN profile_user_info ui ON ui.ID = ci.ID
WHERE addr.STATE = ? AND addr.CITY = ?]] .. extra .. [[
]], params)
    if rows == nil or #rows == 0 then return 0, err end
    return tonumber(rows[1][1]) or 0
end

local function fetch_customers(state, city, filters, limit, offset)
    local extra = ""
    local params = { state, city }
    if filters.user_type ~= nil then
        extra = " AND ui.USER_TYPE = ?"
        table.insert(params, filters.user_type)
    end
    table.insert(params, limit)
    table.insert(params, offset)

    local rows, err = fetch_rows([[
SELECT
    x.crm_id, x.customer_name, x.state_name, x.city_name, x.user_type,
    x.invoice_count, x.total_purchase_amount, rd.JNDATE AS last_purchase_jdate
FROM (
    SELECT
        ci.ID AS crm_id,
        pm.FULLNAME AS customer_name,
        addr.STATE AS state_name,
        addr.CITY AS city_name,
        ui.USER_TYPE AS user_type,
        COUNT(si.ID) AS invoice_count,
        COALESCE(SUM(ia.amount), 0) AS total_purchase_amount,
        MAX(si.RUN_DATE - MOD(si.RUN_DATE, ]] .. CONFIG.DAY_TICKS .. [[)) AS last_purchase_day_key
    FROM crm_info ci
    INNER JOIN profile_main pm ON pm.ID = ci.ID
    INNER JOIN profile_user_address addr ON addr.USER_ID = ci.ID AND addr.TYPE = ]] .. CONFIG.ADDRESS_TYPE_PRIMARY .. [[

    LEFT JOIN profile_user_info ui ON ui.ID = ci.ID
    LEFT JOIN pa_client pc ON pc.REFFERE_ID = ci.ID
    LEFT JOIN sales_invoice si
           ON si.CLIENT_ID = pc.ID AND si.DELETED = 0 AND si.CANCELED = 0 AND si.PRE_INVOICE = 0
    ]] .. INVOICE_AMOUNT_JOIN .. [[
    WHERE addr.STATE = ? AND addr.CITY = ?]] .. extra .. [[

    GROUP BY ci.ID, pm.FULLNAME, addr.STATE, addr.CITY, ui.USER_TYPE
) x
LEFT JOIN report_dimdate rd ON rd.DATEKEY = x.last_purchase_day_key
ORDER BY x.total_purchase_amount DESC
LIMIT ? OFFSET ?
]], params)
    if rows == nil then return nil, err end
    local list = {}
    for _, r in ipairs(rows) do
        table.insert(list, {
            crm_id = r[1],
            customer_name = r[2],
            state_name = r[3],
            city_name = r[4],
            user_type = r[5],
            invoice_count = tonumber(r[6]) or 0,
            total_purchase_amount = tonumber(r[7]) or 0,
            last_purchase_jdate = r[8],
        })
    end
    return list
end

local function fetch_invoices(crm_id)
    local rows, err = fetch_rows([[
SELECT
    si.ID AS invoice_id,
    si.INVOICE_CODE AS invoice_code,
    rd.JNDATE AS run_jdate,
    COALESCE(ia.amount, 0) AS invoice_amount
FROM sales_invoice si
INNER JOIN pa_client pc ON pc.ID = si.CLIENT_ID
LEFT JOIN report_dimdate rd ON rd.DATEKEY = (si.RUN_DATE - MOD(si.RUN_DATE, ]] .. CONFIG.DAY_TICKS .. [[))
]] .. INVOICE_AMOUNT_JOIN .. [[
WHERE pc.REFFERE_ID = ?
  AND si.DELETED = 0 AND si.CANCELED = 0 AND si.PRE_INVOICE = 0
ORDER BY si.RUN_DATE DESC
]], { crm_id })
    if rows == nil then return nil, err end
    local list = {}
    for _, r in ipairs(rows) do
        table.insert(list, {
            invoice_id = r[1],
            invoice_code = r[2],
            run_jdate = r[3],
            invoice_amount = tonumber(r[4]) or 0,
        })
    end
    return list
end

local function fetch_customer_header(crm_id)
    local rows, err = fetch_rows([[
SELECT pm.FULLNAME, addr.STATE, addr.CITY
FROM crm_info ci
INNER JOIN profile_main pm ON pm.ID = ci.ID
LEFT JOIN profile_user_address addr ON addr.USER_ID = ci.ID AND addr.TYPE = ]] .. CONFIG.ADDRESS_TYPE_PRIMARY .. [[

WHERE ci.ID = ?
LIMIT 1
]], { crm_id })
    if rows == nil or #rows == 0 then return nil, err end
    return { customer_name = rows[1][1], state_name = rows[1][2], city_name = rows[1][3] }
end

-- ------------- Drill-down کارت‌های کیفیت داده (Lazy — طبق درخواست کاربر v02) -------------

local function fetch_customers_missing_geo_count(field)
    local col = (field == "city") and "addr.CITY" or "addr.STATE"
    local rows, err = fetch_rows([[
SELECT COUNT(DISTINCT ci.ID)
FROM crm_info ci
LEFT JOIN profile_user_address addr ON addr.USER_ID = ci.ID AND addr.TYPE = ]] .. CONFIG.ADDRESS_TYPE_PRIMARY .. [[

WHERE addr.USER_ID IS NULL OR ]] .. col .. [[ IS NULL OR ]] .. col .. [[ = ''
]], {})
    if rows == nil or #rows == 0 then return 0, err end
    return tonumber(rows[1][1]) or 0
end

local function fetch_customers_missing_geo(field, limit, offset)
    local col = (field == "city") and "addr.CITY" or "addr.STATE"
    local rows, err = fetch_rows([[
SELECT ci.ID, pm.FULLNAME, addr.STATE, addr.CITY
FROM crm_info ci
INNER JOIN profile_main pm ON pm.ID = ci.ID
LEFT JOIN profile_user_address addr ON addr.USER_ID = ci.ID AND addr.TYPE = ]] .. CONFIG.ADDRESS_TYPE_PRIMARY .. [[

WHERE addr.USER_ID IS NULL OR ]] .. col .. [[ IS NULL OR ]] .. col .. [[ = ''
ORDER BY ci.ID DESC
LIMIT ? OFFSET ?
]], { limit, offset })
    if rows == nil then return nil, err end
    local list = {}
    for _, r in ipairs(rows) do
        table.insert(list, {
            crm_id = r[1], customer_name = r[2],
            state_name = safe_str(r[3], nil), city_name = safe_str(r[4], nil),
        })
    end
    return list
end

local function fetch_invoices_missing_geo_count()
    local rows, err = fetch_rows([[
SELECT COUNT(si.ID)
FROM sales_invoice si
INNER JOIN pa_client pc ON pc.ID = si.CLIENT_ID
LEFT JOIN profile_user_address addr ON addr.USER_ID = pc.REFFERE_ID AND addr.TYPE = ]] .. CONFIG.ADDRESS_TYPE_PRIMARY .. [[

WHERE si.DELETED = 0 AND si.CANCELED = 0 AND si.PRE_INVOICE = 0
  AND (addr.USER_ID IS NULL OR addr.STATE IS NULL OR addr.STATE = '' OR addr.CITY IS NULL OR addr.CITY = '')
]], {})
    if rows == nil or #rows == 0 then return 0, err end
    return tonumber(rows[1][1]) or 0
end

local function fetch_invoices_missing_geo(limit, offset)
    local rows, err = fetch_rows([[
SELECT si.ID, si.INVOICE_CODE, rd.JNDATE, COALESCE(ia.amount, 0), pm.FULLNAME, ci.ID
FROM sales_invoice si
INNER JOIN pa_client pc ON pc.ID = si.CLIENT_ID
INNER JOIN crm_info ci ON ci.ID = pc.REFFERE_ID
INNER JOIN profile_main pm ON pm.ID = ci.ID
LEFT JOIN profile_user_address addr ON addr.USER_ID = pc.REFFERE_ID AND addr.TYPE = ]] .. CONFIG.ADDRESS_TYPE_PRIMARY .. [[

LEFT JOIN report_dimdate rd ON rd.DATEKEY = (si.RUN_DATE - MOD(si.RUN_DATE, ]] .. CONFIG.DAY_TICKS .. [[))
]] .. INVOICE_AMOUNT_JOIN .. [[
WHERE si.DELETED = 0 AND si.CANCELED = 0 AND si.PRE_INVOICE = 0
  AND (addr.USER_ID IS NULL OR addr.STATE IS NULL OR addr.STATE = '' OR addr.CITY IS NULL OR addr.CITY = '')
ORDER BY si.RUN_DATE DESC
LIMIT ? OFFSET ?
]], { limit, offset })
    if rows == nil then return nil, err end
    local list = {}
    for _, r in ipairs(rows) do
        table.insert(list, {
            invoice_id = r[1], invoice_code = r[2], run_jdate = r[3],
            invoice_amount = tonumber(r[4]) or 0, customer_name = r[5], crm_id = r[6],
        })
    end
    return list
end

-- ============================================================
-- COMPUTE (سمت Lua — روی نتایج تجمیع‌شدهٔ کوچک، بدون Query اضافه)
-- ============================================================

local function enrich_state_list(states, sales_kpi)
    local total_sales = (sales_kpi and sales_kpi.total_sales_amount) or 0
    local total_customers = 0
    for _, s in ipairs(states) do total_customers = total_customers + s.unique_customer_count end

    for _, s in ipairs(states) do
        s.avg_invoice_amount = (s.invoice_count > 0) and (s.total_sales_amount / s.invoice_count) or 0
        s.avg_sales_per_buyer = (s.buyer_count > 0) and (s.total_sales_amount / s.buyer_count) or 0
        s.sales_share_pct = fmt_pct(s.total_sales_amount, total_sales)
        s.customer_share_pct = fmt_pct(s.unique_customer_count, total_customers)
    end
    return states
end

local function enrich_city_list(cities, state_totals_by_name)
    for _, c in ipairs(cities) do
        c.avg_invoice_amount = (c.invoice_count > 0) and (c.total_sales_amount / c.invoice_count) or 0
        local state_total = (state_totals_by_name[c.state_name] and state_totals_by_name[c.state_name].total_sales_amount) or 0
        c.sales_share_pct = fmt_pct(c.total_sales_amount, state_total)
    end
    return cities
end

local function compute_minmax(states)
    local with_sales = {}
    local without_sales_count = 0
    for _, s in ipairs(states) do
        if s.total_sales_amount > 0 then table.insert(with_sales, s) else without_sales_count = without_sales_count + 1 end
    end
    if #states == 0 then return nil end

    local function pick(list, key, want_max)
        if #list == 0 then return nil end
        local best = list[1]
        for _, s in ipairs(list) do
            if want_max then
                if s[key] > best[key] then best = s end
            else
                if s[key] < best[key] then best = s end
            end
        end
        return best
    end

    return {
        max_sales = pick(states, "total_sales_amount", true),
        min_sales = pick(with_sales, "total_sales_amount", false),
        max_invoices = pick(states, "invoice_count", true),
        min_invoices = pick(with_sales, "invoice_count", false),
        max_buyers = pick(states, "buyer_count", true),
        min_buyers = pick(with_sales, "buyer_count", false),
        states_without_sales_count = without_sales_count,
    }
end

local function build_pie_slices(states)
    local total = 0
    for _, s in ipairs(states) do total = total + s.total_sales_amount end
    local slices = {}
    local other_total = 0
    for _, s in ipairs(states) do
        local pct = fmt_pct(s.total_sales_amount, total)
        if pct >= CONFIG.OTHER_SLICE_THRESHOLD_PCT then
            table.insert(slices, { name = s.state_name, value = s.total_sales_amount, pct = pct })
        else
            other_total = other_total + s.total_sales_amount
        end
    end
    if other_total > 0 then
        table.insert(slices, { name = "سایر", value = other_total, pct = fmt_pct(other_total, total) })
    end
    return slices
end

-- ============================================================
-- CSS
-- ============================================================

local REPORT_CSS = [[
<style>
@font-face {
    font-family: "PeydaReport";
    src: url(data:font/truetype;charset=utf-8;base64,__PEYDA_REGULAR_B64__) format("truetype");
    font-weight: 400; font-style: normal; font-display: swap;
}
@font-face {
    font-family: "PeydaReport";
    src: url(data:font/truetype;charset=utf-8;base64,__PEYDA_BOLD_B64__) format("truetype");
    font-weight: 700; font-style: normal; font-display: swap;
}
* { font-family: "PeydaReport", "Peyda", "IRANSans", "Tahoma", "Arial", sans-serif !important; box-sizing: border-box; }
:root{
  --accent:#16509D; --accent-dark:#0e3a73; --accent-light:#5b85bc; --accent-lighter:#a9c2de;
  --border:#e3e6ea; --muted:#666; --zebra:#f5f5f5; --bg:#f4f6f9;
}
html,body{ margin:0; padding:0; background:var(--bg); color:#000; font-size:14px; direction:rtl; }
#reportRoot{ max-width:1400px; margin:0 auto; padding:18px; }
.toolbar{ display:flex; justify-content:flex-end; gap:8px; margin-bottom:12px; flex-wrap:wrap; }
.btn-toolbar{ background:var(--accent); color:#fff; border:none; border-radius:8px; padding:9px 18px; font-size:14px; font-weight:bold; cursor:pointer; }
.btn-toolbar:hover{ filter:brightness(0.9); }
.btn-toolbar.secondary{ background:#fff; color:var(--accent); border:1.5px solid var(--accent); }
header.hero{ position:relative; background:linear-gradient(135deg,var(--accent),var(--accent-dark)); color:#fff; border-radius:14px; padding:22px 26px; margin-bottom:16px; }
header.hero h1{ margin:0 0 6px; font-size:19px; max-width:calc(100% - 90px); }
header.hero .sub{ margin:0; font-size:14px; opacity:.92; max-width:calc(100% - 90px); }
header.hero .brand140-logo{ position:absolute; top:18px; left:22px; height:34px; width:auto; }
@media(max-width:600px){ header.hero .brand140-logo{ position:static; display:block; margin-bottom:10px; } header.hero h1, header.hero .sub{ max-width:100%; } }
.filter-bar{ background:#fff; border:1px solid var(--border); border-radius:12px; padding:14px 18px; margin-bottom:16px; display:flex; gap:12px; flex-wrap:wrap; align-items:flex-end; }
.filter-field{ display:flex; flex-direction:column; gap:4px; min-width:150px; }
.filter-field label{ font-size:14px; color:var(--muted); }
.filter-field input, .filter-field select{ font-size:14px; padding:8px 10px; border:1px solid var(--border); border-radius:8px; background:#fff; }
.filter-actions{ display:flex; gap:8px; }
.btn-primary{ background:var(--accent); color:#fff; border:none; border-radius:8px; padding:9px 20px; font-size:14px; font-weight:bold; cursor:pointer; }
.btn-secondary{ background:#fff; color:var(--accent); border:1.5px solid var(--accent); border-radius:8px; padding:9px 20px; font-size:14px; font-weight:bold; cursor:pointer; }
.kpi-grid{ display:grid; grid-template-columns:repeat(auto-fit,minmax(190px,1fr)); gap:12px; margin-bottom:18px; }
.kpi-card{ background:#fff; border:1px solid var(--border); border-radius:12px; padding:14px 16px; }
.kpi-card .label{ font-size:14px; color:var(--muted); margin-bottom:6px; }
.kpi-card .value{ font-size:22px; font-weight:bold; color:var(--accent); }
.kpi-card .sub{ font-size:14px; color:var(--muted); margin-top:4px; }
.kpi-card.warn .value{ color:#a33; }
.kpi-card.clickable{ cursor:pointer; transition:box-shadow .15s,transform .15s; }
.kpi-card.clickable:hover{ box-shadow:0 2px 10px rgba(22,80,157,.18); transform:translateY(-1px); border-color:var(--accent); }
.section{ background:#fff; border:1px solid var(--border); border-radius:14px; padding:18px; margin-bottom:16px; }
.section-head{ margin-bottom:12px; }
.section-head h2{ font-size:15px; font-weight:bold; margin:0 0 4px; display:flex; align-items:center; gap:8px; }
.section-head h2 .num{ background:var(--accent); color:#fff; border-radius:50%; width:24px; height:24px; display:inline-flex; align-items:center; justify-content:center; font-size:14px; }
.section-head p{ margin:0; font-size:14px; color:var(--muted); }
.grid-2{ display:grid; grid-template-columns:1fr 1fr; gap:16px; }
@media(max-width:900px){ .grid-2{ grid-template-columns:1fr; } }
.card{ border:1px solid var(--border); border-radius:12px; padding:14px; background:#fff; }
.card h3{ font-size:15px; font-weight:bold; margin:0 0 4px; }
.card .desc{ font-size:14px; color:var(--muted); margin-bottom:10px; }
.chart-box{ position:relative; width:100%; }
.minmax-grid{ display:grid; grid-template-columns:repeat(auto-fit,minmax(210px,1fr)); gap:12px; }
.minmax-card{ border:1px solid var(--border); border-radius:10px; padding:12px 14px; background:var(--zebra); }
.minmax-card .t{ font-size:14px; color:var(--muted); margin-bottom:6px; }
.minmax-card .n{ font-size:15px; font-weight:bold; }
.minmax-card .v{ font-size:14px; color:var(--accent); font-weight:bold; }
table.data-table{ width:auto; min-width:100%; border-collapse:collapse; }
table.data-table th, table.data-table td{ padding:8px 10px; border-bottom:1px solid var(--border); text-align:right; font-size:14px; white-space:nowrap; width:1%; }
table.data-table thead th{ background:var(--zebra); font-weight:bold; font-size:15px; cursor:pointer; user-select:none; position:sticky; top:0; }
table.data-table thead th:hover{ background:var(--accent-lighter); }
table.data-table thead th.sort-asc::after{ content:" ▲"; }
table.data-table thead th.sort-desc::after{ content:" ▼"; }
table.data-table tbody tr:nth-child(even){ background:var(--zebra); }
table.data-table tbody tr.clickable{ cursor:pointer; }
table.data-table tbody tr.clickable:hover{ background:var(--accent-lighter); }
.table-scroll{ overflow-x:auto; }
.badge{ display:inline-block; background:var(--accent); color:#fff; border-radius:6px; padding:2px 8px; font-size:14px; }
.badge.gray{ background:#eee; color:#000; }
.pill{ display:inline-block; border:1px solid var(--border); border-radius:20px; padding:4px 12px; font-size:14px; margin-left:6px; background:#fff; }
a.link{ color:var(--accent); text-decoration:none; font-weight:bold; }
a.link:hover{ text-decoration:underline; }
.search-box{ margin-bottom:10px; }
.search-box input{ width:100%; max-width:320px; padding:8px 10px; border:1px solid var(--border); border-radius:8px; font-size:14px; }
.drill-panel{ border:1.5px solid var(--accent); border-radius:12px; padding:14px; margin-top:14px; background:#fbfcfe; }
.drill-panel .head{ display:flex; justify-content:space-between; align-items:center; margin-bottom:10px; flex-wrap:wrap; gap:8px; }
.drill-panel .head h4{ margin:0; font-size:15px; font-weight:bold; }
.close-btn{ background:none; border:1px solid var(--border); border-radius:8px; padding:5px 12px; cursor:pointer; font-size:14px; }
.pager{ display:flex; gap:8px; align-items:center; margin-top:10px; font-size:14px; }
.pager button{ background:var(--accent); color:#fff; border:none; border-radius:6px; padding:6px 14px; cursor:pointer; font-size:14px; }
.pager button:disabled{ background:#ccc; cursor:not-allowed; }
.loading-row{ text-align:center; color:var(--muted); padding:16px; }
.empty-row{ text-align:center; color:var(--muted); padding:16px; }
.error-row{ text-align:center; color:#a33; padding:16px; }
.tooltip-box{ position:fixed; background:#000; color:#fff; font-size:14px; padding:6px 10px; border-radius:6px; pointer-events:none; z-index:9999; display:none; white-space:nowrap; }
footer{ text-align:center; font-size:14px; color:var(--muted); padding:16px 0; }
.modal{ display:none; position:fixed; inset:0; background:rgba(0,0,0,.45); z-index:10000; align-items:center; justify-content:center; }
.modal.active{ display:flex; }
.modal-content{ background:#fff; border-radius:14px; max-width:640px; width:92%; max-height:82vh; overflow-y:auto; padding:0; }
.modal-header{ display:flex; justify-content:space-between; align-items:center; padding:16px 20px; border-bottom:1px solid var(--border); }
.modal-header h3{ margin:0; font-size:15px; font-weight:bold; }
.modal-close{ background:none; border:none; font-size:20px; cursor:pointer; color:var(--muted); }
.modal-body{ padding:16px 20px; font-size:14px; line-height:1.9; }
.modal-body h4{ font-size:15px; font-weight:bold; margin:14px 0 6px; }
.modal-body ul{ margin:6px 0; padding-inline-start:20px; }
.barlist{ display:flex; flex-direction:column; gap:8px; max-height:520px; overflow-y:auto; }
.bar-row, .combo-row{ display:grid; grid-template-columns:110px 1fr 110px; align-items:center; gap:8px; cursor:pointer; padding:2px 0; }
.combo-row{ grid-template-columns:110px 1fr; }
.bar-label{ font-size:14px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.bar-track{ background:var(--zebra); border-radius:6px; height:16px; overflow:hidden; }
.bar-track.thin{ height:10px; margin-bottom:3px; }
.bar-fill{ height:100%; border-radius:6px; transition:width .3s; }
.bar-value{ font-size:14px; text-align:left; }
.combo-tracks{ display:flex; flex-direction:column; justify-content:center; }
.combo-legend{ display:flex; gap:16px; margin-bottom:10px; font-size:14px; }
.combo-legend .sw, .donut-legend .sw{ display:inline-block; width:12px; height:12px; border-radius:3px; margin-inline-end:6px; vertical-align:middle; }
.donut-wrap{ display:flex; align-items:center; gap:18px; flex-wrap:wrap; justify-content:center; }
.donut{ width:180px; height:180px; border-radius:50%; position:relative; flex:none; }
.donut-hole{ position:absolute; inset:32px; background:#fff; border-radius:50%; }
.donut-legend{ display:flex; flex-direction:column; gap:6px; max-height:220px; overflow-y:auto; }
.donut-legend .legend-row{ display:flex; align-items:center; gap:6px; font-size:14px; cursor:pointer; padding:2px 4px; border-radius:6px; }
.donut-legend .legend-row:hover{ background:var(--zebra); }
.donut-legend .ln{ flex:1; }
.donut-legend .lv{ font-weight:bold; color:var(--accent); }
</style>
]]

-- ============================================================
-- RENDER: KPI CARDS
-- ============================================================

-- کارت‌های KPI بالای صفحه Clickable هستند (طبق درخواست کاربر v02) — کلیک هرکدام به بخش مرتبط
-- (جدول استان‌ها یا فهرست شهرها) Scroll می‌کند؛ برای کارت‌های شهر، فهرست کامل شهرها هم باز می‌شود.
local function render_kpi_cards(crm_kpi, sales_kpi, coverage)
    local html = {}
    local function card(label, value, sub, target, expand_cities)
        local onclick = target and (' onclick="scrollToKpiTarget(\'' .. target .. '\',' .. (expand_cities and 'true' or 'false') .. ')"') or ''
        local cls = target and 'kpi-card clickable' or 'kpi-card'
        table.insert(html, '<div class="' .. cls .. '"' .. onclick .. '><div class="label">' ..
            escape_html(label) .. '</div><div class="value">' .. value .. '</div>' ..
            (sub and ('<div class="sub">' .. sub .. '</div>') or '') .. '</div>')
    end
    card("تعداد کل مشتریان CRM", fmt_num(crm_kpi.total_crm_customers), nil, "stateSection", false)
    card("تعداد مشتریان خریدار", fmt_num(sales_kpi.buyer_customers),
        fmt_dec1(fmt_pct(sales_kpi.buyer_customers, crm_kpi.total_crm_customers)) .. "٪ از کل مشتریان", "stateSection", false)
    card("تعداد کل فاکتورهای فروش", fmt_num(sales_kpi.total_valid_invoices), nil, "stateSection", false)
    card("مبلغ کل فروش", fmt_num(sales_kpi.total_sales_amount) .. " ریال", nil, "chartsSection", false)
    card("استان‌های دارای مشتری", fmt_num(crm_kpi.states_with_customers), nil, "stateSection", false)
    card("استان‌های دارای فروش", fmt_num(sales_kpi.states_with_sales), nil, "stateSection", false)
    card("شهرهای دارای مشتری", fmt_num(crm_kpi.cities_with_customers), nil, "citySection", true)
    card("شهرهای دارای فروش", fmt_num(sales_kpi.cities_with_sales), nil, "citySection", true)
    card("پوشش جغرافیایی فروش", fmt_dec1(coverage.pct) .. "٪",
        fmt_num(coverage.cities_with_sales) .. " از " .. fmt_num(coverage.total_cities) .. " شهر مرجع", "citySection", true)
    return table.concat(html)
end

-- کارت‌های کیفیت داده Clickable‌اند و فهرست واقعی مشتری/فاکتور مربوطه را در یک Modal باز می‌کنند
-- (Lazy AJAX — action=dq_customers/dq_invoices، طبق درخواست کاربر v02)
local function render_data_quality_cards(crm_kpi, sales_kpi)
    local html = {}
    local function card(label, value, onclick)
        table.insert(html, '<div class="kpi-card warn clickable" onclick="' .. onclick .. '"><div class="label">' .. escape_html(label) ..
            '</div><div class="value">' .. value .. '</div></div>')
    end
    card("مشتریان بدون استان", fmt_num(crm_kpi.customers_without_state), "openDataQualityCustomers('state',0)")
    card("مشتریان بدون شهر", fmt_num(crm_kpi.customers_without_city), "openDataQualityCustomers('city',0)")
    card("فاکتورهای بدون نگاشت جغرافیایی", fmt_num(sales_kpi.invoices_without_geo_mapping), "openDataQualityInvoices(0)")
    return table.concat(html)
end

local function render_minmax_cards(mm)
    if mm == nil then return "" end
    local html = {}
    local function card(title, s, valuefmt)
        if s == nil then
            table.insert(html, '<div class="minmax-card"><div class="t">' .. escape_html(title) ..
                '</div><div class="n">—</div></div>')
        else
            table.insert(html, '<div class="minmax-card"><div class="t">' .. escape_html(title) ..
                '</div><div class="n">' .. escape_html(s.state_name) .. '</div><div class="v">' .. valuefmt(s) .. '</div></div>')
        end
    end
    card("استان با بیشترین مبلغ فروش", mm.max_sales, function(s) return fmt_num(s.total_sales_amount) .. " ریال" end)
    card("استان با کمترین مبلغ فروش (در میان استان‌های دارای فروش)", mm.min_sales, function(s) return fmt_num(s.total_sales_amount) .. " ریال" end)
    card("استان با بیشترین تعداد فاکتور", mm.max_invoices, function(s) return fmt_num(s.invoice_count) .. " فاکتور" end)
    card("استان با کمترین تعداد فاکتور (در میان استان‌های دارای فروش)", mm.min_invoices, function(s) return fmt_num(s.invoice_count) .. " فاکتور" end)
    card("استان با بیشترین مشتری خریدار", mm.max_buyers, function(s) return fmt_num(s.buyer_count) .. " مشتری" end)
    card("استان با کمترین مشتری خریدار (در میان استان‌های دارای فروش)", mm.min_buyers, function(s) return fmt_num(s.buyer_count) .. " مشتری" end)
    table.insert(html, '<div class="minmax-card"><div class="t">استان‌های بدون هیچ فروش</div><div class="n">' ..
        fmt_num(mm.states_without_sales_count) .. ' استان</div></div>')
    return table.concat(html)
end

-- ============================================================
-- RENDER: TABLES
-- ============================================================

local function render_state_table_rows(states)
    local html = {}
    for _, s in ipairs(states) do
        table.insert(html, '<tr class="clickable" data-state="' .. escape_html(s.state_name) .. '"><td>' ..
            escape_html(s.state_name) .. '</td><td>' .. fmt_num(s.unique_customer_count) .. '</td><td>' ..
            fmt_num(s.buyer_count) .. '</td><td>' .. fmt_num(s.invoice_count) .. '</td><td>' ..
            fmt_num(s.total_sales_amount) .. '</td><td>' .. fmt_num(s.avg_invoice_amount) .. '</td><td>' ..
            fmt_num(s.avg_sales_per_buyer) .. '</td><td>' .. fmt_num(s.city_count_with_customers) .. '</td><td>' ..
            fmt_num(s.city_count_with_sales) .. '</td><td>' .. fmt_dec1(s.sales_share_pct) .. '٪</td><td>' ..
            fmt_dec1(s.customer_share_pct) .. '٪</td></tr>')
    end
    return table.concat(html)
end

local function render_city_table_rows(cities, limit)
    local html = {}
    for i, c in ipairs(cities) do
        if limit ~= nil and i > limit then break end
        table.insert(html, '<tr class="clickable" data-state="' .. escape_html(c.state_name) .. '" data-city="' ..
            escape_html(c.city_name) .. '"><td>' .. escape_html(c.state_name) .. '</td><td>' ..
            escape_html(c.city_name) .. '</td><td>' .. fmt_num(c.unique_customer_count) .. '</td><td>' ..
            fmt_num(c.buyer_count) .. '</td><td>' .. fmt_num(c.invoice_count) .. '</td><td>' ..
            fmt_num(c.total_sales_amount) .. '</td><td>' .. fmt_num(c.avg_invoice_amount) .. '</td><td>' ..
            fmt_dec1(c.sales_share_pct) .. '٪</td></tr>')
    end
    return table.concat(html)
end

-- ============================================================
-- RENDER: FILTER BAR
-- ============================================================

local function render_filter_bar(filters, default_date_from, state_options, user_type_options)
    local html = {}
    table.insert(html, '<form id="filterForm" class="filter-bar">')
    table.insert(html, '<div class="filter-field"><label>تاریخ از (شمسی)</label><input type="text" name="date_from" id="dateFromInput" placeholder="1405/01/01" value="' ..
        escape_html(filters.date_from_text or default_date_from) .. '"></div>')
    table.insert(html, '<div class="filter-field"><label>استان</label><select name="state" id="stateFilterInput"><option value="">همه استان‌ها</option>')
    for _, st in ipairs(state_options) do
        local sel = (filters.state == st) and ' selected' or ''
        table.insert(html, '<option value="' .. escape_html(st) .. '"' .. sel .. '>' .. escape_html(st) .. '</option>')
    end
    table.insert(html, '</select></div>')
    table.insert(html, '<div class="filter-field"><label>شهر</label><input type="text" name="city" id="cityFilterInput" placeholder="نام شهر" value="' ..
        escape_html(filters.city or "") .. '"></div>')
    table.insert(html, '<div class="filter-field"><label>نوع مشتری</label><select name="user_type"><option value="">همه</option>')
    for _, ut in ipairs(user_type_options) do
        local sel = (filters.user_type == ut) and ' selected' or ''
        table.insert(html, '<option value="' .. escape_html(ut) .. '"' .. sel .. '>' .. escape_html(user_type_label(ut)) .. '</option>')
    end
    table.insert(html, '</select></div>')
    table.insert(html, '<div class="filter-actions"><button type="submit" class="btn-primary" id="filterSubmitBtn">اعمال فیلتر</button>' ..
        '<button type="button" class="btn-secondary" onclick="resetFilters()">پاک‌سازی</button></div>')
    table.insert(html, '</form>')
    return table.concat(html)
end

-- ============================================================
-- RENDER: FOOTER / ERROR
-- ============================================================

local function render_footer_html(generated_jdate)
    return 'تولید شده در ' .. escape_html(generated_jdate or "") .. ' — داشبورد جغرافیایی CRM و فروش'
end

local function render_error_html(message)
    return '<!DOCTYPE html>\n<html dir="rtl" lang="fa">\n<head>\n<meta charset="UTF-8">\n<title>داشبورد جغرافیایی فروش - خطا</title>\n' ..
        REPORT_CSS ..
        '</head>\n<body>\n<div id="reportRoot" style="max-width:640px;">' ..
        '<div class="section" style="border-color:#e00;text-align:center;margin-top:60px;">' ..
        '<h3 style="color:#c00;">خطا در تولید داشبورد</h3><p>' .. escape_html(message) .. '</p></div>' ..
        '</div>\n</body>\n</html>'
end

-- ============================================================
-- JS
-- ============================================================

local REPORT_JS = [[
<script>
'use strict';

function fmtNum(v){
  var n = Math.round(Number(v) || 0);
  var sign = n < 0 ? '-' : ''; n = Math.abs(n);
  var s = String(n);
  var out = '';
  while (s.length > 3) { out = ',' + s.slice(-3) + out; s = s.slice(0, -3); }
  out = s + out;
  return sign + out;
}
function fmtDec1(v){ return (Math.round((Number(v)||0)*10)/10).toFixed(1); }
function escapeHtml(v){
  if (v === null || v === undefined) return '';
  return String(v).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;').replace(/'/g,'&#39;');
}

/* ---------------- Tooltip ---------------- */
var tipEl = null;
function ensureTip(){
  if (!tipEl) { tipEl = document.createElement('div'); tipEl.className = 'tooltip-box'; document.body.appendChild(tipEl); }
  return tipEl;
}
function showTip(evt, text){
  var t = ensureTip();
  t.textContent = text;
  t.style.display = 'block';
  t.style.left = (evt.clientX + 14) + 'px';
  t.style.top = (evt.clientY + 14) + 'px';
}
function hideTip(){ if (tipEl) tipEl.style.display = 'none'; }

/* ---------------- Bar chart (div-based, RTL-friendly, no external lib) ---------------- */
function renderBarChart(containerId, items, opts){
  opts = opts || {};
  var valueKey = opts.valueKey || 'value';
  var labelKey = opts.labelKey || 'label';
  var color = opts.color || 'var(--accent)';
  var suffix = opts.suffix || '';
  var onClick = opts.onClick;
  var el = document.getElementById(containerId);
  if (!el) return;
  var max = 0;
  for (var i = 0; i < items.length; i++) { if (items[i][valueKey] > max) max = items[i][valueKey]; }
  if (max <= 0) max = 1;
  var html = ['<div class="barlist">'];
  for (var j = 0; j < items.length; j++) {
    var it = items[j];
    var pct = (it[valueKey] / max) * 100;
    html.push('<div class="bar-row" data-idx="' + j + '">' +
      '<div class="bar-label">' + escapeHtml(it[labelKey]) + '</div>' +
      '<div class="bar-track"><div class="bar-fill" style="width:' + pct.toFixed(1) + '%;background:' + color + '"></div></div>' +
      '<div class="bar-value">' + fmtNum(it[valueKey]) + suffix + '</div>' +
      '</div>');
  }
  html.push('</div>');
  el.innerHTML = html.join('');
  var rows = el.querySelectorAll('.bar-row');
  rows.forEach(function(row){
    var idx = Number(row.getAttribute('data-idx'));
    var it = items[idx];
    row.addEventListener('mousemove', function(e){ showTip(e, it[labelKey] + ': ' + fmtNum(it[valueKey]) + suffix); });
    row.addEventListener('mouseleave', hideTip);
    if (onClick) row.addEventListener('click', function(){ onClick(it); });
  });
}

/* ---------------- Combo chart: دو معیار در کنار هم برای هر استان ---------------- */
function renderComboChart(containerId, items, optsA, optsB){
  var el = document.getElementById(containerId);
  if (!el) return;
  var maxA = 0, maxB = 0;
  for (var i = 0; i < items.length; i++) {
    if (items[i][optsA.key] > maxA) maxA = items[i][optsA.key];
    if (items[i][optsB.key] > maxB) maxB = items[i][optsB.key];
  }
  if (maxA <= 0) maxA = 1; if (maxB <= 0) maxB = 1;
  var html = ['<div class="combo-legend"><span><i class="sw" style="background:var(--accent)"></i>' + escapeHtml(optsA.label) +
    '</span><span><i class="sw" style="background:var(--accent-light)"></i>' + escapeHtml(optsB.label) + '</span></div>'];
  html.push('<div class="barlist">');
  for (var j = 0; j < items.length; j++) {
    var it = items[j];
    var pctA = (it[optsA.key] / maxA) * 100;
    var pctB = (it[optsB.key] / maxB) * 100;
    html.push('<div class="combo-row" data-idx="' + j + '">' +
      '<div class="bar-label">' + escapeHtml(it.state_name) + '</div>' +
      '<div class="combo-tracks">' +
      '<div class="bar-track thin"><div class="bar-fill" style="width:' + pctA.toFixed(1) + '%;background:var(--accent)"></div></div>' +
      '<div class="bar-track thin"><div class="bar-fill" style="width:' + pctB.toFixed(1) + '%;background:var(--accent-light)"></div></div>' +
      '</div></div>');
  }
  html.push('</div>');
  el.innerHTML = html.join('');
  var rows = el.querySelectorAll('.combo-row');
  rows.forEach(function(row){
    var idx = Number(row.getAttribute('data-idx'));
    var it = items[idx];
    row.addEventListener('mousemove', function(e){
      showTip(e, it.state_name + ' — ' + optsA.label + ': ' + fmtNum(it[optsA.key]) + ' | ' + optsB.label + ': ' + fmtNum(it[optsB.key]));
    });
    row.addEventListener('mouseleave', hideTip);
  });
}

/* ---------------- Donut chart (conic-gradient، بدون کتابخانه خارجی) ---------------- */
function renderDonutChart(containerId, slices, onClick){
  var el = document.getElementById(containerId);
  if (!el) return;
  var shades = ['#16509D', '#3068AE', '#4a7fbe', '#5b85bc', '#7d9dcb', '#a9c2de', '#c7d7ea'];
  var total = 0;
  for (var i = 0; i < slices.length; i++) total += slices[i].value;
  if (total <= 0) total = 1;
  var stops = []; var acc = 0;
  for (var j = 0; j < slices.length; j++) {
    var s = slices[j];
    var color = (s.name === 'سایر') ? '#bbb' : shades[j % shades.length];
    var from = (acc / total) * 100;
    acc += s.value;
    var to = (acc / total) * 100;
    stops.push(color + ' ' + from.toFixed(2) + '% ' + to.toFixed(2) + '%');
  }
  var gradient = 'conic-gradient(' + stops.join(',') + ')';
  var html = '<div class="donut-wrap"><div class="donut" style="background:' + gradient + '"><div class="donut-hole"></div></div>' +
    '<div class="donut-legend">';
  for (var k = 0; k < slices.length; k++) {
    var sl = slices[k];
    var color2 = (sl.name === 'سایر') ? '#bbb' : shades[k % shades.length];
    html += '<div class="legend-row" data-idx="' + k + '"><i class="sw" style="background:' + color2 + '"></i>' +
      '<span class="ln">' + escapeHtml(sl.name) + '</span><span class="lv">' + fmtDec1(sl.pct) + '٪</span></div>';
  }
  html += '</div></div>';
  el.innerHTML = html;
  var rows = el.querySelectorAll('.legend-row');
  rows.forEach(function(row){
    var idx = Number(row.getAttribute('data-idx'));
    var sl = slices[idx];
    row.addEventListener('mousemove', function(e){ showTip(e, sl.name + ': ' + fmtNum(sl.value) + ' ریال (' + fmtDec1(sl.pct) + '٪)'); });
    row.addEventListener('mouseleave', hideTip);
    if (onClick && sl.name !== 'سایر') row.addEventListener('click', function(){ onClick(sl.name); });
  });
}

/* ---------------- Sortable tables ---------------- */
function getCellSortValue(cell){
  var text = cell ? cell.innerText.trim() : '';
  var n = text.replace(/[,%٪]/g,'').trim();
  if (n !== '' && /^-?\d+(\.\d+)?$/.test(n)) return parseFloat(n);
  return text;
}
function sortTableByColumn(table, colIndex, dir){
  var tbody = table.querySelector('tbody');
  var rows = Array.prototype.slice.call(tbody.querySelectorAll('tr'));
  rows.sort(function(ra, rb){
    var a = getCellSortValue(ra.children[colIndex]), b = getCellSortValue(rb.children[colIndex]), cmp;
    if (typeof a === 'number' && typeof b === 'number') cmp = a - b; else cmp = String(a).localeCompare(String(b), 'fa');
    return dir === 'asc' ? cmp : -cmp;
  });
  rows.forEach(function(row){ tbody.appendChild(row); });
}
function initSortableTables(root){
  (root || document).querySelectorAll('table.data-table').forEach(function(table){
    var headers = table.querySelectorAll('thead th');
    headers.forEach(function(th, colIndex){
      if (th.getAttribute('data-sortable-bound')) return;
      th.setAttribute('data-sortable-bound', '1');
      th.addEventListener('click', function(){
        var dir = th.classList.contains('sort-asc') ? 'desc' : 'asc';
        headers.forEach(function(h){ h.classList.remove('sort-asc', 'sort-desc'); });
        th.classList.add(dir === 'asc' ? 'sort-asc' : 'sort-desc');
        sortTableByColumn(table, colIndex, dir);
      });
    });
  });
}

/* ---------------- Toolbar: fullscreen / excel / help ---------------- */
function toggleFullScreen(){
  var root = document.getElementById('reportRoot');
  var isFull = document.fullscreenElement || document.webkitFullscreenElement;
  if (!isFull) { if (root.requestFullscreen) root.requestFullscreen(); else if (root.webkitRequestFullscreen) root.webkitRequestFullscreen(); }
  else { if (document.exitFullscreen) document.exitFullscreen(); else if (document.webkitExitFullscreen) document.webkitExitFullscreen(); }
}
function openHelp(){ document.getElementById('helpModal').classList.add('active'); }
function closeHelp(){ document.getElementById('helpModal').classList.remove('active'); }
function closeInvoiceModal(){ document.getElementById('invoiceModal').classList.remove('active'); }
function closeDqModal(){ document.getElementById('dqModal').classList.remove('active'); }
window.addEventListener('click', function(e){
  if (e.target === document.getElementById('helpModal')) closeHelp();
  if (e.target === document.getElementById('invoiceModal')) closeInvoiceModal();
  if (e.target === document.getElementById('dqModal')) closeDqModal();
});
document.addEventListener('keydown', function(e){ if (e.key === 'Escape') { closeHelp(); closeInvoiceModal(); closeDqModal(); } });

/* ---------------- Drill-down از کارت‌های KPI بالای صفحه (Scroll) و کارت‌های کیفیت داده (Modal، Lazy AJAX) ---------------- */
function scrollToKpiTarget(sectionId, expandCities){
  if (expandCities) {
    var box = document.getElementById('fullCityListBox');
    if (box && (box.style.display === 'none' || !box.style.display)) toggleFullCityList();
  }
  var el = document.getElementById(sectionId);
  if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' });
}

function openDataQualityCustomers(field, offset){
  var modal = document.getElementById('dqModal');
  var body = document.getElementById('dqModalBody');
  document.getElementById('dqModalTitle').textContent = field === 'city' ? 'مشتریان بدون شهر' : 'مشتریان بدون استان';
  body.innerHTML = '<div class="loading-row">در حال بارگذاری...</div>';
  modal.classList.add('active');
  var fd = new FormData();
  fd.append('action', 'dq_customers');
  fd.append('field', field);
  fd.append('offset', String(offset || 0));
  fetch(window.location.href, { method: 'POST', body: fd })
    .then(function(res){ return res.json(); })
    .then(function(payload){
      if (!payload.ok) throw new Error(payload.error || 'خطای ناشناخته');
      var rows = payload.rows || [];
      var rowsHtml = rows.length === 0 ? '<tr><td colspan="4" class="empty-row">موردی یافت نشد</td></tr>' : rows.map(function(c){
        var crmUrl = ']] .. CONFIG.CRM_EDIT_URL_PREFIX .. [[' + c.crm_id + ']] .. CONFIG.CRM_EDIT_URL_SUFFIX .. [[';
        return '<tr><td>' + c.crm_id + '</td><td>' + escapeHtml(c.customer_name) + '</td><td>' + escapeHtml(c.state_name || '—') +
          '</td><td>' + escapeHtml(c.city_name || '—') + '</td><td><a class="link" target="_blank" href="' + crmUrl + '">مشاهده CRM</a></td></tr>';
      }).join('');
      var totalPages = Math.max(1, Math.ceil(payload.total / payload.limit));
      var curPage = Math.floor(payload.offset / payload.limit) + 1;
      body.innerHTML = '<div>' + fmtNum(payload.total) + ' مشتری</div>' +
        '<div class="table-scroll"><table class="data-table"><thead><tr><th>شناسه</th><th>نام مشتری</th><th>استان</th><th>شهر</th><th>CRM</th></tr></thead><tbody>' + rowsHtml + '</tbody></table></div>' +
        '<div class="pager"><button ' + (curPage <= 1 ? 'disabled' : '') + ' onclick="openDataQualityCustomers(\'' + field + '\',' + (payload.offset - payload.limit) + ')">قبلی</button>' +
        '<span>صفحه ' + curPage + ' از ' + totalPages + '</span>' +
        '<button ' + (curPage >= totalPages ? 'disabled' : '') + ' onclick="openDataQualityCustomers(\'' + field + '\',' + (payload.offset + payload.limit) + ')">بعدی</button></div>';
      initSortableTables(body);
    })
    .catch(function(err){ body.innerHTML = '<div class="error-row">خطا: ' + escapeHtml(err.message) + '</div>'; });
}

function openDataQualityInvoices(offset){
  var modal = document.getElementById('dqModal');
  var body = document.getElementById('dqModalBody');
  document.getElementById('dqModalTitle').textContent = 'فاکتورهای بدون نگاشت جغرافیایی';
  body.innerHTML = '<div class="loading-row">در حال بارگذاری...</div>';
  modal.classList.add('active');
  var fd = new FormData();
  fd.append('action', 'dq_invoices');
  fd.append('offset', String(offset || 0));
  fetch(window.location.href, { method: 'POST', body: fd })
    .then(function(res){ return res.json(); })
    .then(function(payload){
      if (!payload.ok) throw new Error(payload.error || 'خطای ناشناخته');
      var rows = payload.rows || [];
      var rowsHtml = rows.length === 0 ? '<tr><td colspan="5" class="empty-row">موردی یافت نشد</td></tr>' : rows.map(function(inv){
        var invUrl = ']] .. CONFIG.INVOICE_VIEW_URL_PREFIX .. [[' + inv.invoice_id;
        var crmUrl = ']] .. CONFIG.CRM_EDIT_URL_PREFIX .. [[' + inv.crm_id + ']] .. CONFIG.CRM_EDIT_URL_SUFFIX .. [[';
        return '<tr><td><a class="link" target="_blank" href="' + invUrl + '">' + inv.invoice_id + '</a></td><td>' + escapeHtml(inv.invoice_code) +
          '</td><td>' + escapeHtml(inv.run_jdate || '—') + '</td><td>' + fmtNum(inv.invoice_amount) + '</td><td>' + escapeHtml(inv.customer_name) +
          ' — <a class="link" target="_blank" href="' + crmUrl + '">CRM</a></td></tr>';
      }).join('');
      var totalPages = Math.max(1, Math.ceil(payload.total / payload.limit));
      var curPage = Math.floor(payload.offset / payload.limit) + 1;
      body.innerHTML = '<div>' + fmtNum(payload.total) + ' فاکتور</div>' +
        '<div class="table-scroll"><table class="data-table"><thead><tr><th>شناسه فاکتور</th><th>کد فاکتور</th><th>تاریخ</th><th>مبلغ</th><th>مشتری</th></tr></thead><tbody>' + rowsHtml + '</tbody></table></div>' +
        '<div class="pager"><button ' + (curPage <= 1 ? 'disabled' : '') + ' onclick="openDataQualityInvoices(' + (payload.offset - payload.limit) + ')">قبلی</button>' +
        '<span>صفحه ' + curPage + ' از ' + totalPages + '</span>' +
        '<button ' + (curPage >= totalPages ? 'disabled' : '') + ' onclick="openDataQualityInvoices(' + (payload.offset + payload.limit) + ')">بعدی</button></div>';
      initSortableTables(body);
    })
    .catch(function(err){ body.innerHTML = '<div class="error-row">خطا: ' + escapeHtml(err.message) + '</div>'; });
}

function csvCell(t){ t = (t == null ? '' : String(t)).replace(/\s+/g,' ').trim(); if (t.indexOf(',') !== -1 || t.indexOf('"') !== -1) t = '"' + t.replace(/"/g,'""') + '"'; return t; }
function downloadCsv(lines, fileName){
  var blob = new Blob(['﻿' + lines.join('\r\n')], { type: 'text/csv;charset=utf-8;' });
  var url = URL.createObjectURL(blob); var link = document.createElement('a');
  link.href = url; link.download = fileName; document.body.appendChild(link); link.click(); document.body.removeChild(link); URL.revokeObjectURL(url);
}
function exportToExcel(){
  var table = document.getElementById('stateTable'); if (!table) return;
  var lines = []; var heads = table.querySelectorAll('thead th'); var hl = [];
  for (var h = 0; h < heads.length; h++) hl.push(csvCell(heads[h].innerText));
  lines.push(hl.join(','));
  var rows = table.querySelectorAll('tbody tr');
  for (var i = 0; i < rows.length; i++) {
    var cells = rows[i].querySelectorAll('td'); var line = [];
    for (var c = 0; c < cells.length; c++) line.push(csvCell(cells[c].innerText));
    lines.push(line.join(','));
  }
  downloadCsv(lines, 'گزارش-جغرافیایی-فروش-استان‌ها.csv');
}

/* ---------------- داده تعبیه‌شده (Executive KPI + State/City Aggregation) ---------------- */
var DASH = JSON.parse(document.getElementById('dashData').textContent);
var STATE_MAP = {};
DASH.states.forEach(function(s){ STATE_MAP[s.state_name] = s; });

function citiesOfState(stateName){
  return DASH.cities.filter(function(c){ return c.state_name === stateName; });
}

/* ---------------- Drill-down سطح استان (کاملاً از داده تعبیه‌شده، بدون Query) ---------------- */
function openStateDrill(stateName){
  var s = STATE_MAP[stateName];
  if (!s) return;
  var panel = document.getElementById('stateDrillPanel');
  var cities = citiesOfState(stateName).slice().sort(function(a,b){ return b.total_sales_amount - a.total_sales_amount; });
  var rows = cities.map(function(c){
    var sharePct = s.total_sales_amount > 0 ? (c.total_sales_amount / s.total_sales_amount * 100) : 0;
    return '<tr class="clickable" data-state="' + escapeHtml(stateName) + '" data-city="' + escapeHtml(c.city_name) + '" onclick="openCustomerDrillFromRow(this)"><td>' +
      escapeHtml(c.city_name) + '</td><td>' + fmtNum(c.unique_customer_count) + '</td><td>' + fmtNum(c.buyer_count) +
      '</td><td>' + fmtNum(c.invoice_count) + '</td><td>' + fmtNum(c.total_sales_amount) + '</td><td>' + fmtDec1(sharePct) + '٪</td></tr>';
  }).join('');
  panel.innerHTML =
    '<div class="head"><h4>جزئیات استان: ' + escapeHtml(stateName) + '</h4><button class="close-btn" onclick="closeStateDrill()">بستن ✕</button></div>' +
    '<div class="kpi-grid">' +
      '<div class="kpi-card"><div class="label">مبلغ کل فروش</div><div class="value">' + fmtNum(s.total_sales_amount) + '</div></div>' +
      '<div class="kpi-card"><div class="label">تعداد فاکتور</div><div class="value">' + fmtNum(s.invoice_count) + '</div></div>' +
      '<div class="kpi-card"><div class="label">تعداد مشتری</div><div class="value">' + fmtNum(s.unique_customer_count) + '</div></div>' +
      '<div class="kpi-card"><div class="label">تعداد مشتری خریدار</div><div class="value">' + fmtNum(s.buyer_count) + '</div></div>' +
      '<div class="kpi-card"><div class="label">تعداد شهر فعال</div><div class="value">' + fmtNum(s.city_count_with_sales) + '</div></div>' +
      '<div class="kpi-card"><div class="label">سهم از کل فروش</div><div class="value">' + fmtDec1(s.sales_share_pct) + '٪</div></div>' +
      '<div class="kpi-card"><div class="label">میانگین مبلغ فاکتور</div><div class="value">' + fmtNum(s.avg_invoice_amount) + '</div></div>' +
    '</div>' +
    '<div class="table-scroll"><table class="data-table"><thead><tr><th>شهر</th><th>تعداد مشتری</th><th>تعداد مشتری خریدار</th><th>تعداد فاکتور</th><th>مبلغ فروش</th><th>سهم از فروش استان</th></tr></thead>' +
    '<tbody>' + (rows || '<tr><td colspan="6" class="empty-row">شهری با آدرس معتبر برای این استان یافت نشد</td></tr>') + '</tbody></table></div>' +
    '<div id="customerDrillPanel"></div>';
  panel.style.display = 'block';
  initSortableTables(panel);
  panel.scrollIntoView({ behavior: 'smooth', block: 'start' });
}
function closeStateDrill(){ document.getElementById('stateDrillPanel').style.display = 'none'; document.getElementById('stateDrillPanel').innerHTML = ''; }
function openCustomerDrillFromRow(tr){
  openCustomerDrill(tr.getAttribute('data-state'), tr.getAttribute('data-city'), 0);
}

/* ---------------- Drill-down سطح شهر → مشتری (Lazy — AJAX هنگام کلیک) ---------------- */
var custDrillState = { state: null, city: null, offset: 0, limit: 50, total: 0 };

function openCustomerDrill(stateName, cityName, offset){
  var host = document.getElementById('customerDrillPanel');
  if (!host) {
    // اگر از جدول Top شهرها (خارج از پنل استان) کلیک شده، پنل مستقل خودش را بساز
    var mainPanel = document.getElementById('stateDrillPanel');
    if (!mainPanel) return;
    openStateDrill(stateName);
    host = document.getElementById('customerDrillPanel');
  }
  custDrillState.state = stateName; custDrillState.city = cityName; custDrillState.offset = offset || 0;
  host.innerHTML = '<div class="drill-panel"><div class="head"><h4>مشتریان شهر: ' + escapeHtml(cityName) + ' (' + escapeHtml(stateName) + ')</h4>' +
    '<button class="close-btn" onclick="closeCustomerDrill()">بستن ✕</button></div>' +
    '<div class="loading-row">در حال بارگذاری...</div></div>';
  var fd = new FormData();
  fd.append('action', 'customers');
  fd.append('state', stateName);
  fd.append('city', cityName);
  fd.append('offset', String(custDrillState.offset));
  var utSel = document.querySelector('select[name="user_type"]');
  if (utSel && utSel.value) fd.append('user_type', utSel.value);
  fetch(window.location.href, { method: 'POST', body: fd })
    .then(function(res){ return res.json(); })
    .then(function(payload){
      if (!payload.ok) throw new Error(payload.error || 'خطای ناشناخته');
      custDrillState.total = payload.total;
      renderCustomerDrill(payload);
    })
    .catch(function(err){
      host.querySelector('.drill-panel').innerHTML =
        '<div class="head"><h4>مشتریان شهر: ' + escapeHtml(cityName) + '</h4><button class="close-btn" onclick="closeCustomerDrill()">بستن ✕</button></div>' +
        '<div class="error-row">خطا در دریافت اطلاعات مشتریان: ' + escapeHtml(err.message) + ' — <a href="#" onclick="openCustomerDrill(\'' + stateName.replace(/'/g,"\\'") + '\',\'' + cityName.replace(/'/g,"\\'") + '\',0);return false;">تلاش مجدد</a></div>';
    });
}
function renderCustomerDrill(payload){
  var host = document.getElementById('customerDrillPanel');
  if (!host) return;
  var rows = payload.rows || [];
  var body = rows.length === 0 ? '<tr><td colspan="6" class="empty-row">مشتری‌ای یافت نشد</td></tr>' : rows.map(function(c){
    var crmUrl = ']] .. CONFIG.CRM_EDIT_URL_PREFIX .. [[' + c.crm_id + ']] .. CONFIG.CRM_EDIT_URL_SUFFIX .. [[';
    return '<tr class="clickable" data-crmid="' + c.crm_id + '" onclick="openInvoiceDrill(' + c.crm_id + ')"><td>' + escapeHtml(c.customer_name) +
      '</td><td>' + fmtNum(c.invoice_count) + '</td><td>' + fmtNum(c.total_purchase_amount) + '</td><td>' +
      escapeHtml(c.last_purchase_jdate || '—') + '</td><td onclick="event.stopPropagation();"><a class="link" target="_blank" href="' + crmUrl + '">مشاهده CRM</a></td></tr>';
  }).join('');
  var totalPages = Math.max(1, Math.ceil(custDrillState.total / custDrillState.limit));
  var curPage = Math.floor(custDrillState.offset / custDrillState.limit) + 1;
  host.innerHTML = '<div class="drill-panel"><div class="head"><h4>مشتریان شهر: ' + escapeHtml(custDrillState.city) +
    ' (' + escapeHtml(custDrillState.state) + ') — ' + fmtNum(custDrillState.total) + ' مشتری</h4>' +
    '<button class="close-btn" onclick="closeCustomerDrill()">بستن ✕</button></div>' +
    '<div class="table-scroll"><table class="data-table"><thead><tr><th>نام مشتری</th><th>تعداد فاکتور</th><th>مبلغ کل خرید</th><th>آخرین تاریخ خرید</th><th>CRM</th></tr></thead>' +
    '<tbody>' + body + '</tbody></table></div>' +
    '<div class="pager"><button ' + (curPage <= 1 ? 'disabled' : '') + ' onclick="openCustomerDrill(\'' + custDrillState.state.replace(/'/g,"\\'") + '\',\'' + custDrillState.city.replace(/'/g,"\\'") + '\',' + (custDrillState.offset - custDrillState.limit) + ')">قبلی</button>' +
    '<span>صفحه ' + curPage + ' از ' + totalPages + '</span>' +
    '<button ' + (curPage >= totalPages ? 'disabled' : '') + ' onclick="openCustomerDrill(\'' + custDrillState.state.replace(/'/g,"\\'") + '\',\'' + custDrillState.city.replace(/'/g,"\\'") + '\',' + (custDrillState.offset + custDrillState.limit) + ')">بعدی</button></div>' +
    '</div>';
}
function closeCustomerDrill(){ var host = document.getElementById('customerDrillPanel'); if (host) host.innerHTML = ''; }

/* ---------------- Drill-down سطح مشتری → فاکتور (Lazy — AJAX هنگام کلیک، در Modal) ---------------- */
function openInvoiceDrill(crmId){
  var modal = document.getElementById('invoiceModal');
  var body = document.getElementById('invoiceModalBody');
  body.innerHTML = '<div class="loading-row">در حال بارگذاری...</div>';
  modal.classList.add('active');
  var fd = new FormData();
  fd.append('action', 'invoices');
  fd.append('crm_id', String(crmId));
  fetch(window.location.href, { method: 'POST', body: fd })
    .then(function(res){ return res.json(); })
    .then(function(payload){
      if (!payload.ok) throw new Error(payload.error || 'خطای ناشناخته');
      var rows = payload.rows || [];
      var rowsHtml = rows.length === 0 ? '<tr><td colspan="4" class="empty-row">فاکتوری یافت نشد</td></tr>' : rows.map(function(inv){
        var url = ']] .. CONFIG.INVOICE_VIEW_URL_PREFIX .. [[' + inv.invoice_id;
        return '<tr><td><a class="link" target="_blank" href="' + url + '">' + inv.invoice_id + '</a></td><td>' +
          escapeHtml(inv.invoice_code) + '</td><td>' + escapeHtml(inv.run_jdate || '—') + '</td><td>' + fmtNum(inv.invoice_amount) + '</td></tr>';
      }).join('');
      var cust = payload.customer || {};
      document.getElementById('invoiceModalTitle').textContent = 'فاکتورهای ' + (cust.customer_name || '');
      body.innerHTML = '<div class="table-scroll"><table class="data-table"><thead><tr><th>شناسه فاکتور</th><th>کد فاکتور</th><th>تاریخ</th><th>مبلغ</th></tr></thead><tbody>' + rowsHtml + '</tbody></table></div>';
      initSortableTables(body);
    })
    .catch(function(err){ body.innerHTML = '<div class="error-row">خطا در دریافت فاکتورها: ' + escapeHtml(err.message) + '</div>'; });
}

/* ---------------- فهرست کامل شهرها (Toggle + جستجوی سمت کلاینت، از داده تعبیه‌شده) ---------------- */
function toggleFullCityList(){
  var box = document.getElementById('fullCityListBox');
  var btn = document.getElementById('toggleCityListBtn');
  if (box.style.display === 'none' || !box.style.display) {
    box.style.display = 'block';
    if (!box.getAttribute('data-rendered')) {
      renderFullCityTable(DASH.cities);
      box.setAttribute('data-rendered', '1');
    }
    btn.textContent = 'بستن فهرست کامل شهرها';
  } else {
    box.style.display = 'none';
    btn.textContent = 'نمایش تمام شهرها';
  }
}
function renderFullCityTable(cities){
  var rows = cities.map(function(c){
    return '<tr class="clickable" data-state="' + escapeHtml(c.state_name) + '" data-city="' + escapeHtml(c.city_name) +
      '" onclick="openCustomerDrillFromFullList(this)"><td>' + escapeHtml(c.state_name) + '</td><td>' + escapeHtml(c.city_name) +
      '</td><td>' + fmtNum(c.unique_customer_count) + '</td><td>' + fmtNum(c.buyer_count) + '</td><td>' + fmtNum(c.invoice_count) +
      '</td><td>' + fmtNum(c.total_sales_amount) + '</td><td>' + fmtNum(c.avg_invoice_amount) + '</td></tr>';
  }).join('');
  document.getElementById('fullCityTbody').innerHTML = rows;
  initSortableTables(document.getElementById('fullCityListBox'));
}
function openCustomerDrillFromFullList(tr){
  var stateName = tr.getAttribute('data-state'), cityName = tr.getAttribute('data-city');
  openStateDrill(stateName);
  openCustomerDrill(stateName, cityName, 0);
  document.getElementById('stateDrillPanel').scrollIntoView({ behavior: 'smooth' });
}
document.addEventListener('input', function(e){
  if (e.target && e.target.id === 'citySearchInput') {
    var q = e.target.value.trim();
    var filtered = q === '' ? DASH.cities : DASH.cities.filter(function(c){
      return c.city_name.indexOf(q) !== -1 || c.state_name.indexOf(q) !== -1;
    });
    renderFullCityTable(filtered);
  }
});

/* ---------------- فیلتر: fetch با format=json + جایگزینی درجای بخش‌های داشبورد (بدون Navigate/iframe) ----------------
   طبق تجربهٔ ثبت‌شدهٔ سایر بات‌های این پروژه: document.write کل صفحه یا iframe تودرتو هر دو داخل شِل/Iframe
   واقعی Teamyar شکست می‌خورند؛ روش سالم fetch همین آدرس + جایگزینی innerHTML بخش‌هاست. */
var filterFormEl = document.getElementById('filterForm');
var filterRequestInFlight = false;
if (filterFormEl) {
  filterFormEl.addEventListener('submit', function(e){
    e.preventDefault();
    if (filterRequestInFlight) return;
    filterRequestInFlight = true;
    var btn = document.getElementById('filterSubmitBtn');
    var originalText = btn ? btn.textContent : '';
    if (btn) { btn.disabled = true; btn.textContent = 'در حال بارگذاری...'; }
    var formData = new FormData(filterFormEl);
    formData.set('format', 'json');
    fetch(window.location.href, { method: 'POST', body: formData })
      .then(function(res){ if (!res.ok) throw new Error('HTTP ' + res.status); return res.json(); })
      .then(function(payload){ if (!payload.ok) throw new Error(payload.error || 'خطای ناشناخته سمت سرور'); applyDashboardUpdate(payload); })
      .catch(function(err){ alert('خطا در اعمال فیلتر: ' + err.message); })
      .finally(function(){ filterRequestInFlight = false; if (btn) { btn.disabled = false; btn.textContent = originalText; } });
  });
}
function resetFilters(){
  document.getElementById('dateFromInput').value = DASH.default_date_from;
  document.querySelector('select[name="state"]').value = '';
  document.querySelector('input[name="city"]').value = '';
  document.querySelector('select[name="user_type"]').value = '';
  filterFormEl.requestSubmit ? filterFormEl.requestSubmit() : filterFormEl.dispatchEvent(new Event('submit', {cancelable:true}));
}
function applyDashboardUpdate(payload){
  DASH = payload.dash_data;
  STATE_MAP = {};
  DASH.states.forEach(function(s){ STATE_MAP[s.state_name] = s; });
  document.getElementById('kpiGrid').innerHTML = payload.kpi_cards_html;
  document.getElementById('dataQualityGrid').innerHTML = payload.data_quality_html;
  document.getElementById('minmaxGrid').innerHTML = payload.minmax_html;
  document.getElementById('stateTbody').innerHTML = payload.state_rows_html;
  document.getElementById('topCityTbody').innerHTML = payload.top_city_rows_html;
  document.getElementById('footerText').textContent = payload.footer_text;
  document.getElementById('fullCityListBox').style.display = 'none';
  document.getElementById('fullCityListBox').removeAttribute('data-rendered');
  document.getElementById('toggleCityListBtn').textContent = 'نمایش تمام شهرها';
  closeStateDrill();
  initCharts();
  initSortableTables();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

/* ---------------- راه‌اندازی اولیه ---------------- */
function initCharts(){
  var byStateSales = DASH.states.slice();
  renderBarChart('salesByStateChart', byStateSales, { valueKey: 'total_sales_amount', labelKey: 'state_name', color: 'var(--accent)', onClick: function(it){ openStateDrill(it.state_name); } });

  var byStateBuyers = DASH.states.slice().sort(function(a,b){ return b.buyer_count - a.buyer_count; });
  renderBarChart('buyersByStateChart', byStateBuyers, { valueKey: 'buyer_count', labelKey: 'state_name', color: 'var(--accent-light)', onClick: function(it){ openStateDrill(it.state_name); } });

  renderComboChart('comboChart', DASH.states, { key: 'invoice_count', label: 'تعداد فاکتور' }, { key: 'total_sales_amount', label: 'مبلغ فروش' });

  renderDonutChart('salesDonutChart', DASH.pie_slices, function(stateName){ openStateDrill(stateName); });
}
initCharts();
initSortableTables();
</script>
]]

-- ============================================================
-- DASH DATA BUILDER
-- ============================================================

local function build_dash_data(states, cities, default_date_from)
    return {
        states = states,
        cities = cities,
        pie_slices = build_pie_slices(states),
        default_date_from = default_date_from,
    }
end

-- ============================================================
-- HTML TEMPLATE — اسکلت کامل صفحه
-- ============================================================

local function render_html(args)
    local dash_json = json.encode(args.dash_data):gsub("</", "<\\/")

    local html = {}
    table.insert(html, '<!DOCTYPE html>\n<html dir="rtl" lang="fa">\n<head>\n<meta charset="UTF-8">\n')
    table.insert(html, '<meta name="viewport" content="width=device-width, initial-scale=1.0">\n')
    table.insert(html, '<title>داشبورد جغرافیایی مشتریان و فروش</title>\n')
    table.insert(html, REPORT_CSS)
    table.insert(html, '</head>\n<body>\n<div id="reportRoot">\n')

    table.insert(html, '<div class="toolbar">' ..
        '<button type="button" class="btn-toolbar" onclick="toggleFullScreen()">تمام صفحه</button>' ..
        '<button type="button" class="btn-toolbar" onclick="exportToExcel()">خروجی Excel</button>' ..
        '<button type="button" class="btn-toolbar secondary" onclick="openHelp()">راهنما</button></div>\n')

    table.insert(html, '<header class="hero"><img class="brand140-logo" alt="140" ' ..
        'src="data:image/png;base64,' .. CONFIG.LOGO140_WHITE_B64 .. '">' ..
        '<h1>داشبورد مدیریتی توزیع جغرافیایی مشتریان و فروش</h1>' ..
        '<p class="sub">بازه: از ' .. escape_html(args.date_from_label) .. ' تا امروز — تولید در ' ..
        escape_html(args.generated_jdate) .. '</p></header>\n')

    table.insert(html, args.filter_bar_html)

    table.insert(html, '<div class="kpi-grid" id="kpiGrid">' .. args.kpi_cards_html .. '</div>\n')

    table.insert(html, [[
<div class="section">
  <div class="section-head"><h2><span class="num">۱</span>کیفیت دادهٔ جغرافیایی</h2><p>مشتریان/فاکتورهایی که آدرس یا نگاشت جغرافیایی معتبر ندارند — حذف خاموش نشده‌اند</p></div>
  <div class="kpi-grid" id="dataQualityGrid">]] .. args.data_quality_html .. [[</div>
</div>

<div class="section" id="chartsSection">
  <div class="section-head"><h2><span class="num">۲</span>نمودارهای استانی</h2><p>روی هر ردیف/بخش کلیک کنید تا جزئیات همان استان باز شود</p></div>
  <div class="grid-2">
    <div class="card"><h3>مبلغ فروش به تفکیک استان</h3><div class="desc">مرتب‌شده نزولی بر اساس مبلغ فروش</div><div class="chart-box" id="salesByStateChart"></div></div>
    <div class="card"><h3>تعداد مشتری خریدار به تفکیک استان</h3><div class="desc">مقایسهٔ تعداد مشتری فعال هر استان</div><div class="chart-box" id="buyersByStateChart"></div></div>
  </div>
  <div class="grid-2" style="margin-top:16px;">
    <div class="card"><h3>مقایسه تعداد فاکتور و مبلغ فروش</h3><div class="desc">استانی با فاکتور زیاد لزوماً مبلغ بالا ندارد و برعکس</div><div class="chart-box" id="comboChart"></div></div>
    <div class="card"><h3>سهم استان‌ها از کل فروش</h3><div class="desc">استان‌های کوچک زیر ]] .. fmt_dec1(CONFIG.OTHER_SLICE_THRESHOLD_PCT) .. [[٪ در «سایر» گروه شده‌اند — دادهٔ خام همچنان در جدول کامل استان‌ها موجود است</div><div class="chart-box" id="salesDonutChart"></div></div>
  </div>
</div>

<div class="section">
  <div class="section-head"><h2><span class="num">۳</span>بیشترین و کمترین</h2><p>کمترین‌ها فقط در میان استان‌های دارای حداقل یک فروش محاسبه شده‌اند</p></div>
  <div class="minmax-grid" id="minmaxGrid">]] .. args.minmax_html .. [[</div>
</div>

<div class="section" id="stateSection">
  <div class="section-head"><h2><span class="num">۴</span>جدول کامل استان‌ها</h2><p>روی هدر ستون‌ها کلیک کنید تا مرتب شود؛ روی هر ردیف کلیک کنید تا جزئیات استان باز شود</p></div>
  <div class="table-scroll"><table class="data-table" id="stateTable"><thead><tr>
    <th>استان</th><th>تعداد مشتری</th><th>تعداد مشتری خریدار</th><th>تعداد فاکتور</th><th>مبلغ فروش</th>
    <th>میانگین فاکتور</th><th>میانگین فروش/خریدار</th><th>تعداد شهر (مشتری)</th><th>تعداد شهر (فروش)</th>
    <th>سهم از فروش</th><th>سهم از مشتری</th>
  </tr></thead><tbody id="stateTbody">]] .. args.state_rows_html .. [[</tbody></table></div>
</div>

<div class="section" id="citySection">
  <div class="section-head"><h2><span class="num">۵</span>شهرهای برتر بر اساس فروش</h2><p>]] .. fmt_num(CONFIG.TOP_CITIES_ON_DASHBOARD) .. [[ شهر برتر — برای فهرست کامل، «نمایش تمام شهرها» را بزنید</p></div>
  <div class="table-scroll"><table class="data-table" id="topCityTable"><thead><tr>
    <th>استان</th><th>شهر</th><th>تعداد مشتری</th><th>تعداد مشتری خریدار</th><th>تعداد فاکتور</th><th>مبلغ فروش</th><th>میانگین فاکتور</th><th>سهم از فروش استان</th>
  </tr></thead><tbody id="topCityTbody">]] .. args.top_city_rows_html .. [[</tbody></table></div>
  <div style="margin-top:10px;"><button type="button" class="btn-secondary" id="toggleCityListBtn" onclick="toggleFullCityList()">نمایش تمام شهرها</button></div>
  <div id="fullCityListBox" style="display:none;margin-top:14px;">
    <div class="search-box"><input type="text" id="citySearchInput" placeholder="جستجوی شهر یا استان..."></div>
    <div class="table-scroll"><table class="data-table" id="fullCityTable"><thead><tr>
      <th>استان</th><th>شهر</th><th>تعداد مشتری</th><th>تعداد مشتری خریدار</th><th>تعداد فاکتور</th><th>مبلغ فروش</th><th>میانگین فاکتور</th>
    </tr></thead><tbody id="fullCityTbody"></tbody></table></div>
  </div>
</div>

<div id="stateDrillPanel" class="drill-panel" style="display:none;"></div>

<footer id="footerText">]] .. escape_html(args.footer_text) .. [[</footer>
]])

    table.insert(html, [[
<div id="helpModal" class="modal"><div class="modal-content">
  <div class="modal-header"><h3>راهنمای داشبورد</h3><button class="modal-close" onclick="closeHelp()">×</button></div>
  <div class="modal-body">
    <p>این داشبورد توزیع جغرافیایی مشتریان CRM و فروش سازمان را بر پایهٔ دادهٔ زندهٔ Teamyar نشان می‌دهد.</p>
    <h4>KPIهای بالای صفحه</h4>
    <ul>
      <li><b>پوشش جغرافیایی فروش:</b> تعداد شهرهای دارای حداقل یک فروش معتبر، تقسیم بر ]] .. fmt_num(CONFIG.TOTAL_CITIES_IRAN) .. [[ (آمار رسمی شهرهای ایران، سال ۱۴۰۴).</li>
      <li><b>کیفیت دادهٔ جغرافیایی:</b> مشتریان/فاکتورهایی که آدرس معتبر ندارند حذف نشده‌اند، جداگانه شمرده شده‌اند تا کیفیت دادهٔ CRM شفاف بماند.</li>
    </ul>
    <h4>تعامل‌ها</h4>
    <ul>
      <li>فیلترهای بالای صفحه (تاریخ از، استان، شهر، نوع مشتری) کل داشبورد را بر اساس فاکتورهای همان بازه/محدوده فیلتر می‌کنند.</li>
      <li>روی هر ردیف نمودار میله‌ای یا جدول استان‌ها کلیک کنید تا پنل جزئیات همان استان باز شود.</li>
      <li>در پنل استان، روی هر شهر کلیک کنید تا فهرست مشتریان همان شهر (با صفحه‌بندی) بارگذاری شود.</li>
      <li>روی هر مشتری کلیک کنید تا فهرست فاکتورهای او در یک پنجره باز شود؛ لینک «مشاهده CRM» صفحهٔ مشتری را در تب جدید Teamyar باز می‌کند.</li>
      <li>روی هدر هر جدول کلیک کنید تا صعودی/نزولی مرتب شود؛ «نمایش تمام شهرها» فهرست کامل با جستجو را باز می‌کند.</li>
      <li>تمام‌صفحه / خروجی Excel (از جدول کامل استان‌ها) از نوار ابزار بالا در دسترس است.</li>
    </ul>
    <h4>محدودیت شناخته‌شده (v01)</h4>
    <ul>
      <li>هیچ جدول مرجع رسمی «شهرهای ایران» در دیتابیس Teamyar پیدا نشد؛ مخرج KPI پوشش جغرافیایی عددی ثابت و مستند است، نه Query زنده.</li>
      <li>برچسب دقیق «نوع مشتری» (کدهای ۳ و ۴) در دیتابیس مستند نیست و به‌صورت خام نمایش داده می‌شود.</li>
    </ul>
  </div>
</div></div>
<div id="invoiceModal" class="modal"><div class="modal-content">
  <div class="modal-header"><h3 id="invoiceModalTitle">فاکتورها</h3><button class="modal-close" onclick="closeInvoiceModal()">×</button></div>
  <div class="modal-body" id="invoiceModalBody"></div>
</div></div>
<div id="dqModal" class="modal"><div class="modal-content" style="max-width:820px;">
  <div class="modal-header"><h3 id="dqModalTitle">جزئیات کیفیت داده</h3><button class="modal-close" onclick="closeDqModal()">×</button></div>
  <div class="modal-body" id="dqModalBody"></div>
</div></div>
]])

    table.insert(html, '<script id="dashData" type="application/json">' .. dash_json .. '</script>\n')
    table.insert(html, REPORT_JS)
    table.insert(html, '</div>\n</body>\n</html>')

    return table.concat(html)
end

-- ============================================================
-- MAIN
-- ============================================================

local function main()
    local input = teamyar.get_input() or {}

    -- ------------- Drill-down: مشتریان یک شهر (Lazy، پارامتری، مستقل از Dashboard اصلی) -------------
    if input["action"] == "customers" then
        local state = input["state"]
        local city = input["city"]
        if state == nil or state == "" or city == nil or city == "" then
            teamyar.write_result(json.encode({ ok = false, error = "استان یا شهر مشخص نشده است" }))
            return
        end
        local filters = { user_type = tonumber(input["user_type"]) }
        local offset = tonumber(input["offset"]) or 0
        if offset < 0 then offset = 0 end
        local limit = CONFIG.CUSTOMER_PAGE_SIZE
        local total, cnt_err = fetch_customers_count(state, city, filters)
        local rows, err = fetch_customers(state, city, filters, limit, offset)
        if rows == nil then
            teamyar.write_result(json.encode({ ok = false, error = "خطا در دریافت فهرست مشتریان: " .. tostring(err or cnt_err) }))
            return
        end
        teamyar.write_result(json.encode({ ok = true, rows = rows, total = total, offset = offset, limit = limit }))
        return
    end

    -- ------------- Drill-down: فاکتورهای یک مشتری (Lazy) -------------
    if input["action"] == "invoices" then
        local crm_id = tonumber(input["crm_id"])
        if crm_id == nil then
            teamyar.write_result(json.encode({ ok = false, error = "شناسه مشتری نامعتبر است" }))
            return
        end
        local customer = fetch_customer_header(crm_id)
        local rows, err = fetch_invoices(crm_id)
        if rows == nil then
            teamyar.write_result(json.encode({ ok = false, error = "خطا در دریافت فاکتورها: " .. tostring(err) }))
            return
        end
        teamyar.write_result(json.encode({ ok = true, rows = rows, customer = customer }))
        return
    end

    -- ------------- Drill-down: مشتریان بدون استان/شهر (کارت‌های کیفیت داده) -------------
    if input["action"] == "dq_customers" then
        local field = input["field"]
        if field ~= "city" then field = "state" end
        local offset = tonumber(input["offset"]) or 0
        if offset < 0 then offset = 0 end
        local limit = CONFIG.CUSTOMER_PAGE_SIZE
        local total, cnt_err = fetch_customers_missing_geo_count(field)
        local rows, err = fetch_customers_missing_geo(field, limit, offset)
        if rows == nil then
            teamyar.write_result(json.encode({ ok = false, error = "خطا در دریافت فهرست: " .. tostring(err or cnt_err) }))
            return
        end
        teamyar.write_result(json.encode({ ok = true, rows = rows, total = total, offset = offset, limit = limit, field = field }))
        return
    end

    -- ------------- Drill-down: فاکتورهای بدون نگاشت جغرافیایی (کارت کیفیت داده) -------------
    if input["action"] == "dq_invoices" then
        local offset = tonumber(input["offset"]) or 0
        if offset < 0 then offset = 0 end
        local limit = CONFIG.CUSTOMER_PAGE_SIZE
        local total, cnt_err = fetch_invoices_missing_geo_count()
        local rows, err = fetch_invoices_missing_geo(limit, offset)
        if rows == nil then
            teamyar.write_result(json.encode({ ok = false, error = "خطا در دریافت فهرست: " .. tostring(err or cnt_err) }))
            return
        end
        teamyar.write_result(json.encode({ ok = true, rows = rows, total = total, offset = offset, limit = limit }))
        return
    end

    -- ------------- Dashboard اصلی (KPI + State/City Aggregation) -------------
    local filters = parse_filters(input)

    local now_raw, now_err = fetch_now_raw()
    local fy_key, fy_jndate = resolve_fiscal_year_start(now_raw)

    local date_from_key = nil
    local date_from_label = filters.date_from_text
    if filters.date_from_text ~= nil then
        date_from_key = resolve_date_from_text(filters.date_from_text)
    end
    local date_warning = nil
    if date_from_key == nil then
        if filters.date_from_text ~= nil then
            date_warning = "تاریخ واردشده («" .. filters.date_from_text .. "») در تقویم سیستم یافت نشد؛ به ابتدای سال مالی جاری بازگردانده شد."
        end
        date_from_key = fy_key
        date_from_label = fy_jndate
    end
    if date_from_key == nil then
        teamyar.write_result(render_error_html("امکان تعیین بازهٔ زمانی گزارش وجود ندارد (خطا در report_dimdate): " .. tostring(now_err)))
        return
    end

    local crm_kpi, crm_err = fetch_crm_kpi()
    if crm_kpi == nil then
        teamyar.write_result(render_error_html("خطا در محاسبهٔ KPI مشتریان: " .. tostring(crm_err)))
        return
    end

    local sales_kpi, sales_err = fetch_sales_kpi(date_from_key, filters)
    if sales_kpi == nil then
        teamyar.write_result(render_error_html("خطا در محاسبهٔ KPI فروش: " .. tostring(sales_err)))
        return
    end

    local states, states_err = fetch_state_aggregation(date_from_key, filters)
    if states == nil then
        teamyar.write_result(render_error_html("خطا در تجمیع استان‌ها: " .. tostring(states_err)))
        return
    end
    local cities, cities_err = fetch_city_aggregation(date_from_key, filters)
    if cities == nil then
        teamyar.write_result(render_error_html("خطا در تجمیع شهرها: " .. tostring(cities_err)))
        return
    end

    local state_totals_by_name = {}
    for _, s in ipairs(states) do state_totals_by_name[s.state_name] = s end
    enrich_state_list(states, sales_kpi)
    enrich_city_list(cities, state_totals_by_name)
    table.sort(cities, function(a, b) return a.total_sales_amount > b.total_sales_amount end)

    local coverage = {
        cities_with_sales = sales_kpi.cities_with_sales,
        total_cities = CONFIG.TOTAL_CITIES_IRAN,
        pct = fmt_pct(sales_kpi.cities_with_sales, CONFIG.TOTAL_CITIES_IRAN),
    }

    local dash_data = build_dash_data(states, cities, date_from_label)
    local generated_jdate = fy_jndate -- برچسب مرجع؛ برای «امروز» دقیق کافی نیست، صرفاً نمایشی است

    local state_options = {}
    for _, s in ipairs(states) do table.insert(state_options, s.state_name) end
    local user_type_options = { 3, 4 }

    local kpi_cards_html = render_kpi_cards(crm_kpi, sales_kpi, coverage)
    local data_quality_html = render_data_quality_cards(crm_kpi, sales_kpi)
    local minmax_html = render_minmax_cards(compute_minmax(states))
    local state_rows_html = render_state_table_rows(states)
    local top_city_rows_html = render_city_table_rows(cities, CONFIG.TOP_CITIES_ON_DASHBOARD)
    local footer_text = "تولید شده — " .. fmt_num(#states) .. " استان و " .. fmt_num(#cities) .. " شهر دارای مشتری" ..
        (date_warning and (" — هشدار: " .. date_warning) or "")

    if input["format"] == "json" then
        teamyar.write_result(json.encode({
            ok = true,
            dash_data = dash_data,
            kpi_cards_html = kpi_cards_html,
            data_quality_html = data_quality_html,
            minmax_html = minmax_html,
            state_rows_html = state_rows_html,
            top_city_rows_html = top_city_rows_html,
            footer_text = footer_text,
        }))
        return
    end

    local filter_bar_html = render_filter_bar(filters, date_from_label, state_options, user_type_options)

    local html = render_html({
        dash_data = dash_data,
        date_from_label = date_from_label,
        generated_jdate = generated_jdate,
        filter_bar_html = filter_bar_html,
        kpi_cards_html = kpi_cards_html,
        data_quality_html = data_quality_html,
        minmax_html = minmax_html,
        state_rows_html = state_rows_html,
        top_city_rows_html = top_city_rows_html,
        footer_text = footer_text,
    })
    teamyar.write_result(html)
end

local ok, err = pcall(main)
if not ok then
    teamyar.write_result(render_error_html(tostring(err)))
end

