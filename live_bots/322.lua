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
    table.insert(res_text, { cred = record[1], deb = record[2], r = record[3] });
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
    table.insert(res_text, { deb= record[1], cred = record[2], r = record[3], crm = record[4], crm_id = record[5],client_id = record[6]});
  end
  db.query_free();
  return res_text;
end

----------------------
function loadData()
  local data = teamyar.get_data("lfbc_data")
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
  from (select distinct code i,name n from pa_client where parent=0 ]]
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
    str_title = " گزارش دفترحساب و انواع فاکتور ها به تفکیک مشتریان"
    str_lang = teamyar.get_attachment("Persian.js");
  else
    str_title = "Ledger And Factors  By Customers"
    str_lang = teamyar.get_attachment("English.js");
  end
  local template = teamyar.run_command("2/res_bot",{
      id = "bot_ledger_factors_by_crm",
      tpl_name = "html",
      title = str_title,
      body = "<div id=\\'lfbc_holder_body_html_"..random.."\\'></div>",
      script = [[
      (function(){
      ]]..str_lang..[[      
      var holder_id = '#lfbc_holder_body_html_]]..random..[[';
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
    local statuses = json.encode(input.st)
  local types = json.encode(input.ty)
  local accounts = json.encode(input.account_id)
  local chash_data = { lfbc_org_id = org_id, lfbc_gn = input.gn, lfbc_datet = datet, lfbc_datef = datef,                               
                                  lfbc_crm = input.crm, lfbc_cn = input.cn, lfbc_accounts = accounts, 
    							  lfbc_ty = types, lfbc_st = statuses
    							 , lfbc_section =  input.section, lfbc_sn = input.sn}
  teamyar.set_data("lfbc_data", json.encode(chash_data));
  if datet ~= nil  and datet ~= "" then 
    datet=datet + (24 * 60 * 60 * 10000000);
  end
  local with_str = [[ with decimaln as (select coalesce((select case when decimal_count>0 then decimal_count else fee_decimal end),0 )d
  							 from PA_SYMBOLS ps inner join PA_ORGANIZATIONS po on ps.id=po.BASE_CURRENCY where po.org_id=]]..org_id..[[ and ps.org_id=]]..org_id..[[  ), 
  decimal_discount as (select decimal_count d  ,i.id fid from  PA_SYMBOLS ps  inner join sales_invoice i on i.SYMBOL_ID=ps.id where ps.org_id=]]..org_id..[[ )]]
  local qselect =  [[ select sum(deb)deb,sum(cred) cred,sum(r)r,crm,crm_id,client_id from
  							( (SELECT distinct _oc.id fi,
                            sum(( ((_od.BASE_SYMBOL_FEE) /power(10 ,(select d from decimaln))) 
                              * (_od.QUANTITY_CONFIRMED / power(10 ,coalesce( _ok.DECIMAL_NUM , 0 ) ) )) 
                              - ((_od.DISCOUNT/power(10 ,(select d from decimal_discount where fid=_oc.id)))
                              *(_od.SYMBOL_RATE/1000000) ) + _od.VALUE_ADDED ) over (partition by _oc.ID) + 
                              coalesce((select sum((select case when effect=1 then quantity*(-1) else quantity end))
                              from sales_invoice_additions where invoice_id =_oc.id),0)   deb
                            ,0 cred,
                            sum(( ((_od.BASE_SYMBOL_FEE) /power(10 ,(select d from decimaln))) 
                              * (_od.QUANTITY_CONFIRMED / power(10 ,coalesce( _ok.DECIMAL_NUM , 0 ) ) )) 
                              - ((_od.DISCOUNT/power(10 ,(select d from decimal_discount where fid=_oc.id)))
                              *(_od.SYMBOL_RATE/1000000) ) + _od.VALUE_ADDED ) over (partition by _oc.ID) + 
                              coalesce((select sum((select case when effect=1 then quantity*(-1) else quantity end))
                              from sales_invoice_additions where invoice_id =_oc.id),0)   r,
                  			_oi.FULLNAME crm,  _oi.id crm_id,_of.id client_id 
                            FROM `0000000`.`SALES_INVOICE` _oc inner join PA_ORGANIZATIONS po on po.org_id=_oc.org_id  JOIN `0000000`.`SALES_INVOICE_PRODUCT` _od ON (_od.INVOICE_ID = _oc.ID) 
                            JOIN `0000000`.`PA_FISCAL_YEAR` _oe ON (_oe.ORG_ID = _oc.ORG_ID AND _oe.START_DATE <= _oc.RUN_DATE AND _oe.END_DATE >= _oc.RUN_DATE) JOIN 
                            `0000000`.`PA_CLIENT` _of ON (_of.ID = _oc.CLIENT_ID AND _of.ORG_ID = _oc.ORG_ID AND _of.TYPE = '1') JOIN `0000000`.`PROFILE_MAIN` 
                            _oi ON (_oi.ID = _of.REFFERE_ID AND _oi.TYPE = '1') LEFT JOIN `0000000`.`PA_FLOATING` _og ON (_og.ID = _oc.FLOATING_ID) LEFT JOIN `0000000`.`PA_ACCOUNT` 
                            _oh ON (_oh.ID = _oc.ACCOUNT_ID) LEFT JOIN `0000000`.`WH_PRODUCT` _oj ON (_oj.ID = _od.PRODUCT_ID) LEFT JOIN `0000000`.`WH_STOCK_CAPACITY` 
                            _ok ON (_ok.ID = _oj.CAPACITY_ID) WHERE _od.CLOSE_FLAG=0  and (_oc.DELETED = '0') AND (_oc.ORG_ID =]]..org_id..[[) ]]
  if  datef ~= nil and datet ~= nil and datef ~= "" and datet ~= ""    then 
    qselect = qselect..[[ and  _oc.RUN_DATE <=]]..datet..[[ and  _oc.RUN_DATE >=]]..datef
  end
  if  input.crm ~= nil and input.crm ~= nil   then 
    qselect = qselect..[[  and _of.ID=]]..input.crm
  end
    if  input.section ~= nil and input.section ~= nil   then 
    qselect = qselect..[[  and _of.code like ']]..input.section..[[%' ]]
  end
  teamyar.write_log( json.encode(input.crmty) )
     if  input.crmty ~= nil and  input.crmty ~= "null" and input.crmty =="0" then 
    qselect=qselect..[[ and   _of.type=0]]
  end 
  if  input.crmty ~= nil  and  input.crmty ~= "null" and input.crmty =="1"   then 
        qselect=qselect..[[ and   _of.type=1]]
  end
   local ids_ty = ""
  local ids_st = ""
  --------------
  if type(input.ty) == "number"   then   
    ids_ty = input.ty
  else
    for i, v in ipairs(input.ty) do
      if v == 0 then
        ids_ty = v;
      end
      if  ids_ty == "" then
        ids_ty = ids_ty..tostring(v.id);
      else
        ids_ty = ids_ty..","..tostring(v.id);
      end
    end
  end
  --------------
  if type(input.st) == "number"   then   
    ids_st = input.st
  else
    for i, v in ipairs(input.st) do
      if v == 0 then
        ids_st = v;
      end
      if  ids_st =="" then
        ids_st = ids_st..tostring(v.id);
      else
        ids_st = ids_st..","..tostring(v.id);
      end
    end
  end
  if  ids_ty ~= nil and ids_ty ~= ""  then 
    qselect = qselect..[[ and   _oc.TYPE in (]]..ids_ty..[[) ]]
  end

  if  ids_st ~= nil and ids_st ~= ""  then 
    qselect = qselect..[[ and  _oc.STATUS in (]]..ids_st..[[) ]]
  end
  qselect = qselect..[[ GROUP BY _oc.ID,_oc.TITLE,_oc.INVOICE_CODE,_oc.INVOICE_ID,_oc.FLOATING_ID, _oc.ORG_ID,_oc.CLIENT_ID,_oc.ACCOUNT_ID,_oc.PRE_INVOICE,_oc.STATUS,_oc.TYPE,_oc.RUN_DATE,_oh.CODE,
                                  _oh.NAME,_of.CODE,_of.NAME,_oi.FULLNAME,_og.CODE, _og.NAME,_od.BASE_SYMBOL_FEE,_od.QUANTITY_CONFIRMED_SEC,_od.DISCOUNT,_od.VALUE_ADDED, _oc.RECEPTION_AMOUNT,
                                  _oc.RECEPTION_AMOUNT_TEXT,_oc.SYMBOL_ID,_od.ID,_ok.NAME,_ok.DECIMAL_NUM,_ok.ID)
                                  union
                                  ( select 0 fi,
                                  coalesce(sum(vr.deb)/POWER(10,COALESCE( ( (select DECIMAL_COUNT from PA_SYMBOLS ps inner join PA_ORGANIZATIONS po on ps.id=po.BASE_CURRENCY  where po.org_id=]]..org_id..[[ and ps.org_id=]]..org_id..[[ )) ,0))) deb,
                                  coalesce(sum(vr.CRd)/POWER(10,COALESCE( ( (select DECIMAL_COUNT from PA_SYMBOLS ps inner join PA_ORGANIZATIONS po on ps.id=po.BASE_CURRENCY  where po.org_id=]]..org_id..[[ and ps.org_id=]]..org_id..[[)) ,0))) cred , 
                                  sum(vr.deb)-sum(vr.CRd)r,
                                  (select name from pa_client where id=vr.client_id and org_id = v.org_id)crm,(select reffere_id from pa_client where id=vr.client_id  and org_id = v.org_id) crm_id,vr.client_id from pa_voucher v inner join 
                                  pa_voucher_record vr on v.id=vr.voucher_id where v.org_id=]]..org_id..[[ and vr.org_id=]]..org_id
  if  input.crm ~= nil and input.crm ~= nil   then 
    qselect=qselect..[[ and vr.client_id=]]..input.crm
  end
      if  input.section ~= nil and input.section ~= nil   then 
    qselect = qselect..[[  and (select code from pa_client where id= vr.client_id limit 1) like ']]..input.section..[[%' ]]
  end
    if  input.crmty ~= nil   then 
    qselect=qselect..[[ and  (select type from pa_client where id=vr.client_id)=]]..input.crmty
  end 
  if  datef ~= nil and datet ~= nil and datef ~= "" and datet ~= ""    then 
    qselect=qselect.. [[ and (( v.RUN_DATE <=]]..datet..[[ and v.RUN_DATE >=]]..datef..[[) or (v.RUN_DATE <=]]..datef..[[  and v.RUN_DATE >=(select start_date from pa_fiscal_year where START_DATE <=]]..datef..[[  and END_DATE >=]]..datet..[[  and org_id=]]..org_id..[[ )))]]
  end
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
  if ids ~= nill and ids ~= "" then 
    qselect = qselect.. [[ and (select code from pa_account where id=vr.account_id and org_id= v.org_id) like  N']]..ids..[[%' ]]
  end 
  qselect = qselect..[[  and vr.deleted=0 and v.deleted=0 
                                    and ((select status from pa_pdc where id=vr.PDC_ID and org_id=v.org_id)<>3  or (select status from pa_pdc where id=vr.PDC_ID and org_id=v.org_id) is null) 
                                    group by vr.client_id))tt where 1=1 ]]
  if input.category ~= nil then
    qselect = qselect..[[  and  crm_id in (select  p.reffere_id  from crm_classify_person cp inner join crm_cross c on cp.profile_id= c.refere_id inner join pa_client p on  p.reffere_id=c.client_id where cp.id=]]..input.category..[[)]]
  end
    qselect = qselect..[[ group by crm,crm_id,client_id order by crm ]]
  local query_select = qselect.. [[ limit ?,? ]]
  teamyar.write_log(with_str..query_select)
  res_data = queryResult2(with_str..query_select , {input.from, input.count})
  -------------------
  local qtotal = [[select count(*) c from  ( ]]..qselect..[[)as t]]
  local qsum = [[select sum(cred) cred,sum(deb),sum(r) r from  ( ]]..qselect..[[)as t ]]
  --  teamyar.write_log(qsum)
  local  totall = queryResult(with_str..qtotal, {})
  local sum = queryResultSum(with_str..qsum, {})
  local title =  "Ledger And Factor By Customer"
  if user_info.lang_id == 4 then
    title = "گزارش دفترحساب و انواع فاکتور ها به تفکیک مشتریان"
  end
  data = {from = input.from, count = input.count, data = res_data, total = totall, sum = sum, currentdate = currentdate, title = title}
  teamyar.write_result(json.encode(data))
else
  WidgetTemplate()
end
