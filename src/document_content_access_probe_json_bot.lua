-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/06/07 22:56

-- botName = document_content_access_probe
-- version = v03
--
-- خلاصهٔ دورهای قبل:
--   v01: io/os در Sandbox موجود نیستند. توابع ناشناختهٔ زیر روی teamyar کشف شدند:
--        get_file, get_attachment, create_file_manager, csv_to_json, json_to_csv
--   v02: csv_to_json(csv_string) کار می‌کند و یک رشتهٔ JSON آرایه‌ای برمی‌گرداند — CONFIRMED.
--        get_attachment(document_id) رشتهٔ خالی برمی‌گرداند (مخصوص پیوست خودِ بات با نام فایل است،
--        نه سند دلخواه از ماژول اسناد).
--        get_file(document_id) / get_file(tostring(id)) / get_file({id=id}) هرکدام nil یا جدول خالی دادند.
--        create_file_manager() با آرگومان صفر خطای «invalid module id» داد — یعنی یک آرگومان module_id
--        می‌خواهد (برای سند اسناد ماژول = 7، طبق docs/context/TeamyarInternalApiReference.md).
--   این دور (v03): create_file_manager با module_id واقعی سند (از ستون MODULE_ID خودِ documents_main،
--   نه فرض ثابت 7) صدا زده می‌شود، شیء برگشتی به‌طور کامل کاویده می‌شود، و چند امضای دیگر برای
--   get_file/create_file_manager (دو-آرگومانی) و چند حدس برای teamyar.call_api(7, ...) هم امتحان می‌شود.
--
-- این بات نهایی نیست و در داشبورد CSV چندفایلی استفاده نمی‌شود.

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

local function summarize_value(v, max_len)
    max_len = max_len or 300
    local t = type(v)
    if t == "string" then
        return { lua_type = t, length = #v, preview = string.sub(v, 1, max_len), is_empty = (#v == 0) }
    elseif t == "table" then
        local keys = {}
        local count = 0
        for k, val in pairs(v) do
            count = count + 1
            if count <= 40 then
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

-- رشتهٔ رشته‌ای غیرخالی؟ (برای جلوگیری از قبول کردن "" به‌عنوان محتوای واقعی)
local function is_real_content(v)
    return type(v) == "string" and #v > 0
end

local input = {}
pcall(function() input = teamyar.get_input() or {} end)
local raw_document_id = input["document_id"] or input["id"] or input["doc_id"]
local document_id = tonumber(raw_document_id) or TEST_DOCUMENT_ID

local result = {
    ok = true,
    note = "این بات فقط تشخیصی است — برای داشبورد نهایی CSV چندفایلی استفاده نمی‌شود",
    document_id_used = document_id,
}

-- 0) متادیتای سند — این‌بار MODULE_ID هم می‌خوانیم (کلید حل مشکل create_file_manager)
local module_id = 7 -- fallback طبق رجیستری اسناد
local rows, err = fetch_rows([[
    SELECT ID, NAME, MIME_TYPE, SIZE, ENCODING_KEY, FILE_TYPE, MODULE_ID, RECORD_ID, RECORD_TYPE
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
        ok = true, id = r[1], name = r[2], mime_type = r[3], size = r[4],
        encoding_key = r[5], file_type = r[6], module_id = r[7], record_id = r[8], record_type = r[9]
    }
    if type(r[7]) == "number" and r[7] > 0 then module_id = r[7] end
end
result.module_id_used = module_id

local get_file_content = nil

-- 1) create_file_manager با module_id واقعی — یک‌آرگومانی و دوآرگومانی
local file_manager_probe = {}

local ok1, fm1 = pcall(function() return teamyar.create_file_manager(module_id) end)
file_manager_probe.single_arg = { ok = ok1, error = (not ok1) and tostring(fm1) or nil }
if ok1 then
    file_manager_probe.single_arg.instance = summarize_value(fm1)
    if type(fm1) == "table" then
        local method_names = { "get", "read", "open", "download", "get_content", "get_file", "fetch", "load", "content" }
        local attempts = {}
        for _, m in ipairs(method_names) do
            if type(fm1[m]) == "function" then
                local ok_m, res_m = pcall(function() return fm1[m](fm1, document_id) end)
                table.insert(attempts, {
                    method = m .. "(self, document_id)", ok = ok_m,
                    result = ok_m and summarize_value(res_m) or nil,
                    error = (not ok_m) and tostring(res_m) or nil
                })
                if get_file_content == nil and is_real_content(res_m) then get_file_content = res_m end
            end
        end
        file_manager_probe.single_arg.method_attempts = attempts
    end
end

local ok2, fm2 = pcall(function() return teamyar.create_file_manager(module_id, document_id) end)
file_manager_probe.two_arg = { ok = ok2, error = (not ok2) and tostring(fm2) or nil }
if ok2 then
    file_manager_probe.two_arg.instance = summarize_value(fm2)
    if type(fm2) == "table" then
        local method_names = { "get", "read", "open", "download", "get_content", "get_file", "fetch", "load", "content" }
        local attempts = {}
        for _, m in ipairs(method_names) do
            if type(fm2[m]) == "function" then
                local ok_m, res_m = pcall(function() return fm2[m](fm2) end)
                table.insert(attempts, {
                    method = m .. "(self)", ok = ok_m,
                    result = ok_m and summarize_value(res_m) or nil,
                    error = (not ok_m) and tostring(res_m) or nil
                })
                if get_file_content == nil and is_real_content(res_m) then get_file_content = res_m end
            end
        end
        file_manager_probe.two_arg.method_attempts = attempts
    end
elseif type(fm2) == "string" then
    -- شاید خودِ create_file_manager دو-آرگومانی مستقیماً محتوا را برگرداند
    if is_real_content(fm2) then get_file_content = fm2 end
end

result.file_manager_probe = file_manager_probe

-- 2) get_file با امضای دوآرگومانی (module_id, document_id) و برعکس
local get_file_probe = {}
local gf1_ok, gf1 = pcall(function() return teamyar.get_file(module_id, document_id) end)
table.insert(get_file_probe, { call = "get_file(module_id, document_id)", ok = gf1_ok,
    result = gf1_ok and summarize_value(gf1) or nil, error = (not gf1_ok) and tostring(gf1) or nil })
