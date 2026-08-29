local input=teamyar.get_input();
input.box_id=tonumber(input.box_id);
input.type=tonumber(input.type);
function getBoxForCombo()
    local param = {
    	query=teamyar.get_attachment("get_email_summery_box_combo.txt");
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
function getEmailSummeryReport()
    teamyar.set_data("email_summery_data", json.encode(input));
    local res = teamyar.get_user_info()
   local box_clause='';

  if input.box_id ~= nil  and input.box_id >0 then 
    box_clause = [[ box_id = ]]..input.box_id..[[  and ]] ;
  end
  local query =teamyar.get_attachment("get_email_summery_report_by_date.txt");
  query =string.gsub(query, "{box_clause}",box_clause)
    local param = {
    	query=query,
    	params={res.id,res.id,res.id,res.id,input.date_from,input.date_to,input.date_from,input.date_to} 
  	} 
  db.query(param) 
  local result={} ; 
  local record={}; 
    while db.query_fetch(record) do 
      table.insert(result,{category=record[1],percent=record[2],count=record[3],total=record[4]}) 
    end 
  db.query_free();
  teamyar.write_result(json.encode(result));
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

local script =  teamyar.get_attachment("email_summery.js");
local template = teamyar.run_command("2/res_bot",{
    id = "email_summery",
    tpl_name = "html",
    title = "EMAIL_SUMMERY",
    body = "<div id=\\'holder_body_html_"..random.."\\'></div>",
    control=   json.encode( {"progress"} ),
	path="2/email_summery",
	lang=1,
	ajax=[[{
    selector_btn:'#holder_layout_chart_]]..random..[[',
    url:'/bot/run/2/email_summery',data:()=>{ 
    var random = ']]..random..[[';
    var date_from=parseInt($.Teamyar.DateTimePicker.get('#email_date_sent_from_'+random,'value'));
    var date_to=parseInt($.Teamyar.DateTimePicker.get('#email_date_sent_to_'+random,'value'));
    if(date_from>0 && date_to>0 && date_from>date_to)
    {
         $.Teamyar.setValidate({selector:'#email_date_sent_to_'+random,message:ty__main.botGetlang("ERR_FROM_FILED_IS_BIGGER_THAN_TO_FIELD"),type: $.Teamyar.validate.type.DATETIMEPICKER});
			
         return -1;
    }
    return {
    type:1,
    date_from:$.Teamyar.DateTimePicker.get('#email_date_sent_from_]]..random..[[','value'),
    date_to:$.Teamyar.DateTimePicker.get('#email_date_sent_to_]]..random..[[','value'),
    box_id:$.Teamyar.input.combobox.get('#email_box_]]..random..[[','value')
  
  } } }]],
    css=[[
 
    .email_summary_holder_parent{
         display:flex;
       flex-direction:row;
       justify-content:center;
      align-items:center;
     }
    
    .email_summary_holder_child{
        width:100%
     }
    
     @media (max-width:992px) {
      .email_summary_holder_child{
        width:70%!important;
        }
    
    }
   
    @media (max-width: 768px) {
      .email_summary_holder_child{
        width:50%!important;
        }
    
    }
    
    ]],
    script=[[
    	(function(){
         var holder_id = '#holder_body_html_]]..random..[[';
    	 var random = ']]..random..[[';
    
        ]]..script..[[
        })();
  ]],
    header="<div id=\\'holder_header_chart_"..random.."\\'></div>",
    
});


if input.type == nil then
teamyar.write_result(template);
elseif input.type == 1 then
    getEmailSummeryReport();
elseif input.type == 2 then
    getBoxForCombo();
elseif input.type == 3 then
    local email_summery_data = teamyar.get_data("email_summery_data");

    if email_summery_data.modify_time == 0 then
        email_summery_data.value = '""';
    end

    teamyar.write_result(email_summery_data.value);
end