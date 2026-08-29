local  input = teamyar.get_input();
local config = teamyar.get_config()
local config_data = {}
local alovoip_id = 0
local username = ""
local password = ""
local org_id = ""
local username_field = ""
local password_field = ""
if config ~= nil then 
  config_data = config.data
end 
if config_data ~= nil then  
  username_field = config_data.username_field
  password_field = config_data.password_field
  org_id =  config_data.org_id
end
if org_id == nil then 
  org_id = 0 
end
local user_info = teamyar.get_user_info()
local user_id = user_info.id
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
  username = res_text[1]
  password = res_text[2]
end
local query_val = [[  with vals as (select cf.name n, cfv.value_ v from hr_per_custom_field_val cfv inner join 
                              hr_personnel_custom_field cf on cf.id=cfv.FIELD_ID where cfv.target_id=(select PERSONNEL_ID from hr_personnels  where profile_id=]]..user_id..[[ 
								and ORG_ID=]]..org_id..[[ ) and cf.ORG_ID=]]..org_id..[[ ) 
                              select 
                              (select v from vals where n=']]..username_field..[[' )username_a,
                              (select v from vals where n=']]..password_field..[['  )pass_a ]]
teamyar.write_log(query_val)
getQueryResponse(query_val,{})
-------------------------
function getTocken2()
  local tocken=""
  local curl = teamyar.create_curl();
  if curl:connect({domain = "voip.bimehland.com", port = 443, ssl = true, secure = false}) then
    local paramsc = {
      method = "POST", 
      url = "/Identity/connect/token", 
      headers = {
        {name = "Accept", value = "*/*"},
      },
      data = {
        {name = "Grant_Type", value = "password"}
     --  ,{name = "username", value = tostring("09112222607")}---username}--
          ,{name = "username", value = username}
   --    ,{name = "password", value = "Aa123456@"}---password}-- 
         ,{name = "password", value = password}
        ,{name = "client_id", value = "STSAdminUIClientId_api"},
       {name = "deviceuid", value = 123}
      }
    };
    if curl:sendRequest(paramsc) then
      if curl:getStatus() == 200 then
        if curl:getResponse() ~= nil then
          tocken = json.decode(curl:getResponse()).access_token
          return tocken
        end
      else
        tocken = ""
      end
    end
    curl:disconnect();
  end
  curl:release();
  return tocken
end

-------------------------------
function changeStatus(tocken, status, user_id)
  teamyar.write_log(status)
  local curl = teamyar.create_curl();
  if curl:connect({domain="voip.bimehland.com", port = 443, ssl = true, secure = false}) then
    local params = {
      method = "POST", 
      url = "/voip/api/telephonysystems/dashboard/ChangeAgentStatus?tsKey=ID&queueMemberStatus="..status, 
      headers = {
        {name = "Accept", value = "*/*"}, {name = "Authorization", value = "Bearer "..tocken}, {name = "Content-Type", value = "application/x-www-form-urlencoded"},
      },
    };
    if curl:sendRequest(params) then
      if curl:getStatus() == 500 then

        local msg =curl:getResponse()
        return msg
      elseif curl:getStatus() == 200 then
        local msg = curl:getResponse()
        return msg
      else
        local msg = json.encode(curl)
        return msg
      end
    end
    curl:disconnect();
  end
  curl:release();
end 

-------------------------------
function getStatus(tocken)
  local curl = teamyar.create_curl();
  curl:debug(true);
  if curl:connect({domain = "voip.bimehland.com", port = 443, ssl = true, secure = false}) then
    local params2 = {
      method = "GET", 
      url = "/voip/api/telephonysystems/dashboard/GetAgentStatus/?tsKey=ID", 
      headers = {
        {name = "Accept", value = "*/*"},
        {name = "Authorization", value = "Bearer "..tocken},
        {name = "Accept-Encoding", value = "gzip, deflate, br"},
        {name = "Connection", value = "keep-alive"},
      },
    };
    if curl:sendRequest(params2) then
      local status_url=curl:getStatus() 
      if status_url == 500 then
        local msg = curl:getResponse()
        return msg
      elseif status_url == 200 then
        local msg = curl:getResponse()
        return msg
      else
        local msg = curl
        return msg
      end
    end
    curl:disconnect();
  end
  curl:release();
end 
----------------------------------------------
local type_input =  input.type;
if type_input == 4 then 
  local tocken_get =  getTocken2()
  local status = getStatus(tocken_get)
  if status== nil then 
    status=0
  end
  local status_str =""
  if status ~= nil and  #(tostring(status))>0 then 
  	if tonumber(status) == -1 or tonumber(status) == 0  then 
    status_str = "Offline"
    else
          status_str=json.decode(status)
 	 end
  end
  teamyar.write_result(json.encode({str_statue = status_str, status = status}));
elseif type_input == 3 then 
  local status=input.alovoip_status
  teamyar.write_log("st---"..status)
  local status_str=""
  if status==1 then 
    status_str="Online"
  elseif status==2 then 
    status_str="Pause"
  elseif status==3 then 
    status_str="Rest"
  elseif status==4 then 
    status_str="Offline"
  end
  local ctocken =  getTocken2()
  local msg =  changeStatus(ctocken, status_str, alovoip_id)
  local res = {msg = msg}
  teamyar.write_result(json.encode(res));
else 
  local userinfo = teamyar.get_user_info();
  local lang = "English";
  if userinfo.lang_id == 4 then
    lang = "Persian";
  end
  local srlang = "<script src='/bot/run/2/change_alovoip_status_3/"..lang..".js'></script>";
  res_data = [[
                    <div id='myDiv'></div>
                    ]]..srlang..[[
                    <link href='/bot/run/2/change_alovoip_status_3/main.css' rel='stylesheet' /> 
                    <script src='/bot/run/2/change_alovoip_status_3/main.js'></script>
                    ]];
  teamyar.write_result(res_data);
end
