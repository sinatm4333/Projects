local input=teamyar.get_input();
local user_info = teamyar.get_user_info();
local res = teamyar.get_user_info()
local user_id = user_info.id;
local query =teamyar.get_attachment("query.txt");
local lang_id=math.floor(user_info["lang_id"]);
local box_clause = "";
local box_clause2 = "";
local direction = "right";
local cur_time=time.current() ;
local date_from = time.get_filetime([=[{"year":]=]..math.floor(tonumber(time.get_year(cur_time)))..[=[,"month":]=]..math.floor(tonumber(time.get_month(cur_time)))..[=[,"day":]=]..math.floor(tonumber(time.get_day(cur_time)))..[=[,"hour":0,"minute":0,"second":0}]=]) - user_info.timezone;
local date_to = date_from + time.day;   
local order = [[ t.id ]];
function getQueryResponse(data, state, from, count) 
    local result={total=0,list={}};
    local record={}; 
    local param = {};
    local params = {user_id, user_id, from, count};
    local state = "";
    if(data.data_type == "1") then

    	date_to = date_from+ time.day;
    	date_from = date_from - (7* time.day);
             teamyar.write_log( string.format("%18.0f" ,date_to))
     teamyar.write_log( "f"..string.format("%18.0f" ,date_from))
        box_clause = [[ AND (tts.RESPONSIBLE_ID = ]]..user_id..[[ OR t.AUTHOR_ID = ]]..user_id..
    	[[) AND  (t.LAST_MODIFY_DATE BETWEEN ]]..date_from..[[ AND ]]..date_to..[[  ) ]];
        order = [[ t.LAST_MODIFY_DATE ]];
    end
    if(data.data_type == "2") then
        box_clause = [[ AND (tts.RESPONSIBLE_ID = ]]..user_id..[[ OR t.AUTHOR_ID = ]]..user_id..
        [[) AND (tts.DATE_CREATE BETWEEN ]]..date_from..[[ AND ]]..date_to..[[ ) ]];
    end
    if(data.data_type == "3") then
        box_clause = [[ AND tts.RESPONSIBLE_ID = ]]..user_id..[[ AND t.STATE=2 ]];
    end
     teamyar.write_log( box_clause)
    query =string.gsub(query, "{box_clause}",box_clause);
    query =string.gsub(query, "{order}",order);

    param = {
        query=query,
        params=params 
    } 
    db.query(param) 
    
    while db.query_fetch(record) do 
        local title_name = record[2];
        title = string.gsub(title_name, '"', '')
        table.insert(result.list,{id=record[1],title=record[2],progress=record[3],responsibles=record[4]}) 
        result.total=record[5];
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

local random= IdGenerator:getId();
local script =  teamyar.get_attachment("main.js");
local css =  teamyar.get_attachment("main.css");
local template = teamyar.run_command("2/res_bot",{
    id = "tasks_my_tasks",
    tpl_name = "table",
    title = "MY_TASKS",
    path="2/tasks_my_tasks",
    lang=1,
    body = "<div id=\\'holder_body_html_"..random.."\\'></div>",
    data= [[{header:['TITLE','PROGRESS', 'RESPONSIBLES']} ]],
    generatetd = [[
        (row)=>{  return ty__main.generatedTdMyTask(row) }
    ]],
    ajax = [[{url:'bot/run/2/tasks_my_tasks',
        data:()=>{
            var holder_id = ']]..random..[[';
            var type=4;
            var date_type=$.Teamyar.input.combobox.get('#task_date_combo_'+holder_id,'value');
            return {
                type:4,
                data_type: date_type
            }
        }
    }]],

    script=[[
      (function(){
        var holder_id = ']]..random..[[';
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
    local dataa = {}; 
    if(input.data) then 
        dataa = input.data 
    else  
        dataa =input; 
    end
    if(input.from == nil) then
        input.from = 0;
        input.count = 10;

    end 
    local queresult =  getQueryResponse(dataa, json.encode(input.state), input.from, input.count);
    teamyar.write_result(json.encode(queresult));
end