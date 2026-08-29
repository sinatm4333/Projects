local input = teamyar.get_input();
local task_id = input.task_id
----------------------------------------
if task_id ~= nil then
      local info =	{
	task_id = task_id,
     portal_show = 3
}
    local   res = teamyar.call_api(8, '/api/todo/taskedit', info);
    teamyar.write_log(json.encode(res))
else
    teamyar.write_result("این بات از طریق جریان کاری اقدام اجرا و فراخوانی می شود و با دکمه اجرای باتی عملیاتی اجرا نمی گردد")
end
