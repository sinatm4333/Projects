local langs= {
    fa = {
        btnSubmitReport = "جستجو" , btnSchedule = "مشاهده برنامه" , listMeetings = "برنامه ها" ,
    },
    en = {
        btnSubmitReport = "search" , btnSchedule = "view schedule" , listMeetings = "Meetings" ,
    }
}


local _COST_DB_MAIN="0000000";

result = teamyar.get_license_info();
local _CONST_BOT_PREFIX_PATH = "bot/run/2/";
local _CONST_BOT_NAME = "calendar_daily_portal";

local _baseUrl = "https://" .. result.domain .. "/";
local _base = _CONST_BOT_PREFIX_PATH .. _CONST_BOT_NAME;

local _icons = {
    clock =  "/clock.png" ,
    calender =  "/calender.png" ,
    cancel =  "/cancel.png" ,
    persons =  "/persons.png" ,
    arrow =  "/arrow.png" ,
};
local _urls = {
    linkCalender = "?page=/calendar/day" ,
    linkItemClientCalender = "?page=/calendar/event/view/" ,
}
local _styles = {
    { base=true , path=  "/style.css" },
};
local _scripts = {
    { base=true , path=  "/form-controller.js" },
    { base=true , path=  "/script.js" },
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
    if reference ~= nil and #reference>0 and reference[1] ~= nil then
        reference = reference[1]
        return whereQuery.getListIdMulti(param)
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
function getTimeFinishDay(timeDay)
    return tostring(timeDay + 60*60*24*10000000);
end
function getStringTimeToHoursAndMinute(timeSelect)
    local timeHours = time.get_hour(timeSelect);
    local timeMinute = time.get_minute(timeSelect);
    if timeHours < 10 then
        timeHours = "0"..timeHours
    end
    if timeMinute < 10 then
        timeMinute = "0"..timeMinute
    end

    return timeHours .. ":" .. timeMinute;
end

local calendarDaily = {};
function calendarDaily:init()
    self.from_date = 0;
    self.to_date = 0;

    self.styles= "";
    self.scripts= "";
    self.templateHtml= "";

    self.userId = 0;
    self.userFullName = "";

    self.filters = {};

    self.queryDailyCalender = "";
    self.paramsDailyCalender = {};
    self.resultDailyCalender = {  };

    self.timezone = 0;
    return self;
end
function calendarDaily.langIsFa()
    local user =teamyar.get_user_info();
    if user~= nil and user.lang_id ~= nil and user.lang_id==4 then
        return true;
    end
    return false;
end
function calendarDaily:getTimeZone()
    local user =teamyar.get_user_info();
    if user~= nil and user.timezone ~= nil then
         self.timezone = tonumber(user.timezone + 60*60*10000000);
    end
    return self;
end
function calendarDaily:readyTemplateHtml()
    self.templateHtml = teamyar.get_attachment("template.html");
    return self;
end
function calendarDaily:readyStyles()
    for i = 1 ,#_styles , 1 do
        local itemStyle = _styles[i];
        if itemStyle ~= nil and itemStyle.path then
            local path = itemStyle.path;
            if itemStyle.base ~= nil  ~= nil  and itemStyle.base == true then
                path = _base .. itemStyle.path;
            end
            calendarDaily.styles = calendarDaily.styles .. "<link href='"..path.."' rel='stylesheet' />";
        end
    end
    self.templateHtml = string.gsub(self.templateHtml, "{{styles}}", calendarDaily.styles);
    return self;
end
function calendarDaily:readyScripts()
    for i = 1 ,#_scripts , 1 do
        local itemScript = _scripts[i];
        if itemScript ~= nil then
            local path = itemScript.path;
            if itemScript.base ~= nil and itemScript.base == true then
                path = _base .. itemScript.path;
            end
            calendarDaily.scripts = calendarDaily.scripts .. "<script src='"..path.."' ></script>";
        end
    end
    self.templateHtml = string.gsub(self.templateHtml, "{{scripts}}", calendarDaily.scripts);
    return self;
end
function calendarDaily:readyIcons()
    if _icons.clock ~= nil then
        self.templateHtml = string.gsub(self.templateHtml, "{{srcIconClock}}", _base .. _icons.clock);
    end
    if _icons.calender ~= nil then
        self.templateHtml = string.gsub(self.templateHtml, "{{srcIconCalender}}", _base .. _icons.calender);
    end
    if _icons.persons ~= nil then
        self.templateHtml = string.gsub(self.templateHtml, "{{srcIconPersons}}", _base .. _icons.persons);
    end
    if _icons.cancel ~= nil then
        self.templateHtml = string.gsub(self.templateHtml, "{{srcIconCancel}}", _base .. _icons.cancel);
    end
    if _icons.arrow ~= nil then
        self.templateHtml = string.gsub(self.templateHtml, "{{srcIconArrow}}", _base .. _icons.arrow);
    end
    return self;
end
function calendarDaily:readyUrls()
    if _urls.linkCalender ~= nil then
        self.templateHtml = string.gsub(self.templateHtml, "{{urlLinkCalenderClient}}", _urls.linkCalender);
    end
    if _urls.linkCalender ~= nil then
        self.templateHtml = string.gsub(self.templateHtml, "{{linkItemClientCalender}}", _urls.linkItemClientCalender);
    end
    return self;
end
function calendarDaily:readyFilterController()

    if calendarDaily.from_date == 0 or calendarDaily.from_date == nil then
        calendarDaily.from_date = getTimeStartDay();
    end
    calendarDaily.to_date = getTimeFinishDay(calendarDaily.from_date);

    local lang = "en";
    if calendarDaily.langIsFa() then
        lang = "fa";
    end
    local btnSubmitReport = langs[lang].btnSubmitReport;
    self.templateHtml = string.gsub(self.templateHtml, "{{language}}", lang);
    calendarDaily.filters = {
        controller = "form" ,
        data= {
            selector= "#form-controller2",
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
                        type = "COL-2",
                        controls=  {
                            {
                                controller = "DateTimePicker" ,
                                data = {
                                    pickTime= false,
                                    title= '',
                                    width_title= '1',
                                    name= 'from_date',
                                    value = calendarDaily.from_date
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
    self.templateHtml = string.gsub(self.templateHtml, "{{dataControllers}}", json.encode(calendarDaily.filters));
    return self;
end
function calendarDaily:readyUserLoginInfo()
    local user = teamyar.get_user_info();
    if user.name ~= nil and user.family~= nil then
        calendarDaily.userFullName = user.name .. ' ' .. user.family;
    end
    if user.id ~= nil then
        calendarDaily.userId = user.id;
    end
    return self;
end
function calendarDaily:getQueryDailyCalender()
    self.queryDailyCalender = teamyar.get_attachment("query_Daily_calender.txt");
    calendarDaily.queryDailyCalender , calendarDaily.paramsDailyCalender = whereQuery:init()
            :addSqlWhere(tonumber(calendarDaily.from_date) , " DATE_START >= ? " )
            :addSqlWhere(tonumber(calendarDaily.to_date) , " DATE_FINISH <= ? " )
            .run(calendarDaily.queryDailyCalender , calendarDaily.paramsDailyCalender ,"{{whereInvites}}");
    calendarDaily.queryDailyCalender , calendarDaily.paramsDailyCalender = whereQuery:init()
            :addSqlWhere(tonumber(calendarDaily.userId) , " USER_ID = ? " )
            .run(calendarDaily.queryDailyCalender , calendarDaily.paramsDailyCalender ,"{{whereInviteUsers}}");
    calendarDaily.resultDailyCalender = baseQuery:init()
            :setQuery(calendarDaily.queryDailyCalender)
            :setFirst(0)
            :setSelects({ column= 'e.event_id' , alias= 'event_id' } , { column= 'e.event_date_start' , alias= 'event_date_start' } , { column= 'e.event_date_finish' , alias= 'event_date_finish' } , { column= 'e.event_name' , alias= 'event_name' } , { column= 'iu.invite_status' , alias= 'invite_status' } , { column= 'iu.invite_reject_reason' , alias= 'invite_reject_reason' } , { column= 'p.profile_id' , alias= 'profile_id' } , { column= 'p.FULLNAME' , alias= 'FULLNAME' } )
            :setParams(calendarDaily.paramsDailyCalender)
            .fetch();

    for i = 1 , #calendarDaily.resultDailyCalender , 1   do
        local itemCalendar = calendarDaily.resultDailyCalender[i];

        local timeStart = 0;
        local timeEnd = 0;
        if itemCalendar.event_date_start ~=nil then
            timeStart = itemCalendar.event_date_start  + calendarDaily.timezone;
        end
        if itemCalendar.event_date_finish ~=nil then
            timeEnd = itemCalendar.event_date_finish   + calendarDaily.timezone;
        end

        calendarDaily.resultDailyCalender[i]["time_start"] = getStringTimeToHoursAndMinute(timeStart)
        calendarDaily.resultDailyCalender[i]["time_end"] = getStringTimeToHoursAndMinute(timeEnd)
    end
    self.templateHtml = string.gsub(self.templateHtml, "{{calendarRecords}}", json.encode(calendarDaily.resultDailyCalender));
    return self;
end
function calendarDaily.run()
    calendarDaily:getTimeZone():readyTemplateHtml():readyStyles():readyScripts():readyFilterController():readyIcons():readyUrls();
    calendarDaily:readyUserLoginInfo():getQueryDailyCalender();

    return calendarDaily.templateHtml;
end

function calendarDailyRun()
    local bot =  calendarDaily:init();
    setParamToObject(bot ,'from_date' , "number" , 0);
    return bot.run()
end
teamyar.write_result(calendarDailyRun())