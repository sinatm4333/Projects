-- botName = chap_module_from_task_workflow
-- creator = mehdi-marefiyan
-- date = 12/11/2024
-- version= 0.2

local _BAT_RES_PATH = "2/res_v2";
-------
function runCodes(codeTxt)
    local loadedFunction, errorMessage = load(codeTxt)
    if loadedFunction then
        loadedFunction();
    else
        teamyar.write_log("Error: " .. errorMessage);
    end
end

--- CONFIG DATA
local _PAR_PAGE= 25
local _QUERY_TYPE = {
    _TYPE_TOTAL_COUNT = 2 ,
    _TYPE_PAGE_REPORT = 3 ,
    _TYPE_PAGE_EXCEL = 4 ,
    _TYPE_PAGE_PRINT = 5
}

--- install [RES]
local userInputs = teamyar.get_input()
userInputs.res_type = "codes";
userInputs.config = json.decode(teamyar.get_attachment("data.txt"));
local responseRes = teamyar.run_command(_BAT_RES_PATH ,userInputs);
if responseRes ~= nil then
    responseRes = json.decode(responseRes)
    for i = 1 , #responseRes, 1 do
        runCodes(responseRes[i])
    end
end

--- data header
function getTableConfig_formData(params)

    local formData = nil;
    if params ~= nil and params[1] ~= nil and params[1].form_data ~= nil then
        formData = params[1].form_data;
    end
    return formData;
end
function getTableConfig(params)
    local  todoCategory , todoWorkFlow  , todoTopic , todoFields  = getValueConfigs_todo();
    local totalFixFields = aclFixFields();

    local data = {
        {show= false     , key = "client_id"  } ,
        {show= false     , key = "product_id" } ,
        {show= false     , key = "form_data"  } ,
        {show= true      , key = "task_id"   , value= "_table_task_id"  , type="method" , name="selectForEdictTaskInTable" , params= {"task_id"}}
    }

    if todoFields ~= nil then
        local formData = getTableConfig_formData(params);

        for i = 1 , #todoFields , 1 do
            local itemField = todoFields[i];

            local exist = false;
            for x = 1 , #totalFixFields, 1 do
                local field = totalFixFields[x];
                if field ~= nil and field.id == itemField and field.col ~= nil then
                    table.insert(data ,field.col);
                    exist = true;
                    break;
                end
            end
            if exist == false then
                if formData ~= nil then
                    formData = toTable(formData);

                    for key, dataKey in pairs(formData) do
                        if key== itemField and  dataKey ~= nil and dataKey.title ~= nil then

                            local paramTitle = dataKey.title;
                            local paramShow = false;
                            if dataKey.show ~= nil then
                                paramShow = dataKey.show;
                            end
                            table.insert(
                                    data ,
                                    {
                                        show = true ,
                                        key = key ,
                                        value = paramTitle
                                    });
                            break;
                        end
                    end

                end
            end
        end
    end
    return data;
end

--- data
function getData(queryType , pageFrom , perPage , pageTo , taskId )

    local dataQuery = {
        query = teamyar.get_attachment("query_select_task_data.txt") ,
        params = {}
    };

    ---- Select
    dataQuery.query = string.gsub(dataQuery.query,"{{select}}", getQuery_select(queryType));

    ---- whereWorkFlow
    local todoCategory , todoWorkFlow  , todoTopic , todoFields = getValueConfigs_todo()
    dataQuery.query , dataQuery.params  = queryTools.where:init()
            :add("id" , "=", todoWorkFlow)
            .run( dataQuery.query ,  dataQuery.params , "{{whereWorkFlow}}");

    ---- whereTask
    local dateFrom = getInput("dateFrom");
    local dateTo = getInput("dateTo");
    dataQuery.query , dataQuery.params  = queryTools.where:init()
            :add("tt.T_START_DATE" , ">=" , dateFrom)
            :add("tt.T_START_DATE" , "<=" , dateTo)
            :add("tt.id" , taskId)
            .run( dataQuery.query ,  dataQuery.params , "{{whereTask}}");

    ---- whereParam
    local todoType = getInput("todo_type");
    dataQuery.query , dataQuery.params  = queryTools.where:init()
            :addIn("param_print_type" , todoType)
            .run( dataQuery.query ,  dataQuery.params , "{{whereParam}}");

    ---- page Number Query
    dataQuery.query = string.gsub(dataQuery.query,"{{slicePageNumber}}", getQuery_page(queryType , pageFrom , perPage , pageTo));

    ---- Execute Query
    return getQuery_result(queryType , dataQuery);
