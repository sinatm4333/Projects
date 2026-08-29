--Bot sales dashbord Notes zmo
input = teamyar.get_input();
local user_info = teamyar.get_user_info();
local user_id = math.floor(user_info["id"]); 
--------------------------------
function queryResult(select_query,user_param)
  db.use_db("0000000");
  local params1 = {
    query = select_query,
    params = user_param
  }
  db.query(params1);
  local res_text = db.query_fetch();
  db.query_free();
  return res_text[1];
end

-----------------------------------------------
function WidgetTemplate()  
  local random = math.random(1,1000);
  local script =  teamyar.get_attachment("main.js");
  local css =  teamyar.get_attachment("main.css");
  local  str_lang="";
  local  str_title="";
  if user_info.lang_id == 4 then
    str_title="یادداشت های من "
    str_lang = teamyar.get_attachment("Persian.js");
  else
    str_title="My Notes"
    str_lang = teamyar.get_attachment("English.js");
  end
  local template = teamyar.run_command("2/res_bot",{
      id = "bot_sd_n",
      tpl_name = "html",
      title = str_title,
      body = "<div id=\\'sdn_holder_body_html_"..random.."\\'></div>",
      script=[[
      (function(){
      ]]..str_lang..[[      
      var holder_id = '#sdn_holder_body_html_]]..random..[[';
      var random_id = ]] .. random .. [[;
      ]]..script..[[
    })();
      ]],
      css = css
    });
  teamyar.write_result(template); 
end
---------------------main
if input.type == 2 then --ADD
  local note={}
  local res_data = teamyar.get_data("sdn_data")
  local notes=res_data.value.note
  for i, v in ipairs(notes) do
    table.insert(note,v)
  end
  ------
  table.insert(note,input.note)
  local chash_data =  {note =note}
  teamyar.set_data("sdn_data", chash_data);
  local res_data = teamyar.get_data("sdn_data")
  data = {data = res_data}
  teamyar.write_result(json.encode(data))
  
elseif input.type == 3 then --DELETE
  local note={}
    local res_data = teamyar.get_data("sdn_data")
  local notes=res_data.value.note
  for i, v in ipairs(notes) do
    if v~=input.note then
      table.insert(note,v)
    end
  end
  ------
  local chash_data =  {note =note}
  teamyar.set_data("sdn_data", chash_data);
  local res_data = teamyar.get_data("sdn_data")
  data = {data = res_data}
  teamyar.write_result(json.encode(data))
  
elseif input.type == 1 then --GET LIST
  local res_data = teamyar.get_data("sdn_data")
  data = {data = res_data}
  teamyar.write_result(json.encode(data))
else
  WidgetTemplate()
end
