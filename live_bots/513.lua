-- botName = report
-- creator = zmo
-- date = 8/17/2024
-- version= 1
--------------------------------------------
--- install [report]
--------------------------------------------
local  work_flow_id=496
local step_id=3682-- تایید باگ کارشناس فنی
local step_bug_process_id=3688 --پردازش باگ استقرار
local step_delever_id=3669--مرحله پیگیری و خاتمه 
local step_develope_id=3674--مرحله توسعه داده شده 
-- local step_tech_process_id=44--مرحله ای که فیلد سفارشی شبیه سازی شده کارشناس فنی دارد
local field_name_had_todo='اقدام داخلی مرتبط'
local field_name_re_event='combobox_name4_3682_1453'
local field_name_develop_simulated='simolation_test'
local field_name_tech_simulated='simolation_test'

---
local day = time.get_day(time.current());
local month = time.get_month(time.current());
local year = time.get_year(time.current());
local min = time.get_minute(time.current());
local hour = time.get_hour(time.current());
local sec = time.get_second(time.current());
local temp_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":]]..hour..[[,"minute":]]..min..[[,"second":]]..sec..[[}]])
local currentdate = string.format("%18.0f", temp_time);
--teamyar.write_log(currentdate)
local input=teamyar.get_input()
local datef = input.datef
local datet = input.datet
if datet ~= nill  and datet ~= "" then 
  datet=datet + (24 * 60 * 60 * 10000000);
end
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
--------------------------------------------
--- Report
--------------------------------------------

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
-------------------------------------------
function queryResult(select_query, user_param)
  db.use_db("0000000")
  local params = {
    query = select_query,
    params = user_param
  }
  teamyar.write_log(select_query)
  db.query(params);
  local res_text = {};
  local record = {};
  while db.query_fetch(record) do
    table.insert(res_text, record[1]);
  end
  db.query_free();
  return res_text;
end
-------------------------------------------
function queryResultItem(select_query,user_param)
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
    table.insert(res_text, {c= record[1], ids = record[2]});
  end
  db.query_free();
  return res_text;
end
-------------------------------------------
function getQueryTbl(select_query,user_param)
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
    table.insert(res_text, {id = record[1], t = record[2], client =  record[3], d =  record[4], d_inspect_develop =  record[5], d_inspect_tech =  record[6], d_develop =  record[7], d_deliver =  record[8]});
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
-------------------------------------------
function queryResultTotal(select_query,user_param)
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
-------------------------------------------
function getQuery(status)
  local q= [[ select  ( select count(t.id)  from todo_task t inner join 
                    todo_task_steps ts on ts.TASK_ID=t.id  
                    where t.TOPIC_ID=topic.id and 
                    t.WORK_FLOW_ID =]]..work_flow_id..[[ and ts.status=]]..status..[[
                    and ts.STEP_ID=]]..step_id
  if datef ~= "" and datef ~= nil and datet ~= "" and datet ~= nil then 
    q = q..[[ and ts.DATE_CREATE between ]]..datef..[[ and ]]..datet
  end
  q = q..[[ ) c from todo_topic topic where topic.id in 
                  (122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137
                  ,140,142,143,156,193,190,200,203,205,211,194,286)  order by topic.id ]]
  return q
end 
--------------------------------------------
function report()  
  local unit_name="--"
  local unit_id=0
  if unit ~= nil then 
    unit_name = unit.name
    unit_id = unit.id
  end 



  --where 1

  local labels = queryResult([[ select name from todo_topic where
                                              id in (122,123,124,125,126,127,128,129,130,131,
                                              132,133,134,135,136,137,140,143,142,156,193,
                                              190,200,203,205,211,194,286) order by id ]], {})

  local drafts = queryResult(getQuery(0), {})
  local inspect = queryResult(getQuery(1), {})
  local doing = queryResult(getQuery(2), {})
  local complete = queryResult(getQuery(3), {})
  local lic=teamyar.get_license_info()

  local license_id=lic.id
  local  report = {
    {
      name = "main" ,
      title = "جدول" ,
      report = { labels = labels, drafts = drafts, inspect = inspect, doing = doing, complete = complete, license_id = license_id}
    }
  }

  teamyar.write_result(json.encode(report));
