-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/05/22 19:40

-- botName = Sum Workdays And Sales Params
-- creator = zmo
-- date = 02/25/2025
-- version= 1.4 (اصلاح باگ‌های getData؛ تلاش قبلی برای رد کردن کوئری روی لود اول فرم فیلتر را
--          می‌شکست — به حالت ساده برگشت داده شد، نیاز به بررسی زنده دارد)
--
-- طبق درخواست: هرچه در بات ۵۰۱ هست عیناً حفظ می‌شود؛ فقط ظاهر (data.css/data.js) و باگ‌های
-- واقعی اصلاح می‌شوند. معماری RES (readyCodes/install_res) و همه فیلترها (org/ctype/cat/crm)
-- دقیقاً مثل بات ۵۰۱ حفظ شده‌اند؛ فقط getData() اصلاح شده. بقیه توابع (SMS، ACL، جدول، dispatch)
-- عیناً بات ۵۰۱ است. فرم فیلتر خودش (getFilters/ویرایشگر) از data.js می‌آید، نه از این فایل —
-- پیوست data.js بات ۶۰۰ باید همان data.js بات ۵۰۱ باشد (فقط با مسیر bot/run/2/crm_rfm_1
-- به‌جای bot/run/2/crm_rfm در دو تابع save_all/send_sms).
--
-- تغییرات در getData() (با دلیل):
--   ۱) باگ اصلی گزارش‌شده: datef/datet وقتی از فرم مقداردهی نمی‌شدند بی‌صدا به 0 (تاریخ صفر
--      سیستم) سقوط می‌کردند -> Monetary/Frequency/Days کل تاریخچه را حساب می‌کردند نه بازهٔ
--      انتخابی؛ چون اکسل هم از همین getData() رد می‌شود، همان باگ آنجا هم بود.
--      طبق خواستهٔ شما «فقط بر اساس تاریخ‌ها کوئری بزنیم» (بدون منطق سال مالی) — به‌جای صفر،
--      روی «امروز» پیش‌فرض می‌گیرد؛ یعنی وقتی فیلتر خالی بماند، بازهٔ خالی/تقریباً خالی نشان
--      می‌دهد (سیگنال واضح که فیلتر ست نشده) نه کل تاریخچه به‌شکل گمراه‌کننده.
--   ۲) queryTools.where/{{whereInvoice}} دقیقاً مثل بات ۵۰۱ دست‌نخورده باقی ماند (نمی‌شود org/
--      ctype/cat/crm را از این مسیر فیلتر کرد — این placeholder روی نتیجهٔ نهایی CTE «data» اعمال
--      می‌شود که ستون‌هایی مثل s.ORG_ID/ui.USER_TYPE اصلاً در آن دید (scope) وجود ندارند؛ فیلتر
--      باید داخل CTE «crm_factor» باشد، جایی که s/p/ui در دسترس‌اند). به همین دلیل org/ctype/cat/crm
--      عیناً با همان مکانیزم substitution بات ۵۰۱ داخل crm_factor فیلتر می‌شوند (نه queryTools) —
--      فقط باگ‌های alias آن اصلاح شدند (توضیح در پایین فایل).
--   ۳) باگ دیگر که همین‌جا پیدا شد: f_nummber/m_nummber هر دو از cdata.rnumber می‌خواندند
--      (کپی/پیست) — یعنی وزن F و M همیشه نادیده گرفته می‌شدند و همه‌چیز فقط با وزن R حساب
--      می‌شد. اصلاح شد: هرکدام از فیلد پیکربندی خودش می‌خواند.
--   ۴) فیلتر cat: در بات ۵۰۱ به alias نامعتبر "c.id" ارجاع می‌داد (در FROM فقط alias «p» برای
--      pa_client وجود دارد) — در صورت انتخاب واقعی، کوئری با خطای unknown column شکست می‌خورد.
--      اصلاح شد به "p.id".
--   ۵) فیلتر ctype/crm: به "ui.USER_TYPE" ارجاع می‌داد اما هیچ‌جا profile_user_info با alias ui
--      join نشده بود (کد مرده، همیشه با خطا شکست می‌خورد). باید در پیوست query_list_invoice.txt
--      یک LEFT JOIN profile_user_info ui ON ui.id = p.REFFERE_ID اضافه شود (متن اصلاح‌شدهٔ
--      پیوست را جدا در چت فرستادم چون آپلود پیوست از راه API ممکن نیست).
--   ۶) باگ واقعی و همیشگی بات ۵۰۱ که با دیدن data.js واقعی پیدا شد: فیلتر «org» در data.js
--      name: "org" ارسال می‌کند، ولی data.txt فقط "org_id" را declare کرده — چون getInput فقط
--      کلیدهای declare‌شده در data.txt را می‌خواند، فیلتر سازمان همیشه (حتی در بات ۵۰۱ زنده)
--      نادیده گرفته می‌شد. رفع نهایی: در data.txt کلید "org_id" به "org" تغییر کرد (نه در Lua).
--   ۷) فیلتر «crm» (مشتری) که ابتدا به‌اشتباه کد مرده تشخیص داده و حذف شده بود، برگردانده شد —
--      واقعاً در data.js بات ۵۰۱ وجود دارد (aclId=7). شرط SQL‌اش («ui.USER_TYPE=crm_id») عیناً
--      از بات ۵۰۱ کپی مانده و مشکوک به نظر می‌رسد (به نظر کپی/پیست ctype است، نه شرط معناداری
--      برای «مشتری») — طبق درخواست شما دست‌نخورده ماند؛ بگویید اگر بخواهید معنایی درست شود.
--   ۸) مقادیر cat[1].id/ctype[1].id/crm[1].id/org[1].id قبل از concat با tonumber() اعتبارسنجی
--      می‌شوند (اگر عددی نبود، آن فیلتر نادیده گرفته می‌شود به‌جای این‌که کوئری با متن نامعتبر بشکند).

