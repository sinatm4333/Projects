-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/06/06 17:05
-- botName = sales_settlement_backfill_queue
-- creator = Cascade (کپی بات 582 — بدون UI/پیوست، برای بک‌فیل یک‌باره‌ی حجم انبوه)
-- date = 1405/06/05
-- version = 1.0
-- توضیح: تسویه خودکار انبوه (بک‌فیل عقب‌افتاده — مثلاً ~۴۰۰٬۰۰۰ فاکتور)، کپی جدا از بات
--   ۵۸۲ (که دست‌نخورده می‌ماند). تفاوت اصلی نسبت به ۵۸۲: به‌جای پردازش نامحدود همه‌ی
--   فاکتورهای منطبق در یک اجرا (که برای این حجم یا timeout می‌خورد یا با
--   max_execute_time خیلی بزرگ چندین ساعت طول می‌کشد و اگر وسط راه قطع شود هیچ اثری
--   از پیشرفت نمی‌ماند)، این نسخه **زمان‌محور** کار می‌کند: تا نزدیک سقف
--   max_execute_time بات (رزرو ایمنی زیر آن) پردازش می‌کند، بعد تمیز متوقف می‌شود و
--   گزارش می‌دهد چند تا انجام شد / چند تا مانده. چون فاکتور تسویه‌شده خودش از شرط
--   کوئری (not in sales_invoice_settlement) خارج می‌شود، هر اجرای بعدی خودکار از همان
--   نقطه ادامه می‌دهد — نیازی به ذخیره‌ی offset/checkpoint نیست.
--   **اجرای مکرر لازم است** تا صف کامل خالی شود (دستی چندبار، یا با زمان‌بندی بات
--   در پنل Teamyar اگر این قابلیت را دارد).
--------------------------------------------
--- CONFIG DATA
--------------------------------------------
-- سقف زمانی این اجرا: باید کمی (مثلاً ۱۰-۱۵٪) کمتر از max_execute_time واقعی بات
-- روی پنل باشد تا مهلت کافی برای پاک‌سازی/برگشت نتیجه هم بماند. اگر max_execute_time
-- بات را روی پنل ۱۸۰۰۰ ثانیه گذاشتید، این را حدود ۱۶۲۰۰ نگه دارید.
local _MAX_RUNTIME_SECONDS = 16200;
-- سقف تعداد ردیف در همان یک کوئری SELECT (صرفاً برای محدود نگه‌داشتن حافظه‌ی یک اجرا؛
-- در عمل به‌خاطر سقف زمانی بالا معمولاً خیلی زودتر از این عدد اجرا متوقف می‌شود)
local _QUERY_ROW_LIMIT = 50000;
-- بازه‌ی تسویه = کل یک سال مالی (نه day_befor از کانفیگ)، مشخص‌شده به‌صورت نسبت به
-- سال مالی «جاری» (همانی که شامل امروز است): 0 = جاری، 1 = یک سال قبل از جاری (۱۴۰۴
-- وقتی جاری ۱۴۰۵ باشد). برای اجرای بعدی روی سال مالی ۱۴۰۵، این را 0 کنید و دوباره
-- دیپلوی کنید. (REPORT_FN_JDATE عمداً استفاده نشده — روی این پلتفرم از طریق db.query
-- خام همیشه «sql error» می‌داد، چه با LIKE چه با CASE محافظت‌شده روی NULL/0.)
local _FISCAL_YEARS_BACK = 1;
--------------------------------------------
local config = teamyar.get_config()
local config_data = {}
local c_account_code = 0
local c_client_code = 0
local c_float_code = 0
local c_center_code = 0
local c_project_code = 0
-- «نوع تسویه» هارد شده، نه از کانفیگ خونده می‌شه — چون هر چیزی که get_config برای
-- kind برمی‌گردوند، API تسویه رو با «نوع تسویه را مشخص کنید» رد می‌کرد؛ طبق درخواست
-- کاربر مستقیم مقدار «نقد» (که همون چیزیه که تو تب پیکربندی هم انتخاب شده بود) هارد شد.
-- طبق bot_config: لیست kind = [["4","نقد"],["5","حساب"]] → نقد = "4".
local c_kind = "4";
local c_day_befor = 0
local c_org_id = 0

