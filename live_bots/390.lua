-- botName = ComprehensiveSales
-- creator = Mozhgan Rajabali
-- date = 25/09/1403
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
        query = teamyar.get_attachment("query_comprehensive_sales_final.txt") ,
        params = {}
    };

    ---- Select
    dataQuery.query = string.gsub(dataQuery.query,"{{select}}", getQuery_select(queryType));

    ---- invoice Filter
    local state = getInput("state");
    local city = getInput("city");
    local wherestr = " 1=1 "
    local org = getInput("org_id");
    local customer = getInput("customer");
    teamyar.write_log('مشتری' .. json.encode(customer))
    local customer_category = getInput("customerCategory");
    local from_date = getInput("from_date") ;
    local to_date = getInput("to_date") ;
   -- to_date= to_date +999999999999;
    if to_date ~= nil  and to_date ~= "" then 
	to_date=to_date + (24 * 60 * 60 * 10000000);
end
    local sales_center = getInput("salesCenter");
    local sales_agent = getInput("salesAgent");
    local stock = getInput("stock");
    local invoice_type = getInput("invoiceType");
    local invoice_status = getInput("invoiceStatus");
    local product = getInput("product");
    local country = getInput("country");
    local gruop_product = getInput("group_product");
    local invoice_number = getInput("invoiceNumber");
    local is_deleted = getInput("del_status");
  
  teamyar.write_log(json.encode(customer))
 teamyar.write_log("sales_center----"..json.encode(sales_center))
    if (org ~= nil and org[1] ~= nil and org[1]["id"] ~= nil  or invoice_number ~= nil ) then
       -- where_org_ids
     dataQuery.query , dataQuery.params  = queryTools.where:init()
 --    :addIn("po.org_id" , org)
     .run( dataQuery.query ,  dataQuery.params , "{{where_po.org_id}}");
   dataQuery.query , dataQuery.params  = queryTools.where:init()
  --  :addIn("pc.org_id" , org)
    
     .run( dataQuery.query ,  dataQuery.params , "{{where_pc.org_id}}");
   dataQuery.query , dataQuery.params  = queryTools.where:init()
  --   :addIn("si.org_id" , org)
     .run( dataQuery.query ,  dataQuery.params , "{{where_si.org_id}}");

   dataQuery.query , dataQuery.params  = queryTools.where:init()
    -- :addIn("MODULE_PARENT_ID" , gruop_product)
     .run( dataQuery.query ,  dataQuery.params , "{{where_id}}");
    
    wherestr=wherestr..[[ and run_date  between  ]] ..from_date..[[ and ]]..to_date
    
     if  state ~= nil  and #state>0  then 
        if state[1].name ~=  nil then
            wherestr = wherestr .. [[ and addr.NEWSTATE  like N'%%]].. state[1].name ..[[%%' ]]
         end
      end 
      if  city ~=nil   and  #city >0 then 
          if  city[1].name  ~=  nil then
              wherestr = wherestr .. [[ and addr.NEWCITY  like N'%%]] .. city[1].name ..[[%%' ]]
         end
      end 
    
    
      local ids_sc = ""
 
  if type(sales_center) == "number"   then   
    ids_sc =sales_center
  else
    for i, v in ipairs(sales_center) do
      if v == 0 then
        ids_sc = v;
      end
      if  ids_sc == "" then
        ids_sc = ids_sc..tostring(v.id);
      else
        ids_sc = ids_sc..","..tostring(v.id);
      end
    end
  end
  if  ids_sc ~= nil and ids_sc ~= ""  then 
    wherestr=wherestr.. [[ and i.SALES_CENTER in (]].. ids_sc..[[) ]]
    end 
                          ---------------------------------------------------is_deleted
  if  is_deleted ~= nil  and #is_deleted>0 then 
    local is_deleted_lids = ""
    for i, v in ipairs(is_deleted) do
      if v.id~= nil then      
        if  is_deleted_lids == "" then
          is_deleted_lids = is_deleted_lids..tostring(v.id);
        else
          is_deleted_lids = is_deleted_lids..","..tostring(v.id);
        end
      end
    end
    if #is_deleted_lids>0 then 
   	 wherestr = wherestr..[[ and i.DELETED in  (]]..is_deleted_lids..[[) ]]
    end
  end 
    
    teamyar.write_log(wherestr)
    -- where_condition
    dataQuery.query , dataQuery.params  = queryTools.where:init({wherestr})
 :addIn("i.org_id" , org)
    :addIn("i.client_id" , customer)
    :addIn("(select group_concat(cc.REFERE_ID) from  crm_cross cc where  cc.client_id=i.client_id ) " , customer_category)
   -- :add("run_date" , ">=" , from_date)
  --  :add("run_date" , "<=" , to_date)
 --:addIn("SALES_CENTER" , sales_center)
    
    
    :addIn("i.SALES_AGENT" , sales_agent)
    :addIn("ip.stock_id" , stock)
    :addIn("i.Type" , invoice_type)
    :addIn("i.Status" , invoice_status)
    :addIn("ip.PRODUCT_ID" , product)
    :addIn("countryId" , country)
  
    :addLike("NEWSTATE" , state)
    :addLike("NEWCITY" , city)
      :addIn("i.INVOICE_ID" ,invoice_number )
      --  teamyar.write_log("9*0000**** ===" .. dataQuery.params)
    .run( dataQuery.query ,  dataQuery.params , "{{where_condition}}");

 end
  
    ---- page Number Query
  teamyar.write_log("9getQuery_page ===" .. getQuery_page(queryType , pageFrom , perPage , pageTo))
    dataQuery.query = string.gsub(dataQuery.query,"{{slicePageNumber}}", getQuery_page(queryType , pageFrom , perPage , pageTo));
     teamyar.write_log("9ppppppppa ==="..json.encode( dataQuery.params))
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
        teamyar.write_log("slicePageNumber=".. slicePageNumber)
    end
    
    return slicePageNumber;
