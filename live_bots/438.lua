local input = teamyar.get_input();
  teamyar.write_log("input  :"..json.encode(input))
local input_type = input.type
if #input == 0 then 
  --   teamyar.write_result(" این بات از طریق رویداد ثبت پیام در گفتگو اجرا می شود و با دکمه اجرا قابل اجرا نیست  ".."</br>")
end 
local self = teamyar.self();
local config = teamyar.get_config()

local config_data = {}
local c_url = ""
local c_port = 0
local fix_key = "1234"
local c_teamyar_url =""
if config ~= nil then
  config_data = config.data
  c_url = config_data.url
  c_port = config_data.port
  fix_key = config_data.key
  c_teamyar_url = config_data.teamyar_url
else
  teamyar.write_result("پیکربندی این بات انجام نشده است ".."</br>")
end
--local input_text = json.encode(input.msg)
--teamyar.write_log(" json.encode(input.msg)--".. json.encode(input.msg))
if input.msg ==nil then 
  input.msg=""
end 
local dialog_id = input.dialog_id
local input_text =input.msg
input_text= input_text:gsub("</p>", "\n")
input_text= input_text:gsub("</li>", "\n")
  input_text= input_text:gsub("</ul>", "\n")
      input_text= input_text:gsub("</ol>", "\n")
 input_text =input_text:gsub("<[^>]->", "") --remove html tags
local entities = {
  ["&".."nbsp;"] = " ",   -- replace with space
  ["&".."amp;"] = "&",
  ["&".."lt;"] = "<",
  ["&".."gt;"] = ">",
  ["&".."quot;"] = '"',
  ["&".."#".."39;"] = "'",
  -- Add more entities if needed
}
input_text= input_text:gsub("(&%w+;)", entities)
---------------------------------------
function queryResultValue(select_query, user_param)
--  teamyar.write_log("select_query--"..select_query)
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
    return res_text[1], res_text[2], res_text[3], res_text[4];
  end
