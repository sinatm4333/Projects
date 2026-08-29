-- botName = login_portal_type_one
-- creator = Mehdi_Maarefian
-- date = 4/29/2024
-- version= 0.7

--------------------------------------------
function isLangFa()
    local lang_id = 4;
    local userInfo = teamyar.get_user_info();
    if userInfo ~= nil and  userInfo.lang_id ~= nil then
        lang_id = userInfo.lang_id;
    end
    if lang_id == 4 then
        return true;
    end
    return false;
end
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
    configResData = json.decode(resConfigQueryResult[1]);
end

local dirFa = isLangFa();
if dirFa == true then
    configResData.directionRtl = true;
else
    configResData.directionRtl = false;
end



------------------
_bot_path = "/public/bot/run/2/login_portal_type_one";

------------------
local listParams =  teamyar.get_input();
page_step = 0; userInvite = ""; lang_id = 4; timeEnd = 0; userOtp = "";userPassword = "";userPasswordConfirm = "";userToken = "";userInput = "";userCountryCode = "";userCode = "";isNewClient = true; isConfirm = true; userLinkId=nil

------------------
--- cf otp
time_duration_sms = 5;
time_duration_email = 5;
time_request_otp = 1;

--- cf box
email_box_id = nil; mobile_box_id = nil; social_media_box_id = nil;
--- cf portal
module_id=nil; profile_category_id=nil;crm_section_id=nil;

--- cf setting
status_use_font = 0;
show_template_animation = 0;
prefix_name_sign_up = "client *** ";
show_user_content=1;url_for_rules="";
url_link_after_login = "";
bg_color_corner = "";
bg_color_btn = "";
default_city_selected = ""; default_country_selected = "";
password_rules = {};
--allowed_characters = nil;

--- cf show
company_name_fa=""; company_name_en="";
company_description_one_fa=""; company_description_one_en="";
company_description_two_fa=""; company_description_two_en="";

--- cf file
company_icon=""; company_logo="";company_background="";list_city_code="";

--- cf field
field_first_name = 0; field_first_name_required = 0;
field_last_name = 0; field_last_name_required = 0;
field_national_code = 0; field_national_code_required = 0;
field_gender = 0; field_gender_required = 0;

field_phone = 0; field_phone_required = 0;
field_mobile = 0; field_mobile_required = 0;
field_email = 0; field_email_required = 0;
field_birthday = 0; field_birthday_required = 0;

field_states = 0; field_states_required = 0;
field_cities = 0; field_cities_required = 0;

field_contact = 0; field_contact_required = 0;



--- cf form
status_show_form_info = 0;
crm_category_id_source=nil; crm_category_id_destination=nil;

--- cf sms register
status_send_register_sms = 0; box_send_register_sms = 0; message_send_register_sms = nil; social_media_box_send_register_sms = nil;

--- cf email register
status_send_register_email = 0; box_send_register_email = 0; subject_send_register_email= nil;message_send_register_email= nil;

local tyConfig = teamyar.get_config();