end
function getQuery_result(queryType , dataQuery)
    local resultExp = nil;
   --   teamyar.write_log("77777777 ===" .. dataQuery.query)
    db.query(dataQuery)
 --  teamyar.write_log("99999999 ===" .. dataQuery.query)
    local record={};
     if queryType == _QUERY_TYPE._TYPE_TOTAL_COUNT then
        record = db.query_fetch();
        resultExp = record[1];
-- teamyar.write_log("total ===" .. json.encode(resultExp))
    
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
        {show= true ,    key = "id"                   , value= "id" } ,
        {show= true ,    key = "invoice_number"           , value= "invoice_number"  , type="link"  , link="/?page=/sales/invoice/view_invoice/{{id}}"          ,params= {"id"}} ,
        {show= true ,    key = "run_date"                     , value= "run_date"  , type="date" } ,
        {show= true ,    key = "FloatName"                     , value= "FloatName"} ,
        {show= true ,   key = "CenterName"                     , value= "CenterName"} ,
        {show= true ,   key = "AgentName"                     , value= "AgentName"} ,
        {show= true ,   key = "InvoiceType"                     , value= "InvoiceType"} ,
        {show= true ,   key = "CODE"                     , value= "CODE"} ,
        {show= true ,   key = "client_name"                     , value= "client_name"} ,
        {show= true ,   key = "full_code"                     , value= "full_code"} ,
        {show= true ,   key = "product_name"                     , value= "product_name"} ,
        {show= true ,    key = "stock_name"                     , value= "stock_name"} ,
        {show= true ,    key = "GroupProduct"                     , value= "GroupProduct"} ,
        {show= true ,    key = "unit_name"                     , value= "unit_name"} ,
        {show= true ,    key = "QUANTITY"                     , value= "QUANTITY" ,  type="price" , sum=true} ,
        {show= true ,    key = "QUANTITY_SEC"                     , value= "QUANTITY_SEC" ,  type="price" , sum=true} ,
        {show= true ,    key = "fee"                     , value= "fee" , type="price", sum=true } ,
        {show= true ,    key = "amountt"                     , value= "amountt" , type="price", sum=true } ,
        {show= true ,    key = "discount"                     , value= "discount" , type="price", sum=true } ,
        {show= true ,    key = "ValueAdd"                     , value= "ValueAdd" , type="price", sum=true } ,
        {show= true ,    key = "Tax"                     , value= "Tax" , type="price", sum=true } ,
        {show= true ,    key = "Toll"                     , value= "Toll" , type="price", sum=true } ,
       -- {show= true ,    key = "VALUE_ADD"                     , value= "VALUE_ADD" , type="price", sum=true } ,
        {show= true ,    key = "AMOUNT"                     , value= "AMOUNT" , type="price", sum=true } ,
        {show= true ,    key = "NEWCOUNTRY"                     , value= "NEWCOUNTRY"} ,
        {show= true ,    key = "NEWCITY"                     , value= "NEWCITY"} ,
        {show= true ,    key = "NEWSTATE"                     , value= "NEWSTATE"} ,
      --  {show= true ,    key = "Month"                     , value= "Month"} ,
      --  {show= true ,    key = "Year"                     , value= "Year"} ,
        {show= true ,    key = "clientID"                     , value= "clientID"} ,
        {show= true ,    key = "tin"                     , value= "tin"} ,
        {show= true ,    key = "EXPIRE_SETTLEMENT_DATE"                     , value= "EXPIRE_SETTLEMENT_DATE" , type="date"} ,
        {show= true ,    key = "NATIONAL_CODE"                     , value= "NATIONAL_CODE"} ,
         {show= true ,    key = "ADDRESS"                     , value= "ADDRESS"} ,
         {show= true ,    key = "POSTAL_CODE"                     , value= "POSTAL_CODE"} ,
         {show= true ,    key = "MOBILE"                     , value= "MOBILE"} ,
      --  {show= true ,    key = "REFFERE_ID"                     , value= "REFFERE_ID"} ,
        {show= false ,    key = "org_id"                     , value= "org_id"} ,
        {show= false ,    key = "SALES_CENTER"                     , value= "SALES_CENTER"} ,
        {show= false ,    key = "stockID"                     , value= "stockID"} ,
        {show= false ,    key = "productID"                     , value= "productID"} ,
         {show= true ,    key = "note"                     , value= "note"} ,
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
      teamyar.write_log("9pppppppp** ===" .. from)
     teamyar.write_log("***_PAR_PAGE** ===" .. _PAR_PAGE)
    local values  = getData(_QUERY_TYPE._TYPE_PAGE_REPORT , from , _PAR_PAGE);
    local total  = getData(_QUERY_TYPE._TYPE_TOTAL_COUNT)

    local sums  = getData(_QUERY_TYPE._TYPE_TOTAL_SUM , from , _PAR_PAGE);
 -- teamyar.write_log(json.encode(sums))

    return install_res.resTable(repId , headers , values  , total , _PAR_PAGE , from ,sums);
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
-----------------------------------------------
function queryResultAcl(select_query,user_param)
  db.use_db("0000000")
  local params = {
    query = select_query,
    params = user_param
  }
  db.query(params);
  local res_text={};
  local record={};
  local i=0;
  while db.query_fetch(record) do
    local tmp=record;
    table.insert(res_text, {id = i, name = record[1], type =1});
   i=i+1;
  end
  db.query_free();
 -- teamyar.write_log(json.encode('eeeeeeeeeeeeee=======' .. res_text));
  return res_text;
