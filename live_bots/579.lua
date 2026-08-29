--check st
local  input = teamyar.get_input();

local input_invoice_id = input.invoice_id
local input_org_id = input.org_id
local status = "NOT_GET"
-----------------------------------------------
function queryResult(select_query,user_param)
  db.use_db("0000000");
  local params1 = {
    query = select_query,
    params = user_param
  }
  db.query(params1);
  local res_text = db.query_fetch();
  db.query_free();
  if res_text ~= nill then 
    return res_text[1];
  else
    return nill;
  end
end
-----------------------------------------------------------
function fileToString(file)
  local str=""
  if file ~= nil and file[1] ~= nil and  file[1].module_id ~= nil and file[1].id ~= nil and file[1].mime ~= nil then
    local file_manager = teamyar.create_file_manager(file[1].module_id);
    str = file_manager:readFile(file[1].id);
    file_manager:release();
  end
  return str
end
---------------------
function hasErrorMessage(res_inquery)
  if res_inquery == nil then
    return ""
  end
  
  local decoded = json.decode(res_inquery)
  if decoded == nil then
    return ""
  end
  
  if decoded.errors == nil or #decoded.errors < 1 then
    return ""
  end
  
  if decoded.errors[1] == nil or decoded.errors[1].message == nil or decoded.errors[1].message == "" then
    return ""
  end
  
  return  decoded.errors[1].message
end
--------------------------------------------------------------------get config
local config = teamyar.get_config()
local config_data = {}
local c_url = ""
local c_memory_tax_id = ""
local private_key = ""
local certificate = ""
if config ~= nil then 
  config_data = config.data
  c_url = config_data.url
  c_memory_tax_id = config_data.memory_tax_id
  private_key = fileToString(config_data.private_key)
  certificate = fileToString(config_data.certificate)
else 
  status = "NOT_CONFIG"
end 

----get nonce
local nonce = 0
local es_str = ""
local curl = teamyar.create_curl();
if curl:connect({domain = c_url, port = 443, ssl = true, secure = false}) then
  local params_no = {
    method = "GET", 
    url = "/requestsmanager/api/v2/nonce?timeToLive=20" ,
    headers = {
      {name = "Accept", value = "*/*"}, 
    },
  };
  if curl:sendRequest(params_no) then
    if curl:getStatus() == 500 then
      local res_nonce = curl:getResponse()
      local msg = json.decode(res_nonce).message
      status = "NOT_RELATED"
    elseif curl:getStatus() == 200 then
      local res_nonce = curl:getResponse()
      nonce = json.decode(res_nonce).nonce
    else
      local res_nonce = curl:getResponse()
      local msg = json.encode(curl)
      status = "NOT_RELATED"

    end
  else    
     status = "NOT_RELATED"
  end
  curl:disconnect();
else
    status = "NOT_RELATED"
end
curl:release();   
-------get tocken
local res_str = ""
local tYear, tMonth, tDay, tHour, tMinute, tSecond = string.match(time.get_str(time.current()),'(%d+).(%d+).(%d+) (%d+):(%d+):(%d+)');

local param_jjwt = {
  algorithm = "RS256",
  secret = private_key,
  headers =  { 
    alg = "RS256",
    sigT=   string.format('%.4d-%.2d-%.2dT%.2d:%.2d:%.2dZ', tYear, tMonth, tDay, tHour, tMinute, tSecond),
    crit={"sigT"},
    x5c = {certificate},
  },
  payload = { 
    nonce = nonce,
    clientId = c_memory_tax_id
  }
}
local ctocken = "Bearer "..coding.jwt(param_jjwt)
------------------------------------------------------------------------------------------check inquery
local qtaxid = [[select SUBSTRING_INDEX(SUBSTRING_INDEX(note, 'factor_tax_id:<br>', -1), '<br>', 1) rf from sales_history where note like '%factor_tax_id:<br>%' and  invoice_id=]]..input_invoice_id..[[ order by id desc limit 1  ]]
local taxid = queryResult(qtaxid,{})
local qst = [[select moadian_status from sales_invoice where id=]]..input_invoice_id
local kind_str = ""
local kind = 0
local int_status = 0
local moadian_status = queryResult(qst, {})
--teamyar.write_log("moadian_status------777----"..moadian_status)
if moadian_status == 1 or (moadian_status > 100 and moadian_status < 121) then 
  kind_str = "[ارسالی] "
  kind = 1
elseif moadian_status == 4 or (moadian_status > 200 and moadian_status < 221) then 
  kind_str = "[ابطالی] "
  kind = 2
elseif moadian_status == 7 or (moadian_status > 300 and moadian_status < 321) then 
  kind_str = "[اصلاحی] "
  kind = 3
end 
local res_inquery = {}
local res_status = 0
local curli = teamyar.create_curl();

