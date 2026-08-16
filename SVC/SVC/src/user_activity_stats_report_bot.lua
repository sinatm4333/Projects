-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/05/20 16:30

-- آمار فعالیت کاربر بر اساس نام
-- ورودی: user_name (یا fullname / name)
-- بازه: همیشه سال مالی جاری (شروع تا پایان) — org_id پیش‌فرض 2
-- گفتگوها: فیلتر روی DATE_CREATE
-- خروجی: HTML (پیش‌فرض) یا JSON با format=json

local input = teamyar.get_input() or {}

local user_name = input["user_name"] or input["userName"] or input["fullname"]
    or input["name"] or input["نام"] or input["کاربر"]

local function normalize_entity_id(value)
    local n = tonumber(value)
    if n ~= nil and n > 0 then
        return n
    end
    return nil
end

local org_id = normalize_entity_id(input["org_id"] or input["orgId"] or 2)

local function wants_json(source)
    local fmt = source["format"] or source["output"] or source["output_format"]
        or source["result_format"] or source["response_format"]
    if fmt ~= nil and tostring(fmt):lower() == "json" then
        return true
    end
    return false
end

local as_json = wants_json(input)

local REPORT_CSS = [[
@font-face {
  font-family: "YekanBakhReport";
  src: local("Yekan Bakh"), local("YekanBakh");
  font-weight: 400;
  font-style: normal;
  font-display: swap;
}
html, body, body *, button, input, select, textarea, table, th, td {
  font-family: "YekanBakhReport", "Yekan Bakh", "IRANSans", "Tahoma", "Arial", sans-serif !important;
}
html, body {
  margin: 0;
  padding: 0;
  background: #eef1f6;
  color: #23262d;
  font-size: 14px;
  font-weight: 400;
}
.page { padding: 18px; }
.shell {
  max-width: 1180px;
  margin: 0 auto;
  background: #fff;
  border: 1px solid #dbe1ea;
  border-radius: 16px;
  box-shadow: 0 8px 24px rgba(15, 23, 42, .06);
  overflow: hidden;
}
.header {
  display: flex;
  justify-content: space-between;
  gap: 16px;
  align-items: flex-start;
  padding: 20px 22px;
  border-bottom: 1px solid #e6ebf2;
  background: linear-gradient(135deg, #f7f9fc, #eef5ff);
}
.header .title h1 {
  margin: 0 0 6px;
  font-size: 24px;
  font-weight: 800;
  line-height: 1.45;
}
.header .title p {
  margin: 0;
  color: #5b6472;
  font-size: 14px;
  font-weight: 700;
}
.actions { display: flex; gap: 8px; flex-wrap: wrap; }
.btn {
  border: 1px solid #cfd8e6;
  background: #fff;
  color: #23262d;
  border-radius: 10px;
  padding: 8px 14px;
  font-size: 14px;
  font-weight: 800;
  cursor: pointer;
}
.btn.primary {
  background: #1d4ed8;
  border-color: #1d4ed8;
  color: #fff;
}
.kpis {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
  gap: 12px;
  padding: 16px 22px;
  border-bottom: 1px solid #e6ebf2;
  background: #fbfcfe;
}
.kpi {
  background: #fff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 12px 14px;
  min-height: 78px;
}
.kpi .l {
  color: #667085;
  font-size: 13px;
  font-weight: 800;
  margin-bottom: 8px;
}
.kpi .v {
  color: #101828;
  font-size: 22px;
  font-weight: 800;
  line-height: 1.2;
  direction: ltr;
  text-align: right;
  font-variant-numeric: tabular-nums;
}
.kpi .s {
  margin-top: 6px;
  color: #98a2b3;
  font-size: 12px;
  font-weight: 700;
}
.tools {
  display: flex;
  justify-content: space-between;
  gap: 10px;
  flex-wrap: wrap;
  padding: 12px 22px;
  border-bottom: 1px solid #e6ebf2;
}
.badge {
  display: inline-block;
  background: #f2f4f7;
  border: 1px solid #e4e7ec;
  border-radius: 999px;
  padding: 6px 12px;
  margin-left: 6px;
  font-size: 13px;
  font-weight: 800;
  color: #344054;
}
.badge b { color: #1d4ed8; }
.table-wrap { padding: 0 0 8px; overflow: auto; }
table {
  width: 100%;
  border-collapse: collapse;
}
th, td {
  padding: 14px 22px;
  border-bottom: 1px solid #eef2f6;
  text-align: right;
  font-size: 14px;
}
th {
  width: 62%;
  color: #475467;
  font-weight: 800;
  background: #fafbfc;
}
td {
  width: 38%;
  color: #101828;
  font-weight: 800;
  direction: ltr;
  text-align: right;
  font-variant-numeric: tabular-nums;
}
tr:last-child th, tr:last-child td { border-bottom: none; }
.footer {
  padding: 14px 22px 18px;
  color: #667085;
  font-size: 12px;
  font-weight: 700;
  border-top: 1px solid #e6ebf2;
  background: #fbfcfe;
}
.warn-box {
  margin: 18px;
  padding: 18px 20px;
  border-radius: 12px;
  border: 1px solid #fecaca;
  background: #fef2f2;
  color: #b91c1c;
  font-weight: 800;
}
.muted { color: #667085; font-weight: 700; }
.candidates { margin: 0 22px 22px; padding: 0 18px; }
.candidates li { margin: 8px 0; font-weight: 700; }
.filters {
  padding: 16px 22px;
  border-bottom: 1px solid #e6ebf2;
  background: #fbfcfe;
}
.filters .grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 12px;
}
.fi > label {
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  text-align: center;
  font-size: 13px;
  font-weight: 950;
  line-height: 1.55;
  color: #23262d;
  margin: 0 0 5px;
}
.fi .box {
  background: #fff;
  border: 1px solid #d0d5dd;
  border-radius: 10px;
  padding: 10px 12px;
  text-align: center;
  font-weight: 800;
  color: #101828;
}
]]

local function render_shell(title, subtitle, body_html, actions_html)
    actions_html = actions_html or ""
    return [[
<!doctype html>
<html lang="fa" dir="rtl">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>]] .. title .. [[</title>
<style>
]] .. REPORT_CSS .. [[
</style>
</head>
<body>
<div class="page">
  <div class="shell">
    <header class="header">
      <div class="title">
        <h1>]] .. title .. [[</h1>
        <p>]] .. subtitle .. [[</p>
      </div>
      <div class="actions">
]] .. actions_html .. [[
      </div>
    </header>
]] .. body_html .. [[
    <footer class="footer">
      گفتگو، اقدام، رسید/حواله، فاکتور فروش و اسناد مالی - بر اساس نام کاربر
    </footer>
  </div>
</div>
</body>
</html>
]]
end

local function fail(message, detail)
    if as_json then
        teamyar.write_result(json.encode({
            ok = false,
            error = message,
            detail = detail
        }))
    else
        local extra = ""
        if detail ~= nil and tostring(detail) ~= "" then
            extra = "<div class='muted' style='margin-top:8px;'>" .. tostring(detail) .. "</div>"
        end
        teamyar.write_result(render_shell(
            "آمار فعالیت کاربر",
            "خطا در اجرای گزارش",
            "<div class='warn-box'>" .. tostring(message) .. extra .. "</div>"
        ))
    end
end

local function normalize_text(value)
    if value == nil then
        return nil
    end
    local text = tostring(value):match("^%s*(.-)%s*$")
    if text == "" then
        return nil
    end
    return text
end

user_name = normalize_text(user_name)
if user_name == nil then
    fail("نام کاربر (user_name) وارد نشده است")
    return
end

local function fetch_rows(query, params)
    local ok, err = pcall(function()
        db.query({
            query = query,
            params = params or {}
        })
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

local function fetch_scalar(query, params)
    local rows, err = fetch_rows(query, params)
    if rows == nil then
        return nil, err
    end
    if #rows == 0 then
        return 0
    end
    return tonumber(rows[1][1]) or 0
end

local HTML_DQ = string.char(34)
local HTML_QUOT = string.char(38) .. "quot;"

local function escape_html(value)
    if value == nil then
        return ""
    end
    return tostring(value)
        :gsub("&", "&amp;")
        :gsub("<", "&lt;")
        :gsub(">", "&gt;")
        :gsub(HTML_DQ, HTML_QUOT)
end

local function fmt_num(value)
    local n = tonumber(value) or 0
    if n == math.floor(n) then
        return tostring(math.floor(n))
    end
    return string.format("%.2f", n)
end

local function fmt_hours(value)
    local n = tonumber(value)
    if n == nil then
        return "-"
    end
    return string.format("%.2f", n)
end

local function fetch_fiscal_bounds()
    local params = {}
    local org_clause = ""
    if org_id ~= nil then
        org_clause = " AND fy.ORG_ID = ?"
        table.insert(params, org_id)
    end

    local rows, err = fetch_rows([[
SELECT
    fy.START_DATE,
    fy.END_DATE,
    REPORT_FN_JDATE(fy.START_DATE, '-') AS start_jalali,
    REPORT_FN_JDATE(fy.END_DATE, '-') AS end_jalali
FROM pa_fiscal_year fy
WHERE (UNIX_TIMESTAMP() + 11644473600) * 10000000 >= fy.START_DATE
  AND (UNIX_TIMESTAMP() + 11644473600) * 10000000 <= fy.END_DATE
]] .. org_clause .. [[
ORDER BY fy.START_DATE DESC
LIMIT 1
]], params)

    if rows == nil then
        return nil, err
    end
    if #rows == 0 then
        return nil, "سال مالی جاری یافت نشد"
    end

    local start_ft = tonumber(rows[1][1])
    local end_ft = tonumber(rows[1][2])
    if start_ft == nil or end_ft == nil or start_ft <= 0 or end_ft <= 0 then
        return nil, "بازه سال مالی نامعتبر است"
    end

    return {
        start_filetime = start_ft,
        end_filetime = end_ft,
        start_jalali = tostring(rows[1][3] or ""),
        end_jalali = tostring(rows[1][4] or "")
    }
end

local function fiscal_between_sql(column)
    return column .. [[ >= ? AND ]] .. column .. [[ <= ?]]
end

-- پیدا کردن کاربر
local like_pattern = "%" .. user_name .. "%"
local user_rows, user_err = fetch_rows([[
SELECT
    pm.ID,
    pm.FULLNAME,
    COALESCE(NULLIF(TRIM(CONCAT(COALESCE(pui.NAME, ''), ' ', COALESCE(pui.SURNAME, ''))), ''), pm.FULLNAME) AS display_name
FROM profile_main pm
LEFT JOIN PROFILE_USER_INFO pui
    ON pui.id = pm.id
WHERE COALESCE(pm.is_role, 0) = 0
  AND (
        pm.FULLNAME = ?
     OR pm.FULLNAME LIKE ?
     OR CONCAT(COALESCE(pui.NAME, ''), ' ', COALESCE(pui.SURNAME, '')) = ?
     OR CONCAT(COALESCE(pui.NAME, ''), ' ', COALESCE(pui.SURNAME, '')) LIKE ?
     OR COALESCE(pui.NAME, '') LIKE ?
     OR COALESCE(pui.SURNAME, '') LIKE ?
  )
ORDER BY
    CASE
        WHEN pm.FULLNAME = ? THEN 0
        WHEN CONCAT(COALESCE(pui.NAME, ''), ' ', COALESCE(pui.SURNAME, '')) = ? THEN 1
        ELSE 2
    END,
    pm.FULLNAME
LIMIT 20
]], {
    user_name, like_pattern,
    user_name, like_pattern,
    like_pattern, like_pattern,
    user_name, user_name
})

if user_rows == nil then
    fail("خطا در جستجوی کاربر", tostring(user_err))
    return
end

if #user_rows == 0 then
    fail("کاربری با نام «" .. user_name .. "» یافت نشد")
    return
end

local exact_matches = {}
for _, row in ipairs(user_rows) do
    local fullname = normalize_text(row[2]) or ""
    local display = normalize_text(row[3]) or fullname
    if fullname == user_name or display == user_name then
        table.insert(exact_matches, row)
    end
end

local selected_users = (#exact_matches == 1) and exact_matches
    or ((#exact_matches > 1) and exact_matches or user_rows)

if #selected_users > 1 then
    local names = {}
    for _, row in ipairs(selected_users) do
        table.insert(names, {
            user_id = tonumber(row[1]) or row[1],
            fullname = row[2],
            display_name = row[3]
        })
    end
    if as_json then
        teamyar.write_result(json.encode({
            ok = false,
            error = "بیش از یک کاربر با این نام یافت شد؛ نام دقیق‌تر وارد کنید",
            candidates = names
        }))
    else
        local lis = {}
        for _, item in ipairs(names) do
            table.insert(lis, "<li>" .. escape_html(item.fullname)
                .. " <span class='muted'>(id=" .. tostring(item.user_id) .. ")</span></li>")
        end
        teamyar.write_result(render_shell(
            "آمار فعالیت کاربر",
            "بیش از یک کاربر با نام «" .. escape_html(user_name) .. "» یافت شد",
            [[
<div class="warn-box">نام دقیق‌تر وارد کنید.</div>
<ul class="candidates">]] .. table.concat(lis, "\n") .. [[</ul>
]],
            [[<span class="badge">نام مبهم</span>]]
        ))
    end
    return
end

local user_id = tonumber(selected_users[1][1]) or selected_users[1][1]
local user_fullname = normalize_text(selected_users[1][2]) or tostring(user_id)
local user_display = normalize_text(selected_users[1][3]) or user_fullname

local fiscal, fiscal_err = fetch_fiscal_bounds()
if fiscal == nil then
    fail("تاریخ سال مالی جاری مشخص نشد", tostring(fiscal_err))
    return
end

local fiscal_start = fiscal.start_filetime
local fiscal_end = fiscal.end_filetime
local fiscal_start_jalali = fiscal.start_jalali
local fiscal_end_jalali = fiscal.end_jalali
local fiscal_range_label = fiscal_start_jalali .. " تا " .. fiscal_end_jalali

local dialog_date_sql = fiscal_between_sql("cd.DATE_CREATE")
local step_date_sql = fiscal_between_sql("tts.DATE_CREATE")
local warehouse_date_sql = fiscal_between_sql("op.DATE_CREATE")
local invoice_date_sql = fiscal_between_sql("si.RUN_DATE")
local voucher_date_sql = fiscal_between_sql("v.RUN_DATE")

local dialogs_participated, err1 = fetch_scalar([[
SELECT COUNT(*) FROM (
    SELECT cd.ID AS dialog_id
    FROM chat_dialogs cd
    WHERE COALESCE(cd.deleted, 0) = 0
      AND ]] .. dialog_date_sql .. [[
      AND (
            cd.AUTHOR_ID = ?
         OR cd.RELATED_ID = ?
         OR EXISTS (
                SELECT 1 FROM chat_dialog_view cdv
                WHERE cdv.DIALOG_ID = cd.ID AND cdv.USER_ID = ?
            )
         OR EXISTS (
                SELECT 1 FROM chat_message cm
                WHERE cm.DIALOG_ID = cd.ID AND cm.USER_ID = ?
            )
      )
) t
]], { fiscal_start, fiscal_end, user_id, user_id, user_id, user_id })
if dialogs_participated == nil then
    fail("خطا در شمارش گفتگوهای کاربر", tostring(err1))
    return
end

local dialogs_created, err2 = fetch_scalar([[
SELECT COUNT(*)
FROM chat_dialogs cd
WHERE COALESCE(cd.deleted, 0) = 0
  AND cd.AUTHOR_ID = ?
  AND ]] .. dialog_date_sql .. [[
]], { user_id, fiscal_start, fiscal_end })
if dialogs_created == nil then
    fail("خطا در شمارش گفتگوهای ایجادشده", tostring(err2))
    return
end

local dialogs_contact_no_reply, err3 = fetch_scalar([[
SELECT COUNT(*)
FROM chat_dialogs cd
WHERE COALESCE(cd.deleted, 0) = 0
  AND ]] .. dialog_date_sql .. [[
  AND COALESCE(cd.AUTHOR_ID, 0) <> ?
  AND (
        cd.RELATED_ID = ?
     OR EXISTS (
            SELECT 1 FROM chat_dialog_view cdv
            WHERE cdv.DIALOG_ID = cd.ID AND cdv.USER_ID = ?
        )
  )
  AND NOT EXISTS (
        SELECT 1 FROM chat_message cm
        WHERE cm.DIALOG_ID = cd.ID AND cm.USER_ID = ?
  )
]], { fiscal_start, fiscal_end, user_id, user_id, user_id, user_id })
if dialogs_contact_no_reply == nil then
    fail("خطا در شمارش گفتگوهای بدون پاسخ", tostring(err3))
    return
end

local open_steps_count, err4 = fetch_scalar([[
SELECT COUNT(*)
FROM todo_task_steps tts
WHERE tts.RESPONSIBLE_ID = ?
  AND tts.STATUS = 0
  AND ]] .. step_date_sql .. [[
]], { user_id, fiscal_start, fiscal_end })
if open_steps_count == nil then
    fail("خطا در شمارش اقدامات باز", tostring(err4))
    return
end

local avg_step_hours_rows, err5 = fetch_rows([[
SELECT
    AVG(duration_hours) AS avg_hours,
    COUNT(*) AS completed_count
FROM (
    SELECT
        CASE
            WHEN COALESCE(tts.date_end, 0) > 0
             AND COALESCE(tts.date_start, 0) > 0
             AND tts.date_end >= tts.date_start
                THEN (tts.date_end - tts.date_start) / 10000000.0 / 3600.0
            WHEN COALESCE(tts.DATE_MODIFY, 0) > 0
             AND COALESCE(tts.DATE_CREATE, 0) > 0
             AND tts.DATE_MODIFY >= tts.DATE_CREATE
                THEN (tts.DATE_MODIFY - tts.DATE_CREATE) / 10000000.0 / 3600.0
            ELSE NULL
        END AS duration_hours
    FROM todo_task_steps tts
    WHERE tts.RESPONSIBLE_ID = ?
      AND tts.STATUS <> 0
      AND ]] .. step_date_sql .. [[
) durations
WHERE duration_hours IS NOT NULL
]], { user_id, fiscal_start, fiscal_end })
if avg_step_hours_rows == nil then
    fail("خطا در محاسبه میانگین زمان مرحله", tostring(err5))
    return
end

local avg_completed_step_hours = tonumber(avg_step_hours_rows[1] and avg_step_hours_rows[1][1]) or nil
local completed_steps_count = tonumber(avg_step_hours_rows[1] and avg_step_hours_rows[1][2]) or 0

local warehouse_rows, err6 = fetch_rows([[
SELECT
    COUNT(DISTINCT op.ID) AS doc_count,
    COUNT(od.ID) AS item_count
FROM wh_operation op
LEFT JOIN wh_operation_details od
    ON od.OPERATION_ID = op.ID
   AND COALESCE(od.DELETED, 0) = 0
WHERE op.AUTHOR_ID = ?
  AND COALESCE(op.DELETED, 0) = 0
  AND COALESCE(op.TEMP_FLAG, 0) = 0
  AND ]] .. warehouse_date_sql .. [[
]], { user_id, fiscal_start, fiscal_end })
if warehouse_rows == nil then
    fail("خطا در شمارش رسید/حواله", tostring(err6))
    return
end

local warehouse_doc_count = tonumber(warehouse_rows[1] and warehouse_rows[1][1]) or 0
local warehouse_item_count = tonumber(warehouse_rows[1] and warehouse_rows[1][2]) or 0

local sales_invoice_count, err7 = fetch_scalar([[
SELECT COUNT(*)
FROM sales_invoice si
WHERE si.USER_CREATE = ?
  AND COALESCE(si.DELETED, 0) = 0
  AND COALESCE(si.CANCELED, 0) = 0
  AND COALESCE(si.REJECT, 0) = 0
  AND ]] .. invoice_date_sql .. [[
]], { user_id, fiscal_start, fiscal_end })
if sales_invoice_count == nil then
    fail("خطا در شمارش فاکتورهای فروش", tostring(err7))
    return
end

local voucher_count, err8 = fetch_scalar([[
SELECT COUNT(*)
FROM pa_voucher v
WHERE v.USER_CREATE = ?
  AND COALESCE(v.DELETED, 0) = 0
  AND ]] .. voucher_date_sql .. [[
]], { user_id, fiscal_start, fiscal_end })
if voucher_count == nil then
    fail("خطا در شمارش اسناد مالی", tostring(err8))
    return
end

local voucher_record_count, err9 = fetch_scalar([[
SELECT COUNT(*)
FROM pa_voucher_record vr
INNER JOIN pa_voucher v
    ON v.ID = vr.VOUCHER_ID
   AND v.ORG_ID = vr.ORG_ID
WHERE v.USER_CREATE = ?
  AND COALESCE(v.DELETED, 0) = 0
  AND COALESCE(vr.DELETED, 0) = 0
  AND ]] .. voucher_date_sql .. [[
]], { user_id, fiscal_start, fiscal_end })
if voucher_record_count == nil then
    fail("خطا در شمارش ردیف اسناد مالی", tostring(err9))
    return
end

local warehouse_summary = fmt_num(warehouse_doc_count) .. " سند / " .. fmt_num(warehouse_item_count) .. " قلم"

local stats = {
    user_id = user_id,
    org_id = org_id,
    fiscal_start_date = fiscal_start_jalali,
    fiscal_end_date = fiscal_end_jalali,
    fiscal_range_label = fiscal_range_label,
    user_name = user_fullname,
    display_name = user_display,
    dialogs_participated_count = dialogs_participated,
    dialogs_created_count = dialogs_created,
    dialogs_contact_no_reply_count = dialogs_contact_no_reply,
    open_steps_count = open_steps_count,
    completed_steps_count = completed_steps_count,
    avg_completed_step_hours = avg_completed_step_hours,
    warehouse_doc_count = warehouse_doc_count,
    warehouse_item_count = warehouse_item_count,
    warehouse_summary = warehouse_summary,
    sales_invoice_count = sales_invoice_count,
    financial_voucher_count = voucher_count,
    financial_voucher_record_count = voucher_record_count
}

if as_json then
    teamyar.write_result(json.encode({
        ok = true,
        stats = stats
    }))
    return
end

local avg_hours_label = fmt_hours(avg_completed_step_hours)

local body_html = [[
<section class="filters">
  <div class="grid">
    <div class="fi"><label>بازه گزارش (سال مالی جاری)</label><div class="box">]] .. escape_html(fiscal_range_label) .. [[</div></div>
    <div class="fi"><label>نام کاربر</label><div class="box">]] .. escape_html(user_display) .. [[</div></div>
    <div class="fi"><label>شناسه کاربر</label><div class="box">]] .. tostring(user_id) .. [[</div></div>
    <div class="fi"><label>سازمان (org_id)</label><div class="box">]] .. tostring(org_id) .. [[</div></div>
  </div>
</section>

<section class="kpis">
  <div class="kpi"><div class="l">گفتگوهای کل</div><div class="v">]] .. fmt_num(dialogs_participated) .. [[</div></div>
  <div class="kpi"><div class="l">گفتگوهای ایجادشده</div><div class="v">]] .. fmt_num(dialogs_created) .. [[</div></div>
  <div class="kpi"><div class="l">مخاطب بدون پاسخ</div><div class="v">]] .. fmt_num(dialogs_contact_no_reply) .. [[</div></div>
  <div class="kpi"><div class="l">اقدامات باز</div><div class="v">]] .. fmt_num(open_steps_count) .. [[</div></div>
  <div class="kpi"><div class="l">میانگین زمان مرحله (ساعت)</div><div class="v">]] .. avg_hours_label .. [[</div><div class="s">از ]] .. fmt_num(completed_steps_count) .. [[ مرحله تکمیل‌شده</div></div>
  <div class="kpi"><div class="l">رسید / حواله</div><div class="v">]] .. fmt_num(warehouse_doc_count) .. [[</div><div class="s">]] .. fmt_num(warehouse_item_count) .. [[ قلم</div></div>
  <div class="kpi"><div class="l">فاکتور فروش</div><div class="v">]] .. fmt_num(sales_invoice_count) .. [[</div></div>
  <div class="kpi"><div class="l">اسناد مالی</div><div class="v">]] .. fmt_num(voucher_count) .. [[</div><div class="s">]] .. fmt_num(voucher_record_count) .. [[ ردیف</div></div>
</section>

<section class="tools">
  <div>
    <span class="badge">بازه: <b>]] .. escape_html(fiscal_range_label) .. [[</b></span>
    <span class="badge">کاربر: <b>]] .. escape_html(user_display) .. [[</b></span>
    <span class="badge">گفتگوها: <b>DATE_CREATE</b></span>
  </div>
</section>

<div class="table-wrap">
  <table>
    <tr><th>تعداد کل گفتگوها (ایجادکننده یا مخاطب)</th><td>]] .. fmt_num(dialogs_participated) .. [[</td></tr>
    <tr><th>تعداد گفتگوهای ایجادشده توسط کاربر</th><td>]] .. fmt_num(dialogs_created) .. [[</td></tr>
    <tr><th>تعداد گفتگوهای مخاطب بدون هیچ پاسخ از کاربر</th><td>]] .. fmt_num(dialogs_contact_no_reply) .. [[</td></tr>
    <tr><th>تعداد اقدامات باز در مرحله کاربر</th><td>]] .. fmt_num(open_steps_count) .. [[</td></tr>
    <tr><th>میانگین زمان تکمیل مرحله (ساعت)</th><td>]] .. avg_hours_label .. [[ <span class="muted">از ]] .. fmt_num(completed_steps_count) .. [[ مرحله</span></td></tr>
    <tr><th>رسید/حواله ثبت‌شده و مجموع اقلام</th><td>]] .. escape_html(warehouse_summary) .. [[</td></tr>
    <tr><th>تعداد فاکتورهای ثبت‌شده</th><td>]] .. fmt_num(sales_invoice_count) .. [[</td></tr>
    <tr><th>تعداد اسناد مالی ثبت‌شده</th><td>]] .. fmt_num(voucher_count) .. [[</td></tr>
    <tr><th>مجموع ردیف‌های اسناد مالی</th><td>]] .. fmt_num(voucher_record_count) .. [[</td></tr>
  </table>
</div>
]]

teamyar.write_result(render_shell(
    "آمار فعالیت کاربر",
    "خلاصه سال مالی جاری (" .. escape_html(fiscal_range_label) .. ") برای " .. escape_html(user_display),
    body_html,
    [[<span class="badge">خروجی HTML</span><button class="btn primary" type="button" onclick='window.print()'>چاپ</button>]]
))
