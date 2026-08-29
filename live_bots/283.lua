--sms_dashboard_portal.lua
local _COST_DB_MAIN="0000000";

local langs= {
    fa = {
        filterFromDate = "از " , filterToDate = "تا " , filterSmsBox = "صندوق" , btnSubmitReport = "جستجو"  ,
    },
    en = {
        filterFromDate = "from " , filterToDate = "to " , filterSmsBox = "sms box" , btnSubmitReport = "search"  ,
    }
}

result = teamyar.get_license_info();
local _CONST_BOT_PREFIX_PATH = "bot/run/2/";
local _CONST_BOT_NAME = "sms_dashboard_portal";

local _baseUrl = "https://" .. result.domain .. "/";
local _base =  _CONST_BOT_PREFIX_PATH .. _CONST_BOT_NAME;


local _icons = {
    comments = "/comments.png"  ,
    prohibition = "/prohibition.png"  ,
    check = "/check.png"  ,
    arrow = "/arrow.png"  ,
};
local _urls = {
    linkListSms = "?page=/sms/index" ,
    linkAclListSmsBox = _base ,
}
local _styles = {
    { base=true , path=  "/style.css" },
};
local _scripts = {
    { base=true , path=  "/form-controller.js" },
    { base=true , path=  "/script.js" },
};
local _acls = {
    acl_list_sms_box = "sms_boxes" ,
};

listParams = {};
function getListParams()
    if #listParams == 0 then
        listParams =  teamyar.get_input();
    end
    return listParams
end
function getParam(paramName , cast , default)
    local params = getListParams();
    if params[paramName] ~= nil then
        if cast=="string" then
            return getParamToString(params , paramName , default);
        elseif cast=="number" then
            return getParamToNumber(params , paramName , default);
        elseif cast=="boolean" then
            return getParamToBoolean(params , paramName , default);
        elseif cast=="table" then
            return toTable(params[paramName]);
        else
            return params[paramName];
        end
    end
    if default == nil then
        return nil;
    else
        return default;
    end
end
function setParamToObject(object , paramName , cast , default)
    local getParam = getParam(paramName , cast , default);
    if getParam ~= nil then
        object[paramName] = getParam;
    end
end
function issetKey(table, element)
    for key, value in pairs(table) do
        if key == element then
            return true
        end
    end
    return false
end
function getParamToString(array , key , default)
    if array[key] ~= nil and #array[key] > 0 then
        return tostring(array[key]);
    else
        if default == nil then
            return "";
        else
            return tostring(default);
        end
    end
end
function getParamToNumber(array , key , default)
    if array[key] ~= nil and tonumber(array[key]) ~= nil and tonumber(array[key]) > 0 then
        return tonumber(array[key]);
    else
        if default == nil then
            return 0;
        else
            return tonumber(default);
        end
    end
end
function getParamToBoolean(array , key , default)
    if array[key] ~= nil then
        if type(array[key]) == "number" then
            if type(array[key]) == 1 then
                return true;
            elseif type(array[key]) == 0 then
                return false;
            end
        elseif type(array[key]) == "boolean" then
            return array[key];
        end
    end
    if default == nil then
        return false;
    else
        return default;
    end
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

baseQuery ={}
function baseQuery:init()
    baseQuery.query ="";
    baseQuery.outQuery ="";
    baseQuery.selects ={};
    baseQuery.first =1;
    baseQuery.wheres ={};
    baseQuery.db_name =_COST_DB_MAIN;
    return baseQuery
end
function baseQuery:setQuery(query)
    baseQuery.query = query;
    return self;
end
function baseQuery:setFirst(first)
    baseQuery.first = first;
    return self;
end
function baseQuery:setSelects(...)
    baseQuery.selects = {...};
    return self;
end
function baseQuery:setParams(params)
    baseQuery.params = params;
    return self;
end
function baseQuery:fetch()
    queryData = {
        query= baseQuery:getQuery(),
        params = baseQuery.params
    }

    db.use_db(baseQuery.db_name)
    db.query(queryData)
    local record={};
    local resultExp = {};
    if baseQuery.first == 1 then
        db.query_fetch(record)
        resultExp = baseQuery.readyItemReturned(record);
    else
        while db.query_fetch(record) do
            local itemReturned = baseQuery.readyItemReturned(record);
            table.insert(resultExp , itemReturned)
        end
        db.query_free();
    end
    return resultExp
