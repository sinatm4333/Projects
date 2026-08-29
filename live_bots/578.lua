-- botName = moadian_factor_tabs
-- description = فاکتورهای ارسالی به سامانه مودیان (ارسالی/ابطالی/اصلاحی)
-- version = 1
------------------------------------
local input = teamyar.get_input();
local intype = tonumber(input.type) or 0;
-----------------------------------
function getQuery(intype, istotal)

  local config = teamyar.get_config()
  local cfg = {}
  if config ~= nil then 
    cfg= config.data
  end 
  if  intype == 1 then
    query = teamyar.get_attachment("querySend.txt")
  elseif  intype == 2 then
    query = teamyar.get_attachment("queryDelete.txt")
  elseif  intype == 2 then
    query = teamyar.get_attachment("queryEdite.txt")
  end


  if cfg.org_id ~= nil then
    query = string.gsub(query, "{{org_id}}", cfg.org_id);
  else
    query = string.gsub(query, "{{org_id}}", "0");
  end 
  local where_stock = ""
  local where_stock_out = ""
  local where_product = ""
  local where_crm= ""
  local where_kcrm= ""
  local where_tag = ""
  local where_moadian_code =""
  local where_factor_id = ""
  local where_send_status = ""

  if cfg.product_ids ~= nil  then 
   -- where_product = where_product.. [[ and ip.product_id in (]]..cfg.product_ids..[[) ]]

  end 
  if cfg.stock_ids ~= nil then 
  --  where_stock = where_stock.. [[ and ip.stock_id in (]]..cfg.stock_ids..[[) ]]
  end 
  local day = time.get_day(time.current());
  local month = time.get_month(time.current());
  local year = time.get_year(time.current());
  local hour = time.get_hour(time.current());
  local min = time.get_minute (time.current());
  local sec = time.get_second(time.current());
  local currentdate_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":]]..hour..[[,"minute":]]..min..[[,"second":]]..sec..[[}]])
  local temp_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":0,"minute":0,"second":0}]])
  local currentdate = string.format("%18.0f" ,temp_time);
  local datet = currentdate
  local datef = string.format("%18.0f" ,temp_time-(60*60*24*10000000*cfg.count_day))


  query = string.gsub(query,"{{datet}}",datet);
  query = string.gsub(query,"{{datef}}",datef);
  query = string.gsub(query,"{{where_stock}}",where_stock);
  query = string.gsub(query,"{{where_product}}",where_product);
  query = string.gsub(query,"{{tabtype}}",intype);
  if istotal ~= nil  then 
    --   teamyar.write_log("i88888--")
    query = string.gsub(query,"{{selected}}","count(*)");
    query = string.gsub(query,"{{slicePageNumber}}", "");
  else 
    --   teamyar.write_log("111111--")
    query = string.gsub(query,"{{selected}}","*");
    query = string.gsub(query,"{{slicePageNumber}}",  " limit "..cfg.per_page);
  end

  return query
end
----------------
function inqueryfactor(fid,referenceNumber,org_id)
  local res_bot = teamyar.run_command("2/inquery_invoice_taxpayer_m/", { referenceNumber = referenceNumber, invoice_id = tostring(fid), org_id = org_id});
  local res_status = teamyar.run_command("2/fact_st_m" , { invoice_id = tostring(fid), org_id = org_id }); 
  return res_bot, res_status
end
------------------------------------
-- type=1 → ارسالی, type=2 → ابطالی, type=3 → اصلاحی
if intype == 1 or intype == 2 or intype == 3 then

  db.use_db("0000000");
  local query =getQuery(intype)  
  -- teamyar.write_log("tab query=" .. query);
  db.query({query = query});
  local rows = {};
  local record = {};
  while db.query_fetch(record) do
    table.insert(rows, {id = tostring(record[2]), name = tostring(record[3])
        , date = tostring(record[4]), amont = tostring(record[5]), rf = tostring(record[6]), uid = tostring(record[7]), st = tostring(record[8]), err = tostring(record[9]),btn = tostring(record[11])
      });
  end
  db.query_free();
  local total = 0
  local qtotal = getQuery(intype,1)
  --  teamyar.write_log("total--------------"..qtotal)
  db.use_db("0000000");
  db.query({query = qtotal});
  local restxt = db.query_fetch();
  if restxt ~= nil then 
    total = restxt[1]
  end
  db.query_free();
  teamyar.write_result(json.encode({data = rows, total = total}));
  return;
