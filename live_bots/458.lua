--Bot eacc
--ver 002
--start date:1404-3-4
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
if account_id == nil then 
  account_id = "";
end 
local day = time.get_day(time.current());
local month = time.get_month(time.current());
local year = time.get_year(time.current());
local min = time.get_minute(time.current());
local hour = time.get_hour(time.current());
local sec = time.get_second(time.current());
local temp_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":]]..hour..[[,"minute":]]..min..[[,"second":]]..sec..[[}]])
local currentdate = string.format("%18.0f", temp_time);
---------------------------------------------
function loadData()
  local data = teamyar.get_data("accr_data")
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
  if res_text == nil then 
    return nil 
  else
  return res_text[1];
  end
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
     table.insert(all, { crd = record[1], deb = record[2], rem = record[3], rem_l = record[4]} )
 end
  db.query_free();
  return all;
end
--------------------------------------------------------
function queryResultAcl(select_query,user_param)
  db.use_db("0000000")
  local params = {
    query = select_query,
    params = user_param
  }
  db.query(params);
  local res_text={};
  local record={};
  while db.query_fetch(record) do
    local tmp=record;
    table.insert(res_text, {id = record[1], name = record[2], type =1});
  end
  db.query_free();
  return res_text;
end
--------------------------------
function queryResultData(select_query,user_param)
  db.use_db("0000000")
    local params1 = {
      query = select_query,
      params = user_param
  }
  db.query(params1);
  local record = {}
  local all = {}
  while db.query_fetch(record) do                            
    table.insert(all, { id = record[1],
        code = record[2],
        title = record[3],
        d = record[4],
        acc_code = record[5],
        acc_name= record[6],
        float = record[7],
        center= record[8],
        project = record[9],
        rt_cmd= record[10],
             deb = record[11],
        crd = record[12], 
           rem = record[13], 
        rem_l = record[14],
        st = record[15],
        client = record[16],
            group_code = record[17],
            kol_code = record[18],
            specific_code = record[19],
            tafzil_code = record[20],
            float_code = record[21],
          cn_code = record[21],
          pr_code = record[21],
          cl_code = record[21],
        
      }
    )
 end
  db.query_free();
  return all;
