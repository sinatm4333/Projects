--Bot MAx Deposit Report  by zmo
--ver 001
--2024-4-18
input = teamyar.get_input();
local user_info = teamyar.get_user_info();
local user_id = math.floor(user_info["id"]); 
local season = input.season;
if season == nil then
  season=0;
end
local _DOMAIN = "61840556e7b3.sn.mynetname.net";
local _PASSWORD = "@Mm6617530";
local _LOGIN = tostring(9111);
local _VERSION = tostring(484);
local _PORT = 2500;
local _TYPE = "manager" --"WebManager";
local _AGENT = "test" ;
local curl = nil;
local connection = {domain= _DOMAIN , port=_PORT, ssl=true, secure=false};
---------------------------------------------
function loadData()
  local data = teamyar.get_data("mda_data")
  teamyar.write_result(data. value);
end
---------------------------------------------
function getThisYear()
  local thisYear = time.get_year(time.current());
  local thisMonth = time.get_month(time.current());
  local thisDay = time.get_day(time.current())
  local data ={
    year = thisYear ,
    month = thisMonth ,
    day = thisDay ,
  }
  local timeShamsi = time.to_jalali(data);
  if timeShamsi.year ~= nil then
    thisYear = timeShamsi.year;
  else
    thisYear = 1402;
  end
  return thisYear;
end
-----------------------------------------------------------
function getQueryResponse(query,query_params)
  db.use_db("0000000")
  local params = {
    query = query,
    params = query_params
  }
  db.query(params);
  local record={};
  local result={};
  while db.query_fetch(record) do
    table.insert(result,{id=record[1]});
  end
  db.query_free();
  return result;
end

-----------------------------------------------
function WidgetTemplate()  
  local random = math.random(1,1000);
  local script =  teamyar.get_attachment("main.js");
  local css =  teamyar.get_attachment("main.css");
  local  str_lang = "";
  local  str_title = "";
  local user_info = teamyar.get_user_info();
  if user_info.lang_id == 4 then
    str_lang = teamyar.get_attachment("Persian.js");
    str_title="بیشترین مبالغ واریزی برای افتتاح حساب "
  else
    str_lang = teamyar.get_attachment("English.js");
    str_title="Max Deposit Report"
  end
  local template =  teamyar.run_command("2/res_bot",{
                                                                                        id = "bot_max_deposit",
                                                                                        tpl_name = "html",
                                                                                        title = str_title,
                                                                                        body = "<div id=\\'mda_holder_body_html_"..random.."\\'></div>",
                                                                                        script=[[
                                                                                        (function(){
                                                                                        ]]..str_lang..[[      
                                                                                        var holder_id = '#mda_holder_body_html_]]..random..[[';
                                                                                        var random_id = ]] .. random .. [[;
                                                                                        ]]..script..[[
                                                                                      })();
                                                                                        ]],
                                                                                        css = css
                                                                                      });
  teamyar.write_result(template);
end
---------------------
function ascii_to_utf16le(input)
  local utf16 = {}
  for i = 1, #input do
    local charCode = input:byte(i)
    table.insert(utf16, string.char(charCode))
    table.insert(utf16, string.char(0))
  end
  return table.concat(utf16)
end
---------------------------
function hex_to_ascii(hex)
  local result = ""
  for i = 1, #hex, 2 do
    local byte = tonumber(hex:sub(i, i+1), 16)
    result = result .. string.char(byte)
  end
  return result
end
---------------------------
function bin_to_hex(binary_data)
  local hex_table = {
    "0", "1", "2", "3", "4", "5", "6", "7",
    "8", "9", "a", "b", "c", "d", "e", "f"
  }

  local hex_string = ""
  for i = 1, #binary_data do
    local byte = string.byte(binary_data, i)
    local first_half = hex_table[math.floor(byte / 16) + 1]
    local second_half = hex_table[(byte % 16) + 1]
    hex_string = hex_string .. first_half .. second_half
  end

  return hex_string
