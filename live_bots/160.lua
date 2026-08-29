  input = teamyar.get_input();



function res_querycustomer()
   local SECTION_ID =input['SECTION_ID'] 
  
    local query= { query= [[ WITH LastCommentId AS ( SELECT MAX(ID) AS ID, CLIENT_ID FROM CRM_HISTORY WHERE TYPE = 1 
    AND AUTHOR_ID > 10000 GROUP BY CLIENT_ID), RankedRecords AS ( SELECT ROW_NUMBER() 
    OVER (PARTITION BY ccp.id ORDER BY ci.MODIFIED_DATE DESC) AS rn, COALESCE(CAST(JSON_UNQUOTE(JSON_EXTRACT(FORM_DATA, '$.deal_amount')) AS UNSIGNED), 0) AS deal_amount,
    COALESCE(JSON_UNQUOTE(JSON_EXTRACT(FORM_DATA, '$.deal_name')), '') AS deal_name,
    COALESCE(JSON_UNQUOTE(JSON_EXTRACT(FORM_DATA, '$.number_line')), '') AS number_line,
    SUBSTRING_INDEX(SUBSTRING_INDEX(`note`, '>', -2), '<', 1) AS text_content, ci.id AS id_customer, ci.COMPANY,
    ci.NUMBER_PERSONNEL, ci.WEBSAITE, ci.ISSUE_ACTIVITY, SUBSTRING_INDEX(GROUP_CONCAT(pmo.MOBILE 
    ORDER BY ci.MODIFIED_DATE DESC SEPARATOR '|'), '|', 1) AS MOBILE, cs.ID AS SECTION_ID, cs.SECTION_NAME,
    ccp.id AS id_category, ccp.name AS category_name, pm.FULLNAME, pui.USER_TYPE, CreateDate.JNDATE AS CREATE_DATE,
    ModifiedDate.JNDATE AS MODIFIED_DATE FROM crm_info ci INNER JOIN profile_main pm ON pm.id = ci.id 
    INNER JOIN profile_user_info pui ON ci.id = pui.id INNER JOIN crm_cross cc ON ci.ID = cc.CLIENT_ID INNER JOIN crm_classify_person ccp
    ON cc.REFERE_ID = ccp.PROFILE_ID INNER JOIN crm_section cs ON ccp.SECTION_ID = cs.ID LEFT JOIN crm_custom_form ccf 
    ON ccf.SECTION_ID = cs.ID AND ccf.CLIENT_ID = ci.ID LEFT JOIN report_dimdate CreateDate ON 
    CreateDate.DATEKEY = ci.CREATE_DATE - MOD(ci.CREATE_DATE, 864000000000) LEFT JOIN 
    report_dimdate ModifiedDate ON ModifiedDate.DATEKEY = ci.MODIFIED_DATE - MOD(ci.MODIFIED_DATE, 864000000000) LEFT JOIN 
    profile_mobile pmo ON pmo.USER_ID = pm.id LEFT JOIN LastCommentId lc ON lc.CLIENT_ID = ci.id LEFT JOIN CRM_HISTORY ch ON ch.ID = lc.ID WHERE
    ci.deleted = 0 AND cs.id = ? GROUP BY ci.id, cs.id, ccp.id, pm.FULLNAME, CreateDate.JNDATE, ModifiedDate.JNDATE)SELECT id_customer, 
    SECTION_ID, SECTION_NAME, id_category, category_name, FULLNAME, CREATE_DATE, MODIFIED_DATE, COMPANY, WEBSAITE, ISSUE_ACTIVITY,
    MOBILE, deal_amount, Deal_Name, NUMBER_PERSONNEL, number_line, text_content, 
    USER_TYPE FROM RankedRecords WHERE rn <= 10;]], params={SECTION_ID}}

  
  
  
  
