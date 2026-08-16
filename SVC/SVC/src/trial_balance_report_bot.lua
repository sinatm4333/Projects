-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/05/20 16:30

-- تراز آزمایشی چهارستونی (گردش بدهکار/بستانکار دوره + مانده بدهکار/بستانکار تا پایان دوره)
-- مدل داده (تأییدشده روی ساختار جدول):
--   pa_account (حساب) — سطح قابل ثبت سند: VOUCHER_ALLOW=1
--   pa_voucher (سند) → pa_voucher_record (آرتیکل سند: DEB/CRD) ON vr.VOUCHER_ID = v.ID AND vr.ORG_ID = v.ORG_ID
--   بازه بر اساس REPORT_FN_JDATE(v.RUN_DATE,'-') (رشته شمسی قابل مقایسه)
--   فیلتر معتبر بودن سند: v.DELETED=0 AND vr.DELETED=0 AND v.STATUS NOT IN (0,3)
-- ورودی: from_date, to_date (شمسی، پیش‌فرض از سال مالی فعال), org_id (پیش‌فرض 2),
--         account_code (پیشوند/like کد حساب، اختیاری), show_zero=1 (نمایش حساب‌های صفر), format=json

local input = teamyar.get_input() or {}

local table_unpack = table.unpack or unpack
local HTML_DQ = string.char(34)
local DEFAULT_ORG_ID = 2

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
    y, m, d = s:match("^(%d%d%d%d)(%d%d)(%d%d)$")
    if y then
        return string.format("%04d-%02d-%02d", tonumber(y), tonumber(m), tonumber(d))
    end
    return nil
end

-- تبدیل شمسی به میلادی (الگوریتم چرخه ۳۳ ساله؛ تأییدشده روی 1405/01/01→2026-03-21 و 1405/05/19→2026-08-10)
local function jalali_to_gregorian(jy, jm, jd)
    local gy
    if jy > 979 then
        gy = 1600
        jy = jy - 979
    else
        gy = 621
    end
    local days = 365 * jy + math.floor(jy / 33) * 8 + math.floor(((jy % 33) + 3) / 4) + 78 + jd
    if jm < 7 then
        days = days + (jm - 1) * 31
    else
        days = days + (jm - 1) * 30 + 6
    end
    gy = gy + 400 * math.floor(days / 146097)
    days = days % 146097
    local leap = true
    if days >= 36525 then
        days = days - 1
        gy = gy + 100 * math.floor(days / 36524)
        days = days % 36524
        if days >= 365 then
            days = days + 1
        else
            leap = false
        end
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
        if gd <= v then
            gm = i
            break
        end
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

local function wants_json(source)
    local fmt = source["format"] or source["output"] or source["output_format"]
    if fmt ~= nil and tostring(fmt):lower() == "json" then return true end
    return false
end

local from_date_in = input["from_date"] or input["fromDate"] or input["start_date"]
local to_date_in = input["to_date"] or input["toDate"] or input["end_date"]
local org_id = tonumber(input["org_id"] or input["orgId"]) or DEFAULT_ORG_ID
local account_code = normalize_text(input["account_code"] or input["accountCode"] or input["code"])
local show_zero = tostring(input["show_zero"] or input["showZero"] or ""):lower()
show_zero = (show_zero == "1" or show_zero == "true" or show_zero == "yes")
local as_json = wants_json(input)

local from_explicit = normalize_text(from_date_in) ~= nil
local to_explicit = normalize_text(to_date_in) ~= nil
local from_jalali = normalize_jalali_date(from_date_in)
local to_jalali = normalize_jalali_date(to_date_in)

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
    return tostring(value)
        :gsub('&', '&amp;')
        :gsub('<', '&lt;')
        :gsub('>', '&gt;')
        :gsub(HTML_DQ, '&quot;')
end

local function safe_format(fmt, ...)
    local args = { ... }
    for i, value in ipairs(args) do
        if type(value) == 'string' then
            args[i] = value:gsub('%%', '%%%%')
        end
    end
    return string.format(fmt, table_unpack(args))
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

local function fetch_generated_at()
    local rows = fetch_rows([[
        SELECT CONCAT(
            REPORT_FN_JDATE((UNIX_TIMESTAMP() + 11644473600) * 10000000, '-'),
            ' ',
            DATE_FORMAT(NOW(), '%H:%i:%s')
        ) AS generated_at
    ]])
    if rows == nil or #rows == 0 or rows[1][1] == nil then return "—" end
    return tostring(rows[1][1])
end

local function fail(message, detail)
    if as_json then
        teamyar.write_result(json.encode({ ok = false, error = message, detail = detail }))
        return
    end
    local extra = ""
    if detail ~= nil and tostring(detail) ~= "" then
        extra = "<p style='font-size:14px;color:#666;'>" .. escape_html(detail) .. "</p>"
    end
    teamyar.write_result(safe_format([[
<!DOCTYPE html>
<html dir="rtl" lang="fa">
<head><meta charset="UTF-8"><title>خطا</title></head>
<body style="font-family:tahoma;padding:2rem;text-align:center;font-size:14px;">
<h2 style="color:#16509D;font-size:15px;">%s</h2>
%s
</body></html>
]], escape_html(message), extra))
end

