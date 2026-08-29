-- botName = group del
-- creator = zmo
-- date = 02/25/2025
-- version= 1.0

--
local config = teamyar.get_config()
local config_data = {}
local c_bot_send_id = 0 
if config ~= nil then 
  config_data = config.data
  c_bot_send_id = config_data.bot_send_id 
  else
  teamyar.write_result("لطفا تنظیمات پیکربندی پیش فرض بررسی شود ".."<br>")
end 
--------------------------------------------
--- CONFIG DATA
--------------------------------------------
local day = time.get_day(time.current());
local month = time.get_month(time.current());
local year = time.get_year(time.current());
local min = time.get_minute(time.current());
local hour = time.get_hour(time.current());
local sec = time.get_second(time.current());
local temp_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":]]..hour..[[,"minute":]]..min..[[,"second":]]..sec..[[}]])
currentdate = string.format("%18.0f", temp_time);
----------------------------
local _PAR_PAGE = 100
local _QUERY_TYPE = {
  _TYPE_TOTAL_SUM = 1 ,
  _TYPE_TOTAL_COUNT = 2 ,
  _TYPE_PAGE_REPORT = 3 ,
  _TYPE_PAGE_EXCEL = 4 ,
  _TYPE_PAGE_PRINT = 5 ,
}
-------------------------------------------
--- install [RES]
--------------------------------------------
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
--------------------------------------------
--- data
--------------------------------------------
function getData(queryType , pageFrom , perPage , pageTo )
  ---- init Query
  local dataQuery = {
    query = teamyar.get_attachment("query_list_invoice.txt") ,
    params = {}
  };
  ---- Select
  local config = teamyar.get_config()
  local cdata={}

  local c_count_out = 0
  if config ~= nil then 
    cdata = config.data
    c_count_out = cdata.count_out

  end 


  local user_info = teamyar.get_user_info()
  local time_zone = user_info.timezone
  local org = getInput("org_id");
  local stock = getInput("stock");
  local tag = getInput("tag");
  local product = getInput("product");
  local crm = getInput("crm");
  local kcrm = getInput("kcrm");
  local datef = getInput("datef");
  local datet = getInput("datet");
    local moadian_code = getInput("moadian_code");
  local factor_id = getInput("factor_id");
  local send_status = getInput("send_status");
  local qs = getQuery_select(queryType)
  local inp = teamyar.get_input()
  ---- invoice Filter
  local where_str=" 1=1 "
  dataQuery.query , dataQuery.params  = queryTools.where:init({where_str})
  -- :addIn("ORG_ID", org)


  .run( dataQuery.query ,  dataQuery.params , "{{whereInvoice}}");
  local where_op_transfer = ""

  ---- page Number Query
  dataQuery.query = string.gsub(dataQuery.query,"{{slicePageNumber}}", getQuery_page(queryType , pageFrom , perPage , pageTo));
  dataQuery.query = string.gsub(dataQuery.query,"{{select}}",qs);

  dataQuery.query = string.gsub(dataQuery.query, "{{current_date}}",  currentdate);

