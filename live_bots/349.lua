-- botName = report
-- creator = zmo
-- date = 8/17/2024
-- version= 1

--------------------------------------------
--- install [RES]
--------------------------------------------
local day = time.get_day(time.current());
local month = time.get_month(time.current());
local year = time.get_year(time.current());
local hour = time.get_hour(time.current());
local min = time.get_minute (time.current());
local sec = time.get_second(time.current());
local currentdate_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":]]..hour..[[,"minute":]]..min..[[,"second":]]..sec..[[}]])
local temp_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":0,"minute":0,"second":0}]])
currentdate = string.format("%18.0f" ,temp_time);
----------------------------------------------------
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

teamyar.write_log(currentdate)

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

    table.insert(res_text, {tempelate_name= record[1],tempelate_id= record[2]  , score= record[3],hr=  record[4]});
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
function getAclPersonnels(data)
local day = time.get_day(time.current());
local month = time.get_month(time.current());
local year = time.get_year(time.current());
local hour = time.get_hour(time.current());
local min = time.get_minute (time.current());
local sec = time.get_second(time.current());
local currentdate_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":]]..hour..[[,"minute":]]..min..[[,"second":]]..sec..[[}]])
local temp_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":0,"minute":0,"second":0}]])
currentdate = string.format("%18.0f" ,temp_time);
  

  local query_param = [[ select distinct p.id,concat('#',h.PERSONNEL_ID,'_',p.fullname)n from hr_personnels h
                                      inner join profile_main p on p.id=h.PROFILE_ID inner join hr_personnel_order o on o.PERSONNEL_ID=h.PERSONNEL_ID 
                                     where  ]]..currentdate..[[ between DATE_FROM and DATE_TO  ]]

  
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  and p.fullname  like N'%]]..data.search..[[%'  or h.PERSONNEL_ID like N'%]]..data.search..[[%' ]]
  end
     teamyar.write_log(query_param)
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
    teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end
--------------------------------------------
function getAclQuestionniers(data)
  local query_param = [[   select id,concat('#',id,'_',name) from poll_questionnaire where show_as_template=1 ]]
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
function getAclTempeletes(data)
  local query_param = [[  select distinct q.id,concat('#',q.id,'_',q.name)name from poll_questionnaire q inner join poll_related r on q.id=r.QUESTIONNAIRE_ID where r.related_type=1 ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  where q.name like N'%]]..data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end
--------------------------------------------
function getData(page)  
  local datef = getInput("datef")
    local datet = getInput("datet")
  
  org = getInput("org")[1]
  local hr = getInput("hr")
  local pattern = getInput("pattern")[1]
  local poll = getInput("poll")[1]

  local org_id = 0
    if  org ~= nil  and org.id~=nil  then 
     org_id= org.id
  end 
  

local query = [[  select distinct (select name from poll_questionnaire where id=q.TEMPLATE_ID)t,q.TEMPLATE_ID, round(sum(m.MARK/100)/count( distinct q.id))s ,(select fullname from profile_main where id=m.RELATED_ID) hr 
 						  from
                          poll_questionnaire q inner join poll_mark m on m.QUESTIONNAIRE_Id=q.id inner join 
                          poll_related r on r.QUESTIONNAIRE_ID=q.id and  r.USER_ID=m.RELATED_ID
                          where r.related_type=1  and  q.TEMPLATE_ID>0 and m.mark>0 and q.ORG_ID= ]]..org.id  

  --where 1
  if  poll ~= nil and   poll.id ~= nil  then 
    query = query.. [[ and q.id= ]]..poll.id  
  end 
    if  pattern ~= nil and   pattern.id ~= nil  then 
    query = query..[[ and q.TEMPLATE_ID= ]]..pattern.id
  end 
  if  hr ~= nil  and #hr>0 then 
    local hr_ids = ""
    for i, v in ipairs(hr) do
      if v.id~= nil then      
        if  hr_ids == "" then
          hr_ids = hr_ids..tostring(v.id);
        else
          hr_ids = hr_ids..","..tostring(v.id);
        end
      end
    end
    if #hr_ids>0 then 
   	 query = query..[[ and m.RELATED_ID in  (]]..hr_ids..[[) ]]
    end
  end 

  if datef ~= nil and datet ~= nil and datef ~= "" and datet ~= "" then 
        datet = datet + (24 * 60 * 60 * 10000000);
        datef = datef - (12 * 60 * 60 * 10000000); --ave first  of day
    query = query..[[ and q.END_DATE between ]]..datef..[[ and ]]..datet
  end 

  query = query..[[ group by m.RELATED_ID, q.TEMPLATE_ID ]]
  local rep_data ={}
  if page ~= nil then 
  rep_data = queryResult(query.." limit ?,20", {page})
else
    rep_data = queryResult(query, {page})
end 
    local total = queryResultTotal(" select count(*) from ("..query..")kk", {})
  return rep_data, total;
end 
--------------------------------------------
function report()  
  local page = getInput("page")
local rep_data,total = getData(page)
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
  getAclPersonnels(teamyar.get_input())
    elseif type==2 then 
  getAclQuestionniers(teamyar.get_input())

      elseif type==7 then 
  getAclOrg(teamyar.get_input())
        elseif type==8 then 
  getAclTempeletes(teamyar.get_input())
elseif type ~= nil and type == 100 then
  report()
  elseif type ~= nil and type == 101 then

 local rep_data =getData()
  local data ={values=rep_data ,  file_name = "test"}
    teamyar.write_result(json.encode(data));
else
  local responseResReport = install_res.resReport();
    teamyar.write_result(responseResReport);

end








