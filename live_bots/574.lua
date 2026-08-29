-- botName = send group 
-- creator = zmo
-- date = 02/25/2025
-- version= 1.0

--
--------------------------------------------
--- CONFIG DATA
--------------------------------------------
local config = teamyar.get_config()
local config_data = {}
local c_bot_send_id = 0
local c_bot_del_id = 0
local c_bot_edit_id = 0
if config ~= nil then 
  config_data = config.data
  c_bot_send_id = config_data.bot_send_id or 0
  c_bot_del_id = config_data.bot_del_id or 0
  c_bot_edit_id = config_data.bot_edit_id or 0
  else
  teamyar.write_result("لطفا تنظیمات پیکربندی پیش فرض بررسی شود ".."<br>")
end 
local day = time.get_day(time.current());
local month = time.get_month(time.current());
local year = time.get_year(time.current());
local min = time.get_minute(time.current());
local hour = time.get_hour(time.current());
local sec = time.get_second(time.current());
local temp_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":]]..hour..[[,"minute":]]..min..[[,"second":]]..sec..[[}]])
currentdate = string.format("%18.0f", temp_time);
----------------------------
local function del_start_all_history()
      db.start()
  local q=[[ delete from  `0000000_bot`.moadianz_fact_history ]]
      db.query_immediate({query = q})
    db.commit()
    db.query_free()
    db.use_db("0000000")
  local quy=teamyar.get_attachment("insert_history.txt")
  
  
        db.start()
      db.query_immediate({query = quy})
    db.commit()
    db.query_free()
    db.use_db("0000000")
end 
-----------------------
--del_start_all_history()
----------------------------
-- check/create moadianz_fact_history table
local _HISTORY_TABLE_OK = false
local _history_err = ""
local ok, err = pcall(function()
  db.use_db("0000000_bot")
  db.check_table({
    name = "moadianz_fact_history",
    fields = [[
      ID            BIGINT       NOT NULL AUTO_INCREMENT,
      invoice_id    BIGINT       NOT NULL DEFAULT 0,
      date          BIGINT       NOT NULL DEFAULT 0,
      unic_id       VARCHAR(255) NOT NULL DEFAULT '',
      ref_id        VARCHAR(255) NOT NULL DEFAULT '',
      err           TEXT,
      ststus        VARCHAR(255) NOT NULL DEFAULT '',
      state         INT          NOT NULL DEFAULT 0,
      comment       TEXT,
      type          INT          NOT NULL DEFAULT 0,
      ref_invoce_id VARCHAR(255) NOT NULL DEFAULT '',
      send_txt      LONGTEXT,
      get_txt       LONGTEXT,
      inquired      TINYINT      NOT NULL DEFAULT 0
    ]],
    index_items = {
      {1, "primary", "ID"},
      {2, "index",   "invoice_id"},
    }
  })
  db.use_db("0000000")
  _HISTORY_TABLE_OK = true
end)
if not ok then _history_err = tostring(err) end
pcall(function() db.use_db("0000000") end)
if not _HISTORY_TABLE_OK then
  teamyar.write_log("moadianz_fact_history table creation failed: " .. tostring(_history_err))
end
----------------------------
local function sql_escape(s)
  s = s or ''
  s = tostring(s)
  s = s:gsub("\\", "\\\\")
  s = s:gsub("'", "''")
  return s
end
----------------------------
local function get_persian_datetime(ft)
  local result = ""
  if not ft or tonumber(ft) == nil or tonumber(ft) <= 0 then return result end
  ft = tonumber(ft)
  pcall(function()
    local uinfo = teamyar.get_user_info()
    local timezone = 0
    if uinfo and uinfo.timezone then timezone = tonumber(uinfo.timezone) or 0 end
    local ft_adjusted = ft + timezone
    local jndate = queryResultOne([[SELECT jndate FROM report_dimdate WHERE ]]..ft_adjusted..[[ BETWEEN datekey AND datekey+(60*60*24*10000000)-(60*10000000)]], "")
    local hh = time.get_hour(ft_adjusted)
    local mi = time.get_minute(ft_adjusted)
    local hh_str = tostring(hh)
    if hh < 10 then hh_str = "0"..hh_str end
    local mi_str = tostring(mi)
    if mi < 10 then mi_str = "0"..mi_str end
    if jndate and jndate ~= "" then
      result = tostring(jndate).." "..hh_str..":"..mi_str
    else
      local yy = time.get_year(ft_adjusted)
      local mm = time.get_month(ft_adjusted)
      local dd = time.get_day(ft_adjusted)
      result = tostring(yy).."/"..tostring(mm).."/"..tostring(dd).." "..hh_str..":"..mi_str
    end
  end)
  return result
end
----------------------------
local function get_ref_id(invoice_id)
  local rf = queryResultOne([[SELECT TRIM(ref_id) FROM `0000000_bot`.moadianz_fact_history
    WHERE invoice_id=]]..invoice_id..[[ AND ref_id!='' ORDER BY id DESC LIMIT 1]], {})
  return rf or ""
end
----------------------------
local function get_unic_id(invoice_id)
  local rf = queryResultOne([[SELECT TRIM(unic_id) FROM `0000000_bot`.moadianz_fact_history
    WHERE invoice_id=]]..invoice_id..[[ AND unic_id!='' ORDER BY id DESC LIMIT 1]], {})
  return rf or ""
end
----------------------------
local function check_last_inquired(invoice_id)
  local last = queryResultOne([[SELECT inquired FROM `0000000_bot`.moadianz_fact_history
    WHERE invoice_id=]]..invoice_id..[[ AND type IN (1,2,3) ORDER BY id DESC LIMIT 1]], {})
  return last == 1
end
----------------------------
local function get_active_unic_id(invoice_id, op_type)
  local uid = queryResultOne([[SELECT TRIM(h1.unic_id) FROM `0000000_bot`.moadianz_fact_history h1
    WHERE h1.invoice_id=]]..invoice_id..[[ AND h1.type=]]..op_type..[[ AND h1.ref_id!=''
    AND h1.id = (
      SELECT MAX(h2.id) FROM `0000000_bot`.moadianz_fact_history h2
      WHERE h2.invoice_id=]]..invoice_id..[[ AND h2.type=]]..op_type..[[ AND h2.ref_id!=''
    )
    AND NOT EXISTS (
      SELECT 1 FROM `0000000_bot`.moadianz_fact_history h3
      WHERE h3.invoice_id=]]..invoice_id..[[ AND h3.type IN (1,2,3) AND h3.ref_id!=''
      AND h3.type != ]]..op_type..[[
      AND h3.id > h1.id
    )
    ORDER BY h1.id DESC LIMIT 1]], {})
  return uid or ""