end
----------------------
function orgAcl(data)
  local query_param = [[select id,name from org_info ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  where name like N'%]]..data.search..[[%'  ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end
----------------------
function accountAcl(data)
  local geted_org_id=data.org_id;
  local query_param = [[ select code i,concat('#',code,'_',name)n from pa_account where 1=1 ]] 
  if geted_org_id~=0 then 
    query_param =query_param..[[ and org_id=]]..geted_org_id
  end 
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param ..  [[ and name like N'%]]..data.search..[[%' or  code like  N'%]]..data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count)  
  teamyar.write_result(json.encode(queryResultAcl(query_param , {})));
end
----------------------
function projectAcl(data)
  local geted_org_id=data.org_id;
  local query_param = [[ select id i,concat('#',code,'_',name)n from pa_project where 1=1 ]] 
  if geted_org_id~=0 then 
    query_param =query_param..[[ and org_id=]]..geted_org_id
  end 
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param ..  [[ and name like N'%]]..data.search..[[%' or  code like  N'%]]..data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count)  
  teamyar.write_result(json.encode(queryResultAcl(query_param , {})));
end
----------------------
function centerAcl(data)
  local geted_org_id=data.org_id;
  local query_param = [[ select id i,concat('#',code,'_',name)n from pa_center where 1=1 ]] 
  if geted_org_id~=0 then 
    query_param =query_param..[[ and org_id=]]..geted_org_id
  end 
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param ..  [[ and name like N'%]]..data.search..[[%' or  code like  N'%]]..data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count)  
  teamyar.write_result(json.encode(queryResultAcl(query_param , {})));
end
----------------------
function clientAcl(data)
  local geted_org_id=data.org_id;
  local query_param = [[ select id i,concat('#',code,'_',name)n from pa_client where 1=1 ]] 
  if geted_org_id~=0 then 
    query_param =query_param..[[ and org_id=]]..geted_org_id
  end 
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param ..  [[ and name like N'%]]..data.search..[[%' or  code like  N'%]]..data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count)  
  teamyar.write_result(json.encode(queryResultAcl(query_param , {})));
end
----------------------
function floatAcl(data)
  local geted_org_id=data.org_id;
  local query_param = [[ select id i,concat('#',code,'_',name)n from pa_floating where 1=1 ]] 
  if geted_org_id~=0 then 
    query_param =query_param..[[ and org_id=]]..geted_org_id
  end 
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param ..  [[ and name like N'%]]..data.search..[[%' or  code like  N'%]]..data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count)  
  teamyar.write_result(json.encode(queryResultAcl(query_param , {})));
end
-----------------------------------------------
function WidgetTemplate()  
  local random = math.random(1,1000);
  local script =  teamyar.get_attachment("main.js");
  local css =  teamyar.get_attachment("main.css");
  local  str_lang="";
  local  str_title="";
  if user_info.lang_id == 4 then
    str_title="دفاتر روزنامه الکترونیکی"
    str_lang = teamyar.get_attachment("Persian.js");
  else
    str_title="Electrionc Accountind Reports"
    str_lang = teamyar.get_attachment("English.js");
  end
  local template = teamyar.run_command("2/res_bot",{
      id = "bot_ledger_elec_row",
      tpl_name = "html",
      title = str_title,
      body = "<div id=\\'accr_holder_body_html_"..random.."\\'></div>",
      script=[[
      (function(){
      ]]..str_lang..[[      
      var holder_id = '#accr_holder_body_html_]]..random..[[';
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

local with_str=[[
  WITH RECURSIVE parent_code AS (
    SELECT 
        id AS product_id,       
        parent AS parent_id,
         level,  code
    FROM pa_account
    WHERE parent IS NOT NULL
    UNION ALL
    SELECT 
        p.product_id,
        pa.parent, 
        pa.level , pa.code
    FROM parent_code p
    inner join pa_account pa ON pa.id = p.parent_id
     WHERE pa.parent IS NOT NULL
)
   ]]

  local qselect=  [[  select id,vid,title,dd,acode,aname,fl,cn,
                            pr,content,deb,crd,(deb-crd)rem,sum(deb-crd) over (order by RowNum)rem_l
                            ,st,cl,group_code,kol_code,specific_code,tafzil_code,fl_code,cn_code,pr_code,cl_code from ]]
  if input.fp then 
  qselect = qselect..[[
 ( (select 0 RowNum, 0  id,0 vid,0  vrid,"موجودی ابتدای دوره " title,0 dd ,"" acode, "" aname,
  "" fl, ""cn, ""pr, "" CONTENT, 
    sum(deb)/POWER(10,COALESCE( ( (select DECIMAL_COUNT from PA_SYMBOLS ps inner join PA_ORGANIZATIONS po on ps.id=po.BASE_CURRENCY where po.org_id=v.org_id limit 1)) ,0))deb,
    sum(crd)/POWER(10,COALESCE( ( (select DECIMAL_COUNT from PA_SYMBOLS ps inner join PA_ORGANIZATIONS po on ps.id=po.BASE_CURRENCY where po.org_id=v.org_id limit 1)) ,0))crd  ,"" st,
  "" cl ,"" group_code ,""kol_code ,"" specific_code ,"" tafzil_code,
  "" fl_code, ""cn_code, ""pr_code, "" cl_code from pa_voucher v
  inner join pa_voucher_record vr on vr.VOUCHER_ID=v.id inner join pa_account _gd on _gd.id=vr.account_id where  v.org_id=]]..org_id..[[ and v.org_id =]]..org_id ..[[ and v.status>2 ]]
  
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
    
  if ids ~= nill and ids ~= "" then 
    qselect = qselect.. ids..[[ ) and VOUCHER_ALLOW=1 and _gd.ORG_ID=]]..org_id -- ..[[ and FORCE_FLOATING=1]]
  end
  --    if ids_acc ~= nil and ids_acc ~= "" then 
    --   qselect = qselect.. [[ and vr.account_id in (select id from pa_account where code like '1101%' and VOUCHER_ALLOW=1 and ORG_ID=]]..org_id..[[ and FORCE_FLOATING=1) ]]
   -- end 
   if  datef ~= nil and datet ~= nil and datef ~= "" and datet ~= ""    then 
  --    qselect = qselect.. [[ and  vr.RUN_DATE between ]]..datef..[[ and ]]..datet
     --  qselect = qselect.. [[ and  vr.RUN_DATE >=(select start_date from pa_fiscal_year fp where ]]..currentdate..[[   between START_DATE and END_DATE and fp.org_id=v.org_id limit 1) ]]
      
      qselect = qselect..   [[ and ((vr.type=16 and vr.RUN_DATE >=(select start_date from pa_fiscal_year fp where  ]]..currentdate..[[    between START_DATE and END_DATE and fp.org_id=v.org_id limit 1))
 or ( vr.RUN_DATE >=(select start_date from pa_fiscal_year fp where   ]]..currentdate..[[   between START_DATE and END_DATE and fp.org_id=v.org_id limit 1) and vr.RUN_DATE <= ]]..datef..[[))   ]]
  end
    qselect = qselect..[[ ) UNION  ]]
end
   qselect = qselect..[[(SELECT  ROW_NUMBER() OVER (ORDER BY _gc.id) AS RowNum,
                            _gb.id,_gb.voucher_id vid,_gc.id vrid,_gb.title,_gb.RUN_DATE dd ,_gd.code acode,
                            _gd.name aname,(select name from pa_floating where id =_gc.FLOATING_ACCOUNT_ID and org_id=_gb.org_id) fl,
                            (select name from pa_center where id=_gc.center_id and org_id=_gb.org_id)cn,
                            (select name from pa_project where id=_gc.project_id and org_id=_gb.org_id)pr,
                            _gc.CONTENT,(coalesce(_gc.DEB/POWER(10,COALESCE( ( (select DECIMAL_COUNT 
                            from PA_SYMBOLS ps inner join PA_ORGANIZATIONS po on ps.id=po.BASE_CURRENCY 
                            where po.org_id=]]..org_id..[[ limit 1)) ,0)))) deb, (coalesce(_gc.CRD/POWER(10,COALESCE( (
                            (select DECIMAL_COUNT from PA_SYMBOLS ps inner join
                            PA_ORGANIZATIONS po on ps.id=po.BASE_CURRENCY where po.org_id=]]..org_id..[[  limit 1)) ,0)))) crd
                          ,(case when _gb.status=1 then 'NOTE' when  _gb.status=2 then
                            'TEMPORARY' when  _gb.status=3 then 'CHECKED' when _gb.status=4 then 'PERMANENT' else '' end )st,(select name from pa_client where id =_gc.client_ID and org_id=_gb.org_id) cl
  ,(SELECT distinct ctte.code pcode
FROM parent_code ctte
where ctte.product_id=_gd.id  and level =1 limit 1)group_code
,(SELECT  distinct ctte.code pcode
FROM parent_code ctte
where ctte.product_id=_gd.id  and level =2 limit 1)kol_code
,(SELECT distinct ctte.code pcode
FROM parent_code ctte
where ctte.product_id=_gd.id  and level =3 limit 1 )specific_code
,(SELECT  distinct ctte.code pcode
FROM parent_code ctte
where ctte.product_id=_gd.id  and level =4 limit 1)tafzil_code,
(select code from pa_floating where id =_gc.FLOATING_ACCOUNT_ID and org_id=_gb.org_id) fl_code,
  (select code from pa_center where id=_gc.center_id and org_id=_gb.org_id)cn_code,
                            (select code from pa_project where id=_gc.project_id and org_id=_gb.org_id)pr_code,
  (select code from pa_client where id =_gc.client_ID and org_id=_gb.org_id) cl_code
                          FROM `0000000`.`PA_VOUCHER` _gb JOIN
                            `0000000`.`PA_VOUCHER_RECORD` _gc ON (_gc.VOUCHER_ID = _gb.ID AND 
                            _gc.ORG_ID = _gb.ORG_ID) JOIN `0000000`.`PA_ACCOUNT` _gd ON 
                            (_gd.ID = _gc.ACCOUNT_ID AND _gd.ORG_ID = _gc.ORG_ID) WHERE 1=1 
                             AND _gb.DELETED = '0' AND
                            _gc.DELETED = '0' AND _gc.R_TYPE <> '13' and _gc.type<>16 and _gb.ORG_ID =]]..org_id


  if  datef ~= nill and datet ~= nill and datef ~= "" and datet ~= ""    then 
    qselect = qselect..[[ and _gb.RUN_DATE <]]..datet..[[ and _gb.RUN_DATE >]]..datef
  end
   if input.from_voucher~= nil and #tostring(input.from_voucher)>0 then 
            qselect = qselect.. [[ and _gb.voucher_id >= ]]..input.from_voucher
  end 
     if input.to_voucher~= nil and #tostring(input.to_voucher)>0 then 
            qselect = qselect.. [[ and _gb.voucher_id <=]]..input.to_voucher
  end 
if input.float_id ~=nil then 
        qselect = qselect.. [[ and _gc.FLOATING_ACCOUNT_ID =]]..input.float_id
  end 
  if input.center_id ~=nil then 
        qselect = qselect.. [[ and _gc.center =]]..input.center_id
  end 
  if input.project_id ~=nil then 
        qselect = qselect.. [[ and _gc.project_id =]]..input.project_id
  end 
   ids = ""; 
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
qselect = qselect..[[ GROUP BY _gb.id,_gd.CODE,_gd.name,_gc.FLOATING_ACCOUNT_ID,_gc.center_id,_gc.project_id,_gc.CONTENT ,_gc.id order by dd,vid desc]]
  if input.fp then 
      qselect = qselect..[[ )   ]]
  end 
  qselect = qselect..[[ )oo order by vid   ]]
  local qtotal = with_str..[[select count(*) c from  ( ]]..qselect..[[)as t]]
    local qsum = with_str..[[select sum(crd),sum(deb) c,sum(rem) rem,sum(rem_l)rem_l from  ( ]]..qselect..[[ )as t]]
  
  if paging == true then 
  qselect= qselect..[[ limit ?,?]]
  end 

 teamyar.write_log(qselect)

  res_data = queryResultData(with_str..qselect , {input.from, input.count})
  -------------------


 teamyar.write_log(qtotal)
  local  totall= queryResult(qtotal, {})

  

    local previus_sum= queryResultSum(qsum, {})

  return {from = input.from, count = input.count, data = res_data, total = totall, previus_sum = previus_sum}
end
---------------------main
if input.type == 3 then 
  loadData()
elseif input.type == 2 then 
  orgAcl(input.data)
elseif input.type == 4 then 
  accountAcl(input.data)
    elseif input.type ==8 then 
  projectAcl(input.data)
  elseif input.type == 9 then 
  centerAcl(input.data)
  elseif input.type == 10 then 
  floatAcl(input.data)
    elseif input.type == 11 then 
  clientAcl(input.data)
  
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
  local chash_data = {	accr_org_id = org_id, accr_gn = input.gn, 
                                  accr_accounts = accounts, accr_datet = datet,
                                  accr_datef = datef, 
                                  accr_client_id= input.client_id, accr_clin = input.clin, 
                                  accr_project_id = input.project_id, accr_pn= input.pn, 
                                  accr_center_id = input.center_id, accr_cn = input.cn, 
                                  accr_float_id= input.float_id, accr_fn = input.fn, 
                                  accr_from_voucher = input.from_voucher,
                                  accr_to_voucher = input.to_voucher,  
    accr_fp=input.fp
   }
  teamyar.set_data("accr_data", json.encode(chash_data));
local data = getData(true)
  teamyar.write_result(json.encode(data))
else
  WidgetTemplate()
end




















		  
		  

	  
	  
	

  
