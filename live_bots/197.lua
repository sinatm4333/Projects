--Bot Service Down
input = teamyar.get_input();
local user_info = teamyar.get_user_info();
local user_id = math.floor(user_info["id"]); 
local org_id = input.org_id;
if org_id == nil then
  org_id=0;
end
local datef = input.df;
local datet = input.dt;
      teamyar.write_log(json.encode(input))

---------------------------------------------
function loadData()
  local data = teamyar.get_data("sd_data")
  teamyar.write_result(data. value);
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
  return res_text[1];
end
----------------------
function orgAcl(data)
  local query_param = [[ SELECT JSON_ARRAYAGG(JSON_OBJECT('id',id, 'name',name, 'type',1))
  										from (select id,name from org_info ]]
 if data.search ~= nil and #data.search > 0 then
     query_param = query_param..[[  where name like N'%]]..data.search..[[%') as p ]]
  else
	query_param = query_param .. [[) p ]]
  end
query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
teamyar.write_result(queryResult(query_param, {}));
end
----------------------
function servicerAcl(data)
  local geted_org_id = data.org_id;
  local query_param = [[ SELECT JSON_ARRAYAGG(JSON_OBJECT('id',i, 'name',n, 'type',1))
                                      from (select id i,title n from pa_fiscal_year where 1=1]]
  if geted_org_id~0 then 
   	query_param =query_param..[[ and org_id=]]..geted_org_id
  end 
    if data.search ~= nil and #data.search > 0 then
     query_param = query_param ..  [[ and name like N'%]]..data.search..[[%'  ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count)..[[)tmp ]];   
      teamyar.write_log(query_param)
  teamyar.write_result(queryResult(query_param , {}));
end
-----------------------------------------------
function WidgetTemplate()  
  local random = math.random(1,1000);
  local script =  teamyar.get_attachment("main.js");
  local css =  teamyar.get_attachment("main.css");
  local  str_lang="";
  if user_info.lang_id == 4 then
    str_lang = teamyar.get_attachment("Persian.js");
  else
     str_lang = teamyar.get_attachment("English.js");
  end
  local template = teamyar.run_command("2/res_bot",{
      id = "bot_service_down",
      tpl_name = "html",
      title = "BOT_Service_down",
      body = "<div id=\\'sd_holder_body_html_"..random.."\\'></div>",
      script=[[
      (function(){
      ]]..str_lang..[[      
      var holder_id = '#sd_holder_body_html_]]..random..[[';
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
elseif input.type == 2 then 
  orgAcl(input.data)
  elseif input.type == 4 then 
  servicerAcl(input.data)
elseif input.type == 1 then 
  teamyar.write_log("start")
  local chash_data = {sd_org_id = org_id, sd_gn = input.gn, sd_servicer_id= input.servicer_id, sd_sn = input.sn, sd_datef = sd_datet}
  teamyar.set_data("sd_data", json.encode(chash_data));
  if datet ~= nill  and datet ~= "" then 
	datet=datet + (24 * 60 * 60 * 10000000);
end
  local qselect=  [[ select  distinct so.id i,so.code c,(select name from wh_product where id= so.product_id limit 1)p
                              from pm_sd_user su inner join pm_service_detail sd on su.service_detail_id=sd.id 
                              inner join pm_service s on s.id=sd.service_id inner join pm_service_order_ver_det ovd on ovd.service_id=s.id
                              inner join pm_service_order_version sv on sv.id=ovd.service_order_version_id inner join pm_service_order so on so.id=sv.service_order_id 
                              where su.user_id=]]..input.servicer_id..[[ and so.org_id=]]..org_id
    if  datef ~= nill and datet ~= nill and datef ~= "" and datet ~= ""    then 
      qselect = qselect..[[ and sv.break_down_date<]]..datet..[[ and sv.break_down_date>]]..datef
    end


local query_select = [[SELECT JSON_ARRAYAGG(JSON_OBJECT("c", c, "p",p,"i",i)) from ( ]]..qselect.. [[ limit ?,? )tmp]]
    teamyar.write_log(query_select)
  res_data = queryResult(query_select , {input.from, input.count})
    -------------------
  local qtotal = [[select count(*) c from  ( ]]..qselect..[[)as t]]
  local  totall= queryResult(qtotal, {})
  data = {from = input.from, count = input.count, data = res_data, total = totall}
    teamyar.write_log("data----"..json.encode(data))
  teamyar.write_result(json.encode(data))
else
	WidgetTemplate()
end
