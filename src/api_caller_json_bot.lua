-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/06/06 20:58

-- botName = api_caller
-- description = فراخوان عمومی APIهای داخلی Teamyar (teamyar.call_api) — هم برای استفادهٔ بات‌های
--               دیگر و هم برای گرفتن schema واقعی یک endpoint قبل از استفاده در بات
-- version = 1
--
-- الگوی این بات از call_api_1_bot.lua (بات موجود همین ریپو) گرفته شده — همان ساختار
-- teamyar.call_api(module_id, url, params) + کنترل secret-key — با سه تفاوت:
--   ۱) module_id و url به‌جای hardcode بودن، ورودی‌اند تا یک بات برای همهٔ endpointها کافی باشد.
--   ۲) secret_key از bot_config خوانده می‌شود، نه داخل سورس. هیچ کلیدی در این ریپو ذخیره نمی‌شود.
--   ۳) allowlist ماژول/مسیر دارد (پایین را ببینید).
--
-- ⚠️ چرا allowlist اجباری است: این بات یک «هر API داخلی را صدا بزن» است. بدون محدودیت، هرکسی که
-- کلید را داشته باشد می‌تواند با همان کلید فاکتور بسازد، سند حسابداری بزند یا اطلاعات پرسنلی را
-- عوض کند. پس رفتار پیش‌فرض fail-closed است: تا وقتی allowed_modules در bot_config تنظیم نشده،
-- هیچ فراخوانی انجام نمی‌شود. برای حالت «کشف schema» هم بهتر است فقط ماژول موردنیاز باز شود، نه همه.
--
-- bot_config:
--   {
--     "secret_key": "...",                       -- الزامی
--     "allowed_modules": "9,13",                 -- الزامی؛ فهرست module_idهای مجاز با کاما
--     "allowed_paths": "/api/dialog/add,/api/group/get"  -- اختیاری؛ اگر باشد فقط همین مسیرها
--   }
--
-- ورودی‌ها:
--   module_id  (عدد، الزامی)  — شناسهٔ ماژول طبق جدول HOME_MODULE_LIST در TeamyarInternalApiReference.md
--   url        (متن، الزامی)  — مسیر endpoint، مثلاً /api/dialog/add
--   params     (شیء یا رشتهٔ JSON، اختیاری) — بدنهٔ درخواست همان endpoint
--   secret_key (متن) — اگر هدر secret-key در دسترس نباشد (مثلاً فراخوانی از بات دیگر با run_command)
--
-- خروجی: { ok, module_id, url, request, response } یا { ok = false, error }
--   response عیناً همان چیزی است که API برگردانده — همین برای استخراج schema واقعی کافی است.

local input = teamyar.get_input() or {}

local function fail(message)
    teamyar.write_result(json.encode({ ok = false, error = message }))
end

-- ── config ───────────────────────────────────────────────────────────

local config_data = {}
do
    local ok = pcall(function()
        local config = teamyar.get_config()
        if config ~= nil and config.data ~= nil then config_data = config.data end
    end)
    if not ok then config_data = {} end
end

local expected_secret = config_data.secret_key
if expected_secret == nil or tostring(expected_secret) == "" then
    fail("کلید امنیتی این بات تنظیم نشده است. مقدار secret_key را در bot_config ثبت کنید.")
    return
end

-- فهرست با کاما → مجموعه، برای هر دو تنظیم allowlist
local function parse_list(raw)
    local items = {}
    if raw == nil then return items end
    for piece in tostring(raw):gmatch("[^,]+") do
        local trimmed = piece:gsub("^%s+", ""):gsub("%s+$", "")
        if trimmed ~= "" then items[trimmed] = true end
    end
    return items
end

local allowed_modules = parse_list(config_data.allowed_modules)
local allowed_paths = parse_list(config_data.allowed_paths)

if next(allowed_modules) == nil then
    fail("هیچ ماژول مجازی تعریف نشده است. allowed_modules را در bot_config تنظیم کنید " ..
        "(مثلاً \"9,13\"). این بات عمداً بدون allowlist هیچ فراخوانی انجام نمی‌دهد.")
    return
end

-- ── auth ─────────────────────────────────────────────────────────────
-- کلید یا از هدر HTTP می‌آید (فراخوانی مستقیم) یا از ورودی (فراخوانی از بات دیگر با run_command،
-- که در آن هدر HTTP وجود ندارد)

local provided_secret = ""
do
    local ok, header = pcall(function() return teamyar.get_http_header("secret-key") end)
    if ok and header ~= nil and #header > 0 then
        provided_secret = header
    elseif input.secret_key ~= nil then
        provided_secret = tostring(input.secret_key)
    end
end

if provided_secret ~= tostring(expected_secret) then
    fail("کلید امنیتی نامعتبر است")
    return
end

-- ── request ──────────────────────────────────────────────────────────

local module_id = tonumber(input.module_id)
if module_id == nil or module_id < 0 then
    fail("module_id نامعتبر است")
    return
end

local url = input.url
if url == nil or tostring(url) == "" then
    fail("url وارد نشده است")
    return
end
url = tostring(url)

if not allowed_modules[tostring(math.floor(module_id))] then
    fail("ماژول " .. tostring(math.floor(module_id)) .. " در allowed_modules این بات مجاز نیست")
    return
end
if next(allowed_paths) ~= nil and not allowed_paths[url] then
    fail("مسیر " .. url .. " در allowed_paths این بات مجاز نیست")
    return
end

-- params می‌تواند شیء باشد (فراخوانی از بات دیگر) یا رشتهٔ JSON (فراخوانی از فرم/HTTP)
local params = input.params
if type(params) == "string" then
    if params == "" then
        params = {}
    else
        local ok, decoded = pcall(function() return json.decode(params) end)
        if not ok or type(decoded) ~= "table" then
            fail("params یک JSON معتبر نیست")
            return
        end
        params = decoded
    end
elseif type(params) ~= "table" then
    params = {}
end

-- ── call ─────────────────────────────────────────────────────────────

local ok, response = pcall(function()
    return teamyar.call_api(module_id, url, params)
end)

if not ok then
    fail("خطا در فراخوانی API: " .. tostring(response))
    return
end

teamyar.write_result(json.encode({
    ok = true,
    module_id = module_id,
    url = url,
    request = params,
    response = response
}))