if tyConfig ~= nil then
    if tyConfig.id ~= nil  then
        _bot_path = _bot_path .. "/".. tyConfig.id;
    end
    if tyConfig.data ~= nil  then
        if tyConfig.data.time_duration_sms then time_duration_sms = tonumber(tyConfig.data.time_duration_sms); end
        if tyConfig.data.time_duration_email then time_duration_email = tonumber(tyConfig.data.time_duration_email); end
        if tyConfig.data.time_request_otp then time_request_otp = tonumber(tyConfig.data.time_request_otp); end

        if tyConfig.data.email_box_id then email_box_id = tonumber(tyConfig.data.email_box_id); end
        if tyConfig.data.mobile_box_id then mobile_box_id = tonumber(tyConfig.data.mobile_box_id); end
        if tyConfig.data.social_media_box_id then social_media_box_id = tonumber(tyConfig.data.social_media_box_id); end

        if tyConfig.data.module_id then module_id = tonumber(tyConfig.data.module_id); end
        if tyConfig.data.profile_category_id then profile_category_id = tonumber(tyConfig.data.profile_category_id); end
        if tyConfig.data.crm_section_id then crm_section_id = tonumber(tyConfig.data.crm_section_id); end

        if tyConfig.data.status_use_font then status_use_font = tonumber(tyConfig.data.status_use_font); end
        if tyConfig.data.show_template_animation then show_template_animation = tonumber(tyConfig.data.show_template_animation); end
        if tyConfig.data.show_user_content then show_user_content = tonumber(tyConfig.data.show_user_content) end
        if tyConfig.data.prefix_name_sign_up then prefix_name_sign_up = tyConfig.data.prefix_name_sign_up; end
        if tyConfig.data.url_for_rules then url_for_rules = tyConfig.data.url_for_rules; end
        if tyConfig.data.url_link_after_login then url_link_after_login = tyConfig.data.url_link_after_login; end
        if tyConfig.data.bg_color_corner then bg_color_corner = tyConfig.data.bg_color_corner; end
        if tyConfig.data.bg_color_btn then bg_color_btn = tyConfig.data.bg_color_btn; end
        if tyConfig.data.default_city_selected then default_city_selected = tyConfig.data.default_city_selected; end
        if tyConfig.data.default_country_selected and #tyConfig.data.default_country_selected > 0 then
            local countrySelectedTable = tyConfig.data.default_country_selected;
            if countrySelectedTable ~= nil then
                countrySelectedTable = json.decode(countrySelectedTable)
                if  countrySelectedTable[1]  ~= nil and countrySelectedTable[1].id ~= nil  then
                    default_country_selected = countrySelectedTable[1].id;
                end
            end
        end
        if tyConfig.data.password_rules then
            local password_rulesTable = tyConfig.data.password_rules;
            if password_rulesTable ~= nil then
                password_rulesTable = json.decode(password_rulesTable)
                if password_rulesTable ~= nil and type(password_rulesTable) == "table" then
                    for index, item in ipairs(password_rulesTable) do
                        if item ~= nil and item.status_customform ~= nil and item.status_customform.value ~= nil and tonumber(item.status_customform.value) == 1
                                and  item.rule_customform ~= nil and item.rule_customform.key ~= nil then

                            local itemRule = {
                                rule = item.rule_customform.key ,
                                arg = nil,
                            };
                            if item.arg_customform ~= nil and item.arg_customform.value ~= nil and item.arg_customform.value ~= "" then
                                itemRule.arg = item.arg_customform.value;
                            end
                            table.insert(
                                    password_rules ,
                                    itemRule
                            )
                        end
                    end
                end
            end
        end


        if tyConfig.data.company_name_fa then company_name_fa = tyConfig.data.company_name_fa; end
        if tyConfig.data.company_name_en then company_name_en = tyConfig.data.company_name_en; end

        if tyConfig.data.company_description_one_fa then company_description_one_fa = tyConfig.data.company_description_one_fa; end
        if tyConfig.data.company_description_one_en then company_description_one_en = tyConfig.data.company_description_one_en; end

        if tyConfig.data.company_description_two_fa then company_description_two_fa = tyConfig.data.company_description_two_fa; end
        if tyConfig.data.company_description_two_en then company_description_two_en = tyConfig.data.company_description_two_en; end

        if tyConfig.data.company_icon then company_icon = tyConfig.data.company_icon; end
        if tyConfig.data.company_logo then company_logo = tyConfig.data.company_logo; end
        if tyConfig.data.company_background then company_background = tyConfig.data.company_background; end
        if tyConfig.data.list_city_code then list_city_code = tyConfig.data.list_city_code; end

        if tyConfig.data.field_first_name then field_first_name = tonumber(tyConfig.data.field_first_name); end
        if tyConfig.data.field_first_name_required then field_first_name_required = tonumber(tyConfig.data.field_first_name_required); end

        if tyConfig.data.field_last_name then field_last_name = tonumber(tyConfig.data.field_last_name); end
        if tyConfig.data.field_last_name_required then field_last_name_required = tonumber(tyConfig.data.field_last_name_required); end

        if tyConfig.data.field_birth_date then field_birth_date = tonumber(tyConfig.data.field_birth_date); end

        if tyConfig.data.field_national_code then field_national_code = tonumber(tyConfig.data.field_national_code); end
        if tyConfig.data.field_national_code_required then field_national_code_required = tonumber(tyConfig.data.field_national_code_required); end

        if tyConfig.data.field_gender then field_gender = tonumber(tyConfig.data.field_gender); end
        if tyConfig.data.field_gender_required then field_gender_required = tonumber(tyConfig.data.field_gender_required); end

        if tyConfig.data.field_phone then field_phone = tonumber(tyConfig.data.field_phone); end
        if tyConfig.data.field_phone_required then field_phone_required = tonumber(tyConfig.data.field_phone_required); end

        if tyConfig.data.field_mobile then field_mobile = tonumber(tyConfig.data.field_mobile); end
        if tyConfig.data.field_mobile_required then field_mobile_required = tonumber(tyConfig.data.field_mobile_required); end

        if tyConfig.data.field_email then field_email = tonumber(tyConfig.data.field_email); end
        if tyConfig.data.field_email_required then field_email_required = tonumber(tyConfig.data.field_email_required); end

        if tyConfig.data.field_contact then field_contact = tonumber(tyConfig.data.field_contact); end
        if tyConfig.data.field_contact_required then field_contact_required = tonumber(tyConfig.data.field_contact_required); end

        if tyConfig.data.field_birthday then field_birthday = tonumber(tyConfig.data.field_birthday); end
        if tyConfig.data.field_birthday_required then field_birthday_required = tonumber(tyConfig.data.field_birthday_required); end

        if tyConfig.data.field_states then field_states = tonumber(tyConfig.data.field_states); end
        if tyConfig.data.field_states_required then field_states_required = tonumber(tyConfig.data.field_states_required); end

        if tyConfig.data.field_cities then field_cities = tonumber(tyConfig.data.field_cities); end
        if tyConfig.data.field_cities_required then field_cities_required = tonumber(tyConfig.data.field_cities_required); end

        if tyConfig.data.status_show_form_info then status_show_form_info = tonumber(tyConfig.data.status_show_form_info); end
        if tyConfig.data.crm_category_id_source then crm_category_id_source = tonumber(tyConfig.data.crm_category_id_source); end
        if tyConfig.data.crm_category_id_destination then crm_category_id_destination = tonumber(tyConfig.data.crm_category_id_destination); end

        if tyConfig.data.status_send_register_sms then status_send_register_sms = tonumber(tyConfig.data.status_send_register_sms); end
        if tyConfig.data.social_media_box_send_register_sms then  social_media_box_send_register_sms = tonumber(tyConfig.data.social_media_box_send_register_sms); end
        if tyConfig.data.box_send_register_sms then  box_send_register_sms = tonumber(tyConfig.data.box_send_register_sms); end
        if tyConfig.data.message_send_register_sms then message_send_register_sms = tyConfig.data.message_send_register_sms; end

        if tyConfig.data.status_send_register_email then status_send_register_email = tonumber(tyConfig.data.status_send_register_email); end
        if tyConfig.data.box_send_register_email then box_send_register_email = tonumber(tyConfig.data.box_send_register_email); end
        if tyConfig.data.subject_send_register_email then subject_send_register_email = tyConfig.data.subject_send_register_email; end
        if tyConfig.data.message_send_register_email then message_send_register_email = tyConfig.data.message_send_register_email; end

    end
end


if listParams ~= nil  then
    if listParams.page_step ~= nil then page_step = tonumber(listParams.page_step); end
    if listParams.userInvite ~= nil then userInvite = listParams.userInvite; end
    if listParams.lang_id ~= nil then lang_id = tonumber(listParams.lang_id); end
    if listParams.timeEnd ~= nil then timeEnd = tonumber(listParams.timeEnd); end
    if listParams.userOtp ~= nil then userOtp = listParams.userOtp; end
    if listParams.userPassword ~= nil then userPassword = listParams.userPassword; end
    if listParams.userPasswordConfirm ~= nil then userPasswordConfirm = listParams.userPasswordConfirm; end
    if listParams.userToken ~= nil then userToken = listParams.userToken; end
    if listParams.userInput ~= nil then userInput = listParams.userInput; end
    if listParams.userLinkId ~= nil then userLinkId = listParams.userLinkId; end
    if listParams.userCode ~= nil then userCode = listParams.userCode; end
    if listParams.userCountryCode ~= nil then userCountryCode = listParams.userCountryCode; end
    if listParams.isNewClient ~= nil then isNewClient = listParams.isNewClient; end
    if listParams.isConfirm ~= nil then isConfirm = listParams.isConfirm; end
end

------------------
function getUserAuthId()
    local query = teamyar.get_attachment("query_get_user_id.txt");
    local queryData = { query= query, params = {string.gsub(userInput, "^0", "") , string.gsub(userInput, "^0", "") } };
    db.query(queryData)
    local record= db.query_fetch();
    if record ~= nil and record[1] ~= nil then
        return  record[1];
    end
    return 0;
