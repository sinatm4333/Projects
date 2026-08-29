-- botName = Sales report by invoice
-- creator = Mozhgan Rajabali
-- date = 21/05/1404
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
local res =  teamyar.get_user_info();  
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
        query = teamyar.get_attachment("query_sales_report_by_invoice.txt") ,
        params = {}
    };

    ---- Select
    dataQuery.query = string.gsub(dataQuery.query,"{{select}}", getQuery_select(queryType));

-- ----------------------------------------------------------------
    ---- invoice Filter
    local org = getInput("org_id");
    local customer = getInput("customer");
    local from_date = getInput("from_date") ;
    local to_date = getInput("to_date") ;
    local invoice_type = getInput("invoiceType");
    local invoice_status = getInput("invoiceStatus");
    local invoice_number = getInput("invoiceNumber");
    local is_send = getInput("send_status");
    local user_type = getInput("user_type");
    local bill_type = getInput("bill_type");
    local note_str = getInput("note");
    local float = getInput("float");  
    local center = getInput("center");  
    local project = getInput("project");  
  -- teamyar.write_log("توضیحاااات" .. json.encode(note_str))
    local wherestr = " i.DELETED = 0 "
  
    if (org ~= nil and org[1] ~= nil and org[1]["id"] ~= nil ) then
    wherestr=wherestr..[[ and i.run_date  between  ]] ..from_date..[[ and ]]..to_date..[[ ]]
    
    if note_str ~= nil and note_str[1] ~= nil and note_str[1]["id"] ~= nil then
      wherestr = wherestr .. [[ and  i.note =']]..note_str[1]["name"]..[[']]
     --   teamyar.write_log("yyyyyyyyyy===" .. json.encode(wherestr))

    end
    -- where_condition
    dataQuery.query , dataQuery.params  = queryTools.where:init({wherestr})
    :addIn("i.org_id" , org)
    :addIn("i.client_id" , customer)
   -- :add("i.run_date" , ">=" , from_date)
  -- :add("i.run_date" , "<=" , to_date)
    :addIn("i.TYPE" , invoice_type)
    :addIn("i.status" , invoice_status)
    :addIn("i.ID" ,invoice_number ) 
    :addIn("i.moadian_status" ,is_send ) 
     :addIn("pui.USER_TYPE" ,user_type ) 
     :addIn("i.bill_type" ,bill_type ) 
     :addIn("pf.ID" ,float ) 
    :addIn("i.SALES_CENTER" ,center ) 
    :addIn("pp.ID" ,project ) 
    .run( dataQuery.query ,  dataQuery.params , "{{where_condition}}");

 end
  
    ---- page Number Query
    dataQuery.query = string.gsub(dataQuery.query,"{{slicePageNumber}}", getQuery_page(queryType , pageFrom , perPage , pageTo));
   --  teamyar.write_log("9ppppppppa ==="..json.encode( dataQuery.params))
    ---- Execute Query
--   teamyar.write_log("9******** ===" .. dataQuery.query)
   local result =  getQuery_result(queryType , dataQuery);
   result= json.encode(result)
   result = string.gsub(result,"filter_natural",translateWord("filter_natural")) 
   result = string.gsub(result,"filter_legal",translateWord("filter_legal"))  
   result = string.gsub(result,"None",translateWord("None")) 
   result = string.gsub(result,"Type_1",translateWord("Type_1")) 
   result = string.gsub(result,"Type_2",translateWord("Type_2")) 
   result = string.gsub(result,"Type_3",translateWord("Type_3"))   
   result = string.gsub(result,"NOTSENT",translateWord("NOTSENT"))
   result = string.gsub(result,"SENT",translateWord("SENT"))
  
  return json.decode(result)
  -- teamyar.write_result("9******** ===" .. dataQuery.query)
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
     --   teamyar.write_log("slicePageNumber=".. slicePageNumber)
    end
    
    return slicePageNumber;