if curli:connect({domain = c_url, port = 443, ssl = true, secure = false}) then
  local params_inq = {
    method = "GET", 
    url = "/requestsmanager/api/v2/inquiry-invoice-status?taxIds="..taxid, 
    headers = {
      {name = "Accept", value = "*/*"}, 
      {name = "Authorization", value = ctocken },
    },
  };
  local sended = curli:sendRequest(params_inq)
  if sended then
    res_inquery = curli:getResponse()
    local str_err = hasErrorMessage(res_inquery)
    if #str_err > 3 then 
      -- status = str_err
      --teamyar.write_log(str_err)
    end
    res_status= curli:getStatus() 
    if res_status == 500 then
      status="ERROR_INQUERY"

    elseif res_status== 200 then
      status="NOT_DETECT"
      if # json.decode(res_inquery) > 0 then
        if type(json.decode(res_inquery)[1].invoiceStatus) == "string" then 
          status=json.decode(res_inquery)[1].invoiceStatus
        elseif type(json.decode(res_inquery)[1].error) == "string" then
          status=json.decode(res_inquery)[1].error
        end
      end
    else
      status = "ERROR_GET"
    end
  else
     status = "NOT_RELATED"
  end
  curli:disconnect();
else
    status = "NOT_RELATED"
end
curli:release();  

local prsain_st = ""

----------------------------------sended 
if status == "ACCEPTED"  and kind == 1 then 
  prsain_st = "پذیرفته شده" 
  int_status = 101
elseif  status == "REJECTED"  and kind == 1 then
  prsain_st = "رد شده"
  int_status = 102 
elseif status == "PENDING"   and kind == 1  then 
  prsain_st = "در انتظار بررسی" 
    int_status = 103
elseif  status == "CANCELLED"  and kind == 1 then
  prsain_st = "ابطال شده" 
   int_status = 104
elseif  status == "FAILED"  and kind == 1 then
  prsain_st = "ناموفق / خطا در پردازش" 
   int_status = 105
elseif  status == "PROCESSING" and kind == 1  then
  prsain_st = "در حال پردازش"
   int_status = 106
elseif  status == "DRAFT"  and kind == 1 then 
  prsain_st = "پیش‌نویس"
   int_status = 107
elseif  status == "SENT"  and kind == 1 then
  prsain_st = "ارسال شده" 
 int_status = 108
elseif status == "WAITING"   and kind == 1 then
  prsain_st = "در انتظار"
  int_status = 109
elseif status == "NO_NEED_REACTION"  and kind == 1 then
  prsain_st = "دیگر نیازی به واکنش نیست" 
    int_status = 110
elseif status == "UNKNOWN" and kind == 1  then 
  prsain_st = "نامشخص"
    int_status = 111
elseif  status == "NOT_DETECT"  and kind == 1 then
  prsain_st = "پیدا نشده" 
    int_status = 112
elseif status == "ERROR_INQUERY"  and kind == 1 then 
  prsain_st = "خطادراستعلام" 
    int_status = 113
elseif status == "ERROR_GET"  and kind == 1 then
  prsain_st = "خطا در ارتباط"
    int_status = 114
elseif  status == "NOT_GET"  and kind == 1 then 
  prsain_st = "استعلام نشده" 
    int_status = 115
elseif status == "NOT_FOUND"  and kind == 1 then
  prsain_st = "عدم ارسال/خطا" 
    int_status = 116
elseif status == "NOT_CONFIG"  and kind == 1 then 
  prsain_st = "تنظیمات پیکربندی خالی" 
    int_status = 117
elseif status == "NOT_RELATED" and kind == 1  then
  prsain_st = "عدم ارتباط سامانه" 
    int_status = 118
  elseif status == "CANCELED" and kind == 1  then
    prsain_st = "لغو شده" 
    int_status = 119
    elseif status == "AWAITING_REACTION" and kind == 1  then
    prsain_st = "منتظر واکنش" 
    int_status = 120
elseif status == "ACCEPTED"  and kind == 2 then -----------------------deleted
  prsain_st = "پذیرفته شده" 
  int_status = 201
elseif  status == "REJECTED"  and kind == 2 then
  prsain_st = "رد شده"
  int_status = 202 
elseif status == "PENDING"   and kind == 2 then 
  prsain_st = "در انتظار بررسی" 
    int_status = 203
elseif status == "CANCELLED"  and kind == 2 then
  prsain_st = "ابطال شده" 
   int_status = 204
elseif status == "FAILED"  and kind == 2 then
  prsain_st = "ناموفق / خطا در پردازش" 
   int_status = 205
elseif status == "PROCESSING" and kind == 2  then
  prsain_st = "در حال پردازش"
   int_status = 206
elseif status == "DRAFT"  and kind == 2 then 
  prsain_st = "پیش‌نویس"
   int_status = 207
elseif status == "SENT"  and kind == 2 then
  prsain_st = "ارسال شده" 
 int_status = 208
elseif status == "WAITING"   and kind == 2 then
  prsain_st = "در انتظار"
  int_status = 209
elseif  status == "NO_NEED_REACTION"  and kind == 2 then
  prsain_st = "دیگر نیازی به واکنش نیست" 
    int_status = 210
elseif status == "UNKNOWN" and kind == 2  then 
  prsain_st = "نامشخص"
    int_status = 211
