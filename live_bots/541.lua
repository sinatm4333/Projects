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

local user_info = teamyar.get_user_info() 
local user_id = user_info.id

function WidgetTemplate()
  local script = teamyar.get_attachment("main.js");
  local str_title="Expense Claims"
    local user_info = teamyar.get_user_info();
    if user_info.lang_id == 4 then
    str_title="درخواست های هزینه"
  end
  local random= math.random(1,1000);
     local params = {title = str_title,description="15655456456-854",body="<div id=\\'holder_header_Expense_claims_"..random.."\\'></div>"}
     local res = teamyar.run_command("2/res_bot",{
     id = "Expense_claims_"..random,
     tpl_name = "html",
     title = params.title,
      path='2/Expense_claims',
      lang=1,
     body=params.body,
     script=[[
     (function(){
         var holder_id= "#holder_header_Expense_claims_]]..random..[[",
        random = "]]..random..[[";
      ]]..script..[[
      
  })();
  
    ]]
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


function getData(data) 
    QueryInfo = teamyar.get_attachment("Query_ExpenseClaims.sql");

    QueryInfo = string.gsub(QueryInfo,"{param1}",user_id) 
    QueryInfo = string.gsub(QueryInfo,"{param2}",data.org_id)
    QueryInfo = string.gsub(QueryInfo,"{param3}",data.date_from)
    QueryInfo = string.gsub(QueryInfo,"{param4}",data.date_to)
    teamyar.write_log(QueryInfo);
  
    db.use_db("0000000");
    local params = {
              query=QueryInfo,
              params={}
    };
    db.query(params)
    local record={};
    local result = {};
    counter = 1;
    while db.query_fetch(record) do
        local rec = {}
        rec[1] = record[2];
        rec[2] = record[3];
        rec[3] = record[4];
        rec[4] = record[5];
        rec[5] = record[6];
        result[counter] =  rec
        counter = counter +1;
    end
    teamyar.write_result(json.encode(result))
    db.query_free(); 
end

-- main --
input = teamyar.get_input();

if input.type == 1 then
  teamyar.set_data("data", input.data);
elseif input.type == 2 then
  OrganizationAcl(input.data);
elseif input.type == 4 then
  getData(input.data);
elseif input.type == 5 then
  LoadData()
else
  WidgetTemplate();
end