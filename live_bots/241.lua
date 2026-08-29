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
	
  local str_query = [[ 
    SELECT JSON_ARRAYAGG(JSON_OBJECT("name",NAME, "y", Y)) 
FROM (
WITH CTE_FilterOnPersonnelOrder AS 
( SELECT PO.ID, PO.ORG_ID, PO.PERSONNEL_ID, P.PROFILE_ID, PO.DATE_FROM, PO.DATE_TO
  FROM HR_PERSONNEL_ORDER PO
  JOIN HR_PERSONNELS P ON P.PERSONNEL_ID = PO.PERSONNEL_ID
  WHERE P.HIRING_STATUS = 4 AND 
PO.ORG_ID = ? AND PO.STATUS = 1) 
, CTE_MinStartDateBaseOrder AS
( SELECT O.ID, O.ORG_ID, O.PERSONNEL_ID, O.PROFILE_ID, O.DATE_FROM , O.DATE_TO, MIN(NO.DATE_FROM) StartDate
  FROM CTE_FilterOnPersonnelOrder O
  LEFT JOIN CTE_FilterOnPersonnelOrder NO
  ON  NO.PERSONNEL_ID = O.PERSONNEL_ID AND NO.ID >= O.ID
  AND ((NO.DATE_FROM >= O.DATE_FROM  AND NO.DATE_TO <= O.DATE_TO) OR (NO.DATE_FROM >= O.DATE_FROM AND NO.DATE_FROM <= O.DATE_TO) OR (NO.DATE_TO >= O.DATE_FROM AND NO.DATE_TO <= O.DATE_TO) OR (NO.DATE_FROM <= O.DATE_FROM AND NO.DATE_TO >= O.DATE_TO))
  GROUP BY  O.ID, O.ORG_ID, O.PERSONNEL_ID, O.PROFILE_ID, O.DATE_FROM , O.DATE_TO)
, CTE_MaxOrder AS
( SELECT DISTINCT SDO.ORG_ID, SDO.PERSONNEL_ID, SDO.PROFILE_ID, max(OrderInfo.ID) RefID, SDO.StartDate
  FROM CTE_MinStartDateBaseOrder SDO
  INNER JOIN CTE_FilterOnPersonnelOrder OrderInfo
  ON SDO.PERSONNEL_ID = OrderInfo.PERSONNEL_ID AND SDO.StartDate = OrderInfo.DATE_FROM 
  GROUP BY SDO.ORG_ID, SDO.PERSONNEL_ID, SDO.PROFILE_ID, SDO.StartDate)
, CTE_OrderInfo AS 
( SELECT MO.ORG_ID, MO.PERSONNEL_ID, MO.PROFILE_ID, MO.RefID, MO.StartDate, EndDateOrder.DATE_TO EndDate, min(SSC.DATE_HIRING_END) StopCooperation
  FROM CTE_MaxOrder MO
  INNER JOIN CTE_FilterOnPersonnelOrder EndDateOrder
  ON EndDateOrder.PERSONNEL_ID = MO.PERSONNEL_ID AND MO.RefID = EndDateOrder.ID
  LEFT JOIN HR_SECOND_HIRING_END SSC 
  ON  MO.PERSONNEL_ID = SSC.PERSONNEL_ID AND (SSC.DATE_HIRING_END >= MO.StartDate AND SSC.DATE_HIRING_END <= EndDateOrder.DATE_TO)
  GROUP BY MO.ORG_ID, MO.PERSONNEL_ID, MO.PROFILE_ID, MO.RefID, MO.StartDate, EndDateOrder.DATE_TO)
, CTE_EmployeeWorkingPeriods AS 
( SELECT CTEO.ORG_ID, CTEO.PERSONNEL_ID, CTEO.PROFILE_ID, CTEO.RefID, CTEO.StartDate
  , IF(min(CTEO.StopCooperation) > 0 AND min(OrderInfO.StartDate)> 0 AND min(CTEO.StopCooperation) <= min(OrderInfO.StartDate) AND min(CTEO.StopCooperation) <= min(CTEO.EndDate), min(CTEO.StopCooperation) - 864000000000, IF(min(CTEO.StopCooperation) > 0 AND min(OrderInfO.StartDate)> 0 AND min(OrderInfO.StartDate) < min(CTEO.StopCooperation) AND min(OrderInfO.StartDate) <= min(CTEO.EndDate), min(OrderInfO.StartDate) - 864000000000, IF(min(CTEO.StopCooperation) > 0  AND min(CTEO.StopCooperation) <= min(CTEO.EndDate) , min(CTEO.StopCooperation) - 864000000000, IF(min(OrderInfO.StartDate)> 0 AND min(OrderInfO.StartDate) <= min(CTEO.EndDate), min(OrderInfO.StartDate) - 864000000000, min(CTEO.EndDate))))) EndDate
  FROM CTE_OrderInfo CTEO
  LEFT JOIN CTE_OrderInfo OrderInfo
  ON CTEO.PERSONNEL_ID = OrderInfO.PERSONNEL_ID AND OrderInfO.RefID > CTEO.RefID
  AND ((OrderInfO.StartDate >= CTEO.StartDate  AND OrderInfO.EndDate <= CTEO.EndDate) OR (OrderInfO.StartDate >= CTEO.StartDate AND OrderInfO.StartDate <= CTEO.EndDate) OR (OrderInfO.EndDate >= CTEO.StartDate AND OrderInfO.EndDate <= CTEO.EndDate) OR (OrderInfO.StartDate <= CTEO.StartDate AND OrderInfO.EndDate >= CTEO.EndDate))
  GROUP BY CTEO.ORG_ID, CTEO.PERSONNEL_ID, CTEO.PROFILE_ID, CTEO.RefID, CTEO.StartDate)
, CTE_Date AS
( SELECT MIN(DATEKEY) MinDate , MAX(DATEKEY) MaxDate , IF(? = 4, JYEAR, GYEAR) YEAR, IF(? = 4, JMONTH, GMONTH) MONTH
  FROM report_dimdate
  -- WHERE DATEKEY >= 113288544000000000 AND DATEKEY <= 133552800000000000
  GROUP BY YEAR, MONTH
)
, CTE_CalculateCountMonth AS
( SELECT ORG_ID, PERSONNEL_ID, PROFILE_ID, YEAR, MONTH
  FROM CTE_EmployeeWorkingPeriods
  LEFT JOIN CTE_Date RDS
  ON ((StartDate >= MinDate  AND EndDate <= MaxDate) OR (StartDate >= MinDate AND StartDate <= MaxDate) OR (EndDate >= MinDate AND EndDate <= MaxDate) OR (StartDate <= MinDate AND EndDate >= MaxDate))
  GROUP BY ORG_ID, PERSONNEL_ID, PROFILE_ID, YEAR, MONTH
)
, CTE_RESULT AS (
SELECT CCM.ORG_ID, CCM.PERSONNEL_ID, CCM.PROFILE_ID, Count(CCM.MONTH) AS MonthCount, IF(BIRTHDAY> 0 ,ROUND((? - ifnull(PUI.BIRTHDAY,0)) / 315360000000000),0) AS AGE
FROM CTE_CalculateCountMonth CCM
JOIN PROFILE_USER_INFO PUI ON PUI.ID= CCM.PROFILE_ID
GROUP BY CCM.ORG_ID, CCM.PERSONNEL_ID, CCM.PROFILE_ID
 HAVING MonthCount < 12
)
SELECT
    '<25' AS NAME,
    ROUND(COALESCE(SUM(CASE WHEN AGE < 25 THEN 1 ELSE 0 END) / COUNT(*) * 100,0),2) AS Y
FROM CTE_RESULT
UNION ALL
SELECT
    '25-35' AS NAME,
    ROUND(COALESCE(SUM(CASE WHEN AGE >= 25 AND AGE < 35 THEN 1 ELSE 0 END) / COUNT(*) * 100,0),2) AS Y
FROM CTE_RESULT
UNION ALL
SELECT
    '35-45' AS NAME,
    ROUND(COALESCE(SUM(CASE WHEN AGE >= 35 AND AGE < 45 THEN 1 ELSE 0 END) / COUNT(*) * 100,0),2) AS Y
FROM CTE_RESULT
UNION ALL
SELECT
    '45-55' AS NAME,
    ROUND(COALESCE(SUM(CASE WHEN AGE >= 45 AND AGE < 55 THEN 1 ELSE 0 END) / COUNT(*) * 100,0),2) AS Y
FROM CTE_RESULT
UNION ALL
SELECT
    '>55' AS NAME,
    ROUND(COALESCE(SUM(CASE WHEN AGE >= 55 THEN 1 ELSE 0 END) / COUNT(*) * 100,0),2) AS Y
FROM CTE_RESULT ) TMP;
   ]];
  
