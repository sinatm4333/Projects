local config = teamyar.get_config()
local config_data = {}
local c_account_code = 0
local c_client_code = 0
local c_float_code = 0
local c_center_code = 0
local c_project_code = 0
local c_kind = 0 
local c_day_befor = 0 
local c_org_id = 0
if config ~= nil then 
  config_data = config.data
  c_account_code = config_data.account_code
  c_client_code = config_data.client_code
  c_float_code = config_data.float_code
  c_center_code = config_data.center_code
  c_project_code = config_data.project_code
  c_kind = config_data.kind
  c_day_befor = config_data.day_befor
  c_org_id=config_data.org_id
end 
local day = time.get_day(time.current());
local month = time.get_month(time.current());
local year = time.get_year(time.current());
local hour = time.get_hour(time.current());
local min = time.get_minute (time.current());
local sec = time.get_second(time.current());
local currentdate_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":]]..hour..[[,"minute":]]..min..[[,"second":]]..sec..[[}]])
local temp_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":0,"minute":0,"second":0}]])
local currentdate = string.format("%18.0f" ,temp_time);
local from_date = string.format("%18.0f" ,(temp_time -    ((60*60*24*10000000*c_day_befor)+(60*60*24*10000000))    ))
local to_date = currentdate+(60*60*3*10000000)
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
  return res_text[1];
end
-------------------------------------------
function queryResultFact(select_query,user_param)
  db.use_db("0000000")
  local params = {
    query = select_query,
    params = user_param
  }
  db.query(params);
  local res_text={};
  local record={};
  while db.query_fetch(record) do
    local tmp=record;
    table.insert(res_text, {id = record[1],
        org_id = record[2], 
           date = record[3], 
           amont = record[4], 
           ps_id = record[5], 
           decimal = record[6], 
           symbol_name = record[7],         
           symbol_rate = record[8], 
           client = record[9], 
           float = record[10], 
           prj = record[11], 
                  center = record[12], 
      });
  end
  db.query_free();
  return res_text;