teamyar.write_log("org=33===="..json.encode(org))
teamyar.write_log("org====="..json.encode( type(org)=="userdata"))
  if type(org)=="table" and  org ~= nil and org[1] ~= nil and org[1].id ~= nil then
    dataQuery.query = string.gsub(dataQuery.query, "{{org_id}}", org[1].id);
  else
    dataQuery.query = string.gsub(dataQuery.query, "{{org_id}}", "0");
  end 
  local where_stock = ""
  local where_stock_out = ""
  local where_product = ""
  local where_crm= ""
  local where_kcrm= ""
  local where_tag = ""
    local where_moadian_code =""
  local where_factor_id = ""
  local where_send_status = ""
  if type(product)=="table" and product ~= nil and product[1] ~= nil then 
    where_product = where_product.. [[ and ip.product_id=]]..product[1].id

  end 
  if type(stock)=="table" and  stock ~= nil and stock[1] ~= nil then 
    where_stock = where_stock.. [[ and ip.stock_id=]]..stock[1].id
  end 
  if type(crm)=="table" and   crm ~= nil and crm[1] ~= nil then 
    where_crm = where_crm.. [[ and i.client_id=]]..crm[1].id
  end 
  if type(kcrm)=="table" and  kcrm ~= nil and kcrm[1] ~= nil then 
    where_kcrm = where_kcrm.. [[ and (select ty from user_ty where clid=i.client_id and oid=i.org_id )=]]..kcrm[1].id
  end 
  if type(tag)=="table" and  tag ~= nil and tag[1] ~= nil then 
    where_tag = where_tag.. [[ and t.TAG_ID=]]..tag[1].id
  end 
    if type(moadian_code)=="table" and  moadian_code ~= nil and moadian_code ~= "" then 
    where_moadian_code = where_moadian_code.. [[ and (select rf from m_factor_id where invoice_id=i.id order by id desc limit 1 )  like '%%]]..moadian_code..[[%%']]
  end 
  if type(factor_id)~="userdata" and  factor_id ~= nil and factor_id ~= "" then 
    where_factor_id = where_factor_id.. [[ and i.id=]]..factor_id
  end 
  if type(send_status)~="userdata" and  send_status ~= nil and send_status[1] ~= nil then 
    where_send_status = where_send_status.. [[ and moadian_status=]]..send_status[1].id
  end 
  if  type(datet)~="userdata" then
  dataQuery.query = string.gsub(dataQuery.query,"{{datet}}",datet);
  else
      dataQuery.query = string.gsub(dataQuery.query,"{{datet}}",0);
  end
    if  type(datef)~="userdata" then
  dataQuery.query = string.gsub(dataQuery.query,"{{datef}}",datef);
  else
      dataQuery.query = string.gsub(dataQuery.query,"{{datef}}",0);
  end
  dataQuery.query = string.gsub(dataQuery.query,"{{where_stock}}",where_stock);
  dataQuery.query = string.gsub(dataQuery.query,"{{where_tag}}",where_tag);
  dataQuery.query = string.gsub(dataQuery.query,"{{where_product}}",where_product);
  dataQuery.query = string.gsub(dataQuery.query,"{{where_crm}}",where_crm);
  dataQuery.query = string.gsub(dataQuery.query,"{{where_kcrm}}",where_kcrm);
    dataQuery.query = string.gsub(dataQuery.query,"{{where_moadian_code}}",where_moadian_code);
  dataQuery.query = string.gsub(dataQuery.query,"{{where_factor_id}}",where_factor_id);  
  dataQuery.query = string.gsub(dataQuery.query,"{{where_send_status}}",where_send_status);


  ---- Execute Query
   teamyar.write_log(dataQuery.query)
  return getQuery_result(queryType , dataQuery);
end
-----------------------------------------------------------
function queryResult(query, query_params)
  db.use_db("0000000")
  local params = {
    query = query,
    params = query_params
  }
  teamyar.write_log(query)
  db.query(params);
  local res_text = {};
  local record = {};
  while db.query_fetch(record) do
    --id,link,TITLE,d,btn,err,status,referenceNumber,unic_id
    table.insert(res_text, { id = record[1],
        link = record[2], 
        TITLE = record[3],
        d = record[4],
        btn = record[5],
        err = record[6],
        status = record[7],
        referenceNumber = record[8] ,
        unic_id = record[9],
        org_id = record[10]});
  end
  db.query_free();
  return res_text;
end
------------------------
--------------------------------
function queryResultOne(select_query,user_param)
  db.use_db("0000000");
  local params1 = {
    query = select_query,
    params = user_param
  }
  db.query(params1);
  local res_text = db.query_fetch();
  db.query_free();
  if res_text ~= nil then 
    return res_text[1];
  else
    return nil 
  end 