end
---------------------------
function random_bytes(length)
  local random_bytes = {}
  for i = 1, length do
    local random_byte = math.random(0, 255)
    table.insert(random_bytes, string.char(random_byte))
  end
  return table.concat(random_bytes)
end
---------------------
function getStatusRetcode(retcode)
  return tonumber(retcode:match("(%d+)"));
end
---------------------
function toTable(data , default)
  if type(data) == "table" then
    return  data;
  elseif type(data) == "string" then
    return stringToTable(data , default);
  end
  if default == nil then
    return {};
  else
    return default;
  end
end
---------------------------
function stringToTable(dataString , default)
  if pcall(function() return  json.decode(dataString) end) == true then
    return  json.decode(dataString)
  end

  if default == nil then
    return {};
  else
    return toTable(default);
  end
end
---------------------
function apiWithCurl(url , doEnd )
  local code = 0;
  local status = false;
  local response = nil;
  local errorMessage = "";

  local isConnection = true;
  if curl == nil then
    curl = teamyar.create_curl();
    isConnection =  curl:connect(connection)
  end

  if isConnection then
    local param = {
      method = "GET",
      url = url,
      headers={
        {name = 'Accept', value = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7'},
        {name = 'Referer', value = 'https://www.teamyar.com/fa/'},
        {name = 'User-Agent', value = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36'}
      }
    };

    code = curl:sendRequest(param);
    status = curl:getStatus();
    response = curl:getResponse();
    errorMessage = curl:getErrorMessage();
  end
  if doEnd ~= nil and doEnd == true then
    curl:disconnect()
    curl:release();
  end
  return code , status , response , errorMessage;
end

--------------------------
function getDeposits(logins)
  local max_deposit =0
  local data_list = {};
  local srv_rand = "";
  local urlAuthStart = "/api/auth/start?version=".._VERSION.."&agent=".._AGENT.."&type=".._TYPE.."&login=".._LOGIN;
  local codeAuthStart , statusAuthStart , responseAuthStart = apiWithCurl(urlAuthStart );
  if statusAuthStart ~= nil and statusAuthStart == 200 and responseAuthStart ~= nil then
    local result = toTable(responseAuthStart);
    if result ~= nil and result.retcode ~= nil  then
      local status = getStatusRetcode(result.retcode);
      if status == 0 and result.srv_rand ~= nil then
        srv_rand = result.srv_rand;
      else
        table.insert(data_list, {err = "ERR_AUTH_START", deposit = sum_deposit, withdraw = sum_widtd})     
        return data_list;
      end
    else
      table.insert(data_list, {err = "ERR_AUTH_START", deposit = sum_deposit, withdraw = sum_widtd})
      return data_list
    end
  else
    table.insert(data_list, {err = "ERR_IN_INPUT_INFO", deposit = sum_deposit, withdraw = sum_widtd})
    return data_list;
  end

  --step 2
  local password_hash = ascii_to_utf16le(_PASSWORD);
  password_hash = coding.md5(password_hash);
  password_hash = string.lower(password_hash);
  password_hash = hex_to_ascii(password_hash);
  password_hash = password_hash .. "WebAPI";
  password_hash = coding.md5(password_hash);
  password_hash = string.lower(password_hash);

  --step 3
  local srv_rand_answer = password_hash .. srv_rand;
  srv_rand_answer = hex_to_ascii(srv_rand_answer);
  srv_rand_answer = coding.md5(srv_rand_answer);
  srv_rand_answer = string.lower(srv_rand_answer);

  --step 4
  local auth_answer_answer = "";
  local cli_rand_buf = random_bytes(16);
  local cli_rand = bin_to_hex(cli_rand_buf);
  local urlAuthAnswer = "/api/auth/answer?srv_rand_answer="..srv_rand_answer.."&cli_rand="..cli_rand ;
  local codeAuthAnswer , statusAuthAnswer , responseAuthAnswer = apiWithCurl(urlAuthAnswer);
  if statusAuthAnswer ~= nil and statusAuthAnswer == 200 and responseAuthAnswer ~= nil then
    local result = toTable(responseAuthAnswer);
    if result ~= nil and result.retcode ~= nil  then
      local status = getStatusRetcode(result.retcode);
      if status == 0 and  result.cli_rand_answer ~= nil then
        auth_answer_answer = result.cli_rand_answer;
      else
        table.insert(data_list, {err = "ERR_AUTH_ANSWER", deposit = sum_deposit, withdraw = sum_widtd})
        return data_list;
      end
    else
      table.insert(data_list, {err = "ERR_AUTH_ANSWER", deposit = sum_deposit, withdraw = sum_widtd})
      return data_list;
    end
  else
    table.insert(data_list, {err = "ERR_IN_INPUT_INFO", deposit = sum_deposit, withdraw = sum_widtd})
    return data_list;
  end

  --step 5
  local cli_rand_answer = password_hash .. cli_rand;
  cli_rand_answer = hex_to_ascii(cli_rand_answer);
  cli_rand_answer = coding.md5(cli_rand_answer);
  cli_rand_answer = string.lower(cli_rand_answer);

  --step 6
  if cli_rand_answer ~= auth_answer_answer then
    table.insert(data_list, {err = "ERR_INVALID_CLIENT_ANSWER", deposit = sum_deposit, withdraw = sum_widtd})
    return data_list;
  else
    local urlRequest = "/api/user/get_batch?login="..logins;
    local codeRequest , statusRequest , responseRequest = apiWithCurl(urlRequest , false);
    local result = {
      code = codeRequest ,
      status = statusRequest ,
      response = responseRequest ,
    };
    local li = json.decode(result.response).answer
    if  li ~=  nil  then 
      for i = 1, #li do
        if li[i] ~= nil and tonumber(li[i].Credit)>tonumber(max_deposit) then 
          max_deposit= li[i].Credit
        end
      end 
    end
  end
  
  return max_deposit;
end
---------------------main
if input.type == 3 then 
  loadData()
elseif input.type == 2 then 
  orgAcl(input.data)
elseif input.type == 1 then 
  local chash_data = {mda_season = season, mda_sn = input.sn}
  teamyar.set_data("mda_data", json.encode(chash_data));
  local login_str="";
  local month_str = ""

  season=input.season;
  if season == 1 then
    month_str = "1,2,3"
  end
  if season == 2 then
    month_str = "4,5,6"
  end
  if season == 3 then
    month_str = "7,8,9"
  end
  if season == 4 then
    month_str = "10,11,12"
  end
  local year = time.get_year(time.current());
  local  str_m = "Gmonth";
  local sre_year = "gyear"
  if user_info.lang_id == 4 then
    str_m = "jmonth";
    year_str = "jyear";
    year = getThisYear();
  end
  local str_query = [[  select value_char from CRM_FIELD_EXT_VALUE  v inner join crm_field_ext ex on ex.id=v.field_id where ex.name='Account'                               
                                  and client_id in (select c.id from crm_info c  inner join  crm_ty_permission p on p.id=c.id where    DELETED=0 and p.perm=4
                                  and p.type=2 and   (select ]]..str_m..[[ from report_dimdate where run_date>=datekey and 
                                  run_date<=(datekey+(24*60*60*10000000)) limit 1)in (]]..month_str..[[) 
                                  and (select ]]..year_str..[[ from report_dimdate where run_date>=datekey and run_date<=(datekey+(24*60*60*10000000)) limit 1)=]]..year..[[  
                                ) ]]

  local res1 =  getQueryResponse(str_query, {});
  local str_logins="";
  for i = 1, #res1 do
    str_logins = str_logins..res1[i].id..","
  end 
  str_logins = string.sub(str_logins,1,#str_logins-1)-- remove extra ","
  local max_deposit=getDeposits(str_logins)
  if max_deposit == nil then 
    max_deposit = 0;
  end
  data = {count = #res1, max_deposit =max_deposit}
  teamyar.write_result(json.encode(data))
else
  WidgetTemplate()
end
