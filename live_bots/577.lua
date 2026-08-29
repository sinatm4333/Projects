local input = teamyar.get_input();
local referenceNumber = input.referenceNumber
local in_invoice_id = input.invoice_id
local in_org_id = input.org_id
-----------------------------------------------------------
function fileToString(file)
  local str = ""
  if file ~= nil and file[1] ~= nil and file[1].module_id ~= nil and file[1].id ~= nil and file[1].mime ~= nil then
    local file_manager = teamyar.create_file_manager(file[1].module_id);
    str = file_manager:readFile(file[1].id);
    file_manager:release();
  end
  return str
end
--------------------------------------------------------------------get config
local config = teamyar.get_config()
local config_data = {}
local c_url = ""
local c_memory_tax_id = ""

local private_key = ""
local certificate = ""
if config ~= nil then
  config_data = config.data
end
if config_data ~= nil then
  c_url = config_data.url
  c_memory_tax_id = config_data.memory_tax_id
  private_key = fileToString(config_data.private_key)
  certificate = fileToString(config_data.certificate)
end
local user_info = teamyar.get_user_info()
--teamyar.write_log(json.encode(user_info))
local user_id = user_info.id

--------------------------------------------------------------------------------
-- get nonce + token
function gettocken()
  local nonce = 0
  local curl = teamyar.create_curl();
  if curl:connect({domain = c_url, port = 443, ssl = true, secure = false}) then
    local params_no = {
      method = "GET",
      url = "/requestsmanager/api/v2/nonce?timeToLive=200",
      headers = {
        {name = "Accept", value = "*/*"},
      },
    };
    if curl:sendRequest(params_no) then
      if curl:getStatus() == 500 then
        local res_nonce = curl:getResponse()
        --teamyar.write_log("nonce error: " .. tostring(res_nonce))
        curl:disconnect();
        curl:release();
        return ""
      elseif curl:getStatus() == 200 then
        local res_nonce = curl:getResponse()
        nonce = json.decode(res_nonce).nonce
      else
        local res_nonce = curl:getResponse()
        --teamyar.write_log("nonce status: " .. tostring(curl:getStatus()) .. " res: " .. tostring(res_nonce))
        curl:disconnect();
        curl:release();
        return ""
      end
    end
    curl:disconnect();
  end
  curl:release();

  -- build JWT token
  local tYear, tMonth, tDay, tHour, tMinute, tSecond = string.match(time.get_str(time.current()), '(%d+).(%d+).(%d+) (%d+):(%d+):(%d+)');
  local sigT = string.format('%.4d-%.2d-%.2dT%.2d:%.2d:%.2dZ', tYear, tMonth, tDay, tHour, tMinute, tSecond);
  --teamyar.write_log("sigT----" .. sigT)

  local param_jjwt = {
    algorithm = "RS256",
    secret = private_key,
    headers = {
      alg = "RS256",
      sigT = sigT,
      crit = {"sigT"},
      x5c = {certificate},
    },
    payload = {
      nonce = nonce,
      clientId = c_memory_tax_id
    }
  }
 -- teamyar.write_log("param_jjwt--" .. json.encode(param_jjwt))
  local ctocken = "Bearer " .. coding.jwt(param_jjwt)
  --teamyar.write_log("ctocken--" .. ctocken)
  return ctocken
end
------------------------------------------
function safeJsonDecode(value)
  if value == nil or type(value) ~= "string" or value == "" then
    return nil
  end
  local ok, decoded = pcall(json.decode, value)
  if ok and decoded ~= nil then
    return decoded
  end
  return nil
end

