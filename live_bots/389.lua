-- botName = report
-- creator = zmo
-- date = 8/17/2024
-- version= 1

--------------------------------------------
--- install [RES]
--------------------------------------------
local org = {}--getInput("org")[1]
local day = time.get_day(time.current());
local month = time.get_month(time.current());
local year = time.get_year(time.current());
local hour = time.get_hour(time.current());
local min = time.get_minute (time.current());
local sec = time.get_second(time.current());
local currentdate_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":]]..hour..[[,"minute":]]..min..[[,"second":]]..sec..[[}]])
local temp_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":0,"minute":0,"second":0}]])
currentdate = string.format("%18.0f" ,temp_time);
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
install_res.resCash();


--------------------------------------------
--- install [report]
--------------------------------------------
-- local org_id=2 --organization ID
local uinfo=teamyar.get_user_info();
local user_id= uinfo.id;
local day = time.get_day(time.current());
local month = time.get_month(time.current());
local year = time.get_year(time.current());
local min = time.get_minute(time.current());
local hour = time.get_hour(time.current());
local sec = time.get_second(time.current());
local temp_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":]]..hour..[[,"minute":]]..min..[[,"second":]]..sec..[[}]])
local currentdate = string.format("%18.0f", temp_time);

--local installCode = teamyar.get_attachment("install_report.lua")
--local loadedFunction = load(installCode);
--loadedFunction();
--------------------------------------------
--- Report
--------------------------------------------

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
  teamyar.write_log(select_query)
  db.query(params);
  local res_text = {};
  local record = {};
  while db.query_fetch(record) do

    local info = {
      org_id= record[19],
    end_date=record[24],
      stock_id= tostring(record[20]),
      product_id=record[21],
      start_date= record[23],
      attribute_id= record[22]
    }
    teamyar.write_log(json.encode(info))
    local   res = teamyar.call_api(17,  '/api/get_cardindex', info);

    local cardex=math.ceil(json.encode(res.data.cost))
    if cardex == nil then 
      cardex=0
    end 
    -- teamyar.write_log()
    table.insert(res_text, {od= record[1],  factor = record[2] , factor_id = record[3], return_factor = record[4],  return_factor_id = record[5],   center = record[6], 
        agent = record[7], client = record[8],  product = record[9], stock = record[10] , count = record[11] , 
        total = record[12], return_count = record[13],  return_price = record[14],pure_count = record[15], total_sale = record[16], full_price  = record[11]*cardex, -- quantity* cardex record[17], 
        gross_profit = record[16]-( record[11]*cardex )--record[18]
        ,discount = record[26],value_added = record[25],
      });
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
function getAclProducts(data)
  local query_param = [[   select  id, name from wh_product where voucher_allow =1 ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  and  name like N'%]]..data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end
--------------------------------------------
function getAclStocks(data)
  local query_param = [[     select  id, name from wh_stock where voucher_allow =1 ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  and name like N'%]]..data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end
--------------------------------------------
function getAclClients(data)

  local query_param = [[      select distinct id, name from  pa_client where 1=1]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  and name like N'%]]..data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end
--------------------------------------------
function getAclCenter(data)

  local query_param = [[      select  id, name from  pa_center where 1=1]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  and name like N'%]]..data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end
--------------------------------------------
function getAclOrg(data)
  local query_param = [[  select id,name from org_info ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  where name like N'%]]..data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end
--------------------------------------------
function getAclStatus()

  local table = {
    {id = 0, name = translateWord("DRAFT")},
    {id = 1, name = translateWord("INSPECT")},
    {id = 2, name = translateWord("DO")},
    {id = 3, name = translateWord("COMPLETE")},
  }
  teamyar.write_result(json.encode(table));
end

--------------------------------------------
function getData(page)  
  local datef = getInput("datef")
  local datet = getInput("datet")
  org = getInput("org")[1]
  local stock = getInput("stock")
  local product = getInput("product")[1]
  local client = getInput("client")[1]
  local agent = getInput("agent")[1]
  local center = getInput("center")
  local op_status = getInput("op_status_in")[1]
  local ststus_in = getInput("status_in")[1]
  local org_id = 0
  if  org ~= nil   then 
    org_id= org.id
  end 

  local with_str= [[
                      with returns_f as (select r.invoice_id ,INVOICE_PRODUCT_ID,RETURN_INVOICE_ID,
                      sum(VALUE_ADDED)VALUE_ADDED,sum(r.QUANTITY)quantity,
                      sum(FEE*r.QUANTITY) price,sum(FEE*r.QUANTITY)+sum(VALUE_ADDED) total_price 
                      from sales_invoice_return r
                      inner join sales_invoice_product si on si.id=r.INVOICE_PRODUCT_ID group by
                      r.invoice_id ,INVOICE_PRODUCT_ID,RETURN_INVOICE_ID)
                      ]]
  local query = [[  select DATE_CREATE ,i.id,concat ('#',i.INVOICE_ID,'_',i.TITLE) factor
                    ,(select group_concat(RETURN_INVOICE_ID) from returns_f where INVOICE_PRODUCT_ID=ip.id) return_factor_id
                    ,0 rid,
                    (select name from pa_center where id=i.SALES_CENTER  and org_id=i.org_id)center,
                    (select name from pa_client where id=i.SALES_AGENT  and org_id=i.org_id)agent,
                    (case when i.CLIENT_ID >0 then (select name from pa_client where id=i.CLIENT_ID and org_id=i.org_id) else (select fullname from profile_main  where id=abs(i.CLIENT_ID)  and org_id=i.org_id ) end )client 
                    ,(select name from wh_product where id=ip.PRODUCT_ID) product ,
                    (select name from wh_stock where id=ip.STOCK_ID)stock
                    ,ip.QUANTITY,((ip.QUANTITY*ip.fee)/POWER(10,(select  FEE_DECIMAL from pa_symbols where id=i.SYMBOL_ID  and org_id=i.org_id))) total_price,
                    (select sum(QUANTITY) from returns_f  where INVOICE_PRODUCT_ID=ip.id) return_count,
                    (select sum(price) from returns_f where INVOICE_PRODUCT_ID=ip.id)/POWER(10,(select FEE_DECIMAL from pa_symbols where id=i.SYMBOL_ID  and org_id=i.org_id)) return_price,
                    ip.QUANTITY -coalesce(( (select sum(quantity) from returns_f where INVOICE_PRODUCT_ID=ip.id)),0)pure_quantity,
                    ((((ip.QUANTITY*ip.fee)+ip.VALUE_ADDED)-coalesce((select sum(total_price) from returns_f where INVOICE_PRODUCT_ID=ip.id),0))
                    /POWER(10,(select FEE_DECIMAL from pa_symbols where id=i.SYMBOL_ID  and org_id=i.org_id)))-ip.discount  total_sale,
                    ((ip.QUANTITY*ip.fee)-(select sum(price) from returns_f where INVOICE_PRODUCT_ID=ip.id) )realprice,
                    ( ((ip.QUANTITY*ip.fee)+ip.VALUE_ADDED)-((ip.QUANTITY*ip.fee)-(select sum(price) from returns_f where INVOICE_PRODUCT_ID=ip.id) ) )grossprofile
                    ,i.org_id,ip.STOCK_ID,ip.PRODUCT_ID,ip.ATTRIBUTE_ID,
                    (select START_DATE from pa_fiscal_year where i.RUN_DATE between START_DATE and End_date and org_id=i.ORG_ID limit 1) dsf,
                    i.RUN_DATE def,ip.VALUE_ADDED,ip.discount 
                    from sales_invoice i inner join sales_invoice_product ip on ip.invoice_id=i.id where i.org_id=]]..org_id..[[ and  i.type=1 
                    and i.SALES_CENTER in (select c.CENTER_ID from sales_center_ext s inner join sales_center_setting c  on c.id=s.SETTING_ID where s.REFERE_ID=]]..user_id..[[ ) ]]
  --where 1
  if datet ~= nill  and datet ~= "" then 
    datet = datet + (24 * 60 * 60 * 10000000);
  end
  if datef ~= nil and datet ~= nil  and datef ~= "" and datet ~= "" then 
    query = query..[[ and i.DATE_CREATE between ]]..datef..[[ and ]]..datet
  end 
  if  product ~= nil and   product.id ~= nil  then 
    query = query..[[ and ip.PRODUCT_ID= ]]..product.id
  end 
  if  stock ~= nil  and #stock>0 then 
    local stock_lids = ""
    for i, v in ipairs(stock) do
      if v.id~= nil then      
        if  stock_lids == "" then
          stock_lids = stock_lids..tostring(v.id);
        else
          stock_lids = stock_lids..","..tostring(v.id);
        end
      end
    end
    if #stock_lids>0 then 
      query = query..[[ and ip.STOCK_ID in  (]]..stock_lids..[[) ]]
    end
  end 

  if  client ~= nil and client.id ~= nil  then 
    query = query..[[ and i.CLIENT_ID= ]]..client.id
  end 
  -------agent 
  if  agent ~= nil  and #agent>0 then 
    local agent_lids = ""
    for i, v in ipairs(agent) do
      if v.id~= nil then      
        if  agent_lids == "" then
          agent_lids = agent_lids..tostring(v.id);
        else
          agent_lids = agent_lids..","..tostring(v.id);
        end
      end
    end
    if #agent_lids>0 then 
      query = query..[[ and i.SALES_AGENT in  (]]..agent_lids..[[) ]]
    end
  end 

  ------center
  if  center ~= nil  and #center>0 then 
    local center_lids = ""
    for i, v in ipairs(center) do
      if v.id~= nil then      
        if  center_lids == "" then
          center_lids = center_lids..tostring(v.id);
        else
          center_lids = center_lids..","..tostring(v.id);
        end
      end
    end
    if #center_lids>0 then 
      query = query..[[ and i.SALES_CENTER in  (]]..center_lids..[[) ]]
    end
  end 

  if  ststus_in ~= nil and ststus_in.id~= nil   then 

    query = query..[[ and  i.status=]]..ststus_in.id

  end 

  query = query..[[ group by DATE_CREATE,i.id,ip.id ]]
  teamyar.write_log(query)
  -- db.set_text_buffer_size(50000)

  local rep_data ={}
  if page ~=nil then 
    rep_data = queryResult(with_str..query.." limit ?,20", {page})
  else
    rep_data = queryResult(with_str..query, {page})
  end 
  local total = queryResultTotal(with_str.." select count(*) from ("..query..")kk", {})
  return rep_data, total;
end 
--------------------------------------------
function report()  
  local page = getInput("page")
  local rep_data,total = getData(page)
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
--- manager
--------------------------------------------
local type = getInput("type");
if type == 3 then 
  local input = teamyar.get_input()
  local datet = input.datet
  local datef = input.datef
  --where 1
  if datet ~= nill  and datet ~= "" then 
    datet = datet + (24 * 60 * 60 * 10000000);
  end

  if datef ~= nil and datet ~= nil then 
    query = query..[[ and _ic.RUN_DATE between ]]..datef..[[ and ]]..datet
  end 

  local rep_data = queryResult(with_str..query, {})
  teamyar.write_result(json.encode(rep_data));
elseif type==1 then 
  getAclProducts(teamyar.get_input())
elseif type==2 then 
  getAclStocks(teamyar.get_input())
elseif type==4 or type==10 then 
  getAclClients(teamyar.get_input())
elseif type==5 then 
  getAclType(teamyar.get_input())
elseif type==6  or type==9 then 
  getAclStatus(teamyar.get_input())
elseif type==11 then 
  getAclCenter(teamyar.get_input())
elseif type==7 then 
  getAclOrg(teamyar.get_input())
elseif type ~= nil and type == 100 then
  report()
elseif type ~= nil and type == 101 then

  local rep_data =getData()

  local header={id = translateWord("ID"),  title =  translateWord("TITLE"), rd = translateWord("DELIVERY_DATE"), invoice_ID = translateWord("INVOICE_ID"),  ty = translateWord("TYPE"),   st = translateWord("STATUS"), 
    product = translateWord("PRODUCT"), stock = translateWord("STOCK"),  quantity = translateWord("COUNT"), q_confirm = translateWord("COUNT_WITH"), 
    discount = translateWord("DISCOUNT"),  client = translateWord("CLIENT"), floating_id = translateWord("FLOATING"), dd = translateWord("CREATE_DATE"), 
    reserved = translateWord("COUNT_RESERVE"), remainded = translateWord("REMAIND"), norial = translateWord("NORIAL"), noconfirmed = translateWord("COUNT_WITHOUT")}
  local data ={headers=header,values=rep_data ,  file_name = "test"}
  teamyar.write_result(json.encode(data));
else
  local responseResReport = install_res.resReport();
  teamyar.write_result(responseResReport);

end








