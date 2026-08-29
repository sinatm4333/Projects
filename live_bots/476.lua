-- botName = ComprehensiveAttendanceReport
-- creator = Mozhgan Rajabali
-- date = 15/07/1404
-- version= 1.0

--------------------------------------------
--- CONFIG DATA
--------------------------------------------
local _PAR_PAGE= 25
local _QUERY_TYPE = {
  _TYPE_TOTAL_SUM = 1 ,
  _TYPE_TOTAL_COUNT = 2 ,
  _TYPE_PAGE_REPORT = 3 ,
  _TYPE_PAGE_EXCEL = 4 ,
  _TYPE_PAGE_PRINT = 5 ,
}

--------------------------------------------
--- install [RES]
--------------------------------------------

  local day = time.get_day(time.current());
local month = time.get_month(time.current());
local year = time.get_year(time.current());
local hour = time.get_hour(time.current());
local min = time.get_minute (time.current());
local sec = time.get_second(time.current());
local currentdate_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":]]..hour..[[,"minute":]]..min..[[,"second":]]..sec..[[}]])   
local temp_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":]].. 00 ..[[,"minute":]].. 00 ..[[,"second":]].. 00 ..[[}]]);
currentdate = string.format("%18.0f" ,temp_time);
  
 teamyar.write_log("زمان جاری" .. currentdate)

-- -------------------------------------------------------
input = teamyar.get_input();
local _BAT_RES_PATH ="2/res_v2";
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
--- data
--------------------------------------------
function getData(queryType , pageFrom , perPage , pageTo )
  ---- init Query
  local dataQuery = {
    query = teamyar.get_attachment("query_comprehensive_attendance.txt") ,
    params = {}
  };

  ---- Select
  dataQuery.query = string.gsub(dataQuery.query,"{{select}}", getQuery_select(queryType));

  ---- invoice Filter
  local wherestr = "1 = 1";
  local wherestrres = "1 = 1";
  local org = getInput("org_id");
  local unit = getInput("unit");
  local salary_group = getInput("salary_group");
  local  calendar = getInput("calendar");
  local from_date = getInput("from_date");
  local to_date = getInput("to_date");
  teamyar.write_log("از تاریخ" .. json.encode(from_date))
  -- if (org ~= nil and org[1] ~= nil and org[1]["id"] ~= nil) then
  -- where
  wherestr = wherestr .. " and hpo.IS_DELAYED = 0 and hp.HIRING_STATUS = 2 and hot.HIRING_TIME in(1,2) and  hpo.DATE_FROM <= ".. from_date .. " and hpo.DATE_TO >= ".. to_date
  dataQuery.query , dataQuery.params  = queryTools.where:init({wherestr})
  :addIn("oi.ID" , org)
  :addIn("ou.ID" , unit)
  :addIn("hpo.SALARY_GROUP_ID" ,salary_group )
  :addIn("hc.ID" ,calendar )
  -- :add("DATE_VACATOIN" , ">=" , from_date)
  --  :add("DATE_VACATOIN" , "<=" , to_date)
  .run( dataQuery.query ,  dataQuery.params , "{{where_condition}}");
    
     
wherestrres = wherestrres ..  " and hp.HIRING_STATUS = 2 and  hwt.WORK_DATE = (" .. from_date .. " + 126000000000 + 36000000000) - MOD((" .. from_date .. " + 126000000000 + 36000000000) , 864000000000)"
  dataQuery.query , dataQuery.params  = queryTools.where:init({wherestrres})
   :addIn("hp.ORG_ID" , org)
  .run( dataQuery.query ,  dataQuery.params , "{{where_time}}");
  
 dataQuery.query = string.gsub(dataQuery.query,"{{start_day}}",from_date);                
   dataQuery.query = string.gsub(dataQuery.query,"{{datecurrent}}",currentdate);  
  --  end
  ---- page Number Query
  dataQuery.query = string.gsub(dataQuery.query,"{{slicePageNumber}}", getQuery_page(queryType , pageFrom , perPage , pageTo));
  teamyar.write_log("4444444" .. dataQuery.query)
  ---- Execute Query
  return getQuery_result(queryType , dataQuery);
end

function getQuery_select(queryType)
  if queryType == _QUERY_TYPE._TYPE_TOTAL_SUM then
    return getTableConfig_sum()
  elseif queryType == _QUERY_TYPE._TYPE_TOTAL_COUNT then
    return getTableConfig_count()
  else
    return getTableConfig_select();
  end
