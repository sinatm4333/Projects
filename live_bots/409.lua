local input = teamyar.get_input()
local productname = input.productname
--teamyar.write_result(productname)

-------------------------------------------
local paramParrent = {
    query = "select id as ProductId,full_code as ProductCode,name as FullName from wh_product where full_name like  '%"..productname.."%'",
    param = { }
}
--teamyar.write_result("select code from wh_product where full_name like '%'"..productname.."%'")
local resultParrent = {}
db.query(paramParrent)
local recordParrent =  db.query_fetch(recordParrent)

db.query_free()
if recordParrent == nil or recordParrent == ''
then
 teamyar.write_result("")
else
  teamyar.write_result("{ProductId:"..json.encode(recordParrent[1])..",ProductCode:"..json.encode(recordParrent[2])..",FullName:"..json.encode(recordParrent[3]).."}")
   --local productcode = {"Id:"..recordParrent[1],"Code:"..recordParrent[2]}
  --teamyar.write_result(productcode)
end
-------------------------------------------
  if result == nil or #result >1
  then
   teamyar.write_result("")
  else
teamyar.write_result(jsonResult)
  --teamyar.write_result("{ProductId:"..json.encode(recordParrent[1])..",ProductCode:"..json.encode(recordParrent[2]).."}")
     --local productcode = {"Id:"..recordParrent[1],"Code:"..recordParrent[2]}
    teamyar.write_result(jsonResult:gsub("%^a", ""))
  end