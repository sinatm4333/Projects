-- botName = Aggregate Represantive Workflow
-- creator = zmo
-- date = 12/22/2025
-- version= 1.0
--------------------------------------------
--- CONFIG DATA
--------------------------------------------
local day = time.get_day(time.current());
local month = time.get_month(time.current());
local year = time.get_year(time.current());
local hour = time.get_hour(time.current());
local min = time.get_minute (time.current());
local sec = time.get_second(time.current());
local currentdate_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":]]..hour..[[,"minute":]]..min..[[,"second":]]..sec..[[}]])
local temp_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":0,"minute":0,"second":0}]])
local currentdate = string.format("%18.0f" ,temp_time);
local currentdate2 = string.format("%18.0f" ,currentdate_time+(60*60*3*10000000));
------------------------------
local config = teamyar.get_config()
local c_data={}

local c_wf_id=0
local c_step_id = ""
local c_step_id_factor = 0
local c_step_back_factor_id = 0
local c_step_predict_id = 0
local c_fpay=""
local c_fpredict =""
if config ~= nil then
  c_data = config.data
  c_wf_id = c_data.wf_id
  c_fpay = c_data.fpay
  c_fpredict = c_data.fpredict
  c_step_id = c_data.step_id
  c_step_back_factor_id = c_data.step_back_factor_id
  c_step_id_factor = c_data.step_id_factor
  c_step_predict_id = c_data.c_step_predict_id
end
-----------------------------------------------
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
    query = teamyar.get_attachment("query.txt") ,
    params = {}
  };
  ---- Select

  local user_info = teamyar.get_user_info()
  local time_zone = user_info.timezone
  local product = getInput("product");
  local tid = getInput("tid");
  local crm = getInput("crm");
  local  datet= getInput("datet");
  local datef =getInput("datef");
  local tstatus = getInput("tstatus");
  local datefactor = getInput("datefactor"); 
  local dateBackfactor = getInput("dateBackfactor");
  local datefactort = getInput("datefactort"); 
  local dateBackfactort = getInput("dateBackfactort");
  local fpricef = getInput("fpricef");
  local fpricet = getInput("fpricet");
  local remf = getInput("remf");
  local remt = getInput("remt");
  local pmount = getInput("pmount");
  local qs = getQuery_select(queryType)
  ---- invoice Filter
  local where_str=" 1=1 "
  dataQuery.query , dataQuery.params  = queryTools.where:init({where_str})
  --:addIn("sid", sid)

  .run( dataQuery.query ,  dataQuery.params , "{{whereInvoice}}");
  ---- page Number Query
  dataQuery.query = string.gsub(dataQuery.query,"{{slicePageNumber}}", getQuery_page(queryType , pageFrom , perPage , pageTo));
  dataQuery.query = string.gsub(dataQuery.query,"{{select}}",qs);
  local where_task =""
  local where_status = ""
  local where_dfactor = ""
  local where_dbfactor = ""
  local where_fprice = ""

  local where_rem = ""
  local where_pmount=""
  local where_not_null_vosole = ""
  local ids = "";
  if type(tid) == "number"   then
    ids = tid
  else
    for i, v in ipairs(tid) do
      if v == 0 then
        ids = v;
      end
      if  ids=="" then
        ids = ids..tostring(v.id);
      else
        ids = ids..","..tostring(v.id);
      end

    end
  end
  if ids ~= nil and ids ~= "" then
    where_task = [[ and t.id in (]]..ids..[[) ]]
  end  

    local where_crm = ""
  if type(crm) == "number"   then
     where_crm = where_crm..[[  ( select group_concat(DST_LINK_ID) from todo_ty_links where SRC_LINK_ID=t.id and DST_MODULE_ID=14) like '%%]]..math.floor(crm)..[[%%' ]]
  else
    for i, v in ipairs(crm) do
      if v ~= 0  then
        if where_crm =="" then 
           where_crm= where_crm..[[  ( select group_concat(DST_LINK_ID) from todo_ty_links where SRC_LINK_ID=t.id and DST_MODULE_ID=14) like '%%]]..math.floor(v.id)..[[%%' ]]
        else
        where_crm= where_crm..[[ or ( select group_concat(DST_LINK_ID) from todo_ty_links where SRC_LINK_ID=t.id and DST_MODULE_ID=14) like '%%]]..math.floor(v.id)..[[%%' ]]
        end
      end
    end
  end
if where_crm ~= "" then 
    where_crm= "and ( "..where_crm..") "
  end 
