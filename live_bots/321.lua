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
teamyar.write_log(json.encode(datef))
teamyar.write_log(json.encode(input))
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
    table.insert(res_text, {floating = record[1], prj = record[2], fid = record[3],fi = record[4], d = record[5], 
        vi = record[6], vid = record[7], deb= record[8], cred = record[9], r = record[10], rg = record[11], rem = record[12], t = record[13], crm = record[14], crm_id =  record[15]});
    --   vi = record[6], vid = record[7], deb= record[8], cred = record[9], r = record[10], t = record[11], crm = record[12], crm_id =  record[13], rg = record[14], rem = record[15]});
  end
  db.query_free();
  return res_text;
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



-----------------------------------------------
function WidgetTemplate()  
  local random = math.random(1,1000);
  local script =  teamyar.get_attachment("main.js");
  local css =  teamyar.get_attachment("main.css");
  local  str_lang = "";
  local  str_title = "";
  if user_info.lang_id == 4 then
    str_title = "گزارش دفترحساب و انواع فاکتور ها"
    str_lang = teamyar.get_attachment("Persian.js");
  else
    str_title = "Ledger And Factors"
    str_lang = teamyar.get_attachment("English.js");
  end
  local template = teamyar.run_command("2/res_bot",{
      id = "bot_ledger_factors",
      tpl_name = "html",
      title = str_title,
      body = "<div id=\\'lf_holder_body_html_"..random.."\\'></div>",
      script = [[
      (function(){
      ]]..str_lang..[[      
      var holder_id = '#lf_holder_body_html_]]..random..[[';
      var random_id = ]] .. random .. [[;
      var lua_input=]]..json.encode(input)..[[; 
      ]]..script..[[
    })();
      ]],
      css = css
    });
  teamyar.write_result(template); 
end
---------------------main

