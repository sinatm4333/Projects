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
local hour = time.get_hour(time.current());
local min = time.get_minute (time.current());
local sec = time.get_second(time.current());
local currentdate_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":]]..hour..[[,"minute":]]..min..[[,"second":]]..sec..[[}]])
local temp_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":0,"minute":0,"second":0}]])
local currentdate = string.format("%18.0f" ,temp_time);
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
-------------------------------------------
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
  local r_nummber = 0
  local f_nummber = 0
  local m_nummber = 0
  local c_count_out = 0

  if config ~= nil then 
    cdata = config.data

    r_nummber = cdata.rnumber
    f_nummber = cdata.rnumber
    m_nummber = cdata.rnumber

  end
 -- teamyar.write_log(c_box_id.."uuuuu")


  local user_info = teamyar.get_user_info()
  local time_zone = user_info.timezone
  local ctype = getInput("ctype");
  local cat = getInput("cat");
  local crm = getInput("crm");
  local org = getInput("org");
  local center = getInput("center");
  local datef = getInput("datef");
  local datet = getInput("datet");
  local sort_key = getInput("sort_key");
  local sort_dir = getInput("sort_dir");
  local monetary_min = getInput("monetary_min");
  local monetary_max = getInput("monetary_max");
  teamyar.write_log("[RFM] getData queryType="..tostring(queryType).." org="..(org and tostring(org[1] and org[1].id or "nil") or "nil").." center="..(center and tostring(center[1] and center[1].id or "nil") or "nil").." crm="..(crm and tostring(crm[1] and crm[1].id or "nil") or "nil").." datef="..tostring(datef).." datet="..tostring(datet).." sort_key="..tostring(sort_key).." sort_dir="..tostring(sort_dir))
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

  local where_cat = ""
  local where_ctype= ""
  local where_crm= ""
  local where_org = ""
  local where_center = ""
  if cat ~= nil and cat[1] ~= nil then 
    where_cat = where_cat.. [[ and c.id in (select CLIENT_ID from crm_cross where REFERE_ID =]]..cat[1].id..[[ )]]
  end 
  if ctype ~= nil and ctype[1] ~= nil then 
    where_ctype = where_ctype.. [[ and ui.USER_TYPE=]]..ctype[1].id
  end 

  if crm ~= nil and crm[1] ~= nil then 
    where_crm = where_crm.. [[ and ui.USER_TYPE=]]..crm[1].id
  end 
  if org ~= nil and org[1] ~= nil then
    where_org = where_org.. [[ and s.org_id=]]..org[1].id..[[ and p.org_id=]]..org[1].id
  end
  if center ~= nil and center[1] ~= nil then
    where_center = where_center.. [[ and s.SALES_CENTER=]]..center[1].id
    teamyar.write_log("[RFM] center filter applied: SALES_CENTER="..tostring(center[1].id))
  end
  if tonumber(datet) == nil then
    datet=0
  end
  if tonumber(datef) == nil then
    datef=0
  end
  ---- monetary filter
  local where_monetary = ""
  local mmin = tonumber(monetary_min)
  local mmax = tonumber(monetary_max)
  if mmin ~= nil and mmin ~= 0 then
    where_monetary = where_monetary .. [[ and Monetary >= ]]..mmin
  end
  if mmax ~= nil and mmax ~= 0 then
    where_monetary = where_monetary .. [[ and Monetary <= ]]..mmax
  end
  ---- sort defaults — treat nil, "", "null" all as empty
  local sort_col = sort_key
  if sort_col == nil or sort_col == "" or sort_col == "null" then
    sort_col = "rfm"
  end
  local sort_dir_val = sort_dir
  if sort_dir_val == nil or sort_dir_val == "" or sort_dir_val == "null" then
    sort_dir_val = "desc"
  end
  dataQuery.query = string.gsub(dataQuery.query,"{{datet}}",datet);
  dataQuery.query = string.gsub(dataQuery.query,"{{datef}}",datef);
  dataQuery.query = string.gsub(dataQuery.query,"{{current_date}}",currentdate);
  dataQuery.query = string.gsub(dataQuery.query,"{{where_cat}}",where_cat);
  dataQuery.query = string.gsub(dataQuery.query,"{{where_crm}}",where_crm);
  dataQuery.query = string.gsub(dataQuery.query,"{{where_ctype}}",where_ctype);
  dataQuery.query = string.gsub(dataQuery.query,"{{where_org}}",where_org);
  dataQuery.query = string.gsub(dataQuery.query,"{{where_center}}",where_center);
  dataQuery.query = string.gsub(dataQuery.query,"{{where_monetary}}",where_monetary);
  dataQuery.query = string.gsub(dataQuery.query,"{{sort_col}}",sort_col);
  dataQuery.query = string.gsub(dataQuery.query,"{{sort_dir}}",sort_dir_val);
  dataQuery.query = string.gsub(dataQuery.query,"{{r_number}}",r_nummber);
    dataQuery.query = string.gsub(dataQuery.query,"{{f_number}}",f_nummber);
 dataQuery.query = string.gsub(dataQuery.query,"{{m_number}}",m_nummber);
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
  local cols = {


    {show = true ,    key = "Customer"           , value= "Customer" } ,
    {show = true ,    key = "mobile"           , value= "mobile" } ,
    {show = true ,    key = "factor_link"           , value= "factor_link" } ,
    {show = true ,    key = "Days"           , value= "Days" ,type="price"} ,
    {show = true ,    key = "LastRunDate"           , value= "LastRunDate",type="date" } ,
    {show = true ,   key = "Frequency"                  		 , value = "Frequency" } ,
    {show = true ,   key = "Monetary"                  		 , value = "Monetary" ,type="price" } ,
    {show = true ,   key = "rd"                  		 , value = "R" } ,
    {show = true ,   key = "fd"                  		 , value = "F" } ,
    {show = true ,   key = "md"                  		 , value = "M" } ,
    {show = true ,   key = "rfm"                  		 , value = "RFM" } ,
    {show = true ,   key = "segment"                  		 , value = "Segment" } ,
    {show = true ,   key = [[concat("<input type='checkbox' id='ch_save_",crm_id,"' name='ch_save' oninput='ty__main.onChangeCheckInput(",crm_id,")' >")]]  , value ="" } ,
    {show = true ,   key =  [[concat ( "<button type='button' id='mdp_print_btn' style='float:left;'
      class='btn ty-btn-default core_btn btnforsubmit core_btn_submit_Form core_btn_revers_change ty-btn-ok' 
      onclick='ty__main.send_sms(",crm_id,")'>Send SMS</button>")]]                		 , value = "" } ,
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
  teamyar.write_log(select_query)
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
----------------------
function catAcl(data)
  local section_id = data.section;
  local query_param = [[ select c.PROFILE_ID ,concat(s.SECTION_NAME,'/',c.name) from crm_classify_person c inner join crm_section s on s.id=c.section_id  ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  and c.name like N'%]]..data.search..[[%'  or  s.SECTION_NAME like N'%]]..data.search..[[%'  ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end
----------------------
function crmAcl(data)
  local org_id = data.org_id;
  local query_param = [[ select id,name from pa_client where org_id=]]..org_id
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  and name like N'%]]..data.search..[[%'  or  id like N'%]]..data.search..[[%'  ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end


----------------------
function ctypeAcl(data)

  local table = {
    {id =3,name=translateWord("REAL")},
    {id =4,name=translateWord("LEGAL")},

  }
  teamyar.write_result(json.encode(table));
end 

--------------------------------------------
--- Report
--------------------------------------------
function report()
  teamyar.write_log("[RFM] report() called")
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
function getAclOrg(data)
  local query_param = [[  select id,name from org_info ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  where name like N'%]]..data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end

-------------------------------------------
function centerAcl(data)
  teamyar.write_log("dsaate----------"..json.encode(data))
  local org_id = data.org_id;
  teamyar.write_log("[RFM] centerAcl called org_id="..tostring(org_id).." search="..tostring(data.search).." from="..tostring(data.from).." count="..tostring(data.count))
  local query_param = [[ select id,name from PA_CENTER where TYPE=2 and VOUCHER_ALLOW=1 and org_id=]]..org_id
  if org_id ~= nil and tonumber(org_id) ~= nil then
    query_param = query_param .. [[ and ORG_ID=]]..org_id
  end
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param .. [[ and name like N'%]]..data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end
-------------------------------------------
function queryResultcrm(select_query,user_param)
  db.use_db("0000000")
  local params = {
    query = select_query,
    params = user_param
  }
  db.query(params);
  local res_text = {};
  local record = {};
  while db.query_fetch(record) do
    table.insert(res_text, {name = record[1], farsidate = record[2], gender = record[3]});
  end
  db.query_free();
  return res_text;
end
--------------------------------------------
function sendSms(crm_id,segment,box_id,txt)
  local res_str=""
  local q = [[select p.fullname,(select jndate from report_dimdate where ]]..currentdate..[[ 
  between datekey and datekey+(60*60*24*10000000)-(60*10000000)) dd,(case when uf.sex=2 then 'Ø®Ø§Ù†Ù…' else 'Ø¢Ù‚Ø§' end) gender 
  from profile_main p inner join profile_user_info uf on uf.id=p.id where p.id=]]..crm_id
  teamyar.write_log(q)
  local data = queryResultcrm(q, {})
    teamyar.write_log(json.encode(data))
  txt = string.gsub(txt, "{{name}}", data[1].name);
  txt = string.gsub(txt, "{{date}}", data[1].farsidate);
  txt = string.gsub(txt, "{{gender}}", data[1].gender);
  local info =	{box_id = box_id,messages = {{content = txt, send_to = {profile_ids = {crm_id}}}}, module_id = 26}
  teamyar.write_log("info----"..json.encode(info))
  local   res = teamyar.call_api(16, '/api/sms/send', info);
  teamyar.write_log("res----"..json.encode(res))
  if res.success ==true then 
    res_str="<div style='color:green;'>".."Ø§Ø±Ø³Ø§Ù„ Ù¾ÛŒØ§Ù…Ú© Ø¨Ø±Ø§ÛŒ Ú©Ø§Ø±Ø¨Ø± :  "..crm_id.." ØŒ  Ø´Ù†Ø§Ø³Ù‡ Ù¾ÛŒØ§Ù…Ú© :"..res.data.message_ids[1].."</div>"
  else 
    res_str="<div style='color:red;'>".."Ø®Ø·Ø§ Ø¯Ø± Ø§Ø±Ø³Ø§Ù„ Ù¾ÛŒØ§Ù…Ú© :  "..res.error.message.."<div>"

  end 
  return res_str
end
------------
function split(str, delimiter)
  local result = {}
  local pattern = "(.-)" .. delimiter .. "()"
  local lastPos = 1

  for part, pos in string.gmatch(str .. delimiter, pattern) do
    table.insert(result, part)
    lastPos = pos
  end

  return result
end
--------------------------------------------
local type = getInput("type");
if type ~= nil and type == 100 then
  local result = report()
  teamyar.write_result(json.encode(result));

elseif type ~= nil and type == 9 then
  catAcl(teamyar.get_input().data)  
elseif type ~= nil and type == 8 then
  ctypeAcl(teamyar.get_input().data)
elseif type ~= nil and type == 7 then
  crmAcl(teamyar.get_input().data)
elseif type ~= nil and type == 6 then
  getAclOrg(teamyar.get_input().data)
elseif type ~= nil and type == 12 then
  centerAcl(teamyar.get_input().data)
elseif type ~= nil and type == 10 then
  local input = teamyar.get_input()
  local res_str = sendSms(input.data.crm_id,input.data.segment,input.data.box_id, input.data.txt)
  local res_data = {msg = res_str}
  teamyar.write_result(json.encode(res_data))
elseif type ~= nil and type == 11 then
  local input = teamyar.get_input()
  local data = input.data
  local crms = split(data.crms, ',')
  local res_str = ""
  local count_send = 0
  for i,v in ipairs (crms) do 
    local crm_id_in = string.sub(v, 0, #v-3)
    local segment_in = string.sub(v, #v-3, #v)
    sendSms(crm_id_in, segment_in, data.box_id, data.txt)
    count_send = count_send+1
  end
  res_str = " ØªØ¹Ø¯Ø§Ø¯  "..count_send.." Ù¾ÛŒØ§Ù…Ú© Ø§Ø±Ø³Ø§Ù„ Ø´Ø¯ ."
  local res_data={msg=res_str}
  teamyar.write_result(json.encode(res_data))
elseif type ~= nil and type == 101 then
  local result = excel()
  teamyar.write_result(json.encode(result));
elseif type ~= nil and type == 102 then
  local result = print()
  teamyar.write_result(json.encode(result));
elseif type ~= nil and type == 199 then
  local ok_cfg, cfg = pcall(teamyar.get_config)
  local cfg_dump = "n/a"
  if ok_cfg and cfg ~= nil then
    local ok_enc, enc = pcall(json.encode, cfg)
    if ok_enc then cfg_dump = enc else cfg_dump = "encode_failed" end
  elseif not ok_cfg then
    cfg_dump = "get_config_threw: " .. tostring(cfg)
  else
    cfg_dump = "get_config_returned_nil"
  end
  local ok_rep, err_rep = pcall(report)
  teamyar.write_result(json.encode({
    dbg = true,
    config_dump = cfg_dump,
    report_ok = ok_rep,
    report_err = tostring(err_rep)
  }));
else
  local responseResReport = install_res.resReport(getTableConfig());
  teamyar.write_result(responseResReport);
end





