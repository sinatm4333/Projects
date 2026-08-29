-- botName = report
-- creator = zmo
-- date = 8/17/2024
-- version= 1

--------------------------------------------
--- install [RES]
--------------------------------------------
  local org = {}--getInput("org")[1]
local day = time.get_day(time.current());
local month = time.get_month(time.current());
local year = time.get_year(time.current());
local hour = time.get_hour(time.current());
local min = time.get_minute (time.current());
local sec = time.get_second(time.current());
local currentdate_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":]]..hour..[[,"minute":]]..min..[[,"second":]]..sec..[[}]])
local temp_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":0,"minute":0,"second":0}]])
currentdate = string.format("%18.0f" ,temp_time);
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
--- install [report]
--------------------------------------------
-- local org_id=2 --organization ID
local uinfo=teamyar.get_user_info();
local user_id= uinfo.id;
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

    table.insert(res_text, { task = record[1],  task_id = record[2],
                                        step = record[3], wf = record[4], 
                                        delay = record[5],  step_status = record[6], 
                                        step_date = record[7],    responsible = record[8], 
                                        date_modify = record[9],  hr_status = record[10],
                                        group = record[11],
       delay_h = record[12] ,
       delay_m = record[13],
      deadtime =  record[14], });
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
  teamyar.write_log(select_query)
  db.query(params1);
  local res_text = db.query_fetch();
  db.query_free();
  return res_text[1];
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
function getAclGroups(data)
  local query_param = [[  select id,name from hr_salary_groups where 1=1 ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  and name like N'%]]..data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end
--------------------------------------------
function getAclOrg(data)
  local query_param = [[  select id,name from org_info ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  where name like N'%]]..data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end
--------------------------------------------
function getData(page,currentdate)  
  teamyar.write_log(currentdate)
  local datef = getInput("datef")
  local datet = getInput("datet")
    local dated = getInput("dated")
  org = getInput("org")[1]
  local group = getInput("group")
  local wf = getInput("wf")
  local user_id = getInput("user_id")[1]
  local org_id = 0
    if  org ~= nil   then 
     org_id = org.id
  end 
  local date_delay = currentdate
teamyar.write_log(#json.encode(dated))
  if  dated ~= nil and  #json.encode(dated) > 2 then 
    date_delay = dated
  end
local with_str= [[
                        with last_orders as (select id, PERSONNEL_ID,
                        STATUS,SALARY_GROUP_ID from hr_personnel_order o
                        where id =(select max(id) from hr_personnel_order
                        where personnel_id=o.personnel_id) 
                        and  ]]..currentdate..[[ between 
                        DATE_FROM and DATE_TO and o.type=3 )
                    ]]
local query = [[    select t.TASK_TITLE,t.id, s.STEP_NAME,wf.WF_TITLE ,
  (select case when ts.date_end>0 then  round(( ]]..date_delay..[[-(ts.date_start+(s.duration*(select case when s.time_unit=1 then (10000000*60) when s.time_unit=2 then (10000000*60*60) when  s.time_unit=3 then (10000000*60*60*24) end))))/(60*60*24*10000000)) else 0 end )  delay_d,
                            ts.STATUS ts_status,ts.DATE_CREATE,
                            (select fullname from profile_main where id=ts.RESPONSIBLE_ID)res,ts.DATE_MODIFY ,o.status,sg.name,
    (select case when ts.date_end>0 then  round(( ]]..date_delay..[[-(ts.date_start+(s.duration*(select case when s.time_unit=1 then (10000000*60)
  when s.time_unit=2 then (10000000*60*60) when  s.time_unit=3 then (10000000*60*60*24) end))))/(60*60*10000000)) else 0 end )  delay_h,
    (select case when ts.date_end>0 then  round(( ]]..date_delay..[[-(ts.date_start+(s.duration*(select case when
  s.time_unit=1 then (10000000*60) when s.time_unit=2 then (10000000*60*60) when  s.time_unit=3 then (10000000*60*60*24) end))))/(60*10000000)) else 0 end )  delay_m ,
   ( ts.date_start+(s.duration*(select case when s.time_unit=1 then (10000000*60) when s.time_unit=2 then (10000000*60*60) when  s.time_unit=3 then (10000000*60*60*24) end))) deadtime
                           from todo_task t inner join todo_task_steps ts on
                            ts.task_id=t.id inner join  todo_step s on s.id=ts.STEP_ID
                            inner join todo_workflow wf on wf.id=t.WORK_FLOW_ID left join last_orders o 
                            on o.PERSONNEL_ID=ts.RESPONSIBLE_ID left join
                            hr_salary_groups sg on sg.id=o.SALARY_GROUP_ID left join
                            hr_personnels hr on hr.PERSONNEL_ID=o.PERSONNEL_ID where ts.FLAG_LAST_STEP=1  and t.STATUS=1 ]]
  --where 1
  if datet ~= nill  and datet ~= "" then 
    datet = datet + (24 * 60 * 60 * 10000000);
  end

    query = query..[[ and ts.DATE_CREATE between ]]..datef..[[ and ]]..datet

  if dated ~= nil and json.encode(dated) ~= "" then 
    query = query..[[ and ts.DATE_CREATE between ]]..datef..[[ and ]]..datet
  end 
    if  user_id ~= nil  and user_id.id ~= nil  then
      query = query..[[ and ts.RESPONSIBLE_ID = ]]..user_id.id
  end 
  if  org ~= nil  and org.id ~= nil  then
      query = query..[[ and hr.org_id = ]]..org.id
  end 
  if  group ~= nil  and #group>0 then 
    local group_ids = ""
    for i, v in ipairs(group) do
      if v.id~= nil then      
        if  group_ids == "" then
          group_ids = group_ids..tostring(v.id);
        else
          group_ids = group_ids..","..tostring(v.id);
        end
      end
    end
    if #group_ids>0 then 
   	 query = query..[[ and sg.id in  (]]..group_ids..[[) ]]
    end
  end 
-------------
  if  wf ~= nil  and #wf>0 then 
    local wf_ids = ""
    for i, v in ipairs(wf) do
      if v.id~= nil then      
        if  wf_ids == "" then
          wf_ids = wf_ids..tostring(v.id);
        else
          wf_ids = wf_ids..","..tostring(v.id);
        end
      end
    end
    if #wf_ids>0 then 
   	 query = query..[[ and wf.id in  (]]..wf_ids..[[) ]]
    end
  end 
  local rep_data ={}
  if page ~=nil then 
  rep_data = queryResult(with_str..query.." limit ?,20", {page})
else
    rep_data = queryResult(with_str..query, {page})
end 
    local total = queryResultTotal(with_str.." select count(*) from ("..query..")kk", {})
  return rep_data, total;
end 
--------------------------------------------
function report()  
  local page = getInput("page")
local rep_data,total = getData(page,currentdate)
  local  report = {
    {
      name = "main" ,
      title = "جدول" ,
      report ={total = total , data = rep_data, page = page}
    }
  }
  teamyar.write_result(json.encode(report));
end

--------------------------------------------
--- manager
--------------------------------------------
local type = getInput("type");
if type == 3 then 
  local input = teamyar.get_input()
  local datet = input.datet
  local datef = input.datef
    local dated= input.dated
  --where 1
  if datet ~= nill  and datet ~= "" then 
    datet = datet + (24 * 60 * 60 * 10000000);
  end

  if datef ~= nil and datet ~= nil then 
    query = query..[[ and _ic.RUN_DATE between ]]..datef..[[ and ]]..datet
  end 
 
  local rep_data = queryResult(with_str..query, {})
  teamyar.write_result(json.encode(rep_data));
  elseif type==1 then 
  getAclGroups(teamyar.get_input())
    elseif type==2 then 
  getAclWF(teamyar.get_input())
      elseif type==7 then 
  getAclOrg(teamyar.get_input())
elseif type ~= nil and type == 100 then
  report()
  elseif type ~= nil and type == 101 then
 local rep_data =getData(nil,currentdate)
  local data ={values=rep_data ,  file_name = "test"}
    teamyar.write_result(json.encode(data));
else
  local responseResReport = install_res.resReport();
    teamyar.write_result(responseResReport);

end








