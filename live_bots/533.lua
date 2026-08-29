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
local currentdate2 = string.format("%18.0f" ,currentdate_time);
------------------------------
local config = teamyar.get_config()
local c_data={}

local c_wf_id=0
local c_f_p_crm = ""
local c_f_p = ""
local c_f_branch = ""
local c_f_city = ""
local c_fp1 = ""
local c_fp2 = ""
local c_fp3 = ""
local c_fp4 = ""
local c_fp5 = ""
local c_fp6 = ""
local c_fp7 = ""
local c_fp8 = ""
local c_fp9 = ""
local c_fp10 = ""
local c_ft1 = ""
local c_ft2 = ""
local c_ft3 = ""
local c_ft4 = ""
local c_ft5 = ""
local c_ft6 = ""
local c_ft7 = ""
local c_ft8 = ""
local c_ft9 = ""
local c_ft10 = ""
local c_step_id = ""
if config ~= nil then
  c_data = config.data
  c_wf_id = c_data.wf_id
  c_f_p_crm = c_data.f_p_crm
  c_f_p = c_data.f_p
  c_f_branch = c_data.f_branch
  c_f_city = c_data.f_city
  c_fp1 = c_data.fp1
  c_fp2 = c_data.fp2
  c_fp3 = c_data.fp3
  c_fp4 = c_data.fp4
  c_fp5 = c_data.fp5
  c_fp6 = c_data.fp6
  c_fp7 = c_data.fp7  
  c_fp8 = c_data.fp8
  c_fp9 = c_data.fp9
  c_fp10 = c_data.fp10
  c_ft1 = c_data.ft1

  c_ft2 = c_data.ft2
  c_ft3 = c_data.ft3
  c_ft4 = c_data.ft4
  c_ft5 = c_data.ft5
  c_ft6 = c_data.ft6
  c_ft7 = c_data.ft7
  c_ft8 = c_data.ft8
  c_ft9 = c_data.ft9
  c_ft10 = c_data.ft10
  c_step_id= c_data.step_id


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
  local  fcount= getInput("fcount");
  local  tcount= getInput("tcount");
  local branch = getInput("branch");
  local city = getInput("city");
  local tstatus = getInput("tstatus");
  local active_step= getInput("active_step")
  local qs = getQuery_select(queryType)
  ---- invoice Filter
  local where_str=" 1=1 "
  dataQuery.query , dataQuery.params  = queryTools.where:init({where_str})
  --:addIn("sid", sid)

  .run( dataQuery.query ,  dataQuery.params , "{{whereInvoice}}");
  ---- page Number Query
  dataQuery.query = string.gsub(dataQuery.query,"{{slicePageNumber}}", getQuery_page(queryType , pageFrom , perPage , pageTo));
  dataQuery.query = string.gsub(dataQuery.query,"{{select}}",qs);
  local where_task=""
  local where_product =""
  local where_count = ""
  local where_city = ""
  local where_branch = ""
  local where_status = ""
  local where_active_step = ""
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
  if active_step[1] ~= nil and active_step[1].id~= nil then
    where_active_step=where_active_step..[[ and (select tts.step_id from todo_task_steps tts where tts.task_id=t.id and tts.FLAG_LAST_STEP=1)= ]]..active_step[1].id
  end 
  local where_crm = ""
  if crm[1] ~= nil and crm[1].id~= nil then
    where_crm= where_crm..[[ and ( select group_concat(DST_LINK_ID) from todo_ty_links where SRC_LINK_ID=t.id and DST_MODULE_ID=14) like '%%]]..math.floor( crm[1].id)..[[%%' ]]
  end
  if branch[1] ~= nil and branch[1].id~= nil then
    where_branch= where_branch..[[ and ( select bt.bid from branch_todo  bt where bt.tid=t.id)=]]..branch[1].id
  end 
  if city[1] ~= nil and city[1].id~= nil then
    where_city = where_city..[[ and ( select ct.cid from city_todo ct where ct.tid=t.id)=]]..city[1].id
  end
  if tstatus[1] ~= nil and tstatus[1].id~= nil then
    where_status = where_status..[[ and t.state=]]..tstatus[1].id
  end
  if product[1] ~= nil and product[1].id~= nil then
    where_product= where_product..[[ and    (
    ]]..product[1].id..[[ =  (select pid from p1 where tid=ts.id) or 
    ]]..product[1].id..[[ = (select pid from p2 where tid=ts.id)  or 
    ]]..product[1].id..[[ = (select pid from p3 where tid=ts.id)  or 
    ]]..product[1].id..[[ = (select pid from p4 where tid=ts.id)  or 
    ]]..product[1].id..[[ = (select pid from p5 where tid=ts.id)  or 
    ]]..product[1].id..[[ = (select pid from p6 where tid=ts.id)  or 
    ]]..product[1].id..[[ = (select pid from p7 where tid=ts.id)  or 
    ]]..product[1].id..[[ = (select pid from p8 where tid=ts.id)  or 
    ]]..product[1].id..[[ = (select pid from p9 where tid=ts.id)  or 
    ]]..product[1].id..[[ = (select pid from p10 where tid=ts.id) 
  )
    ]]
  end
  if fcount~= nil and tcount~= nil then
    if tonumber(fcount)~= nil and tonumber(tcount) ~= nil then
      where_count = where_count..[[ and  (
      (select c from p1 where tid=ts.id) between {{fcount}} and {{tcount}} or
      (select c from p2 where tid=ts.id) between {{fcount}} and {{tcount}} or
      (select c from p3 where tid=ts.id) between {{fcount}} and {{tcount}} or
      (select c from p4 where tid=ts.id) between {{fcount}} and {{tcount}} or
      (select c from p5 where tid=ts.id) between {{fcount}} and {{tcount}} or
      (select c from p6 where tid=ts.id) between {{fcount}} and {{tcount}} or
      (select c from p7 where tid=ts.id) between {{fcount}} and {{tcount}} or
      (select c from p8 where tid=ts.id) between {{fcount}} and {{tcount}} or
      (select c from p9 where tid=ts.id) between {{fcount}} and {{tcount}} or
      (select c from p10 where tid=ts.id) between {{fcount}} and {{tcount}}
    ) ]]
    end
  end
  dataQuery.query = string.gsub(dataQuery.query, "{{step_id}}", c_step_id);
  dataQuery.query = string.gsub(dataQuery.query, "{{datef}}", datef);
  dataQuery.query = string.gsub(dataQuery.query, "{{datet}}", datet);
  dataQuery.query = string.gsub(dataQuery.query, "{{wf_id}}",c_wf_id);
  dataQuery.query = string.gsub(dataQuery.query, "{{where_product}}",where_product);
  dataQuery.query = string.gsub(dataQuery.query, "{{where_count}}",where_count);
  dataQuery.query = string.gsub(dataQuery.query, "{{fcount}}",fcount);
  dataQuery.query = string.gsub(dataQuery.query, "{{tcount}}",tcount);
  dataQuery.query = string.gsub(dataQuery.query, "{{f_project}}", c_f_p);
  dataQuery.query = string.gsub(dataQuery.query, "{{f_project_crm}}", c_f_p_crm);
  dataQuery.query = string.gsub(dataQuery.query, "{{f_city}}", c_f_city);
  dataQuery.query = string.gsub(dataQuery.query, "{{f_branch}}", c_f_branch);
  dataQuery.query = string.gsub(dataQuery.query, "{{where_branch}}", where_branch);
  dataQuery.query = string.gsub(dataQuery.query, "{{where_city}}", where_city);
  dataQuery.query = string.gsub(dataQuery.query, "{{where_crm}}", where_crm);
  dataQuery.query = string.gsub(dataQuery.query, "{{where_task}}", where_task);
  dataQuery.query = string.gsub(dataQuery.query, "{{where_active_step}}", where_active_step);
  dataQuery.query = string.gsub(dataQuery.query, "{{fp1}}", c_fp1);
  dataQuery.query = string.gsub(dataQuery.query, "{{fp2}}", c_fp2);
  dataQuery.query = string.gsub(dataQuery.query, "{{fp3}}", c_fp3);
  dataQuery.query = string.gsub(dataQuery.query, "{{fp4}}", c_fp4);
  dataQuery.query = string.gsub(dataQuery.query, "{{fp5}}", c_fp5);
  dataQuery.query = string.gsub(dataQuery.query, "{{fp6}}", c_fp6);
  dataQuery.query = string.gsub(dataQuery.query, "{{fp7}}", c_fp7);
  dataQuery.query = string.gsub(dataQuery.query, "{{fp8}}", c_fp8);
  dataQuery.query = string.gsub(dataQuery.query, "{{fp9}}", c_fp9);
  dataQuery.query = string.gsub(dataQuery.query, "{{fp10}}", c_fp10);

  dataQuery.query = string.gsub(dataQuery.query, "{{ft1}}", c_ft1);
  dataQuery.query = string.gsub(dataQuery.query, "{{ft2}}", c_ft2);
  dataQuery.query = string.gsub(dataQuery.query, "{{ft3}}", c_ft3);
  dataQuery.query = string.gsub(dataQuery.query, "{{ft4}}", c_ft4);
  dataQuery.query = string.gsub(dataQuery.query, "{{ft5}}", c_ft5);
  dataQuery.query = string.gsub(dataQuery.query, "{{ft6}}", c_ft6);
  dataQuery.query = string.gsub(dataQuery.query, "{{ft7}}", c_ft7);
  dataQuery.query = string.gsub(dataQuery.query, "{{ft8}}", c_ft8);
  dataQuery.query = string.gsub(dataQuery.query, "{{ft9}}", c_ft9);
  dataQuery.query = string.gsub(dataQuery.query, "{{ft10}}", c_ft10);
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
    {show= true ,   key = "T_START_DATE"                  	, value = "T_START_DATE", type="date" } ,
    {show= true ,   key = "parent_task"                  	, value = "parent_task" } ,
    {show= true ,   key = "task_title"                  	, value = "task_title" } ,
    {show= true ,   key = "d"                  	, value = "d" , type="date"} ,
    {show= true ,   key = "active_step"                  	, value = "active_step" } ,
    {show= true ,   key = "crm"                  	, value = "crm" } ,
    {show= true ,   key = "crm_name"                  	, value = "crm_name" } ,
    {show= true ,   key = "branch"                  	, value = "branch" } ,
    {show= true ,   key = "project"                  	, value = "project" } ,
    {show= true ,   key = "tstate"                  	, value = "tstate" } ,
    {show= true ,   key = "city"                  	, value = "city" } ,
    {show= true ,   key = "t1"                  	, value = "t1" } ,
    {show= true ,   key = "t2"                  	, value = "t2" } ,
    {show= true ,   key = "t3"                  	, value = "t3" } ,
    {show= true ,   key = "t4"                  	, value = "t4" } ,
    {show= true ,   key = "t5"                  	, value = "t5" } ,
    {show= true ,   key = "t6"                  	, value = "t6" } ,
    {show= true ,   key = "t7"                  	, value = "t7" } ,
    {show= true ,   key = "t8"                  	, value = "t8" } ,
    {show= true ,   key = "t9"                  	, value = "t9" } ,
    {show= true ,   key = "t10"                  	, value = "t10" } ,
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
function stepAcl(data)
  local query_param = [[ select id,concat('#',id,'_',STEP_NAME) name from todo_step where WF_ID=  ]]..c_wf_id
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  and ( STEP_NAME like N'%]]..data.search..[[%' or id  like N'%]]..data.search..[[%')  ]]
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
    {id = 0, name = "پیش نویس"},
    {id = 1, name = "بررسی"},
    {id = 2, name = "اجرا"},
    {id = 3, name = "کامل"},


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
  productAcl(teamyar.get_input().data)
elseif type ~= nil and type == 9 then
  statusAcl(teamyar.get_input().data)

elseif type ~= nil and type == 8 then
  taskAcl(teamyar.get_input().data)

elseif type ~= nil and type == 10 then
  crmAcl(teamyar.get_input().data)
elseif type ~= nil and type == 5 then
  branchAcl(teamyar.get_input().data)
elseif type ~= nil and type == 3 then
  stepAcl(teamyar.get_input().data)
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