--------------------------------------------
--- CONFIG DATA
--------------------------------------------
local day = time.get_day(time.current());
local month = time.get_month(time.current());
local year = time.get_year(time.current());
local hour = time.get_hour(time.current());
local min = time.get_minute (time.current());
local sec = time.get_second(time.current());
local currentdate_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":]]..hour..[[,"minute":]]..min..[[,"second":]]..sec..[[}]])
local temp_time = time.get_filetime([[{"year":]]..year..[[,"month":]]..month..[[,"day":]]..day..[[,"hour":0,"minute":0,"second":0}]])
local currentdate = string.format("%18.0f" ,temp_time);
----------------------------
local _PAR_PAGE = 25
local _QUERY_TYPE = {
  _TYPE_TOTAL_SUM = 1 ,
  _TYPE_TOTAL_COUNT = 2 ,
  _TYPE_PAGE_REPORT = 3 ,
  _TYPE_PAGE_EXCEL = 4 ,
  _TYPE_PAGE_PRINT = 5 ,
}
-------------------------------------------
--- install [RES]
--------------------------------------------
local _BAT_RES_PATH = "2/res_v2";
function readyCodes()
  local data = teamyar.get_input();
  data["res_type"] = "codes"
  data["config"] = json.decode(teamyar.get_attachment("data.txt"))
  local responseRes = teamyar.run_command(_BAT_RES_PATH , data);
  if responseRes ~= nil then
    responseRes = json.decode(responseRes)
    for i = 1 , #responseRes, 1 do
      local loadedFunction, errorMessage = load(responseRes[i])
      if loadedFunction then
        loadedFunction();
      else
        teamyar.write_log("Error: " .. errorMessage);
      end
    end
  end
end
readyCodes();
--------------------------------------------
--- data
--------------------------------------------
---- getInput() برای هر فیلدی که در درخواست ارسال نشده باشد یک userdata نال
---- ("userdata: 0000000000000000") برمی‌گرداند — نه nil و نه table. آن مقدار در Lua
---- truthy است ولی index نمی‌شود، پس چک «x ~= nil and x[1] ~= nil» با خطای
---- "attempt to index a userdata value" کل بات را می‌شکند. این همان علت «لودینگ گیر
---- می‌کند» در داشبورد CRM است (فرم فیلتر Submit نمی‌شود، پس هیچ فیلدی ارسال نمی‌شود).
local function acl_selection(value)
  if value == nil then return nil end
  if _G.type(value) ~= "table" then return nil end
  if value[1] == nil then return nil end
  if _G.type(value[1]) ~= "table" then return nil end
  if tonumber(value[1].id) == nil then return nil end
  return value
