-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/05/26 12:00

-- botName = excel_dashboard_env_probe
-- version = v01
--
-- هدف: بات تشخیصی موقت — قبل از ساخت «excel_management_dashboard»، سه مجهول را روی Teamyar واقعی محرز می‌کند:
--   1) آیا هیچ کتابخانه/سراسری غیراستاندارد (xlsx/zip/csv/io/os/base64/...) در Sandbox این بات در دسترس است؟
--   2) وقتی فایلی به اجرای بات پیوست می‌شود، دقیقاً در getInput() با چه شکلی (کلید/فیلد) ظاهر می‌شود؟
--   3) اگر document_id از «اسناد» تیم‌یار داده شود، آیا رکورد متادیتای آن از documents_main قابل خواندن است
--      (فقط متادیتا: نام/نوع/حجم/ENCODING_KEY — نه محتوای باینری، چون هیچ ستون/APIای برای محتوای باینری
--      در schema یا مستندات این پروژه پیدا نشد).
--
-- این بات نهایی نیست و در excel_management_dashboard استفاده نمی‌شود؛ فقط برای دریافت خروجی تشخیصی است.

local function run_query(query, query_params)
    local ok_query = pcall(function()
        db.query({ query = query, params = query_params or {} })
    end)
    if not ok_query then
        return nil, "خطا در اجرای کوئری"
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
    return rows, nil
end

-- 1) سراسری‌های احتمالاً مرتبط با فایل/فشرده/اکسل را در _G بررسی کن (بدون فرض هیچ نامی، فقط گزارش وجود/نوع)
local CANDIDATE_GLOBALS = {
    "xlsx", "excel", "csv", "zip", "unzip", "miniz", "lzip", "gzip", "inflate", "deflate",
    "base64", "io", "os", "file", "openxlsx", "libxlsx", "xlsxreader", "spreadsheet"
}

local globals_report = {}
for _, name in ipairs(CANDIDATE_GLOBALS) do
    local ok_probe, value = pcall(function() return _G[name] end)
    globals_report[name] = {
        exists = (ok_probe and value ~= nil),
        lua_type = (ok_probe and value ~= nil) and type(value) or "nil"
    }
end

-- 2) توابع واقعی در دسترس روی خود شیء teamyar (برای دیدن هر تابع مرتبط با اسناد/فایل/پیوست)
local teamyar_functions = {}
local ok_ty_scan = pcall(function()
    for key, value in pairs(teamyar) do
        if type(value) == "function" then
            table.insert(teamyar_functions, tostring(key))
        end
    end
end)
table.sort(teamyar_functions)

-- 3) خروجی خام getInput() — اگر فایلی هنگام اجرای بات پیوست شود، همینجا شکل واقعی‌اش دیده می‌شود
local input = {}
local ok_input = pcall(function()
    input = teamyar.get_input() or {}
end)

local raw_input_keys = {}
if ok_input and type(input) == "table" then
    for key, _ in pairs(input) do
        table.insert(raw_input_keys, tostring(key))
    end
end
table.sort(raw_input_keys)

local raw_input_json = "{}"
pcall(function() raw_input_json = json.encode(input) end)
-- برای جلوگیری از پاسخ حجیم در صورت پیوست شدن base64 یک فایل واقعی
if #raw_input_json > 4000 then
    raw_input_json = string.sub(raw_input_json, 1, 4000) .. "...(truncated, len=" .. tostring(#raw_input_json) .. ")"
end

-- 4) اگر document_id داده شده، فقط متادیتای documents_main (بدون محتوای فایل) خوانده می‌شود
local document_probe = { requested = false }
local raw_document_id = input["document_id"]
local document_id = tonumber(raw_document_id)

if raw_document_id ~= nil and (document_id == nil or document_id <= 0) then
    document_probe = {
        requested = true,
        ok = false,
        error = "document_id نامعتبر است"
    }
elseif document_id ~= nil and document_id > 0 then
    document_probe.requested = true
    local rows, err = run_query([[
        SELECT ID, NAME, MIME_TYPE, SIZE, ENCODING_KEY, FILE_TYPE, TYPE, VERSION, DATE_CREATE
        FROM documents_main
        WHERE ID = ?
        LIMIT 1
    ]], { document_id })

    if err ~= nil then
        document_probe.ok = false
        document_probe.error = err
    elseif rows == nil or #rows == 0 then
        document_probe.ok = false
        document_probe.error = "سندی با این document_id یافت نشد"
    else
        local r = rows[1]
        document_probe.ok = true
        document_probe.data = {
            id = r[1],
            name = r[2],
            mime_type = r[3],
            size = r[4],
            encoding_key = r[5],
            file_type = r[6],
            type = r[7],
            version = r[8],
            date_create = r[9]
        }
    end
end

teamyar.write_result(json.encode({
    ok = true,
    note = "این بات فقط تشخیصی است — برای ساخت excel_management_dashboard استفاده نمی‌شود",
    globals_probe = globals_report,
    teamyar_function_count = #teamyar_functions,
    teamyar_functions = teamyar_functions,
    raw_input_keys = raw_input_keys,
    raw_input_json = raw_input_json,
    document_probe = document_probe
}))
