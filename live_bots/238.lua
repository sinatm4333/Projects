function getQueryResponse(query,query_params)
  local params = {
      query = query,
      params = query_params
  }
  db.query(params);
  local res_text = db.query_fetch();
  db.query_free();
  return res_text[1];
end

function math.round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

function WidgetTemplate()
  
  local random= math.random(1,1000);
  local script =  teamyar.get_attachment("hr_main_5.js");
  local css =  teamyar.get_attachment("hr_main_5.css");
  local template = teamyar.run_command("2/res_bot",{
      id = "hr_internal_mobility",
      tpl_name = "html",
      title = "INTERNAL_MOBILITY",
      body = "<div id=\\'m_hr_internal_mobilities_"..random.."\\'></div>",
      script=[[
      (function(){
      var holder_id = '#m_hr_internal_mobilities_]]..random..[[';
      debugger;
      ]]..script..[[
    })();

      ]],
      css=css

    });
  teamyar.write_result(template);
 
end

function getData(data)
  
	local user_info = teamyar.get_user_info();
	  local user_id=math.floor(user_info["id"]);
	  local lang_id=math.floor(user_info["lang_id"]);
    local org_id = getQueryResponse(' SELECT S_VALUE FROM ADMIN_USER_CACHE_VALUE WHERE USER_ID = ? AND S_NAME = "organization_active"; ' , {user_id});
  
  local res1 =  getQueryResponse([[
    WITH CTE_OLD_ORDER AS (SELECT ID, PERSONNEL_ID FROM HR_PERSONNEL_ORDER WHERE DATE_TO < ?)
    SELECT COUNT(DISTINCT(P.PERSONNEL_ID))
    FROM HR_PERSONNEL_ORDER NEW_ORDER
    JOIN HR_PERSONNELS P ON P.PERSONNEL_ID = NEW_ORDER.PERSONNEL_ID
    LEFT JOIN CTE_OLD_ORDER CO ON CO.PERSONNEL_ID = NEW_ORDER.PERSONNEL_ID
    JOIN ORG_UNITS U ON U.MANAGER = P.PROFILE_ID WHERE P.ORG_ID = ? AND ? >= NEW_ORDER.DATE_FROM  AND  ? <= NEW_ORDER.DATE_TO AND CO.ID > 0
    ]]
    , {string.format("%.0f", time.current()),math.floor(org_id),string.format("%.0f", time.current()),string.format("%.0f", time.current())});
  
   local res2 =  getQueryResponse([[
SELECT COUNT(DISTINCT(P.PERSONNEL_ID))
FROM HR_PERSONNEL_ORDER NEW_ORDER
JOIN HR_PERSONNELS P ON P.PERSONNEL_ID = NEW_ORDER.PERSONNEL_ID
JOIN ORG_UNITS U ON U.MANAGER = P.PROFILE_ID WHERE P.ORG_ID = ? AND ? >= NEW_ORDER.DATE_FROM  AND  ? <= NEW_ORDER.DATE_TO ;
    ]]
    , {math.floor(org_id),string.format("%.0f", time.current()),string.format("%.0f", time.current())});
  
  local res3 =  getQueryResponse([[
    WITH CTE_OLD_ORDER AS (SELECT ID, PERSONNEL_ID FROM HR_PERSONNEL_ORDER WHERE DATE_TO < ?)
    SELECT COUNT(DISTINCT(P.PERSONNEL_ID))
    FROM HR_PERSONNEL_ORDER NEW_ORDER
    JOIN HR_PERSONNELS P ON P.PERSONNEL_ID = NEW_ORDER.PERSONNEL_ID
    LEFT JOIN CTE_OLD_ORDER CO ON CO.PERSONNEL_ID = NEW_ORDER.PERSONNEL_ID
    WHERE P.ORG_ID = ? AND ? >= NEW_ORDER.DATE_FROM  AND  ? <= NEW_ORDER.DATE_TO AND CO.ID > 0
    ]]
    , {string.format("%.0f", time.current()),math.floor(org_id),string.format("%.0f", time.current()),string.format("%.0f", time.current())});
  
     local res4 =  getQueryResponse([[
 SELECT COUNT(DISTINCT(P.PERSONNEL_ID))
FROM HR_PERSONNEL_ORDER NEW_ORDER
JOIN HR_PERSONNELS P ON P.PERSONNEL_ID = NEW_ORDER.PERSONNEL_ID
 WHERE P.ORG_ID = ? AND ? >= NEW_ORDER.DATE_FROM  AND  ? <= NEW_ORDER.DATE_TO 
    ]]
    , {math.floor(org_id),string.format("%.0f", time.current()),string.format("%.0f", time.current())});
  
  local result_1 = math.round((res1 / res2) * 100, 2);
  local result_2 = res3;
  local result_3 = res4;
  local result_4 = math.round((res3 / res4) * 100, 2);
  
  --teamyar.write_result(res4)
   teamyar.write_result(json.encode({result_1=result_1, result_2=result_2, result_3=result_3,result_4=result_4}))
end

-- main
input=teamyar.get_input(); 

 if input.type == 1 then
  getData(input.data);
else
  WidgetTemplate()
end