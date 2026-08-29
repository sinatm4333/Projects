-- botName = Sum Workdays And Sales Params
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
local _PAR_PAGE = 25
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
local c_confirm=""
  local c_count_out = 0
  if config ~= nil then 
    cdata = config.data
    c_count_out = cdata.count_out
    c_confirm= cdata.fconfirm
  end 
  
  
  local user_info = teamyar.get_user_info()
  local time_zone = user_info.timezone
  local org = getInput("org_id");
  local wf = getInput("wf");
    local cat = getInput("cat");
  local section = getInput("sectoin");
   local product = getInput("product");
    local crm = getInput("crm");
 local datef = getInput("datef");
   local datet = getInput("datet");
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
dataQuery.query = string.gsub(dataQuery.query, "{{c_confirm}}",  c_confirm);


  if org ~= nil  then
    dataQuery.query = string.gsub(dataQuery.query, "{{org_id}}", org[1].id);
  else
    dataQuery.query = string.gsub(dataQuery.query, "{{org_id}}", "0");
  end 
local where_wf = ""

  local where_cat = ""
  local where_crm= ""
  local where_product = ""
  local where_section = ""
  if cat ~= nil and cat[1] ~= nil then 
    where_cat = where_cat.. [[ and t.CATEGORY_ID=]]..cat[1].id

  end 
    if wf ~= nil and wf[1] ~= nil then 
    where_wf = where_wf.. [[ and t.WORK_FLOW_ID=]]..wf[1].id
  end 
      if crm ~= nil and crm[1] ~= nil then 
    where_crm = where_crm.. [[ and (select  p.id from todo_ty_links l inner join profile_main p on p.id=l.DST_LINK_ID where DST_MODULE_ID=14 and DST_TYPE=1 )=]]..crm[1].id
  end 
        if product ~= nil and product[1] ~= nil then 
    where_product = where_product.. [[ and (select  p.id from todo_ty_links l inner join profile_main p on p.id=l.DST_LINK_ID where DST_MODULE_ID=17 and DST_TYPE=8 )=]]..product[1].id
  end 
        if section ~= nil and section[1] ~= nil then 
    where_section = where_section.. [[ and t.CATEGORY_ID in ( select id from  todo_category where SECTION_ID=]]..section[1].id..[[) ]]
  end 
  
  dataQuery.query = string.gsub(dataQuery.query,"{{datet}}",datet);
  dataQuery.query = string.gsub(dataQuery.query,"{{datef}}",datef);
    dataQuery.query = string.gsub(dataQuery.query,"{{where_product}}",where_product);
  dataQuery.query = string.gsub(dataQuery.query,"{{where_wf}}",where_wf);
  dataQuery.query = string.gsub(dataQuery.query,"{{where_section}}",where_section);
  dataQuery.query = string.gsub(dataQuery.query,"{{where_cat}}",where_cat);
  dataQuery.query = string.gsub(dataQuery.query,"{{where_crm}}",where_crm);


  ---- Execute Query
  teamyar.write_log(dataQuery.query)
  return getQuery_result(queryType , dataQuery);
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
    {show= true ,    key = "status"           , value= "status" } ,
 {show= true ,    key = "date"           , value= "date",type="date" } ,
    {show= true ,    key = "crm"           , value= "crm" } ,
    {show= true ,    key = "product"           , value= "product" } ,
    {show= true ,    key = "btn"           , value= "btn" } ,
  };
  --   teamyar.write_log("ffcols6"..json.encode(cols))
  return cols
end
--------------------------------------------
function getTableConfig_sum()
  teamyar.write_log("summ --")
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
function catAcl(data)
  local section_id = data.section;
  local query_param = [[select id,CATEGORY_TITLE name from todo_category  where  SECTION_ID=]]..section_id
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  and CATEGORY_TITLEe like N'%]]..data.search..[[%'  ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end
----------------------
function wfAcl(data)
   local cat_id = data.cat;
  local query_param = [[select id,WF_TITLE from todo_workflow  where  CATEGORY_ID=]]..cat_id
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  and  WF_TITLE like N'%]]..data.search..[[%'  ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end
----------------------
function crmAcl(data)
   local geted_org_id = data.org_id;
  local query_param = [[select p.id,p.fullname from profile_main p inner join crm_info c on c.id=p.id where  1=1 ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  and  name like N'%]]..data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_log(query_param)
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end 
----------------------
function sectionAcl(data)

  local query_param = [[select id,SECTION_NAME from  todo_section where 1=1 ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  and  SECTION_NAME like N'%]]..data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
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
function confirmTodo(tid)
  teamyar.write_log("tttttttt---"..tid)
  local js={confirm=1}
    local info =	{
id= tid,
	type= 5,
	form_data=json.encode(js)
}
    teamyar.write_log(json.encode(info))
    local   res = teamyar.call_api(8, '/api/todo/customform/update', info);
    teamyar.write_log(json.encode(res))
  return json.encode(res)
end
--------------------------------------------
local type = getInput("type");
if type ~= nil and type == 100 then
  local result = report()
  teamyar.write_result(json.encode(result));
elseif type ~= nil and type == 7 then
  orgAcl(teamyar.get_input().data)
elseif type ~= nil and type == 9 then
    catAcl(teamyar.get_input().data)  
elseif type ~= nil and type == 4 then
  crmAcl(teamyar.get_input().data)
elseif type ~= nil and type == 5 then
  sectionAcl(teamyar.get_input().data)
elseif type ~= nil and type == 8 then
wfAcl(teamyar.get_input().data)
  elseif type ~= nil and type == 6 then
  productAcl(teamyar.get_input().data)
  elseif type ~= nil and type == 10 then
  local input= teamyar.get_input()
  local tid=input.tid

local msg ="شماره اقدام:"..tid.."  ".. confirmTodo(tid)
  local res_data={msg=msg}
  teamyar.write_result(json.encode(res_data))
  elseif type ~= nil and type == 11 then
  local input= teamyar.get_input()
  local datas=input.datas
 --  local referenceNumber = input.referenceNumber
local res_str =""
  local count_send =0
  for i,v in ipairs (datas) do 
  --  res_str=res_str..i..") ".."شماره فاکتور:"..v.id.."  ".. 
    confirmTodo(v.id)-- .."<hr>"
    count_send = count_send +1
  end
  res_str = " تعداد  "..count_send.."  اقدام تایید شد برای مشاهده نتیجه گزارش را مجدد اجرا نمایید  ."
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




