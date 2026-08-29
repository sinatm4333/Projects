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
local input=teamyar.get_input();
local script =  teamyar.get_attachment("main.js");
local query_fa =teamyar.get_attachment("query_fa.txt");
local user_info = teamyar.get_user_info();
   teamyar.write_log(json.encode(input))

function queryResult(select_query,user_param)

    local params1 = {
      query =select_query,
      params = user_param
  }
  db.query(params1);
  local record = {}
  local all = {}
  while db.query_fetch(record) do
      table.insert(all, {id=record[1], name=record[2]})
  end
  db.query_free();
  return all;
end


local template = teamyar.run_command("2/res_bot",{
    id = "voip_month_call_trends",
    tpl_name = "chart",
   path="2/hr_request_hiring",
    lang=1,
    title = "HR_REQUEST_USE_BY_ORG",
    ajax=[[{
        selector_btn:'#holder_layout_chart_]]..random..[[',
        url:'/bot/run/2/hr_request_hiring',data:()=>{ 
            var holder_id = ']]..random..[[';
      var start_date=parseInt($.Teamyar.DateTimePicker.get('#hr_start_date_'+holder_id,'value'));
    var end_date=parseInt($.Teamyar.DateTimePicker.get('#hr_end_date_'+holder_id,'value'));
    if(start_date>0 && end_date>0 && start_date>end_date)
    {
         $.Teamyar.setValidate({selector:'#hr_end_date_'+holder_id,message:ty__main.botGetlang("ERR_FROM_FILED_IS_BIGGER_THAN_TO_FIELD"),type: $.Teamyar.validate.type.DATETIMEPICKER});
			
         return -1;
    }
            return {
                type:1,
                org_id: $.Teamyar.input.acl.get('#acl_org]]..random..[[','value').id,
                org_name:  $.Teamyar.input.acl.get('#acl_org]]..random..[[','value').name,
                start_date:$.Teamyar.DateTimePicker.get('#hr_start_date_]]..random..[[','value'),
                end_date:$.Teamyar.DateTimePicker.get('#hr_end_date_]]..random..[[','value'),
            }
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
  
function OrganizationAcl()
 
    local str_query = [[ 
	select ID, NAME from ORG_INFO 
  ]];
  if input.data.search ~= nil and #input.data.search > 0 then
    str_query = str_query .. [[ where (instr(NAME,"]] .. input.data.search .. [[")>0)]]
  end
  str_query = str_query .. [[ limit ?,? ;]]
  local res =  queryResult(str_query  , {input.data.from, input.data.count});
  teamyar.write_result(json.encode(res));
  
end

if input.type == nil then
    teamyar.write_result(template);
  
elseif input.type == 1 then
   teamyar.set_data("data",json.encode(input));

  
    if input.org_id==nil then
        input.org_id=0
    end
    local param = {
    	query=query_fa,
    	params={input.start_date, input.end_date,input.org_id, input.start_date, input.end_date, input.start_date, input.end_date } 
  	} 
  db.query(param) 
  local result={} ; 
  local record={}; 
    while db.query_fetch(record) do 
      table.insert(result,{job_name=record[1],total=record[2],request_use=record[3],hiring_count=record[4]}) 
    end 
  db.query_free();
    teamyar.write_result(json.encode(result));

elseif input.type == 2 then
  OrganizationAcl();
elseif input.type == 3 then
   local data = teamyar.get_data("data");;
    if data.modify_time == 0 then
    data.value = '""';
   end
    teamyar.write_result(data.value);
end
  