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
    self.listUsers = {};
    self.listBranches = {};
    self.total_balance = 0;
    self.total_credit = 0;
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
function total_balance.run()
    total_balance:setLibraries():getListUsers():getListAllBranches();

    return template_tools.run("template_main.html" , {
        _total_balance_value =  format_number(total_balance.total_balance),
        _total_credit_value =  format_number(total_balance.total_credit),
    } , "main");
end
function total_balance:getListUsers()
    local listRequests = {
        mt5Request_modelRequests:init():set_urlUserLogins()
    };
    local result =  mt5Request_manager:init():setRequests(listRequests).run();

    if  result.status ~= nil and result.status == true  and result.response ~= nil  and result.response.answer ~= nil then
        total_balance.listUsers = result.response.answer;
    end
    return self;
end
function total_balance:getListAllBranches()
    local listRequests = {
        mt5Request_modelRequests:init():set_urlUserGetBatch():setParams({
            login = table.concat(total_balance.listUsers,",")
        })
    };
    local result =  mt5Request_manager:init():setRequests(listRequests).run();

    if  result.status ~= nil and result.status == true  and result.response ~= nil  and result.response.answer ~= nil then
        local listResult = result.response.answer;
        for i = 1 , #listResult , 1   do
            local item = listResult[i];
            if item.Balance ~= nil and item.Credit ~= nil then
                total_balance.total_balance = total_balance.total_balance + item.Balance;
                total_balance.total_credit = total_balance.total_credit + item.Credit;
            end
        end
    end
    return self;
end

teamyar.write_result(total_balance:init().run())