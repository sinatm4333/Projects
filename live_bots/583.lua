--[[============================================================================
  signed_invoices  —  فاکتورهای فروش و امضاکنندگان آن‌ها
==============================================================================
  RUN_PATH         = <license_id>/signed_invoices
  RESULT_TYPE      = 1   (HTML)
  DEFAULT_DB       = -1  (بدون دیتابیس اختصاصی)
  PUBLIC_ACCESS    = 0   ← اجباری. این بات با SQL خام کار می‌کند.
  MAX_EXECUTE_TIME = 60

  دو حالت اجرا (هر دو HTML):
    بدون پارامتر    -> صفحه کامل (فیلترها + نتایج)
    ?part=rows      -> فقط قطعهٔ نتایج (خلاصه + جدول + صفحه‌بندی) برای XHR

  بازهٔ پیش‌فرض در اولین اجرا «امروز» است. مرورگر در هر درخواست بعدی dset=1
  می‌فرستد؛ با آن، تاریخِ خالی یعنی «همهٔ تاریخ‌ها» و پیش‌فرض دوباره اعمال نمی‌شود.

  ---------------------------------------------------------------------------
  مبنای داده
  ---------------------------------------------------------------------------
  امضای فاکتور در تیم‌یار روی «سند حسابداری» فاکتور ثبت می‌شود، نه روی خود
  فاکتور. زنجیره:

      sales_invoice.ID
        <- pa_voucher_record.REFFERE_ID   (با R_TYPE به‌عنوان تفکیک‌کنندهٔ نوع مرجع)
        -> pa_voucher.ID
        -> pa_voucher_signs (USER_ID, SIGN, DATE_SIGN)

  ⚠ REFFERE_ID یک ارجاع چندریختی است. بدون فیلتر R_TYPE، شناسهٔ فاکتور فروش با
  شناسهٔ اسناد دیگر (حقوق و دستمزد، خرید، انبار، دارایی ...) برخورد می‌کند و
  امضاکنندگانِ بی‌ربط به فاکتور نسبت داده می‌شوند.

  مقادیر معتبر برای فاکتور فروش (از teamyar_sdk/Interfaces/IPro_Accounting.h):
      VOUCHER_TYPE_SALES_INVOICE_TYPE   = 14   (فاکتور فروش)
      VOUCHER_TYPE_SALES_RETURN_INVOICE = 22   (برگشت از فروش)

  مبلغ کل فاکتور از ردیف سند با TYPE = 20 خوانده می‌شود:
      VOUCHER_TYPE_SALES_AMOUNT         = 20

  وضعیت امضا (pa_voucher_signs.SIGN):
      0 = تعیین‌شده ولی هنوز امضا نکرده   (DATE_SIGN در این حالت زمانِ ایجاد
                                            ردیف است، نه زمان امضا — بی‌معناست)
      1 = امضا کرده                        (DATE_SIGN معتبر است)
      2 = رد کرده

  ---------------------------------------------------------------------------
  کارایی — مهم‌ترین قید طراحی
  ---------------------------------------------------------------------------
  روی نصب‌های بزرگ pa_voucher_record میلیونی است (بیمه‌لند: ~۱٫۹ میلیون ردیفِ
  R_TYPE 14/22 روی ۱۸۲ هزار فاکتور). پس هیچ‌جا روی جدول اسناد جمع‌بندیِ
  بی‌کران زده نمی‌شود. مسیر دسترسی همیشه «اول فاکتور، بعد سند» است:

    ۱) شمارش و صفحهٔ ردیف‌ها فقط از sales_invoice  -> IDX2(RUN_DATE)
    ۲) اسناد فقط برای شناسه‌های همان صفحه          -> IDX14(REFFERE_ID)
    ۳) امضاها فقط برای اسناد همان صفحه             -> PRIMARY(VOUCHER_ID,...)
    ۴) جمع‌بندی امضا در Lua، نه در SQL

  فیلترهای مبتنی بر امضا (وضعیت امضا / نام امضاکننده) با EXISTS همبسته اعمال
  می‌شوند که همان ایندکس‌ها را می‌گیرد، ولی فقط وقتی تعداد فاکتورهای بازه از
  SIGN_FILTER_CAP کمتر باشد؛ در غیر این صورت فیلتر اعمال نمی‌شود و به کاربر
  هشدار داده می‌شود که بازه را کوچک‌تر کند.

  ---------------------------------------------------------------------------
  دسترسی — مسئولیت مدیر سیستم
  ---------------------------------------------------------------------------
  API‌ای برای خواندن امضاهای سند وجود ندارد (sales/invoice/get در ماژول ۲۳
  پوستهٔ خالی برمی‌گرداند)، بنابراین این بات از teamyar.query استفاده می‌کند که
  لایهٔ دسترسی ماژول‌ها را دور می‌زند و همهٔ فاکتورهای همهٔ سازمان‌ها را می‌بیند.
  دسترسی «اجرا»ی این بات باید فقط به مدیران مالی/فروش داده شود.
  Public access باید خاموش بماند؛ اسکریپت خودش هم آن را رد می‌کند.
============================================================================]]

teamyar.set_http_status(200, "OK")
teamyar.set_http_header("Content-Type", "text/html; charset=utf-8", true)

------------------------------------------------------------------------------
-- ثابت‌ها
------------------------------------------------------------------------------
local R_TYPES         = "14,22"   -- literal، هرگز از ورودی نمی‌آید
local REC_TYPE_AMOUNT = 20

-- سقف تعداد فاکتورِ بازه برای اعمال فیلترهای مبتنی بر امضا. بالاتر از این،
-- EXISTSها روی ردیف‌های زیادی اجرا می‌شوند و روی نصب زنده گران می‌شوند.
local SIGN_FILTER_CAP = 5000

-- سقف ردیف بازگشتی از probeهای صفحه (زیر سقف ۲۰۰۰ ردیفیِ teamyar.query)
local PROBE_LIMIT = 1900

local PAGE_SIZES  = { [25] = true, [50] = true, [100] = true, [200] = true }
local DEF_PSIZE   = 50
local MAX_ORGS    = 200

local INV_TYPE_TEXT = {
  [1] = "فاکتور فروش",
  [2] = "پیش‌فاکتور",
  [3] = "برگشت از فروش",
  [4] = "فاکتور فروشگاهی",
  [5] = "سفارش فروش",
  [6] = "حواله فروش",
  [7] = "قرارداد",
}

local INV_STATUS_TEXT = {
  [0] = "یادداشت",
  [1] = "بررسی",
  [2] = "در حال انجام",
  [3] = "تکمیل",
}

-- فقط ستون‌های sales_invoice؛ مرتب‌سازی روی مبلغ/آخرین‌امضا حذف شده چون از
-- جدول اسناد می‌آید و روی کل نتیجه اسکن سنگین لازم دارد.
local SORT_COLS = {
  date     = "si.RUN_DATE",
  invoice  = "si.INVOICE_ID",
  client   = "cl.NAME",
  remained = "si.REMAINED_AMOUNT",
}
local SORT_NEEDS_CLIENT = { client = true }

local SIGN_STATES = {
  all      = true,   -- همه
  full     = true,   -- سند دارد و همهٔ امضاکنندگان امضا کرده‌اند
  partial  = true,   -- بخشی امضا کرده‌اند
  none     = true,   -- سند دارد ولی هیچ‌کس امضا نکرده
  signed   = true,   -- حداقل یک امضا
  rejected = true,   -- حداقل یک رد
  nodoc    = true,   -- اصلاً سند حسابداری ندارد
}

local SIGNER_STATES = { any = true, signed = true, pending = true }

------------------------------------------------------------------------------
-- ابزارهای متنی
------------------------------------------------------------------------------
-- ⚠ تیم‌یار سورس بات را هنگام import/ذخیره HTML-decode می‌کند: هر «&…;» که
-- به‌صورت لفظی در سورس باشد به کاراکترِ خودش تبدیل می‌شود. مثلاً موجودیتِ
-- نقل‌قول دوتایی به یک کاراکتر " تبدیل می‌شود و رشته‌ها به هم می‌ریزند و کل
-- اسکریپت خطای نحوی می‌گیرد. پس نام موجودیت‌ها هرگز لفظی نوشته نمی‌شود و
-- همیشه با الحاق به AMP ساخته می‌شود. (این قاعده شامل خودِ همین توضیح هم هست.)
local AMP = string.char(38)

