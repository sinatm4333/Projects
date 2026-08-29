local input=teamyar.get_input();
local user_info = teamyar.get_user_info();
local owner_user = user_info.id;
local cur_date = time.current();
local last_date = time.current()-(time.day*7);
local users = '';

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

function userAcl(data)
  local search = "";
   if data.search ~= nil and #data.search > 0 then
       search =  " AND instr(NAME,'" .. data.search .. "')>0"
    end
    local query_param = [[ with cte_data as(
		SELECT vp.USER_ID AS id, pm.FULLNAME as name , pm.type
        FROM voip_TY_PERMISSION vp 
		LEFT JOIN profile_main pm on vp.user_id = pm.id 
		WHERE vp.ID=]]..owner_user..[[ AND vp.TYPE=1 AND vp.PERM IN(2,3) AND vp.raw_perm=0 AND pm.type =1
	UNION
		SELECT distinct(pgm.USER_ID) AS id, pm.FULLNAME as name, pm.type 
        FROM voip_TY_PERMISSION vp 
		LEFT JOIN profile_group_member pgm on vp.USER_ID = pgm.GROUP_ID
		LEFT JOIN profile_main pm on pgm.USER_ID = pm.id -- AND pm.type = 1 
		WHERE vp.ID=]]..owner_user..[[ AND vp.TYPE=1 AND vp.PERM IN(2,3) AND vp.raw_perm=0 AND pm.type =1 
) 
, cte_dataa as (
select * from cte_data as cte_dataa
  ]]
    query_param = query_param .. string.format(' limit %d,%d',data.from,data.count) .. ')' .. 
   "select JSON_ARRAYAGG(JSON_OBJECT('id',cte_dataa.id, 'name',cte_dataa.name, 'type',1)) as result from cte_dataa"
  
    local params = {
        query=query_param,
        params={}
    };
    db.query(params)
    local record={};
    while db.query_fetch(record) do
        teamyar.write_result(record[1])
    end
    db.query_free();
end

function userAclData()
    local query_param = [[with cte_data as( ]]..
            [[SELECT id AS id, FULLNAME AS name FROM profile_main WHERE ID= ]]..owner_user..[[)]].. 
            [[select JSON_ARRAYAGG(JSON_OBJECT('id',cte_data.id, 'name',cte_data.name, 'type',1)) as result from cte_data]];
  
    local params = {
        query=query_param,
        params={}
    };
    db.query(params)
    local record={};
    while db.query_fetch(record) do
        return record[1];
    end
    db.query_free();
end

function loadData()
    local data = teamyar.get_data("data");  
    if data.modify_time == 0 then
        data.value = '""';
    end
    local param = json.decode(data.value)
    if(param.user_id) then
        if(param.user_id.id) then
            users = checkUserPermission(param.user_id.id);
            if(users == param.user_id.id) then
                teamyar.write_result(data.value);
            end
        end
    end
end
function checkUserPermission(users)
    local perm_record = {};
    local perm = 0;
    if(users ~= owner_user) then
        local perm_query =[[SELECT perm FROM voip_TY_PERMISSION vp ]]..
            [[where type=1 and id= ]]..owner_user..[[ and user_id = ]].. users;
        perm_params = {
            query = perm_query,
            params = {}
        }
        db.query(perm_params);
        while db.query_fetch(perm_record) do 
            perm = perm_record[1];
        end
        if(perm == 0) then
            users = owner_user;
            local id = '#user_id_'..random;
            local acl = "<script> $.Teamyar.acl.set("..id..", 'value', []); </script>"
        end
    end
    return users;
end

function getCallsInfo(data)
    teamyar.set_data("data", json.encode(data));
    local res = teamyar.get_user_info()
    local box_clause='';
    local user =0;
    local users = '';
    local user_record={}; 
    local perm_record = {};
    local user_res={}; 
    perm = 0;
    if(data.user_id) then
        local user_id = data.user_id;
        local type_user_id = type(data.user_id);
        if(type_user_id == "string" or type_user_id == "number") then
            user = data.user_id
        else
            if( user_id.id ~= nil) then
                user = user_id.id;
            end
        end
        if(user == 0) then 
            users = user_info.id
        else
            users = user;
        end
    end
    --  ------------------  check user permission  ------
    users = checkUserPermission(users);
    -- -----------------  get profiles  ------
    local users_query =[[SELECT group_concat(pg.user_id) as users FROM profile_main pm ]]..
        [[left join profile_group_member pg on pm.id = pg.GROUP_ID ]]..
        [[where pm.id=]].. users;
    params = {
        query = users_query,
        params = {}
    }
    db.query(params);
    while db.query_fetch(user_record) do 
        users =user_record[1];
    end
    
    --  ------------------    ------
    -- users = user_res.id;
    -- if tonumber(users) >0 then
    box_clause = [[ ( CallerProfileId in(]]..users..[[)  OR ConnectedLineProfileId in(]]..users..[[ )) ]];
    -- end
    

    if(data.date_from) then
        if (string.len(data.date_from) >= 1 and string.len(data.date_to) >= 1) then
            if string.len(box_clause) > 0 then
                box_clause =box_clause.. [[ AND ]];
            end
            local date_from = data.date_from - user_info.timezone;
            local date_to = data.date_to - user_info.timezone + 864000000000 - 1;
            box_clause = box_clause.. [[ (  DATE >= ]]..date_from..[[  AND DATE <=  ]]..date_to..[[ ) ]];
        end
    end
    local query =teamyar.get_attachment("get_calls_report_by_date.txt");
    query =string.gsub(query, "{box_clause}",box_clause)
    query =string.gsub(query, "{box}",users)
    
    local param = {
        query=query,
        params={users, users,users,users} 
    }
    db.query(param)
    local result={} ; 
    local record={}; 
    while db.query_fetch(record) do 
        no_answer=record[7]; 
        busy=record[8];
        cancel=record[9];
        local failed = tonumber(no_answer) + tonumber(busy) + tonumber(cancel);
        table.insert(result,{total=record[1],sum=record[2],avg=record[3],answer=record[4], inbound=record[5], outbound=record[6], failed = failed}) 
    end 
    db.query_free();
    teamyar.write_result(json.encode(result));
end

local css =  teamyar.get_attachment("main.css");
local script =  teamyar.get_attachment("main.js");
local template = teamyar.run_command("2/res_bot",{
    id = "voip_overview",
    tpl_name = "chart",
    title = "OVERVIEW",
    lang=1,
    path="2/voip_overview",
    src='<script src="/res/gui/res/js/chart/variable-pie.js" type="text/javascript"></script>',
    ajax=[[{
        selector_btn:'#holder_layout_chart_]]..random..[[',
        url:'/bot/run/2/voip_overview',data:()=>{ 
            var holder_id = ']]..random..[[';
            var date_from=parseInt($.Teamyar.DateTimePicker.get('#voip_start_date_'+holder_id,'value'));
            var date_to=parseInt($.Teamyar.DateTimePicker.get('#voip_end_date_'+holder_id,'value'));
            var user_id=parseInt($.Teamyar.acl.get('#user_id_'+holder_id,'value'));
            if(date_from>0 && date_to>0 && date_from>date_to)
            {
                $.Teamyar.setValidate({selector:'#voip_end_date_'+holder_id,message:ty__main.botGetlang("ERR_FROM_FILED_IS_BIGGER_THAN_TO_FIELD"),type: $.Teamyar.validate.type.DATETIMEPICKER});
              
                return -1;
            }
            return {
                type:4,
                date_from:$.Teamyar.DateTimePicker.get('#voip_start_date_]]..random..[[','value'),
                date_to:$.Teamyar.DateTimePicker.get('#voip_end_date_]]..random..[[','value'),
                user_id:$.Teamyar.acl.get('#user_id_]]..random..[[','value')
            }
        }
    }]],
    generatedata=[[(data)=>{
        return    ty__main.createDataForChartOverview(data);
    }]],
    
    script=[[
        (function(){
            var holder_id = ']]..random..[[';
            var cur_date = ]]..cur_date..[[;
            var last_date = ]]..last_date..[[;
            var user_acl = ]]..userAclData()..[[;

            ]]..script..[[;
        })();
    ]],
    
    header="<div id=\\'holder_header_chart_"..random.."\\'></div>",
    css=css
});

if input.type == nil then
    teamyar.write_result(template);
elseif input.type == 1 then
    teamyar.set_data("data", input.data);
elseif input.type == 2 then
    userAcl(input.data);
elseif input.type == 4 then
    local dataa = {}
    if(input.data) then
        dataa = input.data
    else 
        dataa = input;
    end
    getCallsInfo(dataa);
elseif input.type == 5 then
    loadData()
end
