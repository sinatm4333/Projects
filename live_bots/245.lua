local random = math.random(1,1000);
local script =  teamyar.get_attachment("main.js");
local css =  teamyar.get_attachment("main.css");
local query_en_month =teamyar.get_attachment("query_en_month.txt");
local query_en_week =teamyar.get_attachment("query_en_week.txt");

local query_fa_month =teamyar.get_attachment("query_fa_month.txt");
local query_fa_week =teamyar.get_attachment("query_fa_week.txt");

local query_days =teamyar.get_attachment("query_day.txt");
local query_total =teamyar.get_attachment("query_total.txt");
local input = teamyar.get_input();
local user_info = teamyar.get_user_info();
local user_id = user_info.id;
local lang_id=math.floor(user_info["lang_id"]);
local direction = "right";
if(lang_id == 4) then 
    query_month = query_fa_month;
    query_week = query_fa_week;
    direction = 'right';
elseif(lang_id == 1) then
    query_month = query_en_month;
    query_week = query_en_week;
    direction = 'left';
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

function getQueryResponse(data)
    local result = {list = {},total={},total_year={}, type=1};
    local record = {};
    local params = {};
    local date_type = 'JTDAY';
  	local cur_time=time.current() ;
    local date_from = time.get_filetime([=[{"year":]=]..math.floor(tonumber(time.get_year(cur_time)))..[=[,"month":]=]..math.floor(tonumber(time.get_month(cur_time)))..[=[,"day":]=]..math.floor(tonumber(time.get_day(cur_time)))..[=[,"hour":0,"minute":0,"second":0}]=]) - user_info.timezone;
    local date_to = date_from + time.day;

    if(data.data_type == "1") then
        
        --date_to= time.get_filetime([=[{"year":]=]..math.floor(tonumber(time.get_year(cur_time)))..[=[,"month":]=]..math.floor(tonumber(time.get_month(cur_time)))..[=[,"day":]=]..math.floor(tonumber(time.get_day(cur_time)))..[=[,"hour":23,"minute":59,"second":59}]=]) - user_info.timezone;
        params = {
            query = query_days,
            params = {date_from,date_to,user_id,user_id}
        }
        db.query(params);
        while db.query_fetch(record) do 
            table.insert(result.list, {date_from = record[1], date_to = record[2], total = record[3]})
        end
    else 
        if(data.data_type == "2") then -- 1 week
            date_type = 'JTDAY';
        --    local week = time.get_day_of_week(date_from);
      --teamyar.write_log(json.encode(week))
      		date_to = date_from ;
      		date_from = date_from - (time.day *7)
            --if(lang_id == 4) then 
                -- date_from = time.current() - user_info.timezone - (time.day*week) - time.day;
                --date_to = time.current() - user_info.timezone + (time.day*(5-week));
            --else 
                --date_from = time.current() - user_info.timezone - (time.day*(week-1));
                --date_to = time.current() - user_info.timezone + (864000000000*(8-week));
            --end
            result.type = 2;
            query = query_week;
        elseif(data.data_type == "3") then -- 6month
            date_type = 'JTMONTH';
            result.type = 3;
            local cur_time=time.current()+user_info.timezone;

            local get_shamsi = time.to_jalali([=[{"year":]=]..time.get_year(cur_time)..[=[,"month":]=]..time.get_month(cur_time)..[=[,"day":]=]..time.get_day(cur_time)..[=[}]=]);
            local get_shamsi_year = json.decode(get_shamsi)
            local grigorian_json_from = time.to_grigorian([[{"year":]]..math.floor(tonumber(get_shamsi_year.year))..[[,"month":1,"day":1}]]);
            local grigorian_json_to = time.to_grigorian([[{"year":]]..math.floor(tonumber(get_shamsi_year.year))..[[,"month":12,"day":29}]]);

            local grigorian_from = json.decode(grigorian_json_from);
            local grigorian_to = json.decode(grigorian_json_to);

            date_from = time.get_filetime([=[{"year":]=]..math.floor(tonumber(grigorian_from.year))..[=[,"month":]=]..math.floor(tonumber(grigorian_from.month))..[=[,"day":]=]..math.floor(tonumber(grigorian_from.day))..[=[,"hour":0,"minute":0,"second":0}]=]);
            
            date_to = time.get_filetime([=[{"year":]=]..math.floor(tonumber(grigorian_to.year))..[=[,"month":]=]..math.floor(tonumber(grigorian_to.month))..[=[,"day":]=]..math.floor(tonumber(grigorian_to.day))..[=[,"hour":0,"minute":0,"second":0}]=]);

            local last_year_from = tonumber(grigorian_from.year) - 1;
            local last_year_to = tonumber(grigorian_to.year) - 1;
            local last_date_from = time.get_filetime([=[{"year":]=]..math.floor(last_year_from)..[=[,"month":]=]..math.floor(tonumber(grigorian_from.month))..[=[,"day":]=]..math.floor(tonumber(grigorian_from.day))..[=[,"hour":0,"minute":0,"second":0}]=]);
            local last_date_to = time.get_filetime([=[{"year":]=]..math.floor(last_year_to)..[=[,"month":]=]..math.floor(tonumber(grigorian_to.month))..[=[,"day":]=]..math.floor(tonumber(grigorian_to.day))..[=[,"hour":0,"minute":0,"second":0}]=]);
            progress_params = {
                query = query_total,
                params = {user_id, user_id, last_date_from, last_date_to}
            }
            db.query(progress_params);
            while db.query_fetch(record) do 
                table.insert(result.total_year, {total = record[1], done = record[2], closed = record[3]})
            end
            query = query_month;
        end
   		 teamyar.write_log(query)
     teamyar.write_log(user_id)
     teamyar.write_log( string.format("%18.0f" ,date_from))
     teamyar.write_log(string.format("%18.0f" ,date_to))
        params = {
            query = query,
            params = {user_id,user_id,date_from,date_to}
        }
        db.query(params);
        while db.query_fetch(record) do 
            table.insert(result.list, {date = record[1], total = record[2]})
        end
    end
    total_params = {
        query = query_total,
        params = {user_id,user_id,date_from,date_to}
    }
    db.query(total_params);
    while db.query_fetch(record) do 
        table.insert(result.total, {total = record[1], done = record[2], closed = record[3]})
    end

    db.query_free();
   
    teamyar.write_log("weeks-----"..json.encode(result))
    
    return result;
