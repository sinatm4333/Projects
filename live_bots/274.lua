--Bot Total Expense zmo
input = teamyar.get_input();
local user_info     = teamyar.get_user_info();
local license_id	= input.license_id;
local user_id 		 = math.floor(user_info["id"]); 
local lang_id        = user_info.lang_id;
local portal_id		 = input.m_id;
local profile_id     = input.profile_id;
local license_id    = input.license_id;
local token			  = input.token;
if profile_id == nil then 
  profile_id = 0;
end
if license_id == nil then 
  license_id = 0;
end
if token == nil then 
  token = 0;
end
if portal_id	==  nil then
  portal_id=0;
end
local section_id   = 10065;
--------------------------------------------validate input
if license_id == nil then 
  license_id=0;
end
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
  if res_text ~= nil then 
    return res_text[1];
  else
    return res_text;
  end     
end
-----------------------------------------------
function WidgetTemplate()  
  local random = math.random(1,1000);
  local script =  teamyar.get_attachment("main.js");
  local css =  teamyar.get_attachment("main.css");
  local  str_lang = "";
  if user_info.lang_id == 4 then
    str_lang = teamyar.get_attachment("Persian.js");
  else
    str_lang = teamyar.get_attachment("English.js");
  end
  local template = teamyar.run_command("2/res_bot",{
      id = "bot_portal_signup",
      tpl_name = "html",
      title = "BOT_PORTAL_SIGNUP_FORM",
      body = "<div id=\\'suf_holder_body_html_"..random.."\\'></div>",
      script=[[
      (function(){
      ]]..str_lang..[[      
      var holder_id = '#suf_holder_body_html_]]..random..[[';
      var random_id = ]] .. random .. [[;
      ]]..script..[[
    })();
      ]],
      css = css
    });
  teamyar.write_result(template); 
end
--------------------
function  validateToken (profile_id, license_id, token, lic_key)
  if true then
    return true;
  end
  local curr_time = time.current();
  local token_time = curr_time - (curr_time % (5 * time.minute));
  local str = profile_id .. '#' .. license_id .. '#' .. lic_key .. '#' .. string.format('%d',token_time);
  local token_sha = coding.sha256(str);
  if string.sub(token_sha, 1, 20) == token then
    return true;
  end
  token_time = (curr_time - time.minute) - ((curr_time - time.minute) % (5 * time.minute))
  str = profile_id .. '#' .. license_id .. '#' .. lic_key .. '#' .. string.format('%d',token_time);
  token_sha = coding.sha256(str);
  return (string.sub(token_sha, 1, 20) == token);
end
---------------------------
function loginCrm()
  local res = teamyar.call_api(2, '/api/user/login/token', {user_id = profile_id, portal_id = portal_id});
  local token = "";
  if res.success then
    token = res.data.token;
  end
  ------check validate tocken
  local str = [[select  lic_key k from lic_license where id=]]..license_id
  local p_id = queryResult([[select  profile_id k from lic_license where id=]]..license_id, {});
  local crm_id = queryResult([[select ci.id from crm_contacts cc join crm_info ci on ci.id=cc.contact_id where cc.client_id=]]..p_id..[[ and ci.import_id=]]..profile_id, {});
  local count_related = queryResult([[select  count(*) c  from portal_related_user where related_id=42309 and  main_id=]]..profile_id, {});
  if count_related == 0 then 
    return 1
  end
  if crm_id == nill then 
    crm_id=0
  end
  local r_id = queryResult([[select related_id from portal_related_user where main_id=]]..p_id, {})
  if not validateToken(profile_id, license_id, token,  license_data) then
    return 2
  end
  local user_mobile = queryResult([[select mobile from profile_mobile where user_id=]]..profile_id, {});
  if user_id ~= nill and user_id > 0 then
    local res = teamyar.call_api(5, '/api/profile_data/get', {id = profile_id, type = 1, module_id = 2});
    if not res.success or #res.data.mobile == 0 then
      return 3--{error_code = 3, login = 'fail'};
    end
    res = teamyar.call_api(2, '/api/user/login', {login = user_mobile, portal_id = portal_id, lang_id = lang_id, link_id =42309 , token = token}, {set_header = true});
    for i,v in ipairs(res.data.headers) do
      teamyar.set_http_header(v.header,v.value);
    end
    if not res.success then
      return 4--{error_code = 4, login = 'fail'};
    end
  end
  teamyar.set_http_header('content-type','text/html; charset=utf-8', true);
  teamyar.set_http_header('location', "https://tp.teamyar.com/?page=/home/index&id="..profile_id);
  teamyar.set_http_status(302,'Found');
  return 0-- {error_code = 0, login = 'ok'};
