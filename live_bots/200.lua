input = teamyar.get_input();
local uinfo=teamyar.get_user_info();
local user_id=uinfo.id;
-----------------------------------------------------------
function queryResult(select_query,user_param)
  db.use_db("0000000")
    local params1 = {
      query =select_query,
      params = user_param
  }
  db.query(params1);
  local res_text = db.query_fetch();
  db.query_free();
  return res_text[1];
end
-------------------------------
function WidgetTemplate()  
  local random= math.random(1,1000);
  local script =  teamyar.get_attachment("main.js");
  local css =  teamyar.get_attachment("main.css");
  local template = teamyar.run_command("2/res_bot",{
      id = "test_eli",
      tpl_name = "html",
      title = "LICENCE_INFO",
      body = "<div id=\\'holder_body_html_"..random.."\\'></div>",
      script=[[
      (function(){
      var holder_id = '#holder_body_html_]]..random..[[';
    var random_id = ]] .. random .. [[;
      ]]..script..[[
    })();

      ]],
      css=css

    });
  teamyar.write_result(template);
 
end
------------------

--main
if input.type == 3 then 
  local ex=queryResult([[select expiration from admin_user where id=]]..user_id,{})   
  local query=queryResult([[select JSON_ARRAYAGG(JSON_OBJECT("c",c,"n",n)) from 
  (select count(m.id) c,b.name n from email_box b inner join email_message m on 
  m.box_id=b.id where b.author_id=]]..user_id..[[ group by b.name)pp]],{})
  local listdata = {data = query,ex=ex};

  teamyar.write_result(json.encode(listdata));
else 
  WidgetTemplate();
end
