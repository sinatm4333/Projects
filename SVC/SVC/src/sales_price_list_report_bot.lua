-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/05/20 16:30

-- فهرست لیست‌های قیمت فروش (sales_price_setting) + کالاها و قیمت هر لیست
-- مدل داده (تأییدشده روی داده زنده):
--   sales_price_setting (لیست قیمت)
--     → sales_setting ss  ON ss.SETTING_ID = sps.ID   (ss.QUANTITY_INT = فی/قیمت)
--     → sales_discount_ext e  ON e.SETTING_ID = ss.ID AND e.SETTING_TYPE = 3  (e.REFERE_ID = کالا)
--     → wh_product p  ON p.ID = e.REFERE_ID
-- حجم بالا (۹۲هزار قلم) → کالاها با drill-down زنده (fetch) گرفته می‌شوند، نه embed.
--
-- ورودی:
--   org_id, title            → فیلتر فهرست لیست‌ها (HTML)
--   list_id (+format=json)    → کالاها و قیمت یک لیست (drill-down JSON)
--   product (+format=json)    → شناسه لیست‌هایی که کالای منطبق دارند (جستجوی کالا)
--   format=json               → خروجی خام
-- خروجی: HTML (پیش‌فرض) یا JSON

local input = teamyar.get_input() or {}

local table_unpack = table.unpack or unpack
local HTML_DQ = string.char(34)
local PRICE_SETTING_TYPE = 3

local function normalize_entity_id(value)
    local n = tonumber(value)
    if n ~= nil and n > 0 then return n end
    return nil
end

local function normalize_text(value)
    if value == nil then return nil end
    local text = tostring(value):match("^%s*(.-)%s*$")
    if text == "" then return nil end
    return text
end

local function wants_json(source)
    local fmt = source["format"] or source["output"] or source["output_format"]
        or source["result_format"] or source["response_format"]
    if fmt ~= nil and tostring(fmt):lower() == "json" then return true end
    return false
end

local org_id = normalize_entity_id(input["org_id"] or input["orgId"])
local title_filter = normalize_text(input["title"] or input["search"] or input["q"])
local list_id = normalize_entity_id(input["list_id"] or input["setting_id"] or input["listId"])
local product_search = normalize_text(input["product"] or input["product_search"])
local as_json = wants_json(input)

local function fmt_jalali_datetime(col)
    return [[
CASE
    WHEN ]] .. col .. [[ IS NULL OR ]] .. col .. [[ = 0 THEN NULL
    ELSE CONCAT(
        REPORT_FN_JDATE(]] .. col .. [[, '-'),
        ' ',
        DATE_FORMAT(FROM_UNIXTIME(]] .. col .. [[ / 10000000 - 11644473600), '%H:%i:%s')
    )
END]]
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
    return s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
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

local function yes_no_flag(value)
    return tonumber(value) == 1 and "بله" or "خیر"
end

