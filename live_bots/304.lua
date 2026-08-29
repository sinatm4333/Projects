-- botName =  res_v2
-- creator =  mehdi-marefiyan
-- date =     12/09/2025
-- version1 = [Modifier: Mehdi_Marefiyan] [Date: 12/09/2025] [Task: #75136] [Description: add select option reportName in input hidden and create structure]
-- version2 = [Modifier: Mehdi_Marefiyan] [Date: 01/19/2026] [Task: #75529] [Description: add type "object" for table inside to inside with one key]
-- version3 = [Modifier: Mehdi_Marefiyan] [Date: 01/19/2026] [Task: #75530] [Description: add fix-config to res_v2 for report ]
-- version4 = [Modifier: Mehdi_Marefiyan] [Date: 01/21/2026] [Task: #75558] [Description: add filter group for report view ]
-- version5 = [Modifier: Mehdi_Marefiyan] [Date: 01/31/2026] [Task: #75651] [Description: Optimization component.js ]
-- version6 = [Modifier: Mehdi_Marefiyan] [Date: 02/01/2026] [Task: #75742] [Description: add json actions in config.js ]
-- version7 = [Modifier: Mehdi_Marefiyan] [Date: 02/21/2026] [Task: #75921] [Description: add type "file" for get list files sended]

--------------------------------------------
--- Requires Lua
--------------------------------------------
function getRequireFileLua()
    local listCodes = {}
    local requires = {
        "install_res.lua" ,
        "config_res_types.lua" , "config_api_types.lua" ,
        "tools_query.lua" , "tools_public.lua"  , "tools_date.lua"  ,  "tools_params.lua" ,   "tools_translate.lua", "tool_md5.lua" ,
        -- "tools_db.lua" ,
        "tools_db_create.lua" ,
        "tools_db_crud.lua" ,
    }
    for i = 1 , #requires, 1 do
        local itemRequireName = requires[i];
        local itemRequireFile = teamyar.get_attachment(itemRequireName);
        table.insert(listCodes , itemRequireFile);
        local loadedFunction, errorMessage = load(itemRequireFile)
        if loadedFunction then
            loadedFunction();
        else
            teamyar.write_log("Error: " .. errorMessage);
        end
    end
    return listCodes;
end
local listCodes = getRequireFileLua();






--------------------------------------------
--- RES Component
--------------------------------------------
configResData = {  };
local resConfigQuery = {
    query = [[
select CONFIG from bot_command
join bot_command_config bcc on bot_command.ID = bcc.COMMAND_ID and flags=1
where run_path = ?
    ]];
    params = {"2/res_v2"}
}

db.query(resConfigQuery)
local resConfigQueryResult = db.query_fetch();
if resConfigQueryResult ~= nil then
    configResData = toTable(resConfigQueryResult[1]);
end

local dirFa = isLangFa();
if dirFa == true then
    configResData.directionRtl = true;
else
    configResData.directionRtl = false;
end









--------------------------------------------
--- RES Report
--------------------------------------------
function ResReport(select_columns_all , extraTemplates , configFilters)
    local outReport = teamyar.get_attachment("out_report.lua")
    local reportFunction = load(outReport);
    reportFunction();

    return  renderHTML(select_columns_all , extraTemplates , configFilters)
end


--------------------------------------------
--- RES template
--------------------------------------------
function ResTemplate(template , extraTemplates , langIdForce)
    return readyMainTemplate(template , extraTemplates , langIdForce);
end


--------------------------------------------
--- RES table
--------------------------------------------
function ResTable(repId , botPath , tableHeaders, tableValues , tableTotal , tableCount , tableFrom , tableSums)
    local outTable = teamyar.get_attachment("out_table.lua")
    local tableFunction = load(outTable);
    tableFunction();
    return readyTemplateTable(repId , botPath , tableHeaders, tableValues , tableTotal , tableCount , tableFrom , tableSums);
end


--------------------------------------------
--- RES cash
--------------------------------------------
function ResCash()
    local outTable = teamyar.get_attachment("out_cash.lua")
    local tableFunction = load(outTable);
    tableFunction();
    return renderCash();
end



--------------------------------------------
--- RES auth
--------------------------------------------
function ResAuth_createToken(tokenKey)
    local outAuth = teamyar.get_attachment("out_auth.lua")
    local reportFunction = load(outAuth);
    reportFunction();

    return createTokenApiWithTime(tokenKey);
end
function ResAuth_checkToken(tokenKey , token)
    local outAuth = teamyar.get_attachment("out_auth.lua")
    local reportFunction = load(outAuth);
    reportFunction();

    return checkTokenApi(tokenKey , token);
end



--------------------------------------------
--- RES otp
--------------------------------------------
function ResOtp_createToken(token ,userInput , timeDuration , otpLength)
    local outOTP = teamyar.get_attachment("out_otp.lua")
    local reportFunction = load(outOTP);
    reportFunction();

    return createOTPLogin(token ,userInput , timeDuration , otpLength);
end
function ResOtp_checkToken(token ,userInput , userOtp , userToken , timeEnd)
    local outOTP = teamyar.get_attachment("out_otp.lua")
    local reportFunction = load(outOTP);
    reportFunction();

    return checkOTPToken(token ,userInput , userOtp , userToken , timeEnd);
end



--------------------------------------------
--- RES query smart
--------------------------------------------
function ResQuerySmart(query_smart , query_smart_headers , query_smart_where , query_smart_params , query_smart_type , query_smart_from, query_smart_per , query_smart_to)
    local outQuerySmart = teamyar.get_attachment("out_query_smart.lua")
    local reportFunction = load(outQuerySmart);
    reportFunction();

    return renderQuerySmart(query_smart , query_smart_headers , query_smart_where , query_smart_params , query_smart_type , query_smart_from, query_smart_per  , query_smart_to);
end


--------------------------------------------
--- RES report smart
--------------------------------------------
function ResReportSmart(botPath , report_smart_headers , report_smart_query , report_smart_where , report_smart_params , report_smart_per , report_smart_tabs)
    local outQuerySmart = teamyar.get_attachment("out_report_smart.lua")
    local reportFunction = load(outQuerySmart);
    reportFunction();

    return renderReportSmart(botPath , report_smart_headers , report_smart_query , report_smart_where , report_smart_params , report_smart_per , report_smart_tabs);
end


--------------------------------------------
--- RES db
--------------------------------------------
function ResDb(tableName , tableColumns)
    return _DB:run(tableName , tableColumns);
end


--------------------------------------------
--- RES db
--------------------------------------------
function ResJsonConvertor(json_convertor)

    teamyar.write_log(json.encode(json_convertor))

    local resultExp = {}

    local params = {
        domain=   json_convertor.domain,
        port=     json_convertor.port,
        url=      json_convertor.url,
        method=   json_convertor.method ,
        header=   json_convertor.headers,
        data=     json_convertor.data ,
        ssl=      true,
        secure=   false,
    }
    local response = teamyar.call_url(params);

    if response ~= nil and response.result ~= nil and response.result.body ~= nil then
        resultExp = toTable(response.result.body )
    end

    return resultExp;
end




--------------------------------------------
--- RES report Default
--------------------------------------------
function viewMain()
    local outQuerySmart = teamyar.get_attachment("view_main.lua")
    local reportFunction = load(outQuerySmart);
    reportFunction();

    return viewMain.run();
end





--------------------------------------------
--- OUTs
--------------------------------------------
local resultExp = {};
local resType = getInput("res_type");
if resType== _TYPE_RES_REPORT then
    local extraTemplates = getInput("extra_templates");
    local select_columns_all = getInput("select_columns_all");
    local configFilters =getInput("config_filters")
    resultExp = ResReport(select_columns_all , extraTemplates , configFilters);
    resultExp = json.encode(resultExp)

elseif resType== _TYPE_RES_TEMPLATE then
    local template =getInput("template")
    local extraTemplates =getInput("extra_templates")
    local langId =getInput("lang_id")
    resultExp = ResTemplate(template , extraTemplates , langId );
    resultExp = json.encode(resultExp)

elseif resType== _TYPE_RES_TABLE then
    local repId = getInput("rep_id");
    local botPath = getInput("botPath");
    local tableHeaders = getInput("table_headers");
    local tableValues = getInput("table_values");
    local tableTotal = getInput("table_total");
    local tableCount = getInput("table_count");
    local tableFrom = getInput("table_from");
    local tableSums = getInput("table_sums");
    resultExp = ResTable(repId , botPath , tableHeaders , tableValues , tableTotal , tableCount , tableFrom , tableSums);
    resultExp = json.encode(resultExp)

elseif resType== _TYPE_RES_CODES then
    resultExp = listCodes
    resultExp = json.encode(resultExp)

elseif resType== _TYPE_RES_CASH then
    resultExp = ResCash();
    resultExp = json.encode(resultExp)

elseif resType== _TYPE_RES_AUTH then
    local type = getInput("type");
    local token = getInput("token");
    local tokenKey = getInput("token_key");
    if type == nil or type == 0 then
        resultExp = ResAuth_createToken(tokenKey);
    else
        resultExp = ResAuth_checkToken(tokenKey , token);
    end
    resultExp = json.encode(resultExp)

elseif resType== _TYPE_RES_OTP then
    local type = getInput("type");
    local token = getInput("token");
    local userInput = getInput("user_input");
    local userOtp = getInput("user_otp");
    local userToken = getInput("user_token");
    local timeEnd = getInput("time_end");
    local timeDuration = getInput("time_duration");
    local otpLength = getInput("otp_length");
    if type == nil or type == 0 then
        resultExp = ResOtp_createToken(token ,userInput , timeDuration , otpLength);
    else
        resultExp = ResOtp_checkToken(token ,userInput , userOtp , userToken , timeEnd);
    end
    resultExp = json.encode(resultExp)

elseif resType== _TYPE_RES_QUERY_SMART then
    local query_smart = getInput("query_smart");
    local query_smart_headers = getInput("query_smart_headers");
    local query_smart_where = getInput("query_smart_where");
    local query_smart_params = getInput("query_smart_params");
    local query_smart_type = getInput("query_smart_type");
    local query_smart_from = getInput("query_smart_from");
    local query_smart_to = getInput("query_smart_to");
    local query_smart_per = getInput("query_smart_per");
    resultExp = ResQuerySmart(query_smart , query_smart_headers , query_smart_where , query_smart_params , query_smart_type , query_smart_from , query_smart_per , query_smart_to);
    resultExp = json.encode(resultExp)


elseif resType== _TYPE_RES_REPORT_SMART then
    local botPath = getInput("botPath");
    local report_smart_headers = getInput("report_smart_headers");
    local report_smart_query = getInput("report_smart_query");
    local report_smart_where = getInput("report_smart_where");
    local report_smart_params = getInput("report_smart_params");
    local report_smart_per = getInput("report_smart_per");
    local report_smart_tabs = getInput("report_smart_tabs");
    resultExp = ResReportSmart(botPath , report_smart_headers , report_smart_query , report_smart_where , report_smart_params , report_smart_per , report_smart_tabs);
    resultExp = json.encode(resultExp);

elseif resType== _TYPE_RES_JSON_CONVERTOR then
    local json_convertor = getInput("json_convertor");
    resultExp = ResJsonConvertor(json_convertor);

    resultExp = json.encode(resultExp);

else
    resultExp = viewMain();

end
teamyar.write_result(resultExp)