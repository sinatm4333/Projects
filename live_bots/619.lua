-- botName = send group 
-- creator = zmo
-- date = 02/25/2025
-- version= 1.0

--
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



  if org ~= nil and type(org) == "table" then
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

  if product ~= nil and  type(product) == "table" and product[1] ~= nil then 
    where_product = where_product.. [[ and ip.product_id=]]..product[1].id

  end 
  if stock ~= nil and  type(stock) == "table" and stock[1] ~= nil then 
    where_stock = where_stock.. [[ and ip.stock_id=]]..stock[1].id
  end 
  if crm ~= nil and  type(crm) == "table" and crm[1] ~= nil then 
    where_crm = where_crm.. [[ and i.client_id=]]..crm[1].id
  end 
  if kcrm ~= nil  and  type(kcrm) == "table" and kcrm[1] ~= nil then 
    where_kcrm = where_kcrm.. [[ and (select ty from user_ty where clid=i.client_id and oid=i.org_id )=]]..kcrm[1].id
  end 
  if tag ~= nil  and  type(tag) == "table" and tag[1] ~= nil then 
    where_tag = where_tag.. [[ and t.TAG_ID=]]..tag[1].id
  end 

  if moadian_code ~= nil  and  type(moadian_code) == "string" and moadian_code ~= "" and  tostring(moadian_code) ~= "0" and  moadian_code ~= "null" and  moadian_code ~= "nil" then 
    where_moadian_code = where_moadian_code.. [[ and (select rf from m_factor_id where invoice_id=i.id order by id desc limit 1 )  like '%%]]..moadian_code..[[%%']]
  end 
