-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/06/07 22:56

-- بات Discovery برای «داشبورد عملکرد کاربران واحد مالی» (finance_activity_dashboard_v01)
-- هدف: اثبات Table/Column/مقادیر واقعی قبل از ساخت Bot نهایی — طبق قانون اصلی، هیچ Business Logic حدس زده نشده.
-- تمام جداول/ستون‌های زیر از دیتابیس واقعی (docs/context/DatabaseSchema.md، خروجی db_schema_json_bot در این پروژه) استخراج شده‌اند:
--   profile_group_member(GROUP_ID, USER_ID) — عضویت گروه (2,191,465 ردیف — جدول فعال پلتفرم)
--   profile_main(ID, FULLNAME, TYPE)        — نام کامل کاربر
--   admin_user(ID, USERNAME, EXPIRATION, LAST_ACCESS, DATE_CREATE) — هیچ ستون ACTIVE/DISABLE واقعی روی کاربر پیدا نشد (اثبات‌شده با جست‌وجوی کامل ستون‌ها، نه فرض)
--   sales_invoice(ID, USER_CREATE, USER_MODIFIED, DATE_CREATE, DATE_MODIFIED, DELETED, CANCELED, REJECT, STATUS, RUN_DATE)
--   sales_history(ID, TYPE, INVOICE_ID, AUTHOR_ID, DATE_MODIFY, CONTENT, NOTE) — معنای دقیق هر TYPE هنوز اثبات نشده (نمونه NOTE برای هر TYPE در این بات برگردانده می‌شود)
--   purchase_invoice(ID, USER_CREATE, USER_MODIFIED, DATE_CREATE, DATE_MODIFIED, DELETED, CANCELED, REJECT, STATUS, RUN_DATE)
--   purchase_history(ID, TYPE, INVOICE_ID, AUTHOR_ID, DATE_MODIFY, CONTENT, NOTE)
--   pa_voucher(ID, USER_CREATE, USER_MODIFIED, DATE_CREATE, DATE_MODIFIED, DELETED, STATUS) — طبق trial_balance_report_bot.lua: STATUS NOT IN (0,3) یعنی «سند تأییدشده»؛ نگاشت دقیق هر مقدار STATUS هنوز اثبات نشده
--   pa_voucher_signs(VOUCHER_ID, ORG_ID, USER_ID, SIGN, DATE_SIGN) — نزدیک‌ترین جدول به «تایید/امضای سند» به تفکیک کاربر؛ معنای دقیق هر مقدار SIGN هنوز اثبات نشده
--   report_dimdate(DATEKEY, JNDATE, ...) — تبدیل شمسی/FileTime طبق نمونه تاییدشده (JNDATE='1405/01/01' <-> DATEKEY=134185248000000000)
--
-- خروجی این بات فقط JSON خام (شمارش‌ها + نمونه‌های واقعی متن) است، نه Dashboard نهایی —
-- تا معنای TYPE/STATUS/SIGN از روی داده واقعی (نه حدس) تعیین شود، سپس finance_activity_dashboard_v01 ساخته شود.

local input = teamyar.get_input() or {}

local DAY_TICKS = 10000000 * 86400 -- تیک FileTime در هر روز (همان ثابت schema_probe_v2_bot.lua / action_management_dashboard_report_bot.lua)
local DEFAULT_GROUP_ID = 36390
local SAMPLE_LIMIT = 80

local function out(o) teamyar.write_result(json.encode(o)) end

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

local function normalize_entity_id(value)
    local n = tonumber(value)
    if n ~= nil and n > 0 then return n end
    return nil
end

local mode = input["mode"] or "all"
local group_id = normalize_entity_id(input["group_id"]) or DEFAULT_GROUP_ID

-- ============================================================
-- بازه زمانی: هرگز os.date/تبدیل دستی — طبق قانون CLAUDE.md
-- اگر from_jdate/to_jdate (شمسی، مثل 1405/01/01) داده شود از report_dimdate resolve می‌شود.
-- در غیر این صورت پیش‌فرض 180 روز اخیر با همان فرمول تاییدشده FileTime محاسبه می‌شود.
-- ============================================================
local function resolve_jdate_to_datekey(jdate)
    local rows, err = fetch_rows(
        "SELECT DATEKEY FROM report_dimdate WHERE JNDATE = ? LIMIT 1", { jdate })
    if rows == nil or #rows == 0 then return nil, err end
    return tonumber(rows[1][1])
