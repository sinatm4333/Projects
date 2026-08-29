------------------------
local group_id = 0 --category id
local to_number = 0
crm_category_id = 0 
local config_key = ""
-------------------------------------
function detectLanguage(text)
  if string.match(text, "[a-zA-Z]") then
    return 2
  else
    return 1
  end
end
-------------------------------------

function queryResultValue(select_query, user_param)
  db.use_db("0000000");
  local params1 = {
    query = select_query,
    params = user_param
  }
  db.query(params1);
  local res_text = db.query_fetch();
  db.query_free();
  if res_text == nil then 
    return nil 
  else
    return res_text[1];
  end
end
----------------------------
function setConfigByNumber(num)
 teamyar.write_log("num-----"..json.encode(num))
  local self = teamyar.self()
  local bot_id = self.id
  local qc = [[select config from bot_command_config where command_id =]]..bot_id..[[ and config->'$.number'="]]..num..[["]]
   -- teamyar.write_log("config_get-----"..json.encode(config_get))
local config_get= queryResultValue(qc, {})
   teamyar.write_log("config_get-----"..json.encode(config_get))
  if config_get ~= nil then 
      local configdb = json.decode(config_get)
       teamyar.write_log("configdb-----"..json.encode(configdb))
      group_id = configdb.category_id
      config_key = configdb.key
      to_number = configdb.number
      crm_category_id = configdb.crm_category_id
  end 
end 
--------------------------------------
function saveProfileImage(id,pic,pic_info)
  local info_ppic = {
    id = id,
    profile = {
      large_photo = {
        -- size = pic_info.size,
        filename =  pic_info.filename,
        filepath = "",
        mime_type = pic_info.mimetype,
        data_base64 = pic,
        --  src_module_id = 26
      },
      small_photo ={
        --   size = pic_info.size,
        filename =  pic_info.filename,
        filepath = "",
        mime_type = pic_info.mimetype,
        data_base64 = pic,
        --    src_module_id = 26
      }
    }
  }
  teamyar.write_log("info_ppic-----"..json.encode(info_ppic))
  local resSavePPic = teamyar.call_api(14 , "/api/client/update",  info_ppic );
  teamyar.write_log("resSavePPic-----"..json.encode(resSavePPic))
end
------------------------------------------------
function findOrCreateCrm(mobile,name,pic,pic_info)
      local mobile_str = tostring(mobile)
    local last_eight = string.sub(mobile_str, -8)
  local query_m = [[select m.user_id from profile_mobile m  inner join crm_info c on c.id=m.user_id where m.MOBILE LIKE '%]]..last_eight..[[' ]]
  local profile_id= queryResultValue(query_m, {})
  if profile_id == nil then 
    profile_id = createCrm(mobile, name)
  end 
  local image_id =queryResultValue( [[select PHOTO_ID from profile_user_info where id=]]..profile_id ,{})
  if (image_id == nil or image_id=="" or  image_id==0 ) and pic~=nil and pic~="" then 
    saveProfileImage(profile_id, pic, pic_info)
  end 
  return profile_id
end 
-------------------------------
function createCrm(mobile, name)
  local temp_name= ""
  if name ~= nil and name ~="" then 
    temp_name = name 
  else 
    temp_name= "client ***" .. mobile
  end 
  params = { section_id=crm_category_id , profile = { name = temp_name , mobile = { { value= mobile, country=364 } } } }
  local responseCreateClient = teamyar.call_api( 14 , "api/client/create",  params );
  local profileId = 0 
  if responseCreateClient ~= nil and responseCreateClient.success == true and responseCreateClient.data~= nil and responseCreateClient.data.profile_id ~= nil then
    profileId = responseCreateClient.data.profile_id;
  end 
  return profileId
end
----------------------------------
local input = teamyar.get_input()
local temp_input= input

local user_info = teamyar.get_user_info()
local user_id = user_info.id

local input_to_number =  string.match( input.to, "^(.-)@")
local input_from_number =  string.match( input.from, "^(.-)@")
local number_for_config = input_to_number
if input.direction == "outgoing" then 
  number_for_config = input_from_number
end 
setConfigByNumber(number_for_config) --get config from db
local dialog_id = 0

------------------------------------
function SendMessageInDomainMode()
  local admin_dialog_id = 0 
  local query = [[ select id  from chat_dialogs where topic=']].. "Whatsap/Admin/"..input.to..[['  and deleted=0 ]]
  admin_dialog_id = queryResultValue(query,{})
  ---------------------------------create dialog admin
  if admin_dialog_id == nil or admin_dialog_id == 0 then 
    local info_admin_dialog = {topic = "Whatsap/Admin/"..input.sender.number, group_id = group_id, author_id  = user_id}    
    local   res_admin_dialog = teamyar.call_api(9,  '/api/dialog/create', info_admin_dialog);
  end 
  admin_dialog_id = res_admin_dialog.data.dialog_id
  local info_msg_admin = {message = input.status, author_id = 43361, dialog_id  = admin_dialog_id}
  local res_msg_admin = teamyar.call_api(9,  '/api/message/add', info_msg_admin);  
end 
------------------------

