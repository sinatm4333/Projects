local input = teamyar.get_input()
teamyar.write_log("input(full)-----" .. json.encode(input))

local reciver = input.receiver
local caller_num = input.caller_num

local config = teamyar.get_config()
local config_data = {}

local c_tocken = ""
local c_url = ""
local c_f_user_name = ""
local c_f_password = ""
local c_org_id = 0
local c_f_id_api = ""
local c_domain_id_api = ""
local c_url_api_id = ""
local c_cat_id = 0

if config ~= nil and config.data ~= nil then
  config_data = config.data
  c_tocken        = config_data.tocken or ""
  c_url           = config_data.url or ""
  c_f_user_name   = config_data.f_user_name or ""
  c_f_password    = config_data.f_password or ""
  c_org_id        = config_data.org_id or 0
  c_domain_id_api = config_data.domain_id_api or ""
  c_cat_id        = config_data.cat_id or 0
  c_f_id_api      = config_data.f_id_api or ""
  c_url_api_id    = config_data.url_api_id or ""
else
  teamyar.write_result("پیکربندی این بات انجام نشده است</br>")
  return
end

-- =========================
-- Utils
-- =========================
local function normalize_mobile(m)
  m = tostring(m or "")
  m = m:gsub("[^0-9]", "")  -- فقط عدد

  -- اگر با 98 شروع می‌شود => 0 + ادامه
  if m:sub(1,2) == "98" then
    m = "0" .. m:sub(3)
  end

  -- اگر 10 رقم بود و با 9 شروع شد => 09...
  if #m == 10 and m:sub(1,1) == "9" then
    m = "0" .. m
  end

  -- خروجی معتبر ایران
  if #m == 11 and m:sub(1,2) == "09" then
    return m
  end

  return ""
end

local function pick_mobile()
  -- اولویت: caller_num (طبق لاگ شما) سپس receiver
  local raw = caller_num
  if raw == nil or raw == "" then raw = reciver end
  raw = raw or ""

  teamyar.write_log("raw_mobile -> " .. tostring(raw))

  local m = normalize_mobile(raw)
  teamyar.write_log("mobile(normalized) -> " .. tostring(m))
  return m
end

-- =========================
-- API Call: Get ID by Mobile
-- =========================
local function getIdByMobile(mobile)
  local tempbody = {
    searchKey = mobile
  }

  teamyar.write_log("domain_id_api=" .. tostring(c_domain_id_api) .. " | url_api_id=" .. tostring(c_url_api_id))

  local id_url = 0
  local curl = teamyar.create_curl()

  local ok_conn = curl:connect({ domain = c_domain_id_api, port = 443, ssl = true, secure = false })
  if not ok_conn then
    teamyar.write_log("cannot connect to domain: " .. tostring(c_domain_id_api))
    curl:release()
    return 0
  end

  local request_params = {
    method = "POST",
    url = c_url_api_id,
    data_str = json.encode(tempbody),
    headers = {
      { name = "Accept", value = "application/json" },
      { name = "ApiKey", value = c_tocken },
      { name = "Content-Type", value = "application/json" },
    },
  }

  teamyar.write_log("request_params -> " .. json.encode(request_params))

  local ok_send = curl:sendRequest(request_params)
  teamyar.write_log("sendRequest(ok) -> " .. tostring(ok_send))

  local res = curl:getResponse() or ""
  local status = curl:getStatus() or 0

  teamyar.write_log("status -> " .. tostring(status))
  teamyar.write_log("response(raw) -> " .. tostring(res))

  if status == 200 and res ~= "" then
    local decoded = nil
    pcall(function() decoded = json.decode(res) end)

    if decoded and decoded.data and decoded.data.items and decoded.data.items[1] and decoded.data.items[1].id then
      id_url = decoded.data.items[1].id
      teamyar.write_log("found id_url -> " .. tostring(id_url))
    else
      teamyar.write_log("response JSON missing data.items[1].id")
    end
  else
    teamyar.write_log("http error: status=" .. tostring(status))
  end

  curl:disconnect()
  curl:release()

  -- تبدیل به رشته بدون .0
  id_url = tostring(id_url):gsub('%.0$', "")
  if id_url == "nil" then id_url = "0" end

  return id_url
end

-- =========================
-- MAIN
-- =========================
local mobile = pick_mobile()
if mobile == "" then
  teamyar.write_result("شماره/ورودی معتبر نیست</br>")
  return
end

local hr_id = getIdByMobile(mobile)
teamyar.write_log("hr_id(final) -> " .. tostring(hr_id))

if hr_id == "0" or hr_id == "" then
  teamyar.write_result("شناسه‌ای برای شماره پیدا نشد: " .. mobile .. "</br>")
  return
end

-- ساخت URL iframe
local iframe_url = "https://" .. c_url .. "/" .. hr_id
teamyar.write_log("iframe_url -> " .. iframe_url)

-- iframe با ارتفاع خوب (85vh)
local site = [[
<br><br>
<div style="width:100%;height:90vh;">
  <iframe
    id="content"
    src="]] .. iframe_url .. [["
    style="width:100%;height:100%;border:0;"
    title="content"
    allowfullscreen
  ></iframe>
</div>
]]

teamyar.write_result(site)
