-- botName = Sum Workdays And Sales Params
-- creator = zmo
-- date = 02/25/2025
-- version= 2.0
--------------------------------------------
--- CONFIG DATA
--------------------------------------------

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
  local day = time.get_day(time.current());
  local month = time.get_month(time.current());
  local year = time.get_year(time.current());
  local hour = time.get_hour(time.current());
  local min = time.get_minute (time.current());
  local sec = time.get_second(time.current());
  local currentdate_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":]]..hour..[[,"minute":]]..min..[[,"second":]]..sec..[[}]])
  local temp_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":0,"minute":0,"second":0}]])
  local currentdate = string.format("%18.0f" ,temp_time);
  local user_info = teamyar.get_user_info()
  local time_zone = user_info.timezone
  local org = getInput("org_id");
  local mount = getInput("mount");
    local swmount = getInput("first_work_month");
  local personnel_id = getInput("personnel_id");
  local input = teamyar.get_input()
  local datef = input.datef
  local datet =input.datet
  local active_order = getInput("active_order");
  local user_type = getInput("user_type");
  teamyar.write_log("ac---"..json.encode(active_order))
  teamyar.write_log("mount---"..json.encode(mount))
  teamyar.write_log("#personnel_id---"..json.encode(#tostring(personnel_id)))
  local qs = getQuery_select(queryType)
  ---- invoice Filter
  local where_str=" 1=1 "
  if personnel_id ~= nil and type(personnel_id)=="number"  then 
    where_str = where_str.." and PERSONNEL_ID = "..personnel_id
  end
  if mount ~= nil and mount[1]~= nil  then 
    where_str = where_str.." and JTMONTH ='"..mount[1].name.."' "
  end
    if swmount ~= nil and swmount[1]~= nil  then 
    where_str = where_str.." and first_work_month ='"..swmount[1].name.."' "
  end
  dataQuery.query , dataQuery.params  = queryTools.where:init({where_str})
  :addIn("ORG_ID", org)
  -- :addIn("PERSONNEL_ID", personnel_id)
  :add("df" , ">=" , datef)
  :add("dt" , "<=" , datet)
  .run( dataQuery.query ,  dataQuery.params , "{{whereInvoice}}");
  ---- page Number Query
  dataQuery.query = string.gsub(dataQuery.query,"{{slicePageNumber}}", getQuery_page(queryType , pageFrom , perPage , pageTo));
  dataQuery.query = string.gsub(dataQuery.query,"{{select}}",qs);

  --
  local inner_where =""
  if active_order ~= nil and active_order== 1 then 
    inner_where = inner_where..[[ and   ]]..currentdate..[[ between o.DATE_FROM and o.DATE_TO  ]]
  end 
  if user_type ~= nil and user_type[1]~= nil  then 
    if  user_type[1].id ==1 then 
      inner_where = inner_where.." and (select STATUS from  profile_module_status where MODULE_ID=3 and  PROFILE_ID=p.id)<>3 "
    else
      inner_where = inner_where.." and (select STATUS from  profile_module_status where MODULE_ID=3 and  PROFILE_ID=p.id)=3 "
    end
  end

  dataQuery.query = string.gsub(dataQuery.query, "{{inner_where}}",  inner_where);
    dataQuery.query = string.gsub(dataQuery.query, "{{current_date}}",  currentdate);

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
    {show= false ,   key = "ORG_ID"                  		 , value = "ORG_ID" } ,
    {show= true ,   key = "PIC"                  	, value = "PIC" } ,
    {show= false ,   key = "id"                  	, value = "id" } ,
    {show= false ,   key = "PERSONNEL_ID"                  	, value = "PERSONNEL_ID" } ,
    {show= true ,    key = "show_link"           , value= "show_link"  , type="link"  , link="/?page=/warehouse/add_operation/view/{{id}}"          ,params= {"id"}} ,
    {show= true ,   key = "FULLNAME"                  	, value = "FULLNAME" } ,
    {show= true ,   key = "bd"                  	, value = "bd"  , type="date"} ,
    {show= true ,   key = "df"                  	, value = "df" , type="date"} ,
        {show= true ,   key = "INSURANCE_START_DATE"                  	, value = "INSURANCE_START_DATE" , type="date"} ,
    {show= true ,   key = "dif"                  	, value = "dif" } ,
    {show= true ,   key = "JTMONTH"                  	, value = "JTMONTH" } ,
     {show= true ,   key = "first_work_month"                  	, value = "first_work_month" } 
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
function mountAcl(data)
  local table = {
    {id = 1, name = "فروردین"},
    {id = 2, name = "اردیبهشت"},
    {id = 3, name = "خرداد"},
    {id = 4, name = "تیر"},
    {id = 5, name = "مرداد"},
    {id = 6, name = "شهریور"},
    {id = 7, name = "مهر"},
    {id = 8, name = "آبان"},
    {id = 9, name = "آذر"},
    {id = 10, name = "دی"},
    {id = 11, name = "بهمن"},
    {id = 12, name = "اسفند"},
  }
  teamyar.write_result(json.encode(table));
end
---------------------------------------------
function userTypeAcl(data)
  local table = {
    {id = 1, name = "فعال"},
    {id = 2, name = "غیرفعال"},
  }
  teamyar.write_result(json.encode(table));
end
--------------------------------------------
function getAclPersonnel(data)
  local day = time.get_day(time.current());
  local month = time.get_month(time.current());
  local year = time.get_year(time.current());
  local hour = time.get_hour(time.current());
  local min = time.get_minute (time.current());
  local sec = time.get_second(time.current());
  local currentdate_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":]]..hour..[[,"minute":]]..min..[[,"second":]]..sec..[[}]])
  local temp_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":0,"minute":0,"second":0}]])
  currentdate = string.format("%18.0f" ,temp_time);
  local unit = data.unit_id
  if unit == nil then
    unit=0
  end 
  local query_param = [[ select distinct  h.PERSONNEL_ID,concat('#',h.PERSONNEL_ID,'_',p.fullname)n from hr_personnels h
  inner join profile_main p on p.id=h.PROFILE_ID inner join hr_personnel_order o on o.PERSONNEL_ID=h.PERSONNEL_ID ]]
--  where  ]]..currentdate..[[ between DATE_FROM and DATE_TO  ]]
  if unit ~= nil and unit > 0 then
    query_param = query_param..[[  and   (select UNIT_ID from org_organization_unit WHERE ID=o.UNIT_ID)= ]].. unit
  end 
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  and p.fullname  like N'%]]..data.search..[[%'  or h.PERSONNEL_ID like N'%]]..data.search..[[%' ]]
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
local type = getInput("type");
if type ~= nil and type == 100 then
  local result = report()
  teamyar.write_result(json.encode(result));
elseif type ~= nil and type == 7 then
  orgAcl(teamyar.get_input().data)
elseif type ~= nil and type == 9 then
  mountAcl(teamyar.get_input().data)  
elseif type ~= nil and type == 8 then
  getAclPersonnel(teamyar.get_input().data)
elseif type ~= nil and type == 6 then
  userTypeAcl(teamyar.get_input().data)
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




