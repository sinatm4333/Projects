local input = teamyar.get_input()
local productname = input.productname
--teamyar.write_result(productname)

-------------------------------------------
local paramParrent = {
    query = "select id,full_code,description from wh_product where description like  '%"..productname.."%'",
    param = { parrent}
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
  teamyar.write_result("{ProductDescription:"..json.encode(recordParrent[3]).."}")
   --local productcode = {"Id:"..recordParrent[1],"Code:"..recordParrent[2]}
  --teamyar.write_result(productcode)
end

-------------------------------------------