end
--------------------------------------------
function getQueryColumnChart(module_name,step_id,status,custom_field)
  local q= [[select count(DISTINCT  t.id),group_concat(t.id)ids  from todo_topic topic 
                  inner join  todo_task t on  t.TOPIC_ID=topic.id inner join
                  todo_task_steps ts on t.id=ts.TASK_ID  where topic.name like
                  N'%]]..module_name..[[%' and ts.STEP_ID=]]..step_id..[[ and ts.STATUS=]]..status..[[  and  t.WORK_FLOW_ID =]]..work_flow_id
  if datef ~= "" and datef ~= nil and datet ~= "" and datet ~= nil then 
    q = q..[[ and ts.DATE_CREATE between ]]..datef..[[ and ]]..datet
  end
  return q
end 
--------------------------------------------
--- manager
--------------------------------------------
local type = getInput("type");
if type == 4 then 
  getAclOrg(teamyar.get_input())
elseif type == 5 then 
  getAclProduct(teamyar.get_input())
elseif type == 6 then 
  getAclUnit(teamyar.get_input())
elseif type == 7 then 
  getAclUnit(teamyar.get_input())
elseif type == 9 then --table data
  local ids= teamyar.get_input().ids

  local res_tbl =getQueryTbl( [[
                                                select id,concat('#',id,'_',TASK_TITLE)t,(select name from pa_client where id=OWNER_ID)client,round((]]..currentdate..[[-T_START_DATE)/(60*60*24*10000000))d,
                                                (select round((]]..currentdate..[[-date_start)/(60*60*24*10000000))  from todo_task_steps ts  where  ts.STEP_ID=]]..step_bug_process_id..[[ and TASK_ID=id) d_inspect_develop,
                                                (select round((]]..currentdate..[[-date_start)/(60*60*24*10000000))  from todo_task_steps ts  where  ts.STEP_ID=]]..step_id..[[ and TASK_ID=id) d_inspect_tech,
                                                (select round((]]..currentdate..[[-date_start)/(60*60*24*10000000))  from todo_task_steps ts  where  ts.STEP_ID=]]..step_develope_id..[[ and TASK_ID=id) d_develop,
                                                (select round((]]..currentdate..[[-date_start)/(60*60*24*10000000))  from todo_task_steps ts  where  ts.STEP_ID=]]..step_delever_id..[[ and TASK_ID=id) d_deliver
                                                from todo_task where id in (]]..ids..[[)
                                                ]],{})
  teamyar.write_result(json.encode(res_tbl));
elseif type == 8 then -- second chart data
  local module_name = teamyar.get_input().module_name

  local draft = queryResultItem(getQueryColumnChart(module_name,step_id,0),{})
  local compelete = queryResultItem(getQueryColumnChart(module_name,step_id,1),{})
  local confirm = queryResultItem(getQueryColumnChart(module_name,step_id,2),{})
  local reject = queryResultItem(getQueryColumnChart(module_name,step_id,3),{})
local develop =  queryResultItem([[select count(t.id),group_concat(t.id)ids  from todo_topic topic 
                                                        inner join  todo_task t on  t.TOPIC_ID=topic.id inner join
                                                        todo_task_steps ts on t.id=ts.TASK_ID  inner join todo_step s on s.id=ts.step_id where topic.name like 
                                                        N'%]]..module_name..[[%' and ts.STEP_ID=]]..step_develope_id..[[ and ts.STATUS=1   and s.state=3  and t.WORK_FLOW_ID =]]..work_flow_id..[[  ]],{})