end

local function resolve_date_range()
    local from_jdate = input["from_jdate"] or input["fromJDate"]
    local to_jdate = input["to_jdate"] or input["toJDate"]
    local from_raw = normalize_entity_id(input["from_raw"])
    local to_raw = normalize_entity_id(input["to_raw"])

    if from_raw ~= nil and to_raw ~= nil then
        return from_raw, to_raw, "from_raw/to_raw (ورودی مستقیم)"
    end

    if from_jdate ~= nil and to_jdate ~= nil then
        local from_key, e1 = resolve_jdate_to_datekey(from_jdate)
        local to_key, e2 = resolve_jdate_to_datekey(to_jdate)
        if from_key == nil then
            return nil, nil, nil, "from_jdate در report_dimdate پیدا نشد: " .. tostring(from_jdate) .. " " .. tostring(e1)
        end
        if to_key == nil then
            return nil, nil, nil, "to_jdate در report_dimdate پیدا نشد: " .. tostring(to_jdate) .. " " .. tostring(e2)
        end
        return from_key, to_key + DAY_TICKS - 1, "report_dimdate.JNDATE"
    end

    -- پیش‌فرض: 180 روز اخیر — فرمول FileTime همان فرمول تاییدشده schema_probe_v2_bot.lua
    local now_rows, e0 = fetch_rows("SELECT (UNIX_TIMESTAMP() + 11644473600) * 10000000 AS now_raw", {})
    if now_rows == nil then
        return nil, nil, nil, "محاسبه now_raw شکست خورد: " .. tostring(e0)
    end
    local now_raw = tonumber(now_rows[1][1])
    return now_raw - (180 * DAY_TICKS), now_raw, "پیش‌فرض 180 روز اخیر (now_raw محاسبه‌شده)"
end

local from_raw, to_raw, range_source, range_err = resolve_date_range()
if range_err ~= nil then
    out({ ok = false, error = range_err })
    return
end

-- ============================================================
-- مرحله ۱: اعضای گروه واحد مالی
-- ============================================================
local function get_group_members()
    return fetch_rows([[
        SELECT
            gm.USER_ID,
            COALESCE(pm.FULLNAME, 'نامشخص') AS FULLNAME,
            au.USERNAME,
            au.EXPIRATION,
            au.LAST_ACCESS,
            au.DATE_CREATE AS ACCOUNT_DATE_CREATE
        FROM profile_group_member gm
        LEFT JOIN profile_main pm ON pm.ID = gm.USER_ID
        LEFT JOIN admin_user au ON au.ID = gm.USER_ID
        WHERE gm.GROUP_ID = ?
        ORDER BY pm.FULLNAME
    ]], { group_id })
end

local ACTIVE_STATUS_NOTE = "هیچ ستون ACTIVE/DISABLE/STATUS روی کاربر (admin_user/profile_main) در schema پیدا نشد — " ..
    "EXPIRATION و LAST_ACCESS برای تصمیم‌گیری درباره «فعال/غیرفعال» برگردانده شده، اما تفسیر آن نیاز به تایید شما دارد."

if mode == "group_members" then
    local rows, err = get_group_members()
    if rows == nil then
        out({ ok = false, step = "group_members", error = tostring(err) })
        return
    end
    out({
        ok = true,
        group_id = group_id,
        member_count = #rows,
        note = ACTIVE_STATUS_NOTE,
        members = rows
    })
    return
end