end
---------------------------
function registerCrm()
  teamyar.write_log("start register: ")
  local crm_id = 0;
  local in_crm = queryResult([[select  count(*)   from crm_info where id=]]..profile_id,{});
  local sucsess = false;
  -- if hasent crm
  if(in_crm==0) then
    local info = {profile = {name = input.suf_name, email = {{value = input.suf_email, id = 0}}, gender = 1, mobile = {{value = input.suf_number, country = 364}}, last_name = input.suf_last_name, user_type = 1}, profile_id = profile_id, section_id = 8}
    local res = teamyar.call_api(14, '/api/client/create',info)
    if res.success then
      sucsess = true
      crm_id = res.data.profile_id;
    end
  else --if has crm but is in another section
    res = teamyar.call_api(14, '/api/client/update', {id =profile_id, import_id = crm_id});
    if res==nil then 
      res=""
    end
    teamyar.write_log("res client update: "..json.encode(res))
    if res.success then
      sucsess = true
    end
    res = teamyar.call_api(14, '/api/client/contact/add', {id = profile_id, contact = {{type = 1, contact_id = 42309}}});
  end 

  res = teamyar.call_api(14, '/api/client/portal/add', {id = profile_id, lang_id = lang_id, password = input.pass, portal_id = portal_id, category_id = 124, related_contact = {42309}});
  res = teamyar.call_api(14, '/api/client/contact/add', {id = profile_id, contact = {{type = 1, contact_id = 42309}}});
  local count_relate = queryResult([[select  count(*) c  from portal_related_user where related_id=42309 and  main_id=]]..profile_id, {});
  if count_relate == 0 then 
    res = teamyar.call_api(14, '/api/client/contact/add', {id = profile_id, contact = {{type = 1, contact_id = 42309}}})
  end
  return 0;
end
---------------------main
if input.type == 1 then 
  local sstr = [[select count(*) from crm_cross where client_id=]]..user_id..[[ and refere_id=]]..section_id;
  local has_in_section = queryResult(sstr,{})
  local learning_item = {};
  if has_in_section == 1 then 
    learning_item = loginCrm();
  end
  local res_data = {in_section = has_in_section, learning_item = learning_item.items}
  teamyar.write_result(json.encode(res_data))
elseif input.type == "2" then 
  teamyar.write_log("start type 2 ")
  local   ress = registerCrm();
  ress = loginCrm();
else
  teamyar.write_log("start type 0 ")
  local  ress = loginCrm();
  local res_str = "Login Failed";
  if lang_id == 4 then 
    res_str = "خطا در ورود به پورتال"
  end
  if ress == 1 then 
    if lang_id == 4 then 
      res_str = ".خطا در پیدا کردن پکیج های آموزشی. برای افزودن پکیج های آموزشی به پورتال شما رمز عبور به پرتال خود را تعیین نمایید"
    else
      res_str = "failed to find realted learning Pakage.Please select your new portal pass to add learning pakage for you"
    end
  end
  if ress == 2 then 
    if lang_id == 4 then 
      res_str = "خطا در ورود. برای تلاش مجدد رمز عبور جدید پورتال خود را تعیین نمایید."
    else
      res_str = "invalid login to try again please select your new  portal pass. "
    end
  end
  if ress == 3 then 
    if lang_id == 4 then 
      res_str = "پرونده کاربری یافت نشد"
    else
      res_str = "faild to find profile."
    end
  end
  if ress == 3 then 
    if lang_id == 4 then 
      res_str = "ورود به پرتال به موفقیت انجام نشد. برای تلاش مجدد رمز عبور جدید پرتال خود را مجدد تعیین کنید"
    else
      res_str = "Failed login attempt. to try again please select your new portal pass. "
    end
  end
  local pass_title = "password";
  if lang_id == 4 then 
    pass_title = "رمز عبور"
  end
  local msg = "Please Insert Your Portal Password"
  if lang_id == 4 then 
    msg = "رمز عبور جدید ورود به پرتال را تعیین نمایید"
  end
  if ress ~= 0 then 
    res_data  = [=[
    <div id='mainDiv'></div>
    <div style='font-weight:bold;color:red;' >]=]..res_str..[=[:</div><br><br>
    <div style='font-weight:bold;' >]=]..msg..[=[:</div><br><br>
    <form action="/public/portal/signup">
    <input type="hidden" id="m_id" name="m_id" value="]=]..portal_id..[=[">
    <input type="hidden" id="profile_id" name="profile_id" value="]=]..profile_id..[=[">
    <input type="hidden" id="license_id" name="license_id" value="]=]..license_id..[=[">
    <input type="hidden" id="token" name="token" value="]=]..token..[=[">
    <input type="hidden" id="type" name="type" value="2">
    <label for="pass">]=]..portal_id..[=[:</label><br>
    <input type="text" id="pass" name="pass" value=""><br><br>
    <input type="submit" value="Submit">
    ]=]
    teamyar.write_result(res_data);
  end
end