----------------------------------------------
function inquery(refrence_id)
  local ctocken = gettocken()
  if ctocken == "" then
    return "خطا در دریافت توکن"
  end

  local res_inquery = ""
  local res_status = 0
  local curli = teamyar.create_curl();
  local status = ""

  if curli:connect({domain = c_url, port = 443, ssl = true, secure = false}) then
    local params_inq = {
      method = "GET",
      url = "/requestsmanager/api/v2/inquiry-by-reference-id?referenceIds=" .. refrence_id,
      headers = {
        {name = "Accept", value = "*/*"},
        {name = "Authorization", value = ctocken},
      },
    };
    local sended = curli:sendRequest(params_inq)
    if sended then
      res_inquery = curli:getResponse()
      res_status = curli:getStatus()
      teamyar.write_log("inquery status=" .. tostring(res_status) .. " response=" .. tostring(res_inquery))

      if res_status == 500 then
        status = "خطا در دریافت استعلام"
      elseif res_status == 200 then
        local decoded_inquery = safeJsonDecode(res_inquery)
        if decoded_inquery ~= nil and type(decoded_inquery) == "table" and decoded_inquery[1] ~= nil and type(decoded_inquery[1]) == "table" then
          status = tostring(decoded_inquery[1].status or "")
          teamyar.write_log("inquery result status=" .. status)
        else
          status = "پاسخ استعلام معتبر نیست"
        end
      else
        status = "خطا در ارسال درخواست استعلام"
      end
    else
      status = "خطا در ارسال درخواست"
    end
    curli:disconnect();
  else
    status = "خطا در اتصال به سرور"
  end
  curli:release();

  -- parse response for error/message
  local msg_modian = ""
  local decode_res = nil
  local decoded_inquery_response = safeJsonDecode(res_inquery)
  if decoded_inquery_response ~= nil and type(decoded_inquery_response) == "table" and decoded_inquery_response[1] ~= nil and type(decoded_inquery_response[1]) == "table" then
    decode_res = decoded_inquery_response[1]
    if decode_res.data ~= nil and type(decode_res.data) == "table" then
      if decode_res.data.error ~= nil and type(decode_res.data.error) == "table" then
        if decode_res.data.error[1] ~= nil and type(decode_res.data.error[1]) == "table" and decode_res.data.error[1].message ~= nil then
          msg_modian = tostring(decode_res.data.error[1].message)
        end
      elseif decode_res.data.message ~= nil then
        msg_modian = tostring(decode_res.data.message)
      end
    elseif decode_res.data ~= nil then
      msg_modian = tostring(decode_res.data)
    end
  end
 -- teamyar.write_log("invoice_id----"..json.encode(in_invoice_id))  -- log to invoice history
  if in_invoice_id ~= nil then
    local info_log = {
      org_id = in_org_id,
      history = "استعلام فاکتور از سامانه مودیان<br>وضعیت: " .. status .. "<br>پیام:<div id='res_inquery'>" .. msg_modian .. "</div>",
      invoice_id = in_invoice_id
    }
    teamyar.write_log("info_log----"..json.encode(info_log))
   local res_history =  teamyar.call_api(23, '/api/sales/update_invoice_history', info_log);
    teamyar.write_log("res_history----"..json.encode(res_history))
  end

  -- build output string
  local res_inquery_str = ""
  if status == "NOT_FOUND" then
    res_inquery_str = "وضعیت استعلام نامعلوم لطفا بعد از چند دقیقه مجددا تلاش کنید. وضعیت: " .. status
  elseif decode_res ~= nil and type(decode_res) == "table" and decode_res.data ~= nil and type(decode_res.data) == "table"
    and decode_res.data.error ~= nil and type(decode_res.data.error) == "table" and #decode_res.data.error > 0 then
    if decode_res.data.error[1] ~= nil and type(decode_res.data.error[1]) == "table" and decode_res.data.error[1].message ~= nil then
      res_inquery_str = tostring(decode_res.data.error[1].message) .. " وضعیت: " .. status
    else
      res_inquery_str = "خطای نامشخص در استعلام وضعیت: " .. status
    end
  elseif decode_res ~= nil and type(decode_res) == "table" and decode_res.data == nil then
    res_inquery_str = "استعلام انجام شد وضعیت " .. status
  elseif msg_modian ~= "" then
    res_inquery_str = msg_modian .. " وضعیت: " .. status
  else
    res_inquery_str = "عدم وجود خطا وضعیت: " .. status
  end
  return res_inquery_str
end

----------------------------------------------
-- main
if referenceNumber ~= nil and tostring(referenceNumber) ~= "" then
  local res_inquery = inquery(referenceNumber)
  teamyar.write_result(res_inquery)
else
  teamyar.write_result("شماره مرجع برای استعلام ارسال نشده است")
end
