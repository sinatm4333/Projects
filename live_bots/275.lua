--Bot MT5 Login ProFit By Zmo
input = teamyar.get_input();
local user_info = teamyar.get_user_info();
local user_id = user_info.id;
--local _DOMAIN = "61840556e7b3.sn.mynetname.net";
--local _PASSWORD = "@Mm6617530";
--local _LOGIN = tostring(9111);
--local _VERSION = tostring(484);
local _DOMAIN = input.domain;
local _PASSWORD = input.password;
local _LOGIN = tostring(input.login);
local _VERSION = tostring(input.vertion);
local _PORT = 2500;
local _TYPE = "manager" --"WebManager";
local _AGENT = "test" ;
local connection = {domain= _DOMAIN , port=_PORT, ssl=true, secure=false};
  ---------------------------------------------
  function loadData()
    local data = teamyar.get_data("mt5_lp_data")
    teamyar.write_result(data. value);
  end
-------------------------------
function WidgetTemplate()  
  local random= math.random(1,1000);
  local script =  teamyar.get_attachment("main.js");
  local css =  teamyar.get_attachment("main.css");
  local  str_lang="";
  local str_title="";
  if user_info.lang_id == 4 then
    str_lang = teamyar.get_attachment("Persian.js");
    str_title="طبقه بندی مشتریان (براساس سود معاملات)";
  else
    str_lang = teamyar.get_attachment("English.js");
      str_title="Customer Clissify By Deals Profit "
  end
  local template = teamyar.run_command("2/res_bot",{
      id = "mt5_l_p",
      tpl_name = "html",
      title = str_title,
      body = "<div id=\\'lp_holder_body_html_"..random.."\\'></div>",
      script=[[
      (function(){
      ]]..str_lang..[[   
      var holder_id = '#lp_holder_body_html_]]..random..[[';
      var random_id = ]] .. random .. [[;
      ]]..script..[[
    })();

      ]],
      css=css

    });
  teamyar.write_result(template);

end
---------------------
    ---------------------------------------------
  function ascii_to_utf16le(input)
    local utf16 = {}
    for i = 1, #input do
      local charCode = input:byte(i)

      table.insert(utf16, string.char(charCode))
      table.insert(utf16, string.char(0))
    end
    return table.concat(utf16)
  end
    ---------------------------------------------
  function hex_to_ascii(hex)
    local result = ""
    for i = 1, #hex, 2 do
      local byte = tonumber(hex:sub(i, i+1), 16)
      result = result .. string.char(byte)
    end
    return result
  end
    ---------------------------------------------
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
  ---------------------------------------------
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
    ---------------------------------------------
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
  local curl = nil;
  function apiWithCurl(url , doEnd)
  local code = 0;
  local status = false;
  local response = nil;
  local errorMessage = "";
  local  data2 = teamyar.get_data("mt5_lp_data")
  if connection.domain == nil then 
    connection.domain= data2.value.ddw_domain;
  end 
  local isConnection = true;
  
  if curl == nil  and connection.domain ~= nil then
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

    if curl ~= nil then 
    code = curl:sendRequest(param);
    status = curl:getStatus();
    response = curl:getResponse();
    errorMessage = curl:getErrorMessage();
    end
    --    teamyar.write_result(json.encode(response));
  end
  if doEnd ~= nil and doEnd == true then
    curl:disconnect()
    curl:release();
  end
  return code , status , response , errorMessage;
  end
--main
if input.type == 3 then   
      local chash_data = {mtlp_domain = input.domain, mtlp_ver = input.vertion,mtlp_login=input.login,mtlp_pass=input.pass}

      teamyar.set_data("mt5_lp_data", json.encode(chash_data));

  ---------------------
  --step 1
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
        local err={'error [AUTH_START]: in Get Result | retcode: '..result.retcode,err=3}
        teamyar.write_result(json.encode(err));       
        return false;
      end
    else
      local err={msg='error [AUTH_START]: '..responseStart.result.body,err=2}
      teamyar.write_result(json.encode(err));
      return false;
    end
  else
    local err={msg="ERR_IN_INPUT_INFO",err=1}
    teamyar.write_result(json.encode(err));
    return false;
  end


  --step 2
  local data2 = teamyar.get_data("mt5_lp_data")
  local pp=json.decode(data2.value)
  if _PASSWORD == nil or  _PASSWORD == "null" then 
    _PASSWORD=pp.mtlp_pass;
  end 
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
  local urlAuthAnswer= "/api/auth/answer?srv_rand_answer="..srv_rand_answer.."&cli_rand="..cli_rand ;
  local codeAuthAnswer , statusAuthAnswer , responseAuthAnswer = apiWithCurl(urlAuthAnswer);
  if statusAuthAnswer ~= nil and statusAuthAnswer == 200 and responseAuthAnswer ~= nil then
    local result = toTable(responseAuthAnswer);
    if result ~= nil and result.retcode ~= nil  then
      local status = getStatusRetcode(result.retcode);
      if status == 0 and  result.cli_rand_answer ~= nil then
        auth_answer_answer = result.cli_rand_answer;
      else
        local err={msg='error [AUTH_ANSWER]: in Get Result| retcode: '..result.retcode,err=3}
        teamyar.write_result(json.encode(err));
        return false;
      end
    else
      local err={msg='error [AUTH_ANSWER]: '..result.body,err=3}
      teamyar.write_result(json.encode(err));

      return false;
    end
  else
    local err={msg="ERR_IN_INPUT_INFO",err=1}
    teamyar.write_result(json.encode(err));
    return false;
  end

  --step 5
  local cli_rand_answer = password_hash .. cli_rand;
  cli_rand_answer = hex_to_ascii(cli_rand_answer);
  cli_rand_answer = coding.md5(cli_rand_answer);
  cli_rand_answer = string.lower(cli_rand_answer);
   
