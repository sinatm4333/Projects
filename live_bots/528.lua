-- botName = Average system deployment time report
-- creator = Mozhgan Rajabali
-- date = 28/07/1404
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
--install_res.resCash();
--------------------------------------------
--- data
--------------------------------------------
function getData(queryType , pageFrom , perPage , pageTo )
  ---- init Query
  local dataQuery = {
    query = teamyar.get_attachment("query_bug_table.txt") ,
    params = {}
  };

  ---- Select
  dataQuery.query = string.gsub(dataQuery.query,"{{select}}", getQuery_select(queryType));

  ---- invoice Filter
  local from_date = getInput("from_date") ;
  local to_date = getInput("to_date") ;


    --  teamyar.write_log(wherestr)
    -- where_condition
    dataQuery.query , dataQuery.params  = queryTools.where:init({"t.WORK_FLOW_ID = 496"})
     :add("t.T_START_DATE" , ">=" , from_date)
     :add("t.T_START_DATE" , "<=" , to_date)

    .run( dataQuery.query ,  dataQuery.params , "{{where_condition}}");

  

  ---- page Number Query
  dataQuery.query = string.gsub(dataQuery.query,"{{slicePageNumber}}", getQuery_page(queryType , pageFrom , perPage , pageTo));
  --  teamyar.write_log("9ppppppppa ==="..json.encode( dataQuery.params))
  ---- Execute Query
  teamyar.write_log("9******** ===" .. dataQuery.query)
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
    -- teamyar.write_log("nnnnn=".. queryType)
    local limit = tonumber(perPage);
    local offset = tonumber(pageFrom) ;
    slicePageNumber = "LIMIT "..limit .. " OFFSET "..offset;
    --teamyar.write_log("rrrr=".. slicePageNumber)
  elseif queryType == _QUERY_TYPE._TYPE_PAGE_EXCEL then
    local limit = tonumber(perPage)*(tonumber(pageTo)  - tonumber(pageFrom) + 1) ;
    local offset = tonumber(perPage) *(tonumber(pageFrom) - 1);
    slicePageNumber = "LIMIT "..limit.." OFFSET "..offset;
    --  teamyar.write_log("slicePageNumber=".. slicePageNumber)
  end

  return slicePageNumber;
end
function getQuery_result(queryType , dataQuery)
  local resultExp = nil;
  db.query(dataQuery)
  -- teamyar.write_log("99999999 ===" .. dataQuery.query)
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

function getTableConfig()
  return {
    {show= true ,    key = "count_all"                   , value= "count_all" } ,
    {show= true ,    key = "bug_count"                     , value= "count_bug"  } ,
    {show= true ,    key = "percentage"                     , value= "percentage"} ,     
    {show= false ,    key = "WORK_FLOW_ID"                     , value= "WORK_FLOW_ID"} ,        
    --  {show= true ,    key = "TASK_TITLE"                     , value= "TASK_TITLE"} ,     
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
    select = select .."sum( "..itemColumnsSelected..")"
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
----------------------------------------------------------------
function queryResultChart(select_query,user_param)
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
    -- teamyar.write_log(json.encode(record))
    table.insert(res_text, {Year=record[1],average_difference=record[2],months=record[3],days=record[4]
      });
  end
  db.query_free();
  return res_text;
end
--------------------------------------------
--- Report
--------------------------------------------
function report()
  local wherestrchartres = "where  c.AUTHOR_ID != ts.responsible_id AND c.DATE_CREATE > ts.DATE_CREATE ";
  local from_date_chart = getInput("from_date") ;
  local to_date_chart = getInput("to_date") ;

  if from_date_chart ~= nil  and from_date_chart ~= ""  and  to_date_chart ~= nil  and to_date_chart ~= ""   then 
   -- wherestrchart = wherestrchart ..[[ and run_date  between  ]] ..from_date_chart..[[ and ]]..to_date_chart.. [[ ]]
    wherestrchartres = wherestrchartres ..[[ and ts.DATE_CREATE  between  ]] ..from_date_chart..[[ and ]]..to_date_chart.. [[ ]]
    
  end

  -- chart query :
      local resultQuery = teamyar.get_attachment("query_bug_chart.txt");   
--  resultQuery = string.gsub(resultQuery,"{{where_condition}}",wherestrchartres)

    teamyar.write_log("کوئری چارت == " ..(resultQuery))
  local rep_data_chart = queryResultChart(resultQuery,{page});


  local report = {
 --   {
    --  name = "table" ,
 --     title = "جدول" ,
 --     report = getTableSectionOne()
 --   },
    {
      name = "chart" ,
      title = "نمودار باگ ها به تفکیک فصل" ,
      report = {total=100 ,data=rep_data_chart,page=page}
    },
 
  }

  return report;
end

function getTableSectionOne()
  local repId = getInput("rep_id");
  local headers = getTableConfig_header();

  local from = getInput("page");
  --  teamyar.write_log("***_PAR_PAGE** ===" .. _PAR_PAGE)
  local values  = getData(_QUERY_TYPE._TYPE_PAGE_REPORT , from , _PAR_PAGE);
  local total  = getData(_QUERY_TYPE._TYPE_TOTAL_COUNT)
 -- local sums  = getData(_QUERY_TYPE._TYPE_TOTAL_SUM , from , _PAR_PAGE);
  -- teamyar.write_log(json.encode(sums))
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
--------------------------------------------
--- manager
--------------------------------------------
local type = getInput("type");
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
