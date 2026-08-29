local input=teamyar.get_input();
local user_info = teamyar.get_user_info();
local user_id = user_info.id;
local query =teamyar.get_attachment("query.txt");
local lang_id=math.floor(user_info["lang_id"]);
local state = 1;
local box_clause = "";
local direction = "right";
local cur_time=time.current() ;
local date_from = time.get_filetime([=[{"year":]=]..math.floor(tonumber(time.get_year(cur_time)))..[=[,"month":]=]..math.floor(tonumber(time.get_month(cur_time)))..[=[,"day":]=]..math.floor(tonumber(time.get_day(cur_time)))..[=[,"hour":0,"minute":0,"second":0}]=]) - user_info.timezone;
local date_to = date_from + time.day;

function getQueryResponse(data, from, count) 
    local result={total=0,list={}};
    local record={}; 
    local responsible_id = user_id;
    local responsibles_id = user_id;
    if(data.responsible_id ~=nil) then
        responsible_id = data.responsible_id;
        user = {};
        for i, v in ipairs(responsible_id) do
            if tonumber(v.id) >0 then
                table.insert(user,v.id) 
            end
        end
        local responsibles = table.concat(user,",");
        responsibles_id = responsibles;
    end
    if(data.date ~=nil ) then
        if ( string.len(data.date) >= 1 ) then
            date_from = data.date - user_info.timezone;
            date_to = data.date - user_info.timezone + time.day;
        end
    end

    local param = {
        query=query,
        params= {responsibles_id,date_from,date_to,responsibles_id,responsibles_id,from,count} 
    } 
    db.query(param) 
    
    teamyar.write_log(query)
    while db.query_fetch(record) do 
        local title_name = record[2];
        title = string.gsub(title_name, '"', '')
        table.insert(result.list,{id=record[1],title=record[2],wf_end_date=record[3],step_end_date=record[4]}) 
        result.total = record[6];
    end 
    db.query_free();

    return result;
end

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

function LoadData()
    local data = teamyar.get_data("data");  
    if data.modify_time == 0 then
        data.value = '""';
    end
  teamyar.write_result(data.value);
end

local random= IdGenerator:getId();
local script =  teamyar.get_attachment("main.js");
local css =  teamyar.get_attachment("main.css");
local template = teamyar.run_command("2/res_bot",{
    id = "tasks_today",
    tpl_name = "table",
    title = "TODAY_TASKS",
    path="2/tasks_today",
    lang=1,
    body = "<div id=\\'holder_body_html_"..random.."\\'></div>",
    data= [[{header:['TITLE', 'DEADLINE_STEP']} ]],
    generatetd = [[
        (row)=>{  return ty__main.generatedtd(row) }
    ]],
    ajax = [[{url:'bot/run/2/tasks_today',
        data:()=>{
            return  ty__main.botOnClickApplyTodayTask();
        }
    }]],

    script=[[
      (function(){
        var holder_id = ']]..random..[[';
        var date = ]]..date_from..[[;
        ]]..script..[[;
        })();
    ]],
    
    header="<div id=\\'holder_header_task_"..random.."\\'></div>",
    css=css
});

if input.type == nil then
    teamyar.write_result(template);
elseif input.type == 1 then
  teamyar.set_data("data", input.data);
elseif input.type == 4 then

    local dataa = {} 
    if(input.data) then 
        dataa = input.data 
    else  
        dataa = input; 
    end 
    local queresult =  getQueryResponse(dataa, input.from, input.count);
    
    teamyar.write_result(json.encode(queresult));
elseif input.type == 5 then
    LoadData();
end