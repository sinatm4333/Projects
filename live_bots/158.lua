local template = teamyar.get_attachment("template.html")
teamyar.write_result(template)

input = teamyar.get_input();

 params = {
    section_id = input["section"] ,
    profile = {
      name = input["fname"] ,
      last_name = input["lname"],
      user_type = input["u_type"],
      email = {{
        value = input["email"]
      }},
      mobile = {{
        country = 364 ,
        value = input["mobile"]
      }},
      national_code = {{
        country = 0 ,
        value = input["code"]
      }},
    }
  }

         
--teamyar.write_result(json.encode(params).."</br>");
response=teamyar.call_api(14,"/api2/client/create",params);

      if response["type"] ~= "ok" then
   --teamyar.write_result([[{"type":"failed","message":"Error"}]]);
    -- teamyar.write_result(json.encode(response));
   return 
   end

         if response["data"] == nil or  response["data"]["profile_id"] == nil then
          teamyar.write_result([[{"type":"failed","message":"profile id is null"}]]);
          return 
          end 





 teamyar.write_result("")