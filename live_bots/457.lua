local input = teamyar.get_input()
local description = input.description
--teamyar.write_result(hcinvoicenumber)
local sqlquery = "select id,full_name,description from wh_product where wh_product.description like '%"..description.."%'"
--teamyar.write_result(sqlquery)
-------------------------------------------
local paramParrent = {
    query =sqlquery,
    param = { }
}
--teamyar.write_result("select code from wh_product where description like '%'"..productname.."%'")
local result = {}
db.query(paramParrent)
local record = {}
while db.query_fetch(record) do
    table.insert(result, {
        id = record[1],
        full_name = record[2],
        description = record[3],
    })
end
db.query_free()
local jsonResult = json.encode(result)
teamyar.write_result(jsonResult)