end

local function scalar_input(value)
  if value == nil then return nil end
  local t = _G.type(value)
  if t ~= "string" and t ~= "number" then return nil end
  return value
end

function getData(queryType , pageFrom , perPage , pageTo )
  ---- init Query
  local dataQuery = {
    query = teamyar.get_attachment("query_list_invoice.txt") ,
    params = {}
  };
  ---- Select
  local config = teamyar.get_config()
  local cdata={}
  local r_nummber = 0
  local f_nummber = 0
  local m_nummber = 0

  if config ~= nil then
    cdata = config.data
    -- باگ اصلاح‌شده: قبلاً f_nummber/m_nummber هم از cdata.rnumber می‌خواندند (کپی/پیست) —
    -- یعنی وزن F و M همیشه نادیده گرفته می‌شد. هرکدام باید از فیلد پیکربندی خودش بخواند.
    r_nummber = cdata.rnumber
    f_nummber = cdata.fnumber
    m_nummber = cdata.mnumber
  end

  local user_info = teamyar.get_user_info()
  local time_zone = user_info.timezone
  local ctype = getInput("ctype");
  local cat = getInput("cat");
  local org = getInput("org");
  -- بازگردانده شد: فیلتر "مشتری" واقعاً در data.js بات ۵۰۱ وجود دارد (name: "crm"، aclId=7 →
  -- crmAcl) — قبلاً به اشتباه به‌عنوان کد مرده حذف شده بود
  local crm = getInput("crm");
  local datef = getInput("datef");
  local datet = getInput("datet");
  ---- نرمال‌سازی: userdata نال (فیلد ارسال‌نشده) به nil تبدیل می‌شود
  ctype = acl_selection(ctype)
  cat = acl_selection(cat)
  org = acl_selection(org)
  crm = acl_selection(crm)
  datef = scalar_input(datef)
  datet = scalar_input(datet)
  local qs = getQuery_select(queryType)
  local inp = teamyar.get_input()

  ---- invoice Filter (queryTools.where — دست‌نخورده مثل بات ۵۰۱: این placeholder روی نتیجهٔ
  ---- نهایی CTE «data» اعمال می‌شود، جایی که ستون‌های ORG_ID/USER_TYPE در دسترس نیستند؛ برای
  ---- همین org/ctype/cat/crm را نمی‌شود از این مسیر فیلتر کرد — پایین‌تر داخل crm_factor انجام می‌شود)
  local where_str=" 1=1 "
  dataQuery.query , dataQuery.params  = queryTools.where:init({where_str})
  .run( dataQuery.query ,  dataQuery.params , "{{whereInvoice}}");

  ---- page Number Query
  dataQuery.query = string.gsub(dataQuery.query,"{{slicePageNumber}}", getQuery_page(queryType , pageFrom , perPage , pageTo));
  dataQuery.query = string.gsub(dataQuery.query,"{{select}}",qs);

  local where_cat = ""
  local where_ctype= ""
  local where_crm= ""
  local where_org = ""
  if cat ~= nil and cat[1] ~= nil and tonumber(cat[1].id) ~= nil then
    -- alias اصلاح‌شده: بود "c.id" (در FROM وجود نداشت، کد مرده) -> "p.id" (alias واقعی pa_client)
    where_cat = where_cat.. [[ and p.id in (select CLIENT_ID from crm_cross where REFERE_ID =]]..tonumber(cat[1].id)..[[ )]]
  end
  if ctype ~= nil and ctype[1] ~= nil and tonumber(ctype[1].id) ~= nil then
    -- نیازمند LEFT JOIN profile_user_info ui ON ui.id = p.REFFERE_ID در پیوست (اصلاح‌شده جدا ارسال شد)
    where_ctype = where_ctype.. [[ and ui.USER_TYPE=]]..tonumber(ctype[1].id)
  end
  -- توجه: این شرط عیناً از بات ۵۰۱ کپی شده و مشکوک به نظر می‌رسد (شناسه مشتری انتخابی را با
  -- ستون USER_TYPE مقایسه می‌کند — همان کپی/پیست ctype، نه یک شرط معنادار برای «مشتری»).
  -- طبق درخواست شما فقط ظاهر/باگ‌ها را برطرف کنم، این خط دست‌نخورده مانده — بگویید اگر بخواهید اصلاح شود.
  if crm ~= nil and crm[1] ~= nil and tonumber(crm[1].id) ~= nil then
    where_crm = where_crm.. [[ and ui.USER_TYPE=]]..tonumber(crm[1].id)
  end
  if org ~= nil and org[1] ~= nil and tonumber(org[1].id) ~= nil then
    where_org = where_org.. [[ and s.org_id=]]..tonumber(org[1].id)..[[ and p.org_id=]]..tonumber(org[1].id)
  end

  ---- تاریخ: باگ اصلی همین‌جا بود. قبلاً نبودن مقدار => 0 (تاریخ صفر سیستم، یعنی کل تاریخچه).
  ---- طبق خواستهٔ شما بدون منطق سال مالی، فقط پیش‌فرض را از 0 به «امروز» تغییر دادیم: نبودن
  ---- فیلتر حالا بازهٔ خالی/تقریباً خالی نشان می‌دهد (سیگنال واضح)، نه کل تاریخچه به‌اشتباه.
  ---- توجه دوم: چون data.txt نوع datef/datet را "number" declare کرده، خود فریم‌ورک (getParamToNumber)
  ---- مقدار غیرعددی را قبل از رسیدن به اینجا بی‌صدا به 0 تبدیل می‌کند (نه nil) — پس چک == nil
  ---- به‌تنهایی کافی نیست و کوئری بدون فیلتر روی جدول میلیونی sales_invoice اجرا می‌ماند (همان
  ---- «لودینگ می‌ماند»). با <= 0 هم مقدار nil-شده و هم صفرشده را می‌گیرد.
  if tonumber(datet) == nil or tonumber(datet) <= 0 then
    datet = currentdate
  end
  if tonumber(datef) == nil or tonumber(datef) <= 0 then
    datef = currentdate
  end
  dataQuery.query = string.gsub(dataQuery.query,"{{datet}}",datet);
  dataQuery.query = string.gsub(dataQuery.query,"{{datef}}",datef);
  dataQuery.query = string.gsub(dataQuery.query,"{{current_date}}",currentdate);
  dataQuery.query = string.gsub(dataQuery.query,"{{where_cat}}",where_cat);
  dataQuery.query = string.gsub(dataQuery.query,"{{where_crm}}",where_crm);
  dataQuery.query = string.gsub(dataQuery.query,"{{where_ctype}}",where_ctype);
  dataQuery.query = string.gsub(dataQuery.query,"{{where_org}}",where_org);
  dataQuery.query = string.gsub(dataQuery.query,"{{r_number}}",r_nummber);
  dataQuery.query = string.gsub(dataQuery.query,"{{f_number}}",f_nummber);
  dataQuery.query = string.gsub(dataQuery.query,"{{m_number}}",m_nummber);
  ---- Execute Query
  teamyar.write_log(dataQuery.query)
  return getQuery_result(queryType , dataQuery);