--step 6
  local data_list={};
  if cli_rand_answer ~= auth_answer_answer then
    local err={msg="INVALID_CLIENT_ANSWER",err=4}
    teamyar.write_result(json.encode(err));
    return false;
  else
    local urlRequest = "/api/user/logins";
    local codeRequest , statusRequest , responseRequest = apiWithCurl(urlRequest , false);
    local result = {
      code = codeRequest ,
      status = statusRequest ,
      response = responseRequest ,
    };
    local li=json.decode(result.response).answer
    local str_list=""
    for i=1,#li do
      if li[i]~=nil then 
        str_list=str_list..math.floor(json.decode(li[i]))..","
      end
    end
    str_list=string.sub(str_list,1,#str_list-1)-- remove extra ","
    local urlRequest = "/api/user/account/get_batch?login="..str_list
    local codeRequest , statusRequest , responseRequest = apiWithCurl(urlRequest , false);
    local result = {
      code = codeRequest ,
      status = statusRequest ,
      response = responseRequest ,
    };
    local list_deals=json.decode(result.response).answer
    local p_u_list={};
    local max1=0;
    local max2=0;
    local max3=0;
    local login_max1=0;
    local login_ max2=0;
    local login_max3=0;
    for i=1,#list_deals do
      -- teamyar.write_log(json.encode(list_deals[i]))
      local n=tonumber(json.decode( list_deals[i].Profit))
      if  n>max1 then 
        max1=n;
        login_max1=list_deals[i].Login
      end
      table.insert(p_u_list,{profilt=list_deals[i].Profit,login=list_deals[i].Login})
    end

    for i=1,#list_deals do
      local n=tonumber(json.decode( list_deals[i].Profit))
      if  n>max2  and  list_deals[i].Login~=login_max1 then 
        max2=n;
        login_max2= list_deals[i].Login
      end
    end
    for i=1,#list_deals do
      local n=tonumber(json.decode( list_deals[i].Profit))
      if  n>max3  and  list_deals[i].Login~=login_max1 and  list_deals[i].Login~=login_max2 then 
        max3=n;
        login_max3= list_deals[i].Login
      end
    end
    
    local urlRequest = "/api/user/get?login="..login_max1
    local codeRequest , statusRequest , responseRequest = apiWithCurl(urlRequest , false);
    local result = {
      code = codeRequest ,
      status = statusRequest ,
      response = responseRequest ,
    };
    local info1=json.decode(result.response).answer
    local urlRequest = "/api/user/get?login="..login_max2
    local codeRequest , statusRequest , responseRequest = apiWithCurl(urlRequest , false);
    local result = {
      code = codeRequest ,
      status = statusRequest ,
      response = responseRequest ,
    };
    local info2=json.decode(result.response).answer
     -- teamyar.write_log("login"..json.encode(list_deals));
    local urlRequest = "/api/user/get?login="..login_max3
    local codeRequest , statusRequest , responseRequest = apiWithCurl(urlRequest , true);
    local result = {
      code = codeRequest ,
      status = statusRequest ,
      response = responseRequest ,
    };
    local info3=json.decode(result.response).answer
    

	local name1=info1.FirstName.." "..info1.LastName
    	local name2=info2.FirstName.." "..info2.LastName
    	local name3=info3.FirstName.." "..info3.LastName
    table.insert(data_list,{profilt=max1,login=name1})
    table.insert(data_list,{profilt=max2,login=name2})
    table.insert(data_list,{profilt=max3,login=name3})
  end
  teamyar.write_result(json.encode(data_list));
elseif input.type == 2 then 
      loadData()
else 
  WidgetTemplate();
end
