-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/06/07 22:52

-- botName = document_content_access_probe
-- version = v02
--
-- هدف: بات تشخیصی موقت — دور دوم بررسی. دور اول (v01) مشخص کرد io/os در Sandbox این پلتفرم
-- در دسترس نیستند، ولی روی شیء teamyar توابع بسیار امیدوارکننده‌ای هست که در هیچ مستند فعلی این
-- پروژه ثبت نشده بودند: get_file، get_attachment، create_file_manager، csv_to_json، json_to_csv.
-- این دور همان‌ها را با چند الگوی فراخوانی محتمل امتحان می‌کند تا مکانیزم واقعی خواندن محتوای
-- یک سند (شناسه سند از ماژول اسناد) و پارس کردن CSV آن مشخص شود.
--
-- نکتهٔ مهم برای اجرای دستی از موبایل (بدون فرم ورودی تعریف‌شده روی بات):
-- document_id به‌صورت ثابت (TEST_DOCUMENT_ID) در همین فایل تنظیم شده — نیازی به ارسال ورودی نیست.
-- اگر خواستید سند دیگری تست شود، فقط همین عدد را عوض کنید و دوباره بات را آپدیت/اجرا کنید.
--
-- این بات نهایی نیست و در داشبورد CSV چندفایلی استفاده نمی‌شود؛ فقط برای دریافت خروجی تشخیصی از
-- سرور واقعی Teamyar است (این محیط توسعه به erp.bimehland.com دسترسی شبکه ندارد).

local TEST_DOCUMENT_ID = 19025

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

-- خلاصه‌سازی امن یک مقدار ناشناخته برای گزارش JSON (بدون افتادن در حلقه/حجم زیاد)
local function summarize_value(v, max_len)
    max_len = max_len or 300
    local t = type(v)
    if t == "string" then
        return { lua_type = t, length = #v, preview = string.sub(v, 1, max_len) }
    elseif t == "table" then
        local keys = {}
        local count = 0
        for k, val in pairs(v) do
            count = count + 1
            if count <= 30 then
                local vt = type(val)
                local entry = { key = tostring(k), value_type = vt }
                if vt == "string" then
                    entry.length = #val
                    entry.preview = string.sub(val, 1, 150)
                elseif vt == "number" or vt == "boolean" then
                    entry.value = val
                end
                table.insert(keys, entry)
            end
        end
        return { lua_type = t, field_count = count, fields = keys }
    elseif t == "number" or t == "boolean" then
        return { lua_type = t, value = v }
    elseif t == "nil" then
        return { lua_type = "nil" }
    else
        return { lua_type = t }
    end
end

local input = {}
pcall(function() input = teamyar.get_input() or {} end)

local raw_document_id = input["document_id"] or input["id"] or input["doc_id"]
local document_id = tonumber(raw_document_id) or TEST_DOCUMENT_ID

local result = {
    ok = true,
    note = "این بات فقط تشخیصی است — برای داشبورد نهایی CSV چندفایلی استفاده نمی‌شود",
    document_id_used = document_id,
    document_id_source = (raw_document_id ~= nil) and "input" or "hardcoded_default",
}

-- 0) تست مستقل csv_to_json روی یک رشتهٔ ساختگی — مستقل از موفقیت خواندن فایل واقعی
local csv_sample = "col_a,col_b\n1,۲\nhello,دنیا"
local csv_to_json_attempts = {}
do
    local ok1, res1 = pcall(function() return teamyar.csv_to_json(csv_sample) end)
    table.insert(csv_to_json_attempts, {
        call = "csv_to_json(csv_string)",
        ok = ok1,
        result = ok1 and summarize_value(res1) or nil,
        error = (not ok1) and tostring(res1) or nil
    })

    local ok2, res2 = pcall(function() return teamyar.csv_to_json(csv_sample, ",") end)
    table.insert(csv_to_json_attempts, {
        call = "csv_to_json(csv_string, \",\")",
        ok = ok2,
        result = ok2 and summarize_value(res2) or nil,
        error = (not ok2) and tostring(res2) or nil
    })
end
result.csv_to_json_probe = csv_to_json_attempts

-- 1) get_file با چند امضای محتمل
local get_file_attempts = {}
local get_file_content = nil

local ok_a, res_a = pcall(function() return teamyar.get_file(document_id) end)
table.insert(get_file_attempts, {
    call = "get_file(document_id_number)",
    ok = ok_a,
    result = ok_a and summarize_value(res_a) or nil,
    error = (not ok_a) and tostring(res_a) or nil
})
if ok_a and type(res_a) == "string" then get_file_content = res_a end