end
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
function getQuery_result(queryType , dataQuery)
  local resultExp = nil;

  db.query(dataQuery)
  local record={};
  if queryType == _QUERY_TYPE._TYPE_TOTAL_COUNT then
    record = db.query_fetch();
    resultExp = record[1];
    teamyar.write_log(json.encode(resultExp))

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



function getTableConfig()
  return {
    {show= true ,    key = "ORG_NAME"                   , value= "ORG_NAME" } ,
    {show= true ,    key = "UNIT_NAME"                   , value= "UNIT_NAME"} ,
    {show= true ,    key = "CALENDAR_NAME"                         , value= "CALENDAR_NAME" } ,
    {show= true ,    key = "WORK_DATE"                   , value= "WORK_DATE" , type= "date"} ,
    {show= true ,   key = "True_FirstIn"                       , value= "True_FirstIn" , type= "time"} ,
    {show= true ,   key = "True_LastOut"                   , value= "True_LastOut"  , type= "time"} ,
    {show= true ,   key = "FULLNAME"                       , value= "FULLNAME" } ,
    {show= true ,   key = "dar_shift"                           , value= "dar_shift" } ,
    {show= true ,   key = "NotForce"                   , value= "NotForce"} ,
    {show= true ,   key = "present"                   , value= "present"} ,
    {show= true ,   key = "leavee_confirm"                   , value= "leavee_confirm"} ,
    {show= true ,   key = "leavee_not_confirm"                   , value= "leavee_not_confirm"} ,
    {show= false ,   key = "absent"                   , value= "absent"} ,
    {show= true ,   key = "mission_confirm"                   , value= "mission_confirm"} ,
    {show= true ,   key = "mission_not_confirm"                   , value= "mission_not_confirm"} ,
    {show= true ,   key = "Before8"                   , value= "Before8"} ,
    {show= true ,   key = "TopOf8"                   , value= "TopOf8"} ,
    {show= true ,   key = "After8"                   , value= "After8"} ,

  };
end
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
function getTableConfig_count()
  return "count(*)";
end
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


--------------------------------------------
--- Report
--------------------------------------------
function report()
  local report = {
    {
      name = "table" ,
      title = "جدول" ,
      report = getTableSectionOne()
    }
  }

  return report;
end
function getTableSectionOne()
  local repId = getInput("rep_id");
  local headers = getTableConfig_header();

  local from = getInput("page");
  local values  = getData(_QUERY_TYPE._TYPE_PAGE_REPORT , from , _PAR_PAGE);
  local total  = getData(_QUERY_TYPE._TYPE_TOTAL_COUNT)

  return install_res.resTable(repId , headers , values  , total , _PAR_PAGE , from );
end


--------------------------------------------
--- excel
--------------------------------------------
function excel()
  local excelFileName = getInput("excel_file_name");
  local excelFormPage = getInput("excel_from_page");
  local excelToPage = getInput("excel_to_page");
  local excelPerPage= getInput("excel_per_page");

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
------------------------------------------------------------------------
function queryEmployeeAcl(select_query,user_param)
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
------------------------------------------------------------------------
function employeeAcl(data)
  local query_param = [[ select hp.PERSONNEL_ID,(concat(pui.Name , ' ' , pui.SurName)) FullName from
  hr_personnels  hp    join     profile_user_info   pui   on hp.PROFILE_ID = pui.ID
  where hp.HIRING_STATUS IN(2,4) ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  and concat(pui.Name , ' ' , pui.SurName)  like N'%]]..data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(json.encode(queryEmployeeAcl(query_param, {})));
end
-----------------------------------------------------------------------

--- manager
--------------------------------------------
local type = getInput("type");
-- if type ~= nil and type == 5 then
--   employeeAcl(input.data)

--- get report
if type ~= nil and type == 100 then
  local result = report()
  teamyar.write_result(json.encode(result));

  --- get excel
elseif type ~= nil and type == 101 then
  local result = excel()
  teamyar.write_result(json.encode(result));

  --- get print
elseif type ~= nil and type == 102 then
  local result = print()
  teamyar.write_result(json.encode(result));

else
  local responseResReport = install_res.resReport(getTableConfig());
  teamyar.write_result(responseResReport);

end