end
function baseQuery:getQuery()
    outQuery = string.gsub(baseQuery.query, "{{select}}", baseQuery.preprationListSelect(baseQuery.selects))
    return outQuery;
end
function baseQuery.preprationListSelect(select)
    local resultExp = '';
    for i = 1 , #select , 1   do
        local itemSelect = select[i];
        local alias = "";
        local column = "";
        if (type(itemSelect) == "table") then
            if itemSelect.alias ~= nil and #itemSelect.alias > 0 then
                alias = itemSelect.alias;
            end

            if itemSelect.column ~= nil and #itemSelect.column > 0 then
                column = itemSelect.column;
            end
        else
            alias = itemSelect;
            column = itemSelect;
        end

        resultExp = resultExp ..column.." as ".. alias .. " "
        if i~= #select then
            resultExp = resultExp .. " , "
        end
    end
    return resultExp;
end
function baseQuery.readyItemReturned(record)
    local itemReturned = {};
    for i = 1 , #baseQuery.selects , 1   do
        local itemSelect = baseQuery.selects[i];
        if record[i] ~= nil then
            itemReturned[itemSelect["alias"]] = record[i];
        end
    end
    return itemReturned;
end

whereQuery ={}
function whereQuery:init(listWhere)
    self.params = {};
    self.listWhere = {};
    if listWhere~=nil and #listWhere>0 then
        self.listWhere = listWhere
    end
    return self
end
function whereQuery:addSqlWhere(reference , sqlString , getSingleValue)
    if getSingleValue~=nil and getSingleValue then
        reference = whereQuery.getListIdSingle(reference);
    end

    if reference~= nil and reference > 0 then
        table.insert(whereQuery.listWhere ,  sqlString)
        table.insert(whereQuery.params , reference)
    end
    return self;
end
function whereQuery:addSqlWhereIn(reference , columnName)
    reference = whereQuery.getListIdMulti(reference);
    if reference ~= nil and #reference > 0 then
        local query = " "..columnName.." ";
        query = query .. " in ( ";
        for i = 1 ,#reference , 1 do
            local itemQueryWhere = reference[i];
            table.insert(whereQuery.params ,itemQueryWhere)
            query = query.."?";
            if i < #reference   then
                query = query .. ","
            end
        end
        query = query.. " ) "
        table.insert(whereQuery.listWhere ,query)
    end
    return self;
end
function whereQuery:addSqlWhereLike(reference , columnName)
    if reference ~= nil and #reference > 0 then
        local query ="(" ;
        query = query .." (" .. columnName.." like ?) or ";
        table.insert(whereQuery.params ,reference)

        query = query .." (" .. columnName.." like (concat(? , '%%')) ) or ";
        table.insert(whereQuery.params ,reference)

        query = query .." (" .. columnName.." like (concat( '%%' , ? )) ) or ";
        table.insert(whereQuery.params , reference)

        query = query .." (" .. columnName.." like (concat( '%%' , ?  , '%%')) )  ";
        table.insert(whereQuery.params , reference)
        query = query.. " ) "

        table.insert(whereQuery.listWhere ,  query)
    end
    return self;
end
function whereQuery.readyWhere()
    local query= "";
    if whereQuery.listWhere~=nil and #whereQuery.listWhere>0 then
        query = " where ";
        for i = 1 ,#whereQuery.listWhere , 1 do
            local itemQueryWhere = whereQuery.listWhere[i];
            query = query .. " "..itemQueryWhere.." ";
            if i < #whereQuery.listWhere then
                query = query .. " and "
            end
        end
    end
    return query;
end
function whereQuery.getListIdSingle(reference)
    if reference ~= nil then
        if reference.id ~= null then
            return reference.id;
        end
    end
    return nil;
end
function whereQuery.getListIdMulti(reference)
    local listId = nil;
    if reference ~= nil then
        listId = {};
        local getArrayId = toTable(reference)
        if #getArrayId > 0 then
            for i = 1, #getArrayId , 1 do
                local itemId = getParamToNumber(getArrayId[i] , "id")  ;
                if itemId > 0 then
                    table.insert(listId , itemId)
                end
            end
        end
    end
    return listId;