-- ==================== DRILL-DOWN: کالاهای یک لیست (JSON) ====================
if list_id ~= nil then
    local items_rows, err = fetch_rows([[
        SELECT
            COALESCE(NULLIF(p.FULL_CODE, ''), p.CODE, '') AS code,
            COALESCE(p.NAME, '')  AS name,
            e.ATTRIBUTE_ID        AS attribute_id,
            ss.QUANTITY_INT       AS price,
            ss.QUANTITY_BUY_FLOOR AS qty_from,
            ss.QUANTITY_BUY       AS qty_to
        FROM sales_setting ss
        JOIN sales_discount_ext e
            ON e.SETTING_ID = ss.ID AND e.SETTING_TYPE = ?
        JOIN wh_product p
            ON p.ID = e.REFERE_ID
        WHERE ss.SETTING_ID = ?
        ORDER BY ss.ID ASC
    ]], { PRICE_SETTING_TYPE, list_id })

    if items_rows == nil then
        teamyar.write_result(json.encode({ ok = false, error = "خطا در دریافت کالاهای لیست", detail = tostring(err) }))
        return
    end

    local items = {}
    for _, r in ipairs(items_rows) do
        table.insert(items, {
            code = r[1],
            name = r[2],
            attribute_id = tonumber(r[3]) or 0,
            price = tonumber(r[4]) or 0,
            qty_from = tonumber(r[5]) or 0,
            qty_to = tonumber(r[6]) or 0
        })
    end

    teamyar.write_result(json.encode({ ok = true, list_id = list_id, item_count = #items, items = items }))
    return
end

-- ==================== جستجوی کالا: شناسه لیست‌های منطبق (JSON) ====================
if product_search ~= nil then
    local like = "%" .. product_search .. "%"
    -- توجه: e.SETTING_TYPE در ON مصرف می‌شود؛ اینجا تکرار نکن تا تعداد ? با پارامترها بخواند
    local where = { "(p.NAME LIKE ? OR p.FULL_CODE LIKE ? OR p.CODE LIKE ?)" }
    local params = { PRICE_SETTING_TYPE, like, like, like }
    if org_id ~= nil then
        table.insert(where, "sps.ORG_ID = ?")
        table.insert(params, org_id)
    end
    local rows, err = fetch_rows([[
        SELECT DISTINCT ss.SETTING_ID
        FROM sales_setting ss
        JOIN sales_discount_ext e
            ON e.SETTING_ID = ss.ID AND e.SETTING_TYPE = ?
        JOIN wh_product p
            ON p.ID = e.REFERE_ID
        JOIN sales_price_setting sps
            ON sps.ID = ss.SETTING_ID
        WHERE ]] .. table.concat(where, " AND ") .. [[
        LIMIT 500
    ]], params)

    if rows == nil then
        teamyar.write_result(json.encode({ ok = false, error = "خطا در جستجوی کالا", detail = tostring(err) }))
        return
    end

    local ids = {}
    for _, r in ipairs(rows) do table.insert(ids, tonumber(r[1]) or r[1]) end
    teamyar.write_result(json.encode({ ok = true, matched_list_ids = ids }))
    return
end

-- ==================== نمای کلی: فهرست لیست‌های قیمت ====================
local function fail(message, detail)
    if as_json then
        teamyar.write_result(json.encode({ ok = false, error = message, detail = detail }))
        return
    end
    local extra = ""
    if detail ~= nil and tostring(detail) ~= "" then
        extra = "<p class='muted'>" .. escape_html(detail) .. "</p>"
    end
    teamyar.write_result(safe_format([[
<!DOCTYPE html>
<html dir="rtl" lang="fa">
<head><meta charset="UTF-8"><title>خطا</title></head>
<body style="font-family:tahoma;padding:2rem;text-align:center;font-size:14px;">
<h2 style="color:#b42318;font-size:15px;">%s</h2>
%s
</body></html>
]], escape_html(message), extra))
end

local where_parts = {}
local params = {}
if org_id ~= nil then
    table.insert(where_parts, "sps.ORG_ID = ?")
    table.insert(params, org_id)
end
if title_filter ~= nil then
    table.insert(where_parts, "sps.title LIKE ?")
    table.insert(params, "%" .. title_filter .. "%")
end
local where_sql = ""
if #where_parts > 0 then
    where_sql = "WHERE " .. table.concat(where_parts, " AND ")
end

local query = [[
SELECT
    sps.ID,
    sps.title,
    sps.ORG_ID,
    COALESCE(oi.NAME, '') AS org_name,
    sps.auto_update_fee,
    sps.REPEAT_FIELD,
    ]] .. fmt_jalali_datetime("sps.DATE_CREATE") .. [[ AS date_create,
    ]] .. fmt_jalali_datetime("sps.DATE_MODIFY") .. [[ AS date_modify,
    COALESCE(cc.center_count, 0) AS center_count,
    COALESCE(cl.client_count, 0) AS client_count,
    COALESCE(it.item_count, 0)   AS item_count
FROM sales_price_setting sps
LEFT JOIN org_info oi ON oi.ID = sps.ORG_ID
LEFT JOIN (
    SELECT SETTING_ID, COUNT(*) AS center_count
    FROM sales_price_center GROUP BY SETTING_ID
) cc ON cc.SETTING_ID = sps.ID
LEFT JOIN (
    SELECT SETTING_ID, COUNT(*) AS client_count
    FROM sales_price_client GROUP BY SETTING_ID
) cl ON cl.SETTING_ID = sps.ID
LEFT JOIN (
    SELECT ss.SETTING_ID AS pl_id, COUNT(*) AS item_count
    FROM sales_setting ss
    JOIN sales_discount_ext e ON e.SETTING_ID = ss.ID AND e.SETTING_TYPE = ]] .. PRICE_SETTING_TYPE .. [[
    GROUP BY ss.SETTING_ID
) it ON it.pl_id = sps.ID
]] .. where_sql .. [[
ORDER BY sps.ID DESC
]]

local rows, query_err = fetch_rows(query, params)
if rows == nil then
    fail("خطا در دریافت فهرست لیست‌های قیمت", tostring(query_err))
    return
end

local price_lists = {}
for _, row in ipairs(rows) do
    table.insert(price_lists, {
        id = tonumber(row[1]) or row[1],
        title = row[2],
        org_id = tonumber(row[3]) or row[3],
        org_name = row[4],
        auto_update_fee = tonumber(row[5]) == 1,
        auto_update_fee_label = yes_no_flag(row[5]),
        repeat_field = tonumber(row[6]) or 0,
        date_create = row[7],
        date_modify = row[8],
        center_count = tonumber(row[9]) or 0,
        client_count = tonumber(row[10]) or 0,
        item_count = tonumber(row[11]) or 0
    })
end

if as_json then
    teamyar.write_result(json.encode({
        ok = true,
        filters = { org_id = org_id, title = title_filter },
        price_list_count = #price_lists,
        price_lists = price_lists
    }))
    return
end

local generated_at = fetch_generated_at()
local org_label = org_id ~= nil and tostring(org_id) or "همه"
local title_label = title_filter ~= nil and title_filter or "—"

local total_centers, total_clients, total_items, auto_update_count = 0, 0, 0, 0
for _, item in ipairs(price_lists) do
    total_centers = total_centers + (item.center_count or 0)
    total_clients = total_clients + (item.client_count or 0)
    total_items = total_items + (item.item_count or 0)
    if item.auto_update_fee then auto_update_count = auto_update_count + 1 end
end

local table_rows_html = {}
if #price_lists == 0 then
    table.insert(table_rows_html, [[<tr><td colspan="11" class="empty-row">لیست قیمتی یافت نشد.</td></tr>]])
else
    for index, item in ipairs(price_lists) do
        table.insert(table_rows_html, safe_format(
            [[<tr class="pl-row" data-id="%s" data-title="%s" onclick="openItems('%s')">
                <td>%s</td>
                <td>%s</td>
                <td class="name-cell">%s</td>
                <td>%s</td>
                <td class="name-cell">%s</td>
                <td>%s</td>
                <td>%s</td>
                <td>%s</td>
                <td>%s</td>
                <td class="item-count">%s</td>
                <td class="actions-cell">
                    <button type="button" class="icon-btn" title="خروجی اکسل کالاهای این لیست" onclick="event.stopPropagation(); exportListItems('%s')">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
                            <rect x="3" y="3" width="18" height="18" rx="2" fill="#1D6F42"></rect>
                            <path d="M8.5 8L15.5 16M15.5 8L8.5 16" stroke="#fff" stroke-width="1.8" stroke-linecap="round"></path>
                        </svg>
                    </button>
                </td>
            </tr>]],
            escape_html(item.id), escape_html(item.title), escape_html(item.id),
            fmt_num(index), escape_html(item.id), escape_html(item.title),
            escape_html(item.org_id), escape_html(item.org_name),
            escape_html(item.date_create or "—"), escape_html(item.date_modify or "—"),
            fmt_num(item.center_count), fmt_num(item.client_count), fmt_num(item.item_count),
            escape_html(item.id)
        ))
    end
end

local ok_html, html_or_err = pcall(function()
    return safe_format([[
<!DOCTYPE html>
<html dir="rtl" lang="fa">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>فهرست لیست‌های قیمت</title>
<style>
@font-face {
    font-family: "YekanBakhReport";
    src: local("Yekan Bakh"), local("YekanBakh");
    font-weight: 400; font-style: normal; font-display: swap;
}
* { font-family: "YekanBakhReport", "Yekan Bakh", "IRANSans", "Tahoma", "Arial", sans-serif !important; box-sizing: border-box; }
body { margin: 0; padding: 12px; background: #f5f7fb; color: #23262d; font-size: 14px; }
#reportRoot:fullscreen { background: #f5f7fb; padding: 12px; overflow: auto; }
.toolbar { display: flex; justify-content: flex-end; align-items: center; gap: 8px; flex-wrap: wrap; margin-bottom: 10px; }
.search-box { flex: 1 1 280px; min-width: 200px; max-width: 460px; margin-left: auto; padding: 8px 12px; font-size: 14px; border: 2px solid #005bb5; border-radius: 8px; outline: none; }
.search-box:focus { border-color: #0073e6; box-shadow: 0 0 0 2px rgba(0,115,230,0.15); }
.btn-fullscreen { background: #0073e6; color: #fff; border: 2px solid #005bb5; border-radius: 8px; padding: 8px 16px; font-size: 14px; font-weight: bold; cursor: pointer; }
.btn-fullscreen:hover { background: #005bb5; }
.icon-btn { background: transparent; border: none; padding: 2px; cursor: pointer; line-height: 0; border-radius: 6px; }
.icon-btn:hover { background: #d7f0df; }
.help-overlay { display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.5); z-index: 100; align-items: center; justify-content: center; }
.help-overlay.open { display: flex; }
.help-modal { background: #fff; border-radius: 10px; max-width: 820px; width: 92%%; max-height: 84vh; overflow-y: auto; box-shadow: 0 8px 24px rgba(0,0,0,0.3); }
.help-modal-header { display: flex; justify-content: space-between; align-items: center; background: #0073e6; color: #fff; padding: 12px 16px; border-radius: 10px 10px 0 0; font-size: 15px; font-weight: bold; position: sticky; top: 0; }
.help-close { background: transparent; border: none; color: #fff; font-size: 16px; cursor: pointer; }
.help-modal-body { padding: 16px; text-align: right; font-size: 14px; }
.help-modal-body p { margin: 10px 0; line-height: 1.8; }
.help-modal-body ul { margin: 6px 0 14px; padding-right: 20px; }
.help-modal-body li { margin: 6px 0; line-height: 1.7; }
.help-modal-body code { background: #f0f2f5; padding: 2px 6px; border-radius: 4px; }
.items-toolbar { display: flex; justify-content: flex-end; gap: 8px; padding: 10px 16px 0; }
.items-table-wrap { padding: 12px 16px 16px; min-height: 80px; }
.items-table { width: 100%%; border-collapse: collapse; text-align: center; }
.items-table thead th { position: sticky; top: 0; background: #0073e6; color: #fff; border: 1px dashed #000; padding: 8px; font-size: 15px; font-weight: bold; white-space: nowrap; }
.items-table tbody td { border: 1px dashed #000; padding: 8px; font-size: 14px; white-space: nowrap; }
.items-table tbody td.name-cell { text-align: right; font-weight: bold; }
.items-table tbody tr:nth-child(even) { background: #eeeeee; }
.items-empty { padding: 20px; text-align: center; color: #666; font-size: 14px; }
.items-loading { padding: 24px; text-align: center; color: #0073e6; font-size: 14px; }
.report-header { background-color: #D2E0FB; text-align: center; border: 1px dotted #000; border-radius: 10px; padding: 12px 10px 16px; margin-bottom: 12px; }
.report-header p { margin: 4px 0; font-size: 14px; }
.report-header p:first-child { font-size: 15px; font-weight: bold; }
.meta-line { font-size: 14px; color: #333; margin-top: 8px; }
.summary-table { width: 100%%; border-collapse: collapse; margin-bottom: 12px; border: 2px solid #000; border-radius: 8px; overflow: hidden; }
.summary-table td { border: 1px dashed #000; padding: 10px 8px; text-align: center; font-size: 14px; }
.summary-table .summary-head { background: #4472C4; color: #fff; font-size: 15px; font-weight: bold; }
.summary-table .summary-value { background: #5B9BD5; color: #fff; font-size: 14px; font-weight: bold; }
.hint-line { text-align: center; color: #0073e6; font-size: 14px; margin: 6px 0 10px; }
.table-wrap { overflow: auto; max-height: 70vh; border: 2px solid #000; border-radius: 8px; background: #fff; }
table.main-table { width: auto; table-layout: auto; border-collapse: collapse; text-align: center; }
table.main-table thead th { position: sticky; top: 0; z-index: 2; background-color: #0073e6; color: #fff; border: 1px dashed #000; padding: 10px 8px; font-size: 15px; font-weight: bold; white-space: nowrap; width: 1%%; cursor: pointer; user-select: none; }
table.main-table thead th.sort-asc::after { content: ' ▲'; }
table.main-table thead th.sort-desc::after { content: ' ▼'; }
table.main-table tbody td { border: 1px dashed #000; padding: 8px; font-size: 14px; vertical-align: middle; white-space: nowrap; width: 1%%; }
table.main-table tbody tr:nth-child(even) { background-color: #eeeeee; }
tr.pl-row { cursor: pointer; }
tr.pl-row:hover { background-color: #d7e9ff !important; }
.item-count { font-weight: bold; }
.actions-cell { cursor: default; }
.name-cell { text-align: right; font-weight: bold; }
.empty-row { padding: 24px !important; color: #666; }
.footer { text-align: center; color: #666; font-size: 14px; margin-top: 10px; }
.muted { color: #667085; }
</style>
</head>
<body>
<div id="reportRoot">
    <div class="toolbar">
        <input type="text" id="searchBox" class="search-box" placeholder="جستجوی نام لیست قیمت یا نام/کد کالا..." oninput="onSearchInput()">
        <button type="button" class="btn-fullscreen" id="btnFullscreen" onclick="toggleFullScreen()">تمام صفحه</button>
        <button type="button" class="btn-fullscreen" onclick="exportTableToExcel()">خروجی Excel</button>
        <button type="button" class="btn-fullscreen" onclick="openHelpModal()">راهنما</button>
    </div>

    <div id="helpModalOverlay" class="help-overlay" onclick="if(event.target===this){closeHelpModal();}">
        <div class="help-modal">
            <div class="help-modal-header">
                <strong>راهنمای فهرست لیست‌های قیمت</strong>
                <button type="button" class="help-close" onclick="closeHelpModal()">✕</button>
            </div>
            <div class="help-modal-body">
                <p><strong>این گزارش چیست؟</strong> فهرست تمام «لیست قیمت»‌های فروش (جدول <code>sales_price_setting</code>) به‌همراه تعداد کالاهای قیمت‌گذاری‌شده در هر لیست.</p>
                <p><strong>ستون‌ها:</strong></p>
                <ul>
                    <li><b>شناسه / عنوان</b> — کد و نام لیست قیمت</li>
                    <li><b>سازمان</b> — شناسه و نام سازمان</li>
                    <li><b>تاریخ ایجاد / ویرایش</b> — تاریخ شمسی</li>
                    <li><b>مراکز فروش / مشتریان</b> — تعداد مراکز و مشتریان متصل</li>
                    <li><b>تعداد کالا</b> — تعداد کالاهای قیمت‌گذاری‌شده در لیست</li>
                    <li><b>خروجی</b> — دکمه سبز اکسل برای دریافت کالاها و قیمت‌های همان لیست</li>
                </ul>
                <p><strong>تعامل‌ها:</strong></p>
                <ul>
                    <li><b>کلیک روی هر ردیف</b> → پنجرهٔ کالاهای متصل و قیمت هرکدام (زنده از سرور بارگذاری می‌شود).</li>
                    <li><b>کادر جستجو</b> → هم‌زمان در <b>نام لیست قیمت</b> (فوری) و <b>نام/کد کالاهای هر لیست</b> (با جستجوی سرور) می‌گردد.</li>
                    <li><b>کلیک روی هدر ستون‌ها</b> → مرتب‌سازی صعودی/نزولی.</li>
                    <li><b>آیکن سبز اکسل</b> در ستون آخر → خروجی CSV کالاهای همان لیست.</li>
                </ul>
                <p><strong>ارتباط داده:</strong> قیمت‌ها از <code>sales_setting</code> (فی = <code>QUANTITY_INT</code>) و کالاها از <code>sales_discount_ext</code> (<code>REFERE_ID</code>) با <code>SETTING_TYPE=3</code> خوانده می‌شوند.</p>
            </div>
        </div>
    </div>

    <div id="itemsModalOverlay" class="help-overlay" onclick="if(event.target===this){closeItemsModal();}">
        <div class="help-modal">
            <div class="help-modal-header">
                <strong id="itemsModalTitle">کالاهای لیست قیمت</strong>
                <button type="button" class="help-close" onclick="closeItemsModal()">✕</button>
            </div>
            <div class="items-toolbar">
                <button type="button" class="btn-fullscreen" id="itemsExportBtn" style="display:none" onclick="exportCurrentItems()">خروجی Excel این لیست</button>
            </div>
            <div class="items-table-wrap" id="itemsModalBody"></div>
        </div>
    </div>

    <div class="report-header">
        <p><strong>فهرست لیست‌های قیمت فروش</strong></p>
        <p>روی هر لیست کلیک کنید تا کالاها و قیمت‌های آن را ببینید</p>
        <div class="meta-line">org_id: %s | جستجوی عنوان: %s | زمان تولید: %s</div>
    </div>

    <table class="summary-table">
        <tr class="summary-head">
            <td>تعداد لیست قیمت</td>
            <td>جمع کالاهای قیمت‌گذاری‌شده</td>
            <td>جمع اتصال مراکز</td>
            <td>جمع اتصال مشتریان</td>
            <td>به‌روزرسانی خودکار کارمزد</td>
        </tr>
        <tr>
            <td class="summary-value">%s</td>
            <td class="summary-value">%s</td>
            <td class="summary-value">%s</td>
            <td class="summary-value">%s</td>
            <td class="summary-value">%s</td>
        </tr>
    </table>

    <div class="hint-line" id="searchHint">💡 برای دیدن کالاها و قیمت هر لیست، روی ردیف آن کلیک کنید.</div>

    <div class="table-wrap">
        <table class="main-table">
            <thead>
                <tr>
                    <th>ردیف</th><th>شناسه</th><th>عنوان</th><th>org_id</th><th>سازمان</th>
                    <th>تاریخ ایجاد</th><th>تاریخ ویرایش</th><th>مراکز فروش</th><th>مشتریان</th>
                    <th>تعداد کالا</th><th>خروجی</th>
                </tr>
            </thead>
            <tbody id="resultTbody">
                %s
            </tbody>
        </table>
    </div>

    <div class="footer">Teamyar Sales Price List Report</div>
</div>

<script>
var RUN_URL = (location.pathname.indexOf('/bot/run/') === 0)
    ? location.pathname
    : '/bot/run/258/sales_price_list_report';
var itemsCache = {};
var currentItemsId = null;
var searchTimer = null;
var searchToken = 0;

function faNorm(t) {
    return (t || '').toString().toLowerCase().replace(/ي/g, 'ی').replace(/ك/g, 'ک').replace(/\s+/g, ' ').trim();
}
function fmtMoney(n) {
    var v = Math.round(Number(n) || 0);
    return v.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}
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

function fetchList(id, cb) {
    if (itemsCache[id]) { cb(itemsCache[id]); return; }
    var fd = new FormData();
    fd.append('list_id', id);
    fd.append('format', 'json');
    fetch(RUN_URL + '?ver=0', { method: 'POST', credentials: 'same-origin', headers: { 'X-Requested-With': 'XMLHttpRequest' }, body: fd })
        .then(function (r) { return r.json(); })
        .then(function (data) { itemsCache[id] = (data && data.items) ? data.items : []; cb(itemsCache[id]); })
        .catch(function () { cb(null); });
}

function exportTableToExcel() {
    var table = document.querySelector('.table-wrap table');
    if (!table) return;
    var lines = [];
    var hc = table.querySelectorAll('thead th');
    var hl = [];
    for (var h = 0; h < hc.length - 1; h++) hl.push(csvEscapeCell(hc[h].innerText));
    lines.push(hl.join(','));
    var rows = table.querySelectorAll('tbody tr');
    for (var i = 0; i < rows.length; i++) {
        if (rows[i].querySelector('td.empty-row') || rows[i].style.display === 'none') continue;
        var cells = rows[i].querySelectorAll('td');
        var line = [];
        for (var c = 0; c < cells.length - 1; c++) line.push(csvEscapeCell(cells[c].innerText));
        lines.push(line.join(','));
    }
    downloadCsv(lines, 'فهرست-لیست-قیمت.csv');
}

function buildItemsLines(items) {
    var lines = [['ردیف', 'کد کالا', 'نام کالا', 'قیمت'].map(csvEscapeCell).join(',')];
    for (var i = 0; i < items.length; i++) {
        lines.push([csvEscapeCell(i + 1), csvEscapeCell(items[i].code), csvEscapeCell(items[i].name), csvEscapeCell(fmtMoney(items[i].price))].join(','));
    }
    return lines;
}
function listTitle(id) {
    var row = document.querySelector('tr.pl-row[data-id="' + id + '"]');
    return row ? row.getAttribute('data-title') : id;
}
function exportListItems(id) {
    id = String(id);
    fetchList(id, function (items) {
        if (!items) { alert('خطا در دریافت کالاهای لیست.'); return; }
        if (items.length === 0) { alert('برای این لیست قیمت هیچ کالایی ثبت نشده است.'); return; }
        downloadCsv(buildItemsLines(items), 'قیمت-' + listTitle(id) + '.csv');
    });
}
function exportCurrentItems() { if (currentItemsId) exportListItems(currentItemsId); }

function renderItems(items) {
    var body = document.getElementById('itemsModalBody');
    var btn = document.getElementById('itemsExportBtn');
    if (!items) { body.innerHTML = '<div class="items-empty">خطا در دریافت کالاها.</div>'; btn.style.display = 'none'; return; }
    if (items.length === 0) { body.innerHTML = '<div class="items-empty">برای این لیست قیمت هیچ کالایی ثبت نشده است.</div>'; btn.style.display = 'none'; return; }
    btn.style.display = '';
    var html = '<table class="items-table"><thead><tr><th>ردیف</th><th>کد کالا</th><th>نام کالا</th><th>قیمت (ریال)</th></tr></thead><tbody>';
    for (var i = 0; i < items.length; i++) {
        var tr = document.createElement('tr');
        var a = document.createElement('td'); a.textContent = i + 1;
        var b = document.createElement('td'); b.textContent = items[i].code || '—';
        var c = document.createElement('td'); c.className = 'name-cell'; c.textContent = items[i].name || '—';
        var d = document.createElement('td'); d.textContent = fmtMoney(items[i].price);
        tr.appendChild(a); tr.appendChild(b); tr.appendChild(c); tr.appendChild(d);
        html += tr.outerHTML;
    }
    html += '</tbody></table>';
    body.innerHTML = html;
}

function openItems(id) {
    id = String(id);
    currentItemsId = id;
    document.getElementById('itemsModalTitle').textContent = 'کالاهای لیست قیمت: ' + listTitle(id) + '  (شناسه ' + id + ')';
    document.getElementById('itemsExportBtn').style.display = 'none';
    document.getElementById('itemsModalBody').innerHTML = '<div class="items-loading">در حال بارگذاری کالاها...</div>';
    document.getElementById('itemsModalOverlay').classList.add('open');
    fetchList(id, function (items) { if (currentItemsId === id) renderItems(items); });
}
function closeItemsModal() { document.getElementById('itemsModalOverlay').classList.remove('open'); currentItemsId = null; }

function applyTitleFilter(term, matchedSet) {
    var rows = document.querySelectorAll('#resultTbody tr.pl-row');
    var shown = 0;
    for (var i = 0; i < rows.length; i++) {
        var row = rows[i];
        var titleHit = term === '' || faNorm(row.getAttribute('data-title')).indexOf(term) !== -1;
        var prodHit = matchedSet && matchedSet[row.getAttribute('data-id')];
        var visible = titleHit || prodHit;
        row.style.display = visible ? '' : 'none';
        if (visible) shown++;
    }
    return shown;
}

function onSearchInput() {
    var term = faNorm(document.getElementById('searchBox').value);
    var hint = document.getElementById('searchHint');
    applyTitleFilter(term, null);
    if (searchTimer) clearTimeout(searchTimer);
    if (term === '') { hint.textContent = '💡 برای دیدن کالاها و قیمت هر لیست، روی ردیف آن کلیک کنید.'; return; }
    hint.textContent = 'در حال جستجوی کالا در لیست‌ها...';
    var myToken = ++searchToken;
    searchTimer = setTimeout(function () {
        var fd = new FormData();
        fd.append('product', document.getElementById('searchBox').value);
        fd.append('format', 'json');
        fetch(RUN_URL + '?ver=0', { method: 'POST', credentials: 'same-origin', headers: { 'X-Requested-With': 'XMLHttpRequest' }, body: fd })
            .then(function (r) { return r.json(); })
            .then(function (data) {
                if (myToken !== searchToken) return;
                var set = {};
                if (data && data.matched_list_ids) for (var i = 0; i < data.matched_list_ids.length; i++) set[String(data.matched_list_ids[i])] = true;
                var shown = applyTitleFilter(term, set);
                hint.textContent = 'نتایج جستجو (نام لیست + کالا): ' + shown + ' لیست';
            })
            .catch(function () { if (myToken === searchToken) hint.textContent = 'خطا در جستجوی کالا (فقط نام لیست فیلتر شد).'; });
    }, 400);
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
            if (colIndex === headers.length - 1) return;
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
document.addEventListener('keydown', function (e) { if (e.key === 'Escape') { closeHelpModal(); closeItemsModal(); } });
initSortableTables();
</script>
</body>
</html>
]],
    escape_html(org_label), escape_html(title_label), escape_html(generated_at),
    fmt_num(#price_lists), fmt_num(total_items), fmt_num(total_centers),
    fmt_num(total_clients), fmt_num(auto_update_count),
    table.concat(table_rows_html, "\n")
    )
end)

if not ok_html then
    fail("خطا در ساخت گزارش HTML", tostring(html_or_err))
    return
end

teamyar.write_result(html_or_err)