end

--------------------------------------------

function getQuery_select(queryType)
  if queryType == _QUERY_TYPE._TYPE_TOTAL_SUM then
    return getTableConfig_sum()
  elseif queryType == _QUERY_TYPE._TYPE_TOTAL_COUNT then
    return getTableConfig_count()
  else
    return getTableConfig_select();
  end
end
--------------------------------------------
function getQuery_page(queryType , pageFrom , perPage , pageTo)
  local slicePageNumber = "";
  if queryType == _QUERY_TYPE._TYPE_PAGE_REPORT then
    local limit = tonumber(perPage);
    local offset = tonumber(pageFrom) ;
    slicePageNumber = "LIMIT "..limit .. " OFFSET "..offset;
  elseif queryType == _QUERY_TYPE._TYPE_PAGE_EXCEL then
    local limit = tonumber(perPage)*(tonumber(pageTo)  - tonumber(pageFrom) + 1) ;
    local offset = tonumber(perPage) *(tonumber(pageFrom) - 1);
    slicePageNumber = "LIMIT "..limit.." OFFSET "..offset;
  end
  return slicePageNumber;
end
--------------------------------------------
function getQuery_result(queryType , dataQuery)
  local resultExp = nil;

  db.query(dataQuery)
  local record={};
  if queryType == _QUERY_TYPE._TYPE_TOTAL_COUNT then
    record = db.query_fetch();
    resultExp = record[1];
  elseif queryType == _QUERY_TYPE._TYPE_TOTAL_SUM then
    local columnsSelected = {};
    local columns = getTableConfig();
    for i = 1, #columns , 1 do
      local itemColumns = columns[i];
      if itemColumns.key ~= nil and itemColumns.sum ~= nil and itemColumns.sum == true then
        table.insert(columnsSelected , itemColumns.key)
      end
    end
    if #columns > 0 then
      resultExp = {};
      record = db.query_fetch();
      for i = 1, #columnsSelected , 1 do
        resultExp[columnsSelected[i]] = record[i];
      end
    end
  else
    resultExp = {};
    while db.query_fetch(record) do
      local itemRow = {};
      local columns = getTableConfig();
      for i = 1, #columns , 1 do
        local itemColumns = columns[i];
        if itemColumns.key ~= nil then
          itemRow[itemColumns.key] = record[i];
        end
      end
      table.insert(resultExp, itemRow)
    end
  end
  db.query_free();

  return resultExp;
