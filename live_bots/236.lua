  --Bot Personnel Orders Add zmo
  local IdGenerator = {
    x1 = math.random(100,1000),
    x2 = math.random(1,1000),
    getId = function(self)
      self.x1 = self.x1 + 1;
      if self.x1 > 1000 then
        self.x1 = 100;
      end
      self.x2 = self.x2 + 1;
      if self.x2 > 1000 then
        self.x2 = 1;
      end
      return self.x1 * 1000 + self.x2;
    end
  }
  local random= IdGenerator:getId();
  input = teamyar.get_input();
  local user_info = teamyar.get_user_info();
  local user_id = math.floor(user_info["id"]); 
  local org_id = input.org_id;
  ---------------------------------------------
  function loadData()
    local data = teamyar.get_data("pao_data")
    teamyar.write_result(data. value);
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
    if res_text ~= nill then 
      return res_text[1];
    else
      return nill;
    end
  end
  --------------------------------
  function queryResult1(select_query,user_param)
    db.use_db("0000000");
    local params1 = {
      query = select_query,
      params = user_param
    }
    db.query(params1);
    local res_text = db.query_fetch();
    db.query_free();
    if res_text ~= nill then 
      return res_text;
    else
      return nill;
    end
  end
  ----------------------
  function personnelAcl(data)
    local query_param = [[ select h.personnel_id id,p.fullname name,1 type from hr_personnels h inner join profile_main p on h.profile_id=p.id where p.type=1 ]]
    if data.search ~= nil and #data.search > 0 then
      query_param = query_param..[[  and fullname like N'%]]..data.search..[[%' ]]

    end
    query_param = query_param .. string.format(" limit %d,%d ", data.from,data.count);   
    teamyar.write_result(json.encode(getQueryResponse1(query_param, {})));
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
  function inquireAcl(data)
    local query_param = [[ SELECT JSON_ARRAYAGG(JSON_OBJECT('id',id, 'name',name, 'type',1))
    from (select id,name from hr_salary_groups ]]
    if data.search ~= nil and #data.search > 0 then
      query_param = query_param..[[  where name like N'%]]..data.search..[[%') as p ]]
    else
      query_param = query_param .. [[) p ]]
    end
    query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
    teamyar.write_result(queryResult(query_param, {}));
  end
  ----------------------
  function calenderAcl(data)
    local query_param = [[ SELECT JSON_ARRAYAGG(JSON_OBJECT('id',id, 'name',name, 'type',1))
    from (select id,name from hr_calendar ]]
    if data.search ~= nil and #data.search > 0 then
      query_param = query_param..[[  where name like N'%]]..data.search..[[%') as p ]]
    else
      query_param = query_param .. [[) p ]]
    end
    query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
    teamyar.write_result(queryResult(query_param, {}));
  end
  ----------------------
  function compactRowAcl(data)
    local query_param = [[ SELECT JSON_ARRAYAGG(JSON_OBJECT('id',id, 'name',row_value, 'type',1))
    from (select id,row_value from hr_compact_row  ]]
    if data.search ~= nil and #data.search > 0 then
      query_param = query_param..[[  where row_value like N'%]]..data.search..[[%') as p ]]
    else
      query_param = query_param .. [[) p ]]
    end
    query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
    teamyar.write_result(queryResult(query_param, {}));
  end
  ----------------------
  function floatingAcl(data)
    local query_param = [[ SELECT JSON_ARRAYAGG(JSON_OBJECT('id',id, 'name',name, 'type',1))
    from (select id,name from pa_floating  ]]
    if data.search ~= nil and #data.search > 0 then
      query_param = query_param..[[  where name like N'%]]..data.search..[[%') as p ]]
    else
      query_param = query_param .. [[) p ]]
    end
    query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
    teamyar.write_result(queryResult(query_param, {}));
  end
  ----------------------
  function projectAcl(data)
    local query_param = [[ SELECT JSON_ARRAYAGG(JSON_OBJECT('id',id, 'name',name, 'type',1))
    from (select id,name from pa_project  ]]
    if data.search ~= nil and #data.search > 0 then
      query_param = query_param..[[  where name like N'%]]..data.search..[[%') as p ]]
    else
      query_param = query_param .. [[) p ]]
    end
    query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
    teamyar.write_result(queryResult(query_param, {}));
  end
  ----------------------
  function supervisorAcl(data)
    local query_param = [[ SELECT JSON_ARRAYAGG(JSON_OBJECT('id',id, 'name',fullname, 'type',1))
    from (select p.id,pm.fullname from hr_personnels p inner join profile_main pm on p.profile_id= pm.id where hiring_status=2  ]]
    if data.search ~= nil and #data.search > 0 then
      query_param = query_param..[[  and pm.fullname like N'%]]..data.search..[[%') as p ]]
    else
      query_param = query_param .. [[) p ]]
    end
    query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
    teamyar.write_result(queryResult(query_param, {}));
  end
  ----------------------
  function vacationAcl(data)
    local query_param = [[ SELECT JSON_ARRAYAGG(JSON_OBJECT('id',id, 'name',name, 'type',1))
    from (select p.id,p.name from org_position p inner join org_position_unit pu on p.id=pu.p_id where 1=1 ]]
    if data.unit_id ~= nil and data.unit_id > 0 then
      query_param = query_param..[[  and unit_id=]]..data.unit_id
    end 
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
    local query_param = [[ SELECT JSON_ARRAYAGG(JSON_OBJECT('id',id, 'name',name, 'type',1))
    from (select u.id,u.name from org_units u  ]]
    if data.search ~= nil and #data.search > 0 then
      query_param = query_param..[[  where u.name like N'%]]..data.search..[[%') as p ]]
    else
      query_param = query_param .. [[) p ]]
    end
    query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
    teamyar.write_result(queryResult(query_param, {}));
  end
  ----------------------
  function kindOrderAcl(data)
    local query_param = [[ SELECT JSON_ARRAYAGG(JSON_OBJECT('id',id, 'name',name, 'type',1))
    from (select id,name from  hr_order_type ]]
    if data.search ~= nil and #data.search > 0 then
      query_param = query_param..[[  where name like N'%]]..data.search..[[%') as p ]]
    else
      query_param = query_param .. [[) p ]]
    end
    query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
    teamyar.write_result(queryResult(query_param, {}));
  end

  ----------------------
  function WidgetTemplate()  
    local script =  teamyar.get_attachment("main.js");
    local css =  teamyar.get_attachment("main.css");
    local  str_lang = "";
    if user_info.lang_id == 4 then
      str_lang = teamyar.get_attachment("Persian.js");
    else
      str_lang = teamyar.get_attachment("English.js");
    end
    local template = teamyar.run_command("2/res_bot",{
        id = "personnel_add_orders_rep",
        tpl_name = "html",
        title = "ویرایش احکام پرسنل",
        body = "<div id=\\'pao_holder_body_html_"..random.."\\'></div>",
        script = [[
        (function(){
        ]]..str_lang..[[      
        var holder_id = '#pao_holder_body_html_]]..random..[[';
        var random_id = ]] .. random .. [[;
        var random = ]] .. random .. [[;

        ]]..script..[[
      })();
        ]],
        css = css,
      });
    teamyar.write_result(template); 
  end
  ---------------------main
  if input.type == 3 then 
    loadData()
  elseif input.type == 2 then 
    orgAcl(input.data)
  elseif input.type == 5 then 
    inquireAcl(input.data)
  elseif input.type == 6 then 
    calenderAcl(input.data)
  elseif input.type == 7 then 
    vacationAcl(input.data)
  elseif input.type == 8 then 
    unitAcl(input.data)
  elseif input.type == 9 then 
    kindOrderAcl(input.data)
  elseif input.type == 10 then 
    personnelAcl(input.data)
  elseif input.type == 12 then 
    compactRowAcl(input.data)
  elseif input.type == 13 then 
    floatingAcl(input.data)
  elseif input.type == 14 then 
    projectAcl(input.data)
  elseif input.type == 15 then 
    supervisorAcl(input.data)
    elseif input.type == 16 then 
    inquireAcl(input.data)
  elseif input.type == 11 then 
    local all_err = {};
    local per_id = 0;
    local pu_id = 0;
    local unit_id = 0;
    local position_id = 0;
    local sg_id = 0;
    local type_id = 0;
    local rorg_id = 0;
    local gg = 0;
    local calender_id = 0;
    local project_id=0;
    local supervisor_id=0;
    local floating_id=0;
 	local compact_row=0;
    local data = (input.data.data)
    for i = 1, #data, 1  do 
      local err =  {};
      local row = data[i]
      if row ~= nil then
        if row.row == nil then 
          row.row = "NOT_DEFINED"
        end
        if row.unit_name == nil then 
          table.insert(err, {msg = "ERR_IN_READ_UNIT", row = row.row})  
        end
        if row.position_name == nil then 
          table.insert(err, {msg = "ERR_IN_READ_PSITON", row = row.row})
        end
        if row.salary_group == nil then 
          table.insert(err, {msg = "ERR_IN_READ_SALARY_G", row = row.row})
        end
        if row.order_type == nil then 
          table.insert(err, {msg = "ERR_IN_READ_TYPE", row = row.row})
        end
        if row.organization == nil then 
          table.insert(err, {msg = "ERR_IN_READ_ORG", row = row.row})
        end
        if row.calendar_name == nil then 
          table.insert(err, {msg = "ERR_IN_READ_CALENDER", row = row.row})
        end
        if row.personnel_code == nil then 
          table.insert(err, {msg = "ERR_IN_READ_PERSONNEL", row = row.row})
        end
        if row.calendar_name==nil then 
          table.insert(err, {msg = "ERR_IN_READ_CALENDER", row = row.row})
        end
        if row.date_from==nil then 
          table.insert(err, {msg ="ERR_IN_READ_DATE_F",row = row.row})
        end
        if row.date_to == nil then 
          table.insert(err, {msg = "ERR_IN_READ_DATE_T", row = row.row})
        end
        if row.work_hour==nil then 
          table.insert(err, {msg = "ERR_IN_READ_W_HOUR", row = row.row})
        end

        if #err == 0 then
          unit_id = queryResult([[ select id from org_units where name  like N'%]]..row.unit_name..[[%']],{});
          position_id = queryResult([[ select p.id from org_position p inner join org_position_unit pu on p.id=pu.p_id  where p.name  like N'%]]..row.position_name..[[%']],{});
          sg_id = queryResult([[ select id from hr_salary_groups where name  like N'%]]..row.salary_group..[[%']],{});
          type_id = queryResult([[  select id from hr_order_type where name  like N'%]]..row.order_type..[[%' ]],{});
          rorg_id = queryResult([[ select id from org_info where name  like N'%]]..row.organization..[[%']],{});
          gg = [[select id from hr_calendar where name  like N'%]]..row.calendar_name..[[%' ]]
          calender_id = queryResult(gg,{});
          local str = [[select personnel_id id from hr_personnels where personnel_code=]]..row.personnel_code..[[]];
          per_id = queryResult(str,{});
          if  rorg_id ~= nil and unit_id ~= nil then
            pu_id = queryResult([[select id from org_organization_unit pu where  pu.unit_id=]]..unit_id..[[ and org_id=]]..rorg_id,{})
          end
          ------------------------------------
          if unit_id == nil or unit_id == "null" then 
            table.insert(err, {msg = "ERR_IN_READ_UNIT", row = row.row})
          end
          if position_id == nil or position_id == "null"  then 
            table.insert(err, {msg = "ERR_IN_READ_PSITON", row = row.row})
          end
          if sg_id == nil  or sg_id == "null" then 
            table.insert(err, {msg = "ERR_IN_READ_SALARY_G",row = row.row})
          end
          if type_id == nil or  type_id =="null" then 
            table.insert(err, {msg = "ERR_IN_READ_TYPE", row = row.row})
          end
          if rorg_id == nil or  rorg_id == "null" then 
            table.insert(err, {msg = "ERR_IN_READ_ORG", row = row.row})
          end
          if calender_id == nil or calender_id == "null" then 
            table.insert(err, {msg = "ERR_IN_READ_CALENDER", row = row.row})
          end
          if pu_id == nil or pu_id == 0 or pu_id == "null" then 
            table.insert(err, {msg = "ERR_IN_NOT_UNIT_IN_ORG", row = row.row})
          end

          gg = [[select id from pa_project where name  like N'%]]..row.project..[[%' ]]
          project_id=queryResult(gg,{});
          if project_id == nil or project_id == "null" then 
            table.insert(err, {msg = "ERR_IN_READ_PROJECT", row = row.row})
          end
          gg = [[select id  from hr_personnels p inner join profile_main pm on p.profile_id= pm.id where hiring_status=2 and  pm.fullname  like N'%]]..row.supervisor..[[%' ]]
          supervisor_id=queryResult(gg,{});
          if supervisor_id == nil or supervisor_id == "null" then 
            table.insert(err, {msg = "ERR_IN_READ_SUPERVISOR", row = row.row})
          end
            gg = [[select id from hr_compact_row where row_value  like N'%]]..row.compact_row..[[%' ]]
          compact_row=queryResult(gg,{});
          if compact_row == nil or compact_row == "null" then 
            table.insert(err, {msg = "ERR_IN_READ_COMPACT_ROW", row = row.row})
          end
        
          gg = [[select id from pa_floating where name  like N'%]]..row.floating..[[%' ]]
          floating_id=queryResult(gg,{});
          if floating_id == nil or floating_id == "null" then 
            table.insert(err, {msg = "ERR_IN_READ_FlOATING", row = row.row})
          end
        end
        if #err == 0 then 
          local yt = string.sub(row.date_to, 1, 4)
          local yf = string.sub(row.date_from, 1, 4)
          local mf = string.sub(row.date_from, 6, 7)
          local mt = string.sub(row.date_to, 6, 7)
          local dayf = string.sub(row.date_from, 9, 10)
          local dt = string.sub(row.date_to, 9, 10)
          local ddt = time.get_shamsi_filetime([[{"year":]]..yt..[[,"month":]]..tonumber(mt)..[[,"day":]]..tonumber(dt)..[[,"hour":0,"minute":0,"second":0}]])
          local ddf = time.get_shamsi_filetime([[{"year":]]..yf..[[,"month":]]..tonumber(mf)..[[,"day":]]..tonumber(dayf)..[[,"hour":0,"minute":0,"second":0}]])
          local datet = string.format("%18.0f" ,ddt)
          local datef = string.format("%18.0f" ,ddf )
          local order_info =
          {
            orders_list = {
              {
                date_to = datet,
                date_from = datef,
                orders = {
                  {
                    kind = row.kind,
                    type = type_id,
                    roles =roles,
                    org_id = rorg_id,
                    taxable = row.taxable,
                    unit_id = pu_id,
                    position = position_id,
                    insurable = row.insurable,
                    over_time = row.over_time,
                    absent_cal = row.absent_cal,
                    project_id = project_id,
                    sick_leave = row.sick_leave,
                    supervisor = supervisor_id,
                    take_leave = row.take_leave,
                    calendar_id = calender_id,
                    floating_id =floating_id ,
                    item_values = {
                      {
                        value = 0,
                        item_id = 0
                      }
                    },
                    compact_rows ={compact_rows},
                    personnel_id = per_id,
                    holiday_leave = row.holiday_leave,
                    working_hours =  row.work_hour,
                    breast_feeding = row.breast_feeding,
                    force_rollcall = row.force_rollcall,
                    marriage_leave = row.marriage_leave,
                    other_postions = "",
                    leave_per_month = row.leave_per_month,
                    max_delay_month = row.max_delay_month,
                    other_calendars =  {
                      0
                    },
                    salary_group_id = sg_id,
                    floating_enabled = row.floating_enabled,
                    max_hourly_leave = row.max_hourly_leave,
                    min_hourly_leave = row.min_hourly_leave,
                    overtime_confirm = row.overtime_confirm,
                    telework_request = row.telework_request,
                    overtime_disabled =row.overtime_disabled,
                    cal_daily_vacation = row.cal_daily_vacation,
                    over_floating_hour = row.over_floating_hour,
                    break_calculate_type = row.break_calculate_type,
                    hiring_end_first_day = row.hiring_end_first_day,
                    leave_transfer_total = row.leave_transfer_total,
                    pre_overtime_confirm = row.pre_overtime_confirm,
                    pre_overtime_disabled = row.pre_overtime_disabled,
                    unemployment_insurance_exemption = row.unemployment_insurance_exemption
                  }
                }
              }
            }
          }
       teamyar.write_log(json.encode(order_info))
          res = teamyar.call_api(13,  '/api/hr/ordersAdd', order_info);
              teamyar.write_log("res 1---"..json.encode(res))
          if res.error ~= nil then 
            table.insert(err, {msg = res.error, row = row.row})
          end 
          if res.success == true then 
            table.insert(err, {msg = "OK",row = row.row})
          end
        end 
        table.insert(all_err,{err=err,i=i})
      end
    end --for
    teamyar.write_result(json.encode(all_err))
  elseif input.type == 1 then 
    local chash_data = {pao_org_id = org_id, pao_gn = input.gn,
      pao_personnel_id = input.personnel_id, pao_pn = input.pn, pao_unit_id = input.unit_id, pao_un = input.un,
      pao_calender_id = input.calender_id, pao_cn = input.cn, pao_datef = input.datef ,pao_datet = input.datet,
      pao_vacation_id = input.vacation_id, pao_vn = input.vn, pao_inquire_id = input.inquire_id, pao_in = input.inqu,
      pao_kind_id = input.kind_id, pao_kn = input.kn,pao_whour = input.whour,
      pao_fim=input.fim,
      pao_af_invacation=input.af_invacation,
      pao_s=input.s,pao_s_n=input.s_n,
      pao_wcl=input.wcl,pao_wcl_n=input.wcl_n,
      pao_clmd=input.clmd,pao_clmd_n=input.clmd_n,
      pao_ctr=input.ctr,  pao_ctr_n=input.ctr_n,
      pao_f=input.f,pao_f_n=input.f_n,
      pao_p=input.p, pao_p_n=input.p_n,
      pao_r=input.r,pao_r_n=input.r_n,
      pao_cr=input.cr,pao_cr_n=input.cr_n,
      pao_few=input.few,
      pao_af_illness=input.af_illness,
      pao_af_ilegal=input.af_ilegal,
      pao_taf_illness=input.taf_illness,
      pao_taf_ilegal=input.taf_ilegal,
      pao_maxhl=input.maxhl,
      pao_minhl=input.minhl,
      pao_madm=input.madm,
      pao_bft=input.bft,
      pao_ch_oa=input.ch_oa,
      pao_ch_ii=input.ch_ii,
      pao_ch_co=input.ch_co,
      pao_ch_it=input.ch_it,
      pao_ch_ofwa=input.ch_ofwa,
      pao_ch_af=input.ch_af,
      pao_ch_cofw=input.ch_cofw,
      pao_ch_ofwa=input.ch_ofwa,
      pao_ch_rt=input.ch_rt,
      pao_ch_efi=input.ch_efi,
    }
    teamyar.set_data("pao_data", json.encode(chash_data));
    local pu_id = queryResult([[select id from org_organization_unit pu where  pu.unit_id=]]..input.unit_id..[[ and org_id=]]..org_id, {})
    if pu_id == nil then
      pu_id = 0;
    end
  if input.ch_af == true then 
    input.ch_af = 1;
  end 
    if input.ch_ofwa == true then 
    input.ch_ofwa = 1;
  end 
    if input.ch_cofw == true then 
    input.ch_cofw = 1;
  end 
    if input.ch_oa == true then 
    input.ch_oa = 0;
  else
     input.ch_oa = 1;
  end 
    if input.ch_ii == true then 
    input.ch_ii = 1;
  end 
    if input.ch_it == true then 
    input.ch_it = 1;
  end 
    if input.ch_rt == true then 
    input.ch_rt = 1;
  end 
    if input.ch_co == true then 
    input.ch_co = 1;
  end 
      if input.ch_efi == true then 
    input.ch_efi = 1;
  end 
         teamyar.write_log("bbbbbb----"..json.encode( input.whour))
    local order_info=
    {
      orders_list= {
        {
          date_to = input.datet,
          date_from = input.datef,
          orders = {
            {
              kind = 0,
              type = input.kind_id,
              roles = input.r,
              org_id = input.org_id,
              taxable = input.ch_it,
              unit_id = pu_id,
              position = input.vacation_id,
              insurable = input.ch_ii,
              over_time = input.ch_oa,
              absent_cal = input.clmd,
              project_id = input.p,
              sick_leave = tonumber(input.af_illness),
              supervisor = input.s,
              take_leave=0,
              calendar_id = input.calender_id,
              floating_id = input.f,
              item_values = {
                {
                  value = 0,
                  item_id = 0
                }
              },
              compact_rows ={ input.cr},
              personnel_id = input.personnel_id,
              holiday_leave =tonumber(input.af_invacation),
              working_hours =json.encode( input.whour),
              breast_feeding = input.bft,
              force_rollcall =0,
              marriage_leave =0,
              other_postions = "",
              leave_per_month = input.fim,
              max_delay_month = input.madm,
              other_calendars = {
                0
              },
              salary_group_id = input.inquire_id,
              floating_enabled = input.ch_af,
              max_hourly_leave = input.maxhl,
              min_hourly_leave = input.minhl,
              overtime_confirm = input.ch_co,
              telework_request = input.ch_rt,
              overtime_disabled = input.ch_oa,
              cal_daily_vacation = input.ctr+1,
              over_floating_hour = input.few,
              break_calculate_type = input.wcl+1,
              hiring_end_first_day = input.ofwa,
              leave_transfer_total = 0,
              pre_overtime_confirm = input.ch_cofw,
              pre_overtime_disabled = input.ch_ofwa,
              unemployment_insurance_exemption = input.ch_efi,
            }
          }
        }
      }
    }
         teamyar.write_log(json.encode(order_info))
    res = teamyar.call_api(13,  '/api/hr/ordersAdd', order_info);
      teamyar.write_log("res 2------"..json.encode(res))
    data = { data = res_data, acc_l = ids_loss, acc_p = ids_profit, msg=res.error, result=res.success}
    teamyar.write_result(json.encode(data))
  else
    WidgetTemplate()
  end
