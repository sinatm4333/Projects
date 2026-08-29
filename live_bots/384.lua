-- botName = Sum Workdays And Sales Params
-- creator = zmo
-- date = 02/25/2025
-- version= 1.0
--------------------------------------------
--- CONFIG DATA
--------------------------------------------
local config = teamyar.get_config()
local _PAR_PAGE= 25
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
  currentdate = string.format("%18.0f" ,temp_time);
  local org = getInput("org_id");
    local datef = getInput("datef");
    local datet = getInput("datet");
  local unit_id = getInput("unit");
  local personnel = getInput("personnel");
  local salary_group= getInput("salary_group");
  local qs= getQuery_select(queryType)
  ---- invoice Filter
  local where_str=" 1=1 "
  dataQuery.query , dataQuery.params  = queryTools.where:init({where_str})
  :addIn("ORG_ID", org)
  :addIn("unit_id",unit_id)
  :addIn("PersonnelID" , personnel)
  :addIn("salary_group_id" , salary_group)
  .run( dataQuery.query ,  dataQuery.params , "{{whereInvoice}}");
  ---- page Number Query
  dataQuery.query = string.gsub(dataQuery.query,"{{slicePageNumber}}", getQuery_page(queryType , pageFrom , perPage , pageTo));
  dataQuery.query = string.gsub(dataQuery.query,"{{select}}",qs);
  local param1 =  "--"
  local param3 =  "--"
  local param2 =  "--"
  local param4 = "--"
  local param5 =  "--"
  local work_day_name = "--"
  local config = teamyar.get_config()

  if config ~= nil  then 
    local config_data = config.data
    if config_data ~= nil  then 
         
      param1 =  config_data.base_salary_pname
      param3 =  config_data.attraction_right_pname
      param2 =  config_data.base_sanavat_pname
      param4 =  config_data.gurd_right_pname
      param5 =  config_data.params_pname
      work_day_name = config_data.work_day_name
    end
  end

  dataQuery.query = string.gsub(dataQuery.query, "{{param_name1}}","پارامتر حقوق پایه") --param1);
  dataQuery.query = string.gsub(dataQuery.query, "{{param_name2}}", "پارامتر حق سنوات")--param2);
  dataQuery.query = string.gsub(dataQuery.query, "{{param_name3}}", "پارامتر حق جذب")--param3);
  dataQuery.query = string.gsub(dataQuery.query, "{{param_name4}}", "پارامترحق سرپرستی")----param4);
  dataQuery.query = string.gsub(dataQuery.query, "{{param_name5}}", "پارامترحقوق و دستمزد")--param5);
  if work_day_name == nil  then 
    work_day_name = "--"
  end
  dataQuery.query = string.gsub(dataQuery.query, "{{param_wh_name}}","روز کارکرد")-- work_day_name);
  if org ~= nil  then
    dataQuery.query = string.gsub(dataQuery.query, "{{org_id}}", org[1].id);
  else
    dataQuery.query = string.gsub(dataQuery.query, "{{org_id}}", "0");
  end 
  if datef ~= nil and datet ~= nil then    
    datet=datet+(60*60*10000000*12)
        datet=datet-(60*60*10000000*24)
   local temp_str = [[ and ]]..datef..[[ <=pl.DATE_FROM and ]]..datet..[[>=pl.DATE_TO ]]
   dataQuery.query = string.gsub(dataQuery.query, "{{wherepaylisp}}", temp_str);
  else 
    dataQuery.query = string.gsub(dataQuery.query, "{{wherepaylisp}}", "");
  end 
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
    {show= false ,   key = "ORG_ID"                  			, value = "ORG_ID" } ,
    {show= false ,   key = "PersonnelID"                  	  , value = "PersonnelID" } ,
    {show= true ,   key = "pname"                  				, value = "PERSONNEL" } ,
    {show= true ,   key = "PersonnelCode"                  	, value = "PERSONNEL_CODE" } ,    
    {show= true ,   key = "ncode"                  				  , value = "NATIONAL_CODE" } ,
    {show= true ,   key = "u"                  						 , value = "UNIT" } ,
    {show= true ,   key = "sg"                  				     , value = "SALARY_GROUP" } ,
    {show= true ,   key = "OrderID"                  			  , value = "ORDER_ID" } ,
    {show= true ,   key = "wh"                  					 , value = "COUNT_DAY" ,type="price", sum=true} ,
    {show= true ,   key = "param1"                  			  , value = "BASE_SALARY",type="price", sum=true} ,
    {show= true ,   key = "param2"                  			  , value = "BASE_SANAVAT",type="price", sum=true} ,
    {show= true ,   key = "param3"                  			  , value = "ATTRACTION_RIGHT" ,type="price", sum=true} ,
    {show= true ,   key = "param4"                  			  , value = "GURD_RIGHT",type="price" , sum=true} ,
    {show= true ,   key = "param5"                  			  , value = "PARAMS",type="price" , sum=true} ,

  };
  --   teamyar.write_log("ffcols6"..json.encode(cols))
  return cols
