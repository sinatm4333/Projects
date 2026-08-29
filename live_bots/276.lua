-- botName = deals_by_stages
-- creator = mehdi-marefiyan
-- date = 4/17/2024
-- version= 0.1
------------------
local _chart_element_id = "chart_status_crm_sections";
---

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
local deals_by_stages = {};
function deals_by_stages:init()
    self.config = {};
    self.requires = {};
    self.libs = {};
    ---
    self.listCrmSections = {};
    self.charts = {};
    return self;
end
function deals_by_stages:getConfig()
    deals_by_stages.config = _boxAttachment.getAttachment("config.json" , true);
    if deals_by_stages.config ~= nil and  deals_by_stages.config.requires ~= nil then
        deals_by_stages.requires = deals_by_stages.config.requires;
    end
    return self;
end
function deals_by_stages:setLibraries()
    deals_by_stages:getConfig();
    deals_by_stages.libs = _render:init(deals_by_stages.requires).run();
    return self;
end

function deals_by_stages.getFilterCrmSections()
    return listAcls.AclCrmSection();
end
function deals_by_stages.run()
    deals_by_stages:setLibraries();

    -- [type = form]
    local formCreator = FormCreator.run(
            {
                deals_by_stages.getFilterCrmSections().getAclElement() ,
            }
    );

    -- views
    local readyView = ReadyViewReport.run(deals_by_stages.getResultChart);
    return bot_controller
            .run(
            {
                --Acls
                deals_by_stages.getFilterCrmSections().run() ,
                --Form
                formCreator
            },
            readyView
    );
end

function deals_by_stages.getResultChart()
    local crmSection = deals_by_stages.getFilterCrmSections().getValue();

    deals_by_stages:getListPercentSection(crmSection):readyCharts();

    return {
        charts = json.encode(deals_by_stages.charts) ,
        view = template_tools.run("template_result.html" , {
            _chart_element_id =  _chart_element_id,
        } );
    }
end
function deals_by_stages:getListPercentSection(crmSection)
    local query = teamyar.get_attachment("crm_percent_section.txt");
    local params = {};

    query , params = whereQuery:init()
            :addSqlWhere(crmSection , "id=? " , true)
            .run(query , params ,"{{whereCrmSection}}");

    local result  = baseQuery:init()
            :setQuery(query)
            :setFirst(0)
            :setSelects(
                {column= 'section_id' , alias= 'section_id' } , { column= 'section_name' , alias= 'section_name' } ,
                {column= 'classtify_id' , alias= 'classtify_id' } , { column= 'classtify_name' , alias= 'classtify_name' } ,
                {column= 'per' , alias= 'per' } , { column= 'total' , alias= 'total' } , { column= 'percent' , alias= 'percent' }
            )
            :setParams(params)
            .fetch();

    if result ~= nil   then
        deals_by_stages.listCrmSections = result;
    end
    return self;
end
function deals_by_stages:readyCharts()
    local chartGroupClasstifyName = chartGroup:init():setGroupName("classtify_name"):setGroupTitle(language_tools.translateWord("_classtify_title")):setGroupPass("classtify_name"):setGroupDataType_number().run();
    local chartValueClasstifyName = chartValue:init():setValueName("percent"):setValuePrefix(language_tools.translateWord("_pre_prefix")):setValueType_sum().run();

    local simpleTable = pieChart:init()
            :setData(deals_by_stages.listCrmSections)
            :setChartTitle(language_tools.translateWord("_chart_title"))
            :setChartElementId(_chart_element_id)
            :addChartGroup(chartGroupClasstifyName)
            :addChartValue(chartValueClasstifyName)
            .run();

    deals_by_stages.charts = chartManager:init():addChart(simpleTable).run();
    return self;
end


teamyar.write_result(deals_by_stages:init().run())