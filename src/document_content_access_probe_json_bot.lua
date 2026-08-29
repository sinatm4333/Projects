-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/06/07 22:42

-- botName = document_content_access_probe
-- version = v01
--
-- هدف: بات تشخیصی موقت — قبل از ساخت داشبورد چندفایلی CSV (شناسه سند از ماژول «اسناد»)، مشخص می‌کند
-- محتوای واقعی یک سند (نه فقط متادیتای آن) از کجا و چطور در دسترس Lua این پلتفرم است:
--   1) متادیتای کامل ردیف documents_main برای document_id ورودی.
--   2) محتوای جدول documents_storage (فقط ۲ ردیف کل دیتابیس — پیکربندی بک‌اند ذخیره‌سازی: LOCATION/STORAGE_TYPE).
--   3) زنجیره PARENT_ID/ROOT_FOLDER_ID سند تا رسیدن به یک پوشه‌ریشه که با documents_storage.PARENT_ID تطبیق دارد
--      (برای فهمیدن این‌که کدام LOCATION مسیر پایه فایل موردنظر است).
--   4) آیا سراسری `io`/`os` در Sandbox این بات در دسترس است؛ اگر بله، چند الگوی مسیر محتمل
--      (LOCATION + ENCODING_KEY با ترکیب‌های جداکننده مختلف) با io.open امتحان می‌شود و در صورت باز شدن،
--      فقط طول فایل + ۲۰۰ بایت اول (برای تشخیص متن/CSV بودن) گزارش می‌شود — نه کل محتوا.
--   5) فهرست همه توابع تابع‌گونهٔ روی شیء teamyar (شاید تابعی مثل get_document/read_file/download وجود داشته باشد
--      که در مستندات فعلی پروژه ثبت نشده).
--
-- این بات نهایی نیست و در داشبورد CSV چندفایلی استفاده نمی‌شود؛ فقط برای دریافت خروجی تشخیصی از سرور واقعی
-- Teamyar است (این محیط توسعه به erp.bimehland.com دسترسی شبکه ندارد، پس این بررسی باید روی خود سرور اجرا شود).

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

local input = {}
pcall(function() input = teamyar.get_input() or {} end)

local raw_document_id = input["document_id"]
local document_id = tonumber(raw_document_id)

local result = {
    ok = true,
    note = "این بات فقط تشخیصی است — برای داشبورد نهایی CSV چندفایلی استفاده نمی‌شود",
    document_id_input = raw_document_id,
}

-- 1) متادیتای سند
local doc_row = nil
if document_id == nil or document_id <= 0 then
    result.document = { requested = false, error = "document_id نامعتبر یا ارسال نشده است" }
else
    local rows, err = fetch_rows([[
        SELECT ID, NAME, MIME_TYPE, SIZE, ENCODING_KEY, ENCODING_STATUS, FILE_TYPE, FLAGS,
               MODULE_ID, PARENT_ID, RECORD_ID, RECORD_TYPE, ROOT_FOLDER_ID, TYPE, VERSION,
               CHECKSUM, AUTHOR_ID, DATE_CREATE
        FROM documents_main
        WHERE ID = ?
        LIMIT 1
    ]], { document_id })

    if err ~= nil then
        result.document = { requested = true, ok = false, error = tostring(err) }
    elseif rows == nil or #rows == 0 then
        result.document = { requested = true, ok = false, error = "سندی با این document_id یافت نشد" }
    else
        local r = rows[1]
        doc_row = {
            id = r[1], name = r[2], mime_type = r[3], size = r[4], encoding_key = r[5],
            encoding_status = r[6], file_type = r[7], flags = r[8], module_id = r[9],
            parent_id = r[10], record_id = r[11], record_type = r[12], root_folder_id = r[13],
            type = r[14], version = r[15], checksum = r[16], author_id = r[17], date_create = r[18]
        }
        result.document = { requested = true, ok = true, data = doc_row }
    end
end

-- 2) پیکربندی ذخیره‌سازی (فقط ۲ ردیف کل جدول — بدون فیلتر)
local storage_rows, storage_err = fetch_rows([[
    SELECT ID, PARENT_ID, STORAGE_TYPE, USER_CREATE, DATE_CREATE, LOCATION
    FROM documents_storage
    ORDER BY ID
]])
if storage_err ~= nil then
    result.storage = { ok = false, error = tostring(storage_err) }
