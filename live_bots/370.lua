--Bot Ledger 26 Row zmo
--ver 002
--start date:1403-2-26
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
if account_id == nil then 
  account_id = "";
end 
---------------------------------------------
function loadData()
  local data = teamyar.get_data("l26_data")
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
--------------------------------
function queryResultSum(select_query,user_param)
  db.use_db("0000000")
    local params1 = {
      query = select_query,
      params = user_param
  }
  db.query(params1);
  local record = {}
  local all = {}
  while db.query_fetch(record) do
     table.insert(all, { crd = record[1], deb = record[2]} )
 end
  db.query_free();
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
    local acc_level=data.acc_level;
  local query_param = [[ SELECT JSON_ARRAYAGG(JSON_OBJECT('id',i, 'name',n, 'type',1))
  from (select code i,concat('#',code,'_',name)n from pa_account where 1=1 ]] 
  if geted_org_id~=0 then 
    query_param =query_param..[[ and org_id=]]..geted_org_id
  end 
    if acc_level~=0 then 
    if acc_level==4 then
         query_param =query_param..[[ and level >=4]]
    else
         query_param =query_param..[[ and level =]]..acc_level
    end
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
  local  str_title="";
  if user_info.lang_id == 4 then
    str_title="گزارش دفتر کل با 26 ردیف"
    str_lang = teamyar.get_attachment("Persian.js");
  else
    str_title="Ledger Report With 26 Row"
    str_lang = teamyar.get_attachment("English.js");
  end
  local template = teamyar.run_command("2/res_bot",{
      id = "bot_ledger_26_row",
      tpl_name = "html",
      title = str_title,
      body = "<div id=\\'l26_holder_body_html_"..random.."\\'></div>",
      script=[[
      (function(){
      ]]..str_lang..[[      
      var holder_id = '#l26_holder_body_html_]]..random..[[';
      var random_id = ]] .. random .. [[;
      ]]..script..[[
    })();
      ]],
      css = css
    });
  teamyar.write_result(template); 
end
----------------------
function getData(paging)
    if datet ~= nill  and datet ~= "" then 
    datet=datet + (24 * 60 * 60 * 10000000);
  end
  if datef ~= nil  and datef ~= "" then 
    datef = datef - (20 * 10000000);
  end
  local code_lenght=30 --max
  if input.acc_level==1 then 
    code_lenght= 1
  elseif input.acc_level==2 then 
        code_lenght= 3
  elseif input.acc_level==3 then
     code_lenght= 5
      elseif input.acc_level==4 then
     code_lenght= 7
  end
  
  local qselect = [[select ACCOUNT_ID,sum(crd)crd,sum(deb)deb,voucher_id,cmt,debcrd,truedate,vid,sum(rem)  rem  from 
  							( select ACCOUNT_ID,sum(crd)crd,sum(deb)deb,voucher_id,cmt,debcrd,truedate,vid,sum(rem) over (order by record_id) rem from ( 
  							 SELECT   (select concat('#',code,'_',name) from Pa_account where code=substring(_gd.code,1,]]..code_lenght..[[)  and org_id=]]..org_id..[[ ) ACCOUNT_ID
                            ,SUM(coalesce(_gc.CRD/POWER(10,COALESCE( ( (select DECIMAL_COUNT from PA_SYMBOLS ps inner join PA_ORGANIZATIONS po on ps.id=po.BASE_CURRENCY  where po.org_id=]]..org_id..[[ limit 1)) ,0)))) crd,
                            SUM(coalesce(_gc.DEB/POWER(10,COALESCE( ( (select DECIMAL_COUNT from PA_SYMBOLS ps inner join PA_ORGANIZATIONS po on ps.id=po.BASE_CURRENCY  where po.org_id=]]..org_id..[[ limit 1)) ,0)))) deb,
                            SUM(coalesce(_gc.DEB/POWER(10,COALESCE( ( (select DECIMAL_COUNT from PA_SYMBOLS ps inner join PA_ORGANIZATIONS po on ps.id=po.BASE_CURRENCY where po.org_id=]]..org_id..[[ limit 1)) ,0))))-
                            SUM(coalesce(_gc.CRD/POWER(10,COALESCE( ( (select DECIMAL_COUNT from PA_SYMBOLS ps inner join PA_ORGANIZATIONS po on ps.id=po.BASE_CURRENCY where po.org_id=]]..org_id..[[ limit 1)) ,0)))) rem,
  							_gc.id record_id,
                            _gd.CODE,]]
  teamyar.write_log(json.encode(input.is_total))
  if input.is_total ==true then 
       qselect = qselect..[[    '--'  VOUCHER_ID, '--' cmt, '--' DebCrd,0 TrueDate ]]

  else
   qselect = qselect..[[   _gb.id voucher_id ,_gb.voucher_id vid, _gb.title cmt, CASE WHEN COALESCE(_gc.DEB,0)>0 THEN 1 WHEN COALESCE(_gc.CRD,0)>0 THEN 2 END DebCrd,_gb.RUN_DATE TrueDate ]]
  end
   qselect = qselect..[[       FROM `0000000`.`PA_VOUCHER` _gb JOIN
                                      `0000000`.`PA_VOUCHER_RECORD` _gc ON (_gc.VOUCHER_ID = _gb.ID AND _gc.ORG_ID = _gb.ORG_ID) JOIN
                                      `0000000`.`PA_ACCOUNT` _gd 
                                      ON (_gd.ID = _gc.ACCOUNT_ID AND _gd.ORG_ID = _gc.ORG_ID) 
                                      WHERE _gc.SYMBOL_ID = '0' AND _gb.DELETED = '0' 
                                      AND _gc.DELETED = '0' AND _gc.R_TYPE <> '13' and _gb.ORG_ID =]]..org_id
  if  datef ~= nill and datet ~= nill and datef ~= "" and datet ~= ""    then 
    qselect = qselect..[[ and _gb.RUN_DATE <]]..datet..[[ and _gb.RUN_DATE >]]..datef
  end

  local ids = ""; 
  if type(input.account_id) == "number"   then   
    qselect = qselect.. [[ and _gd.code like N']]..input.account_id..[[%'  ]]
  else
    for i, v in ipairs(input.account_id) do
      if v == 0 then
       qselect = qselect..  [[ and _gd.code  like N']]..v..[[%'  ]]
      end
      if  ids=="" then
        ids=[[ and ( _gd.code like N']]..tostring(v.id)..[[%'  ]] 
      else 
          ids=ids..[[ or  _gd.code like N']]..tostring(v.id)..[[%'  ]] 

      end

    end
     
  end
--   ids=  ids
  if ids ~= nill and ids ~= "" then 
    qselect = qselect.. ids..[[ ) ]]
  end
  if input.is_total ==true then 
          qselect = qselect..[[ GROUP BY _gc.ACCOUNT_ID,_gd.CODE ]]
 
  else 
 qselect = qselect..[[ GROUP BY _gc.ACCOUNT_ID,TrueDate,_gd.CODE,_gb.id,_gb.voucher_id,DebCrd, _gb.title ,_gc.id)mm group by  ACCOUNT_ID,voucher_id,cmt,debcrd,truedate,record_id order by truedate,voucher_id desc ]]
    -- if input.acc_level==2 then 
       qselect=qselect.. [[ )tt group by  ACCOUNT_ID,voucher_id,cmt,debcrd,truedate,vid ]]
--end
  end
  local query_select = [[SELECT JSON_ARRAYAGG(JSON_OBJECT("ac_id", ACCOUNT_ID, "crd",crd,"deb",deb,"vi",VOUCHER_ID,"debcrd",debcrd,"d",TrueDate,"cmt",cmt,"vid",vid,"rem",rem)) from ( ]]..qselect
  if paging == true then 
  query_select= query_select..[[ limit ?,?]]
  end 
  query_select= query_select..[[ )tmp]]
 teamyar.write_log(query_select)
   teamyar.write_log(input.from)
  res_data = queryResult(query_select , {input.from, input.count})
  -------------------

  local qtotal = [[select count(*) c from  ( ]]..qselect..[[)as t]]
 teamyar.write_log(qtotal)
  local  totall= queryResult(qtotal, {})
  local from_pre_page=0
  local previus_sum=0
  if input.from>=26 then 
    from_pre_page=input.from-26;
    local qsum = [[select sum(crd),sum(deb) c from  ( ]]..qselect..[[ limit ]]..from_pre_page..[[,26)as t]]
     teamyar.write_log(qsum)
    previus_sum= queryResultSum(qsum, {})
  end 
  return {from = input.from, count = input.count, data = res_data, total = totall, previus_sum = previus_sum}
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
  elseif  input.type == 6 then --print
  local data = getData(true)
    teamyar.write_result(json.encode(data))
    elseif  input.type == 7 then --excel
  local data = getData(false)
  teamyar.write_result(json.encode(data))
elseif input.type == 1 then 
  local accounts =json.encode(input.account_id)
  local chash_data = {l26_org_id = org_id, l26_gn = input.gn, l26_accounts = accounts, l26_datet = datet,
    							  l26_datef = datef, l26_acc_level = input.acc_level, l26_accln = input.accln, is_total = input.is_total }
  teamyar.set_data("l26_data", json.encode(chash_data));
local data = getData(true)
  teamyar.write_result(json.encode(data))
else
  WidgetTemplate()
end
