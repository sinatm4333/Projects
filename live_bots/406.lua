local input = teamyar.get_input();
local invoice_id = input.invoice_id

if invoice_id == nil then 
  teamyar.write_result(" این بات با دکمه اجرا عملیاتی انجام نمی دهد و باید از رویداد فاکتور خرید فراخوانی شود")
end 
local user_info = teamyar.get_user_info();
local config = teamyar.get_config()
local fw_id = 0
local comment = ""
local deadline = ""
local topic_id = 0
local task_type = 0
local c_prj_cat = 0;
local c_project_id = 0
local config_data = {}
if config ~= nil then 
  config_data = config.data
  if config_data ~= nil then
    fw_id = config_data.wf_id
    comment = config_data.comment
    deadline = config_data.deadline
    topic_id = config_data.topic_id
    task_type = config_data.task_type
    c_prj_cat = config_data.prj_cat
    c_project_id = config_data.project_id
  else
    teamyar.write_result(" تنظیمات پیکربندی بات  به درستی انجام نشده است")
  end 
else
  teamyar.write_result(" تنظیمات پیکربندی بات انجام نشده است")
end 
--------------------------------
function queryResult(select_query,user_param)
  db.use_db("0000000");
  teamyar.write_log(select_query)
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
---------------------------------------main

if invoice_id ~= nil then 
  local buy_title = "--"
  local query = [[ select concat(coalesce(i.TITLE,''),'_','فاکتور-',i.invoice_num,'_',
                        (select JNDATE from report_dimdate where i.RUN_DATE between datekey and datekey+(60*60*24*10000000) limit 1)
                        ,'_',coalesce((select p.fullname from pa_client c inner join profile_main p 
                        on p.id=c.REFFERE_ID where c.id=i.CLIENT_ID and c.org_id=i.org_id),''))t 
  from purchase_invoice i  where id =]]..invoice_id
  buy_title = queryResult(query, {})
--if buy_title == nil  or #buy_title == 0 or buy_title == ""  then 
   --   buy_title = queryResult(query, {})
    if buy_title == nil  or #buy_title == 0 or buy_title == ""  then 
    buy_title = comment..invoice_id
    end
--  end
  local querycrm = [[ select coalesce((select c.REFFERE_ID from pa_client c   where c.id=i.CLIENT_ID and c.org_id=i.org_id),0) crm_id  from purchase_invoice i  where id =]]..invoice_id
 --  local querycrm = [[ select i.CLIENT_ID  crm_id  from purchase_invoice i  where id =]]..invoice_id
  local fact_crm_id=queryResult(querycrm, {})
  local info_prj = {
    title = buy_title,
    category_id = c_prj_cat,
  }
 -- local res_project = teamyar.call_api(20, '/api/project/AddProject', info_prj);
--  if  res_project.success == true then
    local project_id = c_project_id --res_project.data.project_id
    local li_info = teamyar.get_license_info()
    local link_prj = "<br><br><div>لینک فاکتور خررید:</div><br><a target='_blank' href='https://"..li_info.domain.."/?page=/purchase/invoice/view_invoice/"..invoice_id.."'>"..buy_title.."</a>"
    local info =	{
      wf_id = fw_id,
      crm_id = fact_crm_id,
      comment = comment..link_prj,
      deadline = deadline,
      topic_id = topic_id,
      task_type = task_type,
      project_id = project_id,
      task_title = buy_title
    }
    teamyar.write_log("info---"..json.encode(info))
    local res = teamyar.call_api(8, '/api/todo/taskadd', info);
  teamyar.write_log("res---"..json.encode(res))
 -- else
     --   teamyar.write_log("خطا در ثبت پروژه")
 -- end 
end 