end
---------------------------------------------
function getAllData(org_id,datef,datet,crm_id,kcrm_id,tag_id,product_id,stock_id,moadian_code,factor_id,send_status)
  local aquery = teamyar.get_attachment("query_list_invoice.txt") 
  aquery = string.gsub(aquery, "{{current_date}}",  currentdate);



  if org_id ~= nil  then
    aquery = string.gsub(aquery, "{{org_id}}", org_id);
  else
    aquery = string.gsub(aquery, "{{org_id}}", "0");
  end 
  local where_stock = ""
  local where_stock_out = ""
  local where_product = ""
  local where_crm= ""
  local where_kcrm= ""
  local where_tag = ""
    local where_moadian_code =""
  local where_factor_id = ""
  local where_send_status = ""
  if product_id ~= nil and product_id ~= nil then 
    where_product = where_product.. [[ and ip.product_id=]]..product_id

  end 
  if stock_id ~= nil and stock_id ~= nil then 
    where_stock = where_stock.. [[ and ip.stock_id=]]..stock_id
  end 
  if crm_id ~= nil and crm_id ~= nil then 
    where_crm = where_crm.. [[ and i.client_id=]]..crm_id
  end 
  if kcrm_id ~= nil and kcrm_id ~= nil then 
    where_kcrm = where_kcrm.. [[ and (select ty from user_ty where clid=i.client_id and oid=i.org_id )=]]..kcrm_id
  end 
  if tag_id ~= nil and tag_id ~= nil then 
    where_tag = where_tag.. [[ and t.TAG_ID=]]..tag_id
  end 

    if moadian_code ~= nil and moadian_code ~= "" then 
    where_moadian_code = where_moadian_code.. [[ and (select rf from m_factor_id where invoice_id=i.id order by id desc limit 1 ) like '%%]]..moadian_code..[[%%']]
  end 
  if factor_id ~= nil and factor_id ~= "" then 
    where_factor_id = where_factor_id.. [[ and i.id=]]..factor_id
  end 
  if send_status ~= nil and send_status[1] ~= nil then 
    where_send_status = where_send_status.. [[ and moadian_status=]]..send_status[1].id
  end  
  aquery = string.gsub(aquery,"{{select}}","*");
  aquery = string.gsub(aquery,"{{whereInvoice}}","");
  aquery = string.gsub(aquery,"{{slicePageNumber}}","");
  aquery = string.gsub(aquery,"{{datet}}",datet);
  aquery = string.gsub(aquery,"{{datef}}",datef);
  aquery = string.gsub(aquery,"{{where_stock}}",where_stock);
  aquery = string.gsub(aquery,"{{where_tag}}",where_tag);
  aquery = string.gsub(aquery,"{{where_product}}",where_product);
  aquery = string.gsub(aquery,"{{where_crm}}",where_crm);
  aquery = string.gsub(aquery,"{{where_kcrm}}",where_kcrm);
    aquery = string.gsub(aquery,"{{where_moadian_code}}",where_moadian_code);
  aquery = string.gsub(aquery,"{{where_factor_id}}",where_factor_id);  
  aquery = string.gsub(aquery,"{{where_send_status}}",where_send_status);
  local res_data=queryResult(aquery,{})
  return res_data
end
--------------------------------------------

function getQuery_select(queryType)
  if queryType == _QUERY_TYPE._TYPE_TOTAL_SUM then
    return getTableConfig_sum()
  elseif queryType == _QUERY_TYPE._TYPE_TOTAL_COUNT then
    return getTableConfig_count()
  else
    return getTableConfig_select();
  end
end
--------------------------------------------
function getQuery_page(queryType , pageFrom , perPage , pageTo)
  local slicePageNumber = "";
  if queryType == _QUERY_TYPE._TYPE_PAGE_REPORT then
    local limit = tonumber(perPage);
    local offset = tonumber(pageFrom) ;
    slicePageNumber = "LIMIT "..limit .. " OFFSET "..offset;
  elseif queryType == _QUERY_TYPE._TYPE_PAGE_EXCEL then
    local limit = tonumber(perPage)*(tonumber(pageTo)  - tonumber(pageFrom) + 1) ;
    local offset = tonumber(perPage) *(tonumber(pageFrom) - 1);
    slicePageNumber = "LIMIT "..limit.." OFFSET "..offset;
  end
  return slicePageNumber;
end
--------------------------------------------
function getQuery_result(queryType , dataQuery)
  local resultExp = nil;

  db.query(dataQuery)
  local record={};
  if queryType == _QUERY_TYPE._TYPE_TOTAL_COUNT then
    record = db.query_fetch();
    resultExp = record[1];
  elseif queryType == _QUERY_TYPE._TYPE_TOTAL_SUM then
    local columnsSelected = {};
    local columns = getTableConfig();
    for i = 1, #columns , 1 do
      local itemColumns = columns[i];
      if itemColumns.key ~= nil and itemColumns.sum ~= nil and itemColumns.sum == true then
        table.insert(columnsSelected , itemColumns.key)
      end
    end
    if #columns > 0 then
      resultExp = {};
      record = db.query_fetch();
      for i = 1, #columnsSelected , 1 do
        resultExp[columnsSelected[i]] = record[i];
      end
    end
  else
    resultExp = {};
    while db.query_fetch(record) do
      local itemRow = {};
      local columns = getTableConfig();
      for i = 1, #columns , 1 do
        local itemColumns = columns[i];
        if itemColumns.key ~= nil then
          itemRow[itemColumns.key] = record[i];
        end
      end
      table.insert(resultExp, itemRow)
    end
  end
  db.query_free();

  return resultExp;
end

--------------------------------------------
function getTableConfig()
  local cols={
    {show= true ,   key = "id"                  		 , value = "id" } ,
    {show= true ,   key = "link"                  		 , value = "link" } ,
    {show= true ,    key = "title"           , value= "title" } ,
    {show= true ,    key = "d"           , value= "d" ,type="date"} ,
    {show= true ,    key = "status"           , value= "status" } ,
    {show= true ,    key = "referenceNumber"           , value= "referenceNumber" } ,
    {show= true ,    key = "unic_id"           , value= "unic_id" } ,
    {show= true ,    key = "err"           , value= "err" } ,
    {show= true ,    key = "btn"           , value= "btn" } ,
  };
  --   teamyar.write_log("ffcols6"..json.encode(cols))
  return cols
