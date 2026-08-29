local langs= {
    fa = {
        filterFromDate = "از " , filterToDate = "تا " , btnSubmitReport = "جستجو" , meeting = "برنامه" , attended = "حضور یافته" , rejected = "رد شده" ,
    },
    en = {
        filterFromDate = "from " , filterToDate = "to " , btnSubmitReport = "search" , meeting = "meeting" , attended = "attended" , rejected = "rejected" ,
    }
}

local _COST_DB_MAIN="0000000";
result = teamyar.get_license_info();
local _CONST_BOT_PREFIX_PATH = "bot/run/2/";
local _CONST_BOT_NAME = "schedule_dashboard_portal";

local _baseUrl = "https://" .. result.domain .. "/";
local _base =  _CONST_BOT_PREFIX_PATH .. _CONST_BOT_NAME;

local _icons = {
    clock =  "/clock.png" ,
    calender =  "/calender.png" ,
    cancel =  "/cancel.png" ,
    persons =  "/persons.png" ,
};
local _urls = {
    linkCalender = "?page=/calendar/event/ShowByCal/0" ,
}
local _styles = {
    { base=true , path=  "/style.css" },
    { base=true , path=  "/bootstrap.css" },
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
function shamciToTimestamp()

    local timeShamci = {
        year = 1402 ,
        month = 12 ,
        day = 29
    }
    timeShamci = json.decode(time.to_grigorian(json.encode(timeShamci)));
    local timeMiladi = {
        year =  timeShamci.year ,
        month = timeShamci.month ,
        day = timeShamci.day ,
        hour = 1,
        minute = 1 ,
        second = 1
    };
    return  time.get_filetime(json.encode(timeMiladi));
end
function getTimeLastWeek()
    return tostring(time.current() + 60*60*24*7*10000000);
end
function getTimeFiveHours()
    return tostring(time.current() + 60*60*5*10000000);
end

local scheduleDashboard = {};
function scheduleDashboard:init()
    self.from_date = 0;
    self.to_date = 0;
    self.to_date_last_week = 0;
    self.from_date_first_week_time= 0;
    self.from_date_last_week_time = 0;

    self.styles= "";
    self.scripts= "";
    self.templateHtml= "";

    self.userId = 0;
    self.userFullName = "";

    self.chart = {};
    self.filters = {};

    self.chartCategory = {};
    self.dataCategory = {};

    self.queryTotalCalender = "";
    self.paramsTotalCalender = {};
    self.resultTotalCalender = {  };

    self.scheduleTime = 0;
    self.scheduleMeeting = 0;
    self.scheduleAttended = 0;
    self.scheduleRejected = 0;

    self.queryLastWeekCalender = "";
    self.paramsLastWeekCalender = {};
    self.resultLastWeekCalender = {  };

    self.countScheduleInLastWeek = 0;
    self.countSuccessScheduleInLastWeek = 0;
    self.progressScheduleInLastWeek = 0;

    self.queryLastFiveHours = "";
    self.paramsLastFiveHours = {};
    self.resultLastFiveHours = {  };

    self.timeZone = 0;
    return self;
end
function scheduleDashboard.langIsFa()
    local user =teamyar.get_user_info();
    if user~= nil and user.lang_id ~= nil and user.lang_id==4 then
        return true;
    end
    return false;
end
function scheduleDashboard:getTimeZone()
    local user =teamyar.get_user_info();
    if user~= nil and user.timezone ~= nil then
        self.timezone = tonumber(user.timezone + 60*60*10000000);
    end
    return self;
end
function scheduleDashboard:readyTemplateHtml()
    self.templateHtml = teamyar.get_attachment("template.html");
    return self;
end
function scheduleDashboard:readyStyles()
    for i = 1 ,#_styles , 1 do
        local itemStyle = _styles[i];
        if itemStyle ~= nil and itemStyle.path then
            local path = itemStyle.path;
            if itemStyle.base ~= nil  ~= nil  and itemStyle.base == true then
                path = _base .. itemStyle.path;
            end
            scheduleDashboard.styles = scheduleDashboard.styles .. "<link href='"..path.."' rel='stylesheet' />";
        end
    end
    return self;
end
function scheduleDashboard:readyScripts()
    for i = 1 ,#_scripts , 1 do
        local itemScript = _scripts[i];
        if itemScript ~= nil then
            local path = itemScript.path;
            if itemScript.base ~= nil and itemScript.base == true then
                path = _base .. itemScript.path;
            end
            scheduleDashboard.scripts = scheduleDashboard.scripts .. "<script src='"..path.."' ></script>";
        end
    end
    return self;
end
function scheduleDashboard:readyAttachments()
    self.templateHtml = string.gsub(self.templateHtml, "{{styles}}", scheduleDashboard.styles);
    self.templateHtml = string.gsub(self.templateHtml, "{{scripts}}", scheduleDashboard.scripts);
    return self;
end
function scheduleDashboard:readyIcons()
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
    return self;
end
function scheduleDashboard:readyUrls()
    if _urls.linkCalender ~= nil then
        self.templateHtml = string.gsub(self.templateHtml, "{{urlLinkCalenderClient}}",  _urls.linkCalender);
    end
    return self;
end
function scheduleDashboard:readyUserLoginInfo()
    local user = teamyar.get_user_info();
    if user.name ~= nil and user.family~= nil then
        scheduleDashboard.userFullName = user.name .. ' ' .. user.family;
    end
    if user.id ~= nil then
        scheduleDashboard.userId = user.id;
    end
    self.templateHtml = string.gsub(self.templateHtml, "{{userFullName}}", scheduleDashboard.userFullName);
    return self;
end
function scheduleDashboard:readyFilterController()
    if scheduleDashboard.from_date == 0 then
        scheduleDashboard.from_date = getTimeStartDay();
    end
    if scheduleDashboard.to_date == 0 then
           scheduleDashboard.to_date = getTimeLastWeek();
    end
    local lang = "en";
    if scheduleDashboard.langIsFa() then
        lang = "fa";
    end
    local filterFromDate = langs[lang].filterFromDate;
    local filterToDate = langs[lang].filterToDate;
    local btnSubmitReport = langs[lang].btnSubmitReport;
    self.templateHtml = string.gsub(self.templateHtml, "{{language}}", lang);
    scheduleDashboard.filters = {
        controller = "form" ,
        data= {
            selector= "#form-controller",
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
                        type = "COL-3",
                        controls=  {
                            {
                                controller = "DateTimePicker" ,
                                data = {
                                    pickTime= false,
                                    title= filterFromDate,
                                    width_title= '2',
                                    name= 'from_date',
                                    value = scheduleDashboard.from_date
                                }
                            } ,
                            {
                                controller = "DateTimePicker" ,
                                data = {
                                    pickTime= false,
                                    title= filterToDate,
                                    width_title= '2',
                                    name= 'to_date',
                                    value = scheduleDashboard.to_date
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
    self.templateHtml = string.gsub(self.templateHtml, "{{dataControllers}}", json.encode(scheduleDashboard.filters));
    return self;
end

function scheduleDashboard:getQueryTotalCalender()
    self.queryTotalCalender = teamyar.get_attachment("query_total_calender.txt");
    scheduleDashboard.queryTotalCalender , scheduleDashboard.paramsTotalCalender = whereQuery:init()
            :addSqlWhere(tonumber(scheduleDashboard.from_date) , " DATE_START >= ? " )
            :addSqlWhere(tonumber(scheduleDashboard.to_date) , " DATE_FINISH <= ? " )
            .run(scheduleDashboard.queryTotalCalender , scheduleDashboard.paramsTotalCalender ,"{{whereInvites}}");
    scheduleDashboard.queryTotalCalender , scheduleDashboard.paramsTotalCalender = whereQuery:init()
            :addSqlWhere(tonumber(scheduleDashboard.userId) , " USER_ID = ? " )
            .run(scheduleDashboard.queryTotalCalender , scheduleDashboard.paramsTotalCalender ,"{{whereInviteUsers}}");
    scheduleDashboard.resultTotalCalender = baseQuery:init()
            :setQuery(scheduleDashboard.queryTotalCalender)
            :setFirst(0)
            :setSelects({ column= 'e.event_id' , alias= 'event_id' } , { column= 'e.event_date_start' , alias= 'event_date_start' } , { column= 'e.event_date_finish' , alias= 'event_date_finish' } , { column= 'e.event_name' , alias= 'event_name' } , { column= 'iu.invite_status' , alias= 'invite_status' } , { column= 'iu.invite_reject_reason' , alias= 'invite_reject_reason' } , { column= 'p.profile_id' , alias= 'profile_id' } , { column= 'p.FULLNAME' , alias= 'FULLNAME' } )
            :setParams(scheduleDashboard.paramsTotalCalender)
            .fetch();
    for i = 1 , #scheduleDashboard.resultTotalCalender , 1   do
        local itemSchedule = scheduleDashboard.resultTotalCalender[i];

        local timeStart = 0;
        local timeEnd = 0;
        local invite_status = 0;
        if itemSchedule.event_date_start ~=nil then
            timeStart = itemSchedule.event_date_start;
        end
        if itemSchedule.event_date_finish ~=nil then
            timeEnd = itemSchedule.event_date_finish;
        end
        if itemSchedule.invite_status ~=nil then
            invite_status = itemSchedule.invite_status;
        end
        scheduleDashboard.scheduleTime = scheduleDashboard.scheduleTime + math.ceil(( (timeEnd - timeStart) /(60*10000000)));
        scheduleDashboard.scheduleMeeting = scheduleDashboard.scheduleMeeting + 1;

        if invite_status == 2 then
            scheduleDashboard.scheduleAttended = scheduleDashboard.scheduleAttended + 1;
        elseif invite_status == 3  then
            scheduleDashboard.scheduleRejected = scheduleDashboard.scheduleRejected + 1;
        end
    end
    self.templateHtml = string.gsub(self.templateHtml, "{{timeRecord}}", scheduleDashboard.scheduleTime);
    self.templateHtml = string.gsub(self.templateHtml, "{{meetingRecord}}", scheduleDashboard.scheduleMeeting);
    self.templateHtml = string.gsub(self.templateHtml, "{{attendedRecord}}", scheduleDashboard.scheduleAttended);
    self.templateHtml = string.gsub(self.templateHtml, "{{rejectedRecord}}", scheduleDashboard.scheduleRejected);
    return self;
end
function scheduleDashboard:getQueryLastWeek()
    scheduleDashboard.to_date_last_week = getTimeLastWeek();
    self.queryLastWeekCalender = teamyar.get_attachment("query_total_calender.txt");
    scheduleDashboard.queryLastWeekCalender , scheduleDashboard.paramsLastWeekCalender = whereQuery:init()
            :addSqlWhere(tonumber(scheduleDashboard.from_date) , " DATE_START >= ? " )
            :addSqlWhere(tonumber(scheduleDashboard.to_date_last_week) , " DATE_FINISH <= ? " )
            .run(scheduleDashboard.queryLastWeekCalender , scheduleDashboard.paramsLastWeekCalender ,"{{whereInvites}}");
    scheduleDashboard.queryLastWeekCalender , scheduleDashboard.paramsLastWeekCalender = whereQuery:init()
            :addSqlWhere(tonumber(scheduleDashboard.userId) , " USER_ID = ? " )
            .run(scheduleDashboard.queryLastWeekCalender , scheduleDashboard.paramsLastWeekCalender ,"{{whereInviteUsers}}");
    scheduleDashboard.resultLastWeekCalender = baseQuery:init()
            :setQuery(scheduleDashboard.queryLastWeekCalender)
            :setFirst(0)
            :setSelects({ column= 'e.event_id' , alias= 'event_id' } , { column= 'e.event_date_start' , alias= 'event_date_start' } , { column= 'e.event_date_finish' , alias= 'event_date_finish' } , { column= 'e.event_name' , alias= 'event_name' } , { column= 'iu.invite_status' , alias= 'invite_status' } , { column= 'iu.invite_reject_reason' , alias= 'invite_reject_reason' } , { column= 'p.profile_id' , alias= 'profile_id' } , { column= 'p.FULLNAME' , alias= 'FULLNAME' } )
            :setParams(scheduleDashboard.paramsLastWeekCalender)
            .fetch();

    scheduleDashboard.countScheduleInLastWeek = #scheduleDashboard.resultLastWeekCalender
    for i = 1 , #scheduleDashboard.resultTotalCalender , 1   do
        local itemSchedule = scheduleDashboard.resultTotalCalender[i];

        local invite_status = 0;
        if itemSchedule.invite_status ~=nil then
            invite_status = itemSchedule.invite_status;
        end

        if invite_status == 2 then
            scheduleDashboard.countSuccessScheduleInLastWeek = scheduleDashboard.countSuccessScheduleInLastWeek + 1;
        end
    end
    if scheduleDashboard.countScheduleInLastWeek > 0 then
        scheduleDashboard.progressScheduleInLastWeek = math.ceil((scheduleDashboard.countSuccessScheduleInLastWeek / scheduleDashboard.countScheduleInLastWeek)*100)
    end
    self.templateHtml = string.gsub(self.templateHtml, "{{progressBarPercent}}", scheduleDashboard.progressScheduleInLastWeek);
    self.templateHtml = string.gsub(self.templateHtml, "{{countScheduleInLastWeek}}", scheduleDashboard.countScheduleInLastWeek);
    return self;
end
function scheduleDashboard:getQueryFiveHours()
    scheduleDashboard.from_date_first_week_time = getTimeStartDay();
    scheduleDashboard.to_date_last_week = getTimeLastWeek();
    self.queryLastFiveHours = teamyar.get_attachment("query_total_calender.txt");
    scheduleDashboard.queryLastFiveHours , scheduleDashboard.paramsLastFiveHours = whereQuery:init()
            :addSqlWhere(tonumber(scheduleDashboard.from_date) , " DATE_START >= ? " )
            :addSqlWhere(tonumber(scheduleDashboard.to_date_last_five_hours) , " DATE_FINISH <= ? " )
            .run(scheduleDashboard.queryLastFiveHours , scheduleDashboard.paramsLastFiveHours ,"{{whereInvites}}");
    scheduleDashboard.queryLastFiveHours , scheduleDashboard.paramsLastFiveHours = whereQuery:init()
            :addSqlWhere(tonumber(scheduleDashboard.userId) , " USER_ID = ? " )
            .run(scheduleDashboard.queryLastFiveHours , scheduleDashboard.paramsLastFiveHours ,"{{whereInviteUsers}}");
    scheduleDashboard.resultLastFiveHours = baseQuery:init()
            :setQuery(scheduleDashboard.queryLastFiveHours)
            :setFirst(0)
            :setSelects({ column= 'e.event_id' , alias= 'event_id' } , { column= 'e.event_date_start' , alias= 'event_date_start' } , { column= 'e.event_date_finish' , alias= 'event_date_finish' } , { column= 'e.event_name' , alias= 'event_name' } , { column= 'iu.invite_status' , alias= 'invite_status' } , { column= 'iu.invite_reject_reason' , alias= 'invite_reject_reason' } , { column= 'p.profile_id' , alias= 'profile_id' } , { column= 'p.FULLNAME' , alias= 'FULLNAME' } )
            :setParams(scheduleDashboard.paramsLastFiveHours)
            .fetch();
    scheduleDashboard.chartCategory = {}
    local listCategory = {};
    local timeSelected = tonumber(scheduleDashboard.from_date_first_week_time);
    while(timeSelected < tonumber(scheduleDashboard.to_date_last_week)) do
        local timeEnd = timeSelected + 60*60*24*10000000;
        table.insert(listCategory ,{
            timeStart = timeSelected + scheduleDashboard.timezone  ,
            timeEnd = timeEnd + scheduleDashboard.timezone
        });
        table.insert( scheduleDashboard.chartCategory ,  tostring(time.get_year(timeSelected)) .."/".. tostring(time.get_month(timeSelected)) .."/".. tostring(time.get_day(timeSelected)));
        timeSelected = timeEnd;
    end
    local meeting = {};
    local attended = {};
    local rejected = {};
    for i = 1 , #listCategory , 1   do
        local itemCategory = listCategory[i];


        local timeS = 0;
        local timeE = 0;
        if itemCategory.timeStart ~=nil then
            timeS = itemCategory.timeStart;
        end
        if itemCategory.timeEnd ~=nil then
            timeE = itemCategory.timeEnd;
        end

        local countMeeting = 0;
        local countAttended = 0;
        local countRejected = 0;
        for y = 1 , #scheduleDashboard.resultLastFiveHours , 1   do
            local itemRecord = scheduleDashboard.resultLastFiveHours[y];

            local timeStart = 0;
            local timeEnd = 0;
            local invite_status = 0;
            if itemRecord.invite_status ~=nil then
                invite_status = itemRecord.invite_status;
            end
            if itemRecord.event_date_start ~=nil then
                timeStart = itemRecord.event_date_start;
            end
            if itemRecord.event_date_finish ~=nil then
                timeEnd = itemRecord.event_date_finish;
            end

            if timeS<=timeStart and timeE>timeStart then
                countMeeting = countMeeting + 1;
                if invite_status == 2 then
                    countAttended = countAttended + 1;
                elseif invite_status == 3  then
                    countRejected = countRejected + 1;
                end
            end
        end
        table.insert(meeting , countMeeting);
        table.insert(attended , countAttended);
        table.insert(rejected , countRejected);
    end

    local lang = "en";
    if scheduleDashboard.langIsFa() then
    lang = "fa";
    end
    local meetingText = langs[lang].meeting;
    local attendedText = langs[lang].attended;
    local rejectedText = langs[lang].rejected;
    scheduleDashboard.dataCategory  =  {
        { name= meetingText, data= meeting },
        { name= attendedText, data= attended },
        { name= rejectedText, data= rejected }
    };
    self.templateHtml = string.gsub(self.templateHtml, "{{chartCategory}}", json.encode(scheduleDashboard.chartCategory));
    self.templateHtml = string.gsub(self.templateHtml, "{{dataCategory}}", json.encode(scheduleDashboard.dataCategory));
    return self;
end

function scheduleDashboard.run()
    scheduleDashboard:getTimeZone():readyTemplateHtml():readyStyles():readyScripts():readyAttachments():readyIcons():readyUrls():readyFilterController()
            :readyUserLoginInfo():getQueryTotalCalender():getQueryLastWeek():getQueryFiveHours();
    return scheduleDashboard.templateHtml;
end
---
function scheduleDashboardRun()
    local bot =  scheduleDashboard:init();
    setParamToObject(bot ,'from_date' , "number" , 0);
    setParamToObject(bot ,'to_date' , "number" , 0);
    return bot.run()
end
teamyar.write_result(scheduleDashboardRun())