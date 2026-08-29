local input=teamyar.get_input();
function getMetaDatasForCombo()
    local param = {
    	query=teamyar.get_attachment("get_metadata_query.txt");
    	params={} 
  	} 
  db.query(param) 
  local result1={} ; 
  local record={}; 
    while db.query_fetch(record) do 
      table.insert(result1,{id=record[1],name=record[2]}) 
    end 
  db.query_free();
  if #result1>0 then
  	teamyar.write_result(json.encode(result1));
  end
end
function getReportByMetaData()
    teamyar.set_data("doc_mt_combo_data", input.name);
    local res = teamyar.get_user_info()
    local param = {
    	query=teamyar.get_attachment("get_report_by_metadata_query.txt");
    
    	params={input.name,res.id} 
  	} 
  db.query(param) 
  local result={} ; 
  local record={}; 
    while db.query_fetch(record) do 
      table.insert(result,{org_name=record[1],confirm_status=record[2],count=record[3]}) 
    end 
  db.query_free();
  if #result>0 then
  	teamyar.write_result(json.encode(result));
  end
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

local script =  teamyar.get_attachment("document_confirm_status_in_org.js");
local template = teamyar.run_command("2/res_bot",{
    id = "document_confirm_status_in_org",
    tpl_name = "chart",
    title = "DOCUMENTS_STATUS_IN_ORGANIZATION_UNITS",
    ajax=[[{
    selector_btn:'#holder_layout_chart_]]..random..[[',
    url:'/bot/run/2/document_confirm_status_in_org',data:()=>{ 
    
    return {
    type:1,
    name:$.Teamyar.input.combobox.get('#document_metadata_combo_]]..random..[[','value')
  
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
    getReportByMetaData();
elseif input.type == 2 then
    getMetaDatasForCombo();
elseif input.type == 3 then
    local data = teamyar.get_data("doc_mt_combo_data");

    if data.modify_time == 0 then
      data.value = '""';
    end

    teamyar.write_result(data.value);
end