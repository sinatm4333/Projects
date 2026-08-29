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
 
  local org_id = getQueryResponse(' SELECT S_VALUE FROM ADMIN_USER_CACHE_VALUE WHERE USER_ID = ? AND S_NAME = "organization_active"; ' , {user_id});

  local str_query = [[ 
  SELECT JSON_ARRAYAGG(JSON_OBJECT("name",NAME, "y", Y)) 
  FROM (
WITH CTE_PERSONNEL AS (
    SELECT PUI.SEX
    FROM `0000000`.PROFILE_USER_INFO PUI
    JOIN `0000000`.HR_PERSONNELS HP ON PUI.ID = HP.PROFILE_ID
    WHERE HP.ORG_ID = ? AND HP.HIRING_STATUS = 2
)
SELECT
    'MEN' AS NAME,
    ROUND((SUM(CASE WHEN SEX = 1 THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS Y
FROM CTE_PERSONNEL
UNION ALL
SELECT
    'WOMEN' AS NAME,
    ROUND((SUM(CASE WHEN SEX = 2 THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS Y
FROM CTE_PERSONNEL
) TMP;
   ]];
  
local res1 =  getQueryResponse(str_query  , {math.floor(org_id)});


local res = teamyar.run_command("2/res_bot",{
    id = "hr_female_to_male_ratio",
    tpl_name = "chart",
    title = "COMPARE_PERSONNEL_BASED_ON_SEX",
    script='',
    data= [[()=>{ 
    var data = ]] .. res1 .. [[;
   for(var i=0;i<data.length;i++){
    if(data[i].name=='WOMEN')
        {
      data[i].sliced= true;
      data[i].selected= true;
      }
    data[i].name =  ty__main.botGetlang(data[i].name);
  }
    
    return {
    chart: {
        type: 'pie',
        spacingLeft: 40,
    },
    title: {
        text: '' ,//ty__main.botGetlang('FEMALE_TO_MALE_RATIO'),
    	direction: 'rtl'
    },
    tooltip: {
        valueSuffix: '%',
    	direction: 'rtl'
    },
    subtitle: {
        text: ''
       // 'Source:<a href="https://www.mdpi.com/2072-6643/11/3/684/htm" target="_default">MDPI</a>'
    },
    plotOptions: {
        series: {
            allowPointSelect: true,
            cursor: 'pointer',
            dataLabels: [{
                enabled: true,
                distance: 20
            }, {
                enabled: true,
                distance: -40,
                format: '{point.percentage:.1f}%',
                style: {
                    fontSize: '1.2em',
                    textOutline: 'none',
                    opacity: 0.7
                },
                filter: {
                    operator: '>',
                    property: 'percentage',
                    value: 10
                }
            }]
        }
    },
    series: [
        {
            name:  'Percentage',
            colorByPoint: true,
            data: data
        }
    ]
}
}]]
    
});


teamyar.write_result(res);