end
--------------------------------------------
function getTableConfig_sum()
  -- teamyar.write_log("summ --")
  local columnsSelected = {};
  local select = "";
  local columns = getTableConfig();
  for i = 1, #columns , 1 do
    local itemColumns = columns[i];
    if itemColumns.key ~= nil and itemColumns.sum ~= nil and itemColumns.sum == true then
      table.insert(columnsSelected , itemColumns.key)
    end
  end
  for i = 1, #columnsSelected , 1 do
    local itemColumnsSelected = columnsSelected[i];
    select = select .."sum("..itemColumnsSelected..")"
    if i < #columnsSelected   then
      select = select..",";
    end
  end
  return select;
end
--------------------------------------------
function getTableConfig_select()
  local columnsSelected = {};
  local select = "";
  local columns = getTableConfig();
  for i = 1, #columns , 1 do
    local itemColumns = columns[i];
    if itemColumns.key ~= nil then
      table.insert(columnsSelected , itemColumns.key)
    end
  end
  for i = 1, #columnsSelected , 1 do
    local itemColumns = columnsSelected[i];
    select = select..itemColumns;
    if i < #columns   then
      select = select.. ",";
    end
  end
  return select;
end
--------------------------------------------
function getTableConfig_count()
  return "count(*)";
end
--------------------------------------------
function getTableConfig_header()
  local headers = {};
  local totalHeader = getTableConfig();
  for i = 1, #totalHeader , 1 do
    local itemHeader = totalHeader[i];
    if itemHeader.show ~= nil and itemHeader.show == true then
      table.insert(headers ,itemHeader );
    end
  end
  return headers;