end
function getQuery_result(queryType , dataQuery)
    local resultExp = nil;
    db.query(dataQuery)
   teamyar.write_log("99999999 ===" .. dataQuery.query)
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
              {show= true ,    key = "invoice_number"                     , value= "invoice_number"  , type="link"  , link="/?page=/sales/invoice/view_invoice/{{invoice_number}}"          ,params= {"invoice_number"}} ,   
              {show= true ,    key = "INVOICE_ID"                     , value= "INVOICE_ID"  } ,  
              {show= true ,    key = "run_date"                     , value= "run_date"  , type="date" } ,  
              {show= true ,   key = "Client_ID"                     , value= "Client_ID"} ,
              {show= true ,    key = "client_name"                     , value= "client_name" , type="link"  , link="/?page=/crm/client/edit/{{Client_ID}}"          ,params= {"Client_ID"}} ,
              {show= true ,    key = "Tin_or_NATIONAL_CODE"                     , value= "Tin_or_NATIONAL_CODE"} ,
              {show= true ,    key = "user_type"                     , value= "user_type"} ,
              {show= true ,    key = "tedad_kala"                     , value= "tedad_kala"} ,
              {show= true ,    key = "Amount_before_discount"                     , value= "Amount_before_discount" ,type="price" , sum=true} ,
              {show= true ,    key = "DISCOUNT"                     , value= "DISCOUNT" ,type="price" , sum=true} ,
              {show= true ,    key = "Amount_after_discount"                     , value= "Amount_after_discount", type="price" , sum=true} ,
              {show= true ,    key = "ValueAdd"                     , value= "ValueAdd" ,type="price" , sum=true} ,
              {show= true ,    key = "AMOUNT"                     , value= "AMOUNT" ,type="price" , sum=true} ,
              {show= true ,    key = "vaziat_moadian"                     , value= "vaziat_moadian"} , 
              {show= true ,    key = "bill_type"                     , value= "bill_type"} ,
              {show= true ,    key = "floatName"                     , value= "floatName"} ,
              {show= true ,    key = "CenterName"                     , value= "CenterName"} ,  
              {show= true ,    key = "ProjectName"                     , value= "ProjectName"} , 
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
--------------------------------------------------
function queryNoteAcl(select_query,user_param)
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
    local i = 1;
    table.insert(res_text, {id = i, name = record[1], type =1});
    i = i+1;
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
-----------------------------------------------------
function noteAcl(data)
  local query_param = [[ select NOTE from sales_invoice ]]
 if data.search ~= nil and #data.search > 0 then
     query_param = query_param..[[  where NOTE like N'%]]..data.search..[[%' ]]
  end
query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
teamyar.write_result(json.encode(queryNoteAcl(query_param, {})));
end
----------------------------------------------------------------------------
function floatAcl(data)
  local query_param = [[select distinct ID,CONCAT(pf.Name,' - ',pf.Code)FuulName  from pa_floating   pf  where pf.VOUCHER_ALLOW = 1 
                                      ]]
 if data.search ~= nil and #data.search > 0 then
     query_param = query_param..[[  and  CONCAT(pf.Name,' - ',pf.Code)  like N'%]]..data.search..[[%' ]] 
  end
query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
teamyar.write_result(json.encode(queryInvoiceAcl(query_param, {})));
end
----------------------------------------------------------------------------
function centerAcl(data)
  local query_param = [[select distinct si.SALES_CENTER,pc.NAME from sales_invoice  si  join pa_center  pc  on(pc.ID = si.SALES_CENTER and pc.ORG_ID = si.ORG_ID)
                                      ]]
 if data.search ~= nil and #data.search > 0 then
     query_param = query_param..[[  where  pc.NAME  like N'%]]..data.search..[[%' ]] 
  end
query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
teamyar.write_result(json.encode(queryInvoiceAcl(query_param, {})));
end
-----------------------------------------------------------------------
function projectAcl(data)
  local query_param = [[select distinct ID,CONCAT(pp.Name,' - ',pp.Code)FullName from pa_project  pp  where pp.VOUCHER_ALLOW = 1
                                      ]]
 if data.search ~= nil and #data.search > 0 then
     query_param = query_param..[[  and  CONCAT(pp.Name,' - ',pp.Code)  like N'%]]..data.search..[[%' ]] 
  end
query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
teamyar.write_result(json.encode(queryInvoiceAcl(query_param, {})));
end
--------------------------------------------
--- manager
--------------------------------------------
local type = getInput("type");
 if input.type == 5 then 
  invoiceNumberAcl(input.data)
elseif input.type == 9 then 
  noteAcl(input.data)
 elseif type ~= nil and type == 10 then
    floatAcl(input.data)
 elseif type ~= nil and type == 11 then
    centerAcl(input.data)
   elseif type ~= nil and type == 12 then
    projectAcl(input.data)
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
