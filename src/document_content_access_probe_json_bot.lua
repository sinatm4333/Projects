-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/06/07 23:09

-- botName = document_content_access_probe
-- version = v05
--
-- خلاصهٔ دورهای قبل:
--   v01-v03: io/os موجود نیستند؛ create_file_manager(module_id[, document_id]) یک userdata (شبیه
--            file handle io.open) برمی‌گرداند؛ get_file/get_attachment/call_api حدسی به جایی نرسیدند.
--   v04: getmetatable(obj).__index روی آن userdata اجرا شد و متدهای واقعی کشف شدند:
--        __gc, getInfo, readFile, readFileBase64, release, updateFile, updateFolder
--        (حدس‌های قبلی مثل read/get/content هیچ‌کدام درست نبودند — برای همین method_attempts خالی ماند)
--   این دور (v05): فقط متدهای امن-فقط-خواندنی (readFile, readFileBase64, getInfo) روی هر دو نمونه
--   (تک‌آرگومانی module_id و دوآرگومانی module_id+document_id) با self-only و self+document_id
--   امتحان می‌شوند. updateFile/updateFolder عمداً فراخوانی نمی‌شوند (نوشتنی‌اند، امضایشان ناشناخته
--   است و ریسک خراب‌کردن سند واقعی کاربر را دارند) — release هم فقط در پایان برای پاک‌سازی صدا زده
--   می‌شود، نه برای کاوش.
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

local function is_real_content(v)
    return type(v) == "string" and #v > 0
end

-- کاوش یک شیء userdata: متادیتای metatable + امتحان متدهای واقعی امن-فقط-خواندنی
-- (کشف‌شده در v04 از getmetatable(obj).__index — updateFile/updateFolder/release عمداً اینجا نیستند)
-- ترتیب عمدی: getInfo (سبک) قبل از readFile/readFileBase64 (فایل ۱۳ مگابایتی — سنگین)
local CANDIDATE_METHODS = { "getInfo", "readFile", "readFileBase64" }

local function probe_userdata_object(obj, extra_arg_for_methods)
    local probe = {}

    -- متادیتا/متدها
    local ok_mt, mt = pcall(function() return getmetatable(obj) end)
    if ok_mt and type(mt) == "table" then
        local mt_summary = { has_metatable = true }
        local ok_idx, idx = pcall(function() return mt.__index end)
        if ok_idx and type(idx) == "table" then
            local method_names = {}
            for k, v in pairs(idx) do
                if type(v) == "function" then table.insert(method_names, tostring(k)) end
            end
            table.sort(method_names)
            mt_summary.index_methods = method_names
        else
            mt_summary.index_type = ok_idx and type(idx) or "error"
        end
        probe.metatable = mt_summary
    else
        probe.metatable = { has_metatable = false }
    end

    -- امتحان متدهای محتمل، هم بدون آرگومان و هم با extra_arg_for_methods (مثلاً document_id)
    -- خروج زودهنگام به‌محض پیدا شدن محتوای واقعی — فایل ۱۳ مگابایتی است، فراخوانی‌های تکراری
    -- readFile/readFileBase64 روی همان سند فقط زمان/حافظه هدر می‌دهند.
    local method_attempts = {}
    local found_content = nil
    for _, m in ipairs(CANDIDATE_METHODS) do
        if found_content ~= nil then break end
        local ok_has, fn = pcall(function() return obj[m] end)
        if ok_has and type(fn) == "function" then
            local ok_call0, res0 = pcall(function() return fn(obj) end)
            table.insert(method_attempts, {
                method = m .. "(self)", ok = ok_call0,
                result = ok_call0 and summarize_value(res0) or nil,
                error = (not ok_call0) and tostring(res0) or nil
            })
            if is_real_content(res0) and m ~= "getInfo" then found_content = res0 end

            if found_content == nil and extra_arg_for_methods ~= nil then
                local ok_call1, res1 = pcall(function() return fn(obj, extra_arg_for_methods) end)
                table.insert(method_attempts, {
                    method = m .. "(self, arg)", ok = ok_call1,
                    result = ok_call1 and summarize_value(res1) or nil,
                    error = (not ok_call1) and tostring(res1) or nil
                })
                if is_real_content(res1) and m ~= "getInfo" then found_content = res1 end
            end
        end
    end
    probe.method_attempts = method_attempts
    probe.found_content = found_content
    return probe
end

local input = {}
pcall(function() input = teamyar.get_input() or {} end)
local raw_document_id = input["document_id"] or input["id"] or input["doc_id"]
local document_id = tonumber(raw_document_id) or TEST_DOCUMENT_ID

local result = {
    ok = true,
    probe_version = "v05",
    note = "این بات فقط تشخیصی است — برای داشبورد نهایی CSV چندفایلی استفاده نمی‌شود",
    document_id_used = document_id,
}

local module_id = 7
local rows, err = fetch_rows([[
    SELECT ID, NAME, MIME_TYPE, SIZE, ENCODING_KEY, FILE_TYPE, MODULE_ID
    FROM documents_main WHERE ID = ? LIMIT 1
]], { document_id })
if rows ~= nil and #rows > 0 then
    local r = rows[1]
    result.document_meta = { id = r[1], name = r[2], mime_type = r[3], size = r[4], encoding_key = r[5], file_type = r[6], module_id = r[7] }
    if type(r[7]) == "number" and r[7] > 0 then module_id = r[7] end
end
result.module_id_used = module_id

local get_file_content = nil
local fm1, fm2 = nil, nil

-- اول نمونهٔ دوآرگومانی (module_id+document_id) که احتمالاً از قبل به همین سند مقیدشده و سبک‌تره —
-- اگر محتوا از این پیدا شد، نیازی به تکرار سنگین همان کار روی نمونهٔ تک‌آرگومانی نیست.
local ok2, fm2_val = pcall(function() return teamyar.create_file_manager(module_id, document_id) end)
fm2 = fm2_val
local two_arg_probe = { ok = ok2, error = (not ok2) and tostring(fm2) or nil }
if ok2 then
    two_arg_probe.lua_type = type(fm2)
    if type(fm2) == "userdata" or type(fm2) == "table" then
        local p = probe_userdata_object(fm2, document_id)
        two_arg_probe.metatable = p.metatable
        two_arg_probe.method_attempts = p.method_attempts
        if get_file_content == nil then get_file_content = p.found_content end
    end
end
result.file_manager_two_arg = two_arg_probe

local ok1, fm1_val = pcall(function() return teamyar.create_file_manager(module_id) end)
fm1 = fm1_val
local single_arg_probe = { ok = ok1, error = (not ok1) and tostring(fm1) or nil }
if ok1 then
    single_arg_probe.lua_type = type(fm1)
    if get_file_content == nil and (type(fm1) == "userdata" or type(fm1) == "table") then
        local p = probe_userdata_object(fm1, document_id)
        single_arg_probe.metatable = p.metatable
        single_arg_probe.method_attempts = p.method_attempts
        get_file_content = p.found_content
    elseif get_file_content ~= nil then
        single_arg_probe.skipped_probing = "محتوا از نمونهٔ دوآرگومانی پیدا شد — برای صرفه‌جویی، متدهای سنگین روی این نمونه هم امتحان نشدند"
    end
end
result.file_manager_single_arg = single_arg_probe

-- پاک‌سازی — release فقط در پایان، بدون گزارش‌گیری از آن
pcall(function() if type(fm1) == "userdata" and fm1.release then fm1:release() end end)
pcall(function() if type(fm2) == "userdata" and fm2.release then fm2:release() end end)

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
