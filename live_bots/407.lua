local config = teamyar.get_config()
local url = ""
local f_user_name = ""
local f_password = ""
local username = ""
local password = ""
local org_id = ""
local config_data ={}
if config ~= nil then 
  config_data = config.data
  url = config_data.url
  f_user_name = config_data.f_user_name
  f_password = config_data.f_password
  org_id = config_data.org_id
end 
local user_info = teamyar.get_user_info()
local user_id = user_info.id
----------------------------
function convertBase64(data)   
local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local encoded = {}
    local padding = 0

    -- Pad the data to a multiple of 3 bytes
    while #data % 3 ~= 0 do
        data = data .. '\0'
        padding = padding + 1
    end

    for i = 1, #data, 3 do
        local b1 = data:byte(i)
        local b2 = data:byte(i + 1)
        local b3 = data:byte(i + 2)

        local n = (b1 << 16) + (b2 << 8) + b3

        encoded[#encoded + 1] = b64chars:sub((n >> 18) + 1, (n >> 18) + 1)
        encoded[#encoded + 1] = b64chars:sub(((n >> 12) & 0x3F) + 1, ((n >> 12) & 0x3F) + 1)
        encoded[#encoded + 1] = b64chars:sub(((n >> 6) & 0x3F) + 1, ((n >> 6) & 0x3F) + 1)
        encoded[#encoded + 1] = b64chars:sub((n & 0x3F) + 1, (n & 0x3F) + 1)
    end

    -- Replace padding with '='
    for i = 1, padding do
        encoded[#encoded - i + 1] = '='
    end

    return table.concat(encoded)
end
function getQueryResponse(query,query_params)
  db.use_db("0000000")
  local params = {
    query = query,
    params = query_params
  }
  db.query(params);
  local res_text = db.query_fetch();
  db.query_free();
  username = res_text[1]
  password = res_text[2]
end
-----------------------------------------------------------------------------------
local query_val = [[  with vals as (select cf.name n, cfv.value_ v from hr_per_custom_field_val cfv inner join 
                              hr_personnel_custom_field cf on cf.id=cfv.FIELD_ID where cfv.target_id=(select PERSONNEL_ID from hr_personnels  where profile_id=]]..user_id..[[ 
								and ORG_ID=]]..org_id..[[ ) and cf.ORG_ID=]]..org_id..[[ ) 
                              select 
                              (select v from vals where n=']]..f_user_name..[[' )username_a,
                              (select v from vals where n=']]..f_password..[['  )pass_a ]]

getQueryResponse(query_val,{})
--------------------------------------
local info_user = {username = username, password = password}
teamyar.write_log(json.encode(info_user))
local b64_user_pass = convertBase64(json.encode(info_user))
local site = [[<br><br><iframe id='content'  style='width:100%;' src="https://]]..url..[[?key=]]..b64_user_pass..[[" title="description"></iframe><script>
                  document.getElementById('content').style.height=document.getElementById('content').parentElement.parentElement.scrollHeight+'px'
                  </script>]]
teamyar.write_result(site)