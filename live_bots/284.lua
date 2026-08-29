local input=teamyar.get_input();
function getSectionForCombo()
    local param = {
    	query=teamyar.get_attachment("get_sms_statistics_section_combo.txt");
    	params={} 
  	} 
  db.query(param) 
  local result={} ; 
  local record={}; 
    while db.query_fetch(record) do 
      table.insert(result,{id=record[1],name=record[2]}) 
    end 
  db.query_free();
  if #result>0 then
  	teamyar.write_result(json.encode(result));
  end
end
function getSmsStatisticsReport()
    teamyar.set_data("sms_statistics_data", json.encode(input));
    local res = teamyar.get_user_info()
   local box_clause='';
  
  if tonumber(input.section_id) >0 then 
    box_clause = [[ WHERE SM.SMSBOX_ID= ]]..input.section_id ;
  end
  local query =teamyar.get_attachment("get_sms_statistics_report_query.txt");
  query =string.gsub(query, "{box_clause}",box_clause)
    local param = {
    	query=query,
    	params={time.current()} 
  	} 
  db.query(param) 
  local result={} ; 
  local record={}; 
    while db.query_fetch(record) do 
      table.insert(result,{date=record[1],cat_5_count=record[2],cat_2_count=record[3],total=record[4]}) 
    end 
  db.query_free();

local data={};
table.insert(data,{data=result,cur_time=time.current()})
  teamyar.write_log(time.current());
teamyar.write_result(json.encode(data));

end
--local random= math.random(1,1000);
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

local script =  teamyar.get_attachment("sms_statistics.js");
local template = teamyar.run_command("2/res_bot",{
    id = "sms_statistics",
    tpl_name = "chart",
    title = "SMS_STATISTICS",
    path="2/sms_statistics",
    src='',
    lang=1,
    ajax=[[{
    selector_btn:'#holder_layout_chart_]]..random..[[',
    url:'/bot/run/2/sms_statistics',data:()=>{ 
        var holder_id = ']]..random..[[';
    return {
    type:1,
    section_id:$.Teamyar.input.combobox.get('#sms_section_]]..random..[[','value')
  
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
    getSmsStatisticsReport();
elseif input.type == 2 then
    getSectionForCombo();
elseif input.type == 3 then
   local sent_email_data=teamyar.get_data("sms_statistics_data");

    if sent_email_data.modify_time == 0 then
        sent_email_data.value = '""';
    end

    teamyar.write_result(sent_email_data.value);
end