end
--------------------------------------------
function getTableConfig_sum()
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
---------------------------------------------
-------------------------------------------
function queryResultt(select_query,user_param)
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
local tt=[[

SELECT group_concat(o.id) v FROM HR_PAYSLIP_PAYMENT_DETAIL pdt inner join
HR_PAYSLIP pl on pdt. PAYSLIP_ID=pl.id inner join hr_personnel_order o on pl.order_id=o.id where pdt.NAME like N'%روز کارکرد%'  and
133553664000000000 <=pl.DATE_FROM and 133843104000000000>=pl.DATE_TO and o.personnel_id=2616  and pl.id=464824]]
local temp=queryResultt(tt,{})
teamyar.write_log(json.encode(temp))
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
function unitAcl(data)
  --  local geted_org_id = data.org_id;
  local query_param = [[select u.id,u.name from org_units u  where 1=1 ]]-- organizatin_id=]]..geted_org_id
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  and  u.name like N'%]]..data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end
----------------------
function salaryGroupAcl(data)
  local query_param = [[ select id,name from hr_salary_groups where 1=1 ]] ---[[org_id=
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  and  name like N'%]]..data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
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
  local unit = data.data.unit_id
  if unit == nil then
    unit=0
  end 
  local query_param = [[ select distinct  h.PERSONNEL_ID,concat('#',h.PERSONNEL_ID,'_',p.fullname)n from hr_personnels h
                                      inner join profile_main p on p.id=h.PROFILE_ID inner join hr_personnel_order o on o.PERSONNEL_ID=h.PERSONNEL_ID 
                                      where  ]]..currentdate..[[ between DATE_FROM and DATE_TO  ]]
  if unit ~= nil and unit > 0 then
    query_param = query_param..[[  and   (select UNIT_ID from org_organization_unit WHERE ID=o.UNIT_ID)= ]].. unit
  end 
  if data.data.search ~= nil and #data.data.search > 0 then
    query_param = query_param..[[  and p.fullname  like N'%]]..data.data.search..[[%'  or h.PERSONNEL_ID like N'%]]..data.data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.data.from, data.data.count);   
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
local type = getInput("type");
if type ~= nil and type == 100 then
  local result = report()
  teamyar.write_result(json.encode(result));
elseif type ~= nil and type == 7 then
  orgAcl(teamyar.get_input().data)
elseif type ~= nil and type == 9 then
  salaryGroupAcl(teamyar.get_input().data)
elseif type ~= nil and type == 10 then
  unitAcl(teamyar.get_input().data)
elseif type ~= nil and type == 8 then
  getAclPersonnel(teamyar.get_input())
elseif type ~= nil and type == 1 then
  getAclPosition(teamyar.get_input())
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




