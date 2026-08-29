local input = teamyar.get_input()
local clientid = input.clientid
--teamyar.write_result(clientid)
--local sqlquery = "select id,reffere_id,code from pa_client where ORG_ID = 8 and NAME like '%"..clientid.."%' where pa_client.DELETED=0"
local sqlquery = "select  id,reffere_id,code,account_code from pa_client where ORG_ID = 8 and reffere_id = "..clientid.."  and pa_client.DELETED=0"

--teamyar.write_result(sqlquery)
-------------------------------------------
local paramParrent = {
    query =sqlquery,
    param = { }
}
local result = {}
db.query(paramParrent)
local record = {}
while db.query_fetch(record) do
    table.insert(result, {
        id = record[1],
        reffere_id = record[2],
        code = record[3],
              account_code = record[4],

    })
end
db.query_free()
local jsonResult = json.encode(result)
teamyar.write_result(jsonResult)