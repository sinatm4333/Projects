-- تحلیل و ایجاد توسط مهدی جهانی 09125632329
-- Last Edit = 1405/05/21 00:45

-- botName = moadian_factor_tabs
-- description = فاکتورهای ارسالی به سامانه مودیان (ارسالی/ابطالی/اصلاحی) — نسخه ۴ (بازطراحی موتور کوئری)
-- version = 4
--
-- چرا این نسخه دوباره بازنویسی شد: نسخهٔ قبلی (v3) مثل بات مبدأ ۵۷۸/۵۹۸ از teamyar.get_config() و سه
-- پیوست querySend/queryDelete/queryEdite.txt می‌خواند. در عمل معلوم شد «پیکربندی» این بات هرگز مقدار
-- واقعی ذخیره‌شده ندارد (چه روی ۵۹۵ چه ۵۹۸، بارها از طریق API و از طریق خود پنل بررسی شد) و همین باعث
-- کرش/عدم بارگذاری تب «ارسالی» می‌شد. به‌جای تلاش بیشتر برای رفع پیکربندی، با بات مرجعِ فعال و واقعاً
-- استفاده‌شونده در این خانواده — «ارسال گروهی به سامانه مودیان[Module]» (بات ۵۷۴، پیوست
-- query_list_invoice.txt) — مقایسه شد و دو تفاوت واقعی پیدا شد:
--   ۱) بات ۵۷۴ فیلتر `i.type IN (1,3)` روی sales_invoice دارد که در querySend/queryDelete/queryEdite.txt
--      بات ۵۷۸ اصلاً نبود.
--   ۲) نگاشت وضعیت بات ۵۷۴ (تابع sendStatusAcl + CASE WHEN کوئری) کدهای ۱۱۹/۱۲۰/۲۱۹/۲۲۰/۳۱۹/۳۲۰/۴۰۰ را
--      هم دارد که در querySend/queryDelete/queryEdite.txt بات ۵۷۸ نبودند (همان کدهای ۱۲۰/۴۰۰ که در
--      دادهٔ زنده دیده شده بودند ولی «نامشخص» نمایش داده می‌شدند).
-- این نسخه کوئری را با همین دو اصلاح، به‌صورت خودکفا (بدون get_config/get_attachment/پیوست دستی) در خود
-- فایل جاسازی کرده — پایدارتر و مستقل از وضعیت تب «پیکربندی» پنل. بازهٔ پیش‌فرض: ۳۶۵ روز اخیر، سازمان ۸
-- (طبق دادهٔ زنده، تنها سازمانی که فاکتور با moadian_status>0 دارد) — با from_date/to_date/org_id در
-- ورودی قابل بازنویسی.
--
-- ظاهر/UI: جدول (نه کارت — طبق بازخورد کاربر برای مرور سریع تعداد زیاد ردیف)، پالت #16509D، فونت Peyda
-- self-contained، نوار ابزار تمام‌صفحه/Excel/راهنما، جعبه جستجوی آنی، هدر ستون‌های مرتب‌سازی‌پذیر،
-- کارت‌های خلاصهٔ KPI، و referenceNumber/شناسهٔ یکتا به‌صورت خلاصه‌شده با کلیک-برای-کپی. `dir="rtl"` +
-- `direction: rtl` صریح روی ریشهٔ گزارش ست شده — بدون آن، flex/جدول با ترتیب چپ‌به‌راست رندر می‌شد
-- (چون این fragment جدا از هر <html dir="rtl"> والدی رندر می‌شود، نمی‌شود به ارث‌بری تکیه کرد).
-- AJAX فقط با fetch خام انجام می‌شود (نه $.Teamyar.ajax) — در تست‌های واقعی چندبار با خطا/سکوت مواجه شد؛
-- روی خطا، جزئیات واقعی (کد HTTP یا پیام شبکه) نمایش داده می‌شود، نه فقط پیام کلی.
--
-- ورودی: org_id (پیش‌فرض 8)، from_date/to_date (شمسی، اختیاری — پیش‌فرض ۳۶۵ روز اخیر)، limit (پیش‌فرض
-- 500)، type=1|2|3 (AJAX سه تب)، type=4+fid+referenceNumber (AJAX استعلام فاکتور)، format=json

local input = teamyar.get_input() or {}

local table_unpack = table.unpack or unpack
local HTML_DQ = string.char(34)
-- طبق دادهٔ زنده (schema_probe_v2 روی sales_invoice) org_id=8 تنها سازمانی است که فاکتور با
-- moadian_status>0 دارد.
local DEFAULT_ORG_ID = 8
local DEFAULT_DAYS_BACK = 365
local DEFAULT_ROW_LIMIT = 500
local MAX_ROW_LIMIT = 3000

local function normalize_text(value)
    if value == nil then return nil end
    local text = tostring(value):match("^%s*(.-)%s*$")
    if text == "" then return nil end
    return text
end

local function normalize_jalali_date(value)
    local s = normalize_text(value)
    if s == nil then return nil end
    s = s:gsub("/", "-"):gsub("%.", "-")
    local y, m, d = s:match("^(%d%d%d%d)-(%d%d?)-(%d%d?)$")
    if y then
        return string.format("%04d-%02d-%02d", tonumber(y), tonumber(m), tonumber(d))
    end
    return nil
end

