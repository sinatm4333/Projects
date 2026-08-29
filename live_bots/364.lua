--Bot Bot Ledger and Factor Sum By Customer zmo
input = teamyar.get_input();
local user_info = teamyar.get_user_info();
local user_id = math.floor(user_info["id"]); 
local org_id = input.org_id;
if org_id == nil then
  org_id = 0;
end
local datef = input.df;
local datet = input.dt;

local day = time.get_day(time.current());
local month = time.get_month(time.current());
local year = time.get_year(time.current());
local min = time.get_minute(time.current());
local hour = time.get_hour(time.current());
local sec = time.get_second(time.current());
local temp_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":]]..hour..[[,"minute":]]..min..[[,"second":]]..sec..[[}]])
currentdate = string.format("%18.0f", temp_time);
-------------------------------------------------
function queryResultSum(query, query_params)
  db.use_db("0000000")
  local params = {
    query = query,
    params = query_params
  }
  db.query(params);
  local res_text = {};
  local record = {};
  while db.query_fetch(record) do
    table.insert(res_text, { cred = record[1], deb = record[2], r = record[3],rall = record[4] });
  end
  db.query_free();
  return res_text;
end
--------------------------------
function queryResult2(query, query_params)
  db.use_db("0000000")
  local params = {
    query = query,
    params = query_params
  }
  db.query(params);
  local res_text = {};
  local record = {};
  while db.query_fetch(record) do
    table.insert(res_text, { deb= record[1], cred = record[2], r = record[3], crm = record[4], crm_id = record[5],client_id = record[6], rall = record[7]});
  end
  db.query_free();
  return res_text;
end

----------------------
function loadData()
  local data = teamyar.get_data("ctb_data")
  teamyar.write_result(data. value);