end
-----------------------------------------------------------
function queryInvoiceAcl(select_query,user_param)
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
-----------------------------------------------------
function invoiceNumberAcl(data)
  local query_param = [[ select distinct INVOICE_ID as NewID,INVOICE_ID   from sales_invoice ]]
 if data.search ~= nil and #data.search > 0 then
     query_param = query_param..[[  where INVOICE_ID like N'%]]..data.search..[[%' ]]
  end
query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
teamyar.write_result(json.encode(queryInvoiceAcl(query_param, {})));
end
----------------------------------------------
function getAclState(data)
  teamyar.write_log("kkkk"..json.encode(data.data.search))
  local query_param = [[  select  distinct State from profile_user_address  where State <> '' ]];

  if data.data.search ~= nil and #data.data.search > 0 then

    query_param = query_param..[[  and State like N'%]]..data.data.search..[[%' ]]
  end
 
   query_param = query_param .. string.format(" limit %d,%d ", data.data.from, data.data.count);  
  local uu=queryResultAcl(query_param, {})
  teamyar.write_result(json.encode(uu));
end
------------------------------------------------------
function getAclCity(data)
  local query_param = [[ select distinct CITY from profile_user_address  where CITY <> '' ]]
  
  if data.data.search ~= nil and #data.data.search > 0 then
    query_param = query_param..[[  and CITY like N'%]]..data.data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.data.from, data.data.count);   
   local tt=queryResultAcl(query_param, {})
  teamyar.write_result(json.encode(tt));
end
--------------------------------------------
--- manager
--------------------------------------------
local type = getInput("type");
-- getState
if type ~= nil and type == 13 then
    local result = getAclState(teamyar.get_input())
 elseif input.type == 16 then 
  invoiceNumberAcl(input.data)
  --getCity
elseif type ~= nil and type == 14 then
    local result = getAclCity(teamyar.get_input())
  --  teamyar.write_result(json.encode(result));
    
--- get report
elseif type ~= nil and type == 100 then
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
