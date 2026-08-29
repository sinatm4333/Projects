-- botName = CustomersWhoDoNotHaveASalesInvoice
-- creator = Mozhgan Rajabali
-- date = 15/10/1403
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
--install_res.resCash();


--------------------------------------------
--- data
--------------------------------------------
function getData(queryType , pageFrom , perPage , pageTo )
    ---- init Query
    local dataQuery = {
        query = teamyar.get_attachment("query_customers_dont_have_sales_invoice.txt") ,
        params = {}
    };

    ---- Select
     dataQuery.query = string.gsub(dataQuery.query,"{{select}}", getQuery_select(queryType));

    ---- invoice Filter
    local org = getInput("org_id");
    local customer = getInput("customer");
    local invoice_type = getInput("invoiceType");
    
   if (org ~= nil and org[1] ~= nil and org[1]["id"] ~= nil) then
    dataQuery.query , dataQuery.params  = queryTools.where:init()
            :addIn("pc.ORG_ID" , org)
            :addIn("Client_Id" , customer)
            :addIn("si.type" , invoice_type)
           
          
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
        {show= true ,    key = "Client_Id"                   , value= "Client_Id" } ,
        {show= true ,    key = "name"                    , value= "name" } ,
        {show= false ,   key = "ORG_ID"                        , value= "ORG_ID"} ,
        {show= true ,   key = "orgName"                 , value= "orgName"} ,
        {show= true ,   key = "CODE"                   , value= "CODE"} ,
        {show= true ,   key = "NOTE"                   , value= "NOTE"} ,
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
    local total  = getData(_QUERY_TYPE._TYPE_TOTAL_COUNT);

   -- local sums  = getData(_QUERY_TYPE._TYPE_TOTAL_SUM , from , _PAR_PAGE);

    return install_res.resTable(repId , headers , values  , total , _PAR_PAGE , from , sums);
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
-------------------------------------------
function customerAcl(data)
    local query = teamyar.get_attachment("query_customer_dont_have_sales_invoice_acl.txt");
    if data.data.search ~= nil and #data.data.search > 0 then
       query = query .. [[  where name like N'%]].. data.data.search ..[[%' ]]
    end
    teamyar.write_log(query)
    local dataQuery = {
      query= query,
      params={}
    }
    db.query(dataQuery)
    
    local record={};
    local res = {};
    while db.query_fetch(record) do
        table.insert(res,{id = record[1],name = record[2],type =1})
    end
    db.query_free();
    teamyar.write_result(json.encode(res));
  end


--------------------------------------------
--- manager
--------------------------------------------
local type = getInput("type");
--- get report
if type ~= nil and type == 2 then 
    customerAcl(teamyar.get_input())
    
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