end
-------------------------------------------------------------
local q=[[
        with DecimalDigits as( 
         select po.ORG_ID,ps.DECIMAL_COUNT DecimalCount,(CASE WHEN COALESCE(ps.FEE_DECIMAL,0) = 0 THEN COALESCE(ps.DECIMAL_COUNT,0) ELSE COALESCE(ps.FEE_DECIMAL,0) END )DigitFee
         from pa_organizations po join pa_symbols ps on(po.BASE_CURRENCY = ps.ID and po.ORG_ID = ps.ORG_ID)
         ),cte_org as(
				SELECT i.id as INVOICE_ID,d.DECIMAL_COUNT Digit, 
					CASE WHEN COALESCE(d.DECIMAL_COUNT,0) <> 0 THEN COALESCE(d.DECIMAL_COUNT,0) ELSE COALESCE(d.FEE_DECIMAL,0) END DigitFee         
					FROM PA_ORGANIZATIONS c       
					join SALES_INVOICE i on i.org_id = c.org_id
					INNER JOIN PA_SYMBOLS d ON (d.ID = c.BASE_CURRENCY AND d.ORG_ID = c.ORG_ID) 				
			) , cte_product as(
				select o.INVOICE_ID,if(Coalesce(d.QUANTITY_CONFIRMED,0)>0,Coalesce(d.QUANTITY_CONFIRMED,0),Coalesce(d.QUANTITY,0))
							as quantity,Coalesce(c.DECIMAL_NUM,0) as dec_quantity,
							Coalesce(d.BASE_SYMBOL_FEE,0) AS BASE_SYMBOL_FEE, Coalesce(o.DigitFee,0) AS DigitFee,
							Coalesce(o.Digit,0) AS Digit,Coalesce(d.BASE_SYMBOL_DISCOUNT,0) AS BASE_SYMBOL_DISCOUNT,Coalesce(d.BASE_SYM_VALUE_ADDED,0) AS BASE_SYM_VALUE_ADDED ,
							Coalesce(d.BASE_SYMBOL_TAX,0) AS BASE_SYMBOL_TAX,Coalesce(d.BASE_SYMBOL_TOLL,0) AS BASE_SYMBOL_TOLL
				from sales_invoice_product d
				join wh_product p on d.product_id = p.id
				join wh_stock_capacity c on p.CAPACITY_ID = c.ID
				join cte_org o on d.INVOICE_ID = o.INVOICE_ID
			) ,CTE_ADDITION as(

				SELECT  o.INVOICE_ID,       
				SUM(ROUND(CASE WHEN (a.EFFECT = 1 OR a.EFFECT = 3) THEN (Coalesce(a.QUANTITY,0)/POWER(10,Coalesce(o.Digit,0)))*(-1) WHEN (a.EFFECT = 2 OR a.EFFECT = 4) THEN (Coalesce(a.QUANTITY,0)/POWER(10,Coalesce(o.Digit,0))) ELSE 0 END)) AS ADDITION     
				FROM SALES_INVOICE_ADDITIONS a
				JOIN cte_org o ON a.INVOICE_ID = o.INVOICE_ID
				group by o.INVOICE_ID
			), CTE_AMOUNT_PRODUCTS AS(
				select INVOICE_ID,
				  SUM(ROUND((quantity/power(10,dec_quantity)* (BASE_SYMBOL_FEE/power(10,DigitFee))) 
				  - BASE_SYMBOL_DISCOUNT/power(10,Digit) + BASE_SYM_VALUE_ADDED/power(10,Digit) + BASE_SYMBOL_TAX/power(10,Digit) + BASE_SYMBOL_TOLL/power(10,Digit))) as AMOUNT
				from cte_product
				group by INVOICE_ID
			)  ,amonts as (
            SELECT   
						 ROUND(p.AMOUNT + Coalesce(a.ADDITION,0)) iamont ,
					 i.id id from  CTE_AMOUNT_PRODUCTS p
			LEFT JOIN CTE_ADDITION a ON p.INVOICE_ID = a.INVOICE_ID
			JOIN SALES_INVOICE i on i.ID = p.INVOICE_ID
			LEFT JOIN PA_CLIENT c on c.id = i.client_id and c.org_id = i.org_id
						)
        select distinct  i.id,i.org_id,i.RUN_DATE,(select iamont from amonts where id= i.id) amont,ps.id,FEE_DECIMAL,ps.SHORT_NAME sy_name,ps.SYMBOL_RATE,cl.code cl_code,fl.code fl_code,prj.code prj_code ,cn.code cn_code
         from sales_invoice i inner join pa_symbols ps on ps.id=i.SYMBOL_ID and ps.org_id= i.org_id left join DecimalDigits  dd on(i.ORG_ID = dd.ORG_ID) 

 left join pa_client cl on cl.id=i.client_id and i.client_id > 0 
 left join pa_floating fl on fl.id=i.FLOATING_ID
 left join pa_center cn on cn.id=i.SALES_CENTER 
 left join pa_project prj on prj.id=i.project_id
         where  i.status= 2 and i.org_id=]]..c_org_id..[[  and ps.org_id=]]..c_org_id..[[  and i.id not in (select INVOICE_ID from sales_invoice_settlement) and i.type=1
          and i.RUN_DATE >=]]..from_date..[[  and i.RUN_DATE<=]]..to_date
teamyar.write_log(q)
local compelete_factors = queryResultFact(q,{})
--local acc_code =queryResult( [[select code from pa_account where org_id=]]..c_org_id..[[ and  id=]]..c_account_id,{})
if #compelete_factors == 0 then
  teamyar.write_result(" فاکتوری در این بازه زمان و در حال اجرا یافت نشد")
end 
local res_str_settelment =""
for i,v in ipairs(compelete_factors) do 
  local info_settelment = {
	org_id=tonumber( c_org_id),
	invoice_id= tonumber(v.id),
	settlements={
		{
			date= v.date,
			type= c_kind,
			price= tostring(v.amont) ,
			center_code= c_center_code,
			client_code= c_client_code,
			symbol_name= v.symbol_name,
			symbol_rate="1",-- , v.symbol_rate,
			account_code= c_account_code,
			project_code= c_project_code,
			floating_code= c_float_code
		}
    }
}
    teamyar.write_log("info_settelment----"..json.encode(info_settelment))
  local res_settelment =  teamyar.call_api(23, '/api/sales/create_settlement', info_settelment);
  teamyar.write_log("res_settelment----"..json.encode(res_settelment))
  res_str_settelment=res_str_settelment.."  "..v.id.."/".. json.encode(res_settelment).."</br>"
        local info_log =  {
        org_id = c_org_id,
        history = "ثبت تسویه در فاکتور توسط بات" ,
        invoice_id = tonumber(v.id)
      }
      local   res_log = teamyar.call_api(23,  '/api/sales/update_invoice_history', info_log);
    teamyar.write_log("res_log---"..json.encode(res_log))
end 
  teamyar.write_result(res_str_settelment)