end

--- query select
function getQuery_select(queryType)
    if queryType == _QUERY_TYPE._TYPE_TOTAL_COUNT then
        return getTableConfig_count()
    else
        return getTableConfig_select();
    end
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
function getTableConfig_header(params)
    local headers = {};
    local totalHeader = getTableConfig(params);

    for i = 1, #totalHeader , 1 do
        local itemHeader = totalHeader[i];
        if itemHeader.show ~= nil and itemHeader.show == true then
            table.insert(headers ,itemHeader );
        end
    end
    return headers;
end

--- query page init
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

--- query execute
function getQuery_resultRows(record)
    local itemRow = {};
    local columns = getTableConfig();
    for i = 1, #columns , 1 do
        local itemColumns = columns[i];
        if itemColumns.key ~= nil then
            itemRow[itemColumns.key] = record[i];
        end
    end
    return itemRow;
end
function getQuery_result(queryType , dataQuery)
    local resultExp = nil;

    db.query(dataQuery)
    local record={};
    if queryType == _QUERY_TYPE._TYPE_TOTAL_COUNT then
        record = db.query_fetch();
        resultExp = record[1];
    elseif queryType == _QUERY_TYPE._TYPE_INFO then
        record = db.query_fetch()
        resultExp = getQuery_resultRows(record)
    else
        resultExp = {};
        while db.query_fetch(record) do
            local itemRow = getQuery_resultRows(record)
            table.insert(resultExp, itemRow)
        end

        resultExp = getQuery_result_addFormData(resultExp);
    end
    db.query_free();

    return resultExp;
end
function getQuery_result_addFormData(resultExp)
    if resultExp ~= nil then
        for i = 1 , #resultExp, 1 do
            local itemResult = resultExp[i];
            if itemResult ~= nil and itemResult.form_data ~= nil then
                local formData = toTable(itemResult.form_data)
                if formData ~= nil  then
                    for key, keyData in pairs(formData) do
                        local value = "";
                        if keyData.value_title ~= nil then
                            value = keyData.value_title
                        end
                        resultExp[i][key] = value;
                    end
                end
            end
        end
    end
    return resultExp;
end

--- Main
function main()
    local templateBtn = teamyar.get_attachment("template_tools.html");
    local extraTemplates = { tools = install_res.resTemplate(templateBtn) };
    local responseResReport = install_res.resReport(getTableConfig() , extraTemplates);
    return responseResReport;
end

--- Report
function report()
    return {
        {
            name = "table" ,
            title = "جدول" ,
            report = getTableSectionOne();
        }
    };
end
function getTableSectionOne()
    local repId = getInput("rep_id");
    local from = getInput("page");
    local values  = getData(_QUERY_TYPE._TYPE_PAGE_REPORT , from , _PAR_PAGE);
    local total  = getData(_QUERY_TYPE._TYPE_TOTAL_COUNT);
    local headers = getTableConfig_header(values);
    return install_res.resTable(repId , headers , values  , total , _PAR_PAGE , from );
end

--- excel
function excel()
    local excelFileName = getInput("excel_file_name");
    local excelFormPage = getInput("excel_from_page");
    local excelToPage = getInput("excel_to_page");
    local excelPerPage= getInput("excel_per_page");
    local values = getData(_QUERY_TYPE._TYPE_PAGE_EXCEL ,  excelFormPage , excelPerPage , excelToPage)
    local headers = getTableConfig_header(values);
    return install_res.resExcel( headers , values , excelFileName);
end

--- print
function print()
    local values = getData(_QUERY_TYPE._TYPE_PAGE_PRINT)
    local headers = getTableConfig_header(values);
    return install_res.resPrint( headers , values);
end