elseif status == "NOT_DETECT"  and kind == 2 then
  prsain_st = "پیدا نشده" 
    int_status = 212
elseif status == "ERROR_INQUERY"  and kind == 2 then 
  prsain_st = "خطادراستعلام" 
    int_status = 213
elseif status == "ERROR_GET"  and kind == 2 then
  prsain_st = "خطا در ارتباط"
    int_status = 214
elseif status == "NOT_GET"  and kind == 2 then 
  prsain_st = "استعلام نشده" 
    int_status = 215
elseif  status == "NOT_FOUND"  and kind == 2 then
  prsain_st = "عدم ارسال/خطا" 
    int_status = 216
elseif status == "NOT_CONFIG"  and kind == 2 then 
  prsain_st = "تنظیمات پیکربندی خالی" 
    int_status = 217
elseif  status == "NOT_RELATED" and kind == 2  then
  prsain_st = "عدم ارتباط سامانه" 
    int_status = 218
    elseif status == "CANCELED" and kind == 2  then
    prsain_st = "لغو شده" 
    int_status = 219
      elseif status == "AWAITING_REACTION" and kind == 2 then
    prsain_st = "منتظر واکنش" 
    int_status = 220
elseif status == "ACCEPTED"  and kind == 3 then ------------------------------deleted
  prsain_st = "پذیرفته شده" 
  int_status = 301
elseif status == "REJECTED"  and kind == 3 then
  prsain_st = "رد شده"
  int_status = 302 
elseif  status == "PENDING"   and kind == 3  then 
  prsain_st = "در انتظار بررسی" 
    int_status = 303
elseif status == "CANCELLED"  and kind == 3 then
  prsain_st = "ابطال شده" 
   int_status = 304
elseif  status == "FAILED"  and kind == 3 then
  prsain_st = "ناموفق / خطا در پردازش" 
   int_status = 305
elseif  status == "PROCESSING" and kind == 3  then
  prsain_st = "در حال پردازش"
   int_status = 306
elseif  status == "DRAFT"  and kind == 3 then 
  prsain_st = "پیش‌نویس"
   int_status = 307
elseif  status == "SENT"  and kind == 3 then
  prsain_st = "ارسال شده" 
 int_status = 308
elseif  status == "WAITING"   and kind == 3 then
  prsain_st = "در انتظار"
  int_status = 309
elseif  status == "NO_NEED_REACTION"  and kind == 3 then
  prsain_st = "دیگر نیازی به واکنش نیست" 
    int_status = 310
elseif status == "UNKNOWN" and kind == 3  then 
  prsain_st = "نامشخص"
    int_status = 311
elseif status == "NOT_DETECT"  and kind == 3 then
  prsain_st = "پیدا نشده" 
    int_status = 312
elseif status == "ERROR_INQUERY"  and kind == 3 then 
  prsain_st = "خطادراستعلام" 
    int_status = 313
elseif status == "ERROR_GET"  and kind == 3 then
  prsain_st = "خطا در ارتباط"
    int_status = 314
elseif status == "NOT_GET"  and kind == 3 then 
  prsain_st = "استعلام نشده" 
    int_status = 315
elseif status == "NOT_FOUND"  and kind == 3 then
  prsain_st = "عدم ارسال/خطا" 
    int_status = 316
elseif status == "NOT_CONFIG"  and kind == 3 then 
  prsain_st = "تنظیمات پیکربندی خالی" 
    int_status = 317
elseif status == "NOT_RELATED" and kind == 3  then
  prsain_st = "عدم ارتباط سامانه" 
    int_status = 318
elseif status == "CANCELED" and kind == 3  then
    prsain_st = "لغو شده" 
    int_status = 319
 elseif status == "AWAITING_REACTION" and kind == 3 then
    prsain_st = "منتظر واکنش" 
    int_status = 320
else
    prsain_st = status
    int_status = 400
end
if int_status == 0 then
  if kind==3 then 
  --  int_status=316
  elseif kind==2 then
   -- int_status=216
  else
  --  int_status=116
  end
    
end 
  local info_log =  {
    org_id = input_org_id,
    history = "وضعیت فاکتوردر سامانه مودیان:<div id='res_st'>"..kind_str..prsain_st.."</div>",
    invoice_id = input_invoice_id
  }
  local   res_log = teamyar.call_api(23,  '/api/sales/update_invoice_history', info_log);

  -----update taxpayer status
if int_status ~= 0 then
  local info_update_status = {
    org_id = input_org_id,
    invoice_id = input_invoice_id,
    moadian_status =  int_status
  }
   -- teamyar.write_log("info_update_status---"..json.encode(info_update_status))
   local   res_update_status = teamyar.call_api(23,  '/api/sales/update_moadian_status', info_update_status);
   -- teamyar.write_log("res_update_status---"..json.encode(res_update_status)) 
end
teamyar.write_log(taxid.."----"..status.."----"..prsain_st.."  int_status  "..int_status)
teamyar.write_result(prsain_st)



