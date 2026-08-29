local module_id = 9
local url = "/api/message/add"
---------------------------------------------------------------------------
local params = teamyar.get_input();
local res =  teamyar.call_api(module_id,  url, params);
teamyar.write_result(json.encode(res))






