end
--    input_text = json.encode(input_text)
------------------------------------
-- input_text = json.encode(string.sub(input_text, 17, #input_text - 6))
if dialog_id ~= nil then 
 local  temp_topic = queryResultValue([[select TOPIC from chat_dialogs where id=]]..dialog_id,{}) -- input.number
    --  teamyar.write_log("temp_topic---"..temp_topic)
  if string.find(temp_topic, "Group") then     
 --   teamyar.write_log("11111111111")
    input_text = json.encode(input.user_name..": \n"..input_text)
    else
       -- teamyar.write_log("22222222222222")
     input_text = json.encode(input_text)
  end
else
 -- teamyar.write_log("33333333333")
     input_text = json.encode(input_text)
end
--teamyar.write_log(" input_text--"..input_text)

local user_info = teamyar.get_user_info();
local user_id = math.floor(user_info["id"]); 

----------------------------------------
function sendImageLink(file_id)
  local file_manager = teamyar.create_file_manager(9);

  local file_data = file_manager:readFile(file_id);

  local q_file = [[select NAME,MIME_TYPE,SIZE,file_type from chat_ty_document where id=]]..file_id
  local  file_name,mimty,file_size,file_type= queryResultValue(q_file,{})

  local fty=tonumber(file_type)
  if fty == 3 or fty == 13 then
    file_ty_str="audio"
  end 
  if fty == 8 or fty == 14 or fty == 65535 then
    file_ty_str="video"
  end 
  if fty == 4 or fty == 18 or fty == 22 or fty == 31 or fty == 36  then
    file_ty_str="image"
  end 

  if   file_ty_str == "image" then 
    teamyar.set_http_header('Content-Type',mimty)	--au
    teamyar.set_http_header('Cross-Origin-Resource-Policy', 'cross-origin')
    teamyar.set_http_header('X-Content-Type-Options', 'nosniff')
    teamyar.set_http_header('Cross-Origin-Resource-Policy', 'cross-origin')
    teamyar.set_http_header('Cache-Control', 'private, max-age=31536000')
    teamyar.set_http_header('Alt-Svc', 'h3=":443"; ma=2592000,h3-29=":443"; ma=2592000')
    teamyar.set_http_header('Access-Control-Allow-Origin', '')
    teamyar.set_http_header('Cross-Origin-Opener-Policy-Report-Only', 'same-origin; report-to="static-on-bigtable"')
    teamyar.set_http_header('X-XSS-Protection', 0)
  else 
    teamyar.set_http_header('Content-Type',"application/octet-stream")	--au	 
    teamyar.set_http_header('X-Content-Type-Options',"")	--au
    teamyar.set_http_header( "Access-Control-Allow-Origin","")
    teamyar.set_http_header('X-XSS-Protection', "")
    teamyar.set_http_header('Content-Disposition', 'attachment;filename="'..file_name..'"')
    teamyar.set_http_header('Cache-Control', "")
    teamyar.set_http_header('ETag', "5fd75213-6743d")
  end 
  teamyar.set_http_header('Content-Length', file_size)	
  teamyar.set_http_header('Accept-Ranges', 'bytes')
  teamyar.set_http_header('Content-Security-Policy', '')
  teamyar.set_http_header('strict-transport-security', '')
  teamyar.set_http_header('Pragma','')
  teamyar.set_http_header('Referrer-Policy', '')
  teamyar.set_http_header('Feature-Policy', '')
  teamyar.set_http_header('Connection', '')
  teamyar.write_result(file_data)
end 

------------------------
function showLoginBtn()
  local config_id=config.id
  local userinfo = teamyar.get_user_info();
  local lang = "English";
  if userinfo.lang_id == 4 then
    lang = "Persian";
  end
  local srlang = "<script src='/bot/run/2/watsap_send_msg/"..lang..".js'></script>";
  res_data = [[
  <div id='myDiv'>
  <input type='hidden' id='inputconfig_id' name='inputconfig_id'  value=']]..config_id..[['>
  </div>

  ]]..srlang..[[
  <div id="qrcode"></div>

  <script src="/bot/run/2/watsap_send_msg/qrcode.js">
  </script>
  <link href='/bot/run/2/watsap_send_msg/main.css' rel='stylesheet' /> 
  <script src='/bot/run/2/watsap_send_msg/main.js'>

  </script>
  ]];
  return res_data
end
-----------------------

if dialog_id == nil then --show login btn

  if tonumber(input_type)==5 then --send img file

    local imge_id = input.image_id
    local file_name = input.file_name

    sendImageLink(imge_id, file_name)
  elseif input_type==3 then -- get qr code
    local params_qr = 
    {
      domain =c_url,
      port =tonumber(c_port),
      url = "/get-qr",
      ssl = false,
      secure = false,
      method = "post",
      data_str = json.encode({key = fix_key}),
      header = {{name = "Content-Type", value = "application/json"}, {name = "Accept", value = "*/*"}
      }
    }
       teamyar.write_log("params_qr  :"..json.encode(params_qr))
    local result = teamyar.call_url(params_qr);
      teamyar.write_log("result---oo--"..json.encode(result))
    local err = json.decode(result.result.body).error
    if err ==nil or err=={} or err =="" then 
      local qr_str=json.decode(result.result.body).qr
      teamyar.write_result(json.encode({tx = qr_str}))
    else 
      teamyar.write_result(json.encode({tx = "" ,err = err}))
    end 
  else
    teamyar.write_result(showLoginBtn())-- show html
  end
end 
local number = ""
if dialog_id ~= nil then 
  number = queryResultValue([[select TOPIC from chat_dialogs where id=]]..dialog_id,{}) -- input.number
  if string.find(number, "Group") then 
    number =  string.match(number, "_(.*)")
  else 
    number = string.sub(number, 9, #number)
  end 

  --   teamyar.write_log("number--"..number)
end 
--teamyar.write_log("file 11111--"..#input.files)
local count_files= 0 
if input.files ~= nil then 
  count_files =#input.files
end 
if (tonumber(input.msg) ~= nil or count_files>0 ) and input_type == nil and input.user_name ~= nil then --- == "" sent file
  teamyar.write_log("file 2--")
  --teamyar.write_log("file 2--")
  local file_id =0
  if  input.files~= nil then 
 file_id=   input.files[1].id
  end


  local q_file = [[select NAME,MIME_TYPE,file_type from chat_ty_document where id=]]..file_id
  local  file_name,mimty,file_type = queryResultValue(q_file,{})

  local file_ty_str = ""
  local fty=tonumber(file_type)
  if fty == 3 or fty == 13 then
    file_ty_str="audio"
  end 
  if fty == 8 or fty == 14 or fty == 65535 then
    file_ty_str="video"
  end 
  if fty == 4 or fty == 18 or fty == 22 or fty == 31 or fty == 36  then
    file_ty_str="image"
  end 
  local data_file = {to = number,
    type = file_ty_str,
    mime_type=mimty,
    url = c_teamyar_url.."/public/bot/run/2/watsap_send_msg?image_id="..file_id.."&type=5&file_name="..file_name,
    caption = file_name,
    key = fix_key
  }
  params_file = 
  {
    domain = c_url,
    port = tonumber(c_port),
    url = "/send-media",
    ssl = false,
    secure = false,
    method = "post",
    data_str = json.encode(data_file),
    header = {{name = "Content-Type", value = "application/json"},{name = "Accept", value = "*/*"} }
  }
 teamyar.write_log("sent media 1111")
--  teamyar.write_log(c_teamyar_url.."/public/bot/run/2/watsap_send_msg?image_id="..file_id.."&type=5&file_name="..file_name)
  local result_file = teamyar.call_url(params_file);
  teamyar.write_log("result_file"..json.encode(result_file) )
end
if #input_text>2 and   #number>0 then -- send message

  params = 
  {
    domain = c_url,
    port = tonumber(c_port),
    url = "/send-message",
    ssl = false,
    secure = false,
    method = "post",
    data_str = [[{"to":"]]..number..[[","message":]]..input_text..[[, "key" : "]]..fix_key..[[" , "isGroup" : true }]],
    header = {{name = "Content-Type", value = "application/json"},{name = "Accept", value = "*/*"} }
  }
  --teamyar.write_log("*param7777s*--"..json.encode(params))
  local result = teamyar.call_url(params);
  -- teamyar.write_log("*result*--"..json.encode(result))
  local err = ""
  if result.result ~= nil and result.result.body~= nil then 
    err = json.decode(result.result.body).error
  end 
  --  teamyar.write_log("*err*--"..json.encode(err))
  if err ~= nil and err ~= "" then -------show err in chat 
    err =  "<div style='color: #8b3232; direction: ltr;'>Error In Send Massage To Watsap Server Call To IT Manager :</div><div style='direction: ltr;'>"..err.."</div>"
    local info2={message = err, author_id = 43361, dialog_id  = dialog_id}
    local   res2 = teamyar.call_api(9,  '/api/message/add', info2);
  end
end



