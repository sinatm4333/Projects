local input = teamyar.get_input()
local productid = input.productid
-------------------------------------------
local paramParrent = {
    query = "select full_code,name from wh_product where id ="..productid,
    param = { productid}
}

local resultParrent = {}
db.query(paramParrent)
local recordParrent =  db.query_fetch(recordParrent)

db.query_free()

local productcode = recordParrent[1]

if recordParrent == nil or recordParrent == ''
then
 teamyar.write_result("")
else
  teamyar.write_result("{ProductCode:"..json.encode(recordParrent[1])..",ProductName:"..json.encode(recordParrent[2]).."}")
end
-------------------------------------------
--teamyar.write_result(productcode)