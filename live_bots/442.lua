local  input = teamyar.get_input();
local config = teamyar.get_config()
local day = time.get_day(time.current());
local month = time.get_month(time.current());
local year = time.get_year(time.current());
local hour = time.get_hour(time.current());
local min = time.get_minute (time.current());
local sec = time.get_second(time.current());
local currentdate_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":]]..hour..[[,"minute":]]..min..[[,"second":]]..sec..[[}]])
local temp_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":0,"minute":0,"second":0}]])

local currentdate = string.format("%18.0f" ,temp_time);
local config_data = {}
local c_box_id = 0 
--local c_email_content = ""
local c_email_subject = ""
local c_sms_box_id =0 
if config ~= nil then 
  config_data = config.data
  c_box_id = config_data.box_id
  --- c_email_content = config_data.email_content
  c_email_subject = config_data.email_subject
  c_sms_box_id = config_data.sms_box_id
end 
local user_info = teamyar.get_user_info()
local user_id = user_info.id
-----------------------------------------------------------
function getQueryResponse(query,query_params)
  --teamyar.write_log(query)
  db.use_db("0000000")
  local params = {
    query = query,
    params = query_params
  }
  db.query(params);
  local res_text = db.query_fetch();
  db.query_free();
  if res_text~= nil then 
    return res_text[1]
  else
    return nil
  end
end
   local farsidate = getQueryResponse([[select JNDATE from  report_dimdate where ]]..currentdate..[[  between DATEKEY and DATEKEY+(60*60*24*10000000) ]],{})
-------------------------------------------
function queryResultCrm(select_query,user_param)
  db.use_db("0000000")
  local params = {
    query = select_query,
    params = user_param
  }
  db.query(params);
  local res_text={};
  local record={};
  while db.query_fetch(record) do
    table.insert(res_text, {id = record[1], name = record[2], mobile = record[3], email = record[4], city = record[5], gender = record[6]});
  end
  db.query_free();
  return res_text;
end

-------------------------------------------
function queryResultAcl(select_query,user_param)
  db.use_db("0000000")
  local params = {
    query = select_query,
    params = user_param
  }
  db.query(params);
  local res_text={};
  local record={};
  while db.query_fetch(record) do
    table.insert(res_text, {id = record[1], name = record[2], type =1});
  end
  db.query_free();
  return res_text;
end


