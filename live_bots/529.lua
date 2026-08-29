-- botName = fx_report_client_withdrawal
-- creator = Mehdi_Marefiyan
-- date = 11/02/2025
-- version= 0.1
------------------

class_setResponsibleSuperviserStepTask = (function()
    local this = {};

    this._LICENSE_ID = 2;
    this._BAT_RES_PATH =  this._LICENSE_ID.."/res_v2";


    this._REQUEST_WIDGET_ACTION = {

    };



    ----------------------------------------------------------------------------------------
    --- constructor
    --------------------------------------------
    function this:new()
        local obj = setmetatable({}, { __index = self })
        return obj:init()
    end


    ----------------------------------------------------------------------------------------
    --- init
    --------------------------------------------
    function this:init()

        self:installResV2()
            :getTeamyarConfig()
            :getListInputs()

        return self
    end


    ----------------------------------------------------------------------------------------
    --- install res_v2
    --------------------------------------------
    function this:installResV2()
        local userInputs = teamyar.get_input()
        userInputs.res_type = "codes";
        userInputs.config = json.decode(teamyar.get_attachment("data.json"));
        local responseRes = teamyar.run_command(self._BAT_RES_PATH ,userInputs);
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
    end


    ----------------------------------------------------------------------------------------
    --- get inputs
    --------------------------------------------
    function this:getListInputs()
        self.task_id =  getInput("task_id");
        self.step_id =  getInput("step_id");
        self.task_step_id =  getInput("task_step_id");

        return self;
    end


    ----------------------------------------------------------------------------------------
    --- get config teamyar
    --------------------------------------------
    function this:getTeamyarConfig()


        return self;
    end


    ----------------------------------------------------------------------------------------
    --- auth data
    --------------------------------------------

    function this:getLastStepActive()
        local taskStepLsatId = 0;
        local stepLsatId = 0;
        local stepLsatResponsible = 0;

        local dataQuery = {
            query = teamyar.get_attachment("query_get_last_step_active.txt") ,
            params = {self.task_id , self.task_step_id}
        }
        db.query(dataQuery)
        local record={};
        record = db.query_fetch();
        if record ~= nil then
            taskStepLsatId = record[1];
            stepLsatId = record[2];
            stepLsatResponsible = record[3];
        end
        db.query_free();

        teamyar.write_log("step0: " .. json.encode({ taskStepLsatId , stepLsatId , stepLsatResponsible }));

        return taskStepLsatId , stepLsatId , stepLsatResponsible
    end

    function this:getSuperviserProfile(stepLsatResponsible)
        local superviserProfileId = 0;
        local superviserFullname = "----";

        local dataQuery = {
            query = teamyar.get_attachment("query_select_responsible.txt") ,
            params = {stepLsatResponsible}
        }
        db.query(dataQuery)
        local record={};
        record = db.query_fetch();
        if record ~= nil then
            superviserProfileId = record[1];
            superviserFullname = record[2];
        end

        db.query_free();
        teamyar.write_log("step1: " .. json.encode({ superviserProfileId , superviserFullname}));

        return superviserProfileId , superviserFullname
    end

    function this:setResponsibleStep( superviserProfileId)

        local params = {
            task_id = self.task_id ,
            step_id = self.step_id ,
            user_id = superviserProfileId ,
        };

        local response = teamyar.call_api( 8, "/api/todo/task/taskstep/responsible/set" , params)
        teamyar.write_log(json.encode( params));
        teamyar.write_log(json.encode(response));

        if response ~= nil and response.success ~= nil then
            return true;
        end

        return false;
    end


    ----------------------------------------------------------------------------------------
    --- run
    --------------------------------------------
    function this:run()

        local taskStepLsatId , stepLsatId , stepLsatResponsible = self:getLastStepActive();
        local superviserProfileId , superviserFullname = self:getSuperviserProfile(stepLsatResponsible);
        local status = self:setResponsibleStep(superviserProfileId);

        if status == true then
            return "<p class='bg-info p-2 border shadow-sm my-1 border rounded text-dark text-center d-block'> ".. superviserFullname .. " is responsible step Task </p>";
        else
            return "<p class='bg-danger p-2 border shadow-sm my-1 border rounded text-dark text-center d-block'> tThis request failed due to an error </p>";
        end
    end

    return this;
end)()

local result = class_setResponsibleSuperviserStepTask:new():run();
teamyar.write_result(result);