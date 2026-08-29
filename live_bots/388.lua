--Bot sales dashbord CRM Remainder zmo
input = teamyar.get_input();
local user_info = teamyar.get_user_info();
local user_id = math.floor(user_info["id"]); 
local day = time.get_day(time.current());
local month = time.get_month(time.current());
local year = time.get_year(time.current());
local min = time.get_minute(time.current());
local hour = time.get_hour(time.current());
local sec = time.get_second(time.current());
local temp_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":]]..hour..[[,"minute":]]..min..[[,"second":]]..sec..[[}]])
currentdate = string.format("%18.0f", temp_time);
teamyar.write_log(currentdate)
local category_id=3-- set your owne category id 
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
-----------------------------------------------
function WidgetTemplate()  
  local random = math.random(1,1000);
  local script =  teamyar.get_attachment("main.js");
  local css =  teamyar.get_attachment("main.css");
  local  str_lang="";
  local  str_title="";
  if user_info.lang_id == 4 then
    str_title="مشتریان باقی مانده"
    str_lang = teamyar.get_attachment("Persian.js");
  else
    str_title="sales dashbord CRM Remainder"
    str_lang = teamyar.get_attachment("English.js");
  end
  local template = teamyar.run_command("2/res_bot",{
      id = "bot_sd_cr",
      tpl_name = "html",
      title = str_title,
      body = "<div id=\\'sdcr_holder_body_html_"..random.."\\'></div>",
      script=[[
      (function(){
      ]]..str_lang..[[      
      var holder_id = '#sdcr_holder_body_html_]]..random..[[';
      var random_id = ]] .. random .. [[;
      ]]..script..[[
    })();
      ]],
      css = css
    });
  teamyar.write_result(template); 
end
---------------------main
if input.type == 1 then 
  local qselect=  [[ with calls as ( select CONNECTEDLINENUM uid,date d from voip_calls where CALLERPROFILEID=]]..user_id..[[ and CONNECTEDLINENUM=p.id 
                           and (round((]]..currentdate..[[-(date-(24*60*60*10000000)))/(60*60*24*10000000))-1)>=7)
                           select p.id,concat('#',p.id,'_',p.fullname)n,calls.d d from crm_ty_permission c inner join profile_main p on p.id=c.id inner join  crm_info i  on i.id=c.id
                           inner join crm_cross cr on cr.client_id=i.id  inner join crm_classify_person cp on cp.profile_id=cr.refere_id inner join calls on calls.uid=p.id
                           where user_id=]]..user_id..[[ and c.type=2 and (perm=4 or perm=5)  and cp.id=]]..category_id
  local query_select = [[SELECT JSON_ARRAYAGG(JSON_OBJECT("pid", pid,"n",n,"d",d)) from ( ]]..qselect.. [[ limit ?,? )tmp]]
  teamyar.write_log(query_select)
  res_data = queryResult(query_select , {input.from, input.count})
  -------------------
  local qtotal = [[select count(*) c from  ( ]]..qselect..[[)as t]]
  local  totall= queryResult(qtotal, {})
  data = {from = input.from, count = input.count, data = res_data, total = totall}
  teamyar.write_result(json.encode(data))
else
  WidgetTemplate()
end