local function esc(s)
  s = tostring(s == nil and "" or s)
  s = s:gsub("&", AMP .. "amp;")
  s = s:gsub("<", AMP .. "lt;")
  s = s:gsub(">", AMP .. "gt;")
  s = s:gsub('"', AMP .. "quot;")
  s = s:gsub("'", AMP .. "#39;")
  return s
end

-- ارقام فارسی/عربی -> لاتین (کاربر ممکن است ۱۴۰۵/۰۴/۰۱ تایپ کند)
local DIGIT_MAP = {
  ["۰"]="0",["۱"]="1",["۲"]="2",["۳"]="3",["۴"]="4",
  ["۵"]="5",["۶"]="6",["۷"]="7",["۸"]="8",["۹"]="9",
  ["٠"]="0",["١"]="1",["٢"]="2",["٣"]="3",["٤"]="4",
  ["٥"]="5",["٦"]="6",["٧"]="7",["٨"]="8",["٩"]="9",
}

local function latin_digits(s)
  if type(s) ~= "string" then return "" end
  return (s:gsub("[\216-\219][\128-\191]", function(ch)
    return DIGIT_MAP[ch] or ch
  end))
end

local function trim(s)
  if type(s) ~= "string" then return "" end
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- در LIKE، کاراکترهای % و _ باید خنثی شوند.
-- کاراکتر فرار عمداً «|» است نه بک‌اسلش، چون رفتار بک‌اسلش به sql_mode
-- (NO_BACKSLASH_ESCAPES) وابسته است.
local LIKE_ESC = "|"
local function like_escape(s)
  return (tostring(s):gsub("([%%_|])", "|%1"))
end

-- یای/کافِ عربی و فارسی در جست‌وجو یکسان نیستند؛ هر دو صورت را می‌سازیم.
-- ⚠ این چهار کاراکتر با بایت‌های صریح ساخته می‌شوند، چون تیم‌یار در سورس بات
-- یای و کافِ عربی را به‌طور خودکار به فارسی نرمال‌سازی می‌کند؛ اگر لفظی نوشته
-- شوند هر دو شاخه یکسان شده و این تابع بی‌اثر می‌شود.
local AR_YEH = "\217\138"   -- U+064A
local AR_KAF = "\217\131"   -- U+0643
local FA_YEH = "\219\140"   -- U+06CC
local FA_KAF = "\218\169"   -- U+06A9

local function name_variants(s)
  local fa = s:gsub(AR_YEH, FA_YEH):gsub(AR_KAF, FA_KAF)
  local ar = s:gsub(FA_YEH, AR_YEH):gsub(FA_KAF, AR_KAF)
  if fa == ar then return { fa } end
  return { fa, ar }
end

-- خروجی time.get_shamsi_str به شکل "1405.4.29 14:05:09" است
local function fmt_date(v, with_time)
  local n = tonumber(v) or 0
  if n <= 0 then return "—" end
  local ok, s = pcall(time.get_shamsi_str, n)
  if not ok or type(s) ~= "string" then return "—" end
  local y, mo, d, hh, mi = s:match("^(%d+)%.(%d+)%.(%d+)%s+(%d+):(%d+)")
  if not y then return s end
  local out = string.format("%04d/%02d/%02d", tonumber(y), tonumber(mo), tonumber(d))
  if with_time then out = out .. " " .. hh .. ":" .. mi end
  return out
end

-- "1405/04/01" یا "1405-4-1" یا با ارقام فارسی -> FILETIME
local function parse_jdate(s, end_of_day)
  s = trim(latin_digits(s))
  if s == "" then return nil end
  local y, m, d = s:match("^(%d%d%d%d)%D(%d%d?)%D(%d%d?)$")
  if not y then return nil end
  y, m, d = tonumber(y), tonumber(m), tonumber(d)
  if m < 1 or m > 12 or d < 1 or d > 31 then return nil end
  local t = { year = y, month = m, day = d, hour = 0, minute = 0, second = 0 }
  if end_of_day then t.hour, t.minute, t.second = 23, 59, 59 end
  local ok, ft = pcall(time.get_shamsi_filetime, t)
  if not ok or type(ft) ~= "number" or ft <= 0 then return nil end
  return ft
end

local function placeholders(n)
  local t = {}
  for i = 1, n do t[i] = "?" end
  return table.concat(t, ", ")
end

------------------------------------------------------------------------------
-- ورودی
------------------------------------------------------------------------------
local ok_in, input = pcall(teamyar.get_input)
if not ok_in or type(input) ~= "table" then input = {} end

local function sparam(name)
  local v = input[name]
  if v == nil then return "" end
  return trim(tostring(v))
end

local F = {}
F.part    = sparam("part")

F.org     = tonumber(latin_digits(sparam("org"))) or 0
if F.org < 0 then F.org = 0 end

F.itype   = tonumber(latin_digits(sparam("itype"))) or 0
if not INV_TYPE_TEXT[F.itype] then F.itype = 0 end

F.sstat   = sparam("sstat"); if not SIGN_STATES[F.sstat] then F.sstat = "all" end
F.sgstate = sparam("sgstate"); if not SIGNER_STATES[F.sgstate] then F.sgstate = "any" end

F.q       = sparam("q")
F.signer  = sparam("signer")

-- بازهٔ تاریخ. در اولین باز شدن صفحه (هیچ پارامتری در URL نیست) پیش‌فرض
-- «امروز» است تا اجرای اول سبک بماند؛ کاربر می‌تواند بازه را باز یا تنگ کند.
local NOW = time.current()

local function day_str(days_back)
  return fmt_date(NOW - (days_back * time.day))
end

F.from_raw = sparam("from")
F.to_raw   = sparam("to")
F.default_range = false

if sparam("dset") == "" and F.from_raw == "" and F.to_raw == "" then
  F.from_raw = day_str(0)
  F.to_raw   = F.from_raw
  F.default_range = true
end

F.from_ft  = parse_jdate(F.from_raw, false)
F.to_ft    = parse_jdate(F.to_raw, true)

F.sort = sparam("sort"); if not SORT_COLS[F.sort] then F.sort = "date" end
F.dir  = (sparam("dir") == "asc") and "asc" or "desc"

F.psize = tonumber(latin_digits(sparam("psize"))) or DEF_PSIZE
if not PAGE_SIZES[F.psize] then F.psize = DEF_PSIZE end

F.page = tonumber(latin_digits(sparam("page"))) or 1
if F.page < 1 then F.page = 1 end