end
----------------------------
local function get_err_text(invoice_id)
  local ef = queryResultOne([[select REPLACE(SUBSTRING_INDEX(NOTE, "<div id='res_inquery'>", -1),'</div></td></tr></table>','')
    from sales_history
    where invoice_id=]]..invoice_id..[[ and note like "%<div id='res_inquery'>%"
    order by id desc limit 1]], {})
  if ef == nil then return "" end
  ef = tostring(ef)
  if ef == "userdata: 0x0" or ef:match("^userdata:") then return "" end
  return ef
end
----------------------------
local function get_moadian_status(invoice_id)
  local ms = queryResultOne([[select moadian_status from sales_invoice where id=]]..invoice_id, {})
  return tonumber(ms) or 0
end

----------------------------
local function insert_history(invoice_id, h_type, send_txt, get_txt, res_status, comment_val, ref_invoce_id_val, h_unic_id_val, h_ref_id_val)
  if not _HISTORY_TABLE_OK then return end
  local h_unic_id = h_unic_id_val or ""
  local h_ref_id = h_ref_id_val or ""
  local h_state = get_moadian_status(invoice_id)
  local h_ststus = ""
  if res_status ~= nil then h_ststus = tostring(res_status) end
  if h_ststus:match("^userdata:") then h_ststus = "" end
  local h_ref_invoce_id = ref_invoce_id_val or ''
  local h_comment = ""
  if comment_val ~= nil then h_comment = tostring(comment_val) end
  if h_comment:match("^userdata:") then h_comment = "" end
  local h_send_txt = ""
  if send_txt ~= nil then h_send_txt = tostring(send_txt) end
  if h_send_txt:match("^userdata:") then h_send_txt = "" end
  local h_get_txt = ""
  if get_txt ~= nil then h_get_txt = tostring(get_txt) end
  if h_get_txt:match("^userdata:") then h_get_txt = "" end
  pcall(function()
    db.start()
    local q = [[INSERT INTO `0000000_bot`.moadianz_fact_history
      (invoice_id, date, unic_id, ref_id, err, ststus, state, comment, type, ref_invoce_id, send_txt, get_txt)
      VALUES (]]..tonumber(invoice_id)..[[, ]]..currentdate..[[, ']]..sql_escape(h_unic_id)..[[', ']]..sql_escape(h_ref_id)..[[',
      '', ']]..sql_escape(h_ststus)..[[', ]]..h_state..[[,
      ']]..sql_escape(h_comment)..[[', ]]..tonumber(h_type)..[[, ']]..sql_escape(h_ref_invoce_id)..[[',
      ']]..sql_escape(h_send_txt)..[[', ']]..sql_escape(h_get_txt)..[[')]]
    db.query_immediate({query = q})
    db.commit()
    db.query_free()
    db.use_db("0000000")
  end)
end
----------------------------
local function update_history_status(invoice_id, res_status, comment_val, err_val, hid, inq_append)
  if not _HISTORY_TABLE_OK then return end
  local h_state = get_moadian_status(invoice_id)
  local h_ststus = ""
  if res_status ~= nil then h_ststus = tostring(res_status) end
  if h_ststus:match("^userdata:") then h_ststus = "" end
  local h_err = ""
  if err_val ~= nil then h_err = tostring(err_val) end
  if h_err:match("^userdata:") then h_err = "" end
  local h_comment = ""
  if comment_val ~= nil then h_comment = tostring(comment_val) end
  if h_comment:match("^userdata:") then h_comment = "" end
  local append_text = ""
  if inq_append ~= nil then append_text = tostring(inq_append) end
  if append_text:match("^userdata:") then append_text = "" end
  local where_clause = ""
  if hid and tonumber(hid) > 0 then
    where_clause = "WHERE id="..tonumber(hid)
  else
    where_clause = "WHERE invoice_id="..tonumber(invoice_id).." ORDER BY id DESC LIMIT 1"
  end
  pcall(function()
    db.start()
    local q = [[UPDATE `0000000_bot`.moadianz_fact_history
      SET ststus=']]..sql_escape(h_ststus)..[[', state=]]..h_state..[[,
      comment=CONCAT(comment, ']]..sql_escape(append_text)..[['),
      err=']]..sql_escape(h_err)..[[', inquired=1
      ]]..where_clause..[[]]
    teamyar.write_log("update_history_status SQL: "..string.sub(q,1,200))
    db.query_immediate({query = q})
    db.commit()
    db.query_free()
    db.use_db("0000000")
  end)
end
----------------------------
local _PAR_PAGE = 100
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

  local c_count_out = 0
  if config ~= nil then 
    cdata = config.data
    c_count_out = cdata.count_out

  end 


  local user_info = teamyar.get_user_info()
  local time_zone = user_info.timezone
  local org = getInput("org_id");
  local stock = getInput("stock");
  local tag = getInput("tag");
  local product = getInput("product");
  local crm = getInput("crm");
  local kcrm = getInput("kcrm");
  local datef = getInput("datef");
  local datet = getInput("datet");
  local moadian_code = getInput("moadian_code");
  local factor_id = getInput("factor_id");
  local send_status = getInput("send_status");
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



  if org ~= nil and type(org) == "table" then
    dataQuery.query = string.gsub(dataQuery.query, "{{org_id}}", org[1].id);
  else
    dataQuery.query = string.gsub(dataQuery.query, "{{org_id}}", "0");
  end 
  local where_stock = ""
  local where_stock_out = ""
  local where_product = ""
  local where_crm= ""
  local where_kcrm= ""
  local where_tag = ""
  local where_moadian_code =""
  local where_factor_id = ""
  local where_send_status = ""

  if product ~= nil and  type(product) == "table" and product[1] ~= nil then 
    where_product = where_product.. [[ and ip.product_id=]]..product[1].id

  end 
  if stock ~= nil and  type(stock) == "table" and stock[1] ~= nil then 
    where_stock = where_stock.. [[ and ip.stock_id=]]..stock[1].id
  end 
  if crm ~= nil and  type(crm) == "table" and crm[1] ~= nil then 
    where_crm = where_crm.. [[ and i.client_id=]]..crm[1].id
  end 
  if kcrm ~= nil  and  type(kcrm) == "table" and kcrm[1] ~= nil then 
    where_kcrm = where_kcrm.. [[ and (select ty from user_ty where clid=i.client_id and oid=i.org_id )=]]..kcrm[1].id
  end 
  if tag ~= nil  and  type(tag) == "table" and tag[1] ~= nil then 
    where_tag = where_tag.. [[ and t.TAG_ID=]]..tag[1].id
  end 

  if moadian_code ~= nil  and  type(moadian_code) == "string" and moadian_code ~= "" and  tostring(moadian_code) ~= "0" and  moadian_code ~= "null" and  moadian_code ~= "nil" then 
    where_moadian_code = where_moadian_code.. [[ and (select rf from m_factor_id where invoice_id=i.id order by id desc limit 1 )  like '%%]]..moadian_code..[[%%']]
  end 
