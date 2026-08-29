local random= math.random(1,1000);
local input=teamyar.get_input();
local script =  teamyar.get_attachment("main.js");
local query_en =teamyar.get_attachment("query_en.txt");
local query_fa =teamyar.get_attachment("query_fa.txt");
local user_info = teamyar.get_user_info();
local lang_id=math.floor(user_info["lang_id"]);

if(lang_id == 4) then 
    query = query_fa;
elseif(lang_id == 1) then
    query = query_en;
end
teamyar.write_log(lang_id)

function getQueryResponse(query,query_params)
    local params = {
        query = query,
        params = query_params
    }
    teamyar.write_log(json.encode(query_params))
    db.query(params);
    local res_text = db.query_fetch();
    db.query_free();
    return res_text[1];
end

local template = teamyar.run_command("2/res_bot",{
    id = "voip_month_call_trends",
    tpl_name = "chart",
    lang=1,
    path="2/voip_month_call_trends",
    title = "VOIP_CALL_TRENDS_BY_MONTH",
    ajax=[[{
        selector_btn:'#holder_layout_chart_]]..random..[[',
        url:'/bot/run/2/voip_month_call_trends',data:()=>{ 
            return ty__main.BotOnClickApply()
            
        }
    }]],
    generatedata=[[(data)=>{
    
      return    ty__main.createdataForChart3(data);
    
    }]],
    script=[[
        (function(){
            var holder_id = ']]..random..[[';
            ]]..script..[[
            
        })();
    ]],
    header="<div id=\\'holder_header_chart_"..random.."\\'></div>",
    src=[[<script src="/res/gui/res/js/chart/funnel.js" type="text/javascript"></script>
    ]]
  });
  
function OrganizationAcl(data)
    local query_param = [[ with cte_data as(select ID, NAME from ORG_INFO ]];
    if data.search ~= nil and #data.search > 0 then
        query_param = query_param .. [[ where instr(NAME,']] .. data.search .. [[ ')>0 ]];
    end
    query_param = query_param .. string.format([[ limit %d,%d ]],data.from,data.count) .. [[ ) ]] .. 
    [[ select JSON_ARRAYAGG(JSON_OBJECT('id',cte_data.ID, 'name',cte_data.NAME, 'type',1)) as result from cte_data ]];
    teamyar.write_result(getQueryResponse(query_param  , {} ));
end
  
function FiscalAclList(data)
    teamyar.write_log(json.encode(data))
    local str_query = [[ select JSON_ARRAYAGG(JSON_OBJECT("id",ID, "name",TITLE, "type",1 , "start_date", START_DATE, "end_date", END_DATE)) 
    from (select id,title,start_date,end_date  from `0000000`.pa_fiscal_year  WHERE ORG_ID=? ]];
    if data.search ~= nil and #data.search > 0 then
        str_query = str_query .. [[ and (instr(TITLE,]] .. data.search .. [[)>0)]]
    end
    str_query = str_query .. [[ limit ?,?  ) tmp;]]
    local res =  getQueryResponse(str_query  , {data.org_id,data.from, data.count});
    teamyar.write_log(res)

    teamyar.write_result(res)
end

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
elseif input.type == 2 then
    OrganizationAcl(input.data);
elseif input.type == 3 then
    FiscalAclList(input.data);
elseif input.type == 4 then
    local dataa = {}
    if(input.data) then
        dataa = input.data
    else 
        dataa = input;
    end
    -- query_params = {dataa.start_date, dataa.end_date,dataa.start_date, dataa.end_date};
    teamyar.write_log(json.encode(dataa));
    query_params = {
        string.format("%.0f", json.encode(dataa.start_date)), 
        string.format("%.0f", json.encode(dataa.end_date)),
        string.format("%.0f", json.encode(dataa.start_date)), 
        string.format("%.0f", json.encode(dataa.end_date))
    };
    local query_result =  getQueryResponse(query, query_params);
    teamyar.write_result(json.encode({data={query_result}}));
elseif input.type == 5 then
  LoadData();
end
  