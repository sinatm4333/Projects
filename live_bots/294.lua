 input = teamyar.get_input();
ctype = input.type;
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
currentdate = string.format("%18.0f" ,temp_time);
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
function WidgetTemplate()  
  local random= math.random(1,1000);
  local script =  teamyar.get_attachment("main.js");
  local css =  teamyar.get_attachment("main.css");
    local  str_lang = "";
  if uinfo.lang_id == 4 then
    str_lang = teamyar.get_attachment("Persian.js");
  else
    str_lang = teamyar.get_attachment("English.js");
  end
  local template = teamyar.run_command("2/res_bot",{
      id = "most_higher_dealer_profit_chart",
      tpl_name = "html",
            body = "<div id=\\'hdp_holder_body_html_"..random.."\\'></div>",
      script=[[
      (function(){
          ]]..str_lang..[[       
      var holder_id = '#hdp_holder_body_html_]]..random..[[';
    var random_id = ]] .. random .. [[;
      ]]..script..[[
    })();

      ]],
      css=css

    });
  teamyar.write_result(template);
 
end
------------------
--main
if ctype == 3 then   
    local query=[[select JSON_ARRAYAGG(JSON_OBJECT('personnel_id', personnel_id, 'timef', timef, 'timet', timet)) as result from 
      (select p.PERSONNEL_ID personnel_id,e.TIME_FROM timef,e.TIME_TO timet from hr_personnels p 
      inner join  hr_ext_time e on p.PERSONNEL_ID=e.PERSONNEL_ID  where e.not_telework=0  and  p.PROFILE_ID=]]..user_id..[[  and e.EXT_DATE=]]..currentdate;
   local res_data=getQueryResponse(query..[[  ) tmp]],{})
  
     teamyar.write_log(query..[[  ) tmp]]);
  
   local last_act=getQueryResponse("select  last_activity from admin_view_session s where s.user_id="..user_id,{})

   local listdata = {data = res_data, cur_date = currentdate_time,last_act=last_act};
   teamyar.write_result(json.encode(listdata));
else 
  WidgetTemplate();
end