-- ==================== تعیین بازه پیش‌فرض از سال مالی فعال ====================
local function fetch_default_dates()
    local rows = fetch_rows([[
SELECT
    REPORT_FN_JDATE(fy.START_DATE, '-') AS fiscal_start_jalali,
    REPORT_FN_JDATE((UNIX_TIMESTAMP() + 11644473600) * 10000000, '-') AS today_jalali
FROM pa_fiscal_year fy
WHERE fy.ORG_ID = ?
  AND (UNIX_TIMESTAMP() + 11644473600) * 10000000 >= fy.START_DATE
  AND (UNIX_TIMESTAMP() + 11644473600) * 10000000 <= fy.END_DATE
ORDER BY fy.START_DATE DESC
LIMIT 1
]], { org_id })

    if rows ~= nil and #rows > 0 and rows[1][1] ~= nil and rows[1][2] ~= nil then
        return tostring(rows[1][1]), tostring(rows[1][2])
    end

    rows = fetch_rows([[
SELECT
    CONCAT(SUBSTRING(REPORT_FN_JDATE((UNIX_TIMESTAMP() + 11644473600) * 10000000, '-'), 1, 4), '-01-01'),
    REPORT_FN_JDATE((UNIX_TIMESTAMP() + 11644473600) * 10000000, '-')
]])
    if rows ~= nil and #rows > 0 and rows[1][1] ~= nil and rows[1][2] ~= nil then
        return tostring(rows[1][1]), tostring(rows[1][2])
    end
    return nil, nil
end

local from_defaulted, to_defaulted = false, false
if from_jalali == nil or to_jalali == nil then
    local def_from, def_to = fetch_default_dates()
    if from_jalali == nil then
        if from_explicit and def_from == nil then
            fail("تاریخ شروع نامعتبر است. فرمت: 1405-01-01")
            return
        end
        from_jalali = def_from
        from_defaulted = true
    end
    if to_jalali == nil then
        if to_explicit and def_to == nil then
            fail("تاریخ پایان نامعتبر است. فرمت: 1405-12-29")
            return
        end
        to_jalali = def_to
        to_defaulted = true
    end
end

if from_jalali == nil or to_jalali == nil then
    fail("بازه تاریخ مشخص نیست و سال مالی فعال یافت نشد")
    return
end

-- ==================== کوئری اصلی ====================
local where_parts = { "a.DELETED = 0", "a.ORG_ID = ?", "a.VOUCHER_ALLOW = 1" }
local account_params = { org_id }

if account_code ~= nil then
    local code = account_code
    if not code:find("%%", 1, true) then
        code = code .. "%"
    end
    table.insert(where_parts, "(a.CODE LIKE ? OR a.ACCOUNT_CODE LIKE ?)")
    table.insert(account_params, code)
    table.insert(account_params, code)
end

-- محدوده RUN_DATE به‌صورت عدد (FILETIME) محاسبه می‌شود تا مقایسه روی ستون خام و بدون فراخوانی
-- تابع REPORT_FN_JDATE برای هر ردیف انجام شود (کلید کارایی روی جدول‌های حجیم سند)
local from_gdatetime = jalali_to_gregorian_datetime(from_jalali, "00:00:00")
local to_gdatetime = jalali_to_gregorian_datetime(to_jalali, "23:59:59")
if from_gdatetime == nil or to_gdatetime == nil then
    fail("خطا در تبدیل تاریخ شمسی به میلادی")
    return
end

local bound_rows, bound_err = fetch_rows(
    "SELECT (UNIX_TIMESTAMP(?) + 11644473600) * 10000000, (UNIX_TIMESTAMP(?) + 11644473600) * 10000000",
    { from_gdatetime, to_gdatetime }
)
if bound_rows == nil or #bound_rows == 0 then
    fail("خطا در محاسبه بازه تاریخ", tostring(bound_err))
    return
end
local tb_from = tonumber(bound_rows[1][1])
local tb_to = tonumber(bound_rows[1][2])
if tb_from == nil or tb_to == nil then
    fail("خطا در محاسبه بازه تاریخ: مقدار عددی نامعتبر")
    return
end

-- «مانده» باید تجمعی از ابتدای سال مالیِ حاویِ to_date باشد، نه از ابتدای عمر دفاتر (۷+ سال، ۱۵ میلیون
-- ردیف سند) — چون هر سال مالی با یک سند افتتاحیه (pa_voucher.TYPE نادر، جداگانه از TYPE=1 عادی) باز
-- می‌شود که مانده انتقالی سال قبل را ثبت می‌کند. محدودکردن مانده به همان سال مالی هم صحیح است هم سریع.
local balance_from_ticks = nil
do
    local rows = fetch_rows([[
SELECT fy.START_DATE
FROM pa_fiscal_year fy
WHERE fy.ORG_ID = ? AND fy.START_DATE <= ? AND fy.END_DATE >= ?
ORDER BY fy.START_DATE DESC
LIMIT 1
]], { org_id, tb_to, tb_to })
    if rows ~= nil and #rows > 0 and rows[1][1] ~= nil then
        balance_from_ticks = tonumber(rows[1][1])
    end
end
if balance_from_ticks == nil then
    balance_from_ticks = tb_from
end

