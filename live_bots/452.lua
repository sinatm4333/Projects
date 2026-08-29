local input = teamyar.get_input()
local text = input.content
local number = input.number
local password = ""
local username = ""
local from = 0
local config =teamyar.get_config()
local config_date = {}
if config ~= nil then 
  config_date = config.data
  password = config_date.password
  username = config_date.username
  from = config_date.from
end 
----------------------------------
local data_sms = {to = number, password = password, username = username, from = from, text = text}
  params_file = 
  {
    domain = "rest.payamak-panel.com",
    port = 80,
    url = "/api/SendSMS/SendSMS",
    ssl = false,
    secure = false,
    method = "post",
    data_str = json.encode(data_sms),
    header = {{name = "Content-Type", value = "application/json"}, {name = "Accept", value = "*/*"} }
  }
teamyar.write_log("PP--"..json.encode(params_file))
  local result_file = teamyar.call_url(params_file);
teamyar.write_log("msg--"..json.encode(result_file))
local msg = "Error In Sent SMS"
if result_file.result ~= nil and result_file.result.status ~= nil then 
    if result_file.result.status == 200 then 
 msg = "SMS Sent Successfully"
  else
    msg = "Error In Sent SMS"
end 
else 
    msg = "Error In Sent SMS"
end 
 teamyar.write_result("<div style='width:100%;text-align: center; margin: 28px;'><div style='font-weight:bold;'>"..msg.."</div></div>")