if input.key == config_key --  and to_number.."@c.us" == input.to
  then --check validate request
  if input.mode ~= nil and iniput.mode == "admin" then 
    SendMessageInDomainMode()
  end 
  -------------------------find dialog
  local topic_str=""
  teamyar.write_log("sender-----"..json.encode(input.sender))
  if input.sender.isGroup == true then 
    topic_str ="WhatsapGroup/".. input.sender.groupName .."_"..input.from
  else
        teamyar.write_log("input---******--"..json.encode(input))
   if input.direction == "outgoing" then 
      local tt=string.match( input.to, "^(.-)@")
        teamyar.write_log("tt-----"..json.encode(tt))
          topic_str = "Whatsap/"..tt
    else 
    	topic_str = "Whatsap/"..input.sender.number
    end
  end 
  local query = [[ select id  from chat_dialogs where topic like ']].. topic_str..[[%'  and group_id=]]..group_id..[[ and  deleted=0 ]]
  dialog_id = queryResultValue(query,{})
  ---------------------------------create dialog
  if dialog_id == nil or dialog_id == 0 then 
    local info_dialog = {topic = topic_str, group_id = group_id, author_id  = user_id}
    local   res_dialog = teamyar.call_api(9,  '/api/dialog/add', info_dialog);
    dialog_id = res_dialog.data.dialog_id
    --------------------------------------first massage
    local  img_url=""
    if input.sender.profilePicUrl ~= nil then 
      img_url =  [[<img class="fit-picture" src="]]..input.sender.profilePicUrl..[[" />	<br>]]
    end 
    local msg =  img_url..[[ <div><div>name:]]..input.sender.name..[[</div>
    <div>number:]]..input.sender.number..[[ </div>
    <div>id:]]..input.sender.id..[[ </div>
    <div>Is Enterprise:]]..tostring(input.sender.isEnterprise)..[[ </div>
    <div>Is Group:]]..tostring(input.sender.isGroup)..[[</div>
    <div>Is Business: ]]..tostring(input.sender.isBusiness)..[[</div>
    </div>]]
    local info1 = {message = msg , author_id = 10001, dialog_id  = dialog_id}
    local   res1 = teamyar.call_api(9,  '/api/message/add', info1);
  end
  -------------------------add message
  local attach_info={}
   teamyar.write_log(" input.hasMedia ----"..json.encode( input.hasMedia ))

 -- local ttty=input.media
----  ttty.data=""
     --    teamyar.write_log("ttty----"..json.encode(ttty ))
       teamyar.write_log(" input.media----"..json.encode(input.media ))
  if input.hasMedia == true then  --attachments
    local  file_name=input.media.filename
    if input.media.mimetype == "audio/ogg; codecs=opus" then 
      file_name = file_name..".ogg"
    end
    if input.media.mimetype == "video/mp4" then 
      file_name=file_name..".mp4"
    end
        if input.media.mimetype == "video/mp4" then 
      file_name=file_name..".mp4"
    end
     teamyar.write_log(" input.media.mimetype----"..json.encode( input.media.mimetype))
      teamyar.write_log(" file_name----"..json.encode( file_name))
         teamyar.write_log("  input.media.size---"..json.encode( input.media.size))
    if file_name ==nil then 
      file_name ="temp.jpg"
    end 
    attach_info =	 {
      {
        size = input.media.size,
        filename = file_name,
        filepath = "",
        mime_type = input.media.mimetype,
        data_base64 = input.media.data,
        src_module_id = 26
      }
    }
  end 
  local author_id = 0
     if input.direction == "outgoing" then 
      local tt = string.match( input.from, "^(.-)@")
      if  string.sub(to_number, -8) ==  string.sub(input.from, -8) then --its from us
             tt = string.match( input.to, "^(.-)@")
      end 
    author_id = findOrCreateCrm(tt , input.sender.name, input.sender.profilePicBase64,input.sender.profilePicDetails) --crm 
      else 
       author_id = findOrCreateCrm(input.sender.number, input.sender.name, input.sender.profilePicBase64,input.sender.profilePicDetails) --crm 
      end
  local asain_param  = {
    assigned= {
      tonumber(author_id)
    },
    author_id = author_id,
    dialog_id = dialog_id
  }    

  local   res_assain  = teamyar.call_api(9,  '/api/assign/add', asain_param);
  local text_lang = 0 
    local body_str = ""
  if input.body ~= nil then 

    local temp_sstr=string.sub(input.body,0,10)
    if  temp_sstr ~= nil then 
      text_lang=   detectLanguage(temp_sstr)
    end
      if text_lang == 1 then 
    body_str = "<div style='direction:rtl' >"..input.body.."<div>"
  else 
    body_str = "<div style='direction:ltr' >"..input.body.."<div>"
  end 
  end 
--  teamyar.write_log("input.body----"..json.encode(input.body))


  local info2={message = body_str, author_id = author_id, dialog_id  = dialog_id, attachments = attach_info}
   teamyar.write_log("info2----"..json.encode(info2))
  local   res2 = teamyar.call_api(9,  '/api/message/add', info2);
  teamyar.write_log("res2----"..json.encode(res2))
  if input.body ~= nil and #attach_info > 0 then -- api of chat dosent send file with text 
    local text_info = {message = body_str, author_id = author_id, dialog_id  = dialog_id}
    local   res_txt = teamyar.call_api(9,  '/api/message/add', text_info);
  end 

end