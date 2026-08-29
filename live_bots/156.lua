  input = teamyar.get_input();


function res_querycustomer()
  
  local category_id = input["category_id"]
  local page =  (input["page"]*10) -10

local query={query="WITH LastCommentId AS (SELECT MAX(ID) ID, CLIENT_ID FROM CRM_HISTORY WHERE TYPE=1 AND AUTHOR_ID>10000 GROUP BY CLIENT_ID ),RankedRecords AS (SELECT IF(JSON_EXTRACT(FORM_DATA, '$.deal_amount') IS NULL, 0,CAST(JSON_EXTRACT(FORM_DATA,'$.deal_amount') AS UNSIGNED)) AS deal_amount, ifnull(JSON_EXTRACT(FORM_DATA, '$.deal_name'), '') AS deal_name,ifnull(JSON_EXTRACT(FORM_DATA, '$.number_line'), '') AS number_line,SUBSTRING_INDEX(SUBSTRING_INDEX(`note`, '>', -2),'<', 1) AS text_content,ci.id AS id_customer, ci.COMPANY, ci.NUMBER_PERSONNEL,ci.WEBSAITE,ci.ISSUE_ACTIVITY,GROUP_CONCAT(pmo.MOBILE) AS MOBILE,cs.ID AS SECTION_ID, cs.SECTION_NAME, ccp.id AS id_category,ccp.name AS category_name, pm.FULLNAME,pui.USER_TYPE ,CreateDate.JNDATE AS CREATE_DATE,ModifiedDate.JNDATE AS MODIFIED_DATE FROM profile_main AS pm INNER JOIN crm_info AS ci ON pm.id = ci.id  INNER JOIN profile_user_info AS pui on ci.id=pui.id  INNER JOIN crm_cross AS cc ON ci.ID = cc.CLIENT_ID INNER JOIN crm_classify_person AS ccp ON cc.REFERE_ID = ccp.PROFILE_ID INNER JOIN crm_section AS cs ON ccp.SECTION_ID = cs.ID left JOIN crm_custom_form ccf ON ccf.SECTION_ID=cs.ID and ccf.CLIENT_ID=ci.ID INNER JOIN report_dimdate AS CreateDate ON CreateDate.DATEKEY = ci.CREATE_DATE - MOD(ci.CREATE_DATE, 864000000000) INNER JOIN report_dimdate AS ModifiedDate ON ModifiedDate.DATEKEY = ci.MODIFIED_DATE - MOD(ci.MODIFIED_DATE, 864000000000) left join profile_mobile as pmo on pmo.USER_ID=pm.id left join LastCommentId as lc on lc.CLIENT_ID= ci.id left join CRM_HISTORY ch on ch.ID=lc.ID WHERE ci.deleted = 0 and ccp.id=? GROUP BY deal_amount,deal_name,number_line,text_content,ci.id,ci.COMPANY,ci.NUMBER_PERSONNEL,ci.WEBSAITE,ci.ISSUE_ACTIVITY,cs.ID,cs.SECTION_NAME,ccp.id,ccp.name,pm.FULLNAME,CreateDate.JNDATE,ModifiedDate.JNDATE ORDER BY ci.MODIFIED_DATE DESC limit ? ,10) SELECT   id_customer,  SECTION_ID, SECTION_NAME, id_category,category_name, FULLNAME, CREATE_DATE, MODIFIED_DATE , COMPANY,WEBSAITE,ISSUE_ACTIVITY,MOBILE,deal_amount,Deal_Name,NUMBER_PERSONNEL,number_line,text_content,USER_TYPE  FROM RankedRecords;",params={category_id, page}} 

  db.query(query);
   local result= {}
   local Out_Query={}
   while db.query_fetch(result) do
      Out_Query[#Out_Query+1] = {ID_CUSTOMER=result[1],SECTION_ID=result[2],SECTION_NAME=result[3],ID_CATEGORY=result[4],CATEGORY_NAME=result[5],FULLNAME=result[6],CREATE_DATE=result[7],MODIFIED_DATE=result[8],COMPANY=result[9],WEBSAITE=result[10],ISSUE_ACTIVITY=result[11],MOBILE=result[12],DEAL_AMOUNT=result[13],DEAL_NAME=result[14],NUMBER_PERSONNEL=result[15],NUMBER_LINE=result[16],COMMENT=result[17],USER_TYPE=result[18]};
   end
  
   db.query_free();
  
 teamyar.write_result(json.encode(Out_Query))
  
  
  if #Out_Query > 0 then
    return Out_Query
  end
  return {}
end

 res_querycustomer()
