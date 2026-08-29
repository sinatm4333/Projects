-- botName = report
-- creator = zmo
-- date = 8/17/2024
-- version= 1
--------------------------------------------
--- install [report]
-------------------------------------------
local _BAT_RES_PATH = "2/res_v2";
function readyCodes()
    local data = teamyar.get_input();
    data["res_type"] = "codes"
    data["config"] = json.decode(teamyar.get_attachment("data.txt"))
    local responseRes = teamyar.run_command(_BAT_RES_PATH , data);
    if responseRes ~= nil then
        responseRes = json.decode(responseRes)
        for i = 1 , #responseRes, 1 do
            local loadedFunction, errorMessage = load(responseRes[i])
            if loadedFunction then
                loadedFunction();
            else
                teamyar.write_log("Error: " .. errorMessage);
            end
        end
    end

end
readyCodes();
-----------------------------
local query =[[  WITH CTE1258 AS ( SELECT _fd.UNIT_MEASURMENT UNIT_MEASURMENT, _fd.DECIMAL_NUM DECIMAL_NUM,
_fc.ID ProductID FROM `0000000`.`WH_PRODUCT` _fc LEFT JOIN `0000000`.`WH_STOCK_CAPACITY` _fd ON
_fd.ID = _fc.CAPACITY_ID WHERE _fd.DELETED = '0' ) 
,ads as (select distinct  c.id,CITY,STATE,c.org_id orid from pa_client c inner join profile_user_address a on a.USER_ID=c.REFFERE_ID)
,ads_user as (select user_id id,CITY,STATE from profile_user_address )
                        ,pp as( with  RECURSIVE 
                        cte as ( SELECT id, id nextid,name, parent
                                 FROM wh_product p
                               UNION ALL
                                 SELECT cte.id, p.id,p.name, p.parent
                                 FROM wh_product p
                                 JOIN cte ON cte.parent = p.id )
                        SELECT Id, name
                        FROM cte
                        WHERE parent=0
                        ), parents as (select id , (select name from wh_product where id=p.parent)parent from wh_product p where voucher_allow=1)
                        SELECT  _ed.RUN_DATE- MOD(_ed.RUN_DATE+126000000000, 864000000000) d,
                        (select name from wh_product where id= _ee.PRODUCT_ID )p,
                        COALESCE((select CONTENT from wh_pr_attribute_detail where ATTRIBUTE_ID=_ee.ATTRIBUTE_ID),'--') att_id, 
                         Coalesce((case when  _ed.CLIENT_ID>0 then  (select  name from pa_client where id=_ed.CLIENT_ID  and org_id= _ed.org_id) else (select fullname from profile_main where id=abs(_ed.CLIENT_ID)) end ),'--')c,
                          Coalesce((case when  _ed.CLIENT_ID>0 then  (select city from ads where id=_ed.CLIENT_ID  and orid= _ed.org_id) else  (select city from ads_user where id=abs(_ed.CLIENT_ID)) end ),'--') ci,
                         Coalesce((case when  _ed.CLIENT_ID>0 then  (select state from ads where id=_ed.CLIENT_ID  and orid= _ed.org_id)else (select state from ads_user where id=_ed.CLIENT_ID) end),'--') br,
                          Coalesce(( select  name from pa_client where id=_ed.SALES_AGENT  and org_id= _ed.org_id),'--')agent,
                        Coalesce((select name from pa_center where id= _ed.SALES_CENTER and org_id= _ed.org_id),'--')cn,  
                         _ed.TYPE ty, 
                         _ed.STATUS st, _ed.id id,
                         SUM(Coalesce(_ee.QUANTITY,0)/POWER(10,Coalesce(_ec.DECIMAL_NUM,0))) count,
                         SUM(((_ee.FEE/1000)*Coalesce(_ee.QUANTITY,0)/POWER(10,Coalesce(_ec.DECIMAL_NUM,0))-_ee.DISCOUNT+_ee.VALUE_ADDED)) price,   (select parent from parents where id=_ee.PRODUCT_ID ) sub,
                         (select name from pp where id=_ee.PRODUCT_ID ) mg, concat('#',_ed.id,'_',_ed.title) title
                         FROM `0000000`.`SALES_INVOICE` _ed JOIN `0000000`.`SALES_INVOICE_PRODUCT` _ee ON (_ee.INVOICE_ID = _ed.ID) JOIN CTE1258 _ec ON (_ec.ProductID = _ee.PRODUCT_ID) WHERE _ed.TYPE IN ('1','5') 
                        AND _ed.TYPE <> '2' AND _ed.CANCELED = '0' AND _ed.DELETED = '0' AND _ed.TYPE <> '3' {{where_str}}
                        GROUP BY _ee.PRODUCT_ID,_ed.SALES_CENTER,ty,st,att_id,d,_ed.CLIENT_ID,_ee.ATTRIBUTE_ID,_ed.SALES_AGENT,_ed.ID 
                        ORDER BY _ed.SALES_CENTER,_ee.PRODUCT_ID,_ee.ATTRIBUTE_ID
                         ]]

