-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/05/23 21:00

-- botName = hr_dashboard
-- description = داشبورد حاکمیت سرمایه انسانی هلدینگ ۱۴۰ (سایدبار ۴ تب — فقط حوزه‌های دارای دادهٔ واقعی)
-- version = 7
--
-- v7 (رفع باگ escape_html): سرور Teamyar هنگام ذخیره‌سازی، رشته‌های پیوستهٔ literal مثل "&"/"'"
-- را decode می‌کند (باگ واقعی مشاهده‌شده روی همین بات — کاربر گزارش کرد). escape_html و مشتقش در bar_row
-- (خط onclick_js:gsub) با الگوی امنِ رایج این ریپو (string.char(38) .. "amp;" و مشابه، دقیقاً همان چیزی
-- که EghdamPerId_bot.lua/user_activity_stats_report_bot.lua استفاده می‌کنند) بازنویسی شدند.
--
-- v6 (فیدبک سوم کاربر):
--   1) تاهل اضافه شد: hr_personnels.MARITAL_STATUS (تایید‌شده در کوئری بات ۳۸۲) — donut جدید در تب
--      «ترکیب نیروی انسانی» کنار جنسیت.
--   2) هر بخشی که ۱۰۰٪ محتوایش «—» بدون منبع دادهٔ واقعی بود حذف شد: تب «جذب و استخدام»، تب «عملکرد و
--      استعداد» (هر دو کامل، سایدبار هم به‌روز شد)، کارت «دلایل خروج/ریسک خروج» در تب ماندگاری، کارت
--      «تحلیل مدیریتی» و ۳ KPI مالی بدون منبع (هزینه/فروش، درآمد/نفر، Cost per Hire) در تب هزینه.
--   3) «اضافه‌کاری به تفکیک واحد» از ساعت درخواستی بات ۳۷۹ (hr_overtime_request) به «میزان پرداخت
--      اضافه‌کاری در حکم» تغییر کرد — عدد واقعی پرداخت‌شده از ردیف‌های hr_payslip_payment_detail که
--      NAME آن‌ها شامل «اضافه کار» است (همان منبع تاییدشدهٔ حقوق و دستمزد، نه یک جدول جدا).
--
-- v5 (فیدبک دوم کاربر):
--   1) حقوق و دستمزد: فیلتر PAYSLIP_VIEW از MAX() روی کل فیش به سطح ردیف hr_payslip_payment_detail
--      اصلاح شد — کوئری واقعی بات ۵۵۷ (query_get_salary_wages.txt، کامل دیکد و خوانده شد، نه truncated)
--      دقیقاً همین را نشان داد؛ نسخهٔ قبلی به‌اشتباه فقط زیرمجموعه‌ای از فیش‌ها را می‌شمرد.
--   2) ترکیب جنسیتی/تحصیلات: کوئری واقعی بات ۳۸۲ (query_get_summary_personnel.txt) این‌بار کامل خوانده
--      شد — ستون‌های منبع تایید شد: profile_user_info.SEX (جنسیت) و hr_education.education/DEGREE
--      (تحصیلات). هر دو حالا با دادهٔ واقعی در تب «ترکیب نیروی انسانی» نمایش داده می‌شوند.
--
-- منبع دادهٔ این بات مستقیماً جداول HR است (hr_personnels / hr_personnel_order / hr_work_time /
-- hr_overtime_request / hr_payslip / hr_payslip_payment_detail / report_dimdate / org_organization_unit /
-- org_units / CRM_PERSON_FAMILY / profile_user_info.BIRTHDAY) — نه فراخوانی بات‌های دیگر (cat_id=57:
-- 379/380/382/384/385/444/474/476/504/505/557) از طریق teamyar.run_command، چون هر فراخوانی بات یک
-- رفت‌وبرگشت HTTP/DB جدا دارد و برای یک داشبورد تجمیعی کند و شکننده می‌شود. الگوی JOIN/ستون هر بخش
-- مستقیماً از کوئری‌های واقعی همان ۱۱ بات (که در Production کار می‌کنند) کپی/تایید شده تا نام ستون/جدول
-- حدسی نباشد. هر بخش (headcount/attendance/overtime/payroll/alerts) در pcall جدا اجرا می‌شود تا خطای
-- یک بخش بقیهٔ داشبورد را از کار نیندازد.
--
-- v3 (کاربر HTML نمونهٔ خودش را داد و خواست همان قالب/تب‌ها با دادهٔ واقعی پر شود، نه طراحی جدید):
--   ساختار سایدبار + ۶ تب (نمای مدیریتی/ترکیب نیروی انسانی/ماندگاری و خروج/جذب و استخدام/عملکرد و
--   استعداد/هزینه و بهره‌وری) و اجزای بصری (donut، chart میله‌ای، progress list، riskitem) از HTML
--   نمونهٔ کاربر عیناً بازسازی شد. طبق قانون اجباری این ریپو، پالت رنگ فقط سایه‌های #16509D است (نه
--   آبی/سبز/زرد/قرمز نمونه) و فونت Peyda (نه Tahoma نمونه) — تایید شد که این با گایدلاین بصری برند ۱۴۰
--   تناقض ندارد (پالت brand-140 طبق CLAUDE.md فقط برای خود لوگو است، نه رنگ گزارش). دو تب «جذب و
--   استخدام» و «عملکرد و استعداد» چون هیچ منبع دادهٔ تاییدشده‌ای در ۱۱ بات HR ندارند، با «—» + توضیح
--   نمایش داده می‌شوند (نه عدد حدسی) — دقیقاً همان الگوی خود HTML نمونه برای تب «هزینه» که مقادیر مالی
--   نداشت. سه معیار جدید (گروه سنی، سابقهٔ همکاری، Retention ۳/۶/۱۲ماهه) به‌صورت کوئری واقعی اضافه شد.
--
-- محدودیت‌های شناخته‌شده — این حوزه‌ها عمداً هیچ‌جای این بات نیستند، نه تب/کارت خالی و نه KPI «—»
-- (داده منبع تاییدشده در ۱۱ بات cat_id=57 برایشان پیدا نشد؛ حذف کامل، نه کم‌کاری):
--   - قیف جذب و استخدام (رزومه/مصاحبه/Offer) — هیچ جدول ATS/مصاحبه‌ای در ۱۱ بات HR دیده نشد
--   - توزیع عملکرد و جانشین‌پروری — هیچ جدول ارزیابی عملکرد/جانشین‌پروری در ۱۱ بات HR دیده نشد
--   - هزینهٔ نیروی انسانی/فروش، درآمد/نفر، Cost per Hire — نیازمند اتصال به سیستم مالی/فروش که در
--     جداول HR این ریپو موجود نیست؛ دلایل خروج و ریسک خروج نیروهای کلیدی — هیچ ستون مرتبط دیده نشد
-- برای هرکدام، قبل از افزودن باید منبع داده واقعی با db_schema_json_bot تایید شود.

local input = teamyar.get_input() or {}

-- ── helpers ──────────────────────────────────────────────────────────

-- طبق قانون تازهٔ CLAUDE.md (تایید‌شده زنده ۱۴۰۵/۰۵/۲۳): رشتهٔ پیوستهٔ entity به‌صورت literal داخل
-- gsub باعث خطا در ذخیره‌سازی command توسط سرور Teamyar می‌شود. با پیوند رشته (نه string.char) بساز —
-- دقیقاً همان الگوی canonical مستندشده در CLAUDE.md.
local HTML_AMP = "&" .. "amp;"
local HTML_LT = "&" .. "lt;"
local HTML_GT = "&" .. "gt;"
local HTML_QUOT = "&" .. "quot;"
local HTML_APOS = "&" .. "#39;"

local function escape_html(value)
    if value == nil then return "" end
    return tostring(value)
        :gsub("&", HTML_AMP)
        :gsub("<", HTML_LT)
        :gsub(">", HTML_GT)
        :gsub('"', HTML_QUOT)
        :gsub("'", HTML_APOS)
end

local function fmt_num(value)
    local n = tonumber(value)
    if n == nil then return "0" end
    local neg = n < 0
    n = math.abs(n)
    local s = tostring(math.floor(n + 0.5))
    local grouped = s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    return (neg and "-" or "") .. grouped
end

local function fmt_decimal(value, decimals)
    local n = tonumber(value)
    if n == nil then return "0" end
    decimals = decimals or 1
    return string.format("%." .. decimals .. "f", n)
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
        for i = 1, #record do row[i] = record[i] end
        table.insert(rows, row)
    end
    db.query_free()
    return rows
end

-- filetime helpers (همان الگوی time.get_filetime استفاده‌شده در بات‌های HR این ریپو)
local FT_DAY = 864000000000 -- 86400 * 10000000

local function today_filetime()
    local y = time.get_year(time.current())
    local m = time.get_month(time.current())
    local d = time.get_day(time.current())
    local ft = time.get_filetime(string.format(
        '{"year":%d,"month":%d,"day":%d,"hour":0,"minute":0,"second":0}', y, m, d))
    return tonumber(string.format("%18.0f", ft))
end

-- ── inputs ───────────────────────────────────────────────────────────

local org_input = input.org_id
local org_id = nil
if type(org_input) == "table" and org_input[1] ~= nil then
    org_id = tonumber(org_input[1].id)
elseif type(org_input) == "number" then
    org_id = org_input
elseif type(org_input) == "string" and tonumber(org_input) ~= nil then
    org_id = tonumber(org_input)
end

local to_date = tonumber(input.to_date) or today_filetime()
local from_date = tonumber(input.from_date) or (to_date - (182 * FT_DAY)) -- ~۶ ماه اخیر پیش‌فرض

local months_back = tonumber(input.months) or 6
local trend_from = to_date - (months_back * 31 * FT_DAY)

local format_out = input.format

-- ── drill-down: personnel list for one org unit (type=drill_unit) ──────
-- سبک و مجزا از بار اصلی داشبورد؛ قبل از اجرای ۵ بخش سنگین برمی‌گردد تا کلیک روی نمودار سریع باشد

if input.type == "drill_unit" then
    local unit_id = tonumber(input.unit_id)
    if unit_id == nil then
        teamyar.write_result(json.encode({ ok = false, error = "unit_id نامعتبر است" }))
        return
    end
    local rows, err = fetch_rows([[
WITH current_order AS (
  SELECT PERSONNEL_ID, MAX(ID) AS max_id
  FROM hr_personnel_order
  WHERE DATE_FROM <= ? AND DATE_TO >= ?
  GROUP BY PERSONNEL_ID
)
SELECT p.FULLNAME, h.PERSONNEL_CODE
FROM current_order co
JOIN hr_personnel_order o ON o.ID = co.max_id
JOIN hr_personnels h ON h.PERSONNEL_ID = co.PERSONNEL_ID
JOIN profile_main p ON p.id = h.PROFILE_ID
WHERE o.UNIT_ID = ?
ORDER BY p.FULLNAME
LIMIT 300
]], { to_date, to_date, unit_id })
    if rows == nil then
        teamyar.write_result(json.encode({ ok = false, error = tostring(err) }))
        return
    end
    local list = {}
    for _, r in ipairs(rows) do
        table.insert(list, { name = r[1] or "-", code = r[2] or "-" })
    end
    teamyar.write_result(json.encode({ ok = true, personnel = list }))
    return
end

-- ── section 1: headcount KPIs + trend + by-unit ─────────────────────

local headcount = {
    active = 0, new_hires = 0, avg_tenure = 0, terminations = 0
}
local headcount_by_unit = {}
local hire_trend = {}
local exit_trend = {}
local age_buckets = { u25 = 0, a25_34 = 0, a35_44 = 0, a45p = 0, unknown = 0 }
local tenure_buckets = { lt3m = 0, m3_6 = 0, m6_12 = 0, y1_2 = 0, y2_3 = 0, y3_5 = 0, y5p = 0 }
local retention = { m3 = 0, m6 = 0, m12 = 0 }
local gender_buckets = { male = 0, female = 0, unknown = 0 }
local education_buckets = { below_diploma = 0, diploma = 0, associate = 0, bachelor = 0, master = 0, phd = 0, unknown = 0 }
local marital_buckets = { single = 0, married = 0, unknown = 0 }
local headcount_err = nil

do
    local ok, err = pcall(function()
        local org_filter_fo = org_id and " AND ORG_ID = ? " or ""
        local org_filter_co = org_id and " AND ORG_ID = ? " or ""
        local params = {}

        local kpi_query = [[
WITH first_order AS (
  SELECT PERSONNEL_ID, MIN(DATE_FROM) AS hire_date
  FROM hr_personnel_order
  WHERE 1=1 ]] .. org_filter_fo .. [[
  GROUP BY PERSONNEL_ID
),
current_order AS (
  SELECT PERSONNEL_ID, MAX(ID) AS max_id
  FROM hr_personnel_order
  WHERE DATE_FROM <= ? AND DATE_TO >= ? ]] .. org_filter_co .. [[
  GROUP BY PERSONNEL_ID
),
last_order AS (
  SELECT PERSONNEL_ID, MAX(ID) AS max_id FROM hr_personnel_order GROUP BY PERSONNEL_ID
)
SELECT
  (SELECT COUNT(*) FROM current_order) AS active_headcount,
  (SELECT COUNT(DISTINCT fo.PERSONNEL_ID) FROM first_order fo
    WHERE fo.hire_date BETWEEN ? AND ?) AS new_hires,
  (SELECT ROUND(AVG(DATEDIFF(
        FROM_UNIXTIME(? / 10000000 - 11644473600),
        FROM_UNIXTIME(fo.hire_date / 10000000 - 11644473600)
      ) / 365.25), 1)
   FROM first_order fo JOIN current_order co ON co.PERSONNEL_ID = fo.PERSONNEL_ID) AS avg_tenure,
  (SELECT COUNT(DISTINCT lo.PERSONNEL_ID)
     FROM last_order lo JOIN hr_personnel_order o ON o.ID = lo.max_id
     WHERE o.DATE_TO BETWEEN ? AND ? AND o.DATE_TO < ?
       AND lo.PERSONNEL_ID NOT IN (SELECT PERSONNEL_ID FROM current_order)
   ]] .. (org_id and " AND o.ORG_ID = ? " or "") .. [[
  ) AS terminations
]]

        if org_id then table.insert(params, org_id) end -- first_order org filter
        table.insert(params, to_date)                    -- current_order DATE_FROM<=
        table.insert(params, to_date)                    -- current_order DATE_TO>=
        if org_id then table.insert(params, org_id) end  -- current_order org filter
        table.insert(params, from_date)                  -- new_hires between
        table.insert(params, to_date)
        table.insert(params, to_date)                    -- avg_tenure "now" cutoff
        table.insert(params, from_date)                  -- terminations DATE_TO between
        table.insert(params, to_date)
        table.insert(params, to_date)                    -- terminations DATE_TO <
        if org_id then table.insert(params, org_id) end  -- terminations org filter

        local rows = fetch_rows(kpi_query, params)
        if rows ~= nil and #rows > 0 then
            local r = rows[1]
            headcount.active = tonumber(r[1]) or 0
            headcount.new_hires = tonumber(r[2]) or 0
            headcount.avg_tenure = tonumber(r[3]) or 0
            headcount.terminations = tonumber(r[4]) or 0
        end

        -- by unit
        local unit_params = { to_date, to_date }
        local unit_org = ""
        if org_id then unit_org = " AND o.ORG_ID = ? "; table.insert(unit_params, org_id) end
        local unit_rows = fetch_rows([[
WITH current_order AS (
  SELECT PERSONNEL_ID, MAX(ID) AS max_id
  FROM hr_personnel_order
  WHERE DATE_FROM <= ? AND DATE_TO >= ?
  GROUP BY PERSONNEL_ID
)
SELECT oou.ID unit_key, COALESCE(ou.NAME, N'نامشخص') unit_name, COUNT(DISTINCT co.PERSONNEL_ID) cnt
FROM current_order co
JOIN hr_personnel_order o ON o.ID = co.max_id
LEFT JOIN org_organization_unit oou ON oou.ID = o.UNIT_ID
LEFT JOIN org_units ou ON ou.ID = oou.UNIT_ID
WHERE 1=1 ]] .. unit_org .. [[
GROUP BY oou.ID, COALESCE(ou.NAME, N'نامشخص')
ORDER BY cnt DESC
LIMIT 20
]], unit_params)
        if unit_rows ~= nil then
            for _, r in ipairs(unit_rows) do
                table.insert(headcount_by_unit, {
                    name = r[2] or "نامشخص",
                    count = tonumber(r[3]) or 0,
                    unit_id = tonumber(r[1]) -- nil برای «نامشخص» → دکمهٔ drill-down غیرفعال می‌ماند
                })
            end
        end

        -- hire trend (monthly, last N months)
        local trend_org = ""
        local trend_params = { trend_from, to_date }
        if org_id then trend_org = " AND fo.ORG_ID = ? "; table.insert(trend_params, org_id) end
        local trend_rows = fetch_rows([[
WITH first_order AS (
  SELECT PERSONNEL_ID, MIN(DATE_FROM) AS hire_date, MIN(ORG_ID) AS ORG_ID
  FROM hr_personnel_order o
  GROUP BY PERSONNEL_ID
)
SELECT rd.JYEARKEY, rd.JMONTHKEY, rd.JYEAR, rd.JTMONTH, COUNT(*) cnt
FROM first_order fo
JOIN report_dimdate rd ON rd.DATEKEY = (fo.hire_date - MOD(fo.hire_date, 864000000000))
WHERE fo.hire_date BETWEEN ? AND ? ]] .. trend_org .. [[
GROUP BY rd.JYEARKEY, rd.JMONTHKEY, rd.JYEAR, rd.JTMONTH
ORDER BY rd.JYEARKEY, rd.JMONTHKEY
]], trend_params) -- trend_org filters fo.ORG_ID (first_order CTE exposes ORG_ID via MIN(ORG_ID))
        if trend_rows ~= nil then
            for _, r in ipairs(trend_rows) do
                table.insert(hire_trend, {
                    label = (r[4] or "-") .. " " .. (r[3] or ""),
                    count = tonumber(r[5]) or 0
                })
            end
        end

        -- exit trend (monthly, last N months) — بر پایهٔ پایان آخرین حکم کاری هر پرسنل که دیگر
        -- در current_order نیست (همان تعریف «خروج» KPI بالا، فقط تفکیک‌شده به ماه)
        local exit_org = ""
        local exit_params = { to_date, to_date }
        if org_id then exit_org = " AND ORG_ID = ? "; table.insert(exit_params, org_id) end
        table.insert(exit_params, trend_from)
        table.insert(exit_params, to_date)
        local exit_rows = fetch_rows([[
WITH current_order AS (
  SELECT PERSONNEL_ID, MAX(ID) AS max_id
  FROM hr_personnel_order
  WHERE DATE_FROM <= ? AND DATE_TO >= ? ]] .. exit_org .. [[
  GROUP BY PERSONNEL_ID
),
last_order AS (
  SELECT PERSONNEL_ID, MAX(ID) AS max_id FROM hr_personnel_order GROUP BY PERSONNEL_ID
)
SELECT rd.JYEARKEY, rd.JMONTHKEY, rd.JYEAR, rd.JTMONTH, COUNT(DISTINCT lo.PERSONNEL_ID) cnt
FROM last_order lo
JOIN hr_personnel_order o ON o.ID = lo.max_id
JOIN report_dimdate rd ON rd.DATEKEY = (o.DATE_TO - MOD(o.DATE_TO, 864000000000))
WHERE o.DATE_TO BETWEEN ? AND ?
  AND lo.PERSONNEL_ID NOT IN (SELECT PERSONNEL_ID FROM current_order)
GROUP BY rd.JYEARKEY, rd.JMONTHKEY, rd.JYEAR, rd.JTMONTH
ORDER BY rd.JYEARKEY, rd.JMONTHKEY
]], exit_params)
        if exit_rows ~= nil then
            for _, r in ipairs(exit_rows) do
                table.insert(exit_trend, {
                    label = (r[4] or "-") .. " " .. (r[3] or ""),
                    count = tonumber(r[5]) or 0
                })
            end
        end

        -- age buckets (نیروی فعال، بر پایهٔ profile_user_info.BIRTHDAY — همان ستون تاییدشده در بات ۴۴۴)
        local age_org = org_id and " AND ORG_ID = ? " or ""
        local age_params = { to_date, to_date }
        if org_id then table.insert(age_params, org_id) end
        table.insert(age_params, to_date)
        local age_rows = fetch_rows([[
WITH current_order AS (
  SELECT PERSONNEL_ID, MAX(ID) AS max_id
  FROM hr_personnel_order
  WHERE DATE_FROM <= ? AND DATE_TO >= ? ]] .. age_org .. [[
  GROUP BY PERSONNEL_ID
)
SELECT
  SUM(CASE WHEN age_years IS NOT NULL AND age_years < 25 THEN 1 ELSE 0 END) age_u25,
  SUM(CASE WHEN age_years BETWEEN 25 AND 34 THEN 1 ELSE 0 END) age_25_34,
  SUM(CASE WHEN age_years BETWEEN 35 AND 44 THEN 1 ELSE 0 END) age_35_44,
  SUM(CASE WHEN age_years >= 45 THEN 1 ELSE 0 END) age_45p,
  SUM(CASE WHEN age_years IS NULL THEN 1 ELSE 0 END) age_unknown
FROM (
  SELECT
    CASE WHEN uf.BIRTHDAY > 0 THEN
      DATEDIFF(FROM_UNIXTIME(? / 10000000 - 11644473600), FROM_UNIXTIME(uf.BIRTHDAY / 10000000 - 11644473600)) / 365.25
    ELSE NULL END AS age_years
  FROM current_order co
  JOIN hr_personnel_order o ON o.ID = co.max_id
  JOIN hr_personnels h ON h.PERSONNEL_ID = co.PERSONNEL_ID
  JOIN profile_main p ON p.id = h.PROFILE_ID
  JOIN profile_user_info uf ON uf.id = p.id
) t
]], age_params)
        if age_rows ~= nil and #age_rows > 0 then
            local r = age_rows[1]
            age_buckets.u25 = tonumber(r[1]) or 0
            age_buckets.a25_34 = tonumber(r[2]) or 0
            age_buckets.a35_44 = tonumber(r[3]) or 0
            age_buckets.a45p = tonumber(r[4]) or 0
            age_buckets.unknown = tonumber(r[5]) or 0
        end

        -- tenure buckets (نیروی فعال، بر پایهٔ اولین حکم کاری — همان first_order بالا)
        local ten_org = org_id and " AND ORG_ID = ? " or ""
        local ten_params = { to_date, to_date }
        if org_id then table.insert(ten_params, org_id) end
        table.insert(ten_params, to_date)
        local ten_rows = fetch_rows([[
WITH first_order AS (
  SELECT PERSONNEL_ID, MIN(DATE_FROM) AS hire_date FROM hr_personnel_order GROUP BY PERSONNEL_ID
),
current_order AS (
  SELECT PERSONNEL_ID, MAX(ID) AS max_id
  FROM hr_personnel_order
  WHERE DATE_FROM <= ? AND DATE_TO >= ? ]] .. ten_org .. [[
  GROUP BY PERSONNEL_ID
)
SELECT
  SUM(CASE WHEN months_t < 3 THEN 1 ELSE 0 END) t_lt3m,
  SUM(CASE WHEN months_t >= 3 AND months_t < 6 THEN 1 ELSE 0 END) t_3_6,
  SUM(CASE WHEN months_t >= 6 AND months_t < 12 THEN 1 ELSE 0 END) t_6_12,
  SUM(CASE WHEN months_t >= 12 AND months_t < 24 THEN 1 ELSE 0 END) t_1_2y,
  SUM(CASE WHEN months_t >= 24 AND months_t < 36 THEN 1 ELSE 0 END) t_2_3y,
  SUM(CASE WHEN months_t >= 36 AND months_t < 60 THEN 1 ELSE 0 END) t_3_5y,
  SUM(CASE WHEN months_t >= 60 THEN 1 ELSE 0 END) t_5yp
FROM (
  SELECT
    DATEDIFF(FROM_UNIXTIME(? / 10000000 - 11644473600), FROM_UNIXTIME(fo.hire_date / 10000000 - 11644473600)) / 30.44 AS months_t
  FROM current_order co
  JOIN first_order fo ON fo.PERSONNEL_ID = co.PERSONNEL_ID
) t
]], ten_params)
        if ten_rows ~= nil and #ten_rows > 0 then
            local r = ten_rows[1]
            tenure_buckets.lt3m = tonumber(r[1]) or 0
            tenure_buckets.m3_6 = tonumber(r[2]) or 0
            tenure_buckets.m6_12 = tonumber(r[3]) or 0
            tenure_buckets.y1_2 = tonumber(r[4]) or 0
            tenure_buckets.y2_3 = tonumber(r[5]) or 0
            tenure_buckets.y3_5 = tonumber(r[6]) or 0
            tenure_buckets.y5p = tonumber(r[7]) or 0
        end

        -- ترکیب جنسیتی (نیروی فعال) — ستون تاییدشده: profile_user_info.SEX (1=مرد,2=زن)
        -- طبق کوئری واقعی بات ۳۸۲ SammaryOfInfoPersonnel (query_get_summary_personnel.txt):
        -- "(CASE WHEN sex=1 THEN 'مرد' WHEN sex=2 THEN 'زن' END) jensiat" روی profile_user_info
        -- joined via profile_main همان الگویی که برای BIRTHDAY هم استفاده شده
        local gender_org = org_id and " AND ORG_ID = ? " or ""
        local gender_params = { to_date, to_date }
        if org_id then table.insert(gender_params, org_id) end
        local gender_rows = fetch_rows([[
WITH current_order AS (
  SELECT PERSONNEL_ID, MAX(ID) AS max_id
  FROM hr_personnel_order
  WHERE DATE_FROM <= ? AND DATE_TO >= ? ]] .. gender_org .. [[
  GROUP BY PERSONNEL_ID
)
SELECT
  SUM(CASE WHEN uf.SEX = 1 THEN 1 ELSE 0 END) male_count,
  SUM(CASE WHEN uf.SEX = 2 THEN 1 ELSE 0 END) female_count,
  SUM(CASE WHEN uf.SEX IS NULL OR uf.SEX NOT IN (1,2) THEN 1 ELSE 0 END) unknown_count
FROM current_order co
JOIN hr_personnel_order o ON o.ID = co.max_id
JOIN hr_personnels h ON h.PERSONNEL_ID = co.PERSONNEL_ID
JOIN profile_main p ON p.id = h.PROFILE_ID
JOIN profile_user_info uf ON uf.id = p.id
]], gender_params)
        if gender_rows ~= nil and #gender_rows > 0 then
            local r = gender_rows[1]
            gender_buckets.male = tonumber(r[1]) or 0
            gender_buckets.female = tonumber(r[2]) or 0
            gender_buckets.unknown = tonumber(r[3]) or 0
        end

        -- تحصیلات (بالاترین مدرک ثبت‌شدهٔ نیروی فعال) — جدول/ستون تاییدشده: hr_education.PERSONNEL_ID/education
        -- طبق کوئری واقعی بات ۳۸۲: education کدهای 1..6 اما ترتیب سطح غیرخطی است (6=زیر دیپلم پایین‌ترین
        -- سطح ولی کد آخر) — اینجا با یک رتبه‌بندی صریح (rnk) به «بالاترین مدرک هر پرسنل» تبدیل شده تا
        -- MAX(education) خام (که برای 6 غلط می‌شود) استفاده نشود
        local edu_org = org_id and " AND ORG_ID = ? " or ""
        local edu_params = { to_date, to_date }
        if org_id then table.insert(edu_params, org_id) end
        local edu_rows = fetch_rows([[
WITH current_order AS (
  SELECT PERSONNEL_ID, MAX(ID) AS max_id
  FROM hr_personnel_order
  WHERE DATE_FROM <= ? AND DATE_TO >= ? ]] .. edu_org .. [[
  GROUP BY PERSONNEL_ID
),
edu_rank AS (
  SELECT PERSONNEL_ID,
    MAX(CASE education
        WHEN 5 THEN 5 WHEN 4 THEN 4 WHEN 3 THEN 3 WHEN 2 THEN 2 WHEN 1 THEN 1 WHEN 6 THEN 0
        ELSE -1 END) AS rnk
  FROM hr_education
  GROUP BY PERSONNEL_ID
)
SELECT
  SUM(CASE WHEN er.rnk = 0 THEN 1 ELSE 0 END) below_diploma,
  SUM(CASE WHEN er.rnk = 1 THEN 1 ELSE 0 END) diploma,
  SUM(CASE WHEN er.rnk = 2 THEN 1 ELSE 0 END) associate,
  SUM(CASE WHEN er.rnk = 3 THEN 1 ELSE 0 END) bachelor,
  SUM(CASE WHEN er.rnk = 4 THEN 1 ELSE 0 END) master,
  SUM(CASE WHEN er.rnk = 5 THEN 1 ELSE 0 END) phd,
  SUM(CASE WHEN er.rnk IS NULL OR er.rnk = -1 THEN 1 ELSE 0 END) unknown
FROM current_order co
LEFT JOIN edu_rank er ON er.PERSONNEL_ID = co.PERSONNEL_ID
]], edu_params)
        if edu_rows ~= nil and #edu_rows > 0 then
            local r = edu_rows[1]
            education_buckets.below_diploma = tonumber(r[1]) or 0
            education_buckets.diploma = tonumber(r[2]) or 0
            education_buckets.associate = tonumber(r[3]) or 0
            education_buckets.bachelor = tonumber(r[4]) or 0
            education_buckets.master = tonumber(r[5]) or 0
            education_buckets.phd = tonumber(r[6]) or 0
            education_buckets.unknown = tonumber(r[7]) or 0
        end

        -- تاهل (نیروی فعال) — ستون تاییدشده: hr_personnels.MARITAL_STATUS (0=نامشخص,1=مجرد,2=متاهل)
        -- طبق کوئری واقعی بات ۳۸۲: "(CASE WHEN marital_status=0 THEN 'نامشخص' WHEN marital_status=1
        -- THEN 'مجرد' WHEN marital_status=2 THEN 'متاهل' END) Marital_St" روی خودِ hr_personnels
        local marital_org = org_id and " AND ORG_ID = ? " or ""
        local marital_params = { to_date, to_date }
        if org_id then table.insert(marital_params, org_id) end
        local marital_rows = fetch_rows([[
WITH current_order AS (
  SELECT PERSONNEL_ID, MAX(ID) AS max_id
  FROM hr_personnel_order
  WHERE DATE_FROM <= ? AND DATE_TO >= ? ]] .. marital_org .. [[
  GROUP BY PERSONNEL_ID
)
SELECT
  SUM(CASE WHEN h.MARITAL_STATUS = 1 THEN 1 ELSE 0 END) single_count,
  SUM(CASE WHEN h.MARITAL_STATUS = 2 THEN 1 ELSE 0 END) married_count,
  SUM(CASE WHEN h.MARITAL_STATUS IS NULL OR h.MARITAL_STATUS NOT IN (1,2) THEN 1 ELSE 0 END) unknown_count
FROM current_order co
JOIN hr_personnel_order o ON o.ID = co.max_id
JOIN hr_personnels h ON h.PERSONNEL_ID = co.PERSONNEL_ID
]], marital_params)
        if marital_rows ~= nil and #marital_rows > 0 then
            local r = marital_rows[1]
            marital_buckets.single = tonumber(r[1]) or 0
            marital_buckets.married = tonumber(r[2]) or 0
            marital_buckets.unknown = tonumber(r[3]) or 0
        end

        -- retention rate (۳/۶/۱۲ ماهه) — درصد کسانی که N ماه پیش فعال بودند و امروز هم فعال‌اند
        local function compute_retention(months_ago)
            local then_date = to_date - (months_ago * 30 * FT_DAY)
            local ret_org = org_id and " AND ORG_ID = ? " or ""
            local ret_params = { then_date, then_date }
            if org_id then table.insert(ret_params, org_id) end
            table.insert(ret_params, to_date)
            table.insert(ret_params, to_date)
            if org_id then table.insert(ret_params, org_id) end
            table.insert(ret_params, then_date)
            table.insert(ret_params, then_date)
            if org_id then table.insert(ret_params, org_id) end
            local ret_rows = fetch_rows([[
SELECT
  (SELECT COUNT(DISTINCT PERSONNEL_ID) FROM hr_personnel_order WHERE DATE_FROM <= ? AND DATE_TO >= ? ]] .. ret_org .. [[) AS then_count,
  (SELECT COUNT(DISTINCT PERSONNEL_ID) FROM hr_personnel_order WHERE DATE_FROM <= ? AND DATE_TO >= ? ]] .. ret_org .. [[
     AND PERSONNEL_ID IN (SELECT PERSONNEL_ID FROM hr_personnel_order WHERE DATE_FROM <= ? AND DATE_TO >= ? ]] .. ret_org .. [[)
  ) AS still_active
]], ret_params)
            if ret_rows == nil or #ret_rows == 0 then return 0 end
            local then_count = tonumber(ret_rows[1][1]) or 0
            local still = tonumber(ret_rows[1][2]) or 0
            if then_count == 0 then return 0 end
            return math.floor((still * 1000 / then_count) + 0.5) / 10
        end
        retention.m3 = compute_retention(3)
        retention.m6 = compute_retention(6)
        retention.m12 = compute_retention(12)
    end)
    if not ok then headcount_err = err end
end

-- ── section 2: attendance / delay trend (hr_work_time, monthly) ─────

local attendance_trend = {}
local attendance_err = nil

do
    local ok, err = pcall(function()
        local params = { trend_from, to_date }
        local org_join, org_filter = "", ""
        if org_id then
            org_join = " JOIN hr_personnels hp ON hp.PERSONNEL_ID = hwt.PERSONNEL_ID "
            org_filter = " AND hp.ORG_ID = ? "
            table.insert(params, org_id)
        end
        local rows = fetch_rows([[
SELECT rd.JYEARKEY, rd.JMONTHKEY, rd.JYEAR, rd.JTMONTH,
  COUNT(DISTINCT hwt.PERSONNEL_ID, hwt.WORK_DATE) AS person_days,
  SUM(CASE WHEN hwt.absent = 1 THEN 1 ELSE 0 END) AS absent_days,
  AVG(CASE
        WHEN hwt.absent = 1 THEN NULL
        WHEN hwt.FINAL_ABSENCE = -1 THEN COALESCE(hwt.ABSENCE, 0) / 10000000 / 60
        ELSE COALESCE(hwt.FINAL_ABSENCE, 0) / 10000000 / 60
      END) AS avg_delay_minutes
FROM hr_work_time hwt
]] .. org_join .. [[
JOIN report_dimdate rd ON rd.DATEKEY = hwt.WORK_DATE
WHERE hwt.WORK_DATE BETWEEN ? AND ? ]] .. org_filter .. [[
GROUP BY rd.JYEARKEY, rd.JMONTHKEY, rd.JYEAR, rd.JTMONTH
ORDER BY rd.JYEARKEY, rd.JMONTHKEY
]], params)
        if rows ~= nil then
            for _, r in ipairs(rows) do
                table.insert(attendance_trend, {
                    label = (r[4] or "-") .. " " .. (r[3] or ""),
                    person_days = tonumber(r[5]) or 0,
                    absent_days = tonumber(r[6]) or 0,
                    avg_delay = tonumber(r[7]) or 0
                })
            end
        end
    end)
    if not ok then attendance_err = err end
end

-- ── section 3: overtime requests (hr_overtime_request, monthly) ─────

local overtime_trend = {}
local overtime_err = nil

do
    local ok, err = pcall(function()
        local params = { trend_from, to_date }
        local org_join, org_filter = "", ""
        if org_id then
            org_join = " JOIN hr_personnels hp ON hp.PERSONNEL_ID = r.PERSONNEL_ID "
            org_filter = " AND hp.ORG_ID = ? "
            table.insert(params, org_id)
        end
        local rows = fetch_rows([[
SELECT rd.JYEARKEY, rd.JMONTHKEY, rd.JYEAR, rd.JTMONTH,
  COUNT(*) AS request_count,
  SUM(CASE WHEN r.STATUS = 1 THEN 1 ELSE 0 END) AS confirmed_count,
  ROUND(SUM(GREATEST(r.TIME_TO - r.TIME_FROM, 0)) / 10000000 / 3600, 1) AS total_hours
FROM hr_overtime_request r
]] .. org_join .. [[
JOIN report_dimdate rd ON rd.DATEKEY = r.DAY_DATE
WHERE r.DAY_DATE BETWEEN ? AND ? ]] .. org_filter .. [[
GROUP BY rd.JYEARKEY, rd.JMONTHKEY, rd.JYEAR, rd.JTMONTH
ORDER BY rd.JYEARKEY, rd.JMONTHKEY
]], params)
        if rows ~= nil then
            for _, r in ipairs(rows) do
                table.insert(overtime_trend, {
                    label = (r[4] or "-") .. " " .. (r[3] or ""),
                    requests = tonumber(r[5]) or 0,
                    confirmed = tonumber(r[6]) or 0,
                    hours = tonumber(r[7]) or 0
                })
            end
        end

    end)
    if not ok then overtime_err = err end
end

-- ── section 4: payroll cost trend (hr_payslip + payment detail, monthly) ─

local payroll_trend = {}
local overtime_pay_by_unit = {}
local payroll_err = nil

do
    local ok, err = pcall(function()
        local org_filter = org_id and " AND o.ORG_ID = ? " or ""
        local payroll_params = {}
        if org_id then table.insert(payroll_params, org_id) end
        table.insert(payroll_params, trend_from)
        table.insert(payroll_params, to_date)
        -- الگوی این کوئری عیناً از query_get_salary_wages.txt بات ۵۵۷ (SalariesAndWagesTotal) کپی شده —
        -- نسخهٔ قبلی این بخش، PAYSLIP_VIEW را با MAX() روی کل فیش تجمیع می‌کرد که نادرست بود؛ بات مبدأ
        -- این فیلتر را روی خودِ ردیف‌های hr_payslip_payment_detail اعمال می‌کند (سطح جزء پرداختی، نه کل
        -- فیش) — همان چیزی که اینجا هم پیاده شده تا فیش‌هایی که ترکیبی از اجزای دیده‌شده/نشده دارند هم
        -- درست جمع بزنند، نه این‌که کل فیش (مثلاً فقط چون یک جزء مشمول بیمه‌اش دیده می‌شود) کنار گذاشته شود.
        local rows = fetch_rows([[
WITH tmp_payslip AS (
  SELECT pl.ID AS ID_HR_Payslip, pl.DATE_FROM, o.ORG_ID, o.PERSONNEL_ID
  FROM hr_payslip pl
  JOIN hr_personnel_order o ON o.ID = pl.ORDER_ID
  WHERE 1=1 ]] .. org_filter .. [[
),
decimaldigit AS (
  SELECT po.ORG_ID AS ORG_ID_Org, ps.DECIMAL_COUNT
  FROM pa_organizations po
  JOIN pa_symbols ps ON ps.ID = po.BASE_CURRENCY AND ps.ORG_ID = po.ORG_ID
)
SELECT rd.JYEARKEY, rd.JMONTHKEY, rd.JYEAR, rd.JTMONTH,
  ROUND(SUM(CASE WHEN pay.TYPE = 2
      THEN COALESCE(pay.VALUE_,0) / POWER(10, COALESCE(dd.DECIMAL_COUNT,0)) ELSE 0 END), 0) total_addition,
  ROUND(SUM(CASE WHEN pay.TYPE = 1
      THEN COALESCE(pay.VALUE_,0) / POWER(10, COALESCE(dd.DECIMAL_COUNT,0)) ELSE 0 END), 0) total_deduction,
  ROUND(SUM(CASE
      WHEN pay.TYPE = 2 THEN COALESCE(pay.VALUE_,0) / POWER(10, COALESCE(dd.DECIMAL_COUNT,0))
      WHEN pay.TYPE = 1 THEN -COALESCE(pay.VALUE_,0) / POWER(10, COALESCE(dd.DECIMAL_COUNT,0))
      ELSE 0 END), 0) total_payable,
  COUNT(DISTINCT tp.PERSONNEL_ID) personnel_count
FROM tmp_payslip tp
JOIN hr_payslip_payment_detail pay ON pay.PAYSLIP_ID = tp.ID_HR_Payslip AND pay.PAYSLIP_VIEW = 1
JOIN report_dimdate rd ON rd.DATEKEY = (tp.DATE_FROM - MOD(tp.DATE_FROM, 864000000000))
LEFT JOIN decimaldigit dd ON dd.ORG_ID_Org = tp.ORG_ID
WHERE (tp.DATE_FROM - MOD(tp.DATE_FROM, 864000000000)) BETWEEN ? AND ?
GROUP BY rd.JYEARKEY, rd.JMONTHKEY, rd.JYEAR, rd.JTMONTH
ORDER BY rd.JYEARKEY, rd.JMONTHKEY
]], payroll_params)
        if rows ~= nil then
            for _, r in ipairs(rows) do
                table.insert(payroll_trend, {
                    label = (r[4] or "-") .. " " .. (r[3] or ""),
                    addition = tonumber(r[5]) or 0,
                    deduction = tonumber(r[6]) or 0,
                    payable = tonumber(r[7]) or 0,
                    personnel_count = tonumber(r[8]) or 0
                })
            end
        end

        -- میزان پرداخت اضافه‌کاری در حکم، به تفکیک واحد (بر پایهٔ ردیف‌های واقعی فیش حقوقی
        -- hr_payslip_payment_detail که در نام‌شان «اضافه کار» آمده — نه ساعت درخواستی بات ۳۷۹؛ این عدد
        -- واقعاً در حکم/فیش پرداخت شده است). واحد = واحد سازمانی *فعلی* پرسنل (تقریب معقول، چون فیش
        -- حقوقی واحد را در لحظهٔ محاسبه ذخیره نمی‌کند)
        local ot_pay_params = {}
        if org_id then table.insert(ot_pay_params, org_id) end
        table.insert(ot_pay_params, trend_from)
        table.insert(ot_pay_params, to_date)
        local ot_pay_rows = fetch_rows([[
WITH tmp_payslip AS (
  SELECT pl.ID AS ID_HR_Payslip, pl.DATE_FROM, o.ORG_ID, o.UNIT_ID
  FROM hr_payslip pl
  JOIN hr_personnel_order o ON o.ID = pl.ORDER_ID
  WHERE 1=1 ]] .. org_filter .. [[
),
decimaldigit AS (
  SELECT po.ORG_ID AS ORG_ID_Org, ps.DECIMAL_COUNT
  FROM pa_organizations po
  JOIN pa_symbols ps ON ps.ID = po.BASE_CURRENCY AND ps.ORG_ID = po.ORG_ID
)
SELECT COALESCE(ou.NAME, N'نامشخص') unit_name,
  ROUND(SUM(COALESCE(pay.VALUE_,0) / POWER(10, COALESCE(dd.DECIMAL_COUNT,0))), 0) total_overtime_pay
FROM tmp_payslip tp
JOIN hr_payslip_payment_detail pay ON pay.PAYSLIP_ID = tp.ID_HR_Payslip AND pay.PAYSLIP_VIEW = 1
  AND pay.NAME LIKE N'%اضافه%کار%'
LEFT JOIN decimaldigit dd ON dd.ORG_ID_Org = tp.ORG_ID
LEFT JOIN org_organization_unit oou ON oou.ID = tp.UNIT_ID
LEFT JOIN org_units ou ON ou.ID = oou.UNIT_ID
WHERE (tp.DATE_FROM - MOD(tp.DATE_FROM, 864000000000)) BETWEEN ? AND ?
GROUP BY COALESCE(ou.NAME, N'نامشخص')
ORDER BY total_overtime_pay DESC
LIMIT 15
]], ot_pay_params)
        if ot_pay_rows ~= nil then
            for _, r in ipairs(ot_pay_rows) do
                table.insert(overtime_pay_by_unit, { name = r[1] or "نامشخص", amount = tonumber(r[2]) or 0 })
            end
        end
    end)
    if not ok then payroll_err = err end
end

-- ── section 5: alerts (birthdays this month + dependents aging out) ─

local birthdays = {}
local dependents_alert = {}
local alerts_err = nil

do
    local ok, err = pcall(function()
        -- ماه شمسی جاری (طبق الگوی بات ۴۴۴) — تروانکیت به روز سمت SQL انجام می‌شود تا از خطای
        -- دقت اعشاری double در اعداد بزرگ FILETIME (~1.3e17) در سمت Lua پرهیز شود
        local month_rows = fetch_rows([[
SELECT JTMONTH FROM report_dimdate WHERE DATEKEY = (? - MOD(?, 864000000000)) LIMIT 1
]], { to_date, to_date })
        local current_month_name = nil
        if month_rows ~= nil and #month_rows > 0 then
            current_month_name = month_rows[1][1]
        end

        if current_month_name ~= nil then
            local org_filter = org_id and " AND h.ORG_ID = ? " or ""
            local birthday_params = {}
            if org_id then table.insert(birthday_params, org_id) end
            table.insert(birthday_params, current_month_name)
            local rows = fetch_rows([[
SELECT p.FULLNAME,
  (SELECT JTMONTH FROM report_dimdate rd
     WHERE rd.DATEKEY >= uf.BIRTHDAY AND rd.DATEKEY <= (uf.BIRTHDAY + 86400*10000000) LIMIT 1) AS birth_month
FROM hr_personnels h
JOIN profile_main p ON p.id = h.PROFILE_ID
JOIN profile_user_info uf ON uf.id = p.id
WHERE h.HIRING_STATUS = 2 ]] .. org_filter .. [[
HAVING birth_month = ?
LIMIT 100
]], birthday_params)
            if rows ~= nil then
                for _, r in ipairs(rows) do
                    table.insert(birthdays, { name = r[1] or "-" })
                end
            end
        end

        -- فرزندان دختر تحت تکفل که تا ۳۰ روز آینده ۱۸ ساله می‌شوند (الگوی بات ۵۰۵/insurance_bot)
        local cutoff = to_date + (30 * FT_DAY)
        local dep_params = {}
        local dep_org = ""
        if org_id then dep_org = " AND h.ORG_ID = ? "; table.insert(dep_params, org_id) end
        table.insert(dep_params, to_date)
        table.insert(dep_params, cutoff)
        local dep_rows = fetch_rows([[
SELECT p.FULLNAME AS employee_name, pf.FIRST_NAME, pf.LAST_NAME,
  (pf.BIRTH_DATE + 568080000000000000) AS turns_18_at
FROM CRM_PERSON_FAMILY pf
JOIN PROFILE_MAIN p ON pf.PROFILE_ID = p.ID
JOIN profile_module_status ms ON ms.PROFILE_ID = p.ID AND ms.MODULE_ID = 13 AND ms.STATUS = 1
LEFT JOIN hr_personnels h ON h.PROFILE_ID = p.ID
WHERE pf.BIRTH_DATE > 0 AND pf.FIRST_NAME != '' AND pf.LAST_NAME != ''
  AND pf.GENDER = 1 AND pf.IS_DEPENDANT = 1 ]] .. dep_org .. [[
HAVING turns_18_at BETWEEN ? AND ?
ORDER BY turns_18_at ASC
LIMIT 50
]], dep_params)
        if dep_rows ~= nil then
            for _, r in ipairs(dep_rows) do
                table.insert(dependents_alert, {
                    employee = r[1] or "-",
                    child = (r[2] or "") .. " " .. (r[3] or "")
                })
            end
        end
    end)
    if not ok then alerts_err = err end
end

-- ── JSON output (debug / API) ───────────────────────────────────────

if format_out == "json" then
    teamyar.write_result(json.encode({
        ok = true,
        headcount = headcount,
        headcount_by_unit = headcount_by_unit,
        hire_trend = hire_trend,
        exit_trend = exit_trend,
        age_buckets = age_buckets,
        tenure_buckets = tenure_buckets,
        gender_buckets = gender_buckets,
        education_buckets = education_buckets,
        marital_buckets = marital_buckets,
        retention = retention,
        attendance_trend = attendance_trend,
        overtime_trend = overtime_trend,
        overtime_pay_by_unit = overtime_pay_by_unit,
        payroll_trend = payroll_trend,
        birthdays = birthdays,
        dependents_alert = dependents_alert,
        errors = {
            headcount = headcount_err,
            attendance = attendance_err,
            overtime = overtime_err,
            payroll = payroll_err,
            alerts = alerts_err
        }
    }))
    return
end

-- ── build HTML ───────────────────────────────────────────────────────

-- js_str: escaper برای مقداری که داخل رشتهٔ تک‌کوتیشن JS (نه HTML) جاسازی می‌شود — escape_html اینجا
-- مناسب نیست چون HTML entityها قبل از اجرای JS توسط مرورگر decode و باعث شکستن رشته می‌شوند
local function js_str(value)
    local s = tostring(value or "")
    return (s:gsub("\\", "\\\\"):gsub("'", "\\'"):gsub("\n", " "):gsub("\r", ""))
end

local function bar_row(label, value, max_value, value_label, onclick_js)
    local pct = 0
    if max_value and max_value > 0 then
        pct = math.floor((value * 100 / max_value) + 0.5)
    end
    local click_attr = ""
    local cls = "bar-row"
    if onclick_js then
        click_attr = ' onclick="' .. (onclick_js:gsub('"', HTML_QUOT)) .. '"'
        cls = "bar-row bar-row-clickable"
    end
    return string.format(
        [[<div class="%s"%s><span class="bar-label">%s</span><div class="bar-track"><div class="bar-fill" style="width:%d%%;"></div></div><span class="bar-value">%s</span></div>]],
        cls, click_attr, escape_html(label), pct, escape_html(value_label or fmt_num(value)))
end

local unit_max = 0
for _, u in ipairs(headcount_by_unit) do
    if u.count > unit_max then unit_max = u.count end
end
local unit_bars = {}
for _, u in ipairs(headcount_by_unit) do
    local onclick_js = nil
    if u.unit_id then
        onclick_js = string.format("showUnitDrill(%d,'%s')", u.unit_id, js_str(u.name))
    end
    table.insert(unit_bars, bar_row(u.name, u.count, unit_max, nil, onclick_js))
end
if #unit_bars == 0 then unit_bars = { '<div class="empty-msg">داده‌ای یافت نشد</div>' } end

local function trend_table(rows, cols, headers)
    local thead = {}
    for _, h in ipairs(headers) do table.insert(thead, "<th>" .. escape_html(h) .. "</th>") end
    local tbody = {}
    for _, row in ipairs(rows) do
        local tds = {}
        for _, c in ipairs(cols) do
            local v = row[c]
            if type(v) == "number" then
                table.insert(tds, "<td>" .. fmt_num(v) .. "</td>")
            else
                table.insert(tds, "<td>" .. escape_html(v) .. "</td>")
            end
        end
        table.insert(tbody, "<tr>" .. table.concat(tds) .. "</tr>")
    end
    if #tbody == 0 then
        tbody = { '<tr><td colspan="' .. #headers .. '" class="empty-msg">داده‌ای یافت نشد</td></tr>' }
    end
    return string.format(
        '<table class="data-table"><thead><tr>%s</tr></thead><tbody>%s</tbody></table>',
        table.concat(thead), table.concat(tbody))
end

local attendance_table = trend_table(attendance_trend,
    { "label", "person_days", "absent_days", "avg_delay" },
    { "ماه", "نفر-روز ثبت‌شده", "روزهای غیبت", "میانگین تاخیر (دقیقه)" })

local overtime_table = trend_table(overtime_trend,
    { "label", "requests", "confirmed", "hours" },
    { "ماه", "تعداد درخواست", "تاییدشده", "جمع ساعات" })

local payroll_table = trend_table(payroll_trend,
    { "label", "personnel_count", "addition", "deduction", "payable" },
    { "ماه", "تعداد پرسنل", "جمع اضافات", "جمع کسورات", "خالص پرداختی" })

local exit_table = trend_table(exit_trend,
    { "label", "count" }, { "ماه", "تعداد خروج" })

local birthday_rows = {}
for _, b in ipairs(birthdays) do
    table.insert(birthday_rows, "<tr><td>" .. escape_html(b.name) .. "</td></tr>")
end
if #birthday_rows == 0 then
    birthday_rows = { '<tr><td class="empty-msg">تولدی در این ماه ثبت نشده</td></tr>' }
end

local dep_rows_html = {}
for _, d in ipairs(dependents_alert) do
    table.insert(dep_rows_html, string.format(
        "<tr><td>%s</td><td>%s</td></tr>", escape_html(d.employee), escape_html(d.child)))
end
if #dep_rows_html == 0 then
    dep_rows_html = { '<tr><td colspan="2" class="empty-msg">موردی یافت نشد</td></tr>' }
end

local payroll_total_payable = 0
for _, p in ipairs(payroll_trend) do payroll_total_payable = payroll_total_payable + p.payable end
local avg_monthly_payable = 0
if #payroll_trend > 0 then avg_monthly_payable = payroll_total_payable / #payroll_trend end

local overtime_total_hours = 0
for _, o in ipairs(overtime_trend) do overtime_total_hours = overtime_total_hours + o.hours end

local avg_delay_overall = 0
if #attendance_trend > 0 then
    local sum_d = 0
    for _, a in ipairs(attendance_trend) do sum_d = sum_d + a.avg_delay end
    avg_delay_overall = sum_d / #attendance_trend
end

local error_notes = {}
if headcount_err then table.insert(error_notes, "نیروی انسانی: " .. escape_html(tostring(headcount_err))) end
if attendance_err then table.insert(error_notes, "حضور/تاخیر: " .. escape_html(tostring(attendance_err))) end
if overtime_err then table.insert(error_notes, "اضافه‌کاری: " .. escape_html(tostring(overtime_err))) end
if payroll_err then table.insert(error_notes, "حقوق و دستمزد: " .. escape_html(tostring(payroll_err))) end
if alerts_err then table.insert(error_notes, "هشدارها: " .. escape_html(tostring(alerts_err))) end
local error_html = ""
if #error_notes > 0 then
    error_html = '<div class="error-box"><strong>برخی بخش‌ها بارگذاری نشدند:</strong><br>' ..
        table.concat(error_notes, "<br>") .. "</div>"
end

-- ── چارت/دونات — طبق پالت الزامی این ریپو فقط سایه‌های #16509D (نه رنگ جدید) ────

local function shade_of_accent(index, total)
    local base_r, base_g, base_b = 0x16, 0x50, 0x9D
    local t = (total > 1) and ((index - 1) / (total - 1)) or 0
    local mix = 0.65 * t -- ترکیب با سفید تا ۶۵٪ در روشن‌ترین سایه
    local r = math.floor(base_r + (255 - base_r) * mix)
    local g = math.floor(base_g + (255 - base_g) * mix)
    local b = math.floor(base_b + (255 - base_b) * mix)
    return string.format("#%02x%02x%02x", r, g, b)
end

local function build_donut(items, top_n)
    top_n = top_n or 6
    local total = 0
    for _, it in ipairs(items) do total = total + it.count end
    if total == 0 then
        return "background:#e7edf4;", '<span class="empty-msg">داده‌ای یافت نشد</span>'
    end
    local segs = {}
    local other = 0
    for i, it in ipairs(items) do
        if i <= top_n then table.insert(segs, it) else other = other + it.count end
    end
    if other > 0 then table.insert(segs, { name = "سایر", count = other }) end
    local css_parts, legend_parts = {}, {}
    local acc = 0
    for i, s in ipairs(segs) do
        local pct = s.count * 100 / total
        local color = shade_of_accent(i, #segs)
        table.insert(css_parts, string.format("%s %.1f%% %.1f%%", color, acc, acc + pct))
        table.insert(legend_parts, string.format(
            '<span><i class="dot" style="background:%s;"></i>%s %s%%</span>',
            color, escape_html(s.name), fmt_decimal(pct, 1)))
        acc = acc + pct
    end
    return "background:conic-gradient(" .. table.concat(css_parts, ",") .. ");", table.concat(legend_parts, "")
end

local function chart_bars(items)
    local maxv = 0
    for _, it in ipairs(items) do if it.value > maxv then maxv = it.value end end
    local parts = {}
    for _, it in ipairs(items) do
        local h = (maxv > 0) and math.floor((it.value * 100 / maxv) + 0.5) or 0
        if h < 2 and it.value > 0 then h = 2 end -- میله‌های خیلی کوچک هم قابل دیدن بمانند
        table.insert(parts, string.format(
            '<div class="bar" style="height:%d%%;"><b>%s</b><span>%s</span></div>',
            h, fmt_num(it.value), escape_html(it.label)))
    end
    if #parts == 0 then return '<div class="empty-msg">داده‌ای یافت نشد</div>' end
    return table.concat(parts, "")
end

local unit_donut_css, unit_donut_legend = build_donut(headcount_by_unit, 6)

local gender_items = {}
if gender_buckets.male > 0 then table.insert(gender_items, { name = "مرد", count = gender_buckets.male }) end
if gender_buckets.female > 0 then table.insert(gender_items, { name = "زن", count = gender_buckets.female }) end
if gender_buckets.unknown > 0 then table.insert(gender_items, { name = "نامشخص", count = gender_buckets.unknown }) end
local gender_donut_css, gender_donut_legend = build_donut(gender_items, 3)

local marital_items = {}
if marital_buckets.single > 0 then table.insert(marital_items, { name = "مجرد", count = marital_buckets.single }) end
if marital_buckets.married > 0 then table.insert(marital_items, { name = "متاهل", count = marital_buckets.married }) end
if marital_buckets.unknown > 0 then table.insert(marital_items, { name = "نامشخص", count = marital_buckets.unknown }) end
local marital_donut_css, marital_donut_legend = build_donut(marital_items, 3)

local education_total = education_buckets.below_diploma + education_buckets.diploma + education_buckets.associate
    + education_buckets.bachelor + education_buckets.master + education_buckets.phd + education_buckets.unknown
local function edu_row(label, value)
    local pct_label = "0.0٪"
    if education_total > 0 then
        pct_label = fmt_decimal(value * 100 / education_total, 1) .. "٪"
    end
    return bar_row(label, value, education_total, pct_label)
end
local education_rows = table.concat({
    edu_row("زیر دیپلم", education_buckets.below_diploma),
    edu_row("دیپلم", education_buckets.diploma),
    edu_row("فوق دیپلم", education_buckets.associate),
    edu_row("کارشناسی", education_buckets.bachelor),
    edu_row("کارشناسی ارشد", education_buckets.master),
    edu_row("دکترا", education_buckets.phd),
    edu_row("نامشخص / ثبت‌نشده", education_buckets.unknown),
})

local age_chart_html = chart_bars({
    { label = "کمتر از ۲۵", value = age_buckets.u25 },
    { label = "۲۵–۳۴", value = age_buckets.a25_34 },
    { label = "۳۵–۴۴", value = age_buckets.a35_44 },
    { label = "۴۵+", value = age_buckets.a45p },
})

local tenure_chart_html = chart_bars({
    { label = "کمتر از ۳ ماه", value = tenure_buckets.lt3m },
    { label = "۳–۶ ماه", value = tenure_buckets.m3_6 },
    { label = "۶–۱۲ ماه", value = tenure_buckets.m6_12 },
    { label = "۱–۲ سال", value = tenure_buckets.y1_2 },
    { label = "۲–۳ سال", value = tenure_buckets.y2_3 },
    { label = "۳–۵ سال", value = tenure_buckets.y3_5 },
    { label = "۵+ سال", value = tenure_buckets.y5p },
})

local hire_exit_chart_html
do
    -- ترکیب استخدام/خروج بر اساس برچسب ماه مشترک برای یک چارت واحد
    local by_label = {}
    local order = {}
    for _, h in ipairs(hire_trend) do
        if by_label[h.label] == nil then by_label[h.label] = { hires = 0, exits = 0 }; table.insert(order, h.label) end
        by_label[h.label].hires = h.count
    end
    for _, e in ipairs(exit_trend) do
        if by_label[e.label] == nil then by_label[e.label] = { hires = 0, exits = 0 }; table.insert(order, e.label) end
        by_label[e.label].exits = e.count
    end
    local items = {}
    for _, label in ipairs(order) do
        table.insert(items, { label = label, value = by_label[label].hires })
    end
    hire_exit_chart_html = chart_bars(items)
end

local turnover_total_exits = 0
for _, e in ipairs(exit_trend) do turnover_total_exits = turnover_total_exits + e.count end
local turnover_pct = 0
if headcount.active > 0 then
    turnover_pct = math.floor((turnover_total_exits * 1000 / headcount.active) + 0.5) / 10
end

local overtime_pay_unit_max = 0
for _, u in ipairs(overtime_pay_by_unit) do if u.amount > overtime_pay_unit_max then overtime_pay_unit_max = u.amount end end
local overtime_pay_unit_bars = {}
for _, u in ipairs(overtime_pay_by_unit) do
    table.insert(overtime_pay_unit_bars, bar_row(u.name, u.amount, overtime_pay_unit_max, fmt_num(u.amount) .. " ریال"))
end
if #overtime_pay_unit_bars == 0 then overtime_pay_unit_bars = { '<div class="empty-msg">داده‌ای یافت نشد</div>' } end

local n_units = #headcount_by_unit
local n_birthdays = #birthdays
local n_dep_alerts = #dependents_alert

local function kpi_card(label, value, sub)
    return string.format(
        '<div class="card kpi"><div class="label">%s</div><div class="value">%s</div><div class="delta">%s</div></div>',
        escape_html(label), escape_html(value), escape_html(sub or ""))
end

-- ── تب ۱: نمای مدیریتی ───────────────────────────────────────────────

local exec_kpis = table.concat({
    kpi_card("تعداد کارکنان فعال", fmt_num(headcount.active), "در تاریخ گزارش"),
    kpi_card("نرخ ماندگاری ۱۲ماهه", fmt_decimal(retention.m12, 1) .. "٪", "نسبت به ۱۲ ماه پیش"),
    kpi_card("Turnover (بازهٔ گزارش)", fmt_decimal(turnover_pct, 1) .. "٪", months_back .. " ماه اخیر"),
    kpi_card("متوسط سابقه", fmt_decimal(headcount.avg_tenure, 1), "سال"),
    kpi_card("استخدام جدید", fmt_num(headcount.new_hires), months_back .. " ماه اخیر"),
    kpi_card("خروج", fmt_num(headcount.terminations), months_back .. " ماه اخیر (تخمینی)"),
})

local exec_alerts_card = string.format([[
<div class="card"><div class="title">هشدارها و یادآوری‌ها</div><div class="risk">
<div class="riskitem"><div><strong>تولد این ماه</strong><br><small>پرسنل فعال</small></div><b>%s</b></div>
<div class="riskitem"><div><strong>قطع بیمهٔ فرزندان</strong><br><small>تا ۳۰ روز آینده</small></div><b>%s</b></div>
<div class="riskitem"><div><strong>استخدام‌های زیر ۳ ماه</strong><br><small>نیازمند برنامهٔ onboarding</small></div><b>%s</b></div>
</div></div>]], fmt_num(n_birthdays), fmt_num(n_dep_alerts), fmt_num(tenure_buckets.lt3m))

local exec_donut_card = string.format([[
<div class="card"><div class="title">ترکیب نیروی فعال به تفکیک واحد (%s واحد)</div>
<div class="donut" style="%s"></div>
<div class="legend">%s</div></div>]], fmt_num(n_units), unit_donut_css, unit_donut_legend)

local section_executive = string.format([[
<section id="executive" class="page active">
<div class="kpis">%s</div>
<div class="grid3">%s%s
<div class="card"><div class="title">پرسنلی که این ماه متولد می‌شوند</div>
<div class="table-wrap" style="max-height:180px;"><table class="data-table"><thead><tr><th>نام پرسنل</th></tr></thead><tbody>%s</tbody></table></div></div>
</div>
<div class="grid2">
<div class="card"><div class="title">روند استخدام (ماهانه)</div><div class="chart">%s</div></div>
<div class="card"><div class="title">توزیع کارکنان فعال بین واحدها</div><div class="list">%s</div></div>
</div>
<div class="grid2">
<div class="card"><div class="title">حضور و تاخیر (ماهانه)</div><div class="table-wrap">%s</div></div>
<div class="card"><div class="title">اضافه‌کاری (ماهانه)</div><div class="table-wrap">%s</div></div>
</div>
</section>]], exec_kpis, exec_alerts_card, exec_donut_card, table.concat(birthday_rows, "\n"),
    hire_exit_chart_html, table.concat(unit_bars, "\n"), attendance_table, overtime_table)

-- ── تب ۲: ترکیب نیروی انسانی ─────────────────────────────────────────

local section_workforce = string.format([[
<section id="workforce" class="page">
<div class="grid2">
<div class="card"><div class="title">ترکیب جنسیتی (نیروی فعال)</div>
<div class="donut" style="%s"></div>
<div class="legend">%s</div></div>
<div class="card"><div class="title">وضعیت تاهل (نیروی فعال)</div>
<div class="donut" style="%s"></div>
<div class="legend">%s</div></div>
</div>
<div class="grid2">
<div class="card"><div class="title">تحصیلات (بالاترین مدرک ثبت‌شده)</div><div class="list">%s</div></div>
<div class="card"><div class="title">گروه سنی (نیروی فعال)</div><div class="chart">%s</div>
<p class="note">%s نفر بدون تاریخ تولد ثبت‌شده در این نمودار محاسبه نشده‌اند.</p></div>
</div>
<div class="card" style="margin-top:14px;">
<div class="title">سابقهٔ همکاری در هلدینگ (نیروی فعال)</div><div class="chart">%s</div>
</div>
</section>]], gender_donut_css, gender_donut_legend, marital_donut_css, marital_donut_legend, education_rows,
    age_chart_html, fmt_num(age_buckets.unknown), tenure_chart_html)

-- ── تب ۳: ماندگاری و خروج ────────────────────────────────────────────

local retention_kpis = table.concat({
    kpi_card("Retention ۳ ماهه", fmt_decimal(retention.m3, 1) .. "٪", ""),
    kpi_card("Retention ۶ ماهه", fmt_decimal(retention.m6, 1) .. "٪", ""),
    kpi_card("Retention ۱۲ ماهه", fmt_decimal(retention.m12, 1) .. "٪", ""),
    kpi_card("خروج در بازهٔ گزارش", fmt_num(headcount.terminations), months_back .. " ماه اخیر (تخمینی)"),
})

local section_retention = string.format([[
<section id="retention" class="page">
<div class="kpis">%s</div>
<div class="card" style="margin-top:14px;"><div class="title">روند خروج (ماهانه)</div><div class="table-wrap">%s</div></div>
</section>]], retention_kpis, exit_table)

-- تب‌های «جذب و استخدام» و «عملکرد و استعداد» طبق درخواست کاربر حذف شدند (۱۰۰٪ محتوایشان «—» بدون منبع
-- داده واقعی بود — هیچ جدول ATS/ارزیابی عملکرد/جانشین‌پروری در ۱۱ بات HR این ریپو پیدا نشد). اگر بعداً
-- منبع دادهٔ این دو حوزه شناسایی/تایید شد، همین‌جا (و در سایدبار/help modal) دوباره اضافه شوند.

-- ── تب ۶: هزینه و بهره‌وری ────────────────────────────────────────────

local cost_kpis = table.concat({
    kpi_card("کل حقوق پرداختی", fmt_num(payroll_total_payable), months_back .. " ماه اخیر"),
    kpi_card("میانگین حقوق ماهانه هر نفر", headcount.active > 0
        and fmt_num(avg_monthly_payable / headcount.active) or "—", "بر پایهٔ نیروی فعال فعلی"),
    kpi_card("جمع ساعات اضافه‌کاری", fmt_num(overtime_total_hours), months_back .. " ماه اخیر"),
})

local section_cost = string.format([[
<section id="cost" class="page">
<div class="kpis">%s</div>
<div class="grid2">
<div class="card"><div class="title">میزان پرداخت اضافه‌کاری در حکم، به تفکیک واحد (واحد فعلی پرسنل)</div>
<div class="list">%s</div></div>
<div class="card"><div class="title">روند حقوق و دستمزد (ماهانه)</div><div class="table-wrap">%s</div></div>
</div>
</section>]], cost_kpis, table.concat(overtime_pay_unit_bars, "\n"), payroll_table)

-- ── قالب کلی صفحه (Static shell — بدون %s برای بخش سنگین؛ ادغام با .. صورت می‌گیرد) ──

local html_head = [[<!DOCTYPE html>
<html lang="fa" dir="rtl">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>داشبورد حاکمیت سرمایه انسانی | هلدینگ ۱۴۰</title>
<style>
@font-face {
    font-family: "PeydaReport";
    src: url(data:font/truetype;charset=utf-8;base64,AAEAAAAOAIAAAwBgRFNJRwAAAAEAASFUAAAACEdERUYrBC3XAADcNAAAAHxHUE9TKUGIwAAA3LAAADTIR1NVQk+rAWsAARF4AAAP2k9TLzJ2gVbcAAABaAAAAGBjbWFwh/GYyAAADSAAAAeaZ2x5ZmvrPHUAABpsAACfzmhlYWQnUViOAAAA7AAAADZoaGVhCDcSFgAAASQAAAAkaG10eD9fZe0AAAHIAAALWGxvY2EviwdzAAAUvAAABa5tYXhwA1MBBAAAAUgAAAAgbmFtZXvHsAoAALo8AAAFPnBvc3RoWZoTAAC/fAAAHLcAAQAAAAMAAGLmoqxfDzz1AAMD6AAAAADflRqKAAAAAOO0+jP/S/3XBaMFFgAAAAcAAgAAAAAAAAABAAADRv5wAAASx/9L/ggFowABAAAAAAAAAAAAAAAAAAAC1gABAAAC1gBhAAcAgQAGAAEAAgAeAAYAAABkAAAAAwADAAQCZAGQAAUACAKKAlgAAABLAooCWAAAAV4AMgEsAAAAAAAAAAAAAAAAAAAgAQAAAAAAAAAIAAAAAEtIRE0AwAAN/vwD6P4MAAAEsAH0AAAAQAAAAAABaQK/AAAAIAAEAiwASwJYAAACWAAAAIMAAAJnABgCaABTAh4AOgKCAFMCLgBUAgwAVAJgADYCogBTAP4AUwE3ABMCVwBTAc8AUwNJAFMCjQBTAqgANQJTAFMCqAA1AosAUwIuADACJAAPApYATgJnABgDkwAdAjQAEwI1ABMCFQAoAdkAJwIYAEkBsAAwAhgALwIHAC8BdwAeAe0AMAIpAEkA6gBJANkAAQINAEkA6wBKA08ASQIpAEkCFAAwAhgASAIYADABcgBJAbkALgFvAB4CKQBAAeQAGAK0ABgB0QAYAcsAGAHFACgCOgApAaIAMwI6AEMCLAA1AjoAKAI1AEECNwAxAhsASgIxACwCNwAxARAAWAEKAEEBEQBYAREAQwG+AEkCVgBJAh4ANAIYACgByQAYAZUASAHtACgCRQBJAe4AKADYADsB2wAxANwAQwGNAEMC9ABhBAkASQJEAEkCqwAlAukAQwFZAEYBWQAyAcEAVwEWAF8BxABUAVsASAGXADEBWwAvAREALAD4ACgB7AArAecAKwDZAEIB1wAoAaUAhAI+AEkChgBJBHoASQKQAEYCogBGAqIARgJbAEkB8ABJAigASQKdAEYCQABJAlcASQI1AEkB8gBJARYAXwLuAE0A8ABNAPAARAH6AEoBuABGAdAASgKQAEYCGgBiAiwARgIuAEYCtwBmAacATAGnADgAAP94AAD/eAJnABgCZwAYAmcAGAJnABgCZwAYAmcAGAJnABgCZwAYAmcAGAN/ABgCHgA6Ah4AOgIeADoCHgA6AtQAUgKCAFMC1ABSAi4AVAIuAFQCLgBUAi4AVAIuAFQCLgBUAi4AVAIuAFQCdAAsAmAANgJgADYCYAA2Ap4ANQD+AFMA/v/ZAP4AGwD+AFMA/v+9AP7/8QD+//ICVwBTAc8AUwHP/9cBzwBTAd0ADAKNAFMCjQBTAo0AUwJ6AFMCjQBTAqgANQKoADUCqAA1AqgANQKoADUCqAA1AqcANQKoADUD+gA1AlgAUwKLAFMCiwBTAosAUwIuADACLgAwAi4AMAIuADACZABKAlAAJQIkAA8CJAAPAiQADwKWAE4ClgBOApYATgKWAE4ClgBOApYATgKWAE4ClgBOA5MAHQOTAB0DkwAdA5MAHQI1ABMCNQATAjUAEwI1ABMCFQAoAhUAKAIVACgB2QAnAdkAJwHZACcB2QAnAdkAJwHZACcB2QAnAdkAJwHZACcDHgAnAbAAMAGwADABsAAwAbAAMAI9ADECGAAvAhgALwIMAC8CBwAvAgwALwH7AC8CBwAvAfsALwIHAC8CBwAvAgcAKgHtADAB7QAwAe0AMAIpACMA6gBJAPsASQEB/9AA+gAVAOgARwDpAAAA5//mAOr/6AINAEkA6wBKAOv/ywDrADUA6//tAikASQIpAEkCKQBJAisASQIpAEkCFAAwAhQAMAIUADACFAAwAhQAMAIUADACFAAwAhQAMANoADACGABIAXIASQFyAA4BcgA7AbkALgG5AC4BuQAuAbkALgJoAEgBbwAeAW//8QFvAB4BbwAeAikAQAIpAEACKQBAAikAQAIpAEACKQBAAikAQAIpAEACtAAYArQAGAK0ABgCtAAYAcsAGAHLABgBywAYAcUAKAHFACgBxQAoAdgAQQDRAEcBCABIAM3/5QEO/+4A3P/wAQsAAAD//+8BKf/vAUH/1QE3/8kDUgBHA3oARwFe//IBM//yAUv/8gGT//IB3f/yA1IARwN6AEcBXv/yATP/8gGT//IDUgBHA3oARwFe//IBS//yAZP/8gHd//IDUgBHA3oARwFe//IBS//yAZP/8gG///IDUgBHA3oARwFe//IBS//yAZP/8gGW//IDUgBHA3oARwFe//IBM//yApsASAKzAEgCrf/yAp3/8gKhAEgCsQBIAq3/8gKd//ICkgBIArMASAKt//ICmP/yApsASAKzAEgCrf/yAp3/8gIlAEgCRgBIAiUASAJGAEgCJQBIAkYASAFE/9gBAv/eAWf/2AEk/94BRP/YAWf/2AEk/94BAv/eAUT/2AFn/9gBRP/YAWf/2AFE/9gBAv/eAbP/2AEk/94EhQBHBLwASAL5//ICx//yBIUARwS8AEgC+f/yAsf/8gTHAEcE9QBHAzH/8gME//IExwBHBPUARwMx//IDBP/yAt0ASQMLAEkCzP/yAp7/8gLdAEkDCwBJAsz/8gKe//ICMABJAlkASQJS//IB2f/yAjAASQJZAEkCUv/yAdn/8gNTAEkDnwBJAcP/8gHH//IDUwBJA58ASQHD//IBx//yA1MASQOfAEkBw//yAcf/8gK7AEkC3ABJArsASQLcAEkBw//yAcf/8gNSAEkDegBJAgD/8gGH//IDaQBHA2oARwRRAEkD4ABHBIQASQIA//IDJP/yAYf/8gGH//IC8v/yA2kARwNoAEcEUQBJA+AARwSEAEkCAP/yAyT/8QGH//IBg//yAvL/8QK5AEgC8QBIAU3/8gEK//MCugBIAvEASAFN//IBCv/zAo8ARwLkAEcCMP/yAgb/8gK3AEcC5gBHAV7/8gEz//ICtwBHAuYARwHnAEcCBABJAm7/8gKw//IB5wBHAgQASQHnAEcCKwA7AkX/8gEz//IB5wBHAgQASQKw//ICVQBBAuz/8gKw//IB5wBHAgQASQHnAEcCKwA7AeAAQQHtAEEB4QBBAewAQQHhAEEB7ABBAeEAQQHsAEEC1wBHAuEARwLXAEcC4QBHApgARwFe//IBS//yAZP/8gHT//IC2AAuAuIARwKYAEcBXv/yATP/8gGT//IC2AA8AtcARwLhAEcCmABHAV7/8gFL//IBk//yAdD/8gJsAEcCmABHArgARwLnAEcAwQAAAhAAMQJGADECEAAWAkYAFwIQADACRgAxAiIAAAJV//wCEP/ZA4kARwPRAEcDjwBHA48ARwOTAC4DjwBHAkb/2gPRAEcD0QBHA+QAUAPRAEcDjwBH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AQ0BDgEUAQ8AdAETASYBIwEkASUBLwEWATEAigDiAIYA3gCLAOMAjwDnAJIA6gCQAOgAlADsAJUA7QCcAPQAmgDyAJ0A9QCXAO8AnwD3AKEA+QCgAPgAogD6AKgBAQCpAQIApgD7AKoBAwCrAQQArQEGAKwBBQCuAQcArwEIALEBCgCwAQkAswEMALkBEgC4AREAvAEVAL4BFwDAARkAvwEYAMEBGgDDARwAwgEbAMgBIQDHASAAxgEfAM8BKADRASoAzgEnANABKQDTASwA1wEwANgA2gEyANwBNADbATMAxAEdAMkBIgLEAsUCxwLLAswCyQLDAsICygLGAsgBNQE8ATgB+gE6AgkBNgFHAfQBUgFYAWIBagFuAXIBdAF4AXwBiAGMAZABlAGYAZwBoAGkAhsBqAG2AboB0gHaAd4B5AH4AgACAgKtAq4CrwKwArECsgKzArsCvAKrAqwCqgKXAmQCZQKRAUABtAKpAT4B6AHqAe4B9gH8Af4A1QEuANIBKwDUAS0ChAKCAoUCgwKLAoYCiQKKAocCjAKBAoACfgJ/AGAAYQBkAGIAYwBlAH4AfwBmAUwBTQFPAU4BXgFfAWEBYAGtAa8BrgFmAWcBaQFoAXYBdwGEAYYBgAGBAb4BwQHFAcMByAHLAc8BzQHoAekB6gHrAe0B7AHxAfMB8gIXAhACEQIUAhMCOAI6AkACQgJIAkoCUQJTAjkCOwJBAkMCSQJLAlICVAE1ATwBPQE4ATkB+gH7AToBOwIJAgoCDQIMATYBNwFHAUgBSgFJAfQB9QFSAVMBVQFUAVgBWQFbAVoBYgFjAWUBZAFqAWsBbQFsAW4BbwFxAXABcgFzAXQBdQF4AXoBfAF9AYgBiQGLAYoBjAGNAY8BjgGQAZEBkwGSAZQBlQGXAZYBmAGZAZsBmgGcAZ0BnwGeAaABoQGjAaIBpAGlAacBpgGoAakBqwGqAbYBtwG5AbgBugG7Ab0BvAHSAdMB1QHUAdoB2wHdAdwB3gHfAeEB4AHkAeUB5wHmAfgB+QIAAgECAgIDAgYCBQIiAiMCHgIfAiACIQIcAh0AAAAAAEIAQgBCAEIAXACNALgA2gDyAQcBOQFRAV0BdAGZAakBxAHbAgMCJAJWAoYCwwLVAvMDBwMkAz8DVANqA6sD2QP8BCoEXQSHBQIFLgVABVkFfAWJBdMGAAYzBmQGlQauBuUHCgcxB0UHYgd7B48HpQfNB98ICghECF4IlAjJCNwJKgliCW0JhwmYCbgJxAnZCjkKTAp2CoQKlwqqCrwKzwr+CwsLHgtPC6YL6gw3DIYMoQy9DOwM+Q0oDUQNUg1vDYsNpg3VDgQOIQ5PDlsOZw5zDn8OoQ74D0kPig+6D+4QFBAhEDwQVhBuEIIQmhCmELkQ8BEWESQRRBGqEcAR3BIIEhsSLhJHEmASaxJ2EoESjBKXEqIS0BLbEuYTFhMhEywTchN9E6cTshO6E8UT0BPbE+YT8RP8FAcUMxRvFHoUhhSRFK8UuhTFFNEU3RTpFPQVFBUgFSsVNhVCFVkVZBVvFXsVhhWoFbMVvhXJFdQV4BXsFh0WKBZjFoQWjxaaFqYWsRa8FxUXIRdeF3YXgReMF5gXoxeuF7kXxBfPF9oYCxgWGCIYLhg6GEUYUBhbGGYYcRh8GIcYkhieGKkYtBjAGMwY1xksGTgZRBmyGb4ZyRoIGhQaVBpfGpQaoBqrGrYawhrOGtoa5RssG18baht1G4EbsxvAG9Qb6xwDHBYcKRw9HGMcbxx7HIcckhynHLMcvhzKHNYdDx0bHScdMx0/HUodVR2RHZ0d+x4sHjgeQx5OHloeZR64HsMfAh8tHzgfeR+EH5Afmx+nH7Mfvh/JIAMgDyAbICYgMiA+IEogVSBhIG0geCCEIKwguSDVIQIhQCFLIVchcyGfIeEiNCJVIoMisiLNIugjAyMfIysjNyNDI04jWSNlI3EjfCOHI5IjnSOpI7UjwSPNI9kkACQMJBgkJCQwJDwkaCR0JIAkjCSYJKQksCS8JMglGiV+JYolliXXJismeya3JsMmzybbJucnDCc/J0snVydjJ28nhSedJ8Qn7if6KAYoEigeKCooNihCKE4oWihmKKAorCj2KVIpqinrKfcqAyoPKhsqbirPKyMrayt3K4MrjyubK9IsFixeLJcsoyyvLLssxy0CLUstky29Lckt1S3hLe0t+S4FLhEuHS4pLjUuQS5NLpgu7C82L3wvyDAeMCowNjBCME4whTDLMNMw2zEIMTQxZzGzMfYyOzJ6Mp8ywzLxMv0zMjM+M0ozVjNiM20zeTOmM7Ez0zQGNC40STRVNGE0bTR5NLI0/DVKNYk1lTWhNa01uTXdNg82STZ8NtY3KTc1N0E3STdrN603uTfFN9E32ThGOK44tjjCOM442jjmOSU5cDl8OYg5lDmgOaw5uDnAOcg51DngOew59zoCOg06NDpAOkw6WDpkOnA6fDqIOsE68DsZOyE7LDs3O147jTu2O8I7zjvdPAE8OjxGPFI8XjxqPHY8gjyOPOo9Rj1SPWI9cj1+PYo9lj2mPbY9wj3OPd497j36PgY+Fj4mPjI+mj8YPyQ/MD88P0g/UD9YP2Q/cD+AP5A/oD+wP7w/yEA6QL9Ay0DXQONA70D3QP9BC0EXQSNBM0FDQVNBY0FvQXtBi0GbQadBt0HDQc9B30HvQftCB0KMQppCtELAQshC0ELYQxtDUkN0Q3xDhEOMQ8BD1kP/RD5EfkTSRQVFNUVnRahF20XjReNF40XjReNF40XjReNF40XjReNF40XjReNF40XjReNF40XvRglGKEZZRrlHH0eFR7VH40hRSIFIt0jCSM1I2EjoSPhJCUkaSTFJR0leSXRJr0nKSdhJ5kn0SgBKC0oySlhKbUq7StBK3kseSytLWkuYTA5MS0yBTOhNHk1TTYFNlk3HTeZOBk4xTlxObk57TohOlk6pTrpOy07lTwtPNU9DT11Pd0+ZT7NPu0/HT9NP30/nAAAAAgBLAAAB4ALBAAYAKgAAASERITkCJSc3NxYnJzcXFyYmJyczBwc3NxcHBxcXBycnFxcjNzcHOQIB4P5rAZX+qxtWNwI6VhtSLQEIAgU4BAsuUhtWNzhWHFEvDAY3AwksAsH9P+4vLhYCFSwxNiUJKAhkYzkmNjAuFBMtMTQmOmFgPCgAAgAYAAACTwK/AAYACgAAATMTIwMDIxMzFyEBBF/sWcLEWKnmGf7mAr/9QQJM/bQBBEoAAAMAUwAAAjMCwAAOABcAHwAAEzMyFhUUBgcWFhUUBiMhJDY1NCYjIxUzEjU0JiMjFTNT4GhlLCtGRG1p/vYBTDtFP6uwTDg+h44CwFNaQE0TCGBJX2NKNz9BQPcBQXk8NusAAQA6//YB9wLHABsAABYmNTQ2MzIXByInJiMiBgYVFBYWMzI3NjMXBiOgZmeDV3wFCh5kN0NFFRVFQzdkHgoFgVMKt7KxtxBCAgZNeVhZeU0GAkMPAAACAFMAAAJNAr8ACAASAAATITIWFwYGIyEkNjY1NCYjIxEzUwEDhm8CAm+F/vwBPEkYSV6enwK/sLCvsEtOf1t4iv3VAAEAVAAAAf0CvwALAAABIRUhFSEVIRUhESEB9P63ARb+6gFS/lcBoAJ07Er0SgK/AAEAVAAAAfQCvwAJAAATIRUhFSEVIREjVAGg/rcBFv7qVwK/S/JK/sgAAAEANv/1AiACxwAgAAAWJjU0NjMyFhcHJiYHIgYGFRQWFjMyNjcmJjU1MxEGBiOdZ2aDLodABC2WIkNFFhZFQyFuGAUEVz2YKwu6r7K3CQhDAwgBTXpYVXpPBAMOHh3j/pQHCwABAFMAAAJPAr8ACwAAEzMRIREzESMRIREjU1gBTVdX/rNYAr/+ygE2/UEBP/7BAAABAFMAAACrAr8AAwAAMyMRM6tYWAK/AAABABP/uwDpAr8ADAAANgYjIic1MzI2NREzEek/SyAsQyUVWRZbB0MnMgJh/bMAAgBTAAACQwK/AA4AEgAAASMnMxMzAwYGBxYWFxMjATMRIwE7mwKbn1qRDxQPDxAQpV3+bVhYAUVLAS/+5x4VCQYSHv7MAr/9QQABAFMAAAHBAr8ABQAAEzMRIRUhU1gBFv6SAr/9i0oAAAEAUwAAAvYCvwAMAAABAyMDESMRMxMTMxEjAp3EacVYl7u6l1kCdf22Akr9iwK//cECP/1BAAEAUwAAAjoCvwAJAAABMxEjAREjETMBAeJYjv7/WI0BAgK//UECcv2OAr/9iwACADX/9QJyAscADAAZAAAWJjU0NjMyFhUUBgYjPgI1NCYjIgYVFBYztH9/oKB+L31yUlcdVHJyVVVyC72srL29rHKdWkpNe1eCnZ2Cgp0AAAIAUwABAjECwAAKABMAABMzMhYVFAYjIxUjADY1NCYjIxEzU/9wb3Fup1gBQkNAR6amAsB5cnR/4QErVFZUTP62AAMANf9pAnICxwAMABkAHwAAFiY1NDYzMhYVFAYGIz4CNTQmIyIGFRQWMxc3FhcXB7R/f6Cgfi99clNXHFRyclRUckc5JCAlSQu9rKy9vaxynVpKTXtXg5ycg4OcOwwKNz0pAAACAFMAAAJeAr8AEQAcAAATMzIWFhUUBgcWFhcTIwMjESMSNjY1NCYmIyMRM1PRUmErLTMNFg6LXpe+WPw6IBg3Mn1nAr8qWEpOYA8GFxj+/wEd/uMBag06QTQ4F/71AAABADD/8wH+AscAKAAAFiYnNxYWMzI2NjU0JicnJiY1NDYzMhcHJyYjIgYGFRQWFxcWFhUUBiP1mSwDPnoiNEAlJzWNTEBkbESSBidaMjE+Jik1h1BAZHoNEQpCCQkPNTYwMBAtGVJKX14PQwIGDzIyLjIRKhlSTGBlAAEADwAAAhUCvwAHAAATIzUhFScRI+fYAgbWWAJ1SksB/YsAAAEATv/1AkkCvwARAAAWJjURMxEUFjMyNjURMxEUBiPBc1lIXF1IWXSKC4mEAb3+OF5aWl4ByP5DhIkAAAEAGAAAAk8CvwAGAAABAyMDMxMTAk/sX+xYxMICv/1BAr/9rQJTAAABAB0AAAN2Ar8ADAAAAQMjAzMTEzMTEzMDIwHKkGK7VZuPWpCaVrthAib92gK//bwCJv3aAkT9QQAAAQATAAACIgK/AAsAABMzExMzAxMjAwMjExVipqZe0NFip6he0QK//tMBLf6c/qUBJv7aAVgAAQATAAACIwLAAAgAABMzExMzAxEjERNeq6hf3FcCwP62AUr+YP7gASAAAQAo//8B7QK/AAkAAAEhNSEVASEVITUBiP6iAcP+owFd/jsCdUpI/dJKSQACACf/9AGeAgoAIAAtAAAWIyImNTU0NjMzNTQmIyIHBiMnNjc2MzIWFREjNQYGBwc2NzUjIgYVFRQWMzI3shA5Qk5DjiEsO1QLFQIzG1ARV1BYDBkcQUQ+kRogHhkKBQxKOkhBThguKgIBQwQBBkpZ/pkdCgsFDFMMtx8dXxYfAQAAAgBJ//oB6ALmABgAHAAABCYnNxYWMzI2NTQmIyIGByc2MzIWFRQGIycRMxEBGZs1MiRoJjQvLzQbZRABbSxfVFRf7FgGCQRDAgRWaGlWCQNDE3yNjHwNAt/9HAABADD/9wGIAgkAFQAAEjYzMhcHJiMiBhUUFjMyNxcGIyImNTBUXzduAkBbNS4uNUpRAm43X1QBjXwJRAJVaWlVA0UJfI0AAgAv//oBzgLmABgAHAAAFiY1NDYzMhcHJiYjIgYVFBYzMjY3FwYGIxMzEQeDVFRfLG0BEGUbNC8vNCZoJDI1mxyUWFgGfIyNfBNDAwlWaWhWBAJDBAkC7P0hBQACAC//+gHdAg4AHQAhAAAWJjU0NjMzMhYVFAYVJzQmIyMiBhUUFhYzMjcXBiMDIRchoHFyZxViXgJQNjgSPUYgQDhSWAd0VZgBWBP+lQaBhICPjXwTHgMna2NfaFBTHQtAEAEYQQACAB4AAAFjAtwAEgAZAAATIzUzNTQ2MzIXFhcHJyIGFREjEiYnJzMVI29RUTtPCzIPHgJgJRVYhSYSB6dMAaFKO11ZBAICRAIwPf3bAaEICjhKAAAEADD+3wH3AqQAKwA8AE4AVwAAEiY1NTQ2NyYmNTQ2NyY1NTQ2MzMyFhUVFAYGBwYHBgYVFBYXFxYVFRQGIyM2NjU1NCYnJw4CFRUUFjMzAjc2Njc1NCYjIyIGFRUUMzI/AhcGBwcGBgd/TzAzISInGVpGS09TOA8kKDooHiEdI3N8T0N+mR8mJl4FLRYeHnskBwYVExgaVB4fPQ4JXW9IBi4NDhgP/t9EPy81Ox0IKB8hLAkXaD89UFpHRCcmEggLCQceEhIUBhYXczdCU0shHEciGAYOAyIiFDolGAHaAgEFA3YbIiciN0sC8LsvDEUUFRcKAAACAEkAAAHpAtsAFAAYAAAAJiMiBwc3NjY3NzY3NjMyFhURIxEBMxEjAZEiIAUOogEEHBosLAUSEUNRWP64WFgBmykCHkQCDAUICAIDWEL+igF5AWL9JQAAAgBJAAAAoQKhAAMABwAAEzMRIxEzFSNJWFhYWAIE/fwCoVEAAgAB/z0AjwKhAAgADAAAFjURMxEUBgcnEzMVIzhXMC4wN1dXTGIB7v37PWQhMwMxUQACAEkAAAHoAsYADgASAAAlIyczNzMHBgYHFhYXFyMBMxEjARl/AoBiWloPFg8QEQ9yXf6+WFjsS820HhoHCBEe2gLG/ToAAQBKAAAAoQMJAAMAABMRIxGhVwMJ/PcDCQADAEkAAAMOAhcAAwAYAC4AABMzESMAJiMiBwc3Njc2Njc3NjMyFhURIxEkJiMiBwc3PgI3Njc3NjMyFhURIxFJWFgBQCIfBQ6xAQ4tFCYNJBIRQ1FZASwiIAUOsAMEEBQQKRwmEhJDUVkCF/3pAZspAiJDDAgFBwMHA1hC/ooBeSIpAiJDAgkGAwkFCANYQv6KAXkAAgBJAAAB6QIXABUAGQAAACYjIgcHNzY3Njc2Njc2MzIWFREjESUzESMBkSIgBQ6iAQwuERYQHQkSEUNRWP64WFgBmykCHkMMCAQDAwYCA1hC/ooBeZ796QAAAgAw//IB5AIIAA8AIQAAFiYmNTQ2NjMyFhYVFAYGIz4CNTU0JiYjIgYGFRUUFhYzuF4qKl5RSl8yMl9KMzgXFzgzMjgXFzgyDjBzaGhzMC51aGh1LkoeRD1DPUUeHkU9Qz1EHgAAAgBI/y0B5wIXABoAHgAABCYnNxYWMzI2NTQmJiMiBgcnNjYzMhYVFAYjAzMRIwEWggwOFWoXNC8UKyQcXyEVQ1IlXlRUXu1ZWQcKA0QCBVVnSFQkDQc9ERF9jot7Ah79FgACADD/LQHPAgoAGgAeAAAWJjU0NjMyFhcHIicmJiMiBhUUFjMyNjcXBiMTFxEjhFRUXh2bNTIMCRxYKTUuLzQaXhgBbS2UWVkHfI2MfAgEQwEBA1VpaFYIA0MTAgoF/S8AAAIASQAAAXICEgADAAoAABMzESMSNjc3Fwc3SVhYWyYQfhreBgIL/fUByxcFK01KSAAAAQAu//UBigIKACQAABYmJzcWFjMyNjU0JicnJiY1NDMyFwcmIyIGFRQWFxcWFhUUBiPBfRUELGoeJCcUIWU5MZ4/YQE+XCgjGChXPDFUUwsOBkMGBx8lJCAKHhJBN5EJQwIeKRkjCxsTQjtPQwACAB7/7gFjAsYAEAAWAAAWJjURIzUzNTMRFBYzNxcGIwInJzMVI64/UVFYFSVgAkogICICp0wSW1sBH0u4/d89MAJDCQHVDD9LAAIAQP/yAd8CAgASABYAABYjIiY1ETMRFBYzMjc3BwYHBgcTMxEj5RFDUVgjIAUOogEOLA1RkFhYDldCAXX+iiMqAh9DDAgDDwIN/fgAAAEAGAAAAc0CBAAGAAABAyMDMxMTAc2rYKpXg4MCBP38AgT+XAGkAAABABgAAAKcAgQADAAAAQMjAzMTEzMTEzMDIwFaX1yHVmZfTl5nVolbAXL+jgIE/ncBZf6bAYn9/AAAAQAYAAABuQIEAAsAABMDMxc3MwMTIycHI7KYZGxtXJSaYnByXQEBAQPOzv7//v3Q0AABABj/JgG0AgQACAAANxMzAyM3IwMz5HlXy1c+LIxXQwHB/SLaAgQAAQAo//wBnQIEAAkAAAEhNSEVASEVITUBNP70AXX+9QEL/osBsVNR/p1UUQACACn/9gIRArEACwAZAAAWJjU0NjMyFhUUBiM2NjU0JiYjIgYGFRQWM5hvb4SGb2+EWT8YQj49RBlBWQqzq7CtsK2rs0qLiV91P0B2XYqKAAEAMwAAAUACpgAGAAATJzczESMTRxS6U1sBAhRHS/1aAj4AAAEAQwAAAfUCswAaAAA3NzY2NTQmIyIGBwcnNzY2MzIWFRQGBgchFSFH5S8ySEEbRCI5Byc7USVlZTd/hgFM/lJG9zJUL0E5BwUHQAYKCldkOWmJgE0AAgA1//cCAgKxABgAIwAAJAYjIiYnNxYzMjY1NCYjIgYHJzY2MzIWFQMBJzY3NjY3ITUhAgKCeiOHJwaLRk1QQ0EcQhsnHl8yV3ch/ssxERordzj+uwGmWGEOB0MPOkFBUAsKJRYcYnEBp/7VLQ8cKnQ2TgABACgAAAIaAqsADgAAJSE1EzMDMzUzFTMVIxUjAXL+tq9Zq+1XUVFXrz8Bvf5O0dFKrwAAAgBB//UB+wKmABkAIQAAFic3FxYWMzI2NTQmIyIGByc2NjMyFhUUBiMDEyEVIQ8Cw4IHQSw5JExEOU0lPzQPPUouZWx4dMcUAYn+wBALBgsbQQkGBkdERkkODzAdE2pqY20BUgFfSvIVHAAAAQAx//MCCwKwACQAABYmJjU0NjYzMhcHJiMiBgYVFBYWMzI2NTQmIyIHJzYzMhUUBiPAaSYue3AyWghARFRVGxJDR1FAP0dBcgR8Usdvew1JjHSAoFQQQghGfWljZTVIUkxBMUM413dtAAEASv/1AfoCpgAGAAABITUhBwEnAaj+ogGwAf72VAJcSkn9mA8AAwAs//UCBQKxABcAJwA1AAAWJjU0NjcmJjU0NjMyFhUUBgcWFhUUBiM+AjU0JiYjIgYGFRQWFjMSNjY1NCYjIgYVFBYWM55yOkhAM2d3dmY1PEk4cHw5Ph0bPjk7QRsdPzo1Nhk6Skw7Gzk0C1lfR2cHCFo8VVxcVT9XCAdmSGBYShQ0MTU5Fxg5NDMzEwFLEC8vQDI0Pi8vEAAAAQAx//MCCwKwACUAAAAWFhUUBgYjIic3FjMyNjY1NCYmIyIGFRQWMzI3FwYjIiY1NDYzAXxpJi97cC5dCEBDVVUbEkNHUUE/SDx3BH5QZWJufAKwSYx0gKBUD0MIRn1pYmU1R1JNQDBCOWxsd20AAAEAWAAAALkAYQADAAAzNTMVWGFhYQABAEH/jADPAMoADAAANhYVFAcHJzc2Nyc3F7McBk07MQwRRiMvsicXDw/KGH4gEBdhEAAAAgBYAAAAuQG3AAMABwAAEzMVIxUzFSNYYWFhYQG3YvRhAAIAQ/98ANABtgADABAAABMzFSMWFhUUBwcnNzY3JzcXWWFhXBsFTTswDhBGIy8BtmKyJxgQDcoYfiIOF2EQAAABAEkA6AF2ATsAAwAANzUhFUkBLehTUwABAEkAFAIOAeAACwAAATUzFTMVIxUjNSM1AQFSu7tSuAEkvLxQwMBQAAABADQBNAHqAwYAQAAAEiYmNTUzFRQGBgc+Ajc3FwcOAgceAhcXBycuAiceAhUVIzc0NjcOAgcHJzc+AjcuAicnNxceAhf4BwJCBAcCBhAQDXMgcw4VEgkIFhMNcyBzEA8PBgIJA0IBBAgGERANciJzDxIWCAgXEw1xH3MRDg8EAkoWEw+EhBIUFAcGEQ0HQjhDCAgEAgIFBwdCOkIJDREGBxgUEISEFxQYBhIMCEM5QgkHBQICBAgHQzhCCgwRBQABACgBPQHwApQABgAAASMDAyMTMwHwXYiFXrtOAT0BAP8AAVcAAAEAGAKZAbADJgAYAAAAJicmJiMiBgcnNjMyFhcWFjMyNjcXBgYjARIkFRIYFRoqEiw7SB0jEhAcFxsnFigXQicCmRQUEQ8dGyNaExMRERsdJSgwAAEASAAAAWwCxAADAAABIwMzAWxYzFcCxP08AAABACgACwHFAegABgAAARUFBRUlNQHF/r8BQf5jAehcj5Vdy0sAAAIASQBzAfwBgwADAAcAABM1IRUFNSEVSQGz/k0BswEyUVG/UlIAAQAoAAsBxgHoAAYAACUlNQUVBTUBaf6/AZ7+Yv2PXMdLy10AAgA7AAAAnAKvAAMABwAANyMDMwM1MxWKQA1eYGG9AfL9UWFhAAACADEAAAGrAq4AGgAeAAA2NTQ2Nz4CNTQmIyIHJzYzMhYVFAYHBgcVIwczFSOnNisHNxQ5SzVhD2VNbVsvPEkHRg5hYcgPKUYlBi8rHTk8FkMkaGA3TDA6Jzc6YQAAAQBDAc8AmgKyAAMAABMjJzOUTgNXAc/jAAACAEMBzwFJArIAAwAHAAATIyczFyMnM5ROA1eqTgRXAc/j4+MAAAIAYQAAApoCnAAbAB8AADcjNzM3IzczNzMHMzczBzMHIwczByMHIzcjByMBIwczyGcBbBBtBHEPTA+uD0wPbgN0EHABdRBLEbAQSwEgrhKwq06xTKampqZMsU6rq6sBqrEAAgBJ/zMDwALVADMAPwAABCY1NDYzMhYVFAYjIicGBiMiJjU0NjYzMhc1MxUVFBYWMzI2NTQmIyIGFRQWFjM3FwYGIxI3JjU1JiMiBhUUMwEm3eHl3dROYWMbMVQqWFMlV0wkSVkIICQ0IKO1urJLoIGPBSJeFQxbBzMyRDFczeHt6eva2oClPB4edX9cczkZD90lREAgfWC5qb7NhKZRCU0EBgEYKT1hhhJTYKwAAQBJ/4YB/AMkACsAABc3JzcWFhcWMzI2NTQmJicmJjU2FzczBxYWFwcnDgIHBhYXHgIVFAYjB9MOkAkiWhkYE0c/HUA7X2AC7BE2EhlbCwe2LjkgAgJQUkVMJnZxDXRrGUYDCQMDPzUgKBwPGFVWvQZ/gwMOA0kPAQ4qKC85FRQnQDZoZ28AAAUAJf/uAqACxAALABcAIwAvADMAABImNTQ2MzIWFRQGIzY2NTQmIyIGFRQWMwAmNTQ2MzIWFRQGIzY2NTQmIyIGFRQWMwMjAzNnQkJGRUJCRRoVFRsZFxYaAShCQkVFQkFGGhUUGhsWFhsbWMxXAX1PUlFPT1FST0wlMDElJjAwJf4lT1FST09SUk5LJDExJSYwMCUCi/08AAACAEP/9QLZAp8AKgA2AAAWJjU0NjcmJjU0NjYzMhcXByYmIyIGBhUUFjMzFSMiBhUUFjMyNjcXBgYjNiY1ETMRFBY3NxcHu3g/KCwvLl1KM1ZBBUdQJDQ4G0Yu1dQ+QklKKXAvJDt8LfJAWRYkWwJmC1xePV8PEk4tRlAiDQlDCAcQLy8vPEpJOjw1GRk6HyIBXFwBVf6sPTEBA0gHAAEARv+SAScDMAANAAA2Fhc3JiY1NDY3JwYGF0ZaUTZMOjpMNlBaAertay6Gt2RkuIUua+13AAEAMv+SARIDMAANAAAAJicHFhYVFAYHFzY2NQESW082TDs7TDZQWgHe6WkuhbhkZLeGLmvxegAAAQBX/6wBlgMXAB8AABYmNTU0Jic1MjY1JzQ2NjMyFxUjERQGBxYWFREzFQYj1CIuLS0vAQ0jITNgiy4nJy6LYDNUKznZJi0CRi4o2igpEgs//vMuLwICMCv+8T4LAAEAX/8lALcCygADAAAXETMRX1jbA6X8WwAAAQBU/6wBkwMXAB8AABYnNTMRNDY3JiY1ESM1NjMyFhYVBxQWMxUGBhUVFAYjtGCLLicnLotgMyEjDQEvLS0uIi9UCz4BDyswAgIvLgENPwsSKSjaKC5GAi0m2TkrAAEASP+sASwDFwAQAAAWJjURNDY2MzIXFSMRMxUGI2oiDSIhNGCMjGA0VCs5AqQoKRILP/0oPgsAAQAx//8BSwLEAAMAABMjExeIV8RWAsT9PAEAAAEAL/+sARQDFwAQAAAWJzUzESM1NjMyFhYHERQGI5BhjIxhMyEiDgEhL1QLPgLYPwsSKif9XDoqAAABACwB1gDEA1IADQAAEgYVFBYXNyYmNzY2NydvQyAZTB0RAwMgGzkDLKApJUoeMDE7GyFOOB4AAAEAKAHWAMADUgANAAASNjU0JicHFhYVFAYHF31DIBlMGBQiHToB/Z0qJUseMSo3FiFZPR0AAAIAKwHWAbIDUgANABsAABIGFRQWFzcmJjU0NjcnFgYVFBYXNyYmNTQ2NydvRCAZTRkUIxw51EQgGUwZEyMcOQMrnyklSR8wKzgXIVg7HiefKSVJHzAqNhchWjweAAACACsB1gGyA1IADQAbAAAANjU0JicHFhYVFAYHFyY2NTQmJwcWFhUUBgcXAW9DIBlMGBQiHTnTQx8ZTRgUIxw6AfufKiVLHjEqNxYhWT0dJp4qJUseMSk3FSJbPB0AAQBC/0MA2gC+AA8AADYGFRQWFzcmJjU0NzY2NyeGRB8ZTRgUAQMgGzmYniolSh4wKjYWCwYhTjgdAAIAKP9aAa8A1gANABsAADYGFRQWFzcmJjU0NjcnFgYVFBYXNyYmNTQ2NydrQyAZTBkTIxw500MfGU0ZEyMcOq+eKiRKHzEqNhYhWjweJ54qJUoeMSo2FiFaPB4AAQCEALgBKAFbAAMAACUjNTMBKKSkuKMAAQBJ/1sB9f+oAAMAABc1IRVJAaylTU0AAQBJAOYCPQEyAAMAADc1IRVJAfTmTEwAAQBJAOYEMQEyAAMAADc1IRVJA+jmTEwAAgBGAUsCRgJ5AAcAFAAAARUjFSM1IzUFNzMRIzUHIycVIxEzAQ5DPkcBcUJNOzwtOzxPAnk59PQ5xcX+0tXExNUBLgAEAEYAnwJbAsUADwATACMAPAAAJCYmNTQ2NjMyFhYVFAYGIwMzESMWNjY1NCYmIyIGBhUUFhYzNyM1MzI2NTQmIyM1MzIWFRQGBx4CFxcjAQZ7RUR6TUx5RUR4TGwvL6dkOTlkPj1kOTllPQ9WOx8WFh9bWTguFRgCDQoFPDCfSX5NTn1HSX5NTX1IAbH+xkg9aD8/aD0+aD0/aT3FJxciHhYpKjMmKQYBBQoIcAADAEYAnwJbAsUAEAAhADgAACQmJjU0NjYzMhYWFRQGBiMxPgI1NCYmIyIGBhUUFhYzMSYmNTQ2MzIXByYHIgYVFBYzMjc3FwYjAQZ7RUV6TU15Q0R5TDxkOTllPT9jODlkPUYwMDwsNgJLECkaGigRJiUCOCyfSX5NTn1HSn5MTX1ILz1oPz5pPT5pPT5pPUJVTU5TCCQFAT86OUACASQIAAACAEkAFwISAeEAHAArAAA2NTQ3JzcXNjMyFzcXBxYVFAcXBycGIyInBycxNxY2NjU0JiMiBhUUFxYzMXYaRz5HLDQwMEc9RxsbRz1HLzE1K0c+R7ozHkEsLEEgIyrGNTYrRz5HGxtHPkcuMzMsRz1IHR1JPkcMHjIcLEFBLCoiIAAAAwBJ/7ABoQJFABUAGQAdAAASNjMyFwcnIgYGFRQWFjM3FwYjIiY1ExUjNRMVIzVJVV8kgAKbJCsUFCskmwJwNF9V7FhYWAFsZwhEARk9Nzg9GQFEB2ZyAUqHh/3ug4MAAwBJAAAB3wKFAAUAFwAfAAAlFwchNSEDIzUzNTQ2MzIWFwcnJgYVESMSJiYnJzMVIwHQD1H+uwE86T4+P0wbXx0CjSUWWIwYFQcSp0xaSBJKARJKKVtbBQNEAgExPf4yAVwKDwQtSgAEAEYAAAJWArIACAAMABAAFAAAEzMTEzMDESMRNxUjNSEVIzUXFSE1RmOnpWHZWhPGAbzGxv5EArL+xAE8/m7+4AEgYktLS0ueS0sAAQBJANQB9wEkAAMAABMhFSFJAa7+UgEkUAACAEkAIgINAe4ACwAPAAABNTMVMxUjFSM1IzURNSEVAQJRurpRuQHEAXV5eVF5eVH+rVBQAAABAEkALAHsAc8ACwAAJQcnByc3JzcXNxcHAew5l5o5mpo5mpc5mWU5mpo5mJk5mZk5mQAAAwBJAG0BqQJDAAMABwALAAATNTMVBzUhFQc1MxXEauUBYOVqAdhra6lTU8JsbAAAAgBf/yUAtwLKAAMABwAAExEzEQMRMxFfWFhYAVQBdv6K/dEBev6GAAMATQAAAqAAbwADAAcACwAAJTMVIyczFSMlMxUjAUtWVv5XVwH9VlZvb29vb28AAAEATQDlAKQBVAADAAA3NTMVTVflb28AAAIARP9DAK0B9AADAAcAABMzFSMTIxMzRGlpY14HUAH0cP2/AckAAgBKAAABxgLAAB8AIwAAABYVFAYHDgIVFBYWMzI3FwYGIyImNTQ2Njc2NjU1MzcVIzUBTgU9KyIbDB40LDplBz1PJG1fFSgpKSpJCmECCSYPJVQlHB0gGzUzDx1FEhFeZCs5LCMiNR4lsWFhAAACAEYBngFnArsACwAXAAASJjU0NjMyFhUUBiM2NjU0JiMiBhUUFjOVT1A/QFJSQCkxMSkmMC8nAZ5OQT9PTz9ATzUyKCgxMicpMQAAAQBKAAABjAKWAAMAAAEjAzMBjFnpWAKW/WoAAAEARgAAAksCsQASAAASJiY1NDY2MyEVIxEjESMRIxEjzFUxMFY2AUlAT2ZPBwE7Mlc0NVQwTP2bAmX9mwE7AAACAGL/ZAHHAl8AIQBEAAAWJic3FjMyNjU0JicnJiY1NDY3Fw4CBwYWFxcWFhUUBiMSFhcHJiMiBgYVFBYXFxYWFRQGByc2NjU0JicnJiY1NDY2M/VmIQRcPzMuFyRkOzIjFUECEw0BAhslYTwzWmQsZiEDW0UkJBUXJGQ7MiQWRhMUFyRhPDMmUkacDgdDDh0tGx0MHxM+NydkGyUEJjQfGyIMHhM9OEtJAvsOB0MOCB8jGx0MHxM+NydjHRcnOy4bHgsfEz04OUAbAAABAEb/tQHkArEACwAAEzUzFTMVIwMjAyM16VijowZNBaMB9L29Tf4OAfJNAAEARv+1AeQCsQAUAAA3MzUjNTM1MxUzFSMVMxUjFSM1IzFGo6OjWaGhoqJZo77pTb29TelLvr4AAQBmAT8CUQHfABkAAAAmJyYmIyIGByc2NjMyFhcWFjMyNjcXBgYjAZ4xIRsjESAsGDMRVTMfMyEdHhAfMBcuD1Q2AT8YFxMTICEnJz4aFxMQHiAoKDoAAAEATABYAW8CBAAGAAAlJzcnBRUFAW/IyBX+8gEOn4yRSLBSqgAAAQA4AFgBWwIEAAYAAAE1JQcXBxcBW/7yFcnJFQECUrBIkYxHAAAB/3gCvACIA3EADAAAAhc2NxUGBhUjNCYnNQYFBoM4NDg0OANuZWUDQAQyPz8yBEAAAAH/eAK8AIgDcQAMAAACNjUzFBYXFSYnBgc1UDQ4NDiDBgWCAwAyPz8yBEADZWUDQAD//wAYAAACTwODBCIABAAAAAYCxToT//8AGAAAAk8DdwQiAAQAAAAGAslHRf//ABgAAAJPA28EIgAEAAAABgLHOkP//wAYAAACTwMxBCIABAAAAAYCwgYT//8AGAAAAk8DggQiAAQAAAAGAsTUD///ABgAAAJPAyoEIgAEAAAABgLMV0UAAwAY/yACUQK/AAYACgAZAAABMxMjAwMjEzMXIQAmNTQ3FwYGFRQWMzMVIwEEX+xZwsRYqeYZ/uYBL0CVJUA7Ih88RwK//UECTP20AQRK/mY1LmA6HRs6IRkdNP//ABgAAAJPA44EIgAEAAAABgLK+Q///wAYAAACTwN2BCIABAAAAAYCywcPAAQAGAAAA08CvwAEAAkADQAZAAABJzMzFyUzFwMjEzMXIQEhFSEVIRUhFSERIQFCDi+8Av7jMA7SWKnzGf7ZAqD+twEW/uoBUv5WAaECdUpKSkr9iwEMSgGz7Ur0SgK///8AOv/2AfcDhQQiAAYAAAAGAsU9Ff//ADr/9gH3A3gEIgAGAAAABgLIOksAAwA6/ygB9wLHABsALAAwAAAWJjU0NjMyFwciJyYjIgYGFRQWFjMyNzYzFwYjBzMyNjU0JiMjNzYWFRQGIyM3MwcjoGZng1d8BQoeZDdDRRUVRUM3ZB4KBYFTFi4SFRUSEREoMzEpPRg7FzoKt7KxtxBCAgZNeVhZeU0GAkMPnRQTERQyATEnKDDYW///ADr/9gH3A0EEIgAGAAAABgLD+CMAAwBSAAACnwK/AAgAEgAWAAATITIWFwYGIyEkNjY1NCYjIxEzASEVIaUBA4ZvAgJvhf78ATxJGElenp/+tgEZ/ucCv7Cwr7BLTn9beIr91QE7SgD//wBTAAACTQNyBCIABwAAAAYCyChF//8AUgAAAp8CvwQCAJMAAP//AFQAAAH9A38EIgAIAAAABgLFFA///wBUAAAB/QNyBCIACAAAAAYCyCpF//8AVAAAAf0DcgQiAAgAAAAGAsctRv//AFQAAAH9Ay0EIgAIAAAABgLC/w///wBUAAAB/QMtBCIACAAAAAYCwwAP//8AVAAAAf0DggQiAAgAAAAGAsQAD///AFQAAAH9AysEIgAIAAAABgLMU0YAAgBU/yAB/wK/AAsAGgAAASEVIRUhFSEVIREhAiY1NDcXBgYVFBYzMxUjAfT+twEW/uoBUv5XAaBxQJUlQDsiHzxHAnTsSvRKAr/8YTUuYDodGzohGR00AAIALP/9AkYCrgAgACcAABYmJjU0NjMzMhYVFAcnNCYmIyMiBhUUFhYzMjY3FwYGIwMhFyInJiPFZzKFgSp5cQVYHj0yJVFVHj47QZkpB1Z+Q5wBtA6/qCoxAz6Ugq6vnJk6ITFqdzB/kHJwJAoGRgwMAWRIAgEA//8ANv/1AiADdgQiAAoAAAAGAslCRP//ADb+ngIgAscEIgAKAAAABwLOALz/2///ADb/9QIgA0AEIgAKAAAABgLDBiIAAgA1AAACaQK/AAsADwAAEzMRIREzESMRIREjAzUhFVFYAUxYWP60WBwCNAK//scBOf1BATz+xAIMTU3//wBTAAABAwN/BCIADAAAAAYCxYEP////2QAAAS4DcQQiAAwAAAAGAseQRf//ABsAAADlAzEEIgAMAAAABwLC/1QAE///AFMAAACrAzcEIgAMAAAABwLD/1QAGf///70AAACrA4oEIgAMAAAABwLE/ucAF/////EAAAENAy4EIgAMAAAABgLMqEkAAv/y/yAArgK/AAMAEgAAMyMRMwImNTQ3FwYGFRQWMzMVI6tYWHlAlSVAOyIfPEcCv/xhNS5gOh0bOiEZHTQA//8AU/6bAkMCvwQiAA4AAAAHAs4ArP/Y//8AUwAAAcEDgwQiAA8AAAAGAsWFE////9cAAAHBA3EEIgAPAAAABgLIjkT//wBT/pEBwQK/BCIADwAAAAcCzgCB/84AAgAMAAABzwK/AAUACQAAEzMRIRUhEwcnN2FYARb+krjeL9gCv/2LSgHstDm3//8AUwAAAjoDfwQiABEAAAAGAsVLD///AFMAAAI6A28EIgARAAAABgLIUUL//wBT/pECOgK/BCIAEQAAAAcCzgDT/87//wBTAAACOgN2BCIAEQAAAAYCyxgPAAIAU/9CAjoCvwAJABAAABMzAREzESMBESMENRcUBgcnU40BAliO/v9YAZBXMS0xAr/9iwJ1/UECcv2OSGQYPWQhMwD//wA1//UCcgODBCIAEgAAAAYCxVsT//8ANf/1AnIDbgQiABIAAAAGAsdgQv//ADX/9QJyAzEEIgASAAAABgLCJRP//wA1//UCcgOGBCIAEgAAAAYCxAAT//8ANf/1AnIDeAQiABIAAAAHAsYAhgBL//8ANf/1AnIDNAQiABIAAAAHAswAgwBPAAMANf/eAnIC4wAMABkAHQAAFiY1NDYzMhYVFAYGIz4CNTQmIyIGFRQWMwcBFwG0f3+goH4vfXJSVx1UcnJVVXL2AbVB/ksLvqyrvr6rcp1bSk58VoKdnYKCnjcC2yr9JQD//wA1//UCcgN2BCIAEgAAAAYCyygPAAMANf/1A8UCxwANABoAJgAAFiY1NDYzMhYWFRQGBiM+AjU0JiMiBhUUFjMBIRUhFSEVIRUhESG0f36haXQsKHRtUlcdVHJyVVZxAmj+twEW/uoBUv5WAaELwKitvVudcnGbXEpPfFODnZ2DfqACNexK9EoCvwACAFMAAAIxApgADAAUAAATMxUzMhYVFAYjIxUjJDU0JiMjETNTWKdwb3Jtp1gBhEBGpqYCmFF3bW99d8GkTkr+xP//AFMAAAJeA4MEIgAVAAAABgLFABP//wBTAAACXgNyBCIAFQAAAAYCyBpF//8AU/6RAl4CvwQiABUAAAAHAs4Axv/O//8AMP/zAf4DgwQiABYAAAAGAsUIE///ADD/8wH+A3wEIgAWAAAABgLIH08AAwAw/ycB/gLHACgAOQA9AAAWJic3FhYzMjY2NTQmJycmJjU0NjMyFwcnJiMiBgYVFBYXFxYWFRQGIwczMjY1NCYjIzc2FhUUBiMjNzMHI/WZLAM+eiI0QCUnNY1MQGRsRJIGJ1oyMT4mKTWHUEBkehouEhUVEhERKDMxKT0YOxc6DREKQgkJDzU2MDAQLRlSSl9eD0MCBg8yMi4yESoZUkxgZZsUExEUMgExJygw2FsA//8AMP6RAf4CxwQiABYAAAAHAs4Amf/OAAMASv/2AjYCpwAZAB0AJAAABCc1FjMyNjY1NCYmJyYnNxYXFhcWFhUUBiMBMxEjEzchNSEXBwEaQ0IdMz0pEikoM0ZRCxs2B0s2Y3v/AFhYqev+pQGdFu0KCEYDCzM2HSYgFh02JQYSIwQrUTZbZAKx/VkBgdxKRP8AAgAlAAACKwK/AAcACwAAEyM1IRUnESMDNSEV/dgCBtZYiAFlAnVKSwH9iwF7TEz//wAPAAACFQNyBCIAFwAAAAYCyCJF//8AD/8oAhUCvwQiABcAAAACAs/lAP//AA/+kQIVAr8EIgAXAAAABwLOAJ3/zv//AE7/9QJJA4MEIgAYAAAABgLFQhP//wBO//UCSQN5BCIAGAAAAAYCx1pN//8ATv/1AkkDMQQiABgAAAAGAsIUE///AE7/9QJJA4YEIgAYAAAABgLEABP//wBO//UCSQN6BCIAGAAAAAYCxmtN//8ATv/1AkkDLwQiABgAAAAGAsx3SgACAE7/LAJJAr8AEQAgAAAWJjURMxEUFjMyNjURMxEUBiMWJjU0NxcGBhUUFjMzFSPBc1lIXF1IWXSKDECVJUA7Ih88RwuJhAG9/jheWlpeAcj+Q4SJyTUuYDodGzohGR00//8ATv/1AkkDkgQiABgAAAAGAsodE///AB0AAAN2A38EIgAaAAAABwLFAM0AD///AB0AAAN2A2kEIgAaAAAABwLHAN4APf//AB0AAAN2Ay0EIgAaAAAABwLCAKUAD///AB0AAAN2A4IEIgAaAAAABgLEZw///wATAAACIwODBCIAHAAAAAYCxS4T//8AEwAAAiMDcwQiABwAAAAGAsceR///ABMAAAIjAzUEIgAcAAAABgLCABf//wATAAACIwOGBCIAHAAAAAYCxLkT//8AKP//Ae0DgwQiAB0AAAAGAsUAE///ACj//wHtA3wEIgAdAAAABgLIFk///wAo//8B7QM1BCIAHQAAAAYCw+sX//8AJ//0AZ4C0QQiAB4AAAAHAsX/7v9h//8AJ//0AZ4CxwQiAB4AAAAGAskAlf//ACf/9AGeAr4EIgAeAAAABgLH95L//wAn//QBngJ9BCIAHgAAAAcCwv/H/1///wAn//QBngLWBCIAHgAAAAcCxP+Y/2P//wAn//QBngJ9BCIAHgAAAAYCzCSYAAMAJ/8gAaECCgAgAC0APAAAFiMiJjU1NDYzMzU0JiMiBwYjJzY3NjMyFhURIzUGBgcHNjc1IyIGFRUUFjMyNxImNTQ3FwYGFRQWMzMVI7IQOUJOQ44hLDtUCxUCMxtQEVdQWAwZHEFEPpEaIB4ZCgVkQJUlQDsiHzxHDEo6SEFOGC4qAgFDBAEGSln+mR0KCwUMUwy3Hx1fFh8B/uI1LmA6HRs6IRkdNAD//wAn//QBngLfBCIAHgAAAAcCyv++/2D//wAn//QBxALEBCIAHgAAAAcCy//M/10ABAAn//QC9AIOACAALQBLAE8AABYjIiY1NTQ2MzM1NCYjIgcGIyc3NjYzMhYVESM1BgYHBzY3NSMiBhUVFBYzMjcWJjU0NjMzMhYVFAcnNCYjIyIGFRQWFjMyNxcGBiMDIRchshA5Qk5DjiEsO1QLFQJPFTkOVkhLDBkcQUQ+kRogHhkKBf1kZmQQYl4DUDY3Ej1GIEA3U1gHOlgynQFXE/6WDEo6SEFOGC4qAgFDBgEESVr+kyMKCwUMUwy3Hx1fFh8BRH+Ggo2NfCUPJ2tjX2hQUx0LQAgIARhB//8AMP/3AYgC0gQiACAAAAAHAsX/5v9i//8AMP/3AZECwwQiACAAAAAGAsjzlgADADD/KAGIAgkAFQAmACoAABI2MzIXByYjIgYVFBYzMjcXBiMiJjUTMzI2NTQmIyM3NhYVFAYjIzczByMwVF83bgJAWzUuLjVKUQJuN19UsS4SFRUSEREoMzEpPRg7FzoBjXwJRAJVaWlVA0UJfI3+WRQTERQyATEnKDDYW///ADD/9wGIAoEEIgAgAAAABwLD/7b/YwACADH/8wILAu0AAwAoAAABByc3AiY1NDMyFwcmIyIGFRQWMzI2NjU0JicmJic3FhYXFhYVFAYGIwHnwUm1827HUnwEdD9HQEFRR0MSFiEhZmQaen0qIhomaWECqacesv0hbXfXOEMxQUxSSDVlY2B5IyQ3HT8dPTosjWR0jEkA//8AL//6Ac4DOAQiACEAAAAGAsgACwADAC//+gIXAuYAGAAcACAAABYmNTQ2MzIXByYmIyIGFRQWMzI2NxcGBiMTMxEHAzUhFYNUVF8sbQEQZRs0Ly80JmgkMjWbHJRYWMQBZQZ8jI18E0MDCVZpaFYEAkMECQLs/SEFAl04OAD//wAv//oB3QLPBCIAIgAAAAcCxQAE/1///wAv//oB3QLBBCIAIgAAAAYCyCKU//8AL//6Ad0CsgQiACIAAAAGAschhv//AC//+gHdAn0EIgAiAAAABwLC/+j/X///AC//+gHdAoYEIgAiAAAABwLD/+T/aP//AC//+gHdAtEEIgAiAAAABwLE/7//Xv//AC//+gHdAnkEIgAiAAAABgLMPZQAAwAv/yoB3QIOAB0AIQAwAAAWJjU0NjMzMhYVFAYVJzQmIyMiBhUUFhYzMjcXBiMDIRchEiY1NDcXBgYVFBYzMxUjoHFyZxViXgJQNjgSPUYgQDhSWAd0VZgBWBP+lehAlSVAOyIfPEcGgYSAj418Ex4DJ2tjX2hQUx0LQBABGEH+WTUuYDodGzohGR00AAIAKv/6AdgCDgAcACAAAAAWFRQGIyMiJjU0NxcUFjMzMjY1NCYmIyIHJzYzEyEnIQFocHJmFmJeA1A2NxI9RiBAN1NYB29bl/6pEwFqAg6BhX+PjHwlDyZsY19oUFMdC0AR/udB//8AMP7fAfcDAAQiACQAAAAGAskFzv//ADD+3wH3A30EIgAkAAAABgLNWKH//wAw/t8B9wKkBCIAJAAAAAcCw//D/2gAAwAjAAAB6QLbABQAGAAcAAAAJiMiBwc3NjY3NzY3NjMyFhURIxEBMxEjAzUhFQGRIiAFDqIBBBwaLCwFEhFDUVj+uFhYJgFlAZspAh5EAgwFCAgCA1hC/ooBeQFi/SUCXzg4AAEASQAAAKEB9AADAAATMxEjSVhYAfT+DAAAAgBJAAAA/AK2AAMABwAAEzMRIxMHIzdJWFizXz1MAfT+DAK2mJgAAAL/0AAAASUCqQADAAoAABMzESMTByM3MxcjTVlZLWFJfFx9SQH0/gwCfFSBgQADABUAAADfAm4AAwAHAAsAABMzESMDMxUjNzMVI05YWDlKSoBKSgH0/gwCbkZGRgACAEcAAACfAnUAAwAHAAATMxEjEzMVI0dYWAtKSgH0/gwCdUYAAAIAAAAAAKoCvwADAAcAABMzESMTIyczUlhYSj1fUAH0/gwCJ5gAAv/mAAABAgJiAAMABwAAEzMRIxMhNSFHWFi7/uQBHAH0/gwCKTkAAAP/6P8gAKQCoQADAAcAFgAAEzMRIxEzFSMCJjU0NxcGBhUUFjMzFSNJWFhYWCFAlSVAOyIfPEcCBP38AqFR/NA1LmA6HRs6IRkdNP//AEn+kQHoAsYEIgAoAAAABwLOAI7/zv//AEoAAADxA9IEIgApAAAABwLF/28AYv///8sAAAEgA7sEIgApAAAABwLI/4IAjv//ADX+kQDDAwkEIgApAAAABgLO9M4AAv/tAAAA+wMJAAMABwAAExEjERMHJzehV7HeMNgDCfz3Awn+47Q5twD//wBJAAAB6QLZBCIAKwAAAAcCxQAo/2n//wBJAAAB6QLEBCIAKwAAAAYCyDKX//8ASf6RAekCFwQiACsAAAAHAs4Aif/O//8ASQAAAekC0QQiACsAAAAHAsv/6f9qAAMASf89AekCFwAVABkAIgAAACYjIgcHNzY3Njc2Njc2MzIWFREjESUzESMENTUzFRQGBycBkSIgBQ6iAQwuERYQHQkSEUNRWP64WFgBSFgwLjABmykCHkMMCAQDAwYCA1hC/osBeJ796U5kRl09ZCEz//8AMP/yAeQC0wQiACwAAAAHAsUAAv9j//8AMP/yAeQCpAQiACwAAAAHAscAE/94//8AMP/yAeQCdAQiACwAAAAHAsL/1f9W//8AMP/yAeQCzgQiACwAAAAHAsT/sf9b//8AMP/yAgICtgQiACwAAAAGAsZAif//ADD/8gHkAnIEIgAsAAAABgLMMo0AAwAw/9cB5AIXAA8AIQAlAAAWJiY1NDY2MzIWFhUUBgYjPgI1NTQmJiMiBgYVFRQWFjMHARcBuF0rK11RSl8yMl9KMzgXFzgzMjgXFzcztgFFNP66DzBwZWVxLy1yZmVyLksbQjxDPEIcHEI8QzxBHEgCIx393QD//wAw//IB5gK8BCIALAAAAAcCy//u/1UABAAw//IDOAIOAA8AIQA9AEEAABYmJjU0NjYzMhYWFRQGBiM+AjU1NCYmIyIGBhUVFBYWMxYRNDYzMzIWFRQHJzQmIyMiBhUUFhYzMjcXBiMDIRchuF4qKl5RR1gtLVhHMzgXFzgzMjgXFzgykGhiFWJeAlA2NxI9RiBAN1JYCHVVlwFXE/6WDjBzaGhzMC50aWl0LkoeRD1DPUUeHkU9Qz1EHkIBBYGOjXwqCidrY19oUFMdC0AQARhBAAACAEj/nwHnAokAGgAeAAAEJic3FhYzMjY1NCYmIyIGByc2NjMyFhUUBiMDMxEjARaCDA4Vahc0LxQrJBxfIRVDUiVeVFRe7VlZBwoDRAIFVWdIVCQNBz0REX2Oi3sCkP0W//8ASQAAAXIC1gQiAC8AAAAHAsX/rf9m//8ADgAAAXICuAQiAC8AAAAGAsjFi///ADv+kQFyAhIEIgAvAAAABgLO+s7//wAu//UBigLUBCIAMAAAAAcCxf/T/2T//wAu//UBigK9BCIAMAAAAAYCyOaQAAMALv8iAYoCCgAkADUAOQAAFiYnNxYWMzI2NTQmJycmJjU0MzIXByYjIgYVFBYXFxYWFRQGIwczMjY1NCYjIzc2FhUUBiMjNzMHI8F9FQQsah4kJxQhZTkxnj9hAT5cKCMYKFc8MVRTJi4SFRUSEREoMzEpPRg7FzoLDgZDBgcfJSQgCh4SQTeRCUMCHikZIwsbE0I7T0OiFBMRFDIBMScoMNhbAP//AC7+kQGKAgoEIgAwAAAABgLOUc4AAQBIAAACMwK+ACwAABI2NjMzMhYVFAYHFhYVFAYjIiYnNxYzMjY1NCYjIzUzMjY1NCYjIyIGFRMjEUgxWDcraGUsK0ZEbWk3RwkHSzRDO0U/fF46NTZAITFAAVgCNVcyUllATRMIYElfYwcBSQc3P0FASj08PTVAMf37Af4AAwAe/+4BYwLGABAAFgAaAAAWJjURIzUzNTMRFBYzNxcGIwInJzMVIwc1IRWuP1FRWBUlYAJKICAiAqdM8gE+EltbAR9LuP3fPTACQwkB1Qw/S6hISP////H/7gFjA3kEIgAxAAAABgLIqEwABAAe/x8BYwLGABAAFgAnACsAABYmNREjNTM1MxEUFjM3FwYjAicnMxUjAzMyNjU0JiMjNzYWFRQGIyM3Mwcjrj9RUVgVJWACSiAgIgKnTFIuEhUVEhERKDMxKT0YOxc6EltbAR9LuP3fPTACQwkB1Qw/S/2NFBMRFDIBMScoMNhb//8AHv6RAWMCxgQiADEAAAAGAs4yzv//AED/8gHfAuQEIgAyAAAABwLFAAv/dP//AED/8gHfArUEIgAyAAAABgLHHIn//wBA//IB3wJ1BCIAMgAAAAcCwv/u/1f//wBA//IB3wLQBCIAMgAAAAcCxP++/13//wBA//ICBQK8BCIAMgAAAAYCxkOP//8AQP/yAd8CdwQiADIAAAAGAsw4kgADAED/GgHiAgIAEgAWACUAABYjIiY1ETMRFBYzMjc3BwYHBgcTMxEjBiY1NDcXBgYVFBYzMxUj5RFDUVgjIAUOogEOLA1RkFhYIUCVJUA7Ih88Rw5XQgF1/oojKgIfQwwIAw8CDf344DUuYDodGzohGR00//8AQP/yAd8C1AQiADIAAAAHAsr/3/9V//8AGAAAApwCxQQiADQAAAAHAsUAYP9V//8AGAAAApwCrAQiADQAAAAGAsdngP//ABgAAAKcAm0EIgA0AAAABwLCAC7/T///ABgAAAKcAr4EIgA0AAAABwLE//z/S///ABj/JgG0AtsEIgA2AAAABwLF/9f/a///ABj/JgG0ArcEIgA2AAAABgLH84v//wAY/yYBtAKFBCIANgAAAAcCwv+3/2f//wAo//wBnQLYBCIANwAAAAcCxf/i/2j//wAo//wBnQK9BCIANwAAAAYCyPiQ//8AKP/8AZ0CfAQiADcAAAAHAsP/s/9eAAEAQf/yAbABiAAWAAA2NTQ2NzcXBwYGFRQXFzcXBSc3JiYnJ2gsJGYeZw8SBiKzIf6xIGIGDgQUzx0mPA8rRy0HGRALDkldQqtDMQQSCygAAQBHAAAAkgKWAAMAABMzESNHS0sClv1qAAABAEgAAAEWApYAEQAAMiYmNREzERQWMzMyFhUVFCMjuUgpSycdMQYIDiQpSCoB+/4HHSgJBjsOAAL/5QAAAPcDnwADABkAABMRIxEmNTQ2NzcXBwYGFRQXFzcXByc3JicnjksxIxw7FjsNDQQZdRj6GGARBw8CR/25AkfUGBwsDBgzGgYVDQoIMzwvgC8xBw4fAAL/7gAAARwDogASACgAADImJjURMxEUFjMzMhYVFRQGIyMCNTQ2NzcXBwYGFRQXFzcXByc3JicnuUcpSycdNgUJBwcqySIdOxY7DA4EGXUY+hhgEQcPKkcrAaz+VR0oCQY7BggDHhkcKwwYMxoFFgwLCDM8L4AvMQcOH/////D+qAECApYEJgKsedUAAgE2AAD//wAA/qgBFgKWBCcCrACJ/9UAAgE3AAAAAv/vAAABFALVAAMADwAAEzMRIwI2MzMVIyIGFRUjNWxLS3wpJdbYCgs4Akf9uQKoLUELCiEoAAAC/+8AAAE3AuQAEQAdAAAyJiY1ETMRFBYzMzIWFRUUIyMANjMzFSMiBhUVIzXaRypLJxwyBggOJP7rKSXW2AoLOCpHKgGs/lYdKAkGOw4Cty1BCwohKAAAA//VAAABaAN1AAMAEAAtAAATMxEjEjY1NTQmIyMiBgcHMwYmJwYjIzUzMjY1NTMVFBc3NjYzMzIWFRUUBiMjgUtLphESDiEOHgtCncEfDBkpGB0PFDEKVhEuFxkjMDEioQJH/bkC5hILGw4SDAtBORATIzkVDiYaEQpVEhQxIyAiMgAAA//JAAABXAN1ABIAHwA8AAAyJiY1ETMRFBYzMzIWFRUUBiMjEjY1NTQmIyMiBgcHMwYmJwYjIzUzMjY1NTMVFBc3NjYzMzIWFRUUBiMj0EcqSycdSQUJBwc8IBESDiEOHgtCncEfDBkpGB0PFDEKVhEuFxkjMDEioSpHKgGu/lQdKAkGOwYIAuYSCxsOEgwLQTkQEyM5FQ4mGhEKVRIUMSMgIjIAAAEARwAAAxYBWAAVAAAyJiY1NTMVFBYzITI2NTUzFRQGBiMhzFMySzspAZAeJ0sqSCv+hDFUMaKcKTsoHbu6K0grAAEARwAAA4gBWAAgAAA2FjMhMjY1NTMVFBYzMzIVFRQjIyInBgYjISImJjU1MxWSOykBkR4nSyodHA4OEEotFj4l/oMxVDFLkzsoHZ6eHSgOPA5BICExVDGinAAAAf/yAAABbAE3ACAAACI1NTQ2MzMyNjc3FwcGFRQWMzMyFhUVFCMjIiYnBgYjIw4IBkMhJQYgSRoBJB4/BggOQCU5DQ9BI0AOOwYJIRyiDYcFCRsiCQY7DiEgHSQAAAH/8gAAAPcBWAARAAAiNTU0NjMzMjY1NTMVFAYGIyMOCAZnHidLKkgqWw47BgkoHrq6K0grAAH/8gAAAQ8BVwARAAAiNTU0NjMzMjY1NTMVFAYGIyMOCAaAHClKKkgqcw47BgkpHLq7KkgqAAH/8gAAAVcBVwARAAAiNTU0NjMzMjY1NTMVFAYGIyMOCAbIHShKKkgquw47BgkoHLu7KkgqAAH/8gAAAaEBVwARAAAiNTU0NjMhMjY1NTMVFAYGIyEOCAYBEh0oSipHK/77DjsGCScdu7sqSCr//wBH/y4DFgFYBCIBQAAAAAcCmgGD/4j//wBH/y4DiAFYBCIBQQAAAAcCmgGD/4j////y/y4BbAE3BCIBQgAAAAcCmgCC/4j////y/y4A9wFYBCIBQwAAAAYCmhSI////8v8uAVcBVwQiAUUAAAAGApoUiP//AEf+sQMWAVgEIgFAAAAABwKhAT3/iP//AEf+sQOIAVgEIgFBAAAABwKhAUv/iP////L+sQFsATcEIgFCAAAABgKhP4j////y/rEBDwFXBCIBRAAAAAYCoRSI////8v6xAVcBVwQiAUUAAAAGAqE9iP////L+sQGhAVcEIgFGAAAABgKhQ4j//wBHAAADFgGyBCIBQAAAAAcCngE+AVn//wBHAAADiAGyBCIBQQAAAAcCngE+AVn////yAAABbAICBCIBQgAAAAcCngBDAan////yAAABDwIjBCIBRAAAAAcCngAqAcr////yAAABVwIiBCIBRQAAAAcCngBVAckAA//yAAABgwIiABEAFQAZAAAiNTU0NjMzMjY1NTMVFAYGIyMTMxUjJzMVIw4IBvMdKUoqSCrnwlhYjVhYDjsGCSgcu7sqSCoCIllZWQD//wBHAAADFgIvBCIBQAAAAAcCogE8AVj//wBHAAADiAIvBCIBQQAAAAcCogE8AVj////yAAABbAJ/BCIBQgAAAAcCogA6Aaj////yAAABDwKiBCIBRAAAAAcCogApAcv////yAAABVwKiBCIBRQAAAAcCogByAcsABP/yAAABWwKhABEAFQAZAB0AACI1NTQ2MzMyNjU1MxUUBgYjIxMzFSMHMxUjNzMVIw4IBswdKEoqSCq/Z1lZRlhYjVhYDjsGCScdu7sqSCoCoVklWVlZ//8ARwAAAxYCWwQnApgBy/5SAAIBQAAA//8ARwAAA4gCWgQnApgB0P5RAAIBQQAA////8gAAAWwCfQQnApgAs/50AAIBQgAA////8gAAASECnwQnApgAjf6WAAIBQwAA//8ASP67AmEBnQQiAWoAAAAHApoBY//3//8ASP67AsEBnQQiAWsAAAAHApoBNf/x////8v8vArsBhgQiAWwAAAAHApoBEv+J////8v8vAmsBhgQiAW0AAAAHApoBEv+JAAQASP67AmEBnQAqAC4AMgA2AAA2NzY3NjcnJiMiBgcHJzc2NjMyFwUHJyYjIgYHBwYGFRQWFjMzFSMiJiY1JTMVIwczFSMnMxUjVWNFeyULzQgEDhkEGkIYC0IoFQ4BaRUvFAgMFxTlHSEsSy3u7kJxQwFmTEw7TEw9TEwiSTNYGQY+AhIOUhJRJzAFbUgNBQwPphVDJitLLVhBb0JzTRVNr00ABABI/rsCwQGdAAMABwALAEYAAAUzFSMHMxUjJzMVIxYmJjU0Nzc2NycmIyIGBwcnNzY2MzIXBQcnJiMiBgcVFBYzMzIWFRUUIyMiJiY1NQcGBhUUFhYzMxUjAXBGRjhGRjlHRwpxQ2PAJwnNBAkOGAQaQhcLRCkPEgFpFS8SCgoRECYbnAYIDownQSa0HiAsSy3u7gpHFUejR/RBb0J1SYsbBD0CEQ5SElEmMQVtRwwFCQtIGyYIBzsOIz4lL4EWQiYrSy1YAP////L+sQK7AYYEIgFsAAAABwKhAMf/iP////L+sQJrAYYEIgFtAAAABwKhAMf/iAABAEj+uwJhAZ0AKgAANjc2NzY3JyYjIgYHByc3NjYzMhcFBycmIyIGBwcGBhUUFhYzMxUjIiYmNVVjRXslC80IBA4ZBBpCGAtCKBUOAWkVLxQIDBcU5R0hLEst7u5CcUMiSTNYGQY+AhIOUhJRJzAFbUgNBQwPphVDJitLLVhBb0IAAQBI/rsCwQGdADoAAAAmJjU0Nzc2NycmIyIGBwcnNzY2MzIXBQcnJiMiBgcVFBYzMzIWFRUUIyMiJiY1NQcGBhUUFhYzMxUjAQlxQ2PAJwnNBAkOGAQaQhcLRCkPEgFpFS8SCgoRECYbnAYIDownQSa0HiAsSy3u7v67QW9CdUmLGwQ9AhEOUhJRJjEFbUcMBQkLSBsmCAc7DiM+JS+BFkImK0stWAAAAf/yAAACuwGGADgAACI1NTQ2MzMyNjc3NjcnJiMiBgcHJzc2NjMyFwUHJyYjIgYHFRQWMzMyFhUVFCMjIiYnNCcHBgYjIw4IBqU1SypLFgjuCAUOGAQcQBcMQygQEgGEFSsSCwsTECUbjQYIDnk0TAoCRiZmOpwOPAUJGCdFFAVGAhEOUhFRKDAFdUYMBgoNKBsmCAc7Dj8wDgo8JiUAAAH/8gAAAmsBhgAnAAAiNTU0NjMzMjY3NzY3JyYjIgYHByc3NjYzMhcFBycmIyIGBwcGBiMjDggGpTVLKkkVC+4IBA8YBBxAFwxCKA8UAYQVKRIMDRcVdCdmOZwOPAUJGCdCFQdGAhIOURFRKDAFdUYMBg4TbCUm//8ASP67AmECdgQiAWoAAAAHApkApgId//8ASP67AsECdgQiAWsAAAAHApkAqgId////8gAAArsCXQQiAWwAAAAHApkAjgIE////8gAAAmsCXQQiAW0AAAAHApkAjQIEAAEASAAAAeoByAAYAAAyJjU1MxUUFjMzMjY1NCcnNxcWFRQGBiMjikJAExOdJyoMcT90GClKL5FCLm1dEhYuIRoVyijNKjArSiwAAQBIAAACVAHkACIAACQWFRUUIyMiJicGBiMjIiY1NTMVFBYzMzI2NTQnAzcTFjMzAkwIDhInQhMORCeJLUE/FRKSIjADTEhbEzYXWAkGOw4sJycsQS5uWxIYMCEKCQEQGP65RQD//wBIAAAB6gKWBCIBcgAAAAcCmQDjAj3//wBIAAACVAKwBCIBcwAAAAcCmQEpAlf//wBIAAAB6gMlBCcCmAFL/xwAAgFyAAD//wBIAAACVANEBCcCmAFu/zsAAgFzAAAAAf/Y/wgA/QE7AAoAAAc3NjURMxEUBgcHKHdjS1FGd7EnIWMBQf7GTWsZKAAB/97/DgC7ATsACwAABzc2NjURMxEUBgcHIkEpKEs6PUOwIhU7PwE6/sxVXiElAAAB/9j/CQF1ATwAGQAABzc2NREzFRQWMzMyFhUVFCMjIiYnFRQGBwcod2NLKhwkCAYOGBkrDlJFd7EnIWQBQaIbJwYIPA4UFDJIZRgoAAAB/97/DgEyATsAGwAABzc2NjURMxUUFjMzMhYVFRQGIyMiJicVFAYHByJBKShLKhwjCAYGCBcZLA47O0OwIhU7PwE6oRsnBgg8CAYUFC9PWB8lAP///9j/CAECAgYEIgF4AAAABwKZAKoBrf///9j/CQF1AgYEIgF6AAAABwKZAKoBrf///97/DgEyAgYEIgF7AAAABwKZAGwBrf///97/DgDCAgYEIgF5AAAABwKZAGoBrf///9j/CAFlApwEJwKYANH+kwACAXgAAP///9j/CQF1AqEEJwKYAOH+mAACAXoAAP///9j91wEKATsEJwK+AIL+swACAXgAAP///9j92QF1ATwEJwK+AIH+tQACAXoAAP///9j/CAFHAoYEIgF4AAAABwKiAGIBr////97/DgEIAoYEIgF5AAAABwKiACMBrwAE/9j/CQHBAoYAGgAeACIAJgAANhYzMzIWFRUUIyMiJicVFAYHByc3NjY1ETMVAzMVIwczFSM3MxUj+ykdcgYIDmYYLA1RRnUYfC4wSVVZWUZYWI1YWH4mCQY7DhQSKUhsGChGKBBGLgFAogHtWSVZWVkA////3v8OATIChgQiAXsAAAAHAqIAIgGvAAEAR/9SBEkBWgA1AAAWJiY1ETMRFBYzMzI2NREzFRQWMzMyNjc3FwcGFRQWMzMRMxUUBiMjIiYnBgYjIicVFAYGIyPcXjdLSjS2LDlLKhwPISUFIEsbASYdVks0KkEmOg4SOyU1IDBSMLCuOF03AQ3+/jVKQC4BI6AcJyEcog2IBAkaIwEC/SozICEgIScuLU0tAAABAEj/UgTKAVkARQAAFiYmNREzERQWMzMyNjURMxUUFjMzMjY3NxcHBhUUFjMzMjY1NTMVFBYzMzIWFRUUBiMjIicGBiMiJicGBiMiJxUUBgYjI91eN0tKNLAsP0sqHBAhJAYgShoCJh0UHShLKR0pBQkIBhxNKxVBJSY8DhE8JDUgM1Uwq643XTcBDf7+NUk/LQElnh0oIRujDYcKBhohKB28ux4oCAY9BQhBHyIgISAhJysuTy0AAf/yAAADBwFZAEIAACImNTU0NjMzMjY1NTMVFBYzMzI2NzcXBwYVFBYzMzI2NTUzFQYWMzMyFhUVFAYjIyImJwYGIyImJwYGIyImJwYGIyMGCAkFJR0oSyobESEkBiBKGwEmHBUeKEsBKh0nBQkIBhskPhYVPiYmPQ8SPSQkPhYWPSQZBwc8BggpHZ2dHSkhHKMOhwQJGiQpHbu6HikIBjwFCSEgHyIgISAhISAgIQAB//IAAAKLAVgALwAAIjU1NDYzMzI2NTUzFRQWMzMyNjc3FwcGFRQWMzMRMxUUBiMjIicGBiMiJicGBiMjDgkFKR0oSiodDyElBiBKGgElHVVLNSlDTR4SPSQlPRYWPiUbDjwGCCodnJ0dKSEcog2HBAkaJAEA+io0QSAhISAgIQD//wBH/1IESQJ/BCIBiAAAAAcCogLQAaj//wBI/1IEygJ/BCIBiQAAAAcCogLRAaj////yAAADBwJ/BCIBigAAAAcCogERAaj////yAAACiwJ/BCIBiwAAAAcCogEWAagAAgBH/1IEjwFpACsAOgAAFiYmNREzERQWMzMyNjURMxUUFhc3NjYzMzIWFhUVFAYGIyEiJicVFAYGIyMANjU1NCYjIyIGBwcWMyHcXjdLSTWxKz9LEAuaHU4qPydCJylEKP7uHj8VMlQxrAMMJScbSh02FIIMDgEcrjdeOAEN/v01SkAsASV9EiMIph8jJ0InRShEKBsXNC9PLgEGJRs9GyYXFo4DAAIAR/9SBQMBaQA3AEYAABYmJjURMxEUFjMzMjY1ETMVFBYXNzY2MzMyFhYVFRQWMzMyFhUVFCMjIicGBiMhIiYnFRQGBiMjADY1NTQmIyMiBgcHFjMh3F43S0k1ry0/Sw8MmR1PKj8nQiYqHSAIBg4USS0TPSH+7h5AFTJVMKsDDCUoG0odNhSCCxIBGq43XTgBDv79NUo/LQElfREjCaYfIydCJzwdKAYIPA44GR8bFzUvTi4BBiUbPRsmFxaOAwAAAv/yAAADPwFqAC8APgAAIjU1NDMzMjY1NTMVFBYXNzY2MzMyFhYVFRQWMzMyFRUUIyMiJwYGIyEiJicGBiMjJDMhMjY1NTQmIyMiBgcHDg4hHSdLDwyaHU0rPydCJykdIg4OFkUwFD0h/vIoWRYORycTARUPARsaJScbSh41FIIOPA4pHZh4FSAIpyAiJ0MnPBwpDjwOOxsgKSknK1glGz0bJhcWjgAAAv/yAAACyQFqACQAMwAAIjU1NDMzMjY1NTMVFBYXNzY2MzMyFhYVFRQGBiMhIiYnBgYjIyQ2NTU0JiMjIgYHBxYzIQ4OIR0nSw8Mmh1NKz8nQicpRSf+8ihZFg5HJxMCWSUnG0oeNRSCDhABGA48DikdmHgVIAinICInQydIJ0IoKSknK1glGz0bJhcWjgP//wBH/1IEjwI1BCIBkAAAAAcCmQOkAdz//wBH/1IFAwI1BCIBkQAAAAcCmQOkAdz////yAAADPwI1BCIBkgAAAAcCmQHlAdz////yAAACyQI1BCIBkwAAAAcCmQHlAdwAAgBJAAACogKWABYAIwAANzM3ETMRFAc2NzYzMzIWFhUVFAYGIyEkNjU1NCYjIyIGBwchSTduSQ8SHS9RPCdCJidEKP46AeskJRxGHzMWiAE5WHYByP7AKCMQHi8mQidFKEQoWCUZPhwmFRiRAAACAEkAAAMZApYAIgAvAAA3MzcRMxEUBzc2MzMyFhYVFRQWMzMyFhUVFAYjIyImJwYjISQ2NTU0JiMjIgYHByFJN25JDy8wUD4mQiYpHSIGCAgGFSQ+FClI/joB6yUmHEYeNhSIAThYdgHI/sAoIy4vJkImPR4nCAY8BQkhH0BYJRo9HCYXFZIAAv/yAAAC2gKWACYAMwAAIjU1NDMzNxEzERQHNzYzMzIWFhUVFBYzMzIWFRUUBiMjIiYnBiMhJDY1NTQmIyMiBgcHIQ4OQG5JDzAvUD4mQicoHSMFCQkFFiU8FCpI/jEB9SQmHEYeNhSIATkOPA52Acj+wCgjLi8mQiY9HSgIBjwFCSAfP1glGj0cJhcVkgAAAv/yAAACZAKWABoAJgAAIjU1NDMzNxEzERQGBzc2MzMyFhYVFRQGBiMhJDY1NTQmIyMiBwchDg5BbkoJBzAyTD4mQicnRCn+MAH0JSUcRz0qiAE4DjwOdgHI/sEZIRIuLydBJ0UoRChYJBo+HCYtkQD//wBJAAACogKWBCIBmAAAAAcCmQG4Ac///wBJAAADGQKWBCIBmQAAAAcCmQG4Ac/////yAAAC2gKWBCIBmgAAAAcCmQF4Ac/////yAAACZAKWBCIBmwAAAAcCmQF5Ac8AAQBJ/nkB8QF9ACcAABImJjU0NjcmJycmNTQ2NjMzFSMiBhUUFxc2NzcXBwYGFRQWFjMzFSP7cEI2KhMHGQMjPiaTmhYgASJGGZEV6yk5K0sutbT+eUFuPzdgGyEigg4MJD0kUyEWBwSzFwcuQ0sNQjMsSStYAAIASf5zAmcBjwArADMAABImJjU0Njc3Jyc0NjMzMhYVFRQHBxYzMzIWFRUUIyMiJwcGBhUUFhYzMxUjEzU0JiMjFRf7cEIwLk+LAS8ptj1KKEwyPGAGCA5sZFRfHyIuTCz08nwcGtWI/nNCcEI4YiE5Xn8qLUs6GzEeNhIJBT0NLUMWQSUsTCxXAm8jGB5UWgAAAv/yAAACYAGNACoANAAAIiY1NTQ2MzMyNjcnNTQ2MzMyFhUVFAYHBx4CMzMyFhUVFAYjIyInBiMjJTU0JiMjFRYWFwYICAZ1GCokdi4muz1JFhNQCSwjEWgGCAgGb1lcXFp4AbMbGtQaVhYJBjoGCQcJT4EnLk04HBcqDTUCCgUJBjoGCTY23yMYHlQSNw4AAf/yAAABngGOABsAADYnJyY1NDYzMxUjIgYXFzcXBwYjIyI1NTQ2MzNqBxECTzmcoxogBR7XDZZ4biIOCAZ3cCRcCRE5S1IoGp8WThMQDjwFCQD//wBJ/nkB8QI6BCIBoAAAAAcCmQDoAeH//wBJ/nMCZwJHBCIBoQAAAAcCmQD7Ae7////yAAACYAJLBCIBogAAAAcCmQD3AfL////yAAABngJNBCIBowAAAAcCmQDHAfT//wBJAAADGQLWBCIBsAAAAAcCmQJJAn3//wBJAAADrQJhBCIBsQAAAAcCmQKUAgj////yAAAB0QJhBCIBsgAAAAcCmQCzAgj////yAAABjQLWBCIBswAAAAcCmQC7An3//wBJAAADGQNBBCIBsAAAAAcCogH6Amr//wBJAAADrQLOBCIBsQAAAAcCogJOAff////yAAAB0QLMBCIBsgAAAAcCogBqAfX////yAAABjQNHBCIBswAAAAcCogBzAnAAAgBJAAADGQIKACYANQAAMiYmNTUzFRQWMyEyNjU1BiMjIiYmNTQ3NzY2MzMyFhYVFRQGBiMhJTU0JiMjIgYHBwYVFBYzzlUwSjgtAYohKh4gSCU+JAIQCkkxNSZCJipJK/6HAc0jGUAWIAUNAR8WMFQzoJssOCQlEQolPyQQCVQwPSZCJ94rSCr/fBojGxZKBAcVHgAAAgBJAAADrQGUAC4APQAAMiYmNTUzFRQWMyEzJiY1NTQ2NjMzMhYWFRUUBgcWNjMzMhYVFRQjIyImJwYGIyEkNjU1NCYjIyIGFRUUFhfNVDBKOCwBShIeIS5NLQwsTC0iHQcLBFsGCA40LUg2MUou/usB5zw2Jw8lNjYsMVQ0n5ssORk8IR4tTS4tTC0gIT4XAQEJBTwODRISDXQ5GSAnNTYlIRozFwAAAv/yAAAB0QGUACgANwAAIiY1NTQ2OwImNTU0NjYzMzIWFhUVFAczMzIWFRUUBiMjIiYnBgYjIyQ2NTU0JiMjIgYVFRQWFwYICAZhEj4uTCwNLUwtPRJgBQkJBTctTy8uTy03ARA0NiYOJTYzLwkFOwYJNkAeLU0uLU0tH0A2CQY7BQkOEBAOejEdHiY1NSYeHTEYAAL/8gAAAY0CCgAjADIAACImNTU0NjMzMjY1NQYjIyImJjU0Nzc2NjMzMhYWFRUUBgYjIyU1NCYjIyIGBwcGFRQWMwYICQX3ISseIEolPiMCDwhLMTUmQiYqSSvvAUQkGT8WIQQOAR8WCQY6BgkkJREKJT4lEQhTMD4mQifdK0kq/n4ZIhsWSQMGFiAAAgBJ/x8CdwFiACcANgAAFiYmNTUzFRQWFjMzMjY1NQYjIyImJjU0Nzc2NjMzMhYWFRUUBgYjIwE1NCYjIyIGBwcGFRQWM91dN0oiOyKvLD8bI0klPyQDEAlKMTQoQSYxVDGtARgiGUAXHwQOAR4W4TddN/PnIjsjPSosCSU+JA4NUzA9JkEn/zFUMQE5fBkiGxZIAwcWHgACAEn/HwLqAWIAMAA/AAAkBiMjFRQGBiMjIiYmNTUzFxQWFjMzMjY1NQYjIyImJjU0Nzc2NjMzMhYWFRUzMhUVJiYjIyIGBwcGFRQWMzM1AuoIBmgwUjGuN1w3SQEiOyKvLD8bJEklPiQCEAlKMTUnQSZmDr4jGT8WIQQOAR8WkAkJLDFTMTZeN/LmIjsjPSosCSY/JBEIVC89JkEnfA483yIbFkcEBxUffAD//wBJ/x8CdwIvBCIBtAAAAAcCngFdAdb//wBJ/x8C6gIvBCIBtQAAAAcCngFdAdb////yAAAB0QJfBCIBsgAAAAcCngBuAgb////yAAABjQLVBCIBswAAAAcCngBxAnwAAgBJAAADGAKWABUAIwAANhYzITI2NREzERQGBiMhIiYmNTUzFTc3JzU3FwcXFhUUBgcHkz0rAY0dKEsrSSr+hTFUMUrIc1+BFmZCGR0ZYJU9KRwB+f4HK0gqMVMyoZevGVwtOywuPhkYEh0FFAACAEkAAAOIApYAIQAvAAATFRQWMyEyNjURMxEUFjMzMhUVFCMjIiYnBgYjISImJjU1JTcnNTcXBxcWFRQGBweTPSsBjR0pSigdHQ4ODyU+FBc+Jf6FMVQxARJzX4EWZkIZHRlgAVeXKz0oHQH5/gcdKA48DiEdHiAxUzKhGBlcLTssLj4ZGBIdBRQA////8gAAAgsCyQQCAcMAAP////IAAAGPAskEAgHFAAAAAQBHAAADcQLJABwAADImJjU1MxUUFjMhMjY1NCcnNSUXBRcWFRQGBiMhzFUwSzgsAXQvPRuiATch/vOPKy9XN/6fMVUzqaMsOz4sJiffPJ9DicU5RTJVMwAAAQBHAAADHgKWABwAADImJjU1MxUUFjMhMjY1NCcnNTcXBxcWFRQGBiMhzFUwSzgsAXQvPRui1SKsjysvVzf+nzFVM6mjLTo+LCYn3zxsQ1bFOUUyVTMAAAEASQAABBUCgwAhAAAyJiY1NTMVFBYzITI2NTU0JiMhJwEXByEyFhYVFRQGBiMhzlUwSjksApcaISQY/ik1AQo1xQGJJ0InKEMl/X0xVDOpoyw6IxlIFyYyATgy5ydCJ0smQicAAAIARwAAA+4CyQAcADMAADImJjU1MxUUFjMhMjY1NCcnNSUXBRcWFRQGBiMhICYnJiYnJiYnNxcWFjMzMhYVFRQGIyPMVTBLOCwBdC89G6IBNyH+848rL1c3/p8CqzoZDiQVFysPM4MTJCYNBQkJBgoxVTOpoyw7PiwmJ988n0OJxTlFMlUzHCIUMh0fOxQpsxoTCQY7BggAAQBJAAAEkQKDAC8AADImJjU1MxUUFjMhMjY1NTQmIyEnARcHITIWFhUVFBYzMzIWFRUUBiMjIiYnBgYjIc5VMEo5LAKWGSMkGf4qMQEGNcUBiCdCJykcKgUJCAYcJjkQFDon/X8xVDOpoyw6IxlHGCU3ATQy6CdCJzwdKAkFPAUJJiMmIwAC//IAAAILAskAFwAuAAAiNTU0MzMyNjU0Jyc1JRcFFxYVFAYGIyMgJicmJicmJic3FxYWMzMyFhUVFAYjIw4Ohy89G6IBNyL+8o8rL1Y3fwHIOhkOJBUXKw8zgxMlJgwFCQkFCw48Dj0sKSXfPJ9DicU5RTJVMxwiFDIdHzsUKbMaEwkGOwYIAAAB//IAAAMyAoMAKwAAJBYzMzIWFRUUBiMjIiYnBgYjISImNTU0MyEyNjU1NCYjIScBFwchMhYWFRUCtSkcKgUJCAYcJjkQFDon/dwGCA4CLxkkJRn+KjEBBjXFAYgnQieAKAkFPAUJJiMmIwkGOw4jGUcYJTcBNDLoJ0InPAAB//IAAAGPAskAFwAAIjU1NDMzMjY1NCcnNSUXBRcWFRQGBiMjDg6HLz0bogE3Iv7yjysvVjd/DjwOPSwpJd88n0OJxTlFMlUzAAH/8gAAATsClQAXAAAiNTU0MzMyNjU0Jyc1NxcHFxYVFAYGIyMODocvPRui0yKqjysvVjd/DjwOPSwpJd88a0NVxTlFMlUzAAH/8gAAArYCgwAdAAATARcHITIWFhUVFAYGIyEiJjU1NDMhMjY1NTQmIyEnAQY1xQGIJ0MnKEQm/dwGCA4CLxkkJRn+KgFPATQy6CdCJ0onQScJBjsOIxlHGCX//wBHAAADcQMzBCIBvgAAAAMCpgKYAAAAAgBHAAADHgL/AAMAIAAAATcXBwAmJjU1MxUUFjMhMjY1NCcnNTcXBxcWFRQGBiMhAgC1Grf+tFUwSzgsAXQvPRui1SKsjysvVzf+nwKkWzdb/ZMxVTOpoy06PiwmJ988bENWxTlFMlUz//8ASQAABBUCtAQiAcAAAAADAqcBzgAA//8ARwAAA+4DMwQiAcEAAAADAqYCmAAA//8ASQAABJECtAQiAcIAAAADAqcBzgAA////8gAAAgsDMwQiAcMAAAADAqYAtgAA////8QAAAzICtAQiAcQAAAACAqdsAP////IAAAGPAzMEIgHFAAAAAwKmALYAAAAC//IAAAE7AwAAAwAbAAATFwcnAjU1NDMzMjY1NCcnNTcXBxcWFRQGBiMj1Bi0GS0Ohy89G6LTIqqPKy9WN38DADlaN/1cDjwOPSwpJd88a0NVxTlFMlUzAP////EAAAK2ArQEIgHHAAAAAgKnbAAAAQBI/1ICdQKWABUAABYmJjU1MxUUFjMzMjY1ETMRFAYGIyPcXTdKSjWwLD5KMVMxra43XTfx5TVKPiwCgv1xMVMxAAABAEj/UwL/ApYAJAAAFiYmNTUXFRQWFjMzMjY1ETMRFBYzMzIVFRQjIyImJxUUBgYjI91eN0oiOiOvLD9KJR45Dg4sGTAIL1I0rK04XTfwAeMiPCNALAKA/gcfJg47DxwUKC5TNAAB//IAAAFbApYAHAAAIjU1NDMzMjY1ETMRFBYzMzIVFRQjIyImJwYGIyMODj4eJ0spHTkODiwlPRYVPiUxDjwOKB0B+f4HHSgOPA4hIB8iAAH/8wAAAM0ClgAQAAAmMzMyNjURMxEUBgYjIyI1NQ0NPR0qSStJKi8NWCgdAfn+BytIKg48//8ASP9SAtkD1gQnAr8CUf/xAAIB0gAA//8ASP9TAv8D1gQnAr8CUv/xAAIB0wAA////8gAAAVsD1gQnAr8Aqf/xAAIB1AAA////8wAAATID1wQnAr8Aqv/yAAIB1QAAAAIAR/8HAlMBaQAbACcAAD4CMzMyFhYVFRQGIyMiJiY1NDc3IyIGFREjEQU1NCYjIwcGFRQWM0crSSrfJ0ImMyp7JT0kAhU1HCpKAcIiGXYYARwZ9kgrJkEnfSo0JT8kCRB2LB3+OQHEc4QZIoEEBxYdAAIAR/8GAvIBaQApADUAAD4CMzMyFhYVFRQWMzMyFRUUBiMjIiYnBgYjIyImJjU0NzcjIgYVESMRBTU0JiMjBwYVFBYzRytIK98nQiYpHUsOCAY/HzcSCCMceyU+IwIVNR0pSgHCIxl2FwEdGPZJKiZCJz0dKA48BggZGh0WJT4lCRB2LB3+OAHFc4MZI4EEBxYdAAAC//IAAAI+AWkAKgA5AAAiNTU0NjMzMjY3NzY2MzMyFhYVFRQWMzMyFhUVFCMjIicGBiMjIicGBiMjJCYjIyIGBwcGFRQWMzM1DggGIBwoBhUKSjA4JkInKB0hBggOFEAnCCUdeUcgETsjHAGAJBlDFiAFDwEeFpcOPAUJHx1nLz8mQiY9HSkJBTwOMRsWQSEg9CMcFVADBxYegwAC//IAAAHKAWkAHQAsAAAiNTU0NjMzMjY3NzY2MzMyFhYVFRQGIyMiJwYGIyMlNTQmIyMiBgcHBhUUFjMOCAYgHCgGFQpKMDgmQic0K3lHIBE7IxwBgCQZQxYgBQ8BHhYOPAUJHx1nLz8mQiZ9KjRBISBYgxkjHBVQAwcWHv//AEf/UgJ2AZUEIgHiAAAABwKZATMBPP//AEf/UQL0AZUEIgHjAAAABwKZATMBPP////IAAAFsAgIEIgFCAAAABwKZAI4Bqf////IAAAD3AhkEIgFDAAAABwKZAJ8BwAABAEf/UgJ2ATwAFQAAExEUFjMzMjY1ERcRFAYGIyMiJiY1EZJKNLAsP0sxVTKrN143ASv+/TVJPy0BJgH+zjJUMTddOAENAAABAEf/UQL0ATsAIwAAFiYmNREzERQWMzMyNjURMxUUFjMzMhUVFCMjIiYnFRQGBiMj3F43S0k1sCw/SygcLA4OHBwsDDNVMKuvN104AQ7+/TVKQCwBJp8cKA48DhYSLS5OLgAAAgBH//YBqwHIABUAJgAAFiYmNTU0Njc3JzcWFxYWFRUUBgYjIzY2NTU0LwIHBgYVFRQWMzPATSwhHTZDKIBRHR0rTTAVQjEaJStNDAwxJCUKL04sIidAESMtP1k1EUElJCxOL1Y0ICofExgcNQoVECsiMwACAEkAAAISAgQAGwAiAAAgJicGIyMiJjU1NDY3NzUzERQWMzMyFRUUBiMjJzUHBgYVFQG5SBMfI3EuNEM2ikorJR4OCAYemngjHi0qDDUuQT5WDSJS/p8gKw48BwejwR8JLSNJAAAC//L/IwJ8AV4AMwBBAAAWJicjIiY1NTQzMzU0NjYzMzIWFxcWFRQGBiMjIicnFhYXFzc2NjMzMhUVFAYjIyIGBwcnNjY1NCcnJiMjIgYVFTOSOQFYBggOVyZBJz4ySQkPAiM+JVMQGBcBHiuJVRpMNAwOCAYdHicRZsuNGAENCTRIGSKhl1FGCQY7DncnQiY9MU4JECQ/JgIBMCwNJZAsJw47BwgWHKs3/hwWCAVFMiMZegAC//IAAAJ0AdoAKwA6AAAkBgYjISImNTU0NjMzJiY1NDc3NjYzFzIWFRUzNTQmJyU3BRYWFRUUBiMjNSYmIyMiBgcHBhUUFjMzNQF2GCIW/toFCQgGZQoLAg0JSDAmOk+aIBv+tBYBQzZDNi6XMiEZMBcbBA4BHRZ8IhYMCAU+BgcGGxMPCUUvOwFPOnF9HysJZ0tkEFY8cS41JMUhGhVNBAgWGH3//wBH//YBqwNHBCcCvQD+/vkAAgHkAAD//wBJAAACEgNxBCcCvQDu/yMAAgHlAAD//wBH//YBqwHIBAIB5AAAAAEAOwAAAjkBIAAUAAA3NzMWFxcWFjMzMhYVFRQjIyInJwc700QQRQ8QJx8fBggODmI4Vbw07BRrFxoYCAc7DlOC0wAAAv/y/x4CUwDtABwALgAAFiY1NTMVFBcXNzYzMzIVFRQGIyMiBgcGBwYGByckJjU1NDMzMjY1NTMVFAYGIyPWO0lKC2U5YQ0OCAYeHSoQDzsLGApK/usIDj0pNTErTTAkuFdP//9dGgOSUg47BwgYGhhWECMPF8sJBjsONikdLDBNKwD////y/m0A9wFYBCIBQwAAAAcCjv/b/nv//wBH//YBqwMqBCcCqwDl/vMAAgHkAAD//wBJAAACEgMlBCcCqwDu/u4AAgHlAAD////yAAACdAHaBAIB5wAAAAYAQf7yAmMBUwAPAB4AIgAsAD0ATAAAACYmNTUzMhYVFAcHBgYjIzY2Nzc2NTQmIyMVFBYzMwEzFSMlMzIWFRUUBiMjJjY2MzMyFhcXFhUUBgYjIzUWNjU0JycmJiMjIgYVFTMBDUEm3ThLAg4ISzE+VyAFDQEfFpkiGUr+zOPjAVm7BggJBbv0JD4nGy9ICQ4DHiwV1tAdAQ0EIBQkGCJx/vImQifASTUHEEwwPlIcFksEBxYegBkjARRYWAcGPgUI8D4lOy5FDQwgMBqocRgVCAVFFBshGHUAA//yAAAC+gHaACsAOgBLAAAkBgYjISImNTU0NjMzJiY1NDc3NjYzFzIWFRUzNTQmJyU3BRYWFRUUBiMjNSYmIyMiBgcHBhUUFjMzNQQmNTUzFRQWMzMyFhUVFCMjAXYYIhb+2gUJCAZlCgsCDQlIMCY6T5ogG/60FgFDNkM2LpcyIRkwFxsEDgEdFnwBQEk2Jx4zBggOJyIWDAgFPgYHBhsTDwlFLzsBTzpxfR8rCWdLZBBWPHEuNSTFIRoVTQQIFhh90VpELS0eKAkGOw4A////8gAAAnQB2gQCAecAAP//AEf/9gGrAoAEIgHkAAAABwKeAIMCJ///AEkAAAISAqwEIgHlAAAABwKeAHkCU///AEf/9gGrAocEIgHkAAAABwKeAIQCLv//ADsAAAI5AegEIgHrAAAABwKeAMMBjwACAEH/CQGfAWkAHAArAAAgIyMiJiY1NDc3NjYzMzIWFhUVFAYHByc3NjY1NTQmIyMiBgcHBhUUFjMzNQEyJUYlPiMCEAhLMjgnQiZSRXYVeS4wIxlIFRwEDwEfFpQlPiQRCFkxPyZCJtdLcRcoRikPRS4S6CMZF1EDBxYegwADAEH/CQH7AWkACAAlADQAACQWFRUUIyM3MwYjIyImJjU0Nzc2NjMzMhYWFRUUBgcHJzc2NjU1NCYjIyIGBwcGFRQWMzM1AfMIDl0BXLIuRiU+IwIQCEsyOCdCJlJFdhV5LjAjGUgVHAQPAR8WlFgIBjwOWFglPiQRCFkxPyZCJtdLcRcoRikPRSkU6yMZF1EDBxYeg///AEH/CQGfAs0EJwKrAOL+lgACAfgAAP//AEH/CQH7AssEJwKrANT+lAACAfkAAP//AEH/CQGfAqgEJwK/APX+wwACAfgAAP//AEH/CQH7AqcEJwK/APL+wgACAfkAAP//AEH/CQGfAsoEJwKxAOz+mQACAfgAAP//AEH/CQH7As4EJwKxAOD+nQACAfkAAP//AEf/WQKTAbIEAgIQAAD//wBH/xUC7wDTBAICEQAA//8AR/6hApMBsgQiAhAAAAAHAp8A+f76//8AR/5qAu8A0wQiAhEAAAAHAp8A9v7D//8AR/5ZAqYAWAQiAhIAAAAHAp8A3P6y////8v8vAWwBNwQiAUIAAAAGAp89iP////L/LwEPAVcEIgFEAAAABgKfFIj////y/y8BVwFXBCIBRQAAAAYCnzKIAAP/8v8vAZQBVwARABUAGQAAIjU1NDYzITI2NTUzFRQGBiMjFzMVIyczFSMOCAYBBR0oSipHK/jLWFiNWFgOOwYJJx27uypIKnhZWVkA//8ALv9ZApMCpQQnAqsAt/5uAAICEAAA//8AR/8VAu8CagQnAqsA3/4zAAICEQAA//8AR/8OAqYBvgQnAqsA1P2HAAICEgAA////8gAAAWwCyQQiAUIAAAAHAqsAt/6S////8gAAARsC+wQiAUMAAAAHAqsAkv7E////8gAAAVcC6wQiAUUAAAAHAqsAsP60//8APP9ZApMCSAQnAr8AuP5jAAICEAAAAAEAR/9ZApMBsgAmAAAkFhUVFAYGIyMiJiY1NTMVFBYWMzMyNjU1JTU0NjY3NxcHBgYVFRcCbCcxVDLJN143SyI7I9QqOP7uK0otdwqFJTDLgy4hJDJUMTdeN+bbIjojPSsmQGswUDMGD0oSBTsmNTAAAAEAR/8VAu8A0wAhAAAEFRUUBgYjIyImJjU1MxUUFjMzMjY1NSM1ITIWFRUUBiMjAn0yVDC0N143S0o0yigxwwFxBQkJBWsVFiItSCk3XTjy5zVKNig1WAgGOwYJAAABAEf/DgKmAFgAGgAABSEiJiY1NTQ2NjMhMhYVFRQjISIGFRUUFjMhAmD+eCdDJyhEJgG/BggO/jYZIyUaAY/yJ0InKydBJwkGOw4jGSQaJwD////y/y8BbAE3BAICBQAA////8v8vAQ8BVwQiAUQAAAAGAp8XiP////L/LwFXAVcEIgFFAAAABgKfMogAA//y/y8BlAFXABEAFQAZAAAiNTU0NjMhMjY1NTMVFAYGIyMXMxUjJzMVIw4IBgEFHShKKkcr+MtYWI1YWA47BgknHbu7KkgqeFlZWQAAAQBHAAACRQG/ABwAACEhIiYmNTU0Njc3NjY3NxcHBgYHBwYGFRUUFjMhAkX+kydDJz8vphMZBAdDBwY/LZwWGiYZAXYnQiceLkkMKQUbFDELMi5DCiYFIhYUGSYAAAEAR/8OAqYAWAAaAAAFISImJjU1NDY2MyEyFhUVFCMhIgYVFRQWMyECYP54J0MnKEQmAb8GCA7+NhkjIxkBkvInQicrJ0EnCQY7DiMZJxklAP//AEf/UgJ2AtUEJwK/AWL+8AACAd4AAP//AEf/UQL0AtUEJwK/AWH+8AACAd8AAAABAAAAAADPAFgABwAANTMyFRUUIyPBDg7BWA48DgABADH/5QHUApYAEwAANzcDNxMWFRQHNzY2NREzERQGBwUxbTBJKAEHaSEmS0s+/vEyDgH+C/5HCA0RIQ4FKiQB7P4YRFYJJgACADH/5QJUApYADwAjAAAkFjMzMhUVFAYjIyImJjU3BTcDNxMWFRQHNzY2NREzERQGBwUB1CwkIg4IBiEhOyUw/l1tMEkoAQdpISZLSz7+8XwkDjwGCB89Kx1yDgH+C/5HCA0RIQ4FKiQB7P4YRFYJJv//ABb/5QHUA6EEJwKrAJ//agACAhwAAP//ABf/5QJUA6MEJwKrAKD/bAACAh0AAP//ADD+agHUApYEJwKsALn/lwACAhwAAP//ADH+bQJUApYEJwKsAMr/mgACAh0AAP//AAD/5QHmAvUEJwK8AIj/dQACAhwSAP////z/5QJjAv4EJwK8AIT/fgACAh0PAP///9n/5QHUA3MEJwKkAI7/ogACAhwAAAABAEf/KgOXAWIAQQAAFiYmNTUzFRQWFjMzMjY1NSU1NDY2Nzc2MzIWFxYWFxYXFhYzMzIVFRQGIyMiJicnJiYHBwYGFRUXFhYVFRQGBiMj3F43SyI7I84qOP75LEssSQYNJkQVBQ0IPAgRKCAZDggGGi9FH1cNMxpTIzG/ISgxVDLC1jheN/fsIjsjPSwmPFIuUjYFBwEjHwYWDWEMGhgOOwYJLDGLFhcDCgM5ISYpBi8hJDJUMgAAAQBH/yoD3wFiAEEAABYmJjU1MxUUFhYzMzI2NTUlNTQ2Njc3NjMyFhcWFhcWFxYWMzMyFRUUBiMjIiYnJyYmBwcGBhUVFxYWFRUUBgYjI9xeN0siOyPOKjj++SxLLEkGDSZEFQUNCDwIESggYQ4IBmIvRR9XDTMaUyMxvyEoMVQywtY4Xjf37CI7Iz0sJjxSLlI2BQcBIx8GFg1hDBoYDjsGCSwxixYXAwoDOSEmKQYvISQyVDIA//8AR/8qA5cBYgQnApoC1/+IAAICJQAA//8AR/5uA5cBYgQnApoC1/+IACICJQAAAAcCnwD5/sf//wAu/yoDlwKLBCcCmgLX/4gAJwKrALf+VAACAiUAAP//AEf/KgOXAWIEJwKaAtf/iAACAiUAAP///9r/5QJUA3UEJwKkAI//pAACAh0AAP//AEf+sQPfAWIEJwKhArf/iAACAiYAAP//AEf+bgPfAWIEJwKhArf/iAAiAiYAAAAHAp8A+f7H//8AUP6xA/ICkgQnAqECt/+IACcCqwDZ/lsAAgImEwD//wBH/rED3wFiBCcCoQK3/4gAAgImAAD//wBH/yoDlwI2BCcCngIVAd0AAgIlAAD//wBH/m4DlwI2BCcCngIVAd0AIgIlAAAABwKfAPn+x///AEf/KgOXApAEJwKeAhUB3QAnAqsA0/5ZAAICJQAA//8AR/8qA5cCNgQnAp4CFQHdAAICJQAA//8AR/8qA5cCtQQnAqICFAHeAAICJQAA//8AR/5uA5cCtQQnAqICFAHeACICJQAAAAcCnwD5/sf//wBH/yoDlwK1BCcCogIUAd4AJwKrAOn+bwACAiUAAP//AEf/KgOXArUEJwKiAhQB3gACAiUAAAABAEf/KgTsAWIASwAAJDMyNjc3FwcGFRQWMzMRMxUUBiMjIicGIyImJycmJgcHBgYVFRcWFhUVFAYGIyMiJiY1NTMVFBYWMzMyNjU1JTU0NjY3NzYzMhYXFwM3Nh0tBCFIGgEoG1ZKNClCRCMqUC1EH1cNMxpTIzG/ISgxVDLCN143SyI7I84qOP75LEssSQcNJkQUXlgiGqEMhgQHGiYBAfwpNEJCLDGLFhcDCgM5ISYpBi8hJDJUMjheN/fsIjsjPSwmPFIuUjYFBwEiIJYAAQBH/yoFZQFiAF4AABYmJjU1MxUUFhYzMzI2NTUlNTQ2Njc3NjMyFhcXFhYzMjY3NxcHBhUUFjMzMjY1NTMVFBYzMzIWHQIUBiMjIiYnBiMiJicGIyImJycmJgcHBgYVFRcWFhUVFAYGIyPcXjdLIjsjzio4/vksSyxJBw0mRBRfDysbHiwFH0kbASgcDx0oSSscKAYHBwYcJT4UKkckPBEnUCxFH1cNMxpTIzG/ISgxVDLC1jheN/fsIjsjPSwmPFIuUjYFBwEiIJYYGyIboQ6EBAgbJSkcvcEaJgkHOgIGBiIhQyEgQSwxixYXAwoDOSEmKQYvISQyVDL//wBH/m4E7AFiBCICOAAAAAcCnwD5/sf//wBH/m4FZQFiBCICOQAAAAcCnwD5/sf//wBH/yoE7AKGBCcCqwD1/k8AAgI4AAD//wBH/yoFZQKKBCcCqwDy/lMAAgI5AAD//wBH/yoE7AFiBAICOAAA//8AR/8qBWUBYgQCAjkAAP//AEf/KgTsAoEEJwKiA2kBqgACAjgAAP//AEf/KgVlAoEEJwKiA2kBqgACAjkAAP//AEf+bgTsAoEEJwKiA20BqgAiAjgAAAAHAp8A+f7H//8AR/5uBWUCgQQnAqIDaQGqACICOQAAAAcCnwD5/sf//wBH/yoE7AKEBCcCogNpAaoAJwKrAO/+TQACAjgAAP//AEf/KgVlApcEJwKrAPr+YAAnAqIDagGqAAICOQAA//8AR/8qBOwCgQQnAqIDaQGqAAICOAAA//8AR/8qBWUCgQQnAqIDaQGqAAICOQAAAAIAR/8qBTEBagBDAFAAABYmJjU1MxUUFhYzMzI2NTUlNTQ2Njc3NjMyFhcXFhc3NjYzMzIWFhUVFAYGIyEiJicnJiYHBwYGFRUXFhYVFRQGBiMjADY1NTQmIyMiBgcHIdxeN0siOyPOKjj++SxLLEkHDSZEFFMRC6cdTSs+JkInKEQo/tIuSB5WDTMaUyMxvyEoMVQywgOuJSYcRh02FIkBOtY4Xjf37CI7Iz0sJjxSLlI2BQcBIiCIGwq2HyInQSdFKUUoLjGJFhcDCgM5ISYpBi8hJDJUMgEuJxo9GyYWFZQAAAMAR/8qBaMBagANAFEAXgAAJBYzMzIVFRQjIyImJzcAJiY1NTMVFBYWMzMyNjU1JTU0NjY3NzYzMhYXFxYXNzY2MzMyFhYVFRQGBiMhIiYnJyYmBwcGBhUVFxYWFRUUBgYjIwA2NTU0JiMjIgYHByEFMCkcIA4OFChHDCv7q143SyI7I84qOP75LEssSQcNJkQUUxELpx1NKz4mQicoRCj+0i5IHlYNMxpTIzG/ISgxVDLCA64lJhxGHTYUiQE6gioNPQ4qLEj+jDheN/fsIjsjPSwmPFIuUjYFBwEiIIgbCrYfIidBJ0UpRSguMYkWFwMKAzkhJikGLyEkMlQyAS4nGj0bJhYVlAD//wBH/m4FMQFqBCICSAAAAAcCnwD5/sf//wBH/m4FowFqBCICSQAAAAcCnwD5/sf//wBH/yoFMQKDBCcCqwD1/kwAAgJIAAD//wBH/yoFowJ/BCcCqwDt/kgAAgJJAAD//wBH/yoFMQFqBAICSAAA//8AR/8qBaMBagQCAkkAAP//AEf/KgWjAjYEJwKZBFUB3QACAkkAAP//AEf/KgUxAjYEJwKZBFUB3QACAkgAAP//AEf/KgWjAjYEJwKZBFUB3QACAkkAAP//AEf+bgUxAjYEJwKZBFUB3QAiAkgAAAAHAp8A+f7H//8AR/5uBaMCNgQnApkEVQHdACICSQAAAAcCnwD5/sf//wBH/yoFMQJ+BCcCmQRVAd0AJwKrAPH+RwACAkgAAP//AEf/KgWjAn8EJwKZBFUB3QAnAqsA8P5IAAICSQAA//8AR/8qBTECNgQnApkEVQHdAAICSAAA//8AR/8qA5cCMwQnApkCXAHaAAICJQAA//8AR/5uA5cCMwQnApkCXAHaACICJQAAAAcCnwD5/sf//wBF/yoDlwKqBCcCmQJcAdoAJwKrAM7+cwACAiUAAP//AEf/KgOXAjMEIgIlAAAABwKZAlwB2v//AEf+bgPfAWIEIgImAAAAJwKfAPn+xwAHAp8CtP+J//8AR/8qA98BYgQiAiYAAAAHAp8CtP+J//8AR/8qA5cDHQQiAiUAAAAHAqsCgf7m//8AR/5uA5cDHQQiAiUAAAAnAp8A+f7HAAcCqwKB/ub//wA0/yoDlwMdBCcCqwC9/lQAIgIlAAAABwKrAoH+5v//AEf/KgOXAx0EIgIlAAAABwKrAoH+5v//AEf/KgPfAWIEIgImAAAABwKfArT/iQAFAEcAAAStA2IAMAA3AFgAXABgAAAgJicGIyMiJjU1NDY3NzUzERQWMzMyNjURMxEUFjMzMjY1ETMRFAYGIyMiJicGBiMjJzUHBgYVFQAmNTUzFRQWMzMyNjc3FwcGFjMzNTMVFAYjIyImJwYGIxMVIzUFMxEjAbhIEx8jcS41QzeJSiwlSh4nSykdSx0pSitJKjAlPRYVPiU9mnkjHQGiNDUUDgUOEwIPMgsDExEhNCAZGRUgBgsnE1o2AeZKSiwrDDUuQT5WDSJS/p8gKygdAR3+4x0oKB0BnP5kK0gqISAfIqPBHwksJEkBUjUkRkMOFRENSgo4EBZxcRghEhMRFAFtmJjM/WoAAAEANP8VAP0ApAADAAA3AycT/ZA5iYz+iRkBdgABAC7/QAC8AH0ADAAANhYVFAcHJzc2Nyc3F6AcBU47MQ0QRiMvZScYDw3KGH0jDRhgEAAAAQBFADQAwwCxAAMAADcVIzXDfrF9fQD//wAy//8AnwKsBAICcQAA//8AO///AdcCrAQCAnIAAP//ADv//wKAAqwEAgJzAAAAAgBBAAABogKkABQALgAAMiYmNTU0Njc3FwcGBhUVFBYzMxUjEiMiJicnJjU0NjYzMxUjIgYVFBcXFjMyNwegPCM7LLYXqyUbIRzb3gwSKTUIEwMjPCN9hBceAQ4LLQ8MCidAJFI3WQ03UjELJiFIGB5eAVMuJ1wMDSI/JlUgFggETTYENwACAC8AAAJlApcAEQAjAAAyJjU0NzY2NzcXBgcGFRQWMwc3ITI2NTQmJzczHgIVFAYjIXtMRR1GOBc2bTpAKSkBAQEDKCmCfQxKTWRCTU3+92ZLZ3czZkwgKZJfaUovPFxcOS5X2ZMRXo+dT09vAAIAIP/wAccCqQAHABEAABInNxYzMwcjEiYnETcRFBYXB2RECE1wvxW+mA4BShESTQJKD1AKVf4NkWMBPBj+ul+TYhX//wAW//YCJgKxBAICdwAA//8AFv/oAiYCowQCAngAAP//AB3/8AGsAqAEAgJ5AAAAAgBAADQBegFwABMAIwAAABYWFRUUBgYjIyImJjU1NDY2MzMWJiMjIgYVFRQWMzMyNjU1ARFCJydBJxwnQScmQiccSCQcKxwlJhsrHCQBcCdCJx8mQSYmQSYfJ0InciQkHCAaJSUaIAABADL//wCfAqwACQAAEiYnNxYWFREjEVUREk0RD0oBnpFkGWyQZP6zAUAAAAIAO///AdcCrAAOABgAABImJzcWFjMzNTMVFAYjIyYmJzcWFhURIxG8Og0qByErm0o6OGahERJOEQ5KAVBUSh81MO7POD9OkWQZb45j/rMBQAACADv//wKAAqwAHwApAAASJic3FhYzMzI2NzcXBwYVFBYzMzUzFRQGIyMiJwYGIyYmJzcWFhURIxG8Og0qByErDiAmBiBKGgElHVpJODgzTh4SPSSgERJOEQ5KAVFUSR81MCEcow6GBQgbJO7POD9CICJOkWQZb45j/rMBQAADADv//wJGAqwADAAdACcAABImJzcWFjMyNxcGBiM2JicnJjU0NjMzFSMiBhcXByYmJzcWFhURIxG/PQkqBSMrY+QJbaA3HQkDEAFNOZWbGiAEG0DJERJOEQ5KARRXRx80MRhPDxJkGhRiCA47TVEoG6UDNJFkGW+OY/6zAUAAAAIAL//5AmQCxwAbADkAAAQmNTQ3NwYVFBYzMzI2NTQmJzcWMR4CFRQGIyAmNTQ3NjY3NjcXBwYGBwYVFBYzMzI2NzcXBwYGIwGEOwMiBCYoESgqoZY0J111U01M/rBMRRtHNRIUNhpDPxZAKSkJJSgJEj8QDUVPB1RDGhgRFxYqJzkuWt+YOiphjaVTT29mS2tzLFxAFxgqH1BPJGVOLzwhLWcMWFBdAAIAPP/sAhQCuwAJABwAADcTNjY3FwYGBwMSJicnJiY1NDY3NxcHBhUUFxcHPrs7Ykk1RmM4uHkfEFYZGhkXcDJ0FBWJKRYBCFJxSjhEcE/+/AE2DQ9KFjcdHTUUYzdmERkaEnQ2AAIAFv/2AiYCsQALABgAABImJyc3FxYWFxMHAxM1EzY2NzY3FwYGBwOEMykSRhcpMBReRV1qXRg0JAMRPzQ4G2MBlXpSJCwwWHdM/p0NAUv+tiQBSVR/TAgkKmeEWf66AAIAFv/oAiYCowANABkAAAAWFxcHJiYnJiYnAzcTAxUDBgYHByc2NjcTAbczLQ9GBAgFLjAVXkVdal4XMSgUPjY2G2IBA3dbHSwHEgpidlABYw3+tQFKJP63U3hWKiptf1gBRgADAB3/8AGsAqAACAAbACoAACQmJzcVFBYXBwImNTQ3NzY2MzMyFhYVFQcGIyM3NTQmIyMiBgcHBhUUFjMBTg4BShESTfVNAhcHTDFAJ0ImRxsjYZwjGksWIAQVAR8WV5FjJxlfk2IVARJQOwYQkS89JkEn1TIJV7kaIhoVhQMHFiEAAgAy//cCIAKWABUAIQAAJQcDJjU0NjMyFhUVIzc0JiMiBhUUFwEVIyIGFRUjNTQ2MwEbTIYXYFo9SjkBJiQ2NA8BilIkJjZKPRIbAXVAN1FiT0edlh4nNi8iMAEPWCcelp1HTwD//wAW//YCJgKxBAICbQAAAAEAIAAAASoAVAADAAA3MwcjNfUV9VRUAAEANf/yAMIBMAAMAAA2JjU0NzcXBwYHFwcnUBsFTTswDBFFIjAKJxgRDMoYfiAQF2EQAAACAE4AAQDcAgsAAwAQAAA3FSM1NiY1NDc3FwcGBxcHJ8NmDRwGTTsxDBFGIy9sa2t5JxcPD8oYfiEPF2EQAAIAMQAAAasCrgAbAB8AADc1JicmJjU0NjMyFwcmIyIGFRQWFhcWFhUHBhUHNTMV6gdHPC9bbU1lEGE1SzgRHyIrNQEBVGGbNyc6MEw3YGgkQxY8ORslIB0lRikhChGbYWEAAQA0ATQB6gMGAEAAABImJjU1MxUUBgYHPgI3NxcHDgIHHgIXFwcnLgInHgIVFSM3NDY3DgIHByc3PgI3LgInJzcXHgIX+AcCQgQHAgYQEA1zIHMOFRIJCBYTDXMgcxAPDwYCCQNCAQQIBhEQDXIicw8SFggIFxMNcR9zEQ4PBAJKFhMPhIQSFBQHBhENB0I4QwgIBAICBQcHQjpCCQ0RBgcYFBCEhBcUGAYSDAhDOUIJBwUCAgQIB0M4QgoMEQUABAAx/5ICEwMwAA0AJAA6AD4AAAQmNyY2NxcGBhUUFhcHATc+AjcuAicnNxceAhcXDgIHByQmJic1NjY3NxcHDgIHHgIXFwcvAgcXAU1aAgJaUTZMOztMNv6TchETFgUJFxINcR9zEQ8PBAEHEBANcgEeDw8GEg4TcyByDhEWCgYYFQxzIXNAHB0dA+13d+1rLoW4ZGS3hi4BdkIKBgUBAgUHCEI5QgsNEQVDBxIMCEJLDREGQxQODEI5QgkGBQIBBQkHQjlCUB0dHQAABABR/5ICMwMwAA0AJAA6AD4AADY2NTQmJzcWFgcWBgcnACYmJzc+Ajc3FwcOAgceAhcXBycFNz4CNy4CJyc3FxYWFxUOAgcHNycHF9w7O0w2UFsBAltRNgEBEQ0HAQQREQ1zH3EOEhYJBRkUDXIhcv6xcxAUFQYKFxIMciBzEw4SBhAQDXPsHB0dRrdkZLiFLmvtd3btbC4BWg8OB0MFEw4IQjlCCQYFAgEFCQdCOUIJQgkHBQECBQcIQjlCDA4UQwYSDQhCkh0dHQAAAgBDAAABtwI4AA0AGwAAJCY1NDY3FwYGFRQWFwckJic2NjcXBgYVFBYXBwFMOzs6MSoqKiox/vk7AQE7OzEqKioqMUKQSEiPQyk/ckBAcUApR49ISI9DKUBxQEBxQCkAAgAtAAABoAI4AA0AGwAANjY1NCYnNxYWFRQGByc2NjU0Jic3FhYVFAYHJ1cqKioxOjs7OjH2KioqMTs7OzsxaXFAQHI/KUOPSEiQQilEcUBAcUApQ49ISI9DKQAHAHb/CAU3ApYAFQAZAB0AKgAzAEAASwAABCYmNTUzFRQWMzMyNjURMxEUBgYjIyUzFSM3MxUjNiYmNREzERQWMzMVIwIWFREHESc3FxMzMjY1NTMVFAYGIyMXNzY1ETMRFAYHBwELXjdKSzWvLD5KMVIxrQHCWFhWhIQSRypLJx0xJHAfS3sjaKFhHClKKkcrVGZ3Y0tSRneuN1038eU1Sj4sAoL9cTFTMU1PT0+wKkcqAQT+/h0oWAJINiD+7yEBRE1FPv4AKRzGxypIKrEnImIBQf7GTWsZKAAAAwAi//cB6wKbAAMADwAbAAA3ARcBJCY1NDYzMhYVFAYjACY1NDYzMhYVFAYjIgGIQf53AQgnJxsbJycb/ucnJxwbKCgbIwJ4Lf2JHygcHCcnHBwoAeQnHBwnJxwcJwAAAv9sAwgAlAQJABoAJAAAAzMyNjU1NCYjIyIHByc3NjYzMzIWFRUUBiMjNjY1NTMVFAYHB5TaDBESDiMgF0IcTBEuFxMjMTIi1DUKMA8MKwNBEgwdDhIXQB1MERQxIyIiM24eHlc4HSgHGgAAAQAAAAAAWABZAAMAADUzFSNYWFlZAAEAAP+mAFkAAAADAAAxMxcjWAFZWgABAAD/1ABYAC0AAwAANTMVI1hYLVkAAgAAAAAAWADLAAMABwAANTMVIxUzFSNYWFhYy1gaWQACAAD/NQBYAAAAAwAHAAAxMxUjFTMVI1hYWFhZGlgAAAIAAAAAAOUAWQADAAcAADczFSMnMxUjjVhYjVhYWVlZWQACAAD/pwDlAAAAAwAHAAAzMxUjJzMVI41YWI1YWFlZWQAAAwAAAAAA5QDXAAMABwALAAA3MxUjBzMVIyczFSONWFhHWFhGWFjXWSVZ11kAAAMAAP8pAOUAAAADAAcACwAAMzMVIwczFSMnMxUjjVhYR1hYRlhYWSVZ11kAAwAAAAAA5QDXAAMABwALAAA3MxUjBzMVIzczFSNGWVlGWFiNWFjXWSVZWVkAAAMAAP8pAOUAAAADAAcACwAAMzMVIwczFSM3MxUjRllZRlhYjVhYWSVZWVkAAv9LAwkA3gPRAAwAKQAAEjY1NTQmIyMiBgcHMwYmJwYjIzUzMjY1NTMVFBc3NjYzMzIWFRUUBiMjnRESDiEOHgtCncEfDBkpGB0PFDEKVhEuFxkjMDEioQNCEgsbDhIMC0E5EBMjORUOJhoRClUSFDEjICIyAAH/nwMIAEoEGQANAAADNyc1NxcHFxYVFAYHB2FzX4EWZkIaHhlgAzwZXC07LC4+FxkTHQUUAAH/aAJtAJgDMwADAAADFyUnmBgBGBkCpDeOOAAB/4UBoAB7ArQAAwAAEycHF3sozikCkCTzIQAAAf9oAS4AmAH0AAMAAAMXJSeYGAEYGQFlN444AAH/5QMKABsDvAADAAATFSM1GzYDvLKyAAH/5f9OABsAAAADAAAzFSM1GzaysgAB/3cDCgCJBDcAFQAAAjU0Njc3FwcGBhUUFxc3FwcnNyYnJ1wjHDsWOwwOBBl1GPoYYBEHDwO2FhssDBgzGgUWDQoIMzwvgC8xBw4fAAAB/3f+0wCJAAAAFQAABzcmJycmNTQ2NzcXBwYGFRQXFzcXB4lgEQcPDCIdOxY7DA4EGXUY+v8yBw4fGBUcLAwYMxoFFg0KCDM7LoAAAv93AwoAiQQ7AAMABwAAExcHJxMXBydxGPoY+hj6GAO5L4AvAQIvgC4AA/9kAwsAkgQ7AAcAHwAxAAADFxYVFAcHJxc3JiYnJyY1NDY3NzYzMhYXFxYVFAYHBzY2NTQnJyYmIyIHBwYVFBcXN3QtAwkYNw9xCAkFFwkeGzYLCxYmChAJFhXdyQoECwQPCQMIKRkEHkMDzVcGBgoFDGl+OgQJCS4UEhgnCRIDFxUlEhQXJgtxohEJCAcYCQoCDggVBgo9IgAAAv93/s8AiQAAAAMABwAAFxcHJxMXBydxGPoY+hj6GIIvgC8BAi+ALwAAAf93AwoAiQO5AAMAABMXBydxGPoYA7kvgC8AAAL/cgMIAIQEMQAWACgAAAM3JicnJjU0Njc3NjMyFhcXFhUUBgcHNjY1NCcnJiYjIgcHBhUUFxc3jmQPBxcJHhs2DAsWJgkQCRYVz7sKBAsEDwkDCCkZBB5DAzc0BhAuFBIYJwkRAxcUJRMUFiYLa5sRCQgHGQgKAg0IFgUKPiIAAf93/1EAiQAAAAMAADMXBydxGPoYL4AvAAAB/2gDCQCTA7MAHwAAAiY1NTMVFBYzMzI2NzcXBwYWMzM1MxUUBiMjIicGBiNlMzQVDgUNEwMPMQoDEhEiNCEYGTAMCyYUAwk0JUZDDhUQDUsKOBAWcXEZICURFAAAA/9oAwkAkwULAB8AIwAnAAACJjU1MxUUFjMzMjY3NxcHBhYzMzUzFRQGIyMiJwYGIxMXBycTFwcnZTM0FQ4FDRMDDzEKAxIRIjQhGBkwDAsmFLEY+hj6GPoYAwk0JUZDDhUQDUsKOBAWcXEZICURFAGALoEvAQIvgC8AAAT/ZAMJAJMFCQAfACcAPwBRAAACJjU1MxUUFjMzMjY3NxcHBhYzMzUzFRQGIyMiJwYGIwMXFhUUBwcnFzcmJicnJjU0Njc3NjMyFhcXFhUUBgcHNjY1NCcnJiYjIgcHBhUUFxc3ZTM0FQ4FDRMDDzEKAxIRIjQhGBkwDAsmFDQtAwkYNw9xCAkFFwkeGzYLCxYmChAJFhXdyQoECwQPCQMIKRkEHkMDCTQlRkMOFRANSwo4EBZxcRkgJREUAZJXBgYKBQxpfjoECQkuFBIYJwkSAxcVJRIUFyYLcKERCQgHGAkKAg4IFQYKPSIAA/9oAwkAkwUWAB8AIwAnAAACJjU1MxUUFjMzMjY3NxcHBhYzMzUzFRQGIyMiJwYGIxcXBycTFwcnZTM0FQ4FDRMDDzEKAxIRIjQhGBkwDAsmFLEY+hj6GPoYBGw0JUZDDhUQDUsKOBAWcXEZICURFLMvgS8BAy+BLwAC/2gDCQCTBIkAHwAjAAACJjU1MxUUFjMzMjY3NxcHBhYzMzUzFRQGIyMiJwYGIxMXBydlMzQVDgUNEwMPMQoDEhEiNCEYGTAMCyYUsRj6GAMJNCVGQw4VEA1LCjgQFnFxGSAlERQBgC6BLwAD/2gDCQCTBQIAHwA3AEcAAAImNTUzFRQWMzMyNjc3FwcGFjMzNTMVFAYjIyInBgYjJzcmJicnJjU0Njc3NjMyFhcXFhUUBgcHNjU0JycmIyIHBwYVFBcXN2UzNBUOBQ0TAw8xCgMSESI0IRgZMAwLJhROZAEPBhcJHhs2DAsWJgkQCRYVz8UECwoTBwMpGQQeQwMJNCVGQw4VEA1LCjgQFnFxGSAlERT/NAEIDS4UEhgnCREDFxQlEhQXJgtqoRMJBxgSAQ4IFgUKPSIAAAL/aAMJAJMElQAfACMAAAImNTUzFRQWMzMyNjc3FwcGFjMzNTMVFAYjIyInBgYjFxcHJ2UzNBUOBQ0TAw8xCgMSESI0IRgZMAwLJhSxGPoYA+s0JUZDDhUQDUsKOBAWcXEZICURFDIvgS8AAAL/aAMJAJMEdgAfACMAAAImNTUzFRQWMzMyNjc3FwcGFjMzNTMVFAYjIyInBgYjExUjNWUzNBUOBQ0TAw8xCgMSESI0IRgZMAwLJhRbNgMJNCVGQw4VEA1LCjgQFnFxGSAlERQBbZiYAAAC/6QDCQBdA8QADwAfAAASFhUVFAYjIyImNTU0NjMzFiYjIyIGFRUUFjMzMjY1NSozNCQKJDMyJQoqFQ8UEBMUDxQPFQPEMyULJDQ0JAslM0gVFBAJDxUVDwkAAAH/eAMJAJ0DgAALAAACNjMzFSMiBhUVIzWHKSXW2AoLOANTLUELCiEoAAH/mwMJAF0ETgAdAAASFhcXFhUUBgcHJzc2Ni8DJjU0Njc3FwcGHwI7GQMEAisgbQptFRQDA4ALAiQcOBA/HwYDVwPCFhEVDAUhMgUUMhIDGxQSBjsMBR4wChMwFgolEQUAAf+E/yQAiAAAABEAAAYmJic3HgIVNDY2NxcHFSM1HhIeLhgnKxgDMCwjazuLJxUcMxUhMCQCGkEtLHI+LQAB/4QDCQCIA+UAEQAAAiYmJzceAhU+AjcXBxUjNR4SHy0ZJisYAggqLCJqPANZJxcbMhQhMCQOFjktLHI+LQAAAf9V/yQArAAAABkAAAYmNTU0Njc3Njc3FwcGBgcHBgYVFBYzIRUhfi0hGFAUAQQpAwMiGUoJCxALARD+9NwtIAUZJwYTBRAcBh0ZJgURAg0ICg80AAAB/1UDCQCsA+YAGQAAAiY1NTQ2Nzc2NzcXBwYGBwcGBhUUFjMhFSF+LSEYUBQBBCkDAyIZSgkLEAsBEP70AwkuHwUZJwYUBRAcBh0aJQURAw0ICg41AAIAxwLYAZEDHgADAAcAABMzFSM3MxUjx0pKgEpKAx5GRkYAAAEBBwLYAVEDHgADAAABMxUjAQdKSgMeRgAAAQDWAtsBcgNzAAMAAAEjJzMBcj1fUALbmAABAOYC2AGCA3AAAwAAAQcjNwGCXz1MA3CYmAAAAgBNAqwBwgMtAAMABwAAATMHIyczByMBa1eBTTBXgU0DLYGBgQABAEkCqwGeAywABgAAEwcjNzMXI/NhSXxcfUkC/1SBgQAAAQBJAqwBngMtAAYAAAEjJzMXNzMBIVx8RmRlRgKsgVdXAAEASQKsAYsDMgANAAASJiczFhYzMjY3MwYGI6VaAj8BNyoqNwE/AlpFAqxKPCQtLSQ8SgACAOUC2AGMA38ACwAXAAAAJjU0NjMyFhUUBiM2NjU0JiMiBhUUFjMBEy4vJCQwLyUPEhIPDhERDgLYLiUkMC8lJS4zEg4PEhIPDhIAAQBgAtoB+ANnABgAAAAmJyYmIyIGByc2MzIWFxYWMzI2NxcGBiMBWSUSERoVGioSLDtIHiMSERsWGycWKBdBKALaFRMQEB0bI1oUExEQGx0lKDAAAQBJAqwBZQLlAAMAAAEhNSEBZf7kARwCrDkAAAEAQQKeAM8D3AAMAAASJjU0NzcXBwYHFwcnXRwFTjsxDBFGIy8CticYEQzKGH4gEBdhEAABAEH+wwDPAAEADAAAFhYVFAcHJzc2Nyc3F7McBk07MQwRRiMvFycXDw/KGH4hDxdhEAAAAgEH/ygBngAAABAAFAAABTMyNjU0JiMjNzYWFRQGIyM3MwcjARUuEhUVEhERKDMxKT0YOxc6pxQTERQyATEnKDDYWwABAEn/IAEFAB0ADgAAFiY1NDcXBgYVFBYzMxUjiUCVJUA7Ih88R+A1LmA6HRs6IRkdNAD//wBJAqwBngMtBAICyAAA//8AR/8VAu8BsQQnAr8BPv3MAAICEQAA////8v8vASYClwQnAr8Anv6yAAICFAAA////8v8vAWwCdAQnAr8At/6PAAICEwAA//8ASQAAAhICBAQCAeUAAAAAAAAAEgDeAAMAAQQJAAAAdgAAAAMAAQQJAAEACgB2AAMAAQQJAAIADgCAAAMAAQQJAAMAMACOAAMAAQQJAAQAGgC+AAMAAQQJAAUAGgDYAAMAAQQJAAYAGgDyAAMAAQQJAAcAUAEMAAMAAQQJAAgAGAFcAAMAAQQJAAkAGAFcAAMAAQQJAAoAmgF0AAMAAQQJAAsAIAIOAAMAAQQJAAwAQAIuAAMAAQQJAA0AmgF0AAMAAQQJAA4AKgJuAAMAAQQJABAACgB2AAMAAQQJABEADgCAAAMAAQQJAGQByAKYAEMAbwBwAHkAcgBpAGcAaAB0ACAAKABjACkAIAAyADAAMgAxACAAYgB5ACAAdwB3AHcALgBmAG8AbgB0AGkAcgBhAG4ALgBjAG8AbQAgAEEAbABsACAAcgBpAGcAaAB0AHMAIAByAGUAcwBlAHIAdgBlAGQALgBQAGUAeQBkAGEAUgBlAGcAdQBsAGEAcgAzAC4AMAAwADAAOwBLAEgARABNADsAUABlAHkAZABhAC0AUgBlAGcAdQBsAGEAcgBQAGUAeQBkAGEAIABSAGUAZwB1AGwAYQByAFYAZQByAHMAaQBvAG4AIAAzAC4AMAAwADAAUABlAHkAZABhAC0AUgBlAGcAdQBsAGEAcgBQAGUAeQBkAGEAIABpAHMAIABhACAAdAByAGEAZABlAG0AYQByAGsAIABvAGYAIAB3AHcAdwAuAGYAbwBuAHQAaQByAGEAbgAuAGMAbwBtAE4AYQBzAGUAcgAgAEsAaABhAGQAZQBtAFQAbwAgAHUAcwBlACAAdABoAGkAcwAgAGYAbwBuAHQALAAgAGkAdAAgAGkAcwAgAG4AZQBjAGUAcwBzAGEAcgB5ACAAdABvACAAbwBiAHQAYQBpAG4AIAB0AGgAZQAgAGwAaQBjAGUAbgBzAGUAIABmAHIAbwBtACAAdwB3AHcALgBmAG8AbgB0AGkAcgBhAG4ALgBjAG8AbQB3AHcAdwAuAGYAbwBuAHQAaQByAGEAbgAuAGMAbwBtAGgAdAB0AHAAcwA6AC8ALwBkAHIAaQBiAGIAYgBsAGUALgBjAG8AbQAvAG4AYQBzAGUAcgBrAGgAYQBkAGUAbQBmAG8AbgB0AGkAcgBhAG4ALgBjAG8AbQAvAGwAaQBjAGUAbgBzAGUAcwBlAHkASgBwAGQAaQBJADYASQBtAGQAawBNADIATQByAFMARgBNAHYAUQBWAGcAMABPAEgAcABHAGUAaQA4ADMAZQBHADkASABRAGwARQA5AFAAUwBJAHMASQBuAFoAaABiAEgAVgBsAEkAagBvAGkAYQBtADEAVQBXAFcAVgBXAFYAMAA1AHIAWgAxAEIAMQBMADAAcABhAFIAbABZADUAUwBqAGwAQwBUAG0AOQBEAFEAVgBWAHEAUwBUAFoARgBSAG4ATgBIAFUAWABwAGgAYgB6AGgAdABUAEYAbABxAGMAegAwAGkATABDAEoAdABZAFcATQBpAE8AaQBJADAAWgBXAFkAegBNAEQAZABtAFkAMgBaAGwAWQB6AEYAaQBZAFQAaABpAFkAVABZAHcATwBHAEYAbQBZAFQAQQB5AE4ARABVAHkATgBUAFYAagBNAG0AWgBtAE0AagBKAGsATgB6AGcANABZAGoARQA0AFoAagBBADIAWgBXAEYAaABNAGoAawB5AE0ARABFAHkAWQBUAFYAbABNADIAVgBtAE0ARwBRAHoASQBpAHcAaQBkAEcARgBuAEkAagBvAGkASQBuADAAPQAAAAIAAAAAAAD/nAAyAAAAAAAAAAAAAAAAAAAAAAAAAAAC1gAAAAEAAgADACQAJQAmACcAKAApACoAKwAsAC0ALgAvADAAMQAyADMANAA1ADYANwA4ADkAOgA7ADwAPQBEAEUARgBHAEgASQBKAEsATABNAE4ATwBQAFEAUgBTAFQAVQBWAFcAWABZAFoAWwBcAF0AEwAUABUAFgAXABgAGQAaABsAHAARAA8AHQAeABAADgANAEEA2QASAB8AIAAhAAQAIgAKAAUABgAjAAcACAAJAAsADABeAF8AYAA+AD8AQAC2ALcAtAC1AMQAxQCHAEIAsgCzAIwAigCLAL0AhACFAJYA7wCTAPAAuADoAKsAwwCjAKIAgwC8AIgAhgCCAMIAYQC+AL8BAgEDAMkBBADHAGIArQEFAQYAYwCuAJAA/QD/AGQBBwDpAQgBCQBlAQoAyADKAQsAywEMAQ0BDgD4AQ8BEAERAMwAzQDOAPoAzwESARMBFAEVARYBFwDiARgBGQEaAGYBGwDQANEAZwDTARwBHQCRAK8AsADtAR4BHwEgASEA5AD7ASIBIwEkASUBJgEnANQA1QBoANYBKAEpASoBKwEsAS0BLgEvAOsBMAC7ATEBMgDmATMAaQE0AGsAbABqATUBNgBuAG0AoAD+AQAAbwE3AOoBOAEBAHABOQByAHMBOgBxATsBPAE9APkBPgE/AUAA1wB0AHYAdwFBAHUBQgFDAUQBRQFGAUcA4wFIAUkBSgB4AUsAeQB7AHwAegFMAU0AoQB9ALEA7gFOAU8BUAFRAOUA/AFSAIkBUwFUAVUBVgB+AIAAgQB/AVcBWAFZAVoBWwFcAV0BXgDsAV8AugFgAOcBYQFiAWMBZAFlAWYBZwFoAWkBagFrAWwBbQFuAW8BcAFxAXIBcwF0AXUBdgF3AXgBeQF6AXsBfAF9AX4BfwGAAYEBggGDAYQBhQGGAYcBiAGJAYoBiwGMAY0BjgGPAZABkQGSAZMBlAGVAZYBlwGYAZkBmgGbAZwBnQGeAZ8BoAGhAaIBowGkAaUBpgGnAagBqQGqAasBrAGtAa4BrwGwAbEBsgGzAbQBtQG2AbcBuAG5AboBuwG8Ab0BvgG/AcABwQHCAcMBxAHFAcYBxwHIAckBygHLAcwBzQHOAc8B0AHRAdIB0wHUAdUB1gHXAdgB2QHaAdsB3AHdAd4B3wHgAeEB4gHjAeQB5QHmAecB6AHpAeoB6wHsAe0B7gHvAfAB8QHyAfMB9AH1AfYB9wH4AfkB+gH7AfwB/QH+Af8CAAIBAgICAwIEAgUCBgIHAggCCQIKAgsCDAINAg4CDwIQAhECEgITAhQCFQIWAhcCGAIZAhoCGwIcAh0CHgIfAiACIQIiAiMCJAIlAiYCJwIoAikCKgIrAiwCLQIuAi8CMAIxAjICMwI0AjUCNgI3AjgCOQI6AjsCPAI9Aj4CPwJAAkECQgJDAkQCRQJGAkcCSAJJAkoCSwJMAk0CTgJPAlACUQJSAlMCVAJVAlYCVwJYAlkCWgJbAlwCXQJeAl8CYAJhAmICYwJkAmUCZgJnAmgCaQJqAmsCbAJtAm4CbwJwAnECcgJzAnQCdQJ2AncCeAJ5AnoCewJ8An0CfgJ/AoACgQKCAoMChAKFAoYChwKIAokCigKLAowCjQKOAo8CkAKRApICkwKUApUClgKXApgCmQKaApsCnAKdAp4CnwKgAqECogKjAqQCpQKmAqcCqAKpAqoCqwKsAq0CrgKvArACsQKyArMCtAK1ArYCtwK4ArkCugK7ArwCvQK+Ar8CwACpAKoCwQLCAsMCxALFAsYCxwLIAskCygLLAswCzQLOAs8C0ALRAtIC0wLUAtUC1gLXAtgC2QLaAtsC3ALdAt4C3wLgAuEC4gLjAuQC5QLmAucC6ALpAuoC6wLsAu0C7gLvAvAC8QLyAvMC9AL1AvYC9wL4AvkC+gL7AOEC/AL9Av4C/wd1bmkwNjVBB3VuaTA2NUIGQWJyZXZlB0FtYWNyb24HQW9nb25lawpDZG90YWNjZW50BkRjYXJvbgZEY3JvYXQGRWNhcm9uCkVkb3RhY2NlbnQHRW1hY3JvbgdFb2dvbmVrB3VuaTAxOEYHdW5pMDEyMgpHZG90YWNjZW50BEhiYXIHSW1hY3JvbgdJb2dvbmVrB3VuaTAxMzYGTGFjdXRlBkxjYXJvbgd1bmkwMTNCBk5hY3V0ZQZOY2Fyb24HdW5pMDE0NQNFbmcNT2h1bmdhcnVtbGF1dAdPbWFjcm9uBlJhY3V0ZQZSY2Fyb24HdW5pMDE1NgZTYWN1dGUHdW5pMDIxOAd1bmkxRTlFBFRiYXIGVGNhcm9uB3VuaTAxNjIHdW5pMDIxQQ1VaHVuZ2FydW1sYXV0B1VtYWNyb24HVW9nb25lawVVcmluZwZXYWN1dGULV2NpcmN1bWZsZXgJV2RpZXJlc2lzBldncmF2ZQtZY2lyY3VtZmxleAZZZ3JhdmUGWmFjdXRlClpkb3RhY2NlbnQGYWJyZXZlB2FtYWNyb24HYW9nb25lawpjZG90YWNjZW50BmRjYXJvbgZlY2Fyb24KZWRvdGFjY2VudAdlbWFjcm9uB2VvZ29uZWsHdW5pMDI1OQd1bmkwMTIzCmdkb3RhY2NlbnQEaGJhcglpLmxvY2xUUksHaW1hY3Jvbgdpb2dvbmVrB3VuaTAxMzcGbGFjdXRlBmxjYXJvbgd1bmkwMTNDBm5hY3V0ZQZuY2Fyb24HdW5pMDE0NgNlbmcNb2h1bmdhcnVtbGF1dAdvbWFjcm9uBnJhY3V0ZQZyY2Fyb24HdW5pMDE1NwZzYWN1dGUHdW5pMDIxOQR0YmFyBnRjYXJvbgd1bmkwMTYzB3VuaTAyMUINdWh1bmdhcnVtbGF1dAd1bWFjcm9uB3VvZ29uZWsFdXJpbmcGd2FjdXRlC3djaXJjdW1mbGV4CXdkaWVyZXNpcwZ3Z3JhdmULeWNpcmN1bWZsZXgGemFjdXRlCnpkb3RhY2NlbnQHdW5pMDYyMQd1bmkwNjI3DHVuaTA2MjcuZmluYQd1bmkwNjIzDHVuaTA2MjMuZmluYQd1bmkwNjI1DHVuaTA2MjUuZmluYQd1bmkwNjIyDHVuaTA2MjIuZmluYQd1bmkwNjcxDHVuaTA2NzEuZmluYQd1bmkwNjZFDHVuaTA2NkUuZmluYQx1bmkwNjZFLm1lZGkMdW5pMDY2RS5pbml0EHVuaTA2NkUuaW5pdC5hbHQRdW5pMDY2RS5pbml0LmFsdDIRdW5pMDY2RS5pbml0LmFsdDMHdW5pMDYyOAx1bmkwNjI4LmZpbmEMdW5pMDYyOC5tZWRpDHVuaTA2MjguaW5pdBB1bmkwNjI4LmluaXQuYWx0B3VuaTA2N0UMdW5pMDY3RS5maW5hDHVuaTA2N0UubWVkaQx1bmkwNjdFLmluaXQQdW5pMDY3RS5pbml0LmFsdBF1bmkwNjdFLmluaXQuYWx0Mgd1bmkwNjJBDHVuaTA2MkEuZmluYQx1bmkwNjJBLm1lZGkMdW5pMDYyQS5pbml0EHVuaTA2MkEuaW5pdC5hbHQRdW5pMDYyQS5pbml0LmFsdDIHdW5pMDYyQgx1bmkwNjJCLmZpbmEMdW5pMDYyQi5tZWRpDHVuaTA2MkIuaW5pdBB1bmkwNjJCLmluaXQuYWx0EXVuaTA2MkIuaW5pdC5hbHQyB3VuaTA2NzkMdW5pMDY3OS5maW5hDHVuaTA2NzkubWVkaQx1bmkwNjc5LmluaXQHdW5pMDYyQwx1bmkwNjJDLmZpbmEMdW5pMDYyQy5tZWRpDHVuaTA2MkMuaW5pdAd1bmkwNjg2DHVuaTA2ODYuZmluYQx1bmkwNjg2Lm1lZGkMdW5pMDY4Ni5pbml0B3VuaTA2MkQMdW5pMDYyRC5maW5hDHVuaTA2MkQubWVkaQx1bmkwNjJELmluaXQHdW5pMDYyRQx1bmkwNjJFLmZpbmEMdW5pMDYyRS5tZWRpDHVuaTA2MkUuaW5pdAd1bmkwNjJGDHVuaTA2MkYuZmluYQd1bmkwNjMwDHVuaTA2MzAuZmluYQd1bmkwNjg4DHVuaTA2ODguZmluYQd1bmkwNjMxC3VuaTA2MzEuYWx0DHVuaTA2MzEuZmluYRB1bmkwNjMxLmZpbmEuYWx0B3VuaTA2MzIMdW5pMDYzMi5maW5hEHVuaTA2MzIuZmluYS5hbHQLdW5pMDYzMi5hbHQHdW5pMDY5MQx1bmkwNjkxLmZpbmEHdW5pMDY5NQx1bmkwNjk1LmZpbmEHdW5pMDY5OAt1bmkwNjk4LmFsdAx1bmkwNjk4LmZpbmEQdW5pMDY5OC5maW5hLmFsdAd1bmkwNjMzDHVuaTA2MzMuZmluYQx1bmkwNjMzLm1lZGkMdW5pMDYzMy5pbml0B3VuaTA2MzQMdW5pMDYzNC5maW5hDHVuaTA2MzQubWVkaQx1bmkwNjM0LmluaXQHdW5pMDYzNQx1bmkwNjM1LmZpbmEMdW5pMDYzNS5tZWRpDHVuaTA2MzUuaW5pdAd1bmkwNjM2DHVuaTA2MzYuZmluYQx1bmkwNjM2Lm1lZGkMdW5pMDYzNi5pbml0B3VuaTA2MzcMdW5pMDYzNy5maW5hDHVuaTA2MzcubWVkaQx1bmkwNjM3LmluaXQHdW5pMDYzOAx1bmkwNjM4LmZpbmEMdW5pMDYzOC5tZWRpDHVuaTA2MzguaW5pdAd1bmkwNjM5DHVuaTA2MzkuZmluYQx1bmkwNjM5Lm1lZGkMdW5pMDYzOS5pbml0B3VuaTA2M0EMdW5pMDYzQS5maW5hDHVuaTA2M0EubWVkaQx1bmkwNjNBLmluaXQHdW5pMDY0MQx1bmkwNjQxLmZpbmEMdW5pMDY0MS5tZWRpDHVuaTA2NDEuaW5pdAd1bmkwNkE0DHVuaTA2QTQuZmluYQx1bmkwNkE0Lm1lZGkMdW5pMDZBNC5pbml0B3VuaTA2QTEMdW5pMDZBMS5maW5hDHVuaTA2QTEubWVkaQx1bmkwNkExLmluaXQHdW5pMDY2Rgx1bmkwNjZGLmZpbmEHdW5pMDY0Mgx1bmkwNjQyLmZpbmEMdW5pMDY0Mi5tZWRpDHVuaTA2NDIuaW5pdAd1bmkwNjQzDHVuaTA2NDMuZmluYQx1bmkwNjQzLm1lZGkMdW5pMDY0My5pbml0B3VuaTA2QTkLdW5pMDZBOS5hbHQMdW5pMDZBOS5zczAxDHVuaTA2QTkuZmluYRF1bmkwNkE5LmZpbmEuc3MwMQx1bmkwNkE5Lm1lZGkRdW5pMDZBOS5tZWRpLnNzMDEMdW5pMDZBOS5pbml0EHVuaTA2QTkuaW5pdC5hbHQRdW5pMDZBOS5pbml0LnNzMDEHdW5pMDZBRgt1bmkwNkFGLmFsdAx1bmkwNkFGLnNzMDEMdW5pMDZBRi5maW5hEXVuaTA2QUYuZmluYS5zczAxDHVuaTA2QUYubWVkaRF1bmkwNkFGLm1lZGkuc3MwMQx1bmkwNkFGLmluaXQQdW5pMDZBRi5pbml0LmFsdBF1bmkwNkFGLmluaXQuc3MwMQd1bmkwNjQ0DHVuaTA2NDQuZmluYQx1bmkwNjQ0Lm1lZGkMdW5pMDY0NC5pbml0B3VuaTA2QjUMdW5pMDZCNS5maW5hDHVuaTA2QjUubWVkaQx1bmkwNkI1LmluaXQHdW5pMDY0NQx1bmkwNjQ1LmZpbmEMdW5pMDY0NS5tZWRpDHVuaTA2NDUuaW5pdAd1bmkwNjQ2DHVuaTA2NDYuZmluYQx1bmkwNjQ2Lm1lZGkMdW5pMDY0Ni5pbml0B3VuaTA2QkEMdW5pMDZCQS5maW5hB3VuaTA2NDcMdW5pMDY0Ny5maW5hDHVuaTA2NDcubWVkaQx1bmkwNjQ3LmluaXQHdW5pMDZDMAx1bmkwNkMwLmZpbmEHdW5pMDZDMQx1bmkwNkMxLmZpbmEMdW5pMDZDMS5tZWRpDHVuaTA2QzEuaW5pdAd1bmkwNkMyDHVuaTA2QzIuZmluYQd1bmkwNkJFDHVuaTA2QkUuZmluYQx1bmkwNkJFLm1lZGkMdW5pMDZCRS5pbml0B3VuaTA2MjkMdW5pMDYyOS5maW5hB3VuaTA2QzMMdW5pMDZDMy5maW5hB3VuaTA2NDgMdW5pMDY0OC5maW5hB3VuaTA2MjQMdW5pMDYyNC5maW5hB3VuaTA2QzYMdW5pMDZDNi5maW5hB3VuaTA2QzcMdW5pMDZDNy5maW5hB3VuaTA2NDkMdW5pMDY0OS5maW5hB3VuaTA2NEEMdW5pMDY0QS5maW5hEXVuaTA2NEEuZmluYS5zczAxDHVuaTA2NEEubWVkaQx1bmkwNjRBLmluaXQQdW5pMDY0QS5pbml0LmFsdBF1bmkwNjRBLmluaXQuYWx0Mgd1bmkwNjI2DHVuaTA2MjYuZmluYRF1bmkwNjI2LmZpbmEuc3MwMQx1bmkwNjI2Lm1lZGkMdW5pMDYyNi5pbml0EHVuaTA2MjYuaW5pdC5hbHQHdW5pMDZDRQd1bmkwNkNDDHVuaTA2Q0MuZmluYRF1bmkwNkNDLmZpbmEuc3MwMQx1bmkwNkNDLm1lZGkMdW5pMDZDQy5pbml0EHVuaTA2Q0MuaW5pdC5hbHQRdW5pMDZDQy5pbml0LmFsdDIHdW5pMDZEMgx1bmkwNkQyLmZpbmEHdW5pMDc2OQx1bmkwNzY5LmZpbmEHdW5pMDY0MAt1bmkwNjQ0MDYyNxB1bmkwNjQ0MDYyNy5maW5hC3VuaTA2NDQwNjIzEHVuaTA2NDQwNjIzLmZpbmELdW5pMDY0NDA2MjUQdW5pMDY0NDA2MjUuZmluYQt1bmkwNjQ0MDYyMhB1bmkwNjQ0MDYyMi5maW5hC3VuaTA2NDQwNjcxEHVuaTA2NkUwNkNDLmZpbmEVdW5pMDY2RTA2Q0MuX2ZpbmEuYWx0EHVuaTA2MjgwNjQ5LmZpbmEQdW5pMDYyODA2NEEuZmluYRB1bmkwNjI4MDYyNi5maW5hEHVuaTA2MjgwNkNDLmZpbmEQdW5pMDY0NDA2NzEuZmluYRB1bmkwNjdFMDY0OS5maW5hEHVuaTA2N0UwNjRBLmZpbmEQdW5pMDY3RTA2MjYuZmluYRB1bmkwNjdFMDZDQy5maW5hEHVuaTA2MkEwNjQ5LmZpbmEQdW5pMDYyQTA2NEEuZmluYRB1bmkwNjJBMDYyNi5maW5hEHVuaTA2MkEwNkNDLmZpbmEQdW5pMDYyQjA2NDkuZmluYRB1bmkwNjJCMDY0QS5maW5hEHVuaTA2MkIwNjI2LmZpbmEQdW5pMDYyQjA2Q0MuZmluYQt1bmkwNjMzMDY0ORB1bmkwNjMzMDY0OS5maW5hC3VuaTA2MzMwNjRBEHVuaTA2MzMwNjRBLmZpbmELdW5pMDYzMzA2MjYQdW5pMDYzMzA2MjYuZmluYQt1bmkwNjMzMDZDQxB1bmkwNjMzMDZDQy5maW5hC3VuaTA2MzQwNjQ5EHVuaTA2MzQwNjQ5LmZpbmELdW5pMDYzNDA2NEEQdW5pMDYzNDA2NEEuZmluYQt1bmkwNjM0MDYyNhB1bmkwNjM0MDYyNi5maW5hC3VuaTA2MzQwNkNDEHVuaTA2MzQwNkNDLmZpbmELdW5pMDYzNTA2NDkQdW5pMDYzNTA2NDkuZmluYQt1bmkwNjM1MDY0QRB1bmkwNjM1MDY0QS5maW5hC3VuaTA2MzUwNjI2EHVuaTA2MzUwNjI2LmZpbmELdW5pMDYzNTA2Q0MQdW5pMDYzNTA2Q0MuZmluYRp1bmkwNjM2X2ZhcnNpX3VuaTA2Q0MuZmluYQt1bmkwNjM2MDY0ORB1bmkwNjM2MDY0OS5maW5hC3VuaTA2MzYwNjRBEHVuaTA2MzYwNjRBLmZpbmELdW5pMDYzNjA2MjYQdW5pMDYzNjA2MjYuZmluYQt1bmkwNjM2MDZDQxB1bmkwNjQ2MDY0OS5maW5hEHVuaTA2NDYwNjRBLmZpbmEQdW5pMDY0NjA2MjYuZmluYRB1bmkwNjQ2MDZDQy5maW5hEHVuaTA2NEEwNjRBLmZpbmEQdW5pMDY0QTA2Q0MuZmluYRB1bmkwNjI2MDY0OS5maW5hEHVuaTA2MjYwNjRBLmZpbmEQdW5pMDYyNjA2MjYuZmluYRB1bmkwNjI2MDZDQy5maW5hEHVuaTA2Q0MwNkNDLmZpbmEHdW5pRkRGMgd1bmkwNjZCB3VuaTA2NkMHdW5pMDY2MAd1bmkwNjYxB3VuaTA2NjIHdW5pMDY2Mwd1bmkwNjY0B3VuaTA2NjUHdW5pMDY2Ngd1bmkwNjY3B3VuaTA2NjgHdW5pMDY2OQd1bmkwNkYwB3VuaTA2RjEHdW5pMDZGMgd1bmkwNkYzB3VuaTA2RjQHdW5pMDZGNQd1bmkwNkY2B3VuaTA2RjcHdW5pMDZGOAd1bmkwNkY5DHVuaTA2RjQudXJkdQx1bmkwNkY3LnVyZHUHdW5pMzAwMAd1bmkyMDVGB3VuaTIwMEUHdW5pMjAwRgd1bmkyMDBEB3VuaTIwMEMHdW5pMjAwMQd1bmkyMDAzB3VuaTIwMDAHdW5pMjAwMgd1bmkyMDA1B3VuaTIwMEEHdW5pMjAyRgd1bmkyMDA2B3VuaTIwMDkHdW5pMjAwNAd1bmkyMDBCB3VuaTA2RDQHdW5pMDYwQwd1bmkwNjFCB3VuaTA2MUYHdW5pMDY2RAd1bmlGRDNFB3VuaUZEM0YHdW5pRkRGQwd1bmkwNjZBB3VuaTA2MTUKZG90YWJvdmVhcgpkb3RiZWxvd2FyC2RvdGNlbnRlcmFyFnR3b2RvdHN2ZXJ0aWNhbGFib3ZlYXIWdHdvZG90c3ZlcnRpY2FsYmVsb3dhchh0d29kb3RzaG9yaXpvbnRhbGFib3ZlYXIYdHdvZG90c2hvcml6b250YWxiZWxvd2FyFHRocmVlZG90c2Rvd25hYm92ZWFyFHRocmVlZG90c2Rvd25iZWxvd2FyEnRocmVlZG90c3VwYWJvdmVhchJ0aHJlZWRvdHN1cGJlbG93YXIHd2FzbGFhcgttaW5pS2VoZWhhchFnYWZzYXJrYXNoYWJvdmVhchVnYWZzYXJrYXNoYWJvdmVhci5hbHQSZ2Fmc2Fya2FzaGNlbnRlcmFyB3VuaTA2NzAHdW5pMDY1Ngd1bmkwNjU0B3VuaTA2NTUHdW5pMDY0Qgd1bmkwNjRDB3VuaTA2NEQHdW5pMDY0RQd1bmkwNjRGB3VuaTA2NTAHdW5pMDY1MQt1bmkwNjUxMDY0Qgt1bmkwNjUxMDY0Qwt1bmkwNjUxMDY0RAt1bmkwNjUxMDY0RQt1bmkwNjUxMDY0Rgt1bmkwNjUxMDY1MAt1bmkwNjUxMDY3MAd1bmkwNjUyB3VuaTA2NTMIc2FyZXlhYXIRc2V2ZW5zYW1sbC5ib3R0b20Qc2V2ZW5zbWFsbC5hYm92ZQ55ZWhzYW1sLmJvdHRvbQ15ZWhzbWFsLmFib3ZlB3VuaTAzMDgHdW5pMDMwNwlncmF2ZWNvbWIJYWN1dGVjb21iB3VuaTAzMEIHdW5pMDMwMgd1bmkwMzBDB3VuaTAzMDYHdW5pMDMwQQl0aWxkZWNvbWIHdW5pMDMwNAd1bmkwMzEyB3VuaTAzMjYHdW5pMDMyNwd1bmkwMzI4DHVuaTA2Y2UuZmluYQx1bmkwNmNlLmluaXQMdW5pMDZjZS5tZWRpDHVuaTA2ZDUuZmluYQAAAQACAA4AAAAAAAAANgACAAYAgwCEAAMBNQIbAAECHAJjAAICmAK8AAMCwgLQAAMC0gLVAAEAAQACAAAADAAAABgAAQAEAqoCrAKvArIAAQAVAIMAhAKYAqQCpQKpAqsCrQKuArACsQKzArQCtQK2ArcCuAK5AroCuwK8AAEAAAAKAH4AugADREZMVAAUYXJhYgAYbGF0bgAuAFQAAAAKAAFVUkQgAFAAAP//AAMAAAADAAQALgAHQVpFIAA6Q1JUIAA6S0FaIAA6TU9MIAA6Uk9NIAA6VEFUIAA6VFJLIAA6AAD//wADAAEAAgAEAAD//wADAAAAAgAEAAVrZXJuACBrZXJuACBtYXJrACptYXJrACpta21rADQAAAADAAAAAQACAAAAAwADAAQABQAAAAIABgAHAAgAEgXyFvgZmhpOJ3wx9jJsAAIACAACAAoEKgABAEQABAAAAB0C5ALkAIIAggLyAIgAtgEYARgBJgGAAYoB/AIKAnwC1gLWAuQC5ALyAvIDCAMOAxwD6gPwBAYEEAQWAAEAHQBCAEMARABFAEYASABLAFEAUgBYAFkAWgBcAF0AXgBhAGMAZABlAGgAaQB3AHgAeQCBAIICcAJ2AncAAQAZ//MACwAE/9sADf/tABcABQAd//cAIP/wACH/7AAi//AAJP/yACz/8AAu/+wAMP/1ABgABP/WAAb/+gAK//kADf/tABL/+QAU//kAHv/qACD/3wAh/94AIv/fACT/4AAq/+wAK//sACz/3wAt/+wALv/eAC//7AAw/+UAMv/uADP/+QA0//oANv/4ADf/9wBLAAAAAwBL/8AAVP/0AFf/5QAWAAb/9AAK//MAEv/zABT/8wAe//oAIP/uACH/7QAi/+4AI//7ACcACwAq//sAK//7ACz/7gAt//sALv/tAC//+wAw//sAMv/xADP/+wA0//gANv/7AFr/9QACAFz/+gBf//oAHAAE/+8ABv/qAAr/6QAS/+kAFP/pABb/9wAe/+cAIP/hACH/4QAi/+EAI//3ACcACgAq/+wAK//sACz/4QAt/+wALv/hAC//7AAw/+4AMf/xADL/5AAz/+gANP/mADX/8wA2/+kAN//yAFj/+gBa/+4AAwBZ//UAXP/uAF//6wAcAAT/7AAG/+gACv/mABL/5gAU/+YAFv/3AB7/4wAg/9wAIf/dACL/3AAj//EAJwAEACr/6wAr/+sALP/cAC3/6wAu/90AL//rADD/6wAx/+kAMv/gADP/4gA0/+EANf/xADb/5AA3/+8AWP/6AFr/6wAWAAb/9gAK//YAEv/2ABT/9gAW//sAF//IABj/9QAZ/9MAGv/hABz/vAAg//sAIv/7ACP/+gAs//sAMf/zADP/6QA0/+8ANv/qAFH/ugBS/7oAYf+8AGP/vAADAEv/uQBU/+gAV//jAAMAGf/NACP/9QAz/98ABQAZ/+IAG//aACP/9QAz//QANf/jAAEAKf/IAAMAF//TABn/+gAc/+AAMwAE/94ABf/mAAb/5gAH/+YACP/mAAn/5gAK/+YAC//mAAz/5gAN//UADv/mAA//5gAQ/+YAEf/mABL/5gAT/+YAFP/mABX/5gAW/+cAF/+0ABj/5QAZ/9YAGv/d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ABn/4gAb//gAM//4ADX//QBQ/+0AWf/6AFz/6ABe/90AX//rAGr/8gAYAAT/5AAN/+oAF//mABv/9QAc//kAHf/3ACD/9wAh//gAIv/3ACT/+wAs//cALv/4AEL/2ABD/9gARv/YAEv/5QBX//gAZP/YAGX/2ABo/9gAaf/YAHb/2ACB/+AAgv/uAAMAGf/4ACcAEwBe//kABQAZ//gAUP/6AFz/9QBe//cAX//yAAEAd//IAAkAGf/jADP//ABI//0AUP/sAFn/+wBc/+wAXv/bAF//6gBq//AACwAZ/+AAG//rADP/9wA1//QASP/9AFD/6wBZ/+4AXP/hAF7/2gBf/9wAav/yAAsAGf/iABv/7AAz//gANf/1AEj/+ABQ/+gAWf/tAFz/4QBe/9sAX//dAGr/7wAHABv/5QBL/98AV//4AFn/+wBc/+sAXv/7AF//5QAKABn/6wAb//0AM//5ADX//QBQ//UAWf/5AFz/5wBe/+kAX//iAGr/9QAEABn/9gBc//oAXv/3AF//9wAIABn/5gAb//gAUP/1AFn/+wBc/+wAXv/pAF//6wBq//UAHgAE/+8ADf/oABf/wAAZ//gAG//nABz/2QAd//MAHv/4ACD/9wAh//gAIv/3ACT/9wAs//cALv/4ADD/+wBC/98AQ//fAEb/9ABL/+wAUP/4AFn/+wBc/+cAXv/3AF//4gBk/98AZf/fAGj/9ABp//QAdv/fAIH/9AAIABn/9wAb/+cAS//vAFD/+ABZ//gAXP/mAF7/9wBf/+EAEgAN//0AF/+8ABn/+gAc/9oAHv/9ACD/9AAh//QAIv/0ACT/9gAs//QALv/0AEb/4gBc//MAXv/5AF//8ABo/+IAaf/iAIH/5gAHABn/+AAb/+cAS//rAFD/+ABc/+oAXv/3AF//5QAGABn/8wBQ//oAXP/yAF7/9ABf/+8Aav/7AAQADf/6ABf/8wAZ//oAHP/kABEABv/6AAr/+gAS//oAFP/6ABf/2QAY//sAGf/hABr/7QAc/8sAMf/6ADP/9QA0//gANv/1AFH/0QBS/9EAYf/SAGP/0gADAAT/5QAN/+wAHf/7AAcABP/mAA3/6gAX//gAGf/6ABv/+AAc/+oAHf/1AAIHUAAEAAAHZggkACAAHQAA//r/9f/9//b/9//x/+P//f/7//X/8f/zAAAAAAAA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CE4IVAhaCGAIZghsCJYIcgh4CH4IrgiECIoIkAiWCJwIogioCK4ItAi6CMAIxgjMCNII2AkgCN4I5AjqCPAI9gj8CQIJCAkOCRQJGgkgCSYAAAksAAAJMgl6CTgJegk+CUQJSgnCCVAJVglcCWIJaAluCXQJegmACYYJjAmSCZgJngmkCaoJsAm2CbwJwgnICc4J1AnaCeAJ5gnsCfIJ+An+CgQKCgoQChYKHAoiCigKLgo0CjoKQApGCkwMegpSAAAKWAAACl4AAApkAAAKagpwCnYKfAqCCogKjgqUCpoKoAqmCqwKsgq4Cr4KxArKCtAK1grcCuIK6AruCvQK+gsACwYLfgsMAAALEgAACxgLHgskCyoLMAs2CzwLQgtIAAALTgAAC1QLWgtgC2YLbAtyC3gLfguEC4oLkAuWC5wLoguoC64LtAu6C8ALxgvMAAAL0gAAC9gAAAveAAAL5AAAC+oAAAvwC/YL/AykDAIMCAwODBQMGgwgDCYMLAwyDDgMPgxEDEoMUAxWAAAMXAAADGIAAAxoDG4MdAx6DIAMhgyMAAAMkgyYDJ4MpAyqDLAMtgy8DMIMyAzODNQM2gzgDOYAAAzsAAAM8gAADPgAAAz+DQQNCgABAP//6wABAQAB6gABAHH/nAABAGwC+gABAI//nAABAHMDAQABAGwD/QABAH4EBwABAHv+mQABAJD+mAABAJEDKAABAI8DMgABAMID0AABAKYD2QABAbr/nAABAbgBuAABAcf/nAABAb0BvAABALP/nAABALcBmwABAJP/nAABAJIBzQABAJX/nAABAJ4B0QABALABvQABAJn/nAABALkBvgABAbP+xAABAbYBwwABAbL+xgABAbABxwABAK4BoAABAGr+vwABAJABywABAH7+0AABAK0BxAABAbL+TAABAcMBxwABAcb+RwABAb8BxwABAK/+SAABALMBmwABAIT+SgABAJEBwAABALP+QwABAKcBsQABALf+gQABAL8BbgABAcD/lQABAaoB3AABAbn/lQABAaoB5QABAK7/nAABALMCaAABAI7/nAABAJgCjQABAJj/mgABALwCigABAKL/nAABAKECkAABAa7/nAABAb7/nAABAa4CmwABAKj/nAABAK0C6wABAJb/nAABAJcDDQABAJz/nAABAOEDCwABAJf/nAABAJ0DBwABAZ4CwwABAaYCwwABALIC7QABAIsDBgABASn+WAABAPICAQABAQD+VwABAPAB/wABATv+wgABAMMB7AABAT3+ygABAM0B7AABAP7+WAABANwCAQABAQv+UwABAOIBvwABATj+SgABANcB5wABATb+SAABAMgB6gABAQX+UAABAPb+TAABANACAAABAL0B7AABAOb/nAABALkB6wABAN7+WgABANUC3AABAOf+WwABANYC7AABAMn/nAABAL4CygABAMP/nAABAL8CzgABASMCRQABAR7/lwABATECUwABAQP/mAABAQ0DAQABAP//lAABAVUDHQABATADhgABAVcDqAABAHf+zgABALoBpAABAGb+0gABAJIBpAABAG7+0AABANYBoAABAIn+6AABAJcBqAABAID+5AABAM4CcgABAJL+5AABANcCdQABAH/+8gABAJcCcwABAHP+3AABAJQCbgABAMYC9wABANoC+wABAID9fgABAIH9fwABAIH+0wABAM4C7gABAHn+5wABAJYC7gABAIn+4QABANYC7wABAH7+7QABAJMC7wABAzL/nQABA0MBpAABA0n/mgABA0YBmQABAYYBoAABAXf/nAABAYYBoQABAzT/nAABAzsC5wABAzz/nAABAzkC3wABAXn/nAABAXgC5gABAXH/nAABAXkC5wABA27/nQABA8sBzgABA3v/nAABA8cByQABAbP/nAABAgMBzQABAar/nAABAgEB0AABA3P/nAABA9ACowABA3r/nAABA9ECoQABAaH/nAABAhACnQABAab/nAABAhMCmwABAhQByAABAW7/nAABAhIBygABARn/nAABAc8BwAABARv/nAABAc4BxQABAVz/nAABAeQCjAABAWL/nAABAegCjQABAUL/nAABAawCjgABATP/nAABAawCjwABAQr+DQABAQMB6wABARn+CwABASoB8wABASz/nAABASgB8QABANT/oAABAOUCCwABANL+IQABARUCsAABAOn+EQABASUCqQABASn/nAABASQCsgABALH/nAABAO4CsgABAZD/nAABAnQDPgABAr0CxgABAN7/nAABANkCygABAOQDRAABAZz/nAABAmkDpgABAZH/nAABAsUDKwABAOv/nAABAN0DKAABALn/nAABAOQDqwABAan/mAABAm4CcAABAZ3/mAABAsMB+AABAOj/nAABAOAB9AABAOoCaAABATX+uQABAc0BzQABAS7+tgABAc0BygABASX+uwABAc4ClwABASX+ugABAc8CjwABAOP/nAABAOECvgABAM3/nAABAN0DNwABAbICpwABAbgCowABALUC8QABAK4C4wABAaT/mgABAhMCkwABAhkCjAABAhz/nAABAUUB0QABAa3/mgABAhkCjgABAib/nAABAR4BzwABAMn/mQABAJ4C7AABATb/mgABAHwCdwABAKT/mwABAKQC1wABAIr/mwABAI8CzgABARr/nAABAIQCkAABAaf/mAABAgQDCQABAa7/mAABAgADDgABAjv/nAABAT0CZQABAbn/mAABAgsDBwABAhb/nAABATcCXQABAMP/mQABAH8DRgABAV//nAABAGcCvgABAH//mQABAHgDKwABAHf/mQABAIMDMQABASr/nAABAGcCzQABAWr+5QABAS8BhgABAWH+8AABATsBiwABAKH/nAABAKgC+gABAKIDAQABASoB1AABATwBnQABALYEDQABAKUEDwABAYP/qQABAUgBzQABAav/nAABAVYBxgABARz/nAABAR0ByQABARb/nAABARsB0AABAWX+5gABAV8B9QABAT3+8gABAWEB+AABAKv/nAABALMCZAABAJH/nAABAL4CgwABAWf+4QABAVkBYgABAWj+3wABAWABnwABAPr/lgABAOsCHwABAPr/zgABAQACTQABAPX+5gABAQoBvQABAQwCNAABAOUDqAABANgDxQABAPD/nAABANUCHQABAQX/ywABATIBkQABAPP+0QABAQABdQABAIP+FgABAJEB2QABAO0DhQABAPMDfwABASv/nAABAQkCLgABAVH+lgABAToBvAABAWX/lgABAUYCCAABAST/nAABAUkCJAABAPH/nAABAO0C4gABAPT/zgABAOoDGQABAP3/nAABAPgC6gABAQv/rQABAS8CTAABAPL+zQABAPIBzAABAPf+zAABAO4B1AABAPgDJAABAQMDLwABAQAC/wABAP0C+wABAPoDLQABAPkDPAABAXX+5wABAMABjQABAVwBAgABAWz+RAABAMABigABAWX+BQABAU4A/wABAVL99QABAUUAwAABAKr+0wABAK8BoQABAJL+0wABAKABvAABAKT+xgABAKkBvwABALT+xgABAL8BqwABANgDCAABAPYCygABAO0CIAABALL/nAABAL8DIgABAIb/nAABAJoDYgABAKP/nAABAKsDOwABAMACpgABAXP+7QABAMYBmQABAWT+owABAXUA/AABAU3+pAABAToAyQABAKz+ygABALsBoQABAIb+ywABAJ8ByAABAKz+xgABAJ8BuAABAKf+xwABALABtQABATYCBAABATYAvAABAWIDAQABAWMDCQABAGP/nAABAGAA5QAFAAAAAQAIAAEADAAoAAIAMgCYAAIABACDAIQAAAKYApgAAgKkAqUAAwKpArwABQACAAECHAJiAAAAGQABC4QAAQuEAAELlgABC5YAAQuWAAELigAACoQAAQuWAAAKhAABC5YAAQuQAAAKhAABC5YAAQuWAAAKhAABC5YAAQuWAAELlgABC5YAAQuWAAELlgABC5YAAQuWAAELlgABC5YARwCQALIA1AD2ARgBOgFcAX4BoAHCAeQCBgIoAkoCbAKOArAC0gL0AxYDOANaA3wDngPAA+IEBAQmBEgEagSMBKgEygTmBQgFKgVMBW4FkAWsBc4F8AYSBjQGVgZ4BpQGtgbSBvQHFgc4B1oHfAeeB8AH4ggECCYISAhqCIwIrgjQCPIJFAk2CVIJdAmWCbgAAgAKABAAFgAcAAEBlv+0AAEBtAMaAAEAiP9wAAEAewKsAAIACgAQABYAHAABAZr/qwABAb0DGAABAHz/eAABAHwCswACAAoAEAAWABwAAQGU/7gAAQG5Ax0AAQB9/5AAAQCbA+MAAgAKABAAFgAcAAEBtv+nAAEBxQMhAAEAnP+PAAEAmwQFAAIACgAQABYAHAABAbb/ogABAakDCwABAMT+UwABAIkCoQACAAoAEAAWABwAAQHd/5wAAQGzAxsAAQDc/mMAAQCFArgAAgAKABAAFgAcAAEBr/+9AAEBywM2AAEAjP92AAEAhgNfAAIACgAQABYAHAABAar/swABAdADMAABAJb/dwABAKQDYAACAAoAEAAWABwAAQGd/7QAAQHqA2AAAQCa/2IAAQCgA6QAAgAKABAAFgAcAAEC4f8sAAECgQHvAAEBWf6jAAEAvAGdAAIACgAQABYAHAABAvL/QgABAoYB5gABAV3+qwABALsBnQACAAoAEAAWABwAAQL+/s4AAQJ1AbgAAQFY/roAAQC8AVkAAgAKABAAFgAcAAEC//7VAAECnAHXAAEBZ/4WAAEAoQFzAAIACgAQABYAHAABAv7+ygABApYB4wABAWP+vAABALwC6AACAAoAEAAWABwAAQLy/tAAAQJzAb4AAQFi/r4AAQCuAVEAAgAKABAAFgAcAAEBof+xAAEB/QMsAAEAhv+DAAEA0AOuAAIACgAQABYAHAABAyj+TgABAo0B0wABAVX+vwABAK8BYAACAAoAEAAWABwAAQMm/loAAQKXAcgAAQFm/foAAQDDAU4AAgAKABAAFgAcAAEDTv48AAECowHiAAEBX/6uAAEAzALXAAIACgAQABYAHAABAy3+VgABApwBvAABAVP+ngABAJUBfQACAAoAEAAWABwAAQLI/zQAAQKHArAAAQFV/qAAAQDBAX8AAgAKABAAFgAcAAEC5/81AAECegKnAAEBeP3ZAAEAvAFoAAIACgAQABYAHAABAvb/DQABAo4CogABAUD+qAABAM4C9QACAAoAEAAWABwAAQLe/xoAAQKFApgAAQFX/pYAAQCuAYIAAgAKABAAFgAcAAEC3f8kAAECgwMdAAEBXf6XAAEAwAF2AAIACgAQABYAHAABAuP/LQABAnsDIQABAWj+CQABALsBcwACAAoAEAAWABwAAQLV/x0AAQKMAykAAQFf/pwAAQDgAwQAAgAKABAAFgAcAAEC5v85AAECfgMkAAEBXP6kAAEAuAFdAAIACgAQABYAHAABA9j/lwABA+8BqwABAWz+oAABAOMBjQACAAoAEAAWABwAAQPQ/4gAAQPgAboAAQFo/qoAAQDOAX8AAgCoAAoAEAAWAAED5gG0AAEBdP3wAAEAuQF/AAIACgAQABYAHAABA9//kQABA+UBvQABAXD98QABAMYBgwACANAACgAQABYAAQPhAbQAAQFe/qIAAQD+AtYAAgAKABAAFgAcAAED5P+jAAED4AGtAAEBYv6mAAEA9ALjAAIACgAQABYAHAABA+H/nAABA9MBugABAUz+rgABAMgBiwACAAoAEAAWABwAAQPg/5wAAQPcAbIAAQFZ/qQAAQDBAW4AAgAKABAAFgAcAAED6/+cAAEDwgLlAAEBaf6fAAEAqAFzAAIACgAQABYAHAABA/L/nAABA8cC3gABAWP+pgABALgBiQACAAoAkgAQABYAAQPi/5wAAQFz/eoAAQDJAYgAAgAKABAAFgAcAAED2/+cAAEDyQLtAAEBcf34AAEAtwF8AAIACgAQABYAHAABA93/nAABA9AC3gABAVv+nwABANMC3AACAAoAEAAWABwAAQPt/5wAAQPFAt4AAQFH/o4AAQDzAtwAAgAKABAAFgAcAAED5f+cAAEDzQLeAAEBWP6dAAEA1AF8AAIACgAQABYAHAABA9z/nAABA8kC3gABAVf+nwABAMQBfwACAAoAEAAWABwAAQP+/5wAAQRzAecAAQFf/qYAAQClAZ0AAgCGAAoAEAAWAAEEeAHnAAEBY/6gAAEAxAGAAAIACgAQABYAHAABBA3/nAABBHUB5wABAWv9/AABANsBhAACAIwACgAQABYAAQRtAeQAAQFm/f0AAQDMAXQAAgAKABAAFgAcAAEENf+cAAEESgHnAAEBUP63AAEA6gLTAAIACgAQABYAHAABBBb/nAABBHIB5wABAWD+mgABAOMCyQACAAoAEAAWABwAAQQf/5wAAQRoAecAAQFR/qIAAQC+AXwAAgAKABAAFgAcAAEEE/+cAAEEYQHnAAEBaf6jAAEAvQGCAAIACgAQABYAHAABBBf/nAABBIECpwABAWD+owABAM8BeAACAAoAEAAWABwAAQQj/5wAAQR+ArsAAQFU/psAAQDSAXMAAgAKABAAFgAcAAEEB/+cAAEEgAKsAAEBWv6VAAEAyQFsAAIACgAQABYAHAABBE//nAABBIcCwwABAYX9qQABAOkBnQACAAoAEAAWABwAAQQm/5wAAQSCAqkAAQFt/ggAAQDIAXUAAgAKABAAFgAcAAEEJP+cAAEEewKdAAEBWf66AAEA7wLLAAIACgAQABYAHAABBA//nAABBIQCqAABAVv+ugABAPUCvQACAAoAEAAWABwAAQQa/5wAAQSHAqYAAQFd/rAAAQDtAZ0AAgAKABAAFgAcAAEC1/9ZAAEChgKZAAEBWf6fAAEAsAF7AAIACgAQABYAHAABAtj/PAABAn8CmgABAXP+AAABANABYwACAAoAEAAWABwAAQLq/08AAQJ+ApsAAQFm/qEAAQC/AvwAAgAKABAAFgAcAAEC1v88AAEChwKUAAEBVf6zAAEAuwF2AAIACgAQABYAHAABAyP+1AABApoB1QABAW/+JwABAMQBeAACAAoAEAAWABwAAQMi/sUAAQKaAdEAAQFN/o4AAQDRAWQAAgBIAAoAEAAWAAECewNfAAEBXf6gAAEAwAFqAAIACgAQABYAHAABAtv/UgABAosDWQABAWv+CQABAMgBgQACAAoAEAAWABwAAQMN/2AAAQKLA2sAAQFW/o8AAQDGAs4AAgAKABAAFgAcAAEC7v9gAAECewNtAAEBXP6cAAEAvgF0AAIACgAQABYAHAABAxr+ywABAo0B1QABAVP+rgABAMwBZwAGABAAAQAKAAAAAQAMABgAAQAoAEAAAQAEAqoCrAKvArIAAQAGAqoCrAKvArICvgLAAAQAAAASAAAAEgAAABIAAAASAAEAAAAAAAYADgAUABoAIAAmACYAAQAA/yYAAQAA/ssAAQAA/t4AAQAA/2EAAQAA/vwABgAQAAEACgABAAEADAA6AAEAbgDcAAEAFQCDAIQCmAKkAqUCqQKrAq0CrgKwArECswK0ArUCtgK3ArgCuQK6ArsCvAABABgAgwCEApgCpAKlAqkCqwKtAq4CsAKxArMCtAK1ArYCtwK4ArkCugK7ArwCvQK/AsEAFQAAAFYAAABWAAAAaAAAAGgAAABoAAAAXAAAAGgAAABoAAAAYgAAAGgAAABoAAAAaAAAAGgAAABoAAAAaAAAAGgAAABoAAAAaAAAAGgAAABoAAAAaAABAAACvAABAAADCgABAAADCwABAAADCQAYADIAMgA4AD4ARABKAFAAVgBcAGIAaABuAHQAegCAAIYAjACSAJgAngCkAKoAsAC2AAEAAAO7AAEADAQcAAEAGgP6AAH/9AQ0AAEAAAPkAAEAAARYAAEAAARcAAEAAARiAAEAAAPZAAEAAARZAAEAAAPdAAEAAAUwAAEAAAU7AAEAAAU/AAEAAASpAAEAAAUvAAEAAAS/AAEAAASeAAEAAAPwAAEAAAOoAAEAAAR0AAEAAAQOAAEAAAQPAAEAAAAKAVwCIAADREZMVAAUYXJhYgAYbGF0bgBWAHAAAAAKAAFVUkQgACQAAP//AAoAAAABAAMABAAFAAYADwAQABEAEgAA//8ACgAAAAEAAgAEAAUABgAOAA8AEQASAC4AB0FaRSAARkNSVCAAYEtBWiAAek1PTCAAlFJPTSAArlRBVCAAyFRSSyAA4gAA//8ACQAAAAEAAgAEAAUABgAPABEAEgAA//8ACgAAAAEAAgAEAAUABgAHAA8AEQASAAD//wAKAAAAAQACAAQABQAGAAgADwARABIAAP//AAoAAAABAAIABAAFAAYACQAPABEAEgAA//8ACgAAAAEAAgAEAAUABgANAA8AEQASAAD//wAKAAAAAQACAAQABQAGAAwADwARABIAAP//AAoAAAABAAIABAAFAAYACgAPABEAEgAA//8ACgAAAAEAAgAEAAUABgALAA8AEQASABNhYWx0AHRjYWx0AHpjY21wAIBjY21wAIBkbGlnAIhmaW5hAI5pbml0AJRsb2NsAJpsb2NsAJpsb2NsAJpsb2NsAJpsb2NsAJpsb2NsAKBsb2NsAKBsb2NsAKZtZWRpAKxybGlnALJzYWx0ALhzczAxAL4AAAABAAAAAAABAA0AAAACAAEAAgAAAAEACgAAAAEACAAAAAEABgAAAAEAAwAAAAEABAAAAAEABQAAAAEABwAAAAEACQAAAAEACwAAAAEADAATACgERgSIBTYFRAVeBXwF0gZ0B7oILAp4Cs4LGAzuDQINMA1ODWwAAwAAAAEACAABAzgAbQDgAOQA6ADsAPAA9AD4APwBAAEEAQgBEAEYARwBJAEqATIBOAFAAUYBTgFWAV4BZgFuAXIBdgF6AYABhAGKAY4BkgGWAZwBoAGoAbABuAHAAcgB0AHYAeAB6AHwAfgB/AIEAiACJAIoAhACHAIgAiQCKAIuAjICPgJCAkYCTAJUAlwCZAJsAnACeAJ8AoQCiAKQApQCmAKcAqACpAKsArACtgK+AsICxgLOAtYC2gLgAuQC6ALsAvAC9AL4AvwDAAMEAwgDDAMQAxQDGAMcAyADJAMoAywDMAM0AAEA/wABAMQAAQDJAAEBHQABASIAAQE3AAEBOQABATsAAQE9AAEBPwADAUMBQgFBAAMBSgFJAUgAAQFLAAMBTwFOAU0AAgFRAVAAAwFVAVQBUwACAVYBVwADAVsBWgFZAAIBXAFdAAMBYQFgAV8AAwFlAWQBYwADAWkBaAFnAAMBbQFsAWsAAwFxAXABbwABAXMAAQF1AAEBdwACAXoBeQABAXsAAgF9AX8AAQF+AAEBgQABAYMAAgGGAYUAAQGHAAMBiwGKAYkAAwGPAY4BjQADAZMBkgGRAAMBlwGWAZUAAwGbAZoBmQADAZ8BngGdAAMBowGiAaEAAwGnAaYBpQADAasBqgGpAAMBrwGuAa0AAwGzAbIBsQABAbUAAwG5AbgBtwAFAb0BvAG7AcABvwAFAcUBwwHBAcABvwABAcAAAQHCAAEBxAACAccBxgABAccABQHPAc0BywHKAckAAQHMAAEBzgACAdEB0AADAdUB1AHTAAMB2QHYAdcAAwHdAdwB2wADAeEB4AHfAAEB4wADAecB5gHlAAEB6QADAe0B7AHrAAEB7wADAfMB8gHxAAEB9QABAfcAAQH5AAEB+wABAgEAAwIGAgUCAwABAgQAAgIIAgcAAwINAgwCCgABAgsAAQIOAAMC0wLUAtIAAwIUAhMCEQABAhIAAgIWAhUAAQIYAAECGgABAh0AAQIfAAECIQABAiMAAQIrAAECOQABAjsAAQI9AAECQQABAkMAAQJFAAECSQABAksAAQJNAAECUgABAlQAAQJWAAECegABAmwAAQJ7AAEAbQAmAMMAyAEcASEBNgE4AToBPAE+AUABRwFKAUwBTwFSAVUBWAFbAV4BYgFmAWoBbgFyAXQBdgF4AXoBfAF9AYABggGEAYYBiAGMAZABlAGYAZwBoAGkAagBrAGwAbQBtgG6AbsBvAG9Ab4BvwHBAcMBxQHGAcgBywHNAc8B0gHWAdoB3gHiAeQB6AHqAe4B8AH0AfYB+AH6AgACAgIDAgYCCQIKAg0CDwIQAhECFAIXAhkCHAIeAiACIgIkAjgCOgI8AkACQgJEAkgCSgJMAlECUwJVAnQCdgJ3AAYAAAACAAoAHAADAAAAAQisAAEALgABAAAADgADAAAAAQiaAAIAFAAcAAEAAAAOAAEAAgLPAtAAAgABAsICzQAAAAQAAAABAAgAAQCWAAgAFgAgACoANAA+AEgAUgBcAAEABAK6AAICswABAAQCtAACArMAAQAEArUAAgKzAAEABAK2AAICswABAAQCtwACArMAAQAEArgAAgKzAAEABAK5AAICswAHABAAFgAcACIAKAAuADQCugACAqkCtAACAq0CtQACAq4CtgACAq8CtwACArACuAACArECuQACArIAAgACAqkCqQAAAq0CswABAAEAAAABAAgAAQe+ANkAAQAAAAEACAABAAYAAQABAAQAwwDIARwBIQABAAAAAQAIAAIADAADAnoCbAJ7AAEAAwJ0AnYCdwABAAAAAQAIAAIApAAkAUMBSgFPAVUBWwFhAWUBaQFtAXEBiwGPAZMBlwGbAZ8BowGnAasBrwGzAbkBvQHFAc8B1QHZAd0B4QHnAe0B8wIGAg0C0wIUAAEAAAABAAgAAgBOACQBQgFJAU4BVAFaAWABZAFoAWwBcAGKAY4BkgGWAZoBngGiAaYBqgGuAbIBuAG8AcMBzQHUAdgB3AHgAeYB7AHyAgUCDALUAhMAAQAkAUABRwFMAVIBWAFeAWIBZgFqAW4BiAGMAZABlAGYAZwBoAGkAagBrAGwAbYBugG+AcgB0gHWAdoB3gHkAeoB8AICAgkCDwIQAAEAAAABAAgAAgCgAE0BNwE5ATsBPQE/AUEBSAFNAVMBWQFfAWMBZwFrAW8BcwF1AXcBegF9AYEBgwGGAYkBjQGRAZUBmQGdAaEBpQGpAa0BsQG1AbcBuwHBAcsB0wHXAdsB3wHjAeUB6QHrAe8B8QH1AfcB+QH7AgECAwIKAtICEQIYAhoCHQIfAiECIwIrAjkCOwI9AkECQwJFAkkCSwJNAlICVAJWAAEATQE2ATgBOgE8AT4BQAFHAUwBUgFYAV4BYgFmAWoBbgFyAXQBdgF4AXwBgAGCAYQBiAGMAZABlAGYAZwBoAGkAagBrAGwAbQBtgG6Ab4ByAHSAdYB2gHeAeIB5AHoAeoB7gHwAfQB9gH4AfoCAAICAgkCDwIQAhcCGQIcAh4CIAIiAiQCOAI6AjwCQAJCAkQCSAJKAkwCUQJTAlUABAAIAAEACAABAGAAAwCaAAwANgAFAAwAEgAYAB4AJAIdAAIBNwIfAAIBOQIhAAIBOwIjAAIBPQIrAAIBPwAFAAwAEgAYAB4AJAIcAAIBNwIeAAIBOQIgAAIBOwIiAAIBPQIkAAIBPwABAAMBNgHUAdUABAAJAAEACAABAh4AEQAoADYAWAB6AJwAvgDgAQIBJAFGAWgBigGkAcYB6AHyAhQAAQAEAmMABAHVAdQB5QAEAAoAEAAWABwCJwACAgECKAACAgMCKQACAgoCKgACAhEABAAKABAAFgAcAiwAAgIBAi0AAgIDAi4AAgIKAi8AAgIRAAQACgAQABYAHAIwAAICAQIxAAICAwIyAAICCgIzAAICEQAEAAoAEAAWABwCNAACAgECNQACAgMCNgACAgoCNwACAhEABAAKABAAFgAcAjkAAgIBAjsAAgIDAj0AAgIKAj8AAgIRAAQACgAQABYAHAI4AAICAQI6AAICAwI8AAICCgI+AAICEQAEAAoAEAAWABwCQQACAgECQwACAgMCRQACAgoCRwACAhEABAAKABAAFgAcAkAAAgIBAkIAAgIDAkQAAgIKAkYAAgIRAAQACgAQABYAHAJJAAICAQJLAAICAwJNAAICCgJPAAICEQAEAAoAEAAWABwCSAACAgECSgACAgMCTAACAgoCTgACAhEAAwAIAA4AFAJSAAICAQJUAAICAwJWAAICCgAEAAoAEAAWABwCUQACAgECUwACAgMCVQACAgoCVwACAhEABAAKABAAFgAcAlgAAgIBAlkAAgIDAloAAgIKAlsAAgIRAAEABAJdAAICEQAEAAoAEAAWABwCXgACAgECXwACAgMCYAACAgoCYQACAhEAAQAEAmIAAgIRAAEAEQE2AUkBTgFUAVoBigGLAY4BjwGSAZMBlgGXAeACBQIMAhMAAQAJAAEACAACACgAEQHAAcIBxAHHAcABwAHCAcQBxwHHAcoBzAHOAdECBAILAhIAAQARAboBuwG8Ab0BvgG/AcEBwwHFAcYByAHLAc0BzwIDAgoCEQABAAkAAQAIAAIAIgAOAcABwgHEAccBwAHAAcIBxAHHAccBygHMAc4B0QABAA4BugG7AbwBvQG+Ab8BwQHDAcUBxgHIAcsBzQHPAAYACQAKABoAPABWAHIAmAC+AQABIgFgAZoAAwABABIAAQHsAAAAAQAAAA8AAgACAXgBfwAAAYQBhwAIAAMAAAABAfAAAQASAAEAAAAQAAEAAgGGAYcAAwAAAAEB1gABABIAAQAAABEAAQADAVQBWgIMAAMAAAABABIAAQAcAAEAAAARAAEAAwFPAgYCFAABAAMBTgIFAhMAAwABABIAAQGUAAAAAQAAABIAAQAIATwBPQE+AT8CIgIjAiQCKwADAAAAAQB2AAEAEgABAAAAEgABABYBNgE4AToBPAE+AUoBSwFPAVEBVQFWAVsBXAHhAfgB+QIGAggCDQIOAhQCFgADAAAAAQA0AAEAEgABAAAAEgABAAYBeAF5AXwBfwGEAYUAAwAAAAEAEgABACIAAQAAABIAAQAGAXgBegF8AX0BhAGGAAEADAFiAWYBagFuAaABpAG2Ad4CAAICAgkCEAADAAEAEgABAC4AAAABAAAAEgACAAQBNgE/AAABhAGHAAoCHAIkAA4CKwIrABcAAQAEAb4BxQHIAc8AAwABABIAAQA0AAAAAQAAABIAAgAFATYBPwAAAXwBfwAKAYQBhwAOAhwCJAASAisCKwAbAAEAAgG6Ab0AAQAAAAEACAABAAYA1QABAAEAJgABAAkAAQAIAAIAFAAHAUsBUQFWAVwCCAIOAhYAAQAHAUoBTwFVAVsCBgINAhQAAQAJAAEACAACAAwAAwFXAV0CDgABAAMBVQFbAg0AAQAJAAEACAABAAYAAQABAAYBTwFVAVsCBgINAhQAAQAJAAEACAACACQADwFXAV0BeQF7AX8BfgGFAYcBvwHGAb8BxgHJAdACDgABAA8BVQFbAXgBegF8AX0BhAGGAboBvQG+AcUByAHPAg0AAAAAAAEAAAAAClExXk1eMEBoN0RvQHh0MnU3VWpyTUo0WDJYRUA=) format("truetype");
    font-weight: 400; font-style: normal; font-display: swap;
}
@font-face {
    font-family: "PeydaReport";
    src: url(data:font/truetype;charset=utf-8;base64,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AowAPgKMAD4CjAA+AowAPgKMAD4D5QARA+UAEQPlABED5QARAkoABwJKAAcCSgAHAkoABwIUACQCFAAkAhQAJAHsAB8B7AAfAewAHwHsAB8B7AAfAewAHwHsAB8B7AAfAewAGQMeAB8BugAgAboAGAG6ACABugAgAlUAJQIdAB8CHQAfAhEAHwIQAB8CEQAfAfEAHwIQAB8B8QAfAhAAHwIQAB8CEAAdAhoAIAIaACACGgAgAjgAGwD9ADkBEAA5ATj/zgE7ABkA9QA0ARL/+gD0/+UA/f/nAggAOQEHAD4BB/+5AQcALQEH/9kCOAA5AjgAOQI4ADkCOAA2AjgAOQIIACACCAAgAggAIAIIACACCAAgAggAIAIIACACCAAgA08AIAIdADgBmgA5AZr//AGaADABvgAgAb4AGgG+ACABvgAgAlUALAGPABoBj//ZAY8AGgGPABoCOAA1AjgANQI4ADUCOAA1AjgANQI4ADUCOAA1AjgANQMKABADCgAQAwoAEAMKABAB8wAMAfMADAHzAAwB1gAoAdYAKAHWACgB0wAxANoANAEIADUA0f/UARX/5gDq/+UBCgAGATb/7QFL/+0BS//QAUr/ywNiADQDgQA0AX7/8gFN//IBff/yAc3/8gJD//IDYgA0A4EANAF+//IBTf/yAc3/8gNiADQDgQA0AX7/8gF9//IBzf/yAkP/8gNiADQDgQA0AX7/8gF9//IBzf/yAgX/8gNiADQDgQA0AX7/8gF9//IBzf/yAfP/8gNiADQDgQA0AX7/8gFN//ICrwA2Ar4ANgKt//ICmf/yAr0ANgK+ADYCrf/yApn/8gKrADYCvgA2Aq3/8gKX//ICrwA2Ar4ANgKt//ICmf/yAjgANgJPADYCOAA2Ak8ANgI4ADYCTwA2AWj/2AEj/9oBiv/YAUX/2gFo/9gBiv/YAUX/2gEj/9oBaP/YAYr/2AFo/9gBiv/YAWj/2AEj/9oBxv/YAUX/2gSoADQE0wA2AwL/8gLh//IEqAA0BNMANgMC//IC4f/yBN8ANAUEADQDRf/yAx3/8gTfADQFBAA0A0X/8gMd//IC4gA2Aw4ANgLi//ICtv/yAuIANgMOADYC4v/yArb/8gI6ADYCdgA2Akb/8QHv//ICOgA2AnYANgJG//EB7//yA2YANgOyADYB9P/yAeP/8gNmADYDsgA2AfT/8gHj//IDZgA2A7IANgH0//IB4//yAssANgLjADYCywA2AuMANgH0//IB4//yA2MANgOBADYCAf/yAZj/8gOCADQDgwA0BGIANgPpADQEpQA2AgH/8gN2//IBmP/yAZj/8gMz//IDggA0A4QANARiADYD6QA0BKUANgIB//IDdv/NAZj/8gGY//IDM//NAskANQMCADUBVv/yAQ//8gLLADUDBAA1AVb/8gEP//ICsgA0AuAANAI1//ICEf/yAskANAL5ADQBfv/yAU3/8gLJADQC+QA0AfoANAIMADYCfv/yAwP/8gH6ADQCDAA2AfoANAI7ACoCXf/yAU3/8gH6ADQCDAA2AwP/8gJUADIDQf/yAwP/8gH6ADQCDAA2AfoANAI7ACoB9gAyAgkAMgH2ADICBgAyAfYAMgIGADIB9gAyAgYAMgLnADQC6AA0AucANALoADQCmgA0AX7/8gF9//IBzf/yAe//8gLoABYC6QA0ApoANAF+//IBTf/yAc3/8gLoABQC5wA0AugANAKaADQBfv/yAX3/8gHN//IB5v/yAmYANAKaADQCywA0AvoANAC0AAACLwAlAmwAJQIvAAgCbAAOAi8AJQJsACUCUv/7Aov/9wIv/+QDlwA0BAUANAObADQDmwA0A6AACwObADQCbP/UA/8ANAP/ADQEBAA5A/8ANAObADQDmwA0A54ANAObADQDnAA0A5wANAOcADQDnAA0BUkANAVsADQFSQA0BWwANAVJADQFbAA0BUkANAVsADQFSQA0BWwANAVJADQFbAA0BUkANAVsADQFSQA0BWwANAWLADQFrgA0BYsANAWuADQFiwA0BbAANAWLADQFrgA0Ba4ANAWLADQFrgA0BYsANAWuADQFiwA0Ba4ANAWLADQDmwA0A5cANAOXADQDlwA0BAUANAQFADQDlwA0A5cANAOXAC0DlwA0BAUANAUPADQBXwAtAQ4AKgEfADkA8wAjAi8AJwLzACcB1QAyAp4AIgItABkCZAANAmQADQIMAB4B6gA0APMAIwIvACcC8wAnAo0AJwKcACICUQAnAmQADQJkAA0CDAAeAlIAKQJkAA0COgAAB30AAAAAAAAAAAAAAAAAAAAAAAACOgAAAjoAAAJfAAACXwAAAn4AAAK3AAACYQAAAqsAAAKZAAACbAAAAwUAAAFKABkBDgAt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AGEAQgBvAGwAZAAzAC4AMAAwADAAOwBLAEgARABNADsAUABlAHkAZABhAC0AQgBvAGwAZABQAGUAeQBkAGEAIABCAG8AbABkAFYAZQByAHMAaQBvAG4AIAAzAC4AMAAwADAAUABlAHkAZABhAC0AQgBvAGwAZABQAGUAeQBkAGEAIABpAHMAIABhACAAdAByAGEAZABlAG0AYQByAGsAIABvAGYAIAB3AHcAdwAuAGYAbwBuAHQAaQByAGEAbgAuAGMAbwBtAE4AYQBzAGUAcgAgAEsAaABhAGQAZQBtAFQAbwAgAHUAcwBlACAAdABoAGkAcwAgAGYAbwBuAHQALAAgAGkAdAAgAGkAcwAgAG4AZQBjAGUAcwBzAGEAcgB5ACAAdABvACAAbwBiAHQAYQBpAG4AIAB0AGgAZQAgAGwAaQBjAGUAbgBzAGUAIABmAHIAbwBtACAAdwB3AHcALgBmAG8AbgB0AGkAcgBhAG4ALgBjAG8AbQB3AHcAdwAuAGYAbwBuAHQAaQByAGEAbgAuAGMAbwBtAGgAdAB0AHAAcwA6AC8ALwBkAHIAaQBiAGIAYgBsAGUALgBjAG8AbQAvAG4AYQBzAGUAcgBrAGgAYQBkAGUAbQBmAG8AbgB0AGkAcgBhAG4ALgBjAG8AbQAvAGwAaQBjAGUAbgBzAGUAcwAAAAIAAAAAAAD/nAAyAAAAAAAAAAAAAAAAAAAAAAAAAAAC1gAAAAEAAgADACQAJQAmACcAKAApACoAKwAsAC0ALgAvADAAMQAyADMANAA1ADYANwA4ADkAOgA7ADwAPQBEAEUARgBHAEgASQBKAEsATABNAE4ATwBQAFEAUgBTAFQAVQBWAFcAWABZAFoAWwBcAF0AEwAUABUAFgAXABgAGQAaABsAHAARAA8AHQAeABAADgANAEEA2QASAB8AIAAhAAQAIgAKAAUABgAjAAcACAAJAAsADABeAF8AYAA+AD8AQAC2ALcAtAC1AMQAxQCHAEIAsgCzAIwAigCLAL0AhACFAJYA7wCTAPAAuADoAKsAwwCjAKIAgwC8AIgAhgCCAMIAYQC+AL8BAgEDAMkBBADHAGIArQEFAQYAYwCuAJAA/QD/AGQBBwDpAQgBCQBlAQoAyADKAQsAywEMAQ0BDgD4AQ8BEAERAMwAzQDOAPoAzwESARMBFAEVARYBFwDiARgBGQEaAGYBGwDQANEAZwDTARwBHQCRAK8AsADtAR4BHwEgASEA5AD7ASIBIwEkASUBJgEnANQA1QBoANYBKAEpASoBKwEsAS0BLgEvAOsBMAC7ATEBMgDmATMAaQE0AGsAbABqATUBNgBuAG0AoAD+AQAAbwE3AOoBOAEBAHABOQByAHMBOgBxATsBPAE9APkBPgE/AUAA1wB0AHYAdwFBAHUBQgFDAUQBRQFGAUcA4wFIAUkBSgB4AUsAeQB7AHwAegFMAU0AoQB9ALEA7gFOAU8BUAFRAOUA/AFSAIkBUwFUAVUBVgB+AIAAgQB/AVcBWAFZAVoBWwFcAV0BXgDsAV8AugFgAOcBYQFiAWMBZAFlAWYBZwFoAWkBagFrAWwBbQFuAW8BcAFxAXIBcwF0AXUBdgF3AXgBeQF6AXsBfAF9AX4BfwGAAYEBggGDAYQBhQGGAYcBiAGJAYoBiwGMAY0BjgGPAZABkQGSAZMBlAGVAZYBlwGYAZkBmgGbAZwBnQGeAZ8BoAGhAaIBowGkAaUBpgGnAagBqQGqAasBrAGtAa4BrwGwAbEBsgGzAbQBtQG2AbcBuAG5AboBuwG8Ab0BvgG/AcABwQHCAcMBxAHFAcYBxwHIAckBygHLAcwBzQHOAc8B0AHRAdIB0wHUAdUB1gHXAdgB2QHaAdsB3AHdAd4B3wHgAeEB4gHjAeQB5QHmAecB6AHpAeoB6wHsAe0B7gHvAfAB8QHyAfMB9AH1AfYB9wH4AfkB+gH7AfwB/QH+Af8CAAIBAgICAwIEAgUCBgIHAggCCQIKAgsCDAINAg4CDwIQAhECEgITAhQCFQIWAhcCGAIZAhoCGwIcAh0CHgIfAiACIQIiAiMCJAIlAiYCJwIoAikCKgIrAiwCLQIuAi8CMAIxAjICMwI0AjUCNgI3AjgCOQI6AjsCPAI9Aj4CPwJAAkECQgJDAkQCRQJGAkcCSAJJAkoCSwJMAk0CTgJPAlACUQJSAlMCVAJVAlYCVwJYAlkCWgJbAlwCXQJeAl8CYAJhAmICYwJkAmUCZgJnAmgCaQJqAmsCbAJtAm4CbwJwAnECcgJzAnQCdQJ2AncCeAJ5AnoCewJ8An0CfgJ/AoACgQKCAoMChAKFAoYChwKIAokCigKLAowCjQKOAo8CkAKRApICkwKUApUClgKXApgCmQKaApsCnAKdAp4CnwKgAqECogKjAqQCpQKmAqcCqAKpAqoCqwKsAq0CrgKvArACsQKyArMCtAK1ArYCtwK4ArkCugK7ArwCvQK+Ar8CwACpAKoCwQLCAsMCxALFAsYCxwLIAskCygLLAswCzQLOAs8C0ALRAtIC0wLUAtUC1gLXAtgC2QLaAtsC3ALdAt4C3wLgAuEC4gLjAuQC5QLmAucC6ALpAuoC6wLsAu0C7gLvAvAC8QLyAvMC9AL1AvYC9wL4AvkC+gL7AOEC/AL9Av4C/wd1bmkwNjVBB3VuaTA2NUIGQWJyZXZlB0FtYWNyb24HQW9nb25lawpDZG90YWNjZW50BkRjYXJvbgZEY3JvYXQGRWNhcm9uCkVkb3RhY2NlbnQHRW1hY3JvbgdFb2dvbmVrB3VuaTAxOEYHdW5pMDEyMgpHZG90YWNjZW50BEhiYXIHSW1hY3JvbgdJb2dvbmVrB3VuaTAxMzYGTGFjdXRlBkxjYXJvbgd1bmkwMTNCBk5hY3V0ZQZOY2Fyb24HdW5pMDE0NQNFbmcNT2h1bmdhcnVtbGF1dAdPbWFjcm9uBlJhY3V0ZQZSY2Fyb24HdW5pMDE1NgZTYWN1dGUHdW5pMDIxOAd1bmkxRTlFBFRiYXIGVGNhcm9uB3VuaTAxNjIHdW5pMDIxQQ1VaHVuZ2FydW1sYXV0B1VtYWNyb24HVW9nb25lawVVcmluZwZXYWN1dGULV2NpcmN1bWZsZXgJV2RpZXJlc2lzBldncmF2ZQtZY2lyY3VtZmxleAZZZ3JhdmUGWmFjdXRlClpkb3RhY2NlbnQGYWJyZXZlB2FtYWNyb24HYW9nb25lawpjZG90YWNjZW50BmRjYXJvbgZlY2Fyb24KZWRvdGFjY2VudAdlbWFjcm9uB2VvZ29uZWsHdW5pMDI1OQd1bmkwMTIzCmdkb3RhY2NlbnQEaGJhcglpLmxvY2xUUksHaW1hY3Jvbgdpb2dvbmVrB3VuaTAxMzcGbGFjdXRlBmxjYXJvbgd1bmkwMTNDBm5hY3V0ZQZuY2Fyb24HdW5pMDE0NgNlbmcNb2h1bmdhcnVtbGF1dAdvbWFjcm9uBnJhY3V0ZQZyY2Fyb24HdW5pMDE1NwZzYWN1dGUHdW5pMDIxOQR0YmFyBnRjYXJvbgd1bmkwMTYzB3VuaTAyMUINdWh1bmdhcnVtbGF1dAd1bWFjcm9uB3VvZ29uZWsFdXJpbmcGd2FjdXRlC3djaXJjdW1mbGV4CXdkaWVyZXNpcwZ3Z3JhdmULeWNpcmN1bWZsZXgGemFjdXRlCnpkb3RhY2NlbnQHdW5pMDYyMQd1bmkwNjI3DHVuaTA2MjcuZmluYQd1bmkwNjIzDHVuaTA2MjMuZmluYQd1bmkwNjI1DHVuaTA2MjUuZmluYQd1bmkwNjIyDHVuaTA2MjIuZmluYQd1bmkwNjcxDHVuaTA2NzEuZmluYQd1bmkwNjZFDHVuaTA2NkUuZmluYQx1bmkwNjZFLm1lZGkMdW5pMDY2RS5pbml0EHVuaTA2NkUuaW5pdC5hbHQRdW5pMDY2RS5pbml0LmFsdDIRdW5pMDY2RS5pbml0LmFsdDMHdW5pMDYyOAx1bmkwNjI4LmZpbmEMdW5pMDYyOC5tZWRpDHVuaTA2MjguaW5pdBB1bmkwNjI4LmluaXQuYWx0B3VuaTA2N0UMdW5pMDY3RS5maW5hDHVuaTA2N0UubWVkaQx1bmkwNjdFLmluaXQQdW5pMDY3RS5pbml0LmFsdBF1bmkwNjdFLmluaXQuYWx0Mgd1bmkwNjJBDHVuaTA2MkEuZmluYQx1bmkwNjJBLm1lZGkMdW5pMDYyQS5pbml0EHVuaTA2MkEuaW5pdC5hbHQRdW5pMDYyQS5pbml0LmFsdDIHdW5pMDYyQgx1bmkwNjJCLmZpbmEMdW5pMDYyQi5tZWRpDHVuaTA2MkIuaW5pdBB1bmkwNjJCLmluaXQuYWx0EXVuaTA2MkIuaW5pdC5hbHQyB3VuaTA2NzkMdW5pMDY3OS5maW5hDHVuaTA2NzkubWVkaQx1bmkwNjc5LmluaXQHdW5pMDYyQwx1bmkwNjJDLmZpbmEMdW5pMDYyQy5tZWRpDHVuaTA2MkMuaW5pdAd1bmkwNjg2DHVuaTA2ODYuZmluYQx1bmkwNjg2Lm1lZGkMdW5pMDY4Ni5pbml0B3VuaTA2MkQMdW5pMDYyRC5maW5hDHVuaTA2MkQubWVkaQx1bmkwNjJELmluaXQHdW5pMDYyRQx1bmkwNjJFLmZpbmEMdW5pMDYyRS5tZWRpDHVuaTA2MkUuaW5pdAd1bmkwNjJGDHVuaTA2MkYuZmluYQd1bmkwNjMwDHVuaTA2MzAuZmluYQd1bmkwNjg4DHVuaTA2ODguZmluYQd1bmkwNjMxC3VuaTA2MzEuYWx0DHVuaTA2MzEuZmluYRB1bmkwNjMxLmZpbmEuYWx0B3VuaTA2MzIMdW5pMDYzMi5maW5hEHVuaTA2MzIuZmluYS5hbHQLdW5pMDYzMi5hbHQHdW5pMDY5MQx1bmkwNjkxLmZpbmEHdW5pMDY5NQx1bmkwNjk1LmZpbmEHdW5pMDY5OAt1bmkwNjk4LmFsdAx1bmkwNjk4LmZpbmEQdW5pMDY5OC5maW5hLmFsdAd1bmkwNjMzDHVuaTA2MzMuZmluYQx1bmkwNjMzLm1lZGkMdW5pMDYzMy5pbml0B3VuaTA2MzQMdW5pMDYzNC5maW5hDHVuaTA2MzQubWVkaQx1bmkwNjM0LmluaXQHdW5pMDYzNQx1bmkwNjM1LmZpbmEMdW5pMDYzNS5tZWRpDHVuaTA2MzUuaW5pdAd1bmkwNjM2DHVuaTA2MzYuZmluYQx1bmkwNjM2Lm1lZGkMdW5pMDYzNi5pbml0B3VuaTA2MzcMdW5pMDYzNy5maW5hDHVuaTA2MzcubWVkaQx1bmkwNjM3LmluaXQHdW5pMDYzOAx1bmkwNjM4LmZpbmEMdW5pMDYzOC5tZWRpDHVuaTA2MzguaW5pdAd1bmkwNjM5DHVuaTA2MzkuZmluYQx1bmkwNjM5Lm1lZGkMdW5pMDYzOS5pbml0B3VuaTA2M0EMdW5pMDYzQS5maW5hDHVuaTA2M0EubWVkaQx1bmkwNjNBLmluaXQHdW5pMDY0MQx1bmkwNjQxLmZpbmEMdW5pMDY0MS5tZWRpDHVuaTA2NDEuaW5pdAd1bmkwNkE0DHVuaTA2QTQuZmluYQx1bmkwNkE0Lm1lZGkMdW5pMDZBNC5pbml0B3VuaTA2QTEMdW5pMDZBMS5maW5hDHVuaTA2QTEubWVkaQx1bmkwNkExLmluaXQHdW5pMDY2Rgx1bmkwNjZGLmZpbmEHdW5pMDY0Mgx1bmkwNjQyLmZpbmEMdW5pMDY0Mi5tZWRpDHVuaTA2NDIuaW5pdAd1bmkwNjQzDHVuaTA2NDMuZmluYQx1bmkwNjQzLm1lZGkMdW5pMDY0My5pbml0B3VuaTA2QTkLdW5pMDZBOS5hbHQMdW5pMDZBOS5zczAxDHVuaTA2QTkuZmluYRF1bmkwNkE5LmZpbmEuc3MwMQx1bmkwNkE5Lm1lZGkRdW5pMDZBOS5tZWRpLnNzMDEMdW5pMDZBOS5pbml0EHVuaTA2QTkuaW5pdC5hbHQRdW5pMDZBOS5pbml0LnNzMDEHdW5pMDZBRgt1bmkwNkFGLmFsdAx1bmkwNkFGLnNzMDEMdW5pMDZBRi5maW5hEXVuaTA2QUYuZmluYS5zczAxDHVuaTA2QUYubWVkaRF1bmkwNkFGLm1lZGkuc3MwMQx1bmkwNkFGLmluaXQQdW5pMDZBRi5pbml0LmFsdBF1bmkwNkFGLmluaXQuc3MwMQd1bmkwNjQ0DHVuaTA2NDQuZmluYQx1bmkwNjQ0Lm1lZGkMdW5pMDY0NC5pbml0B3VuaTA2QjUMdW5pMDZCNS5maW5hDHVuaTA2QjUubWVkaQx1bmkwNkI1LmluaXQHdW5pMDY0NQx1bmkwNjQ1LmZpbmEMdW5pMDY0NS5tZWRpDHVuaTA2NDUuaW5pdAd1bmkwNjQ2DHVuaTA2NDYuZmluYQx1bmkwNjQ2Lm1lZGkMdW5pMDY0Ni5pbml0B3VuaTA2QkEMdW5pMDZCQS5maW5hB3VuaTA2NDcMdW5pMDY0Ny5maW5hDHVuaTA2NDcubWVkaQx1bmkwNjQ3LmluaXQHdW5pMDZDMAx1bmkwNkMwLmZpbmEHdW5pMDZDMQx1bmkwNkMxLmZpbmEMdW5pMDZDMS5tZWRpDHVuaTA2QzEuaW5pdAd1bmkwNkMyDHVuaTA2QzIuZmluYQd1bmkwNkJFDHVuaTA2QkUuZmluYQx1bmkwNkJFLm1lZGkMdW5pMDZCRS5pbml0B3VuaTA2MjkMdW5pMDYyOS5maW5hB3VuaTA2QzMMdW5pMDZDMy5maW5hB3VuaTA2NDgMdW5pMDY0OC5maW5hB3VuaTA2MjQMdW5pMDYyNC5maW5hB3VuaTA2QzYMdW5pMDZDNi5maW5hB3VuaTA2QzcMdW5pMDZDNy5maW5hB3VuaTA2NDkMdW5pMDY0OS5maW5hB3VuaTA2NEEMdW5pMDY0QS5maW5hEXVuaTA2NEEuZmluYS5zczAxDHVuaTA2NEEubWVkaQx1bmkwNjRBLmluaXQQdW5pMDY0QS5pbml0LmFsdBF1bmkwNjRBLmluaXQuYWx0Mgd1bmkwNjI2DHVuaTA2MjYuZmluYRF1bmkwNjI2LmZpbmEuc3MwMQx1bmkwNjI2Lm1lZGkMdW5pMDYyNi5pbml0EHVuaTA2MjYuaW5pdC5hbHQHdW5pMDZDRQd1bmkwNkNDDHVuaTA2Q0MuZmluYRF1bmkwNkNDLmZpbmEuc3MwMQx1bmkwNkNDLm1lZGkMdW5pMDZDQy5pbml0EHVuaTA2Q0MuaW5pdC5hbHQRdW5pMDZDQy5pbml0LmFsdDIHdW5pMDZEMgx1bmkwNkQyLmZpbmEHdW5pMDc2OQx1bmkwNzY5LmZpbmEHdW5pMDY0MAt1bmkwNjQ0MDYyNxB1bmkwNjQ0MDYyNy5maW5hC3VuaTA2NDQwNjIzEHVuaTA2NDQwNjIzLmZpbmELdW5pMDY0NDA2MjUQdW5pMDY0NDA2MjUuZmluYQt1bmkwNjQ0MDYyMhB1bmkwNjQ0MDYyMi5maW5hC3VuaTA2NDQwNjcxEHVuaTA2NkUwNkNDLmZpbmEVdW5pMDY2RTA2Q0MuX2ZpbmEuYWx0EHVuaTA2MjgwNjQ5LmZpbmEQdW5pMDYyODA2NEEuZmluYRB1bmkwNjI4MDYyNi5maW5hEHVuaTA2MjgwNkNDLmZpbmEQdW5pMDY0NDA2NzEuZmluYRB1bmkwNjdFMDY0OS5maW5hEHVuaTA2N0UwNjRBLmZpbmEQdW5pMDY3RTA2MjYuZmluYRB1bmkwNjdFMDZDQy5maW5hEHVuaTA2MkEwNjQ5LmZpbmEQdW5pMDYyQTA2NEEuZmluYRB1bmkwNjJBMDYyNi5maW5hEHVuaTA2MkEwNkNDLmZpbmEQdW5pMDYyQjA2NDkuZmluYRB1bmkwNjJCMDY0QS5maW5hEHVuaTA2MkIwNjI2LmZpbmEQdW5pMDYyQjA2Q0MuZmluYQt1bmkwNjMzMDY0ORB1bmkwNjMzMDY0OS5maW5hC3VuaTA2MzMwNjRBEHVuaTA2MzMwNjRBLmZpbmELdW5pMDYzMzA2MjYQdW5pMDYzMzA2MjYuZmluYQt1bmkwNjMzMDZDQxB1bmkwNjMzMDZDQy5maW5hC3VuaTA2MzQwNjQ5EHVuaTA2MzQwNjQ5LmZpbmELdW5pMDYzNDA2NEEQdW5pMDYzNDA2NEEuZmluYQt1bmkwNjM0MDYyNhB1bmkwNjM0MDYyNi5maW5hC3VuaTA2MzQwNkNDEHVuaTA2MzQwNkNDLmZpbmELdW5pMDYzNTA2NDkQdW5pMDYzNTA2NDkuZmluYQt1bmkwNjM1MDY0QRB1bmkwNjM1MDY0QS5maW5hC3VuaTA2MzUwNjI2EHVuaTA2MzUwNjI2LmZpbmELdW5pMDYzNTA2Q0MQdW5pMDYzNTA2Q0MuZmluYRp1bmkwNjM2X2ZhcnNpX3VuaTA2Q0MuZmluYQt1bmkwNjM2MDY0ORB1bmkwNjM2MDY0OS5maW5hC3VuaTA2MzYwNjRBEHVuaTA2MzYwNjRBLmZpbmELdW5pMDYzNjA2MjYQdW5pMDYzNjA2MjYuZmluYQt1bmkwNjM2MDZDQxB1bmkwNjQ2MDY0OS5maW5hEHVuaTA2NDYwNjRBLmZpbmEQdW5pMDY0NjA2MjYuZmluYRB1bmkwNjQ2MDZDQy5maW5hEHVuaTA2NEEwNjRBLmZpbmEQdW5pMDY0QTA2Q0MuZmluYRB1bmkwNjI2MDY0OS5maW5hEHVuaTA2MjYwNjRBLmZpbmEQdW5pMDYyNjA2MjYuZmluYRB1bmkwNjI2MDZDQy5maW5hEHVuaTA2Q0MwNkNDLmZpbmEHdW5pRkRGMgd1bmkwNjZCB3VuaTA2NkMHdW5pMDY2MAd1bmkwNjYxB3VuaTA2NjIHdW5pMDY2Mwd1bmkwNjY0B3VuaTA2NjUHdW5pMDY2Ngd1bmkwNjY3B3VuaTA2NjgHdW5pMDY2OQd1bmkwNkYwB3VuaTA2RjEHdW5pMDZGMgd1bmkwNkYzB3VuaTA2RjQHdW5pMDZGNQd1bmkwNkY2B3VuaTA2RjcHdW5pMDZGOAd1bmkwNkY5DHVuaTA2RjQudXJkdQx1bmkwNkY3LnVyZHUHdW5pMzAwMAd1bmkyMDVGB3VuaTIwMEUHdW5pMjAwRgd1bmkyMDBEB3VuaTIwMEMHdW5pMjAwMQd1bmkyMDAzB3VuaTIwMDAHdW5pMjAwMgd1bmkyMDA1B3VuaTIwMEEHdW5pMjAyRgd1bmkyMDA2B3VuaTIwMDkHdW5pMjAwNAd1bmkyMDBCB3VuaTA2RDQHdW5pMDYwQwd1bmkwNjFCB3VuaTA2MUYHdW5pMDY2RAd1bmlGRDNFB3VuaUZEM0YHdW5pRkRGQwd1bmkwNjZBB3VuaTA2MTUKZG90YWJvdmVhcgpkb3RiZWxvd2FyC2RvdGNlbnRlcmFyFnR3b2RvdHN2ZXJ0aWNhbGFib3ZlYXIWdHdvZG90c3ZlcnRpY2FsYmVsb3dhchh0d29kb3RzaG9yaXpvbnRhbGFib3ZlYXIYdHdvZG90c2hvcml6b250YWxiZWxvd2FyFHRocmVlZG90c2Rvd25hYm92ZWFyFHRocmVlZG90c2Rvd25iZWxvd2FyEnRocmVlZG90c3VwYWJvdmVhchJ0aHJlZWRvdHN1cGJlbG93YXIHd2FzbGFhcgttaW5pS2VoZWhhchFnYWZzYXJrYXNoYWJvdmVhchVnYWZzYXJrYXNoYWJvdmVhci5hbHQSZ2Fmc2Fya2FzaGNlbnRlcmFyB3VuaTA2NzAHdW5pMDY1Ngd1bmkwNjU0B3VuaTA2NTUHdW5pMDY0Qgd1bmkwNjRDB3VuaTA2NEQHdW5pMDY0RQd1bmkwNjRGB3VuaTA2NTAHdW5pMDY1MQt1bmkwNjUxMDY0Qgt1bmkwNjUxMDY0Qwt1bmkwNjUxMDY0RAt1bmkwNjUxMDY0RQt1bmkwNjUxMDY0Rgt1bmkwNjUxMDY1MAt1bmkwNjUxMDY3MAd1bmkwNjUyB3VuaTA2NTMIc2FyZXlhYXIRc2V2ZW5zYW1sbC5ib3R0b20Qc2V2ZW5zbWFsbC5hYm92ZQ55ZWhzYW1sLmJvdHRvbQ15ZWhzbWFsLmFib3ZlB3VuaTAzMDgHdW5pMDMwNwlncmF2ZWNvbWIJYWN1dGVjb21iB3VuaTAzMEIHdW5pMDMwMgd1bmkwMzBDB3VuaTAzMDYHdW5pMDMwQQl0aWxkZWNvbWIHdW5pMDMwNAd1bmkwMzEyB3VuaTAzMjYHdW5pMDMyNwd1bmkwMzI4DHVuaTA2Y2UuZmluYQx1bmkwNmNlLmluaXQMdW5pMDZjZS5tZWRpDHVuaTA2ZDUuZmluYQAAAQACAA4AAAAAAAAANgACAAYAgwCEAAMBNQIbAAECHAJjAAICmAK8AAMCwgLQAAMC0gLVAAEAAQACAAAADAAAABgAAQAEAqoCrAKvArIAAQAVAIMAhAKYAqQCpQKpAqsCrQKuArACsQKzArQCtQK2ArcCuAK5AroCuwK8AAEAAAAKAH4AugADREZMVAAUYXJhYgAYbGF0bgAuAFQAAAAKAAFVUkQgAFAAAP//AAMAAAADAAQALgAHQVpFIAA6Q1JUIAA6S0FaIAA6TU9MIAA6Uk9NIAA6VEFUIAA6VFJLIAA6AAD//wADAAEAAgAEAAD//wADAAAAAgAEAAVrZXJuACBrZXJuACBtYXJrACptYXJrACpta21rADQAAAADAAAAAQACAAAAAwADAAQABQAAAAIABgAHAAgAEgXyFvgZmhpOJ5Qx8DJsAAIACAACAAoEKgABAEQABAAAAB0C5ALkAIIAggLyAIgAtgEYARgBJgGAAYoB/AIKAnwC1gLWAuQC5ALyAvIDCAMOAxwD6gPwBAYEEAQWAAEAHQBCAEMARABFAEYASABLAFEAUgBYAFkAWgBcAF0AXgBhAGMAZABlAGgAaQB3AHgAeQCBAIICcAJ2AncAAQAZ//gACwAE/+gADf/7ABcADQAdAAUAIP/xACH/7wAi//EAJP/yACz/8QAu/+8AMP/1ABgABP/eAAb/8AAK/+0ADf/0ABL/7QAU/+0AHv/gACD/2wAh/9sAIv/bACT/3QAq/+kAK//pACz/2wAt/+kALv/bAC//6QAw/+AAMv/rADP/7wA0//AANv/uADf/6gBLAAAAAwBL/78AVP/3AFf/7wAWAAb/8QAK//AAEv/wABT/8AAe//AAIP/rACH/7AAi/+sAI//zACcAHAAq//EAK//xACz/6wAt//EALv/sAC//8QAw//MAMv/wADP/8wA0/+4ANv/zAFr/8gACAFwABABfAAQAHAAEAAoABv/6AAr/9wAS//cAFP/3ABYABQAe//wAIP/0ACH/9gAi//QAIwAFACcAGwAqAAsAKwALACz/9AAtAAsALv/2AC8ACwAwAAsAMQAJADL/+QAz//sANP/3ADUACQA2//oANwAIAFgABABa//gAAwBZ//IAXP/4AF//7wAcAAQACwAG//UACv/wABL/8AAU//AAFgAFAB7/9gAg/+oAIf/rACL/6gAj//gAJwALACoADQArAA0ALP/qAC0ADQAu/+sALwANADAADQAx//wAMv/zADP/8gA0//EANQAJADb/8QA3AAoAWAAEAFr/7wAWAAb/6AAK/+YAEv/mABT/5gAW//MAF//JABj/5AAZ/9IAGv/cABz/uAAg//MAIv/zACP/8AAs//MAMf/uADP/7AA0//AANv/rAFH/tQBS/7UAYf+8AGP/vAADAEv/tgBU/+gAV//tAAMAGf/eACP/9AAz/+8ABQAZ/+wAG//kACP/9gAz//kANf/tAAEAKf+7AAMAF//rABkABAAc/+cAMwAE//sABf/5AAb/9gAH//kACP/5AAn/+QAK//QAC//5AAz/+QANAAYADv/5AA//+QAQ//kAEf/5ABL/9AAT//kAFP/0ABX/+QAW//0AF//PABj/8wAZ/+QAGv/rABv/+AAc/80AHf/6AB7/8wAf//QAIP/vACH/7wAi/+8AI//wACX/9AAm//QAJ//0ACj/9AAp//QAKv/0ACv/9AAs/+8ALf/0AC7/7wAv//QAMP/yADH/8AAy//EAM//sADT/7wA1//QANv/pADf/8wABABn/+QAFABn/6wAb/+4AI//zADMABAA1/+0AAgJ3AAACeAAAAAECcP+PAAICcAAAAnj/tQACAMgABAAAAOIBBAAEABcAAP/U/94AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD/y/+8AAUABf/4/+cAEf+O//X/9f/sAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA/8v/wwAAAAAAAP/zAAD/y//6AAT/+AAF//X/8v/xAAT/2wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP/KAAAAAAAAAAD/6P/5AAAAAAAAAAD/9/+P//b/+gACAAEACwBCAEMARABFAEYAUQBSAGcAaABpAHEAAgAFAEIAQwABAEYARgACAFEAUgADAGcAaQACAHEAcQACAAIAHQAEAAQADAAGAAYAAwAKAAoABAANAA0ADQASABIABAAUABQABAAWABYADgAXABcAAQAYABgABQAaABoABgAcABwAAgAdAB0ADwAeAB4AEAAgACAAEgAhACEAFAAiACIAEgAkACQAFQAsACwAEgAuAC4AFAAwADAAFgAxADEACQA0ADQACgA2ADYACwA3ADcAEQBCAEMAEwBGAEYABwBRAFIACABnAGkABwBxAHEABwACAAgAAgAKCAAAAQB0AAQAAAA1AJwAxgEIARYBPAFGAdwCMAIwAe4B9AICAjACMAKkAjYCpALGAtwC8gMQAxoDxAPOBDgEWgRoBaoEigSgBMoFLAVWBToFUAVWBVYFfAWqBjIF2AX2BiAGMgZUBs4G8Ac6B1gHcgeEB8oH2AACAAYABAAgAAAAIgAlAB0AKAA3ACEAVABUADEAVwBXADIAagBrADMACgAZ/7IAI//3ADP/9ABI/+kAUP/3AFwACgBe/9gAXwALAGr/5wBr//IAEAAE//kADQAJABcACQAZ//gAGgABABv/9gAc/+sAJP/6ADMAAgA0AAIANQACADYAAgBQAAQAXAAKAF7/6wBf//gAAwAj//wAMwAAAGsABgAJABn/9wAb/+8ANQABAEv/7QBQAAQAWf/yAFz/+wBe/+kAX//yAAIAIwABADMABQAlAAT/8QAGAAUACgAFAA3//gASAAUAFAAFABYABQAbAAIAHv/4ACD/8AAh/+8AIv/wACP//AAk/+sAKv/xACv/8QAs//AALf/xAC7/7wAv//EAMP/xADEABAAy//UAMwAFADT//gA1AAIANv//ADf/+wBC/9kAQ//ZAEb/9QBL/9YAZP/ZAGX/2QBo//UAaf/1AHb/2QAEABn/+QAj//oAM//8AF7/8wABACP/+AADACP/8QAz//MAawAFAAsAGf/LACP/9gAz/+YASP+8AFAABgBcAAUAXv+3AF8ABwBq/7sAa//NAHcAGwABACP/9gAbAAT/8wAN//8AGf/4ABv/7wAc/+wAHQAEAB7/+wAgAAIAIQACACIAAgAkAAIALAACAC4AAgBC/80AQ//NAEYABABL/9kAWf/zAFz/+wBe//AAX//4AGT/zQBl/80AaAAEAGkABAB2/80AgQAEAAgAGf/3ABv/8ABL/+4AUAAEAFn/7wBc//oAXv/oAF//8AAFABn/+AAb//YAXAAIAF7/7QBfAAgABQAZ//kAG//7ACP/9gAz//wANf/5AAcAI//wADP/2AA1/9oAS//QAFT/9gBX//sAawAEAAIAI//4AEv/6wAqAAT/5gAG//gACv/3AA3//gAS//cAFP/3ABb/+AAe/+sAIP/kACH/5gAi/+QAI//3ACT/5gAq/+0AK//tACz/5AAt/+0ALv/mAC//7QAw/+sAMv/yADP/+wA0//gANf/6ADb/+wA3//IAQv/eAEP/3gBE//gARf/4AEb/7ABL/9kAVP/1AFf/9ABk/94AZf/eAGj/7ABp/+wAawAEAHb/3gCB/+oAgv/5AAIAS//iAFcAAwAaAAb/8QAK//AAEv/wABT/8AAe//gAIP/kACH/6wAi/+QAI//1ACT/6gAq//gAK//4ACz/5AAt//gALv/rAC//+AAx//UAMv/sADP/7AA0/+kANv/rAEb/4wBo/+MAaf/jAGsABACB//AACAAj/+cAM//j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AKP/nAABALUCywABAKv/mwABAPQCyAABALL/nAABALoC1AABAbL/nAABAbUDFgABAcv/nAABAbMDFgABALf/nAABALoDUQABALIDbgABAKz/nAABAQMDaQABAKL/nAABALwDXwABAYsDJAABAZ8DIwABALsDWQABAIkDZAABARD+XAABAOcCNwABAOL+WwABAOUCNAABAUz+mgABAL4CIQABAU3+qAABAMYCIQABAPD+WQABAN0CNQABAOz+VQABAN4CGgABAT/+BwABANECHAABAT3+AgABAMkCGwABAPX+SgABANkCNAABAPD+QgABANgCNAABAQf/nAABALwCIQABAPL/nAABALcCIQABALz+WwABANwDJAABANr+WgABAN0DQgABALv/nAABAMcDGQABALb/nAABAMUDIAABAQz/jQABATAChAABAR3/kQABAU0ClwABAQ//lAABAQoDRwABAP3/jQABAU8DYwABATkD6AABAWoECgABAIr+ywABAN8B2AABAHn+0wABALEB2wABAHP+wwABAPYB1AABAKv+7gABALIB5AABAKP+4QABAOkCtQABAKj+3gABAPUCuQABAKL+/QABALMCswABAJf+0gABALgCqAABAOQDQwABAPgDTQABAJz9aAABAJ/9ZwABAJ3+yQABAOcDSAABAJX+4gABAK4DSAABAKj+4gABAPcDSQABAJz+7QABAKgDSAABA0L/nAABA0sB2gABA1//mwABA1MBzQABAWr/nAABAYcB3AABAX7/nAABAYcB3gABA0n/nAABAzgDRQABA03/nAABAzUDOAABAYT/nAABAWgDRAABAXb/nAABAWgDRgABA4n/nAABA+ECAgABA4//nAABA9oB+QABAcP/nAABAhsCAAABAhcCBwABA4P/nAABA9kC5wABA5T/nAABA90C4gABAar/nAABAh4C3QABAbz/nAABAiMC1QABAV3/nAABAisB9gABAWH/nAABAiwB+QABAR3/nAABAf0B5wABAR7/nAABAfsB8AABAUD/nAABAeACzgABAVb/nAABAecCzgABAUj/nAABAb0C0QABATT/nAABAcIC1QABARr99wABARwCHAABAPz+BQABATACKgABASn/nAABASkCKQABAPD/nQABAOwCPwABAMf+GwABASgC9gABANX+FwABATEC6QABASL/nAABASIC/QABAPIC+AABAnkDlAABArYDAAABAOwDCQABAPoDoQABAaL/nAABAmgEJQABAZD/nAABAscDhwABAPv/nAABAPYDgwABALn/nAABAPQEJAABAa//mAABAnICvQABAZz/mAABAssCLAABAPT/nAABAPwCJAABAP0CsAABAV3+tgABAdICBwABAVD+sgABAdECAQABAT7+uwABAdIC0AABAT7+uQABAdYCwAABAPX/nAABAPkC8gABAM3/nAABAOQDhAABAcIC1gABAcoC0gABAK8DCwABAKsDDgABAaX/mQABAgECvQABAg8CrgABAiD/nAABASYCFAABAbj/mQABAg4CsgABAiL/nAABARICBAABANn/mQABAKADEgABAVL/mwABAH8CpgABAMr/mgABAKMDAwABAJf/mgABAJQDAgABATD/nAABAJMCxAABAav/mAABAeYDPAABAbr/mAABAd8DRQABAi7/nAABAPQCnwABAc//mAABAeQDPQABAfX/nAABAN8CnAABAM3/mQABAH4DgAABAX//nAABAFQDAgABAHv/mQABAGEDYAABAH//mQABAIQDbwABAS//nAABAF4DHwABAW3+3gABASUBlwABAWP+5AABASUBnwABAKf/nAABAKoDFgABAIb/nAABAJsDIwABAQ4CMQABASEBxQABALUEPQABAJ4ETgABAYr/tgABAVICAAABAb//nAABAXIB8gABARn/nAABARsB+AABARb/nAABARoCBQABAWv+2gABAWMCRwABAVD+5wABAWgCSgABAL7/nAABAMkCngABAJD/nAABAMsCxwABAWz+1AABAWcBvQABAWv+0AABAWcB0gABAQD/mgABAPkCTAABAO3/zgABAPACcwABAQX+8wABAQcB6wABATACdQABAOkD8QABANcEBgABAPH/nAABANwCUQABARD/yQABATUBvAABAQz+ygABAQ8BlwABAIr97wABAJoB/gABAOYD3AABAP8D1AABAVH/nAABAR8CdAABAUT+lQABATACAgABAY//mgABAVgCVwABAUn/nAABAVwCbQABAPD/nAABAOkDKAABAP7/zgABAPMDcgABAQT/nAABAQIDMQABART/vQABAS0ChwABAPX+xQABAPkB/QABAP7+wwABAPgCDgABAPUDcwABAQ8DiAABAP8DTwABAP4DQwABAPMDfwABAPADnAABAWj+vAABAMUBnwABAWX+lwABAXcBLAABAXj+DAABANABlwABAXL96AABAV8BJwABAUT9yQABAUEA+AABALf+twABALIB3gABAKj+uAABALYB8wABANn+owABAMEB8QABAMf+oQABALoBzwABAM8DKwABAPcDHQABAOMCdgABAL//nAABAM8DegABAJP/nAABAKcDzQABAK//nAABALcDhAABALACxAABAXT+ygABAMoBrwABAWj+mAABAYwBJwABAU7+iwABASoBCQABAL3+qAABAMkB3QABAKP+rAABALQCCAABAN7+oQABAL0B6AABALf+pQABAMwB4wABATYCLAABATYA7wABAWcDegABAWgDiwABAFn/nAABAFMBQAAFAAAAAQAIAAEADAAoAAIAMgCYAAIABACDAIQAAAKYApgAAgKkAqUAAwKpArwABQACAAECHAJiAAAAGQABC2wAAQtsAAELeAABC3gAAQt4AAELeAAACmYAAQt4AAAKZgABC3gAAQtyAAAKZgABC3gAAQt4AAAKZgABC3gAAQt4AAELeAABC3gAAQt4AAELeAABC3gAAQt4AAELeAABC3gARwCQALIA1AD2ARgBOgFcAX4BoAHCAeQCBgIoAkoCbAKOArAC0gLuAxADMgNUA3YDmAO6A9wD/gQgBEIEZASGBKIExATgBQIFJAVGBWIFhAWmBcgF6gYMBi4GSgZsBogGpAbABtwG+AcaBzYHWAd6B5wHvgfgCAIIJAhGCGgIigisCM4I8AkSCTQJVgl4CZoAAgAKABAAFgAcAAEBmf+1AAEBwwNIAAEAd/90AAEAagLXAAIACgAQABYAHAABAar/sAABAdcDIgABAHL/fAABAG4C0QACAAoAEAAWABwAAQGZ/7kAAQHVAy4AAQBn/4MAAQCKBBsAAgAKABAAFgAcAAEB0f+yAAEB3QNDAAEAlv+CAAEAkgQ6AAIACgAQABYAHAABAdH/pwABAc0DKAABAMP+NQABAH0CwwACAAoAEAAWABwAAQH//5wAAQHUAzcAAQDi/icAAQB7As8AAgAKABAAFgAcAAEByP/KAAEB+gM/AAEAkv9yAAEApwOdAAIACgAQABYAHAABAcz/sQABAfADQAABAJr/bQABALEDoAACAAoAEAAWABwAAQGt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AAMBiwGKAYkAAwGPAY4BjQADAZMBkgGRAAMBlwGWAZUAAwGbAZoBmQADAZ8BngGdAAMBowGiAaEAAwGnAaYBpQADAasBqgGpAAMBrwGuAa0AAwGzAbIBsQABAbUAAwG5AbgBtwAFAb0BvAG7AcABvwAFAcUBwwHBAcABvwABAcAAAQHCAAEBxAACAccBxgABAccABQHPAc0BywHKAckAAQHMAAEBzgACAdEB0AADAdUB1AHTAAMB2QHYAdcAAwHdAdwB2wADAeEB4AHfAAEB4wADAecB5gHlAAEB6QADAe0B7AHrAAEB7wADAfMB8gHxAAEB9QABAfcAAQH5AAEB+wABAgEAAwIGAgUCAwABAgQAAgIIAgcAAwINAgwCCgABAgsAAQIOAAMC0wLUAtIAAwIUAhMCEQABAhIAAgIWAhUAAQIYAAECGgABAh0AAQIfAAECIQABAiMAAQIrAAECOQABAjsAAQI9AAECQQABAkMAAQJFAAECSQABAksAAQJNAAECUgABAlQAAQJWAAECegABAmwAAQJ7AAEAbQAmAMMAyAEcASEBNgE4AToBPAE+AUABRwFKAUwBTwFSAVUBWAFbAV4BYgFmAWoBbgFyAXQBdgF4AXoBfAF9AYABggGEAYYBiAGMAZABlAGYAZwBoAGkAagBrAGwAbQBtgG6AbsBvAG9Ab4BvwHBAcMBxQHGAcgBywHNAc8B0gHWAdoB3gHiAeQB6AHqAe4B8AH0AfYB+AH6AgACAgIDAgYCCQIKAg0CDwIQAhECFAIXAhkCHAIeAiACIgIkAjgCOgI8AkACQgJEAkgCSgJMAlECUwJVAnQCdgJ3AAYAAAACAAoAHAADAAAAAQisAAEALgABAAAADgADAAAAAQiaAAIAFAAcAAEAAAAOAAEAAgLPAtAAAgABAsICzQAAAAQAAAABAAgAAQCWAAgAFgAgACoANAA+AEgAUgBcAAEABAK6AAICswABAAQCtAACArMAAQAEArUAAgKzAAEABAK2AAICswABAAQCtwACArMAAQAEArgAAgKzAAEABAK5AAICswAHABAAFgAcACIAKAAuADQCugACAqkCtAACAq0CtQACAq4CtgACAq8CtwACArACuAACArECuQACArIAAgACAqkCqQAAAq0CswABAAEAAAABAAgAAQe+ANkAAQAAAAEACAABAAYAAQABAAQAwwDIARwBIQABAAAAAQAIAAIADAADAnoCbAJ7AAEAAwJ0AnYCdwABAAAAAQAIAAIApAAkAUMBSgFPAVUBWwFhAWUBaQFtAXEBiwGPAZMBlwGbAZ8BowGnAasBrwGzAbkBvQHFAc8B1QHZAd0B4QHnAe0B8wIGAg0C0wIUAAEAAAABAAgAAgBOACQBQgFJAU4BVAFaAWABZAFoAWwBcAGKAY4BkgGWAZoBngGiAaYBqgGuAbIBuAG8AcMBzQHUAdgB3AHgAeYB7AHyAgUCDALUAhMAAQAkAUABRwFMAVIBWAFeAWIBZgFqAW4BiAGMAZABlAGYAZwBoAGkAagBrAGwAbYBugG+AcgB0gHWAdoB3gHkAeoB8AICAgkCDwIQAAEAAAABAAgAAgCgAE0BNwE5ATsBPQE/AUEBSAFNAVMBWQFfAWMBZwFrAW8BcwF1AXcBegF9AYEBgwGGAYkBjQGRAZUBmQGdAaEBpQGpAa0BsQG1AbcBuwHBAcsB0wHXAdsB3wHjAeUB6QHrAe8B8QH1AfcB+QH7AgECAwIKAtICEQIYAhoCHQIfAiECIwIrAjkCOwI9AkECQwJFAkkCSwJNAlICVAJWAAEATQE2ATgBOgE8AT4BQAFHAUwBUgFYAV4BYgFmAWoBbgFyAXQBdgF4AXwBgAGCAYQBiAGMAZABlAGYAZwBoAGkAagBrAGwAbQBtgG6Ab4ByAHSAdYB2gHeAeIB5AHoAeoB7gHwAfQB9gH4AfoCAAICAgkCDwIQAhcCGQIcAh4CIAIiAiQCOAI6AjwCQAJCAkQCSAJKAkwCUQJTAlUABAAIAAEACAABAGAAAwCaAAwANgAFAAwAEgAYAB4AJAIdAAIBNwIfAAIBOQIhAAIBOwIjAAIBPQIrAAIBPwAFAAwAEgAYAB4AJAIcAAIBNwIeAAIBOQIgAAIBOwIiAAIBPQIkAAIBPwABAAMBNgHUAdUABAAJAAEACAABAh4AEQAoADYAWAB6AJwAvgDgAQIBJAFGAWgBigGkAcYB6AHyAhQAAQAEAmMABAHVAdQB5QAEAAoAEAAWABwCJwACAgECKAACAgMCKQACAgoCKgACAhEABAAKABAAFgAcAiwAAgIBAi0AAgIDAi4AAgIKAi8AAgIRAAQACgAQABYAHAIwAAICAQIxAAICAwIyAAICCgIzAAICEQAEAAoAEAAWABwCNAACAgECNQACAgMCNgACAgoCNwACAhEABAAKABAAFgAcAjkAAgIBAjsAAgIDAj0AAgIKAj8AAgIRAAQACgAQABYAHAI4AAICAQI6AAICAwI8AAICCgI+AAICEQAEAAoAEAAWABwCQQACAgECQwACAgMCRQACAgoCRwACAhEABAAKABAAFgAcAkAAAgIBAkIAAgIDAkQAAgIKAkYAAgIRAAQACgAQABYAHAJJAAICAQJLAAICAwJNAAICCgJPAAICEQAEAAoAEAAWABwCSAACAgECSgACAgMCTAACAgoCTgACAhEAAwAIAA4AFAJSAAICAQJUAAICAwJWAAICCgAEAAoAEAAWABwCUQACAgECUwACAgMCVQACAgoCVwACAhEABAAKABAAFgAcAlgAAgIBAlkAAgIDAloAAgIKAlsAAgIRAAEABAJdAAICEQAEAAoAEAAWABwCXgACAgECXwACAgMCYAACAgoCYQACAhEAAQAEAmIAAgIRAAEAEQE2AUkBTgFUAVoBigGLAY4BjwGSAZMBlgGXAeACBQIMAhMAAQAJAAEACAACACgAEQHAAcIBxAHHAcABwAHCAcQBxwHHAcoBzAHOAdECBAILAhIAAQARAboBuwG8Ab0BvgG/AcEBwwHFAcYByAHLAc0BzwIDAgoCEQABAAkAAQAIAAIAIgAOAcABwgHEAccBwAHAAcIBxAHHAccBygHMAc4B0QABAA4BugG7AbwBvQG+Ab8BwQHDAcUBxgHIAcsBzQHPAAYACQAKABoAPABWAHIAmAC+AQABIgFgAZoAAwABABIAAQHsAAAAAQAAAA8AAgACAXgBfwAAAYQBhwAIAAMAAAABAfAAAQASAAEAAAAQAAEAAgGGAYcAAwAAAAEB1gABABIAAQAAABEAAQADAVQBWgIMAAMAAAABABIAAQAcAAEAAAARAAEAAwFPAgYCFAABAAMBTgIFAhMAAwABABIAAQGUAAAAAQAAABIAAQAIATwBPQE+AT8CIgIjAiQCKwADAAAAAQB2AAEAEgABAAAAEgABABYBNgE4AToBPAE+AUoBSwFPAVEBVQFWAVsBXAHhAfgB+QIGAggCDQIOAhQCFgADAAAAAQA0AAEAEgABAAAAEgABAAYBeAF5AXwBfwGEAYUAAwAAAAEAEgABACIAAQAAABIAAQAGAXgBegF8AX0BhAGGAAEADAFiAWYBagFuAaABpAG2Ad4CAAICAgkCEAADAAEAEgABAC4AAAABAAAAEgACAAQBNgE/AAABhAGHAAoCHAIkAA4CKwIrABcAAQAEAb4BxQHIAc8AAwABABIAAQA0AAAAAQAAABIAAgAFATYBPwAAAXwBfwAKAYQBhwAOAhwCJAASAisCKwAbAAEAAgG6Ab0AAQAAAAEACAABAAYA1QABAAEAJgABAAkAAQAIAAIAFAAHAUsBUQFWAVwCCAIOAhYAAQAHAUoBTwFVAVsCBgINAhQAAQAJAAEACAACAAwAAwFXAV0CDgABAAMBVQFbAg0AAQAJAAEACAABAAYAAQABAAYBTwFVAVsCBgINAhQAAQAJAAEACAACACQADwFXAV0BeQF7AX8BfgGFAYcBvwHGAb8BxgHJAdACDgABAA8BVQFbAXgBegF8AX0BhAGGAboBvQG+AcUByAHPAg0AAAAAAAEAAAAA) format("truetype");
    font-weight: 700; font-style: normal; font-display: swap;
}
:root{--bg:#f4f7fb;--card:#fff;--text:#000;--muted:#666;--line:#e5eaf2;--accent:#16509D;--accent-dark:#0e3c73}
*{box-sizing:border-box}
body,.shell,.shell *{font-family:"PeydaReport","Peyda","IRANSans","Tahoma","Arial",sans-serif !important}
body{margin:0;background:var(--bg);color:var(--text);font-size:14px}
.shell{display:grid;grid-template-columns:230px 1fr;min-height:100vh}
.sidebar{background:var(--accent-dark);color:#fff;padding:22px 16px;position:sticky;top:0;height:100vh;overflow-y:auto}
.brand{display:flex;align-items:center;gap:10px;font-size:20px;font-weight:800;margin-bottom:6px}
.brand img{height:28px;width:auto}
.brand small{display:block;font-size:14px;font-weight:400;color:#b8c7d9;margin-top:5px}
.nav{margin-top:28px;display:grid;gap:8px}
.nav button{border:0;background:transparent;color:#d9e4ef;text-align:right;padding:11px 12px;border-radius:10px;cursor:pointer;font:inherit;font-size:14px}
.nav button.active,.nav button:hover{background:#ffffff22;color:#fff}
.main{padding:22px}
.topbar{display:flex;justify-content:space-between;gap:16px;align-items:center;margin-bottom:18px;flex-wrap:wrap}
h1{font-size:20px;margin:0;font-weight:bold}
.sub{font-size:14px;color:var(--muted);margin-top:5px}
.filters{display:flex;gap:8px;flex-wrap:wrap}
.btn-action{background:var(--accent);color:#fff;border:2px solid var(--accent);border-radius:9px;padding:9px 14px;font-size:14px;font-weight:bold;cursor:pointer;font-family:inherit}
.btn-action:hover{background:var(--accent-dark)}
.page{display:none}.page.active{display:block}
.kpis{display:grid;grid-template-columns:repeat(6,1fr);gap:12px}
@media(max-width:1300px){.kpis{grid-template-columns:repeat(3,1fr)}}
.card{background:var(--card);border:1px solid var(--line);border-radius:14px;padding:15px;box-shadow:0 2px 10px #00000009}
.kpi .label{font-size:14px;color:var(--muted)}
.kpi .value{font-size:24px;font-weight:800;margin:8px 0;color:var(--accent)}
.kpi .delta{font-size:14px;color:var(--muted)}
.grid2{display:grid;grid-template-columns:1fr 1fr;gap:14px;margin-top:14px}
.grid3{display:grid;grid-template-columns:repeat(3,1fr);gap:14px;margin-top:14px}
.title{font-weight:bold;font-size:15px;margin-bottom:13px;color:var(--accent)}
.chart{height:220px;display:flex;align-items:flex-end;gap:9px;padding:12px 4px 25px;border-bottom:1px solid var(--line);position:relative}
.bar{flex:1;background:var(--accent);border-radius:6px 6px 2px 2px;min-width:18px;position:relative}
.bar span{position:absolute;bottom:-22px;right:50%;transform:translateX(50%);font-size:14px;color:var(--muted);white-space:nowrap}
.bar b{position:absolute;top:-19px;right:50%;transform:translateX(50%);font-size:14px}
.donut{width:170px;height:170px;border-radius:50%;margin:8px auto;position:relative}
.donut:after{content:"";position:absolute;inset:32px;background:#fff;border-radius:50%}
.legend{display:flex;gap:12px;justify-content:center;flex-wrap:wrap;font-size:14px;color:var(--muted)}
.dot{display:inline-block;width:9px;height:9px;border-radius:50%;margin-left:5px}
.list{display:grid;gap:11px}
.risk{display:grid;gap:9px}
.riskitem{display:flex;align-items:center;justify-content:space-between;border:1px solid var(--line);border-radius:10px;padding:10px}
.riskitem strong{font-size:14px}.riskitem small{color:var(--muted);font-size:14px}
.note{font-size:14px;color:var(--muted);line-height:1.9}
.bar-row{display:flex;align-items:center;gap:8px;margin-bottom:8px}
.bar-label{width:180px;text-align:right;font-size:14px;flex-shrink:0}
.bar-track{flex:1;height:22px;background:#f5f5f5;border-radius:6px;overflow:hidden;border:1px solid var(--line)}
.bar-fill{height:100%;background:var(--accent);border-radius:6px}
.bar-value{width:70px;text-align:left;font-size:14px;font-weight:bold}
.bar-row-clickable{cursor:pointer}
.bar-row-clickable:hover .bar-label{color:var(--accent);text-decoration:underline}
.table-wrap{overflow:auto;max-height:360px;border:1px solid var(--muted);border-radius:8px}
.data-table{width:auto;min-width:100%;border-collapse:collapse}
.data-table th{background:var(--accent);color:#fff;padding:10px 8px;text-align:center;font-size:15px;font-weight:bold;border:1px dashed #666;white-space:nowrap;width:1%;position:sticky;top:0;cursor:pointer;user-select:none}
.data-table th.sort-asc::after{content:' ▲'}.data-table th.sort-desc::after{content:' ▼'}
.data-table td{padding:8px;border:1px dashed #666;font-size:14px;text-align:center;white-space:nowrap}
.data-table tr:nth-child(even) td{background:#f5f5f5}
.data-table tr:hover td{background:#e8eef6}
.empty-msg{text-align:center;color:var(--muted);padding:18px;font-size:14px}
.error-box{background:#f5f5f5;border:1px solid var(--accent);color:var(--accent-dark);border-radius:8px;padding:12px 14px;font-size:14px;margin-bottom:16px}
.help-overlay{display:none;position:fixed;inset:0;background:rgba(0,0,0,0.5);z-index:100;align-items:center;justify-content:center}
.help-overlay.open{display:flex}
.help-modal{background:#fff;border-radius:10px;max-width:720px;width:92%;max-height:84vh;overflow-y:auto;box-shadow:0 8px 24px rgba(0,0,0,0.3)}
.help-modal-header{display:flex;justify-content:space-between;align-items:center;background:var(--accent);color:#fff;padding:12px 16px;border-radius:10px 10px 0 0;font-size:15px;font-weight:bold;position:sticky;top:0}
.help-close{background:transparent;border:none;color:#fff;font-size:16px;cursor:pointer}
.help-modal-body{padding:16px;text-align:right;font-size:14px}
.help-modal-body p{margin:10px 0;line-height:1.8}
.help-modal-body ul{margin:6px 0 14px;padding-right:20px}
.help-modal-body li{margin:6px 0;line-height:1.7}
.footer{text-align:center;color:var(--muted);font-size:14px;margin-top:12px}
@media(max-width:1100px){.grid3{grid-template-columns:1fr}.shell{grid-template-columns:1fr}.sidebar{height:auto;position:relative}.nav{grid-template-columns:repeat(3,1fr)}}
@media(max-width:700px){.kpis,.grid2{grid-template-columns:1fr 1fr}.main{padding:12px}.topbar{display:block}.filters{margin-top:12px}}
</style>
</head>
<body>
<div class="shell">
<aside class="sidebar">
  <div class="brand"><img alt="140" src="data:image/png;base64,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"><small>داشبورد حاکمیت سرمایه انسانی</small></div>
  <div class="nav">
    <button class="active" data-page="executive">نمای مدیریتی</button>
    <button data-page="workforce">ترکیب نیروی انسانی</button>
    <button data-page="retention">ماندگاری و خروج</button>
    <button data-page="cost">هزینه و بهره‌وری</button>
  </div>
</aside>
<main class="main">
<div class="topbar"><div><h1>وضعیت سرمایه انسانی هلدینگ ۱۴۰</h1>]]

local topbar_sub = string.format(
    '<div class="sub">بازهٔ روند: %s ماه اخیر%s | تاریخ گزارش: امروز</div></div>',
    tostring(months_back),
    org_id and (" | سازمان: " .. escape_html(tostring(org_id))) or " | همه سازمان‌ها")

local topbar_filters = [[<div class="filters">
<button type="button" class="btn-action" id="btnFullscreen" onclick="toggleFullScreen()">تمام صفحه</button>
<button type="button" class="btn-action" onclick="exportAllToExcel()">خروجی Excel</button>
<button type="button" class="btn-action" onclick="openHelpModal()">راهنما</button>
</div></div>]]

local html_tail = [[
</main></div>

<div id="helpModalOverlay" class="help-overlay" onclick="if(event.target===this){closeHelpModal();}">
  <div class="help-modal">
    <div class="help-modal-header">
      <strong>راهنمای داشبورد منابع انسانی</strong>
      <button type="button" class="help-close" onclick="closeHelpModal()">✕</button>
    </div>
    <div class="help-modal-body">
      <p><strong>این داشبورد چیست؟</strong> نمای تجمیعی وضعیت نیروی انسانی هلدینگ ۱۴۰ در ۴ تب — فقط شامل
      حوزه‌هایی که منبع دادهٔ تاییدشده در بات‌های HR این ریپو دارند (جذب و استخدام و عملکرد/جانشین‌پروری
      چون هیچ منبع دادهٔ تاییدشده‌ای نداشتند، حذف شدند).</p>
      <ul>
        <li><b>نمای مدیریتی</b> — KPIهای اصلی، ترکیب سازمانی، هشدارها، روند استخدام.</li>
        <li><b>ترکیب نیروی انسانی</b> — جنسیت، تاهل، تحصیلات، گروه سنی و سابقهٔ همکاری نیروی فعال.</li>
        <li><b>ماندگاری و خروج</b> — نرخ ماندگاری ۳/۶/۱۲ ماهه و روند خروج ماهانه.</li>
        <li><b>هزینه و بهره‌وری</b> — حقوق و دستمزد و میزان پرداخت اضافه‌کاری در حکم به تفکیک واحد.</li>
      </ul>
      <p><strong>فیلترها:</strong> <code>org_id</code> (اختیاری)، <code>from_date</code>/<code>to_date</code>/<code>months</code> (پیش‌فرض ۶ ماه اخیر) — FILETIME عددی.</p>
      <p><strong>تعامل‌ها:</strong> کلیک روی هدر هر جدول برای مرتب‌سازی؛ کلیک روی هر ردیف نمودار «ترکیب سازمانی» فهرست پرسنل همان واحد را نشان می‌دهد؛ «خروجی Excel» تمام جدول‌های تب فعال را دانلود می‌کند.</p>
    </div>
  </div>
</div>

<div id="unitDrillOverlay" class="help-overlay" onclick="if(event.target===this){closeUnitDrill();}">
  <div class="help-modal">
    <div class="help-modal-header">
      <strong id="unitDrillTitle">فهرست پرسنل واحد</strong>
      <button type="button" class="help-close" onclick="closeUnitDrill()">✕</button>
    </div>
    <div class="help-modal-body">
      <div class="table-wrap" style="max-height:50vh;">
        <table class="data-table" id="unitDrillTable">
          <thead><tr><th>نام پرسنل</th><th>کد پرسنلی</th></tr></thead>
          <tbody id="unitDrillBody"><tr><td colspan="2" class="empty-msg">در حال بارگذاری...</td></tr></tbody>
        </table>
      </div>
    </div>
  </div>
</div>

<div class="footer">داشبورد منابع انسانی — Teamyar HR</div>

<script>
var RUN_URL = (location.pathname.indexOf('/bot/run/') === 0) ? location.pathname : '/bot/run/443/hr_dashboard';

document.querySelectorAll('.nav button').forEach(function (btn) {
  btn.addEventListener('click', function () {
    document.querySelectorAll('.nav button').forEach(function (x) { x.classList.remove('active'); });
    document.querySelectorAll('.page').forEach(function (x) { x.classList.remove('active'); });
    btn.classList.add('active');
    document.getElementById(btn.dataset.page).classList.add('active');
  });
});

function showUnitDrill(unitId, unitName) {
  document.getElementById('unitDrillTitle').textContent = 'فهرست پرسنل واحد: ' + unitName;
  var tbody = document.getElementById('unitDrillBody');
  tbody.innerHTML = '<tr><td colspan="2" class="empty-msg">در حال بارگذاری...</td></tr>';
  document.getElementById('unitDrillOverlay').classList.add('open');
  $.Teamyar.ajax({
    block_holder: 'body',
    options: {
      url: RUN_URL,
      type: 'POST',
      dataType: 'json',
      data: { customform: JSON.stringify({ type: 'drill_unit', unit_id: unitId }) }
    },
    events: {
      success: function (res) {
        if (!res || !res.ok || !res.personnel || res.personnel.length === 0) {
          tbody.innerHTML = '<tr><td colspan="2" class="empty-msg">' + (res && res.error ? res.error : 'پرسنلی یافت نشد') + '</td></tr>';
          return;
        }
        var rows = res.personnel.map(function (p) {
          return '<tr><td>' + (p.name || '-') + '</td><td>' + (p.code || '-') + '</td></tr>';
        });
        tbody.innerHTML = rows.join('');
      },
      error: function () {
        tbody.innerHTML = '<tr><td colspan="2" class="empty-msg">خطا در دریافت اطلاعات</td></tr>';
      }
    }
  });
}
function closeUnitDrill() { document.getElementById('unitDrillOverlay').classList.remove('open'); }

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
function exportAllToExcel() {
  var activePage = document.querySelector('.page.active');
  if (!activePage) return;
  var lines = [];
  activePage.querySelectorAll('table.data-table').forEach(function (table, idx) {
    if (table.id === 'unitDrillTable') return;
    var hc = table.querySelectorAll('thead th');
    var hl = []; for (var h = 0; h < hc.length; h++) hl.push(csvEscapeCell(hc[h].innerText));
    if (idx > 0) lines.push('');
    lines.push(hl.join(','));
    var rows = table.querySelectorAll('tbody tr');
    for (var i = 0; i < rows.length; i++) {
      if (rows[i].querySelector('td.empty-msg')) continue;
      var cells = rows[i].querySelectorAll('td');
      var line = []; for (var c = 0; c < cells.length; c++) line.push(csvEscapeCell(cells[c].innerText));
      lines.push(line.join(','));
    }
  });
  if (lines.length === 0) { lines.push('این تب جدولی برای خروجی ندارد'); }
  downloadCsv(lines, 'داشبورد-منابع-انسانی.csv');
}
function toggleFullScreen() {
  var root = document.querySelector('.shell');
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
function getCellSortValue(cell) {
  var text = cell ? cell.innerText.trim() : '';
  var n = text.replace(/[,٪%]/g, '').trim();
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
function openHelpModal() { document.getElementById('helpModalOverlay').classList.add('open'); }
function closeHelpModal() { document.getElementById('helpModalOverlay').classList.remove('open'); }
document.addEventListener('keydown', function (e) { if (e.key === 'Escape') { closeHelpModal(); closeUnitDrill(); } });
initSortableTables();
</script>
</body>
</html>]]

local html = html_head .. topbar_sub .. topbar_filters .. error_html ..
    section_executive .. section_workforce .. section_retention .. section_cost .. html_tail

teamyar.write_result(html)
