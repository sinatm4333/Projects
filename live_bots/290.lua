  local input=teamyar.get_input();

  function getList()

    teamyar.set_data("documents_approved_data", json.encode(input));
      teamyar.write_log( json.encode(input));
    local clause='';

	for value in input.approved_type:gmatch("[^,]+") do
      if tonumber(value) == 1 then
      		clause=clause ..[[ OR (DATE_CONFIRM != 0  AND STATUS_CONFIRM=1) ]]
  		end
 		 if tonumber(value) == 2 then
     		 clause=clause ..[[ OR (DATE_SIGN !=0 AND STATUS_SIGN=1) ]]
  		end     
 		if tonumber(value) == 3 then
          clause=clause ..[[ OR (DATE_RESPONSIBLE!=0 AND STATUS_RESPONSIBLE = 1) ]]
  		end
	end

    local query =teamyar.get_attachment("documents_approved_query.txt");
    query =string.gsub(query, "{confirm_clause}",clause)
    if input.user_ids=="" then
    	input.user_ids=0;
  end
    query =string.gsub(query, "{user_ids}",input.user_ids)
   teamyar.write_log(query);
    local param = {
          query=query,
          params={input.date_from,input.date_to,input.from,input.count}
    }
  local users ='';
    db.query(param)
  local result={total=0,list={}}  ;
    local user_ids={};
    local record={};
    local total=0
    if db.query_fetch(record) then 
  
        result.total=record[1];
  
        while db.query_fetch(record) do
  
            table.insert(result.list,{record[2],record[6],record[9],record[11],record[12],record[13],record[29],record[30] ,record[31],record[32],record[33],record[34],record[35]});
            table.insert(user_ids,record[29]);
        end 
    users=user_ids
         profile_infos=teamyar.call_api(5,"/api/profile_info/get",{ids=user_ids});
        if profile_infos.success == true then
            for i, v in ipairs(profile_infos.data) do 
                for j, value in ipairs(result.list) do 
                        if v.id==value[7] then
            				table.insert(result.list[j],v.fullname)
                        end
                end
            end
        end
     end
    db.query_free();

    return result;
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
local script =  teamyar.get_attachment("documents_approved.js");

local template = teamyar.run_command("2/res_bot",{
    id = "documents_approved",
    tpl_name = "table",
    title = "APPROVED_DOCUMENTS",
    script=[[
        (function(){
    var holder_id = ']]..random..[[';
        ]]..script..[[
            
        })();
    ]],
    data= [[{header:['FILE_ICON','FILE_NAME','FILE_SIZE','APPROVED_USER','DATE_CREATE','DATE_CONFIRM','DATE_SIGN','DATE_RESPONSIBLE']} ]],
    settable = 1,
    path="2/documents_approved",
    lang=1,
    header="<div id=\\'holder_header_table_"..random.."\\'></div>",
    generatetd = [[(row)=>{
        return  [
                                $.Teamyar.icon({type:row[2]}),
                                $.Teamyar.link({title:row[1],href: "/document/file/show_version/" +row[0] ,target:"_blank"}),
                                $.Teamyar.tools.BytesToString(row[3]),
                                row[13],
                                $.Teamyar.smartDate(row[4],1),
                                $.Teamyar.smartDate(row[8],1),
                                $.Teamyar.smartDate(row[9],1),
                                $.Teamyar.smartDate(row[11],1)
                                ]
    }]],
    ajax = [[{url:'bot/run/2/documents_approved',data:()=>{
    	let users_obj=$.Teamyar.acl.get('#documents_approved_user_]]..random..[[','value');
    	var user_ids_str='';
    	if(Object.keys(users_obj).length >0)
   	 	{
    		user_ids_str = users_obj.map(item => item.id).join(',');
  		}

        return	{
            type:1,
            user_ids: user_ids_str,
    		users_obj: users_obj,
            date_from:$.Teamyar.DateTimePicker.get('#documents_approved_date_from_]]..random..[[','value'),
            date_to:$.Teamyar.DateTimePicker.get('#documents_approved_date_to_]]..random..[[','value'),
            approved_type:$.Teamyar.input.combobox.get('#documents_approved_type_]]..random..[[','value')}
    } }]]
});

if input.type == nil then
    teamyar.write_result(template);
    elseif input.type == 1 then
        teamyar.write_result(json.encode(getList()));
    elseif input.type == 2 then
       local documents_approved_data=teamyar.get_data("documents_approved_data");
        if documents_approved_data.modify_time == 0 then
            documents_approved_data.value = '""';
        end
        teamyar.write_result(documents_approved_data.value);
    end