--------------------------------------------
--- Report
--------------------------------------------
function getAclPersonnel(data)
  local query_param = [[   select PERSONNEL_ID id,fullname name from hr_personnels h inner join profile_main p on h.PROFILE_ID=p.id  ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  where fullname like N'%]]..data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end
-------------------------------------------
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
-------------------------------------------
function queryResult(select_query, user_param)
  db.use_db("0000000")
  local params = {
    query = select_query,
    params = user_param
  }
    teamyar.write_log("select_query----------------"..select_query)
  db.query(params);
  local res_text = {};
  local record = {};
  while db.query_fetch(record) do   
    table.insert(res_text, {d = record[1],  p = record[2], a = record[3], c = record[4],  ci = record[5],
                                        br = record[6], agent = record[7],  cn = record[8], ty = record[9], st = record[10],
                                        id = record[11],  count = record[12],  price= record[13],
                                        subg = record[14],  mg = record[15], title = record[16]});
  end
  db.query_free();
  return res_text;
end
-------------------------------------------
function queryResultTotal(select_query,user_param)
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
--------------------------------------------
function report()  
  local datef = getInput("datef")
  local datet = getInput("datet")
  local page = getInput("page")
  local org = getInput("org")[1]
  local center = getInput("center")[1]
  local agent = getInput("agent")[1]
  local product = getInput("product")[1]
  local attribute = getInput("attribute")[1]
  local client = getInput("client")[1]
  local ty = getInput("typefa")
  local st = getInput("status")

  local where_str=[[]] 
    --where 
  if datet ~= nill  and datet ~= "" then 
    datet = datet + (24 * 60 * 60 * 10000000);
  end
  teamyar.write_log(datef.."--"..datet)
  if  datef ~= nil and  datef ~= "" and datet ~= nil and  datet ~= ""  then 
    where_str = where_str..[[ and _ed.RUN_DATE between ]]..datef..[[ and ]]..datet
  end 
  
    if  org ~= nil  then 
    where_str = where_str..[[ and _ed.ORG_ID= ]]..org.id
  end 
      if  product ~= nil   then 
    where_str = where_str..[[ and _ee.PRODUCT_ID= ]]..product.id
  end 
      if  attribute ~= nil then 
    where_str = where_str..[[ and _ed.ORG_ID= ]]..attribute.id
  end 
      if  center ~= nil then 
    where_str = where_str..[[ and  _ed.SALES_CENTER= ]]..center.id
  end 
        if  agent ~= nil  then 
    where_str = where_str..[[ and _ed.SALES_AGENT ]]..agent.id
  end 
          if  client ~= nil then 
    where_str = where_str..[[ and _ed.CLIENT_ID= ]]..client.id
  end 
    local ids_ty = ""
  local ids_st = ""
  --------------
  if type(ty) == "number"   then   
    ids_ty =ty
  else
    for i, v in ipairs(ty) do
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
  if type(st) == "number"   then   
    ids_st = st
  else
    for i, v in ipairs(st) do
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
            if  #ids_ty>0 then 
    where_str = where_str..[[ and  _ed.TYPE in ( ]]..ids_ty..[[) ]]
  end 
              if  #ids_st>0 then 
    where_str = where_str..[[ and _ed.STATUS in ( ]]..ids_st..[[) ]]
  end 
local q= string.gsub(query,"{{where_str}}",where_str);
  teamyar.write_log("ضضضض"..q)

  local rep_data ={}
  local total =0
  if  org ~= nil  then 
    teamyar.write_log(q)
    rep_data = queryResult(q..[[ limit ]]..page..[[,20]], { })
      teamyar.write_log("select count(*) from ("..q..")kk")
  	total = queryResultTotal("select count(*) from ("..q..")kk", {})
  end
  local  report = {
    {
      name = "main" ,
      title = "جدول" ,
      report ={total = total , data = rep_data, page = page}
    }
  }
  teamyar.write_result(json.encode(report));
end
--------------------------------------------
function getAclOrg(data)
  local query_param = [[  select  id,name from org_info   ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  where name like N'%]]..data.search..[[%' ]]

  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end
--------------------------------------------
function getAclProduct(data)
  local query_param = [[  select  id,name from wh_Product ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  where name like N'%]]..data.search..[[%' ]]

  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end
--------------------------------------------
function getAclAttribute(data)
  local query_param = [[  select  id,name from wh_Product ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  where name like N'%]]..data.search..[[%' ]]

  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end
--------------------------------------------
function getAclCenter(data)
  local query_param = [[  select  id,name from wh_Product ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  where name like N'%]]..data.search..[[%' ]]

  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end
--------------------------------------------
function getAclAgent(data)
  local query_param = [[  select  id,name from wh_Product ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  where name like N'%]]..data.search..[[%' ]]

  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end
--------------------------------------------
function getAclClient(data)
  local query_param = [[  select  id,name from wh_Product ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  where name like N'%]]..data.search..[[%' ]]

  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end
--------------------------------------------
function getAclStatus(data)
    local table = {
        {id =1,name=translateWord("DRAFT")},
        {id =2,name=translateWord("INSPECT")},
        {id =3,name=translateWord("DO")},
        {id =4,name=translateWord("COMPELETE")}
    }
    teamyar.write_result(json.encode(table));
end
--------------------------------------------
function getAclType(data)
    local table = {
        {id =5,name=translateWord("SALE_ORDER")},
        {id =2,name=translateWord("PRE_FASCTOR")},
        {id =6,name=translateWord("SALE_LICENSE")},
        {id =7,name=translateWord("CONTRACT")},
    	{id =1,name=translateWord("SALE_FACTOR")},
        	{id =3,name=translateWord("RETURN_SALE")},
    }
    teamyar.write_result(json.encode(table));
end
--------------------------------------------
--- manager
--------------------------------------------
local type = getInput("type");
if type == 4 then 
  getAclOrg(teamyar.get_input())
  elseif type == 5 then 
  getAclType(teamyar.get_input())
    elseif type == 6 then 
  getAclStatus(teamyar.get_input())
    elseif type == 7 then 
  getAclProduct(teamyar.get_input())
    elseif type == 8 then 
  getAclAttribute(teamyar.get_input())
    elseif type == 9 then 
  getAclClient(teamyar.get_input())
    elseif type == 10 then 
  getAclCenter(teamyar.get_input())
    elseif type == 11 then 
  getAclAgent(teamyar.get_input())
elseif type == 3 then 
  local input = teamyar.get_input()
  local org = input.org
  local st = input.st
  local ty = input.ty
  local datet = input.dt
  local datef = input.df
  local product = input.p
  local attribute = input.att
  local center = input.cn
  local agent = input.ag
  local client = input.c
  
  local query = [[  select d.OPERATION_ID,d.PRODUCT_ID,serial from wh_operation_details d
                          join wh_op_base_serial_bach b on b.OPERATION_DETAIL_ID=d.id
                          join wh_operation_serials o on o.BASE_ID=b.id
                          join wh_product_serial p on p.id=o.SERIAL_ID where p.org_id=]]..org.id..[[ and serial between ]]..serialf..[[ and ]]..serialt
    --where 
  if datet ~= nill  and datet ~= "" then 
    datet = datet + (24 * 60 * 60 * 10000000);
  end
  if  datef ~= nil and datet ~= nil then 
    query = query..[[ and p.CREATION_DATE between ]]..datef..[[ and ]]..datet
  end 
  query = query ..[[   order by serial ]]
  teamyar.write_log(query)
  local rep_data = queryResult(query, {})
  teamyar.write_result(json.encode(rep_data));
elseif type ~= nil and type == 100 then
  report()
else
 local responseResReport = install_res.resReport();
    teamyar.write_result(responseResReport);
end