-- ==================== درون‌کاوی یک سطح پایین‌تر (تفصیلی/مشتریان یک حساب کنترل) ====================
-- برخی حساب‌ها (مثل «حسابهای دریافتنی تجاری») در pa_account فرزند ندارند؛ سطح پایین‌تر آنها از طریق
-- تفصیلی (pa_client، ستون CLIENT_ID در pa_voucher_record) یا شناور (pa_floating) ثبت می‌شود
-- (FORCE_CLIENT/FORCE_FLOATING روی pa_account). این بخش برای همان یک حساب (سریع) این ریزحساب‌ها را می‌دهد.
local drill_account_id = tonumber(input["drill_account_id"] or input["drillAccountId"])
if drill_account_id ~= nil then
    local drill_rows, drill_err = fetch_rows([[
SELECT
    COALESCE(c.CODE, 'بدون-تفصیلی') AS client_code,
    COALESCE(c.NAME, 'بدون تفصیلی/مشتری') AS client_name,
    SUM(CASE WHEN v.RUN_DATE >= ? AND v.RUN_DATE <= ? THEN COALESCE(vr.DEB, 0) ELSE 0 END) AS turnover_debit,
    SUM(CASE WHEN v.RUN_DATE >= ? AND v.RUN_DATE <= ? THEN COALESCE(vr.CRD, 0) ELSE 0 END) AS turnover_credit,
    SUM(CASE WHEN v.RUN_DATE >= ? AND v.RUN_DATE <= ? THEN COALESCE(vr.DEB, 0) ELSE 0 END) AS cum_debit,
    SUM(CASE WHEN v.RUN_DATE >= ? AND v.RUN_DATE <= ? THEN COALESCE(vr.CRD, 0) ELSE 0 END) AS cum_credit
FROM pa_voucher v
INNER JOIN pa_voucher_record vr
    ON vr.VOUCHER_ID = v.ID AND vr.ORG_ID = v.ORG_ID AND vr.ACCOUNT_ID = ?
LEFT JOIN pa_client c
    ON c.ID = vr.CLIENT_ID AND c.ORG_ID = v.ORG_ID
WHERE v.ORG_ID = ? AND v.DELETED = 0 AND v.STATUS NOT IN (0, 3) AND vr.DELETED = 0
  AND v.RUN_DATE >= ? AND v.RUN_DATE <= ?
GROUP BY client_code, client_name
ORDER BY client_name ASC
]], {
        tb_from, tb_to, tb_from, tb_to,
        balance_from_ticks, tb_to, balance_from_ticks, tb_to,
        drill_account_id, org_id, math.min(balance_from_ticks, tb_from), tb_to
    })

    if drill_rows == nil then
        teamyar.write_result(json.encode({ ok = false, error = "خطا در دریافت تفصیلی حساب", detail = tostring(drill_err) }))
        return
    end

    local items = {}
    for _, row in ipairs(drill_rows) do
        local turnover_debit = tonumber(row[3]) or 0
        local turnover_credit = tonumber(row[4]) or 0
        local cum_debit = tonumber(row[5]) or 0
        local cum_credit = tonumber(row[6]) or 0
        local net = cum_debit - cum_credit
        if turnover_debit ~= 0 or turnover_credit ~= 0 or cum_debit ~= 0 or cum_credit ~= 0 then
            table.insert(items, {
                client_code = row[1],
                client_name = row[2],
                turnover_debit = turnover_debit,
                turnover_credit = turnover_credit,
                debit_balance = net > 0 and net or 0,
                credit_balance = net < 0 and -net or 0
            })
        end
    end

    teamyar.write_result(json.encode({ ok = true, drill_account_id = drill_account_id, item_count = #items, items = items }))
    return
end

-- گام ۱: فهرست حساب‌های قابل ثبت سند (مطابق فیلترها)
local account_query = [[
SELECT a.ID, COALESCE(NULLIF(a.CODE, ''), a.ACCOUNT_CODE) AS account_code, a.NAME, a.LEVEL,
    COALESCE(a.FORCE_CLIENT, 0) AS force_client, COALESCE(a.FORCE_FLOATING, 0) AS force_floating
FROM pa_account a
WHERE ]] .. table.concat(where_parts, " AND ") .. [[

ORDER BY account_code ASC
]]

local account_rows, account_err = fetch_rows(account_query, account_params)
if account_rows == nil then
    fail("خطا در دریافت فهرست حساب‌ها", tostring(account_err))
    return
end

-- گام ۲: تجمیع گردش/مانده هر حساب — کوئری از سمت pa_voucher رانده می‌شود (نه pa_voucher_record) تا
-- از ایندکس IDX6(ORG_ID,DELETED,RUN_DATE,STATUS,TYPE) برای محدودکردن حجم اسناد به بازه تاریخ استفاده
-- شود؛ سپس JOIN به pa_voucher_record روی VOUCHER_ID (ایندکس‌دار). این باعث می‌شود حجم اسکن به‌جای کل
-- ۱۵ میلیون ردیف سند تاریخچه ۷+ ساله، فقط به بازه درخواستی محدود شود.
local scan_from_ticks = math.min(balance_from_ticks, tb_from)

local totals_by_account = {}
local agg_query = [[
SELECT
    vr.ACCOUNT_ID,
    SUM(CASE WHEN v.RUN_DATE >= ? AND v.RUN_DATE <= ? THEN COALESCE(vr.DEB, 0) ELSE 0 END) AS turnover_debit,
    SUM(CASE WHEN v.RUN_DATE >= ? AND v.RUN_DATE <= ? THEN COALESCE(vr.CRD, 0) ELSE 0 END) AS turnover_credit,
    SUM(CASE WHEN v.RUN_DATE >= ? AND v.RUN_DATE <= ? THEN COALESCE(vr.DEB, 0) ELSE 0 END) AS cum_debit,
    SUM(CASE WHEN v.RUN_DATE >= ? AND v.RUN_DATE <= ? THEN COALESCE(vr.CRD, 0) ELSE 0 END) AS cum_credit
FROM pa_voucher v
INNER JOIN pa_voucher_record vr
    ON vr.VOUCHER_ID = v.ID AND vr.ORG_ID = v.ORG_ID
WHERE v.ORG_ID = ? AND v.DELETED = 0 AND v.RUN_DATE >= ? AND v.RUN_DATE <= ?
  AND v.STATUS NOT IN (0, 3) AND vr.DELETED = 0
GROUP BY vr.ACCOUNT_ID
]]
local agg_params = {
    tb_from, tb_to, tb_from, tb_to,
    balance_from_ticks, tb_to, balance_from_ticks, tb_to,
    org_id, scan_from_ticks, tb_to
}

local agg_rows, agg_err = fetch_rows(agg_query, agg_params)
if agg_rows == nil then
    fail("خطا در تجمیع گردش/مانده حساب‌ها", tostring(agg_err))
    return
end
for _, row in ipairs(agg_rows) do
    totals_by_account[tostring(row[1])] = {
        turnover_debit = tonumber(row[2]) or 0,
        turnover_credit = tonumber(row[3]) or 0,
        cum_debit = tonumber(row[4]) or 0,
        cum_credit = tonumber(row[5]) or 0
    }
end

local report_rows = {}
local total_turnover_debit, total_turnover_credit = 0, 0
local total_debit_balance, total_credit_balance = 0, 0
local zero_totals = { turnover_debit = 0, turnover_credit = 0, cum_debit = 0, cum_credit = 0 }

for _, account_row in ipairs(account_rows) do
    local totals = totals_by_account[tostring(account_row[1])] or zero_totals
    local turnover_debit = totals.turnover_debit
    local turnover_credit = totals.turnover_credit
    local cum_debit = totals.cum_debit
    local cum_credit = totals.cum_credit
    local net = cum_debit - cum_credit
    local debit_balance = net > 0 and net or 0
    local credit_balance = net < 0 and -net or 0

    if show_zero or turnover_debit ~= 0 or turnover_credit ~= 0 or cum_debit ~= 0 or cum_credit ~= 0 then
        total_turnover_debit = total_turnover_debit + turnover_debit
        total_turnover_credit = total_turnover_credit + turnover_credit
        total_debit_balance = total_debit_balance + debit_balance
        total_credit_balance = total_credit_balance + credit_balance

        table.insert(report_rows, {
            row_no = #report_rows + 1,
            account_id = account_row[1],
            account_code = account_row[2],
            account_name = account_row[3],
            level = account_row[4],
            force_client = tonumber(account_row[5]) == 1,
            force_floating = tonumber(account_row[6]) == 1,
            turnover_debit = turnover_debit,
            turnover_credit = turnover_credit,
            debit_balance = debit_balance,
            credit_balance = credit_balance
        })
    end
end

if as_json then
    teamyar.write_result(json.encode({
        ok = true,
        report_title = "تراز آزمایشی چهارستونی",
        filters = {
            from_date = from_jalali,
            to_date = to_jalali,
            from_date_defaulted = from_defaulted,
            to_date_defaulted = to_defaulted,
            org_id = org_id,
            account_code = account_code,
            show_zero = show_zero
        },
        row_count = #report_rows,
        totals = {
            turnover_debit = total_turnover_debit,
            turnover_credit = total_turnover_credit,
            debit_balance = total_debit_balance,
            credit_balance = total_credit_balance
        },
        rows = report_rows
    }))
    return
end

local generated_at = fetch_generated_at()

local table_rows_html = {}
if #report_rows == 0 then
    table.insert(table_rows_html, [[<tr><td colspan="9" class="empty-row">در بازه و فیلترهای انتخاب‌شده رکوردی یافت نشد</td></tr>]])
else
    for _, item in ipairs(report_rows) do
        local drill_cell
        if item.force_client or item.force_floating then
            drill_cell = safe_format(
                [[<button type="button" class="btn-drill" id="drillBtn-%s" onclick="toggleDrillRows('%s','%s','%s')">تفصیلی ▾</button>]],
                escape_html(item.account_id), escape_html(item.account_id),
                escape_html(item.account_name), escape_html(item.account_code)
            )
        else
            drill_cell = "—"
        end
        table.insert(table_rows_html, safe_format(
            [[<tr class="acc-row" id="accRow-%s" data-code="%s" data-name="%s">
                <td>%s</td>
                <td class="code-cell" onclick="drillToCode('%s')" title="کلیک برای نمایش زیرمجموعه‌های این کد">%s</td>
                <td class="name-cell">%s</td>
                <td>%s</td>
                <td>%s</td>
                <td>%s</td>
                <td>%s</td>
                <td>%s</td>
                <td class="drill-cell">%s</td>
            </tr>]],
            escape_html(item.account_id),
            escape_html(item.account_code),
            escape_html(item.account_name),
            fmt_num(item.row_no),
            escape_html(item.account_code),
            escape_html(item.account_code),
            escape_html(item.account_name),
            escape_html(item.level),
            fmt_num(item.turnover_debit),
            fmt_num(item.turnover_credit),
            fmt_num(item.debit_balance),
            fmt_num(item.credit_balance),
            drill_cell
        ))
    end
end

local from_label = from_jalali or "—"
local to_label = to_jalali or "—"
local account_label = account_code or "—"

local ok_html, html_or_err = pcall(function()
    return safe_format([[
<!DOCTYPE html>
<html dir="rtl" lang="fa">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>تراز آزمایشی</title>
<style>
@font-face {
    font-family: "YekanBakhReport";
    src: local("Yekan Bakh"), local("YekanBakh");
    font-weight: 400; font-style: normal; font-display: swap;
}
* { font-family: "YekanBakhReport", "Yekan Bakh", "IRANSans", "Tahoma", "Arial", sans-serif !important; box-sizing: border-box; }
body { margin: 0; padding: 12px; background: #f5f5f5; color: #000; font-size: 14px; }
#reportRoot:fullscreen { background: #f5f5f5; padding: 12px; overflow: auto; }
.toolbar { display: flex; justify-content: flex-end; align-items: center; gap: 8px; flex-wrap: wrap; margin-bottom: 10px; }
.btn-action { background: #16509D; color: #fff; border: 2px solid #16509D; border-radius: 8px; padding: 8px 16px; font-size: 14px; font-weight: bold; cursor: pointer; }
.btn-action:hover { background: #b8005a; }
.filter-box { flex: 1 1 320px; min-width: 220px; max-width: 460px; margin-left: auto; padding: 8px 12px; font-size: 14px; border: 2px solid #16509D; border-radius: 8px; outline: none; color: #000; }
.filter-box:focus { box-shadow: 0 0 0 2px rgba(229,0,110,0.2); }
.code-cell { cursor: pointer; color: #16509D; font-weight: bold; text-decoration: underline dotted; }
.code-cell:hover { color: #b8005a; }
.filter-summary { background: #fff; border: 2px dashed #16509D; border-radius: 8px; padding: 8px 10px; margin-bottom: 10px; font-size: 14px; text-align: center; }
.btn-drill { background: #fff; color: #16509D; border: 2px solid #16509D; border-radius: 6px; padding: 4px 10px; font-size: 14px; font-weight: bold; cursor: pointer; white-space: nowrap; }
.btn-drill:hover { background: #16509D; color: #fff; }
.drill-cell { cursor: default; }
tr.drill-sub-row { background: #fff !important; }
tr.drill-sub-row td { color: #444; }
tr.drill-sub-row td.name-cell { padding-right: 26px; font-weight: normal; }
tr.drill-sub-row td.name-cell::before { content: '↳ '; color: #16509D; font-weight: bold; }
tr.drill-loading-row td, tr.drill-empty-row td { padding: 14px !important; color: #666; }
tr.drill-action-row td { padding: 8px !important; background: #fff !important; }
.btn-drill-export { background: #16509D; color: #fff; border: none; border-radius: 6px; padding: 5px 12px; font-size: 14px; font-weight: bold; cursor: pointer; }
.btn-drill-export:hover { background: #b8005a; }
.help-overlay { display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.5); z-index: 100; align-items: center; justify-content: center; }
.help-overlay.open { display: flex; }
.help-modal { background: #fff; border-radius: 10px; max-width: 780px; width: 92%%; max-height: 84vh; overflow-y: auto; box-shadow: 0 8px 24px rgba(0,0,0,0.3); }
.help-modal-header { display: flex; justify-content: space-between; align-items: center; background: #16509D; color: #fff; padding: 12px 16px; border-radius: 10px 10px 0 0; font-size: 15px; font-weight: bold; position: sticky; top: 0; }
.help-close { background: transparent; border: none; color: #fff; font-size: 16px; cursor: pointer; }
.help-modal-body { padding: 16px; text-align: right; font-size: 14px; }
.help-modal-body p { margin: 10px 0; line-height: 1.8; }
.help-modal-body ul { margin: 6px 0 14px; padding-right: 20px; }
.help-modal-body li { margin: 6px 0; line-height: 1.7; }
.help-modal-body code { background: #f5f5f5; padding: 2px 6px; border-radius: 4px; }
.report-header { background-color: #f5f5f5; text-align: center; border: 1px dotted #666; border-radius: 10px; padding: 12px 10px 16px; margin-bottom: 12px; }
.report-header p { margin: 4px 0; font-size: 14px; }
.report-header p:first-child { font-size: 15px; font-weight: bold; }
.meta-line { font-size: 14px; color: #666; margin-top: 8px; }
.summary-table { width: 100%%; border-collapse: collapse; margin-bottom: 12px; border: 2px solid #000; border-radius: 8px; overflow: hidden; }
.summary-table td { border: 1px dashed #666; padding: 10px 8px; text-align: center; font-size: 14px; }
.summary-table .summary-head { background: #16509D; color: #fff; font-size: 15px; font-weight: bold; }
.summary-table .summary-value { background: #f5f5f5; color: #000; font-size: 14px; font-weight: bold; }
.table-wrap { overflow: auto; max-height: 70vh; border: 2px solid #000; border-radius: 8px; background: #fff; }
table.main-table { width: auto; table-layout: auto; border-collapse: collapse; text-align: center; }
table.main-table thead th { position: sticky; top: 0; z-index: 2; background-color: #16509D; color: #fff; border: 1px dashed #666; padding: 10px 8px; font-size: 15px; font-weight: bold; white-space: nowrap; width: 1%%; cursor: pointer; user-select: none; }
table.main-table thead th.sort-asc::after { content: ' ▲'; }
table.main-table thead th.sort-desc::after { content: ' ▼'; }
table.main-table tbody td { border: 1px dashed #666; padding: 8px; font-size: 14px; vertical-align: middle; white-space: nowrap; width: 1%%; }
table.main-table tbody tr:nth-child(even) { background-color: #f5f5f5; }
.name-cell { text-align: right; font-weight: bold; }
.empty-row { padding: 24px !important; color: #666; }
.footer { text-align: center; color: #666; font-size: 14px; margin-top: 10px; }
</style>
</head>
<body>
<div id="reportRoot">
    <div class="toolbar">
        <input type="text" id="codeFilterBox" class="filter-box" placeholder="فیلتر زیرمجموعه: کد حساب (مثلاً 104001) یا نام حساب..." oninput="onCodeFilterInput()">
        <button type="button" class="btn-action" id="btnClearFilter" onclick="clearCodeFilter()" style="display:none;">پاک‌کردن فیلتر</button>
        <button type="button" class="btn-action" id="btnFullscreen" onclick="toggleFullScreen()">تمام صفحه</button>
        <button type="button" class="btn-action" onclick="exportTableToExcel()">خروجی Excel</button>
        <button type="button" class="btn-action" onclick="openHelpModal()">راهنما</button>
    </div>
    <div class="filter-summary" id="filterSummary" style="display:none;"></div>

    <div id="helpModalOverlay" class="help-overlay" onclick="if(event.target===this){closeHelpModal();}">
        <div class="help-modal">
            <div class="help-modal-header">
                <strong>راهنمای تراز آزمایشی</strong>
                <button type="button" class="help-close" onclick="closeHelpModal()">✕</button>
            </div>
            <div class="help-modal-body">
                <p><strong>این گزارش چیست؟</strong> تراز آزمایشی چهارستونی کلیه حساب‌های قابل ثبت سند (معین/تفصیلی) سازمان، شامل گردش دوره و مانده تجمعی تا پایان دوره.</p>
                <p><strong>ستون‌ها:</strong></p>
                <ul>
                    <li><b>کد / نام حساب</b> — کد و عنوان حساب</li>
                    <li><b>سطح</b> — سطح حساب در درخت حساب‌ها (<code>pa_account.LEVEL</code>)</li>
                    <li><b>گردش بدهکار / بستانکار</b> — جمع بدهکار/بستانکار آرتیکل‌های سند در بازه انتخابی</li>
                    <li><b>مانده بدهکار / بستانکار</b> — مانده تجمعی حساب از ابتدای دفاتر تا پایان بازه (تاریخ پایان)</li>
                    <li><b>تفصیلی</b> — برای حساب‌های کنترلی که پایین‌تر از آنها زیرحساب pa_account ندارند اما تفصیلی/مشتری یا شناور اجباری دارند (مثل «حسابهای دریافتنی تجاری»)، دکمه «تفصیلی ▾» یک سطح پایین‌تر (ریز مشتریان/شناورها) را در همان بازه نشان می‌دهد</li>
                </ul>
                <p><strong>فیلترها:</strong> <code>from_date</code> و <code>to_date</code> (پیش‌فرض: سال مالی فعال تا امروز)، <code>org_id</code> (پیش‌فرض 2)، <code>account_code</code> (پیشوند کد حساب)، <code>show_zero=1</code> برای نمایش حساب‌های بدون گردش.</p>
                <p><strong>تعامل‌ها:</strong> کلیک روی هدر ستون‌ها برای مرتب‌سازی صعودی/نزولی، دکمه «خروجی Excel» برای دریافت CSV. کلیک روی <b>کد حساب</b> در هر ردیف (یا تایپ کد/نام در کادر بالای جدول) زیرمجموعه‌های همان کد را فیلتر می‌کند و جمع ستون‌ها برای همان زیرمجموعه در نوار خلاصه نمایش داده می‌شود (مثلاً کد <code>104001</code> برای دیدن همه زیرحساب‌های «حساب‌های دریافتنی تجاری»).</p>
                <p><strong>منبع داده:</strong> فقط اسناد تأییدشده (<code>pa_voucher.STATUS NOT IN (0,3)</code>) و حذف‌نشده در نظر گرفته می‌شوند.</p>
            </div>
        </div>
    </div>

    <div class="report-header">
        <p>تراز آزمایشی چهارستونی</p>
        <p class="meta-line">از تاریخ: %s | تا تاریخ: %s | کد حساب: %s | سازمان: %s</p>
        <p class="meta-line">زمان تولید: %s | تعداد ردیف: %s</p>
    </div>

    <table class="summary-table">
        <tr class="summary-head">
            <td>جمع گردش بدهکار</td>
            <td>جمع گردش بستانکار</td>
            <td>جمع مانده بدهکار</td>
            <td>جمع مانده بستانکار</td>
        </tr>
        <tr>
            <td class="summary-value">%s</td>
            <td class="summary-value">%s</td>
            <td class="summary-value">%s</td>
            <td class="summary-value">%s</td>
        </tr>
    </table>

    <div class="table-wrap">
        <table class="main-table">
            <thead>
                <tr>
                    <th>ردیف</th><th>کد حساب</th><th>نام حساب</th><th>سطح</th>
                    <th>گردش بدهکار</th><th>گردش بستانکار</th>
                    <th>مانده بدهکار</th><th>مانده بستانکار</th><th class="no-sort">تفصیلی</th>
                </tr>
            </thead>
            <tbody id="resultTbody">
                %s
            </tbody>
        </table>
    </div>

    <div class="footer">Teamyar Trial Balance Report</div>
</div>

<script>
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
    var table = document.querySelector('.table-wrap table');
    if (!table) return;
    var lines = [];
    var hc = table.querySelectorAll('thead th');
    var hl = [];
    for (var h = 0; h < hc.length; h++) hl.push(csvEscapeCell(hc[h].innerText));
    lines.push(hl.join(','));
    var rows = table.querySelectorAll('tbody tr');
    for (var i = 0; i < rows.length; i++) {
        if (rows[i].querySelector('td.empty-row')) continue;
        if (rows[i].classList.contains('drill-loading-row') || rows[i].classList.contains('drill-empty-row') || rows[i].classList.contains('drill-action-row')) continue;
        var cells = rows[i].querySelectorAll('td');
        var line = [];
        for (var c = 0; c < cells.length; c++) line.push(csvEscapeCell(cells[c].innerText));
        lines.push(line.join(','));
    }
    downloadCsv(lines, 'تراز-آزمایشی.csv');
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
document.addEventListener('fullscreenchange', syncFullscreenButton);
document.addEventListener('webkitfullscreenchange', syncFullscreenButton);
function syncFullscreenButton() {
    var btn = document.getElementById('btnFullscreen');
    var isFull = document.fullscreenElement || document.webkitFullscreenElement || document.msFullscreenElement;
    btn.innerText = isFull ? 'خروج از تمام صفحه' : 'تمام صفحه';
}
function getCellSortValue(cell) {
    var text = cell ? cell.innerText.trim() : '';
    var n = text.replace(/[,٪%%]/g, '').trim();
    if (n !== '' && /^-?\d+(\.\d+)?$/.test(n)) return parseFloat(n);
    return text;
}
function sortTableByColumn(table, colIndex, dir) {
    var tbody = table.querySelector('tbody');
    var rows = Array.prototype.slice.call(tbody.querySelectorAll('tr'));
    rows.sort(function (ra, rb) {
        var a = getCellSortValue(ra.children[colIndex]), b = getCellSortValue(rb.children[colIndex]), cmp;
        if (typeof a === 'number' && typeof b === 'number') cmp = a - b;
        else cmp = String(a).localeCompare(String(b), 'fa');
        return dir === 'asc' ? cmp : -cmp;
    });
    rows.forEach(function (row) { tbody.appendChild(row); });
}
function initSortableTables() {
    document.querySelectorAll('table.main-table').forEach(function (table) {
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
function openHelpModal() { document.getElementById('helpModalOverlay').classList.add('open'); }
function closeHelpModal() { document.getElementById('helpModalOverlay').classList.remove('open'); }
document.addEventListener('keydown', function (e) { if (e.key === 'Escape') closeHelpModal(); });

function faNorm(t) {
    return (t || '').toString().toLowerCase().replace(/ي/g, 'ی').replace(/ك/g, 'ک').replace(/\s+/g, ' ').trim();
}
function parseAmountCell(text) {
    var n = (text || '').toString().replace(/,/g, '').trim();
    return n !== '' && /^-?\d+(\.\d+)?$/.test(n) ? parseFloat(n) : 0;
}
function applyCodeFilter(term) {
    var t = term.trim();
    var tNorm = faNorm(t);
    var rows = document.querySelectorAll('#resultTbody tr.acc-row');
    var shown = 0;
    var sumTurnoverDebit = 0, sumTurnoverCredit = 0, sumDebitBalance = 0, sumCreditBalance = 0;
    rows.forEach(function (row) {
        var code = (row.getAttribute('data-code') || '').toString();
        var name = faNorm(row.getAttribute('data-name'));
        var visible = t === '' || code.indexOf(t) === 0 || name.indexOf(tNorm) !== -1;
        row.style.display = visible ? '' : 'none';
        if (visible) {
            shown++;
            var cells = row.children;
            sumTurnoverDebit += parseAmountCell(cells[4].innerText);
            sumTurnoverCredit += parseAmountCell(cells[5].innerText);
            sumDebitBalance += parseAmountCell(cells[6].innerText);
            sumCreditBalance += parseAmountCell(cells[7].innerText);
        }
    });
    var summary = document.getElementById('filterSummary');
    var clearBtn = document.getElementById('btnClearFilter');
    if (t === '') {
        summary.style.display = 'none';
        clearBtn.style.display = 'none';
        return;
    }
    clearBtn.style.display = '';
    summary.style.display = '';
    summary.textContent = 'نتایج فیلتر «' + t + '»: ' + shown + ' حساب | جمع گردش بدهکار: ' + fmtNum(sumTurnoverDebit)
        + ' | جمع گردش بستانکار: ' + fmtNum(sumTurnoverCredit)
        + ' | جمع مانده بدهکار: ' + fmtNum(sumDebitBalance)
        + ' | جمع مانده بستانکار: ' + fmtNum(sumCreditBalance);
}
function fmtNum(n) {
    var v = Math.round(Number(n) || 0);
    var sign = v < 0 ? '-' : '';
    return sign + Math.abs(v).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}
function onCodeFilterInput() {
    applyCodeFilter(document.getElementById('codeFilterBox').value);
}
function drillToCode(code) {
    var box = document.getElementById('codeFilterBox');
    box.value = code;
    applyCodeFilter(code);
    box.scrollIntoView({ behavior: 'smooth', block: 'start' });
}
function clearCodeFilter() {
    var box = document.getElementById('codeFilterBox');
    box.value = '';
    applyCodeFilter('');
}

var RUN_URL = (location.pathname.indexOf('/bot/run/') === 0)
    ? location.pathname
    : '/bot/run/258/trial_balance_report';

var drillCache = {};
var drillRowClass = function (accountId) { return 'drill-sub-' + accountId; };

function collapseDrillRows(accountId) {
    document.querySelectorAll('.' + drillRowClass(accountId)).forEach(function (row) { row.remove(); });
    var btn = document.getElementById('drillBtn-' + accountId);
    if (btn) { btn.textContent = 'تفصیلی ▾'; btn.disabled = false; }
}

function buildDrillRow(item, accountId, cssClass) {
    var tr = document.createElement('tr');
    tr.className = cssClass;
    tr.innerHTML = '<td>—</td>'
        + '<td>' + (item.client_code || '—') + '</td>'
        + '<td class="name-cell">' + (item.client_name || '—') + '</td>'
        + '<td>—</td>'
        + '<td>' + fmtNum(item.turnover_debit) + '</td>'
        + '<td>' + fmtNum(item.turnover_credit) + '</td>'
        + '<td>' + fmtNum(item.debit_balance) + '</td>'
        + '<td>' + fmtNum(item.credit_balance) + '</td>'
        + '<td>—</td>';
    return tr;
}

function renderDrillRowsInline(accountId, accountName, accountCode, items) {
    var parentRow = document.getElementById('accRow-' + accountId);
    var btn = document.getElementById('drillBtn-' + accountId);
    if (!parentRow) return;
    var cssClass = 'drill-sub-row ' + drillRowClass(accountId);
    var anchor = parentRow;

    if (!items) {
        var errRow = document.createElement('tr');
        errRow.className = 'drill-empty-row ' + drillRowClass(accountId);
        errRow.innerHTML = '<td colspan="9">خطا در دریافت تفصیلی.</td>';
        anchor.after(errRow);
        if (btn) { btn.textContent = '▴ بستن تفصیلی'; btn.disabled = false; }
        return;
    }
    if (items.length === 0) {
        var emptyRow = document.createElement('tr');
        emptyRow.className = 'drill-empty-row ' + drillRowClass(accountId);
        emptyRow.innerHTML = '<td colspan="9">برای این حساب در بازه انتخابی تفصیلی/مشتری‌ای با گردش یا مانده یافت نشد.</td>';
        anchor.after(emptyRow);
        if (btn) { btn.textContent = '▴ بستن تفصیلی'; btn.disabled = false; }
        return;
    }

    for (var i = 0; i < items.length; i++) {
        var row = buildDrillRow(items[i], accountId, cssClass);
        anchor.after(row);
        anchor = row;
    }
    var actionRow = document.createElement('tr');
    actionRow.className = 'drill-action-row ' + drillRowClass(accountId);
    actionRow.innerHTML = '<td colspan="9"><button type="button" class="btn-drill-export">خروجی Excel تفصیلی ' + accountCode + '</button></td>';
    actionRow.querySelector('button').addEventListener('click', function () { exportDrillExcel(accountId, accountCode); });
    anchor.after(actionRow);

    if (btn) { btn.textContent = '▴ بستن تفصیلی'; btn.disabled = false; }
}

function toggleDrillRows(accountId, accountName, accountCode) {
    var btn = document.getElementById('drillBtn-' + accountId);
    var existing = document.querySelector('.' + drillRowClass(accountId));
    if (existing) { collapseDrillRows(accountId); return; }

    if (btn) { btn.textContent = 'در حال بارگذاری...'; btn.disabled = true; }
    var loadingRow = document.createElement('tr');
    loadingRow.className = 'drill-loading-row ' + drillRowClass(accountId);
    loadingRow.innerHTML = '<td colspan="9">در حال بارگذاری تفصیلی...</td>';
    document.getElementById('accRow-' + accountId).after(loadingRow);

    var fd = new FormData();
    fd.append('drill_account_id', accountId);
    fd.append('format', 'json');
    fetch(RUN_URL + '?ver=0', { method: 'POST', credentials: 'same-origin', headers: { 'X-Requested-With': 'XMLHttpRequest' }, body: fd })
        .then(function (r) { return r.json(); })
        .then(function (data) {
            loadingRow.remove();
            var items = data && data.ok ? data.items : null;
            drillCache[accountId] = items;
            renderDrillRowsInline(accountId, accountName, accountCode, items);
        })
        .catch(function () {
            loadingRow.remove();
            renderDrillRowsInline(accountId, accountName, accountCode, null);
        });
}

function exportDrillExcel(accountId, accountCode) {
    var items = drillCache[accountId];
    if (!items || items.length === 0) return;
    var lines = [['ردیف', 'کد تفصیلی', 'نام تفصیلی/مشتری', 'گردش بدهکار', 'گردش بستانکار', 'مانده بدهکار', 'مانده بستانکار'].map(csvEscapeCell).join(',')];
    for (var i = 0; i < items.length; i++) {
        var it = items[i];
        lines.push([i + 1, it.client_code || '', it.client_name || '', fmtNum(it.turnover_debit), fmtNum(it.turnover_credit), fmtNum(it.debit_balance), fmtNum(it.credit_balance)].map(csvEscapeCell).join(','));
    }
    downloadCsv(lines, 'تفصیلی-' + accountCode + '.csv');
}

initSortableTables();
</script>
</body>
</html>
]],
    escape_html(from_label), escape_html(to_label), escape_html(account_label), escape_html(org_id),
    escape_html(generated_at), escape_html(#report_rows),
    fmt_num(total_turnover_debit), fmt_num(total_turnover_credit),
    fmt_num(total_debit_balance), fmt_num(total_credit_balance),
    table.concat(table_rows_html, "\n")
    )
end)

if not ok_html then
    fail("خطا در ساخت گزارش HTML", tostring(html_or_err))
    return
end

teamyar.write_result(html_or_err)
