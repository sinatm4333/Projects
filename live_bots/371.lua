local input = teamyar.get_input();
local userId = input.userId
local price = input.price
local serial = input.serialNumber
local comment = input.comment
local user_info = teamyar.get_user_info();
---------------------------------------main
      local content_msg = " Amont "..price.." for "..comment.."  is recived by "..serial.." serial number."
      if user_info.lang_id == 4 then 
       content_msg = " مبلغ "..price.." بابت "..comment.."  با شماره سریال "..serial.." دریافت شد."
      end 
    local info =	{messages = {{content = content_msg, send_to = {profile_ids = {userId}}}}, module_id = 26}
    teamyar.write_log(content_msg)
    local   res = teamyar.call_api(16, '/api/sms/send', info);
    teamyar.write_log(json.encode(res))
