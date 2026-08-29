local input  = teamyar.get_input()
local task_id= input.task_id
if task_id== nil or task_id ==0 then 
  teamyar.write_result(" این بات از طریق جریان کاری اقدام فراخوانی می شود و به صورت دستی اجرا نمی گردد")
  task_id =0
end 
----------------------------------------
function closeTodo(taskid)
  local info = {
    status = 2,
    task_id = taskid
  }
  local   res2 = teamyar.call_api(8,  '/api/todo/task/status/set', info);
  teamyar.write_log("res2----"..json.encode(res2))
end
----------------------------------------
function completeStep(stepid,task_id)
  local info ={
    status = 1,
    step_id = stepid,
    task_id = task_id
  }

  local   res2 = teamyar.call_api(8,  '/api/todo/taskstep/status/set', info);
  teamyar.write_log("res2----"..json.encode(res2))
end
--------------------------------------------
function queryData(select_query, user_param)
  db.use_db("0000000")
  local params = {
    query = select_query,
    params = user_param
  }
  db.query(params);
  local res_text = {};
  local record = {};
  while db.query_fetch(record) do
    table.insert(res_text, {step_id = record[1] })
  end
  db.query_free();
  return res_text;
end
----------------------------------------
local q = [[select STEP_ID from todo_task_steps where task_id= ]]..task_id
local steps = queryData(q,{})
for i, v in ipairs(steps) do
  completeStep(v.step_id,task_id)
end 
closeTodo(task_id)