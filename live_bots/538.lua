--Bot Total Salary zmo
input = teamyar.get_input();
local user_info = teamyar.get_user_info();
local user_id = math.floor(user_info["id"]); 
local org_id = input.org_id;
if org_id == nil then
  org_id=0;
end
local datef = input.df;
local datet = input.dt;
local month = input.month;
local mali_year= input.mali_yr
if account_id == nill then 
  account_id = "";
end 
local cte_str=[[WITH CTE1095 AS ( SELECT _dc.ORG_ID ORG_ID, _dc.PERSONNEL_ID PersonnelID, _dc.PROFILE_ID ProfileID, _dc.PERSONNEL_CODE PersonnelCode, _dd.salary_group_id sg,
                              _dd.ID OrderID, _dc.ACCOUNT_NUMBER AccountNumber, _de.UNIT_ID UNIT_ID FROM `0000000`.`HR_PERSONNELS` _dc JOIN `0000000`.`HR_PERSONNEL_ORDER` _dd
                              ON (_dd.PERSONNEL_ID = _dc.PERSONNEL_ID AND _dd.ORG_ID = _dc.ORG_ID) JOIN `0000000`.`ORG_ORGANIZATION_UNIT` _de 
                              ON (_de.ID = _dd.UNIT_ID AND _de.ORG_ID = _dc.ORG_ID) WHERE _dc.ORG_ID = ']]..org_id..[[' )  ]]
---------------------------------------------
function loadData()
  local data = teamyar.get_data("total_salary_data")
  teamyar.write_result(data. value);
end
  -----------------------------------------------------------
  function getQueryResponse2(query,query_params)
    db.use_db("0000000")
    local params = {
      query = query,
      params = query_params
    }
    db.query(params);
    local res_text={};
    local record={};
    while db.query_fetch(record) do
      local tmp=record;
      table.insert(res_text,{n=record[1],v=record[2]});
    end
    db.query_free();
    return res_text;
  end

  -----------------------------------------------------------
  function getQueryResponse1(query,query_params)
    db.use_db("0000000")
    local params = {
      query = query,
      params = query_params
    }
    db.query(params);
    local res_text={};
    local record={};
    while db.query_fetch(record) do
      local tmp=record;
      table.insert(res_text,{id=record[1],name=record[2],type=record[3]});
    end
    db.query_free();
    return res_text;
  end
  --------------------------------
function queryResult(select_query,user_param)
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
----------------------
function orgAcl(data)
  local query_param = [[ SELECT JSON_ARRAYAGG(JSON_OBJECT('id',id, 'name',name, 'type',1))
  										from (select id,name from org_info ]]
 if data.search ~= nil and #data.search > 0 then
     query_param = query_param..[[  where name like N'%]]..data.search..[[%') as p ]]
  else
	query_param = query_param .. [[) p ]]
  end
query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
teamyar.write_result(queryResult(query_param, {}));
end
----------------------
function unitAcl(data)
  local geted_org_id = data.org_id;
    local query_param = [[ SELECT JSON_ARRAYAGG(JSON_OBJECT('id',id, 'name',name, 'type',1))
    from (select u.id,u.name from org_units u  where organizatin_id=]]..geted_org_id
    if data.search ~= nil and #data.search > 0 then
      query_param = query_param..[[  and  u.name like N'%]]..data.search..[[%') as p ]]
    else
      query_param = query_param .. [[) p ]]
    end
    query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
    teamyar.write_result(queryResult(query_param, {}));
end
----------------------
function salaryGroupAcl(data)
    local geted_org_id = data.org_id;
    local query_param = [[ SELECT JSON_ARRAYAGG(JSON_OBJECT('id',id, 'name',name, 'type',1))
   										 from (select id,name from hr_salary_groups where org_id=]]..geted_org_id
    if data.search ~= nil and #data.search > 0 then
      query_param = query_param..[[  and  name like N'%]]..data.search..[[%') as p ]]
    else
      query_param = query_param .. [[) p ]]
    end
    query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
    teamyar.write_result(queryResult(query_param, {}));
end
----------------------
function personnelAcl(data)
    local geted_org_id = data.org_id;
    local query_param = [[ select h.personnel_id id,p.fullname name,1 type from hr_personnels h inner join profile_main p on h.profile_id=p.id where p.type=1 and  stop_working_date=0 and org_id=]]..geted_org_id
    if data.search ~= nil and #data.search > 0 then
      query_param = query_param..[[  and fullname like N'%]]..data.search..[[%' ]]
    end
    query_param = query_param .. string.format(" limit %d,%d ", data.from,data.count);   
    teamyar.write_result(json.encode(getQueryResponse1(query_param, {})));
end
-----------------------------------------------
function WidgetTemplate()  
  local random = math.random(1,1000);
  local script =  teamyar.get_attachment("main.js");
  local css =  teamyar.get_attachment("main.css");
  local  str_lang="";
    local  str_title="";
  if user_info.lang_id == 4 then
    str_title="گزارش حقوق و دستمزد - سرجمع "
    str_lang = teamyar.get_attachment("Persian.js");
  else
    str_title="Bot Total Salary"
     str_lang = teamyar.get_attachment("English.js");
  end
  local template = teamyar.run_command("2/res_bot",{
      id = "bot_total_salary",
      tpl_name = "html",
      title = str_title,
      body = "<div id=\\'btsalary_holder_body_html_"..random.."\\'></div>",
      script=[[
      (function(){
      ]]..str_lang..[[      
      var holder_id = '#btsalary_holder_body_html_]]..random..[[';
    var random_id = ]] .. random .. [[;
      ]]..script..[[
    })();
      ]],
      css = css
    });
  teamyar.write_result(template); 
end
----------------------------------------------
function getParams(personnel_id)
 datef = input.df;
