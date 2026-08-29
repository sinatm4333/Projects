local  input = teamyar.get_input();
local refrence_id = input.refrence_id
if refrence_id == nil or #refrence_id == 0  then
  refrence_id = 0 
end
local start_d= input.start_d
local end_d= input.end_d
-----------------------------------------------------------
function fileToString(file)
  local str=""
  if file ~= nil and file[1] ~= nil and  file[1].module_id ~= nil and file[1].id ~= nil and file[1].mime ~= nil then
    local file_manager = teamyar.create_file_manager(file[1].module_id);
    str = file_manager:readFile(file[1].id);
    file_manager:release();
  end
  return str
end
--------------------------------------------------------------------get config
local config = teamyar.get_config()
local config_data = {}
local c_url = ""
-- local c_ec_client_id = ""
local c_memory_tax_id = ""
local c_public_key_id = ""
local c_org_id = 0
local private_key = ""
local certificate = ""
if config ~= nil then 
  config_data = config.data
end 
if config_data ~= nil then  
  c_url = config_data.url
  c_memory_tax_id = config_data.memory_tax_id
  c_public_key_id = config_data.public_key_id
  c_org_id = config_data.org_id
  private_key = fileToString(config_data.private_key)
  certificate = fileToString(config_data.certificate)
end
local user_info = teamyar.get_user_info()
teamyar.write_log(json.encode(user_info))
local user_id = user_info.id
local public_key = teamyar.get_attachment('public-key.txt');

--------------------------------
function queryResult(select_query,user_param)
  db.use_db("0000000");
  local params1 = {
    query = select_query,
    params = user_param
  }
  db.query(params1);
  local res_text = db.query_fetch();
  db.query_free();
  return res_text[1];
end
--------------------------------------------------------------------------------
----get nonce
local nonce = 0
local es_str = ""
local curl = teamyar.create_curl();
if curl:connect({domain = c_url, port = 443, ssl = true, secure = false}) then
  local params_no = {
    method = "GET", 
    url = "/requestsmanager/api/v2/nonce?timeToLive=20" ,
    headers = {
      {name = "Accept", value = "*/*"}, 
    },
  };
  if curl:sendRequest(params_no) then
    if curl:getStatus() == 500 then
      local res_nonce = curl:getResponse()
      local msg = json.decode(res_nonce).message
      return ""
    elseif curl:getStatus() == 200 then
      local res_nonce = curl:getResponse()
      nonce = json.decode(res_nonce).nonce

    else
      local res_nonce = curl:getResponse()
      local msg = json.encode(curl)
      return ""
    end
  end
  curl:disconnect();
end
curl:release();   
-------get tocken
local res_str = ""
local day = tostring(time.get_day(time.current()));
local month = tostring(time.get_month(time.current()))
local year = tostring(time.get_year(time.current()));
local min = tostring(time.get_minute(time.current()));
local hour = tostring(time.get_hour(time.current()));
local sec = tostring(time.get_second(time.current()));

local tYear,tMonth,tDay,tHour,tMinute,tSecond = string.match(time.get_str(time.current()),'(%d+).(%d+).(%d+) (%d+):(%d+):(%d+)');
local ddstr= string.format('%.4d-%.2d-%.2dT%.2d:%.2d:%.2dZ',tYear,tMonth,tDay,tHour,tMinute,tSecond)

if #month ==1 then 
  month="0"..month
end
if #day==1 then 
  day="0"..day
end
local date_str = year.."-"..month.."-"..day.."T"..(hour+3)..":"..(min+30)..":"..sec.."Z"
teamyar.write_log("date_str----"..date_str)
local param_jjwt = {
  algorithm = "RS256",
  secret = private_key,
  headers =  { 
    alg = "RS256",
    sigT=   string.format('%.4d-%.2d-%.2dT%.2d:%.2d:%.2dZ',tYear,tMonth,tDay,tHour,tMinute,tSecond),
    crit={"sigT"},
    x5c = {certificate},
  },
  payload = { 
    nonce = nonce,
    clientId =c_memory_tax_id
  }
}
teamyar.write_log("param_jjwt--"..json.encode(param_jjwt))
local ctocken = "Bearer "..coding.jwt(param_jjwt)
teamyar.write_log("ctocken--"..ctocken)
------------------------------------------------------------------------------------------check inquery
local res_inquery ={}
local res_status=0
local curli = teamyar.create_curl();
local status=""
if curli:connect({domain = c_url, port = 443, ssl = true, secure = false}) then
  local params_inq= {
    method = "GET", 
    url = "/requestsmanager/api/v2/inquiry-by-reference-id?referenceIds="..refrence_id, 
    headers = {
      {name = "Accept", value = "*/*"}, 
      {name = "Authorization", value = ctocken },
    },
  };
  local sended = curli:sendRequest(params_inq)
  if sended then
    res_inquery= curli:getResponse()
    res_status= curli:getStatus() 
    teamyar.write_log("eres status--"..json.encode(res_status))
    teamyar.write_log("res_inquery--"..res_inquery)

    if res_status == 500 then
      status="خطا در دریافت استعلام  "
      return ""
    elseif res_status== 200 then
      status=json.decode(res_inquery)[1].status
      teamyar.write_log("status--"..json.encode(status)) 
    else
      status="خطا در ارسال درخواست استعلام  "
      return ""
    end
  end
  curli:disconnect();
end
curli:release();  


if #json.decode(res_inquery)[1].data.error>0  then 
  teamyar.write_log("پیام:"..json.decode(res_inquery)[1].data.error[1].message.."  وضعیت:"..status)
  teamyar.write_result("پیام:"..json.decode(res_inquery)[1].data.error[1].message.."  وضعیت:"..status)
else

  teamyar.write_result("فاکتور با موفقیت در سامانه مودیان ثبت شد")
end