end

local template = teamyar.run_command("2/res_bot",{
    id = "tasks_tasks_done",
    tpl_name = "chart",
    lang=1,
    path="2/tasks_tasks_done",
    title = "TASKS_DONE",
    ajax=[[{
        selector_btn:'#holder_layout_chart_]]..random..[[',
        url:'/bot/run/2/tasks_tasks_done',data:()=>{ 
            var holder_id = ']]..random..[[';
            var data_type=parseInt($.Teamyar.input.combobox.get('#task_data_type_combo_'+holder_id,'value'));
            return {
                type:4,
                data_type:$.Teamyar.input.combobox.get('#task_data_type_combo_]]..random..[[','value'),
            }
        }
    }]],
    generatedata=[[(data)=>{
    
      return    ty__main.createdataForChartTasksDone(data);
    
    }]],
    script=[[
        (function(){
            var holder_id = ']]..random..[[';
            var direction = ']]..direction..[[';
            ]]..script..[[
            
        })();
    ]],
    header="<div id=\\'holder_header_chart_"..random.."\\'></div>",
    css=css,
    src=[[<script src="/res/gui/res/js/chart/funnel.js" type="text/javascript"></script>
    ]]
  });

function LoadData()
    local data = teamyar.get_data("data");      
    if data.modify_time == 0 then
        data.value = '""';
    end
    teamyar.write_result(data.value);
end
  
if input.type == nil then
    teamyar.write_result(template);
  
elseif input.type == 1 then
    teamyar.set_data("data",input.data);
elseif input.type == 4 then
    local dataa = {}
    if(input.data) then
        dataa = input.data
    else 
        dataa = input;
    end
    teamyar.write_log(json.encode(input));
    
    local query_result =  getQueryResponse(dataa);
    teamyar.write_result(json.encode({data={query_result}}));
elseif input.type == 5 then
  LoadData();
end