-- تبدیل شمسی به میلادی (الگوریتم چرخه ۳۳ ساله؛ همان تابع تأییدشدهٔ trial_balance_report_bot.lua)
local function jalali_to_gregorian(jy, jm, jd)
    local gy
    if jy > 979 then gy = 1600; jy = jy - 979 else gy = 621 end
    local days = 365 * jy + math.floor(jy / 33) * 8 + math.floor(((jy % 33) + 3) / 4) + 78 + jd
    if jm < 7 then days = days + (jm - 1) * 31 else days = days + (jm - 1) * 30 + 6 end
    gy = gy + 400 * math.floor(days / 146097)
    days = days % 146097
    local leap = true
    if days >= 36525 then
        days = days - 1
        gy = gy + 100 * math.floor(days / 36524)
        days = days % 36524
        if days >= 365 then days = days + 1 else leap = false end
    end
    gy = gy + 4 * math.floor(days / 1461)
    days = days % 1461
    if days >= 366 then
        leap = false
        days = days - 1
        gy = gy + math.floor(days / 365)
        days = days % 365
    end
    local gd = days + 1
    local sal_a = { 0, 31, leap and 29 or 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
    local gm = 0
    for i = 1, 12 do
        local v = sal_a[i + 1]
        if gd <= v then gm = i; break end
        gd = gd - v
    end
    return gy, gm, gd
end

local function jalali_to_gregorian_datetime(jalali_date, time_part)
    local y, m, d = jalali_date:match("^(%d%d%d%d)-(%d%d)-(%d%d)$")
    if y == nil then return nil end
    local gy, gm, gd = jalali_to_gregorian(tonumber(y), tonumber(m), tonumber(d))
    return string.format("%04d-%02d-%02d %s", gy, gm, gd, time_part)
end

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

local function escape_html(value)
    if value == nil then return '' end
    return tostring(value):gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;'):gsub(HTML_DQ, '&quot;')
end

local function fmt_num(value)
    local n = tonumber(value)
    if n == nil then return "0" end
    local s = tostring(math.floor(n + 0.5))
    local sign = ""
    if s:sub(1, 1) == "-" then sign = "-"; s = s:sub(2) end
    return sign .. s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

-- برچسب moadian_status — تکمیل‌شده طبق بات مرجع ۵۷۴ (query_list_invoice.txt)، شامل کدهایی که در
-- querySend/queryDelete/queryEdite.txt بات ۵۷۸ نبودند: 119،120،219،220،319،320،400
local STATUS_LABELS = {
    [0] = 'ارسال نشده', [1] = 'ارسال شده', [2] = 'خطا', [3] = 'تایید شده',
    [4] = 'درخواست ابطال', [5] = 'خطا در ثبت ابطال', [6] = 'ابطال',
    [101] = 'پذیرفته شده [ارسالی]', [102] = 'رد شده [ارسالی]', [103] = 'در انتظار بررسی [ارسالی]',
    [104] = 'ابطال شده [ارسالی]', [105] = 'ناموفق / خطا در پردازش [ارسالی]', [106] = 'در حال پردازش [ارسالی]',
    [107] = 'پیش‌نویس [ارسالی]', [108] = 'ارسال شده [ارسالی]', [109] = 'در انتظار [ارسالی]',
    [110] = 'دیگر نیازی به واکنش نیست [ارسالی]', [111] = 'نامشخص [ارسالی]', [112] = 'پیدا نشده [ارسالی]',
    [113] = 'خطادراستعلام [ارسالی]', [114] = 'خطا در ارتباط [ارسالی]', [115] = 'استعلام نشده [ارسالی]',
    [116] = 'عدم ارسال/خطا [ارسالی]', [117] = 'تنظیمات پیکربندی خالی [ارسالی]', [118] = 'عدم ارتباط سامانه [ارسالی]',
    [119] = 'لغو شده [ارسالی]', [120] = 'در انتظار واکنش [ارسالی]',
    [201] = 'پذیرفته شده [ابطالی]', [202] = 'رد شده [ابطالی]', [203] = 'در انتظار بررسی [ابطالی]',
    [204] = 'ابطال شده [ابطالی]', [205] = 'ناموفق / خطا در پردازش [ابطالی]', [206] = 'در حال پردازش [ابطالی]',
    [207] = 'پیش‌نویس [ابطالی]', [208] = 'ارسال شده [ابطالی]', [209] = 'در انتظار [ابطالی]',
    [210] = 'دیگر نیازی به واکنش نیست [ابطالی]', [211] = 'نامشخص [ابطالی]', [212] = 'پیدا نشده [ابطالی]',
    [213] = 'خطادراستعلام [ابطالی]', [214] = 'خطا در ارتباط [ابطالی]', [215] = 'استعلام نشده [ابطالی]',
    [216] = 'عدم ارسال/خطا [ابطالی]', [217] = 'تنظیمات پیکربندی خالی [ابطالی]', [218] = 'عدم ارتباط سامانه [ابطالی]',
    [219] = 'لغو شده [ابطالی]', [220] = 'در انتظار واکنش [ابطالی]',
    [301] = 'پذیرفته شده [اصلاحی]', [302] = 'رد شده [اصلاحی]', [303] = 'در انتظار بررسی [اصلاحی]',
    [304] = 'ابطال شده [اصلاحی]', [305] = 'ناموفق / خطا در پردازش [اصلاحی]', [306] = 'در حال پردازش [اصلاحی]',
    [307] = 'پیش‌نویس [اصلاحی]', [308] = 'ارسال شده [اصلاحی]', [309] = 'در انتظار [اصلاحی]',
    [310] = 'دیگر نیازی به واکنش نیست [اصلاحی]', [311] = 'نامشخص [اصلاحی]', [312] = 'پیدا نشده [اصلاحی]',
    [313] = 'خطادراستعلام [اصلاحی]', [314] = 'خطا در ارتباط [اصلاحی]', [315] = 'استعلام نشده [اصلاحی]',
    [316] = 'عدم ارسال/خطا [اصلاحی]', [317] = 'تنظیمات پیکربندی خالی [اصلاحی]', [318] = 'عدم ارتباط سامانه [اصلاحی]',
    [319] = 'لغو شده [اصلاحی]', [320] = 'در انتظار واکنش [اصلاحی]',
    [400] = 'نامشخص',
}
local function status_label_for(code)
    if code == nil then return "ارسال نشده" end
    return STATUS_LABELS[code] or ("نامشخص (کد " .. tostring(code) .. ")")
end

-- بازهٔ هر تب — کران بالا اکنون شامل خود عدد (<=120/220/320) است، چون کدهای 120/220/320 («در انتظار
-- واکنش») طبق بات مرجع ۵۷۴ متعلق به همان تب‌اند، نه بیرون از بازه.
local STATUS_CONDITIONS = {
    [1] = "(i.moadian_status IN (1,2,3) OR (i.moadian_status > 100 AND i.moadian_status <= 120))",
    [2] = "(i.moadian_status IN (4,5,6) OR (i.moadian_status > 200 AND i.moadian_status <= 220))",
    [3] = "(i.moadian_status IN (7,8,9) OR (i.moadian_status > 300 AND i.moadian_status <= 320))",
}

local intype = tonumber(input.type or input["type"]) or 0
local as_json = (tostring(input.format or ""):lower() == "json") or intype ~= 0
local org_id = tonumber(input.org_id or input.orgId) or DEFAULT_ORG_ID
local row_limit = tonumber(input.limit or input.per_page or input.perPage) or DEFAULT_ROW_LIMIT
if row_limit < 1 then row_limit = DEFAULT_ROW_LIMIT end
if row_limit > MAX_ROW_LIMIT then row_limit = MAX_ROW_LIMIT end

----------------
function inqueryfactor(fid,referenceNumber,org_id)
  local res_bot = teamyar.run_command("2/inquery_invoice_taxpayer_m/", { referenceNumber = referenceNumber, invoice_id = tostring(fid), org_id = tostring(org_id)});
  local res_status = teamyar.run_command("2/fact_st_m" , { invoice_id = tostring(fid), org_id = tostring(org_id) });
  return res_bot, res_status
end

-- ==================== type=4: استعلام یک فاکتور ====================
if intype == 4 then
    local fid = normalize_text(input.fid or input.invoice_id)
    local referenceNumber = input.referenceNumber or input.reference_number or ""
    if fid == nil then
        teamyar.write_result(json.encode({ ok = false, error = "شماره فاکتور مشخص نیست" }))
        return
    end
    local ok_run, res_a, res_b = pcall(function() return inqueryfactor(fid, referenceNumber, org_id) end)
    if not ok_run then
        teamyar.write_result(json.encode({ ok = false, error = "خطا در استعلام از سامانه مودیان", detail = tostring(res_a) }))
        return
    end
    local msg = "شماره فاکتور: " .. escape_html(fid) .. "&nbsp;&nbsp;" .. tostring(res_a) .. "<br>وضعیت در سامانه: " .. tostring(res_b)
    teamyar.write_result(json.encode({ ok = true, msg = msg }))
    return
end

-- ==================== بازهٔ تاریخ ====================
local from_jalali = normalize_jalali_date(input["from_date"] or input["fromDate"])
local to_jalali = normalize_jalali_date(input["to_date"] or input["toDate"])

local tb_from, tb_to
if from_jalali and to_jalali then
    local from_g = jalali_to_gregorian_datetime(from_jalali, "00:00:00")
    local to_g = jalali_to_gregorian_datetime(to_jalali, "23:59:59")
    local bound_rows = fetch_rows(
        "SELECT (UNIX_TIMESTAMP(?) + 11644473600) * 10000000, (UNIX_TIMESTAMP(?) + 11644473600) * 10000000",
        { from_g, to_g }
    )
    if bound_rows ~= nil and bound_rows[1] ~= nil then
        tb_from = tonumber(bound_rows[1][1])
        tb_to = tonumber(bound_rows[1][2])
    end
else
    local bound_rows = fetch_rows(
        "SELECT (UNIX_TIMESTAMP() + 11644473600) * 10000000 - (? * 86400 * 10000000), (UNIX_TIMESTAMP() + 11644473600) * 10000000",
        { DEFAULT_DAYS_BACK }
    )
    if bound_rows ~= nil and bound_rows[1] ~= nil then
        tb_from = tonumber(bound_rows[1][1])
        tb_to = tonumber(bound_rows[1][2])
    end
end

if tb_from == nil or tb_to == nil then
    teamyar.write_result(json.encode({ ok = false, error = "خطا در محاسبه بازه تاریخ" }))
    return
end

-- ==================== کوئری مشترک سه تب — بر مبنای query_list_invoice.txt بات ۵۷۴ (بات مرجع) ====================
-- تفاوت با اتچمنت‌های بات ۵۷۸: فیلتر i.type IN (1,3) اضافه شد (در مرجع هست، در بات ۵۷۸ نبود)،
-- cte_org از ابتدا با WHERE c.ORG_ID=? محدود شده (بات مرجع هم مثل بات ۵۷۸ این فیلتر را نداشت — این یک
-- بهبود کارایی اضافه است، نه چیزی که از مرجع کپی شده).
local function build_data_query(status_condition)
    return string.format([[
WITH cte_org AS (
    SELECT i.id AS INVOICE_ID,
           d.DECIMAL_COUNT AS Digit,
           CASE WHEN COALESCE(d.DECIMAL_COUNT,0) <> 0 THEN COALESCE(d.DECIMAL_COUNT,0) ELSE COALESCE(d.FEE_DECIMAL,0) END AS DigitFee
    FROM PA_ORGANIZATIONS c
    JOIN SALES_INVOICE i ON i.org_id = c.org_id
    INNER JOIN PA_SYMBOLS d ON (d.ID = c.BASE_CURRENCY AND d.ORG_ID = c.ORG_ID)
    WHERE c.ORG_ID = ?
),
cte_product AS (
    SELECT o.INVOICE_ID,
           IF(COALESCE(d.QUANTITY_CONFIRMED,0) > 0, COALESCE(d.QUANTITY_CONFIRMED,0), COALESCE(d.QUANTITY,0)) AS quantity,
           COALESCE(c.DECIMAL_NUM,0) AS dec_quantity,
           COALESCE(d.BASE_SYMBOL_FEE,0) AS BASE_SYMBOL_FEE,
           COALESCE(o.DigitFee,0) AS DigitFee,
           COALESCE(o.Digit,0) AS Digit,
           COALESCE(d.BASE_SYMBOL_DISCOUNT,0) AS BASE_SYMBOL_DISCOUNT,
           COALESCE(d.BASE_SYM_VALUE_ADDED,0) AS BASE_SYM_VALUE_ADDED,
           COALESCE(d.BASE_SYMBOL_TAX,0) AS BASE_SYMBOL_TAX,
           COALESCE(d.BASE_SYMBOL_TOLL,0) AS BASE_SYMBOL_TOLL
    FROM sales_invoice_product d
    JOIN wh_product p ON d.product_id = p.id
    JOIN wh_stock_capacity c ON p.CAPACITY_ID = c.ID
    JOIN cte_org o ON d.INVOICE_ID = o.INVOICE_ID
),
cte_addition AS (
    SELECT o.INVOICE_ID,
           SUM(ROUND(CASE WHEN (a.EFFECT = 1 OR a.EFFECT = 3) THEN (COALESCE(a.QUANTITY,0)/POWER(10,COALESCE(o.Digit,0)))*(-1)
                          WHEN (a.EFFECT = 2 OR a.EFFECT = 4) THEN (COALESCE(a.QUANTITY,0)/POWER(10,COALESCE(o.Digit,0)))
                          ELSE 0 END)) AS ADDITION
    FROM SALES_INVOICE_ADDITIONS a
    JOIN cte_org o ON a.INVOICE_ID = o.INVOICE_ID
    GROUP BY o.INVOICE_ID
),
cte_amount_products AS (
    SELECT INVOICE_ID,
           SUM(ROUND((quantity/POWER(10,dec_quantity) * (BASE_SYMBOL_FEE/POWER(10,DigitFee)))
               - BASE_SYMBOL_DISCOUNT/POWER(10,Digit)
               + BASE_SYM_VALUE_ADDED/POWER(10,Digit)
               + BASE_SYMBOL_TAX/POWER(10,Digit)
               + BASE_SYMBOL_TOLL/POWER(10,Digit))) AS AMOUNT
    FROM cte_product
    GROUP BY INVOICE_ID
),
amounts AS (
    SELECT ROUND(p.AMOUNT + COALESCE(a.ADDITION,0)) AS iamount, i.id AS id
    FROM cte_amount_products p
    LEFT JOIN cte_addition a ON p.INVOICE_ID = a.INVOICE_ID
    JOIN SALES_INVOICE i ON i.ID = p.INVOICE_ID
),
e_h AS (
    SELECT id, invoice_id,
           REPLACE(SUBSTRING_INDEX(NOTE, "<div id='res_inquery'>", -1), '</div></td></tr></table>', '') AS ef
    FROM sales_history
    WHERE note LIKE "%%<div id='res_inquery'>%%"
),
m_h AS (
    SELECT id, invoice_id,
           TRIM(SUBSTRING_INDEX(REPLACE(SUBSTRING_INDEX(NOTE, 'result_referenceNumber:<br>', -1), '</td></tr></table>', ''), '<br>', 1)) AS rf
    FROM sales_history
    WHERE note LIKE '%%result_referenceNumber:<br>%%'
),
m_factor_id AS (
    SELECT id, invoice_id,
           SUBSTRING_INDEX(SUBSTRING_INDEX(note, 'factor_tax_id:<br>', -1), '<br>', 1) AS rf
    FROM sales_history
    WHERE note LIKE '%%factor_tax_id:<br>%%'
)
SELECT DISTINCT
    i.id,
    i.INVOICE_CODE,
    COALESCE(i.TITLE,'--'),
    i.RUN_DATE,
    (SELECT iamount FROM amounts WHERE id = i.id),
    (SELECT rf FROM m_h WHERE invoice_id = i.id ORDER BY id DESC LIMIT 1),
    (SELECT rf FROM m_factor_id WHERE invoice_id = i.id ORDER BY id DESC LIMIT 1),
    i.moadian_status,
    (SELECT ef FROM e_h WHERE invoice_id = i.id ORDER BY id DESC LIMIT 1),
    i.DATE_MODIFIED
FROM sales_invoice i
INNER JOIN sales_invoice_product ip ON i.id = ip.invoice_id
WHERE i.status > 1
  AND i.DELETED = 0
  AND i.type IN (1,3)
  AND i.org_id = ?
  AND i.RUN_DATE BETWEEN ? AND ?
  AND %s
ORDER BY i.DATE_MODIFIED DESC
LIMIT ?
]], status_condition)
end

local function build_count_query(status_condition)
    return string.format([[
SELECT COUNT(DISTINCT i.id)
FROM sales_invoice i
INNER JOIN sales_invoice_product ip ON i.id = ip.invoice_id
WHERE i.status > 1
  AND i.DELETED = 0
  AND i.type IN (1,3)
  AND i.org_id = ?
  AND i.RUN_DATE BETWEEN ? AND ?
  AND %s
]], status_condition)
end

local function fetch_tab_rows(tab_type, limit)
    local condition = STATUS_CONDITIONS[tab_type]
    if condition == nil then return nil, "نوع تب نامعتبر است", 0 end

    local rows, err = fetch_rows(build_data_query(condition), { org_id, org_id, tb_from, tb_to, limit })
    if rows == nil then return nil, err, 0 end

    local count_rows = fetch_rows(build_count_query(condition), { org_id, tb_from, tb_to })
    local total = 0
    if count_rows ~= nil and count_rows[1] ~= nil and count_rows[1][1] ~= nil then
        total = tonumber(count_rows[1][1]) or 0
    end

    -- شکل خروجی هر ردیف عمداً با ستون‌های قدیمی (id/name/date/amont/rf/uid/st/err/btn) یکسان نگه داشته
    -- شده چون JS سمت کلاینت (loadTabData) دقیقاً همین کلیدها را می‌خواند — با این تفاوت که لینک فاکتور
    -- و دکمهٔ استعلام اینجا با escape_html ساخته می‌شوند (نه CONCAT خام در SQL مثل بات مرجع ۵۷۴).
    local items = {}
    for _, row in ipairs(rows) do
        local invoice_id = row[1]
        local invoice_code = row[2] or ""
        local title = row[3] or "--"
        local reference_number = row[6] or ""
        local status_code = tonumber(row[8])

        local link_html = string.format(
            '<a target="_blank" href="/?page=/sales/invoice/view_invoice/%s">%s</a>',
            escape_html(invoice_id), escape_html(invoice_code)
        )

        local btn_html = ""
        if reference_number ~= "" then
            btn_html = string.format(
                "<button type='button' id='mdp_print_btn' style='float:left;' class='btn ty-btn-default core_btn btnforsubmit core_btn_submit_Form core_btn_revers_change ty-btn-ok' onclick='ty__main.inquery_factor(%s,%s,%s)'>استعلام</button>",
                tostring(invoice_id), string.format("%q", reference_number), tostring(tab_type)
            )
        end

        table.insert(items, {
            id = link_html,
            name = escape_html(title),
            date = row[4],
            amont = row[5] or 0,
            rf = reference_number,
            uid = row[7] or "",
            st = status_label_for(status_code),
            err = escape_html(row[9] or ""),
            btn = btn_html,
        })
    end
    return items, nil, total
end

-- فقط کوئری شمارش سبک را اجرا می‌کند (نه کوئری کامل داده با CTEهای مبلغ) — برای کارت‌های KPI صفحهٔ اول
-- که فقط عدد کل لازم دارند، نه ردیف‌ها؛ در غیر این صورت روی تب «ارسالی» (~75هزار ردیف) هزینهٔ اجرای
-- کامل CTE فقط برای گرفتن یک عدد، بی‌دلیل دوبرابر می‌شد.
local function safe_tab_total(tab_type)
    local condition = STATUS_CONDITIONS[tab_type]
    if condition == nil then return nil end
    local count_rows = fetch_rows(build_count_query(condition), { org_id, tb_from, tb_to })
    if count_rows == nil or count_rows[1] == nil or count_rows[1][1] == nil then return nil end
    return tonumber(count_rows[1][1])
end

-- ==================== type=1|2|3: دادهٔ یک تب (AJAX) ====================
if intype == 1 or intype == 2 or intype == 3 then
    local items, tab_err, total = fetch_tab_rows(intype, row_limit)
    if items == nil then
        teamyar.write_result(json.encode({ ok = false, error = "خطا در دریافت فاکتورهای مودیان", detail = tostring(tab_err) }))
        return
    end
    teamyar.write_result(json.encode({ ok = true, data = items, total = total, count = #items }))
    return
end

-- ==================== format=json بدون type: هر سه تب ====================
if as_json then
    local out = {}
    for i = 1, 3 do
        local items, tab_err, total = fetch_tab_rows(i, row_limit)
        if items == nil then
            out[i] = { ok = false, error = tab_err }
        else
            out[i] = { ok = true, total = total, count = #items, data = items }
        end
    end
    teamyar.write_result(json.encode({ ok = true, org_id = org_id, tabs = { sent = out[1], canceled = out[2], corrected = out[3] } }))
    return
end

-- ==================== خروجی HTML ====================

local total_sent = fmt_num(safe_tab_total(1) or 0)
local total_canceled = fmt_num(safe_tab_total(2) or 0)
local total_corrected = fmt_num(safe_tab_total(3) or 0)

local res_data = string.format([[

<div class="mft-container" dir="rtl">
<div class="card">
  <div class="top-bar">
    <img class="brand-mark" src="data:image/png;base64,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" alt="Mobile140">
    <div class="toolbar">
      <button type="button" class="btn-action" id="btnFullscreen" onclick="toggleFullScreen()">تمام صفحه</button>
      <button type="button" class="btn-action" onclick="exportTableToExcel()">خروجی Excel</button>
      <button type="button" class="btn-action" onclick="openHelpModal()">راهنما</button>
    </div>
  </div>

  <div id="helpModalOverlay" class="help-overlay" onclick="if(event.target===this){closeHelpModal();}">
    <div class="help-modal">
      <div class="help-modal-header">
        <strong>راهنمای گزارش فاکتورهای ارسالی به سامانه مودیان</strong>
        <button type="button" class="help-close" onclick="closeHelpModal()">✕</button>
      </div>
      <div class="help-modal-body">
        <p><strong>این گزارش چیست؟</strong> فاکتورهای ارسال‌شده به سامانهٔ مودیان (مالیات) را در سه تب نشان می‌دهد. کارت‌های بالای صفحه خلاصهٔ تعداد کل هر وضعیت را نشان می‌دهند.</p>
        <p><strong>تب‌ها:</strong></p>
        <ul>
          <li><b>ارسالی</b> — فاکتورهای ارسال‌شده به سامانه</li>
          <li><b>ابطالی</b> — فاکتورهایی که درخواست/فرآیند ابطال آن‌ها ثبت شده</li>
          <li><b>اصلاحی</b> — فاکتورهایی که به‌صورت اصلاحی ارسال شده‌اند</li>
        </ul>
        <p><strong>ستون‌ها:</strong> شماره فاکتور (لینک به فاکتور فروش)، عنوان، تاریخ، مبلغ، شناسهٔ رهگیری (referenceNumber) و شناسهٔ یکتای مالیاتی به‌صورت خلاصه‌شده (کلیک برای کپی مقدار کامل — با نگه‌داشتن اشاره‌گر روی آن هم متن کامل دیده می‌شود)، وضعیت (برچسب رنگی)، خطا، دکمهٔ استعلام.</p>
        <p><strong>تعامل‌ها:</strong> جعبهٔ جستجو، ردیف‌ها را آنی فیلتر می‌کند؛ کلیک روی هدر ستون‌ها مرتب‌سازی صعودی/نزولی؛ دکمهٔ «استعلام» در هر ردیف، آخرین وضعیت همان فاکتور را از سامانهٔ مودیان می‌گیرد؛ «خروجی Excel» فقط ردیف‌های فیلترشدهٔ قابل‌مشاهدهٔ تب فعال را CSV می‌کند (با مقدار کامل شناسه‌ها، نه نسخهٔ خلاصه).</p>
        <p><strong>بازه و سازمان:</strong> پیش‌فرض ۳۶۵ روز اخیر و سازمان ۸؛ با پارامترهای <code>from_date</code>/<code>to_date</code> (شمسی) و <code>org_id</code> در آدرس اجرای بات قابل بازنویسی است.</p>
      </div>
    </div>
  </div>

  <h2 class="main-title">فاکتورهای ارسال شده به سامانه مودیان</h2>

  <div class="kpi-row">
    <div class="kpi-card">
      <div class="kpi-label">تعداد ارسالی</div>
      <div class="kpi-value">%s</div>
    </div>
    <div class="kpi-card">
      <div class="kpi-label">تعداد ابطالی</div>
      <div class="kpi-value">%s</div>
    </div>
    <div class="kpi-card">
      <div class="kpi-label">تعداد اصلاحی</div>
      <div class="kpi-value">%s</div>
    </div>
  </div>

  <div class="tabs">
    <div class="tab active" data-type="1" onclick="switchTab(1)">ارسالی</div>
    <div class="tab" data-type="2" onclick="switchTab(2)">ابطالی</div>
    <div class="tab" data-type="3" onclick="switchTab(3)">اصلاحی</div>
  </div>
  <div class="tab-content active" id="tab_1">
  <div id='msg_text_report1' ></div>
  <div class="search-row">
    <input type="text" class="search-box" id="search_1" placeholder="جستجو در همه ستون‌ها...">
    <span class="search-count" id="searchCount_1"></span>
  </div>
   <h3 class="show_total"> تعداد فاکتور های ارسالی : <div style='display:inline-block;'  id='show_total1'  >0</div> </h3>
    <div class="table-wrap">
    <table class="data-table">
      <thead><tr>
      <th class="th-id">شماره فاکتور</th>
      <th class="th-name">عنوان</th>
      <th class="th-date">تاریخ</th>
      <th class="th-amont">مبلغ</th>
      <th class="th-rf">referenceNumber</th>
      <th class="th-uid">شناسه یکتای مالیاتی صورتحساب</th>
      <th class="th-st">وضعیت</th>
      <th class="th-er">خطا</th>
      <th class="th-er no-sort">استعلام</th>
      </tr></thead>
      <tbody id="tbody_1"></tbody>
    </table>
    </div>
  </div>
  <div class="tab-content" id="tab_2">
  <div id='msg_text_report2' ></div>
  <div class="search-row">
    <input type="text" class="search-box" id="search_2" placeholder="جستجو در همه ستون‌ها...">
    <span class="search-count" id="searchCount_2"></span>
  </div>
 <h3 class="show_total">تعداد فاکتور های ابطالی : <div style='display:inline-block;'  id='show_total2' >0</div> </h3>
    <div class="table-wrap">
    <table class="data-table">
      <thead><tr>
        <th class="th-id">شماره فاکتور</th>
        <th class="th-name">عنوان</th>
        <th class="th-date">تاریخ</th>
        <th class="th-amont">مبلغ</th>
        <th class="th-rf">referenceNumber</th>
        <th class="th-uid">شناسه یکتای مالیاتی صورتحساب</th>
        <th class="th-st">وضعیت</th>
        <th class="th-er">خطا</th>
        <th class="th-er no-sort">استعلام</th>
        </tr></thead>
      <tbody id="tbody_2"></tbody>
    </table>
    </div>
  </div>
  <div class="tab-content" id="tab_3">
  <div id='msg_text_report3' ></div>
  <div class="search-row">
    <input type="text" class="search-box" id="search_3" placeholder="جستجو در همه ستون‌ها...">
    <span class="search-count" id="searchCount_3"></span>
  </div>
 <h3 class="show_total">تعداد فاکتور های اصلاحی : <div style='display:inline-block;' id='show_total3' >0</div> </h3>
    <div class="table-wrap">
    <table class="data-table">
      <thead>
        <tr>
        <th class="th-id">شماره فاکتور</th>
        <th class="th-name">عنوان</th>
        <th class="th-date">تاریخ</th>
        <th class="th-amont">مبلغ</th>
        <th class="th-rf">referenceNumber</th>
        <th class="th-uid">شناسه یکتای مالیاتی صورتحساب</th>
        <th class="th-st">وضعیت</th>
        <th class="th-er">خطا</th>
        <th class="th-er no-sort">استعلام</th>
</tr>
</thead>
      <tbody id="tbody_3"></tbody>
    </table>
    </div>
  </div>
</div>
</div>

<style>
/*__PEYDA_FONT_FACES__*/
.mft-container, .mft-container * , .help-modal, .help-modal * { font-family: "PeydaReport", "Peyda", "IRANSans", "Tahoma", "Arial", sans-serif !important; box-sizing: border-box; }

.mft-container { direction: rtl; text-align: right; margin: 0; padding: 20px; box-sizing: border-box; background: #f5f5f5; min-height: 100vh; }
.mft-container .card { background: white; border-radius: 14px; padding: 25px; box-shadow: 0 2px 8px rgba(0,0,0,0.08); margin: 0 auto; border: 1px solid #ccc; }
.mft-container .top-bar { display: flex; justify-content: space-between; align-items: center; gap: 8px; flex-wrap: wrap; margin-bottom: 14px; }
.mft-container .brand-mark { height: 34px; width: auto; }
.mft-container .toolbar { display: flex; justify-content: flex-end; align-items: center; gap: 8px; flex-wrap: wrap; }
.mft-container .btn-action { background: #16509D; color: #fff; border: 2px solid #16509D; border-radius: 8px; padding: 8px 16px; font-size: 14px; font-weight: bold; cursor: pointer; }
.mft-container .btn-action:hover { background: #113e7a; }
.mft-container .help-overlay { display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.5); z-index: 100; align-items: center; justify-content: center; }
.mft-container .help-overlay.open { display: flex; }
.mft-container .help-modal { background: #fff; border-radius: 10px; max-width: 720px; width: 92%%; max-height: 84vh; overflow-y: auto; box-shadow: 0 8px 24px rgba(0,0,0,0.3); }
.mft-container .help-modal-header { display: flex; justify-content: space-between; align-items: center; background: #16509D; color: #fff; padding: 12px 16px; border-radius: 10px 10px 0 0; font-size: 15px; font-weight: bold; position: sticky; top: 0; }
.mft-container .help-close { background: transparent; border: none; color: #fff; font-size: 16px; cursor: pointer; }
.mft-container .help-modal-body { padding: 16px; text-align: right; font-size: 14px; }
.mft-container .help-modal-body p { margin: 10px 0; line-height: 1.8; }
.mft-container .help-modal-body ul { margin: 6px 0 14px; padding-right: 20px; }
.mft-container .help-modal-body li { margin: 6px 0; line-height: 1.7; }
.mft-container .main-title { text-align: center; margin-bottom: 18px; font-size: 21px; font-weight: bold; color: #16509D; }
.mft-container .kpi-row { display: flex; gap: 14px; flex-wrap: wrap; margin-bottom: 20px; }
.mft-container .kpi-card { flex: 1; min-width: 160px; background: #f5f5f5; border: 2px solid #16509D; border-radius: 12px; padding: 16px; text-align: center; }
.mft-container .kpi-label { font-size: 14px; color: #000; margin-bottom: 6px; }
.mft-container .kpi-value { font-size: 26px; font-weight: bold; color: #16509D; }
.mft-container .tabs { display: flex; gap: 6px; border-bottom: 3px solid #16509D; margin-bottom: 0; padding: 0 4px; }
.mft-container .tab { padding: 12px 30px; cursor: pointer; font-size: 14px; font-weight: bold; color: #16509D; border: 1px solid #ccc; border-bottom: none; border-radius: 10px 10px 0 0; background: #f5f5f5; transition: all 0.2s; position: relative; top: 1px; }
.mft-container .tab:hover { background: #e8eef6; }
.mft-container .tab.active { color: white; background: #16509D; border-color: #16509D; }
.mft-container .tab-content { display: none; padding: 0; border: 1px solid #ccc; border-top: none; border-radius: 0 0 10px 10px; background: #fff; overflow: hidden; }
.mft-container .tab-content.active { display: block; }
.mft-container .search-row { display: flex; align-items: center; gap: 10px; padding: 14px 16px 0; }
.mft-container .search-box { flex: 1; max-width: 340px; padding: 9px 14px; font-size: 14px; border: 2px solid #16509D; border-radius: 8px; color: #000; }
.mft-container .search-box:focus { outline: none; border-color: #113e7a; }
.mft-container .search-count { font-size: 14px; color: #666; white-space: nowrap; }
.mft-container .show_total { color: #000; padding: 12px 25px; margin: 5px; font-size: 14px; font-weight: bold; }

.mft-container .table-wrap { margin: 6px 16px 16px; overflow-x: auto; border: 2px solid #16509D; border-radius: 10px; }
.mft-container .data-table { width: auto; border-collapse: collapse; }
.mft-container .data-table thead th { background: #16509D; color: #fff; padding: 13px 18px; text-align: center; font-size: 15px; font-weight: bold; white-space: nowrap; width: 1%%; position: sticky; top: 0; cursor: pointer; user-select: none; border-left: 1px solid rgba(255,255,255,0.18); }
.mft-container .data-table thead th:last-child { border-left: none; }
.mft-container .data-table thead th.no-sort { cursor: default; }
.mft-container .data-table thead th.sort-asc::after { content: ' ▲'; }
.mft-container .data-table thead th.sort-desc::after { content: ' ▼'; }
.mft-container .data-table .th-id { width: 1%%; }
.mft-container .data-table tbody td { padding: 12px 18px; font-size: 14px; color: #000; white-space: nowrap; width: 1%%; border-bottom: 1px solid #e6e6e6; text-align: center; }
.mft-container .data-table .name-cell { text-align: right; }
.mft-container .data-table tbody tr:nth-child(even) td { background: #f7f9fc; }
.mft-container .data-table tbody tr:nth-child(odd) td { background: #fff; }
.mft-container .data-table tbody tr:hover td { background: #eaf1fb; }
.mft-container .data-table tbody tr:last-child td { border-bottom: none; }

.mft-container .status-chip { display: inline-block; padding: 4px 12px; border-radius: 12px; font-size: 14px; font-weight: bold; white-space: nowrap; background: #f5f5f5; color: #000; border: 1px solid #ccc; }
.mft-container .status-chip.ok { background: #16509D; color: #fff; border-color: #16509D; }
.mft-container .status-chip.flag { background: #f5f5f5; color: #000; border: 1px solid #666; }
.mft-container .id-chip { display: inline-block; font-size: 14px; color: #666; background: #f5f5f5; border: 1px dashed #666; border-radius: 6px; padding: 4px 10px; cursor: pointer; }
.mft-container .id-chip:hover { background: #eaf1fb; color: #16509D; border-color: #16509D; }
.mft-container .id-chip.copied { background: #16509D; color: #fff; border-color: #16509D; }
.mft-container .loading-msg, .mft-container .empty-msg, .mft-container .error-msg { text-align: center; padding: 30px; font-size: 14px; }
.mft-container .loading-msg { color: #16509D; }
.mft-container .loading-msg::before { content: '⏳ '; }
.mft-container .empty-msg { color: #666; }
.mft-container .empty-msg::before { content: '📋 '; }
.mft-container .error-msg { color: #000; }
.mft-container .error-msg::before { content: '⚠ '; }
</style>

<script>

var loadedTabs = {};
var RUN_URL = (location.pathname.indexOf('/bot/run/') === 0) ? location.pathname : '/bot/run/2/moadian_index_m_1';
function escapeHtmlClient(s) {
  var d = document.createElement('div');
  d.textContent = String(s == null ? '' : s);
  return d.innerHTML;
}

function switchTab(type) {
  document.querySelectorAll('.mft-container .tab').forEach(function(t) { t.classList.remove('active'); });
  document.querySelectorAll('.mft-container .tab-content').forEach(function(c) { c.classList.remove('active'); });
  document.querySelector('.mft-container .tab[data-type="' + type + '"]').classList.add('active');
  document.getElementById('tab_' + type).classList.add('active');
  if (!loadedTabs[type]) {
    loadTabData(type);
  }
}

// AJAX: فقط fetch خالص — نسخهٔ قبلی $.Teamyar.ajax را هم امتحان می‌کرد اما بارها در محیط استقرار
// واقعی (نه در تست دستی از کنسول صفحهٔ پنل ادمین) با خطا/سکوت مواجه شد. اینجا onError جزئیات واقعی
// (کد HTTP یا پیام خطای شبکه) را پاس می‌دهد تا در رابط کاربری نمایش داده شود — برای تشخیص دقیق‌تر اگر
// باز هم خطا داد.
function ajaxPost(data, onSuccess, onError) {
  var settled = false;
  var timeoutId = setTimeout(function () { finish(onError, 'پاسخ سرور بیش از ۲۰ ثانیه طول کشید'); }, 20000);
  function finish(fn, arg) { if (settled) return; settled = true; clearTimeout(timeoutId); fn(arg); }

  var body = 'customform=' + encodeURIComponent(JSON.stringify(data));
  fetch(RUN_URL, {
    method: 'POST',
    headers: { 'X-Requested-With': 'XMLHttpRequest', 'Content-Type': 'application/x-www-form-urlencoded' },
    body: body,
    credentials: 'include'
  }).then(function (resp) {
    return resp.text().then(function (text) { return { status: resp.status, ok: resp.ok, text: text }; });
  }).then(function (result) {
    if (!result.ok) {
      finish(onError, 'HTTP ' + result.status + ' — ' + result.text.substring(0, 150));
      return;
    }
    var parsed;
    try { parsed = JSON.parse(result.text); } catch (e) {
      finish(onError, 'پاسخ سرور JSON معتبر نبود (HTTP ' + result.status + '): ' + result.text.substring(0, 150));
      return;
    }
    finish(onSuccess, parsed);
  }).catch(function (err) {
    finish(onError, 'خطای شبکه: ' + (err && err.message ? err.message : String(err)));
  });
}
// جایگزین $.Teamyar.convertNormalDate — تبدیل تیک FILETIME (مبنای ۱۶۰۱) به تاریخ شمسی، بدون وابستگی خارجی
function gregorianToJalali(gy, gm, gd) {
  var g_d_m = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
  var jy = (gy <= 1600) ? 0 : 979;
  gy -= (gy <= 1600) ? 621 : 1600;
  var gy2 = (gm > 2) ? (gy + 1) : gy;
  var days = (365 * gy) + (Math.floor((gy2 + 3) / 4)) - (Math.floor((gy2 + 99) / 100)) + (Math.floor((gy2 + 399) / 400)) - 80 + gd + g_d_m[gm - 1];
  jy += 33 * Math.floor(days / 12053);
  days %%= 12053;
  jy += 4 * Math.floor(days / 1461);
  days %%= 1461;
  if (days > 365) { jy += Math.floor((days - 1) / 365); days = (days - 1) %% 365; }
  var jm = (days < 186) ? 1 + Math.floor(days / 31) : 7 + Math.floor((days - 186) / 30);
  var jd = 1 + ((days < 186) ? (days %% 31) : ((days - 186) %% 30));
  return [jy, jm, jd];
}
function p2(n) { n = Math.floor(n); return (n < 10 ? '0' : '') + n; }
function fmtFiletimeJalali(ticksVal) {
  var ticks = Number(ticksVal);
  if (!ticks) return '—';
  var unixMs = (ticks - 116444736000000000) / 10000;
  var d = new Date(unixMs);
  var j = gregorianToJalali(d.getFullYear(), d.getMonth() + 1, d.getDate());
  return j[0] + '/' + p2(j[1]) + '/' + p2(j[2]) + ' ' + p2(d.getHours()) + ':' + p2(d.getMinutes()) + ':' + p2(d.getSeconds());
}

function statusVariant(label) {
  if (!label) return '';
  if (label.indexOf('خطا') !== -1 || label.indexOf('رد شده') !== -1 || label.indexOf('ناموفق') !== -1 || label.indexOf('لغو شده') !== -1) return 'flag';
  if (label.indexOf('پذیرفته') !== -1 || label.indexOf('تایید') !== -1 || label === 'ارسال شده' || label === 'ابطال') return 'ok';
  return '';
}
function shortId(v) {
  if (!v) return '—';
  if (v.length <= 16) return v;
  return v.substring(0, 8) + '…' + v.substring(v.length - 6);
}
function copyToClipboard(text, el) {
  function feedback() {
    var original = el.textContent;
    el.classList.add('copied');
    el.textContent = 'کپی شد!';
    setTimeout(function () { el.classList.remove('copied'); el.textContent = original; }, 1200);
  }
  if (navigator.clipboard && navigator.clipboard.writeText) {
    navigator.clipboard.writeText(text).then(feedback).catch(feedback);
  } else {
    feedback();
  }
}

function buildInvoiceRow(row) {
  var tr = document.createElement('tr');
  tr.setAttribute('data-status', row.st || '');
  tr.setAttribute('data-rf', row.rf || '');
  tr.setAttribute('data-uid', row.uid || '');
  tr.setAttribute('data-err', row.err || '');

  var tdId = document.createElement('td'); tdId.innerHTML = row.id;
  var tdName = document.createElement('td'); tdName.className = 'name-cell'; tdName.innerHTML = row.name;
  var tdDate = document.createElement('td'); tdDate.textContent = fmtFiletimeJalali(row.date);
  var tdAmount = document.createElement('td'); tdAmount.textContent = (Math.round(row.amont)).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");

  var tdRf = document.createElement('td');
  if (row.rf) {
    var rfChip = document.createElement('span'); rfChip.className = 'id-chip';
    rfChip.title = 'referenceNumber: ' + row.rf + ' (کلیک برای کپی)';
    rfChip.textContent = shortId(row.rf);
    rfChip.addEventListener('click', function () { copyToClipboard(row.rf, rfChip); });
    tdRf.appendChild(rfChip);
  } else { tdRf.textContent = '—'; }

  var tdUid = document.createElement('td');
  if (row.uid) {
    var uidChip = document.createElement('span'); uidChip.className = 'id-chip';
    uidChip.title = 'شناسه یکتای مالیاتی: ' + row.uid + ' (کلیک برای کپی)';
    uidChip.textContent = shortId(row.uid);
    uidChip.addEventListener('click', function () { copyToClipboard(row.uid, uidChip); });
    tdUid.appendChild(uidChip);
  } else { tdUid.textContent = '—'; }

  var tdSt = document.createElement('td');
  var variant = statusVariant(row.st);
  var statusEl = document.createElement('span');
  statusEl.className = 'status-chip' + (variant ? ' ' + variant : '');
  statusEl.textContent = row.st || '—';
  tdSt.appendChild(statusEl);

  var tdErr = document.createElement('td'); tdErr.innerHTML = row.err || '—';
  var tdBtn = document.createElement('td'); tdBtn.innerHTML = row.btn || '';

  tr.appendChild(tdId); tr.appendChild(tdName); tr.appendChild(tdDate); tr.appendChild(tdAmount);
  tr.appendChild(tdRf); tr.appendChild(tdUid); tr.appendChild(tdSt); tr.appendChild(tdErr); tr.appendChild(tdBtn);
  return tr;
}

function loadTabData(type) {

  var tbody = document.getElementById('tbody_' + type);
  tbody.innerHTML = '<tr><td colspan="9" class="loading-msg">در حال بارگذاری...</td></tr>';

  ajaxPost({ type: type }, function (res) {
    loadedTabs[type] = true;
    tbody.innerHTML = '';
    if (!res || res.ok === false) {
      tbody.innerHTML = '<tr><td colspan="9" class="error-msg">' + ((res && res.error) || 'خطا در دریافت اطلاعات') + ' — <a href="javascript:void(0)" onclick="loadTabData(' + type + ')">تلاش مجدد</a></td></tr>';
      return;
    }
    if (res.data && res.data.length > 0) {
      res.data.forEach(function(row) {
        tbody.appendChild(buildInvoiceRow(row));
      });
      document.getElementById("show_total"+type).innerHTML = res.total;
      applySearchFilter(type);
    } else {
      tbody.innerHTML = '<tr><td colspan="9" class="empty-msg">موردی یافت نشد</td></tr>';
    }
  }, function (detail) {
    tbody.innerHTML = '<tr><td colspan="9" class="error-msg">خطا در دریافت اطلاعات' + (detail ? ' (' + escapeHtmlClient(detail) + ')' : '') + ' — <a href="javascript:void(0)" onclick="loadTabData(' + type + ')">تلاش مجدد</a></td></tr>';
  });
}
//-----------------------------------------------
window.ty__main = window.ty__main || {};
ty__main.inquery_factor= function(fid,referenceNumber,tabtype)
{
  var box;
  if( tabtype == 1 ) box = document.getElementById("msg_text_report1");
  if( tabtype == 2 ) box = document.getElementById("msg_text_report2");
  if( tabtype == 3 ) box = document.getElementById("msg_text_report3");
  if (!box) return;
  box.innerHTML = "<div style='height: 61px;  overflow-y: auto;border: 1px solid #666;   padding: 10px;background-color: #f5f5f5;color: #000; '>در حال استعلام...</div>";

  ajaxPost({ type:4, fid:fid, referenceNumber:referenceNumber }, function (res) {
    var content = (res && res.ok !== false) ? res.msg : ((res && res.error) || 'خطا در استعلام');
    box.innerHTML = "<div style='height: 61px;  overflow-y: auto;border: 1px solid #666;   padding: 10px;background-color: #f5f5f5;color: #000; '>"+content+"</div>";
  }, function (detail) {
    box.innerHTML = "<div style='height: 61px;  overflow-y: auto;border: 1px solid #666;   padding: 10px;background-color: #f5f5f5;color: #000; '>خطا در استعلام" + (detail ? " (" + escapeHtmlClient(detail) + ")" : "") + "</div>";
  });
}

//------------------ جستجوی آنی هر تب ------------------
function applySearchFilter(type) {
  var input = document.getElementById('search_' + type);
  var countLabel = document.getElementById('searchCount_' + type);
  var term = input.value.trim().toLowerCase();
  var tbody = document.getElementById('tbody_' + type);
  var rows = tbody.querySelectorAll('tr');
  var visible = 0, total = 0;
  rows.forEach(function (row) {
    if (row.querySelector('td.loading-msg, td.empty-msg, td.error-msg')) { row.style.display = ''; return; }
    total++;
    var text = row.innerText.toLowerCase();
    var match = term === '' || text.indexOf(term) !== -1;
    row.style.display = match ? '' : 'none';
    if (match) visible++;
  });
  countLabel.textContent = (term === '' || total === 0) ? '' : ('نمایش ' + visible + ' از ' + total + ' نتیجه');
}
function setupSearch(type) {
  var input = document.getElementById('search_' + type);
  input.addEventListener('input', function () { applySearchFilter(type); });
}
setupSearch(1); setupSearch(2); setupSearch(3);

function csvEscapeCell(text) {
  var t = (text == null ? '' : String(text)).replace(/\s+/g, ' ').trim();
  if (t.indexOf(',') !== -1 || t.indexOf('"') !== -1 || t.indexOf('\n') !== -1) t = '"' + t.replace(/"/g, '""') + '"';
  return t;
}
function downloadCsv(lines, fileName) {
  var blob = new Blob(['﻿' + lines.join('\r\n')], { type: 'text/csv;charset=utf-8;' });
  var url = URL.createObjectURL(blob);
  var link = document.createElement('a');
  link.href = url; link.download = fileName;
  document.body.appendChild(link); link.click(); document.body.removeChild(link);
  URL.revokeObjectURL(url);
}
function exportTableToExcel() {
  var activeContent = document.querySelector('.mft-container .tab-content.active');
  var table = activeContent ? activeContent.querySelector('table.data-table') : null;
  if (!table) return;
  var tabTitle = document.querySelector('.mft-container .tab.active').textContent.trim();
  var lines = [];
  lines.push(['شماره فاکتور', 'عنوان', 'تاریخ', 'مبلغ', 'referenceNumber', 'شناسه یکتای مالیاتی', 'وضعیت', 'خطا'].map(csvEscapeCell).join(','));
  var rows = table.querySelectorAll('tbody tr');
  rows.forEach(function (row) {
    if (row.style.display === 'none') return;
    if (row.querySelector('td.empty-msg, td.loading-msg, td.error-msg')) return;
    var cells = row.querySelectorAll('td');
    var code = cells[0] ? cells[0].innerText.trim() : '';
    var title = cells[1] ? cells[1].innerText.trim() : '';
    var date = cells[2] ? cells[2].innerText.trim() : '';
    var amount = cells[3] ? cells[3].innerText.trim() : '';
    var rf = row.getAttribute('data-rf') || '';
    var uid = row.getAttribute('data-uid') || '';
    var status = row.getAttribute('data-status') || '';
    var err = row.getAttribute('data-err') || '';
    var line = [code, title, date, amount, rf, uid, status, err];
    lines.push(line.map(csvEscapeCell).join(','));
  });
  downloadCsv(lines, 'فاکتورهای-مودیان-' + tabTitle + '.csv');
}
function toggleFullScreen() {
  var root = document.querySelector('.mft-container');
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
document.addEventListener('fullscreenchange', syncFullscreenButton);
document.addEventListener('webkitfullscreenchange', syncFullscreenButton);
function syncFullscreenButton() {
  var btn = document.getElementById('btnFullscreen');
  if (!btn) return;
  var isFull = document.fullscreenElement || document.webkitFullscreenElement || document.msFullscreenElement;
  btn.innerText = isFull ? 'خروج از تمام صفحه' : 'تمام صفحه';
}
function openHelpModal() { document.getElementById('helpModalOverlay').classList.add('open'); }
function closeHelpModal() { document.getElementById('helpModalOverlay').classList.remove('open'); }
document.addEventListener('keydown', function (e) { if (e.key === 'Escape') closeHelpModal(); });

function getCellSortValue(cell) {
  var text = cell ? cell.innerText.trim() : '';
  var n = text.replace(/[,٪%%]/g, '').trim();
  if (n !== '' && /^-?\d+(\.\d+)?$/.test(n)) return parseFloat(n);
  return text;
}
function sortTableByColumn(table, colIndex, dir) {
  var tbody = table.querySelector('tbody');
  var rows = Array.prototype.slice.call(tbody.querySelectorAll('tr'));
  if (rows.length === 0 || rows[0].querySelectorAll('td').length < colIndex + 1) return;
  rows.sort(function (ra, rb) {
    var a = getCellSortValue(ra.children[colIndex]), b = getCellSortValue(rb.children[colIndex]), cmp;
    if (typeof a === 'number' && typeof b === 'number') cmp = a - b;
    else cmp = String(a).localeCompare(String(b), 'fa');
    return dir === 'asc' ? cmp : -cmp;
  });
  rows.forEach(function (row) { tbody.appendChild(row); });
}
function initSortableTables() {
  document.querySelectorAll('.mft-container table.data-table').forEach(function (table) {
    var headers = table.querySelectorAll('thead th');
    headers.forEach(function (th, colIndex) {
      if (th.classList.contains('no-sort')) return;
      th.addEventListener('click', function () {
        var dir = th.classList.contains('sort-asc') ? 'desc' : 'asc';
        headers.forEach(function (h) { h.classList.remove('sort-asc', 'sort-desc'); });
        th.classList.add(dir === 'asc' ? 'sort-asc' : 'sort-desc');
        sortTableByColumn(table, colIndex, dir);
      });
    });
  });
}

initSortableTables();
loadTabData(1);

</script>

		]], total_sent, total_canceled, total_corrected);

local ok_html, html_or_err = pcall(function() return res_data end)
if not ok_html then
    teamyar.write_result(json.encode({ ok = false, error = "خطا در ساخت گزارش", detail = tostring(html_or_err) }))
    return
end
teamyar.write_result(res_data)