local res1 =  getQueryResponse(str_query  , {math.floor(org_id), math.floor(lang_id), math.floor(lang_id), string.format("%.0f", time.current())});

local res = teamyar.run_command("2/res_bot",{
    id = "hr_quit_the_job_by_age_group",
    tpl_name = "chart",
    title = "NOTICES_DURING_FIRST_YEAR_BY_AGE_GROUP",
    script='',
    data= [[()=>{ 
    var data = ]] .. res1 .. [[;

  
    return {
    chart: {
        type: 'column'
    },
    title: {
        align: 'left',
        text: '' // ty__main.botGetlang("NOTICES_DURING_FIRST_YEAR_BY_AGE_GROUP")
    },
    subtitle: {
        align: 'left',
       // text: 'Click the columns to view versions. Source: <a href="http://statcounter.com" target="_blank">statcounter.com</a>'
    },
    accessibility: {
        announceNewData: {
            enabled: true
        }
    },
    xAxis: {
        type: 'category'
    },
    yAxis: {
        title: {
            text: ''
        }

    },
    legend: {
        enabled: false
    },
    plotOptions: {
        series: {
            borderWidth: 0,
            dataLabels: {
                enabled: true,
                format: '{point.y:.1f}%'
            }
        }
    },

    tooltip: {
        headerFormat: '<span style="font-size:11px">{series.name}</span><br>',
        pointFormat: '<span style="color:{point.color}">{point.name}</span>: <b>{point.y:.2f}%</b> of total<br/>'
    },

    series: [
        {
            name: '',//'Browsers',
            colorByPoint: true,
            data: data
        }
    ]
}
}]]
    
});


teamyar.write_result(res);