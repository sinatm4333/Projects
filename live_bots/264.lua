local input=teamyar.get_input();
local query =teamyar.get_attachment("query.txt");
local user_info = teamyar.get_user_info();
local all_inbound = {};
local all_outbound = {};
local mType=2;
local res = {};
function getCallsInfo(data)
    teamyar.set_data("data", json.encode(data));
    local res = teamyar.get_user_info()
    local box_clause='';
    if ( string.len(data.date) >= 1 ) then
        date_from = data.date - user_info.timezone;
        date_to = data.date - user_info.timezone + 864000000000;
    end
    query =string.gsub(query, "{box_clause}",box_clause)
  
    local param = {
        query=query,
        params={date_from, date_to} 
    } 
  
    db.query(param) 
    local result={} ; 
    local record={}; 
    while db.query_fetch(record) do 
        table.insert(result,{start_date=record[1],end_date=record[2],sum_outbound=record[3],sum_inbound=record[4]}) 
    end

    db.query_free();
    return result;
end

local script =  teamyar.get_attachment("main.js");

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

function loadData()
    local data = teamyar.get_data("data");  
    if data.modify_time == 0 then
        data.value = '""';
    end
  teamyar.write_result(data.value);
end

local template = teamyar.run_command("2/res_bot",{
    id = "voip_call_trends",
    tpl_name = "chart",
    lang=1,
    title = "CALL_TRENDS",
    path="2/voip_call_trends",
    ajax=[[{ 
        selector_btn:'#holder_layout_chart_]]..random..[[',
        url:'/bot/run/2/voip_call_trends',
        data:()=>{ 
            var holder_id = ']]..random..[[';
            var date=parseInt($.Teamyar.DateTimePicker.get('#voip_date_'+holder_id,'value'));
            var type = ]]..mType..[[;
            if(type == 2) {
                res =  ]] .. json.encode(res) .. [[;
            }
            return {
                type:4,
                res :  ]] .. json.encode(res) .. [[,
                date:$.Teamyar.DateTimePicker.get('#voip_date_]]..random..[[','value'),
            }
        } 
    }]],
      generatedata=[[(data)=>{
  
    return    ty__main.createDataForChartCallTrends(data);
  
  }]],
    script=[[
    (function(){
        var holder_id = ']]..random..[[';
          ]]..script..[[;
        })();
    ]],
   
        header="<div id=\\'holder_header_chart_"..random.."\\'></div>",

});

if input.type == nil then
    teamyar.write_result(template);
elseif input.type == 1 then
    teamyar.set_data("data", input.data);
elseif input.type == 4 then
    local dataa = {};
    mType = 1;
    if(input.data) then
        dataa = input.data
    else 
        dataa = input;
    end
    res = getCallsInfo(dataa);
    teamyar.write_result(json.encode(res));
elseif input.type == 5 then
    loadData();
end