-- botName = order_of_steps_todo
-- creator = developer_name
-- date = 9/29/2025
-- version= 0.4
------------------

_LICENSE_ID = 2;
_BAT_RES_PATH =  _LICENSE_ID.."/res_v2";

class_bot = {

    ----------------------------------------------------------------------------------------
    --- init
    --------------------------------------------
    init= function(self)

        self:installResV2()
            :getTeamyarConfig()
            :getListInputs()
            :tools_getAuthId()

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

        return self
    end ,

    ----------------------------------------------------------------------------------------
    --- get inputs
    --------------------------------------------
    getListInputs= function(self)
        self.type = getInput("type");

        self.task_id = getInput('task_id');
        self.step_id = getInput('step_id');
        self.task_step_id = getInput('task_step_id');

        return self;
    end ,


    ----------------------------------------------------------------------------------------
    --- get config teamyar
    --------------------------------------------
    getTeamyarConfig= function(self)
        self.type_render_steps      =  getTeamyarConfigParam("type_render_steps"    , "number"    , 1);

        return self;
    end ,


    ----------------------------------------------------------------------------------------
    --- [TOOLS]
    --------------------------------------------
    tools_getAuthId = function(self)
        local userData = teamyar.get_user_info();
        if userData ~= nil then
            if userData.id ~= nil then
                self.authId = userData.id;
            end
            if userData.timezone then
                self.timezone = userData.timezone;
            end
        end

        return self;
    end ,



    ----------------------------------------------------------------------------------------
    --- [step 1]
    --------------------------------------------
    db_getDataQueryRels = function(self)

        local dataQuery = {
            query = teamyar.get_attachment("query_data_task_and_workflow.txt") ,
            params = {}
        };

        dataQuery.query , dataQuery.params = queryTools.where:init()
                :add("id" , "=" ,self.task_id )
                .run(dataQuery.query , dataQuery.params ,"{{whereTask}}");

        dataQuery.query , dataQuery.params = queryTools.where:init()
                :add("tts.STEP_ID2" , "=" ,self.step_id )
                :add("tts.step_id_real" , "=" ,self.task_step_id )
                .run(dataQuery.query , dataQuery.params ,"{{whereTaskStep}}");


        local result  =  queryTools.execute:init()
                :setQuery(dataQuery.query)
                :setFirst(1)
                :setSelects(
                   { column= 'task_id'           , alias= 'task_id' } ,
                   { column= 'task_title'        , alias= 'task_title' } ,
                   { column= 'workflow_id'       , alias= 'workflow_id' } ,
                   { column= 'workflow_title'    , alias= 'workflow_title' } ,
                   { column= 'step_id'           , alias= 'step_id' } ,
                   { column= 'step_id_ref'       , alias= 'step_id_ref' } ,
                   { column= 'step_id_real'      , alias= 'step_id_real' } ,
                   { column= 'form_data'         , alias= 'form_data' } ,
                   { column= 'form_data_default' , alias= 'form_data_default' }
                 )
                :setParams(dataQuery.params)
                .fetch();



        local formData = {};
        local formDataDefault = {};
        if result.form_data ~= nil then
            formData = toTable(result.form_data)
        end
        if result.form_data_default ~= nil then
            formDataDefault = toTable(result.form_data_default)
        end

        return self:regularStepFormData(formData , formDataDefault) , self:nextStepFormData(formData);
    end ,

    regularStepFormData = function(self , formData , formDataDefault)
        local listExp = {};

        if formDataDefault.info ~= nil then
            local info = formDataDefault.info;
            for i = 1 , #info , 1 do
                local item = info[i];
                if item.name ~= nil then
                    local formDataName = item.name;
                    for key,value in pairs(formData) do
                        if key == formDataName then
                            local listKey = explodeToArray(key , "_");
                            if tonumber(value) ==1 and  type(listKey) == "table" and #listKey > 0 and listKey[1] ~=nil and listKey[2] ~=nil and listKey[1] == "step" then
                                table.insert(listExp , listKey[2])
                            end
                        end
                    end
                end
            end
        end

        return listExp
    end ,

    nextStepFormData = function(self , formData)
        for key,value in pairs(formData) do
            if key == "next_step" then
                return tonumber(value)
            end
        end
        return nil;
    end ,


    ----------------------------------------------------------------------------------------
    --- [step 2]
    --------------------------------------------
    db_getListExistStep = function(self , listSteps)

        local dataQuery = {
            query = teamyar.get_attachment("query_get_list_steps_relations.txt") ,
            params = {}
        };


        dataQuery.query , dataQuery.params = queryTools.where:init()
                :add("id" , "=" ,self.task_id )
                .run(  dataQuery.query , dataQuery.params,"{{whereTask}}");

        dataQuery.query , dataQuery.params= queryTools.where:init()
                :add("tts.STEP_ID2" , "=" ,self.step_id )
                :add("tts.step_id_real" , "=" ,self.task_step_id )
                .run(  dataQuery.query , dataQuery.params ,"{{whereTaskStep}}");

        local result  =   queryTools.execute:init()
                :setQuery(dataQuery.query)
                :setFirst(0)
                :setSelects(
                     { column= 'task_id' , alias= 'task_id' } ,
                     { column= 'task_title' , alias= 'task_title' } ,
                     { column= 'workflow_id' , alias= 'workflow_id' } ,
                     { column= 'workflow_title' , alias= 'workflow_title' } ,
                     { column= 'workflow_step' , alias= 'workflow_step' } ,
                     { column= 'workflow_step_name' , alias= 'workflow_step_name' }
                 )
                :setParams(dataQuery.params)
                .fetch();

        return self:getNextStepTask(listSteps , result);
    end ,

    getNextStepTask = function(self , listSteps , listExistSteps)
        local number = 0;
        local resultExp = {};

        if listSteps~= nil then
            resultExp = {};
            for i = 1 , #listSteps , 1 do
                number = number + 1;
                local itemStep = listSteps[i];
                if itemStep ~= nil and listExistSteps ~= nil then
                    for x = 1 , #listExistSteps , 1 do
                        local itemExistStep = listExistSteps[x];
                        if itemExistStep.workflow_step ~= nil and tonumber(itemExistStep.workflow_step) == tonumber(itemStep) then
                            table.insert(
                                    resultExp ,
                                    {
                                        nextStep = tonumber(itemExistStep.workflow_step) ,
                                        itemNextData = itemExistStep,
                                        numberItem = number
                                    }
                            );
                            if self.type_render_steps == 0 then
                                break;
                            end
                        end
                    end
                end
            end
        end

        return resultExp;
    end ,


    ----------------------------------------------------------------------------------------
    --- [step 3]
    --------------------------------------------
    db_checkNextStep = function(self , itemNextData , nextGroupStep , numberItem)

        if itemNextData ~= nil then
            return itemNextData , numberItem;
        else
            if nextGroupStep ~= nil then
                return self:db_checkNextStep_getNextGroupStep(nextGroupStep , numberItem);
            end
        end
        return nil , nil;

    end ,

    db_checkNextStep_getNextGroupStep = function(self , nextGroupStep , numberItem)

        local dataQuery = {
            query = teamyar.get_attachment("query_next_group_data.txt") ,
            params = {}
        };

        dataQuery.query , dataQuery.params = queryTools.where:init()
                :add("id" , "=" ,self.task_id )
                .run( dataQuery.query , dataQuery.params ,"{{whereTask}}");

        dataQuery.query , dataQuery.params = queryTools.where:init()
                :add("id" , "=" , tonumber(nextGroupStep))
                .run( dataQuery.query , dataQuery.params ,"{{whereWorkflowStep}}");

        local result  = queryTools.execute:init()
                :setQuery(dataQuery.query)
                :setFirst(1)
                :setSelects(
                   { column= 'task_id' , alias= 'task_id' } ,
                   { column= 'task_title' , alias= 'task_title' } ,
                   { column= 'workflow_id' , alias= 'workflow_id' } ,
                   { column= 'workflow_title' , alias= 'workflow_title' } ,
                   { column= 'workflow_step_id' , alias= 'workflow_step_id' } ,
                   { column= 'workflow_step_name' , alias= 'workflow_step_name' }
                )
                :setParams(dataQuery.params)
                .fetch();

        return result , numberItem+1;
    end ,


    ----------------------------------------------------------------------------------------
    --- [step 4]
    --------------------------------------------

    runTaskStep = function(self , nextStep )
        if nextStep ~= nil then
            return teamyar.call_api(
                8,
                "/api/todo/task/stepadd" ,
                {
                    task_id = self.task_id ,
                    step_ids = tostring(nextStep)
                }
            );
        end
        return nil;
    end ,

    getTemplateHtml = function(self , withHeader , template , numRow , dataTask)
        if withHeader~= nil and withHeader==true and
                numRow ~= nil and numRow == 1 then
            template = template .. teamyar.get_attachment("template_header_log_todo.html");
            template =  install_res.resTemplate(template);
        end

        template = template .. teamyar.get_attachment("template_log_todo.html");
        template = string.gsub(template , "{{_log_num}}" , tostring(numRow));
        template = string.gsub(template , "{{_task_title}}" , dataTask.task_title);
        template = string.gsub(template , "{{_workflow_title}}" , dataTask.workflow_title);
        template = string.gsub(template , "{{_step_title}}" , dataTask.workflow_step_name);

        return template;
    end ,


    ----------------------------------------------------------------------------------------
    --- run
    --------------------------------------------
    run = function(self)

        --- [step 1]
        local listSteps , nextGroupStep= self:db_getDataQueryRels();

        --- [step 2] ----> get step connected
        local resultValidateStepExist = self:db_getListExistStep(listSteps);


        if self.type_render_steps == 0 then

            local nextStep = nil;
            local itemNextData = nil;
            local numberItem = 0;

            if  resultValidateStepExist ~= nil and #resultValidateStepExist > 0 then
                nextStep = resultValidateStepExist[1]["nextStep"];
                itemNextData = resultValidateStepExist[1]["itemNextData"];
                numberItem = resultValidateStepExist[1]["numberItem"];
            end

            --- [step 3] ----> next group
            itemNextData , numberItem = self:db_checkNextStep(itemNextData , nextGroupStep , numberItem);

            --- [step 4] ----> set template result
            if nextStep ~= nil and nextStep>0 then
                local response = self:runTaskStep(nextStep);
                return  self:getTemplateHtml(true , "" , numberItem , itemNextData);
            else
                if nextGroupStep ~= nil and nextGroupStep > 0 then
                    local response = self:runTaskStep(nextGroupStep);
                    return  self:getTemplateHtml(false , "" , numberItem , itemNextData);
                end
            end

        elseif self.type_render_steps == 1 then
            local template = "";
            local numberItem = 0;
            local nextGroupStepData = nil;

            if  resultValidateStepExist ~= nil and #resultValidateStepExist > 0 then
                for index, row in pairs(resultValidateStepExist) do
                    local nextStep =     row["nextStep"];
                    local itemNextData = row["itemNextData"];
                    numberItem =         row["numberItem"];

                    local isFirst = false;
                    if index == 1 then
                        isFirst = true;
                    end

                    local response = self:runTaskStep(nextStep);
                    template = self:getTemplateHtml(isFirst , template , numberItem , itemNextData);
                end
            end

            if nextGroupStep ~= nil and nextGroupStep > 0 then
                nextGroupStepData , numberItem = self:db_checkNextStep_getNextGroupStep(nextGroupStep , numberItem);
                local response = self:runTaskStep(nextGroupStep);
                template = self:getTemplateHtml(false , template , numberItem , nextGroupStepData);
            end

            return template;
        end


        return "_________";
    end
}

local result = class_bot:init():run();
teamyar.write_result(result);