--- template step Tasks data
function getTemplateStepTaskData()
    local taskId =  getInput("taskId")
    local taskData =  getTaskSelected(taskId);
    if taskData ~= nil then
        local template = teamyar.get_attachment("template_task_steps.html");
        local resultTemplate = install_res.resTemplate(template);
        if resultTemplate ~= nil  then
            resultTemplate = string.gsub(resultTemplate , "{{_task_data}}" , json.encode(taskData) );
            return resultTemplate;
        end
    end
    return "";
end

--- query get data task selected
function getTaskSelected(task_id)
    local resultExp = {};

    local dataQuery = {
        query = teamyar.get_attachment("query_search_tasks.txt") ,
        params = {}
    };

    dataQuery.query = string.gsub(dataQuery.query,"{{selects}}", " task_id , task_title  , date_start , date_end , customer_id , customer_name, product_id, product_name , form_data , workflow_id  , step_first_id  , form_data_schema , step_id , responsible_name");

    local todoCategory , todoWorkFlow  , todoTopic , todoFields = getValueConfigs_todo()
    dataQuery.query , dataQuery.params  = queryTools.where:init()
            :addIn("id" , todoWorkFlow)
            .run( dataQuery.query ,  dataQuery.params , "{{whereWorkFlow}}");

    dataQuery.query , dataQuery.params  = queryTools.where:init()
            :add("id" , "=" , task_id)
            .run( dataQuery.query ,  dataQuery.params , "{{whereTask}}");

    db.query(dataQuery)
    local record=db.query_fetch();
    if record ~= nil then
        resultExp = {
            task_id =  record[1], task_title = record[2],
            date_start = time.get_shamsi_str(record[3]), date_end = time.get_shamsi_str(record[4]),
            customer_id = record[5], customer_name =   record[6],
            product_id = record[7], product_name = record[8],
            form_data = record[9],
            workFlow_id =  record[10],
            step_first_id =  record[11],
            form_data_schema =  record[12],
            step_id =  record[13],
            responsible_name =  record[14],
        }
    end
    db.query_free();

    return resultExp;
end

--- template add
function addTaskWorkFlow()
    local resultExp = {
        status = true , error = "" , result = nil ,
        data = { workFlowId = nil , todoTopicId = nil };
    };

    local todoCategory , todoWorkFlow  , todoTopic , todoFields = getValueConfigs_todo()

    local customer = getInput("customer");
    local customerId = nil;
    local product = getInput("product");
    local product_str = getInput("product_str");
    local productResId = nil;
    local todoTypeSelected = getInput("todo_type_selected");

    local productCode = nil;
    if todoTypeSelected == 0 then

        if product_str ~= nil and product_str ~= "" then

            local productOrg , productParent , productSetting , productAccount , productUnit = getValueConfigs_product()
            local productData = {
                name = product_str ,
                org_id =  productOrg , unit_id =  productUnit, setting_id =  productSetting , parent_code = productParent ,
                account_info = { account_code = productAccount , } ,
                voucher_allow = 1 , pricing_method = 1 , product_type_id = 4
            }
            local responseProduct= teamyar.call_api( 17 , "/api/add_product",productData);
            if responseProduct ~= nil and responseProduct.success ~= nil and responseProduct.success == true then
                if responseProduct.data ~= nil and responseProduct.data.id ~= nil then
                    productResId = responseProduct.data.id;
                end
            else
                resultExp.error = resultExp.error .. translateWord("_error_add_task_product") .. "</br>";
                resultExp.status = false;
            end

        else
            resultExp.error = resultExp.error .. translateWord("_error_add_task_product") .. "</br>";
            resultExp.status = false;
        end
    else
        if product ~= nil and product[1] ~= nil and product[1].id ~= nil then
            productCode = product[1].id;
            productResId = getProductIdFromCode(productCode);
        else
            resultExp.error = resultExp.error .. translateWord("_error_add_task_product") .. "</br>";
            resultExp.status = false;
        end
    end

    if customer ~= nil and customer[1] ~= nil and customer[1].id ~= nil then
        customerId = customer[1].id;
    else
        resultExp.error = resultExp.error .. translateWord("_error_add_task_customer") .. "</br>";
        resultExp.status = false;
    end


    local taskTitle = getTaskName(customerId , productResId);
    if resultExp.status == true and taskTitle ~= nil  then
        local response = teamyar.call_api( 8 , "/api/todo/taskadd", {
            wf_id =  todoWorkFlow ,
            --crm_id =  customerId,
            topic_id = todoTopic,
            task_title = taskTitle
        });

        if response ~= nil and response.success ~= nil and response.success == true and response.data ~= nil and response.data.task_id ~= nil then
            local teakId =  response.data.task_id;
            local dataTask = getTaskSelected(teakId);
            if dataTask~= nil and dataTask.step_first_id ~= nil then
                local responseFormData = teamyar.call_api( 8 , "/api/todo/customform/update", {
                    id =  dataTask.step_first_id ,
                    type =  2,
                    form_data = json.encode({ print_type =todoTypeSelected , print_count="1" })
                });

                if responseFormData ~= nil and responseFormData.success ~= nil and responseFormData.success == true then
                    local responseAddCrm = teamyar.call_api( 1 , "/api/add_linkmodule", {
                        src_type =  3 ,  src_module_id = 8  , src_link_id = teakId,
                        dst_type =  1 ,  dst_module_id = 14 , dst_link_id = customerId,
                    });
                    local responseProduct = teamyar.call_api( 1 , "/api/add_linkmodule", {
                        src_type =  3 ,  src_module_id = 8  , src_link_id = teakId,
                        dst_type =  8 ,  dst_module_id = 17 , dst_link_id = productResId,
                    });
                    resultExp.result = response;
                else
                    resultExp.error = resultExp.error .. translateWord("_error_add_task_public") .. "</br>";
                end
            end
        end
    else
        resultExp.error = resultExp.error .. translateWord("_error_add_task_public") .. "</br>";
    end
    return resultExp;
