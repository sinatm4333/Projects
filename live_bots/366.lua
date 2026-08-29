input = teamyar.get_input();
local day_input=input.day;
if day_input == nil then
  day_input = 0;
end
local user_info = teamyar.get_user_info();
local user_id = math.floor(user_info["id"]); 
local day = time.get_day(time.current());
local month = time.get_month(time.current());
local year = time.get_year(time.current());
local temp_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":0,"minute":0,"second":0}]])
local date_startday = string.format("%18.0f" ,temp_time);
date_startday=date_startday+(day_input*(60*60*24*10000000))-user_info.timezone;
local date_night = date_startday+(60*60*24*10000000)+user_info.timezone;
---------------------------------------------
function loadData()
  local data = teamyar.get_data("ssc_data")

  teamyar.write_result(data. value);
end
--------------------------------
function queryResult(select_query)
  db.use_db("0000000");
  local params1 = {
    query = select_query,
    params = {}
  }
  db.query(params1);
  local record={};
  local res_text={};
  while db.query_fetch(record) do
    table.insert(res_text, {d = record[1], s = record[2], n = record[3], pp = record[4] });
  end
  db.query_free();
  return res_text;
end
---------------------------------------main
function sendSms()
    local query = [[ select date_issue d,serial s,note n,AMOUNT p 
 from  pa_pdc  
                                                where date_issue>=]]..date_startday..[[ and date_issue<=]]..date_night;
  teamyar.write_log(query)
    local cheqs = queryResult(query)


    for i, v in ipairs(cheqs) do
          local content_msg = " Banck Cheque Maturity "..v.s.." for "..v.n.."by amont "..tostring(v.pp).." is "..day_input.." days later "
          if user_info.lang_id == 4 then 
           content_msg = " سررسید چک به  شماره"..v.s.." بابت "..v.n.." به مبلغ "..tostring(v.pp).." "..day_input.." روز دیگر می باشد"
          end 
        local info =	{messages = {{content = content_msg, send_to = {profile_ids = {user_id}}}}, module_id = 26}
        teamyar.write_log(json.encode(info))
     --   local   res = teamyar.call_api(16, '/api/sms/send', info);
      -- teamyar.write_log(json.encode(res))
    end 
end
-----------------------------------------------
function WidgetTemplate()  
  local random = math.random(1,1000);
  local script =  teamyar.get_attachment("main.js");
  local css =  teamyar.get_attachment("main.css");
  local  str_lang="";
    local  str_title="";
  if user_info.lang_id == 4 then
    str_title="ارسال خودکار پیامک  قبل از سررسید چک"
    str_lang = teamyar.get_attachment("Persian.js");
  else
    str_title="َAutomatic SMS Sending Befor Cheque Due"
     str_lang = teamyar.get_attachment("English.js");
  end
  local template = teamyar.run_command("2/res_bot",{
      id = "bot_SMS_SEND_CHEQUE",
      tpl_name = "html",
      title = str_title,
      body = "<div id=\\'ssc_holder_body_html_"..random.."\\'></div>",
      script=[[
      (function(){
      ]]..str_lang..[[      
      var holder_id = '#ssc_holder_body_html_]]..random..[[';
    var random_id = ]] .. random .. [[;
      ]]..script..[[
    })();
      ]],
      css = css
    });
  teamyar.write_result(template); 
end
---------------------main
if input.type == 3 then 
   loadData()
elseif input.type == 1 then   
  local ddd= teamyar.get_data("ssc_data")
 local chash_data = {ssc_day = input.day}
  teamyar.set_data("ssc_data", json.encode(chash_data));
   sendSms()
else

  	WidgetTemplate()
end