elseif intype == 4 then
  local iinput = teamyar.get_input()
  local fid=input.fid
  local referenceNumber = input.referenceNumber
  local date_replace=input.date_replace
  local config = teamyar.get_config()
  local cfg = {}
  if config ~= nil then 
    cfg= config.data
  end 
  local botmsg, fact_st =  inqueryfactor(fid,referenceNumber,cfg.org_id)
  local msg ="شماره فاکتور:"..fid.."  ".. botmsg.."<br> وضعیت در سامانه= "..fact_st
  local res_data={msg = msg}
  teamyar.write_result(json.encode(res_data))
else

local res_data = [[

<div class="mft-container">
<div class="card">
  <h2 class="main-title">فاکتورهای ارسال شده به سامانه مودیان</h2>
  <div class="tabs">
    <div class="tab active" data-type="1" onclick="switchTab(1)">ارسالی</div>
    <div class="tab" data-type="2" onclick="switchTab(2)">ابطالی</div>
    <div class="tab" data-type="3" onclick="switchTab(3)">اصلاحی</div>
  </div>
  <div class="tab-content active" id="tab_1">
  <div id='msg_text_report1' ></div>
   <h3 class="show_total"> تعداد فاکتور های ارسالی : <div style='display:inline-block;'  id='show_total1'  >0</div> </h3>
    <table class="data-table">
      <thead><tr>
      <th class="th-id">شماره فاکتور</th>
      <th class="th-name">عنوان</th>
      <th class="th-date">تاریخ</th>
      <th class="th-amont">مبلغ</th>
      <th class="th-rf">referenceNumber</th>
      <th class="th-uid">شناسه یکتای مالیاتی صورتحساب</th>
      <th class="th-st">وضعیت</th>
      <th class="th-er">خطا</th>
      <th class="th-er">استعلام</th>
      </tr></thead>
      <tbody id="tbody_1"></tbody>
    </table>
  </div>
  <div class="tab-content" id="tab_2">
  <div id='msg_text_report2' ></div>
 <h3 class="show_total">تعداد فاکتور های ابطالی : <div style='display:inline-block;'  id='show_total2' >0</div> </h3>
    <table class="data-table">
      <thead><tr>
        <th class="th-id">شماره فاکتور</th>
        <th class="th-name">عنوان</th>
        <th class="th-date">تاریخ</th>
        <th class="th-amont">مبلغ</th>
        <th class="th-rf">referenceNumber</th>
        <th class="th-uid">شناسه یکتای مالیاتی صورتحساب</th>
        <th class="th-st">وضعیت</th>
        <th class="th-er">خطا</th>
        <th class="th-er">استعلام</th>
        </tr></thead>
      <tbody id="tbody_2"></tbody>
    </table>
  </div>
  <div class="tab-content" id="tab_3">
  <div id='msg_text_report3' ></div>
 <h3 class="show_total">تعداد فاکتور های اصلاحی : <div style='display:inline-block;' id='show_total3' >0</div> </h3>
    <table class="data-table">
      <thead>
        <tr>
        <th class="th-id">شماره فاکتور</th>
        <th class="th-name">عنوان</th>
        <th class="th-date">تاریخ</th>
        <th class="th-amont">مبلغ</th>
        <th class="th-rf">referenceNumber</th>
        <th class="th-uid">شناسه یکتای مالیاتی صورتحساب</th>
        <th class="th-st">وضعیت</th>
        <th class="th-er">خطا</th>
        <th class="th-er">استعلام</th>
</tr>
</thead>
      <tbody id="tbody_3"></tbody>
    </table>
  </div>
</div>
</div>

 	
       <link href='/bot/run/2/moadian_index_m/main.css' rel='stylesheet' /> 
		<script src='/bot/run/2/moadian_index_m/main.js'></script>
  
		]];
teamyar.write_result(res_data);

end

------------------------------------
-- default: show HTML

