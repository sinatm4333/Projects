local input =teamyar.get_input()
teamyar.write_log(json.encode(input))
local crm_id=input.client_id
------------------------------
function queryResult(select_query,user_param)
  db.use_db("0000000");
  local params1 = {
    query = select_query,
    params = user_param
  }
  db.query(params1);
  local res_text = db.query_fetch();
  db.query_free();
  if res_text ~= nil then 
    return res_text[1];
  else 
    return 0 
  end 
end
-----------------------------
local query=[[ select comment from crm_info where id=]]..crm_id
local comment = queryResult(query,{})
comment=string.sub(comment,21,#comment)

local iframe_url = "https://mobile140.com/dashboard/users/customer/" .. comment
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
--teamyar.write_result(comment)