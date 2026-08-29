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
            result = toTable(configJson);
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




function toTable(data , default)
    if type(data) == "table" then
        return  data;
    elseif type(data) == "string" then
        return stringToTable(data , default);
    end
    if default == nil then
        return {};
    else
        return default;
    end
end
function stringToTable(dataString , default)
    if pcall(function() return  json.decode(dataString) end) == true then
        return  json.decode(dataString)
    end
    if default == nil then
        return {};
    else
        return toTable(default);
    end
end



----------------
local fx_rate = {};
function fx_rate:init()
    self.config = {};
    self.requires = {};
    self.libs = {};
    ---
    self.symbolSelected = nil;
    ---
    self.aclSymbolCustom = {};
    self.strSymbols = "";

    return self;
end
function fx_rate:getConfig()
    local configJson = _boxAttachment.getAttachment("config.json" , true);
    if configJson~= nil and configJson.requires ~= nil then
        fx_rate.requires =configJson.requires;
    end
    return self;
end
function fx_rate:setLibraries()
    fx_rate:getConfig();
    fx_rate.libs = _render:init(fx_rate.requires).run();
    return self;
end
function fx_rate:setValueAclSymbol()
    local aclName = Mt5Symbol.getAclName();
    self[aclName] = nil;
    setParamToObject(fx_rate , aclName , "table" , {});
    
    if fx_rate[aclName] ~= nil and fx_rate[aclName].id ~= nil then
        fx_rate.symbolSelected = fx_rate[aclName].id;
    end
    return self;
end
function fx_rate:readyAclMt5SymbolCustom()
    local config = _boxAttachment.attachments["config.json"];
    for i = 1 ,#config.symbols , 1 do
        local itemSymbol = config.symbols[i];
        if itemSymbol.name ~= nil and  itemSymbol.symbol then
            if fx_rate.symbolSelected == nil then
                fx_rate.symbolSelected = itemSymbol.symbol; ;
            end
            local itemAcl = {
                id = itemSymbol.symbol ,
                name = language_tools.translateWord(itemSymbol.name);
            }
            table.insert(fx_rate.aclSymbolCustom , itemAcl);
        end
    end
    return self;
end
function fx_rate:readyStringSymbols()
    if fx_rate.symbolSelected ~= nil  then
        local config = _boxAttachment.attachments["config.json"];
        for i = 1 ,#config.symbols , 1 do
            local itemSymbol = config.symbols[i];
            if itemSymbol.symbol ~= nil  then
                fx_rate.strSymbols = fx_rate.strSymbols .. fx_rate.symbolSelected .. itemSymbol.symbol .. ",";
            end
        end
    end
    return self;
end
function fx_rate.run()
    fx_rate:setLibraries():setValueAclSymbol():readyAclMt5SymbolCustom();

    -- [RUN Acls]
    local AclSymbols = Mt5Symbol.run(false , fx_rate.aclSymbolCustom);

    -- [type = form]
    local formCreator = FormCreator.run(
            {
                Mt5Symbol.run(true)
            }
    );

    -- views
    local readyView = ReadyViewReport.run(fx_rate.getMt5Symbols);

    return bot_controller.run(
            {
                AclSymbols ,
                formCreator
            },
            readyView
    );
end


-----
function fx_rate.getListDataSymbols()
    local listDataSymbols = {};
    local botUrl = bot_url_tools.run();
    local config = _boxAttachment.attachments["config.json"];
    for i = 1 ,#config.symbols , 1 do
        local item = config.symbols[i];
        if item.name ~= nil and  item.symbol then
            local itemSymbol = item.symbol;
            local itemName = item.name;
            local itemData = {
                real = itemSymbol,
                title = fx_rate.symbolSelected .. itemSymbol,
                name = language_tools.translateWord(itemName),
                img = botUrl.base.."/"..itemSymbol..".jpg",
            }
            table.insert(listDataSymbols , itemData);
        end
    end
    return listDataSymbols;
end
function fx_rate.getMt5Symbols()
    fx_rate:readyStringSymbols();

    local listRequests = {
        mt5Request_modelRequests:init():set_urlSymbolTickLast():setParams({
            symbol = fx_rate.strSymbols
        })
    };

    return {
        symbols = mt5Request_manager:init():setRequests(listRequests).run(),
        data = fx_rate.getListDataSymbols() ,
        selected = fx_rate.symbolSelected
    };
end


-----
function botExampleRun()
    local bot = fx_rate:init();
    return bot.run()
end
teamyar.write_result(botExampleRun())