end
------------------
function createTokenLogin(isEmail , isMobile)
    local duration = 0;
    if isMobile == true then
        duration = time_duration_sms;
    elseif isEmail == true then
        duration = time_duration_email;
    end

    local code = math.random(math.pow(10 , 5) ,math.pow(10 , 6) -1);
    local timeUnix = (getTimeUnix() +  duration*60)*1000;
    local token = createTokenFromData(code  , timeUnix) ;
    return token , code , timeUnix;
end
function createTokenFromData(code  , timeUnix)
    return coding.sha256(tostring("]15]!j9OpKCS$97BDn5.*2<./Q2jn(@f") .. "#" .. tostring(userInput) .. "#" .. tostring(code) .. "#" .. string.format('%d', timeUnix))
end
function getTimeUnix(timeInsert)
    if timeInsert == nil then
        timeInsert = time.current();
    end
    --[[return math.floor(timeInsert / 10000000) - 11644473600;]]
    return time.get_unixtime(timeInsert);
end
function checkTokenToken()  -- [0,f] token or otp not valid   [1,f] token is expire  [nil ,t] token is true
    local resultExp = { status = false , code = 0 };
    local token = createTokenFromData( userOtp  , timeEnd);
    if token == userToken then
        resultExp.code =1;
        if ((getTimeUnix())*1000) <=timeEnd then
            resultExp.code =nil; resultExp.status = true;
        end
    end
    return resultExp;
end
---
function isLangFa()
    if lang_id == 4 then
        return true;
    end
    return false;
end
function getListLang()
    local  listLang = {};
    local config = json.decode(teamyar.get_attachment("data.txt"));
    if config ~= nil and config.languages~= nil then
        local lang = config.languages;
        local isFa = isLangFa();
        if lang ~=nil  then
            if isFa == true and lang.fa~= nil then
                listLang = lang.fa;
            elseif isFa == false and lang.en~= nil then
                listLang = lang.en;
            end
        end
    end
    return listLang;
end
function convertFileToBase64(file)
    local file_manager = teamyar.create_file_manager(file.module_id);
    local file_data = file_manager:readFileBase64(file.id);
    file_manager:release();
    return "data:"..file.mime..";base64,"..file_data;
end
function translateTemplate(templateFile)
    local template = teamyar.get_attachment(templateFile);
    local listLang = getListLang();
    for key, trans in pairs(listLang) do
        template = string.gsub(template, "{{"..key.."}}", trans);
    end

    template = string.gsub(template , "{{_bot_path}}" , _bot_path);

    template = string.gsub(template , "{{_show_user_invite}}" , show_user_content);
    template = string.gsub(template , "{{_link_rule_furexer}}" , url_for_rules);

    local dirFa = isLangFa();
    local companyName = company_name_fa;
    local companyDescriptionOne = company_description_one_fa;
    local companyDescriptionTwo = company_description_two_fa;
    local fontName = "font_fa.woff"
    if dirFa == false then
        companyName = company_name_en;
        companyDescriptionOne = company_description_one_en;
        companyDescriptionTwo = company_description_two_en;
        fontName = "font_en.woff";
    end
    template = string.gsub(template , "{{_company_name}}" , companyName);
    template = string.gsub(template , "{{_company_description_one}}" , companyDescriptionOne);
    template = string.gsub(template , "{{_company_description_two}}" , companyDescriptionTwo);

    if company_logo ~= nil and company_logo[1] ~= nil then
        local company_logo_base64 = convertFileToBase64(company_logo[1]);
        template = string.gsub(template , "{{_company_logo}}" , company_logo_base64);
        --template = string.gsub(template , "{{_company_logo}}" , "/bot/command/filedownload/"..company_logo[1].id);
    end

    if company_icon ~= nil and company_icon[1] ~= nil then
        local company_icon_base64 = convertFileToBase64(company_icon[1]);
        template = string.gsub(template , "{{_company_icon}}" , company_icon_base64);
    end

    if company_background ~= nil and company_background[1] ~= nil then
        local company_background_base64 = convertFileToBase64(company_background[1]);
        template = string.gsub(template , "{{_company_background}}" , company_background_base64);
    end

    local font_selected = "";
    if status_use_font ~= nil and status_use_font == 1 then
        font_selected = [[
        @font-face {
            font-family: 'font_selectd';
            font-style: normal;
            font-weight: 500;
            src: url(']].._bot_path.."/"..fontName..[[') format('woff');
        }
        body {
            font-family: "font_selectd", Tahoma !important;
        }
        ]]
    end
    template = string.gsub(template , "{{_font_selected}}" , font_selected);

    local template_animation = "";
    if show_template_animation~= nil and show_template_animation == 1 then
        template_animation = teamyar.get_attachment("template_animation.html");
    end
    template = string.gsub(template , "{{_template_animation}}" , template_animation);

    local listCountries = teamyar.get_attachment("ty__country_list.json");
    template = string.gsub(template , "{{_list_countries}}" , listCountries);
    template = string.gsub(template , "{{_default_country_selected}}" , json.encode(default_country_selected));


    local dirFa = isLangFa();
    local direction = "rtl";
    local float = "right";
    if dirFa == false then
        direction = "ltr";
        float = "left";
    end

    template = string.gsub(template , "{{_direction_css}}" , direction);
    template = string.gsub(template , "{{_float_css}}" , float);
    template = string.gsub(template , "{{_lang_id}}" , lang_id);
    template = string.gsub(template , "{{_module_id}}" , module_id);
    template = string.gsub(template , "{{_user_input}}" , userInput);
    template = string.gsub(template , "{{_user_code}}" , userCode);
    template = string.gsub(template , "{{_user_invite}}" , userInvite);

    template = string.gsub(template , "{{_bg_color_corner}}" , bg_color_corner);
    template = string.gsub(template , "{{_bg_color_btn}}" , bg_color_btn);


    local componentData = {};
    if configResData ~= mil then
        componentData = configResData
    end
    template = string.gsub(template , "{{_config_component}}" , json.encode(componentData));

    return template;
end
function getLangSelected(key)
    local listLang = getListLang();
    if listLang ~= nil and listLang[key] ~= nil then
        return listLang[key];
    end
    return key;
end
function getListMessage(messages)
    local listMessages = nil;
    local listMessagesStr = "";
    local displayMessage = "d-none";
    if messages ~= nil and type(messages) == "table" and #messages > 0 then
        listMessages = {}; displayMessage = "";
        for i = 1 , #messages , 1 do
            local trans = getLangSelected(messages[i]);
            table.insert(listMessages , trans);
            listMessagesStr = listMessagesStr..trans.."</br>";
        end
    end
    return listMessages , listMessagesStr , displayMessage;
end
----------------
function runTemplateMain()

    local template = translateTemplate("template_main.html");

    return template;