end
function whereQuery.run(query , params , pattern)
    local queryOut = whereQuery.readyWhere();
    for i = 1 ,#whereQuery.params , 1 do
        local itemParam = whereQuery.params[i];
        table.insert(params , itemParam )
    end
    return string.gsub(query, pattern, queryOut) , params;
end

function getCurrentTime()
    return tostring(time.current());
end

function startYear()

    -- get this year
    local thisYear = getThisYear();

    -- get last day year grigorian
    local timeShamci = {
        year = thisYear ,
        month = 1 ,
        day = 1
    }

    timeShamci = time.to_grigorian(timeShamci);

    -- get timestamp day
    local timeMiladi = {
        year =  timeShamci.year ,
        month = timeShamci.month ,
        day = timeShamci.day ,
        hour = 1,
        minute = 1 ,
        second = 1
    };

    local timestamp =  time.get_filetime(json.encode(timeMiladi))

    return timestamp;
end

function getThisYear()

    local thisYear = time.get_year(time.current());
    local thisMonth = time.get_month(time.current());
    local thisDay = time.get_day(time.current())
    local data ={
        year = thisYear ,
        month = thisMonth ,
        day = thisDay ,
    }
    local timeShamsi = time.to_jalali(data);

    if timeShamsi.year ~= nil then
        thisYear = timeShamsi.year;
    else
        thisYear = 1402;
    end

    return thisYear;
end


function getCurrentTime()
    return tostring(time.current());
end
function getTimeStartDay()
    local thisYear = time.get_year(time.current());
    local thisMonth = time.get_month(time.current());
    local thisDay = time.get_day(time.current())

    -- get timestamp day
    local timeMiladi = {
        year =  thisYear ,
        month = thisMonth ,
        day = thisDay ,
        hour = 0,
        minute = 0 ,
        second = 0
    };

    return  time.get_filetime(timeMiladi);
end
function getTimeFinishDay()
    return tostring(time.current() + 60*60*24*10000000);
end

--=
local smsDashboard = {};
function smsDashboard:init()
    self.from_date = 0;
    self.to_date = 0;
    self.from_date_start_day = 0;
    self.to_date_finish_day = 0;

    self.box_id = {  };

    self.acl="";
    self.search="";
    self.queryAcl = "";
    self.paramsAcl = {};
    self.resultAcl = {  };

    self.userId = 0;
    self.userFullName = "";

    self.queryPeriodSms = "";
    self.paramsPeriodSms = {};
    self.resultPeriodSms = {  };

    self.queryThisDayParams = "";
    self.paramsThisDaySms = {};
    self.resultThisDaySms = {  };


    self.styles= "";
    self.scripts= "";
    self.templateHtml= "";

    return self;
end
function smsDashboard.langIsFa()
    local user =teamyar.get_user_info();
    if user~= nil and user.lang_id ~= nil and user.lang_id==4 then
        return true;
    end
    return false;
end

function smsDashboard:readyTemplateHtml()
    self.templateHtml = teamyar.get_attachment("template.html");
    return self;
end
function smsDashboard:readyStyles()
    for i = 1 ,#_styles , 1 do
        local itemStyle = _styles[i];
        if itemStyle ~= nil and itemStyle.path then
            local path = itemStyle.path;
            if itemStyle.base ~= nil  ~= nil  and itemStyle.base == true then
                path = _base .. itemStyle.path;
            end
            smsDashboard.styles = smsDashboard.styles .. "<link href='"..path.."' rel='stylesheet' />";
        end
    end
    self.templateHtml = string.gsub(self.templateHtml, "{{styles}}", smsDashboard.styles);
    return self;
end
function smsDashboard:readyScripts()
    for i = 1 ,#_scripts , 1 do
        local itemScript = _scripts[i];
        if itemScript ~= nil then
            local path = itemScript.path;
            if itemScript.base ~= nil and itemScript.base == true then
                path = _base .. itemScript.path;
            end
            smsDashboard.scripts = smsDashboard.scripts .. "<script src='"..path.."' ></script>";
        end
    end
    self.templateHtml = string.gsub(self.templateHtml, "{{scripts}}", smsDashboard.scripts);
    return self;
