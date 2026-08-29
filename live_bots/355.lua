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

function WidgetTemplate()
  local script = teamyar.get_attachment("main.js");
  
     local params = {title = "Revenue vs Expenses",description="15655456456-854",header="<div id=\\'holder_header_Revenue_vs_Expenses_"..random.."\\'></div>"}

     local res = teamyar.run_command("2/res_bot",{
     id = "Revenue_vs_Expenses_"..random,
     tpl_name = "chart",
     title = params.title,
      path='2/Revenue_vs_Expenses',
      lang=1,
     header=params.header,
     description="",
     script=[[
     (function(){
   
         var holder_id= "#holder_header_Revenue_vs_Expenses_]]..random..[[",
        random = "]]..random..[[";
      ]]..script..[[
      
  })();
  
    ]],
    ajax=[[{url: 'bot/run/2/Revenue_vs_Expenses',data: ()=>{
     return ty__main.BotOnClickApplyRevenueExpenses()
    }  }]]
    , generatedata= [[ (data)=>{  return ty__main.bbachangechartRevenueExpenses(data)  } ]]
     
   });
   teamyar.write_result(res);   
  
end

function LoadData()
  local data = teamyar.get_data("data");  
  if data.modify_time == 0 then
  	data.value = '""';
  end
  
  teamyar.write_result(data.value);
end

function OrganizationAcl(data)
    local query_param = "with cte_data as(select ID, NAME from ORG_INFO"
    if data.search ~= nil and #data.search > 0 then
       query_param = query_param .. " where instr(NAME,'" .. data.search .. "')>0"
    end
    query_param = query_param .. string.format(' limit %d,%d',data.from,data.count) .. ')' .. 
    "select JSON_ARRAYAGG(JSON_OBJECT('id',cte_data.ID, 'name',cte_data.NAME, 'type',1)) as result from cte_data"
  
    local params = {
              query=query_param,
              params={}
              };
    db.query(params)
    local record={};
    while db.query_fetch(record) do
         teamyar.write_result(record[1])
    end
    db.query_free();
end

function FiscalYearAclList(data)
      local query_param ="with cte_data as(select fy.ID AS ID, fy.TITLE AS NAME  from pa_fiscal_year fy where fy.ORG_ID=" .. data.org_id;
      if data.search ~= nil and #data.search > 0 then
         query_param = query_param .. " and (instr(fy.TITLE,'" .. data.search .. "')>0) "
      end
      query_param = query_param .. string.format(' limit %d,%d',data.from,data.count) .. ') ' .. 
      "select JSON_ARRAYAGG(JSON_OBJECT('id',cte_data.ID, 'name',cte_data.NAME, 'type',1)) as result from cte_data"

      local params = {
                query=query_param,
                params={}
             };
      db.query(params)
      local record={};
      while db.query_fetch(record) do
           teamyar.write_result(record[1])
      end
      db.query_free();
end

function AccountAclList(data)
      local query_param ="with cte_data as(select pa.ID AS ID, concat(pa.NAME,'-',pa.code) AS NAME  from pa_account pa where pa.ORG_ID=" .. data.org_id;
      if data.search ~= nil and #data.search > 0 then
         query_param = query_param .. " and (instr(pa.NAME,'" .. data.search .. "')>0 or instr(pa.CODE,'" .. data.search .. "')>0)"
      end
      query_param = query_param .. string.format(' limit %d,%d',data.from,data.count) .. ')' .. 
      "select JSON_ARRAYAGG(JSON_OBJECT('id',cte_data.ID, 'name',cte_data.NAME, 'type',1)) as result from cte_data"

      local params = {
                query=query_param,
                params={}
             };
      db.query(params)
      local record={};
      while db.query_fetch(record) do
           teamyar.write_result(record[1])
      end
      db.query_free();
end

function getData(data) 
   local income_accounts = data.income_accounts
   local income_accounts_ids = ""
   for i = 1, #income_accounts, 1 do
     if income_accounts_ids == nil or income_accounts_ids == "" then
        income_accounts_ids = income_accounts[i]["id"]
    else
        income_accounts_ids = income_accounts_ids..","..income_accounts[i]["id"]
    end
   end
  
   local expense_accounts = data.expense_accounts
   local expense_accounts_ids = ""
   for i = 1, #expense_accounts, 1 do
     if expense_accounts_ids == nil or expense_accounts_ids == "" then
        expense_accounts_ids = expense_accounts[i]["id"]
    else
        expense_accounts_ids = expense_accounts_ids..","..expense_accounts[i]["id"]
    end
   end
    
    local user_lang =teamyar.get_user_info()
  
    QueryInfo = teamyar.get_attachment("Query_RevenuevsExpense.sql");
    QueryInfo = string.gsub(QueryInfo,"{param1}",data.org_id)
    QueryInfo = string.gsub(QueryInfo,"{param2}",data.fiscal_year)
    QueryInfo = string.gsub(QueryInfo,"{param3}",income_accounts_ids)
    QueryInfo = string.gsub(QueryInfo,"{param4}",expense_accounts_ids)
    QueryInfo = string.gsub(QueryInfo,"{lang}",user_lang.lang_id)
  
    db.use_db("0000000");
    local params = {
              query=QueryInfo,
              params={}
    };
    db.query(params)
    local record={};
    local result = {{},{},{},{}};
    i = 1;
    while db.query_fetch(record) do
        result[1][i] = record[1];
        result[2][i] = math.floor(record[2]);
        result[3][i] = math.floor(record[3]);
        result[4][i] = math.floor(record[4]);
        i = i +1;
    end
    db.query_free(); 
    teamyar.write_result(json.encode(result))
end

-- main --
input = teamyar.get_input();

if input.type == 1 then
  teamyar.set_data("data", input.data);
elseif input.type == 2 then
  OrganizationAcl(input.data);
elseif input.type == 3 then
  AccountAclList(input.data);
elseif input.type == 4 then
  getData(input.data);
elseif input.type == 5 then
 LoadData()
elseif input.type == 6 then
  FiscalYearAclList(input.data)
else
  WidgetTemplate();
end