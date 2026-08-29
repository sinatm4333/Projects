input = teamyar.get_input();
local section = input.section_id

 	-- teamyar.write_result(section)

res = teamyar.call_api(5, '/api/profile_data/get', {id=input.id,module_id=5,type=1});


if res.success then
  
  		local param =  {section_id=section,profile={name=res.data.name,last_name=res.data.surname,mobile={},national_code={},email={}}}
  
  		for i,v in ipairs(res.data.mobile) do
    		table.insert(param.profile.mobile, {country=v.country_code,value=v.mobile})
  		end
  
   		for i,v in ipairs(res.data.national_code) do
    		table.insert(param.profile.national_code, {country=v.country_code,value=v.national_code})
  		end
  
   		for i,v in ipairs(res.data.email) do
    		table.insert(param.profile.email, {value=v.email})
  		end

  	teamyar.write_result(json.encode(param))
  
  		response = teamyar.call_api(14, '/api/client/create', param);


         if not response.success then
                  teamyar.write_result(context,[[{"type":"failed","message":"]] .. response.error.message .. [["}]]);
                 return
         end

         if response["data"] == nil or  response["data"]["profile_id"] == nil then
          teamyar.write_result(context,[[{"type":"failed","message":"profile id is null"}]]);
          return 
          end 

 	
  	

  	
else
  teamyar.write_result( "Not OK")
end