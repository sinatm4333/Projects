_render = {};
function _render:init(files)
    _render.files = files;
    _render.libs = {};
    return self;
end
function _render:renderFile(key , code)
    local properties = nil;
    if type(code) == "table" then
        if code.properties ~= nil then
            properties = code.properties;
        end
        if code.file ~= nil then
            code = code.file;
        end
    end

    code = teamyar.get_attachment(code);

    local loadedFunction, errorMessage = load(code)
    if loadedFunction then
        local result = loadedFunction();
        if result ~= nil then
            _render.libs[key] = result:install(properties , _render.libs);
        end
    else
        teamyar.write_log("Error: " .. errorMessage);
    end
    return self;
end
function _render.run()
    for key, code in pairs(_render.files) do
        _render:renderFile(key , code);
    end

   return _render.libs;
end
----
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




----
local report = {};
function report:init()
    self.config = {};
    self.requires = {};
    self.libs = {};
    ----
    self.org_id = {  };
    ----
    self.listResult = {  };
    self.listChartData = {  };
    return self;
end
function report:getConfig()
    local configJson = teamyar.get_attachment("config.json");
    if configJson~= nil then

        local libraries = toTable(configJson)
        if libraries.requires ~= nil then
            report.requires =libraries.requires;
        end
    end
    return self;
end
function report:setLibraries()
    report.libs = _render:init(report.requires).run();
    return self;
end
function report:getParamsReport()
    setParamToObject(report ,'org_id' , "table" , {});
    return self;
end
function report:getDataReport()
    local query = teamyar.get_attachment("query_get_list_voucher_period.txt");
    local params = {};

    local startTime = getCalcNextTimeFromCurrentTime(60*60*24*45)

    query , params = whereQuery:init()
                               :addSqlWhere(report.org_id , "id=? " , true)
                               .run(query , params ,"{{whereOrg}}");
    query , params = whereQuery:init({"TYPE = 1" , "DELETED=0"})
                               :addSqlWhere(tonumber(startTime) , " DATE_ISSUE <= ? " )
                               .run(query , params ,"{{wherePdc}}");

    local result  = baseQuery:init()
            :setQuery(query)
            :setFirst(0)
            :setSelects({ column= 'pdc_id' , alias= 'pdc_id' } , { column= 'pdc_amount' , alias= 'pdc_amount' } , { column= 'pdc_date_issue' , alias= 'pdc_date_issue' })
            :setParams(params)
            .fetch();

    if result ~= nil   then
        report.listResult = result;
    end

    return self;
end
function report:getDataInPartitionPeriod()
    local timeFrom10 = getCalcNextTimeFromCurrentTime(60*60*24*10);
    local existTimeForm10=false;
    local timeFrom30 = getCalcNextTimeFromCurrentTime(60*60*24*30);
    local existTimeForm30=false;
    local timeFrom45 = getCalcNextTimeFromCurrentTime(60*60*24*45);
    local existTimeForm45=false;
    local pasDay = report.libs.reportMain.getLangSelected("passDay" , "روز");

    for i = 1 , #report.listResult , 1   do
        local itemRecord = report.listResult[i];
        if itemRecord.pdc_date_issue ~= nil then
            local pdc_date_issue = itemRecord.pdc_date_issue;

            local typeId = nil;
            local typeTitle = "";
            if pdc_date_issue <= timeFrom10 then
                typeId = 1;
                typeTitle = "<10 " .. pasDay;
                existTimeForm10 = true;
            elseif pdc_date_issue>timeFrom10 and pdc_date_issue<=timeFrom30 then
                typeId = 2;
                typeTitle = "10 - 30 " .. pasDay;
                existTimeForm30 = true;
            elseif pdc_date_issue>timeFrom30 and pdc_date_issue<=timeFrom45 then
                typeId = 3;
                typeTitle = "30 - 45 " .. pasDay;
                existTimeForm45 = true;
            end

            if typeId ~= nil then
                report.listResult[i].typeId = typeId;
                report.listResult[i].typeTitle = typeTitle;
            end

        end
    end

    if existTimeForm10 == false then
        table.insert(report.listResult , {
            typeId = 1 ,
            typeTitle = "<10 " .. pasDay;
            pdc_amount = "0";
        })
    end
    if existTimeForm30 == false then
        table.insert(report.listResult , {
            typeId = 2 ,
            typeTitle = "10 - 30 " .. pasDay;
            pdc_amount = "0";
        })
    end
    if existTimeForm45 == false then
        table.insert(report.listResult , {
            typeId = 3 ,
            typeTitle = "30 - 45 " .. pasDay;
            pdc_amount = "0";
        })
    end

    return self;
end
function report:readyDataChart()
    local chartTitle = report.libs.reportMain.getLangSelected("ageingOfPayable" , "نمودار تجزیه سنی حسابهای پرداختنی");
    self.listChartData = {
        {
            data = report.listResult ,
            groups = {
                {
                    name= "typeId" ,
                    pass= "typeTitle" ,
                    dataType= "number" ,
                } ,
            },
            values = {
                {
                    name= "pdc_amount" ,
                    prefix= "%" ,
                    type= "sum"
                },
            },
            config = {
                type= "pie" ,
                title= chartTitle,
                element= "element-chart-pie-ageing-of-pay" ,
            }
        },
    };
    return self;
end

function report.run()
    report:getConfig():setLibraries();
    local result = report.libs.reportMain.run();

    local data = {};
    if result.isArray~= nil and result.isArray==true then
        report:getParamsReport():getDataReport():getDataInPartitionPeriod():readyDataChart();
        data = {
            chartData = report.listChartData,
        };
    end

    return report.libs.reportMain.renderOutput(result , data);
end




function reportRun()
    local bot =  report:init();
    return bot.run()
end
teamyar.write_result(reportRun())