-- ============================================================
-- مرحله ۳: فروش — sales_invoice (CREATE/EDIT/CANCEL/DELETE/REJECT) + sales_history (TYPE واقعی)
-- ============================================================
local function probe_sales()
    local result = {}

    result.create_by_user, result.err_create = fetch_rows([[
        SELECT si.USER_CREATE AS user_id, COUNT(DISTINCT si.ID) AS op_count
        FROM sales_invoice si
        WHERE si.USER_CREATE IN (SELECT USER_ID FROM profile_group_member WHERE GROUP_ID = ?)
          AND si.RUN_DATE BETWEEN ? AND ?
        GROUP BY si.USER_CREATE
    ]], { group_id, from_raw, to_raw })

    result.edit_by_user, result.err_edit = fetch_rows([[
        SELECT si.USER_MODIFIED AS user_id, COUNT(DISTINCT si.ID) AS op_count
        FROM sales_invoice si
        WHERE si.USER_MODIFIED IN (SELECT USER_ID FROM profile_group_member WHERE GROUP_ID = ?)
          AND si.DATE_MODIFIED BETWEEN ? AND ?
          AND si.DATE_MODIFIED <> si.DATE_CREATE
        GROUP BY si.USER_MODIFIED
    ]], { group_id, from_raw, to_raw })

    result.flags_by_user, result.err_flags = fetch_rows([[
        SELECT
            si.USER_MODIFIED AS user_id,
            SUM(CASE WHEN si.CANCELED = 1 THEN 1 ELSE 0 END) AS canceled_count,
            SUM(CASE WHEN si.DELETED = 1 THEN 1 ELSE 0 END) AS deleted_count,
            SUM(CASE WHEN si.REJECT = 1 THEN 1 ELSE 0 END) AS reject_count
        FROM sales_invoice si
        WHERE si.USER_MODIFIED IN (SELECT USER_ID FROM profile_group_member WHERE GROUP_ID = ?)
          AND si.DATE_MODIFIED BETWEEN ? AND ?
        GROUP BY si.USER_MODIFIED
    ]], { group_id, from_raw, to_raw })

    result.status_distribution, result.err_status = fetch_rows([[
        SELECT si.STATUS, COUNT(*) AS cnt
        FROM sales_invoice si
        WHERE (si.USER_CREATE IN (SELECT USER_ID FROM profile_group_member WHERE GROUP_ID = ?)
            OR si.USER_MODIFIED IN (SELECT USER_ID FROM profile_group_member WHERE GROUP_ID = ?))
          AND si.RUN_DATE BETWEEN ? AND ?
        GROUP BY si.STATUS
        ORDER BY si.STATUS
    ]], { group_id, group_id, from_raw, to_raw })

    result.history_type_distribution, result.err_hist_type = fetch_rows([[
        SELECT sh.TYPE, COUNT(*) AS cnt
        FROM sales_history sh
        WHERE sh.AUTHOR_ID IN (SELECT USER_ID FROM profile_group_member WHERE GROUP_ID = ?)
          AND sh.DATE_MODIFY BETWEEN ? AND ?
        GROUP BY sh.TYPE
        ORDER BY cnt DESC
    ]], { group_id, from_raw, to_raw })

    result.history_samples, result.err_hist_sample = fetch_rows([[
        SELECT sh.ID, sh.TYPE, sh.AUTHOR_ID, sh.INVOICE_ID, sh.DATE_MODIFY, sh.CONTENT, LEFT(sh.NOTE, 300) AS note_sample
        FROM sales_history sh
        WHERE sh.AUTHOR_ID IN (SELECT USER_ID FROM profile_group_member WHERE GROUP_ID = ?)
          AND sh.DATE_MODIFY BETWEEN ? AND ?
        ORDER BY sh.ID DESC
        LIMIT ]] .. tostring(SAMPLE_LIMIT), { group_id, from_raw, to_raw })

    return result
end