end
function getTaskName(customerId , productId)
    local resultExp = nil;
    local todoCategory , todoWorkFlow  , todoTopic , todoFields = getValueConfigs_todo()
    if todoWorkFlow ~= nil and productId ~= nil and customerId ~= nil  then
        local dataQuery = {
            query = teamyar.get_attachment("query_select_task_name.txt") ,
            params = {}
        };

        table.insert(dataQuery.params , todoWorkFlow);
        dataQuery.query = string.gsub(dataQuery.query,"{{whereWorkFlow}}","where ID =?");

        table.insert(dataQuery.params , productId);
        dataQuery.query = string.gsub(dataQuery.query,"{{whereProduct}}","where ID =?");

        table.insert(dataQuery.params , customerId);
        dataQuery.query = string.gsub(dataQuery.query,"{{whereCustomer}}","where ID =?");

        dataQuery.query = string.gsub(dataQuery.query,"{{selects}}", " task_title");

        db.query(dataQuery);
        local record = db.query_fetch();
        if record ~= nil and record[1]~=nil then
            resultExp =  record[1];
        end
        db.query_free();
    end
    return resultExp;
end

--- custom form
function editCustomFormTask()
    local resultExp = { status = true , error = "" , msg = "" };
    local taskId =  getInput("taskId")
    local customForm =  getInput("customForm")
    if taskId ~= nil and type(taskId) == "number" and taskId >0 then
        local dataTask = getTaskSelected(taskId);
        if dataTask~= nil and dataTask.step_first_id ~= nil then
            local responseFormData = teamyar.call_api( 8 , "/api/todo/customform/update", {
                id =  dataTask.step_first_id ,
                type =  2,
                form_data = json.encode(customForm)
            });
            if responseFormData ~= nil and responseFormData.success ~= nil and responseFormData.success == true then
                resultExp.status = true;
                resultExp.msg = resultExp.msg .. translateWord("_msg_success_response") .. "</br>";
            else
                resultExp.error = resultExp.error .. translateWord("_error_add_task_public") .. "</br>";
            end
        else
            resultExp.error = resultExp.error .. translateWord("_error_add_task_public") .. "</br>";
        end
    else
        resultExp.error = resultExp.error .. translateWord("_error_add_task_public") .. "</br>";
    end
    return resultExp
end

