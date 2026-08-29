-- botName = call log history
-- creator =zmo
-- date = 12/15/2024
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

--install_res.resCash();

--------------------------------------------
--- data
--------------------------------------------

-----------------------------------------------------
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
  dataQuery.query = string.gsub(dataQuery.query,"{{current_date}}", currentdate);
  dataQuery.query = string.gsub(dataQuery.query,"{{select}}", getQuery_select(queryType));
  ---- invoice Filter
  local toDate_s = getInput("to_date_s");
  local unit = getInput("order_group");
  local orgId = getInput("org_id");
  local personnel = getInput("personnel");
  local where_str=" 1=1 "
  if  unit ~= nil  and #unit>0 then 
    where_str = where_str..[[ and (]]
    for i, v in ipairs(unit) do
      if v.id~= nil then      
        where_str = where_str..[[  ]]..v.id..[[ in   (select o.SALARY_GROUP_ID from hr_personnel_order o where personnel_id =p_id)  or ]]
      end
    end
    where_str = where_str..[[  1=2 )  ]]
  end 
  dataQuery.query , dataQuery.params  = queryTools.where:init({where_str})
  :add("org_id", orgId)
  :addIn("p_id" , personnel)
  .run( dataQuery.query ,  dataQuery.params , "{{whereInvoice}}");
  ---- page Number Query
  dataQuery.query = string.gsub(dataQuery.query,"{{slicePageNumber}}", getQuery_page(queryType , pageFrom , perPage , pageTo));
  ---- Execute Query
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
  return {
    {show= false ,   key = "p_id"                   					   , value = "p_id"} ,
    {show= true ,   key = "name"                  						 , value = "name" } ,
    {show= true ,   key = "SALARY_GROUP_NAME"              , value = "SALARY_GROUP_NAME" } ,
    {show= true ,   key = "balance_d"                  				   , value = "balance_d" } ,
    {show= true ,   key = "balance_h"                  				   , value = "balance_h" } ,
    {show= true ,   key = "balance_m"                  				  , value = "balance_m" } ,
    {show= true ,   key = "balance_d_h_m"                  		   , value = "balance_d_h_m" } ,
    {show= true ,   key = "balance_h_m"                  			 , value = "balance_h_m" } ,
    {show= false ,   key = "SALARY_GROUP_ID"                   , value = "SALARY_GROUP_ID" } ,
    {show= false ,   key = "org_id"                  					   , value = "org_id" } ,
  };
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
--------------------------------------------

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
  local currentdate = string.format("%18.0f" ,temp_time);
  local query_param = [[ select distinct  h.PERSONNEL_ID,concat('#',h.PERSONNEL_ID,'_',p.fullname)n from hr_personnels h
                          inner join profile_main p on p.id=h.PROFILE_ID inner join hr_personnel_order o on o.PERSONNEL_ID=h.PERSONNEL_ID 
                          where  ]]..currentdate..[[ between DATE_FROM and DATE_TO  ]]

  if data.data.search ~= nil and #data.data.search > 0 then
    query_param = query_param..[[  and p.fullname  like N'%]]..data.data.search..[[%'  or h.PERSONNEL_ID like N'%]]..data.data.search..[[%' ]]
  end
  -- teamyar.write_log(query_param)
  query_param = query_param .. string.format(" limit %d,%d ", data.data.from, data.data.count);   
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end
--------------------------------------------
--- Report
--------------------------------------------
function report()
  local data = getTableSectionOne()
  local report = {
    {
      name = "table" ,
      title = "table" ,
      report = data
    }
  }
  return report;
end
--------------------------------
function queryResultval(select_query,user_param)
  db.use_db("0000000");
  local params1 = {
    query = select_query,
    params = user_param
  }
  db.query(params1);
  local res_text = db.query_fetch();
  db.query_free();
  if res_text == nil then 
    return nil
  else
    return res_text[1];
  end
end
--------------------------------------------
function getTableSectionOne()
  local repId = getInput("rep_id");
  local headers = getTableConfig_header();
  local from = getInput("page");
  local datef = getInput("to_date_s");
  local values  = getData(_QUERY_TYPE._TYPE_PAGE_REPORT , from , _PAR_PAGE);
  local total  = getData(_QUERY_TYPE._TYPE_TOTAL_COUNT);
  if datef ~= nil then 
    datef = datef + (60 * 60 * 24 * 10000000)
  end 
  for i, v in ipairs(values) do
    local info = {
      date_to = datef,
      personnel_ids = {
        v.p_id
      }
    }
    local   res = teamyar.call_api(13,  '/api/hr/leaveTransferGet', info);
    local time = tonumber(res.data[1].value)
    local qqq=[[select o.WORKING_HOURS from hr_personnel_order o where id =(select max(id) from hr_personnel_order where personnel_id=o.personnel_id)
                and ]]..currentdate..[[ between DATE_FROM and DATE_TO  
                and PERSONNEL_ID=]].. v.p_id
    local work_hours = queryResultval(qqq,{})
    if work_hours==nil then
      work_hours=0
    end 
    local is_negative=0
    if time<0 then 
      time=time*-1
      is_negative= 1
    end
    if work_hours == nil then 
      work_hours = 528
    else
      work_hours = math.floor(tonumber(work_hours)/60)
    end 
    local day =0
    local  hours =0
    local minutes = 0
    if work_hours>0 then
      day =math.floor( time / (60*work_hours))
      time = (math.fmod(time,60*work_hours))
      hours = (math.floor( time / 3600));
      time = (math.fmod(time,3600))
      minutes = math.floor(  time / 60);
    end
    if is_negative==1 then
      hours=hours*-1
      minutes=minutes*-1
      day=day*-1
    end 
    if #tostring(hours) == 1 then 
      hours = "0"..hours
    end 
    if #tostring(minutes) == 1 then 
      minutes = "0"..minutes
    end 
    v.balance_h = hours
    v.balance_m = minutes
    v.balance_h_m = hours..":"..minutes
    v.balance_d = day
    v.balance_d_h_m = day..":"..hours..":"..minutes
  end   
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
elseif type ~= nil and type == 15 then
  getAclPersonnel(teamyar.get_input())
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