--------------------------------------------
function getAclClients(data)
  local query_param = [[      select  distinct c.id, p.fullname from crm_info c inner join profile_main p on p.id=c.id where 1=1  ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  and p.fullname like N'%]]..data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end
----------------------------------------------
function getAclCategory(data)

  local query_param = [[      select  distinct id, name from  crm_classify_person where 1=1  ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  and name like N'%]]..data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end
----------------------------------------------
function getAclSection(data)
  local query_param = [[      select  distinct id, SECTION_NAME from  crm_section where 1=1  ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  and SECTION_NAME like N'%]]..data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end
----------------------------------------------
function getAclCountry(data)
  local query_param = [[      select  distinct id, NAME_P from  report_country where 1=1  ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  and NAME_P like N'%]]..data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end
----------------------------------------------
function getAclState(data)
  local query_param = [[      select  distinct state id, state from  profile_user_address where state<> "" and state is not null  ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  and state like N'%]]..data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end
----------------------------------------------
function getAclCity(data)
  local query_param = [[      select  distinct city id, city from  profile_user_address where city<> "" and city is not null  ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  and city like N'%]]..data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  -- teamyar.write_log(query_param)
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end
----------------------------------------------
function getAclKind(data)
  local table = {
    {id =1, name = "حقیقی"},
    {id = 2, name = "حقوقی"},
  }
  teamyar.write_result(json.encode(table));
end
---------------------------------------
function getIds(data)
  teamyar.write_log("datta--"..json.encode(data))
  local ids = ""; 
  if data ~= nil then 
    if type(data) == "number"   then   
      ids = data
    else
      for i, v in ipairs(data) do
        if v == 0 then
          ids = v;
        end
        if  ids=="" then
          ids = ids..tostring(v.id);
        else
          ids = ids..","..tostring(v.id);
        end

      end
    end
  end 
  return ids
end 
----------------------------------------------
function getCustomers(data)
  teamyar.write_log("input--"..json.encode(input))
  local client = getIds(input.client)
  teamyar.write_log("cl--"..client)
  local section =getIds( input.section)
  local category = getIds(input.category)
  local country = getIds(input.country)
  local city = getIds(input.cityn)
  local state = getIds(input.staten)
  local kind = input.kind
  local datet = input.datet
  local datef = input.datef
  local mobile = input.mobile
  local selected = input.selected

  local query = [[  select distinct p.id,p.fullname,mo.mobile,em.email
  						 ,addr.city,(case when uf.sex=1 then 'آقای' when uf.sex=2 then 'خانم'  else '' end )gender
                          from crm_info  c inner join profile_main  p  on
                          p.id=c.id left join profile_user_info uf on uf.id=p.id left join profile_mobile mo on mo.user_id=p.id
                          left  join profile_email em on em.user_id=p.id left join profile_user_address addr on addr.user_id=p.id
                          left join crm_cross cx on cx.CLIENT_ID=p.id left join crm_classify_person cat on
                          cat.PROFILE_ID=cx.REFERE_ID left join crm_section sec on sec.id=cat.section_id where 1=1 ]]
  if client ~= nil  and client ~= "" then  
    query = query..[[ and p.id in (]]..client..[[) ]]
  end 
  if mobile ~= nil  and mobile ~= "" then  
    query = query..[[ and mo.mobile like '%]]..mobile..[[%' ]]
  end 
  if city ~= nil  and city ~= "" then  
    query = query..[[ and addr.city in (]]..city..[[) ]]
  end 
  if state ~= nil  and state ~= ""  then  
    query = query..[[ and addr.state in (]]..state..[[) ]]
  end 
  if country ~= nil  and country ~= ""  then  
    query = query..[[ and addr.COUNTRY_CODE in (]]..country..[[) ]]
  end 
  if section ~= nil  and section ~= ""  then  
    query = query..[[ and cat.id in (]]..section..[[) ]]
  end 
  if category ~= nil  and category ~= ""  then  
    query = query..[[ and sec.id in (]]..category..[[) ]]
  end 
  if datef~=nil  and datet ~= nil and datef~=""  and datet ~= ""  then  
    query = query..[[ and CREATE_DATE between  ]]..datef..[[ and ]]..datet
  end 


  if selected ~= nil  and selected ~= ""  then  
    --  query = query..[[ and cat.id in (]]..selected..[[) ]]
  end 
  teamyar.write_log(query)
  local table = queryResultCrm(query,{})

  -- teamyar.write_log("tbl----"..json.encode(table))
  return table 
end
--------------------------------
function sendSms(crms,txt)

  local res_str=""
  for i,v in ipairs (crms) do 
      txt = string.gsub(txt, "{{name}}", v.name);
    txt = string.gsub(txt, "{{date}}", farsidate);
     txt = string.gsub(txt, "{{city}}", v.city);
         txt = string.gsub(txt, "{{gender}}", v.gender);
    local info =	{box_id=c_sms_box_id,messages = {{content = txt, send_to = {profile_ids = {v.id}}}}, module_id = 26}
    local   res = teamyar.call_api(16, '/api/sms/send', info);
    --    teamyar.write_log("res----"..json.encode(res))
    if res.success ==true then 
      res_str=res_str.."<div style='color:green;'>".."ارسال پیامک برای کاربر :  "..v.name.." ،  شناسه پیامک :"..res.data.message_ids[1].."</div>"
    else 
      res_str=res_str.."<div style='color:red;'>".."خطا در ارسال پیامک :  "..res.error.message.."<div>"

    end 
  end 
  return res_str
end 
--------------------------------
function sendEmail(crms,txt)
  local res=""
  for i,v in ipairs (crms) do 
    url = "/api/email/emailmsgadd";
    
    txt = string.gsub(txt, "{{name}}", v.name);
    txt = string.gsub(txt, "{{date}}", farsidate);
         txt = string.gsub(txt, "{{city}}", v.city);
         txt = string.gsub(txt, "{{gender}}", v.gender);
    params = {
      box_id = tonumber(c_box_id) ,
      address = v.email ,
      email_content = txt ,
      email_subject = c_email_subject
    }
    teamyar.write_log("params----"..json.encode(params))
    local response = teamyar.call_api(12 , url , params);
    teamyar.write_log("response----"..json.encode(response))
    if response ~= nil and response.success ~= nil then
      status  = response.success;
      if response.success == true and response.data ~= nil and response.data.email_message_id ~= nil  then
        res = res.."<div style='color:green;'>".."ارسال پست الکترونیک برای کاربر "..v.name.." ،  شناسه  : "..response.data.email_message_id .. "<div>"
      elseif response.success == false and response.error ~= nil and response.error.status ~= nil and response.error.message ~= nil then
        res = res .."<div style='color:red;'>".."خطا در ارسال پست الکترونیک برای کاربر".. v.name.. " خطا: "..response.error.message.."</div>";
      end
    end
  end 
  return res
end 
------------------------------------------
function loadData()
  local data = teamyar.get_data("send_sms_filter_data")
  teamyar.write_result(data. value);
end
---------------------------------------
function setCashData(input)
  teamyar.write_log("input.category----"..json.encode(input.category))
  local client =json.encode( input.client)
  local section =json.encode( input.section)
  local category = json.encode(input.category)
  local country = json.encode(input.country)
  local city = json.encode(input.city)
  local state = json.encode(input.state)

  local chash_data = {
    ssf_client = client, 
    ssf_state = state,
    ssf_country = country, 
    ssf_city = city,
    ssf_kind= input.kind,ssf_kindn = input.kindn,
    ssf_section = section, 
    ssf_category = category, 
    ssf_datet = input.datet,
    ssf_datef = input.datef ,
    ssf_mobile= input.mobile,
    ssf_txt= input.txt,
  }
  teamyar.set_data("send_sms_filter_data", json.encode(chash_data));
end 
----------------------------------------------
local type_input =  input.type;
if type_input == 3 then 
  getAclCategory(input.data)
elseif input.type == 2 then 
  loadData()
elseif type_input == 4 then 
  getAclSection(input.data)
elseif type_input == 5 then 
  getAclClients(input.data)
elseif type_input == 6 then 
  getAclCountry(input.data)
elseif type_input == 7 then 
  getAclState(input.data)
elseif type_input == 8 then 
  getAclCity(input.data)
elseif type_input == 9 then 
  getAclKind(input.data)
elseif type_input == 10 then --sms
  setCashData(input)
  local crms =getCustomers()
  local res= ""
    local txt = input.txt
  if #crms == 0 then 
    res= "کاربری برای ارسال پیامک یافت نشد"
  elseif txt ==nil or  #txt == 0 then
       res= "متن پیامک خالی می باشد"
  else
    res= sendSms(crms,txt )
  end
  teamyar.write_result(json.encode({msg=res}))
elseif type_input == 13 then --ecel
  setCashData(input)     
  local crms =getCustomers()
  teamyar.write_result(json.encode(crms))
elseif type_input == 12 then --count
  setCashData(input)     
  local crms =getCustomers()
  local countcrm=#crms
  teamyar.write_result(json.encode({count=countcrm}))
elseif type_input == 11 then --email
  setCashData(input)     
  local crms =getCustomers()
  local res= ""
     local txt = input.txt
  if #crms == 0 then 
    res= "کاربری برای ارسال پست الکترونیک یافت نشد"
  elseif txt ==nil or  #txt == 0 then
       res= "متن پیامک خالی می باشد"
  else     
    res= sendEmail(crms, txt)
  end
  teamyar.write_result(json.encode({msg=res}))
else 
  local userinfo = teamyar.get_user_info();
  local lang = "English";
  if userinfo.lang_id == 4 then
    lang = "Persian";
  end
  local srlang = "<script src='/bot/run/2/sms_crm_filter/"..lang..".js'></script><script src='/bot/run/2/sms_crm_filter/xlsx.full.min.js'></script>";
  res_data = [[
  <div id='myDiv'></div>
  ]]..srlang..[[
  <link href='/bot/run/2/sms_crm_filter/main.css' rel='stylesheet' /> 
  <script src='/bot/run/2/sms_crm_filter/main.js'>
  </script>
  ]];
  teamyar.write_result(res_data);
end
