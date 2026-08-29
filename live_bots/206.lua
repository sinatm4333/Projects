--Bot MT5 Daily Deposits & Withdrawals
input = teamyar.get_input();
local user_info = teamyar.get_user_info();
local user_id = user_info.id;
--local _DOMAIN = "61840556e7b3.sn.mynetname.net";
--local _PASSWORD = "@Mm6617530";
--local _LOGIN = tostring(9111);
--local _VERSION = tostring(484);
local _DOMAIN = input.domain;
local _PASSWORD = tostring(input.pass);
local _LOGIN = tostring(input.login);
local _VERSION = tostring(input.vertion);

--teamyar.write_log(json.encode(input))
--teamyar.write_log(json.encode(_VERSION))
--teamyar.write_log(json.encode(_LOGIN))
--teamyar.write_log(json.encode(_DOMAIN))
--teamyar.write_log(_PASSWORD)
--teamyar.write_log("_DOMAIN=".._DOMAIN..",  _PASSWORD=".._PASSWORD..",  _LOGIN=".._LOGIN..",  _VERSION=".._VERSION)
local _PORT = 2500;
local _TYPE = "manager" --"WebManager";
local _AGENT = "test" ;
local curl = nil;
local connection = {domain= _DOMAIN , port=_PORT, ssl=true, secure=false};
---------------------------------------------
function loadData()
  local data = teamyar.get_data("mt5_ddw_data")
  teamyar.write_result(data. value);
