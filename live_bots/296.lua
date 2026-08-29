local module_id = 17
local url = "/api/update_product_can_accept_serial"
local secret_key_fixed = "Tt@123456" --secret_key
---------------------------------------------------------------------------
local params = teamyar.get_input();
local header_secret_key = ""
local content_type = teamyar.get_http_header('secret-key');
if content_type ~= nil and #content_type > 0 then
 header_secret_key= content_type
end
if  secret_key_fixed == header_secret_key then 
  local res =  teamyar.call_api(module_id,  url, params);
      teamyar.write_result(json.encode(res))
else 
  teamyar.write_result("Key Is Invalid..!!")
end





















