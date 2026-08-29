local input = teamyar.get_input()
local parrent = input.parrent
-------------------------------------------
local paramParrent = {
    query = "select code from wh_product where id ="..parrent,
    param = { parrent}
}

local resultParrent = {}
db.query(paramParrent)
local recordParrent =  db.query_fetch(recordParrent)

db.query_free()
local resultExprecordParrent = recordParrent[1]
-------------------------------------------
local Fromyear = 1403
local frommonth = 09
local fromday = 02
local param = {
    query = "select code from wh_product where full_code like '"..resultExprecordParrent.."%' order by id desc limit 1",
    param = { Fromyear, frommonth, fromday}
}

local result = {}
db.query(param)
local record =  db.query_fetch(record)

db.query_free()
local resultExp = record[1]

date_input = json.encode(resultExp)
local lastcode = tonumber(resultExp)
teamyar.write_result(tostring(lastcode))
------------------------------------------