-- ============================================================
-- مرحله ۴: خرید — purchase_invoice + purchase_history (TYPE واقعی)
-- ============================================================
local function probe_purchase()
    local result = {}

    result.create_by_user, result.err_create = fetch_rows([[
        SELECT pi.USER_CREATE AS user_id, COUNT(DISTINCT pi.ID) AS op_count
        FROM purchase_invoice pi
        WHERE pi.USER_CREATE IN (SELECT USER_ID FROM profile_group_member WHERE GROUP_ID = ?)
          AND pi.RUN_DATE BETWEEN ? AND ?
        GROUP BY pi.USER_CREATE
    ]], { group_id, from_raw, to_raw })

    result.edit_by_user, result.err_edit = fetch_rows([[
        SELECT pi.USER_MODIFIED AS user_id, COUNT(DISTINCT pi.ID) AS op_count
        FROM purchase_invoice pi
        WHERE pi.USER_MODIFIED IN (SELECT USER_ID FROM profile_group_member WHERE GROUP_ID = ?)
          AND pi.DATE_MODIFIED BETWEEN ? AND ?
          AND pi.DATE_MODIFIED <> pi.DATE_CREATE
        GROUP BY pi.USER_MODIFIED
    ]], { group_id, from_raw, to_raw })

    result.flags_by_user, result.err_flags = fetch_rows([[
        SELECT
            pi.USER_MODIFIED AS user_id,
            SUM(CASE WHEN pi.CANCELED = 1 THEN 1 ELSE 0 END) AS canceled_count,
            SUM(CASE WHEN pi.DELETED = 1 THEN 1 ELSE 0 END) AS deleted_count,
            SUM(CASE WHEN pi.REJECT = 1 THEN 1 ELSE 0 END) AS reject_count
        FROM purchase_invoice pi
        WHERE pi.USER_MODIFIED IN (SELECT USER_ID FROM profile_group_member WHERE GROUP_ID = ?)
          AND pi.DATE_MODIFIED BETWEEN ? AND ?
        GROUP BY pi.USER_MODIFIED
    ]], { group_id, from_raw, to_raw })

    result.status_distribution, result.err_status = fetch_rows([[
        SELECT pi.STATUS, COUNT(*) AS cnt
        FROM purchase_invoice pi
        WHERE (pi.USER_CREATE IN (SELECT USER_ID FROM profile_group_member WHERE GROUP_ID = ?)
            OR pi.USER_MODIFIED IN (SELECT USER_ID FROM profile_group_member WHERE GROUP_ID = ?))
          AND pi.RUN_DATE BETWEEN ? AND ?
        GROUP BY pi.STATUS
        ORDER BY pi.STATUS
    ]], { group_id, group_id, from_raw, to_raw })

    result.history_type_distribution, result.err_hist_type = fetch_rows([[
        SELECT ph.TYPE, COUNT(*) AS cnt
        FROM purchase_history ph
        WHERE ph.AUTHOR_ID IN (SELECT USER_ID FROM profile_group_member WHERE GROUP_ID = ?)
          AND ph.DATE_MODIFY BETWEEN ? AND ?
        GROUP BY ph.TYPE
        ORDER BY cnt DESC
    ]], { group_id, from_raw, to_raw })

    result.history_samples, result.err_hist_sample = fetch_rows([[
        SELECT ph.ID, ph.TYPE, ph.AUTHOR_ID, ph.INVOICE_ID, ph.DATE_MODIFY, ph.CONTENT, LEFT(ph.NOTE, 300) AS note_sample
        FROM purchase_history ph
        WHERE ph.AUTHOR_ID IN (SELECT USER_ID FROM profile_group_member WHERE GROUP_ID = ?)
          AND ph.DATE_MODIFY BETWEEN ? AND ?
        ORDER BY ph.ID DESC
        LIMIT ]] .. tostring(SAMPLE_LIMIT), { group_id, from_raw, to_raw })

    return result
end