end
function smsDashboard:readyIcons()
    if _icons.comments ~= nil then
        self.templateHtml = string.gsub(self.templateHtml, "{{srcIconComments}}", _base .. _icons.comments);
    end
    if _icons.prohibition ~= nil then
        self.templateHtml = string.gsub(self.templateHtml, "{{srcIconProhibition}}", _base .. _icons.prohibition);
    end
    if _icons.check ~= nil then
        self.templateHtml = string.gsub(self.templateHtml, "{{srcIconCheck}}", _base .. _icons.check);
    end
    if _icons.arrow ~= nil then
        self.templateHtml = string.gsub(self.templateHtml, "{{srcIconArrow}}", _base .. _icons.arrow);
    end
    return self;
end
function smsDashboard:readyUrls()
    if _urls.linkListSms ~= nil then
        self.templateHtml = string.gsub(self.templateHtml, "{{urlLinkSmsClient}}", _urls.linkListSms);
    end
    return self;
end
function smsDashboard:readyUserLoginInfo()
    local user = teamyar.get_user_info();
    if user.name ~= nil and user.family~= nil then
        smsDashboard.userFullName = user.name .. ' ' .. user.family;
    end
    if user.id ~= nil then
        smsDashboard.userId = user.id;
    end
    return self;
end

function smsDashboard:readyFilterController()

    if smsDashboard.from_date == 0 or smsDashboard.from_date == nil then
        smsDashboard.from_date = startYear();
    end
    if smsDashboard.to_date == 0  or smsDashboard.from_date == nil  then
        smsDashboard.to_date = getCurrentTime();
    end

    local lang = "en";
    if smsDashboard.langIsFa() then
        lang = "fa";
    end
    local filterFromDate = langs[lang].filterFromDate;
    local filterToDate = langs[lang].filterToDate;
    local filterSmsBox = langs[lang].filterSmsBox;
    local btnSubmitReport = langs[lang].btnSubmitReport;
    self.templateHtml = string.gsub(self.templateHtml, "{{language}}", lang);
    smsDashboard.filters = {
        controller = "form" ,
        data= {
            selector= "#form-controller3",
            id= formName ,
            action= _base,
            method= 'POST',
            events = {
                onformsend = {"onFormSearch"}
            },
            controls = {
                {
                    controller = "layout" ,
                    data = {
                        type = "COL-4",
                        controls=  {

                            {
                                controller = "acl",
                                data = {
                                    count = 100,
                                    name="box_id",
                                    title = filterSmsBox,
                                    width_title = '2',
                                    disabled = false,
                                    hide = false,
                                    value= smsDashboard.box_id,
                                    url = _urls.linkAclListSmsBox .. "?acl=".._acls.acl_list_sms_box.."&search="..smsDashboard.search,
                                    typevalue = 'object',
                                    multiselect = false,
                                    format = 'input',
                                }
                            },

                            {
                                controller = "DateTimePicker" ,
                                data = {
                                    pickTime= false,
                                    title= filterFromDate,
                                    width_title= '2',
                                    name= 'from_date',
                                    value = smsDashboard.from_date
                                }
                            } ,
                            {
                                controller = "DateTimePicker" ,
                                data = {
                                    pickTime= false,
                                    title= filterToDate,
                                    width_title= '2',
                                    name= 'to_date',
                                    value = smsDashboard.to_date
                                }
                            } ,



                            {
                                controller = "form.submit" ,
                                data = {
                                    type= 'submit' ,
                                    title= btnSubmitReport ,
                                }
                            }
                        }
                    },
                }
            }
        }

    }
    self.templateHtml = string.gsub(self.templateHtml, "{{dataControllers}}", json.encode(smsDashboard.filters));
    return self;