teamyar.write_log("where_crm---"..where_crm)

  if tstatus[1] ~= nil and tstatus[1].id~= nil then
    where_status = where_status..[[ and t.STATUS=]]..tstatus[1].id
  end

  if #json.encode(datefactort) >2 and #json.encode(datefactor)>2 then 
    where_dfactor = where_dfactor..[[ and dd between ]]..datefactor..[[ and ]]..datefactort
  end 
  if #json.encode(dateBackfactort)>2   and #json.encode(dateBackfactor)>2 then 
    where_dbfactor = where_dbfactor..[[ and (select run_date from sales_invoice where step_id=]]..c_step_back_factor_id..[[ and task_id=t.id ) between ]]..dateBackfactor..[[ and ]]..dateBackfactort
  end 

  if  #json.encode(fpricef)>2 and #json.encode(fpricet)>2 then 
    where_fprice = where_fprice..[[ and famount between ]]..fpricef..[[ and ]]..fpricet
  end 
  
   local mids = "";
  if type(pmount) == "number"   then
    mids = [["]]..pmount..[["]]
  else
    for i, v in ipairs(pmount) do
      if v == 0 then
        mids = v;
      end
      if  mids=="" then
        mids = mids..[["]]..tostring(v.id)..[["]];
      else
        mids = mids..",".. [["]]..tostring(v.id)..[["]];
      end

    end
  end
  if mids ~= nil and mids ~= "" then
   -- if pmount[1] ~= nil and pmount[1].id~= nil then
  where_pmount = where_pmount..[[and (JSON_UNQUOTE(JSON_EXTRACT(cfs.FORM_DATA->>'$.DATE', CONCAT('$[', n.n, ']."تاریخ پیش بینی وصول_customform".key')))="]]..pmount[1].id..[[")>0 ]]
    where_not_null_vosole=where_not_null_vosole..[[ and (select count(*) from ivosole where tid=t.id)>0]]
  end

  if  #json.encode(remf)>2 and #json.encode(remt)>2 then 
    where_rem = where_rem..[[ and ( (coalesce(famount,0)-coalesce(spays,0))+coalesce(price_backfactor,0) between ]]..remf..[[ and ]]..remt..[[)]]
  end 
 
  dataQuery.query = string.gsub(dataQuery.query, "{{fpredict}}", c_fpredict);
  dataQuery.query = string.gsub(dataQuery.query, "{{fpay}}", c_fpay);
  dataQuery.query = string.gsub(dataQuery.query, "{{step_factor_id}}", c_step_id_factor);  
  dataQuery.query = string.gsub(dataQuery.query, "{{step_back_factor_id}}", c_step_back_factor_id);
  dataQuery.query = string.gsub(dataQuery.query, "{{datef}}", datef);
  dataQuery.query = string.gsub(dataQuery.query, "{{datet}}", datet);
  dataQuery.query = string.gsub(dataQuery.query, "{{wf_id}}",c_wf_id);
  dataQuery.query = string.gsub(dataQuery.query, "{{current_date}}",currentdate2);
  dataQuery.query = string.gsub(dataQuery.query, "{{where_status}}",where_status);
  dataQuery.query = string.gsub(dataQuery.query, "{{where_crm}}", where_crm);
  dataQuery.query = string.gsub(dataQuery.query, "{{where_task}}", where_task);
  dataQuery.query = string.gsub(dataQuery.query, "{{where_dfactor}}", where_dfactor);
  dataQuery.query = string.gsub(dataQuery.query, "{{where_dbfactor}}", where_dbfactor);
  dataQuery.query = string.gsub(dataQuery.query, "{{where_fprice}}", where_fprice);
  dataQuery.query = string.gsub(dataQuery.query, "{{where_rem}}", where_rem);
  dataQuery.query = string.gsub(dataQuery.query, "{{where_pmount}}", where_pmount);
    dataQuery.query = string.gsub(dataQuery.query, "{{where_not_null_vosole}}", where_not_null_vosole);

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
    {show= true ,   key = "tlink"                  	, value = "tlink"} ,
    {show= true ,   key = "tstate"                  	, value = "tstate" } ,
    {show= true ,   key = "fact_id"                  	, value = "fact_id" } ,

    {show= true ,   key = "dd"                  	, value = "dd" , type="date"} ,
    {show= true ,   key = "back_fact_id"                  	, value = "back_fact_id" } ,
    {show= true ,   key = "crm"                  	, value = "crm" } ,
    {show= true ,   key = "crm_name"                  	, value = "crm_name" } ,
    {show= true ,   key = "dpredict"                  	, value = "dpredict" } ,
    {show= true ,   key = "vosole_items"                  	, value = "vosole_items" } ,
       {show= true ,   key = "sum_vosol"                  	, value = "sum_vosol",type="price", sum=true  } ,
    {show= true ,   key = "famount"                  	, value = "famount",type="price", sum=true } ,
    {show= true ,   key = "pays"                  	, value = "pays" } ,
    {show= true ,   key = "spays"                  	, value = "spays",type="price", sum=true} ,
    {show= true ,   key = "(coalesce(famount,0)-coalesce(spays,0))+coalesce(price_backfactor,0)"                  	, value = "rem",type="price" , sum=true} ,
    {show= true ,   key = "midpays"                  	, value = "midpays",type="price" , sum=true} ,
    {show= true ,   key = "sname"                  	, value = "sname" } ,
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
function productAcl(data)
  local query_param = [[ select id,concat('#',id,'_',name) name from wh_product where voucher_allow=1  ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  and ( name like N'%]]..data.search..[[%' or id  like N'%]]..data.search..[[%')  ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end

-----------------------------------------------------------------------
function taskAcl(data)
  local query_param = [[ select id,concat('#',id,'_',task_title)name  from todo_task where WORK_FLOW_ID= ]]..c_wf_id
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  and ( task_title like N'%]]..data.search..[[%'  or  id like N'%]]..data.search..[[%' )]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end
-----------------------------------------------------------------------
function statusAcl(data)
  local table = {
    {id = 1, name = "باز"},
    {id = 2, name = "بسته"},
   --  {id = 1, name = "معلق"},
  }
  teamyar.write_result(json.encode(table));
end
-----------------------------------------------------------------------
function mountAcl(data)
  local table = {
    {id = "DATE1",  name = "فروردین"},
    {id = "DATE2",  name = "اردیبهشت"},
    {id = "DATE3",  name = "خرداد"},
    {id = "DATE4",  name = "تیر"},
    {id = "DATE5",  name = "مرداد"},
    {id = "DATE6",  name = "شهریور"},
    {id = "DATE7",  name = "مهر"},
    {id = "DATE8",  name = "آبان"},
    {id = "DATE9",  name = "آذر"},
    {id = "DATE10", name = "دی"},
    {id = "DATE11", name = "بهمن"},
    {id = "DATE12", name = "اسفند"},
  }
  teamyar.write_result(json.encode(table));
end

-----------------------------------------------------------------------
function crmAcl(data)
  local query_param = [[ select c.id,concat('#',p.id,'_',p.FULLNAME)name from crm_info c inner join profile_main p on p.id=c.id ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  where ( p.FULLNAME like N'%]]..data.search..[[%'  or  p.id like N'%]]..data.search..[[%' )]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);

  teamyar.write_log(query_param)
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end
-----------------------------------------------------------------------
function branchAcl(data)
  local query_param = [[ 
  select distinct  JSON_UNQUOTE(json_extract(cast(cfs.FORM_DATA->>'$.]]..c_f_branch..[[' as json),'$[0].id')),
  JSON_UNQUOTE(json_extract(cast(cfs.FORM_DATA->>'$.]]..c_f_branch..[[' as json),'$[0].name')) p 
  from todo_custom_form cfs  inner join todo_task t on t.id=cfs.id  where  cfs.type=5 and  t.WORK_FLOW_ID=]]..c_wf_id..[[
  and LENGTH(IFNULL(cfs.FORM_DATA->'$.]]..c_f_branch..[[','')) > 2 ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  and ( JSON_UNQUOTE(json_extract(cast(cfs.FORM_DATA->>'$.]]..c_f_branch..[[' as json),'$[0].name'))  like N'%]]..data.search..[[%'  
    or  JSON_UNQUOTE(json_extract(cast(cfs.FORM_DATA->>'$.]]..c_f_branch..[[' as json),'$[0].id'))  like N'%]]..data.search..[[%' ) ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);
  teamyar.write_log(query_param)
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end
-----------------------------------------------------------------------
function cityAcl(data)
  local query_param = [[ 
  select distinct JSON_UNQUOTE(json_extract(cast(cfs.FORM_DATA->>'$.]]..c_f_city..[[' as json),'$[0].id')),
  JSON_UNQUOTE(json_extract(cast(cfs.FORM_DATA->>'$.]]..c_f_city..[[' as json),'$[0].name')) p 
  from todo_custom_form cfs inner join todo_task t on t.id=cfs.id where  cfs.type=5 and  t.WORK_FLOW_ID=]]..c_wf_id..[[
  and LENGTH(IFNULL(cfs.FORM_DATA->'$.]]..c_f_city..[[','')) > 10 ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  and ( JSON_UNQUOTE(json_extract(cast(cfs.FORM_DATA->>'$.]]..c_f_city..[[' as json),'$[0].name'))  like N'%]]..data.search..[[%'  
    or  JSON_UNQUOTE(json_extract(cast(cfs.FORM_DATA->>'$.]]..c_f_city..[[' as json),'$[0].id'))  like N'%]]..data.search..[[%' ) ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);
  teamyar.write_log(query_param)
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
  productAcl(teamyar.get_input().data)
elseif type ~= nil and type == 9 then
  statusAcl(teamyar.get_input().data)

elseif type ~= nil and type == 10 then
  taskAcl(teamyar.get_input().data)
elseif type ~= nil and type == 11 then
  mountAcl(teamyar.get_input().data)

elseif type ~= nil and type == 8 then
  crmAcl(teamyar.get_input().data)
elseif type ~= nil and type == 5 then
  branchAcl(teamyar.get_input().data)
elseif type ~= nil and type == 6 then
  cityAcl(teamyar.get_input().data)
elseif type ~= nil and type == 20 then
  local curdate={curdate=currentdate2}
  teamyar.write_result(json.encode(curdate));
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




