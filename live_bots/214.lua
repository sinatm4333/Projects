-- cash_and_bank_balances_filter
local _COST_DB_MAIN="0000000";
local _CONST_ORG_ID_DEFAULT = {1}--{2} ;
local _CONST_ACCOUNT_ID_DEFAULT = {}--{2} ;

local langs= {
    fa = {
        btnSubmitReport = "جستجو" ,
        filterFromDate = "از تاریخ" ,
        filterToDate = "تا تاریخ" ,
        filterOrg = "شعبه" ,
        filterAccount = "حساب" ,
    },
    en = {
        btnSubmitReport = "filter" ,
        filterFromDate = "from date" ,
        filterToDate = "to date" ,
        filterOrg = "organ" ,
        filterAccount = "account" ,
    }
}

result = teamyar.get_license_info();
local _CONST_BOT_PREFIX_PATH = "bot/run/2/";
local _CONST_BOT_NAME = "cash_and_bank_balances_filter";
---
local _baseUrl = "https://" .. result.domain .. "/";
local _botUrl = _CONST_BOT_PREFIX_PATH .. _CONST_BOT_NAME;
local _base = _botUrl;
---
local _type = {
    type_acl = "acl" ,
    type_form = "form"
}
local _icons = {

};
local _urls = {
    linkAcl = _base ,
    linkForm = _botUrl.."?type=".._type.type_form,
    linkReport = _CONST_BOT_PREFIX_PATH .. "cash_and_bank_balances_view" ,
}
local _styles = {
    form = {
        { base=true , path=  "/style.css" },
    },
};
local _scripts = {
    form = {
        { base=true , path=  "/form-controller.js" },
        { base=true , path=  "/script.js" },
    },
};
local _acls = {
    acl_list_orgs = "orgs" ,
    acl_list_pa_account = "pa_account" ,
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
            if array[key] == 1 then
                return true;
            elseif array[key] == 0 then
                return false;
            end
        elseif type(array[key]) == "string" then
            if array[key] == "1" then
                return true;
            elseif array[key] == "0" then
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


function getParamIdInSingle(param)
    local resultId = 0;
    if param ~= nil and param[1] ~= nil  then
        local resItem = param[1];
        if type(resItem) == "table" and resItem.id ~= nil and resItem.id>0 then
            resultId = resItem.id;
        elseif type(resItem) == "number" then
            resultId = resItem;
        end
    end
    return tostring(resultId);
end
function getIdAclSelected(listReferences , isFirst)
    if isFirst == false then
        local list = {};
        for x = 1 , #listReferences , 1   do
            local item = listReferences[x];
            if item.id ~= nil then
                table.insert(list , item.id);
            end
        end
        return list;
    else
        return listReferences;
    end
end
function getRealAclSelected(listReferences , listTotal , isFirst)
    listReferences = getIdAclSelected(listReferences , isFirst)
    local listExp = {};
    for x = 1 , #listReferences , 1   do
        local itemRefId = tonumber(listReferences[x]);
        local itemResult = nil;
        for y = 1 , #listTotal , 1   do
            local item = listTotal[y];
            local itemId = 0;
            local itemName = "";
            if item.id ~= nil then
                itemId = tonumber(item.id);
            end
            if item.name ~= nil then
                itemName = item.name;
            end
            if ( itemName ~= nil and itemId > 0)  and ( itemName ~= nil and itemName ~= "") and itemRefId == itemId then
                itemResult = {
                    id = itemId ,
                    name = itemName
                }
            end
        end
        if itemResult ~= nil then
            table.insert(listExp , itemResult);
        end
    end
    return listExp;
end
function searchInAclStatic(listAcl , search)
    if search ~= null and #search>0 then
        local listExp = {};
        for x = 1 , #listAcl , 1   do
            local itemAcl = listAcl[x];
            if  itemAcl.name ~= nil  then
                if string.find(itemAcl.name, search) then
                    table.insert(listExp , itemAcl);
                end
            end
        end
        return listExp;
    else
        return listAcl;
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
function baseQuery:setTableSelects(selects)
    baseQuery.selects = selects;
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
   -- teamyar.write_result(json.encode(queryData))
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


function startYear()
    local thisYear = getThisYear();
    local timeShamci = {
        year = thisYear ,
        month = 1 ,
        day = 1
    }
    timeShamci = time.to_grigorian(timeShamci);
    local timeMiladi = {
        year =  timeShamci.year ,
        month = timeShamci.month ,
        day = timeShamci.day ,
        hour = 1,
        minute = 1 ,
        second = 1
    };
    return time.get_filetime(json.encode(timeMiladi));
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

local cash_and_bank_balances = {};
function cash_and_bank_balances:init()
    self.from_date = 0;
    self.to_date = 0;

    self.org_id = {  };
    self.pa_account = {  };

    self.type = _type.type_form;
    self.is_first = true;

    self.acl="";
    self.search="";
    self.ref_id=0;

    self.styles= "";
    self.scripts= "";
    self.templateHtml= "";

    self.filters = "";
    return self;
end
function cash_and_bank_balances.langIsFa()
    local user =teamyar.get_user_info();
    if user~= nil and user.lang_id ~= nil and user.lang_id==4 then
        return true;
    end
    return false;
end
function cash_and_bank_balances:readyStyles(section)
    local styleSectionSelected = section
    for i = 1 ,#styleSectionSelected , 1 do
        local itemStyle = styleSectionSelected[i];
        if itemStyle ~= nil and itemStyle.path then
            local path = itemStyle.path;
            if itemStyle.base ~= nil  ~= nil  and itemStyle.base == true then
                path = _base .. itemStyle.path;
            end
            cash_and_bank_balances.styles = cash_and_bank_balances.styles .. "<link href='"..path.."' rel='stylesheet' />";
        end
    end
    self.templateHtml = string.gsub(self.templateHtml, "{{styles}}", cash_and_bank_balances.styles);
    return self;
end
function cash_and_bank_balances:readyScripts(section)
    local scriptsSectionSelected = section
    for i = 1 ,#scriptsSectionSelected , 1 do
        local itemScript = scriptsSectionSelected[i];
        if itemScript ~= nil then
            local path = itemScript.path;
            if itemScript.base ~= nil and itemScript.base == true then
                path = _base .. itemScript.path;
            end
            cash_and_bank_balances.scripts = cash_and_bank_balances.scripts .. "<script src='"..path.."' ></script>";
        end
    end
    self.templateHtml = string.gsub(self.templateHtml, "{{scripts}}", cash_and_bank_balances.scripts);
    return self;
end
function cash_and_bank_balances:getDataTimeDefault()
    if self.from_date == 0 or self.from_date == nil then
        self.from_date = startYear();
    end
    if self.to_date == 0  or self.from_date == nil  then
        self.to_date = getCurrentTime();
    end
    return self;
end
function cash_and_bank_balances:readyFilterController()
    local formSelector = "#form-controller-cash-and-bank-balances";
    local formId = "form-controller";
    local reportUrl = _urls.linkReport;
    local aclUrlOrg = _urls.linkAcl .. "?acl=".._acls.acl_list_orgs.."&search="..cash_and_bank_balances.search.."&type=".._type.type_acl.."&is_first=0";
    local aclUrlPaAccount = _urls.linkAcl .. "?acl=".._acls.acl_list_pa_account.."&search="..cash_and_bank_balances.search.."&type=".._type.type_acl.."&is_first=0&ref_id="..getParamIdInSingle(cash_and_bank_balances.org_id);

    local lang = "en";
    if cash_and_bank_balances.langIsFa() then
        lang = "fa";
    end
    local btnSubmitReport = langs[lang].btnSubmitReport;
    local filterFromDate = langs[lang].filterFromDate;
    local filterToDate = langs[lang].filterToDate;
    local filterOrg = langs[lang].filterOrg;
    local filterAccount = langs[lang].filterAccount;
    cash_and_bank_balances.filters = {
        controller = "form" ,
        data= {
            selector= formSelector,
            id= formId ,
            action= reportUrl,
            method= 'POST',
            ajax = { contentType= "JSON" },
            events = { onformsend = {"ty__main.onGetReportHtmlCashAndBankBalances"} },
            controls = {
                {
                    controller = "layout" ,
                    data = {
                        type = "COL-4",
                        controls=  {
                            {
                                controller = "acl",
                                data = {
                                    name="org_id",
                                    title = filterOrg,
                                    disabled = false,
                                    value= cash_and_bank_balances.org_id,
                                    url = aclUrlOrg,
                                    typevalue = 'object',
                                    multiselect = false,
                                    format = 'input',
                                    --events= { onchange = { 'ty__main.OnChangeFormData' } }
                                }
                            },

                            {
                                controller = "acl",
                                data = {
                                    name="pa_account",
                                    title = filterAccount,
                                    disabled = false,
                                    value= cash_and_bank_balances.pa_account,
                                    url = aclUrlPaAccount,
                                    typevalue = 'object',
                                    multiselect = false,
                                    format = 'input',
                                    --events= { onchange = { 'ty__main.OnChangeFormData' } }
                                }
                            },

                            {
                                controller = "DateTimePicker" ,
                                data = {
                                    title= filterFromDate,
                                    name= 'from_date',
                                    value = cash_and_bank_balances.from_date
                                }
                            } ,
                            {
                                controller = "DateTimePicker" ,
                                data = {
                                    title= filterToDate,
                                    name= 'to_date',
                                    value = cash_and_bank_balances.to_date
                                }
                            } ,

                        }
                    },
                } ,
                {
                    controller = "layout" ,
                    data = {
                        type = "COL-4",
                        controls=  {
                            {
                                controller = "form.submit" ,
                                data = {
                                    type= 'submit' ,
                                    id = "btn-submit-report" ,
                                    title= btnSubmitReport
                                }
                            }

                        }
                    },
                } ,
            }
        }
    }
    self.templateHtml = string.gsub(self.templateHtml, "{{dataControllers}}", json.encode(cash_and_bank_balances.filters));
    self.templateHtml = string.gsub(self.templateHtml, "{{formId}}", formId);
    self.templateHtml = string.gsub(self.templateHtml, "{{formUrl}}", _urls.linkForm);
    return self;
end
function cash_and_bank_balances.renderAclListOrgs()
    local query = teamyar.get_attachment("query_list_orgs.txt");
    local params = {};
    local where = whereQuery:init();
    if (cash_and_bank_balances.search ~= nil or cash_and_bank_balances.search ~= "") then
        where = where:addSqlWhereLike(cash_and_bank_balances.search , "name")
    end
    query , params = where.run(query , params ,"{{whereOrg}}");
    return baseQuery:init():setQuery(query):setFirst(0):setTableSelects({{ column= 'id' , alias= 'id' } , { column= 'name' , alias= 'name' }}):setParams(params).fetch();
end
function cash_and_bank_balances.renderAclListPaAccount()
    local query = teamyar.get_attachment("query_list_pa_account.txt");
    local params = {};

    local orgId = cash_and_bank_balances.getRefOrgId();

    local where = whereQuery:init();
    if (orgId ~= nil) then
        where = where:addSqlWhere(tonumber(orgId) , "org_id=? ")
    end
    if (cash_and_bank_balances.search ~= nil or cash_and_bank_balances.search ~= "") then
        where = where:addSqlWhereLike(cash_and_bank_balances.search , "(concat(CODE , ' - ' , NAME)) ")
    end
    query , params = where.run(query , params ,"{{whereAccount}}");

    return baseQuery:init():setQuery(query):setFirst(0):setTableSelects({{ column= 'id' , alias= 'id' } , { column= 'name' , alias= 'name' }}):setParams(params).fetch();

end
function cash_and_bank_balances.getRefOrgId()
    local refId = cash_and_bank_balances.ref_id;
    if cash_and_bank_balances.is_first then
        refId = getParamIdInSingle(_CONST_ORG_ID_DEFAULT);
    else
        if cash_and_bank_balances.ref_id ~= nil and tonumber(cash_and_bank_balances.ref_id ) > 0  then
            refId = cash_and_bank_balances.ref_id;
        else
            refId = getParamIdInSingle(cash_and_bank_balances.org_id);
        end
    end
    return refId;
end



function cash_and_bank_balances:readyTemplateHtmlForm()
    cash_and_bank_balances.templateHtml = teamyar.get_attachment("template_form.html");
    return self;
end
function cash_and_bank_balances.renderHtmlForm()
    cash_and_bank_balances:readyTemplateHtmlForm():readyStyles(_styles.form):readyScripts(_scripts.form):getDataTimeDefault():readyFilterController();
    return cash_and_bank_balances.templateHtml;
end


function cash_and_bank_balances.run()
    if cash_and_bank_balances.type ~= nil and cash_and_bank_balances.type ~= "" then
        local resultAclListOrgs =cash_and_bank_balances.renderAclListOrgs();
        local resultAclListPaAccount =cash_and_bank_balances.renderAclListPaAccount();
        if (cash_and_bank_balances.type == _type.type_acl) then
            if (cash_and_bank_balances.acl ~= nil or cash_and_bank_balances.acl ~= "")  then
                if cash_and_bank_balances.acl == _acls.acl_list_orgs then
                    return json.encode(resultAclListOrgs);
                end
                if cash_and_bank_balances.acl == _acls.acl_list_pa_account then
                    return json.encode(resultAclListPaAccount);
                end
            end
        elseif (cash_and_bank_balances.type == _type.type_form) then
            local listOrgs = cash_and_bank_balances.org_id;
            local listPaAccount = cash_and_bank_balances.pa_account;
            if cash_and_bank_balances.is_first==true then
                listOrgs = _CONST_ORG_ID_DEFAULT;
                listPaAccount = _CONST_ACCOUNT_ID_DEFAULT;
            end
            cash_and_bank_balances.org_id = getRealAclSelected(listOrgs , resultAclListOrgs , cash_and_bank_balances.is_first);
            cash_and_bank_balances.pa_account = getRealAclSelected(listPaAccount , resultAclListPaAccount , cash_and_bank_balances.is_first);
            return cash_and_bank_balances.renderHtmlForm();
        end
    end
    return "";
end

function cashAndBankBalancesRun()
    local bot =  cash_and_bank_balances:init();
    setParamToObject(bot ,'from_date' , "number");
    setParamToObject(bot ,'to_date' , "number");
    setParamToObject(bot ,'org_id' , "table");
    setParamToObject(bot ,'pa_account' , "table");
    setParamToObject(bot ,'type' , "string" , nil);
    setParamToObject(bot ,'is_first' , "boolean" , false);
    setParamToObject(bot ,'acl' , "string" , nil);
    setParamToObject(bot ,'search' , "string" , nil);
    setParamToObject(bot ,'ref_id' , "int" , 0);
    return bot.run()
end
teamyar.write_result(cashAndBankBalancesRun())