end
function smsDashboard:getQueryPeriodSms()

    self.queryPeriodSms = teamyar.get_attachment("query_list_sms.txt");

    smsDashboard.queryPeriodSms , smsDashboard.paramsPeriodSms = whereQuery:init()
            :addSqlWhere(smsDashboard.box_id , "  ID = ?" , true)
            .run(smsDashboard.queryPeriodSms , smsDashboard.paramsPeriodSms ,"{{whereSmsBox}}");
    smsDashboard.queryPeriodSms , smsDashboard.paramsPeriodSms = whereQuery:init()
            :addSqlWhere(tonumber(smsDashboard.from_date) , " DATE_CREATE >= ? " )
            :addSqlWhere(tonumber(smsDashboard.to_date) , " DATE_CREATE <= ? " )
            .run(smsDashboard.queryPeriodSms , smsDashboard.paramsPeriodSms ,"{{whereSmsMessage}}");
    smsDashboard.queryPeriodSms , smsDashboard.paramsPeriodSms = whereQuery:init()
            :addSqlWhere(tonumber(smsDashboard.userId) , " ID = ? " )
            .run(smsDashboard.queryPeriodSms , smsDashboard.paramsPeriodSms ,"{{whereProfileMain}}");
    smsDashboard.resultPeriodSms = baseQuery:init()
            :setQuery(smsDashboard.queryPeriodSms)
            :setFirst(0)
            :setSelects({ column= 'm.id' , alias= 'message_id' } , { column= 'm.STATUS' , alias= 'STATUS' } , { column= 'm.CATEGORY' , alias= 'CATEGORY' } , { column= 'm.DATE_CREATE' , alias= 'DATE_CREATE' } , { column= 'b.ID' , alias= 'box_id' } , { column= 'b.NAME' , alias= 'box_name' }  )
            :setParams(smsDashboard.paramsPeriodSms)
            .fetch();

    local data = smsDashboard.getCountSmsInBox(smsDashboard.resultPeriodSms);
    local percent = 0;
    local created = 0;
    local failed = 0;
    local delivered = 0;
    if data.percent ~=nil then
        percent = data.percent;
    end
    if data.created ~=nil then
        created = data.created;
    end
    if data.failed ~=nil then
        failed = data.failed;
    end
    if data.delivered ~=nil then
        delivered = data.delivered;
    end

    self.templateHtml = string.gsub(self.templateHtml, "{{dataChartSmsCreatedPeriodRecords}}", created);
    self.templateHtml = string.gsub(self.templateHtml, "{{dataChartSmsFieldPeriodRecords}}", failed);
    self.templateHtml = string.gsub(self.templateHtml, "{{dataChartSmsDliveredPeriodRecords}}", delivered);
    self.templateHtml = string.gsub(self.templateHtml, "{{percentChartSmsPeriodRecords}}", percent);

    return self;
end
function smsDashboard:getQueryThisDaySms()

    smsDashboard.from_date_start_day = getTimeStartDay();
    smsDashboard.to_date_finish_day = getTimeFinishDay();
    self.queryThisDayParams = teamyar.get_attachment("query_list_sms.txt");

    smsDashboard.queryThisDayParams , smsDashboard.paramsThisDaySms = whereQuery:init()
            :addSqlWhere(smsDashboard.box_id , "  ID = ?" , true)
            .run(smsDashboard.queryThisDayParams , smsDashboard.paramsThisDaySms ,"{{whereSmsBox}}");
    smsDashboard.queryThisDayParams , smsDashboard.paramsThisDaySms = whereQuery:init()
            :addSqlWhere(tonumber(smsDashboard.from_date_start_day) , " DATE_CREATE >= ? " )
            :addSqlWhere(tonumber(smsDashboard.to_date_finish_day) , " DATE_CREATE <= ? " )
            .run(smsDashboard.queryThisDayParams , smsDashboard.paramsThisDaySms ,"{{whereSmsMessage}}");
    smsDashboard.queryThisDayParams , smsDashboard.paramsThisDaySms = whereQuery:init()
            :addSqlWhere(tonumber(smsDashboard.userId) , " ID = ? " )
            .run(smsDashboard.queryThisDayParams , smsDashboard.paramsThisDaySms ,"{{whereProfileMain}}");

    smsDashboard.resultThisDaySms = baseQuery:init()
                                             :setQuery(smsDashboard.queryThisDayParams)
                                             :setFirst(0)
                                             :setSelects({ column= 'm.id' , alias= 'message_id' } , { column= 'm.STATUS' , alias= 'STATUS' } , { column= 'm.CATEGORY' , alias= 'CATEGORY' } , { column= 'm.DATE_CREATE' , alias= 'DATE_CREATE' } , { column= 'b.ID' , alias= 'box_id' } , { column= 'b.NAME' , alias= 'box_name' }  )
                                             :setParams(smsDashboard.paramsThisDaySms)
                                             .fetch();

    local data = smsDashboard.getCountSmsInBox(smsDashboard.resultThisDaySms);
    local percent = 0;
    local created = 0;
    local failed = 0;
    local delivered = 0;
    if data.percent ~=nil then
        percent = data.percent;
    end
    if data.created ~=nil then
        created = data.created;
    end
    if data.failed ~=nil then
        failed = data.failed;
    end
    if data.delivered ~=nil then
        delivered = data.delivered;
    end

    self.templateHtml = string.gsub(self.templateHtml, "{{percentChartSmsDalyRecords}}", percent);
    self.templateHtml = string.gsub(self.templateHtml, "{{dataChartSmsCreatedDalyRecords}}", created);
    self.templateHtml = string.gsub(self.templateHtml, "{{dataChartSmsFieldDalyRecords}}", failed);
    self.templateHtml = string.gsub(self.templateHtml, "{{dataChartSmsDeliveredDalyRecords}}", delivered);

    return self;
