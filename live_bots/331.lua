--Bot Import Product By Execle zmo
local input = teamyar.get_input();
local user_info = teamyar.get_user_info();
local user_id = math.floor(user_info["id"]); 
local cat_id = input.cat;
if cat_id == nil then
  cat_id = 0;
end
--------------------------------
function queryResult2(query, query_params,from_q)
  db.use_db("0000000")
  local params = {
    query = query,
    params = query_params
  }
  db.query(params);
  local res_text = {};
  local record = {};
  while db.query_fetch(record) do
      table.insert(res_text,{path = record[1], name = record[2], code = record[3],attr = record[4]});
  end
  db.query_free();
  return res_text;
end
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
----------------------
function catAcl(data)
  local query_param = [[ SELECT JSON_ARRAYAGG(JSON_OBJECT('id',id, 'name',name, 'type',1))
 									  from (SELECT ID,NAME FROM  wh_setting_product_info where  type=1 and PRODUCT_ID=0 ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  where name like N'%]]..data.search..[[%') as p ]]
  else
    query_param = query_param .. [[) p ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(queryResult(query_param, {}));
end
-----------------------------------------------
function WidgetTemplate()  
  local random = math.random(1,1000);
  local script =  teamyar.get_attachment("main.js");
  local css =  teamyar.get_attachment("main.css");
  local  str_lang = "";
  local  str_title = "";
  if user_info.lang_id == 4 then
    str_title = "خروجی اکسل محصولات "
    str_lang = teamyar.get_attachment("Persian.js");
  else
    str_title = "Product Export By Excle"
    str_lang = teamyar.get_attachment("English.js");
  end
  local template = teamyar.run_command("2/res_bot",{
      id = "bot_product_export_by_excel",
      tpl_name = "html",
      title = str_title,
      body = "<div id=\\'exip_holder_body_html_"..random.."\\'></div>",
      script = [[
      (function(){
      ]]..str_lang..[[      
      var holder_id = '#exip_holder_body_html_]]..random..[[';
      var random_id = ]] .. random .. [[;
      ]]..script..[[
    })();
      ]],
      css = css
    });
  teamyar.write_result(template); 
end
---------------------main
if input.type == 2 then 
  catAcl(input.data)

elseif input.type == 1 then 

  local qselect=   [[ with recursive cte (PRODUCT_ID,ATTRIBUTE_ID,id, name, MODULE_PARENT_ID,dd,counter) as (
                            select    PRODUCT_ID,ATTRIBUTE_ID, id,
                                       name,
                                       MODULE_PARENT_ID , Coalesce((select name from wh_setting_product_info where id=MODULE_PARENT_ID),'') dd , 0 counter          
                            from       wh_setting_product_info
                            where      id =  ]]..cat_id..[[
                            union all
                            select     p.PRODUCT_ID,p.ATTRIBUTE_ID,p.id,
                                       p.name,
                                       p.MODULE_PARENT_ID,
                                       concat((select name from wh_setting_product_info where id=p.MODULE_PARENT_ID),'/',cte.dd) dd , cte.counter+1 counter   
                            from       wh_setting_product_info p
                            inner join cte
                                    on p.MODULE_PARENT_ID = cte.id
                          )
                          select max(dd) path ,(select full_name from wh_product where id= product_id)name,(select full_code from wh_product where id=product_id)code,
                          Coalesce((select group_concat(CONTENT) from wh_pr_attribute_detail where ATTRIBUTE_ID=cte.ATTRIBUTE_ID ),'--')attribute from cte where product_id>0
                          group by PRODUCT_ID,ATTRIBUTE_ID ]]

teamyar.write_log(qselect)

  local query_select = qselect.. [[ limit ?,? ]]
  res_data = queryResult2(query_select , {input.from, input.count},input.from_q)
  -------------------
  local qtotal = [[select count(*) c from ( ]]..qselect..[[)as t]]
  local  totall = queryResult(qtotal, {})
  local title =  "ّProduct Export By Excle"
  if user_info.lang_id == 4 then
    title = "خروجی اکسل محصولات"
  end
  data = {from = input.from, count = input.count, data = res_data, total = totall, currentdate = currentdate, title = title}
  teamyar.write_result(json.encode(data))
else
  WidgetTemplate()
end
