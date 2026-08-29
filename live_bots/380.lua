-- botName = report
-- creator = zmo
-- date = 8/17/2024
-- version= 1
--------------------------------------------
--- install [report]
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
--install_res.resCash();
--------------------------------------------
--- Report
--------------------------------------------
function getAclPersonnel(data)
  local query_param = [[   select PERSONNEL_ID id,fullname name from hr_personnels h inner join profile_main p on h.PROFILE_ID=p.id  ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  where fullname like N'%]]..data.search..[[%' ]]

  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_log(query_param)
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
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
function queryResult(select_query,user_param)
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
      table.insert(res_text, {p = record[1], ms = record[2], mc = record[3], dif = record[4]});
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
--------------------------------------------
function report()  
  local datef=getInput("datef")
    local datet=getInput("datet")
  teamyar.write_log("datet--"..json.encode(datet))
  local per=getInput("personnel")[1]
  local page =getInput("page")
  local query = [[  select concat('#',m1.PERSONNEL_ID,'_',p.fullname)p,ms,mc,mc-ms dif from
                            (select  PERSONNEL_ID,sum(MISSION_OUT_CITY+MISSION_OV_OUT_CITY)ms                            
                           from hr_work_time where 1=1  ]]
  --where 1
  query =query..[[ and WORK_DATE between ]]..datef..[[ and ]]..datet
      if per ~= nil  and per ~= {}  and json.encode(per) ~= "{}" then 
    query =query..[[ and PERSONNEL_ID=]]..per.id
  end
      query =query..[[ group by PERSONNEL_ID )m1
                            cross join   
                            (select PERSONNEL_ID ,sum(TIME_TO-TIME_FROM) mc
                             from hr_ext_time where type=3 and CITY_TYPE=1 ]]
  --where 2
     query =query..[[ and  EXT_DATE between ]]..datef..[[ and ]]..datet
      if per ~= nil  and per ~= {}  and json.encode(per) ~= "{}" then 
    query =query..[[ and PERSONNEL_ID=]]..per.id
  end
      query =query..[[ group by PERSONNEL_ID)m2
                            on m1.PERSONNEL_ID=m2.PERSONNEL_ID inner join 
                            hr_personnels h on h.PERSONNEL_ID=m1.PERSONNEL_ID 
                            inner join profile_main p on h.PROFILE_ID=p.id  ]]

      teamyar.write_log(query)
  
      teamyar.write_log(page)
local per_page=20*page-20
  local rep_data= queryResult(query.." limit ?,20",{per_page})
local total= queryResultTotal("select count(*) from ("..query..")kk",{})
  
 local  report = {
        {
            name = "main" ,
            title = "جدول" ,
            report ={total=total ,data=rep_data,page=page}

        }
    }
    teamyar.write_result(json.encode(report));
end

--------------------------------------------
--- manager
--------------------------------------------
local type = getInput("type");
if type==2 then 
  local  p=getInput("personnel")
  local ii=teamyar.get_input()
  teamyar.write_log(json.encode(ii))
  getAclPersonnel(ii)
 elseif type==3 then 
    local input=teamyar.get_input()
  local datef=input.df
    local datet=input.dt
  teamyar.write_log("input---"..json.encode(input.per))
  local per=input.per
  local query = [[  select concat('#',m1.PERSONNEL_ID,'_',p.fullname)p,ms,mc,mc-ms dif from
                            (select  PERSONNEL_ID,sum(MISSION_OUT_CITY+MISSION_OV_OUT_CITY)ms                            
                           from hr_work_time where 1=1  ]]
  --where 1
  query =query..[[ and WORK_DATE between ]]..datef..[[ and ]]..datet
      if per ~= nil  and per ~=0 then 
    query =query..[[ and PERSONNEL_ID=]]..per
  end
      query =query..[[ group by PERSONNEL_ID )m1
                            cross join   
                            (select PERSONNEL_ID ,sum(TIME_TO-TIME_FROM) mc
                             from hr_ext_time where type=3 and CITY_TYPE=1 ]]
  --where 2
     query =query..[[ and  EXT_DATE between ]]..datef..[[ and ]]..datet
      if per ~= nil  and per ~= 0 then 
    query =query..[[ and PERSONNEL_ID=]]..per
  end
      query =query..[[ group by PERSONNEL_ID)m2
                            on m1.PERSONNEL_ID=m2.PERSONNEL_ID inner join 
                            hr_personnels h on h.PERSONNEL_ID=m1.PERSONNEL_ID 
                            inner join profile_main p on h.PROFILE_ID=p.id  ]]

      teamyar.write_log(query)
  

  local rep_data= queryResult(query,{})
      teamyar.write_result(json.encode(rep_data));
elseif type ~= nil and type == 100 then
    report()
else
  local responseResReport = install_res.resReport();
    teamyar.write_result(responseResReport);
end




