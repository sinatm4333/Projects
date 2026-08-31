local input=teamyar.get_input();
local random = math.random(1,1000);
local extra_params = "";


if input.data == nil then
input.data = "''"
end

if input.title == nil then
input.title = ""
end

if input.description == nil then
input.description = ""
end

if input.header == nil then
input.header = ""
end

if input.css == nil then
input.css = ""
end

  
  if input.ajax == nil then
  input.ajax = "{}"
  end
  
  if input.src == nil then
  input.src = ""
  end

if input.tpl_name == "table" then
  if input.generatetd == nil then
  input.generatetd = "''"
  end
  
   if input.beforegenerate == nil then
  input.beforegenerate = "''"
  end
  
  if input.settable == nil then
  input.settable = 0
  end

  extra_params =[[,generatetd:]]..input.generatetd..[[,beforegenerate:]]..input.beforegenerate..[[,settable:]]..input.settable;
end



if input.tpl_name == "chart" then

  
  if input.generatedata == nil then
  input.generatedata = "''"
  end
  extra_params =[[,generatedata:]]..input.generatedata;
end


if input.tpl_name == "html" then

  
  if input.body == nil then
  input.body = "''"
  end
  extra_params =[[,body:']]..input.body..[[']];
  
end


local controls = {}

if input.control  ~= nil then
     input.control = json.decode(input.control)
	for i= 1,  #input.control, 1  do 
    table.insert(controls, [[<script src='/bot/run/2/res_bot/]]..input.control[i]..[[_control.js'></script><link rel="stylesheet"  href='/bot/run/2/res_bot/]]..input.control[i]..[[_control.css'>]]) 
    end
end

local src_lang = "";
local userinfo = teamyar.get_user_info();
local lang = "English"

if userinfo.lang_id == 4 then
  lang = "Persian"
end
  
  if input.path ~= nil and input.lang == 1 then
		src_lang  = [[<script src='/bot/run/]]..input.path..[[/]]..lang..[[.js'></script>]]
  end

  

local res = [[
<div class="bot_holder"  id="BOT_HOLDER_ID"></div>
]]..table.concat(controls, "")..[[
<script>
ty__main.random_of_tpl = '';
</script>
<script src='/bot/run/2/res_bot/main.js'></script>
  <script src="/bot/run/2/res_bot/xlsx.full.min.js"></script>
]]..input.src..[[
<script>
	ty__main.botTPL({ holder_id :'#BOT_HOLDER_ID',tpl_name:'BOT_TPL_NAME'}) ;
</script>
]]..src_lang..[[
<script>
    ty__main['botTplBOT_TPL_NAME'] ({holder_id:'#BOT_HOLDER_ID',id:'BOT_HOLDER_ID_tpl',title:']]..input.title..[[',description:']]..input.description..[[',header:']]..input.header..[[',ajax:]]..input.ajax..[[,data:]]..input.data..extra_params..[[});
	]]..input.script..[[
    ty__main['botTplBOT_TPL_NAME'].afterload();
</script>
<style>
    ]]..input.css..[[
</style>]];

res = string.gsub(res, "BOT_HOLDER_ID",input.id..random)
res = string.gsub(res, "BOT_TPL_NAME",input.tpl_name)

teamyar.write_result(res);
