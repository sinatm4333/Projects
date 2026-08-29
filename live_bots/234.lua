-- botName = send_sms_to_profile_hr
-- creator = mehdi-marefiyan
-- date = 4/15/2024
-- version= 0.1
------------------
local _ACL_MESSAGES = "message_id"
local _ACL_PROFILE_ID = "profile_id"
local _TYPE_SEND_MESSAGE = "send_message"
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
local send_sms_to_profile_hr = {};
function send_sms_to_profile_hr:init()
    self.config = {};
    self.requires = {};
    self.libs = {};
    ---
    self.listMessages = {} ;
    self.profile_id = 0 ;
    self.message_id = 0 ;
    self.box_id = 0 ;
    self.typeReference = nil ;
    return self;
end
function send_sms_to_profile_hr:getConfig()
    send_sms_to_profile_hr.config = _boxAttachment.getAttachment("config.json" , true);
    if send_sms_to_profile_hr.config ~= nil and  send_sms_to_profile_hr.config.requires ~= nil then
        send_sms_to_profile_hr.requires = send_sms_to_profile_hr.config.requires;
    end
    return self;
end
function send_sms_to_profile_hr:setLibraries()
    send_sms_to_profile_hr:getConfig();
    send_sms_to_profile_hr.libs = _render:init(send_sms_to_profile_hr.requires).run();
    return self;
end
function send_sms_to_profile_hr:getParams()
    setParamToObject(send_sms_to_profile_hr ,'box_id' , "number" , 0);
    setParamToObject(send_sms_to_profile_hr ,'profile_id' , "number" , 0);
    setParamToObject(send_sms_to_profile_hr ,'message_id' , "number" , 0);
    setParamToObject(send_sms_to_profile_hr ,'typeReference' , "string" , nil);
    return self;
end
function send_sms_to_profile_hr:setListMessages()
    if send_sms_to_profile_hr.config ~= nil and send_sms_to_profile_hr.config.messages then
        local listMessages = send_sms_to_profile_hr.config.messages;
        for i = 1 ,#listMessages , 1 do
            local itemMessage = listMessages[i];
            if itemMessage.id ~= nil and itemMessage.name ~= nil and itemMessage.text ~= nil then
                table.insert(send_sms_to_profile_hr.listMessages , {
                    id = itemMessage.id ,
                    name = language_tools.translateWord(itemMessage.name),
                    text =  language_tools.translateWord(itemMessage.text)
                })
            end
        end
    end
    return self;
end
function send_sms_to_profile_hr.getAclSmsBox()
    return listAcls.AclSmsBox();
end
function send_sms_to_profile_hr.getAclListMessages()
    return listAcls.AclObjectCustom(_ACL_MESSAGES, "_filter_sms_selected" , send_sms_to_profile_hr.listMessages);
end
function send_sms_to_profile_hr.getInputHiddenProfileId()
    return listAcls.textHidden(_ACL_PROFILE_ID ,  send_sms_to_profile_hr.profile_id );
end
function send_sms_to_profile_hr.run()
    send_sms_to_profile_hr:setLibraries():getParams():setListMessages();

    if send_sms_to_profile_hr.typeReference == _TYPE_SEND_MESSAGE then

        return send_sms_to_profile_hr.readyForSendMessage();

    else
        -- [type = form]
        local formCreator = FormCreator.run(
                {
                    send_sms_to_profile_hr.getAclSmsBox().getAclElement() ,
                    send_sms_to_profile_hr.getAclListMessages().getAclElement() ,
                    send_sms_to_profile_hr.getInputHiddenProfileId().getAclElement() ,
                } ,
                "COL-2"
        );

        -- views
        local readyView = ReadyViewReport.run(send_sms_to_profile_hr.getResponseSendMessage , {
            profile_id = send_sms_to_profile_hr.profile_id
        });
        return bot_controller
                .run(
                {
                    --Acls
                    send_sms_to_profile_hr.getAclSmsBox().run() ,
                    send_sms_to_profile_hr.getAclListMessages().run() ,
                    --Form
                    formCreator
                },
                readyView
        );
    end