end
function smsDashboard.getCountSmsInBox(listRecords)
    local resultExp = {
        count = 0 ,
        percent = 0 ,
        created = 0 ,
        failed = 0 ,
        delivered = 0 ,
    };

    for i = 1 , #listRecords , 1   do
        local item = listRecords[i];

        local smsStatus = 0;
        if item.STATUS ~=nil then
            smsStatus = item.STATUS;
        end

        resultExp.count = resultExp.count + 1;
        resultExp.created = resultExp.created + 1;
        if smsStatus == 2 then
            resultExp.failed = resultExp.failed + 1;
        end
        if smsStatus == 3 then
            resultExp.delivered = resultExp.delivered + 1;
        end

    end
    if resultExp.count > 0 then
        resultExp.percent = math.ceil((resultExp.delivered / resultExp.count)*100)
    end

    return resultExp;
end

--- render HTML

function smsDashboard.renderHtml()
    smsDashboard:readyTemplateHtml():readyStyles():readyScripts():readyIcons():readyUrls():readyFilterController();
    smsDashboard:readyUserLoginInfo():getQueryPeriodSms():getQueryThisDaySms();

    return smsDashboard.templateHtml;
end

--- render Acl

function smsDashboard.renderAclListSmsBox()

    smsDashboard.queryAcl = teamyar.get_attachment("query_acl_list_sms_box.txt");

    local whereSmsBox = whereQuery:init();
    if (smsDashboard.search ~= nil or smsDashboard.acl ~= "") then
        whereSmsBox = whereSmsBox:addSqlWhereLike(smsDashboard.search , 'name')
    end
    smsDashboard.queryAcl , smsDashboard.paramsAcl = whereSmsBox.run(smsDashboard.queryAcl , smsDashboard.paramsAcl ,"{{whereSmsBox}}");
    smsDashboard.resultAcl = baseQuery:init()
                                      :setQuery(smsDashboard.queryAcl)
                                      :setFirst(0)
                                      :setSelects({ column= 'b.id' , alias= 'id' } , { column= 'b.name' , alias= 'name' })
                                      :setParams(smsDashboard.paramsAcl)
                                      .fetch();

    return json.encode(smsDashboard.resultAcl);
end
function smsDashboard.run()
    if (smsDashboard.acl ~= nil or smsDashboard.acl ~= "") and smsDashboard.acl == _acls.acl_list_sms_box then
        return smsDashboard.renderAclListSmsBox();
    elseif (smsDashboard.acl ~= nil or smsDashboard.acl == "") then

        if (smsDashboard.box_id == nil or smsDashboard.box_id.id == nil) then
            smsDashboard.renderAclListSmsBox();

            if #smsDashboard.resultAcl>0 then
                smsDashboard.box_id = {smsDashboard.resultAcl[1]}
            end
        end

        return smsDashboard.renderHtml();
    end
    return "";
end

---
function smsDashboardRun()
    local bot =  smsDashboard:init();
    setParamToObject(bot ,'from_date' , "number" , 0);
    setParamToObject(bot ,'to_date' , "number" , 0);
    setParamToObject(bot ,'box_id' , "table" , {});
    ---
    setParamToObject(bot ,'acl' , "string" , nil);
    setParamToObject(bot ,'search' , "string" , nil);

    return bot.run()
end
teamyar.write_result(smsDashboardRun())