local input = teamyar.get_input()
local accountname = input.accountname
--teamyar.write_result(productname)

-------------------------------------------
local paramParrent = {
    --query = "select id,parent,name from pa_client where name like   '%"..accountname.."%'",
      query = "select max(id) from pa_client",

    param = { parrent}
}
--teamyar.write_result("select id,parent,name from pa_client where name like   '%"..accountname.."%'")
local resultParrent = {}
db.query(paramParrent)
local recordParrent =  db.query_fetch(recordParrent)

db.query_free()
if recordParrent == nil or recordParrent == ''
then
 teamyar.write_result("")
else
  teamyar.write_result("{Id:"..json.encode(recordParrent[1]).."}")
  teamyar.write_result("{Parent:"..json.encode(recordParrent[2]).."}")
  teamyar.write_result("{AccountName:"..json.encode(recordParrent[3]).."}")
   --local productcode = {"Id:"..recordParrent[1],"Code:"..recordParrent[2]}
  --teamyar.write_result(productcode)
end

-------------------------------------------
