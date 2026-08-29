local input = teamyar.get_input();
if #input == 0 then 
          teamyar.write_result("خطا در دریافت ورودی : این بات از طریق رویداد تماس فراخوانی می گردد".."</br>")
end 
local config = teamyar.get_config()
local config_data = {}
local sms_content = ""
if config ~= nil then   
  config_data = config.data
  sms_content = config_data.sms_content
end 
local userId = 0
if input.receiver ~= nil and #input.receiver > 0 then 
  userId= tonumber(input.receiver)
end 
local number = ""
if input.caller_number ~= nil and #input.caller_number > 0 then 
  number = input.caller_number
end 
---------------------------------------main
if userId>0 then 
    local info =	{messages = {{content = sms_content, send_to = {profile_ids = {userId}}}}, module_id = 26}
    local   res = teamyar.call_api(16, '/api/sms/send', info);
    teamyar.write_log(json.encode(res))
elseif #number > 0 then 
      local info =	{messages = {{content = sms_content, send_to = {mobile_numbers = {				
            {
						value= number,
						country=364
					}
          }}}}, module_id = 26}
    local   res = teamyar.call_api(16, '/api/sms/send', info);
    teamyar.write_log(json.encode(res))
end 