-- local query= { query= " WITH LastCommentId AS (SELECT MAX(ID) ID, CLIENT_ID FROM CRM_HISTORY WHERE TYPE=1 AND AUTHOR_ID>10000 GROUP BY CLIENT_ID), RankedRecords AS (SELECT ROW_NUMBER() OVER(PARTITION BY ccp.id ORDER BY ci.MODIFIED_DATE DESC) as rn, IF(JSON_EXTRACT(FORM_DATA, '$.deal_amount') IS NULL, 0, CAST(JSON_EXTRACT(FORM_DATA,'$.deal_amount') AS UNSIGNED)) AS deal_amount, ifnull(JSON_EXTRACT(FORM_DATA, '$.deal_name'), '') AS deal_name, ifnull(JSON_EXTRACT(FORM_DATA, '$.number_line'), '') AS number_line, SUBSTRING_INDEX(SUBSTRING_INDEX(`note`, '>', -2),'<', 1) AS text_content, ci.id AS id_customer, ci.COMPANY, ci.NUMBER_PERSONNEL, ci.WEBSAITE, ci.ISSUE_ACTIVITY, SUBSTRING_INDEX(GROUP_CONCAT(pmo.MOBILE ORDER BY ci.MODIFIED_DATE DESC SEPARATOR '|'), '|', 1) AS MOBILE, cs.ID AS SECTION_ID, cs.SECTION_NAME, ccp.id AS id_category, ccp.name AS category_name, pm.FULLNAME, pui.USER_TYPE, CreateDate.JNDATE AS CREATE_DATE, ModifiedDate.JNDATE AS MODIFIED_DATE FROM profile_main AS pm INNER JOIN crm_info AS ci ON pm.id = ci.id INNER JOIN profile_user_info AS pui on ci.id=pui.id INNER JOIN crm_cross AS cc ON ci.ID = cc.CLIENT_ID INNER JOIN crm_classify_person AS ccp ON cc.REFERE_ID = ccp.PROFILE_ID INNER JOIN crm_section AS cs ON ccp.SECTION_ID = cs.ID LEFT JOIN crm_custom_form ccf ON ccf.SECTION_ID=cs.ID and ccf.CLIENT_ID=ci.ID INNER JOIN report_dimdate AS CreateDate ON CreateDate.DATEKEY = ci.CREATE_DATE - MOD(ci.CREATE_DATE, 864000000000) INNER JOIN report_dimdate AS ModifiedDate ON ModifiedDate.DATEKEY = ci.MODIFIED_DATE - MOD(ci.MODIFIED_DATE, 864000000000) LEFT JOIN profile_mobile as pmo on pmo.USER_ID=pm.id LEFT JOIN LastCommentId as lc on lc.CLIENT_ID= ci.id LEFT JOIN CRM_HISTORY ch on ch.ID=lc.ID WHERE ci.deleted = 0 and cs.id=? GROUP BY deal_amount, deal_name, number_line, text_content, ci.id, ci.COMPANY, ci.NUMBER_PERSONNEL, ci.WEBSAITE, ci.ISSUE_ACTIVITY, cs.ID, cs.SECTION_NAME, ccp.id, ccp.name, pm.FULLNAME, CreateDate.JNDATE, ModifiedDate.JNDATE ) SELECT   id_customer,  SECTION_ID, SECTION_NAME, id_category,category_name, FULLNAME, CREATE_DATE, MODIFIED_DATE , COMPANY,WEBSAITE,ISSUE_ACTIVITY,MOBILE,deal_amount,Deal_Name,NUMBER_PERSONNEL,number_line,text_content,USER_TYPE  FROM RankedRecords WHERE rn <= 10;", params={SECTION_ID}}

 teamyar.write_log("query1----"..json.encode(query.query))
     db.query(query);
   local result= {}
   local Out_Query={}
   while db.query_fetch(result) do
      Out_Query[#Out_Query+1] = {ID_CUSTOMER=result[1],SECTION_ID=result[2],SECTION_NAME=result[3],ID_CATEGORY=result[4],CATEGORY_NAME=result[5],FULLNAME=result[6],CREATE_DATE=result[7],MODIFIED_DATE=result[8],COMPANY=result[9],WEBSAITE=result[10],ISSUE_ACTIVITY=result[11],MOBILE=result[12],DEAL_AMOUNT=result[13],DEAL_NAME=result[14],NUMBER_PERSONNEL=result[15],NUMBER_LINE=result[16],COMMENT=result[17],USER_TYPE=result[18]};
   end
  
   db.query_free();
  
 -- teamyar.write_result(json.encode(Out_Query))
  
  
  
  
  --params=string.format(query,SECTION_ID)
  --local Out_Query= teamyar.query(context,params)
  
  if #Out_Query>0 then
        return Out_Query;
  end
      return {}
end

function CategoryCount()
   local SECTION_ID =input['SECTION_ID']  
   local query={query=" with cat_count as(select ANY_VALUE(ccp.ID) ID, count(*) count from crm_cross cc join crm_classify_person ccp on ccp.PROFILE_ID=cc.REFERE_ID join crm_info ci on ci.id=cc.CLIENT_ID where ci.deleted=0 and ccp.SECTION_ID = ? group by ccp.PROFILE_ID) select   ID, count from cat_count;",params={SECTION_ID}}
 teamyar.write_log("query2----"..json.encode(query))
      db.query(query);
   local result= {}
   local Out_Query={}
   while db.query_fetch(result) do
      Out_Query[#Out_Query+1] = {category_id=result[1],count=result[2]};
   end
  
   db.query_free();
  
 -- teamyar.write_result(json.encode(Out_Query))
  
  --params=string.format(query,SECTION_ID)
  --local Out_Query= teamyar.query(context,params)
     if #Out_Query>0 then
        return Out_Query;
  end
      return {0}
end


function AmountCount()
   local SECTION_ID =input['SECTION_ID']  
  --local query= [[{"query":" WITH cat_count AS (SELECT ANY_VALUE(ccp.ID) AS ID,SUM(IF(JSON_EXTRACT(FORM_DATA, '$.deal_amount') IS NULL,0, CAST(JSON_EXTRACT(FORM_DATA, '$.deal_amount') AS UNSIGNED))) AS amount , COUNT(*) AS count FROM crm_cross cc JOIN crm_classify_person ccp ON ccp.PROFILE_ID = cc.REFERE_ID JOIN crm_info ci ON ci.id = cc.CLIENT_ID JOIN crm_section AS cs ON ccp.SECTION_ID = cs.id left JOIN crm_custom_form AS ccf ON ccf.CLIENT_ID = ci.ID WHERE ci.deleted = 0 AND ccp.SECTION_ID = ? GROUP BY ccp.PROFILE_ID) select JSON_ARRAYAGG(JSON_OBJECT( 'category_id', ID, 'amount', amount)) from cat_count;","params":["%d"]}]] 
  local query= {query=" WITH cat_count AS  (SELECT ANY_VALUE(ccp.ID) AS ID, GREATEST(SUM(IF(JSON_EXTRACT(FORM_DATA, '$.deal_amount') IS NULL,0, CAST(JSON_EXTRACT(FORM_DATA, '$.deal_amount') AS UNSIGNED))), 0) AS amount ,  COUNT(*) AS count FROM crm_cross cc JOIN crm_classify_person ccp ON ccp.PROFILE_ID = cc.REFERE_ID JOIN crm_info ci ON ci.id = cc.CLIENT_ID JOIN crm_section AS cs ON ccp.SECTION_ID = cs.id left JOIN crm_custom_form AS ccf ON ccf.CLIENT_ID = ci.ID WHERE ci.deleted = 0 AND ccp.SECTION_ID = ? GROUP BY ccp.PROFILE_ID) select  ID , amount from cat_count;",params={SECTION_ID}}

 
   teamyar.write_log("query3----"..json.encode(query))
      db.query(query);
   local result= {}
   local Out_Query={}
   while db.query_fetch(result) do
      Out_Query[#Out_Query+1] = {category_id=result[1],amount=result[2]};
   end
  
   db.query_free();
  
 -- teamyar.write_result(json.encode(Out_Query))
  
  --params=string.format(query,SECTION_ID)
 -- local Out_Query= teamyar.query(context,params)
     if #Out_Query>0 then
        return Out_Query;
  end
      return {0}
end

 -- res_querycustomer()
 -- teamyar.write_result(context,res_querycustomer)
teamyar.write_result(json.encode({list=res_querycustomer(),count=CategoryCount(),amount=AmountCount()}))
