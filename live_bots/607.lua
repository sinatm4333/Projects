--------------------------------------------
--- SMS API Caller Bot
--- Module: 9_Sms
--- Type: [api]
--------------------------------------------

function api()
  local inputs = teamyar.get_input();
  local form = inputs.form;
  local to = inputs.to;
  local content = inputs.content;
  
  -- Call Teamyar SMS API (RECEIVE messages)
  -- Documentation: from, content, to (all optional strings)
  local yyy={
    from = form,    -- شماره فرستنده (فیلتر)
    to = to,        -- شماره گیرنده (فیلتر)
    content = content  -- فیلتر متن (اختیاری)
  }
  local api_result = teamyar.call_api(16, "/api/sms/receive", yyy);
   teamyar.write_log("item---"..json.encode(yyy))
  -- Log inputs using teamyar.write_log (visible in history tab)
  teamyar.write_log("[SMS API] From: " .. form .. ", To: " .. to .. ", Content: " .. content);
  
  -- Log API response
  teamyar.write_log("[SMS API] Response: " .. json.encode(api_result));
  
  return api_result;
end

--------------------------------------------
--- Manager (single execution path - no type check needed)
--------------------------------------------
local result = api();
teamyar.write_result(json.encode(result));
