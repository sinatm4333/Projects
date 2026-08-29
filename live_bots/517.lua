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

    table.insert(res_text, { task = record[1],
                                        task_id = record[2],
                                        step = record[3], 
                                        wf = record[4], 
                                        delay = record[5], 
                                        step_status = record[6], 
                                        step_date = record[7],   
                                        date_modify = record[9], 
                                        delay_h = record[12] ,
                                        delay_m = record[13],
                                        deadtime =  record[14], 
                                        personnel =  record[15],
                                        unit =  record[16],});
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
  local wf = getInput("wf")
  local date_delay = currentdate
teamyar.write_log(#json.encode(dated))
  if  dated ~= nil and  #json.encode(dated) > 2 then 
    date_delay = dated
  end
local with_str = [[ with pers_manager as ( 
                             select distinct p.PROFILE_ID pers ,u.manager from hr_personnel_order o inner join org_organization_unit ou on ou.id= o.unit_id inner join org_units u on u.id= ou.UNIT_ID 
                             inner join hr_personnels p on p.PERSONNEL_ID=o.PERSONNEL_ID
                             where o.id =(select max(id) from hr_personnel_order where personnel_id=o.personnel_id) 
                               and o.status=1 

                             ) ,pers_unit as (
                              select distinct p.PROFILE_ID pers ,u.name unit_name from hr_personnel_order o inner join org_organization_unit ou on ou.id= o.unit_id inner join org_units u on u.id= ou.UNIT_ID 
                             inner join hr_personnels p on p.PERSONNEL_ID=o.PERSONNEL_ID
                             where o.id =(select max(id) from hr_personnel_order where personnel_id=o.personnel_id)                              
                             )
  						]]
 -- local with_str =""
local query = [[    select t.TASK_TITLE,t.id, s.STEP_NAME,wf.WF_TITLE ,
 						 (select case when ts.date_end>0 then  round(( ]]..date_delay..[[-(ts.date_start+(s.duration*(select case when s.time_unit=1 then (10000000*60) when
  							s.time_unit=2 then (10000000*60*60) when  s.time_unit=3 then (10000000*60*60*24) end))))/(60*60*24*10000000)) else 0 end )  delay_d,
                            ts.STATUS ts_status,ts.DATE_CREATE,
                            0 res,ts.DATE_MODIFY ,1 ostatus,1 sgname,
                            (select case when ts.date_end>0 then  round(( ]]..date_delay..[[-(ts.date_start+(s.duration*(select case when s.time_unit=1 then (10000000*60)
                          when s.time_unit=2 then (10000000*60*60) when  s.time_unit=3 then (10000000*60*60*24) end))))/(60*60*10000000)) else 0 end )  delay_h,
                            (select case when ts.date_end>0 then  round(( ]]..date_delay..[[-(ts.date_start+(s.duration*(select case when
                          s.time_unit=1 then (10000000*60) when s.time_unit=2 then (10000000*60*60) when  s.time_unit=3 then (10000000*60*60*24) end))))/(60*10000000)) else 0 end )  delay_m ,
                           ( ts.date_start+(s.duration*(select case when s.time_unit=1 then (10000000*60) when s.time_unit=2 then (10000000*60*60) when  s.time_unit=3 then (10000000*60*60*24) end))) deadtime,
 						 (select group_concat(unit_name) from pers_unit where pers=ts.RESPONSIBLE_ID)unit,(select fullname from profile_main where id=ts.RESPONSIBLE_ID)per_name
                           from todo_task t inner join todo_task_steps ts on
                            ts.task_id=t.id inner join  todo_step s on s.id=ts.STEP_ID
                            inner join todo_workflow wf on wf.id=t.WORK_FLOW_ID 
  							where ts.FLAG_LAST_STEP=1  and t.STATUS=1   and (ts.RESPONSIBLE_ID in (select pers from  pers_manager where manager= ]]..user_id..[[ ) or  ts.RESPONSIBLE_ID =]]..user_id..[[ )]]
  --where 1
  if datet ~= nill  and datet ~= "" then 
    datet = datet + (24 * 60 * 60 * 10000000);
  end



--  if dated ~= nil and json.encode(dated) ~= "" then 
    query = query..[[ and ts.DATE_CREATE between ]]..datef..[[ and ]]..datet
 -- end 



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
  teamyar.write_log(query)
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








