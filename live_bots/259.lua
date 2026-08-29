local user_info = teamyar.get_user_info();
local input = teamyar.get_input();
local script = teamyar.get_attachment("main.js");
local query = teamyar.get_attachment("query.txt");
local query_total = teamyar.get_attachment("query_total.txt");
local m_type = 2;
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
function getQueryResponse(data, from, count)
    local box_clause = ''; 
    local result_data={} ; 
    local record={}; 
    local date_from = 0;
    local date_to = 0;
    local user =0;
    local result={total=0,list={}};
    local users = '';
    local user_record={}; 
    local perm_record = {};
    local user_res={}; 
  	local order = 'ID';
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
    
    box_clause = [[ AND CallerProfileId = ]]..user;
    if ( string.len(data.date_from) >= 1 and string.len(data.date_to) >= 1) then
        date_from = data.date_from  - user_info.timezone;
        date_to = data.date_to  - user_info.timezone + 864000000000 - 1;
        
        box_clause = box_clause.. [[ AND (  v.DATE BETWEEN ]]..date_from..[[  AND  ]]..date_to..[[ ) ]];
    end
  	
    query_total =string.gsub(query_total, "{box_clause}",box_clause);
    local params = {
        query= query_total,
        params={} 
    } 

    db.query(params) 
    while db.query_fetch(record) do 
        result.total = record[1];
    end
    db.query_free();
	order = data.order;
    query =string.gsub(query, "{box_clause}",box_clause);
    query =string.gsub(query, "{order}",order);
    local param = {
        query=query,
        params= {from,count} 
    } 

    db.query(param) 
    local counter = 1;

    while db.query_fetch(record) do 
        table.insert(result.list, {name = record[2], total = record[3], no_answer = record[4], duration = record[5]})
    end
    db.query_free();
    
    return result;
end

local res = teamyar.run_command("2/res_bot",{
    id = "outbound_call_details",
    tpl_name = "table",
    lang=1,
    path="2/voip_outbound_call_details",
    title = "OUTBOUND_CALL_DETAILS",
    data= [[{header:['NAME','TOTAL','NO_ANSWER','DURATION']} ]],
    header="<div id=\\'holder_header_chart_"..random.."\\'></div>",
    settable = 1,
    generatetd = [[
        (row)=>{  return ty__main.generatedtd(row) }
    ]],
    ajax = [[{url:'bot/run/2/voip_outbound_call_details',
        data:()=>{
            return  ty__main.botOnClickApplyOutCall();
        }
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
});

if input.type == nil then
    teamyar.write_result(res);
elseif input.type == 1 then
    teamyar.write_log(json.encode(input));
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
    local queresult =  getQueryResponse(dataa, input.from, input.count);
    teamyar.write_result(json.encode(queresult));
elseif input.type == 5 then
    LoadData();
end