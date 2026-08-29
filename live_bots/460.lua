local sqlquery = "select id,full_name,description from wh_product"

local paramParrent = {
    query =sqlquery,
    param = { }
}
--teamyar.write_result(sqlquery)
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
--teamyar.write_result(result)
local jsonResult = json.encode(result)
teamyar.write_result(jsonResult)