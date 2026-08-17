-- botName = external_sms_gateway
-- version = v01

--------------------------------------------
--- External SMS Gateway Bot
--- Module: 9_Sms (فراخوانی داخلی از طریق teamyar.call_api(16, '/api/sms/send', ...))
--- Type: [api] — فقط JSON برمی‌گرداند، بدون HTML
---
--- هدف: این بات از بیرون ERP (نرم‌افزار خارجی) فراخوانی می‌شود و پیامک را از طریق
--- API واقعی پیامک Teamyar ارسال می‌کند:
---   External Software -> این بات -> teamyar.call_api -> SMS API
---
--- ساختار send_to برای ارسال مستقیم به شماره موبایل (mobile_numbers) حدس زده نشده؛
--- طبق مستندات رسمی پورتال Teamyar است — ر.ک:
--- docs/context/TeamyarInternalApiReference.md (بخش «ماژول پیامک (SMS) — module_id 16»):
---   messages: array<object> — هرکدام:
---     { content, send_to: { profile_ids: [int64], mobile_numbers: [{value, country}] } }
--- country = کد کشور طبق country_list.ini (ایران = 364؛ همان مستند، بخش Profile.mobile)
---
--- الگوی خواندن secret-key از HTTP Header (teamyar.get_http_header) نیز حدس زده نشده؛
--- عیناً از بات‌های زندهٔ همین ریپو کپی شده: src/call_api_1_bot.lua و
--- docs/context/CrmCustomerUiDiscovery.md (خط ۱۹۵)
--------------------------------------------

local SMS_MODULE_ID = 16          -- ماژول SMS طبق TeamyarInternalApiReference.md
local SMS_SEND_PATH = "/api/sms/send"
local SMS_INFO_MODULE_ID = 26     -- module_id داخل payload ارسال (طبق نمونهٔ زندهٔ crm_rfm_bot.lua)
local IRAN_COUNTRY_CODE = 364     -- طبق TeamyarInternalApiReference.md (Profile.mobile.country)
local MAX_QUEUE_ITEMS = 200       -- سقف تعداد پیامک در هر فراخوانی صف (محافظتی)

-- در صورت نبود Config بات، این مقادیر جایگزین می‌شوند.
-- ترجیح همیشه teamyar.get_config() است؛ این‌ها فقط fallback هستند.
local FALLBACK_SMS_BOX_ID = 0     -- قبل از استقرار واقعی، شناسهٔ صندوق SMS را اینجا تنظیم کنید
local FALLBACK_SECRET_KEY = ""    -- خالی = غیرفعال (fail-closed)، مگر در Config مقداردهی شود

--------------------------------------------
--- Config
--------------------------------------------
local function get_gateway_config()
  local config = teamyar.get_config()
  local cfg_data = {}
  if config ~= nil and config.data ~= nil then
    cfg_data = config.data
  end

  local sms_box_id = cfg_data.sms_box_id
  if sms_box_id == nil or sms_box_id == "" then
    sms_box_id = FALLBACK_SMS_BOX_ID
  end

  local secret_key = cfg_data.secret_key
  if secret_key == nil or secret_key == "" then
    secret_key = FALLBACK_SECRET_KEY
  end

  return {
    sms_box_id = tonumber(sms_box_id) or sms_box_id,
    secret_key = secret_key
  }
end

--------------------------------------------
--- Security: secret-key از HTTP Header (الگوی تاییدشده در call_api_1_bot.lua)
--------------------------------------------
local function read_header_secret_key()
  local ok, value = pcall(teamyar.get_http_header, "secret-key")
  if ok and value ~= nil and value ~= "" then
    return value
  end
  return ""
end

local function is_secret_key_valid(expected_secret_key)
  if expected_secret_key == nil or expected_secret_key == "" then
    return false -- کلید تعریف‌نشده در Config/Fallback یعنی گیت‌وی قفل بماند
  end
  return read_header_secret_key() == expected_secret_key
end

--------------------------------------------
--- Validation
--------------------------------------------
local function is_blank(value)
  if value == nil then return true end
  if type(value) == "string" and value:gsub("%s+", "") == "" then return true end
  return false
end

