local input = teamyar.get_input()
local name = input.name
local last_name = input.last_name
local mobile = input.mobile
local product_code = input.product_code
local stock_code = input.stock_code
local sales_center_code = input.sales_center_code
local attribute_id = input.attribute_id
local factor_title = input.factor_title
local quantity = input.quantity
local unit_id = input.unit_id
local fee = input.fee



local day = time.get_day(time.current());
local month = time.get_month(time.current());
local year = time.get_year(time.current());
local min = time.get_minute(time.current());
local hour = time.get_hour(time.current());
local sec = time.get_second(time.current());
local temp_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":]]..hour..[[,"minute":]]..min..[[,"second":]]..sec..[[}]])
currentdate = string.format("%18.0f", temp_time);
local date_input=currentdate
-------------------------------------------
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
-----------------------------------------------------------------------
function getDateFileTime(date)
  local dateFile = 0 
  dateFile = queryResult([[]],{})
  teamyar.write_log(dateFile)
  return dateFile
end 
-----------------------------------------------------------------------
local info = {
  section_id=5,
	profile = {
		name =  name,
		mobile = {
			{
				value = mobile,
				country = 364
			}
  		},
		last_name = last_name
	}
}
local res_client = teamyar.call_api(14 , "/api/client/create" , info);
local factor_info = {
     invoice = {
		title = factor_title ,
		type = 1,
		run_date = json.decode( date_input) ,
        client_mobile = tostring(mobile) ,
        client_name = name.." "..last_name ,
		payment_type = 3,
		sales_center_code = sales_center_code ,
		symbol_name = "IRR" ,
        client_parent = "01001"
    },
  products = {
		{
        stock_code = stock_code,
		product_code = product_code ,
        attribute_id =json.decode( attribute_id),
        quantity = quantity ,
        unit_id = tostring(unit_id) ,
		symbol_rate = "1" ,
		fee = fee 
		} 
	}
}
local res_factor = teamyar.call_api(23 , "/api/invoice/create" , factor_info);
teamyar.write_result("date sh:"..date_input.."result client:   "..json.encode(res_client).." result factor:   "..json.encode(res_factor))