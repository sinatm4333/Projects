function getActivePeriods(input)
  if input["org_id"] ~= nil then
    local search = ''
    if input["search"] ~= nil then
        search = input["search"]
    end
    local param = {
      query=teamyar.get_attachment("active_periods_query.txt"),
      params={input["org_id"], search}
    }
    db.query(param)
    local result={}
    local record={}
    while db.query_fetch(record) do
      local obj = {}
      if teamyar.get_user_info().lang_id == 4 then --language is persian, so show time in shamsi
        obj.name = record[2] .. ' (' .. time.get_shamsi_str(record[3]) .. ' - ' .. time.get_shamsi_str(record[4]) .. ') '
      else
        obj.name = record[2] .. ' (' .. time.get_str(record[3]) .. ' - ' .. time.get_str(record[4]) .. ') '
      end
      obj.id = record[1]
      table.insert(result, obj)
    end
    db.query_free();
    return result;
  end
end
----------
function getActivePeriodForTime(input) 
  if input["org_id"] ~= nil then
    local origin_time = 0
    if input.origin_time ~= nil then
        origin_time = input.origin_time
      end
    local param = {
      query=teamyar.get_attachment("current_period_query.txt"),
      params={input["org_id"], tostring(origin_time)}
    }
    db.query(param)
    local result={}
    local record={}
    if db.query_fetch(record) then
      if teamyar.get_user_info().lang_id == 4 then --language is persian, so show time in shamsi
        result.name = record[2] .. ' (' .. time.get_shamsi_str(record[3]) .. ' - ' .. time.get_shamsi_str(record[4]) .. ') '
      else
        result.name = record[2] .. ' (' .. time.get_str(record[3]) .. ' - ' .. time.get_str(record[4]) .. ') '
      end
      result.id = record[1]
    elseif time.get_month(origin_time + (10000000 * 60 * 60 * 24)) ~= time.get_month(origin_time) then	--temporary fix find the date for last day of month
      input.origin_time = origin_time - (10000000 * 60 * 60 * 24)
      return getActivePeriodForTime(input)
    else
      result.id = 0
      result.name = ""
    end
    db.query_free();
    return result;
  end
end
----------
function getBudgetDefinedList(input)
  local result={total=0,holder_id= input.holder_id,list={}}
  if input["org_id"] ~= nil and input["period_id"] ~= nil then
    local org_id = tostring(input["org_id"])
    local param = {
      query=teamyar.get_attachment("budget_defined_query.txt"),
      params={org_id, org_id, tostring(input["period_id"]), tostring(input["from"]), tostring(input["count"])}
    }
    db.query(param)
    local record={}
    if db.query_fetch(record) then 
      result.total=record[1]
      result.min_remained_budget = record[2]
      result.max_remained_budget = record[3]
      while db.query_fetch(record) do
        local normalized_remained_value = record[9]
        if record[9] < 0 then
          normalized_remained_value = normalized_remained_value * 100 / result.min_remained_budget 
          if normalized_remained_value > 0 then
            normalized_remained_value = normalized_remained_value * -1
          end
          if normalized_remained_value > -0.5 then
            normalized_remained_value = -0.5
          end
        elseif record[9] > 0 then
          normalized_remained_value = normalized_remained_value * 100 / result.max_remained_budget
          if normalized_remained_value < 0.5 then
            normalized_remained_value = 0.5
          end
        end
        table.insert(result.list,{record[4],record[5],record[6],record[7],record[8],record[9],record[10], normalized_remained_value})
      end 
    end
    db.query_free();
  end
  return result;