--  teamyar.write_log("type(factor_id)----"..type(factor_id))
  if factor_id ~= nil and  type(factor_id) == "number"  and factor_id ~= "" and  tostring(factor_id) ~= "0" and  factor_id ~= "null" and  factor_id ~= "nil"  then 
    where_factor_id = where_factor_id.. [[ and i.id=]]..factor_id
  end 
  if send_status ~= nil and  type(send_status) == "table" and send_status[1] ~= nil then 
    where_send_status = where_send_status.. [[ and moadian_status=]]..send_status[1].id
  end 
  if type(datet)~="number" then
    datet = 0
  end
  if type(datef)~="number" then
    datef = 0
  end
  dataQuery.query = string.gsub(dataQuery.query,"{{datet}}",datet);
  dataQuery.query = string.gsub(dataQuery.query,"{{datef}}",datef);
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
--------------------------------
function queryResultOne(select_query,user_param)
  db.use_db("0000000");
  teamyar.write_log(select_query)
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
   
    {show= true ,    key = "fee"           , value= "fee" ,type="price",sum=true} ,
    {show= true ,    key = "discount"           , value= "discount" ,type="price",sum=true} ,
    {show= true ,    key = "value_added"           , value= "value_added" ,type="price",sum=true} ,
    {show= true ,    key = "price_fact"           , value= "price_fact" ,type="price",sum=true} ,
    {show= true ,    key = "amont"           , value= "amont" ,type="price",sum=true} ,
     {show= true ,    key = "product_codes"           , value= "product_codes" } ,
          {show= true ,    key = "bill_type"           , value= "bill_type" } ,
      {show= true ,    key = "bill_template"           , value= "bill_template" } ,
    {show= true ,    key = "status"           , value= "status" } ,
        {show= true ,    key = "unic_id"           , value= "unic_id" } ,
        {show= true ,    key = "ref_invoce_id"           , value= "ref_invoce_id" } ,
        {show= true ,    key = "ref_id"           , value= "ref_id" } ,
    {show= true ,    key = "comment"           , value= "comment" } ,
    {show= true ,    key = "type_send"           , value= "type_send" } ,
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
  local query_param = [[select id,concat(full_code,'_',name)name from wh_stock  where  VOUCHER_ALLOW=1 and  org_id=]]..geted_org_id
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
function sendStatusAcl(data)
  local moadian_status_table = {
    {id = 101, name = translateWord("پذیرفته شده [ارسالی]")},
    {id = 102, name = translateWord("رد شده [ارسالی]")},
    {id = 103, name = translateWord("در انتظار بررسی [ارسالی]")},
    {id = 104, name = translateWord("ابطال شده [ارسالی]")},
    {id = 105, name = translateWord("ناموفق / خطا در پردازش [ارسالی]")},
    {id = 106, name = translateWord("در حال پردازش [ارسالی]")},
    {id = 107, name = translateWord("پیش‌نویس [ارسالی]")},
    {id = 108, name = translateWord("ارسال شده [ارسالی]")},
    {id = 109, name = translateWord("در انتظار [ارسالی]")},
    {id = 110, name = translateWord("دیگر نیازی به واکنش نیست [ارسالی]")},
    {id = 111, name = translateWord("نامشخص [ارسالی]")},
    {id = 112, name = translateWord("پیدا نشده [ارسالی]")},
    {id = 113, name = translateWord("خطادراستعلام [ارسالی]")},
    {id = 114, name = translateWord("خطا در ارتباط [ارسالی]")},
    {id = 115, name = translateWord("استعلام نشده [ارسالی]")},
    {id = 116, name = translateWord("عدم ارسال/خطا [ارسالی]")},
    {id = 117, name = translateWord("تنظیمات پیکربندی خالی [ارسالی]")},
    {id = 118, name = translateWord("عدم ارتباط سامانه [ارسالی]")},
    {id = 201, name = translateWord("پذیرفته شده [ابطالی]")},
    {id = 202, name = translateWord("رد شده [ابطالی]")},
    {id = 203, name = translateWord("در انتظار بررسی [ابطالی]")},
    {id = 204, name = translateWord("ابطال شده [ابطالی]")},
    {id = 205, name = translateWord("ناموفق / خطا در پردازش [ابطالی]")},
    {id = 206, name = translateWord("در حال پردازش [ابطالی]")},
    {id = 207, name = translateWord("پیش‌نویس [ابطالی]")},
    {id = 208, name = translateWord("ارسال شده [ابطالی]")},
    {id = 209, name = translateWord("در انتظار [ابطالی]")},
    {id = 210, name = translateWord("دیگر نیازی به واکنش نیست [ابطالی]")},
    {id = 211, name = translateWord("نامشخص [ابطالی]")},
    {id = 212, name = translateWord("پیدا نشده [ابطالی]")},
    {id = 213, name = translateWord("خطادراستعلام [ابطالی]")},
    {id = 214, name = translateWord("خطا در ارتباط [ابطالی]")},
    {id = 215, name = translateWord("استعلام نشده [ابطالی]")},
    {id = 216, name = translateWord("عدم ارسال/خطا [ابطالی]")},
    {id = 217, name = translateWord("تنظیمات پیکربندی خالی [ابطالی]")},
    {id = 218, name = translateWord("عدم ارتباط سامانه [ابطالی]")},
    {id = 301, name = translateWord("پذیرفته شده [اصلاحی]")},
    {id = 302, name = translateWord("رد شده [اصلاحی]")},
    {id = 303, name = translateWord("در انتظار بررسی [اصلاحی]")},
    {id = 304, name = translateWord("ابطال شده [اصلاحی]")},
    {id = 305, name = translateWord("ناموفق / خطا در پردازش [اصلاحی]")},
    {id = 306, name = translateWord("در حال پردازش [اصلاحی]")},
    {id = 307, name = translateWord("پیش‌نویس [اصلاحی]")},
    {id = 308, name = translateWord("ارسال شده [اصلاحی]")},
    {id = 309, name = translateWord("در انتظار [اصلاحی]")},
    {id = 310, name = translateWord("دیگر نیازی به واکنش نیست [اصلاحی]")},
    {id = 311, name = translateWord("نامشخص [اصلاحی]")},
    {id = 312, name = translateWord("پیدا نشده [اصلاحی]")},
    {id = 313, name = translateWord("خطادراستعلام [اصلاحی]")},
    {id = 314, name = translateWord("خطا در ارتباط [اصلاحی]")},
    {id = 315, name = translateWord("استعلام نشده [اصلاحی]")},
    {id = 316, name = translateWord("عدم ارسال/خطا [اصلاحی]")},
    {id = 317, name = translateWord("تنظیمات پیکربندی خالی [اصلاحی]")},
    {id = 318, name = translateWord("عدم ارتباط سامانه [اصلاحی]")},
    {id = 0,   name = translateWord("ارسال نشده")},
    {id = 1,   name = translateWord("ارسال شده")},
    {id = 2,   name = translateWord("خطا")},
    {id = 3,   name = translateWord("تایید")},
    {id = 4,   name = translateWord("درخواست ابطال")},
    {id = 5,   name = translateWord("خطا در ثبت ابطال")},
    {id = 6,   name = translateWord("ابطال شده")},
  }

  if data.search ~= nil and #data.search > 0 then
    local filtered = {}
    for _, item in ipairs(moadian_status_table) do
      if string.find(item.name, data.search, 1, true) ~= nil then
        table.insert(filtered, item)
      end
    end
    teamyar.write_result(json.encode(filtered))
  else
      teamyar.write_result(json.encode(moadian_status_table))
  end

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
  local sums  = getData(_QUERY_TYPE._TYPE_TOTAL_SUM , from , _PAR_PAGE);
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
  sendStatusAcl(teamyar.get_input().data)
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