end
---
function runTemplateSignUp(errors , infos)
    local listMessage , messages , displayMessage = getListMessage(infos);
    local dirFa = isLangFa();
    local iconGoogleMargin = "10px 100px 10px 0";
    if dirFa == false then
        iconGoogleMargin = "10px 0 10px 100px";
    end
    local template = translateTemplate("template_sign_up.html");
    template = string.gsub(template , "{{_margin_icon_google}}" , iconGoogleMargin);
    template = string.gsub(template , "{{_display_message}}" , displayMessage);
    template = string.gsub(template , "{{_text_message}}" , messages);
    return json.encode({ userInput = userInput , userInvite = userInvite , userCode = userCode , errors = getListMessage(errors) , view= template })
end
---
function runTemplateConfirm(errors , isConfirm , infos , showView , withToken)
    if infos == nil then
        infos = { }
    end
    local data = { userInput = userInput , userCountryCode = userCountryCode , userInvite = userInvite , userCode = userCode , setTimer=true };
    local withData = false;
    if showView == nil or (showView ~= nil and showView == true) then
        withData = true;
    end
    if userInput ~= "" then
        local responseCode = true;
        if isConfirm == nil then
            isConfirm = true
        end
        local isNewClient , validInput , isEmail , isMobile = checkExistUserSelected();


        data.isConfirm = isConfirm;
        data.isNewClient = isNewClient;
        if isNewClient == false and isConfirm == false then
            table.insert(infos , '_info_change_password_fields');
        end
        if validInput == true then
            local listMessage , messages , displayMessage = getListMessage(infos);

            data.userInput = userInput;
            data.userInvite = userInvite;
            data.userCode = userCode;
            data.check = "/public/bot/run/2/login_portal_type_one/check.png";
            data.unCheck = "/public/bot/run/2/login_portal_type_one/un-check.png";
            data.rules=getRulesPasswords();

            if withData == true then
                if  (isNewClient == true and isConfirm == true) then
                    local token , code , timeEnd = sendToUserInput(isEmail , isMobile);
                    data.userToken = token;
                    data.timeEnd = timeEnd;
                elseif  (isNewClient == false and isConfirm == false)  then
                    responseCode = sendToUserInput(isEmail , isMobile , true);
                end
            else
                if withToken ~= nil and withToken==true then
                    data.userToken = userToken;
                    data.timeEnd = timeEnd;
                else
                    data.setTimer = false;
                end
            end
            data.timeDurationRequest = (getTimeUnix() + time_request_otp*60)*1000;

            if isEmail == true then
                data.durationForEndTime = time_duration_email;
                data.durationForNewRequestTime = data.durationForEndTime;
            else
                data.durationForEndTime = time_duration_sms;
                data.durationForNewRequestTime = data.durationForEndTime;
            end

            --data.durationForNewRequestTime = time_request_otp;

            if responseCode == true then
                local template = translateTemplate("template_confirm.html");
                template = string.gsub(template , "{{_input_otp}}" , userInput);
                template = string.gsub(template , "{{_display_message}}" , displayMessage);
                template = string.gsub(template , "{{_text_message}}" , messages);


                userCountryTel = "";
                if isMobile == true then
                    local listCountries = teamyar.get_attachment("ty__country_list.json");
                    listCountries = json.decode(listCountries)
                    if listCountries ~= nil and type(listCountries) == "table" then
                        for index, itemCountry in ipairs(listCountries) do
                            if itemCountry ~= nil and itemCountry.code ~= nil and itemCountry.tel ~= nil and itemCountry.code == userCountryCode then
                                userCountryTel = itemCountry.tel .. " - ";
                                break;
                            end
                        end
                    end
                end
                template = string.gsub(template , "{{_user_country_tel}}" , userCountryTel );


                data["view"] =  template

                if type(errors) == "string" then
                    data["errors"] = errors;
                elseif type(errors) == "table" then
                    data["errors"] = getListMessage(errors);
                end
                return json.encode(data)
            else
                return runTemplateSignUp({"_error_in_process"});
            end
        else
            return runTemplateSignUp({"_error_invalid_input"});
        end
    else
        return runTemplateSignUp({"_error_empty_user_input"});
    end
end
function getRulesPasswords()
    local rules = {};

    if password_rules ~= nil and type(password_rules) == "table" then
        for index, itemRule in ipairs(password_rules) do
            if itemRule ~= nil and itemRule.rule ~= nil then

                local itemResult = {
                    title = nil ,
                    rule = itemRule.rule,
                    params = nil ,
                };
                local arg = itemRule.arg;
                local status = false;

                if itemRule.rule == "_char_length" then
                    itemResult.title = getLangSelected("_rule_characters_length")
                    status = true;
                    local min = 1;
                    if arg ~= nil then
                        min = tonumber(arg)
                    end
                    itemResult.params = {min = min}
                    itemResult.title = string.gsub(itemResult.title , "{{min}}" , min);

                elseif itemRule.rule  == "_num_length" then
                    itemResult.title = getLangSelected("_rule_numbers_length")
                    status = true;
                    local min = 1;
                    if arg ~= nil then
                        min = tonumber(arg)
                    end
                    itemResult.params = {min = min};
                    itemResult.title = string.gsub(itemResult.title , "{{min}}" , min);

                elseif itemRule.rule  == "_text_length" then
                    itemResult.title = getLangSelected("_rule_text_length")
                    status = true;
                    local min = 1;
                    if arg ~= nil then
                        min = tonumber(arg)
                    end
                    itemResult.params = {min = min};
                    itemResult.title = string.gsub(itemResult.title , "{{min}}" , min);

                elseif itemRule.rule  == "_text_forbidden" then
                    itemResult.title = getLangSelected("_rule_text_not_exist")
                    status = true;
                    local chars = {};
                    if arg ~= nil then
                        for part in arg:gmatch("([^,]+)") do
                            table.insert(chars, part)
                        end
                        if #arg > 0 then
                            itemResult.title =  itemResult.title ..  getLangSelected("_rule_text_not_exist_expect") .. "(" .. arg .. ")";
                        end

                    end
                    itemResult.params = {chars = chars};

                elseif itemRule.rule  == "_text_char_upper" then
                    itemResult.title = getLangSelected("_rule_exist_char_upper")
                    status = true;
                    local min = 1;
                    if arg ~= nil then
                        min = tonumber(arg)
                    end
                    itemResult.params = {min = min};
                    itemResult.title = string.gsub(itemResult.title , "{{min}}" , min);

                end

                if status == true then
                    table.insert(rules , itemResult)
                end

            end
        end
    end
    return rules;
