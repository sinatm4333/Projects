 local input = teamyar.get_input();
local uinfo = teamyar.get_user_info();
local user_id = uinfo.id;

local day = time.get_day(time.current());
local month = time.get_month(time.current());
local year = time.get_year(time.current());
local hour = time.get_hour(time.current());
local min = time.get_minute (time.current());
local sec = time.get_second(time.current());
local currentdate_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":]]..hour..[[,"minute":]]..min..[[,"second":]]..sec..[[}]])
local temp_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":0,"minute":0,"second":0}]])
local currentdate = string.format("%18.0f" ,temp_time);
--------------------------------------
function convertToFarsi(input,lang_id)
    local farsiNumbers = {}
  if lang_id==4 then 
    farsiNumbers = {
  [0] = "۰",
  [1] = "۱",
  [2] = "۲",
  [3] = "۳",
  [4] = "۴",
  [5] = "۵",
  [6] = "۶",
  [7] = "۷",
  [8] = "۸",
  [9] = "۹"
}
  else
        farsiNumbers = {
  [0] = "0",
  [1] = "1",
  [2] = "2",
  [3] = "3",
  [4] = "4",
  [5] = "5",
  [6] = "6",
  [7] = "7",
  [8] = "8",
  [9] = "9"
}
  end
  local farsiNumber = ""
  local isNegative = false

  if type(input) == "number" then
    input = input / 10
  elseif type(input) == "string" then
    if input:sub(1, 1) == "-" then
      isNegative = true
      input = input:sub(2)
    end
  else
    return nil
  end

  local inputValue = tonumber(input) or tonumber(input:match("%-?%d+%.?%d*"))

  if inputValue < 0 then
    isNegative = true
    inputValue = -inputValue
  end

  local inputStr = tostring(inputValue)
  inputStr = inputStr:gsub("%.", "")
  inputStr = tostring(math.floor(tonumber(inputStr) + 0.5))

  local separatedDigits = ""
  local digitCount = 0
  for i = #inputStr, 1, -1 do
    separatedDigits = farsiNumbers[tonumber(inputStr:sub(i, i))] .. separatedDigits
    digitCount = digitCount + 1

    if digitCount % 3 == 0 and i > 1 and #inputStr ~= 4 then
      separatedDigits = "," .. separatedDigits
    end
  end

  if isNegative then
    separatedDigits = "-" .. separatedDigits
  end
  farsiNumber = separatedDigits
  return farsiNumber
end
-------------------------------------------
function queryResult(select_query,user_param)
  db.use_db("0000000");
  local params1 = {
    query = select_query,
    params = user_param
  }
  db.query(params1);
  local res_text = db.query_fetch();
  db.query_free();
  if res_text == nil then 
    return nil
  end 
  return res_text[1];
end
-----------------------------------------
function queryResultdates(query, query_params)
  db.use_db("0000000")
  local params = {
    query = query,
    params = query_params
  }
  db.query(params);
  local res_text = {};
  local record = {};
  while db.query_fetch(record) do
    table.insert(res_text, { ds = record[1], de = record[2] });
  end
  db.query_free();
  return res_text;
end
-----------------------------------------------
local res_str=""
local remainded = 0;
local org_id=queryResult([[  select val  from pa_ty_config where name='portal_default_org' ]],{})
local client_id=queryResult([[ select id from pa_client where REFFERE_ID= ]]..user_id,{})
local dates = queryResultdates([[select  START_DATE, END_DATE from pa_fiscal_year where org_id=]]..org_id..[[ and ]]..currentdate..[[  between  START_DATE and END_DATE ]],{})
teamyar.write_log(json.encode(dates))
local info_remainded = {
	id = client_id,
	type = 2,
	org_id = org_id,
	end_date =  dates[1].de,
	symbol_id = 0,
	start_date = dates[1].ds
}
teamyar.write_log(json.encode(info_remainded))
 local response = teamyar.call_api(10, "/api/account_info/get", info_remainded);
teamyar.write_log(json.encode(response))
remainded=convertToFarsi( response.data.total_remain,uinfo.lang_id)
if uinfo.lang_id == 4 then
  res = [[ <div style='color:blue;font-size:14px;font-weight:bold;'>مانده حساب مشتری : </div><br><div style='color:blue;font-size:17px;'>]]..remainded..[[</div>]]
else
    res = [[ <div style='color:blue;font-size:14px;font-weight:bold;'>Your Remainded Aomunt Is : </div><br><div style='color:blue;font-size:17px;'>]]..remainded..[[</div>]]
end
teamyar.write_result(res)
