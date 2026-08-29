--Bot Total Expense zmo
input = teamyar.get_input();
local user_info = teamyar.get_user_info();
local user_id = math.floor(user_info["id"]); 
local org_id = input.org_id;
if org_id == nil then
  org_id = 0;
end
local datef = input.df;
local datet = input.dt;
if account_id == nill then 
  account_id = "";
end 
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
    table.insert(res_text, { cred = record[1], deb = record[2] ,dif = record[3], rem= record[4], per = record[5]});
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
    table.insert(res_text, { prj = record[1],  deb= record[2], cred = record[3], r = record[4],rem = record[5], crm = record[6], dif = record[7], per = record[8]});
  end
  db.query_free();
  return res_text;
end

----------------------
function loadData()
  local data = teamyar.get_data("lfbpp_data")
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
function projectAcl(data)
  local geted_org_id = data.org_id;
  local query_param = [[ SELECT JSON_ARRAYAGG(JSON_OBJECT('id',i, 'name',n, 'type',1))
                                      from (select id i,name n from pa_project where 1=1]]
  if geted_org_id ~ 0 then 
    query_param = query_param..[[ and org_id=]]..geted_org_id
  end 
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param ..  [[ and name like N'%]]..data.search..[[%'  ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count)..[[)tmp ]];   
  teamyar.write_result(queryResult(query_param , {}));
end
----------------------
function floatingAcl(data)
  local geted_org_id = data.org_id;
  local query_param = [[ SELECT JSON_ARRAYAGG(JSON_OBJECT('id',i, 'name',n, 'type',1))
                                      from (select id i,name n from pa_floating where 1=1]]
  if geted_org_id ~ 0 then 
    query_param = query_param..[[ and org_id=]]..geted_org_id
  end 
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param ..  [[ and name like N'%]]..data.search..[[%'  ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count)..[[)tmp ]];   
  teamyar.write_result(queryResult(query_param , {}));
end
----------------------
function customerAcl(data)
  local query_param = [[ SELECT JSON_ARRAYAGG(JSON_OBJECT('id',i, 'name',n, 'type',1))
  from (select id i ,concat(code,'_',name)n from pa_client where  type=1 and VOUCHER_ALLOW=1   ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param ..  [[ and name like N'%]]..data.search..[[%' or  code like  N'%]]..data.search..[[%' ]]
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
    str_title = "گزارش دفترحساب و انواع فاکتور ها به تفکیک  درصد حداقل پیش پرداخت"
    str_lang = teamyar.get_attachment("Persian.js");
  else
    str_title = "Ledger And Factors By Peyment Percent"
    str_lang = teamyar.get_attachment("English.js");
  end
  local template = teamyar.run_command("2/res_bot",{
      id = "bot_ledger_factors_bpp",
      tpl_name = "html",
      title = str_title,
      body = "<div id=\\'lfbpp_holder_body_html_"..random.."\\'></div>",
      script = [[
      (function(){
      ]]..str_lang..[[      
      var holder_id = '#lfbpp_holder_body_html_]]..random..[[';
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
  projectAcl(input.data)
elseif  input.type == 7 then 
  customerAcl(input.data)
elseif input.type == 1 then 

  local accounts = json.encode(input.account_id)
    local statuses = json.encode(input.st)
  local types = json.encode(input.ty)
  local chash_data = { lfbpp_org_id = org_id, lfbpp_gn = input.gn, lfbpp_accounts = accounts, lfbpp_datet = datet, lfbpp_datef = datef,
                                  lfbpp_prj = input.prj, lfbpp_pn = input.pn,
                                  lfbpp_crm = input.crm, lfbpp_cn = input.cn, lfbpp_per = input.per, lfbpp_pern = input.pern, lfbpp_define=input.define, lfbpp_dn=input.dn,  lfbpp_ty = types, lfbpp_st = statuses}
  teamyar.set_data("lfbpp_data", json.encode(chash_data));
  if datet ~= nill  and datet ~= "" then 
    datet=datet + (24 * 60 * 60 * 10000000);
  end
  local percent_payment = 70
  if input.per ~= nil then 
    percent_payment = tonumber(input.per)*10
  end 
    local with_str = [[ with decimaln as (select coalesce((select case when decimal_count>0  then decimal_count else fee_decimal end),0 )d 
  							from PA_SYMBOLS ps inner join PA_ORGANIZATIONS po on ps.id=po.BASE_CURRENCY where po.org_id=]]..org_id..[[)]]
  local qselect =  [[ select * from (select prj,sum(deb)deb,sum(cred)cred,sum(r)r,(sum(deb)-sum(cred))rem,crm,sum(dif)dif,sum(per)per from (  select prj,deb,cred,r,crm,
                            round(deb*]]..percent_payment..[[/100) per,
                            round((deb*]]..percent_payment..[[/100)-cred )dif 
  from
  							( (SELECT 
                           _oc.id fi,  COALESCE( (select name from pa_project where id=_oc.project_id),'--') prj,
                           round( sum((_od.BASE_SYMBOL_FEE * (_od.QUANTITY_CONFIRMED / power(10 ,coalesce( _ok.DECIMAL_NUM , 0 ) ) )) - _od.DISCOUNT + _od.VALUE_ADDED ) over (partition by _oc.ID) +
                            coalesce((select sum((select case when effect=1 then quantity*(-1) else quantity end)) from sales_invoice_additions where invoice_id =_oc.id),0))/power(10 ,(select d from decimaln)) deb
                            ,0 cred,
                            round(sum((_od.BASE_SYMBOL_FEE * (_od.QUANTITY_CONFIRMED / power(10 ,coalesce( _ok.DECIMAL_NUM , 0 ) ) )) - _od.DISCOUNT + _od.VALUE_ADDED ) over (partition by _oc.ID)
                            +coalesce((select sum((select case when effect=1 then quantity*(-1) else quantity end)) from sales_invoice_additions where invoice_id =_oc.id),0))/power(10 ,(select d from decimaln)) r,
                              _oi.FULLNAME crm,0 account_id 
                            FROM `0000000`.`SALES_INVOICE` _oc inner join PA_ORGANIZATIONS po on po.org_id=_oc.org_id  JOIN `0000000`.`SALES_INVOICE_PRODUCT` _od ON (_od.INVOICE_ID = _oc.ID) 
                            JOIN `0000000`.`PA_FISCAL_YEAR` _oe ON (_oe.ORG_ID = _oc.ORG_ID AND _oe.START_DATE <= _oc.RUN_DATE AND _oe.END_DATE >= _oc.RUN_DATE) JOIN 
                            `0000000`.`PA_CLIENT` _of ON (_of.ID = _oc.CLIENT_ID AND _of.ORG_ID = _oc.ORG_ID AND _of.TYPE = '1') JOIN `0000000`.`PROFILE_MAIN` 
                            _oi ON (_oi.ID = _of.REFFERE_ID AND _oi.TYPE = '1') LEFT JOIN `0000000`.`PA_FLOATING` _og ON (_og.ID = _oc.FLOATING_ID) LEFT JOIN `0000000`.`PA_ACCOUNT` 
                            _oh ON (_oh.ID = _oc.ACCOUNT_ID) LEFT JOIN `0000000`.`WH_PRODUCT` _oj ON (_oj.ID = _od.PRODUCT_ID) LEFT JOIN `0000000`.`WH_STOCK_CAPACITY` 
                            _ok ON (_ok.ID = _oj.CAPACITY_ID) WHERE _od.CLOSE_FLAG=0 and  (_oc.DELETED = '0') AND (_oc.ORG_ID =]]..org_id..[[) ]]
  if  datef ~= nil and datet ~= nil and datef ~= "" and datet ~= ""    then 
    qselect = qselect..[[ and  _oc.RUN_DATE <=]]..datet..[[ and  _oc.RUN_DATE >=]]..datef
  end
  if  input.crm ~= nil and input.crm ~= nil   then 
    qselect = qselect..[[  and _of.ID=]]..input.crm
  end
  if  input.prj ~= nil and input.prj ~= nil   then 
    qselect = qselect..[[ and  _oc.Project_ID=]]..input.prj
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
                                  ( select 0 fi,COALESCE( (select name from pa_project where id=project_id),'--')   prj,
                                  coalesce(sum(vr.deb)/POWER(10,COALESCE( ( (select DECIMAL_COUNT from PA_SYMBOLS ps inner join PA_ORGANIZATIONS po on ps.id=po.BASE_CURRENCY  where po.org_id=]]..org_id..[[ limit 1)) ,0))) deb,
                                  coalesce(sum(vr.CRd)/POWER(10,COALESCE( ( (select DECIMAL_COUNT from PA_SYMBOLS ps inner join PA_ORGANIZATIONS po on ps.id=po.BASE_CURRENCY  where po.org_id=]]..org_id..[[ limit 1)) ,0))) cred , 
                                  sum(vr.deb)-sum(vr.CRd)r,
                                 (select name from pa_client where id=vr.client_id)crm,vr.account_id from pa_voucher v inner join  pa_voucher_record vr on v.id=vr.voucher_id where v.org_id=]]..org_id..[[ and vr.org_id=]]..org_id
  if  input.crm ~= nil and input.crm ~= nil   then 
    qselect=qselect..[[ and vr.client_id=]]..input.crm
  end
  if  datef ~= nil and datet ~= nil and datef ~= "" and datet ~= ""    then 
    qselect=qselect.. [[ and  v.RUN_DATE <=]]..datet..[[ and v.RUN_DATE >=]]..datef
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

  if  input.prj ~= nil and input.prj ~= nil   then 
    qselect = qselect..[[ and  vr.Project_ID=]]..input.prj
  end

  qselect = qselect..[[  and vr.deleted=0 and v.deleted=0  and ( (select status from pa_pdc where id=vr.PDC_ID)<>3  or (select status from pa_pdc where id=vr.PDC_ID) is null) group by vr.client_id,vr.PROJECT_ID,vr.account_id))tt  where 1=1 ]]
    if ids ~= nill and ids ~= "" then 
    qselect = qselect.. [[ and  account_id in (]]..ids..[[) ]]
  end 
    qselect = qselect.. [[order by crm)tmps where 1=1  ]]
  teamyar.write_log(json.encode(input.define))

   qselect = qselect.. [[and crm is not null  group by crm,prj)oo where 1=1  ]]
    if input.define~= nil and input.define=="1"  or input.define==1 then 
        qselect = qselect.. [[  and oo.r>0  ]]
  elseif input.define~= nil and input.define=="2" or  input.define==2 then 
      qselect = qselect.. [[  and oo.r<0  ]]
  end
  local query_select = qselect.. [[ limit ?,? ]]
 teamyar.write_log(with_str..query_select )
  res_data = queryResult2(with_str..query_select , {input.from, input.count})
  -------------------
  local qtotal = [[select count(*) c from  ( ]]..qselect..[[)as t]]
  local qsum = [[select sum(cred) cred,sum(deb) deb,sum(dif) dif,sum(rem) rem,sum(per) per from  ( ]]..qselect..[[)as t ]]
  local  totall = queryResult(with_str..qtotal, {})
  local sum = queryResultSum(with_str..qsum, {})
  local title =  "Ledger And Factor By Payment Percent"
  if user_info.lang_id == 4 then
    title = "گزارش دفترحساب و انواع فاکتور ها  به تفکیک درصد پیش پرداخت"
  end
  data = {from = input.from, count = input.count, data = res_data, total = totall, sum = sum, currentdate = currentdate, title = title}
  teamyar.write_result(json.encode(data))
else
  WidgetTemplate()
end