end
--------------------------------
function queryResult(select_query,user_param)
  teamyar.write_log(select_query)
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
function accountAcl(data)
  local geted_org_id = data.org_id;
  local query_param = [[ SELECT JSON_ARRAYAGG(JSON_OBJECT('id',i, 'name',n, 'type',1))
  from (select id i,concat('#',code,'_',name)n from pa_account where 1=1 ]] 
  if geted_org_id ~ 0 then 
    query_param = query_param..[[ and org_id=]]..geted_org_id
  end 
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param ..  [[ and name like N'%]]..data.search..[[%' or  code like  N'%]]..data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count)..[[)tmp ]];   
  teamyar.write_result(queryResult(query_param , {}));
end
----------------------
function customerAcl(data)
  local query_param = [[ SELECT JSON_ARRAYAGG(JSON_OBJECT('id',i, 'name',n, 'type',1))
  from (select distinct id i ,concat('#',code,'_',name) n from pa_client  where VOUCHER_ALLOW=1 ]]

  if  data.section~= nil then 
    query_param =query_param..[[  and code like ']]..data.section..[[%' ]]
  end 
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param ..  [[ and name like N'%]]..data.search..[[%' or code like  N'%]]..data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count)..[[)tmp ]];   
  teamyar.write_log(query_param)
  teamyar.write_result(queryResult(query_param , {}));
end

----------------------
function sectionAcl(data)
  local query_param = [[ SELECT JSON_ARRAYAGG(JSON_OBJECT('id',i, 'name',n, 'type',1))
  from (select code i,name n from pa_client where parent=0 ]]
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
  local  str_lang = "";
  local  str_title = "";
  if user_info.lang_id == 4 then
    str_title = " گزارش تراز آزمایشی اشخاص با جزئیات"
    str_lang = teamyar.get_attachment("Persian.js");
  else
    str_title = "Client Trial Balance"
    str_lang = teamyar.get_attachment("English.js");
  end
  local template = teamyar.run_command("2/res_bot",{
      id = "bot_ledger_factors_by_crm",
      tpl_name = "html",
      title = str_title,
      body = "<div id=\\'ctb_holder_body_html_"..random.."\\'></div>",
      script = [[
      (function(){
      ]]..str_lang..[[      
      var holder_id = '#ctb_holder_body_html_]]..random..[[';
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
  customerAcl(input.data)
elseif input.type == 5 then 
  accountAcl(input.data)

elseif input.type == 9 then 
  sectionAcl(input.data)
elseif input.type == 1 then 
  local ids = ""; 
  --------------
  if type(input.account_id) == "number"   then   
    ids = input.account_id
  else
    for i, v in ipairs(input.account_id) do
      if v == 0 then
        ids = v;
      end
      if  ids == "" then
        ids = ids..tostring(v.id);
      else
        ids = ids..","..tostring(v.id);
      end
    end
  end
  local accounts = json.encode(input.account_id)
  local chash_data = {  ctb_org_id = org_id,
                                    ctb_gn = input.gn, 
                                    ctb_datet = datet,
                                    ctb_datef = datef,                               
                                    ctb_crm = input.crm,
                                    ctb_cn = input.cn,
                                    ctb_def = input.def,
                                    ctb_defn = input.defn,
                                    ctb_show_zero_rem = input.show_zero_rem,
                                    ctb_accounts = accounts, 
                                    ctb_section =  input.section,
                                    ctb_sn = input.sn}
  teamyar.set_data("ctb_data", json.encode(chash_data));
  if datet ~= nil  and datet ~= "" then 
   -- datet=datet + (24 * 60 * 60 * 10000000);
  end
  local with_str = [[ with decimaln as (select coalesce((select case when decimal_count>0 then decimal_count else fee_decimal end),0 )d
                                from PA_SYMBOLS ps inner join PA_ORGANIZATIONS po on ps.id=po.BASE_CURRENCY where po.org_id=]]..org_id..[[  and ps.org_id=]]..org_id..[[  ) ,
  
  vochers as ( select sum(deb)deb ,sum(cred)cred,CLIENT_ID clid  from(
                                  select (vr.deb) deb ,(vr.crd ) cred,vr.CLIENT_ID  CLIENT_ID 
                                    from pa_voucher v inner join pa_voucher_record vr  on vr.VOUCHER_ID=v.id

                                    where     v.deleted<>1 and vr.deleted <>1 and v.status>1 and
                                     vr.org_id=]]..org_id..[[ and v.org_id=]]..org_id
      if  datef ~= nil and datef ~= ""  then 
                                   with_str=with_str..[[ and vr.RUN_DATE >= ( select START_DATE from pa_fiscal_year where ]]..datef..[[ between START_DATE and END_DATE and org_id= v.org_id limit 1 ) ]]
  end
        if  datet ~= nil and datet ~= ""  then 
                                   with_str=with_str..  [[ and vr.RUN_DATE <=]]..datet 
  end

      if  input.crm ~= nil and input.crm ~= ""   then 
  with_str=with_str.. [[ and vr.CLIENT_ID=]]..input.crm
  end
    if ids ~= nill and ids ~= "" then 
    with_str=with_str..[[ and vr.ACCOUNT_ID in (]]..ids..[[) ]]
  end
    if  input.prj ~= nil   then 
    with_str = with_str..[[ and  v.PROJECT_ID=]]..input.prj
  end
  if  input.floating ~= nil   then 
    with_str = with_str..[[ and  vr.FLOATING_ACCOUNT_ID=]]..input.floating
  end

  
  with_str=with_str..[[  ) oo group by CLIENT_ID)]]
  local qselect =  [[ select sum(deb)deb,sum(cred) cred,sum(r)r,crm,crm_id,clid,sum(r) over (order by clid desc)rall from
                                            (
            select coalesce(sum(vo.deb)/POWER(10,COALESCE(
            (select DECIMAL_COUNT from PA_SYMBOLS ps inner join PA_ORGANIZATIONS po
            on ps.id=po.BASE_CURRENCY where po.org_id=]]..org_id..[[ limit 1) )),0)   deb,
            coalesce(sum(vo.cred)/POWER(10,COALESCE( ( (select DECIMAL_COUNT from PA_SYMBOLS
            ps inner join PA_ORGANIZATIONS po on ps.id=po.BASE_CURRENCY where po.org_id=]]..org_id..[[ limit 1)) ,0))) cred
            , sum(vo.deb)- sum(vo.cred)/POWER(10,COALESCE( ( (select DECIMAL_COUNT from PA_SYMBOLS ps inner join
  PA_ORGANIZATIONS po on ps.id=po.BASE_CURRENCY where po.org_id=]]..org_id..[[  limit 1)),0) )r, (select name from pa_client where id=vo.clid and org_id=]]..org_id..[[  )crm,
            (select reffere_id from pa_client where id= vo.clid and org_id=]]..org_id..[[  ) crm_id,vo.clid from vochers vo where 1=1  ]]

  if  input.crm ~= nil and input.crm ~= nil   then 
    qselect=qselect..[[ and vo.clid=]]..input.crm
  end
  if  input.section ~= nil and input.section ~= nil   then 
    qselect = qselect..[[  and (select code from pa_client where id= vo.clid limit 1) like ']]..input.section..[[%' ]]
  end
  if  input.crmty ~= nil   then 
    qselect=qselect..[[ and  (select type from pa_client where id=vo.clid)=]]..input.crmty
  end 



  qselect = qselect..[[  group by vo.clid)tt where 1=1 ]]
  if  input.def ~= nil   then 
    if json.encode(input.def)=="0" or  input.def == "0" or  input.def == 0   then 
      qselect=qselect..[[ and r>0 ]]
    elseif json.encode(input.def)=="1" or  input.def == "1" or  input.def == 1  then 
      qselect=qselect..[[ and r<0 ]]
    end
end
  if input.show_zero_rem then 
          qselect=qselect..[[ and r<>0 ]]
  end 

  if input.category ~= nil then
    qselect = qselect..[[  and  clid in (select  p.reffere_id  from crm_classify_person cp inner join crm_cross c on 
    cp.profile_id= c.refere_id inner join pa_client p on  p.reffere_id=c.client_id where cp.id=]]..input.category..[[)]]
  end
  qselect = qselect..[[ group by crm,crm_id,clid order by crm ]]
  local query_select = qselect.. [[ limit ?,? ]]
  teamyar.write_log(with_str..query_select)
  res_data = queryResult2(with_str..query_select , {input.from, input.count})
  -------------------
  local qtotal = [[select count(*) c from  ( ]]..qselect..[[)as t]]
  local qsum = [[select sum(cred) cred,sum(deb),sum(r) r,sum(rall)rall from  ( ]]..qselect..[[)as t ]]
  --  teamyar.write_log(qsum)
  local  totall = queryResult(with_str..qtotal, {})
  local sum = queryResultSum(with_str..qsum, {})
  local title =  "Trial Balance By Detail"
  if user_info.lang_id == 4 then
    title = "گزارش تراز آزمایشی اشخاص با جزئیات "
  end
  data = {from = input.from, count = input.count, data = res_data, total = totall, sum = sum, currentdate = currentdate, title = title}
  teamyar.write_result(json.encode(data))
else
  WidgetTemplate()
end