end

--------------------------------------------
function getTableConfig()
  local cols = {


    {show = true ,    key = "Customer"           , value= "Customer" } ,
    {show = true ,    key = "mobile"           , value= "mobile" } ,
    {show = true ,    key = "factor_link"           , value= "factor_link" } ,
    {show = true ,    key = "Days"           , value= "Days" ,type="price"} ,
    {show = true ,    key = "LastRunDate"           , value= "LastRunDate",type="date" } ,
    {show = true ,   key = "Frequency"                  		 , value = "Frequency" } ,
    {show = true ,   key = "Monetary"                  		 , value = "Monetary" ,type="price" } ,
    {show = true ,   key = "rd"                  		 , value = "R" } ,
    {show = true ,   key = "fd"                  		 , value = "F" } ,
    {show = true ,   key = "md"                  		 , value = "M" } ,
    {show = true ,   key = "rfm"                  		 , value = "RFM" } ,
    {show = true ,   key = "segment"                  		 , value = "Segment" } ,
    {show = true ,   key = [[concat("<input type='checkbox' id='ch_save_",crm_id,"' name='ch_save' oninput='ty__main.onChangeCheckInput(",crm_id,")' >")]]  , value ="" } ,
    {show = true ,   key =  [[concat ( "<button type='button' id='mdp_print_btn' style='float:left;'
      class='btn ty-btn-default core_btn btnforsubmit core_btn_submit_Form core_btn_revers_change ty-btn-ok'
      onclick='ty__main.send_sms(",crm_id,")'>Send SMS</button>")]]                		 , value = "" } ,
  };
  --   teamyar.write_log("ffcols6"..json.encode(cols))
  return cols
end
--------------------------------------------
function getTableConfig_sum()
  teamyar.write_log("summ --")
  local columnsSelected = {};
  local select = "";
  local columns = getTableConfig();
  for i = 1, #columns , 1 do
    local itemColumns = columns[i];
    if itemColumns.key ~= nil and itemColumns.sum ~= nil and itemColumns.sum == true then
      table.insert(columnsSelected , itemColumns.key)
    end
  end
  for i = 1, #columnsSelected , 1 do
    local itemColumnsSelected = columnsSelected[i];
    select = select .."sum("..itemColumnsSelected..")"
    if i < #columnsSelected   then
      select = select..",";
    end
  end
  return select;
end
--------------------------------------------
function getTableConfig_select()
  local columnsSelected = {};
  local select = "";
  local columns = getTableConfig();
  for i = 1, #columns , 1 do
    local itemColumns = columns[i];
    if itemColumns.key ~= nil then
      table.insert(columnsSelected , itemColumns.key)
    end
  end
  for i = 1, #columnsSelected , 1 do
    local itemColumns = columnsSelected[i];
    select = select..itemColumns;
    if i < #columns   then
      select = select.. ",";
    end
  end
  return select;
end
--------------------------------------------
function getTableConfig_count()
  return "count(*)";
end
--------------------------------------------
function getTableConfig_header()
  local headers = {};
  local totalHeader = getTableConfig();
  for i = 1, #totalHeader , 1 do
    local itemHeader = totalHeader[i];
    if itemHeader.show ~= nil and itemHeader.show == true then
      table.insert(headers ,itemHeader );
    end
  end
  return headers;
end
---------------------------------------------
function queryResultAcl(select_query,user_param)
  db.use_db("0000000")
  local params = {
    query = select_query,
    params = user_param
  }
  db.query(params);
  local res_text={};
  local record={};
  while db.query_fetch(record) do
    local tmp=record;
    table.insert(res_text, {id = record[1], name = record[2], type =1});
  end
  db.query_free();
  return res_text;
end
----------------------
function catAcl(data)
  local section_id = data.section;
  local query_param = [[ select c.PROFILE_ID ,concat(s.SECTION_NAME,'/',c.name) from crm_classify_person c inner join crm_section s on s.id=c.section_id  ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  and c.name like N'%]]..data.search..[[%'  or  s.SECTION_NAME like N'%]]..data.search..[[%'  ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end
----------------------
function crmAcl(data)
  local org_id = data.org_id;
  local query_param = [[ select id,name from pa_client where org_id=]]..org_id
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  and name like N'%]]..data.search..[[%'  or  id like N'%]]..data.search..[[%'  ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end


----------------------
function ctypeAcl(data)

  local table = {
    {id =3,name=translateWord("REAL")},
    {id =4,name=translateWord("LEGAL")},

  }
  teamyar.write_result(json.encode(table));
end

--------------------------------------------
--- Report
--------------------------------------------
function report()
  local data= getTableSectionOne()
  local report = {
    {
      name = "table" ,
      title = "table" ,
      report = data
    }
  }
  return report;
end
--------------------------------------------
function getTableSectionOne()
  -- توجه: تلاش قبلی برای رد کردن کوئری روی لود خودکار اول صفحه (با page_search_first) باعث شد
  -- کل فرم فیلتر لود نشود — برگردانده شد به حالت ساده (همیشه کوئری واقعی، فقط با fallback تاریخ
  -- <=0 که قبلاً تأیید شد کار می‌کند). رفع «کوئری زودتر از انتخاب فیلتر اجرا نشود» نیاز به بررسی
  -- زنده دارد (چرا نسخهٔ قبلی فرم را می‌شکست) — فعلاً برای این‌که چیزی که کار می‌کرد را خراب نکنیم،
  -- به عقب برگشت.
  local repId = getInput("rep_id");
  local headers = getTableConfig_header();
  local from = getInput("page");
  local values  = getData(_QUERY_TYPE._TYPE_PAGE_REPORT , from , _PAR_PAGE);
  local total  = getData(_QUERY_TYPE._TYPE_TOTAL_COUNT);
  --local sums  = getData(_QUERY_TYPE._TYPE_TOTAL_SUM , from , _PAR_PAGE);
  return install_res.resTable(repId , headers , values  , total , _PAR_PAGE , from,sums );
end
--------------------------------------------
--- excel
--------------------------------------------
function excel()
  local excelFileName = getInput("excel_file_name");
  local excelFormPage = getInput("excel_from_page");
  local excelToPage = getInput("excel_to_page");
  local excelPerPage = getInput("excel_per_page");
  local headers = getTableConfig_header();
  local values = getData(_QUERY_TYPE._TYPE_PAGE_EXCEL ,  excelFormPage , excelPerPage , excelToPage)
  return install_res.resExcel( headers , values , excelFileName);
end
--------------------------------------------
--- print
--------------------------------------------
function print()
  local headers = getTableConfig_header();
  local values = getData(_QUERY_TYPE._TYPE_PAGE_PRINT)
  return install_res.resPrint( headers , values);
end
--------------------------------------------
--- manager
--------------------------------------------
function confirmTodo(tid)
  teamyar.write_log("tttttttt---"..tid)
  local js={confirm=1}
  local info =	{
    id= tid,
    type= 5,
    form_data=json.encode(js)
  }
  teamyar.write_log(json.encode(info))
  local   res = teamyar.call_api(8, '/api/todo/customform/update', info);
  teamyar.write_log(json.encode(res))
  return json.encode(res)
end
--------------------------------------------
function getAclOrg(data)
  local query_param = [[  select id,name from org_info ]]
  if data.search ~= nil and #data.search > 0 then
    query_param = query_param..[[  where name like N'%]]..data.search..[[%' ]]
  end
  query_param = query_param .. string.format(" limit %d,%d ", data.from, data.count);
  teamyar.write_result(json.encode(queryResultAcl(query_param, {})));
end

-------------------------------------------
function queryResultcrm(select_query,user_param)
  db.use_db("0000000")
  local params = {
    query = select_query,
    params = user_param
  }
  db.query(params);
  local res_text = {};
  local record = {};
  while db.query_fetch(record) do
    table.insert(res_text, {name = record[1], farsidate = record[2], gender = record[3]});
  end
  db.query_free();
  return res_text;
end
--------------------------------------------
function sendSms(crm_id,segment,box_id,txt)
  local res_str=""
  local q = [[select p.fullname,(select jndate from report_dimdate where ]]..currentdate..[[
  between datekey and datekey+(60*60*24*10000000)-(60*10000000)) dd,(case when uf.sex=2 then 'خانم' else 'آقا' end) gender
  from profile_main p inner join profile_user_info uf on uf.id=p.id where p.id=]]..crm_id
  teamyar.write_log(q)
  local data = queryResultcrm(q, {})
    teamyar.write_log(json.encode(data))
  txt = string.gsub(txt, "{{name}}", data[1].name);
  txt = string.gsub(txt, "{{date}}", data[1].farsidate);
  txt = string.gsub(txt, "{{gender}}", data[1].gender);
  local info =	{box_id = box_id,messages = {{content = txt, send_to = {profile_ids = {crm_id}}}}, module_id = 26}
  teamyar.write_log("info----"..json.encode(info))
  local   res = teamyar.call_api(16, '/api/sms/send', info);
  teamyar.write_log("res----"..json.encode(res))
  if res.success ==true then
    res_str="<div style='color:green;'>".."ارسال پیامک برای کاربر :  "..crm_id.." ،  شناسه پیامک :"..res.data.message_ids[1].."</div>"
  else
    res_str="<div style='color:red;'>".."خطا در ارسال پیامک :  "..res.error.message.."<div>"

  end
  return res_str
end
------------
function split(str, delimiter)
  local result = {}
  local pattern = "(.-)" .. delimiter .. "()"
  local lastPos = 1

  for part, pos in string.gmatch(str .. delimiter, pattern) do
    table.insert(result, part)
    lastPos = pos
  end

  return result
end
--------------------------------------------
local type = getInput("type");
if type ~= nil and type == 100 then
  local result = report()
  teamyar.write_result(json.encode(result));

elseif type ~= nil and type == 9 then
  catAcl(teamyar.get_input().data)
elseif type ~= nil and type == 8 then
  ctypeAcl(teamyar.get_input().data)
elseif type ~= nil and type == 7 then
  crmAcl(teamyar.get_input().data)
elseif type ~= nil and type == 6 then
  getAclOrg(teamyar.get_input().data)
elseif type ~= nil and type == 10 then
  local input = teamyar.get_input()
  local res_str = sendSms(input.data.crm_id,input.data.segment,input.data.box_id, input.data.txt)
  local res_data = {msg = res_str}
  teamyar.write_result(json.encode(res_data))
elseif type ~= nil and type == 11 then
  local input = teamyar.get_input()
  local data = input.data
  local crms = split(data.crms, ',')
  local res_str = ""
  local count_send = 0
  for i,v in ipairs (crms) do
    local crm_id_in = string.sub(v, 0, #v-3)
    local segment_in = string.sub(v, #v-3, #v)
    sendSms(crm_id_in, segment_in, data.box_id, data.txt)
    count_send = count_send+1
  end
  res_str = " تعداد  "..count_send.." پیامک ارسال شد ."
  local res_data={msg=res_str}
  teamyar.write_result(json.encode(res_data))
elseif type ~= nil and type == 101 then
  local result = excel()
  teamyar.write_result(json.encode(result));
elseif type ~= nil and type == 102 then
  local result = print()
  teamyar.write_result(json.encode(result));
else
  local responseResReport = install_res.resReport(getTableConfig());
  teamyar.write_result(responseResReport);
end
