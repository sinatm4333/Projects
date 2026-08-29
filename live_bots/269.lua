local input=teamyar.get_input();
function getSectionsForCombo()
    local param = {
    	query=teamyar.get_attachment("get_sections_query.txt");
    	params={} 
  	} 
  db.query(param) 
  local result={} ; 
  local record={}; 
    while db.query_fetch(record) do 
      table.insert(result,{id=record[1],name=record[2]}) 
    end 
  db.query_free();
  teamyar.write_result(json.encode(result));
end
function getReportBySection()
    teamyar.set_data("crm_section_combo_data",input.name);
    local param = {
    	query=teamyar.get_attachment("signed_deals_by_pipeline_get_report_query.txt");
    	params={input.name} 
  	} 
  db.query(param) 
  local result={} ; 
  local record={}; 
    while db.query_fetch(record) do 
      table.insert(result,{count=record[1],section_name=record[2]}) 
    end 
  db.query_free();
  teamyar.write_result(json.encode(result));
end
local random= math.random(1,1000);

local script =  teamyar.get_attachment("signed_deals_by_pipeline.js");
local template = teamyar.run_command("2/res_bot",{
    id = "signed_deals_by_pipeline",
    tpl_name = "chart",
    title = "SIGNED_DEALS_BY_PIPELINE",
    src='<script src="/res/gui/res/js/chart/variable-pie.js" type="text/javascript"></script>',
    ajax=[[{
    selector_btn:'#holder_layout_chart_]]..random..[[',
    url:'/bot/run/2/crm_signed_deals_by_pipeline',data:()=>{ 
    
    return {
    type:1,
    name:$.Teamyar.input.combobox.get('#crm_section_combo_]]..random..[[','value')
  
  } } }]],
    generatedata=[[(data)=>{
  
    return    ty__main.createdataForChart(data);
  
  }]],
    script=[[
    	(function(){
    var holder_id = ']]..random..[[';
        ]]..script..[[
  			
        })();
    ]],
   header="<div id=\\'holder_header_chart_"..random.."\\'></div>",
   -- data= [[()=>{return   ty__main.createdataForChart();
 -- }]]
    
});

if input.type == nil then
teamyar.write_result(template);
elseif input.type == 1 then
    getReportBySection();
elseif input.type == 2 then
    getSectionsForCombo();
elseif input.type == 3 then
    local data = teamyar.get_data("crm_section_combo_data");

    if data.modify_time == 0 then
      data.value = '""';
    end

    teamyar.write_result(data.value);
end