local ok_b, res_b = pcall(function() return teamyar.get_file(tostring(document_id)) end)
table.insert(get_file_attempts, {
    call = "get_file(tostring(document_id))",
    ok = ok_b,
    result = ok_b and summarize_value(res_b) or nil,
    error = (not ok_b) and tostring(res_b) or nil
})
if get_file_content == nil and ok_b and type(res_b) == "string" then get_file_content = res_b end

local ok_c, res_c = pcall(function() return teamyar.get_file({ id = document_id }) end)
table.insert(get_file_attempts, {
    call = "get_file({id=document_id})",
    ok = ok_c,
    result = ok_c and summarize_value(res_c) or nil,
    error = (not ok_c) and tostring(res_c) or nil
})

result.get_file_probe = get_file_attempts

-- 2) get_attachment با document_id (نه فقط نام فایل پیوستی خود بات)
local get_attachment_attempts = {}
local ok_d, res_d = pcall(function() return teamyar.get_attachment(document_id) end)
table.insert(get_attachment_attempts, {
    call = "get_attachment(document_id_number)",
    ok = ok_d,
    result = ok_d and summarize_value(res_d) or nil,
    error = (not ok_d) and tostring(res_d) or nil
})
if get_file_content == nil and ok_d and type(res_d) == "string" then get_file_content = res_d end

local ok_e, res_e = pcall(function() return teamyar.get_attachment(tostring(document_id)) end)
table.insert(get_attachment_attempts, {
    call = "get_attachment(tostring(document_id))",
    ok = ok_e,
    result = ok_e and summarize_value(res_e) or nil,
    error = (not ok_e) and tostring(res_e) or nil
})
if get_file_content == nil and ok_e and type(res_e) == "string" then get_file_content = res_e end

result.get_attachment_probe = get_attachment_attempts

-- 3) create_file_manager — شیء بازگشتی را می‌کاویم تا متدهایش معلوم شود
local file_manager_probe = {}
local ok_f, fm_or_err = pcall(function() return teamyar.create_file_manager() end)
file_manager_probe.create_ok = ok_f
if ok_f then
    file_manager_probe.instance = summarize_value(fm_or_err)
    if type(fm_or_err) == "table" then
        -- امتحان چند متد محتمل روی شیء فایل‌منیجر
        local method_names = { "get", "read", "open", "download", "get_content", "fetch", "load" }
        local method_attempts = {}
        for _, m in ipairs(method_names) do
            if type(fm_or_err[m]) == "function" then
                local ok_m, res_m = pcall(function() return fm_or_err[m](fm_or_err, document_id) end)
                table.insert(method_attempts, {
                    method = m .. "(document_id)",
                    ok = ok_m,
                    result = ok_m and summarize_value(res_m) or nil,
                    error = (not ok_m) and tostring(res_m) or nil
                })
                if get_file_content == nil and ok_m and type(res_m) == "string" then
                    get_file_content = res_m
                end
            end
        end
        file_manager_probe.method_attempts = method_attempts
    end
else
    file_manager_probe.error = tostring(fm_or_err)
end
result.file_manager_probe = file_manager_probe

-- 4) اگر از هرکدام از بالا محتوای رشته‌ای واقعی به دست آمد، csv_to_json را روی آن هم امتحان کن
if get_file_content ~= nil then
    result.real_content_found = true
    result.real_content_length = #get_file_content
    result.real_content_preview = string.sub(get_file_content, 1, 300)
    local ok_real, res_real = pcall(function() return teamyar.csv_to_json(get_file_content) end)
    result.real_content_csv_to_json = {
        ok = ok_real,
        result = ok_real and summarize_value(res_real) or nil,
        error = (not ok_real) and tostring(res_real) or nil
    }
else
    result.real_content_found = false
end

-- 5) متادیتای سند (از دور قبل، برای مرجع)
local rows, err = fetch_rows([[
    SELECT ID, NAME, MIME_TYPE, SIZE, ENCODING_KEY, FILE_TYPE
    FROM documents_main
    WHERE ID = ?
    LIMIT 1
]], { document_id })
if err ~= nil then
    result.document_meta = { ok = false, error = tostring(err) }
elseif rows == nil or #rows == 0 then
    result.document_meta = { ok = false, error = "سندی با این document_id یافت نشد" }
else
    local r = rows[1]
    result.document_meta = {
        ok = true,
        id = r[1], name = r[2], mime_type = r[3], size = r[4], encoding_key = r[5], file_type = r[6]
    }
end

out(result)