end
---
function runChangePassword(errors)
    return runTemplateConfirm(errors , false )
end
---
function runFinishLogin()

    if ((isNewClient == true and isConfirm == true) or (isNewClient == false and isConfirm == false)) then
        if userOtp ~= "" and #userOtp == 6 then
            if userPassword ~= userPasswordConfirm  then
                return runTemplateConfirm({"_error_not_some_password"}  , isConfirm , nil , false , true);
            end
        else
            return runTemplateConfirm({"_error_empty_user_otp"}  , isConfirm , nil , false , true);
        end
    end

    if isNewClient == true and isConfirm == true  then
        local checkToken = checkTokenClient();
        if checkToken == nil then
            return checkRegisterClient();
        else
            return checkToken;
        end
    elseif isNewClient == false and isConfirm == false then
        return checkChangePassword();
    else
        return checkLoginClient();
    end
end

---
function runGetNewToken()
    local isNewClient , validInput , isEmail , isMobile = checkExistUserSelected();
    local token , code , timeEnd = sendToUserInput(isEmail , isMobile);
    local timeDurationRequest = (getTimeUnix() + time_request_otp*60)*1000;
    return json.encode({
        setTimer=true ,
        userInput = userInput ,
        userInvite = userInvite ,
        userCode = userCode ,
        userToken= token ,
        timeEnd= timeEnd ,
        isConfirm = true ,
        isNewClient = true ,
        timeDurationRequest = timeDurationRequest ,

        durationForEndTime = time_duration ,
        durationForNewRequestTime = time_request_otp ,

        infos = {getLangSelected("_text_otp")}
    })
end
---
function runTemplate404(errors)
    return json.encode({ userInput = userInput , userInvite = userInvite , userCode = userCode , errors = getListMessage(errors) , view = translateTemplate("template_404.html") })
end
---
function checkLoginClient()
    local data = {login= userInput, password= userPassword , portal_id= module_id, lang_id= lang_id} ;
    if userLinkId ~= nil and userLinkId ~= "" then
        data.link_id = userLinkId;
    end
    local response = teamyar.call_api( 2 , "/api/user/login",  {login= userInput, password= userPassword , portal_id= module_id, lang_id= lang_id, link_id=userLinkId} );

    if response ~= nil and  response.success == true and response.data ~= nil then
        local data = response.data;
        if data.result_type == 0 and data.headers ~= nil then
            for i,v in ipairs(data.headers) do
                teamyar.set_http_header(v.header,v.value);
            end
            return managerForLoginPortal();
        elseif data.links ~= nil and type(data.links) == "table" and #data.links>0 then
            local temp = teamyar.get_attachment("template_link.html");
            temp = string.gsub(temp , "{{_list_link}}" , json.encode(data.links))

            return json.encode({tempLink = temp , params = listParams});
        elseif data.result_type > 0 and data.message~=nil then
            return runTemplateConfirm({data.message}   , isConfirm , nil , false , true);
        end
    else
        return runTemplateConfirm({"_error_invalid_password"}   , isConfirm , nil , false , false);
    end
end
---
function checkChangePassword()
    local isNewClient , validInput , isEmail , isMobile , profileId = checkExistUserSelected();
    if isNewClient==false and validInput == true  then
        local response = teamyar.call_api( 2 , "/api/user/password/forgot/change",  {mobile_email= userInput , portal_id= module_id, security_code= userOtp , new_password=userPassword , confirm_password=userPasswordConfirm} );
        if response ~= nil and  response.success == true then
            return runTemplateSignUp(nil , {"_info_change_password_success"});
        end
    end
    return runChangePassword({ "_error_in_process" });
end
---
function checkRegisterClient()
    local isNewClient , validInput , isEmail , isMobile = checkExistUserSelected();
    local params = {};
    if isEmail == true then
        params = { section_id=crm_section_id , profile = { name = prefix_name_sign_up .. userInput , email = { { value= userInput } } } }
    elseif isMobile == true then
        params = { section_id=crm_section_id , profile = { name = prefix_name_sign_up .. userInput , mobile = { { value= string.gsub(userInput, "^0", ""), country=userCountryCode } } } }
    end
    local responseCreateClient = teamyar.call_api( 14 , "api/client/create",  params );
    if responseCreateClient ~= nil and responseCreateClient.success == true and responseCreateClient.data~= nil and responseCreateClient.data.profile_id ~= nill then
        local profileId = responseCreateClient.data.profile_id;
        if userInvite ~= nil and userInvite ~= "" then
            teamyar.call_api( 14 , "/api/client/contact/add",  { id =  profileId, contact = { { type = 3 , contact_id = userInvite } } } );
        end
        local responseCreatePortal = teamyar.call_api( 14 , "/api/client/portal/add",  { id =  profileId, lang_id = lang_id , password = userPassword, portal_id = module_id, category_profile_id =  profile_category_id } );

        if responseCreatePortal~= nil and   responseCreatePortal.success==true then
            sendSmsRegister(isMobile)
            sendEmailRegister(isEmail)
            return checkLoginClient();
        end
    end
    return runTemplate404({"_error_in_process"});
end
function sendSmsRegister(isMobile)
    if status_send_register_sms ~= nil and status_send_register_sms == 1
            and message_send_register_sms ~= nil
            and isMobile ~= nil and isMobile==true then

        local paramPhone =  {
            box_id = nil  ,
            messages = {
                {
                    content = message_send_register_sms ,
                    send_to = {
                        mobile_numbers = {
                            {
                                value =  userInput ,
                                country = userCountryCode
                            }
                        }
                    }
                }
            }
        }

        if box_send_register_sms ~= nil and mobile_box_id ~= "" then
            paramPhone.box_id = mobile_box_id;
            local resPhone = teamyar.call_api(16 , "/api/sms/send" , paramPhone);
        end
        if social_media_box_send_register_sms ~= nil and social_media_box_send_register_sms ~= "" then
            paramPhone.box_id = social_media_box_send_register_sms;
            local resWhatsUp = teamyar.call_api(16 , "/api/sms/send" , paramPhone);
        end

    end
end

function sendEmailRegister(isEmail)
    if status_send_register_email ~= nil and status_send_register_email == 1
            and box_send_register_email ~= nil
            and subject_send_register_email ~= nil
            and message_send_register_email ~= nil
            and isEmail ~= nil and isEmail==true then
        local paramEmail =  {
            box_id = box_send_register_email ,
            address = userInput ,
            email_content = message_send_register_email ,
            email_subject = subject_send_register_email
        }
        local resEmail = teamyar.call_api(12 , "/api/email/emailmsgadd" , paramEmail);
    end
