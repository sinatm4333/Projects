local query_fa =teamyar.get_attachment("query_fa.txt");
local query_en =teamyar.get_attachment("query_en.txt");
local user_info = teamyar.get_user_info();
local input=teamyar.get_input();
local script =  teamyar.get_attachment("main.js");
local input_type = "inbound";
local m_type=2;
local query = "";
local lang_id=math.floor(user_info["lang_id"]);

if(lang_id == 4) then 
    query = query_fa;
elseif(lang_id == 1) then
    query = query_en;
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

function getQueryResponse(query,input_type)
    local day={} ; 
    local answer={}; 
    local cancel={}; 
    local record={};
    local box_clause = ''; 
    local result_data={} ; 
    local date_from = time.current();
    local date_to = date_from - 6048000000000;
    teamyar.write_log(input_type)

    if string.match(input_type, "2")then
        box_clause = [[CallerNum > 100000]];
    elseif string.match(input_type, "3") then
        box_clause = [[(CallerNum < 100000 AND ConnectedLineNum > 10000)]];
    else 
        box_clause = [[(CallerNum > 100000 OR ConnectedLineNum > 10000)]];
    end
    
    query =string.gsub(query, "{box_clause}",box_clause);
    teamyar.write_log(date_from)
    teamyar.write_log(date_to)
    teamyar.write_log(query)
    local param = {
      query=query,
      params={date_to, date_from} 
    } 

    db.query(param) 
    while db.query_fetch(record) do 
        table.insert(day, record[1]);
        table.insert(answer,tonumber(record[2]));
        table.insert(cancel,tonumber(record[3]));
    end
        table.insert(result_data, {days = day, answers = answer, cancels = cancel})
    db.query_free();
    return result_data;
end

if input.type == nil then
local res = teamyar.run_command("2/res_bot",{
    id = "voip_success_call_trends",
    tpl_name = "chart",
    lang=1,
    path="2/voip_success_call_trends",
    script='',
    title = "SUCCESS_CALL_TRENDS",
    ajax=[[{
        selector_btn:'#holder_layout_chart_]]..random..[[',
        url:'/bot/run/2/voip_success_call_trends',
        data:()=>{ 
             var holder_id = ']]..random..[[';
            var data_type=parseInt($.Teamyar.input.combobox.get('#voip_data_type_combo_'+holder_id,'value'));
            return {
                type:1,
                data_type:$.Teamyar.input.combobox.get('#voip_data_type_combo_]]..random..[[','value'),
            }
        }
    }]],
    generatedata=[[(data)=>{
        return    ty__main.createDataForChartSuccessCallTrends(data);
    }]],
    script=[[
        (function(){
            var holder_id = ']]..random..[[';
            ]]..script..[[
      
        })();
    ]],
    header="<div id=\\'holder_header_chart_"..random.."\\'></div>"
});

teamyar.write_result(res);

elseif input.type == 1 then
    
    local queresult =  getQueryResponse(query  , json.encode(input.data_type));
    teamyar.write_result(json.encode(queresult));
end