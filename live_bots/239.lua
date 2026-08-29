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
  
  local user_info = teamyar.get_user_info();
  local user_id=math.floor(user_info["id"]);
  local lang_id=math.floor(user_info["lang_id"]);
 
  local org_id = getQueryResponse(' SELECT S_VALUE FROM ADMIN_USER_CACHE_VALUE WHERE USER_ID = ? AND S_NAME = "organization_active"; ' , {user_id});
local fiscal = getQueryResponse([[
  select JSON_ARRAYAGG(JSON_OBJECT("id",id, "title", title, "start_date", start_date, "end_date", end_date)) from (
  SELECT ID, title, START_DATE,END_DATE FROM PA_FISCAL_YEAR WHERE ORG_ID=? ) tmp; 
  ]] , {math.floor(org_id)});
	
 local str_query =teamyar.get_attachment("main_query.txt");


local fiscal_data = json.decode(fiscal)
local all_fiscals = {};
local all_full_time = {};
local all_part_time = {};
for _, entry in ipairs(fiscal_data) do
    table.insert(all_fiscals, entry.title)
  local res1 =  getQueryResponse(str_query  , {math.floor(org_id), string.format("%.0f", entry.start_date),string.format("%.0f", entry.end_date),string.format("%.0f", entry.start_date),string.format("%.0f", entry.end_date),
      																									string.format("%.0f", entry.start_date),string.format("%.0f", entry.end_date),string.format("%.0f", entry.start_date),string.format("%.0f", entry.end_date),
      																								    string.format("%.0f", entry.start_date),string.format("%.0f", entry.end_date),string.format("%.0f", entry.start_date),string.format("%.0f", entry.end_date),
    																				                    string.format("%.0f", entry.start_date),string.format("%.0f", entry.end_date),string.format("%.0f", entry.start_date),string.format("%.0f", entry.end_date)});
  
  local tmp = json.decode(res1);	
  table.insert(all_full_time, tmp.full_time)
  table.insert(all_part_time, tmp.part_time)

end

local res = teamyar.run_command("2/res_bot",{
    id = "hr_parttime_vs_fulltime",
    tpl_name = "chart",
    title = "PART_TIME_VS_FULL_TIME",
    script='',
    data= [[()=>{ 
    var all_fiscals =  ]] .. json.encode(all_fiscals) .. [[;
     var all_full_time =  ]] .. json.encode(all_full_time) .. [[;
     var all_part_time =  ]] .. json.encode(all_part_time) .. [[;

  
    return {
    chart: {
        type: 'spline'
    },
    title: {
        text: "",// ty__main.botGetlang('PART_TIME_VS_FULL_TIME')
    },
    subtitle: {
        text: "", // 'Source: ' +
           // '<a href="https://en.wikipedia.org/wiki/List_of_cities_by_average_temperature" ' +
            //'target="_blank">Wikipedia.com</a>'
    },
    xAxis: {
        categories: all_fiscals,
        accessibility: {
            description: 'Months of the year'
        }
    },
    yAxis: {
        title: {
            text: 'Percentage'
        },
        labels: {
            format: '{value}%'
        }
    },
    tooltip: {
        crosshairs: true,
        shared: true
    },
    plotOptions: {
        spline: {
            marker: {
                radius: 4,
                lineColor: '#666666',
                lineWidth: 1
            }
        }
    },
    series: [{
        name: ty__main.botGetlang('FULL_TIME'),
        marker: {
            symbol: 'square'
        },
        data: all_full_time

    }, {
        name:  ty__main.botGetlang('PART_TIME'),
        marker: {
            symbol: 'diamond'
        },
        data: all_part_time
    }]
}
}]]
    
});


teamyar.write_result(res);