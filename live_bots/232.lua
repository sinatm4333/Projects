local input=teamyar.get_input();
function getSectionForCombo()
    local param = {
    	query=teamyar.get_attachment("get_sent_email_section_combo.txt");
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
function getSentEmailReport()
    teamyar.set_data("sent_email_data", json.encode(input));
    local res = teamyar.get_user_info()
   local box_clause='';
  if tonumber(input.section_id) >0 then 
    box_clause = [[ box_id = ]]..input.section_id..[[  and ]] ;
  end
  local query =teamyar.get_attachment("get_sent_email_report_by_date.txt");
  query =string.gsub(query, "{box_clause}",box_clause)
    local param = {
    	query=query,
    	params={res.id,res.id,res.id,input.date_from,input.date_to,input.date_from,input.date_to} 
  	} 
  db.query(param) 
  local result={} ; 
  local record={}; 
    while db.query_fetch(record) do 
      table.insert(result,{send_flag=record[1],percent=record[2],count=record[3]}) 
    end 
  db.query_free();
  --if #result>0 then
  	teamyar.write_result(json.encode(result));
  --end
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

local script =  teamyar.get_attachment("sent_email.js");
local template = teamyar.run_command("2/res_bot",{
    id = "email_sent_email",
    tpl_name = "chart",
    title = "SENT_EMAIL",
    path="2/email_sent_email",
    src='<script src="/res/gui/res/js/chart/variable-pie.js" type="text/javascript"></script>',
    lang=1,
    ajax=[[{
    selector_btn:'#holder_layout_chart_]]..random..[[',
    url:'/bot/run/2/email_sent_email',data:()=>{ 
        var holder_id = ']]..random..[[';
      var date_from=parseInt($.Teamyar.DateTimePicker.get('#email_date_sent_from_'+holder_id,'value'));
    var date_to=parseInt($.Teamyar.DateTimePicker.get('#email_date_sent_to_'+holder_id,'value'));
    if(date_from>0 && date_to>0 && date_from>date_to)
    {
         $.Teamyar.setValidate({selector:'#email_date_sent_to_'+holder_id,message:ty__main.ES_BOT_LANG.ERR_FROM_FILED_IS_BIGGER_THAN_TO_FIELD,type: $.Teamyar.validate.type.DATETIMEPICKER});
			
         return -1;
    }
    return {
    type:1,
    date_from:$.Teamyar.DateTimePicker.get('#email_date_sent_from_]]..random..[[','value'),
    date_to:$.Teamyar.DateTimePicker.get('#email_date_sent_to_]]..random..[[','value'),
    section_id:$.Teamyar.input.combobox.get('#email_section_]]..random..[[','value')
  
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
    getSentEmailReport();
elseif input.type == 2 then
    getSectionForCombo();
elseif input.type == 3 then
   local sent_email_data=teamyar.get_data("sent_email_data");

    if sent_email_data.modify_time == 0 then
        sent_email_data.value = '""';
    end

    teamyar.write_result(sent_email_data.value);
end