--  teamyar.write_log("type(factor_id)----"..type(factor_id))
  if factor_id ~= nil and  type(factor_id) == "number"  and factor_id ~= "" and  tostring(factor_id) ~= "0" and  factor_id ~= "null" and  factor_id ~= "nil"  then 
    where_factor_id = where_factor_id.. [[ and i.id=]]..factor_id
  end 
  if send_status ~= nil and  type(send_status) == "table" and send_status[1] ~= nil then 
    where_send_status = where_send_status.. [[ and moadian_status=]]..send_status[1].id
  end 
  if type(datet)~="number" then
    datet = 0
  end
  if type(datef)~="number" then
    datef = 0
  end
  dataQuery.query = string.gsub(dataQuery.query,"{{datet}}",datet);
  dataQuery.query = string.gsub(dataQuery.query,"{{datef}}",datef);
  dataQuery.query = string.gsub(dataQuery.query,"{{where_stock}}",where_stock);
  dataQuery.query = string.gsub(dataQuery.query,"{{where_tag}}",where_tag);
  dataQuery.query = string.gsub(dataQuery.query,"{{where_product}}",where_product);
  dataQuery.query = string.gsub(dataQuery.query,"{{where_crm}}",where_crm);
  dataQuery.query = string.gsub(dataQuery.query,"{{where_kcrm}}",where_kcrm);
  dataQuery.query = string.gsub(dataQuery.query,"{{where_moadian_code}}",where_moadian_code);
  dataQuery.query = string.gsub(dataQuery.query,"{{where_factor_id}}",where_factor_id);  
  dataQuery.query = string.gsub(dataQuery.query,"{{where_send_status}}",where_send_status);


  ---- Execute Query
--  teamyar.write_log(dataQuery.query)
  return getQuery_result(queryType , dataQuery);
end
--------------------------------
function queryResultOne(select_query,user_param)
  db.use_db("0000000");
  teamyar.write_log(select_query)
  local params1 = {
    query = select_query,
    params = user_param
  }
  db.query(params1);
  local res_text = db.query_fetch();
  db.query_free();
  if res_text ~= nil then 
    return res_text[1];
  else
    return nil 
  end 
end
-----------------------------------------------------------
function queryResult(query, query_params)
  db.use_db("0000000")
  local params = {
    query = query,
    params = query_params
  }
 -- teamyar.write_log(query)
  db.query(params);
  local res_text = {};
  local record = {};
  while db.query_fetch(record) do
    --id,link,TITLE,d,btn,err,status,referenceNumber,unic_id

    table.insert(res_text, { 
        id = record[1],
        link = record[2], 
        TITLE = record[3],
        d = record[4],
                btn = record[5],
        btne = record[6],
             err = record[7],
    
        status = record[8],
         
        referenceNumber = record[9] ,
        unic_id = record[10],
         amont = record[11],   

        });
  end
  db.query_free();
  return res_text;
end
---------------------------------------------
function getAllData(org_id,datef,datet,crm_id,kcrm_id,tag_id,product_id,stock_id,moadian_code,factor_id,send_status)
  local aquery = teamyar.get_attachment("query_list_invoice.txt") 
  aquery = string.gsub(aquery, "{{current_date}}",  currentdate);



  if org_id ~= nil  then
    aquery = string.gsub(aquery, "{{org_id}}", org_id);
  else
    aquery = string.gsub(aquery, "{{org_id}}", "0");
  end 
  local where_stock = ""
  local where_stock_out = ""
  local where_product = ""
  local where_crm= ""
  local where_kcrm= ""
  local where_tag = ""
  local where_moadian_code =""
  local where_factor_id = ""
  local where_send_status = ""


  if product_id ~= nil and product_id ~= nil then 
    where_product = where_product.. [[ and ip.product_id=]]..product_id

  end 
  if stock_id ~= nil and stock_id ~= nil then 
    where_stock = where_stock.. [[ and ip.stock_id=]]..stock_id
  end 
  if crm_id ~= nil and crm_id ~= nil then 
    where_crm = where_crm.. [[ and i.client_id=]]..crm_id
  end 
  if kcrm_id ~= nil and kcrm_id ~= nil then 
    where_kcrm = where_kcrm.. [[ and (select ty from user_ty where clid=i.client_id and oid=i.org_id )=]]..kcrm_id
  end 
  if tag_id ~= nil and tag_id ~= nil then 
    where_tag = where_tag.. [[ and t.TAG_ID=]]..tag_id
  end  
  if  moadian_code ~= nil  and  type(moadian_code) == "string" and moadian_code ~= "" and  tostring(moadian_code) ~= "0" and  moadian_code ~= "null" and  moadian_code ~= "nil" then 
    where_moadian_code = where_moadian_code.. [[ and (select rf from m_factor_id where invoice_id=i.id order by id desc limit 1 ) like '%%]]..moadian_code..[[%%']]
  end 
  

  if factor_id ~= nil and  type(factor_id) == "number"  and factor_id ~= "" and  tostring(factor_id) ~= "0" and  factor_id ~= "null" and  factor_id ~= "nil"  then 
    where_factor_id = where_factor_id.. [[ and i.id=]]..factor_id
  end 
  if send_status ~= nil and send_status[1] ~= nil then 
    where_send_status = where_send_status.. [[ and moadian_status=]]..send_status[1].id
  end  
  aquery = string.gsub(aquery,"{{select}}","*");
  aquery = string.gsub(aquery,"{{whereInvoice}}","");
  aquery = string.gsub(aquery,"{{slicePageNumber}}","");
  aquery = string.gsub(aquery,"{{datet}}",datet);
  aquery = string.gsub(aquery,"{{datef}}",datef);
  aquery = string.gsub(aquery,"{{where_stock}}",where_stock);
  aquery = string.gsub(aquery,"{{where_tag}}",where_tag);
  aquery = string.gsub(aquery,"{{where_product}}",where_product);
  aquery = string.gsub(aquery,"{{where_crm}}",where_crm);
  aquery = string.gsub(aquery,"{{where_kcrm}}",where_kcrm);
  aquery = string.gsub(aquery,"{{where_moadian_code}}",where_moadian_code);
  aquery = string.gsub(aquery,"{{where_factor_id}}",where_factor_id);  
  aquery = string.gsub(aquery,"{{where_send_status}}",where_send_status);