end
---
function checkTokenClient()
    local checkTokenNotInvalid , checkTokenNotExpire = checkUserToken();
    if checkTokenNotInvalid == false then
        return runTemplateConfirm({"_error_invalid_token"}   , isConfirm , nil , false , false);
    elseif checkTokenNotExpire == false then
        return runTemplateConfirm({"_error_expire_token"}  , isConfirm , nil , false , false);
    end
    return nil;
end
function checkUserToken()
    local checkTokenNotInvalid = false;
    local checkTokenNotExpire = false;
    local checkToken = checkTokenToken();
    if checkToken.status ~= nil then
        if checkToken.code ~= nil then
            if checkToken.status == false then
                checkTokenNotInvalid = true;
                if checkToken.code == 0 then
                    checkTokenNotInvalid = false
                end
                if checkToken.code == 1 then
                    checkTokenNotExpire = false
                end
            end
        elseif checkToken.status == true then
            checkTokenNotInvalid = true;
            checkTokenNotExpire = true;
        end
    end
    return checkTokenNotInvalid , checkTokenNotExpire;
end
---
function checkExistUserSelected()
    local isNewClient = true; local validInput = true; local isEmail = false; local isMobile = false; local profileId = nil;
    local client =  teamyar.call_api(14 , "/api/client/check" , { email = { { value = userInput } }, mobile = { { value = userInput , country = userCountryCode } } });
    if client ~= nil and client.data ~= nil and client.data.list ~= nil and  #client.data.list > 0 then
        local clientSelected = client.data.list[1];
        if clientSelected~= nil and clientSelected.exist_in ~= nil and (clientSelected.exist_in == "crm" or clientSelected.exist_in == "CRM") and clientSelected.profile ~= nil and clientSelected.profile.id ~= nil then
            profileId = clientSelected.profile.id;
            if clientSelected.exist == "email" then
                isEmail = true;
            elseif clientSelected.exist == "mobile" then
                isMobile = true;
            end
            local query = teamyar.get_attachment("query_check_exist_client.txt");
            query = string.gsub(query , "{{select}}" , "pm2.PORTAL_ID as profile_id");
            query = string.gsub(query , "{{wherePortal}}" , "where pm1.TYPE=? and pm1.MODULE_ID=?  and pm2.PORTAL_ID=?");
            local queryData = { query= query, params = {2 , tonumber(module_id) , tonumber(profileId) } };
            db.query(queryData)
            local record={};
            db.query_fetch(record)
            if record ~= nil then
                isNewClient = false;
            end
        end
    end
    if isNewClient == true then
        if string.match(userInput, '[%w]+@[%w]+%.[%w]+') then
            isEmail = true;
        elseif (string.match(userInput, '[%d]+') and #userInput >= 9 and #userInput <= 11) then
            isMobile = true;
        else
            validInput = false;
        end
    end
    return isNewClient , validInput , isEmail , isMobile , profileId;
end
---
function sendToUserInput(isEmail , isMobile , inTeamyar )

    if inTeamyar == nil or inTeamyar == false then
        local token , code , timeEnd = createTokenLogin(isEmail , isMobile);
        if isEmail == true then
            local messageEmail = getLangSelected( "_text_message_email_otp");
            messageEmail = string.gsub(messageEmail , "{{codeOtp}}" , code);
            local subjectEmail = getLangSelected( "_subject_message_email_otp");
            local paramEmail =  { box_id = email_box_id , address = userInput , email_content = messageEmail , email_subject = subjectEmail }
            local resEmail = teamyar.call_api(12 , "/api/email/emailmsgadd" , paramEmail);
        elseif isMobile == true then
            local messageMobile = getLangSelected( "_text_message_mobile_otp");
            messageMobile = string.gsub(messageMobile , "{{codeOtp}}" , code);
            local paramPhone =  { box_id = nil , messages = { { content = messageMobile , send_to = { mobile_numbers = { { value =  userInput , country = userCountryCode } } } } } }

            if mobile_box_id ~= nil and mobile_box_id ~= "" then
                paramPhone.box_id = mobile_box_id;
                local resPhone = teamyar.call_api(16 , "/api/sms/send" , paramPhone);
            end
            if social_media_box_id ~= nil then
                paramPhone.box_id = social_media_box_id;
                local resWhatsUp = teamyar.call_api(16 , "/api/sms/send" , paramPhone);
            end
        end
        return token , code , timeEnd;
    else
        local response = teamyar.call_api( 2 , "/api/user/password/forgot/sendSecurityCode",  {mobile_email= userInput , portal_id= module_id, lang_id= lang_id} );
        if response~= nil and response.success==true then
            return true ;
        end
        return false  ;
    end
end
---


function getClientCategoryInSectionSelected()
    local resultExp = nil;
    local query = teamyar.get_attachment("query_get_list_crm_section_for_client.txt");
    local queryData = { query= query, params = { getUserAuthId() , crm_section_id } };

    db.query(queryData)
    local record= db.query_fetch();
    if record ~= nil and record[1] ~= nil then
        resultExp = record[1];
    end
    db.query_free();
    return resultExp;
end
function statusExistSectionCrm(clientCategory , categorySelected)
    if clientCategory ~= nil and clientCategory == categorySelected then
        return true;
    end
    return false;
end
function checkStepForLoginPortal()
    local clientCategory = getClientCategoryInSectionSelected();

    if status_show_form_info ~= nil and crm_category_id_source ~= nil and crm_category_id_destination ~= nil then
        if status_show_form_info == 1 then
            local existCategorySource = statusExistSectionCrm(clientCategory , crm_category_id_source);
            local existCategoryDestination = statusExistSectionCrm(clientCategory , crm_category_id_destination);

            if existCategoryDestination == true then
                return 0;
            elseif existCategorySource == true then
                return 1;
            else
                return 2;
            end
        end
    end
    return 0;
end
---
function managerForLoginPortal_goToPortal()
    return json.encode({ userInput = userInput , userInvite = userInvite , userCode = userCode , linkProfile = "/?page="..url_link_after_login })
end
function managerForLoginPortal_addToCategorySource()
    local res = teamyar.call_api(14 , "/api/client/category/add" , {
        id = getUserAuthId() ,
        category_id = crm_category_id_source
    });
end
function managerForLoginPortal_addToCategoryDestination()
    local res = teamyar.call_api(14 , "/api/client/category/add" , {
        id = getUserAuthId() ,
        category_id = crm_category_id_destination
    });
end






function managerForLoginPortal_showTemplateFormData_getField(
        listForms ,
        fieldStatus , fieldStatusRequired ,
        fieldName , value
)
    if fieldStatus ~= nil and fieldStatus == 1 then
        table.insert(listForms , {
            field = fieldName ,
            require=fieldStatusRequired ,
            value = value
        });
    end

    return listForms;
end

function managerForLoginPortal_getListStateCity()
    local resultExp = {  };
    local resultStateCities = {  };
    local query = teamyar.get_attachment("qury_get_list_state_cities.txt");
    local queryData = { query= query, params = {} };

    db.query(queryData)
    local record={};
    while db.query_fetch(record) do
        table.insert(
                resultStateCities ,
                {
                    state_code = record[2],
                    state_name = record[3],
                    city_code = record[4],
                    city_name = record[5],
                }
        )
    end
    db.query_free();

    return {
        states = managerForLoginPortal_getListStateCity_checkStates(resultStateCities),
        cities = managerForLoginPortal_getListStateCity_checkCity(resultStateCities , true),
    }
end
function managerForLoginPortal_getListStateCity_checkStates(resultStateCities)

    local resultExp = {  };
    for indexState, state in ipairs(resultStateCities) do
        if state ~= nil and state.state_code ~= nil and state.state_name ~= nil then
            local exist = false;

            for historyIndexState, historyState in ipairs(resultExp) do
                if historyState ~= nil and historyState.id == state.state_code then
                    exist = true;
                    break;
                end
            end

            if exist == false then
                table.insert(
                        resultExp ,
                        {
                            id =  state.state_code ,
                            name =  state.state_name ,
                            state_cities = managerForLoginPortal_getListStateCity_checkCity(resultStateCities , false , state.state_code) ,
                        }
                )
            end
        end
    end

    return resultExp;
end
function managerForLoginPortal_getListStateCity_checkCity(resultStateCities , all , stateCode )
    local resultExp = {  };
    for indexState, state in ipairs(resultStateCities) do
        if (((all == nil or all == false) and state ~= nil and state.state_code ~= nil and state.state_code == stateCode)
                or (all ~= nil and all == true))
                and state.city_code ~= nil and state.city_name ~= nil then
            table.insert(
                    resultExp ,
                    {
                        id =  state.city_code ,
                        name =  state.city_name ,
                    }
            )
        end
    end
    return resultExp;
end



function managerForLoginPortal_showTemplateFormData()
    local listForms = {};

    listForms = managerForLoginPortal_showTemplateFormData_getField(
            listForms , field_first_name , field_first_name_required , "name" , ""
    )
    listForms = managerForLoginPortal_showTemplateFormData_getField(
            listForms , field_last_name , field_last_name_required , "last_name"  , ""
    )
   --[[ listForms = managerForLoginPortal_showTemplateFormData_getField(
            listForms , field_national_code , field_national_code_required , "national_code" , ""
    )]]
    listForms = managerForLoginPortal_showTemplateFormData_getField(
            listForms , field_phone , field_phone_required , "phone" , ""
    )
    --[[listForms = managerForLoginPortal_showTemplateFormData_getField(
            listForms , field_mobile , field_mobile_required , "mobile" , ""
    )
    listForms = managerForLoginPortal_showTemplateFormData_getField(
            listForms , field_email , field_email_required , "email" , ""
    )]]
    listForms = managerForLoginPortal_showTemplateFormData_getField(
            listForms , field_birthday , field_birthday_required , "birthday" , (time.current() / 10000000)- 11644473600
    )
    listForms = managerForLoginPortal_showTemplateFormData_getField(
            listForms , field_gender , field_gender_required , "gender" , ""
    )
    listForms = managerForLoginPortal_showTemplateFormData_getField(
            listForms , field_states , field_states_required , "state" , ""
    )
    listForms = managerForLoginPortal_showTemplateFormData_getField(
            listForms , field_cities , field_cities_required , "city" , ""
    )
    listForms = managerForLoginPortal_showTemplateFormData_getField(
            listForms , field_contact , field_contact_required , "contact" , ""
    )

    local template = translateTemplate("template_info_client.html")
    template = string.gsub(template , "{{_list_forms}}" , json.encode(listForms));
    template = string.gsub(template , "{{_user_input}}" , userInput);

    local listCountries = teamyar.get_attachment("ty__country_list.json");
    template = string.gsub(template , "{{_list_countries}}" , listCountries);
    template = string.gsub(template , "{{_default_country_selected}}" , json.encode(default_country_selected));

    local listStateCities = managerForLoginPortal_getListStateCity();
    if listStateCities~= nil then
        if listStateCities.states ~= nil then
            template = string.gsub(template , "{{_list_states}}" , json.encode(listStateCities.states));
        end
        if listStateCities.cities ~= nil then
            template = string.gsub(template , "{{_list_cities}}" , json.encode(listStateCities.cities));
        end
    end


    local list_city_code_base64 = nil;
    if list_city_code ~= nil and list_city_code[1] ~= nil then
        list_city_code_base64 = convertFileToBase64(list_city_code[1]);
    end
    template = string.gsub(template , "{{_list_city_code}}" , list_city_code_base64);
    template = string.gsub(template , "{{_default_city_selected}}" , json.encode(default_city_selected));

    return json.encode({view= template });
end
function managerForLoginPortal()
    local stepLogin = checkStepForLoginPortal();
    if stepLogin == nil or stepLogin == 0 then
        return managerForLoginPortal_goToPortal();
    elseif stepLogin ~= nil and stepLogin == 1 then
        return managerForLoginPortal_showTemplateFormData();
    elseif stepLogin ~= nil and stepLogin == 2 then
        managerForLoginPortal_addToCategorySource();
        return managerForLoginPortal_showTemplateFormData();
    end
end






function submitDataClient_getValueField_string_check(value , status , errors , fieldStatusRequired , fieldKeyError)
    if fieldStatusRequired ~= nil and fieldStatusRequired == 1 and (value == nil or #value == 0) then
        status = false;
        table.insert(errors , getLangSelected(fieldKeyError))
    end
    return  status , errors;
end
function submitDataClient_getValueField_string(errors , status , fieldStatus , fieldStatusRequired , fieldName , fieldKeyError, userInfo)
    local value= nil;
    if fieldStatus ~= nil and fieldStatus == 1 and userInfo[fieldName] ~= nil then
        value= userInfo[fieldName];
        errors , status = submitDataClient_getValueField_string_check(value ,  errors , status , fieldStatusRequired , fieldKeyError);
    end
    return value , errors , status ;
end

function submitDataClient()

    if listParams.user_info ~= nil then
        local userInfo = listParams.user_info;
        local status = true;
        local errors = {};

        local data = {
            id =getUserAuthId() ,
            profile = {};
        }

        -- first name
        local valueFirstName = nil;
        valueFirstName , status , errors = submitDataClient_getValueField_string (status , errors , field_first_name , field_first_name_required , "name"  , "_name_require", userInfo);
        if valueFirstName ~= nil and status == true  then
            data.profile.name = valueFirstName;
        end

        -- last name
        local valueLastName = nil;
        valueLastName , status , errors = submitDataClient_getValueField_string (status , errors , field_last_name , field_last_name_required , "last_name"  , "_last_name_require", userInfo);
        if valueLastName ~= nil and status == true  then
            data.profile.last_name = valueLastName;
        end

        -- national_code
        --[[local valueNationalCode = nil;
        valueNationalCode , status , errors = submitDataClient_getValueField_string ( status , errors , field_national_code , field_national_code_required , "national_code"   , "_national_code_require", userInfo  );
        if valueNationalCode ~= nil and status == true  then
            data.profile.national_code = {{value = valueNationalCode , country=364}}; ;
        end]]

        -- gender
        local valueGender = nil;
        valueGender , status , errors = submitDataClient_getValueField_string ( status , errors , field_gender , field_gender_required , "gender"   , "_gender_require", userInfo  );
        if valueGender ~= nil and status == true  then
            data.profile.gender = valueGender;
        end

        -- email
        --[[local valueEmail = nil;
        valueEmail , status , errors = submitDataClient_getValueField_string ( status , errors , field_email , field_email_required , "email"   , "_email_require", userInfo  );
        if valueEmail ~= nil and status == true  then
            data.profile.email = {{value = valueEmail}};
        end]]

        -- mobile
        --[[local valueMobile = nil;
        valueMobile , status , errors = submitDataClient_getValueField_string ( status , errors , field_mobile , field_mobile_required , "mobile"  , "_mobile_require", userInfo  );
        if valueMobile ~= nil and status == true  then
            data.profile.mobile = {{value = valueMobile , country=userInfo["mobile_code_selected"]}};
        end]]

        -- phone
        local valuePhone = nil;
        valuePhone , status , errors = submitDataClient_getValueField_string ( status , errors , field_phone , field_phone_required , "phone"   , "_phone_require", userInfo  );
        if valuePhone ~= nil and status == true  then
            data.profile.phone = {{value = valuePhone , type=2 , country="364"}};
        end

        -- birth_date
        local valueBirthDay = nil;
        valueBirthDay , status , errors = submitDataClient_getValueField_string ( status , errors , field_birthday , field_birthday_required , "birthday"   , "_birthday_require", userInfo  );
        if valueBirthDay ~= nil and status == true  then
            data.profile.birth_date =  time.get_filetime(valueBirthDay) ;
        end

        -- state
        local valueState = nil;
        valueState , status , errors = submitDataClient_getValueField_string ( status , errors , field_states , field_states_required , "state"   , "_state_require", userInfo  );
        if valueState ~= nil and status == true  then
            data.state_code = { id= valueState };
        end

        -- city
        local valueCity = nil;
        valueCity , status , errors = submitDataClient_getValueField_string ( status , errors , field_cities , field_cities_required , "city"   , "_city_require", userInfo  );
        if valueCity ~= nil and status == true  then
            data.city_code = { id= valueCity };
        end


        -- contact
        if field_contact ~= nil and field_contact == 1 and userInfo.contact ~= nil then
            local contact=  userInfo.contact;
            if field_contact_required ~= nil and field_contact_required == 1 and (contact == nil or #contact == 0) then
                status = false;
                table.insert(errors , getLangSelected("_contact_require"))
            else
                teamyar.call_api( 14 , "/api/client/contact/add",  { id =  getUserAuthId(), contact = { { type = 3 , contact_id = contact } } } );
            end
        end

        if status == true then
            local response = teamyar.call_api(14 , "/api/client/update" , data);
            if response ~= nil and response.success ~= nil then
                if response.success == true then
                    managerForLoginPortal_addToCategoryDestination();
                    return managerForLoginPortal_goToPortal();
                else
                    if response.error ~= nil and response.error.message ~= nil then
                        return json.encode({status = false , errors = { response.error.message }})
                    end
                end
            end
        else
            return json.encode({status = false , errors = errors})
        end
    end
    return json.encode({status = false , errors = {getLangSelected("_error_in_process")}})
end

function submitDataClient_getValueField_data(date)
    local resultExp = {  };
    for indexState, state in ipairs(resultStateCities) do
        if (((all == nil or all == false) and state ~= nil and state.state_code ~= nil and state.state_code == stateCode)
                or (all ~= nil and all == true))
                and state.city_code ~= nil and state.city_name ~= nil then
            table.insert(
                    resultExp ,
                    {
                        id =  state.city_code ,
                        name =  state.city_name ,
                    }
            )
        end
    end
    return resultExp;
end
---
function getClientData()
    local response = teamyar.call_api(14 , "/api/client/get" , { id = getUserAuthId() });
    if response ~= nil and response.success ~= nil and response.success == true and response.data ~= nil then
        return response.data;
    end
    return {};
end
---

function getAclListCountry()
    local resultExp = {};

    local inputs = teamyar.get_input();
    local search = "";
    if inputs.search ~= nil then
        search = inputs.search
    end

    local listCountries = teamyar.get_attachment("ty__country_list.json");
    listCountries = json.decode(listCountries);
    if listCountries ~= nil and type(listCountries) == "table" then
        for index, itemCountry in ipairs(listCountries) do
            if itemCountry~= nil and itemCountry.code ~= nil and itemCountry.name ~= nil and itemCountry.tel then
                local row = {
                    id = itemCountry.code ,
                    name = itemCountry.tel .. " - " .. itemCountry.name
                }
                if string.find(row.name, search) then
                    table.insert(
                            resultExp,
                            {
                                id = itemCountry.code ,
                                name = itemCountry.tel .. " - " .. itemCountry.name
                            }
                    )
                end
            end
        end
    end

    return resultExp;
end


---
if page_step == 0 then
    teamyar.write_result(runTemplateMain())
elseif page_step == 1 then
    teamyar.write_result(runTemplateSignUp())
elseif page_step == 2 then
    teamyar.write_result(runTemplateConfirm())
elseif page_step == 4 then
    teamyar.write_result(runChangePassword())
elseif page_step == 5 then
    teamyar.write_result(runFinishLogin())
elseif page_step == 7 then
    teamyar.write_result(runGetNewToken())
elseif page_step == 8 then
    teamyar.write_result(submitDataClient())

elseif page_step == 100 then
    teamyar.write_result(json.encode(getAclListCountry()))
else
    teamyar.write_result(runTemplate404())
end