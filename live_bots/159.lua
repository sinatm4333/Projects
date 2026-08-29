  input = teamyar.get_input();

--local input = json.decode(form_param)
--	teamyar.write_result(context,form_param)


local cat_del_api = [[{"module_id":14,"path":"/api/client/category/del"}]]
local cat_add_api = [[{"module_id":14,"path":"/api/client/category/add"}]]
local del_param = string.format([[{"id":%d,"category_id":%d}]], input.client_id, input.old_cat_id);
local add_param = string.format([[{"id":%d,"category_id":%d}]], input.client_id, input.cat_id);

	teamyar.write_log("del_param"..del_param)

	teamyar.write_log("add_param"..add_param)


local res = teamyar.call_api(context ,add_param, cat_add_api);
	teamyar.write_log("res"..res)

res = json.decode(res);

if res.success then

  -- local res = teamyar.call_api(context, del_param, cat_del_api);

  --res = json.decode(res);

  --if res.success then
	teamyar.write_result(context, "OK")
  --else
  --  teamyar.write_result(context, "Not OK")
  --end
else
  teamyar.write_result(context, "Not OK")
end