datet = input.dt;
 --   teamyar.write_log(datet)
  local params_qry=[[
 SELECT  NAME n, VALUE_ v FROM HR_PAYSLIP_PAYMENT_DETAIL WHERE PAYSLIP_ID IN(SELECT max(p.id) FROM HR_PAYSLIP p inner join hr_personnel_order o on p.order_id=o.id
    WHERE o.personnel_id = ]]..personnel_id..[[

)   ORDER BY R_ORDER DESC  ]]
  
  --  and DATE_FROM >= ]]..datef..[[ AND DATE_TO <=  ]]..datet..[[ 
  teamyar.write_log(params_qry)
  teamyar.write_result(json.encode(getQueryResponse2(params_qry, {})));
end
---------------------main
if input.type == 3 then 
   loadData()
elseif input.type == 2 then 
  orgAcl(input.data)
elseif  input.type == 5 then 
  unitAcl(input.data)
elseif  input.type == 4 then 
  personnelAcl(input.data)
elseif  input.type == 6 then 
  salaryGroupAcl(input.data)
elseif  input.type == 7 then 
  getParams(input.pi)  
elseif input.type == 1 then 
teamyar.write_log(json.encode(input))
  local chash_data = {	btsalary_org_id = org_id, btsalary_gn = input.gn, btsalary_unit = input.unit_id, btsalary_un= input.un, btsalary_datet = datet, btsalary_datef = datef,
    								btsalary_personnel = input.personnel_id,btsalary_pern=input.pern, btsalary_pn = input.pn , btsalary_salarygroup = input.salary_group, 
    								btsalary_sqn = input.sgn, btsalary_parameter = input.parameter_id, btsalary_pn = input.pn}
  teamyar.set_data("total_salary_data", json.encode(chash_data));
local qselect=[[ SELECT Round(SUM(CASE WHEN pd.Type = 2 THEN COALESCE(pd.Value_,0)/POWER(10 , COALESCE(0,0)) WHEN pd.Type = 1 THEN -COALESCE(pd.Value_,0)/POWER(10 , COALESCE(0,0)) ELSE 0 END )  ,0) ps
                        ,(Round(SUM(CASE WHEN pd.Type = 1 THEN Round(COALESCE(pd.Value_,0) /POWER(10 , COALESCE(0,0) ),0) ELSE 0 END),0)) sd
                        ,(Round(SUM(CASE WHEN pd.Type = 2 THEN Round(COALESCE(pd.Value_,0) /POWER(10 , COALESCE(0,0) ),0) ELSE 0 END),0)) sx ,  _cd.DATE_FROM, _cd.DATE_TO, _cd.ID, _cc.PersonnelID,
                        (select fullname from profile_main where id= _cc.ProfileID) name, _cc.OrderID, _cc.PersonnelCode,_cc.PersonnelId persid, _cc.AccountNumber, _cc.ORG_ID, _cd.PAYROLL_ID,(select name from hr_salary_groups where id=_cc.sg) sg, 
                        _cd.working_hours,(select name from org_units where id= _cc.UNIT_ID) u FROM `0000000`.`HR_PAYSLIP` _cd  JOIN CTE1095 _cc 
                        ON (_cc.OrderID = _cd.ORDER_ID)  left join 
                        HR_PAYSLIP_PAYMENT_DETAIL pd on PAYSLIP_ID =(SELECT p.id FROM HR_PAYSLIP p inner join hr_personnel_order o on p.order_id=o.id
    WHERE o.personnel_id =_cc.PersonnelId and  p.DATE_FROM >= ]]..datef..[[ AND p.DATE_TO <=  ]]..datet..[[  )  where 1=1  ]]

  if input.parameter_id ~= nil then
    qselect = qselect..[[ and   pd.PAYSLIP_VIEW= ]]..input.parameter_id
  end
    if input.personnel_id ~= nil then
    qselect = qselect..[[ and  _cc.PersonnelId= ]]..input.personnel_id
  end

    if input.unit_id ~= nil then
    qselect = qselect..[[ and  _cc.UNIT_ID= ]]..input.unit_id
  end
      if input.salary_group ~= nil then
    qselect = qselect..[[ and  _cc.sg= ]]..input.salary_group
  end
 --  if datef ~= nil and datet ~= nil then 
  	qselect = qselect..[[ and  _cd.DATE_FROM >= ]]..datef..[[ AND _cd.DATE_TO <=  ]]..datet 
 --   end 
  qselect = qselect..[[  group by _cd.DATE_FROM, _cd.DATE_TO, _cd.ID, _cc.PersonnelID,_cc.ProfileID ,_cc.OrderID, _cc.PersonnelCode, _cc.AccountNumber, _cc.ORG_ID, _cd.PAYROLL_ID,_cc.sg,_cd.working_hours, _cc.UNIT_ID ]]
  local query_select = cte_str..[[	SELECT JSON_ARRAYAGG(JSON_OBJECT("df", DATE_FROM, "dt",DATE_TO,"id",ID,"PD",PersonnelID,"n",name,"oi",OrderID,"persid",persid
  													,"pc",PersonnelCode,"ac",AccountNumber,"prid",PAYROLL_ID,"wh",working_hours,"u",u,"sx",sx,"sd",sd,"ps",ps,"sg",sg)) from ( ]]..qselect.. [[  limit ?,? )tmp]]
      teamyar.write_log(query_select)
  res_data = queryResult(query_select , {input.from, input.count})
    -------------------
  local qtotal = cte_str..[[select count(*) c from  ( ]]..qselect..[[)as t]]
  local  totall= queryResult(qtotal, {})
  data = {from = input.from, count = input.count, data = res_data, total = totall}
  teamyar.write_result(json.encode(data))
else
	WidgetTemplate()
end
