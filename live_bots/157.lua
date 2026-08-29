input = teamyar.get_input();
teamyar.write_log(json.encode(input))

--local comment_add_api = [[{"module_id":14,"path":"/api/client/add/comment"}]]
local add_param = {id=input.idCustomerComment,comment=input.file_content,section_id=input.sectionIdComment};
teamyar.write_log(json.encode(add_param))
local res = teamyar.call_api(14,"/api/client/add/comment", add_param);

if res.success then
	teamyar.write_result("OK")
else
  teamyar.write_result(json.encode(res))
end