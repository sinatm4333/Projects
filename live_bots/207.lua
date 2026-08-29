-- botName = total_balance
-- creator = mehdi-marefiyan
-- date = 4/9/2024
-- version= 0.1
------------------
_boxAttachment = {
    attachments = {}
};
function _boxAttachment.getAttachment(fileName , isTable)
    for key, code in pairs(_boxAttachment.attachments) do
        if key == fileName then
            return code;
        end
    end

    local configJson = teamyar.get_attachment(fileName);
    if configJson~= nil then
        local result = configJson;
        if isTable ~= nil and isTable == true then
            result = json.decode(configJson);
        end
        _boxAttachment.attachments[fileName] = result;
        return result;
    end

    return nil;
end


_render = {};
function _render:init(files)
    _render.files = files;
    _render.libs = {};
    return self;
end
function _render:renderFile(code)
    if type(code) == "table" then
        if code.file ~= nil then
            code = code.file;
        end
    end
    code = _boxAttachment.getAttachment(code);
    local loadedFunction, errorMessage = load(code)
    if loadedFunction then
        local result = loadedFunction();
        if result ~= nil then
            table.insert(_render.libs , result);
        end
    else
        teamyar.write_log("Error: " .. errorMessage);
    end
    return self;
end
function _render.run()
    for x = 1 , #_render.files , 1   do
        local item = _render.files[x];
        if item ~= nil then
            _render:renderFile(item);
        end
    end
    return _render.libs;
end



----------------
local total_balance = {};
function total_balance:init()
    self.config = {};
    self.requires = {};
    self.libs = {};
    ---
    self.crmFiledIdCustom = 0;
    return self;
end
function total_balance:getConfig()
    total_balance.config = _boxAttachment.getAttachment("config.json" , true);
    if total_balance.config ~= nil and  total_balance.config.requires ~= nil then
        total_balance.requires = total_balance.config.requires;
    end
    return self;
end
function total_balance:setLibraries()
    total_balance:getConfig();
    total_balance.libs = _render:init(total_balance.requires).run();
    return self;
end
function total_balance:setCrmFiledCustomId()
    if total_balance.config.crm_field_custom_id ~= nil then
        total_balance.crmFiledIdCustom = total_balance.config.crm_field_custom_id;
    end
    return self;
end
function total_balance.getAclCustomClient()
    return listAcls.aclCrmCustomField("_filter_filed_custom" , total_balance.crmFiledIdCustom);
end
function total_balance.run()
    total_balance:setLibraries():setCrmFiledCustomId();

    -- [type = form]
    local formCreator = FormCreator.run(
            {
                total_balance.getAclCustomClient().getAclElement() ,
            }
    );

    -- views
    local readyView = ReadyViewReport.run(total_balance.getMt5TotalBalance);
    return bot_controller
            .run(
            {
                --Acls
                total_balance.getAclCustomClient().run() ,
                --Form
                formCreator
            },
            readyView
    );
end

function total_balance.getMt5TotalBalance()
    local clientMt5 = total_balance.getAclCustomClient().getValue();
    if clientMt5 ~= nil and clientMt5.id ~= id then
        local clientId = clientMt5.id;
        local listRequests = {
            mt5Request_modelRequests:init():set_urlUserCheckBalance():setParams({
                login = clientId
            })
        };

        local result =  mt5Request_manager:init():setRequests(listRequests).run();
        local totalView = total_balance.readyViewTotal(result);
        if totalView ~= nil  then
            return {
                totalView = totalView
            };
        end
    end
    return {};
end
function total_balance.readyViewTotal(result)
    local resultExp = nil;
    if result.status ~= nil and result.status == true and result.response ~= nil and result.response.answer then
        local answer = result.response.answer
        local balance = 0
        local credit = 0;
        if answer.balance ~= nil and answer.balance.user ~= nil then
            balance = answer.balance.user;
        end
        if answer.credit ~= nil and answer.credit.user ~= nil then
            credit = answer.credit.user;
        end

        return template_tools.run("template_result.html" , {
            _total_balance_value =  tostring(balance),
            _total_credit_value =  tostring(credit),
        } );

    end
    return resultExp;
end






teamyar.write_result(total_balance:init().run())