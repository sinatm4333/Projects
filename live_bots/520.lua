local input = teamyar.get_input();
local task_id = input.task_id
local user_info = teamyar.get_user_info();
local config = teamyar.get_config()
local day = time.get_day(time.current());
local month = time.get_month(time.current());
local year = time.get_year(time.current());
local hour = time.get_hour(time.current());
local min = time.get_minute (time.current());
local sec = time.get_second(time.current());
local currentdate_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":]]..hour..[[,"minute":]]..min..[[,"second":]]..sec..[[}]])
local temp_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":0,"minute":0,"second":0}]])
local currentdate = string.format("%18.0f" ,temp_time);

local title=input.task_title
	local category_id=0
	local date_start=currentdate
	local description=""
	local link_stage_sync=0
	local show_user_tasks=0
	local portal_perm_export=0
	local planning_date_limit=0
	local planning_date_start=0
	local portal_perm_add_task=0
	local show_amount_col_portal=0
	local show_first_step_to_all= 0
	local show_progress_col_portal=0
	local show_amount_sum_col_portal=0
	local show_participation_col_portal=0
	local show_stage_description_portal= 0
	local show_project_description_portal=0
local config_data = {}
if config ~= nil then 
  config_data = config.data
   if config_data~= nil then 
	date_limit=config_data.date_limit
	category_id=config_data.category_id
	description=config_data.description
	link_stage_sync=config_data.link_stage_sync
	show_user_tasks=config_data.show_user_tasks
	portal_perm_export= config_data.portal_perm_export
	planning_date_limit=config_data.planning_date_limit
	planning_date_start=config_data.planning_date_start
	portal_perm_add_task=config_data.portal_perm_add_task
	show_amount_col_portal=config_data.show_amount_col_portal
	show_first_step_to_all=config_data. show_first_step_to_all
	show_progress_col_portal=config_data.show_progress_col_portal
	show_amount_sum_col_portal=config_data.show_amount_sum_col_portal
	show_participation_col_portal=config_data.show_participation_col_portal
	show_stage_description_portal= config_data.show_stage_description_portal
	show_project_description_portal=config_data.show_project_description_portal
  else 
          teamyar.write_result("تنظیمات پیکربندی باتی به درستی انجام نشده است")
  end
else 
      teamyar.write_result("تنظیمات پیکربندی باتی انجام نشده است")
end 


----------------------------------------
    local info =	{
	title=title,
	date_limit=date_limit,
	date_start=date_start,
	category_id=category_id,
	description=description,
	link_stage_sync=link_stage_sync,
	show_user_tasks=show_user_tasks,
	portal_perm_export= portal_perm_export,
	planning_date_limit=planning_date_limit,
	planning_date_start=planning_date_start,
	portal_perm_add_task=portal_perm_add_task,
	show_amount_col_portal=show_amount_col_portal,
	show_first_step_to_all= show_first_step_to_all,
	show_progress_col_portal=show_progress_col_portal,
	show_amount_sum_col_portal=show_amount_sum_col_portal,
	show_participation_col_portal=show_participation_col_portal,
	show_stage_description_portal= show_stage_description_portal,
	show_project_description_portal=show_stage_description_portal
}
if task_id ~= nil then
    local   res = teamyar.call_api(20, '/api/project/AddProject', info);
    teamyar.write_log(json.encode(res))
else
    teamyar.write_result("این بات از طریق جریان کاری اقدام اجرا و فراخوانی می شود و باتوجه به پیکربندی بات پروژه ای را ایجاد می نماید و با دکمه اجرای باتی عملیاتی اجرا نمی گردد")
end
