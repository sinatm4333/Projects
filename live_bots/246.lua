local input=teamyar.get_input();
local user_info = teamyar.get_user_info();
local res = teamyar.get_user_info()
local box_clause='';
local box_clause2='';
local user_id = user_info.id;
local query =teamyar.get_attachment("query.txt");
local lang_id=math.floor(user_info["lang_id"]);
local state = 1;
local direction = "right";
if(lang_id == 4) then 
    direction = 'right';
elseif(lang_id == 1) then
    direction = 'left';
end

function getQueryResponse(data, state, from, count) 
    local result={total=0,list={}};
    local record={}; 
    

    if(data.start_date_from ~=nil and data.start_date_to ~=nil) then
        if ( string.len(data.start_date_from) >= 1 and string.len(data.start_date_to) >= 1) then
            local start_date_from = data.start_date_from - user_info.timezone;
            local start_date_to = data.start_date_to - user_info.timezone + 864000000000 - 1;
            box_clause = box_clause.. [[ AND (T_START_DATE BETWEEN ]]..start_date_from..[[ AND ]]..start_date_to..[[ ) ]];
        end
    end
    if(data.end_date_from ~=nil and data.end_date_to ~=nil) then
        if ( string.len(data.end_date_from) >= 1 and string.len(data.end_date_to) >= 1) then

            local end_date_from = data.end_date_from - user_info.timezone;
            local end_date_to = data.end_date_to - user_info.timezone + 864000000000 - 1;
            box_clause = box_clause.. [[ AND (  T_REAL_END_DATE BETWEEN ]]..end_date_from..[[ AND ]]..end_date_to..[[ ) ]];
        end
    end
    local responsible_id = user_id;
    if(data.responsible_id ~=nil) then
        responsible_id = data.responsible_id;
        -- box_clause = [[ ( ]]
        user = {};
        for i, v in ipairs(responsible_id) do
            if tonumber(v.id) >0 then
                table.insert(user,v.id) 
            end
        end
        local responsibles = table.concat(user,",");
        local responsibles_id = responsibles;
        if(string.len(responsibles_id) > 1) then
            box_clause2 = [[AND tts.RESPONSIBLE_ID in(]]..responsibles_id..[[)  AND tts.FLAG_LAST_STEP = 1 ]];
        end
    end
    state = tonumber(data.state);
    query =string.gsub(query, "{box_clause}",box_clause);
    query =string.gsub(query, "{box_clause2}",box_clause2);
    local param = {
        query=query,
        params={user_id,state,user_id,from,count} 
    } 
    db.query(param) 
    
    teamyar.write_log(query)
    while db.query_fetch(record) do 
        local title_name = record[2];
        title = string.gsub(title_name, '"', '')
        table.insert(result.list,{id=record[1],title=record[2],owner=record[3],end_date=record[4],state=record[5],progress=record[6],step_end_date=record[7], steps = record[8], complete_steps = record[9], rejected_steps = record[10]}) 
  		result.total = record[11];  
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
    id = "tasks_todo",
    tpl_name = "table",
    title = "TODO_TASKS",
    path="2/tasks_todo",
    lang=1,
    body = "<div id=\\'holder_body_html_"..random.."\\'></div>",
    data= [[{header:['STATE','TITLE','END_DATE','PROGRESS', 'STEP_END_DATE',  'STEPS', 'COMPLETE_STEPS', 'REJECTED_STEPS']} ]],
    generatetd = [[
        (row)=>{  return ty__main.generatedtdTodoTasks(row) }
    ]],
    ajax = [[{url:'bot/run/2/tasks_todo',
        data:()=>{
            return  ty__main.botOnClickApplyTodo();
        }
    }]],

    script=[[
      (function(){
        var holder_id = ']]..random..[[';
        var direction = ']]..direction..[[';
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
    local queresult =  getQueryResponse(dataa, json.encode(input.state), input.from, input.count);
    teamyar.write_result(json.encode(queresult));
elseif input.type == 5 then
    LoadData();
end