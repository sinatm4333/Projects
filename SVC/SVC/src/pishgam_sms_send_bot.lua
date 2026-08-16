-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/05/20 18:01

--------------------------------------------
--- Pishgam Rayan SMS Send Bot
--- Module: Sms
--- Similar to: بات 397 (MeliPayamak Panel SMS Send)
--- API: Guidance-WebService-Pishgamrayan.pdf v2.2 - POST /Messages/Send
--- Base URL: https://smsapi.pishgamrayan.com
--- پیکربندی لازم (تب «پیکربندی» بات): token (مقدار هدر Authorization), sender_number (شماره فرستنده پیش‌فرض)
--------------------------------------------

local PISHGAM_DOMAIN = "smsapi.pishgamrayan.com"
local PISHGAM_PORT = 443
local SEND_PATH = "/Messages/Send"
local MAX_RECIPIENTS = 100

-- خواندن توکن/شماره فرستنده از تب پیکربندی بات (هرگز در سورس هاردکد نشود)
local function get_pishgam_config()
  local config = teamyar.get_config()
  local data = {}
  if config ~= nil and config.data ~= nil then
    data = config.data
  end
  return {
    token = data.token or "",
    sender_number = data.sender_number or ""
  }
end

-- "0912...,0913..." یا "0912... 0913..." یا یک شماره تنها -> آرایه شماره‌ها
local function split_numbers(raw)
  local numbers = {}
  if raw == nil or raw == "" then
    return numbers
  end
  for part in string.gmatch(raw, "[^,%s]+") do
    table.insert(numbers, part)
  end
  return numbers
end

local function send_sms()
  local input = teamyar.get_input() or {}
  local cfg = get_pishgam_config()

  if cfg.token == "" then
    return { ok = false, error = "توکن Authorization پیشگام رایان در پیکربندی بات تنظیم نشده است" }
  end

  local to = input.to
  local text = input.text
  local from = input.from
  if from == nil or from == "" then
    from = cfg.sender_number
  end
  local send_date = input.send_date -- اختیاری - "1403/10/20 09:00:00" برای ارسال زمان‌بندی‌شده

  if to == nil or to == "" then
    return { ok = false, error = "شماره گیرنده (to) الزامی است" }
  end
  if text == nil or text == "" then
    return { ok = false, error = "متن پیامک (text) الزامی است" }
  end
  if from == nil or from == "" then
    return { ok = false, error = "شماره فرستنده (from) الزامی است و در پیکربندی بات هم تنظیم نشده است" }
  end

  local recipient_numbers = split_numbers(to)
  if #recipient_numbers == 0 then
    return { ok = false, error = "شماره گیرنده معتبر یافت نشد" }
  end
  if #recipient_numbers > MAX_RECIPIENTS then
    return { ok = false, error = "حداکثر " .. MAX_RECIPIENTS .. " شماره گیرنده در هر درخواست مجاز است" }
  end

  -- یک متن برای همه گیرندگان (طبق نمونه اول مستندات API)
  local payload = {
    senderNumber = from,
    messageBodies = { text },
    recipientNumbers = recipient_numbers
  }
  if send_date ~= nil and send_date ~= "" then
    payload.sendDateTime = send_date
  end

  local params_file = {
    domain = PISHGAM_DOMAIN,
    port = PISHGAM_PORT,
    url = SEND_PATH,
    ssl = true,
    secure = false,
    method = "post",
    data_str = json.encode(payload),
    header = {
      { name = "Content-Type", value = "application/json" },
      { name = "Authorization", value = cfg.token }
    }
  }

  teamyar.write_log("[Pishgam SMS Send] request=" .. json.encode(payload))
  local call_ok, result_file = pcall(teamyar.call_url, params_file)

  if not call_ok or result_file == nil then
    teamyar.write_log("[Pishgam SMS Send] call_url error: " .. tostring(result_file))
    return { ok = false, error = "خطا در برقراری ارتباط با سرویس پیامک پیشگام رایان" }
  end

  teamyar.write_log("[Pishgam SMS Send] raw_response=" .. json.encode(result_file))

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

  if http_status ~= 200 then
    return {
      ok = false,
      error = "سرویس پیامک با کد HTTP " .. tostring(http_status) .. " پاسخ داد",
      status_code = body.statusCode,
      response = body
    }
  end

  -- طبق مستندات API: statusCode برابر 1 یا 2 یعنی پیام در صف ارسال قرار گرفت.
  -- جدول کامل کدهای وضعیت در مستندات API (فصل «کدهای وضعیت statusCode») آمده است؛
  -- این بات پاسخ خام را هم برمی‌گرداند تا فراخواننده در صورت نیاز خودش دقیق‌تر تفسیر کند.
  local queued = (body.statusCode == 1 or body.statusCode == 2)

  return {
    ok = queued,
    error = (not queued) and ("پیامک ارسال نشد - statusCode=" .. tostring(body.statusCode)) or nil,
    message_id = body.messageId,
    status_code = body.statusCode,
    black_list_count = body.blackListCount,
    invalid_inputs = body.invalidInputs,
    recipient_count = #recipient_numbers
  }
end

--------------------------------------------
--- Manager (single execution path - no type check needed)
--------------------------------------------
local result = send_sms()
teamyar.write_result(json.encode(result))