-- کانفیگ بات مقادیر عددی رو با ارقام فارسی (۰۱۲۳۴۵۶۷۸۹) ذخیره می‌کنه، نه ارقام
-- انگلیسی — دقیقاً همین چیزی بود که «نوع تسویه را مشخص کنید» رو باعث می‌شد (kind="۴"
-- فارسی، نه "4" انگلیسی که bot_config انتظار داشت). account_code هم همین مشکل رو
-- دارد ("۱۰۱۰۰۱۰۰۴") — خطای مشابهی نداده، ولی برای اطمینان (چون کد حساب واقعی روی
-- تسویه‌ی مالی واقعی اثر می‌گذارد) همه‌ی کدهای کانفیگ رو به ارقام انگلیسی تبدیل می‌کنیم.
local _FA_TO_EN_DIGITS = {
  ["۰"] = "0", ["۱"] = "1", ["۲"] = "2", ["۳"] = "3", ["۴"] = "4",
  ["۵"] = "5", ["۶"] = "6", ["۷"] = "7", ["۸"] = "8", ["۹"] = "9",
};
function toAsciiDigits(v)
  if v == nil then return v; end
  local s = tostring(v);
  for fa, en in pairs(_FA_TO_EN_DIGITS) do
    s = string.gsub(s, fa, en);
  end
  return s;
end

if config ~= nil then
  config_data = config.data
  c_account_code = toAsciiDigits(config_data.account_code)
  c_client_code = toAsciiDigits(config_data.client_code)
  c_float_code = toAsciiDigits(config_data.float_code)
  c_center_code = toAsciiDigits(config_data.center_code)
  c_project_code = toAsciiDigits(config_data.project_code)
  c_day_befor = tonumber(toAsciiDigits(config_data.day_befor)) or 0
  c_org_id = tonumber(toAsciiDigits(config_data.org_id)) or 0
end
teamyar.write_log("backfill config_data raw: " .. json.encode(config_data)
  .. " | type(kind)=" .. type(c_kind));
local day = time.get_day(time.current());
local month = time.get_month(time.current());
local year = time.get_year(time.current());
local hour = time.get_hour(time.current());
local min = time.get_minute(time.current());
local sec = time.get_second(time.current());
local currentdate_time = time.get_filetime([[{"year":]] .. year .. [[,"month":]] .. month .. [[,"day":]] .. day .. [[,"hour":]] .. hour .. [[,"minute":]] .. min .. [[,"second":]] .. sec .. [[}]])
local temp_time = time.get_filetime([[{"year":]] .. year .. [[,"month":]] .. month .. [[,"day":]] .. day .. [[,"hour":0,"minute":0,"second":0}]])
local currentdate = string.format("%18.0f", temp_time);

