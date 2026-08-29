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
  
     local params = {title = "account_watchlist",description="15655456456-854",header="<div id=\\'holder_header_account_watchlist_"..random.."\\'></div>"}
     local res = teamyar.run_command("2/res_bot",{
     id = "account_watchlist"..random,
     tpl_name = "table",
     title = params.title,
      path='2/account_watchlist',
      lang=1,
     header=params.header,
     description="",
     script=[[
     (function(){
         var holder_id= "#holder_header_account_watchlist_]]..random..[[",
        random = "]]..random..[[";
      ]]..script..[[
      
  })();
  
    ]],
    css=[[
    ]],
    ajax=[[{url: 'bot/run/2/account_watchlist',data: ()=>{
     return ty__main.BotOnClickApplyAccountWatchlist()
    
    }  }]],
    generatetd= [[ (row)=>{  return ty__main.generatedtdAccountWatchlist(row) } ]],
    settable=1,
    data= [[{header:[ ty__main.botGetlang('Account_Name'),  ty__main.botGetlang('Amount_Budget'),  ty__main.botGetlang('Remind_Month'),  ty__main.botGetlang('Remind_Year')],
         styles:['','','direction:ltr;','direction:ltr;']} ]]
     
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

function getData(data, from, count)
  
  local input = [[{"year":{p1},"month":{p2},"day":{p3},"hour":0,"minute":0,"second":0}]]
  input = string.gsub(input, '{p1}',time.get_year(time.current()))
  input = string.gsub(input, '{p2}',time.get_month(time.current()))
  input = string.gsub(input, '{p3}',time.get_day(time.current()))
  local date = time.get_filetime(input)
   DAccount = data.account_id

   AccountID = ""
   for i = 1, #DAccount, 1 do
     if AccountID == nil or AccountID == "" then
        AccountID = DAccount[i]["id"]
    else
        AccountID = AccountID..","..DAccount[i]["id"]
    end
   end
  
   local user_lang =teamyar.get_user_info();
   QueryInfo = teamyar.get_attachment("QUERY_AccountWatchlist.sql");
   QueryInfo = string.gsub(QueryInfo,"{param1}",data.org_id);
   QueryInfo = string.gsub(QueryInfo,"{param2}",AccountID);
   QueryInfo = string.gsub(QueryInfo,"{param3}",date)
   QueryInfo = string.gsub(QueryInfo,"{param4}",time.current())
   QueryInfo = string.gsub(QueryInfo,"{lang}",user_lang.lang_id);
     teamyar.write_log(QueryInfo)

  db.use_db("0000000");
   local params = {
         query=QueryInfo,
         params={from,count}
   };
   db.query(params)
   local result={total=0,list={}};
   local record={};
   while db.query_fetch(record) do
         result.total = record[5]
         table.insert(result.list, {Account_Name = record[1], Amount_Budget = record[2], Remind_Month = record[3], Remind_Year = record[4]})
   end
   teamyar.write_result(json.encode(result));
   db.query_free();
   teamyar.write_log(json.encode(result))

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
  getData(input.data,input.from, input.count);
  teamyar.write_log(json.encode(input))
elseif input.type == 5 then
  LoadData()
else
  WidgetTemplate();
end