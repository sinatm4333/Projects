--Bot Total Expense zmo
input = teamyar.get_input();
local user_info = teamyar.get_user_info();
local user_id = math.floor(user_info["id"]); 
local org_id = input.org_id;
local account_ids = input.account_ids
if org_id == nil then
  org_id = 0;
end
local datef = input.df;
local datet = input.dt;
teamyar.write_log(json.encode(datef))
teamyar.write_log(json.encode(input))
if account_ids == nill then 
  account_ids = "";
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
    table.insert(res_text, {  cred= record[1],  deb= record[2], r = record[3] });
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
    table.insert(res_text, {floating = record[1], prj = record[2], fi = record[3], d = record[4], 
        vi = record[5], vid = record[6], deb= record[7], cred = record[8], r = record[9], rg = record[10], rem = record[11], t = record[12], crm = record[13], crm_id =  record[15], content =  record[16],rall=record[18]});
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
    str_title = "گزارش جزئیات تراز آزمایشی اشخاص"
    str_lang = teamyar.get_attachment("Persian.js");
  else
    str_title = "Trial Balance Detail"
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
      var account_ids=']]..account_ids..[[';
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


if input.type == 1 then 
  datef=input.input.df;
    datet=input.input.dt;
  org_id=input.input.org_id
  if datet ~= nill  and datet ~= "" then 
    datet=datet + (24 * 60 * 60 * 10000000);
  end
  local acc_ids=input.account_ids
    local with_str = [[ with decimaln as (select coalesce((select case when decimal_count>0 then decimal_count else fee_decimal end),0 )d
                                from PA_SYMBOLS ps inner join PA_ORGANIZATIONS po on ps.id=po.BASE_CURRENCY where po.org_id=]]..org_id..[[ and ps.org_id=]]..org_id..[[  ) ,
                                vochers as ( select sum(vr.deb) deb ,sum(vr.crd ) cred,vr.CLIENT_ID clid, 
                                (select name from pa_floating where id=vr.FLOATING_ACCOUNT_ID and org_id=v.ORG_ID)floating
                                ,(select name from pa_project where id=vr.PROJECT_ID and org_id=vr.ORG_ID)prj,
                                v.run_date ,v.voucher_id vi,v.id vid, v.TITLE,vr.content,vr.id vrid from pa_voucher v inner join pa_voucher_record vr on vr.VOUCHER_ID=v.id 
                                    where  v.deleted<>1 and vr.deleted <>1 and
                                     vr.org_id=]]..org_id..[[ and v.org_id=]]..org_id
      if  datef ~= nil and datef ~= ""  then 
                                   with_str=with_str..  [[ and v.RUN_DATE >=]]..datef
  end
        if  datet ~= nil and datet ~= ""  then 
                                   with_str=with_str..  [[ and v.RUN_DATE <=]]..datet 
  end
      if  input.input.crm ~= nil and input.input.crm ~= ""   then 
  with_str=with_str.. [[ and vr.CLIENT_ID=]]..input.input.crm
  end
    if acc_ids ~= nill and acc_ids ~= "" then 
    with_str=with_str..[[ and vr.ACCOUNT_ID in (]]..acc_ids..[[) ]]
  end
    if  input.input.prj ~= nil and input.input.prj ~= nil   then 
    with_str = with_str..[[ and  vr.PROJECT_ID=]]..input.input.prj
  end
  if  input.input.floating ~= nil and input.input.floating ~= nil   then 
    with_str = with_str..[[ and  vr.FLOATING_ACCOUNT_ID=]]..input.input.floating
  end
  with_str=with_str..[[  group by vr.CLIENT_ID ,vr.FLOATING_ACCOUNT_ID,vr.PROJECT_ID,v.run_date ,v.voucher_id ,v.id , v.TITLE,vr.REFFERE_ID,vr.ACCOUNT_ID,vr.content,vr.id  ) ]]
        
 
  local qselect =  [[  select *  ,sum(r)over (order by vrid desc)from (select floating,prj,0 fi,run_date,vi, vid,coalesce(vo.deb/POWER(10,COALESCE( (select DECIMAL_COUNT from PA_SYMBOLS ps inner join
                                PA_ORGANIZATIONS po on ps.id=po.BASE_CURRENCY where po.org_id=]]..org_id..[[  limit 1) )),0) deb
                                , coalesce(vo.cred/POWER(10,COALESCE( ( (select DECIMAL_COUNT from PA_SYMBOLS ps inner join 
                                PA_ORGANIZATIONS po on ps.id=po.BASE_CURRENCY where po.org_id=]]..org_id..[[  limit 1)) ,0))) cred 
                                , (vo.deb- vo.cred)/POWER(10,COALESCE( ( (select DECIMAL_COUNT from PA_SYMBOLS ps inner join 
  								PA_ORGANIZATIONS po on ps.id=po.BASE_CURRENCY where po.org_id=2 limit 1)),0))r, 0 rg,0 rem ,title,(select name from pa_client where id=vo.clid and org_id=]]..org_id..[[ )crm,
                                (select reffere_id from pa_client where id= vo.clid and org_id=]]..org_id..[[ ) crm_id,vo.clid,content,vo.vrid from vochers vo where 1=1 and vo.clid= ]]..input.input.crm

  qselect = qselect.. [[ order by run_date)mm ]]
  
  local query_select = qselect.. [[ limit ?,? ]]
  
  teamyar.write_log(with_str..query_select)
  res_data = queryResult2(with_str..query_select , {input.from, input.count})
  -------------------
  local qtotal = [[select count(*) c from  ( ]]..qselect..[[)as t]]
  local qsum = [[select sum(cred) cred,sum(deb)deb,sum(r) r from  ( ]]..qselect..[[)as t ]]
  local  totall = queryResult(with_str..qtotal, {})
  local sum = queryResultSum(with_str..qsum, {})
  local title =  "Trial Balance Detail"
  if user_info.lang_id == 4 then
    title = "گزارش جزئیات تراز آزمایشی اشخاص"
  end

  data = {from = input.from, count = input.count, data = res_data, total = totall, sum = sum, currentdate = currentdate, title = title, menu = 1023}
  teamyar.write_result(json.encode(data))
else
  WidgetTemplate()
end