if get_file_content == nil and is_real_content(gf1) then get_file_content = gf1 end

local gf2_ok, gf2 = pcall(function() return teamyar.get_file(document_id, module_id) end)
table.insert(get_file_probe, { call = "get_file(document_id, module_id)", ok = gf2_ok,
    result = gf2_ok and summarize_value(gf2) or nil, error = (not gf2_ok) and tostring(gf2) or nil })
if get_file_content == nil and is_real_content(gf2) then get_file_content = gf2 end

local gf3_ok, gf3 = pcall(function() return teamyar.get_file({ module_id = module_id, id = document_id }) end)
table.insert(get_file_probe, { call = "get_file({module_id=..,id=..})", ok = gf3_ok,
    result = gf3_ok and summarize_value(gf3) or nil, error = (not gf3_ok) and tostring(gf3) or nil })
if get_file_content == nil and is_real_content(gf3) then get_file_content = gf3 end

result.get_file_probe_v2 = get_file_probe

-- 3) چند حدس برای teamyar.call_api(module_id, url, params) روی ماژول اسناد
local call_api_probe = {}
local api_guesses = {
    { url = "document/download", params = { id = document_id } },
    { url = "document/get", params = { id = document_id } },
    { url = "document/get_content", params = { id = document_id } },
    { url = "file/download", params = { id = document_id } },
}
for _, guess in ipairs(api_guesses) do
    local ok_api, res_api = pcall(function() return teamyar.call_api(module_id, guess.url, guess.params) end)
    table.insert(call_api_probe, {
        url = guess.url, ok = ok_api,
        result = ok_api and summarize_value(res_api) or nil,
        error = (not ok_api) and tostring(res_api) or nil
    })
end
result.call_api_probe = call_api_probe

-- 4) اگر محتوای واقعی پیدا شد، طول/پیش‌نمایش + تست csv_to_json روی آن
if get_file_content ~= nil then
    result.real_content_found = true
    result.real_content_length = #get_file_content
    result.real_content_preview = string.sub(get_file_content, 1, 300)
    local ok_real, res_real = pcall(function() return teamyar.csv_to_json(get_file_content) end)
    result.real_content_csv_to_json_preview = {
        ok = ok_real,
        preview = ok_real and type(res_real) == "string" and string.sub(res_real, 1, 400) or nil,
        error = (not ok_real) and tostring(res_real) or nil
    }
else
    result.real_content_found = false
end

out(result)