-- بازه‌ی تسویه: بازه‌ی دقیق یک سال مالی از pa_fiscal_year، بدون هیچ استفاده‌ای از
-- REPORT_FN_JDATE (که روی این پلتفرم از طریق db.query خام، هم با LIKE و هم با CASE
-- محافظت‌شده روی NULL/0، همیشه «sql error» می‌داد — به نظر می‌رسد این تابع فقط از
-- مسیر داخلی گزارش‌ساز Teamyar قابل‌فراخوانی است، نه از db.query دلخواه). به‌جایش:
-- همه‌ی سال‌های مالی این سازمان را با ستون‌های خام (بدون هیچ تابعی) می‌گیریم، سال
-- مالیِ «جاری» (شاملِ امروز) را در خود Lua پیدا می‌کنیم، و بر اساس _FISCAL_YEARS_BACK
-- چند ردیف عقب‌تر می‌رویم. اگر برای این org_id چیزی پیدا نشد، برمی‌گردیم به رفتار
-- قدیمی (day_befor نسبت به امروز) تا بات بی‌صدا روی کل تاریخچه اجرا نشود.
function fetchFiscalYearRange(orgId, yearsBack, todayTicks)
  local q = [[
    SELECT fy.START_DATE, fy.END_DATE
    FROM pa_fiscal_year fy
    WHERE fy.ORG_ID = ]] .. tostring(tonumber(orgId) or 0) .. [[
      AND fy.START_DATE IS NOT NULL AND fy.START_DATE <> 0
      AND fy.END_DATE IS NOT NULL AND fy.END_DATE <> 0
    ORDER BY fy.START_DATE DESC
  ]];
  local ok, err = pcall(function()
    db.use_db("0000000");
    db.query({ query = q, params = {} });
  end);
  if not ok then
    teamyar.write_log("fetchFiscalYearRange sql error ---- " .. tostring(err) .. " ---- query was: " .. q);
    pcall(db.query_free);
    return nil, nil;
  end

  -- الگوی while db.query_fetch(record) با جدول از پیش ساخته‌شده — همان الگوی
  -- امتحان‌پس‌داده‌ی queryResultFact در همین فایل.
  local rows = {};
  local record = {};
  while db.query_fetch(record) do
    table.insert(rows, { startDate = record[1], endDate = record[2] });
  end
  db.query_free();

  teamyar.write_log("fetchFiscalYearRange rows for org_id=" .. tostring(orgId) .. ": "
    .. json.encode(rows));

  -- rows بر اساس START_DATE نزولی مرتب است (جدیدترین سال مالی اول). سال «جاری» یعنی
  -- ردیفی که امروز بین START_DATE و END_DATEاش قرار می‌گیرد.
  local currentIdx = nil;
  for i, row in ipairs(rows) do
    local s = tonumber(row.startDate);
    local e = tonumber(row.endDate);
    if s ~= nil and e ~= nil and todayTicks >= s and todayTicks <= e then
      currentIdx = i;
      break;
    end
  end
  if currentIdx == nil then
    teamyar.write_log("fetchFiscalYearRange: no fiscal year row for org_id=" .. tostring(orgId)
      .. " contains today (rows found=" .. #rows .. ")");
    return nil, nil;
  end

  local targetIdx = currentIdx + yearsBack;
  local target = rows[targetIdx];
  if target == nil then
    teamyar.write_log("fetchFiscalYearRange: no row at index " .. targetIdx
      .. " (current fiscal year index=" .. currentIdx .. ", yearsBack=" .. yearsBack .. ", total rows=" .. #rows .. ")");
    return nil, nil;
  end
  return tostring(target.startDate), tostring(target.endDate);
end

local from_date, to_date;
local fy_start, fy_end = fetchFiscalYearRange(c_org_id, _FISCAL_YEARS_BACK, temp_time);
if fy_start ~= nil and fy_end ~= nil then
  from_date = fy_start;
  to_date = fy_end;
  teamyar.write_log("backfill using fiscal year (yearsBack=" .. _FISCAL_YEARS_BACK .. ") for org_id=" .. tostring(c_org_id)
    .. " — from_date=" .. from_date .. " to_date=" .. to_date);
else
  from_date = string.format("%18.0f", (temp_time - ((60 * 60 * 24 * 10000000 * c_day_befor) + (60 * 60 * 24 * 10000000))))
  to_date = tostring(currentdate + (60 * 60 * 3 * 10000000))
  teamyar.write_log("backfill: fiscal year (yearsBack=" .. _FISCAL_YEARS_BACK .. ") not found for org_id=" .. tostring(c_org_id)
    .. " — falling back to day_befor range: from_date=" .. from_date .. " to_date=" .. to_date);
end

-- زمان شروع اجرا (FILETIME، واحد ۱۰۰نانوثانیه) برای سنجش سقف زمانی
local _RUN_START = currentdate_time;
local FILETIME_PER_SECOND = 10000000;
function elapsedSeconds()
  local now = time.get_filetime([[{"year":]] .. time.get_year(time.current()) .. [[,"month":]] .. time.get_month(time.current())
    .. [[,"day":]] .. time.get_day(time.current()) .. [[,"hour":]] .. time.get_hour(time.current())
    .. [[,"minute":]] .. time.get_minute(time.current()) .. [[,"second":]] .. time.get_second(time.current()) .. [[}]]);
  return (now - _RUN_START) / FILETIME_PER_SECOND;
end
--------------------------------------------
function queryResult(select_query, user_param)
  db.use_db("0000000");
  local params1 = {
    query = select_query,
    params = user_param
  }
  db.query(params1);
  local res_text = db.query_fetch();
  db.query_free();
  return res_text[1];
end
-------------------------------------------
function queryResultFact(select_query, user_param)
  db.use_db("0000000")
  local params = {
    query = select_query,
    params = user_param
  }
  db.query(params);
  local res_text = {};
  local record = {};
  while db.query_fetch(record) do
    table.insert(res_text, {
      id = record[1],
      org_id = record[2],
      date = record[3],
      amont = record[4],
      ps_id = record[5],
      decimal = record[6],
      symbol_name = record[7],
      symbol_rate = record[8],
      client = record[9],
      float = record[10],
      prj = record[11],
      center = record[12],
    });
  end
  db.query_free();
  return res_text;
end
-------------------------------------------------------------
-- جدول اختصاصی این بات برای فاکتورهایی که با خطای دائمی («سند مربوطه امضا شده است»)
-- رد شده‌اند. بدون این جدول، این فاکتورها چون هیچ‌وقت در sales_invoice_settlement ثبت
-- نمی‌شوند، هر اجرا دوباره در صف ظاهر و دوباره رد می‌شوند (گزارش کاربر ۱۴۰۵/۰۶/۰۶:
-- «هر دفعه بات رو ران می‌کنی دوباره همون فاکتورها رو میاره و تسویه نمی‌کنه»).
-- idempotent — هر اجرا فقط اگر جدول از قبل نباشد می‌سازدش.
-------------------------------------------------------------
function ensurePermanentSkipTable()
  db.use_db("0000000");
  local ddl = [[
    CREATE TABLE IF NOT EXISTS sales_settlement_permanent_skip (
      ID bigint NOT NULL AUTO_INCREMENT,
      ORG_ID bigint NOT NULL,
      INVOICE_ID bigint NOT NULL,
      REASON varchar(500) NOT NULL,
      DATE_CREATE bigint NOT NULL,
      PRIMARY KEY (ID),
      UNIQUE KEY UQ_ORG_INVOICE (ORG_ID, INVOICE_ID)
    ) ENGINE=InnoDB
  ]];
  local ok, err = pcall(function()
    db.query({ query = ddl, params = {} });
  end);
  if not ok then
    teamyar.write_log("ensurePermanentSkipTable error ---- " .. tostring(err));
  end
  pcall(db.query_free);
  return ok;
end

-- ثبت یک فاکتور در جدول ردهای دائمی — فقط برای خطاهای دائمی (امضا شده)؛ خطاهای دیگر
-- عمداً اینجا ثبت نمی‌شوند چون ممکن است موقتی باشند و باید در اجرای بعد دوباره امتحان شوند
function recordPermanentSkip(orgId, invoiceId, reason)
  db.use_db("0000000");
  local truncatedReason = string.sub(tostring(reason), 1, 500);
  local sql = [[
    INSERT INTO sales_settlement_permanent_skip (ORG_ID, INVOICE_ID, REASON, DATE_CREATE)
    VALUES (?, ?, ?, ?)
    ON DUPLICATE KEY UPDATE REASON = VALUES(REASON), DATE_CREATE = VALUES(DATE_CREATE)
  ]];
  local params = { tonumber(orgId), tonumber(invoiceId), truncatedReason, currentdate_time };
  local ok, err = pcall(function()
    db.query({ query = sql, params = params });
  end);
  if not ok then
    teamyar.write_log("recordPermanentSkip error (invoice " .. tostring(invoiceId) .. ")----" .. tostring(err));
  end
  pcall(db.query_free);
  return ok;
end

-- اگر CREATE TABLE به هر دلیلی شکست بخورد (مثلاً کاربر DB این بات فقط دسترسی DML دارد،
-- نه DDL)، نباید کل بات (که قبل از این ویژگی فقط SELECT/API می‌زد) از کار بیفتد؛ در آن
-- حالت شرط NOT IN زیر اصلاً به کوئری اضافه نمی‌شود و رفتار به همان قبل (بدون این فیلتر)
-- برمی‌گردد — recordPermanentSkip هم پایین‌تر با همین pcall صرفاً لاگ می‌کند، صف را نمی‌شکند.
local _skipTableReady = ensurePermanentSkipTable();
local skipTableClause = "";
if _skipTableReady then
  skipTableClause = " and i.id not in (select INVOICE_ID from sales_settlement_permanent_skip where ORG_ID = "
    .. c_org_id .. ") ";
else
  teamyar.write_log("backfill: sales_settlement_permanent_skip در دسترس نیست — فیلتر امضا-دائمی غیرفعال این اجرا");
end
-------------------------------------------------------------
-- کوئری فیلتر — عیناً از بات 582. order by + limit فقط برای کران‌دار نگه‌داشتن یک
-- SELECT اضافه شده (نه برای صف‌بندی؛ صف‌بندی واقعی از طریق سقف زمانی پایین‌تر است)
-------------------------------------------------------------
local q = [[
        with DecimalDigits as(
         select po.ORG_ID,ps.DECIMAL_COUNT DecimalCount,(CASE WHEN COALESCE(ps.FEE_DECIMAL,0) = 0 THEN COALESCE(ps.DECIMAL_COUNT,0) ELSE COALESCE(ps.FEE_DECIMAL,0) END )DigitFee
         from pa_organizations po join pa_symbols ps on(po.BASE_CURRENCY = ps.ID and po.ORG_ID = ps.ORG_ID)
         ),cte_org as(
				SELECT i.id as INVOICE_ID,d.DECIMAL_COUNT Digit,
					CASE WHEN COALESCE(d.DECIMAL_COUNT,0) <> 0 THEN COALESCE(d.DECIMAL_COUNT,0) ELSE COALESCE(d.FEE_DECIMAL,0) END DigitFee
					FROM PA_ORGANIZATIONS c
					join SALES_INVOICE i on i.org_id = c.org_id
					INNER JOIN PA_SYMBOLS d ON (d.ID = c.BASE_CURRENCY AND d.ORG_ID = c.ORG_ID)
			) , cte_product as(
				select o.INVOICE_ID,if(Coalesce(d.QUANTITY_CONFIRMED,0)>0,Coalesce(d.QUANTITY_CONFIRMED,0),Coalesce(d.QUANTITY,0))
							as quantity,Coalesce(c.DECIMAL_NUM,0) as dec_quantity,
							Coalesce(d.BASE_SYMBOL_FEE,0) AS BASE_SYMBOL_FEE, Coalesce(o.DigitFee,0) AS DigitFee,
							Coalesce(o.Digit,0) AS Digit,Coalesce(d.BASE_SYMBOL_DISCOUNT,0) AS BASE_SYMBOL_DISCOUNT,Coalesce(d.BASE_SYM_VALUE_ADDED,0) AS BASE_SYM_VALUE_ADDED ,
							Coalesce(d.BASE_SYMBOL_TAX,0) AS BASE_SYMBOL_TAX,Coalesce(d.BASE_SYMBOL_TOLL,0) AS BASE_SYMBOL_TOLL
				from sales_invoice_product d
				join wh_product p on d.product_id = p.id
				join wh_stock_capacity c on p.CAPACITY_ID = c.ID
				join cte_org o on d.INVOICE_ID = o.INVOICE_ID
			) ,CTE_ADDITION as(

				SELECT  o.INVOICE_ID,
				SUM(ROUND(CASE WHEN (a.EFFECT = 1 OR a.EFFECT = 3) THEN (Coalesce(a.QUANTITY,0)/POWER(10,Coalesce(o.Digit,0)))*(-1) WHEN (a.EFFECT = 2 OR a.EFFECT = 4) THEN (Coalesce(a.QUANTITY,0)/POWER(10,Coalesce(o.Digit,0))) ELSE 0 END)) AS ADDITION
				FROM SALES_INVOICE_ADDITIONS a
				JOIN cte_org o ON a.INVOICE_ID = o.INVOICE_ID
				group by o.INVOICE_ID
			), CTE_AMOUNT_PRODUCTS AS(
				select INVOICE_ID,
				  SUM(ROUND((quantity/power(10,dec_quantity)* (BASE_SYMBOL_FEE/power(10,DigitFee)))
				  - BASE_SYMBOL_DISCOUNT/power(10,Digit) + BASE_SYM_VALUE_ADDED/power(10,Digit) + BASE_SYMBOL_TAX/power(10,Digit) + BASE_SYMBOL_TOLL/power(10,Digit))) as AMOUNT
				from cte_product
				group by INVOICE_ID
			)  ,amonts as (
            SELECT
						 ROUND(p.AMOUNT + Coalesce(a.ADDITION,0)) iamont ,
					 i.id id from  CTE_AMOUNT_PRODUCTS p
			LEFT JOIN CTE_ADDITION a ON p.INVOICE_ID = a.INVOICE_ID
			JOIN SALES_INVOICE i on i.ID = p.INVOICE_ID
			LEFT JOIN PA_CLIENT c on c.id = i.client_id and c.org_id = i.org_id
						)
        select distinct  i.id,i.org_id,i.RUN_DATE,(select iamont from amonts where id= i.id) amont,ps.id,FEE_DECIMAL,ps.SHORT_NAME sy_name,ps.SYMBOL_RATE,cl.code cl_code,fl.code fl_code,prj.code prj_code ,cn.code cn_code
         from sales_invoice i inner join pa_symbols ps on ps.id=i.SYMBOL_ID and ps.org_id= i.org_id left join DecimalDigits  dd on(i.ORG_ID = dd.ORG_ID)

 left join pa_client cl on cl.id=i.client_id and i.client_id > 0
 left join pa_floating fl on fl.id=i.FLOATING_ID
 left join pa_center cn on cn.id=i.SALES_CENTER
 left join pa_project prj on prj.id=i.project_id
         where  i.status= 2 and i.org_id=]] .. c_org_id .. [[  and ps.org_id=]] .. c_org_id .. [[  and i.id not in (select INVOICE_ID from sales_invoice_settlement) and i.type=1
          and i.deleted = 0
          ]] .. skipTableClause .. [[
          and i.RUN_DATE >=]] .. from_date .. [[  and i.RUN_DATE<=]] .. to_date .. [[
         order by i.RUN_DATE asc
         limit ]] .. _QUERY_ROW_LIMIT

-- تعداد کل فاکتورهای واجد شرایط (کل صف واقعی)، بدون اعمال LIMIT — فقط برای گزارش
-- i.deleted=0: عیناً از کوئری بات 612 (mySqlQuery.txt) اضافه شد — این کوئری (که از
-- بات 582 کپی شده بود) این شرط رو نداشت و فاکتورهایی رو می‌آورد که سند مربوطه‌شون
-- «امضا شده» بود (API با «سند مربوطه امضا شده است...» ردشون می‌کرد). بات 612 هیچ‌وقت
-- این‌ها رو نمی‌آورد، دقیقاً به‌خاطر همین شرط. اما این کافی نبود (گزارش کاربر
-- ۱۴۰۵/۰۶/۰۶) — deleted=0 فقط یک زیرمجموعه از فاکتورهای امضاشده را حذف می‌کرد؛
-- بقیه‌شان چون هیچ‌وقت در sales_invoice_settlement ثبت نمی‌شدند، همچنان هر اجرا دوباره
-- برمی‌گشتند. حالا هر فاکتوری که settleFactor با خطای «امضا» رد کند، در
-- sales_settlement_permanent_skip ثبت و از این کوئری هم حذف می‌شود (بالاتر: تعریف
-- ensurePermanentSkipTable/recordPermanentSkip).
local q_count = [[
  select count(*) cnt
  from sales_invoice i
  inner join pa_symbols ps on ps.id = i.SYMBOL_ID and ps.org_id = i.org_id
  where i.status = 2 and i.org_id=]] .. c_org_id .. [[ and ps.org_id=]] .. c_org_id .. [[
    and i.deleted = 0
    and i.id not in (select INVOICE_ID from sales_invoice_settlement)
    ]] .. skipTableClause .. [[
    and i.type = 1
    and i.RUN_DATE >=]] .. from_date .. [[ and i.RUN_DATE<=]] .. to_date

teamyar.write_log("backfill query ---" .. q)
local compelete_factors = queryResultFact(q, {})
local queue_total = tonumber(queryResult(q_count, {})) or #compelete_factors;

teamyar.write_log("backfill start — queue_total=" .. tostring(queue_total)
  .. " fetched_this_run=" .. #compelete_factors
  .. " max_runtime_seconds=" .. _MAX_RUNTIME_SECONDS);

if #compelete_factors == 0 then
  teamyar.write_result("صف خالی است — فاکتوری در این بازه زمانی و در حال اجرا یافت نشد");
  return;
end

--------------------------------------------
-- استخراج پیام خطای قابل‌خواندن از پاسخ API (error می‌تواند رشته یا جدول {message=...} باشد)
--------------------------------------------
function extractErrorMessage(res)
  if res == nil then return "پاسخ خالی از API"; end
  if res.error == nil then return nil; end
  if type(res.error) == "table" then
    return tostring(res.error.message or json.encode(res.error));
  end
  return tostring(res.error);
end

-- علامت تشخیص خطای «سند مربوطه امضا شده است» — این‌ها خطای دائمی/غیرقابل‌تلاش‌مجدد هستند
-- (فاکتور دیگر هیچ‌وقت از این مسیر تسویه نمی‌شود)، برخلاف بقیه‌ی خطاها که می‌توانند
-- موقتی باشند. جدا کردنشان در خلاصه‌ی خروجی لازم است تا معلوم شود «ناموفق» یعنی چه.
local _SIGNED_DOC_ERROR_MARKER = "امضا";

--------------------------------------------
-- تسویه‌ی یک فاکتور؛ history فقط روی تسویه‌ی واقعاً موفق ثبت می‌شود (همان رفع باگ 582)
-- خروجی: success, reason (reason فقط وقتی success=false پر است)
--------------------------------------------
function settleFactor(v)
  local info_settelment = {
    org_id = tonumber(c_org_id),
    invoice_id = tonumber(v.id),
    settlements = {
      {
        date = v.date,
        type = c_kind,
        price = tostring(v.amont),
        center_code = c_center_code,
        client_code = c_client_code,
        symbol_name = v.symbol_name,
        symbol_rate = "1",
        account_code = c_account_code,
        project_code = c_project_code,
        floating_code = c_float_code
      }
    }
  };

  local callOk, res_settelment = pcall(teamyar.call_api, 23, '/api/sales/create_settlement', info_settelment);
  if not callOk then
    local reason = "خطای فراخوانی API: " .. tostring(res_settelment);
    teamyar.write_log("create_settlement error (invoice " .. tostring(v.id) .. ")----" .. reason);
    return false, reason;
  end

  local success = res_settelment ~= nil and res_settelment.error == nil and res_settelment.success == true;
  if success then
    local info_log = {
      org_id = c_org_id,
      history = "ثبت تسویه در فاکتور توسط بات (بک‌فیل)",
      invoice_id = tonumber(v.id)
    };
    local logOk, res_log = pcall(teamyar.call_api, 23, '/api/sales/update_invoice_history', info_log);
    if not logOk then
      teamyar.write_log("update_invoice_history error (invoice " .. tostring(v.id) .. ")----" .. tostring(res_log));
    end
    return true, nil;
  end

  local reason = extractErrorMessage(res_settelment) or "خطای نامشخص";
  teamyar.write_log("settle failed (invoice " .. tostring(v.id) .. ")----" .. json.encode(res_settelment));
  return false, reason;
end

--------------------------------------------
-- حلقه‌ی زمان‌محور: تا رسیدن به سقف زمانی امن پردازش می‌کند و بعد تمیز متوقف می‌شود.
-- فاکتورهای پردازش‌نشده (چه به‌خاطر توقف زمانی، چه شکست تسویه) خودکار در اجرای بعدی
-- دوباره در همان کوئری ظاهر می‌شوند — هیچ checkpoint دستی لازم نیست.
--------------------------------------------
local okCount = 0;
local failCount = 0;
local signedDocFailCount = 0;
local otherFailCount = 0;
local processedCount = 0;
local stoppedEarly = false;
local _FAIL_SAMPLE_LIMIT = 15;
local signedDocSampleIds = {};
local otherFailSamples = {};

-- زمان فقط هر _TIME_CHECK_EVERY فاکتور یک‌بار چک می‌شود، نه هر فاکتور — چون
-- elapsedSeconds() خودش چند فراخوانی time.* دارد و روی صدها‌هزار تکرار محسوس می‌شود؛
-- حاشیه‌ی امن ۱۸۰۰ ثانیه‌ای (18000 واقعی منهای 16200 سقف) این عقب‌افتادگی کوچک را می‌پوشاند
local _TIME_CHECK_EVERY = 20;
for i, v in ipairs(compelete_factors) do
  if i % _TIME_CHECK_EVERY == 1 and elapsedSeconds() >= _MAX_RUNTIME_SECONDS then
    stoppedEarly = true;
    break;
  end
  local success, reason = settleFactor(v);
  processedCount = processedCount + 1;
  if success then
    okCount = okCount + 1;
  else
    failCount = failCount + 1;
    if reason ~= nil and string.find(reason, _SIGNED_DOC_ERROR_MARKER, 1, true) ~= nil then
      signedDocFailCount = signedDocFailCount + 1;
      -- خطای دائمی — ثبت در جدول اختصاصی تا از اجرای بعدی این کوئری حذف شود، وگرنه
      -- برای همیشه در صف می‌ماند (چون هیچ‌وقت در sales_invoice_settlement ثبت نمی‌شود).
      -- اگر جدول در دسترس نبود، این تلاش هم بی‌فایده است — رد می‌شود تا لاگ شلوغ نشود.
      if _skipTableReady then
        recordPermanentSkip(c_org_id, v.id, reason);
      end
      if #signedDocSampleIds < _FAIL_SAMPLE_LIMIT then
        table.insert(signedDocSampleIds, tostring(v.id));
      end
    else
      otherFailCount = otherFailCount + 1;
      if #otherFailSamples < _FAIL_SAMPLE_LIMIT then
        table.insert(otherFailSamples, tostring(v.id) .. ": " .. tostring(reason));
      end
    end
  end
  if processedCount % 500 == 0 then
    teamyar.write_log("backfill progress — processed=" .. processedCount .. "/" .. #compelete_factors
      .. " ok=" .. okCount .. " fail=" .. failCount .. " (signed_doc=" .. signedDocFailCount
      .. " other=" .. otherFailCount .. ") elapsed_s=" .. string.format("%.0f", elapsedSeconds()));
  end
end

-- signedDocFailCount فقط وقتی از remaining کم می‌شود که جدول اختصاصی واقعاً در دسترس
-- بوده باشد (یعنی این فاکتورها واقعاً ثبت و از کوئری اجرای بعدی حذف شدند) — وگرنه
-- (fallback بدون جدول) هنوز جزو صف واقعی‌اند و باید در remaining بمانند.
local remaining = queue_total - okCount;
if _skipTableReady then
  remaining = remaining - signedDocFailCount;
end
if remaining < 0 then remaining = 0; end

local summary = "این اجرا: " .. processedCount .. " فاکتور پردازش شد (موفق=" .. okCount .. "، ناموفق=" .. failCount .. ")"
  .. " در " .. string.format("%.0f", elapsedSeconds()) .. " ثانیه";
if stoppedEarly then
  summary = summary .. " — به سقف زمانی امن رسید و متوقف شد (نه به‌خاطر اتمام صف).";
else
  summary = summary .. " — همه‌ی ردیف‌های واکشی‌شده‌ی این اجرا پردازش شد.";
end
summary = summary .. " حدود " .. remaining .. " فاکتور دیگر در کل صف باقی مانده (از مجموع " .. queue_total .. ").";
if remaining > 0 then
  summary = summary .. " برای ادامه، این بات را دوباره اجرا کنید — صف خودکار از همین‌جا ادامه پیدا می‌کند.";
else
  summary = summary .. " صف خالی شد.";
end

-- تفکیک دلیل شکست‌ها: «سند مربوطه امضا شده است» دائمی است. این فاکتورها بالاتر در
-- sales_settlement_permanent_skip ثبت شدند — از این به بعد کوئری صف خودش این‌ها را
-- کنار می‌گذارد و دیگر هر اجرا دوباره امتحان/رد نمی‌شوند (رفع مستقیم گزارش کاربر
-- ۱۴۰۵/۰۶/۰۶: «هر دفعه بات رو ران می‌کنی دوباره همون فاکتورها رو میاره»).
if failCount > 0 then
  summary = summary .. " از ناموفق‌ها: " .. signedDocFailCount
    .. " فاکتور به دلیل «سند مربوطه امضا شده است» رد شد";
  if _skipTableReady then
    summary = summary .. " و در جدول اختصاصی این بات ثبت شد تا دیگر در اجراهای بعدی امتحان نشود"
      .. " (دائمی — این فاکتورها باید دستی در حسابداری رسیدگی شوند)";
  else
    summary = summary .. " — ثبت در جدول اختصاصی این اجرا ممکن نشد، پس این فاکتورها همچنان در"
      .. " اجرای بعدی دوباره در صف ظاهر می‌شوند (برای علت به لاگ اجرا مراجعه کنید)";
  end
  summary = summary .. " و " .. otherFailCount
    .. " فاکتور با خطای دیگر (احتمالاً موقتی، در اجرای بعد دوباره امتحان می‌شود).";
  if #signedDocSampleIds > 0 then
    summary = summary .. " نمونه شناسه فاکتورهای دارای سند امضاشده: "
      .. table.concat(signedDocSampleIds, "، ") .. ".";
  end
  if #otherFailSamples > 0 then
    summary = summary .. " نمونه خطاهای دیگر: " .. table.concat(otherFailSamples, " | ") .. ".";
  end
end

teamyar.write_log(summary);
teamyar.write_result(summary);
