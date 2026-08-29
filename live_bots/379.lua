--Bot Bot Personel Daily Request OverTime zmo
--ver:001
--start 1403-2-9
input = teamyar.get_input();
local user_info = teamyar.get_user_info();
local user_id = math.floor(user_info["id"]); 
local org_id = input.org_id;
if org_id == nil then
  org_id=0;
end
local datef = input.df;
local datet = input.dt;
local month = input.month;
local mali_year= input.mali_yr
if account_id == nill then 
  account_id = "";
end 
---------------------------------------------
function loadData()
  local data = teamyar.get_data("hrdr_data")
  teamyar.write_result(data. value);
end
-----------------------------------------------------------
function queryResultByColumn(query,query_params)
    db.use_db("0000000")
  local params = {
    query = query,
    params = query_params
  }
  db.query(params);
  local res_text={};
  local record={};
  while db.query_fetch(record) do
    local tmp=record;
    table.insert(res_text,{p=record[1],dr=record[2],df=record[3],dt=record[4],dc=record[5],a=record[6],s=record[7]});
  end
  db.query_free();
  return res_text;
end 
----------------------------------------------------------------------
function getQueryResponse1(query,query_params)
  db.use_db("0000000")
  local params = {
    query = query,
    params = query_params
  }
  db.query(params);
  local res_text={};
  local record={};
  while db.query_fetch(record) do
    local tmp=record;
    table.insert(res_text,{id=record[1],name=record[2],type=record[3]});
  end
  db.query_free();
  return res_text;
end
--------------------------------------------------------
function queryResult(select_query,user_param)
  db.use_db("0000000");
  local params1 = {
    query = select_query,
    params = user_param
  }
  db.query(params1);
  teamyar.write_log(json.encode(params1))
  local res_text = db.query_fetch();
  db.query_free();
  if res_text == nil then 
    return nil 
  else
    return res_text[1];
  end 
end

----------------------
function personnelAcl(data)
  local geted_org_id = data.org_id;
  local query_param = [[ select h.personnel_id id,p.fullname name,1 type from hr_personnels h inner join profile_main p on h.profile_id=p.id where 1=1 ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  and fullname like N'%]]..data.search..[[%' ]]

  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from,data.count);   
  teamyar.write_result(json.encode(getQueryResponse1(query_param, {})));
end
-----------------------------------------------
function WidgetTemplate()  
  local random = math.random(1,1000);
  local script =  teamyar.get_attachment("main.js");
  local css =  teamyar.get_attachment("main.css");
  local  str_lang="";
  local  str_title="";
  if user_info.lang_id == 4 then
    str_title="گزارش درخواست های اضافه کاری پرسنل"
    str_lang = teamyar.get_attachment("Persian.js");
  else
    str_title="Personnel OverTime Request"
    str_lang = teamyar.get_attachment("English.js");
  end
  local template = teamyar.run_command("2/res_bot",{
      id = "bot_hr_daily_request",
      tpl_name = "html",
      title = str_title,
      body = "<div id=\\'hrdr_holder_body_html_"..random.."\\'></div>",
      script=[[
      (function(){
      ]]..str_lang..[[      
      var holder_id = '#hrdr_holder_body_html_]]..random..[[';
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
elseif  input.type == 5 then 
  personnelAcl(input.data)
elseif input.type == 1 then 
  local personnels =json.encode(input.per)
  local chash_data = {hrdr_org_id = org_id, hrdr_gn = input.gn,  hrdr_datet = datet,hrdr_datef = datef,
    hrdr_per =personnels, hrdr_ty = hrdr_ty, hrdr_tyn = input.tyn}
  teamyar.set_data("hrdr_data", json.encode(chash_data));
  if datet ~= nill  and datet ~= "" then 
    datet=datet + (24 * 60 * 60 * 10000000);
  end
  local qselect=  [[ select(select fullname from profile_main where id=p.PROFILE_ID) p,DAY_DATE dr,TIME_FROM df,TIME_TO dt
                              , r.DATE_CREATE dc,(select fullname from profile_main where id=r.AUTHOR_ID) a,
                              STATUS s from hr_overtime_request r inner join hr_personnels p on p.PERSONNEL_ID=r.PERSONNEL_ID where 1=1 ]]
  if  datef ~= nill and datet ~= nill and datef ~= "" and datet ~= ""    then 
    qselect = qselect..[[ and (TIME_FROM-(60*60*10000000))<=]]..datet..[[ and (TIME_FROM-(60*60*10000000))>=]]..datef
  end
  local ids = ""; 
  if type(input.per) == "number"   then   
    ids = input.per
  else
    for i, v in ipairs(input.per) do
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
  if ids ~= nill and ids ~= "" then 
    qselect = qselect..[[ and  r.PERSONNEL_ID in (]]..ids..[[) ]]
  end 

  qselect = qselect..[[ order by DAY_DATE  ]]
--  local query_select = [[SELECT JSON_ARRAYAGG(JSON_OBJECT("p", p, "dr",dr,"dt",dt,"df",df,"dc",dc,"s",s,"a",a)) from ( ]]..qselect.. [[ limit ?,? )tmp]]
   local query_select = qselect.. [[ limit ?,?]]
  teamyar.write_log(query_select)
  res_data = queryResultByColumn(query_select , {input.from, input.count})
  -------------------
  local qtotal = [[select count(*) c from  ( ]]..qselect..[[)as t]]
  local  totall= queryResult(qtotal, {})
  data = {from = input.from, count = input.count, data = res_data, total = totall, timezone= user_info.timezone}
  teamyar.write_result(json.encode(data))
else
  WidgetTemplate()
end
