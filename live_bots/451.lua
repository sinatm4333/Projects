--local input = teamyar.get_input() 
--local hcinvoicenumber = input.hcinvoicenumber 
--teamyar.write_result(hcinvoicenumber) 
local sqlquery = "select sales_invoice.TITLE,count(sales_invoice.id) as cnt from sales_invoice where DELETED=0 having count(sales_invoice.id)>1" 
--teamyar.write_result(sqlquery) ------------------------------------------- 
local paramParrent = { query =sqlquery, param = { } } 
--teamyar.write_result("select code from wh_product where full_name like '%'"..productname.."%'") 
local result = {} 
db.query(paramParrent) 
local record = {} while db.query_fetch(record) do 
  table.insert(result, { TeamyarInvoiceID = record[0], TeamyarInvoiceNumber = tonumber(record[1])}) end 
db.query_free() 
local jsonResult = json.encode(result) 
teamyar.write_result(jsonResult)