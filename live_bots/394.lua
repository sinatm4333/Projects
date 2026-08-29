local input = teamyar.get_input()
-------------------------------------------
local Fromyear = input.yearshamsi
local frommonth = input.monthshamsi
local fromday = input.dayshamsi
local param = {
    query = [[
              select datekey from report_dimdate
				where JYEAR =  ]] .. Fromyear .. [[ 
				and jmonth = ]] .. frommonth .. [[ 
				and jmday = ]] .. fromday .. [[ 
				limit 1
    ]],
    param = { Fromyear, frommonth, fromday}
}

local result = {}
db.query(param)
local record =  db.query_fetch(record)

db.query_free()
local resultExp = record[1]

date_input = json.encode(resultExp)
------------------------------------------
-------------------------------------------
ClientInfo = input.customerjsondata
local clientinfoparameters = json.decode(ClientInfo)
--teamyar.write_result(json.encode(ClientInfo))

local res_client = teamyar.call_api(14 , "/api/client/create" , clientinfoparameters);
--teamyar.write_result("resultClient:"..json.encode(res_client))

-------------------------------------------

factor_info= input.factorjsondata

local factorinfoparameters = json.decode(factor_info)
--teamyar.write_result(json.encode(factor_info))

local res_factor = teamyar.call_api(23 , "/api/invoice/create" , factorinfoparameters);
--teamyar.write_result("resFactor:"..json.encode(res_factor))

local combined = {
  resultClient = json.encode(res_client),
  resultFactor = json.encode(res_factor)
}
teamyar.write_result(json.encode(combined))