local deliver =  queryResultItem([[ select count(t.id),group_concat(t.id)ids  from todo_topic topic 
                                                      inner join  todo_task t on  t.TOPIC_ID=topic.id inner join
                                                      todo_task_steps ts on t.id=ts.TASK_ID    inner join todo_step s on s.id=ts.step_id where topic.name like
                                                      N'%]]..module_name..[[%' and ts.STEP_ID=]]..step_delever_id..[[ and ts.STATUS=1  and s.state=3  and  t.WORK_FLOW_ID =]]..work_flow_id..[[]],{})

local establish_similared = queryResultItem( [[ select count(t.id),group_concat(t.id)ids from
                                                                      todo_topic topic  inner join  todo_task t on 
                                                                      t.TOPIC_ID=topic.id inner join todo_task_steps ts on t.id=ts.TASK_ID 
                                                                      inner join  todo_custom_form cf on cf.id=ts.id
                                                                      where  ts.STEP_ID=]]..step_bug_process_id..[[  and topic.name like
                                                                      N'%]]..module_name..[[%' and (cf.form_data->>'$.]]..field_name_develop_simulated..[[')="1"  and  t.WORK_FLOW_ID =]]..work_flow_id..[[  ]] ,{})
local tech_similared = {{c= 0, ids = ""}}
local re_event = queryResultItem([[   select count(t.id),group_concat(t.id)ids from todo_topic topic  
                                                          inner join  todo_task t on  t.TOPIC_ID=topic.id
                                                          inner join todo_task_steps ts on t.id=ts.TASK_ID 
                                                          inner join  todo_custom_form cf on cf.id=ts.id
                                                          where  ts.STEP_ID=]]..step_id..[[  and  t.WORK_FLOW_ID =]]..work_flow_id..[[ and  topic.name like
                                                          N'%]]..module_name..[[%' and (cf.form_data->>'$.]]..field_name_re_event..[[')="1" ]],{})

local has_todo =queryResultItem([[ select count(t.id),group_concat(t.id)ids from todo_topic topic  inner join
                                                        todo_task t on  t.TOPIC_ID=topic.id inner join todo_task_steps ts on t.id=ts.TASK_ID 
                                                        inner join  todo_custom_form cf on cf.id=ts.id
                                                        where  ts.STEP_ID=]]..step_id..[[  and  t.WORK_FLOW_ID =]]..work_flow_id..[[ and topic.name like
                                                        N'%]]..module_name..[[%' and (cf.form_data->>'$.]]..field_name_had_todo..[[')="1"  ]],{})

local close_count = queryResultItem([[ select count(t.id),group_concat(t.id)ids  from todo_topic topic  inner join
                                                            todo_task t on  t.TOPIC_ID=topic.id inner join todo_task_steps ts on t.id=ts.TASK_ID 
                                                            where topic.name like N'%]]..module_name..[[%' and t.STATUS=2   and ts.STEP_ID=]]..step_id..[[  and  t.WORK_FLOW_ID =]]..work_flow_id..[[  ]],{})

if has_todo == nil  or #has_todo == 0 then 
  has_todo = {{c= 0, ids = ""}}
end

local  res = {
                    draft = draft,
                    compelete = compelete,
                    confirm = confirm,
                    reject = reject, 
                    develop = develop,
                    deliver = deliver,
                    establish_similared = establish_similared,
                    tech_similared = tech_similared,
                    re_event = re_event,
                    has_todo = has_todo,
                    close_count = close_count,
                    module_name = module_name
                  }

teamyar.write_result(json.encode(res))
elseif type == 3 then 
local input = teamyar.get_input()
--where 1
local rep_data = {}
teamyar.write_result(json.encode(rep_data));
elseif type ~= nil and type == 100 then
install_res.setCashInputs();
report()
else
  local responseResReport = install_res.resReport();
    teamyar.write_result(responseResReport);
end




