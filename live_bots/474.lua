-- botName = TotalPersonnelCompensation
-- creator = Mozhgan Rajabali
-- date = 25/01/1403
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
        query = teamyar.get_attachment("query_total_personnel_compensation.txt") ,
        params = {}
    };

    ---- Select
    dataQuery.query = string.gsub(dataQuery.query,"{{select}}", getQuery_select(queryType));

    ---- invoice Filter
    local res =  teamyar.get_user_info();  
    time_zone = json.encode(res["timezone"]);
    user_id = json.encode(res["id"]);
  
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
  
 --  local current_date = time.current();
    local org = getInput("org_id");
    local salary_group = getInput("salary_group");
    local from_date = getInput("from_date");
    local to_date = getInput("to_date");
    local wherestr = " 1=1 "
  
  dataQuery.query = string.gsub(dataQuery.query,"{{Time_Zone}}", time_zone);
  dataQuery.query = string.gsub(dataQuery.query,"{{Time_Current}}", currentdate);
 dataQuery.query = string.gsub(dataQuery.query,"{{User_ID}}", user_id);

    if (org ~= nil and org[1] ~= nil and org[1]["id"] ~= nil) then
    
    -- where_work_time
    dataQuery.query , dataQuery.params  = queryTools.where:init({"TYPE IN(14,23)"})
    .run( dataQuery.query ,  dataQuery.params , "{{where_work_time}}");
  
    -- where_type
    dataQuery.query , dataQuery.params  = queryTools.where:init({"TYPE = 2"})
    .run( dataQuery.query ,  dataQuery.params , "{{where_type}}");
    
    -- where_Binperm
    dataQuery.query , dataQuery.params  = queryTools.where:init({"p.BinPerm = 16"})
    .run( dataQuery.query ,  dataQuery.params , "{{where_Binperm}}");
   
   -- where_order
    dataQuery.query , dataQuery.params  = queryTools.where:init({"hpo.IS_DELAYED = 0 and hpo.CALENDAR_ID > 0"})
    :addIn(" hpo.ORG_ID" , org)
    :add("hpo.DATE_FROM" , "<=" , currentdate)
    :add("hpo.DATE_TO" , ">=" , currentdate)
    .run( dataQuery.query ,  dataQuery.params , "{{where_order}}");
    
    -- where_delay
    dataQuery.query , dataQuery.params  = queryTools.where:init({}) 
    :add("hwt.WORK_DATE" , ">=" , from_date)
    :add("hwt.WORK_DATE" , "<=" , to_date)
    .run( dataQuery.query ,  dataQuery.params , "{{where_delay}}");
    
      -- where_last
     wherestr=wherestr..[[ and  (hpo.DATE_FROM  >=  ]] ..from_date..[[ and  hpo.DATE_FROM <= ]]..to_date .. [[) or (hpo.DATE_TO >= ]].. from_date ..
    [[ and hpo.DATE_TO <=]] ..to_date.. [[) or (hpo.DATE_FROM >= ]]..from_date..[[ and hpo.DATE_TO <=]].. to_date ..[[) or (hpo.DATE_FROM
    <= ]].. from_date .. [[ and hpo.DATE_TO >= ]] ..to_date .. [[ ) ]]
    
    dataQuery.query , dataQuery.params  = queryTools.where:init({})
      :addIn("ORG_ID" , org)
    :add("DATE_FROM" , "<=" , to_date)
    :add("DATE_TO" , ">=" , from_date)
    .run( dataQuery.query ,  dataQuery.params , "{{where_last}}");
    
       -- where_condition 
    dataQuery.query , dataQuery.params  = queryTools.where:init({})
     :addIn("SALARY_GROUP_ID" ,salary_group )
    .run( dataQuery.query ,  dataQuery.params , "{{where_condition}}");
    end
  
    ---- page Number Query
    dataQuery.query = string.gsub(dataQuery.query,"{{slicePageNumber}}", getQuery_page(queryType , pageFrom , perPage , pageTo));
    teamyar.write_log(dataQuery.query)
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
        {show= false ,    key = "PERSONNEL_ID"                   , value= "PERSONNEL_ID" } ,
        {show= true ,    key = "FULLNAME"                   , value= "FULLNAME", type="link"  , link="/?page=/hr/worktimes/worktime_detail/&personnel_id={{PERSONNEL_ID}}&selected=2&wpage=2"          ,params= {"PERSONNEL_ID"} } ,
        {show= true ,    key = "Name"                   , value= "Name" } ,
        {show= true ,    key = "TotalDelayStr2"                         , value= "TotalDelayStr2" } ,
        {show= true ,    key = "TotalDelayStr"                   , value= "TotalDelayStr"} ,
        {show= false ,   key = "SALARY_GROUP_ID"                       , value= "SALARY_GROUP_ID"} ,
        {show= false ,   key = "DayTime"                   , value= "DayTime" } ,
   
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
