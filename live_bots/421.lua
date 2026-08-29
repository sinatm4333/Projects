--Bot Ledger zmo
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
  local data = teamyar.get_data("al_data")
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
-------------------------------
function queryResultByRec(select_query, user_param)
  db.use_db("0000000")
    local params1 = {
      query = select_query,
      params = user_param
  }
  db.query(params1);
  local record = {}
  local all = {}
  while db.query_fetch(record) do
     table.insert(all, {i = record[1], d = record[2], crd = record[3], deb = record[4]
                              ,t = record[5], tt = record[6], ac = record[7]
                              ,l = record[8], s = record[9]})
 end
  db.query_free();
   --   teamyar.write_log(json.encode(all))
  return all;
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
function accountAcl(data)
  local geted_org_id=data.org_id;
  local query_param = [[ SELECT JSON_ARRAYAGG(JSON_OBJECT('id',i, 'name',n, 'type',1))
                                      from (select code i,concat('#',code,'_',name)n from pa_account where 1=1 ]] 
    if geted_org_id~0 then 
   	query_param =query_param..[[ and org_id=]]..geted_org_id
  end 
    if data.search ~= nil and #data.search > 0 then
     query_param = query_param ..  [[ and name like N'%]]..data.search..[[%' or  code like  N'%]]..data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count)..[[)tmp ]];   
  teamyar.write_result(queryResult(query_param , {}));
end
----------------------
function maliYearAcl(data)
  local geted_org_id = data.org_id;
  local query_param = [[ SELECT JSON_ARRAYAGG(JSON_OBJECT('id',i, 'name',n, 'type',1))
                                      from (select id i,title n from pa_fiscal_year where 1=1]]
  if geted_org_id~0 then 
   	query_param =query_param..[[ and org_id=]]..geted_org_id
  end 
    if data.search ~= nil and #data.search > 0 then
     query_param = query_param ..  [[ and title like N'%]]..data.search..[[%'  ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count)..[[)tmp ]];   
  teamyar.write_result(queryResult(query_param , {}));
end
----------------------
function labelAcl(data)
  local geted_org_id = data.org_id;
  local query_param = [[ SELECT JSON_ARRAYAGG(JSON_OBJECT('id',i, 'name',n, 'type',1))
                                      from (select id i,name n from pa_voucher_tag where 1=1]]
  if geted_org_id~0 then 
   	query_param =query_param..[[ and org_id=]]..geted_org_id
  end 
    if data.search ~= nil and #data.search > 0 then
     query_param = query_param ..  [[ and name like N'%]]..data.search..[[%'  ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count)..[[)tmp ]];  
  teamyar.write_result(queryResult(query_param , {}));
end
----------------------
function currencyAcl(data)
  local geted_org_id = data.org_id;
  local query_param = [[ SELECT JSON_ARRAYAGG(JSON_OBJECT('id',i, 'name',n, 'type',1))
                                      from (select id i,name n from pa_symbols where 1=1]]
  if geted_org_id~0 then 
   	query_param =query_param..[[ and org_id=]]..geted_org_id
  end 
    if data.search ~= nil and #data.search > 0 then
     query_param = query_param ..  [[ and name like N'%]]..data.search..[[%'  ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count)..[[)tmp ]];   
  teamyar.write_result(queryResult(query_param , {}));
end
-----------------------------------------------
function WidgetTemplate()  
  local random = math.random(1,1000);
  local script =  teamyar.get_attachment("main.js");
  local css =  teamyar.get_attachment("main.css");
  local  str_lang="";
    local  str_t="";
  if user_info.lang_id == 4 then
    str_lang = teamyar.get_attachment("Persian.js");
    str_t="دفتر حساب";
  else
     str_lang = teamyar.get_attachment("English.js");
    str_t="Bot Ledger";
  end
  local template = teamyar.run_command("2/res_bot",{
      id = "bot_accounting_ledger",
      tpl_name = "html",
      title = str_t,
      body = "<div id=\\'al_holder_body_html_"..random.."\\'></div>",
      script=[[
      (function(){
      ]]..str_lang..[[      
      var holder_id = '#al_holder_body_html_]]..random..[[';
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
  accountAcl(input.data)
  elseif  input.type == 5 then 
    maliYearAcl(input.data)
  elseif  input.type ==7 then 
    labelAcl(input.data)
  elseif  input.type ==8 then 
    currencyAcl(input.data)
elseif input.type == 1 then 
     	local accounts =json.encode(input.account_id)
  local chash_data = { al_accounts = accounts, al_datet = datet, al_datef = datef,
                                  al_mali_yr = mali_year, al_mali_yr_n = input.mali_yr_n, al_label = input.label, al_ln = input.ln, al_f_vocher = input.f_vocher,
                                  al_t_vocher = input.t_vocher, al_v_status = input.v_status, al_vn = input.vn,
                                  al_without = input.without, al_wn = input.wn, al_currency = input.currency, al_cn = input.cn, al_level = input.level, al_lvn = input.lvn}
  teamyar.set_data("al_data", json.encode(chash_data));
  if datet ~= nill  and datet ~= "" then 
	datet=datet + (24 * 60 * 60 * 10000000);
end
  local qselect=  [[select  v.VOUCHER_ID i ,v.RUN_DATE d, 
                              coalesce(vr.CRd/POWER(10,COALESCE( ( (select DECIMAL_COUNT from PA_SYMBOLS ps inner join PA_ORGANIZATIONS po on ps.id=po.BASE_CURRENCY  where po.org_id=2 limit 1)) ,0))) crd ,
                               coalesce(vr.DEB/POWER(10,COALESCE(( (select DECIMAL_COUNT from PA_SYMBOLS ps inner join PA_ORGANIZATIONS po on ps.id=po.BASE_CURRENCY  where po.org_id=2 limit 1)),0)))deb, v.type t, 
                                v.title tt,
             
   concat('#',ac.code,'_',ac.name)ac,
                                COALESCE(t.name,'--') l ,
                               v.status s from pa_voucher v inner join pa_voucher_record vr on v.ID=vr.voucher_id inner join pa_account ac on ac.id=vr.ACCOUNT_ID
--   inner join PA_ORGANIZATIONS po on po.org_id=ac.org_id   inner join PA_SYMBOLS ps on  ps.id=po.BASE_CURRENCY
   left join  pa_voucher_record_tag tr on tr.voucher_record_id=vr.id left join pa_voucher_tag t on t.id=tr.tag_id  
                                  where  v.ORG_ID=]]..org_id..[[  and VR.ORG_ID =]]..org_id..[[ and ac.org_id=]]..org_id..[[   and v.DELETED=0 and  vr.deleted <>1 ]]
    if   input.v_status ~= nil and  input.v_status ~= "" then 
      qselect= qselect..[[  and v.status =]]..input.v_status;
    end 
        if   input.currency ~= nil and  input.currency ~= "" then 
      qselect= qselect..[[  and po.BASE_CURRENCY=]]..input.currency;
    end 
      if  input.f_vocher~= ""  and input.t_vocher ~= ""   and input.f_vocher~= nil and input.t_vocher ~= nil     then 
      qselect = qselect..[[ and v.id<=]]..input.t_vocher..[[ and  v.id>=]]..input.f_vocher
    end
    if  datef ~= nill and datet ~= nill and datef ~= "" and datet ~= ""    then 
      qselect = qselect..[[ and v.run_date<]]..datet..[[ and v.run_date>]]..datef;
    end
    if input.label ~=nil and input.label ~= 0 then 
      qselect = qselect..[[ and (select t.id from  pa_voucher_tag t inner join pa_voucher_record_tag tr on t.id=tr.tag_id where tr.voucher_record_id=vr.id)=]]..input.label
    end
    if mali_year~=nill and mali_year~=0 then 
     	qselect = qselect..[[ and (select id from pa_fiscal_year where v.run_date > start_date and v.run_date< end_date limit 1)=]]..mali_year
  	end 
    local ids = ""; 
    if type(input.account_id) == "number"   then   
      ids = input.account_id
    else
    for i, v in ipairs(input.account_id) do
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
      qselect = qselect.. [[ and ac.code like N']]..ids..[[%'  ]]
    end
	local query_select =[[ ( ]]..qselect.. [[ limit ?,? )]]
    local q_total =[[select count(*) c from  ( ]]..qselect..[[)as t]]
    if  input.level ==1 then 
        --    teamyar.write_log("----lev1-----")
      query_select =[[select i,d,sum(crd),sum(deb),t,tt,ac,,level,l,s from ( ]]..qselect.. [[ limit ?,? )mm group by i,d,t,tt,acg,l,s ]]
     q_total =[[select count(*) c from  (select sum(crd),sum(deb),i,d,t,tt,acg,'--'ack,'--'acm,'--'act,l,s from ( ]]..qselect..[[)mm group by i,d,t,tt,ac,level,l,s)mm ]]
    end
    if  input.level ==2 then 
       --     teamyar.write_log("------lev2---")
      query_select =[[select i,d,sum(crd),sum(deb),t,tt,acg,ac,level,l,s from ( ]]..qselect.. [[ limit ?,? )mm group by i,d,t,tt,acg,ack,l,s ]]
         q_total =[[select count(*) c from  (select sum(crd),sum(deb),i,d,t,tt,acg,ack,'--'acm,'--'act,l,s from ( ]]..qselect..[[)mm group by i,d,t,tt,ac,level,l,s)mm ]]
    end 
    if  input.level ==3 then 
         --  teamyar.write_log("-------llev3--")
      query_select =[[select i,d,sum(crd),sum(deb),t,tt,acg,ac,level,l,s from ( ]]..qselect.. [[ limit ?,? )mm group by i,d,t,tt,acg,ack,acm,l,s ]]
         q_total =[[select count(*) c from  (select sum(crd),sum(deb),i,d,t,tt,acg,ack,acm,'--'act,l,s from ( ]]..qselect..[[)mm group by i,d,t,tt,ac,level,l,s)mm ]]
    end 
    local qsum = [[SELECT JSON_ARRAYAGG(JSON_OBJECT("sdeb", sdeb, "scrd",scrd)) from ( select sum(deb) sdeb,sum(crd) scrd from  ( ]]..qselect..[[)mm)as t]];
     -- teamyar.write_log(json.encode(input) )
   -- teamyar.write_log("-----****----")
 --  teamyar.write_log(query_select )
  res_data = queryResultByRec(query_select , {input.from, input.count})
 -- res_data = queryResultByRec(query_select , {input.from,3})
  local  totall= queryResult(q_total, {})
  local sum=queryResult(qsum, {})

  data = {from = input.from, count = input.count, data = res_data, total = totall, sum = sum}
 --   teamyar.write_log(json.encode(data) )
  teamyar.write_result(json.encode(data))
else
	WidgetTemplate()
end