end
---------------------------------------------
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
-----------------------------------------------------------------------
function orgAcl(data)
  local query_param = [[ select id,name from org_info ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  where name like N'%]]..data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end
----------------------
function productAcl(data)
  local geted_org_id = data.org_id;
  local query_param = [[select id,concat(full_code,'_',name)name from wh_product  where voucher_allow=1  and org_id=]]..geted_org_id
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  and  (name like N'%]]..data.search..[[%' or  full_code like N'%]]..data.search..[[%') ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end
----------------------
function StockAcl(data)
  local geted_org_id = data.org_id;
  local query_param = [[select id,concat(full_code,'_',name)name from wh_stock  where  org_id=]]..geted_org_id
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  and  (name like N'%]]..data.search..[[%' or  full_code like N'%]]..data.search..[[%') ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end
----------------------
function crmAcl(data)
  local geted_org_id = data.org_id;
  local query_param = [[select id,name from pa_client where  org_id= ]]..geted_org_id
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  and  name like N'%]]..data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end 
----------------------
function crmTag(data)

  local query_param = [[select id,name from  pa_voucher_tag where 1=1 ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  and  name like N'%]]..data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end 
--------------------------------------------
function kcrmAcl()
  local table = {
    {id =3,name=translateWord("حقیقی")},
    {id =4,name=translateWord("حقوقی")},

  }
  teamyar.write_result(json.encode(table));
end
--------------------------------------------
function sendStatusAcl()
  local table = {
    {id =0,name=translateWord("ارسال نشده")},
    {id =1,name=translateWord("ارسال شده")},
    {id =2,name=translateWord("خطا")},
    {id =3,name=translateWord("تایید")},
    {id =4,name=translateWord("درخواست ابطال")},
    {id =5,name=translateWord("خطا در ثبت ابطال")},
    {id =6,name=translateWord("ابطال شده")},
  }
  teamyar.write_result(json.encode(table));
end
--------------------------------------------
--- Report
--------------------------------------------
function report()
  local data= getTableSectionOne()
  local report = {
    {
      name = "table" ,
      title = "table" ,
      report = data
    }
  }
  return report;
end
--------------------------------------------
function getTableSectionOne()
  local repId = getInput("rep_id");
  local headers = getTableConfig_header();
  local from = getInput("page");
  local values  = getData(_QUERY_TYPE._TYPE_PAGE_REPORT , from , _PAR_PAGE);
  local total  = getData(_QUERY_TYPE._TYPE_TOTAL_COUNT);
  --local sums  = getData(_QUERY_TYPE._TYPE_TOTAL_SUM , from , _PAR_PAGE);
  return install_res.resTable(repId , headers , values  , total , _PAR_PAGE , from,sums );
end
--------------------------------------------
--- excel
--------------------------------------------
function excel()
  local excelFileName = getInput("excel_file_name");
  local excelFormPage = getInput("excel_from_page");
  local excelToPage = getInput("excel_to_page");
  local excelPerPage = getInput("excel_per_page");
  local headers = getTableConfig_header();
  local values = getData(_QUERY_TYPE._TYPE_PAGE_EXCEL ,  excelFormPage , excelPerPage , excelToPage)
  return install_res.resExcel( headers , values , excelFileName);
end
--------------------------------------------
--- print
--------------------------------------------
function print()
  local headers = getTableConfig_header();
  local values = getData(_QUERY_TYPE._TYPE_PAGE_PRINT)
  return install_res.resPrint( headers , values);
end
--------------------------------------------
--- manager
--------------------------------------------
function savefactor(fid,referenceNumber,date_replace,factor_code,org_id)


    local res_bot = ""
    local config_id = queryResultOne([[select  CONFIG_ID  from bot_command_config where COMMAND_ID=]]..c_bot_send_id..[[ and json_unquote(config->"$.org_id")=]]..org_id,{})
    if config_id == nil or config_id ==0 then 
   	res_bot = [[ برای شعبه انتخاب شده در بات  "ارسال فاکتور ابطالی به سامانه مودیان" پیکربندی ای یافت نشد]]
  else
    teamyar.write_log("factor_code---"..factor_code)
     res_bot = teamyar.run_command("2/tax_gov_edit/"..config_id ,
        {invoice_id = tostring(fid), referenceNumber = referenceNumber,
          date_replace= date_replace,invoice_factor_code=factor_code,kind_refrence=3});
  -- teamyar.write_log("res_bot---"..res_bot)
  end
  return res_bot
end
--------------------------------------------
local type = getInput("type");
if type ~= nil and type == 100 then
  local result = report()
  teamyar.write_result(json.encode(result));
elseif type ~= nil and type == 7 then
  orgAcl(teamyar.get_input().data)
elseif type ~= nil and type == 9 then
  productAcl(teamyar.get_input().data)  
elseif type ~= nil and type == 4 then
  crmAcl(teamyar.get_input().data)
elseif type ~= nil and type == 5 then
  crmTag(teamyar.get_input().data)
elseif type ~= nil and type == 8 then
  StockAcl(teamyar.get_input().data)
elseif type ~= nil and type == 3 then
  kcrmAcl()
  elseif type ~= nil and type == 6 then
  sendStatusAcl()
elseif type ~= nil and type == 10 then
  local input= teamyar.get_input()
  local fid=input.fid
  local referenceNumber = input.referenceNumber
  local date_replace=input.date_replace
   
  teamyar.write_log(" input.factor_code--"..json.encode(input.factor_code))
  local msg ="شماره فاکتور:"..fid.."  ".. savefactor(fid,referenceNumber,date_replace,input.factor_code,input.org_id)
  teamyar.write_log(" msg---"..json.encode(msg))
  local res_data={msg=msg}
  teamyar.write_result(json.encode(res_data))
elseif type ~= nil and type == 11 then
  local input= teamyar.get_input()
     teamyar.write_log(" input--55---"..json.encode(input))
  --local datas=input.datas
  local date_replace=input.date_replace
  local res_data=getAllData(input.org_id,input.datef,input.datet,input.crm_id,input.kcrm_id,input.tag_id,input.product_id,input.stock_id,input.moadian_code,input.factor_id,input.send_status)
  --datef:datef,datet:datet,org_id:org.id,crm_id:crm.id,kcrm_id:kcrm.id,product_id:product.id,stock_id:stock.id,tag_id:tag.id
  -- local datef=input.da
  --  local referenceNumber = input.referenceNumber
  local res_str =""
  local count_send =0
  for i,v in ipairs (res_data) do 
    if  v.status~="تایید شده" then
      savefactor(v.id, v.referenceNumber, date_replace,v.unic_id,v.org_id)-- .."<hr>"
      count_send = count_send +1
    end 
  end
  res_str = " تعداد  "..count_send.."  فاکتور به سامانه مودیان ارسال شد   ."
  local res_data={msg=res_str}
  teamyar.write_result(json.encode(res_data))
elseif type ~= nil and type == 101 then
  local result = excel()
  teamyar.write_result(json.encode(result));
elseif type ~= nil and type == 102 then
  local result = print()
  teamyar.write_result(json.encode(result));
else
  local responseResReport = install_res.resReport(getTableConfig());
  teamyar.write_result(responseResReport);
end