else
    local storages = {}
    for _, r in ipairs(storage_rows or {}) do
        table.insert(storages, {
            id = r[1], parent_id = r[2], storage_type = r[3],
            user_create = r[4], date_create = r[5], location = r[6]
        })
    end
    result.storage = { ok = true, rows = storages }
end

-- 3) زنجیرهٔ PARENT_ID سند تا رسیدن به یکی از ریشه‌های documents_storage (حداکثر ۵۰ گام، ضدحلقهٔ بی‌نهایت)
local folder_chain = {}
if doc_row ~= nil then
    local storage_parent_ids = {}
    for _, s in ipairs(result.storage.rows or {}) do
        storage_parent_ids[tostring(s.parent_id)] = s
    end

    local current_id = doc_row.root_folder_id
    if current_id == nil or current_id == 0 then current_id = doc_row.parent_id end

    local visited = {}
    local matched_storage = nil
    local steps = 0
    while current_id ~= nil and current_id ~= 0 and steps < 50 do
        steps = steps + 1
        if visited[tostring(current_id)] then
            table.insert(folder_chain, { id = current_id, note = "حلقه تشخیص داده شد — توقف" })
            break
        end
        visited[tostring(current_id)] = true

        if storage_parent_ids[tostring(current_id)] ~= nil then
            matched_storage = storage_parent_ids[tostring(current_id)]
            table.insert(folder_chain, { id = current_id, matched_storage = true })
            break
        end

        local frows, ferr = fetch_rows(
            "SELECT ID, NAME, PARENT_ID, TYPE FROM documents_main WHERE ID = ? LIMIT 1",
            { current_id }
        )
        if ferr ~= nil or frows == nil or #frows == 0 then
            table.insert(folder_chain, { id = current_id, error = "یافت نشد یا خطا در خواندن والد" })
            break
        end
        local fr = frows[1]
        table.insert(folder_chain, { id = fr[1], name = fr[2], parent_id = fr[3], type = fr[4] })
        current_id = fr[3]
    end

    result.folder_chain = folder_chain
    result.matched_storage = matched_storage
end

-- 4) بررسی سراسری‌های io/os و تلاش برای باز کردن فایل با چند الگوی مسیر محتمل
local io_probe = { io_exists = false, os_exists = false }
local ok_io_check, io_val = pcall(function() return _G["io"] end)
io_probe.io_exists = ok_io_check and io_val ~= nil
local ok_os_check, os_val = pcall(function() return _G["os"] end)
io_probe.os_exists = ok_os_check and os_val ~= nil

local file_attempts = {}
if io_probe.io_exists and doc_row ~= nil and result.matched_storage ~= nil and doc_row.encoding_key ~= nil then
    local base = tostring(result.matched_storage.location or "")
    local key = tostring(doc_row.encoding_key)
    local candidates = {
        base .. key,
        base .. "/" .. key,
        base .. "\\" .. key,
        base .. "/" .. key .. "." .. tostring(doc_row.file_type or ""),
        base .. "\\" .. key .. "." .. tostring(doc_row.file_type or ""),
    }
    for _, path in ipairs(candidates) do
        local attempt = { path = path, opened = false }
        local ok_open, fh_or_err = pcall(function() return io.open(path, "rb") end)
        if ok_open and fh_or_err ~= nil then
            attempt.opened = true
            local ok_read, content_or_err = pcall(function()
                local content = fh_or_err:read("*a")
                fh_or_err:close()
                return content
            end)
            if ok_read and content_or_err ~= nil then
                attempt.length = #content_or_err
                attempt.preview = string.sub(content_or_err, 1, 200)
            else
                attempt.read_error = tostring(content_or_err)
            end
        else
            attempt.error = tostring(fh_or_err)
        end
        table.insert(file_attempts, attempt)
    end
end
result.io_probe = io_probe
result.file_attempts = file_attempts

-- 5) توابع در دسترس روی شیء teamyar
local teamyar_functions = {}
pcall(function()
    for key, value in pairs(teamyar) do
        if type(value) == "function" then
            table.insert(teamyar_functions, tostring(key))
        end
    end
end)
table.sort(teamyar_functions)
result.teamyar_functions = teamyar_functions

out(result)