end
-------------------------------
function WidgetTemplate2()  
  local random= math.random(1,1000);
  local script =  teamyar.get_attachment("main.js");
  local css =  teamyar.get_attachment("main.css");
  local  str_lang="";
  local str_title="";
  if user_info.lang_id == 4 then
    str_lang = teamyar.get_attachment("Persian.js");
    str_title="گزارش واریز ها و برداشت های روزانه";
  else
    str_lang = teamyar.get_attachment("English.js");
    str_title="Daily Deposits And Withdrawals "
  end
  local template = teamyar.run_command("2/res_bot",{
      id = "ddw_l_p",
      tpl_name = "html",
      title = str_title,
      body = "<div id=\\'ddw_holder_body_html_"..random.."\\'></div>",
      script=[[
      (function(){
      ]]..str_lang..[[   
      var holder_id = '#ddw_holder_body_html_]]..random..[[';
      var random_id = ]] .. random .. [[;
      ]]..script..[[
    })();

      ]],
      css=css
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
  local  data2 = teamyar.get_data("mt5_ddw_data")
    teamyar.write_log("innput "..json.encode(input))
      teamyar.write_log("data2:   "..json.encode(data2))
  if connection.domain == nil then 
    connection.domain= data2.value.ddw_domain;
  end 
  local isConnection = true;
  
  if curl == nil  and connection.domain ~= nil then
    curl = teamyar.create_curl();

    isConnection =  curl:connect(connection)
        teamyar.write_log(json.encode(isConnection))
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

--------------------------
function WidgetTemplate(deposit,widthtrue)
  if widthtrue == nil then 
    widthtrue = 0
  end
  if deposit == nil then 
    deposit = 0
  end
  local user_info = teamyar.get_user_info()
  local lang = user_info["lang_id"]
  local date = ""
  if lang == 4 then 
    date = time.get_shamsi_str(time.current());
  else
    date = time.get_str(time.current());
  end
  --  local output = getData()
  local res = teamyar.run_command("2/res_bot",{
      id = "Daily_Deposits_Withdrawals",
      tpl_name = "chart",
      title = "",
      script='',
      lang=1,
      data=[[()=>{ 
      var data =0;
      return {
      chart: {
      type: 'bar'
    },
      title: {
      text:  ""
    },
      xAxis: {
      categories:  [ty__main.botGetlang('Withdrawals'), ty__main.botGetlang('Deposits')]
    },
      yAxis: {
      min: 0,
      title: {
      text: ""
    }
    },
      legend: {
      reversed: true
    },
      plotOptions: {
      series: {
      stacking: 'normal',
      dataLabels: {
      enabled: true
    }
    }
    },
      series: [{
      name: ty__main.botGetlang('Price'),
      data: []]..deposit..[[, ]]..widthtrue..[[]
    }]

    }
    }]]

    });
  teamyar.write_result(res);
end
---------------------
function getDepositAndWithdraw(input_login,input_ver,input_pass)
  local data_list = {};
  local srv_rand = "";
  local urlAuthStart = "/api/auth/start?version="..input_ver.."&agent=".._AGENT.."&type=".._TYPE.."&login="..input_login;
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
  local password_hash = ascii_to_utf16le(input_pass);
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
    local urlRequest = "/api/user/logins";
    local codeRequest , statusRequest , responseRequest = apiWithCurl(urlRequest , false);
    local result = {
      code = codeRequest ,
      status = statusRequest ,
      response = responseRequest ,
    };
    local li = json.decode(result.response).answer
    local str_list = ""
    for i = 1, #li do
      if li[i] ~= nil then 
        str_list = str_list..math.floor(json.decode(li[i]))..","
      end
    end 
    str_list = string.sub(str_list,1,#str_list-1)-- remove extra ","
    teamyar.write_log("login list:  "..json.encode(str_list))
    local day = time.get_day(time.current());
    local month = time.get_month(time.current());
    local year = time.get_year(time.current());
    local temp_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":0,"minute":0,"second":0}]])
    currentdate = string.format("%18.0f", temp_time);
    local tf=tostring(time.get_unixtime(currentdate))
    local tt=tostring(time.get_unixtime(time.current() + (60 * 60 * 60 * 10000000)));
    tt=string.sub(tt,1,#tt-2)
    tf=string.sub(tf,1,#tf-2)
    local urlRequest = "/api/trade/balance?login="..str_list
    local codeRequest , statusRequest , responseRequest = apiWithCurl(urlRequest , flase);
    local result = {
      code = codeRequest ,
      status = statusRequest ,
      response = responseRequest ,
    };
    local last_ticket = json.decode(result.response).answer
        teamyar.write_log("last ticket:  "..json.encode(last_ticket))
    local list_ticket=""
    for i = 1,200 do
      list_ticket=list_ticket..tonumber(last_ticket.ticket)-i..","
    end
    list_ticket = string.sub(list_ticket,1,#list_ticket-1)-- remove extra ","
    local urlRequest = "/api/deal/get_batch?from="..tf.."&to="..tt.."&ticket="..list_ticket
    local codeRequest , statusRequest , responseRequest = apiWithCurl(urlRequest , true);
    local result = {
      code = codeRequest ,
      status = statusRequest ,
      response = responseRequest ,
    };
    local lists = json.decode(result.response).answer

    local sum_deposit = 0;
    local sum_widtd = 0;
        local sum_str = "";
    local str = ""
    for i = 1,#lists do
      str = str..lists[i].Deal.." , "
      if lists[i].Time>=tf  and lists[i].Action=="2" then 
     if tonumber(lists[i].Profit) > 0 then 
          sum_deposit = sum_deposit + math.abs (lists[i].Profit)
  elseif tonumber(lists[i].Profit) < 0 then 
                        --    teamyar.write_log("wit:  "..json.encode( lists[i].Profit).." ticket: "..json.encode(lists[i].Deal))
       sum_widtd = sum_widtd +math.abs (lists[i].Profit)
        end 
      end

    end
    table.insert(data_list, {err = "", deposit = sum_deposit, withdraw = sum_widtd})
  end
  return data_list;
end
-------------------------------------------main
if input.type== nil then
  input.type=1
end
if input.type == 3 then   
  local chash_data = {ddw_domain = input.domain, ddw_ver = input.vertion, ddw_login = input.login, ddw_pass = input.pass}
  teamyar.set_data("mt5_ddw_data", json.encode(chash_data));
  --step 1
  local res=getDepositAndWithdraw(input.login, input.vertion, input.pass)
  teamyar.write_result(json.encode(res));
elseif input.type == 2 then 
  loadData()
else 
  WidgetTemplate2()  
  data = teamyar.get_data("mt5_ddw_data")
  local d="";
  if(data ~= nil and data.value ~= nil and data.value ~= "") then
    teamyar.write_log(json.encode(data))
 	 d=json.decode(data.value)
  end
  local input_login = d.ddw_login;
  local input_ver = d.ddw_ver;
  local input_pass = d.ddw_pass;
  if input_login ~= nill and input_ver~= nil and  input_pass~= nil and  input_login ~= "" and input_ver ~= "" and input_pass ~= "" then
    local res=getDepositAndWithdraw(input_login, input_ver, input_pass)
    WidgetTemplate(res[1].deposit, res[1].withdraw);
  else
    WidgetTemplate(0,0);  
  end
end
