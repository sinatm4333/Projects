 input = teamyar.get_input();
 ctype=input.type;
local uinfo=teamyar.get_user_info();
local user_id=uinfo.id;
-----------------------------------------------------------
function getQueryResponse(query,query_params)
db.use_db("0000000")
  local params = {
      query = query,
      params = query_params
  }
  db.query(params);
  local res_text = db.query_fetch();
  db.query_free();
  return res_text[1];
end
-------------------------------
    teamyar.write_log(json.encode(input)); 	 	



--main


if ctype == 3 then 
 local has_club_config=getQueryResponse("select count(*) count  from admin_mem_user_cache_value where user_id="..user_id,{});
 	 local res_data=getQueryResponse([[select JSON_ARRAYAGG(JSON_OBJECT('fname',fname,'mobile',mobile,'email',email,'username',username)) as result from 
    (select p.fullname fname,m.mobile mobile,e.email email, u.username username from profile_main p left join 
    profile_mobile m on p.id=m.user_id left join profile_email e on e.user_id=p.id  left join  admin_user u  on  u.id=p.id where p.id=]]..user_id..[[) tmp]],{})
  teamyar.write_log(json.encode(res_data)); 	
  if res_data==nil then 
    res_data=""
  end
      local listdata = {data=res_data, has_club_config=has_club_config};
  teamyar.write_result(json.encode(listdata));
else 
    local userinfo = teamyar.get_user_info();
	local lang = "English";
	if userinfo.lang_id == 4 then
  		lang = "Persian";
	 end
 	local srlang = "<script src='/bot/run/2/p_1/"..lang..".js'></script>";
	res_data = [[
		<div id='myDiv'></div>
 		 ]]..srlang..[[
       <link href='/bot/run/2/p_1/main.css' rel='stylesheet' /> 
		<script src='/bot/run/2/p_1/main.js'></script>
  
		]];
  	teamyar.write_result(res_data);
end