end
----------
function getList(input)
  local result={total=0,holder_id= input.holder_id,list={}}
  if input["org_id"] ~= nil and input["period_id"] ~= nil then
    local org_id = tostring(input["org_id"])
    local param = {
      query=teamyar.get_attachment("query.txt"),
      params={tostring(input["accounts"]), org_id, org_id, org_id, tostring(input["period_id"]), tostring(input["from"]), tostring(input["count"])}
    }
    db.query(param)
    local record={}
    if db.query_fetch(record) then 
      result.total=record[1]
      result.min_remained_budget = record[2]
      result.max_remained_budget = record[3]
      while db.query_fetch(record) do
        local normalized_remained_value = record[9]
        if record[9] < 0 then
          normalized_remained_value = normalized_remained_value * 100 / result.min_remained_budget 
          if normalized_remained_value > 0 then
            normalized_remained_value = normalized_remained_value * -1
          end
          if normalized_remained_value > -0.5 then
            normalized_remained_value = -0.5
          end
        elseif record[9] > 0 then
          normalized_remained_value = normalized_remained_value * 100 / result.max_remained_budget
          if normalized_remained_value < 0.5 then
            normalized_remained_value = 0.5
          end
        end
        table.insert(result.list,{record[4],record[5],record[6],record[7],record[8],record[9],record[10], normalized_remained_value})
      end 
    end
    db.query_free();
  end
  return result;
end
----------
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
input=teamyar.get_input();
input.type = tonumber(input.type)
if input.type == nil then
  local random= IdGenerator:getId();
  local script =  teamyar.get_attachment("main.js");
  local before_generate =  teamyar.get_attachment("beforegenerate_func.js");
  local run_path = "2/budget_vs_expenses"
  input.origin_time = time.current()
  local accounts = ""
  if input["accounts"] ~= nil and input["accounts"] ~= "" then
    local input_accs =  json.decode(input["accounts"])
     for i = 1, #input_accs, 1 do
      if (#accounts > 0) then
        accounts = accounts .. ","
      end
      accounts = accounts .. tostring(input_accs[i]["id"])
    end
  end
  local user_info = teamyar.get_user_info();
  local str_title="Budget VS Actual Expenses"
  if user_info.lang_id == 4  then 
    str_title=" بودجه و هزینه های واقعی"
  end
  local res = teamyar.run_command("2/res_bot",{
        id = "budget_vs_expences",
        path= run_path,
        lang=1,
        tpl_name = "table",
        title = str_title,
        script=[[
        (function(){
        var holder_id = ']]..random..[[';
      	var org_id = ']] .. input.org_id .. [[';
      	var run_path = ']] .. run_path .. [[';
      	var initial_period = ]] .. json.encode(getActivePeriodForTime(input)) .. [[;
        ]]..script..[[
      })();
        ]],
        data= [[{header:['ACCOUNT_NAME','ACTUAL_COST','BUDGET','REMAINING_BUDGET','REMAINING_BUDGET_PERCENT']} ]],
      	css = styles,
        settable = 1,
        header=[[<div id="budget_vs_expences_header_]]..random..[["></div>]],
        generatetd = [[(row)=>{
      	let col_class = "number-range-plus";
      	let col_style = "--dynamic-value:";
      	if (row[7] < 0)
        {
        	col_class = "number-range-minus";
        	col_style = col_style + (row[7] * -1) + '%';
      	}
      	else
        	col_style = col_style + row[7] + '%';

        return  [
        $.Teamyar.link({title:row[1] + " - " + row[2],href: "/accounting/account_info/show/0/" +row[0]+"&expand=0&from=0&count=500",target:"_blank"}),
      	$.Teamyar.label({title:row[3]}),
      	$.Teamyar.label({title:row[4]}),
      	"<div class='" + col_class + "' style='" + col_style + "'>" + $.Teamyar.label({title:row[5]}) + "</div>",
      	$.Teamyar.label({title:row[6] + '%'}),
        ]
      }]],
      beforegenerate = before_generate,
        ajax = [[{url:'bot/run/]] .. run_path .. [[',type: 'GET',data:()=>{
        return	{report_type:"]] .. input.report_type .. [[", type:"]] .. input.report_type .. [[", org_id:"]] .. input.org_id .. [[",accounts:"]] .. accounts .. [[", holder_id:"]] .. random .. [[",
    	period_id: $.Teamyar.acl.get('#budget_vs_expences_header_period_'+]]..random..[[,'value') }
      } }]]
      })
    teamyar.write_result(res)
elseif input.type == 1 then
  teamyar.write_result(json.encode(getBudgetDefinedList(input)))
elseif input.type == 2 then
  teamyar.write_result(json.encode(getList(input)))
elseif input.type == 3 then
  teamyar.write_result(json.encode(getActivePeriods(input)))
else
  teamyar.write_result("wrong input")
end