-- هشدارهای غیرکشنده که به کاربر نشان داده می‌شوند
local warnings = {}
if F.from_raw ~= "" and not F.from_ft then
  warnings[#warnings + 1] = "تاریخ «از» نامعتبر بود و نادیده گرفته شد (قالب درست: ۱۴۰۵/۰۱/۳۱)."
end
if F.to_raw ~= "" and not F.to_ft then
  warnings[#warnings + 1] = "تاریخ «تا» نامعتبر بود و نادیده گرفته شد (قالب درست: ۱۴۰۵/۰۱/۳۱)."
end
if F.from_ft and F.to_ft and F.from_ft > F.to_ft then
  warnings[#warnings + 1] = "تاریخ «از» بعد از «تا» بود؛ جای دو تاریخ عوض شد."
  F.from_ft, F.to_ft = F.to_ft, F.from_ft
  F.from_raw, F.to_raw = F.to_raw, F.from_raw
end

------------------------------------------------------------------------------
-- ساخت WHERE — هیچ مقدار ورودی داخل رشتهٔ SQL نمی‌رود
------------------------------------------------------------------------------
-- زیرپرس‌وجوی EXISTS روی اسنادِ همین فاکتور. با IDX14(REFFERE_ID) شروع می‌شود
-- و بعد با PRIMARYهای pa_voucher و pa_voucher_signs جلو می‌رود.
local EX_HEAD = [[
EXISTS (SELECT 1 FROM pa_voucher_record r
        INNER JOIN pa_voucher v
                ON v.ID = r.VOUCHER_ID AND v.ORG_ID = r.ORG_ID
               AND COALESCE(v.DELETED, 0) = 0
        INNER JOIN pa_voucher_signs g
                ON g.VOUCHER_ID = v.ID AND g.ORG_ID = v.ORG_ID]]

local EX_TAIL = [[
        WHERE r.REFFERE_ID = si.ID AND r.ORG_ID = si.ORG_ID
          AND r.R_TYPE IN (]] .. R_TYPES .. [[)
          AND COALESCE(r.DELETED, 0) = 0)]]

local function exists_sign(sign_value)
  return EX_HEAD .. " AND g.`SIGN` = " .. tostring(sign_value) .. EX_TAIL
end

-- «سند دارد» بدون قید امضا
local EXISTS_DOC = [[
EXISTS (SELECT 1 FROM pa_voucher_record r
        INNER JOIN pa_voucher v
                ON v.ID = r.VOUCHER_ID AND v.ORG_ID = r.ORG_ID
               AND COALESCE(v.DELETED, 0) = 0
        WHERE r.REFFERE_ID = si.ID AND r.ORG_ID = si.ORG_ID
          AND r.R_TYPE IN (]] .. R_TYPES .. [[)
          AND COALESCE(r.DELETED, 0) = 0)]]

-- شرط‌های ارزان: فقط ستون‌های sales_invoice (و در صورت جست‌وجو، pa_client)
local function build_base()
  local w = { "COALESCE(si.DELETED, 0) = 0", "COALESCE(si.CANCELED, 0) = 0" }
  local p = {}
  local needs_client = SORT_NEEDS_CLIENT[F.sort] or false

  if F.org > 0 then
    w[#w + 1] = "si.ORG_ID = ?"
    p[#p + 1] = F.org
  end

  if F.itype > 0 then
    w[#w + 1] = "si.TYPE = ?"
    p[#p + 1] = F.itype
  end

  if F.from_ft then w[#w + 1] = "si.RUN_DATE >= ?"; p[#p + 1] = F.from_ft end
  if F.to_ft   then w[#w + 1] = "si.RUN_DATE <= ?"; p[#p + 1] = F.to_ft   end

  if F.q ~= "" then
    needs_client = true
    local ESC  = " LIKE ? ESCAPE '" .. LIKE_ESC .. "'"
    local base = like_escape(F.q)
    local ors  = { "si.invoice_code" .. ESC,
                   "CAST(si.INVOICE_ID AS CHAR)" .. ESC }
    p[#p + 1] = "%" .. latin_digits(base) .. "%"
    p[#p + 1] = "%" .. latin_digits(base) .. "%"
    for _, v in ipairs(name_variants(base)) do
      ors[#ors + 1] = "si.TITLE" .. ESC
      p[#p + 1] = "%" .. v .. "%"
      ors[#ors + 1] = "cl.NAME" .. ESC
      p[#p + 1] = "%" .. v .. "%"
    end
    w[#w + 1] = "(" .. table.concat(ors, " OR ") .. ")"
  end

  return { where = " WHERE " .. table.concat(w, "\n  AND "),
           params = p, needs_client = needs_client }
end

-- شرط‌های مبتنی بر امضا. فقط وقتی صدا زده می‌شود که تعداد بازه زیر سقف باشد.
local function build_sign(base)
  local w, p = {}, {}

  if F.sstat == "nodoc" then
    w[#w + 1] = "NOT " .. EXISTS_DOC
  elseif F.sstat == "signed" then
    w[#w + 1] = exists_sign(1)
  elseif F.sstat == "rejected" then
    w[#w + 1] = exists_sign(2)
  elseif F.sstat == "full" then
    w[#w + 1] = exists_sign(1)
    w[#w + 1] = "NOT " .. exists_sign(0)
  elseif F.sstat == "partial" then
    w[#w + 1] = exists_sign(1)
    w[#w + 1] = exists_sign(0)
  elseif F.sstat == "none" then
    w[#w + 1] = EXISTS_DOC
    w[#w + 1] = "NOT " .. exists_sign(1)
  end

  if F.signer ~= "" then
    local ESC  = " LIKE ? ESCAPE '" .. LIKE_ESC .. "'"
    local cond = ""
    if F.sgstate == "signed" then cond = " AND g.`SIGN` = 1"
    elseif F.sgstate == "pending" then cond = " AND g.`SIGN` = 0" end

    local ors = {}
    for _, v in ipairs(name_variants(like_escape(F.signer))) do
      ors[#ors + 1] = "m.FULLNAME" .. ESC
      p[#p + 1] = "%" .. v .. "%"
    end

    w[#w + 1] = [[
EXISTS (SELECT 1 FROM pa_voucher_record r
        INNER JOIN pa_voucher v
                ON v.ID = r.VOUCHER_ID AND v.ORG_ID = r.ORG_ID
               AND COALESCE(v.DELETED, 0) = 0
        INNER JOIN pa_voucher_signs g
                ON g.VOUCHER_ID = v.ID AND g.ORG_ID = v.ORG_ID]] .. cond .. [[

        INNER JOIN profile_main m ON m.ID = g.USER_ID
        WHERE r.REFFERE_ID = si.ID AND r.ORG_ID = si.ORG_ID
          AND r.R_TYPE IN (]] .. R_TYPES .. [[)
          AND COALESCE(r.DELETED, 0) = 0
          AND (]] .. table.concat(ors, " OR ") .. "))"
  end

  if #w == 0 then return nil end

  local params = {}
  for i = 1, #base.params do params[i] = base.params[i] end
  for i = 1, #p do params[#params + 1] = p[i] end

  return { where = base.where .. "\n  AND " .. table.concat(w, "\n  AND "),
           params = params, needs_client = base.needs_client }
end

local function client_join(needed)
  if not needed then return "" end
  return "\nLEFT JOIN pa_client cl ON cl.ID = si.CLIENT_ID AND cl.ORG_ID = si.ORG_ID"
end

------------------------------------------------------------------------------
-- خواندن داده
------------------------------------------------------------------------------
local function copy(t)
  local out = {}
  for i = 1, #t do out[i] = t[i] end
  return out
end

local function fetch_orgs()
  local rows = teamyar.query(
    "SELECT po.ORG_ID AS id," ..
    " COALESCE(NULLIF(MAX(oi.NAME), ''), CONCAT('سازمان ', po.ORG_ID)) AS nm" ..
    " FROM pa_organizations po LEFT JOIN org_info oi ON oi.ID = po.ORG_ID" ..
    " GROUP BY po.ORG_ID ORDER BY po.ORG_ID LIMIT ?", { MAX_ORGS }, 2)
  return (type(rows) == "table") and rows or {}
end

-- شمارش و جمع مانده: فقط sales_invoice. با IDX2(RUN_DATE) اجرا می‌شود.
local function fetch_totals(w)
  local sql = "SELECT COUNT(*) AS n, COALESCE(SUM(si.REMAINED_AMOUNT), 0) AS rem" ..
              " FROM sales_invoice si" .. client_join(w.needs_client) ..
              w.where .. " LIMIT 1"
  local rows = teamyar.query(sql, copy(w.params), 2)
  if type(rows) == "table" and rows[1] then
    return tonumber(rows[1].n) or 0, tonumber(rows[1].rem) or 0
  end
  return 0, 0
end

local function fetch_page(w, offset)
  local order = SORT_COLS[F.sort] .. " " .. (F.dir == "asc" and "ASC" or "DESC")
  local sql =
    "SELECT si.ID AS inv_row, si.ORG_ID AS org_id, si.INVOICE_ID AS inv_no," ..
    " si.invoice_code AS inv_code, si.TITLE AS inv_title, si.TYPE AS inv_type," ..
    " si.STATUS AS inv_status, si.RUN_DATE AS inv_date," ..
    " si.REMAINED_AMOUNT AS remained, si.CLIENT_ID AS client_id," ..
    " cl.NAME AS client_name, oi.NAME AS org_name" ..
    " FROM sales_invoice si" ..
    "\nLEFT JOIN pa_client cl ON cl.ID = si.CLIENT_ID AND cl.ORG_ID = si.ORG_ID" ..
    "\nLEFT JOIN org_info oi ON oi.ID = si.ORG_ID" ..
    w.where .. "\nORDER BY " .. order .. ", si.ID DESC\nLIMIT ? OFFSET ?"

  local p = copy(w.params)
  p[#p + 1] = F.psize
  p[#p + 1] = offset

  local rows = teamyar.query(sql, p, 2)
  return (type(rows) == "table") and rows or {}
end

-- اسناد فقط برای شناسه‌های همین صفحه. ORG_ID عمداً در IN نیست تا
-- IDX14(REFFERE_ID) قابل استفاده بماند؛ تطبیق سازمان در Lua انجام می‌شود.
local function fetch_vouchers(rows)
  if #rows == 0 then return {} end

  local ids, seen = {}, {}
  for _, r in ipairs(rows) do
    local id = tonumber(r.inv_row) or 0
    if id > 0 and not seen[id] then seen[id] = true; ids[#ids + 1] = id end
  end
  if #ids == 0 then return {} end

  local sql =
    "SELECT pvr.REFFERE_ID AS rid, pvr.ORG_ID AS oid, pvr.VOUCHER_ID AS vid," ..
    " SUM(CASE WHEN pvr.TYPE = " .. tostring(REC_TYPE_AMOUNT) ..
    " THEN pvr.DEB - pvr.CRD ELSE 0 END) AS amount" ..
    " FROM pa_voucher_record pvr" ..
    "\nINNER JOIN pa_voucher pv ON pv.ID = pvr.VOUCHER_ID AND pv.ORG_ID = pvr.ORG_ID" ..
    "\n   AND COALESCE(pv.DELETED, 0) = 0" ..
    "\nWHERE pvr.R_TYPE IN (" .. R_TYPES .. ")" ..
    "\n  AND COALESCE(pvr.DELETED, 0) = 0" ..
    "\n  AND pvr.REFFERE_ID IN (" .. placeholders(#ids) .. ")" ..
    "\nGROUP BY pvr.REFFERE_ID, pvr.ORG_ID, pvr.VOUCHER_ID" ..
    "\nLIMIT " .. tostring(PROBE_LIMIT)

  local res = teamyar.query(sql, ids, 2)
  return (type(res) == "table") and res or {}
end

-- امضاها فقط برای اسناد همین صفحه، با PRIMARY(VOUCHER_ID, ORG_ID, USER_ID).
-- هر سند می‌تواند ده‌ها امضاکننده داشته باشد (روی بیمه‌لند ۱۳ تا ۲۱ نفر) و
-- اسناد دسته‌ای بین چند فاکتور مشترک‌اند، پس با اندازهٔ صفحهٔ بزرگ تعداد ردیف‌ها
-- از سقف teamyar.query رد می‌شود. برای همین در دسته‌های کوچک خوانده می‌شود.
local SIGN_CHUNK = 40

local function fetch_signs(vids)
  local out = {}
  if #vids == 0 then return out end

  local i = 1
  while i <= #vids do
    local chunk = {}
    for j = i, math.min(i + SIGN_CHUNK - 1, #vids) do
      chunk[#chunk + 1] = vids[j]
    end

    local sql =
      "SELECT pvs.VOUCHER_ID AS vid, pvs.ORG_ID AS oid, pvs.USER_ID AS uid," ..
      " COALESCE(NULLIF(pm.FULLNAME, ''), CONCAT('کاربر ', pvs.USER_ID)) AS uname," ..
      " pvs.`SIGN` AS st, pvs.DATE_SIGN AS dt" ..
      " FROM pa_voucher_signs pvs" ..
      "\nLEFT JOIN profile_main pm ON pm.ID = pvs.USER_ID" ..
      "\nWHERE pvs.VOUCHER_ID IN (" .. placeholders(#chunk) .. ")" ..
      "\nLIMIT " .. tostring(PROBE_LIMIT)

    local res = teamyar.query(sql, chunk, 2)
    if type(res) == "table" then
      for _, row in ipairs(res) do out[#out + 1] = row end
    end

    i = i + SIGN_CHUNK
  end

  return out
end

-- جمع‌بندی در Lua: برای هر فاکتور، مبلغ + یک ردیف به‌ازای هر امضاکنندهٔ یکتا.
-- اگر یک نفر روی چند سندِ همان فاکتور ردیف داشته باشد، امضا بر رد و رد بر
-- «منتظر» اولویت دارد تا دوبار شمرده نشود.
local function enrich(rows)
  local info = {}
  for _, r in ipairs(rows) do
    info[tostring(r.inv_row) .. "|" .. tostring(r.org_id)] =
      { amount = 0, has_doc = false, users = {}, order = {} }
  end

  local vrows = fetch_vouchers(rows)
  if #vrows == 0 then return info end

  local vids, vseen, vmap = {}, {}, {}
  for _, v in ipairs(vrows) do
    local key = tostring(v.rid) .. "|" .. tostring(v.oid)
    local rec = info[key]
    if rec then
      rec.has_doc = true
      rec.amount  = rec.amount + (tonumber(v.amount) or 0)
      local vid = tonumber(v.vid) or 0
      if vid > 0 then
        local vkey = tostring(vid) .. "|" .. tostring(v.oid)
        if not vmap[vkey] then vmap[vkey] = {} end
        vmap[vkey][#vmap[vkey] + 1] = key
        if not vseen[vid] then vseen[vid] = true; vids[#vids + 1] = vid end
      end
    end
  end

  for _, s in ipairs(fetch_signs(vids)) do
    local vkey = tostring(s.vid) .. "|" .. tostring(s.oid)
    local targets = vmap[vkey]
    if targets then
      local st = tonumber(s.st) or 0
      local dt = (st == 1) and (tonumber(s.dt) or 0) or 0
      for _, key in ipairs(targets) do
        local rec = info[key]
        local uid = tostring(s.uid)
        local cur = rec.users[uid]
        if not cur then
          cur = { name = s.uname, eff = st, dt = dt }
          rec.users[uid] = cur
          rec.order[#rec.order + 1] = uid
        else
          -- اولویت: امضا (۱) > رد (۲) > منتظر (۰)
          if st == 1 then
            if cur.eff ~= 1 then cur.eff = 1; cur.dt = dt
            elseif dt > cur.dt then cur.dt = dt end
          elseif st == 2 and cur.eff == 0 then
            cur.eff = 2
          end
        end
      end
    end
  end

  return info
end

------------------------------------------------------------------------------
-- رندر
------------------------------------------------------------------------------
local function label_of(map, v, fallback)
  local n = tonumber(v)
  if n and map[n] then return map[n] end
  return fallback or "—"
end

local function num(v) return tonumber(v) or 0 end
local function intstr(v) return string.format("%.0f", num(v)) end

local function amt_cell(v, cls, dash)
  if dash then
    return '<td class="amt ' .. (cls or "") .. ' none">—</td>'
  end
  local n = intstr(v)
  return '<td class="amt ' .. (cls or "") .. '" data-amt="' .. n .. '">' .. n .. '</td>'
end

local function sign_badge(eff)
  local e = num(eff)
  if e == 1 then return '<span class="chip ok">امضا شده</span>' end
  if e == 2 then return '<span class="chip no">رد شده</span>' end
  return '<span class="chip wait">منتظر امضا</span>'
end

-- فهرست امضاکنندگان یک فاکتور، مرتب: امضاشده، رد، منتظر
local function signer_list(rec)
  local list = {}
  for _, uid in ipairs(rec.order) do
    local u = rec.users[uid]
    list[#list + 1] = { name = u.name, eff = u.eff, dt = u.dt }
  end
  table.sort(list, function(a, b)
    local ra = (a.eff == 1) and 0 or ((a.eff == 2) and 1 or 2)
    local rb = (b.eff == 1) and 0 or ((b.eff == 2) and 1 or 2)
    if ra ~= rb then return ra < rb end
    if a.dt ~= b.dt then return a.dt < b.dt end
    return a.name < b.name
  end)
  return list
end

local function render_signers(rec)
  if not rec.has_doc then
    return '<div class="nosign">برای این فاکتور سند حسابداری صادر نشده است، ' ..
           'بنابراین امضاکننده‌ای هم ندارد.</div>'
  end
  local list = signer_list(rec)
  if #list == 0 then
    return '<div class="nosign">سند حسابداری دارد ولی امضاکننده‌ای برایش ' ..
           'تعیین نشده است.</div>'
  end
  local out = { '<table class="sgt"><thead><tr>',
                '<th>امضاکننده</th><th>وضعیت</th><th>تاریخ امضا</th>',
                '</tr></thead><tbody>' }
  for _, s in ipairs(list) do
    out[#out + 1] = '<tr><td class="nm">' .. esc(s.name) .. '</td>' ..
                    '<td>' .. sign_badge(s.eff) .. '</td>' ..
                    '<td class="dt">' ..
                      ((s.eff == 1) and esc(fmt_date(s.dt, true)) or "—") ..
                    '</td></tr>'
  end
  out[#out + 1] = '</tbody></table>'
  return table.concat(out)
end

local COLSPAN = 11

-- شمارنده‌های وضعیت برای همین صفحه
local function render_rows(rows, info, tally)
  if #rows == 0 then
    local extra = ""
    if F.default_range then
      extra = '<div class="emptyhint">بازهٔ پیش‌فرض «امروز» است. برای دیدن موارد ' ..
              'قدیمی‌تر، یکی از دکمه‌های بازهٔ سریع را بزنید یا تاریخ‌ها را پاک کنید.</div>'
    end
    return '<tr><td colspan="' .. COLSPAN .. '" class="empty">' ..
           'هیچ فاکتوری با این فیلترها یافت نشد.' .. extra .. '</td></tr>'
  end

  local out = {}
  for i, r in ipairs(rows) do
    local key = tostring(r.inv_row) .. "|" .. tostring(r.org_id)
    local rec = info[key] or { amount = 0, has_doc = false, users = {}, order = {} }

    local sc, pc, rc = 0, 0, 0
    local names, first_dt, last_dt = {}, 0, 0
    for _, s in ipairs(signer_list(rec)) do
      if s.eff == 1 then
        sc = sc + 1
        names[#names + 1] = s.name
        if s.dt > 0 then
          if first_dt == 0 or s.dt < first_dt then first_dt = s.dt end
          if s.dt > last_dt then last_dt = s.dt end
        end
      elseif s.eff == 2 then rc = rc + 1
      else pc = pc + 1 end
    end
    local tot = sc + pc + rc

    local state_cls, state_txt
    if not rec.has_doc then state_cls, state_txt = "gray", "بدون سند"
    elseif rc > 0 then      state_cls, state_txt = "no",   "دارای رد"
    elseif sc == 0 then     state_cls, state_txt = "wait", "بدون امضا"
    elseif pc == 0 then     state_cls, state_txt = "ok",   "امضای کامل"
    else                    state_cls, state_txt = "half", "امضای ناقص"
    end
    tally[state_cls] = (tally[state_cls] or 0) + 1

    local pct = 0
    if tot > 0 then pct = math.floor((sc * 100) / tot + 0.5) end
    local names_txt = (#names > 0) and table.concat(names, "، ") or "—"

    local ratio = rec.has_doc
      and ('<span class="ratio">' .. tostring(sc) .. '/' .. tostring(tot) .. '</span>' ..
           '<span class="bar"><i style="width:' .. tostring(pct) .. '%"></i></span>')
      or ""

    out[#out + 1] = table.concat({
      '<tr class="row" data-k="', esc(key), '" tabindex="0">',
        '<td class="c mini">', tostring(i), '</td>',
        '<td class="c num">', esc(tostring(r.inv_no or "—")), '</td>',
        '<td class="code">', esc(r.inv_code or "—"), '</td>',
        '<td class="title" title="', esc(r.inv_title or ""), '">',
            esc((r.inv_title and r.inv_title ~= "") and r.inv_title or "—"), '</td>',
        '<td class="client">', esc(r.client_name or "—"), '</td>',
        '<td class="c t">', esc(label_of(INV_TYPE_TEXT, r.inv_type)), '</td>',
        '<td class="c dt">', esc(fmt_date(r.inv_date)), '</td>',
        amt_cell(rec.amount, "", not rec.has_doc),
        amt_cell(r.remained, "rem"),
        '<td class="sgn"><span class="chip ', state_cls, '">', state_txt, '</span>',
          ratio, '</td>',
        '<td class="who" title="', esc(names_txt), '">', esc(names_txt), '</td>',
      '</tr>',
      '<tr class="det" data-d="', esc(key), '"><td colspan="', tostring(COLSPAN), '">',
        '<div class="detwrap">',
          '<div class="dhead">امضاکنندگان فاکتور ',
            esc(tostring(r.inv_no or "")), ' — ', esc(r.org_name or ""), '</div>',
          render_signers(rec),
          -- جداکننده با CSS فاصله می‌گیرد؛ موجودیتِ فاصلهٔ سخت در سورس دوام ندارد
          '<div class="dmeta">اولین امضا: ', esc(fmt_date(first_dt, true)),
            '<i class="sep">|</i>آخرین امضا: ', esc(fmt_date(last_dt, true)),
            '<i class="sep">|</i>وضعیت فاکتور: ',
            esc(label_of(INV_STATUS_TEXT, r.inv_status)), '</div>',
        '</div>',
      '</td></tr>',
    })
  end
  return table.concat(out)
end

local function tile(label, value, cls, raw_amt, sub)
  local dattr = raw_amt and (' data-amt="' .. intstr(raw_amt) .. '"') or ""
  local subhtml = sub and ('<span class="ts">' .. esc(sub) .. '</span>') or ""
  return '<div class="tile ' .. (cls or "") .. '"><span class="tl">' .. esc(label) ..
         subhtml .. '</span><span class="tv"' .. dattr .. '>' .. esc(value) ..
         '</span></div>'
end

local function render_pager(total, pages)
  if total == 0 then return "" end
  local function btn(p, txt, dis)
    if dis then
      return '<button type="button" class="pg" disabled>' .. txt .. '</button>'
    end
    return '<button type="button" class="pg" data-page="' .. tostring(p) .. '">' ..
           txt .. '</button>'
  end
  local first = (F.page <= 1)
  local last  = (F.page >= pages)
  return table.concat({
    '<div class="pager">',
      btn(1, "« ابتدا", first),
      btn(F.page - 1, "‹ قبلی", first),
      '<span class="pinfo">صفحه ', tostring(F.page), ' از ', tostring(pages),
      ' — ', tostring(total), ' فاکتور</span>',
      btn(F.page + 1, "بعدی ›", last),
      btn(pages, "انتها »", last),
    '</div>',
  })
end

------------------------------------------------------------------------------
-- قطعهٔ نتایج
------------------------------------------------------------------------------
local function build_results()
  local base = build_base()

  -- گام ۱ — شمارش ارزان روی sales_invoice
  local total, total_rem = fetch_totals(base)

  -- گام ۲ — فیلترهای مبتنی بر امضا، فقط اگر بازه به‌اندازهٔ کافی کوچک باشد
  local w = base
  local wants_sign = (F.sstat ~= "all") or (F.signer ~= "")

  if wants_sign then
    if total > SIGN_FILTER_CAP then
      warnings[#warnings + 1] =
        "بازهٔ انتخابی " .. intstr(total) .. " فاکتور دارد و بیش از سقف " ..
        intstr(SIGN_FILTER_CAP) .. " است، بنابراین فیلترهای «وضعیت امضا» و " ..
        "«امضاکننده» اعمال نشدند. بازهٔ تاریخ را کوچک‌تر کنید."
    else
      local ws = build_sign(base)
      if ws then
        w = ws
        total, total_rem = fetch_totals(w)
      end
    end
  end

  local pages = math.max(1, math.ceil(total / F.psize))
  if F.page > pages then F.page = pages end

  -- گام ۳ و ۴ — فقط ردیف‌های همین صفحه و اسناد/امضاهای همان‌ها
  local rows = fetch_page(w, (F.page - 1) * F.psize)
  local info = enrich(rows)

  local tally = {}
  local body  = render_rows(rows, info, tally)

  local warn = ""
  if #warnings > 0 then
    local ws = {}
    for _, m in ipairs(warnings) do ws[#ws + 1] = '<li>' .. esc(m) .. '</li>' end
    warn = '<ul class="warn">' .. table.concat(ws) .. '</ul>'
  end

  return table.concat({
    warn,
    '<div class="tiles">',
      tile("تعداد فاکتور", intstr(total), "b", nil, "کل نتیجه"),
      tile("جمع مانده", intstr(total_rem), "b", total_rem, "کل نتیجه"),
      tile("امضای کامل", intstr(tally.ok or 0), "ok", nil, "این صفحه"),
      tile("امضای ناقص", intstr(tally.half or 0), "half", nil, "این صفحه"),
      tile("بدون امضا", intstr(tally.wait or 0), "wait", nil, "این صفحه"),
      tile("دارای رد", intstr(tally.no or 0), "no", nil, "این صفحه"),
      tile("بدون سند", intstr(tally.gray or 0), "gray", nil, "این صفحه"),
    '</div>',

    '<div class="tblwrap"><table class="main"><thead><tr>',
      '<th class="c">#</th>',
      '<th class="c sortable" data-s="invoice">شماره</th>',
      '<th>کد فاکتور</th>',
      '<th>عنوان</th>',
      '<th class="sortable" data-s="client">طرف حساب</th>',
      '<th class="c">نوع</th>',
      '<th class="c sortable" data-s="date">تاریخ</th>',
      '<th class="c">مبلغ</th>',
      '<th class="c sortable" data-s="remained">مانده</th>',
      '<th class="c">وضعیت امضا</th>',
      '<th>امضاکنندگان</th>',
    '</tr></thead><tbody>',
      body,
    '</tbody></table></div>',

    render_pager(total, pages),
  })
end

------------------------------------------------------------------------------
-- صفحهٔ کامل
------------------------------------------------------------------------------
local function opts_org(orgs)
  local out = { '<option value="0"', (F.org == 0) and " selected" or "", '>همه سازمان‌ها</option>' }
  for _, o in ipairs(orgs) do
    local id = tostring(num(o.id))
    out[#out + 1] = '<option value="' .. id .. '"' ..
                    ((num(o.id) == F.org) and " selected" or "") .. '>' ..
                    esc(o.nm) .. '</option>'
  end
  return table.concat(out)
end

local function opts_from(pairs_list, current)
  local out = {}
  for _, kv in ipairs(pairs_list) do
    out[#out + 1] = '<option value="' .. esc(kv[1]) .. '"' ..
                    ((tostring(kv[1]) == tostring(current)) and " selected" or "") ..
                    '>' .. esc(kv[2]) .. '</option>'
  end
  return table.concat(out)
end

-- دکمه‌های بازهٔ سریع. تاریخ‌ها سمت سرور حساب می‌شوند چون محاسبهٔ شمسی سمت
-- مرورگر دردسر دارد؛ مرورگر فقط مقدار آماده را در فیلدها می‌گذارد.
local QUICK_RANGES = {
  { label = "امروز",   back = 0  },
  { label = "۷ روز",   back = 6  },
  { label = "۳۰ روز",  back = 29 },
  { label = "۹۰ روز",  back = 89 },
}

local function quick_buttons()
  local today = day_str(0)
  local out = {}
  for _, r in ipairs(QUICK_RANGES) do
    local from = day_str(r.back)
    local on = (F.from_raw == from and F.to_raw == today) and " on" or ""
    out[#out + 1] = '<button type="button" class="qr' .. on ..
                    '" data-from="' .. from .. '" data-to="' .. today .. '">' ..
                    r.label .. '</button>'
  end
  local all_on = (F.from_raw == "" and F.to_raw == "") and " on" or ""
  out[#out + 1] = '<button type="button" class="qr' .. all_on ..
                  '" data-from="" data-to="">همه</button>'
  return table.concat(out)
end

local function build_page()
  local self_info = teamyar.self()
  local base_url  = "/bot/run/" .. tostring(self_info.run_path or "")
  local orgs      = fetch_orgs()

  local type_opts = {
    { "0", "همه انواع" },
    { "1", INV_TYPE_TEXT[1] }, { "2", INV_TYPE_TEXT[2] }, { "3", INV_TYPE_TEXT[3] },
    { "4", INV_TYPE_TEXT[4] }, { "5", INV_TYPE_TEXT[5] }, { "6", INV_TYPE_TEXT[6] },
    { "7", INV_TYPE_TEXT[7] },
  }
  local sstat_opts = {
    { "all", "همه" },
    { "signed", "حداقل یک امضا" },
    { "full", "امضای کامل" },
    { "partial", "امضای ناقص" },
    { "none", "بدون امضا" },
    { "rejected", "دارای رد" },
    { "nodoc", "بدون سند حسابداری" },
  }
  local sgstate_opts = {
    { "any", "هر وضعیتی" },
    { "signed", "امضا کرده" },
    { "pending", "منتظر امضای او" },
  }
  local psize_opts = { { "25", "۲۵" }, { "50", "۵۰" }, { "100", "۱۰۰" }, { "200", "۲۰۰" } }
  local sort_opts = {
    { "date", "تاریخ فاکتور" },
    { "invoice", "شماره فاکتور" },
    { "client", "طرف حساب" },
    { "remained", "مانده" },
  }
  local dir_opts = { { "desc", "نزولی" }, { "asc", "صعودی" } }

  return table.concat({
[[<!-- signed_invoices -->
<div id="tysi" dir="rtl">
<style>
#tysi{font-family:IRANSans,Tahoma,sans-serif;font-size:13px;color:#22303c;padding:10px;box-sizing:border-box}
#tysi *{box-sizing:border-box}
#tysi h2{margin:0 0 2px;font-size:17px;font-weight:700}
#tysi .sub{color:#7b8896;font-size:12px;margin:0 0 12px}
#tysi .card{background:#fff;border:1px solid #e3e8ee;border-radius:10px}

#tysi .filters{padding:12px;margin-bottom:12px;display:flex;flex-wrap:wrap;gap:10px;align-items:flex-end}
#tysi .fld{display:flex;flex-direction:column;gap:4px}
#tysi .fld label{font-size:11px;color:#7b8896;font-weight:600}
#tysi input[type=text],#tysi select{font-family:inherit;font-size:12.5px;padding:6px 9px;
  border:1px solid #d5dde6;border-radius:7px;background:#fff;color:#22303c;height:32px;outline:none}
#tysi input[type=text]:focus,#tysi select:focus{border-color:#3f7fd4;box-shadow:0 0 0 3px rgba(63,127,212,.13)}
#tysi input[type=text]{min-width:150px}
#tysi .fld.grow{flex:1 1 210px}
#tysi .fld.grow input{width:100%}
#tysi .btns{display:flex;gap:7px;margin-right:auto}
#tysi button{font-family:inherit;font-size:12.5px;height:32px;padding:0 14px;border-radius:7px;
  border:1px solid #d5dde6;background:#fff;color:#3d4b59;cursor:pointer}
#tysi button:hover{background:#f4f7fa}
#tysi button.primary{background:#3f7fd4;border-color:#3f7fd4;color:#fff;font-weight:600}
#tysi button.primary:hover{background:#3670bd}
#tysi button:disabled{opacity:.45;cursor:default}
#tysi .quick{display:flex;gap:4px}
#tysi button.qr{height:32px;padding:0 10px;font-size:12px;border-radius:7px;color:#5b6a79}
#tysi button.qr.on{background:#eaf2fd;border-color:#9ec2ee;color:#2c5f9e;font-weight:600}

#tysi .tiles{display:flex;flex-wrap:wrap;gap:9px;margin-bottom:11px}
#tysi .tile{flex:1 1 118px;background:#fff;border:1px solid #e3e8ee;border-left:3px solid #cfd8e3;
  border-radius:9px;padding:9px 11px;display:flex;flex-direction:column;gap:3px}
#tysi .tile .tl{font-size:11px;color:#7b8896;display:flex;align-items:baseline;gap:5px}
#tysi .tile .ts{font-size:9.5px;color:#b4bec8}
#tysi .tile .tv{font-size:16px;font-weight:700;letter-spacing:.2px}
#tysi .tile.b{border-left-color:#3f7fd4}
#tysi .tile.ok{border-left-color:#2e9e5b}
#tysi .tile.half{border-left-color:#d99420}
#tysi .tile.wait{border-left-color:#8b95a1}
#tysi .tile.no{border-left-color:#cf4141}
#tysi .tile.gray{border-left-color:#d5dde6}

#tysi .tblwrap{background:#fff;border:1px solid #e3e8ee;border-radius:10px;overflow:auto;max-height:66vh}
#tysi table.main{width:100%;border-collapse:separate;border-spacing:0;min-width:1080px}
#tysi table.main th,#tysi table.main td{padding:8px 9px;text-align:right;
  border-bottom:1px solid #eef2f6;vertical-align:middle;white-space:nowrap}
#tysi table.main th{position:sticky;top:0;z-index:2;background:#f7f9fb;font-weight:700;
  color:#5b6a79;font-size:11.5px;border-bottom:1px solid #e3e8ee}
#tysi th.sortable{cursor:pointer;user-select:none}
#tysi th.sortable:hover{color:#3f7fd4}
#tysi th.sortable.on{color:#3f7fd4}
#tysi th.sortable.on:after{content:" \25BE";font-size:10px}
#tysi th.sortable.on.asc:after{content:" \25B4"}
#tysi td.c,#tysi th.c{text-align:center}
#tysi td.mini{color:#aab4bf;font-size:11px}
#tysi td.num{font-weight:700}
#tysi td.code{color:#6b7885;font-size:11.5px;direction:ltr;text-align:left}
#tysi td.title{max-width:250px;overflow:hidden;text-overflow:ellipsis;font-weight:600}
#tysi td.client{max-width:190px;overflow:hidden;text-overflow:ellipsis}
#tysi td.who{max-width:210px;overflow:hidden;text-overflow:ellipsis;color:#44525f;font-size:12px}
#tysi td.t{font-size:11.5px;color:#5b6a79}
#tysi td.dt{font-size:12px;color:#5b6a79;direction:ltr;text-align:center}
#tysi td.amt{font-variant-numeric:tabular-nums;direction:ltr;text-align:left;font-size:12.5px}
#tysi td.amt.rem{color:#a8541c}
#tysi td.amt.none{color:#c8d2dc;text-align:center}
#tysi tr.row{cursor:pointer}
#tysi tr.row:hover>td{background:#f5f9ff}
#tysi tr.row:focus{outline:2px solid #3f7fd4;outline-offset:-2px}
#tysi tr.row.open>td{background:#eaf2fd}
#tysi td.empty{text-align:center;color:#98a4b0;padding:34px}
#tysi .emptyhint{margin-top:8px;font-size:12px;color:#b4bec8}

#tysi .chip{display:inline-block;padding:2px 8px;border-radius:11px;font-size:11px;
  font-weight:600;white-space:nowrap}
#tysi .chip.ok{background:#e4f4ea;color:#22753f}
#tysi .chip.half{background:#fdf1dd;color:#8a5c10}
#tysi .chip.wait{background:#eef1f4;color:#5f6b77}
#tysi .chip.no{background:#fbe6e6;color:#a52f2f}
#tysi .chip.gray{background:#f4f6f8;color:#98a4b0}
#tysi td.sgn{white-space:nowrap}
#tysi .ratio{color:#7b8896;font-size:11px;margin:0 6px}
#tysi .bar{display:inline-block;width:44px;height:5px;background:#e6ebf0;border-radius:3px;
  overflow:hidden;vertical-align:middle}
#tysi .bar i{display:block;height:100%;background:#2e9e5b}

#tysi tr.det{display:none}
#tysi tr.det.show{display:table-row}
#tysi tr.det>td{background:#f9fbfd;padding:0;border-bottom:1px solid #e3e8ee}
#tysi .detwrap{padding:11px 16px}
#tysi .dhead{font-size:12px;font-weight:700;color:#44525f;margin-bottom:7px}
#tysi table.sgt{border-collapse:collapse;min-width:340px;background:#fff;
  border:1px solid #e3e8ee;border-radius:7px;overflow:hidden}
#tysi table.sgt th,#tysi table.sgt td{padding:5px 11px;font-size:12px;text-align:right;
  border-bottom:1px solid #f0f4f7;white-space:nowrap}
#tysi table.sgt th{background:#f7f9fb;color:#5b6a79;font-size:11px}
#tysi table.sgt td.nm{font-weight:600}
#tysi table.sgt td.dt{color:#5b6a79;direction:ltr;text-align:left}
#tysi .nosign{color:#98a4b0;font-size:12px;padding:5px 0}
#tysi .dmeta{margin-top:7px;font-size:11.5px;color:#7b8896}
#tysi .dmeta .sep{font-style:normal;color:#c8d2dc;margin:0 9px}

#tysi .pager{display:flex;align-items:center;gap:7px;justify-content:center;padding:11px 0}
#tysi .pinfo{font-size:12px;color:#5b6a79;margin:0 9px}
#tysi ul.warn{margin:0 0 10px;padding:9px 26px 9px 12px;background:#fdf6e3;
  border:1px solid #efdfb4;border-radius:8px;color:#7a5a12;font-size:12px}
#tysi .fatal{padding:22px;color:#a52f2f;background:#fbe6e6;border:1px solid #f0c9c9;
  border-radius:9px;font-size:13.5px;line-height:2}
#tysi .loading{opacity:.45;pointer-events:none}
#tysi .hint{font-size:11px;color:#98a4b0;margin-top:8px;line-height:1.9}
@media print{
  #tysi .filters,#tysi .pager,#tysi .btns{display:none}
  #tysi .tblwrap{max-height:none;overflow:visible;border:none}
  #tysi table.main{min-width:0}
  #tysi tr.det{display:table-row}
}
</style>

<h2>فاکتورهای فروش و امضاکنندگان</h2>
<p class="sub">امضا روی سند حسابداری فاکتور ثبت می‌شود. روی هر ردیف کلیک کنید تا فهرست کامل امضاکنندگان و وضعیت هرکدام باز شود.</p>

<div class="card filters">
  <div class="fld"><label>سازمان</label>
    <select id="f_org">]], opts_org(orgs), [[</select></div>

  <div class="fld"><label>نوع سند</label>
    <select id="f_itype">]], opts_from(type_opts, tostring(F.itype)), [[</select></div>

  <div class="fld"><label>وضعیت امضا</label>
    <select id="f_sstat">]], opts_from(sstat_opts, F.sstat), [[</select></div>

  <div class="fld"><label>از تاریخ</label>
    <input type="text" id="f_from" placeholder="۱۴۰۵/۰۱/۰۱" value="]], esc(F.from_raw), [[" size="11"></div>

  <div class="fld"><label>تا تاریخ</label>
    <input type="text" id="f_to" placeholder="۱۴۰۵/۱۲/۲۹" value="]], esc(F.to_raw), [[" size="11"></div>

  <div class="fld"><label>بازهٔ سریع</label><div class="quick">]],
    quick_buttons(), [[</div></div>

  <div class="fld grow"><label>جست‌وجو (عنوان، کد، شماره، طرف حساب)</label>
    <input type="text" id="f_q" value="]], esc(F.q), [["></div>

  <div class="fld"><label>امضاکننده</label>
    <input type="text" id="f_signer" value="]], esc(F.signer), [[" size="14"></div>

  <div class="fld"><label>وضعیت امضاکننده</label>
    <select id="f_sgstate">]], opts_from(sgstate_opts, F.sgstate), [[</select></div>

  <div class="fld"><label>مرتب‌سازی</label>
    <select id="f_sort">]], opts_from(sort_opts, F.sort), [[</select></div>

  <div class="fld"><label>ترتیب</label>
    <select id="f_dir">]], opts_from(dir_opts, F.dir), [[</select></div>

  <div class="fld"><label>در هر صفحه</label>
    <select id="f_psize">]], opts_from(psize_opts, tostring(F.psize)), [[</select></div>

  <div class="fld"><label>واحد مبلغ</label>
    <select id="f_unit"><option value="rial">ریال</option><option value="toman">تومان</option></select></div>

  <div class="btns">
    <button type="button" class="primary" id="b_apply">اعمال فیلتر</button>
    <button type="button" id="b_reset">پاک‌کردن</button>
    <button type="button" id="b_print">چاپ</button>
  </div>
</div>

<div id="tyres">]], build_results(), [[</div>

<p class="hint">هنگام باز شدن، فقط فاکتورهای <b>امروز</b> نمایش داده می‌شود؛ با دکمه‌های بازهٔ سریع یا با پاک‌کردن تاریخ‌ها بازه را باز کنید.
کادرهای «تعداد فاکتور» و «جمع مانده» مربوط به کل نتیجه‌اند؛ تفکیک وضعیت امضا فقط برای صفحهٔ جاری شمرده می‌شود تا روی نصب‌های بزرگ کوئری سنگین اجرا نشود.
مبلغ از ردیف سند حسابداری نوع «مبلغ فروش» می‌آید و شامل ارزش افزوده است؛ فاکتور بدون سند در ستون مبلغ خط تیره می‌گیرد.</p>

<script>
(function(){
  var BASE = ']], base_url, [[';
  var box  = document.getElementById('tyres');
  var root = document.getElementById('tysi');
  var page = ]], tostring(F.page), [[;
  var busy = false;

  function val(id){ var e = document.getElementById(id); return e ? e.value : ''; }

  function qs(extra){
    var p = {
      part:  'rows',
      dset:  '1',          // تاریخ‌ها صریحاً از فیلدها می‌آیند؛ پیش‌فرض اعمال نشود
      org:   val('f_org'),
      itype: val('f_itype'),
      sstat: val('f_sstat'),
      from:  val('f_from'),
      to:    val('f_to'),
      q:     val('f_q'),
      signer: val('f_signer'),
      sgstate: val('f_sgstate'),
      sort:  val('f_sort'),
      dir:   val('f_dir'),
      psize: val('f_psize'),
      page:  page
    };
    if (extra) { for (var k in extra) { if (extra.hasOwnProperty(k)) p[k] = extra[k]; } }
    var out = [];
    for (var k2 in p) {
      if (p.hasOwnProperty(k2)) {
        out.push(encodeURIComponent(k2) + '=' + encodeURIComponent(p[k2] == null ? '' : p[k2]));
      }
    }
    return out.join('&');
  }

  function load(extra){
    if (busy) return;
    busy = true;
    box.className = 'loading';

    var xhr = new XMLHttpRequest();
    xhr.open('GET', BASE + '?' + qs(extra), true);
    xhr.onreadystatechange = function(){
      if (xhr.readyState !== 4) return;
      busy = false;
      box.className = '';
      if (xhr.status >= 200 && xhr.status < 300 && xhr.responseText) {
        box.innerHTML = xhr.responseText;
        applyUnit();
        markSort();
      } else {
        box.innerHTML = '<div class="fatal">خطا در دریافت اطلاعات از سرور' +
          (xhr.status ? ' (کد ' + xhr.status + ')' : '') + '.</div>';
      }
    };
    xhr.send();
  }

  function apply(){ page = 1; load(); }

  function sep(s){
    var neg = false;
    s = String(s);
    if (s.charAt(0) === '-') { neg = true; s = s.substring(1); }
    s = s.replace(/^0+(?=\d)/, '');
    var out = s.replace(/\B(?=(\d{3})+(?!\d))/g, ',');
    return (neg ? '-' : '') + out;
  }

  function toToman(s){
    var neg = false;
    s = String(s);
    if (s.charAt(0) === '-') { neg = true; s = s.substring(1); }
    s = (s.length > 1) ? s.substring(0, s.length - 1) : '0';
    return (neg ? '-' : '') + (s === '' ? '0' : s);
  }

  function applyUnit(){
    var unit = val('f_unit');
    var nodes = root.querySelectorAll('[data-amt]');
    for (var i = 0; i < nodes.length; i++) {
      var raw = nodes[i].getAttribute('data-amt');
      nodes[i].textContent = sep(unit === 'toman' ? toToman(raw) : raw);
    }
  }

  // دکمهٔ بازهٔ سریعی که با مقدار فعلی فیلدهای تاریخ می‌خواند برجسته می‌شود
  function syncQuick(){
    var f = val('f_from'), t2 = val('f_to');
    var qs2 = root.querySelectorAll('button.qr');
    for (var n = 0; n < qs2.length; n++) {
      if (qs2[n].getAttribute('data-from') === f && qs2[n].getAttribute('data-to') === t2) {
        qs2[n].classList.add('on');
      } else {
        qs2[n].classList.remove('on');
      }
    }
  }

  function markSort(){
    var s = val('f_sort'), d = val('f_dir');
    var th = root.querySelectorAll('th.sortable');
    for (var i = 0; i < th.length; i++) {
      th[i].classList.remove('on', 'asc');
      if (th[i].getAttribute('data-s') === s) {
        th[i].classList.add('on');
        if (d === 'asc') { th[i].classList.add('asc'); }
      }
    }
  }

  root.addEventListener('click', function(e){
    var t = e.target;

    var pg = t.closest ? t.closest('button.pg') : null;
    if (pg && !pg.disabled) {
      var p = parseInt(pg.getAttribute('data-page'), 10);
      if (p > 0) { page = p; load(); }
      return;
    }

    var qr = t.closest ? t.closest('button.qr') : null;
    if (qr) {
      document.getElementById('f_from').value = qr.getAttribute('data-from');
      document.getElementById('f_to').value   = qr.getAttribute('data-to');
      syncQuick();
      apply();
      return;
    }

    var th = t.closest ? t.closest('th.sortable') : null;
    if (th) {
      var col = th.getAttribute('data-s');
      var se = document.getElementById('f_sort'), de = document.getElementById('f_dir');
      if (se.value === col) { de.value = (de.value === 'asc') ? 'desc' : 'asc'; }
      else { se.value = col; de.value = 'desc'; }
      apply();
      return;
    }

    var tr = t.closest ? t.closest('tr.row') : null;
    if (tr) {
      var k = tr.getAttribute('data-k');
      var det = root.querySelector('tr.det[data-d="' + k + '"]');
      if (det) {
        var on = det.className.indexOf('show') >= 0;
        det.className = on ? 'det' : 'det show';
        tr.className  = on ? 'row' : 'row open';
      }
    }
  });

  root.addEventListener('keydown', function(e){
    if (e.key !== 'Enter' && e.key !== ' ') return;
    var tr = e.target.closest ? e.target.closest('tr.row') : null;
    if (!tr) return;
    e.preventDefault();
    tr.click();
  });

  document.getElementById('b_apply').addEventListener('click', apply);

  document.getElementById('b_reset').addEventListener('click', function(){
    var ids = ['f_from','f_to','f_q','f_signer'];
    for (var i = 0; i < ids.length; i++) { document.getElementById(ids[i]).value = ''; }
    document.getElementById('f_org').value     = '0';
    document.getElementById('f_itype').value   = '0';
    document.getElementById('f_sstat').value   = 'all';
    document.getElementById('f_sgstate').value = 'any';
    document.getElementById('f_sort').value    = 'date';
    document.getElementById('f_dir').value     = 'desc';
    syncQuick();
    apply();
  });

  document.getElementById('b_print').addEventListener('click', function(){ window.print(); });
  document.getElementById('f_unit').addEventListener('change', applyUnit);

  var selIds = ['f_org','f_itype','f_sstat','f_sgstate','f_sort','f_dir','f_psize'];
  for (var i = 0; i < selIds.length; i++) {
    document.getElementById(selIds[i]).addEventListener('change', apply);
  }

  var txtIds = ['f_from','f_to','f_q','f_signer'];
  for (var j = 0; j < txtIds.length; j++) {
    document.getElementById(txtIds[j]).addEventListener('keydown', function(e){
      if (e.key === 'Enter') { e.preventDefault(); syncQuick(); apply(); }
    });
    document.getElementById(txtIds[j]).addEventListener('input', syncQuick);
  }

  applyUnit();
  markSort();
  syncQuick();
})();
</script>
</div>]],
  })
end

------------------------------------------------------------------------------
-- اجرا — هیچ خطایی نباید فرار کند، وگرنه بدنهٔ پاسخ خالی و ۵۰۰ می‌شود
------------------------------------------------------------------------------
local is_fragment = (F.part == "rows")

-- گارد دسترسی — روی هر دو حالت اجرا (صفحهٔ کامل و قطعهٔ XHR) اعمال می‌شود،
-- وگرنه با فراخوانی مستقیم ?part=rows دور زده می‌شد.
local function guard()
  local ok_self, si = pcall(teamyar.self)
  if ok_self and type(si) == "table" and tonumber(si.is_public) == 1 then
    return "این بات نباید عمومی (public) باشد؛ داده‌های مالی همهٔ سازمان‌ها را " ..
           "نمایش می‌دهد. لطفاً «دسترسی عمومی» را در تنظیمات بات خاموش کنید."
  end

  local ok_me, me = pcall(teamyar.get_user_info)
  if not ok_me or type(me) ~= "table" or not tonumber(me.id) or tonumber(me.id) <= 0 then
    return "کاربر شناسایی نشد. این بات فقط برای کاربران واردشده قابل اجراست."
  end
  return nil
end

local denied = guard()
if denied then
  teamyar.write_result(
    '<div dir="rtl" style="font-family:Tahoma,sans-serif;padding:22px;color:#a52f2f;' ..
    'background:#fbe6e6;border:1px solid #f0c9c9;border-radius:9px;line-height:2">' ..
    esc(denied) .. '</div>')
  return
end

local ok, result = pcall(is_fragment and build_results or build_page)

if not ok then
  teamyar.write_log("signed_invoices failed: " .. tostring(result))
  result = '<div dir="rtl" style="font-family:Tahoma,sans-serif;padding:18px;' ..
           'color:#a52f2f;background:#fbe6e6;border:1px solid #f0c9c9;border-radius:9px">' ..
           'خطا در تهیهٔ گزارش فاکتورهای امضاشده. لطفاً بازهٔ تاریخ را کوچک‌تر کنید ' ..
           'یا با پشتیبانی تماس بگیرید.</div>'
end

teamyar.write_result(tostring(result))