-- teamyar.write_log("***-----------"..aquery)
  local res_data=queryResult(aquery,{})
  return res_data
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
    {show= true ,    key = "title"           , value= "title" } ,
    {show= true ,    key = "d"           , value= "d" ,type="date"} ,
   
    {show= true ,    key = "fee"           , value= "fee" ,type="price",sum=true} ,
    {show= true ,    key = "discount"           , value= "discount" ,type="price",sum=true} ,
    {show= true ,    key = "value_added"           , value= "value_added" ,type="price",sum=true} ,
    {show= true ,    key = "price_fact"           , value= "price_fact" ,type="price",sum=true} ,
    {show= true ,    key = "amont"           , value= "amont" ,type="price",sum=true} ,
     {show= true ,    key = "product_codes"           , value= "product_codes" } ,
          {show= true ,    key = "bill_type"           , value= "bill_type" } ,
      {show= true ,    key = "bill_template"           , value= "bill_template" } ,

    {show= true ,    key = "status"           , value= "status" } ,

    {show= true ,    key = "btn"           , value= "btn" } ,
    {show= true ,    key = "btne"           , value= "btne" } ,
  };
  --   teamyar.write_log("ffcols6"..json.encode(cols))
  return cols
end
--------------------------------------------
function getTableConfig_sum()
  -- teamyar.write_log("summ --")
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
function StockAcl(data)
  local geted_org_id = data.org_id;
  local query_param = [[select id,concat(full_code,'_',name)name from wh_stock  where  VOUCHER_ALLOW=1 and  org_id=]]..geted_org_id
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  and  (name like N'%]]..data.search..[[%' or  full_code like N'%]]..data.search..[[%') ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end
----------------------
function crmAcl(data)
  local geted_org_id = data.org_id;
  local query_param = [[select id,name from pa_client where  org_id= ]]..geted_org_id
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  and  name like N'%]]..data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end 
----------------------
function crmTag(data)

  local query_param = [[select id,name from  pa_voucher_tag where 1=1 ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  and  name like N'%]]..data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end 
--------------------------------------------
function kcrmAcl()
  local table = {
    {id =3,name=translateWord("حقیقی")},
    {id =4,name=translateWord("حقوقی")},

  }
  teamyar.write_result(json.encode(table));
end
--------------------------------------------
function sendStatusAcl(data)
  local moadian_status_table = {
    {id = 101, name = translateWord("پذیرفته شده [ارسالی]")},
    {id = 102, name = translateWord("رد شده [ارسالی]")},
    {id = 103, name = translateWord("در انتظار بررسی [ارسالی]")},
    {id = 104, name = translateWord("ابطال شده [ارسالی]")},
    {id = 105, name = translateWord("ناموفق / خطا در پردازش [ارسالی]")},
    {id = 106, name = translateWord("در حال پردازش [ارسالی]")},
    {id = 107, name = translateWord("پیش‌نویس [ارسالی]")},
    {id = 108, name = translateWord("ارسال شده [ارسالی]")},
    {id = 109, name = translateWord("در انتظار [ارسالی]")},
    {id = 110, name = translateWord("دیگر نیازی به واکنش نیست [ارسالی]")},
    {id = 111, name = translateWord("نامشخص [ارسالی]")},
    {id = 112, name = translateWord("پیدا نشده [ارسالی]")},
    {id = 113, name = translateWord("خطادراستعلام [ارسالی]")},
    {id = 114, name = translateWord("خطا در ارتباط [ارسالی]")},
    {id = 115, name = translateWord("استعلام نشده [ارسالی]")},
    {id = 116, name = translateWord("عدم ارسال/خطا [ارسالی]")},
    {id = 117, name = translateWord("تنظیمات پیکربندی خالی [ارسالی]")},
    {id = 118, name = translateWord("عدم ارتباط سامانه [ارسالی]")},
    {id = 201, name = translateWord("پذیرفته شده [ابطالی]")},
    {id = 202, name = translateWord("رد شده [ابطالی]")},
    {id = 203, name = translateWord("در انتظار بررسی [ابطالی]")},
    {id = 204, name = translateWord("ابطال شده [ابطالی]")},
    {id = 205, name = translateWord("ناموفق / خطا در پردازش [ابطالی]")},
    {id = 206, name = translateWord("در حال پردازش [ابطالی]")},
    {id = 207, name = translateWord("پیش‌نویس [ابطالی]")},
    {id = 208, name = translateWord("ارسال شده [ابطالی]")},
    {id = 209, name = translateWord("در انتظار [ابطالی]")},
    {id = 210, name = translateWord("دیگر نیازی به واکنش نیست [ابطالی]")},
    {id = 211, name = translateWord("نامشخص [ابطالی]")},
    {id = 212, name = translateWord("پیدا نشده [ابطالی]")},
    {id = 213, name = translateWord("خطادراستعلام [ابطالی]")},
    {id = 214, name = translateWord("خطا در ارتباط [ابطالی]")},
    {id = 215, name = translateWord("استعلام نشده [ابطالی]")},
    {id = 216, name = translateWord("عدم ارسال/خطا [ابطالی]")},
    {id = 217, name = translateWord("تنظیمات پیکربندی خالی [ابطالی]")},
    {id = 218, name = translateWord("عدم ارتباط سامانه [ابطالی]")},
    {id = 301, name = translateWord("پذیرفته شده [اصلاحی]")},
    {id = 302, name = translateWord("رد شده [اصلاحی]")},
    {id = 303, name = translateWord("در انتظار بررسی [اصلاحی]")},
    {id = 304, name = translateWord("ابطال شده [اصلاحی]")},
    {id = 305, name = translateWord("ناموفق / خطا در پردازش [اصلاحی]")},
    {id = 306, name = translateWord("در حال پردازش [اصلاحی]")},
    {id = 307, name = translateWord("پیش‌نویس [اصلاحی]")},
    {id = 308, name = translateWord("ارسال شده [اصلاحی]")},
    {id = 309, name = translateWord("در انتظار [اصلاحی]")},
    {id = 310, name = translateWord("دیگر نیازی به واکنش نیست [اصلاحی]")},
    {id = 311, name = translateWord("نامشخص [اصلاحی]")},
    {id = 312, name = translateWord("پیدا نشده [اصلاحی]")},
    {id = 313, name = translateWord("خطادراستعلام [اصلاحی]")},
    {id = 314, name = translateWord("خطا در ارتباط [اصلاحی]")},
    {id = 315, name = translateWord("استعلام نشده [اصلاحی]")},
    {id = 316, name = translateWord("عدم ارسال/خطا [اصلاحی]")},
    {id = 317, name = translateWord("تنظیمات پیکربندی خالی [اصلاحی]")},
    {id = 318, name = translateWord("عدم ارتباط سامانه [اصلاحی]")},
    {id = 0,   name = translateWord("ارسال نشده")},
    {id = 1,   name = translateWord("ارسال شده")},
    {id = 2,   name = translateWord("خطا")},
    {id = 3,   name = translateWord("تایید")},
    {id = 4,   name = translateWord("درخواست ابطال")},
    {id = 5,   name = translateWord("خطا در ثبت ابطال")},
    {id = 6,   name = translateWord("ابطال شده")},
  }

  if data.search ~= nil and #data.search > 0 then
    local filtered = {}
    for _, item in ipairs(moadian_status_table) do
      if string.find(item.name, data.search, 1, true) ~= nil then
        table.insert(filtered, item)
      end
    end
    teamyar.write_result(json.encode(filtered))
  else
      teamyar.write_result(json.encode(moadian_status_table))
  end

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
function inqueryfactor(fid,referenceNumber,date_replace,org_id,unic_id,hid)
  teamyar.write_log("inqueryfactor called: fid="..tostring(fid).." hid="..tostring(hid).." ref="..tostring(referenceNumber).." unic_id=["..tostring(unic_id).."] len="..tostring(#tostring(unic_id or "")))
  local res_bot = teamyar.run_command("2/inquery_invoice_taxpayer_m/", { referenceNumber = referenceNumber, invoice_id = tostring(fid), org_id = org_id, unic_id = unic_id})
  local res_status = teamyar.run_command("2/fact_st_m" , { invoice_id = tostring(fid), org_id = org_id }); 
  if res_status ~= nil then res_status = tostring(res_status) end
  if res_status and res_status:match("^userdata:") then res_status = "" end
  local h_send_txt = ""
  local h_get_txt = ""
  local h_comment = ""
  local h_err = ""
  pcall(function()
    local parsed = json.decode(res_bot)
    if parsed and parsed.msg then res_bot = parsed.msg end
    if parsed and parsed.send_txt then h_send_txt = parsed.send_txt end
    if parsed and parsed.get_txt then h_get_txt = parsed.get_txt end
    if parsed and parsed.status then h_comment = tostring(parsed.status) end
    if h_get_txt and h_get_txt ~= "" then
      local ok2, inq = pcall(json.decode, h_get_txt)
      if ok2 and inq and inq[1] and inq[1].data and inq[1].data.error and inq[1].data.error[1] then
        h_err = inq[1].data.error[1].message or ""
      end
    end
  end)
  if h_err == "" then
    h_err = get_err_text(fid)
  end
  teamyar.write_log("inqueryfactor err: hid="..tostring(hid).." err_len="..tostring(#h_err).." err="..tostring(string.sub(h_err,1,80)))
  local inq_date_fa = ""
  pcall(function()
    local ct = time.current()
    inq_date_fa = get_persian_datetime(ct)
  end)
  local inq_append = ""
  if res_bot and tostring(res_bot) ~= "" then
    inq_append = "<br>استعلام:"..inq_date_fa.."|"..tostring(res_bot)
  end
  pcall(function()
    update_history_status(fid, res_status or "", h_comment, h_err, hid, inq_append)
  end)
  return res_bot, res_status
end
-------------------------------------------
function delfactor(fid,referenceNumber,date_replace,org_id,unic_id)
  local res_bot = ""
  local config_id = queryResultOne([[select  CONFIG_ID  from bot_command_config where COMMAND_ID=]]..c_bot_del_id..[[ and json_unquote(config->"$.org_id")=]]..org_id,{})
    teamyar.write_log("delfactor: invoice "..tostring(fid).." last operation not inquired, doing inquiry first")
    local last_hid = queryResultOne([[SELECT id FROM `0000000_bot`.moadianz_fact_history
      WHERE invoice_id=]]..fid..[[ AND type IN (1,2,3) ORDER BY id DESC LIMIT 1]], {})
    pcall(function()
      inqueryfactor(fid, get_ref_id(fid), date_replace, org_id, get_unic_id(fid), tonumber(last_hid) or 0)
    end)

  if config_id == nil or config_id ==0 then 
    res_bot = [[ برای شعبه انتخاب شده در بات  "ارسال فاکتور ابطالی به سامانه مودیان" پیکربندی ای یافت نشد]]
  else
    res_bot = teamyar.run_command("2/tax_gov_edit_m/"..config_id ,
      {invoice_id = tostring(fid), referenceNumber = referenceNumber,
        date_replace= date_replace,kind_refrence=3, unic_id=unic_id or ""});
  end
  local res_status = teamyar.run_command("2/fact_st_m" , { invoice_id = tostring(fid), org_id = org_id });
  local h_send_txt = ""
  local h_get_txt = ""
  local h_comment = ""
  local h_ref_invoce_id = unic_id or ""
  local h_unic_id = ""
  local h_ref_id = ""
  pcall(function()
    local parsed = json.decode(res_bot)
    if parsed and parsed.msg then res_bot = parsed.msg end
    if parsed and parsed.send_txt then h_send_txt = parsed.send_txt end
    if parsed and parsed.get_txt then h_get_txt = parsed.get_txt end
    if parsed and parsed.status then h_comment = tostring(parsed.status) end
    if parsed and parsed.ref_invoce_id and #tostring(parsed.ref_invoce_id) > 0 then
      h_ref_invoce_id = tostring(parsed.ref_invoce_id)
    end
    if parsed and parsed.unic_id then h_unic_id = tostring(parsed.unic_id) end
    if parsed and parsed.ref_id then h_ref_id = tostring(parsed.ref_id) end
  end)
  local bot_msg = ""
  if res_bot and tostring(res_bot) ~= "" then bot_msg = tostring(res_bot) end
  if h_comment and h_comment ~= "" then
    h_comment = h_comment .. "<br>" .. bot_msg
  else
    h_comment = bot_msg
  end
  pcall(function()
    insert_history(fid, 2, h_send_txt, h_get_txt, res_status or "", h_comment, h_ref_invoce_id, h_unic_id, h_ref_id)
  end)
  return res_bot, res_status
end
-------------------------------------------
function editfactor(fid,referenceNumber,date_replace,org_id,changes,unic_id)
  teamyar.write_log("editfactor unic_id=["..tostring(unic_id).."] fid=["..tostring(fid).."]")
  teamyar.write_log("changes------------"..json.encode(changes))
  local res_bot = ""
  local config_id = queryResultOne([[select  CONFIG_ID  from bot_command_config where COMMAND_ID=]]..c_bot_edit_id..[[ and json_unquote(config->"$.org_id")=]]..org_id,{})

    teamyar.write_log("editfactor: invoice "..tostring(fid).." last operation not inquired, doing inquiry first")
    local last_hid = queryResultOne([[SELECT id FROM `0000000_bot`.moadianz_fact_history
      WHERE invoice_id=]]..fid..[[ AND type IN (1,2,3) ORDER BY id DESC LIMIT 1]], {})
    pcall(function()
      inqueryfactor(fid, get_ref_id(fid), date_replace, org_id, get_unic_id(fid), tonumber(last_hid) or 0)
    end)

  if config_id == nil or config_id ==0 then 
    res_bot = [[ برای شعبه انتخاب شده در بات  "ارسال فاکتور اصلاحی به سامانه مودیان" پیکربندی ای یافت نشد]]
  else
    res_bot = teamyar.run_command("2/tax_gov_edit_factor_m/"..config_id ,
      {invoice_id = tostring(fid), referenceNumber = referenceNumber,
        date_replace= date_replace, changes=changes,type=128, unic_id=unic_id or ""});-- 128 get changews by input not form 
  end
  local res_status = teamyar.run_command("2/fact_st_m" , { invoice_id = tostring(fid), org_id = org_id });
  local h_send_txt = ""
  local h_get_txt = ""
  local h_comment = ""
  local h_ref_invoce_id = unic_id or ""
  local h_unic_id = ""
  local h_ref_id = ""
  pcall(function()
    local parsed = json.decode(res_bot)
    if parsed and parsed.msg then res_bot = parsed.msg end
    if parsed and parsed.send_txt then h_send_txt = parsed.send_txt end
    if parsed and parsed.get_txt then h_get_txt = parsed.get_txt end
    if parsed and parsed.status then h_comment = tostring(parsed.status) end
    if parsed and parsed.ref_invoce_id and #tostring(parsed.ref_invoce_id) > 0 then
      h_ref_invoce_id = tostring(parsed.ref_invoce_id)
    end
    if parsed and parsed.unic_id then h_unic_id = tostring(parsed.unic_id) end
    if parsed and parsed.ref_id then h_ref_id = tostring(parsed.ref_id) end
  end)
  local bot_msg = ""
  if res_bot and tostring(res_bot) ~= "" then bot_msg = tostring(res_bot) end
  if h_comment and h_comment ~= "" then
    h_comment = h_comment .. "<br>" .. bot_msg
  else
    h_comment = bot_msg
  end
  pcall(function()
    insert_history(fid, 3, h_send_txt, h_get_txt, res_status or "", h_comment, h_ref_invoce_id, h_unic_id, h_ref_id)
  end)
  return res_bot, res_status
end
-------------------------------------------
function savefactor(fid,date_replace,org_id)

 --teamyar.write_log("org_id---"..org_id)
  local config_id = queryResultOne([[select  CONFIG_ID  from bot_command_config where COMMAND_ID=]]..c_bot_send_id..[[ and json_unquote(config->"$.org_id")=]]..org_id,{})
  local res_bot = ""
  local h_send_txt = ""
  local h_get_txt = ""
  local h_comment = ""
  local h_unic_id = ""
  local h_ref_id = ""

    teamyar.write_log("savefactor: invoice "..tostring(fid).." last operation not inquired, doing inquiry first")
    local last_hid = queryResultOne([[SELECT id FROM `0000000_bot`.moadianz_fact_history
      WHERE invoice_id=]]..fid..[[ AND type IN (1,2,3) ORDER BY id DESC LIMIT 1]], {})
    local last_ref = get_ref_id(fid)
    pcall(function()
      inqueryfactor(fid, last_ref, date_replace, org_id, get_unic_id(fid), tonumber(last_hid) or 0)
    end)

  if config_id == nil or config_id ==0 then 
  	res_bot = [[ برای شعبه انتخاب شده در بات  "ارسال مستقیم فاکتور به سامانه مودیان" پیکربندی ای یافت نشد]]
  else
  res_bot = teamyar.run_command("2/tax_gov_test_md/"..config_id , {invoice_id = tostring(fid),date_replace = date_replace});
  end
  -- teamyar.write_log("res_bot---"..res_bot)
  local res_status = teamyar.run_command("2/fact_st_m" , { invoice_id = tostring(fid), org_id = org_id });
  --teamyar.write_log("res_status---"..res_status)
  pcall(function()
    local parsed = json.decode(res_bot)
    if parsed and parsed.msg then res_bot = parsed.msg end
    if parsed and parsed.send_txt then h_send_txt = parsed.send_txt end
    if parsed and parsed.get_txt then h_get_txt = parsed.get_txt end
    if parsed and parsed.status then h_comment = tostring(parsed.status) end
    if parsed and parsed.unic_id then h_unic_id = tostring(parsed.unic_id) end
    if parsed and parsed.ref_id then h_ref_id = tostring(parsed.ref_id) end
  end)
  local bot_msg = ""
  if res_bot and tostring(res_bot) ~= "" then bot_msg = tostring(res_bot) end
  if h_comment and h_comment ~= "" then
    h_comment = h_comment .. "<br>" .. bot_msg
  else
    h_comment = bot_msg
  end
  pcall(function()
    insert_history(fid, 1, h_send_txt, h_get_txt, res_status or "", h_comment, nil, h_unic_id, h_ref_id)
  end)
  return res_bot, res_status
end
--------------------------------------------
local type = getInput("type");
if type ~= nil and type == 100 then
  local result = report()
  teamyar.write_result(json.encode(result));
elseif type ~= nil and type == 7 then
  orgAcl(teamyar.get_input().data)
elseif type ~= nil and type == 9 then
  productAcl(teamyar.get_input().data)  
elseif type ~= nil and type == 4 then
  crmAcl(teamyar.get_input().data)
elseif type ~= nil and type == 5 then
  crmTag(teamyar.get_input().data)
elseif type ~= nil and type == 8 then
  StockAcl(teamyar.get_input().data)
elseif type ~= nil and type == 3 then
  kcrmAcl()
elseif type ~= nil and type == 6 then
  sendStatusAcl(teamyar.get_input().data)
elseif type ~= nil and type == 10 then
  local input= teamyar.get_input()
  local fid=input.fid
  local date_replace=input.date_replace
  local botmsg, fact_st = savefactor(fid,date_replace,input.org_id)
  local msg ="شماره فاکتور:"..fid.."  ".. botmsg.."<br> وضعیت در سامانه= "..fact_st
  local res_data={msg = msg}
  teamyar.write_result(json.encode(res_data))
  elseif type ~= nil and type == 12 then
  local input= teamyar.get_input()
  local fid=input.fid
  local referenceNumber = input.referenceNumber
  local date_replace=input.date_replace
  local h_unic_id = get_unic_id(fid)
  local botmsg, fact_st = inqueryfactor(fid,referenceNumber,date_replace,input.org_id, h_unic_id, 0)
  local msg ="شماره فاکتور:"..fid.."  ".. botmsg.."<br> وضعیت در سامانه= "..fact_st
  local res_data={msg = msg}
  teamyar.write_result(json.encode(res_data))
elseif type ~= nil and type == 11 then
  local input = teamyar.get_input()
  local date_replace = input.date_replace
  local res_data = getAllData(input.org_id, input.datef, input.datet, input.crm_id, input.kcrm_id, input.tag_id, input.product_id, input.stock_id, input.moadian_code, input.factor_id, input.send_status)
  local res_str =""
  local count_send =0
  for i,v in ipairs (res_data) do 
        teamyar.write_log(" v.status---555------------".. v.status)
    if  v.status == "ارسال نشده" 
      or  v.status == "خطا"
      or  v.status == "درخواست ابطال"
      or  v.status == "ابطال"
      or  v.status == "رد شده [ارسالی]"
      or  v.status == "ابطال شده [ارسالی]"
      or  v.status == "ناموفق / خطا در پردازش [ارسالی]"
      or  v.status == "پیدا نشده [ارسالی]"
      or  v.status == "تنظیمات پیکربندی خالی [ارسالی]"
      or  v.status == "نامشخص/خطا [ارسالی]"      
      then
    local ms, st = savefactor(v.id, date_replace,input.org_id)-- .."<hr>"
      res_str = res_str.. v.id.." --- "..ms.." وضعیت در سامانه: "..st.."<hr>"
      count_send = count_send +1
    end 
  end
  res_str = res_str.." تعداد  "..count_send.."  فاکتور به سامانه مودیان ارسال شد  ."
  if not _HISTORY_TABLE_OK then
    res_str = res_str.."<br><span style='color:#c62828;'>⚠ جدول moadianz_fact_history ساخته نشد — تاریخچه ثبت نخواهد شد.</span>"
  end
  local res_data={msg=res_str}
  teamyar.write_result(json.encode(res_data))
  elseif type ~= nil and type == 13 then
  local input = teamyar.get_input()
  local date_replace = input.date_replace
  local res_data = getAllData(input.org_id, input.datef, input.datet, input.crm_id, input.kcrm_id, input.tag_id, input.product_id, input.stock_id, input.moadian_code, input.factor_id, input.send_status)
  local res_str = ""
  local count_send = 0
  for i,v in ipairs (res_data) do 
    teamyar.write_log(" v.status---------------".. v.status)
    if  v.status == "ارسال شده"
	  or  v.status == "رد شده [ارسالی]"
      or  v.status == "در حال پردازش [ارسالی]"
      or  v.status == "پیش‌نویس [ارسالی]"
      or  v.status == "ارسال شده [ارسالی]"
      or  v.status == "در انتظار [ارسالی]"
      or  v.status == "نامشخص [ارسالی]"
      or  v.status == "خطادراستعلام [ارسالی]"
      or  v.status == "خطا در ارتباط [ارسالی]"
      or  v.status == "استعلام نشده [ارسالی]"
      or  v.status == "نامشخص/خطا [ارسالی]"
      or  v.status == "عدم ارتباط سامانه [ارسالی]"
      or  v.status == "درخواست ابطال"
      then
        if  v.referenceNumber ~= nil and #v.referenceNumber>0  then
          local ms, st = inqueryfactor(v.id, v.referenceNumber, date_replace,input.org_id)
          res_str = res_str.. v.id.." --- "..ms.." وضعیت در سامانه: "..st.."<hr>"
          count_send = count_send +1
        end 
    end 
  end
  res_str = res_str.." تعداد  "..count_send.."  فاکتور از سامانه مودیان استعلام گرفته شد  ."
  local res_data = {msg = res_str}
  teamyar.write_result(json.encode(res_data))
elseif type ~= nil and type == 14 then
  local input = teamyar.get_input()
  local fid = input.fid
          local q= [[SELECT ID, invoice_id, date, unic_id, ref_id, err, ststus, state, comment, type, ref_invoce_id, send_txt, get_txt FROM moadianz_fact_history WHERE invoice_id=]]..tonumber(fid)..[[ ORDER BY ID DESC]]
        teamyar.write_log("q---------------------------------------------"..q)
  local history_rows = {}
  if _HISTORY_TABLE_OK then
    pcall(function()
      db.use_db("0000000_bot")
      db.query({query =q})
      local function to_str(v)
        if v == nil then return "" end
        local ok, s = pcall(function() return "" .. v end)
        if ok then return s end
        return tostring(v)
      end
      local record = {}
      while db.query_fetch(record) do
           teamyar.write_log("record-----------"..json.encode(record))
       -- local d_fa = get_persian_datetime(tonumber(record[3]))
        table.insert(history_rows, {
          id = to_str(record[1]),
          invoice_id = to_str(record[2]),
          date_fa = tostring(record[3]),--d_fa,
          unic_id = to_str(record[4]),
          ref_id = to_str(record[5]),
          err = to_str(record[6]),
          ststus = to_str(record[7]),
          state = to_str(record[8]),
          comment = to_str(record[9]),
          type = to_str(record[10]),
          ref_invoce_id = to_str(record[11]),
          send_txt = to_str(record[12]),
          get_txt = to_str(record[13]),
        })
      end
      db.query_free()
      db.use_db("0000000")
    end)
  end
  
  for i,v in ipairs(history_rows) do 
    v.date_fa=get_persian_datetime(tonumber(v.date_fa))
  end 
      teamyar.write_log("history_rows-----------"..json.encode(history_rows))
  teamyar.write_result(json.encode({rows = history_rows, table_ok = _HISTORY_TABLE_OK}))
elseif type ~= nil and type == 15 then
  local input = teamyar.get_input()
  local fid = input.fid
  local referenceNumber = input.referenceNumber
  local date_replace = input.date_replace
  local org_id = input.org_id
  local unic_id = input.unic_id or ""
  local hid = tonumber(input.hid) or 0
  local botmsg, fact_st = inqueryfactor(fid, referenceNumber, date_replace, org_id, unic_id, hid)
  local msg = "شماره فاکتور:"..fid.."  "..botmsg.."<br> وضعیت در سامانه= "..fact_st
  local res_data = {msg = msg}
  teamyar.write_result(json.encode(res_data))
elseif type ~= nil and type == 16 then
  local input = teamyar.get_input()
  local fid = input.fid
  local referenceNumber = input.referenceNumber
  local date_replace = input.date_replace
  local org_id = input.org_id
  local unic_id = input.unic_id or ""
  local botmsg, fact_st = delfactor(fid, referenceNumber, date_replace, org_id, unic_id)
  local msg = "شماره فاکتور:"..fid.."  "..botmsg.."<br> وضعیت در سامانه= "..fact_st
  local res_data = {msg = msg}
  teamyar.write_result(json.encode(res_data))
elseif type ~= nil and type == 17 then
  local input = teamyar.get_input()
  local fid = input.fid
  local referenceNumber = input.referenceNumber
  local date_replace = input.date_replace
  local org_id = input.org_id
  local changes = input.changes
  local unic_id = input.unic_id or ""
  teamyar.write_log("type17 unic_id=["..tostring(unic_id).."] input_keys=["..json.encode(input).."]")
  local botmsg, fact_st = editfactor(fid, referenceNumber, date_replace, org_id, changes, unic_id)
  local msg = "شماره فاکتور:"..fid.."  "..botmsg.."<br> وضعیت در سامانه= "..fact_st
  local res_data = {msg = msg}
  teamyar.write_result(json.encode(res_data))
elseif type ~= nil and type == 18 then
  local input = teamyar.get_input()
  local fid = tonumber(input.fid)
  local rows = {}
  if fid == nil then
    teamyar.write_log("type:18 error: fid is nil, input.fid="..tostring(input.fid))
    teamyar.write_result(json.encode({rows=rows, error="fid is nil"}))
  else
    local ok, err = pcall(function()
      local query = [[
                      WITH DecimalDigits AS (
                        SELECT po.ORG_ID, ps.DECIMAL_COUNT DecimalCount,
                          (CASE WHEN COALESCE(ps.FEE_DECIMAL,0) = 0 THEN COALESCE(ps.DECIMAL_COUNT,0) ELSE COALESCE(ps.FEE_DECIMAL,0) END) DigitFee, ps.SHORT_NAME
                        FROM pa_organizations po
                        JOIN pa_symbols ps ON (po.BASE_CURRENCY = ps.ID AND po.ORG_ID = ps.ORG_ID)
                      )
                      SELECT pi.ID, pi.PRODUCT_ID, p.NAME,
                      (pi.QUANTITY/POW(10,COALESCE(sc.DECIMAL_NUM,0))) QUANTITY,
                      (pi.FEE/POWER(10,COALESCE(dd.DigitFee,0))) FEE
                      FROM sales_invoice_product pi
                      INNER JOIN wh_product p ON p.ID=pi.PRODUCT_ID
                      LEFT JOIN wh_stock_capacity sc ON p.CAPACITY_ID=sc.ID
                      LEFT JOIN sales_invoice i ON i.ID=pi.INVOICE_ID
                      LEFT JOIN DecimalDigits dd ON (i.ORG_ID = dd.ORG_ID AND dd.SHORT_NAME = (SELECT ps.SHORT_NAME FROM pa_symbols ps WHERE ps.ID = i.SYMBOL_ID LIMIT 1))
                      WHERE pi.INVOICE_ID=]]..fid..[[
                      ORDER BY pi.ID]]
      db.use_db("0000000")
      db.query({query=query})
      local record = {}
      while db.query_fetch(record) do
        table.insert(rows, {
          id = tonumber(record[1]),
          product_id = tonumber(record[2]),
          name = tostring(record[3]),
          quantity = tonumber(record[4]),
          fee = tonumber(record[5])
        })
      end
      db.query_free()
    end)
    if not ok then
      teamyar.write_log("type:18 DB error: "..tostring(err))
    end
    teamyar.write_result(json.encode({rows=rows, error=ok and "" or tostring(err)}))
  end
elseif type ~= nil and type == 101 then
  local result = excel()
  teamyar.write_result(json.encode(result));
elseif type ~= nil and type == 102 then
  local result = print()
  teamyar.write_result(json.encode(result));
else
  if not _HISTORY_TABLE_OK then
    teamyar.write_log("خطا: جدول moadianz_fact_history ساخته نشد یا به دیتابیس بات وصل نشد.")
  end
  local responseResReport = install_res.resReport(getTableConfig());
  teamyar.write_result(responseResReport);
end




