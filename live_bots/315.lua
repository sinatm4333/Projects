--Bot WhereHouse Conflict zmo
input = teamyar.get_input();
local user_info = teamyar.get_user_info();
local user_id = math.floor(user_info["id"]); 
local org_id = input.org_id;
if org_id == nil then
  org_id=0;
end
local mali_year= input.mali_yr

---------------------------------------------
function loadData()
  local data = teamyar.get_data("wc_data")
  teamyar.write_result(data. value);
end
  --------------------------------
function queryResult(select_query,user_param)
  db.use_db("0000000");
    local params1 = {
      query = select_query,
      params = user_param
  }
  db.query(params1);
  local res_text = db.query_fetch();
  db.query_free();
  if res_text==nil then
    return nil;
  else
  return res_text[1];
  end
end
----------------------
function orgAcl(data)
  local query_param = [[ SELECT JSON_ARRAYAGG(JSON_OBJECT('id',id, 'name',name, 'type',1))
  										from (select id,name from org_info ]]
 if data.search ~= nil and #data.search > 0 then
     query_param = query_param..[[  where name like N'%]]..data.search..[[%') as p ]]
  else
	query_param = query_param .. [[) p ]]
  end
query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);   
teamyar.write_result(queryResult(query_param, {}));
end
----------------------
function maliYearAcl(data)
  local geted_org_id = data.org_id;
  local query_param = [[ SELECT JSON_ARRAYAGG(JSON_OBJECT('id',i, 'name',n, 'type',1))
                                      from (select id i,title n from pa_fiscal_year where 1=1]]
  if geted_org_id~0 then 
   	query_param =query_param..[[ and org_id=]]..geted_org_id
  end 
    if data.search ~= nil and #data.search > 0 then
     query_param = query_param ..  [[ and name like N'%]]..data.search..[[%'  ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count)..[[)tmp ]];   
  teamyar.write_result(queryResult(query_param , {}));
end
-----------------------------------------------
function WidgetTemplate()  
  local random = math.random(1,1000);
  local script =  teamyar.get_attachment("main.js");
  local css =  teamyar.get_attachment("main.css");
  local  str_lang="";
  if user_info.lang_id == 4 then
    str_lang = teamyar.get_attachment("Persian.js");
  else
     str_lang = teamyar.get_attachment("English.js");
  end
  local template = teamyar.run_command("2/res_bot",{
      id = "bot_wherehouse_conflict",
      tpl_name = "html",
      title = "BOT_WHEREHOUSE_CONFLICT",
      body = "<div id=\\'wc_holder_body_html_"..random.."\\'></div>",
      script = [[
                  (function(){
                  ]]..str_lang..[[      
                  var holder_id = '#wc_holder_body_html_]]..random..[[';
                var random_id = ]] .. random .. [[;
                  ]]..script..[[
    })();
      ]],
      css = css
    });
  teamyar.write_result(template); 
end
---------------------main
if input.type == 3 then 
   loadData()
elseif input.type == 2 then 
  orgAcl(input.data)
    elseif  input.type == 5 then 
  maliYearAcl(input.data)
elseif input.type == 1 then 
  local chash_data = {wc_org_id = org_id, wc_gn = input.gn,wc_mali_yr = mali_year, wc_mali_yr_n = input.mali_yr_n}
  teamyar.set_data("wc_data", json.encode(chash_data));
  local mali_year2= queryResult([[ select id,title from pa_fiscal_year where id<]]..mali_year..[[ order by id desc limit 1]],{})
  local cte_str=  [[  WITH CTE_DET AS 
                              ( 
                                  SELECT OD.PRODUCT_ID, OD.ATTRIBUTE_ID, OD.STOCK_ID, OD.TYPE, OD.QUANTITY
                                  FROM		 WH_OPERATION_DETAILS OD 
                                  INNER JOIN WH_OPERATION O ON O.ID = OD.OPERATION_ID 
                                  WHERE OD.OPERATION_ID >= 0 AND O.ORG_ID =]]..org_id..[[ AND OD.QUANTITY >= 0 AND O.DELETED = 0 ]]
   if mali_year ~= nill and mali_year ~= 0 then 
     	cte_str = cte_str..[[ and (select id from pa_fiscal_year where  O.DATE_OPERATION > start_date and  O.DATE_OPERATION< end_date limit 1)=]]..mali_year
  end 
  cte_str = cte_str..[[ and OD.IS_BACK = 0 AND O.OPERATION_STATUS>0 
                                        ), CTE_SUM_QUANTITY_IN AS ( 
                                            SELECT  PRODUCT_ID, ATTRIBUTE_ID, STOCK_ID, SUM(QUANTITY) AS QUANTITY_IN
                                            FROM		 CTE_DET 
                                            WHERE TYPE = 1 
                                            GROUP BY PRODUCT_ID, ATTRIBUTE_ID, STOCK_ID 
                                        ), CTE_SUM_QUANTITY_OUT AS ( 
                                            SELECT  PRODUCT_ID, ATTRIBUTE_ID, STOCK_ID, SUM(QUANTITY) AS QUANTITY_OUT
                                            FROM		 CTE_DET 
                                            WHERE TYPE = 2 
                                            GROUP BY PRODUCT_ID, ATTRIBUTE_ID, STOCK_ID 
                                        ), CTE_RESULT_QUANTITY AS ( 
                                            SELECT I.PRODUCT_ID, I.ATTRIBUTE_ID, I.STOCK_ID, 
                                            (I.QUANTITY_IN - IF(O.QUANTITY_OUT IS NOT NULL, O.QUANTITY_OUT, 0)) AS REMAIND_QUANTITY
                                            FROM  CTE_SUM_QUANTITY_IN I 
                                            LEFT JOIN CTE_SUM_QUANTITY_OUT O ON I.PRODUCT_ID = O.PRODUCT_ID AND I.ATTRIBUTE_ID = O.ATTRIBUTE_ID AND I.STOCK_ID = O.STOCK_ID
                                        ), CTE_INIT AS (
                                            SELECT OD.PRODUCT_ID, OD.ATTRIBUTE_ID, OD.STOCK_ID, OD.QUANTITY AS INIT_QUANTITY
                                            FROM		 WH_OPERATION_DETAILS OD 
                                            INNER JOIN WH_OPERATION O ON O.ID = OD.OPERATION_ID 
                                            WHERE OD.OPERATION_ID >= 0 AND O.ORG_ID = ]]..org_id..[[ AND OD.QUANTITY >= 0 AND O.DELETED = 0  ]]
  if mali_year2 ~= nill and mali_year2 ~= 0 then 
     	cte_str = cte_str..[[ and (select id from pa_fiscal_year where  O.DATE_OPERATION > start_date and  O.DATE_OPERATION< end_date limit 1)=]]..mali_year2
  end 
 cte_str = cte_str.. [[ and OD.IS_BACK = 0 AND O.OPERATION_STATUS>0 AND O.OPERATION_TYPE = 5
                                    )]]
 local   qselect= [[  SELECT (select name from WH_PRODUCT where id=CI.PRODUCT_ID) PRODUCT_ID, CI.ATTRIBUTE_ID,
  (select name  from wh_stock where id=CI.STOCK_ID) STOCK_ID,
                            CI.INIT_QUANTITY , RQ.REMAIND_QUANTITY, P.FULL_CODE, P.FULL_NAME, S.FULL_CODE FULL_CODE2, S.NAME
                            FROM CTE_INIT CI
                            JOIN CTE_RESULT_QUANTITY RQ ON  CI.PRODUCT_ID = RQ.PRODUCT_ID AND CI.ATTRIBUTE_ID = RQ.ATTRIBUTE_ID AND CI.STOCK_ID = RQ.STOCK_ID
                            JOIN WH_PRODUCT P ON P.ID = CI.PRODUCT_ID
                            JOIN WH_STOCK S ON S.ID = CI.STOCK_ID
                            WHERE CI.INIT_QUANTITY - RQ.REMAIND_QUANTITY != 0  ]]  

  res_data = queryResult(cte_str..[[  SELECT JSON_ARRAYAGG(JSON_OBJECT('PRODUCT_ID',PRODUCT_ID, 'ATTRIBUTE_ID',ATTRIBUTE_ID, 'STOCK_ID',STOCK_ID,'INIT_QUANTITY'
  ,INIT_QUANTITY,'REMAIND_QUANTITY',REMAIND_QUANTITY,'FULL_CODE',FULL_CODE,'FULL_NAME',FULL_NAME,'FULL_CODE2',FULL_CODE2,'NAME',NAME)) 
  from (]]..qselect..[[)oo ]] , {input.from, input.count})

    -------------------
  local qtotal =[[ select count(*) c from  ( ]]..qselect..[[)as t]]
    teamyar.write_log(cte_str..qtotal)
  local  total= queryResult(cte_str..qtotal, {})
  if total ==nil then
    total=0
  end
  data = {from = input.from, count = input.count, data = res_data, total = total}
 teamyar.write_log(json.encode(data))
  teamyar.write_result(json.encode(data))
else
	WidgetTemplate()
end