end

-- for confirm
function send_sms_to_profile_hr.getResponseSendMessage()


    local box = send_sms_to_profile_hr.getAclSmsBox().getValue();
    local box_id = nil;
    if box ~= nil and box.id ~= id then
        box_id = box.id;
    end

    local profile_id = send_sms_to_profile_hr.getInputHiddenProfileId().getValue();
    local message_id = 0;
    local status = false;

    local message =  send_sms_to_profile_hr.getAclListMessages().getValue();
    if message ~= nil and message.id ~= nil then
        message_id =  message.id;
    end

    if tonumber(profile_id) > 0 and tonumber(message_id) > 0 and tonumber(box_id) > 0 then
        status = true;
    end

    local botUrl = bot_url_tools.run();
    return {
        view = template_tools.run("template_confirm.html"  , {
            _BOT_URL_SEND = botUrl.base.."?typeReference=".._TYPE_SEND_MESSAGE,
            _CONFIRM_MSG = language_tools.translateWord("_title_confirm_send_message" ),
            _MESSAGE_ID = message_id ,
            _PROFILE_ID = profile_id,
            _BOX_ID = box_id,
        } , "send") ,
        status = status
    };
end

-- for result
function send_sms_to_profile_hr.readyForSendMessage()
    local profile_selected = send_sms_to_profile_hr.getUserInfo();
    local message_selected = send_sms_to_profile_hr.getMessageInfo();

    if profile_selected ~= nil and message_selected ~= nil then
        if profile_selected.profile_id ~= nil and profile_selected.profile_name ~= nil and profile_selected.profile_mobile ~= nil then
            local profile_id = profile_selected.profile_id;
            local profile_name = profile_selected.profile_name;
            local profile_mobile = profile_selected.profile_mobile;
            local response = send_sms_to_profile_hr.sendSmsWithProfileId(send_sms_to_profile_hr.box_id ,message_selected , profile_id);

            if response.success ~= nil and response.success == true then
                return template_tools.run("template_result.html"  , {
                    _PROFILE_NAME = profile_name,
                    _MESSAGE_TEXT = message_selected
                })
            end
        end
    end

    return ".. not response ..";
end
function send_sms_to_profile_hr.getUserInfo()
    local query = _boxAttachment.getAttachment("query_get_profile_mobile.txt" );
    local params = {};
    query , params = whereQuery:init()
            :addSqlWhere(  send_sms_to_profile_hr.profile_id , "id=?" )
            .run(query , params ,"{{whereProfileMain}}");

    local result  = baseQuery:init()
            :setQuery(query)
            :setFirst(1)
            :setTableSelects({ { column= 'profile_id' , alias= 'profile_id' } , { column= 'profile_name' , alias= 'profile_name' } , { column= 'profile_mobile' , alias= 'profile_mobile' } })
            :setParams(params)
            .fetch();

    if result ~= nil   then
        return  result;
    end
    return nil;
end
function send_sms_to_profile_hr.getMessageInfo()
    for i = 1 ,#send_sms_to_profile_hr.listMessages , 1 do
        local itemMessage = send_sms_to_profile_hr.listMessages[i];
        if itemMessage.id ~= nil and itemMessage.id==send_sms_to_profile_hr.message_id and itemMessage.text ~= nil then
            return itemMessage.text;
        end
    end
    return nil;
end
function send_sms_to_profile_hr.sendSmsWithProfileId(box_id , content , profileId)
    local params = {
        box_id = box_id,
        messages = {
            {
                content= content,
                send_to = {
                    profile_ids = {
                        profileId
                    }
                }
            }
        }
    }

    return callApi:init():setModuleId(16):setPath("/api/sms/send"):setParams(params).run();
end


teamyar.write_result(send_sms_to_profile_hr:init().run())