-- ============================================================
-- مرحله ۵: حسابداری — pa_voucher (CREATE/EDIT/STATUS) + pa_voucher_signs (SIGN به تفکیک کاربر)
-- ============================================================
local function probe_accounting()
    local result = {}

    result.create_by_user, result.err_create = fetch_rows([[
        SELECT v.USER_CREATE AS user_id, COUNT(DISTINCT v.ID) AS op_count
        FROM pa_voucher v
        WHERE v.USER_CREATE IN (SELECT USER_ID FROM profile_group_member WHERE GROUP_ID = ?)
          AND v.DATE_CREATE BETWEEN ? AND ?
          AND v.DELETED = 0
        GROUP BY v.USER_CREATE
    ]], { group_id, from_raw, to_raw })

    result.edit_by_user, result.err_edit = fetch_rows([[
        SELECT v.USER_MODIFIED AS user_id, COUNT(DISTINCT v.ID) AS op_count
        FROM pa_voucher v
        WHERE v.USER_MODIFIED IN (SELECT USER_ID FROM profile_group_member WHERE GROUP_ID = ?)
          AND v.DATE_MODIFIED BETWEEN ? AND ?
          AND v.DATE_MODIFIED <> v.DATE_CREATE
          AND v.DELETED = 0
        GROUP BY v.USER_MODIFIED
    ]], { group_id, from_raw, to_raw })

    result.deleted_by_user, result.err_deleted = fetch_rows([[
        SELECT v.USER_MODIFIED AS user_id, COUNT(DISTINCT v.ID) AS op_count
        FROM pa_voucher v
        WHERE v.USER_MODIFIED IN (SELECT USER_ID FROM profile_group_member WHERE GROUP_ID = ?)
          AND v.DATE_MODIFIED BETWEEN ? AND ?
          AND v.DELETED = 1
        GROUP BY v.USER_MODIFIED
    ]], { group_id, from_raw, to_raw })

    result.status_distribution, result.err_status = fetch_rows([[
        SELECT v.STATUS, COUNT(*) AS cnt
        FROM pa_voucher v
        WHERE (v.USER_CREATE IN (SELECT USER_ID FROM profile_group_member WHERE GROUP_ID = ?)
            OR v.USER_MODIFIED IN (SELECT USER_ID FROM profile_group_member WHERE GROUP_ID = ?))
          AND v.DATE_MODIFIED BETWEEN ? AND ?
        GROUP BY v.STATUS
        ORDER BY v.STATUS
    ]], { group_id, group_id, from_raw, to_raw })

    result.signs_by_user, result.err_signs = fetch_rows([[
        SELECT s.USER_ID AS user_id, s.SIGN, COUNT(*) AS cnt, MIN(s.DATE_SIGN) AS min_date, MAX(s.DATE_SIGN) AS max_date
        FROM pa_voucher_signs s
        WHERE s.USER_ID IN (SELECT USER_ID FROM profile_group_member WHERE GROUP_ID = ?)
          AND s.DATE_SIGN BETWEEN ? AND ?
        GROUP BY s.USER_ID, s.SIGN
        ORDER BY s.USER_ID, s.SIGN
    ]], { group_id, from_raw, to_raw })

    return result
end

-- ============================================================
-- بررسی report_dimdate برای بازه انتخابی (اثبات تبدیل شمسی)
-- ============================================================
local function probe_dimdate()
    return fetch_rows([[
        SELECT DATEKEY, JNDATE, JYEAR, JMONTH, JMDAY
        FROM report_dimdate
        WHERE DATEKEY BETWEEN ? AND ?
        ORDER BY DATEKEY
        LIMIT 5
    ]], { from_raw, to_raw })
end

-- ============================================================
-- rawp: کوئری آزاد پارامتری برای دیباگ بیشتر (همان الگوی schema_probe_v2_bot.lua)
-- ============================================================
if mode == "rawp" then
    local params_json = input["params"] or "[]"
    local ok_p, params = pcall(function() return json.decode(params_json) end)
    if not ok_p or params == nil then params = {} end
    local rows, err = fetch_rows(input["q"], params)
    if rows == nil then out({ ok = false, error = tostring(err), params_used = params }); return end
    out({ ok = true, rows = rows, params_used = params })
    return
end

local response = {
    ok = true,
    group_id = group_id,
    range = { from_raw = from_raw, to_raw = to_raw, source = range_source }
}

if mode == "all" then
    local rows, err = get_group_members()
    response.members = rows
    response.members_error = err ~= nil and tostring(err) or nil
    response.members_note = ACTIVE_STATUS_NOTE
end

if mode == "all" or mode == "sales_probe" then
    response.sales = probe_sales()
end

if mode == "all" or mode == "purchase_probe" then
    response.purchase = probe_purchase()
end

if mode == "all" or mode == "accounting_probe" then
    response.accounting = probe_accounting()
end

if mode == "all" or mode == "dimdate_probe" then
    response.dimdate_sample = probe_dimdate()
end

out(response)