teamyar.write_log(json.encode(teem))
if input.type == 1 then 
  datef=input.input.df;
    datet=input.input.dt;
  org_id=input.input.org_id
  if datet ~= nill  and datet ~= "" then 
    datet=datet + (24 * 60 * 60 * 10000000);
  end
  
    local with_str = [[
                            with vochers as ( select sum(deb)deb ,sum(cred)cred from( select 
                            coalesce(vr.deb/POWER(10,COALESCE( ( (select DECIMAL_COUNT from PA_SYMBOLS ps inner join PA_ORGANIZATIONS po on ps.id=po.BASE_CURRENCY where po.org_id=]]..org_id..[[ limit 1)) ,0)))deb 
                            ,  coalesce(vr.crd/POWER(10,COALESCE( ( (select DECIMAL_COUNT from PA_SYMBOLS ps inner join PA_ORGANIZATIONS po on ps.id=po.BASE_CURRENCY where po.org_id=]]..org_id..[[ limit 1)) ,0)))cred
                            from pa_voucher v inner join  pa_voucher_record vr on vr.VOUCHER_ID=v.id
                            where vr.R_TYPE=14
                            and vr.client_id>0 and vr.type=20 and vr.org_id=]]..org_id..[[ and v.org_id=]]..org_id

  if  input.input.prj  ~= nil and input.input.prj  ~= nil   then 
    with_str = with_str..[[ and  vr.PROJECT_ID=]]..input.input.prj 
  end
  if input.input.floating~= nil and input.input.floating ~= nil   then 
    with_str = with_str..[[ and  vr.FLOATING_ACCOUNT_ID=]]..input.input.floating
  end
  if  datef ~= nil and datet ~= nil and datef ~= "" and datet ~= ""    then 
    with_str = with_str..[[ and  v.RUN_DATE <=]]..datet..[[ and  v.RUN_DATE >=]]..datef
  end
  with_str=with_str..[[)nk ),  decimaln as (select coalesce((select case when decimal_count>0  then decimal_count else fee_decimal end),0 )d 
  							from PA_SYMBOLS ps inner join PA_ORGANIZATIONS po on ps.id=po.BASE_CURRENCY where po.org_id=]]..org_id..[[ and ps.org_id= ]]..org_id..[[ ),
  decimal_discount as (select decimal_count d  ,i.id fid from  PA_SYMBOLS ps  inner join sales_invoice i on i.SYMBOL_ID=ps.id where ps.org_id=]]..org_id..[[ )]]  
  
  
 
  local qselect=  [[ select floating,prj,fid,fi,d,vi,vid,deb,cred,r, sum(r) over (order by count) rg,lag(r,1,0) over (order by count)rem,t,crm,crm_id from
  							(select *, row_number() over (order by  d)count from ( 
  
  
  (  select "" floating,"" prj,-1 fid,0 fi,0 d,0 vi ,0 vid,sum(deb)deb,sum(crd)cred ,(sum(deb)-sum(crd))r, "FIRST_PRIOD_EXSITANCE" t,"" crm,0 crm_id ,0 ACCOUNT_ID
                            from  pa_voucher v inner join pa_voucher_record vr on vr.VOUCHER_ID=v.id  where    v.org_id=]]..org_id..[[  and v.org_id =]]..org_id
  --where status
  if  datef ~= nil and datet ~= nil and datef ~= "" and datet ~= ""    then 
     qselect = qselect..[[ and  v.RUN_DATE <=]]..datef..[[ and  v.RUN_DATE >=(select start_date from pa_fiscal_year where START_DATE <=]]..datef..[[ and END_DATE >=]]..datet..[[ and org_id =]]..org_id..[[ ) ]]
  end


  if  input.input.crm ~= nil and input.input.crm ~= nil   then 
qselect = qselect..[[  and CLIENT_ID=]]..input.input.crm
  end
  if  input.input.prj ~= nil and input.input.prj ~= nil   then 
    qselect = qselect..[[ and  vr.PROJECT_ID=]]..input.input.prj
  end
  if  input.input.floating ~= nil and input.input.floating ~= nil   then 
qselect = qselect..[[ and  vr.FLOATING_ACCOUNT_ID=]]..input.input.floating
  end
qselect = qselect.. [[)
  
  
  union (SELECT DISTINCT COALESCE((select name from pa_floating where id=_oc.FLOATING_ID and org_id= ]]..org_id..[[),'--') floating,
                            COALESCE( (select name from pa_project where id=_oc.project_id and org_id= ]]..org_id..[[),'--') prj,_oc.id fid,_oc.invoice_id fi, _oc.RUN_DATE d, 0 vi, 0 vid,
                               sum(( ((_od.BASE_SYMBOL_FEE) /power(10 ,(select d from decimaln))) 
                              * (_od.QUANTITY_CONFIRMED / power(10 ,coalesce( _ok.DECIMAL_NUM , 0 ) ) )) 
                              - ((_od.DISCOUNT/power(10 ,(select d from decimal_discount where fid=_oc.id)))
                              *(_od.SYMBOL_RATE/1000000) ) + _od.VALUE_ADDED ) over (partition by _oc.ID) + 
                              coalesce((select sum((select case when effect=1 then quantity*(-1) else quantity end))
                              from sales_invoice_additions where invoice_id =_oc.id),0)  deb
                            ,0 cred,
                                sum(( ((_od.BASE_SYMBOL_FEE) /power(10 ,(select d from decimaln))) 
                              * (_od.QUANTITY_CONFIRMED / power(10 ,coalesce( _ok.DECIMAL_NUM , 0 ) ) )) 
                              - ((_od.DISCOUNT/power(10 ,(select d from decimal_discount where fid=_oc.id)))
                              *(_od.SYMBOL_RATE/1000000) ) + _od.VALUE_ADDED ) over (partition by _oc.ID) + 
                              coalesce((select sum((select case when effect=1 then quantity*(-1) else quantity end))
                              from sales_invoice_additions where invoice_id =_oc.id),0)  r,
                            _oc.TITLE t,   _oi.FULLNAME crm,_oi.id crm_id, 0 account_id 
                            FROM `0000000`.`SALES_INVOICE` _oc inner join PA_ORGANIZATIONS po on po.org_id=_oc.org_id  JOIN `0000000`.`SALES_INVOICE_PRODUCT` _od ON (_od.INVOICE_ID = _oc.ID) 
                            JOIN `0000000`.`PA_FISCAL_YEAR` _oe ON (_oe.ORG_ID = _oc.ORG_ID AND _oe.START_DATE <= _oc.RUN_DATE AND _oe.END_DATE >= _oc.RUN_DATE) JOIN 
                            `0000000`.`PA_CLIENT` _of ON (_of.ID = _oc.CLIENT_ID AND _of.ORG_ID = _oc.ORG_ID AND _of.TYPE = '1') JOIN `0000000`.`PROFILE_MAIN` 
                            _oi ON (_oi.ID = _of.REFFERE_ID AND _oi.TYPE = '1') LEFT JOIN `0000000`.`PA_FLOATING` _og ON (_og.ID = _oc.FLOATING_ID) LEFT JOIN `0000000`.`PA_ACCOUNT` 
                            _oh ON (_oh.ID = _oc.ACCOUNT_ID) LEFT JOIN `0000000`.`WH_PRODUCT` _oj ON (_oj.ID = _od.PRODUCT_ID) LEFT JOIN `0000000`.`WH_STOCK_CAPACITY` 
                            _ok ON (_ok.ID = _oj.CAPACITY_ID) WHERE _od.CLOSE_FLAG=0  and (_oc.DELETED = '0') AND (_oc.ORG_ID =]]..org_id..[[)  and _oc.TYPE in (5) and _oc.STATUS in (1,2) ]]
  if  datef ~= nil and datet ~= nil and datef ~= "" and datet ~= ""    then 
    qselect = qselect..[[ and  _oc.RUN_DATE <=]]..datet..[[ and  _oc.RUN_DATE >=]]..datef
  end
  if  input.input.crm ~= nil and input.input.crm ~= nil   then 
    qselect = qselect..[[  and _of.ID=]]..input.input.crm
  end
  if  input.input.prj ~= nil and input.input.prj ~= nil   then 
    qselect = qselect..[[ and  _oc.Project_ID=]]..input.input.prj
  end
  if  input.input.floating ~= nil and input.input.floating ~= nil   then 
    qselect = qselect..[[ and  _oc.FLOATING_ID=]]..input.input.floating
  end
  
  qselect = qselect..[[ GROUP BY _oc.ID,_oc.TITLE,_oc.INVOICE_CODE,_oc.INVOICE_ID,_oc.FLOATING_ID, _oc.ORG_ID,_oc.CLIENT_ID,_oc.ACCOUNT_ID,_oc.PRE_INVOICE,_oc.STATUS,_oc.TYPE,_oc.RUN_DATE,_oh.CODE,
                                  _oh.NAME,_of.CODE,_of.NAME,_oi.FULLNAME,_og.CODE, _og.NAME,_od.BASE_SYMBOL_FEE,_od.QUANTITY_CONFIRMED_SEC,_od.DISCOUNT,_od.VALUE_ADDED, _oc.RECEPTION_AMOUNT,
                                  _oc.RECEPTION_AMOUNT_TEXT,_oc.SYMBOL_ID,_od.ID,_ok.NAME,_ok.DECIMAL_NUM,_ok.ID)
                                  union
                                  ( select COALESCE((select name from pa_floating where id=floating_account_id and org_id= ]]..org_id..[[),'--') floating, COALESCE( (select name from pa_project where id=project_id and org_id= ]]..org_id..[[),'--')   prj,0 fid,0 fi,v.run_date d, v.voucher_id vi,v.id vid,
                                  coalesce(sum(vr.deb)/POWER(10,COALESCE( ( (select DECIMAL_COUNT from PA_SYMBOLS ps inner join PA_ORGANIZATIONS po on ps.id=po.BASE_CURRENCY  where po.org_id=]]..org_id..[[ and ps.org_id= ]]..org_id..[[)) ,0))) deb,
                                  coalesce(sum(vr.CRd)/POWER(10,COALESCE( ( (select DECIMAL_COUNT from PA_SYMBOLS ps inner join PA_ORGANIZATIONS po on ps.id=po.BASE_CURRENCY  where po.org_id=]]..org_id..[[ and ps.org_id= ]]..org_id..[[)) ,0))) cred , 
                                  sum(vr.deb)-sum(vr.CRd)r,
                                  v.title t,(select name from pa_client where id=vr.client_id and org_id= ]]..org_id..[[)crm,(select reffere_id from pa_client where id=vr.client_id and org_id= ]]..org_id..[[) crm_id,vr.account_id  from pa_voucher v inner join 
                                  pa_voucher_record vr on v.id=vr.voucher_id where v.org_id=]]..org_id..[[ and vr.org_id=]]..org_id
  if  input.input.crm ~= nil and input.input.crm ~= nil   then 
    qselect=qselect..[[ and vr.client_id=]]..input.input.crm
  end
  if  datef ~= nil and datet ~= nil and datef ~= "" and datet ~= ""    then 
    qselect=qselect.. [[ and  v.RUN_DATE <=]]..datet..[[ and v.RUN_DATE >=]]..datef
  end


  if  input.input.prj ~= nil and input.input.prj ~= nil   then 
    qselect = qselect..[[ and  vr.Project_ID=]]..input.input.prj
  end
  if  input.input.floating ~= nil and input.input.floating ~= nil   then 
    qselect = qselect..[[ and  vr.floating_account_id=]]..input.input.floating
  end
  qselect = qselect..[[  and vr.deleted=0 and v.deleted=0
                                    and ((select status from pa_pdc where id=vr.PDC_ID)<>3  or (select status from pa_pdc where id=vr.PDC_ID) is null) 
                                    group by floating_account_id,project_id,v.run_date ,v.id,v.title ,vr.client_id,vr.account_id))kk)tt where 1=1 ]]

  qselect = qselect.. [[order by d ]]
  local query_select = qselect.. [[ limit ?,? ]]
  
  teamyar.write_log(with_str..query_select)
  res_data = queryResult2(with_str..query_select , {input.from, input.count})
  -------------------
  local qtotal = [[select count(*) c from  ( ]]..qselect..[[)as t]]
  local qsum = [[select sum(cred) cred,sum(deb)deb,sum(r) r from  ( ]]..qselect..[[)as t ]]
    
  -- teamyar.write_log(qsum)
  local  totall = queryResult(with_str..qtotal, {})
  local sum = queryResultSum(with_str..qsum, {})
  local title =  "Ledger And Factor"
  if user_info.lang_id == 4 then
    title = "گزارش دفترحساب و انواع فاکتور ها"
  end

  data = {from = input.from, count = input.count, data = res_data, total = totall, sum = sum, currentdate = currentdate, title = title, menu = 1023}
  teamyar.write_result(json.encode(data))
else
  WidgetTemplate()
end