--------------------------------------------
--- ارسال یک پیامک به یک شماره موبایل
--------------------------------------------
local function send_one_sms(cfg, mobile, message)
  local info = {
    box_id = cfg.sms_box_id,
    messages = {
      {
        content = message,
        send_to = {
          mobile_numbers = { { value = mobile, country = IRAN_COUNTRY_CODE } }
        }
      }
    },
    module_id = SMS_INFO_MODULE_ID
  }

  -- Log ورودی بدون اطلاعات حساس (بدون secret_key، بدون متن کامل پیامک)
  teamyar.write_log("[external_sms_gateway] send request mobile=" .. tostring(mobile)
    .. " box_id=" .. tostring(cfg.sms_box_id)
    .. " message_len=" .. tostring(#tostring(message)))

  local call_ok, api_result = pcall(teamyar.call_api, SMS_MODULE_ID, SMS_SEND_PATH, info)

  if not call_ok then
    teamyar.write_log("[external_sms_gateway] call_api error mobile=" .. tostring(mobile)
      .. " err=" .. tostring(api_result))
    return {
      success = false,
      mobile = mobile,
      error = "sms_api_call_failed"
    }
  end

  teamyar.write_log("[external_sms_gateway] api_response mobile=" .. tostring(mobile)
    .. " response=" .. json.encode(api_result))

  local message_id = nil
  if type(api_result) == "table" and type(api_result.data) == "table"
      and type(api_result.data.message_ids) == "table" then
    message_id = api_result.data.message_ids[1]
  end

  return {
    success = (type(api_result) == "table" and api_result.success == true),
    mobile = mobile,
    message_id = message_id, -- اگر واقعاً در پاسخ API نبود، nil می‌ماند (اختراع نمی‌شود)
    api_response = api_result
  }
end

--------------------------------------------
--- ولیدیشن + ارسال یک آیتم (mobile + message)
--- attach_mobile_on_error: در حالت صف true است (اسناد هر خطا به شماره‌اش)؛
--- در حالت تکی false است تا خروجی خطا دقیقاً مطابق قرارداد اعلام‌شده بماند: {success, error}
--------------------------------------------
local function validate_and_send(cfg, mobile, message, attach_mobile_on_error)
  if is_blank(mobile) then
    local err_result = { success = false, error = "mobile_required" }
    if attach_mobile_on_error then err_result.mobile = mobile end
    return err_result
  end
  if is_blank(message) then
    local err_result = { success = false, error = "message_required" }
    if attach_mobile_on_error then err_result.mobile = mobile end
    return err_result
  end

  local ok, result = pcall(send_one_sms, cfg, mobile, message)
  if not ok then
    teamyar.write_log("[external_sms_gateway] unexpected error mobile=" .. tostring(mobile)
      .. " err=" .. tostring(result))
    return { success = false, mobile = mobile, error = "unexpected_error" }
  end
  return result
end

--------------------------------------------
--- Manager
--- ورودی تکی:  { secret_key, mobile, message }
--- ورودی صف:   { secret_key, items: [ {mobile, message}, ... ] }  (حداکثر MAX_QUEUE_ITEMS آیتم)
--------------------------------------------
local function handle_request()
  local input = teamyar.get_input()
  if input == nil then
    return { success = false, error = "invalid_input" }
  end

  local cfg = get_gateway_config()
  if not is_secret_key_valid(cfg.secret_key) then
    return { success = false, error = "invalid_secret_key" }
  end

  -- حالت صف: input.items یک آرایه از {mobile, message} است
  if type(input.items) == "table" and #input.items > 0 then
    local queue = input.items
    if #queue > MAX_QUEUE_ITEMS then
      return { success = false, error = "too_many_items" }
    end

    local results = {}
    local success_count = 0
    local fail_count = 0

    for _, item in ipairs(queue) do
      local item_mobile = (type(item) == "table") and item.mobile or nil
      local item_message = (type(item) == "table") and item.message or nil
      local item_result = validate_and_send(cfg, item_mobile, item_message, true)
      table.insert(results, item_result)
      if item_result.success then
        success_count = success_count + 1
      else
        fail_count = fail_count + 1
      end
    end

    return {
      success = (fail_count == 0),
      total = #queue,
      success_count = success_count,
      fail_count = fail_count,
      results = results
    }
  end

  -- حالت تکی
  return validate_and_send(cfg, input.mobile, input.message, false)
end

--------------------------------------------
--- Manager (single execution path - no type check needed)
--------------------------------------------
local run_ok, run_result = pcall(handle_request)
if not run_ok then
  teamyar.write_log("[external_sms_gateway] fatal error: " .. tostring(run_result))
  teamyar.write_result(json.encode({ success = false, error = "internal_error" }))
else
  teamyar.write_result(json.encode(run_result))
end
