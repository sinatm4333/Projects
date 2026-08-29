-- botName = report
-- creator = zmo
-- date = 3/5/2025
-- version= 1
--------------------------------------------
--- install [RES]
--------------------------------------------
local _BAT_RES_PATH = "2/res_v2";
function readyCodes()
  local data = teamyar.get_input();
  data["res_type"] = "codes"
  data["config"] = json.decode(teamyar.get_attachment("data.txt"))
  local responseRes = teamyar.run_command(_BAT_RES_PATH , data);
  if responseRes ~= nil then
    responseRes = json.decode(responseRes)
    for i = 1 , #responseRes, 1 do
      local loadedFunction, errorMessage = load(responseRes[i])
      if loadedFunction then
        loadedFunction();
      else
        teamyar.write_log("Error: " .. errorMessage);
      end
    end
  end
end
readyCodes();
install_res.resCash();
-----------------------------------------------------------
function getQueryResponse(query,query_params)
  db.use_db("0000000")
  local params = {
    query = query,
    params = query_params
  }
  db.query(params);
  local res_text = db.query_fetch();
  db.query_free();
  return res_text[1];
end
--------------------------------------------
--- install [report]
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
    table.insert(res_text, {tid = record[1], tname = record[2], dd = record[3], wf = record[4]})
  end
  db.query_free();
  return res_text;
end
-------------------------------------------
function queryResultAcl(select_query,user_param)
  db.use_db("0000000")
  local params = {
    query = select_query,
    params = user_param
  }
  db.query(params);
  local res_text={};
  local record={};
  while db.query_fetch(record) do
    local tmp=record;
    table.insert(res_text, {id = record[1], name = record[2], type =1});
  end
  db.query_free();
  return res_text;
end
-----------------------------------------------------------
function getData(page, datef, datet, wf)  
  local res_text = ""
    if datet ~= nill  and datet ~= "" then 
    datet = datet + (24 * 60 * 60 * 10000000);
  end
      if datef ~= nil  and datef ~= "" then 
    datef = datef - (12 * 60 * 60 * 10000000);
  end
  local q_p = [[ select id,TASK_TITLE,T_START_DATE,(select WF_TITLE from todo_workflow where id=WORK_FLOW_ID)wf from todo_task 
                        where status=1 and T_START_DATE between   ]]..datef..[[ and ]]..datet
  if wf ~= nil  and wf.id ~= nil and  wf.id>0 then     
 	 q_p = q_p..[[ and WORK_FLOW_ID=]]..wf.id
  end 

  local res_data ={}
  if page ~= nil then 
  	res_data = queryData(q_p..[[ limit ]]..page..[[,]]..page+20  , {})
  else
     res_data = queryData(q_p , {})
  end
 queryData(q_p , {})
  local q_total = [[ select count(*) from (]]..q_p..[[ )mm ]]
  
  local total = getQueryResponse(q_total,{})
  return res_data, total;
end 
--------------------------------------------
function report()  
  local str_title = "جدول"
  local page = getInput("page")
    local datef = getInput("datef")
    local datet = getInput("datet")
    local wf = getInput("wf")[1]
  if fd ~= nil then 
    str_title = fd
  end
  local rep_data, total = getData(page,datef,datet,wf)
  local  report = {
    {
      name = "main" ,
      title = str_title,
      report = {total = total , data = rep_data, page = page}
    }
  }
  teamyar.write_result(json.encode(report));
end
----------------------------------------
function closeAllTodo(df, dt, wf)
 local res_data =  getData(nil,df,dt,wf)
      for i, v in ipairs(res_data) do
		closeTodo(v.tid)
     end 
end
----------------------------------------
function closeTodo(taskid)
  local info = {
	status = 2,
	task_id = taskid
}
    teamyar.write_log("info----"..json.encode(info))
    local   res2 = teamyar.call_api(8,  '/api/todo/task/status/set', info);
teamyar.write_log("res2----"..json.encode(res2))
end
--------------------------------------------
function getAclWF(data)
  local query_param = [[   select id,WF_TITLE from todo_workflow where 1=1  ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  and  WF_TITLE like N'%]]..data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end
--------------------------------------------
--- manager
--------------------------------------------
local type = getInput("type");
if type==2 then 
  getAclWF(teamyar.get_input())
elseif type ~= nil and type == 6 then
  local input_in = teamyar.get_input()
  local tid = input_in.tid
  closeTodo(tid)
  teamyar.write_result(json.encode({ok = msg}));
  elseif type ~= nil and type == 7 then
  local input_in = teamyar.get_input()

  local df= input_in.datef
  local dt = input_in.datet
    local wf = input_in.wf
  closeAllTodo(df, dt, wf)
  teamyar.write_result(json.encode({ok = msg}));
elseif type ~= nil and type == 100 then
  report()
else
  local responseResReport = install_res.resReport();
  teamyar.write_result(responseResReport);

end








