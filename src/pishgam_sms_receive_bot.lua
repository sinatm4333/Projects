-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/05/20 18:01

--------------------------------------------
--- Pishgam Rayan SMS Receive Bot (Inbox pull)
--- Module: Sms
--- Similar to: بات 570 (SMS API Caller [api])
--- API: Guidance-WebService-Pishgamrayan.pdf v2.2 - POST /Messages/GetMessage
--- Base URL: https://smsapi.pishgamrayan.com
--- پیکربندی لازم (تب «پیکربندی» بات): token (مقدار هدر Authorization), private_number (شماره اختصاصی پیش‌فرض)
--- توجه: طبق مستندات، این سرویس فقط API «واکشی» (pull) دارد؛ callback/webhook مستند نشده -
--- این بات باید هنگام نیاز (یا با تایمر بات Teamyar) با بازه زمانی مشخص فراخوانی شود.
--------------------------------------------

local PISHGAM_DOMAIN = "smsapi.pishgamrayan.com"
local PISHGAM_PORT = 443
local GET_MESSAGE_PATH = "/Messages/GetMessage"

-- خواندن توکن/شماره اختصاصی از تب پیکربندی بات (هرگز در سورس هاردکد نشود)
local function get_pishgam_config()
  local config = teamyar.get_config()
  local data = {}
  if config ~= nil and config.data ~= nil then
    data = config.data
  end
  return {
    token = data.token or "",
    private_number = data.private_number or ""
  }
end

local function to_bool(value, default_value)
  if value == nil or value == "" then
    return default_value
  end
  if value == true or value == "true" or value == "1" or value == 1 then
    return true
  end
  return false
end

local function receive_sms()
  local input = teamyar.get_input() or {}
  local cfg = get_pishgam_config()

  if cfg.token == "" then
    return { ok = false, error = "توکن Authorization پیشگام رایان در پیکربندی بات تنظیم نشده است" }
  end

  local private_number = input.private_number
  if private_number == nil or private_number == "" then
    private_number = cfg.private_number
  end
  if private_number == nil or private_number == "" then
    return { ok = false, error = "شماره اختصاصی (private_number) الزامی است" }
  end

  local date_from = input.date_from
  local date_to = input.date_to
  if date_from == nil or date_from == "" or date_to == nil or date_to == "" then
    return {
      ok = false,
      error = "بازه زمانی الزامی است - date_from و date_to را با فرمت \"YYYY/MM/DD HH:MM:SS\" (شمسی) ارسال کنید"
    }
  end

  -- طبق مستندات API پیش‌فرض true است
  local mark_as_read = to_bool(input.mark_as_read, true)

  local payload = {
    dateTimeFrom = date_from,
    dateTimeTo = date_to,
    privateNumber = private_number,
    markAsRead = mark_as_read
  }

  local params_file = {
    domain = PISHGAM_DOMAIN,
    port = PISHGAM_PORT,
    url = GET_MESSAGE_PATH,
    ssl = true,
    secure = false,
    method = "post",
    data_str = json.encode(payload),
    header = {
      { name = "Content-Type", value = "application/json" },
      { name = "Authorization", value = cfg.token }
    }
  }

  teamyar.write_log("[Pishgam SMS Receive] request=" .. json.encode(payload))
  local call_ok, result_file = pcall(teamyar.call_url, params_file)

  if not call_ok or result_file == nil then
    teamyar.write_log("[Pishgam SMS Receive] call_url error: " .. tostring(result_file))
    return { ok = false, error = "خطا در برقراری ارتباط با سرویس پیامک پیشگام رایان" }
  end

  teamyar.write_log("[Pishgam SMS Receive] raw_response=" .. json.encode(result_file))

  if result_file.type ~= "ok" or result_file.result == nil then
    local msg = result_file.message or "خطای نامشخص در فراخوانی سرویس"
    return { ok = false, error = "خطا در فراخوانی سرویس پیامک: " .. msg }
  end

  local http_status = result_file.result.status
  local decode_ok, body = pcall(json.decode, result_file.result.body or "")
  if not decode_ok or body == nil then
    return {
      ok = false,
      error = "پاسخ سرویس پیامک قابل تجزیه نبود (HTTP " .. tostring(http_status) .. ")",
      raw_body = result_file.result.body
    }
  end

  -- طبق مستندات API: در endpointهای دریافت/استعلام، statusCode=0 یعنی موفق
  if http_status ~= 200 or body.statusCode ~= 0 then
    return {
      ok = false,
      error = "دریافت پیامک‌ها ناموفق بود - statusCode=" .. tostring(body.statusCode),
      status_code = body.statusCode,
      response = body
    }
  end

  local messages = body.messages or {}

  return {
    ok = true,
    status_code = body.statusCode,
    message_count = #messages,
    messages = messages,
    date_from = date_from,
    date_to = date_to,
    private_number = private_number
  }
end

--------------------------------------------
--- Manager (single execution path - no type check needed)
--------------------------------------------
local result = receive_sms()
teamyar.write_result(json.encode(result))
