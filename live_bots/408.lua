local total_param = teamyar.get_input()

local hour = time.get_hour(time.current());
local min = time.get_minute(time.current());
local sec = time.get_second(time.current());

local year = total_param.fromyear;
local month = total_param.frommonth;
local day = total_param.fromday;
--
local param = {
    query = [[
              select datekey from report_dimdate
				where JYEAR =  ]] .. year .. [[ 
				and jmonth = ]] .. month .. [[ 
				and jmday = ]] .. day .. [[ 
				limit 1
    ]],
    param = { year, month, day}
}
local result = {}
db.query(param)
local record =  db.query_fetch(record)
db.query_free()
local resultExp = record[1]
date_input = json.encode(resultExp)
--

--local timeinput = [[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":]]..hour..[[,"minute":]]..min..[[,"second":]]..sec..[[}]];

--local temp_time = time.get_filetime(timeinput)
--currentdate = string.format("%18.0f", temp_time);
--local date_input = currentdate

--local param = {
    --query = [[select datekey from report_dimdatewhere JYEAR =  ]] .. total_param.Fromyear .. [[ and jmonth = ]] .. total_param.frommonth .. [[ and jmday = ]] .. total_param.fromday .. [[ limit 1]],
  --query = "select REPORT_FN_JDATE_TO_FILETIME("..total_param.Fromyear ..","..total_param.frommonth ..","..total_param.fromday ..")",
    --param = { total_param.Fromyear, total_param.frommonth, total_param.fromday}
--}

--local result = {}
--db.query(param)
--local record =  db.query_fetch(record)

--db.query_free()
--local resultExp = record[1]

--
--local resultTime = (resultExp / 10000000) - 11644473600
--local resultExpFinal = resultExp - resultTime
--teamyar.write_result(string.format("%.0f", resultExpFinal))

--
--local jsonResult = json.encode(string.format("%18.0f", date_input))
teamyar.write_result(string.format("%18.0f", date_input))
