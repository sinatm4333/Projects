-- botName = report_task_custom_form
-- creator = Mehdi_Maarefiyan
-- date = 4/07/2025
-- version= 0.1
------------------
_LICENSE_ID = 2;
_BAT_RES_PATH =  _LICENSE_ID.."/res_v2";


class_report = {

    _PAR_PAGE=25,
    _QUERY_TYPE = {
        _TYPE_TOTAL_SUM = 1 ,
        _TYPE_TOTAL_COUNT = 2 ,
        _TYPE_PAGE_REPORT = 3 ,
        _TYPE_PAGE_EXCEL = 4 ,
        _TYPE_PAGE_PRINT = 5 ,
    },

    ----------------------------------------------------------------------------------------
    --- init
    --------------------------------------------
    init= function(self)
        self:installResV2()
            :getTeamyarConfig():getListInputs()
        return self
    end ,

    ----------------------------------------------------------------------------------------
    --- install res_v2
    --------------------------------------------
    installResV2 = function(self)
        local userInputs = teamyar.get_input()
        userInputs.res_type = "codes";
        userInputs.config = json.decode(teamyar.get_attachment("data.txt"));
        local responseRes = teamyar.run_command(_BAT_RES_PATH ,userInputs);
        if responseRes ~= nil then
            responseRes = json.decode(responseRes)
            for i = 1 , #responseRes, 1 do
                local loadedFunction, errorMessage = load(responseRes[i])
                if loadedFunction then
                    loadedFunction();
                end
            end
        end
        return self;
    end ,

    --------------------------------------------
    --- get inputs
    --------------------------------------------
    getListInputs= function(self)
        self.type = getInput("type");

        self.repId = getInput("rep_id");
        self.from = getInput("page");

        self.excelFileName = getInput("excel_file_name");
        self.excelFormPage = getInput("excel_from_page");
        self.excelToPage = getInput("excel_to_page");
        self.excelPerPage= getInput("excel_per_page");

        self.task_title = getInput("task_title");
        self.task_category = getInput("task_category");
        self.task_status = getInput("task_status");
        self.task_state = getInput("task_state");
        self.task_date_from = getInput("task_date_from");
        self.task_date_to = getInput("task_date_to");

        return self;
    end ,

    --------------------------------------------
    --- get config teamyar
    --------------------------------------------
    getTeamyarConfig= function(self)
        local wf_id = getTeamyarConfigParam("task_work_flow_id", "table" , {});
        self.task_work_flow_id = nil;
        if wf_id ~= nil and wf_id[1] ~= nil and wf_id[1]["id"] ~= nil then
            self.task_work_flow_id =  wf_id[1]["id"];
        end

        self.task_work_flow_steps_id = getTeamyarConfigParam("task_work_flow_steps_id", "table" , {});

        local cf_list = getTeamyarConfigParam("list_custom_form", "table" , {});
        self.list_custom_form =  {};
        if cf_list ~= nil and type(cf_list) == "table" then
            for index, item in ipairs(cf_list) do

                if item ~= nil and
                        item.show_customform ~= nil and item.show_customform.value ~= nil and
                        item.key_customform ~= nil and item.key_customform.value ~= nil and
                        item.type_customform ~= nil and item.type_customform.key ~= nil and
                        item.name_customform ~= nil and item.name_customform.value ~= nil then

                    local itemShow = false;
                    if  item.show_customform.value == 1 then
                        itemShow = true
                    end

                    table.insert(self.list_custom_form,
                            {
                                show= itemShow ,
                                key = item.key_customform.value ,
                                value= item.name_customform.value ,
                                type_customform= item.type_customform.key ,
                            })
                end
            end
        end


        self.render_export_type = getTeamyarConfigParam("render_export_type", "number" , nil);

        return self;
    end ,




    --------------------------------------------
    --- query
    --------------------------------------------
    getData = function(self , headers , queryType , pageFrom , perPage , pageTo  )
        ---- init Query
        local dataQuery = {
            query = teamyar.get_attachment("query_report_task_custom_forms.txt") ,
            params = {}
        };

        ---- Select
        dataQuery.query = string.gsub(dataQuery.query,"{{select}}", self:getQuery_select(queryType));

        ---- where
        dataQuery.query , dataQuery.params  = queryTools.where:init({" id = ".. self.task_work_flow_id})
                .run( dataQuery.query ,  dataQuery.params , "{{whereWorkFlow}}");

        dataQuery.query , dataQuery.params  = queryTools.where:init()
                :addIn("ts.id" , self.task_work_flow_steps_id)
                .run( dataQuery.query ,  dataQuery.params , "{{whereWorkflowStep_forCF}}");

        dataQuery.query , dataQuery.params  = queryTools.where:init()
                :addIn("id" , self.task_title)
                :addIn("CATEGORY_ID" ,self.task_category )
                :addIn("STATE" ,self.task_state )
                :addIn("STATUS" ,self.task_status )
                :add("T_START_DATE" , ">=" , self.task_date_from)
                :add("T_START_DATE" , "<=" , self.task_date_to )
                .run( dataQuery.query ,  dataQuery.params , "{{whereTask}}");

        dataQuery.query , dataQuery.params  = queryTools.where:init()
                :addIn("tts.STEP_ID" , self.task_work_flow_steps_id)
                .run( dataQuery.query ,  dataQuery.params , "{{whereWorkflowStep_forValue}}");

        ---- page Number Query
        dataQuery.query = string.gsub(dataQuery.query,"{{slicePageNumber}}", self:getQuery_page(queryType , pageFrom , perPage , pageTo));

        ---- Execute Query
        local resultExp =  self:getQuery_result(queryType , dataQuery);

        teamyar.write_log((dataQuery.query))

        if queryType ~= self._QUERY_TYPE._TYPE_TOTAL_SUM and queryType ~= self._QUERY_TYPE._TYPE_TOTAL_COUNT  then
            ---- add custom form
            resultExp =  self:getData_customForm(queryType , resultExp);

            ---- render
            resultExp = self:getData_customForm_render(resultExp , headers);
        end

        return resultExp
    end ,



    --------------------------------------------
    --- Custom Form
    --------------------------------------------
    getData_customForm = function(self , queryType , resultExp)
        if resultExp ~= nil and type(resultExp) == "table" then
            for indexRow, row in ipairs(resultExp) do
                if row ~= nil and row.formData ~= nil then

                    local formData = toTable(row.formData);
                    if formData ~= nil and type(formData) == "table" then

                        for keyFD, valueFD in pairs(formData) do
                            local typeVal = nil;
                            local name = "---";
                            if self.list_custom_form ~= nil then
                                for index, data in ipairs(self.list_custom_form) do
                                    if data ~= nil and data.key ~= nil and data.key == keyFD then

                                        if data.type_customform ~= nil then
                                            typeVal = data.type_customform;
                                        else
                                            typeVal = "string"
                                        end

                                        if data.value ~= nil then
                                            name = data.value;
                                        end
                                        break;
                                    end
                                end
                            end



                            if typeVal ~= nil then
                                local value = "";
                                if valueFD ~= nil and valueFD.value ~= nil then
                                    value = valueFD.value
                                end

                                local ColVal = "---"
                                if typeVal == "string" then
                                    ColVal  = value;
                                elseif typeVal == "date_time" then
                                    ColVal  = self:convert_toFullDate(value);
                                elseif typeVal == "date" then
                                    ColVal  = self:convert_toDate(value);
                                elseif typeVal == "time_in_date" then
                                    ColVal  = self:convert_toTime(value);
                                elseif typeVal == "time" then
                                    ColVal  = self:convert_toTime_calc(value);

                                elseif typeVal == "table" then
                                    ColVal  = self:getData_customForm_table(queryType  , indexRow , keyFD ,value , name);
                                elseif typeVal == "acl" then
                                    ColVal  = self:getData_customForm_acl(queryType , indexRow , keyFD ,value , name);
                                end
                                resultExp[indexRow][keyFD]  = ColVal;


                            end
                        end

                    end
                end
            end
        end
        return resultExp;
    end,



    getData_customForm_render = function(self , data , headers)
        local resultExp = {};

        resultExp = self:getData_customForm_render_getBasicRow(data , headers);
        resultExp = self:getData_customForm_render_cartesianProduct(resultExp);

        return resultExp;
    end ,

    getData_customForm_render_getBasicRow = function(self , data , headers)
        local resultExp = {};

        for indexData, itemData in ipairs(data) do
            local row ={
                multi = {}
            };
            for key, value in pairs(itemData) do
                for indexHeader, itemHeader in ipairs(headers) do

                    if itemHeader~= nil
                            and itemHeader.show ~= nil and itemHeader.show == true then

                        if itemHeader.isCustomForm == nil and itemHeader.key == key  then
                            row[key] = value;
                        elseif itemHeader ~= nil and itemHeader.isCustomForm == true then
                            if (itemHeader.isList == nil or itemHeader.isList == false)  and itemHeader.reference == key  then
                                row[key] = value;
                            elseif itemHeader.isList ~= nil and itemHeader.isList == true  and itemHeader.reference == key then

                                local cfRows = {};
                                if value ~= nil and value.dataExp ~= nil and type(value.dataExp) == "table" then
                                    for cfIndex, cf in ipairs(value.dataExp) do
                                        local cfRow = {};
                                        if cf ~= nil then
                                            for cfKey, cfValue in pairs(cf) do
                                                if cfValue ~= nil and cfValue.content ~= nil then
                                                    cfRow[cfKey] = cfValue.content;
                                                end
                                            end
                                        end
                                        table.insert(cfRows , cfRow);
                                    end

                                end
                                row.multi[key] = cfRows;
                            end
                        end
                    end
                end
            end
            table.insert(resultExp , row);
        end

        return resultExp;
    end ,

    getData_customForm_render_cartesianProduct = function(self, data)
        local finalResult = {}

        if data ~= nil then
            for _, row in ipairs(data) do
                local multi = row.multi
                if multi and type(multi) == "table" then
                    local keys = {}
                    for k in pairs(multi) do table.insert(keys, k) end

                    local function recurse(i, current)
                        if i > #keys then
                            -- ترکیب ثابت با مقادیر current
                            local combined = {}
                            for k, v in pairs(row) do
                                if k ~= "multi" then
                                    combined[k] = v
                                end
                            end
                            for _, part in ipairs(current) do
                                for k, v in pairs(part) do
                                    combined[k] = v
                                end
                            end
                            table.insert(finalResult, combined)
                            return
                        end

                        local key = keys[i]
                        for _, value in ipairs(multi[key]) do
                            local nextCurrent = { table.unpack(current) }
                            table.insert(nextCurrent, value)
                            recurse(i + 1, nextCurrent)
                        end
                    end

                    recurse(1, {})
                else
                    table.insert(finalResult, row)
                end
            end
        end
        return finalResult
    end ,



    --------------------------------------------
    --- Custom Form Convertor
    --------------------------------------------
    getData_customForm_table = function(self , queryType  , index , keyFD , value , name)
        local resultExp = "---";

        local arrayId = {};
        local headers = {};
        local dataExp = {};
        if value ~= nil then
            value = toTable(value);

            for indexRow, row in ipairs(value) do
                if row ~= nil and type(row) == "table" then
                    for keyTable, valueTable in pairs(row) do
                        local keyData = explode(keyTable , "_customform");
                        if self.render_export_type == nil or self.render_export_type == 0 then
                            keyData = name.."_"..keyData;
                        end
                        local exist=false;
                        for keyHeader, itemHeader in pairs(headers) do
                            if itemHeader ~= nil and itemHeader.id ~= nil and keyData == itemHeader.id then
                                exist = true;
                                break;
                            end
                        end

                        if exist == false then
                            table.insert(arrayId , keyData)
                            table.insert(headers , { id = keyData , content =keyData})
                        end
                    end
                end
            end

            for indexRow, row in ipairs(value) do
                if row ~= nil and type(row) == "table" then
                    local dataRow = {};

                    for indexHeader, header in ipairs(arrayId) do
                        local existCol = false;
                        local headerKey = explode(header , name.."_");
                        dataRow[header] = {content = "---" }

                        for keyTable, valueTable in pairs(row) do
                            if valueTable ~= nil and valueTable.value ~= nil then
                                local keyData = explode(keyTable , "_customform");
                                if keyData == headerKey  then
                                    existCol = true;

                                    local type = "text";
                                    if valueTable.type ~= nil then
                                        type = valueTable.type;
                                    end

                                    if type == "text" then
                                        dataRow[header] = {content = valueTable.value }
                                    elseif type == "DateTimePicker" then
                                        if valueTable.value ~= nil then
                                            dataRow[header] =  {content =  self:convert_toDate(valueTable.value) } ;
                                        else
                                            dataRow[header] = {content = "---" }
                                        end

                                    elseif type == "combobox" then

                                        if valueTable.value ~= nil then
                                            dataRow[header] = {content = valueTable.value }
                                        else
                                            dataRow[header] = {content = "---" }
                                        end

                                    elseif type == "status"  then

                                        if valueTable.value == 0 then
                                            if queryType == self._QUERY_TYPE._TYPE_PAGE_EXCEL then
                                                dataRow[header] = {content = translateWord("_value_type_false") }
                                            else
                                                dataRow[header] = {content = [[<span class="tyf tyf-square"></span>]] }
                                            end
                                        else
                                            if queryType == self._QUERY_TYPE._TYPE_PAGE_EXCEL then
                                                dataRow[header] = {content = translateWord("_value_type_true") }
                                            else
                                                dataRow[header] = {content = [[<span class="tyf tyf-check-square-o"></span>]] }
                                            end
                                        end
                                    end

                                    break;
                                end
                            end
                        end
                    end

                    table.insert(dataExp , dataRow)

                end
            end
        end

        if self.render_export_type == nil or self.render_export_type == 0 then
            resultExp = { arrayId = arrayId, headers = headers, dataExp = dataExp, }
        elseif self.render_export_type ~= nil and self.render_export_type == 1 then
            if queryType ~= self._QUERY_TYPE._TYPE_PAGE_EXCEL then
                local elementId = "table_table_"..keyFD.."_"..index
                resultExp = self:readyHtmlTable( elementId , arrayId , headers , dataExp) ;
            else
                resultExp = self:readyExcelTable(  headers , dataExp) ;
            end
        end

        return resultExp ;
    end ,
    getData_customForm_acl = function(self , queryType , index , keyFD , value)
        local resultExp = "---";

        local arrayId = {"id" , "name"};
        local headers = { { id = "id" , content = translateWord("_col_acl_id")} , { id = "name" , content = translateWord("_col_acl_name") } };
        local elementId = "table_acl_"..keyFD.."_"..index
        local dataExp = { };
        if value ~= nil then
            value = toTable(value);
            if value ~= nil and type(value) == "table" then
                for indexRow , row in ipairs(value) do
                    if row ~= nil and row.id ~= nil and row.name ~= nil then
                        table.insert(dataExp , {
                            id = {content = row.id }   ,
                            name = {content = row.name }
                        })
                    end
                end
            end
        end


        if self.render_export_type == nil or self.render_export_type == 0 then
            resultExp = { arrayId = arrayId, headers = headers, dataExp = dataExp, }
        elseif self.render_export_type ~= nil and self.render_export_type == 1 then
            if queryType ~= self._QUERY_TYPE._TYPE_PAGE_EXCEL then
                resultExp = self:readyHtmlTable( elementId , arrayId , headers , dataExp) ;
            else
                resultExp = self:readyExcelTable(  headers , dataExp) ;
            end
        end


        return resultExp;
    end ,


    --------------------------------------------
    --- Type I
    --------------------------------------------
    --- Custom Form HTML
    readyHtmlTable = function(self , elementId , arrayId , headers , dataExp)
        return [[
<div id="]]..elementId..[[" class="mx-1"></div>
<script>
    let arrayId =]]..json.encode(arrayId)..[[;
    let objHeader =]]..json.encode(headers)..[[;
    let objDataOut =]]..json.encode(dataExp)..[[;
    let objData = [];
    for(let i=0; i<objDataOut.length ;i++){
       const itemRow = objDataOut[i];
       let itemRowOut = {};
        for(let j=0; j<objHeader.length ;j++){
            const itemHeader = objHeader[j];
            if(itemHeader.hasOwnProperty("id")){
                 Object.keys(itemRow).forEach(keyRow => {
                     if(keyRow = itemHeader["id"] ){
                         itemRowOut[keyRow] = itemRow[keyRow];
                     }
                 })
            }
       }
       objData.push(itemRowOut)
    }

    $.Teamyar.layout({
        selector: "#]]..elementId..[[",
        type: 'COL-1',
        controls:  [
            $.Teamyar.table({ arrayId , objData, objHeader, })
        ]
    });
</script>
             ]];
    end ,

    --- Custom Form EXCEL
    readyExcelTable = function(self , headers , dataExp)
        local sep = "\n"
        local lineVertical = "ا"
        local spaceStr = self:readyExcelTable_getSpace(3);
        local resultEXpHeader = lineVertical;
        local resultEXpData = "";

        if headers ~= nil and type(headers) == "table" then
            for indexHeader, rowHeader in ipairs(headers) do
                local headerTitle , headerMax = self:readyExcelTable_headerCalc(rowHeader , dataExp , spaceStr , lineVertical);
                headers[indexHeader].max = headerMax;
                resultEXpHeader = resultEXpHeader .. headerTitle;
            end
        end

        if dataExp ~= nil and type(dataExp) == "table" then
            for i, itemRow in ipairs(dataExp) do
                resultEXpData = resultEXpData .. lineVertical;
                if itemRow ~= nil  then
                    for j, itemHeader in ipairs(headers) do
                        if itemHeader.max ~= nil and itemRow[itemHeader.id] ~= nil then
                            for keyRow, valueRow in pairs(itemRow) do
                                if keyRow == itemHeader.id then
                                    resultEXpData = resultEXpData .. self:readyExcelTable_columnCalc(valueRow , itemHeader.max , spaceStr , lineVertical);
                                end
                            end
                        end
                    end
                end
                resultEXpData = resultEXpData .. sep
            end
        end

        return resultEXpHeader .. sep .. resultEXpData
    end ,
    readyExcelTable_headerCalc = function(self, rowHeader , dataExp , spaceStr , lineVertical)
        local content = "";
        if rowHeader ~= nil and rowHeader.content ~= nil and type(rowHeader.content) == "string" then
            content = rowHeader.content;
        end

        local resultExp = " --- ";
        local title_len = self:utf8len(content);
        local max = title_len;

        for indexData, rowData in ipairs(dataExp) do
            if rowData ~= nil and  rowData[rowHeader.id] ~= nil  then
                for key, val in pairs(rowData) do
                    if val.content ~= nil  and rowHeader.id == key then
                        if self:utf8len(val.content)  > max  then
                            max = self:utf8len(val.content) ;
                        end
                    end
                end
            end
        end

        resultExp = spaceStr ..  content .. self:readyExcelTable_getSpace(math.floor(max-title_len)) ..  spaceStr .. lineVertical;

        return resultExp , max
    end ,
    readyExcelTable_columnCalc = function(self, rowData , max , spaceStr , lineVertical)
        local content = "";
        if rowData ~= nil and rowData.content ~= nil and type(rowData.content) == "string" then
            content = rowData.content;
        end
        local lengthSpace = max -  self:utf8len(content);
        local spaceAfterWordStr = self:readyExcelTable_getSpace(lengthSpace);
        return spaceStr .. content .. spaceAfterWordStr .. spaceStr .. lineVertical;
    end ,
    readyExcelTable_getSpace = function(self, space , word)
        if word == nil then
            word = " "
        end
        local resultExp = "";
        for i = 1, space do
            resultExp = resultExp .. word;
        end
        return resultExp;
    end ,





    --------------------------------------------
    --- query
    --------------------------------------------
    getQuery_select = function(self , queryType)
        if queryType == self._QUERY_TYPE._TYPE_TOTAL_SUM then
            return self:getTableConfig_sum()
        elseif queryType == self._QUERY_TYPE._TYPE_TOTAL_COUNT then
            return self:getTableConfig_count()
        else
            return self:getTableConfig_select();
        end
    end ,

    getQuery_page = function(self , queryType , pageFrom , perPage , pageTo)
        local slicePageNumber = "";
        if queryType == self._QUERY_TYPE._TYPE_PAGE_REPORT then
            local limit = tonumber(perPage);
            local offset = tonumber(pageFrom) ;
            slicePageNumber = "LIMIT "..limit .. " OFFSET "..offset;
        elseif queryType == self._QUERY_TYPE._TYPE_PAGE_EXCEL then
            local limit = tonumber(perPage)*(tonumber(pageTo)  - tonumber(pageFrom) + 1) ;
            local offset = tonumber(perPage) *(tonumber(pageFrom) - 1);
            slicePageNumber = "LIMIT "..limit.." OFFSET "..offset;
        end

        return slicePageNumber;
    end ,

    getQuery_result = function(self , queryType , dataQuery)
        local resultExp = nil;

        db.query(dataQuery)
        local record={};
        if queryType == self._QUERY_TYPE._TYPE_TOTAL_COUNT then
            record = db.query_fetch();
            if record ~= nil and record[1] ~= nil then
                resultExp = record[1];
            else
                resultExp = 0;
            end


        elseif queryType == self._QUERY_TYPE._TYPE_TOTAL_SUM then
            local columnsSelected = {};
            local columns = self:getTableConfig();
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
                local columns = self:getTableConfig();
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
    end ,

    getTableConfig_sum = function(self)
        local columnsSelected = {};
        local select = "";

        local columns = self:getTableConfig();
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
    end ,

    getTableConfig_select = function(self)
        local columnsSelected = {};
        local select = "";

        local columns = self:getTableConfig();
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
    end ,

    getTableConfig_count = function(self)
        return "count(*)";
    end ,




    --------------------------------------------
    --- header
    --------------------------------------------

    getTableConfig= function(self , withCustomForm)
        local list = {
            {show= true ,    key = "workflow_id"             , value= "_col_workflow_id" } ,
            {show= true ,    key = "workflow_title"          , value= "_col_workflow_title"} ,
            {show= true ,    key = "task_id"                 , value= "_col_task_id"       , type="link"      , link="/?page=/todo/report/{{task_id}}"          ,params= {"task_id"}} ,
            {show= true ,    key = "TASK_TITLE"              , value= "_col_task_title" } ,
            {show= true ,    key = "task_date"               , value= "_col_task_date"     , type= "date"} ,
            {show= false ,    key = "formData"              } ,
        };

        if withCustomForm ~= nil and withCustomForm == true and self.list_custom_form ~= nil then
            if self.render_export_type == nil or self.render_export_type == 0 then
                local listCf = self:getTableConfig_queryCf();
                for i, v in ipairs(listCf) do
                    if v ~= nil and v.key ~= nil and v.name ~= nil then
                        table.insert(list , {
                            show= true ,key = v.key, value= v.name , isCustomForm = true , reference = v.reference, isList = v.isList
                        });
                    end
                end
            elseif self.render_export_type ~= nil and self.render_export_type == 1 then
                for index, data in ipairs(self.list_custom_form) do
                    table.insert(list , data);
                end
            end
        end

        return list;
    end ,

    getTableConfig_header = function(self , withCustomForm)
        local headers = {};
        local totalHeader = self:getTableConfig(withCustomForm);
        for i = 1, #totalHeader , 1 do
            local itemHeader = totalHeader[i];
            if itemHeader.show ~= nil and itemHeader.show == true then
                table.insert(headers ,itemHeader );
            end
        end
        return headers;
    end ,

    getTableConfig_queryCf = function(self)

        local listCf = {};
        local resultExp = {};

        ---- init Query
        local dataQuery = {
            query = teamyar.get_attachment("query_config_custom_form.txt") ,
            params = {}
        };

        ---- where
        dataQuery.query , dataQuery.params  = queryTools.where:init({" id = ".. self.task_work_flow_id})
                .run( dataQuery.query ,  dataQuery.params , "{{whereWorkFlow}}");

        dataQuery.query , dataQuery.params  = queryTools.where:init()
                :addIn("ts.id" , self.task_work_flow_steps_id)
                .run( dataQuery.query ,  dataQuery.params , "{{whereWorkflowStep_forCF}}");

        db.query(dataQuery)
        local record={};
        while db.query_fetch(record) do

            local column_list = record[2];
            if column_list ~= nil and column_list ~= "" then
                column_list = toTable(record[2])
            else
                column_list = nil
            end

            table.insert(listCf, {
                column_name = record[1],
                column_list = column_list
            })
        end
        db.query_free();

        if  listCf ~= nil and #listCf > 0 then
            for indexCf, dataCf in ipairs(listCf) do
                if dataCf ~= nil and dataCf.column_name ~= nil  then
                    for index, data in ipairs(self.list_custom_form) do
                        if data ~= nil and data.show ~= nil and data.show == true and data.key ~= nil and data.key ~= nil and  data.key == dataCf.column_name and data.value ~= nil then


                            if dataCf.column_list ~= nil  then
                                for i, col in ipairs(dataCf.column_list) do
                                    table.insert(resultExp,
                                            {
                                                key= data.value .. "_" .. col[1] ,
                                                name= data.value .. "_" .. col[1] ,
                                                reference=  data.key ,
                                                isList=  true ,
                                            })
                                end
                            else
                                table.insert(resultExp,
                                        {
                                            key= data.key  ,
                                            name= data.value  ,
                                            reference=  data.key  ,
                                            isList=  false ,
                                        })
                            end

                            break;
                        end
                    end
                end
            end

        end

        return resultExp;
    end ,




    --------------------------------------------
    --- template main
    --------------------------------------------
    getTemplateMain= function(self)
        return install_res.resReport(self:getTableConfig(true));
    end ,



    --------------------------------------------
    --- Report
    --------------------------------------------
    report = function(self)
        local report = {
            {
                name = "table" ,
                title = "جدول" ,
               report = self:getTableSectionOne()
            }
        }



        return report;
    end ,

    getTableSectionOne = function(self)
        local headers = self:getTableConfig_header(true);

        local values  = self:getData(headers , self._QUERY_TYPE._TYPE_PAGE_REPORT , self.from , self._PAR_PAGE );
        local total  = self:getData(headers , self._QUERY_TYPE._TYPE_TOTAL_COUNT);

        return install_res.resTable(self.repId , headers , values  , total , self._PAR_PAGE , self.from );
    end ,


    excel = function(self)
        local headers = self:getTableConfig_header(true );
        local values= self:getData(headers , self._QUERY_TYPE._TYPE_PAGE_EXCEL ,  self.excelFormPage , self.excelPerPage , self.excelToPage)

        return install_res.resExcel( headers , values , self.excelFileName);
    end ,


    print = function(self)
        local headers = self:getTableConfig_header(true);
        local values = self:getData(headers , self._QUERY_TYPE._TYPE_PAGE_PRINT)

        return install_res.resPrint( headers , values);
    end ,

    --------------------------------------------
    --- tools
    --------------------------------------------
    convert_toFullDate = function(self , value)
        if value ~= nil and #value>0 then
            return self:convertNumberEnToFa(time.get_shamsi_str(value));
        end
        return "---"
    end ,
    convert_toDate = function(self , value)
        if value ~= nil and #value>0 then
            value = self:convert_toFullDate(value);
            value = explodeToArray(value , " ");
            if value ~= nil and type(value) == "table" and value[1] ~= nil then
                return self:convertNumberEnToFa(value[1]);
            end
        end
        return "---"
    end ,
    convert_toTime = function(self , value)
        if value ~= nil and #value>0 then
            value = self:convert_toFullDate(value);
            value = explodeToArray(value , " ");
            if value ~= nil and type(value) == "table" and value[2] ~= nil then
                return self:convertNumberEnToFa(value[2]);
            end
        end
        return "---"
    end ,
    convert_toTime_calc = function(self , value)
        if value ~= nil and #value>0 then
            local hours = math.floor(tonumber(value) / (60*60));
            if hours == 0 then
                hours = "00"
            end
            local minute = math.floor((tonumber(value) - (hours*60*60))/ (60));
            if minute == 0 then
                minute = "00"
            end

            return self:convertNumberEnToFa(tostring(hours) .. ":" .. tostring(minute));
        end
        return "---"
    end ,

    utf8len = function(self , str)
        if str ~= nil and type(str) == "string" and #str>0 then
            local _, count = str:gsub("[^\128-\193]", "")
            return count
        end
        return 0;
    end,

    convertNumberEnToFa = function(self , str)
        --[[local isFa = isLangFa();
        if isFa == true  then
            local digits = {'۰','۱','۲','۳','۴','۵','۶','۷','۸','۹'}
            return (str:gsub('%d', function(d) return digits[tonumber(d)+1] end))
        end]]
        return str;
    end ,


    --------------------------------------------
    --- acls
    --------------------------------------------

    aclQueryCustom = function(self , query , fullName , tableWhere)
        local params = {};
        local search = getInput("search");

        local where = {};
        if tableWhere ~= nil then
            table.insert(where , tableWhere)
        end
        local where_acl = queryTools.where:init(where)
                :addLike(fullName , search);

        query , params = where_acl.run(query , params , "{{whereAcl}}");

        local dataQuery = {
            query= query,
            params=params
        }

        db.query(dataQuery)
        local record={};
        local res = {};
        while db.query_fetch(record) do
            table.insert(res,{id = record[1],name = record[2] , type=1})
        end
        db.query_free();
        return res;
    end ,

    getTaskAcl= function(self)
        local queryTitle = "concat(Id , ' ' , TASK_TITLE)"
        local query = [[
select id , ]]..queryTitle..[[ task_title from todo_task {{whereAcl}}
        ]];
        local queryWhere =  "WORK_FLOW_ID =" .. self.task_work_flow_id

        return self:aclQueryCustom(query , queryTitle , queryWhere);
    end,

    getTaskCategoryAcl= function(self)
        local queryTitle = "category_title"
        local query = [[
with data as (
    select tc.id , concat(tc.id, " - " , ts.SECTION_NAME , " > " , tc.CATEGORY_TITLE) as category_title
    from todo_section as ts
    join todo_category as tc on ts.ID = tc.SECTION_ID
)
select id , ]]..queryTitle..[[ from data {{whereAcl}}
        ]];

        return self:aclQueryCustom(query , queryTitle , nil);
    end,


    getListWorkFlowAcl= function(self)
        local queryTitle = "concat(Id , ' ' , WF_TITLE)"
        local query = [[
select id , ]]..queryTitle..[[ workFlowTitle from todo_workflow {{whereAcl}}
        ]];

        return self:aclQueryCustom(query , queryTitle , nil);
    end,


    getListWorkFlowStepsAcl= function(self)
        local queryTitle = "concat(Id , ' ' , STEP_NAME)"
        -- local whereAcl = "wf_id = "..self.task_work_flow_id
        local query = [[
select id , ]]..queryTitle..[[ STEP_NAME from todo_step {{whereAcl}}
        ]];

        return self:aclQueryCustom(query , queryTitle , nil --[[whereAcl]]);
    end,

    --------------------------------------------
    --- run
    --------------------------------------------
    run = function(self)
        local result = "";
        --- get report
        if self.type ~= nil and self.type == 100 then
           return json.encode(self:report())

        elseif self.type ~= nil and self.type == 101 then
            return json.encode(self:excel())

        elseif self.type ~= nil and self.type == 102 then
            return  json.encode(self:print())

        elseif self.type ~= nil and self.type == 1 then
            return json.encode(self:getTaskAcl())

        elseif self.type ~= nil and self.type == 2 then
            return json.encode(self:getTaskCategoryAcl())

        elseif self.type ~= nil and self.type == 1001 then
            return json.encode(self:getListWorkFlowAcl())

        elseif self.type ~= nil and self.type == 1002 then
            return json.encode(self:getListWorkFlowStepsAcl())

        else
            return self:getTemplateMain()

        end
        return "404"
    end
}


local reportTodoCf = class_report:init():run();
teamyar.write_result(reportTodoCf)