--- task customer
function changeTaskCustomer()
    local taskId =  getInput("taskId");
    local customer =  getInput("customer");

    local responseProduct = teamyar.call_api( 1 , "/api/add_linkmodule", {
        dst_type =  8 ,  dst_module_id = 17 , dst_link_id = customer,
        src_type =  3,   src_module_id = 8 , src_link_id = taskId,
    });
    return getTemplateStepTaskData();
end

--- task product
function changeTaskProduct()
    local taskId =  getInput("taskId");
    local product =  getInput("product");

    local productId = getProductIdFromCode(product);

    local responseProduct = teamyar.call_api( 1 , "/api/add_linkmodule", {
        dst_type =  8 , dst_module_id = 17 , dst_link_id = productId,
        src_type =  3,  src_module_id = 8 , src_link_id = taskId,
    });
    return getTemplateStepTaskData();
end


--- field config
function aclFixFields()
    return {
        { id = "workflow_id" , name = "[field]" .. translateWord("_table_workflow_title") ,                        col = {show= true  , key = "workflow_title"     , value= "_table_workflow_title" } },

        { id = "task_title" , name = "[field]" .. translateWord("_table_task_title") ,                             col = {show= true  , key = "task_title"         , value= "_table_task_title"  , type="method" , name="selectForEdictTaskInTable" , params= {"task_id"} } },
        { id = "task_date" , name = "[field]" .. translateWord("_table_task_date") ,                               col = {show= true  , key = "task_date"          , value= "_table_task_date" , type= "date"} },
        { id = "task_end" , name = "[field]" .. translateWord("_table_task_end") ,                                 col = {show= true  , key = "task_end"           , value= "_table_task_end"  , type= "date"} },

        { id = "responsible_name" , name = "[field]" .. translateWord("_table_response_name") ,                    col = {show= true  , key = "responsible_name"   , value= "_table_response_name"} },

        { id = "client_name_profile" , name = "[field]" .. translateWord("_table_client_name_profile") ,           col = {show= true  , key = "client_name"        , value= "_table_client_name"  ,  type= "profile" , profile={"client_id"}  }  },
        { id = "client_name" , name = "[field]" .. translateWord("_table_client_name") ,                           col = {show= true  , key = "client_name"        , value= "_table_client_name"  } },

        { id = "product_code" , name = "[field]" .. translateWord("_table_product_code") ,                         col = {show= true  , key = "product_code"       , value= "_table_product_code"  ,  type= "link"  , link = "?page=/warehouse/product_add/view_product/{{product_id}}"  , params={"product_id"}    } , },
        { id = "product_name" , name = "[field]" ..  translateWord("_table_product_name") ,                        col = {show= true  , key = "product_name"       , value= "_table_product_name"  ,  type= "link"  , link = "?page=/warehouse/product_add/view_product/{{product_id}}"  , params={"product_id"}    } , },
    };
end

--- install code config
local codeConfig = teamyar.get_attachment("codeConfigs.lua");
runCodes(codeConfig)


--- manager
local type = getInput("type");
local result = "";
if  type == 100 then
    result = json.encode( report());
elseif type == 101 then
    result = json.encode(excel())
elseif type == 102 then
    result =json.encode(print())
elseif type == 1000 then
    result = getTemplateAddTask();
elseif type == 1001 then
    result = json.encode(addTaskWorkFlow());
elseif type == 2000 then
    result = getTemplateStepTaskData();
elseif type == 2001 then
    result = json.encode(editCustomFormTask() ) ;

elseif type == 2002 then
    result = changeTaskCustomer();
elseif type == 2003 then
    result = changeTaskProduct();

elseif type == 10001 then
    result = json.encode(aclTodoCategory());
elseif type == 10002 then
    result = json.encode(aclTodoTopic());
elseif type == 10003 then
    result = json.encode(aclListWorkFlows());
elseif type == 10004 then
    result = json.encode(aclCustomForm());

elseif type == 10011 then
    result = json.encode(aclOrg());
elseif type == 10012 then
    result = json.encode(aclProduct());
elseif type == 10013 then
    result = json.encode(aclProductSetting());
elseif type == 10014 then
    result = json.encode(aclAccount());
elseif type == 10015 then
    result = json.encode(aclListUnit());

elseif type == 100021 then
    result = json.encode(aclListProfiles());

else
    result = main();
end
teamyar.write_result(result);