-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/05/29 20:15

-- Bot: CRM + Sales Geographic Dashboard
-- botName = crm_geo_sales_dashboard
-- version = v04.1
-- تغییرات v04.1 (طبق گزارش زندهٔ کاربر پس از تست v04):
--   ۱) رفع باگ ساختاری «ارور JSON هنگام فیلتر»: بخش Dashboard اصلی (هم صفحهٔ کامل هم AJAX با format=json)
--      در همهٔ مسیرهای خطا (نه‌فقط خطای خاص) قبلاً همیشه HTML برمی‌گرداند (render_error_html) حتی وقتی
--      کلاینت صریحاً format=json خواسته بود — یعنی هر SQL error واقعی به‌جای JSON قابل‌Parse به شکل صفحهٔ
--      HTML به fetch().then(res.json()) می‌رسید و خطای عمومی «Unexpected token '<'» ایجاد می‌کرد (پیام
--      واقعی خطا هرگز دیده نمی‌شد). تابع جدید write_dashboard_error(input, message) اضافه شد که بر اساس
--      input.format تصمیم می‌گیرد JSON برگرداند یا HTML؛ همهٔ ۹ نقطهٔ خطای Dashboard اصلی (شامل pcall(main)
--      بیرونی) اصلاح شدند.
--   ۲) Preload ۳ تب غیرفعال، طبق درخواست صریح کاربر «موقع فراخوانی، B2B/B2C هم فراخوانی شود و تغییر تب
--      دوباره فراخوانی نکند». **تلاش اول** (همان روز، همین نسخه): هر ۴ تب در یک درخواست واحد سمت سرور
--      (حلقهٔ build_channel_view روی ۴ کانال) محاسبه می‌شد — این به گزارش زندهٔ کاربر «باز هم ارور JSON»
--      منجر شد: ۴× حجم Query (۲۵ کوئری، شامل ۴ بار اجرای Subquery سنگین بدون فیلتر تاریخ INVOICE_AMOUNT_JOIN
--      که خودش از قبل به‌عنوان ریسک Performance مستند بود) به محدودیت max_execute_time پلتفرم Teamyar
--      می‌خورد و یک صفحهٔ خطای HTML سطح پلتفرم برمی‌گشت (نه خطای Lua — write_dashboard_error نمی‌توانست آن
--      را ببیند). **طرح نهایی**: هر درخواست سرور فقط یک تب (تب فعال) را با build_channel_view محاسبه
--      می‌کند — دقیقاً هم‌سنگین قبل از v04. سه تب دیگر با ۳ درخواست جداگانه سمت کلاینت (fetchChannelView/
--      prefetchOtherChannels در REPORT_JS)، در پس‌زمینه و بعد از رندر تب فعال، پر می‌شوند — نه هم‌زمان در
--      یک درخواست. نتیجه: بارگذاری اولیه سریع (مثل قبل)، و بعد از چند ثانیهٔ پس‌زمینه، سوییچ تب هم بدون
--      Round-trip. اگر کاربر تبی را قبل از اتمام Prefetch کلیک کند، setActiveChannel یک Fallback ایمن
--      (fetchChannelView فقط برای همان یک تب) دارد.
--   ۳) رفع باگ «مشتری جدید»: MIN(RUN_DATE) قبلاً روی همان JOIN محدودشده به channel_extra محاسبه می‌شد —
--      یعنی زیر تب B2B، «اولین فاکتور» یعنی «اولین فاکتور B2B»، نه واقعاً اولین فاکتور مشتری در کل
--      Teamyar؛ مشتری چندسالهٔ B2C که امسال اولین‌بار B2B خریده، اشتباهاً «جدید» شمرده می‌شد. طبق اصلاح
--      صریح کاربر («کل تاریخ تیم‌یار را در نظر بگیر، نه بازهٔ فیلترشده») رفع شد: اکنون یک Subquery همبستهٔ
--      جدا (بدون channel_extra، بدون کران تاریخ) اولین فاکتور واقعی مشتری را در کل تاریخچه محاسبه می‌کند؛
--      JOIN اصلی (که مبلغ/تعداد این بازه را جمع می‌زند) همچنان به بازه+دسته فعال محدود است.
--   ۴) بهینه‌سازی Performance واقعی کوئری‌ها (طبق درخواست صریح کاربر): INVOICE_AMOUNT_JOIN/INVOICE_QUANTITY_JOIN
--      (Subquery مشترک محاسبهٔ مبلغ/تعداد فاکتور، مصرف‌شده در ۹+۱ محل این فایل) اکنون داخل خودشان
--      i2/i3.DELETED=0 AND CANCELED=0 AND PRE_INVOICE=0 را فیلتر می‌کنند. بدون‌ریسک — تک‌تک محل‌های مصرف
--      بررسی شد (2026-08-23) و همه از قبل دقیقاً همین سه شرط را روی همان فاکتور (si) اعمال می‌کردند؛ این
--      تغییر فقط ردیف‌های بی‌ربط (فاکتور حذف/کنسل/پیش‌فاکتور که در نتیجهٔ هیچ Query‌ای استفاده نمی‌شد) را
--      زودتر از GROUP BY حذف می‌کند — نتیجهٔ نهایی هیچ Query‌ای عوض نشد. فیلتر تاریخ (ریسک بالاتر، نیاز به
--      Threading پارامتر در هر محل مصرف) عمداً به بعد از تست زنده موکول شد (ر.ک. یادداشت بالای
--      INVOICE_AMOUNT_JOIN).
--   ۵) رفع باگ واقعی «بات باز نمی‌شود، در Loading گیر می‌کند» (کشف‌شده با دیباگ زندهٔ کاربر روی DevTools
--      Network — نه حدس): تأیید شد که خروجی خودِ بات همیشه سریع/موفق برمی‌گشت (200، ~۶۰ms)، ولی پنل
--      Teamyar خودش در یک Loop از فراخوانی مکرر Endpoint های داخلی‌اش (view/info/exist/acltypes/
--      active_session) گیر می‌افتاد و صفحه هرگز «تمام‌شده» حساب نمی‌شد (تأیید شد با تست کنترل: بات دیگری
--      از همان پنل مشکلی نداشت، یعنی خاص همین بات بود). علت یافت‌شده: بلوک <script> این بات بدون IIFE بود،
--      یعنی ده‌ها var/function سطح بالای آن (DASH, STATE_MAP, CHANNEL_CACHE, ACTIVE_CHANNEL,
--      applyDashboardUpdate, ...) مستقیم روی window (همان Scope سراسری صفحهٔ پنل) قرار می‌گرفتند — چون
--      صفحهٔ بات داخل DOM خودِ پنل Render می‌شود (نه iframe مجزا)، این نام‌های سراسری با متغیر/تابع داخلی
--      پنل (که چرخهٔ Loading/Session/ACL را مدیریت می‌کند) برخورد می‌کردند. رفع شد: کل REPORT_JS داخل یک
--      IIFE پیچیده شد؛ فقط ۱۸ تابعی که HTML با onclick="..." صدا می‌زند (ذاتاً باید Global باشند) صریحاً
--      روی window Export شدند، بقیه محبوس در Scope محلی ماندند.
-- v02 با موفقیت روی بات ۶۰۴ دیپلوی و تأیید شد (بعد از رفع باگ escape_html — رشتهٔ Entity پیوستهٔ Literal
-- هنگام ذخیرهٔ command توسط Teamyar بی‌صدا Decode می‌شد و کامپایل را می‌شکست؛ رفع شد با Concatenation،
-- طبق قانون از قبل مستند در CLAUDE.md). طبق دستور کاربر، منطق سالم v02 در v03 دست‌نخورده ماند.
-- تغییرات v03 (طبق درخواست صریح کاربر):
--   ۱) رفع باگ اسکرول در حالت تمام‌صفحه (#reportRoot:fullscreen بدون overflow صریح بود).
--   ۲) تفکیک B2B/B2C: تب‌های «همه/B2B (همکار)/B2C (مصرف‌کننده)/سایر» بر اساس مرکز درآمد فاکتور
--      (sales_invoice.SALES_CENTER -> pa_center.NAME؛ تأییدشده با Query زنده روی دادهٔ واقعی، نه حدس —
--      ر.ک. یادداشت CHANNEL_* در CONFIG برای اعداد دقیق). همهٔ Query های سمت فروش (KPI، تجمیع استان/شهر،
--      Drill-down مشتری/فاکتور، فاکتورهای بدون نگاشت جغرافیایی) اکنون channel-aware هستند؛ شمارش صرف
--      وجود مشتری در CRM (نه خریدش) عمداً مستقل از این تب ماند — چون خودِ مشتری ذاتاً B2B/B2C نیست، فقط
--      خریدهای او دسته دارند (ر.ک. build_channel_clause برای توضیح فنی محل صحیح این شرط در هر Query).
-- باگ v03 (پیدا و رفع شد قبل از v04): کلیک تب B2B/B2C گاهی خطای «Unexpected token '<'» می‌داد — علت
--   Submit خودکار native فرم (GET) که هم‌زمان با fetch AJAX (POST) رقابت می‌کرد؛ رفع شد با استخراج منطق
--   fetch به تابع مستقل submitFilterForm() که مستقیم صدا زده می‌شود، نه از طریق requestSubmit()/Event مصنوعی.
-- تغییرات v04 (طبق درخواست صریح کاربر):
--   ۱) کارت‌های KPI بالای صفحه اکنون واقعاً channel-aware هستند: fetch_crm_kpi اکنون filters می‌گیرد و از
--      یک EXISTS subquery (بدون محدودیت تاریخ، چون خودِ مشتری ذاتاً B2B/B2C نیست) برای فیلتر تب استفاده می‌کند.
--   ۲) فیلتر «تاریخ تا (شمسی)» اضافه شد (resolve_active_date_to_key + ورودی dateToInput)؛ همهٔ Query های
--      فروش/Drill-down اکنون هم date_from_key و هم date_to_key می‌گیرند (بازهٔ [از, تا) به‌جای فقط [از, ∞)).
--   ۳) کوئری «مجموع خرید بر اساس مرکز درآمد» (fetch_center_comparison) اضافه/بازبینی شد؛ نیاز به تأیید
--      نهایی با داده زنده پس از دیپلوی دارد (ر.ک. یادداشت پایین تابع).
--   ۴) بخش «۱۰ مشتری برتر» (fetch_top_customers) اکنون channel-aware است — با سوییچ تب B2B/B2C همان
--      بخش، فهرست مشتریان همان کانال را نشان می‌دهد (به‌جای دو بخش جدا برای B2B/B2C).
--   ۵) بخش «مقایسهٔ مراکز درآمد» (fetch_center_comparison/render_center_comparison_rows) فقط در تب «همه»
--      نمایش داده می‌شود (show_center_comparison)، چون در تب B2B/B2C خودِ مقایسه بی‌معنی است.
--   ۶) بخش «مشتریان جدید در این بازه» (fetch_new_customers_stats): تعداد + مجموع مبلغ خرید + مجموع تعداد
--      اقلام (بر اساس اولین فاکتور مشتری که در بازهٔ فعال افتاده)، در هر تب نمایش داده می‌شود.
--   نکتهٔ v04 (پیاده‌سازی/اصلاح‌شده در v04.1، ر.ک. Changelog بالا): Preload سه تب غیرفعال اکنون با
--      درخواست‌های جداگانهٔ پس‌زمینه سمت کلاینت انجام می‌شود، نه در یک درخواست سرور واحد (که به Timeout
--      می‌خورد).

-- داشبورد مدیریتی توزیع جغرافیایی مشتریان CRM و فروش (استان/شهر) — بر پایهٔ دادهٔ زندهٔ
-- crm_info / profile_main / profile_user_address / pa_client / sales_invoice / report_dimdate.
--
-- Mapping اعتبارسنجی‌شده (Discovery در 1405/05/23 روی بات ۵۸۹ = schema_probe_v2، با Query واقعی
-- روی داده زنده تأیید شد — چیزی حدس زده نشده):
--   شناسه CRM     = crm_info.ID = profile_main.ID = pa_client.REFFERE_ID  (روی ۲۰ نمونه واقعی تأیید شد)
--   نام مشتری     = profile_main.FULLNAME   (crm_info هیچ ستون نامی ندارد — تست شد)
--   آدرس مشتری    = profile_user_address (USER_ID = شناسه CRM) — هر مشتری دقیقاً ۲ ردیف آدرس دارد:
--                    TYPE=1 آدرس واقعی (۹۱٪ موارد پر است) و TYPE=2 که عملاً همیشه خالی است (۹۹.۳٪ خالی).
--                    Rule قطعی: فقط addr.TYPE=1 به‌عنوان «آدرس مشتری» در نظر گرفته می‌شود. Validate شد:
--                    بدون این فیلتر Join مستقیم به آدرس، فروش را دقیقاً ۲برابر می‌کند (187,761→372,432
--                    فاکتور و مبلغ هم دقیقاً ۲برابر)؛ با addr.TYPE=1 دقیقاً برابر با قبل از Join است.
--   فاکتور معتبر  = sales_invoice: DELETED=0 AND CANCELED=0 AND PRE_INVOICE=0
--   مبلغ فاکتور   = دیگر RECEPTION_AMOUNT+REMAINED_AMOUNT نیست (v01 اولیه) — از v02 به بعد فرمول واقعی
--    Production از دو بات مستقل (id=433/440، ر.ک. INVOICE_AMOUNT_JOIN پایین‌تر و
--    docs/context/SalesReportBotsReference.md یافتهٔ ۳): SUM روی sales_invoice_product با علامت منفی
--    برای TYPE=3 (برگشت از فروش)، به تأیید صریح کاربر (1405/05/24).
--   کد فاکتور     = sales_invoice.INVOICE_CODE (تست شد، ستون واقعی موجود است)
--   pa_client.REFFERE_ID یکتا نیست (یک مشتری CRM می‌تواند چند ردیف pa_client داشته باشد — تست شد،
--    مثال REFFERE_ID=10053 چهار ردیف pa_client دارد). این مشکلی برای SUM/COUNT فروش ایجاد نمی‌کند چون
--    هر sales_invoice.CLIENT_ID دقیقاً به یک pa_client.ID متصل است؛ به همین دلیل همه‌جا برای شمارش
--    مشتری از COUNT(DISTINCT crm_info.ID) استفاده شده، نه از pa_client.ID.
--   مرجع استان/شهر = crm_state_city بررسی و رد شد: فقط ۲۷٪ از جفت‌های (استان,شهر) واقعاً مصرف‌شده در
--    profile_user_address با آن تطبیق داشت؛ شهرهایی مثل شیراز/تبریز/مشهد اصلاً در آن جدول نبودند
--    (آن جدول فهرست ریزمحله/کدپستی است، نه فهرست رسمی شهر). به تأیید صریح کاربر پروژه (1405/05/23)،
--    مخرج KPI «پوشش جغرافیایی» = عدد ثابت مستند CONFIG.TOTAL_CITIES_IRAN (منبع در همان‌جا نوشته شده).
--   تاریخ فاکتور  = sales_invoice.RUN_DATE (FILETIME، تیک ۱۰۰ns از ۱۶۰۱) — تبدیل شمسی فقط از طریق
--    report_dimdate.DATEKEY/JNDATE انجام می‌شود، نه REPORT_FN_JDATE (که در بات‌های دیگر این پروژه با
--    خطای عمومی مواجه شده) و نه تقویم دستی Lua. برای Join یک ردیف فاکتور به روز مربوطه از الگوی
--    تأییدشدهٔ hr_dashboard_report_bot.lua استفاده شده: rd.DATEKEY = (RUN_DATE - MOD(RUN_DATE, 864000000000)).
--    نکتهٔ حیاتی: FILETIME (~1.3e17) از سقف عدد صحیح دقیق double (2^53) عبور می‌کند — تفریق/باقیمانده
--    روی این مقادیر همیشه در SQL انجام می‌شود، هرگز در Lua؛ در Lua این مقادیر فقط به‌عنوان پارامتر
--    Opaque بین دو Query رد و بدل می‌شوند (نه محاسبه‌شده) — دقیقاً همان قرارداد بات‌های دیگر پروژه.
--   نوع مشتری     = profile_user_info.USER_TYPE (تست شد: فقط دو مقدار در دادهٔ زنده — 3 و 4). برچسب
--    فارسی دقیق هر کد در هیچ جدول Enum/کامنتی تأیید نشد؛ در این نسخه به‌صورت خام «نوع ۳»/«نوع ۴» نمایش
--    داده می‌شود تا برچسب حدسی ساخته نشود — اگر معنای دقیق را دارید، در v02 جایگزین می‌شود.
--   سال مالی جاری = پیش‌فرض فیلتر تاریخ، به‌صورت پویا از report_dimdate محاسبه می‌شود (نه hardcode)،
--    طبق درخواست صریح کاربر برای محدودکردن گزارش به سال مالی جاری.

-- ============================================================
-- CONFIG
-- ============================================================

local CONFIG = {
    -- منبع: آمار رسمی شهرهای ایران، سال ۱۴۰۴ — تأیید صریح کاربر پروژه در جلسهٔ طراحی این بات
    -- (1405/05/23). هیچ جدول مرجع معتبری در دیتابیس Teamyar برای این عدد پیدا نشد (ر.ک. یادداشت بالا)؛
    -- این تنها استثنای مصوب hardcode در کل این بات است.
    TOTAL_CITIES_IRAN = 1458,
    DAY_TICKS = 864000000000, -- یک روز بر حسب تیک FILETIME (10,000,000 * 86400) — فقط در SQL استفاده می‌شود
    CUSTOMER_PAGE_SIZE = 50,
    TOP_CITIES_ON_DASHBOARD = 20,
    OTHER_SLICE_THRESHOLD_PCT = 2.0, -- استان‌های زیر این سهم در نمودار Donut داخل «سایر» گروه می‌شوند
    ADDRESS_TYPE_PRIMARY = 1,
    CRM_EDIT_URL_PREFIX = "/?page=/crm/client/edit/",
    -- تأییدشدهٔ زنده (1405/05/26): نسخهٔ Literal این رشته («&section=2») روی سرور، هنگام ذخیرهٔ command،
    -- به «§ion=2» تبدیل شده بود (Teamyar به‌صورت Greedy رشتهٔ «&sect» را به Entity نامدار HTML «§»
    -- Decode کرده، دقیقاً همان خانوادهٔ Quirk ذخیره‌سازی که برای escape_html در CLAUDE.md مستند است، ولی
    -- این‌بار روی یک رشتهٔ کاملاً بی‌ربط به HTML). رفع شد با Concatenation تا رشتهٔ «&sect» پیوسته در
    -- سورس ذخیره‌نشود — همان تکنیک escape_html.
    CRM_EDIT_URL_SUFFIX = "&" .. "section=2",
    INVOICE_VIEW_URL_PREFIX = "/?page=/sales/invoice/view_invoice/",
    -- تأییدشده (نه حدس) — از دو بات تولیدی مستقل («گزارش جامع فروش نسخه اصلی» id=433 و
    -- «گزارش فروش به تفکیک فاکتور» id=440، هر دو profile_user_info.USER_TYPE): 3=حقیقی، 4=حقوقی
    -- (ر.ک. docs/context/SalesReportBotsReference.md یافتهٔ ۱)
    USER_TYPE_LABELS = { ["3"] = "حقیقی", ["4"] = "حقوقی" },
    -- تفکیک B2B/B2C (v03، طبق درخواست صریح کاربر) — بر اساس مرکز درآمد فاکتور (sales_invoice.SALES_CENTER
    -- -> pa_center.NAME). تأییدشده با Query زنده روی داده واقعی (1405/05/24)، نه حدس:
    --   «فروش همکار» (id=80, 159,810 فاکتور) و «فروش همکار آفلاین» (id=96, 459 فاکتور) => B2B
    --   «فروش مصرف کننده» (id=81, 29,672 فاکتور) => B2C
    --   «فروش فروشگاه» (id=82, ۳ فاکتور) و «هئیت مدیره» (id=10, ۱ فاکتور) => نه B2B نه B2C؛ چون حجمشان
    --   ناچیز است (۴ از ۱۸۹,۹۴۵ فاکتور = ۰.۰۰۲٪) و کاربر فقط «همکار»/«مصرف‌کننده» را مشخص کرد، این دو در
    --   دستهٔ سوم «سایر» قرار می‌گیرند (حذف خاموش نمی‌شوند، طبق اصل شفافیت کیفیت‌داده همین بات).
    -- با LIKE روی نام (نه ID ثابت) تا اگر مرکز درآمد جدیدی با همین الگوی نام‌گذاری اضافه شد، خودکار
    -- شناسایی شود.
    CHANNEL_B2B_LIKE = "%همکار%",
    CHANNEL_B2C_LIKE = "%مصرف%",
    CHANNEL_LABELS = { b2b = "B2B (همکار)", b2c = "B2C (مصرف‌کننده)", other = "سایر" },
    -- لوگو «۱۴۰» (الزام CLAUDE.md برای بات‌های HTML جدید) — نسخهٔ White، چون روی نوار Accent هدر می‌نشیند
    LOGO140_WHITE_B64 = "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",
}

-- ============================================================
-- HELPERS
-- ============================================================

-- پیاده‌سازی مرجع escape_html (طبق CLAUDE.md، الزامی برای همهٔ بات‌ها) — یک رشتهٔ پیوستهٔ HTML Entity که
-- به‌صورت Literal مستقیم در سورس نوشته شود (amp/lt/gt/quot/apos)، هنگام ذخیرهٔ command توسط Teamyar
-- بی‌صدا Decode می‌شود (تأیید زندهٔ ۱۴۰۵/۰۵/۲۳ در CLAUDE.md، و تکرارشده این‌جا با خطای «unfinished
-- string near '"'» روی خط quot_entity) — باید هر Entity با Concatenation ساخته شود، نه Literal مستقیم.
local function escape_html(value)
    if value == nil then return "" end
    local amp_entity = "&" .. "amp;"
    local lt_entity = "&" .. "lt;"
    local gt_entity = "&" .. "gt;"
    local quot_entity = "&" .. "quot;"
    local apos_entity = "&" .. "#39;"
    return tostring(value)
        :gsub("&", amp_entity)
        :gsub("<", lt_entity)
        :gsub(">", gt_entity)
        :gsub('"', quot_entity)
        :gsub("'", apos_entity)
end

local function fmt_num(value)
    local n = tonumber(value)
    if n == nil then return "0" end
    local s = tostring(math.floor(n + 0.5))
    local sign = ""
    if s:sub(1, 1) == "-" then
        sign = "-"
        s = s:sub(2)
    end
    return sign .. s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function fmt_dec1(value)
    local n = tonumber(value)
    if n == nil then return "0.0" end
    return string.format("%.1f", n)
end

local function fmt_pct(part, total)
    local t = tonumber(total) or 0
    if t <= 0 then return 0.0 end
    return (tonumber(part) or 0) / t * 100.0
end

local function safe_str(v, default_v)
    if v == nil or v == "" then return default_v or "—" end
    return tostring(v)
end

local function user_type_label(code)
    if code == nil then return "نامشخص" end
    return CONFIG.USER_TYPE_LABELS[tostring(code)] or ("نوع " .. tostring(code))
end

-- ============================================================
-- DATABASE HELPERS
-- ============================================================

local function fetch_rows(query, params)
    pcall(function() db.use_db("0000000") end)
    local ok, err = pcall(function()
        db.query({ query = query, params = params or {} })
    end)
    if not ok then return nil, err end
    local rows = {}
    local record = {}
    while db.query_fetch(record) do
        local row = {}
        for i = 1, #record do row[i] = record[i] end
        table.insert(rows, row)
    end
    db.query_free()
    return rows
end

-- ============================================================
-- DATE HELPERS (فقط report_dimdate — بدون REPORT_FN_JDATE و بدون محاسبهٔ دستی Lua)
-- ============================================================

local function fetch_now_raw()
    local rows, err = fetch_rows("SELECT (UNIX_TIMESTAMP() + 11644473600) * 10000000 AS now_raw", {})
    if rows == nil or #rows == 0 then return nil, err end
    return rows[1][1]
end

-- ابتدای سال مالی جاری (شمسی) را به‌صورت پویا از report_dimdate پیدا می‌کند — بدون hardcode سال
local function resolve_fiscal_year_start(now_raw)
    if now_raw == nil then return nil, nil end
    local year_rows = fetch_rows(
        "SELECT JYEAR FROM report_dimdate WHERE DATEKEY = (? - MOD(?, " .. CONFIG.DAY_TICKS .. ")) LIMIT 1",
        { now_raw, now_raw })
    if year_rows == nil or #year_rows == 0 then return nil, nil end
    local jyear = year_rows[1][1]
    local jndate = tostring(jyear) .. "/01/01"
    local key_rows = fetch_rows("SELECT DATEKEY FROM report_dimdate WHERE JNDATE = ? LIMIT 1", { jndate })
    if key_rows == nil or #key_rows == 0 then return nil, jndate end
    return key_rows[1][1], jndate
end

-- ورودی متنی کاربر (شمسی "1405/01/01") را به DATEKEY تبدیل می‌کند؛ نامعتبر/یافت‌نشده => nil (بدون خطا)
local function resolve_date_from_text(text)
    if text == nil then return nil end
    text = tostring(text):gsub("^%s+", ""):gsub("%s+$", "")
    if not text:match("^%d%d%d%d/%d%d?/%d%d?$") then return nil end
    local rows = fetch_rows("SELECT DATEKEY FROM report_dimdate WHERE JNDATE = ? LIMIT 1", { text })
    if rows == nil or #rows == 0 then return nil end
    return rows[1][1]
end

-- تعیین بازهٔ تاریخ فعال (مشترک بین Dashboard اصلی و همهٔ Drill-down های Lazy) — طبق درخواست کاربر
-- (مشابه الگوی بات ۶۰۰: محاسبهٔ «مبلغ فروش هر مشتری» همیشه باید با همان فیلتر تاریخ باشد، نه کل تاریخچه).
-- اگر ورودی date_from معتبر نباشد/نیامده باشد، بدون خطا به ابتدای سال مالی جاری برمی‌گردد (نه hardcode).
local function resolve_active_date_from_key(input)
    local date_from_text = input["date_from"]
    if date_from_text == "" then date_from_text = nil end
    local date_from_key = nil
    if date_from_text ~= nil then
        date_from_key = resolve_date_from_text(date_from_text)
    end
    if date_from_key ~= nil then return date_from_key, date_from_text end
    local now_raw = fetch_now_raw()
    local fy_key, fy_jndate = resolve_fiscal_year_start(now_raw)
    return fy_key, fy_jndate
end

-- بازهٔ تاریخ اکنون دو‌سر است (طبق درخواست کاربر: «تاریخ از داره تا نداره») — کران بالا Exclusive است
-- (RUN_DATE < date_to_key) تا روز date_to کامل شامل شود؛ محاسبهٔ «DATEKEY + یک روز» همیشه در SQL انجام
-- می‌شود (نه Lua) چون FILETIME از دقت صحیح double عبور می‌کند. پیش‌فرض بدون ورودی: تا پایان امروز.
local function resolve_active_date_to_key(input)
    local date_to_text = input["date_to"]
    if date_to_text == "" then date_to_text = nil end
    if date_to_text ~= nil then
        local text = tostring(date_to_text):gsub("^%s+", ""):gsub("%s+$", "")
        if text:match("^%d%d%d%d/%d%d?/%d%d?$") then
            local rows = fetch_rows(
                "SELECT (DATEKEY + " .. CONFIG.DAY_TICKS .. ") FROM report_dimdate WHERE JNDATE = ? LIMIT 1",
                { text })
            if rows ~= nil and #rows > 0 then return rows[1][1], text end
        end
    end
    local now_raw = fetch_now_raw()
    if now_raw == nil then return nil, nil end
    local rows = fetch_rows(
        "SELECT (DATEKEY + " .. CONFIG.DAY_TICKS .. "), JNDATE FROM report_dimdate WHERE DATEKEY = (? - MOD(?, " .. CONFIG.DAY_TICKS .. ")) LIMIT 1",
        { now_raw, now_raw })
    if rows == nil or #rows == 0 then return nil, nil end
    return rows[1][1], rows[1][2]
end

-- ============================================================
-- INPUT / FILTER PARSING
-- ============================================================

local function parse_filters(input)
    input = input or {}
    local state = input["state"]
    if state == "" then state = nil end
    local city = input["city"]
    if city == "" then city = nil end
    local user_type = tonumber(input["user_type"])
    local date_from_text = input["date_from"]
    if date_from_text == "" then date_from_text = nil end
    local date_to_text = input["date_to"]
    if date_to_text == "" then date_to_text = nil end
    -- دستهٔ کسب‌وکار (v03): "b2b" | "b2c" | "other" | nil (= همه)
    local channel = input["channel"]
    if channel ~= "b2b" and channel ~= "b2c" and channel ~= "other" then channel = nil end
    return {
        state = state,
        city = city,
        user_type = user_type,
        date_from_text = date_from_text,
        date_to_text = date_to_text,
        channel = channel,
    }
end

-- ============================================================
-- INVOICE AMOUNT (فرمول واقعی Production)
-- ============================================================
-- منبع: دو بات تولیدی مستقل («گزارش جامع فروش نسخه اصلی» id=433 و «گزارش فروش به تفکیک فاکتور» id=440 —
-- ر.ک. docs/context/SalesReportBotsReference.md یافتهٔ ۳). به تأیید صریح کاربر (1405/05/24) جایگزین
-- RECEPTION_AMOUNT+REMAINED_AMOUNT شد چون آن فرمول برگشت‌ازفروش (sales_invoice.TYPE=3) را کسر نمی‌کرد.
-- مبلغ هر فاکتور = SUM روی ردیف‌های sales_invoice_product: (FEE/۱۰^رقم‌اعشار × QUANTITY/۱۰^رقم‌اعشار‌انبار)
-- - DISCOUNT + VALUE_ADDED + TAX/۱۰^رقم‌اعشار + TOLL/۱۰^رقم‌اعشار — با علامت منفی برای TYPE=3 (برگشت از فروش).
-- توجه Performance: این Subquery روی کل sales_invoice_product (بدون فیلتر تاریخ) SUM می‌گیرد — چون GROUP BY
-- دارد، MySQL معمولاً آن را قبل از JOIN با si کامل می‌سازد (Derived Table Merge برای Query های Aggregate
-- تضمین‌شده نیست). **بهینه‌سازی v04.1 (بدون‌ریسک)**: فیلتر i2.DELETED/CANCELED/PRE_INVOICE داخل خودِ
-- Subquery (پایین‌تر) اضافه شد — هر ۹ محل مصرف این Join در این فایل از قبل دقیقاً همین سه شرط را روی همان
-- فاکتور (si، هم‌ارز i2 چون ia.invoice_id = si.ID) اعمال می‌کنند؛ بررسی‌شده (2026-08-23)، هیچ محل مصرفی
-- بدون این فیلتر روی si نیست. پس این تغییر هیچ نتیجهٔ نهایی را عوض نمی‌کند، فقط فاکتورهای بی‌ربط
-- (حذف‌شده/کنسل‌شده/پیش‌فاکتور) را زودتر از GROUP BY کنار می‌گذارد. **مهم — این توضیح عمداً بیرون از
-- رشتهٔ [[...]] نوشته شده، نه داخل خودِ متن SQL**: قرار دادن کامنت‌های طولانی فارسی داخل رشتهٔ SQL واقعی
-- (که مستقیماً به db.query می‌رود) ریسک غیرضروری است — طبق سابقهٔ مستند این پروژه در CLAUDE.md، متن‌های
-- غیرمعمول گاهی حین ذخیرهٔ command توسط Teamyar به‌طور غیرمنتظره Mangle می‌شوند؛ کامنت SQL تنها اگر واقعاً
-- لازم باشد باید کوتاه و ساده (`-- text`) بماند، نه یک بلوک چندخطی مستندسازی.
-- فیلتر تاریخ هنوز عمداً اضافه نشد (نیاز به Threading پارامتر در هر ۹ محل مصرف دارد، ریسک بالاتر بدون تست
-- زنده). قبل از اجرای زنده روی محیط Production، زمان اجرا را با/بدون این بهینه‌سازی مقایسه کنید؛ اگر هنوز
-- کند بود، گام بعدی افزودن فیلتر تاریخ (i2.RUN_DATE) یا Index روی sales_invoice_product(INVOICE_ID)
-- (احتمالاً به‌عنوان FK از قبل موجود است) — بدون اجازهٔ کاربر Index جدید ساخته نشود.
local INVOICE_AMOUNT_JOIN = [[
LEFT JOIN (
    SELECT
        ip.INVOICE_ID AS invoice_id,
        SUM(
            (CASE WHEN i2.TYPE = 3 THEN -1 ELSE 1 END) *
            (
                COALESCE((ip.QUANTITY / POW(10, COALESCE(sc.DECIMAL_NUM, 0))) * (ip.FEE / POW(10, COALESCE(dd.digit_fee, 0))), 0)
                - COALESCE(ip.DISCOUNT, 0)
                + COALESCE(ip.VALUE_ADDED, 0)
                + COALESCE(ip.TAX / POW(10, COALESCE(dd.digit_fee, 0)), 0)
                + COALESCE(ip.TOLL / POW(10, COALESCE(dd.digit_fee, 0)), 0)
            )
        ) AS amount
    FROM sales_invoice_product ip
    INNER JOIN sales_invoice i2 ON i2.ID = ip.INVOICE_ID
    LEFT JOIN wh_product wp ON wp.ID = ip.PRODUCT_ID
    LEFT JOIN wh_stock_capacity sc ON sc.ID = wp.CAPACITY_ID
    LEFT JOIN (
        SELECT po.ORG_ID,
            (CASE WHEN COALESCE(ps.FEE_DECIMAL, 0) = 0 THEN COALESCE(ps.DECIMAL_COUNT, 0) ELSE COALESCE(ps.FEE_DECIMAL, 0) END) AS digit_fee
        FROM pa_organizations po
        INNER JOIN pa_symbols ps ON ps.ID = po.BASE_CURRENCY AND ps.ORG_ID = po.ORG_ID
    ) dd ON dd.ORG_ID = i2.ORG_ID
    WHERE i2.DELETED = 0 AND i2.CANCELED = 0 AND i2.PRE_INVOICE = 0
    GROUP BY ip.INVOICE_ID
) ia ON ia.invoice_id = si.ID
]]

-- تعداد خالص اقلام کالای خریداری‌شده (برای KPI «مشتریان جدید»، v04) — همان قرارداد علامت TYPE=3
-- (برگشت از فروش با علامت منفی) و همان نرمال‌سازی اعشار انبار (wh_stock_capacity.DECIMAL_NUM) که در
-- INVOICE_AMOUNT_JOIN استفاده شده، برای هم‌خوانی؛ این تفسیر (SUM تعداد واحد، نه COUNT ردیف کالا) تأییدشدهٔ
-- کاربر نیست، فرض معقول است — بعد از دیپلوی روی داده واقعی سنجیده شود.
-- همان بهینه‌سازی بدون‌ریسک INVOICE_AMOUNT_JOIN (ر.ک. یادداشت آنجا برای توضیح کامل) — تنها محل مصرف این
-- Join (fetch_new_customers_stats) از قبل si.DELETED=0/CANCELED=0/PRE_INVOICE=0 را روی همان فاکتور دارد.
local INVOICE_QUANTITY_JOIN = [[
LEFT JOIN (
    SELECT
        ip.INVOICE_ID AS invoice_id,
        SUM((CASE WHEN i3.TYPE = 3 THEN -1 ELSE 1 END) * COALESCE(ip.QUANTITY / POW(10, COALESCE(sc3.DECIMAL_NUM, 0)), 0)) AS qty
    FROM sales_invoice_product ip
    INNER JOIN sales_invoice i3 ON i3.ID = ip.INVOICE_ID
    LEFT JOIN wh_product wp3 ON wp3.ID = ip.PRODUCT_ID
    LEFT JOIN wh_stock_capacity sc3 ON sc3.ID = wp3.CAPACITY_ID
    WHERE i3.DELETED = 0 AND i3.CANCELED = 0 AND i3.PRE_INVOICE = 0
    GROUP BY ip.INVOICE_ID
) iq ON iq.invoice_id = si.ID
]]

-- ============================================================
-- EXECUTIVE KPI QUERIES
-- ============================================================

-- سمت فروش — پارامتری با بازهٔ تاریخ + فیلتر استان/شهر/نوع مشتری اختیاری
local function build_sales_filter_clause(filters)
    local extra = ""
    local params = {}
    if filters.state ~= nil then
        extra = extra .. " AND addr.STATE = ?"
        table.insert(params, filters.state)
    end
    if filters.city ~= nil then
        extra = extra .. " AND addr.CITY = ?"
        table.insert(params, filters.city)
    end
    if filters.user_type ~= nil then
        extra = extra .. " AND ui.USER_TYPE = ?"
        table.insert(params, filters.user_type)
    end
    return extra, params
end

-- شرط دستهٔ کسب‌وکار (v03) — به alias «ctr» (pa_center، از طریق sales_invoice.SALES_CENTER) نیاز دارد.
-- از Subquery همبسته برای نام مرکز درآمد استفاده می‌شود (نه یک alias جداگانه از pa_center) تا این شرط
-- بدون وابستگی به ترتیب JOIN، هم در WHERE بیرونی (Query‌هایی که sales_invoice پایهٔ اصلی FROM است —
-- fetch_sales_kpi/fetch_invoices/fetch_invoices_missing_geo) و هم داخل ON خودِ LEFT JOIN sales_invoice
-- (fetch_state_aggregation/fetch_city_aggregation/fetch_customers، جایی که si اختیاری است) یکسان کار کند.
-- توجه مهم: در Query‌های دستهٔ دوم (LEFT JOIN)، این شرط را هرگز به WHERE بیرونی اضافه نکنید — مشتریانی که
-- اصلاً فاکتوری در آن دسته ندارند si.SALES_CENTER=NULL خواهند داشت و افزودن به WHERE بیرونی کل ردیف
-- مشتری (نه فقط فروش او) را از تجمیع حذف می‌کند و unique_customer_count را هم غلط کم می‌کند.
-- نکتهٔ حیاتی (کشف‌شده 1405/05/26 حین تست زندهٔ همین بات توسط کاربر — نه حدس): پارامتری‌کردن LIKE با
-- «?» در لایهٔ db.query این پلتفرم Teamyar شکست می‌خورد — پارامتر رسیده بی‌صدا نادیده گرفته می‌شود
-- (تعداد Placeholder با تعداد Param واقعی جور درنمی‌آید) و «sql error» برمی‌گرداند؛ تأیید شد با تست
-- ایزوله روی bot 589/schema_probe_v2: «= ?» پارامتری کار می‌کند، «LIKE ?» نه (ر.ک. یادداشت مشابه در
-- CLAUDE.md و sales_revenue_center_dashboard_report_bot.lua). چون CHANNEL_B2B_LIKE/CHANNEL_B2C_LIKE
-- ثابت‌های Hardcode همین فایل‌اند (هرگز از ورودی کاربر خوانده نمی‌شوند)، بدون ریسک SQL Injection
-- مستقیماً به‌صورت Literal رشته‌ای درج می‌شوند، نه به‌عنوان Param.
local function build_channel_clause(filters)
    local extra = ""
    local center_name = "(SELECT pcc.NAME FROM pa_center pcc WHERE pcc.ID = si.SALES_CENTER)"
    if filters.channel == "b2b" then
        extra = " AND " .. center_name .. " LIKE '" .. CONFIG.CHANNEL_B2B_LIKE .. "'"
    elseif filters.channel == "b2c" then
        extra = " AND " .. center_name .. " LIKE '" .. CONFIG.CHANNEL_B2C_LIKE .. "'"
    elseif filters.channel == "other" then
        extra = " AND (" .. center_name .. " IS NULL OR (" .. center_name .. " NOT LIKE '" .. CONFIG.CHANNEL_B2B_LIKE ..
            "' AND " .. center_name .. " NOT LIKE '" .. CONFIG.CHANNEL_B2C_LIKE .. "'))"
    end
    return extra, {}
end

-- سمت CRM/مشتری — بدون بازهٔ تاریخ (تاریخچهٔ کامل)، ولی channel-aware (v04، طبق درخواست کاربر: کارت‌های
-- هدر باید با تغییر تب واقعاً تغییر کنند). وقتی دسته‌ای انتخاب شده، «تعداد کل مشتریان CRM» یعنی «مشتریانی
-- که حداقل یک فاکتور معتبر در این دسته دارند» — عمداً بدون کران تاریخ (کل تاریخچه، نه فقط بازهٔ فعال) تا
-- با «تعداد مشتریان خریدار» (که هم دسته و هم بازهٔ تاریخ را لحاظ می‌کند) یک مفهوم جدا و معنادار بماند، نه
-- عدد تکراری. customers_without_state/city هم به همین ترتیب در دستهٔ انتخاب‌شده محاسبه می‌شوند.
local function fetch_crm_kpi(filters)
    local channel_extra = ""
    if filters ~= nil and filters.channel ~= nil then
        local inner_extra = build_channel_clause(filters)
        channel_extra = [[
WHERE EXISTS (
    SELECT 1 FROM pa_client pc
    INNER JOIN sales_invoice si ON si.CLIENT_ID = pc.ID AND si.DELETED = 0 AND si.CANCELED = 0 AND si.PRE_INVOICE = 0]] .. inner_extra .. [[

    WHERE pc.REFFERE_ID = ci.ID
)
]]
    end
    local rows, err = fetch_rows([[
SELECT
    COUNT(DISTINCT ci.ID) AS total_crm_customers,
    COUNT(DISTINCT CASE WHEN addr.STATE IS NOT NULL AND addr.STATE <> '' THEN addr.STATE END) AS states_with_customers,
    COUNT(DISTINCT CASE WHEN addr.CITY IS NOT NULL AND addr.CITY <> '' THEN addr.CITY END) AS cities_with_customers,
    SUM(CASE WHEN addr.USER_ID IS NULL OR addr.STATE IS NULL OR addr.STATE = '' THEN 1 ELSE 0 END) AS customers_without_state,
    SUM(CASE WHEN addr.USER_ID IS NULL OR addr.CITY IS NULL OR addr.CITY = '' THEN 1 ELSE 0 END) AS customers_without_city
FROM crm_info ci
LEFT JOIN profile_user_address addr ON addr.USER_ID = ci.ID AND addr.TYPE = ]] .. CONFIG.ADDRESS_TYPE_PRIMARY .. [[

]] .. channel_extra .. [[
]], {})
    if rows == nil or #rows == 0 then return nil, err end
    local r = rows[1]
    return {
        total_crm_customers = tonumber(r[1]) or 0,
        states_with_customers = tonumber(r[2]) or 0,
        cities_with_customers = tonumber(r[3]) or 0,
        customers_without_state = tonumber(r[4]) or 0,
        customers_without_city = tonumber(r[5]) or 0,
    }
end

-- ۱۰ مشتری برتر (بر اساس مبلغ خرید) در بازهٔ تاریخ + دستهٔ فعال — طبق درخواست کاربر v04، هر تب فهرست
-- برتر خودش را نشان می‌دهد (B2B/B2C جدا). city-independent — کل کشور، نه محدود به یک شهر خاص.
local function fetch_top_customers(date_from_key, date_to_key, filters, limit)
    local channel_extra = build_channel_clause(filters or {})
    local rows, err = fetch_rows([[
SELECT
    ci.ID, pm.FULLNAME, addr.STATE, addr.CITY,
    COUNT(si.ID) AS invoice_count,
    COALESCE(SUM(ia.amount), 0) AS total_purchase_amount
FROM crm_info ci
INNER JOIN profile_main pm ON pm.ID = ci.ID
LEFT JOIN profile_user_address addr ON addr.USER_ID = ci.ID AND addr.TYPE = ]] .. CONFIG.ADDRESS_TYPE_PRIMARY .. [[

INNER JOIN pa_client pc ON pc.REFFERE_ID = ci.ID
INNER JOIN sales_invoice si ON si.CLIENT_ID = pc.ID AND si.DELETED = 0 AND si.CANCELED = 0 AND si.PRE_INVOICE = 0
  AND si.RUN_DATE >= ? AND si.RUN_DATE < ?]] .. channel_extra .. [[

]] .. INVOICE_AMOUNT_JOIN .. [[
GROUP BY ci.ID, pm.FULLNAME, addr.STATE, addr.CITY
ORDER BY total_purchase_amount DESC
LIMIT ?
]], { date_from_key, date_to_key, limit })
    if rows == nil then return nil, err end
    local list = {}
    for _, r in ipairs(rows) do
        table.insert(list, {
            crm_id = r[1], customer_name = r[2], state_name = r[3], city_name = r[4],
            invoice_count = tonumber(r[5]) or 0, total_purchase_amount = tonumber(r[6]) or 0,
        })
    end
    return list
end

-- مقایسهٔ تعداد فاکتور/مبلغ/تعداد مشتری بر اساس مرکز درآمد خام (نه فقط دستهٔ B2B/B2C جمع‌شده) — طبق
-- درخواست کاربر v04، فقط در تب «همه» نمایش داده می‌شود؛ عمداً مستقل از فیلتر channel است (خودش این تفکیک
-- را کامل‌تر نشان می‌دهد).
local function fetch_center_comparison(date_from_key, date_to_key)
    local rows, err = fetch_rows([[
SELECT
    COALESCE(ctr.NAME, 'نامشخص') AS center_name,
    COUNT(si.ID) AS invoice_count,
    COUNT(DISTINCT ci.ID) AS customer_count,
    COALESCE(SUM(ia.amount), 0) AS total_amount
FROM sales_invoice si
INNER JOIN pa_client pc ON pc.ID = si.CLIENT_ID
INNER JOIN crm_info ci ON ci.ID = pc.REFFERE_ID
LEFT JOIN pa_center ctr ON ctr.ID = si.SALES_CENTER
]] .. INVOICE_AMOUNT_JOIN .. [[
WHERE si.DELETED = 0 AND si.CANCELED = 0 AND si.PRE_INVOICE = 0
  AND si.RUN_DATE >= ? AND si.RUN_DATE < ?
GROUP BY ctr.NAME
ORDER BY total_amount DESC
]], { date_from_key, date_to_key })
    if rows == nil then return nil, err end
    local list = {}
    for _, r in ipairs(rows) do
        table.insert(list, {
            center_name = r[1], invoice_count = tonumber(r[2]) or 0,
            customer_count = tonumber(r[3]) or 0, total_amount = tonumber(r[4]) or 0,
        })
    end
    return list
end

-- مشتریان «جدید»: کسانی که اولین فاکتور معتبرشان در کل تاریخچهٔ تیم‌یار (همهٔ مراکز درآمد/دسته‌ها، بدون هیچ
-- کران زمانی یا فیلتر channel — طبق اصلاح صریح کاربر v04: «کل تاریخ تیم‌یار را در نظر بگیر نه بازهٔ فیلترشده»)
-- داخل بازهٔ تاریخ فعال افتاده. باگ نسخهٔ قبلی: MIN(si.RUN_DATE) روی همان JOIN محدودشده به channel_extra
-- محاسبه می‌شد — یعنی وقتی تب B2B فعال بود، «اولین فاکتور» یعنی «اولین فاکتور B2B»، نه واقعاً اولین فاکتور
-- مشتری در کل Teamyar؛ مشتری‌ای که سال‌ها مشتری B2C بوده و امسال اولین‌بار از B2B خرید کرده، اشتباهاً
-- «جدید» شمرده می‌شد. رفع شد: تاریخ اولین فاکتور واقعی با Subquery همبستهٔ جداگانه (بدون channel_extra و
-- بدون کران تاریخ) محاسبه می‌شود؛ JOIN اصلی (که مبلغ/تعداد این بازه را جمع می‌زند) همچنان به بازه+دسته
-- فعال محدود است — هم برای معنای صحیح «خرید این تب در این بازه» و هم برای Performance (فیلتر RUN_DATE در
-- شرط JOIN اعمال می‌شود، نه با CASE WHEN بعد از Join کل تاریخچه).
local function fetch_new_customers_stats(date_from_key, date_to_key, filters)
    local channel_extra = build_channel_clause(filters or {})
    local rows, err = fetch_rows([[
SELECT COUNT(*), COALESCE(SUM(t.window_amount), 0), COALESCE(SUM(t.window_qty), 0)
FROM (
    SELECT
        ci.ID AS crm_id,
        (
            SELECT MIN(si_all.RUN_DATE)
            FROM sales_invoice si_all
            INNER JOIN pa_client pc_all ON pc_all.ID = si_all.CLIENT_ID
            WHERE pc_all.REFFERE_ID = ci.ID
              AND si_all.DELETED = 0 AND si_all.CANCELED = 0 AND si_all.PRE_INVOICE = 0
        ) AS global_first_run_date,
        COALESCE(SUM(ia.amount), 0) AS window_amount,
        COALESCE(SUM(iq.qty), 0) AS window_qty
    FROM crm_info ci
    INNER JOIN pa_client pc ON pc.REFFERE_ID = ci.ID
    INNER JOIN sales_invoice si ON si.CLIENT_ID = pc.ID AND si.DELETED = 0 AND si.CANCELED = 0 AND si.PRE_INVOICE = 0
      AND si.RUN_DATE >= ? AND si.RUN_DATE < ?]] .. channel_extra .. [[

    ]] .. INVOICE_AMOUNT_JOIN .. [[
    ]] .. INVOICE_QUANTITY_JOIN .. [[
    GROUP BY ci.ID
) t
WHERE t.global_first_run_date >= ? AND t.global_first_run_date < ?
]], { date_from_key, date_to_key, date_from_key, date_to_key })
    if rows == nil or #rows == 0 then return nil, err end
    local r = rows[1]
    return {
        new_customer_count = tonumber(r[1]) or 0,
        new_customer_amount = tonumber(r[2]) or 0,
        new_customer_qty = tonumber(r[3]) or 0,
    }
end

local function fetch_sales_kpi(date_from_key, date_to_key, filters)
    local extra, extra_params = build_sales_filter_clause(filters)
    local channel_extra, channel_params = build_channel_clause(filters)
    extra = extra .. channel_extra -- sales_invoice پایهٔ اصلی FROM است، پس افزودن به WHERE درست است
    local params = { date_from_key, date_to_key }
    for _, p in ipairs(extra_params) do table.insert(params, p) end
    for _, p in ipairs(channel_params) do table.insert(params, p) end

    local rows, err = fetch_rows([[
SELECT
    COUNT(si.ID) AS total_valid_invoices,
    COUNT(DISTINCT ci.ID) AS buyer_customers,
    COALESCE(SUM(ia.amount), 0) AS total_sales_amount,
    COUNT(DISTINCT CASE WHEN addr.STATE IS NOT NULL AND addr.STATE <> '' THEN addr.STATE END) AS states_with_sales,
    COUNT(DISTINCT CASE WHEN addr.CITY IS NOT NULL AND addr.CITY <> '' THEN addr.CITY END) AS cities_with_sales,
    SUM(CASE WHEN addr.USER_ID IS NULL OR addr.STATE IS NULL OR addr.STATE = '' OR addr.CITY IS NULL OR addr.CITY = '' THEN 1 ELSE 0 END) AS invoices_without_geo_mapping
FROM sales_invoice si
INNER JOIN pa_client pc ON pc.ID = si.CLIENT_ID
INNER JOIN crm_info ci ON ci.ID = pc.REFFERE_ID
LEFT JOIN profile_user_address addr ON addr.USER_ID = pc.REFFERE_ID AND addr.TYPE = ]] .. CONFIG.ADDRESS_TYPE_PRIMARY .. [[

LEFT JOIN profile_user_info ui ON ui.ID = pc.REFFERE_ID
]] .. INVOICE_AMOUNT_JOIN .. [[
WHERE si.DELETED = 0 AND si.CANCELED = 0 AND si.PRE_INVOICE = 0
  AND si.RUN_DATE >= ? AND si.RUN_DATE < ?]] .. extra .. [[
]], params)
    if rows == nil or #rows == 0 then return nil, err end
    local r = rows[1]
    return {
        total_valid_invoices = tonumber(r[1]) or 0,
        buyer_customers = tonumber(r[2]) or 0,
        total_sales_amount = tonumber(r[3]) or 0,
        states_with_sales = tonumber(r[4]) or 0,
        cities_with_sales = tonumber(r[5]) or 0,
        invoices_without_geo_mapping = tonumber(r[6]) or 0,
    }
end

-- ============================================================
-- STATE / CITY AGGREGATION
-- ============================================================

local function fetch_state_aggregation(date_from_key, date_to_key, filters)
    local extra, extra_params = build_sales_filter_clause(filters)
    local channel_extra, channel_params = build_channel_clause(filters)
    local params = { date_from_key, date_to_key }
    for _, p in ipairs(channel_params) do table.insert(params, p) end
    for _, p in ipairs(extra_params) do table.insert(params, p) end

    local rows, err = fetch_rows([[
SELECT
    addr.STATE AS state_name,
    COUNT(DISTINCT ci.ID) AS unique_customer_count,
    COUNT(DISTINCT CASE WHEN si.ID IS NOT NULL THEN ci.ID END) AS buyer_count,
    COUNT(si.ID) AS invoice_count,
    COALESCE(SUM(ia.amount), 0) AS total_sales_amount,
    COUNT(DISTINCT addr.CITY) AS city_count_with_customers,
    COUNT(DISTINCT CASE WHEN si.ID IS NOT NULL THEN addr.CITY END) AS city_count_with_sales
FROM crm_info ci
INNER JOIN profile_user_address addr ON addr.USER_ID = ci.ID AND addr.TYPE = ]] .. CONFIG.ADDRESS_TYPE_PRIMARY .. [[

LEFT JOIN profile_user_info ui ON ui.ID = ci.ID
LEFT JOIN pa_client pc ON pc.REFFERE_ID = ci.ID
LEFT JOIN sales_invoice si
       ON si.CLIENT_ID = pc.ID AND si.DELETED = 0 AND si.CANCELED = 0 AND si.PRE_INVOICE = 0
      AND si.RUN_DATE >= ? AND si.RUN_DATE < ?]] .. channel_extra .. [[

]] .. INVOICE_AMOUNT_JOIN .. [[
WHERE addr.STATE IS NOT NULL AND addr.STATE <> ''
]] .. extra .. [[

GROUP BY addr.STATE
ORDER BY total_sales_amount DESC
]], params)
    if rows == nil then return nil, err end
    local list = {}
    for _, r in ipairs(rows) do
        table.insert(list, {
            state_name = r[1],
            unique_customer_count = tonumber(r[2]) or 0,
            buyer_count = tonumber(r[3]) or 0,
            invoice_count = tonumber(r[4]) or 0,
            total_sales_amount = tonumber(r[5]) or 0,
            city_count_with_customers = tonumber(r[6]) or 0,
            city_count_with_sales = tonumber(r[7]) or 0,
        })
    end
    return list
end

local function fetch_city_aggregation(date_from_key, date_to_key, filters)
    local extra, extra_params = build_sales_filter_clause(filters)
    local channel_extra, channel_params = build_channel_clause(filters)
    local params = { date_from_key, date_to_key }
    for _, p in ipairs(channel_params) do table.insert(params, p) end
    for _, p in ipairs(extra_params) do table.insert(params, p) end

    local rows, err = fetch_rows([[
SELECT
    addr.STATE AS state_name,
    addr.CITY  AS city_name,
    COUNT(DISTINCT ci.ID) AS unique_customer_count,
    COUNT(DISTINCT CASE WHEN si.ID IS NOT NULL THEN ci.ID END) AS buyer_count,
    COUNT(si.ID) AS invoice_count,
    COALESCE(SUM(ia.amount), 0) AS total_sales_amount
FROM crm_info ci
INNER JOIN profile_user_address addr ON addr.USER_ID = ci.ID AND addr.TYPE = ]] .. CONFIG.ADDRESS_TYPE_PRIMARY .. [[

LEFT JOIN profile_user_info ui ON ui.ID = ci.ID
LEFT JOIN pa_client pc ON pc.REFFERE_ID = ci.ID
LEFT JOIN sales_invoice si
       ON si.CLIENT_ID = pc.ID AND si.DELETED = 0 AND si.CANCELED = 0 AND si.PRE_INVOICE = 0
      AND si.RUN_DATE >= ? AND si.RUN_DATE < ?]] .. channel_extra .. [[

]] .. INVOICE_AMOUNT_JOIN .. [[
WHERE addr.STATE IS NOT NULL AND addr.STATE <> '' AND addr.CITY IS NOT NULL AND addr.CITY <> ''
]] .. extra .. [[

GROUP BY addr.STATE, addr.CITY
ORDER BY total_sales_amount DESC
]], params)
    if rows == nil then return nil, err end
    local list = {}
    for _, r in ipairs(rows) do
        table.insert(list, {
            state_name = r[1],
            city_name = r[2],
            unique_customer_count = tonumber(r[3]) or 0,
            buyer_count = tonumber(r[4]) or 0,
            invoice_count = tonumber(r[5]) or 0,
            total_sales_amount = tonumber(r[6]) or 0,
        })
    end
    return list
end

-- ============================================================
-- DRILL-DOWN QUERIES (Lazy — فقط هنگام کلیک صدا زده می‌شوند)
-- ============================================================

local function fetch_customers_count(state, city, filters)
    local extra = ""
    local params = { state, city }
    if filters.user_type ~= nil then
        extra = " AND ui.USER_TYPE = ?"
        table.insert(params, filters.user_type)
    end
    local rows, err = fetch_rows([[
SELECT COUNT(DISTINCT ci.ID)
FROM crm_info ci
INNER JOIN profile_user_address addr ON addr.USER_ID = ci.ID AND addr.TYPE = ]] .. CONFIG.ADDRESS_TYPE_PRIMARY .. [[

LEFT JOIN profile_user_info ui ON ui.ID = ci.ID
WHERE addr.STATE = ? AND addr.CITY = ?]] .. extra .. [[
]], params)
    if rows == nil or #rows == 0 then return 0, err end
    return tonumber(rows[1][1]) or 0
end

-- توجه (طبق درخواست کاربر): مبلغ/تعداد فاکتور هر مشتری اینجا باید با همان بازهٔ تاریخ فعال Dashboard
-- (پیش‌فرض سال مالی جاری، مشابه محاسبهٔ Monetary در بات ۶۰۰) محاسبه شود، نه کل تاریخچه.
local function fetch_customers(state, city, filters, date_from_key, date_to_key, limit, offset)
    local extra = ""
    local channel_extra, channel_params = build_channel_clause(filters)
    local params = { date_from_key, date_to_key }
    for _, p in ipairs(channel_params) do table.insert(params, p) end
    table.insert(params, state)
    table.insert(params, city)
    if filters.user_type ~= nil then
        extra = " AND ui.USER_TYPE = ?"
        table.insert(params, filters.user_type)
    end
    table.insert(params, limit)
    table.insert(params, offset)

    local rows, err = fetch_rows([[
SELECT
    x.crm_id, x.customer_name, x.state_name, x.city_name, x.user_type,
    x.invoice_count, x.total_purchase_amount, rd.JNDATE AS last_purchase_jdate
FROM (
    SELECT
        ci.ID AS crm_id,
        pm.FULLNAME AS customer_name,
        addr.STATE AS state_name,
        addr.CITY AS city_name,
        ui.USER_TYPE AS user_type,
        COUNT(si.ID) AS invoice_count,
        COALESCE(SUM(ia.amount), 0) AS total_purchase_amount,
        MAX(si.RUN_DATE - MOD(si.RUN_DATE, ]] .. CONFIG.DAY_TICKS .. [[)) AS last_purchase_day_key
    FROM crm_info ci
    INNER JOIN profile_main pm ON pm.ID = ci.ID
    INNER JOIN profile_user_address addr ON addr.USER_ID = ci.ID AND addr.TYPE = ]] .. CONFIG.ADDRESS_TYPE_PRIMARY .. [[

    LEFT JOIN profile_user_info ui ON ui.ID = ci.ID
    LEFT JOIN pa_client pc ON pc.REFFERE_ID = ci.ID
    LEFT JOIN sales_invoice si
           ON si.CLIENT_ID = pc.ID AND si.DELETED = 0 AND si.CANCELED = 0 AND si.PRE_INVOICE = 0
          AND si.RUN_DATE >= ? AND si.RUN_DATE < ?]] .. channel_extra .. [[

    ]] .. INVOICE_AMOUNT_JOIN .. [[
    WHERE addr.STATE = ? AND addr.CITY = ?]] .. extra .. [[

    GROUP BY ci.ID, pm.FULLNAME, addr.STATE, addr.CITY, ui.USER_TYPE
) x
LEFT JOIN report_dimdate rd ON rd.DATEKEY = x.last_purchase_day_key
ORDER BY x.total_purchase_amount DESC
LIMIT ? OFFSET ?
]], params)
    if rows == nil then return nil, err end
    local list = {}
    for _, r in ipairs(rows) do
        table.insert(list, {
            crm_id = r[1],
            customer_name = r[2],
            state_name = r[3],
            city_name = r[4],
            user_type = r[5],
            invoice_count = tonumber(r[6]) or 0,
            total_purchase_amount = tonumber(r[7]) or 0,
            last_purchase_jdate = r[8],
        })
    end
    return list
end

-- توجه: همان بازهٔ تاریخ فعال (fetch_customers) اینجا هم اعمال می‌شود تا جمع این فهرست دقیقاً با
-- «مبلغ کل خرید» نمایش‌داده‌شده در ردیف مشتری (که با همین فیلتر محاسبه شده) یکی باشد.
local function fetch_invoices(crm_id, date_from_key, date_to_key, filters)
    local channel_extra, channel_params = build_channel_clause(filters or {})
    local params = { crm_id, date_from_key, date_to_key }
    for _, p in ipairs(channel_params) do table.insert(params, p) end
    local rows, err = fetch_rows([[
SELECT
    si.ID AS invoice_id,
    si.INVOICE_CODE AS invoice_code,
    rd.JNDATE AS run_jdate,
    COALESCE(ia.amount, 0) AS invoice_amount
FROM sales_invoice si
INNER JOIN pa_client pc ON pc.ID = si.CLIENT_ID
LEFT JOIN report_dimdate rd ON rd.DATEKEY = (si.RUN_DATE - MOD(si.RUN_DATE, ]] .. CONFIG.DAY_TICKS .. [[))
]] .. INVOICE_AMOUNT_JOIN .. [[
WHERE pc.REFFERE_ID = ?
  AND si.DELETED = 0 AND si.CANCELED = 0 AND si.PRE_INVOICE = 0
  AND si.RUN_DATE >= ? AND si.RUN_DATE < ?]] .. channel_extra .. [[

ORDER BY si.RUN_DATE DESC
]], params)
    if rows == nil then return nil, err end
    local list = {}
    for _, r in ipairs(rows) do
        table.insert(list, {
            invoice_id = r[1],
            invoice_code = r[2],
            run_jdate = r[3],
            invoice_amount = tonumber(r[4]) or 0,
        })
    end
    return list
end

local function fetch_customer_header(crm_id)
    local rows, err = fetch_rows([[
SELECT pm.FULLNAME, addr.STATE, addr.CITY
FROM crm_info ci
INNER JOIN profile_main pm ON pm.ID = ci.ID
LEFT JOIN profile_user_address addr ON addr.USER_ID = ci.ID AND addr.TYPE = ]] .. CONFIG.ADDRESS_TYPE_PRIMARY .. [[

WHERE ci.ID = ?
LIMIT 1
]], { crm_id })
    if rows == nil or #rows == 0 then return nil, err end
    return { customer_name = rows[1][1], state_name = rows[1][2], city_name = rows[1][3] }
end

-- ------------- Drill-down کارت‌های کیفیت داده (Lazy — طبق درخواست کاربر v02) -------------

local function fetch_customers_missing_geo_count(field)
    local col = (field == "city") and "addr.CITY" or "addr.STATE"
    local rows, err = fetch_rows([[
SELECT COUNT(DISTINCT ci.ID)
FROM crm_info ci
LEFT JOIN profile_user_address addr ON addr.USER_ID = ci.ID AND addr.TYPE = ]] .. CONFIG.ADDRESS_TYPE_PRIMARY .. [[

WHERE addr.USER_ID IS NULL OR ]] .. col .. [[ IS NULL OR ]] .. col .. [[ = ''
]], {})
    if rows == nil or #rows == 0 then return 0, err end
    return tonumber(rows[1][1]) or 0
end

local function fetch_customers_missing_geo(field, limit, offset)
    local col = (field == "city") and "addr.CITY" or "addr.STATE"
    local rows, err = fetch_rows([[
SELECT ci.ID, pm.FULLNAME, addr.STATE, addr.CITY
FROM crm_info ci
INNER JOIN profile_main pm ON pm.ID = ci.ID
LEFT JOIN profile_user_address addr ON addr.USER_ID = ci.ID AND addr.TYPE = ]] .. CONFIG.ADDRESS_TYPE_PRIMARY .. [[

WHERE addr.USER_ID IS NULL OR ]] .. col .. [[ IS NULL OR ]] .. col .. [[ = ''
ORDER BY ci.ID DESC
LIMIT ? OFFSET ?
]], { limit, offset })
    if rows == nil then return nil, err end
    local list = {}
    for _, r in ipairs(rows) do
        table.insert(list, {
            crm_id = r[1], customer_name = r[2],
            state_name = safe_str(r[3], nil), city_name = safe_str(r[4], nil),
        })
    end
    return list
end

-- توجه: با همان بازهٔ تاریخ فعال فیلتر می‌شود تا مجموع این فهرست دقیقاً با KPI «فاکتورهای بدون
-- نگاشت جغرافیایی» (که خودش با همین date_from_key محاسبه می‌شود) یکی باشد.
local function fetch_invoices_missing_geo_count(date_from_key, date_to_key, filters)
    local channel_extra, channel_params = build_channel_clause(filters or {})
    local params = { date_from_key, date_to_key }
    for _, p in ipairs(channel_params) do table.insert(params, p) end
    local rows, err = fetch_rows([[
SELECT COUNT(si.ID)
FROM sales_invoice si
INNER JOIN pa_client pc ON pc.ID = si.CLIENT_ID
LEFT JOIN profile_user_address addr ON addr.USER_ID = pc.REFFERE_ID AND addr.TYPE = ]] .. CONFIG.ADDRESS_TYPE_PRIMARY .. [[

WHERE si.DELETED = 0 AND si.CANCELED = 0 AND si.PRE_INVOICE = 0
  AND si.RUN_DATE >= ? AND si.RUN_DATE < ?]] .. channel_extra .. [[

  AND (addr.USER_ID IS NULL OR addr.STATE IS NULL OR addr.STATE = '' OR addr.CITY IS NULL OR addr.CITY = '')
]], params)
    if rows == nil or #rows == 0 then return 0, err end
    return tonumber(rows[1][1]) or 0
end

local function fetch_invoices_missing_geo(date_from_key, date_to_key, filters, limit, offset)
    local channel_extra, channel_params = build_channel_clause(filters or {})
    local params = { date_from_key, date_to_key }
    for _, p in ipairs(channel_params) do table.insert(params, p) end
    table.insert(params, limit)
    table.insert(params, offset)
    local rows, err = fetch_rows([[
SELECT si.ID, si.INVOICE_CODE, rd.JNDATE, COALESCE(ia.amount, 0), pm.FULLNAME, ci.ID
FROM sales_invoice si
INNER JOIN pa_client pc ON pc.ID = si.CLIENT_ID
INNER JOIN crm_info ci ON ci.ID = pc.REFFERE_ID
INNER JOIN profile_main pm ON pm.ID = ci.ID
LEFT JOIN profile_user_address addr ON addr.USER_ID = pc.REFFERE_ID AND addr.TYPE = ]] .. CONFIG.ADDRESS_TYPE_PRIMARY .. [[

LEFT JOIN report_dimdate rd ON rd.DATEKEY = (si.RUN_DATE - MOD(si.RUN_DATE, ]] .. CONFIG.DAY_TICKS .. [[))
]] .. INVOICE_AMOUNT_JOIN .. [[
WHERE si.DELETED = 0 AND si.CANCELED = 0 AND si.PRE_INVOICE = 0
  AND si.RUN_DATE >= ? AND si.RUN_DATE < ?]] .. channel_extra .. [[

  AND (addr.USER_ID IS NULL OR addr.STATE IS NULL OR addr.STATE = '' OR addr.CITY IS NULL OR addr.CITY = '')
ORDER BY si.RUN_DATE DESC
LIMIT ? OFFSET ?
]], params)
    if rows == nil then return nil, err end
    local list = {}
    for _, r in ipairs(rows) do
        table.insert(list, {
            invoice_id = r[1], invoice_code = r[2], run_jdate = r[3],
            invoice_amount = tonumber(r[4]) or 0, customer_name = r[5], crm_id = r[6],
        })
    end
    return list
end

-- ============================================================
-- COMPUTE (سمت Lua — روی نتایج تجمیع‌شدهٔ کوچک، بدون Query اضافه)
-- ============================================================

local function enrich_state_list(states, sales_kpi)
    local total_sales = (sales_kpi and sales_kpi.total_sales_amount) or 0
    local total_customers = 0
    for _, s in ipairs(states) do total_customers = total_customers + s.unique_customer_count end

    for _, s in ipairs(states) do
        s.avg_invoice_amount = (s.invoice_count > 0) and (s.total_sales_amount / s.invoice_count) or 0
        s.avg_sales_per_buyer = (s.buyer_count > 0) and (s.total_sales_amount / s.buyer_count) or 0
        s.sales_share_pct = fmt_pct(s.total_sales_amount, total_sales)
        s.customer_share_pct = fmt_pct(s.unique_customer_count, total_customers)
    end
    return states
end

local function enrich_city_list(cities, state_totals_by_name)
    for _, c in ipairs(cities) do
        c.avg_invoice_amount = (c.invoice_count > 0) and (c.total_sales_amount / c.invoice_count) or 0
        local state_total = (state_totals_by_name[c.state_name] and state_totals_by_name[c.state_name].total_sales_amount) or 0
        c.sales_share_pct = fmt_pct(c.total_sales_amount, state_total)
    end
    return cities
end

local function compute_minmax(states)
    local with_sales = {}
    local without_sales_count = 0
    for _, s in ipairs(states) do
        if s.total_sales_amount > 0 then table.insert(with_sales, s) else without_sales_count = without_sales_count + 1 end
    end
    if #states == 0 then return nil end

    local function pick(list, key, want_max)
        if #list == 0 then return nil end
        local best = list[1]
        for _, s in ipairs(list) do
            if want_max then
                if s[key] > best[key] then best = s end
            else
                if s[key] < best[key] then best = s end
            end
        end
        return best
    end

    return {
        max_sales = pick(states, "total_sales_amount", true),
        min_sales = pick(with_sales, "total_sales_amount", false),
        max_invoices = pick(states, "invoice_count", true),
        min_invoices = pick(with_sales, "invoice_count", false),
        max_buyers = pick(states, "buyer_count", true),
        min_buyers = pick(with_sales, "buyer_count", false),
        states_without_sales_count = without_sales_count,
    }
end

local function build_pie_slices(states)
    local total = 0
    for _, s in ipairs(states) do total = total + s.total_sales_amount end
    local slices = {}
    local other_total = 0
    for _, s in ipairs(states) do
        local pct = fmt_pct(s.total_sales_amount, total)
        if pct >= CONFIG.OTHER_SLICE_THRESHOLD_PCT then
            table.insert(slices, { name = s.state_name, value = s.total_sales_amount, pct = pct })
        else
            other_total = other_total + s.total_sales_amount
        end
    end
    if other_total > 0 then
        table.insert(slices, { name = "سایر", value = other_total, pct = fmt_pct(other_total, total) })
    end
    return slices
end

-- ============================================================
-- CSS
-- ============================================================

local REPORT_CSS = [[
<style>
@font-face {
    font-family: "PeydaReport";
    src: url(data:font/truetype;charset=utf-8;base64,AAEAAAAOAIAAAwBgRFNJRwAAAAEAASFUAAAACEdERUYrBC3XAADcNAAAAHxHUE9TKUGIwAAA3LAAADTIR1NVQk+rAWsAARF4AAAP2k9TLzJ2gVbcAAABaAAAAGBjbWFwh/GYyAAADSAAAAeaZ2x5ZmvrPHUAABpsAACfzmhlYWQnUViOAAAA7AAAADZoaGVhCDcSFgAAASQAAAAkaG10eD9fZe0AAAHIAAALWGxvY2EviwdzAAAUvAAABa5tYXhwA1MBBAAAAUgAAAAgbmFtZXvHsAoAALo8AAAFPnBvc3RoWZoTAAC/fAAAHLcAAQAAAAMAAGLmoqxfDzz1AAMD6AAAAADflRqKAAAAAOO0+jP/S/3XBaMFFgAAAAcAAgAAAAAAAAABAAADRv5wAAASx/9L/ggFowABAAAAAAAAAAAAAAAAAAAC1gABAAAC1gBhAAcAgQAGAAEAAgAeAAYAAABkAAAAAwADAAQCZAGQAAUACAKKAlgAAABLAooCWAAAAV4AMgEsAAAAAAAAAAAAAAAAAAAgAQAAAAAAAAAIAAAAAEtIRE0AwAAN/vwD6P4MAAAEsAH0AAAAQAAAAAABaQK/AAAAIAAEAiwASwJYAAACWAAAAIMAAAJnABgCaABTAh4AOgKCAFMCLgBUAgwAVAJgADYCogBTAP4AUwE3ABMCVwBTAc8AUwNJAFMCjQBTAqgANQJTAFMCqAA1AosAUwIuADACJAAPApYATgJnABgDkwAdAjQAEwI1ABMCFQAoAdkAJwIYAEkBsAAwAhgALwIHAC8BdwAeAe0AMAIpAEkA6gBJANkAAQINAEkA6wBKA08ASQIpAEkCFAAwAhgASAIYADABcgBJAbkALgFvAB4CKQBAAeQAGAK0ABgB0QAYAcsAGAHFACgCOgApAaIAMwI6AEMCLAA1AjoAKAI1AEECNwAxAhsASgIxACwCNwAxARAAWAEKAEEBEQBYAREAQwG+AEkCVgBJAh4ANAIYACgByQAYAZUASAHtACgCRQBJAe4AKADYADsB2wAxANwAQwGNAEMC9ABhBAkASQJEAEkCqwAlAukAQwFZAEYBWQAyAcEAVwEWAF8BxABUAVsASAGXADEBWwAvAREALAD4ACgB7AArAecAKwDZAEIB1wAoAaUAhAI+AEkChgBJBHoASQKQAEYCogBGAqIARgJbAEkB8ABJAigASQKdAEYCQABJAlcASQI1AEkB8gBJARYAXwLuAE0A8ABNAPAARAH6AEoBuABGAdAASgKQAEYCGgBiAiwARgIuAEYCtwBmAacATAGnADgAAP94AAD/eAJnABgCZwAYAmcAGAJnABgCZwAYAmcAGAJnABgCZwAYAmcAGAN/ABgCHgA6Ah4AOgIeADoCHgA6AtQAUgKCAFMC1ABSAi4AVAIuAFQCLgBUAi4AVAIuAFQCLgBUAi4AVAIuAFQCdAAsAmAANgJgADYCYAA2Ap4ANQD+AFMA/v/ZAP4AGwD+AFMA/v+9AP7/8QD+//ICVwBTAc8AUwHP/9cBzwBTAd0ADAKNAFMCjQBTAo0AUwJ6AFMCjQBTAqgANQKoADUCqAA1AqgANQKoADUCqAA1AqcANQKoADUD+gA1AlgAUwKLAFMCiwBTAosAUwIuADACLgAwAi4AMAIuADACZABKAlAAJQIkAA8CJAAPAiQADwKWAE4ClgBOApYATgKWAE4ClgBOApYATgKWAE4ClgBOA5MAHQOTAB0DkwAdA5MAHQI1ABMCNQATAjUAEwI1ABMCFQAoAhUAKAIVACgB2QAnAdkAJwHZACcB2QAnAdkAJwHZACcB2QAnAdkAJwHZACcDHgAnAbAAMAGwADABsAAwAbAAMAI9ADECGAAvAhgALwIMAC8CBwAvAgwALwH7AC8CBwAvAfsALwIHAC8CBwAvAgcAKgHtADAB7QAwAe0AMAIpACMA6gBJAPsASQEB/9AA+gAVAOgARwDpAAAA5//mAOr/6AINAEkA6wBKAOv/ywDrADUA6//tAikASQIpAEkCKQBJAisASQIpAEkCFAAwAhQAMAIUADACFAAwAhQAMAIUADACFAAwAhQAMANoADACGABIAXIASQFyAA4BcgA7AbkALgG5AC4BuQAuAbkALgJoAEgBbwAeAW//8QFvAB4BbwAeAikAQAIpAEACKQBAAikAQAIpAEACKQBAAikAQAIpAEACtAAYArQAGAK0ABgCtAAYAcsAGAHLABgBywAYAcUAKAHFACgBxQAoAdgAQQDRAEcBCABIAM3/5QEO/+4A3P/wAQsAAAD//+8BKf/vAUH/1QE3/8kDUgBHA3oARwFe//IBM//yAUv/8gGT//IB3f/yA1IARwN6AEcBXv/yATP/8gGT//IDUgBHA3oARwFe//IBS//yAZP/8gHd//IDUgBHA3oARwFe//IBS//yAZP/8gG///IDUgBHA3oARwFe//IBS//yAZP/8gGW//IDUgBHA3oARwFe//IBM//yApsASAKzAEgCrf/yAp3/8gKhAEgCsQBIAq3/8gKd//ICkgBIArMASAKt//ICmP/yApsASAKzAEgCrf/yAp3/8gIlAEgCRgBIAiUASAJGAEgCJQBIAkYASAFE/9gBAv/eAWf/2AEk/94BRP/YAWf/2AEk/94BAv/eAUT/2AFn/9gBRP/YAWf/2AFE/9gBAv/eAbP/2AEk/94EhQBHBLwASAL5//ICx//yBIUARwS8AEgC+f/yAsf/8gTHAEcE9QBHAzH/8gME//IExwBHBPUARwMx//IDBP/yAt0ASQMLAEkCzP/yAp7/8gLdAEkDCwBJAsz/8gKe//ICMABJAlkASQJS//IB2f/yAjAASQJZAEkCUv/yAdn/8gNTAEkDnwBJAcP/8gHH//IDUwBJA58ASQHD//IBx//yA1MASQOfAEkBw//yAcf/8gK7AEkC3ABJArsASQLcAEkBw//yAcf/8gNSAEkDegBJAgD/8gGH//IDaQBHA2oARwRRAEkD4ABHBIQASQIA//IDJP/yAYf/8gGH//IC8v/yA2kARwNoAEcEUQBJA+AARwSEAEkCAP/yAyT/8QGH//IBg//yAvL/8QK5AEgC8QBIAU3/8gEK//MCugBIAvEASAFN//IBCv/zAo8ARwLkAEcCMP/yAgb/8gK3AEcC5gBHAV7/8gEz//ICtwBHAuYARwHnAEcCBABJAm7/8gKw//IB5wBHAgQASQHnAEcCKwA7AkX/8gEz//IB5wBHAgQASQKw//ICVQBBAuz/8gKw//IB5wBHAgQASQHnAEcCKwA7AeAAQQHtAEEB4QBBAewAQQHhAEEB7ABBAeEAQQHsAEEC1wBHAuEARwLXAEcC4QBHApgARwFe//IBS//yAZP/8gHT//IC2AAuAuIARwKYAEcBXv/yATP/8gGT//IC2AA8AtcARwLhAEcCmABHAV7/8gFL//IBk//yAdD/8gJsAEcCmABHArgARwLnAEcAwQAAAhAAMQJGADECEAAWAkYAFwIQADACRgAxAiIAAAJV//wCEP/ZA4kARwPRAEcDjwBHA48ARwOTAC4DjwBHAkb/2gPRAEcD0QBHA+QAUAPRAEcDjwBH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AQ0BDgEUAQ8AdAETASYBIwEkASUBLwEWATEAigDiAIYA3gCLAOMAjwDnAJIA6gCQAOgAlADsAJUA7QCcAPQAmgDyAJ0A9QCXAO8AnwD3AKEA+QCgAPgAogD6AKgBAQCpAQIApgD7AKoBAwCrAQQArQEGAKwBBQCuAQcArwEIALEBCgCwAQkAswEMALkBEgC4AREAvAEVAL4BFwDAARkAvwEYAMEBGgDDARwAwgEbAMgBIQDHASAAxgEfAM8BKADRASoAzgEnANABKQDTASwA1wEwANgA2gEyANwBNADbATMAxAEdAMkBIgLEAsUCxwLLAswCyQLDAsICygLGAsgBNQE8ATgB+gE6AgkBNgFHAfQBUgFYAWIBagFuAXIBdAF4AXwBiAGMAZABlAGYAZwBoAGkAhsBqAG2AboB0gHaAd4B5AH4AgACAgKtAq4CrwKwArECsgKzArsCvAKrAqwCqgKXAmQCZQKRAUABtAKpAT4B6AHqAe4B9gH8Af4A1QEuANIBKwDUAS0ChAKCAoUCgwKLAoYCiQKKAocCjAKBAoACfgJ/AGAAYQBkAGIAYwBlAH4AfwBmAUwBTQFPAU4BXgFfAWEBYAGtAa8BrgFmAWcBaQFoAXYBdwGEAYYBgAGBAb4BwQHFAcMByAHLAc8BzQHoAekB6gHrAe0B7AHxAfMB8gIXAhACEQIUAhMCOAI6AkACQgJIAkoCUQJTAjkCOwJBAkMCSQJLAlICVAE1ATwBPQE4ATkB+gH7AToBOwIJAgoCDQIMATYBNwFHAUgBSgFJAfQB9QFSAVMBVQFUAVgBWQFbAVoBYgFjAWUBZAFqAWsBbQFsAW4BbwFxAXABcgFzAXQBdQF4AXoBfAF9AYgBiQGLAYoBjAGNAY8BjgGQAZEBkwGSAZQBlQGXAZYBmAGZAZsBmgGcAZ0BnwGeAaABoQGjAaIBpAGlAacBpgGoAakBqwGqAbYBtwG5AbgBugG7Ab0BvAHSAdMB1QHUAdoB2wHdAdwB3gHfAeEB4AHkAeUB5wHmAfgB+QIAAgECAgIDAgYCBQIiAiMCHgIfAiACIQIcAh0AAAAAAEIAQgBCAEIAXACNALgA2gDyAQcBOQFRAV0BdAGZAakBxAHbAgMCJAJWAoYCwwLVAvMDBwMkAz8DVANqA6sD2QP8BCoEXQSHBQIFLgVABVkFfAWJBdMGAAYz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AAEACgB2AAMAAQQJAAIADgCAAAMAAQQJAAMAMACOAAMAAQQJAAQAGgC+AAMAAQQJAAUAGgDYAAMAAQQJAAYAGgDyAAMAAQQJAAcAUAEMAAMAAQQJAAgAGAFcAAMAAQQJAAkAGAFcAAMAAQQJAAoAmgF0AAMAAQQJAAsAIAIOAAMAAQQJAAwAQAIuAAMAAQQJAA0AmgF0AAMAAQQJAA4AKgJuAAMAAQQJABAACgB2AAMAAQQJABEADgCAAAMAAQQJAGQByAKYAEMAbwBwAHkAcgBpAGcAaAB0ACAAKABjACkAIAAyADAAMgAxACAAYgB5ACAAdwB3AHcALgBmAG8AbgB0AGkAcgBhAG4ALgBjAG8AbQAgAEEAbABsACAAcgBpAGcAaAB0AHMAIAByAGUAcwBlAHIAdgBlAGQALgBQAGUAeQBkAGEAUgBlAGcAdQBsAGEAcgAzAC4AMAAwADAAOwBLAEgARABNADsAUABlAHkAZABhAC0AUgBlAGcAdQBsAGEAcgBQAGUAeQBkAGEAIABSAGUAZwB1AGwAYQByAFYAZQByAHMAaQBvAG4AIAAzAC4AMAAwADAAUABlAHkAZABhAC0AUgBlAGcAdQBsAGEAcgBQAGUAeQBkAGEAIABpAHMAIABhACAAdAByAGEAZABlAG0AYQByAGsAIABvAGYAIAB3AHcAdwAuAGYAbwBuAHQAaQByAGEAbgAuAGMAbwBtAE4AYQBzAGUAcgAgAEsAaABhAGQAZQBtAFQAbwAgAHUAcwBlACAAdABoAGkAcwAgAGYAbwBuAHQALAAgAGkAdAAgAGkAcwAgAG4AZQBjAGUAcwBzAGEAcgB5ACAAdABvACAAbwBiAHQAYQBpAG4AIAB0AGgAZQAgAGwAaQBjAGUAbgBzAGUAIABmAHIAbwBtACAAdwB3AHcALgBmAG8AbgB0AGkAcgBhAG4ALgBjAG8AbQB3AHcAdwAuAGYAbwBuAHQAaQByAGEAbgAuAGMAbwBtAGgAdAB0AHAAcwA6AC8ALwBkAHIAaQBiAGIAYgBsAGUALgBjAG8AbQAvAG4AYQBzAGUAcgBrAGgAYQBkAGUAbQBmAG8AbgB0AGkAcgBhAG4ALgBjAG8AbQAvAGwAaQBjAGUAbgBzAGUAcwBlAHkASgBwAGQAaQBJADYASQBtAGQAawBNADIATQByAFMARgBNAHYAUQBWAGcAMABPAEgAcABHAGUAaQA4ADMAZQBHADkASABRAGwARQA5AFAAUwBJAHMASQBuAFoAaABiAEgAVgBsAEkAagBvAGkAYQBtADEAVQBXAFcAVgBXAFYAMAA1AHIAWgAxAEIAMQBMADAAcABhAFIAbABZADUAUwBqAGwAQwBUAG0AOQBEAFEAVgBWAHEAUwBUAFoARgBSAG4ATgBIAFUAWABwAGgAYgB6AGgAdABUAEYAbABxAGMAegAwAGkATABDAEoAdABZAFcATQBpAE8AaQBJADAAWgBXAFkAegBNAEQAZABtAFkAMgBaAGwAWQB6AEYAaQBZAFQAaABpAFkAVABZAHcATwBHAEYAbQBZAFQAQQB5AE4ARABVAHkATgBUAFYAagBNAG0AWgBtAE0AagBKAGsATgB6AGcANABZAGoARQA0AFoAagBBADIAWgBXAEYAaABNAGoAawB5AE0ARABFAHkAWQBUAFYAbABNADIAVgBtAE0ARwBRAHoASQBpAHcAaQBkAEcARgBuAEkAagBvAGkASQBuADAAPQAAAAIAAAAAAAD/nAAyAAAAAAAAAAAAAAAAAAAAAAAAAAAC1gAAAAEAAgADACQAJQAmACcAKAApACoAKwAsAC0ALgAvADAAMQAyADMANAA1ADYANwA4ADkAOgA7ADwAPQBEAEUARgBHAEgASQBKAEsATABNAE4ATwBQAFEAUgBTAFQAVQBWAFcAWABZAFoAWwBcAF0AEwAUABUAFgAXABgAGQAaABsAHAARAA8AHQAeABAADgANAEEA2QASAB8AIAAhAAQAIgAKAAUABgAjAAcACAAJAAsADABeAF8AYAA+AD8AQAC2ALcAtAC1AMQAxQCHAEIAsgCzAIwAigCLAL0AhACFAJYA7wCTAPAAuADoAKsAwwCjAKIAgwC8AIgAhgCCAMIAYQC+AL8BAgEDAMkBBADHAGIArQEFAQYAYwCuAJAA/QD/AGQBBwDpAQgBCQBlAQoAyADKAQsAywEMAQ0BDgD4AQ8BEAERAMwAzQDOAPoAzwESARMBFAEVARYBFwDiARgBGQEaAGYBGwDQANEAZwDTARwBHQCRAK8AsADtAR4BHwEgASEA5AD7ASIBIwEkASUBJgEnANQA1QBoANYBKAEpASoBKwEsAS0BLgEvAOsBMAC7ATEBMgDmATMAaQE0AGsAbABqATUBNgBuAG0AoAD+AQAAbwE3AOoBOAEBAHABOQByAHMBOgBxATsBPAE9APkBPgE/AUAA1wB0AHYAdwFBAHUBQgFDAUQBRQFGAUcA4wFIAUkBSgB4AUsAeQB7AHwAegFMAU0AoQB9ALEA7gFOAU8BUAFRAOUA/AFSAIkBUwFUAVUBVgB+AIAAgQB/AVcBWAFZAVoBWwFcAV0BXgDsAV8AugFgAOcBYQFiAWMBZAFlAWYBZwFoAWkBagFrAWwBbQFuAW8BcAFxAXIBcwF0AXUBdgF3AXgBeQF6AXsBfAF9AX4BfwGAAYEBggGDAYQBhQGGAYcBiAGJAYoBiwGMAY0BjgGPAZABkQGSAZMBlAGVAZYBlwGYAZkBmgGbAZwBnQGeAZ8BoAGhAaIBowGkAaUBpgGnAagBqQGqAasBrAGtAa4BrwGwAbEBsgGzAbQBtQG2AbcBuAG5AboBuwG8Ab0BvgG/AcABwQHCAcMBxAHFAcYBxwHIAckBygHLAcwBzQHOAc8B0AHRAdIB0wHUAdUB1gHXAdgB2QHaAdsB3AHdAd4B3wHgAeEB4gHjAeQB5QHmAecB6AHpAeoB6wHsAe0B7gHvAfAB8QHyAfMB9AH1AfYB9wH4AfkB+gH7AfwB/QH+Af8CAAIBAgICAwIEAgUCBgIHAggCCQIKAgsCDAINAg4CDwIQAhECEgITAhQCFQIWAhcCGAIZAhoCGwIcAh0CHgIfAiACIQIiAiMCJAIlAiYCJwIoAikCKgIrAiwCLQIuAi8CMAIxAjICMwI0AjUCNgI3AjgCOQI6AjsCPAI9Aj4CPwJAAkECQgJDAkQCRQJGAkcCSAJJAkoCSwJMAk0CTgJPAlACUQJSAlMCVAJVAlYCVwJYAlkCWgJbAlwCXQJeAl8CYAJhAmICYwJkAmUCZgJnAmgCaQJqAmsCbAJtAm4CbwJwAnECcgJzAnQCdQJ2AncCeAJ5AnoCewJ8An0CfgJ/AoACgQKCAoMChAKFAoYChwKIAokCigKLAowCjQKOAo8CkAKRApICkwKUApUClgKXApgCmQKaApsCnAKdAp4CnwKgAqECogKjAqQCpQKmAqcCqAKpAqoCqwKsAq0CrgKvArACsQKyArMCtAK1ArYCtwK4ArkCugK7ArwCvQK+Ar8CwACpAKoCwQLCAsMCxALFAsYCxwLIAskCygLLAswCzQLOAs8C0ALRAtIC0wLUAtUC1gLXAtgC2QLaAtsC3ALdAt4C3wLgAuEC4gLjAuQC5QLmAucC6ALpAuoC6wLsAu0C7gLvAvAC8QLyAvMC9AL1AvYC9wL4AvkC+gL7AOEC/AL9Av4C/wd1bmkwNjVBB3VuaTA2NUIGQWJyZXZlB0FtYWNyb24HQW9nb25lawpDZG90YWNjZW50BkRjYXJvbgZEY3JvYXQGRWNhcm9uCkVkb3RhY2NlbnQHRW1hY3JvbgdFb2dvbmVrB3VuaTAxOEYHdW5pMDEyMgpHZG90YWNjZW50BEhiYXIHSW1hY3JvbgdJb2dvbmVrB3VuaTAxMzYGTGFjdXRlBkxjYXJvbgd1bmkwMTNCBk5hY3V0ZQZOY2Fyb24HdW5pMDE0NQNFbmcNT2h1bmdhcnVtbGF1dAdPbWFjcm9uBlJhY3V0ZQZSY2Fyb24HdW5pMDE1NgZTYWN1dGUHdW5pMDIxOAd1bmkxRTlFBFRiYXIGVGNhcm9uB3VuaTAxNjIHdW5pMDIxQQ1VaHVuZ2FydW1sYXV0B1VtYWNyb24HVW9nb25lawVVcmluZwZXYWN1dGULV2NpcmN1bWZsZXgJV2RpZXJlc2lzBldncmF2ZQtZY2lyY3VtZmxleAZZZ3JhdmUGWmFjdXRlClpkb3RhY2NlbnQGYWJyZXZlB2FtYWNyb24HYW9nb25lawpjZG90YWNjZW50BmRjYXJvbgZlY2Fyb24KZWRvdGFjY2VudAdlbWFjcm9uB2VvZ29uZWsHdW5pMDI1OQd1bmkwMTIzCmdkb3RhY2NlbnQEaGJhcglpLmxvY2xUUksHaW1hY3Jvbgdpb2dvbmVrB3VuaTAxMzcGbGFjdXRlBmxjYXJvbgd1bmkwMTNDBm5hY3V0ZQZuY2Fyb24HdW5pMDE0NgNlbmcNb2h1bmdhcnVtbGF1dAdvbWFjcm9uBnJhY3V0ZQZyY2Fyb24HdW5pMDE1NwZzYWN1dGUHdW5pMDIxOQR0YmFyBnRjYXJvbgd1bmkwMTYzB3VuaTAyMUINdWh1bmdhcnVtbGF1dAd1bWFjcm9uB3VvZ29uZWsFdXJpbmcGd2FjdXRlC3djaXJjdW1mbGV4CXdkaWVyZXNpcwZ3Z3JhdmULeWNpcmN1bWZsZXgGemFjdXRlCnpkb3RhY2NlbnQHdW5pMDYyMQd1bmkwNjI3DHVuaTA2MjcuZmluYQd1bmkwNjIzDHVuaTA2MjMuZmluYQd1bmkwNjI1DHVuaTA2MjUuZmluYQd1bmkwNjIyDHVuaTA2MjIuZmluYQd1bmkwNjcxDHVuaTA2NzEuZmluYQd1bmkwNjZFDHVuaTA2NkUuZmluYQx1bmkwNjZFLm1lZGkMdW5pMDY2RS5pbml0EHVuaTA2NkUuaW5pdC5hbHQRdW5pMDY2RS5pbml0LmFsdDIRdW5pMDY2RS5pbml0LmFsdDMHdW5pMDYyOAx1bmkwNjI4LmZpbmEMdW5pMDYyOC5tZWRpDHVuaTA2MjguaW5pdBB1bmkwNjI4LmluaXQuYWx0B3VuaTA2N0UMdW5pMDY3RS5maW5hDHVuaTA2N0UubWVkaQx1bmkwNjdFLmluaXQQdW5pMDY3RS5pbml0LmFsdBF1bmkwNjdFLmluaXQuYWx0Mgd1bmkwNjJBDHVuaTA2MkEuZmluYQx1bmkwNjJBLm1lZGkMdW5pMDYyQS5pbml0EHVuaTA2MkEuaW5pdC5hbHQRdW5pMDYyQS5pbml0LmFsdDIHdW5pMDYyQgx1bmkwNjJCLmZpbmEMdW5pMDYyQi5tZWRpDHVuaTA2MkIuaW5pdBB1bmkwNjJCLmluaXQuYWx0EXVuaTA2MkIuaW5pdC5hbHQyB3VuaTA2NzkMdW5pMDY3OS5maW5hDHVuaTA2NzkubWVkaQx1bmkwNjc5LmluaXQHdW5pMDYyQwx1bmkwNjJDLmZpbmEMdW5pMDYyQy5tZWRpDHVuaTA2MkMuaW5pdAd1bmkwNjg2DHVuaTA2ODYuZmluYQx1bmkwNjg2Lm1lZGkMdW5pMDY4Ni5pbml0B3VuaTA2MkQMdW5pMDYyRC5maW5hDHVuaTA2MkQubWVkaQx1bmkwNjJELmluaXQHdW5pMDYyRQx1bmkwNjJFLmZpbmEMdW5pMDYyRS5tZWRpDHVuaTA2MkUuaW5pdAd1bmkwNjJGDHVuaTA2MkYuZmluYQd1bmkwNjMwDHVuaTA2MzAuZmluYQd1bmkwNjg4DHVuaTA2ODguZmluYQd1bmkwNjMxC3VuaTA2MzEuYWx0DHVuaTA2MzEuZmluYRB1bmkwNjMxLmZpbmEuYWx0B3VuaTA2MzIMdW5pMDYzMi5maW5hEHVuaTA2MzIuZmluYS5hbHQLdW5pMDYzMi5hbHQHdW5pMDY5MQx1bmkwNjkxLmZpbmEHdW5pMDY5NQx1bmkwNjk1LmZpbmEHdW5pMDY5OAt1bmkwNjk4LmFsdAx1bmkwNjk4LmZpbmEQdW5pMDY5OC5maW5hLmFsdAd1bmkwNjMzDHVuaTA2MzMuZmluYQx1bmkwNjMzLm1lZGkMdW5pMDYzMy5pbml0B3VuaTA2MzQMdW5pMDYzNC5maW5hDHVuaTA2MzQubWVkaQx1bmkwNjM0LmluaXQHdW5pMDYzNQx1bmkwNjM1LmZpbmEMdW5pMDYzNS5tZWRpDHVuaTA2MzUuaW5pdAd1bmkwNjM2DHVuaTA2MzYuZmluYQx1bmkwNjM2Lm1lZGkMdW5pMDYzNi5pbml0B3VuaTA2MzcMdW5pMDYzNy5maW5hDHVuaTA2MzcubWVkaQx1bmkwNjM3LmluaXQHdW5pMDYzOAx1bmkwNjM4LmZpbmEMdW5pMDYzOC5tZWRpDHVuaTA2MzguaW5pdAd1bmkwNjM5DHVuaTA2MzkuZmluYQx1bmkwNjM5Lm1lZGkMdW5pMDYzOS5pbml0B3VuaTA2M0EMdW5pMDYzQS5maW5hDHVuaTA2M0EubWVkaQx1bmkwNjNBLmluaXQHdW5pMDY0MQx1bmkwNjQxLmZpbmEMdW5pMDY0MS5tZWRpDHVuaTA2NDEuaW5pdAd1bmkwNkE0DHVuaTA2QTQuZmluYQx1bmkwNkE0Lm1lZGkMdW5pMDZBNC5pbml0B3VuaTA2QTEMdW5pMDZBMS5maW5hDHVuaTA2QTEubWVkaQx1bmkwNkExLmluaXQHdW5pMDY2Rgx1bmkwNjZGLmZpbmEHdW5pMDY0Mgx1bmkwNjQyLmZpbmEMdW5pMDY0Mi5tZWRpDHVuaTA2NDIuaW5pdAd1bmkwNjQzDHVuaTA2NDMuZmluYQx1bmkwNjQzLm1lZGkMdW5pMDY0My5pbml0B3VuaTA2QTkLdW5pMDZBOS5hbHQMdW5pMDZBOS5zczAxDHVuaTA2QTkuZmluYRF1bmkwNkE5LmZpbmEuc3MwMQx1bmkwNkE5Lm1lZGkRdW5pMDZBOS5tZWRpLnNzMDEMdW5pMDZBOS5pbml0EHVuaTA2QTkuaW5pdC5hbHQRdW5pMDZBOS5pbml0LnNzMDEHdW5pMDZBRgt1bmkwNkFGLmFsdAx1bmkwNkFGLnNzMDEMdW5pMDZBRi5maW5hEXVuaTA2QUYuZmluYS5zczAxDHVuaTA2QUYubWVkaRF1bmkwNkFGLm1lZGkuc3MwMQx1bmkwNkFGLmluaXQQdW5pMDZBRi5pbml0LmFsdBF1bmkwNkFGLmluaXQuc3MwMQd1bmkwNjQ0DHVuaTA2NDQuZmluYQx1bmkwNjQ0Lm1lZGkMdW5pMDY0NC5pbml0B3VuaTA2QjUMdW5pMDZCNS5maW5hDHVuaTA2QjUubWVkaQx1bmkwNkI1LmluaXQHdW5pMDY0NQx1bmkwNjQ1LmZpbmEMdW5pMDY0NS5tZWRpDHVuaTA2NDUuaW5pdAd1bmkwNjQ2DHVuaTA2NDYuZmluYQx1bmkwNjQ2Lm1lZGkMdW5pMDY0Ni5pbml0B3VuaTA2QkEMdW5pMDZCQS5maW5hB3VuaTA2NDcMdW5pMDY0Ny5maW5hDHVuaTA2NDcubWVkaQx1bmkwNjQ3LmluaXQHdW5pMDZDMAx1bmkwNkMwLmZpbmEHdW5pMDZDMQx1bmkwNkMxLmZpbmEMdW5pMDZDMS5tZWRpDHVuaTA2QzEuaW5pdAd1bmkwNkMyDHVuaTA2QzIuZmluYQd1bmkwNkJFDHVuaTA2QkUuZmluYQx1bmkwNkJFLm1lZGkMdW5pMDZCRS5pbml0B3VuaTA2MjkMdW5pMDYyOS5maW5hB3VuaTA2QzMMdW5pMDZDMy5maW5hB3VuaTA2NDgMdW5pMDY0OC5maW5hB3VuaTA2MjQMdW5pMDYyNC5maW5hB3VuaTA2QzYMdW5pMDZDNi5maW5hB3VuaTA2QzcMdW5pMDZDNy5maW5hB3VuaTA2NDkMdW5pMDY0OS5maW5hB3VuaTA2NEEMdW5pMDY0QS5maW5hEXVuaTA2NEEuZmluYS5zczAxDHVuaTA2NEEubWVkaQx1bmkwNjRBLmluaXQQdW5pMDY0QS5pbml0LmFsdBF1bmkwNjRBLmluaXQuYWx0Mgd1bmkwNjI2DHVuaTA2MjYuZmluYRF1bmkwNjI2LmZpbmEuc3MwMQx1bmkwNjI2Lm1lZGkMdW5pMDYyNi5pbml0EHVuaTA2MjYuaW5pdC5hbHQHdW5pMDZDRQd1bmkwNkNDDHVuaTA2Q0MuZmluYRF1bmkwNkNDLmZpbmEuc3MwMQx1bmkwNkNDLm1lZGkMdW5pMDZDQy5pbml0EHVuaTA2Q0MuaW5pdC5hbHQRdW5pMDZDQy5pbml0LmFsdDIHdW5pMDZEMgx1bmkwNkQyLmZpbmEHdW5pMDc2OQx1bmkwNzY5LmZpbmEHdW5pMDY0MAt1bmkwNjQ0MDYyNxB1bmkwNjQ0MDYyNy5maW5hC3VuaTA2NDQwNjIzEHVuaTA2NDQwNjIzLmZpbmELdW5pMDY0NDA2MjUQdW5pMDY0NDA2MjUuZmluYQt1bmkwNjQ0MDYyMhB1bmkwNjQ0MDYyMi5maW5hC3VuaTA2NDQwNjcxEHVuaTA2NkUwNkNDLmZpbmEVdW5pMDY2RTA2Q0MuX2ZpbmEuYWx0EHVuaTA2MjgwNjQ5LmZpbmEQdW5pMDYyODA2NEEuZmluYRB1bmkwNjI4MDYyNi5maW5hEHVuaTA2MjgwNkNDLmZpbmEQdW5pMDY0NDA2NzEuZmluYRB1bmkwNjdFMDY0OS5maW5hEHVuaTA2N0UwNjRBLmZpbmEQdW5pMDY3RTA2MjYuZmluYRB1bmkwNjdFMDZDQy5maW5hEHVuaTA2MkEwNjQ5LmZpbmEQdW5pMDYyQTA2NEEuZmluYRB1bmkwNjJBMDYyNi5maW5hEHVuaTA2MkEwNkNDLmZpbmEQdW5pMDYyQjA2NDkuZmluYRB1bmkwNjJCMDY0QS5maW5hEHVuaTA2MkIwNjI2LmZpbmEQdW5pMDYyQjA2Q0MuZmluYQt1bmkwNjMzMDY0ORB1bmkwNjMzMDY0OS5maW5hC3VuaTA2MzMwNjRBEHVuaTA2MzMwNjRBLmZpbmELdW5pMDYzMzA2MjYQdW5pMDYzMzA2MjYuZmluYQt1bmkwNjMzMDZDQxB1bmkwNjMzMDZDQy5maW5hC3VuaTA2MzQwNjQ5EHVuaTA2MzQwNjQ5LmZpbmELdW5pMDYzNDA2NEEQdW5pMDYzNDA2NEEuZmluYQt1bmkwNjM0MDYyNhB1bmkwNjM0MDYyNi5maW5hC3VuaTA2MzQwNkNDEHVuaTA2MzQwNkNDLmZpbmELdW5pMDYzNTA2NDkQdW5pMDYzNTA2NDkuZmluYQt1bmkwNjM1MDY0QRB1bmkwNjM1MDY0QS5maW5hC3VuaTA2MzUwNjI2EHVuaTA2MzUwNjI2LmZpbmELdW5pMDYzNTA2Q0MQdW5pMDYzNTA2Q0MuZmluYRp1bmkwNjM2X2ZhcnNpX3VuaTA2Q0MuZmluYQt1bmkwNjM2MDY0ORB1bmkwNjM2MDY0OS5maW5hC3VuaTA2MzYwNjRBEHVuaTA2MzYwNjRBLmZpbmELdW5pMDYzNjA2MjYQdW5pMDYzNjA2MjYuZmluYQt1bmkwNjM2MDZDQxB1bmkwNjQ2MDY0OS5maW5hEHVuaTA2NDYwNjRBLmZpbmEQdW5pMDY0NjA2MjYuZmluYRB1bmkwNjQ2MDZDQy5maW5hEHVuaTA2NEEwNjRBLmZpbmEQdW5pMDY0QTA2Q0MuZmluYRB1bmkwNjI2MDY0OS5maW5hEHVuaTA2MjYwNjRBLmZpbmEQdW5pMDYyNjA2MjYuZmluYRB1bmkwNjI2MDZDQy5maW5hEHVuaTA2Q0MwNkNDLmZpbmEHdW5pRkRGMgd1bmkwNjZCB3VuaTA2NkMHdW5pMDY2MAd1bmkwNjYxB3VuaTA2NjIHdW5pMDY2Mwd1bmkwNjY0B3VuaTA2NjUHdW5pMDY2Ngd1bmkwNjY3B3VuaTA2NjgHdW5pMDY2OQd1bmkwNkYwB3VuaTA2RjEHdW5pMDZGMgd1bmkwNkYzB3VuaTA2RjQHdW5pMDZGNQd1bmkwNkY2B3VuaTA2RjcHdW5pMDZGOAd1bmkwNkY5DHVuaTA2RjQudXJkdQx1bmkwNkY3LnVyZHUHdW5pMzAwMAd1bmkyMDVGB3VuaTIwMEUHdW5pMjAwRgd1bmkyMDBEB3VuaTIwMEMHdW5pMjAwMQd1bmkyMDAzB3VuaTIwMDAHdW5pMjAwMgd1bmkyMDA1B3VuaTIwMEEHdW5pMjAyRgd1bmkyMDA2B3VuaTIwMDkHdW5pMjAwNAd1bmkyMDBCB3VuaTA2RDQHdW5pMDYwQwd1bmkwNjFCB3VuaTA2MUYHdW5pMDY2RAd1bmlGRDNFB3VuaUZEM0YHdW5pRkRGQwd1bmkwNjZBB3VuaTA2MTUKZG90YWJvdmVhcgpkb3RiZWxvd2FyC2RvdGNlbnRlcmFyFnR3b2RvdHN2ZXJ0aWNhbGFib3ZlYXIWdHdvZG90c3ZlcnRpY2FsYmVsb3dhchh0d29kb3RzaG9yaXpvbnRhbGFib3ZlYXIYdHdvZG90c2hvcml6b250YWxiZWxvd2FyFHRocmVlZG90c2Rvd25hYm92ZWFyFHRocmVlZG90c2Rvd25iZWxvd2FyEnRocmVlZG90c3VwYWJvdmVhchJ0aHJlZWRvdHN1cGJlbG93YXIHd2FzbGFhcgttaW5pS2VoZWhhchFnYWZzYXJrYXNoYWJvdmVhchVnYWZzYXJrYXNoYWJvdmVhci5hbHQSZ2Fmc2Fya2FzaGNlbnRlcmFyB3VuaTA2NzAHdW5pMDY1Ngd1bmkwNjU0B3VuaTA2NTUHdW5pMDY0Qgd1bmkwNjRDB3VuaTA2NEQHdW5pMDY0RQd1bmkwNjRGB3VuaTA2NTAHdW5pMDY1MQt1bmkwNjUxMDY0Qgt1bmkwNjUxMDY0Qwt1bmkwNjUxMDY0RAt1bmkwNjUxMDY0RQt1bmkwNjUxMDY0Rgt1bmkwNjUxMDY1MAt1bmkwNjUxMDY3MAd1bmkwNjUyB3VuaTA2NTMIc2FyZXlhYXIRc2V2ZW5zYW1sbC5ib3R0b20Qc2V2ZW5zbWFsbC5hYm92ZQ55ZWhzYW1sLmJvdHRvbQ15ZWhzbWFsLmFib3ZlB3VuaTAzMDgHdW5pMDMwNwlncmF2ZWNvbWIJYWN1dGVjb21iB3VuaTAzMEIHdW5pMDMwMgd1bmkwMzBDB3VuaTAzMDYHdW5pMDMwQQl0aWxkZWNvbWIHdW5pMDMwNAd1bmkwMzEyB3VuaTAzMjYHdW5pMDMyNwd1bmkwMzI4DHVuaTA2Y2UuZmluYQx1bmkwNmNlLmluaXQMdW5pMDZjZS5tZWRpDHVuaTA2ZDUuZmluYQAAAQACAA4AAAAAAAAANgACAAYAgwCEAAMBNQIbAAECHAJjAAICmAK8AAMCwgLQAAMC0gLVAAEAAQACAAAADAAAABgAAQAEAqoCrAKvArIAAQAVAIMAhAKYAqQCpQKpAqsCrQKuArACsQKzArQCtQK2ArcCuAK5AroCuwK8AAEAAAAKAH4AugADREZMVAAUYXJhYgAYbGF0bgAuAFQAAAAKAAFVUkQgAFAAAP//AAMAAAADAAQALgAHQVpFIAA6Q1JUIAA6S0FaIAA6TU9MIAA6Uk9NIAA6VEFUIAA6VFJLIAA6AAD//wADAAEAAgAEAAD//wADAAAAAgAEAAVrZXJuACBrZXJuACBtYXJrACptYXJrACpta21rADQAAAADAAAAAQACAAAAAwADAAQABQAAAAIABgAHAAgAEgXyFvgZmhpOJ3wx9jJsAAIACAACAAoEKgABAEQABAAAAB0C5ALkAIIAggLyAIgAtgEYARgBJgGAAYoB/AIKAnwC1gLWAuQC5ALyAvIDCAMOAxwD6gPwBAYEEAQWAAEAHQBCAEMARABFAEYASABLAFEAUgBYAFkAWgBcAF0AXgBhAGMAZABlAGgAaQB3AHgAeQCBAIICcAJ2AncAAQAZ//MACwAE/9sADf/tABcABQAd//cAIP/wACH/7AAi//AAJP/yACz/8AAu/+wAMP/1ABgABP/WAAb/+gAK//kADf/tABL/+QAU//kAHv/qACD/3wAh/94AIv/fACT/4AAq/+wAK//sACz/3wAt/+wALv/eAC//7AAw/+UAMv/uADP/+QA0//oANv/4ADf/9wBLAAAAAwBL/8AAVP/0AFf/5QAWAAb/9AAK//MAEv/zABT/8wAe//oAIP/uACH/7QAi/+4AI//7ACcACwAq//sAK//7ACz/7gAt//sALv/tAC//+wAw//sAMv/xADP/+wA0//gANv/7AFr/9QACAFz/+gBf//oAHAAE/+8ABv/qAAr/6QAS/+kAFP/pABb/9wAe/+cAIP/hACH/4QAi/+EAI//3ACcACgAq/+wAK//sACz/4QAt/+wALv/hAC//7AAw/+4AMf/xADL/5AAz/+gANP/mADX/8wA2/+kAN//yAFj/+gBa/+4AAwBZ//UAXP/uAF//6wAcAAT/7AAG/+gACv/mABL/5gAU/+YAFv/3AB7/4wAg/9wAIf/dACL/3AAj//EAJwAEACr/6wAr/+sALP/cAC3/6wAu/90AL//rADD/6wAx/+kAMv/gADP/4gA0/+EANf/xADb/5AA3/+8AWP/6AFr/6wAWAAb/9gAK//YAEv/2ABT/9gAW//sAF//IABj/9QAZ/9MAGv/hABz/vAAg//sAIv/7ACP/+gAs//sAMf/zADP/6QA0/+8ANv/qAFH/ugBS/7oAYf+8AGP/vAADAEv/uQBU/+gAV//jAAMAGf/NACP/9QAz/98ABQAZ/+IAG//aACP/9QAz//QANf/jAAEAKf/IAAMAF//TABn/+gAc/+AAMwAE/94ABf/mAAb/5gAH/+YACP/mAAn/5gAK/+YAC//mAAz/5gAN//UADv/mAA//5gAQ/+YAEf/mABL/5gAT/+YAFP/mABX/5gAW/+cAF/+0ABj/5QAZ/9YAGv/d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ABn/4gAb//gAM//4ADX//QBQ/+0AWf/6AFz/6ABe/90AX//rAGr/8gAYAAT/5AAN/+oAF//mABv/9QAc//kAHf/3ACD/9wAh//gAIv/3ACT/+wAs//cALv/4AEL/2ABD/9gARv/YAEv/5QBX//gAZP/YAGX/2ABo/9gAaf/YAHb/2ACB/+AAgv/uAAMAGf/4ACcAEwBe//kABQAZ//gAUP/6AFz/9QBe//cAX//yAAEAd//IAAkAGf/jADP//ABI//0AUP/sAFn/+wBc/+wAXv/bAF//6gBq//AACwAZ/+AAG//rADP/9wA1//QASP/9AFD/6wBZ/+4AXP/hAF7/2gBf/9wAav/yAAsAGf/iABv/7AAz//gANf/1AEj/+ABQ/+gAWf/tAFz/4QBe/9sAX//dAGr/7wAHABv/5QBL/98AV//4AFn/+wBc/+sAXv/7AF//5QAKABn/6wAb//0AM//5ADX//QBQ//UAWf/5AFz/5wBe/+kAX//iAGr/9QAEABn/9gBc//oAXv/3AF//9wAIABn/5gAb//gAUP/1AFn/+wBc/+wAXv/pAF//6wBq//UAHgAE/+8ADf/oABf/wAAZ//gAG//nABz/2QAd//MAHv/4ACD/9wAh//gAIv/3ACT/9wAs//cALv/4ADD/+wBC/98AQ//fAEb/9ABL/+wAUP/4AFn/+wBc/+cAXv/3AF//4gBk/98AZf/fAGj/9ABp//QAdv/fAIH/9AAIABn/9wAb/+cAS//vAFD/+ABZ//gAXP/mAF7/9wBf/+EAEgAN//0AF/+8ABn/+gAc/9oAHv/9ACD/9AAh//QAIv/0ACT/9gAs//QALv/0AEb/4gBc//MAXv/5AF//8ABo/+IAaf/iAIH/5gAHABn/+AAb/+cAS//rAFD/+ABc/+oAXv/3AF//5QAGABn/8wBQ//oAXP/yAF7/9ABf/+8Aav/7AAQADf/6ABf/8wAZ//oAHP/kABEABv/6AAr/+gAS//oAFP/6ABf/2QAY//sAGf/hABr/7QAc/8sAMf/6ADP/9QA0//gANv/1AFH/0QBS/9EAYf/SAGP/0gADAAT/5QAN/+wAHf/7AAcABP/mAA3/6gAX//gAGf/6ABv/+AAc/+oAHf/1AAIHUAAEAAAHZggkACAAHQAA//r/9f/9//b/9//x/+P//f/7//X/8f/zAAAAAAAA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CE4IVAhaCGAIZghsCJYIcgh4CH4IrgiECIoIkAiWCJwIogioCK4ItAi6CMAIxgjMCNII2AkgCN4I5AjqCPAI9gj8CQIJCAkOCRQJGgkgCSYAAAksAAAJMgl6CTgJegk+CUQJSgnCCVAJVglcCWIJaAluCXQJegmACYYJjAmSCZgJngmkCaoJsAm2CbwJwgnICc4J1AnaCeAJ5gnsCfIJ+An+CgQKCgoQChYKHAoiCigKLgo0CjoKQApGCkwMegpSAAAKWAAACl4AAApkAAAKagpwCnYKfAqCCogKjgqUCpoKoAqmCqwKsgq4Cr4KxArKCtAK1grcCuIK6AruCvQK+gsACwYLfgsMAAALEgAACxgLHgskCyoLMAs2CzwLQgtIAAALTgAAC1QLWgtgC2YLbAtyC3gLfguEC4oLkAuWC5wLoguoC64LtAu6C8ALxgvMAAAL0gAAC9gAAAveAAAL5AAAC+oAAAvwC/YL/AykDAIMCAwODBQMGgwgDCYMLAwyDDgMPgxEDEoMUAxWAAAMXAAADGIAAAxoDG4MdAx6DIAMhgyMAAAMkgyYDJ4MpAyqDLAMtgy8DMIMyAzODNQM2gzgDOYAAAzsAAAM8gAADPgAAAz+DQQNCgABAP//6wABAQAB6gABAHH/nAABAGwC+gABAI//nAABAHMDAQABAGwD/QABAH4EBwABAHv+mQABAJD+mAABAJEDKAABAI8DMgABAMID0AABAKYD2QABAbr/nAABAbgBuAABAcf/nAABAb0BvAABALP/nAABALcBmwABAJP/nAABAJIBzQABAJX/nAABAJ4B0QABALABvQABAJn/nAABALkBvgABAbP+xAABAbYBwwABAbL+xgABAbABxwABAK4BoAABAGr+vwABAJABywABAH7+0AABAK0BxAABAbL+TAABAcMBxwABAcb+RwABAb8BxwABAK/+SAABALMBmwABAIT+SgABAJEBwAABALP+QwABAKcBsQABALf+gQABAL8BbgABAcD/lQABAaoB3AABAbn/lQABAaoB5QABAK7/nAABALMCaAABAI7/nAABAJgCjQABAJj/mgABALwCigABAKL/nAABAKECkAABAa7/nAABAb7/nAABAa4CmwABAKj/nAABAK0C6wABAJb/nAABAJcDDQABAJz/nAABAOEDCwABAJf/nAABAJ0DBwABAZ4CwwABAaYCwwABALIC7QABAIsDBgABASn+WAABAPICAQABAQD+VwABAPAB/wABATv+wgABAMMB7AABAT3+ygABAM0B7AABAP7+WAABANwCAQABAQv+UwABAOIBvwABATj+SgABANcB5wABATb+SAABAMgB6gABAQX+UAABAPb+TAABANACAAABAL0B7AABAOb/nAABALkB6wABAN7+WgABANUC3AABAOf+WwABANYC7AABAMn/nAABAL4CygABAMP/nAABAL8CzgABASMCRQABAR7/lwABATECUwABAQP/mAABAQ0DAQABAP//lAABAVUDHQABATADhgABAVcDqAABAHf+zgABALoBpAABAGb+0gABAJIBpAABAG7+0AABANYBoAABAIn+6AABAJcBqAABAID+5AABAM4CcgABAJL+5AABANcCdQABAH/+8gABAJcCcwABAHP+3AABAJQCbgABAMYC9wABANoC+wABAID9fgABAIH9fwABAIH+0wABAM4C7gABAHn+5wABAJYC7gABAIn+4QABANYC7wABAH7+7QABAJMC7wABAzL/nQABA0MBpAABA0n/mgABA0YBmQABAYYBoAABAXf/nAABAYYBoQABAzT/nAABAzsC5wABAzz/nAABAzkC3wABAXn/nAABAXgC5gABAXH/nAABAXkC5wABA27/nQABA8sBzgABA3v/nAABA8cByQABAbP/nAABAgMBzQABAar/nAABAgEB0AABA3P/nAABA9ACowABA3r/nAABA9ECoQABAaH/nAABAhACnQABAab/nAABAhMCmwABAhQByAABAW7/nAABAhIBygABARn/nAABAc8BwAABARv/nAABAc4BxQABAVz/nAABAeQCjAABAWL/nAABAegCjQABAUL/nAABAawCjgABATP/nAABAawCjwABAQr+DQABAQMB6wABARn+CwABASoB8wABASz/nAABASgB8QABANT/oAABAOUCCwABANL+IQABARUCsAABAOn+EQABASUCqQABASn/nAABASQCsgABALH/nAABAO4CsgABAZD/nAABAnQDPgABAr0CxgABAN7/nAABANkCygABAOQDRAABAZz/nAABAmkDpgABAZH/nAABAsUDKwABAOv/nAABAN0DKAABALn/nAABAOQDqwABAan/mAABAm4CcAABAZ3/mAABAsMB+AABAOj/nAABAOAB9AABAOoCaAABATX+uQABAc0BzQABAS7+tgABAc0BygABASX+uwABAc4ClwABASX+ugABAc8CjwABAOP/nAABAOECvgABAM3/nAABAN0DNwABAbICpwABAbgCowABALUC8QABAK4C4wABAaT/mgABAhMCkwABAhkCjAABAhz/nAABAUUB0QABAa3/mgABAhkCjgABAib/nAABAR4BzwABAMn/mQABAJ4C7AABATb/mgABAHwCdwABAKT/mwABAKQC1wABAIr/mwABAI8CzgABARr/nAABAIQCkAABAaf/mAABAgQDCQABAa7/mAABAgADDgABAjv/nAABAT0CZQABAbn/mAABAgsDBwABAhb/nAABATcCXQABAMP/mQABAH8DRgABAV//nAABAGcCvgABAH//mQABAHgDKwABAHf/mQABAIMDMQABASr/nAABAGcCzQABAWr+5QABAS8BhgABAWH+8AABATsBiwABAKH/nAABAKgC+gABAKIDAQABASoB1AABATwBnQABALYEDQABAKUEDwABAYP/qQABAUgBzQABAav/nAABAVYBxgABARz/nAABAR0ByQABARb/nAABARsB0AABAWX+5gABAV8B9QABAT3+8gABAWEB+AABAKv/nAABALMCZAABAJH/nAABAL4CgwABAWf+4QABAVkBYgABAWj+3wABAWABnwABAPr/lgABAOsCHwABAPr/zgABAQACTQABAPX+5gABAQoBvQABAQwCNAABAOUDqAABANgDxQABAPD/nAABANUCHQABAQX/ywABATIBkQABAPP+0QABAQABdQABAIP+FgABAJEB2QABAO0DhQABAPMDfwABASv/nAABAQkCLgABAVH+lgABAToBvAABAWX/lgABAUYCCAABAST/nAABAUkCJAABAPH/nAABAO0C4gABAPT/zgABAOoDGQABAP3/nAABAPgC6gABAQv/rQABAS8CTAABAPL+zQABAPIBzAABAPf+zAABAO4B1AABAPgDJAABAQMDLwABAQAC/wABAP0C+wABAPoDLQABAPkDPAABAXX+5wABAMABjQABAVwBAgABAWz+RAABAMABigABAWX+BQABAU4A/wABAVL99QABAUUAwAABAKr+0wABAK8BoQABAJL+0wABAKABvAABAKT+xgABAKkBvwABALT+xgABAL8BqwABANgDCAABAPYCygABAO0CIAABALL/nAABAL8DIgABAIb/nAABAJoDYgABAKP/nAABAKsDOwABAMACpgABAXP+7QABAMYBmQABAWT+owABAXUA/AABAU3+pAABAToAyQABAKz+ygABALsBoQABAIb+ywABAJ8ByAABAKz+xgABAJ8BuAABAKf+xwABALABtQABATYCBAABATYAvAABAWIDAQABAWMDCQABAGP/nAABAGAA5QAFAAAAAQAIAAEADAAoAAIAMgCYAAIABACDAIQAAAKYApgAAgKkAqUAAwKpArwABQACAAECHAJiAAAAGQABC4QAAQuEAAELlgABC5YAAQuWAAELigAACoQAAQuWAAAKhAABC5YAAQuQAAAKhAABC5YAAQuWAAAKhAABC5YAAQuWAAELlgABC5YAAQuWAAELlgABC5YAAQuWAAELlgABC5YARwCQALIA1AD2ARgBOgFcAX4BoAHCAeQCBgIoAkoCbAKOArAC0gL0AxYDOANaA3wDngPAA+IEBAQmBEgEagSMBKgEygTmBQgFKgVMBW4FkAWsBc4F8AYSBjQGVgZ4BpQGtgbSBvQHFgc4B1oHfAeeB8AH4ggECCYISAhqCIwIrgjQCPIJFAk2CVIJdAmWCbgAAgAKABAAFgAcAAEBlv+0AAEBtAMaAAEAiP9wAAEAewKsAAIACgAQABYAHAABAZr/qwABAb0DGAABAHz/eAABAHwCswACAAoAEAAWABwAAQGU/7gAAQG5Ax0AAQB9/5AAAQCbA+MAAgAKABAAFgAcAAEBtv+nAAEBxQMhAAEAnP+PAAEAmwQFAAIACgAQABYAHAABAbb/ogABAakDCwABAMT+UwABAIkCoQACAAoAEAAWABwAAQHd/5wAAQGzAxsAAQDc/mMAAQCFArgAAgAKABAAFgAcAAEBr/+9AAEBywM2AAEAjP92AAEAhgNfAAIACgAQABYAHAABAar/swABAdADMAABAJb/dwABAKQDYAACAAoAEAAWABwAAQGd/7QAAQHqA2AAAQCa/2IAAQCgA6QAAgAKABAAFgAcAAEC4f8sAAECgQHvAAEBWf6jAAEAvAGdAAIACgAQABYAHAABAvL/QgABAoYB5gABAV3+qwABALsBnQACAAoAEAAWABwAAQL+/s4AAQJ1AbgAAQFY/roAAQC8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AbIBsQABAbUAAwG5AbgBtwAFAb0BvAG7AcABvwAFAcUBwwHBAcABvwABAcAAAQHCAAEBxAACAccBxgABAccABQHPAc0BywHKAckAAQHMAAEBzgACAdEB0AADAdUB1AHTAAMB2QHYAdcAAwHdAdwB2wADAeEB4AHfAAEB4wADAecB5gHlAAEB6QADAe0B7AHrAAEB7wADAfMB8gHxAAEB9QABAfcAAQH5AAEB+wABAgEAAwIGAgUCAwABAgQAAgIIAgcAAwINAgwCCgABAgsAAQIOAAMC0wLUAtIAAwIUAhMCEQABAhIAAgIWAhUAAQIYAAECGgABAh0AAQIfAAECIQABAiMAAQIrAAECOQABAjsAAQI9AAECQQABAkMAAQJFAAECSQABAksAAQJNAAECUgABAlQAAQJWAAECegABAmwAAQJ7AAEAbQAmAMMAyAEcASEBNgE4AToBPAE+AUABRwFKAUwBTwFSAVUBWAFbAV4BYgFmAWoBbgFyAXQBdgF4AXoBfAF9AYABggGEAYYBiAGMAZABlAGYAZwBoAGkAagBrAGwAbQBtgG6AbsBvAG9Ab4BvwHBAcMBxQHGAcgBywHNAc8B0gHWAdoB3gHiAeQB6AHqAe4B8AH0AfYB+AH6AgACAgIDAgYCCQIKAg0CDwIQAhECFAIXAhkCHAIeAiACIgIkAjgCOgI8AkACQgJEAkgCSgJMAlECUwJVAnQCdgJ3AAYAAAACAAoAHAADAAAAAQisAAEALgABAAAADgADAAAAAQiaAAIAFAAcAAEAAAAOAAEAAgLPAtAAAgABAsICzQAAAAQAAAABAAgAAQCWAAgAFgAgACoANAA+AEgAUgBcAAEABAK6AAICswABAAQCtAACArMAAQAEArUAAgKzAAEABAK2AAICswABAAQCtwACArMAAQAEArgAAgKzAAEABAK5AAICswAHABAAFgAcACIAKAAuADQCugACAqkCtAACAq0CtQACAq4CtgACAq8CtwACArACuAACArECuQACArIAAgACAqkCqQAAAq0CswABAAEAAAABAAgAAQe+ANkAAQAAAAEACAABAAYAAQABAAQAwwDIARwBIQABAAAAAQAIAAIADAADAnoCbAJ7AAEAAwJ0AnYCdwABAAAAAQAIAAIApAAkAUMBSgFPAVUBWwFhAWUBaQFtAXEBiwGPAZMBlwGbAZ8BowGnAasBrwGzAbkBvQHFAc8B1QHZAd0B4QHnAe0B8wIGAg0C0wIUAAEAAAABAAgAAgBOACQBQgFJAU4BVAFaAWABZAFoAWwBcAGKAY4BkgGWAZoBngGiAaYBqgGuAbIBuAG8AcMBzQHUAdgB3AHgAeYB7AHyAgUCDALUAhMAAQAkAUABRwFMAVIBWAFeAWIBZgFqAW4BiAGMAZABlAGYAZwBoAGkAagBrAGwAbYBugG+AcgB0gHWAdoB3gHkAeoB8AICAgkCDwIQAAEAAAABAAgAAgCgAE0BNwE5ATsBPQE/AUEBSAFNAVMBWQFfAWMBZwFrAW8BcwF1AXcBegF9AYEBgwGGAYkBjQGRAZUBmQGdAaEBpQGpAa0BsQG1AbcBuwHBAcsB0wHXAdsB3wHjAeUB6QHrAe8B8QH1AfcB+QH7AgECAwIKAtICEQIYAhoCHQIfAiECIwIrAjkCOwI9AkECQwJFAkkCSwJNAlICVAJWAAEATQE2ATgBOgE8AT4BQAFHAUwBUgFYAV4BYgFmAWoBbgFyAXQBdgF4AXwBgAGCAYQBiAGMAZABlAGYAZwBoAGkAagBrAGwAbQBtgG6Ab4ByAHSAdYB2gHeAeIB5AHoAeoB7gHwAfQB9gH4AfoCAAICAgkCDwIQAhcCGQIcAh4CIAIiAiQCOAI6AjwCQAJCAkQCSAJKAkwCUQJTAlUABAAIAAEACAABAGAAAwCaAAwANgAFAAwAEgAYAB4AJAIdAAIBNwIfAAIBOQIhAAIBOwIjAAIBPQIrAAIBPwAFAAwAEgAYAB4AJAIcAAIBNwIeAAIBOQIgAAIBOwIiAAIBPQIkAAIBPwABAAMBNgHUAdUABAAJAAEACAABAh4AEQAoADYAWAB6AJwAvgDgAQIBJAFGAWgBigGkAcYB6AHyAhQAAQAEAmMABAHVAdQB5QAEAAoAEAAWABwCJwACAgECKAACAgMCKQACAgoCKgACAhEABAAKABAAFgAcAiwAAgIBAi0AAgIDAi4AAgIKAi8AAgIRAAQACgAQABYAHAIwAAICAQIxAAICAwIyAAICCgIzAAICEQAEAAoAEAAWABwCNAACAgECNQACAgMCNgACAgoCNwACAhEABAAKABAAFgAcAjkAAgIBAjsAAgIDAj0AAgIKAj8AAgIRAAQACgAQABYAHAI4AAICAQI6AAICAwI8AAICCgI+AAICEQAEAAoAEAAWABwCQQACAgECQwACAgMCRQACAgoCRwACAhEABAAKABAAFgAcAkAAAgIBAkIAAgIDAkQAAgIKAkYAAgIRAAQACgAQABYAHAJJAAICAQJLAAICAwJNAAICCgJPAAICEQAEAAoAEAAWABwCSAACAgECSgACAgMCTAACAgoCTgACAhEAAwAIAA4AFAJSAAICAQJUAAICAwJWAAICCgAEAAoAEAAWABwCUQACAgECUwACAgMCVQACAgoCVwACAhEABAAKABAAFgAcAlgAAgIBAlkAAgIDAloAAgIKAlsAAgIRAAEABAJdAAICEQAEAAoAEAAWABwCXgACAgECXwACAgMCYAACAgoCYQACAhEAAQAEAmIAAgIRAAEAEQE2AUkBTgFUAVoBigGLAY4BjwGSAZMBlgGXAeACBQIMAhMAAQAJAAEACAACACgAEQHAAcIBxAHHAcABwAHCAcQBxwHHAcoBzAHOAdECBAILAhIAAQARAboBuwG8Ab0BvgG/AcEBwwHFAcYByAHLAc0BzwIDAgoCEQABAAkAAQAIAAIAIgAOAcABwgHEAccBwAHAAcIBxAHHAccBygHMAc4B0QABAA4BugG7AbwBvQG+Ab8BwQHDAcUBxgHIAcsBzQHPAAYACQAKABoAPABWAHIAmAC+AQABIgFgAZoAAwABABIAAQHsAAAAAQAAAA8AAgACAXgBfwAAAYQBhwAIAAMAAAABAfAAAQASAAEAAAAQAAEAAgGGAYcAAwAAAAEB1gABABIAAQAAABEAAQADAVQBWgIMAAMAAAABABIAAQAcAAEAAAARAAEAAwFPAgYCFAABAAMBTgIFAhMAAwABABIAAQGUAAAAAQAAABIAAQAIATwBPQE+AT8CIgIjAiQCKwADAAAAAQB2AAEAEgABAAAAEgABABYBNgE4AToBPAE+AUoBSwFPAVEBVQFWAVsBXAHhAfgB+QIGAggCDQIOAhQCFgADAAAAAQA0AAEAEgABAAAAEgABAAYBeAF5AXwBfwGEAYUAAwAAAAEAEgABACIAAQAAABIAAQAGAXgBegF8AX0BhAGGAAEADAFiAWYBagFuAaABpAG2Ad4CAAICAgkCEAADAAEAEgABAC4AAAABAAAAEgACAAQBNgE/AAABhAGHAAoCHAIkAA4CKwIrABcAAQAEAb4BxQHIAc8AAwABABIAAQA0AAAAAQAAABIAAgAFATYBPwAAAXwBfwAKAYQBhwAOAhwCJAASAisCKwAbAAEAAgG6Ab0AAQAAAAEACAABAAYA1QABAAEAJgABAAkAAQAIAAIAFAAHAUsBUQFWAVwCCAIOAhYAAQAHAUoBTwFVAVsCBgINAhQAAQAJAAEACAACAAwAAwFXAV0CDgABAAMBVQFbAg0AAQAJAAEACAABAAYAAQABAAYBTwFVAVsCBgINAhQAAQAJAAEACAACACQADwFXAV0BeQF7AX8BfgGFAYcBvwHGAb8BxgHJAdACDgABAA8BVQFbAXgBegF8AX0BhAGGAboBvQG+AcUByAHPAg0AAAAAAAEAAAAAClExXk1eMEBoN0RvQHh0MnU3VWpyTUo0WDJYRUA=
) format("truetype");
    font-weight: 400; font-style: normal; font-display: swap;
}
@font-face {
    font-family: "PeydaReport";
    src: url(data:font/truetype;charset=utf-8;base64,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AowAPgKMAD4CjAA+AowAPgKMAD4D5QARA+UAEQPlABED5QARAkoABwJKAAcCSgAHAkoABwIUACQCFAAkAhQAJAHsAB8B7AAfAewAHwHsAB8B7AAfAewAHwHsAB8B7AAfAewAGQMeAB8BugAgAboAGAG6ACABugAgAlUAJQIdAB8CHQAfAhEAHwIQAB8CEQAfAfEAHwIQAB8B8QAfAhAAHwIQAB8CEAAdAhoAIAIaACACGgAgAjgAGwD9ADkBEAA5ATj/zgE7ABkA9QA0ARL/+gD0/+UA/f/nAggAOQEHAD4BB/+5AQcALQEH/9kCOAA5AjgAOQI4ADkCOAA2AjgAOQIIACACCAAgAggAIAIIACACCAAgAggAIAIIACACCAAgA08AIAIdADgBmgA5AZr//AGaADABvgAgAb4AGgG+ACABvgAgAlUALAGPABoBj//ZAY8AGgGPABoCOAA1AjgANQI4ADUCOAA1AjgANQI4ADUCOAA1AjgANQMKABADCgAQAwoAEAMKABAB8wAMAfMADAHzAAwB1gAoAdYAKAHWACgB0wAxANoANAEIADUA0f/UARX/5gDq/+UBCgAGATb/7QFL/+0BS//QAUr/ywNiADQDgQA0AX7/8gFN//IBff/yAc3/8gJD//IDYgA0A4EANAF+//IBTf/yAc3/8gNiADQDgQA0AX7/8gF9//IBzf/yAkP/8gNiADQDgQA0AX7/8gF9//IBzf/yAgX/8gNiADQDgQA0AX7/8gF9//IBzf/yAfP/8gNiADQDgQA0AX7/8gFN//ICrwA2Ar4ANgKt//ICmf/yAr0ANgK+ADYCrf/yApn/8gKrADYCvgA2Aq3/8gKX//ICrwA2Ar4ANgKt//ICmf/yAjgANgJPADYCOAA2Ak8ANgI4ADYCTwA2AWj/2AEj/9oBiv/YAUX/2gFo/9gBiv/YAUX/2gEj/9oBaP/YAYr/2AFo/9gBiv/YAWj/2AEj/9oBxv/YAUX/2gSoADQE0wA2AwL/8gLh//IEqAA0BNMANgMC//IC4f/yBN8ANAUEADQDRf/yAx3/8gTfADQFBAA0A0X/8gMd//IC4gA2Aw4ANgLi//ICtv/yAuIANgMOADYC4v/yArb/8gI6ADYCdgA2Akb/8QHv//ICOgA2AnYANgJG//EB7//yA2YANgOyADYB9P/yAeP/8gNmADYDsgA2AfT/8gHj//IDZgA2A7IANgH0//IB4//yAssANgLjADYCywA2AuMANgH0//IB4//yA2MANgOBADYCAf/yAZj/8gOCADQDgwA0BGIANgPpADQEpQA2AgH/8gN2//IBmP/yAZj/8gMz//IDggA0A4QANARiADYD6QA0BKUANgIB//IDdv/NAZj/8gGY//IDM//NAskANQMCADUBVv/yAQ//8gLLADUDBAA1AVb/8gEP//ICsgA0AuAANAI1//ICEf/yAskANAL5ADQBfv/yAU3/8gLJADQC+QA0AfoANAIMADYCfv/yAwP/8gH6ADQCDAA2AfoANAI7ACoCXf/yAU3/8gH6ADQCDAA2AwP/8gJUADIDQf/yAwP/8gH6ADQCDAA2AfoANAI7ACoB9gAyAgkAMgH2ADICBgAyAfYAMgIGADIB9gAyAgYAMgLnADQC6AA0AucANALoADQCmgA0AX7/8gF9//IBzf/yAe//8gLoABYC6QA0ApoANAF+//IBTf/yAc3/8gLoABQC5wA0AugANAKaADQBfv/yAX3/8gHN//IB5v/yAmYANAKaADQCywA0AvoANAC0AAACLwAlAmwAJQIvAAgCbAAOAi8AJQJsACUCUv/7Aov/9wIv/+QDlwA0BAUANAObADQDmwA0A6AACwObADQCbP/UA/8ANAP/ADQEBAA5A/8ANAObADQDmwA0A54ANAObADQDnAA0A5wANAOcADQDnAA0BUkANAVsADQFSQA0BWwANAVJADQFbAA0BUkANAVsADQFSQA0BWwANAVJADQFbAA0BUkANAVsADQFSQA0BWwANAWLADQFrgA0BYsANAWuADQFiwA0BbAANAWLADQFrgA0Ba4ANAWLADQFrgA0BYsANAWuADQFiwA0Ba4ANAWLADQDmwA0A5cANAOXADQDlwA0BAUANAQFADQDlwA0A5cANAOXAC0DlwA0BAUANAUPADQBXwAtAQ4AKgEfADkA8wAjAi8AJwLzACcB1QAyAp4AIgItABkCZAANAmQADQIMAB4B6gA0APMAIwIvACcC8wAnAo0AJwKcACICUQAnAmQADQJkAA0CDAAeAlIAKQJkAA0COgAAB30AAAAAAAAAAAAAAAAAAAAAAAACOgAAAjoAAAJfAAACXwAAAn4AAAK3AAACYQAAAqsAAAKZAAACbAAAAwUAAAFKABkBDgAt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AGEAQgBvAGwAZAAzAC4AMAAwADAAOwBLAEgARABNADsAUABlAHkAZABhAC0AQgBvAGwAZABQAGUAeQBkAGEAIABCAG8AbABkAFYAZQByAHMAaQBvAG4AIAAzAC4AMAAwADAAUABlAHkAZABhAC0AQgBvAGwAZABQAGUAeQBkAGEAIABpAHMAIABhACAAdAByAGEAZABlAG0AYQByAGsAIABvAGYAIAB3AHcAdwAuAGYAbwBuAHQAaQByAGEAbgAuAGMAbwBtAE4AYQBzAGUAcgAgAEsAaABhAGQAZQBtAFQAbwAgAHUAcwBlACAAdABoAGkAcwAgAGYAbwBuAHQALAAgAGkAdAAgAGkAcwAgAG4AZQBjAGUAcwBzAGEAcgB5ACAAdABvACAAbwBiAHQAYQBpAG4AIAB0AGgAZQAgAGwAaQBjAGUAbgBzAGUAIABmAHIAbwBtACAAdwB3AHcALgBmAG8AbgB0AGkAcgBhAG4ALgBjAG8AbQB3AHcAdwAuAGYAbwBuAHQAaQByAGEAbgAuAGMAbwBtAGgAdAB0AHAAcwA6AC8ALwBkAHIAaQBiAGIAYgBsAGUALgBjAG8AbQAvAG4AYQBzAGUAcgBrAGgAYQBkAGUAbQBmAG8AbgB0AGkAcgBhAG4ALgBjAG8AbQAvAGwAaQBjAGUAbgBzAGUAcwAAAAIAAAAAAAD/nAAyAAAAAAAAAAAAAAAAAAAAAAAAAAAC1gAAAAEAAgADACQAJQAmACcAKAApACoAKwAsAC0ALgAvADAAMQAyADMANAA1ADYANwA4ADkAOgA7ADwAPQBEAEUARgBHAEgASQBKAEsATABNAE4ATwBQAFEAUgBTAFQAVQBWAFcAWABZAFoAWwBcAF0AEwAUABUAFgAXABgAGQAaABsAHAARAA8AHQAeABAADgANAEEA2QASAB8AIAAhAAQAIgAKAAUABgAjAAcACAAJAAsADABeAF8AYAA+AD8AQAC2ALcAtAC1AMQAxQCHAEIAsgCzAIwAigCLAL0AhACFAJYA7wCTAPAAuADoAKsAwwCjAKIAgwC8AIgAhgCCAMIAYQC+AL8BAgEDAMkBBADHAGIArQEFAQYAYwCuAJAA/QD/AGQBBwDpAQgBCQBlAQoAyADKAQsAywEMAQ0BDgD4AQ8BEAERAMwAzQDOAPoAzwESARMBFAEVARYBFwDiARgBGQEaAGYBGwDQANEAZwDTARwBHQCRAK8AsADtAR4BHwEgASEA5AD7ASIBIwEkASUBJgEnANQA1QBoANYBKAEpASoBKwEsAS0BLgEvAOsBMAC7ATEBMgDmATMAaQE0AGsAbABqATUBNgBuAG0AoAD+AQAAbwE3AOoBOAEBAHABOQByAHMBOgBxATsBPAE9APkBPgE/AUAA1wB0AHYAdwFBAHUBQgFDAUQBRQFGAUcA4wFIAUkBSgB4AUsAeQB7AHwAegFMAU0AoQB9ALEA7gFOAU8BUAFRAOUA/AFSAIkBUwFUAVUBVgB+AIAAgQB/AVcBWAFZAVoBWwFcAV0BXgDsAV8AugFgAOcBYQFiAWMBZAFlAWYBZwFoAWkBagFrAWwBbQFuAW8BcAFxAXIBcwF0AXUBdgF3AXgBeQF6AXsBfAF9AX4BfwGAAYEBggGDAYQBhQGGAYcBiAGJAYoBiwGMAY0BjgGPAZABkQGSAZMBlAGVAZYBlwGYAZkBmgGbAZwBnQGeAZ8BoAGhAaIBowGkAaUBpgGnAagBqQGqAasBrAGtAa4BrwGwAbEBsgGzAbQBtQG2AbcBuAG5AboBuwG8Ab0BvgG/AcABwQHCAcMBxAHFAcYBxwHIAckBygHLAcwBzQHOAc8B0AHRAdIB0wHUAdUB1gHXAdgB2QHaAdsB3AHdAd4B3wHgAeEB4gHjAeQB5QHmAecB6AHpAeoB6wHsAe0B7gHvAfAB8QHyAfMB9AH1AfYB9wH4AfkB+gH7AfwB/QH+Af8CAAIBAgICAwIEAgUCBgIHAggCCQIKAgsCDAINAg4CDwIQAhECEgITAhQCFQIWAhcCGAIZAhoCGwIcAh0CHgIfAiACIQIiAiMCJAIlAiYCJwIoAikCKgIrAiwCLQIuAi8CMAIxAjICMwI0AjUCNgI3AjgCOQI6AjsCPAI9Aj4CPwJAAkECQgJDAkQCRQJGAkcCSAJJAkoCSwJMAk0CTgJPAlACUQJSAlMCVAJVAlYCVwJYAlkCWgJbAlwCXQJeAl8CYAJhAmICYwJkAmUCZgJnAmgCaQJqAmsCbAJtAm4CbwJwAnECcgJzAnQCdQJ2AncCeAJ5AnoCewJ8An0CfgJ/AoACgQKCAoMChAKFAoYChwKIAokCigKLAowCjQKOAo8CkAKRApICkwKUApUClgKXApgCmQKaApsCnAKdAp4CnwKgAqECogKjAqQCpQKmAqcCqAKpAqoCqwKsAq0CrgKvArACsQKyArMCtAK1ArYCtwK4ArkCugK7ArwCvQK+Ar8CwACpAKoCwQLCAsMCxALFAsYCxwLIAskCygLLAswCzQLOAs8C0ALRAtIC0wLUAtUC1gLXAtgC2QLaAtsC3ALdAt4C3wLgAuEC4gLjAuQC5QLmAucC6ALpAuoC6wLsAu0C7gLvAvAC8QLyAvMC9AL1AvYC9wL4AvkC+gL7AOEC/AL9Av4C/wd1bmkwNjVBB3VuaTA2NUIGQWJyZXZlB0FtYWNyb24HQW9nb25lawpDZG90YWNjZW50BkRjYXJvbgZEY3JvYXQGRWNhcm9uCkVkb3RhY2NlbnQHRW1hY3JvbgdFb2dvbmVrB3VuaTAxOEYHdW5pMDEyMgpHZG90YWNjZW50BEhiYXIHSW1hY3JvbgdJb2dvbmVrB3VuaTAxMzYGTGFjdXRlBkxjYXJvbgd1bmkwMTNCBk5hY3V0ZQZOY2Fyb24HdW5pMDE0NQNFbmcNT2h1bmdhcnVtbGF1dAdPbWFjcm9uBlJhY3V0ZQZSY2Fyb24HdW5pMDE1NgZTYWN1dGUHdW5pMDIxOAd1bmkxRTlFBFRiYXIGVGNhcm9uB3VuaTAxNjIHdW5pMDIxQQ1VaHVuZ2FydW1sYXV0B1VtYWNyb24HVW9nb25lawVVcmluZwZXYWN1dGULV2NpcmN1bWZsZXgJV2RpZXJlc2lzBldncmF2ZQtZY2lyY3VtZmxleAZZZ3JhdmUGWmFjdXRlClpkb3RhY2NlbnQGYWJyZXZlB2FtYWNyb24HYW9nb25lawpjZG90YWNjZW50BmRjYXJvbgZlY2Fyb24KZWRvdGFjY2VudAdlbWFjcm9uB2VvZ29uZWsHdW5pMDI1OQd1bmkwMTIzCmdkb3RhY2NlbnQEaGJhcglpLmxvY2xUUksHaW1hY3Jvbgdpb2dvbmVrB3VuaTAxMzcGbGFjdXRlBmxjYXJvbgd1bmkwMTNDBm5hY3V0ZQZuY2Fyb24HdW5pMDE0NgNlbmcNb2h1bmdhcnVtbGF1dAdvbWFjcm9uBnJhY3V0ZQZyY2Fyb24HdW5pMDE1NwZzYWN1dGUHdW5pMDIxOQR0YmFyBnRjYXJvbgd1bmkwMTYzB3VuaTAyMUINdWh1bmdhcnVtbGF1dAd1bWFjcm9uB3VvZ29uZWsFdXJpbmcGd2FjdXRlC3djaXJjdW1mbGV4CXdkaWVyZXNpcwZ3Z3JhdmULeWNpcmN1bWZsZXgGemFjdXRlCnpkb3RhY2NlbnQHdW5pMDYyMQd1bmkwNjI3DHVuaTA2MjcuZmluYQd1bmkwNjIzDHVuaTA2MjMuZmluYQd1bmkwNjI1DHVuaTA2MjUuZmluYQd1bmkwNjIyDHVuaTA2MjIuZmluYQd1bmkwNjcxDHVuaTA2NzEuZmluYQd1bmkwNjZFDHVuaTA2NkUuZmluYQx1bmkwNjZFLm1lZGkMdW5pMDY2RS5pbml0EHVuaTA2NkUuaW5pdC5hbHQRdW5pMDY2RS5pbml0LmFsdDIRdW5pMDY2RS5pbml0LmFsdDMHdW5pMDYyOAx1bmkwNjI4LmZpbmEMdW5pMDYyOC5tZWRpDHVuaTA2MjguaW5pdBB1bmkwNjI4LmluaXQuYWx0B3VuaTA2N0UMdW5pMDY3RS5maW5hDHVuaTA2N0UubWVkaQx1bmkwNjdFLmluaXQQdW5pMDY3RS5pbml0LmFsdBF1bmkwNjdFLmluaXQuYWx0Mgd1bmkwNjJBDHVuaTA2MkEuZmluYQx1bmkwNjJBLm1lZGkMdW5pMDYyQS5pbml0EHVuaTA2MkEuaW5pdC5hbHQRdW5pMDYyQS5pbml0LmFsdDIHdW5pMDYyQgx1bmkwNjJCLmZpbmEMdW5pMDYyQi5tZWRpDHVuaTA2MkIuaW5pdBB1bmkwNjJCLmluaXQuYWx0EXVuaTA2MkIuaW5pdC5hbHQyB3VuaTA2NzkMdW5pMDY3OS5maW5hDHVuaTA2NzkubWVkaQx1bmkwNjc5LmluaXQHdW5pMDYyQwx1bmkwNjJDLmZpbmEMdW5pMDYyQy5tZWRpDHVuaTA2MkMuaW5pdAd1bmkwNjg2DHVuaTA2ODYuZmluYQx1bmkwNjg2Lm1lZGkMdW5pMDY4Ni5pbml0B3VuaTA2MkQMdW5pMDYyRC5maW5hDHVuaTA2MkQubWVkaQx1bmkwNjJELmluaXQHdW5pMDYyRQx1bmkwNjJFLmZpbmEMdW5pMDYyRS5tZWRpDHVuaTA2MkUuaW5pdAd1bmkwNjJGDHVuaTA2MkYuZmluYQd1bmkwNjMwDHVuaTA2MzAuZmluYQd1bmkwNjg4DHVuaTA2ODguZmluYQd1bmkwNjMxC3VuaTA2MzEuYWx0DHVuaTA2MzEuZmluYRB1bmkwNjMxLmZpbmEuYWx0B3VuaTA2MzIMdW5pMDYzMi5maW5hEHVuaTA2MzIuZmluYS5hbHQLdW5pMDYzMi5hbHQHdW5pMDY5MQx1bmkwNjkxLmZpbmEHdW5pMDY5NQx1bmkwNjk1LmZpbmEHdW5pMDY5OAt1bmkwNjk4LmFsdAx1bmkwNjk4LmZpbmEQdW5pMDY5OC5maW5hLmFsdAd1bmkwNjMzDHVuaTA2MzMuZmluYQx1bmkwNjMzLm1lZGkMdW5pMDYzMy5pbml0B3VuaTA2MzQMdW5pMDYzNC5maW5hDHVuaTA2MzQubWVkaQx1bmkwNjM0LmluaXQHdW5pMDYzNQx1bmkwNjM1LmZpbmEMdW5pMDYzNS5tZWRpDHVuaTA2MzUuaW5pdAd1bmkwNjM2DHVuaTA2MzYuZmluYQx1bmkwNjM2Lm1lZGkMdW5pMDYzNi5pbml0B3VuaTA2MzcMdW5pMDYzNy5maW5hDHVuaTA2MzcubWVkaQx1bmkwNjM3LmluaXQHdW5pMDYzOAx1bmkwNjM4LmZpbmEMdW5pMDYzOC5tZWRpDHVuaTA2MzguaW5pdAd1bmkwNjM5DHVuaTA2MzkuZmluYQx1bmkwNjM5Lm1lZGkMdW5pMDYzOS5pbml0B3VuaTA2M0EMdW5pMDYzQS5maW5hDHVuaTA2M0EubWVkaQx1bmkwNjNBLmluaXQHdW5pMDY0MQx1bmkwNjQxLmZpbmEMdW5pMDY0MS5tZWRpDHVuaTA2NDEuaW5pdAd1bmkwNkE0DHVuaTA2QTQuZmluYQx1bmkwNkE0Lm1lZGkMdW5pMDZBNC5pbml0B3VuaTA2QTEMdW5pMDZBMS5maW5hDHVuaTA2QTEubWVkaQx1bmkwNkExLmluaXQHdW5pMDY2Rgx1bmkwNjZGLmZpbmEHdW5pMDY0Mgx1bmkwNjQyLmZpbmEMdW5pMDY0Mi5tZWRpDHVuaTA2NDIuaW5pdAd1bmkwNjQzDHVuaTA2NDMuZmluYQx1bmkwNjQzLm1lZGkMdW5pMDY0My5pbml0B3VuaTA2QTkLdW5pMDZBOS5hbHQMdW5pMDZBOS5zczAxDHVuaTA2QTkuZmluYRF1bmkwNkE5LmZpbmEuc3MwMQx1bmkwNkE5Lm1lZGkRdW5pMDZBOS5tZWRpLnNzMDEMdW5pMDZBOS5pbml0EHVuaTA2QTkuaW5pdC5hbHQRdW5pMDZBOS5pbml0LnNzMDEHdW5pMDZBRgt1bmkwNkFGLmFsdAx1bmkwNkFGLnNzMDEMdW5pMDZBRi5maW5hEXVuaTA2QUYuZmluYS5zczAxDHVuaTA2QUYubWVkaRF1bmkwNkFGLm1lZGkuc3MwMQx1bmkwNkFGLmluaXQQdW5pMDZBRi5pbml0LmFsdBF1bmkwNkFGLmluaXQuc3MwMQd1bmkwNjQ0DHVuaTA2NDQuZmluYQx1bmkwNjQ0Lm1lZGkMdW5pMDY0NC5pbml0B3VuaTA2QjUMdW5pMDZCNS5maW5hDHVuaTA2QjUubWVkaQx1bmkwNkI1LmluaXQHdW5pMDY0NQx1bmkwNjQ1LmZpbmEMdW5pMDY0NS5tZWRpDHVuaTA2NDUuaW5pdAd1bmkwNjQ2DHVuaTA2NDYuZmluYQx1bmkwNjQ2Lm1lZGkMdW5pMDY0Ni5pbml0B3VuaTA2QkEMdW5pMDZCQS5maW5hB3VuaTA2NDcMdW5pMDY0Ny5maW5hDHVuaTA2NDcubWVkaQx1bmkwNjQ3LmluaXQHdW5pMDZDMAx1bmkwNkMwLmZpbmEHdW5pMDZDMQx1bmkwNkMxLmZpbmEMdW5pMDZDMS5tZWRpDHVuaTA2QzEuaW5pdAd1bmkwNkMyDHVuaTA2QzIuZmluYQd1bmkwNkJFDHVuaTA2QkUuZmluYQx1bmkwNkJFLm1lZGkMdW5pMDZCRS5pbml0B3VuaTA2MjkMdW5pMDYyOS5maW5hB3VuaTA2QzMMdW5pMDZDMy5maW5hB3VuaTA2NDgMdW5pMDY0OC5maW5hB3VuaTA2MjQMdW5pMDYyNC5maW5hB3VuaTA2QzYMdW5pMDZDNi5maW5hB3VuaTA2QzcMdW5pMDZDNy5maW5hB3VuaTA2NDkMdW5pMDY0OS5maW5hB3VuaTA2NEEMdW5pMDY0QS5maW5hEXVuaTA2NEEuZmluYS5zczAxDHVuaTA2NEEubWVkaQx1bmkwNjRBLmluaXQQdW5pMDY0QS5pbml0LmFsdBF1bmkwNjRBLmluaXQuYWx0Mgd1bmkwNjI2DHVuaTA2MjYuZmluYRF1bmkwNjI2LmZpbmEuc3MwMQx1bmkwNjI2Lm1lZGkMdW5pMDYyNi5pbml0EHVuaTA2MjYuaW5pdC5hbHQHdW5pMDZDRQd1bmkwNkNDDHVuaTA2Q0MuZmluYRF1bmkwNkNDLmZpbmEuc3MwMQx1bmkwNkNDLm1lZGkMdW5pMDZDQy5pbml0EHVuaTA2Q0MuaW5pdC5hbHQRdW5pMDZDQy5pbml0LmFsdDIHdW5pMDZEMgx1bmkwNkQyLmZpbmEHdW5pMDc2OQx1bmkwNzY5LmZpbmEHdW5pMDY0MAt1bmkwNjQ0MDYyNxB1bmkwNjQ0MDYyNy5maW5hC3VuaTA2NDQwNjIzEHVuaTA2NDQwNjIzLmZpbmELdW5pMDY0NDA2MjUQdW5pMDY0NDA2MjUuZmluYQt1bmkwNjQ0MDYyMhB1bmkwNjQ0MDYyMi5maW5hC3VuaTA2NDQwNjcxEHVuaTA2NkUwNkNDLmZpbmEVdW5pMDY2RTA2Q0MuX2ZpbmEuYWx0EHVuaTA2MjgwNjQ5LmZpbmEQdW5pMDYyODA2NEEuZmluYRB1bmkwNjI4MDYyNi5maW5hEHVuaTA2MjgwNkNDLmZpbmEQdW5pMDY0NDA2NzEuZmluYRB1bmkwNjdFMDY0OS5maW5hEHVuaTA2N0UwNjRBLmZpbmEQdW5pMDY3RTA2MjYuZmluYRB1bmkwNjdFMDZDQy5maW5hEHVuaTA2MkEwNjQ5LmZpbmEQdW5pMDYyQTA2NEEuZmluYRB1bmkwNjJBMDYyNi5maW5hEHVuaTA2MkEwNkNDLmZpbmEQdW5pMDYyQjA2NDkuZmluYRB1bmkwNjJCMDY0QS5maW5hEHVuaTA2MkIwNjI2LmZpbmEQdW5pMDYyQjA2Q0MuZmluYQt1bmkwNjMzMDY0ORB1bmkwNjMzMDY0OS5maW5hC3VuaTA2MzMwNjRBEHVuaTA2MzMwNjRBLmZpbmELdW5pMDYzMzA2MjYQdW5pMDYzMzA2MjYuZmluYQt1bmkwNjMzMDZDQxB1bmkwNjMzMDZDQy5maW5hC3VuaTA2MzQwNjQ5EHVuaTA2MzQwNjQ5LmZpbmELdW5pMDYzNDA2NEEQdW5pMDYzNDA2NEEuZmluYQt1bmkwNjM0MDYyNhB1bmkwNjM0MDYyNi5maW5hC3VuaTA2MzQwNkNDEHVuaTA2MzQwNkNDLmZpbmELdW5pMDYzNTA2NDkQdW5pMDYzNTA2NDkuZmluYQt1bmkwNjM1MDY0QRB1bmkwNjM1MDY0QS5maW5hC3VuaTA2MzUwNjI2EHVuaTA2MzUwNjI2LmZpbmELdW5pMDYzNTA2Q0MQdW5pMDYzNTA2Q0MuZmluYRp1bmkwNjM2X2ZhcnNpX3VuaTA2Q0MuZmluYQt1bmkwNjM2MDY0ORB1bmkwNjM2MDY0OS5maW5hC3VuaTA2MzYwNjRBEHVuaTA2MzYwNjRBLmZpbmELdW5pMDYzNjA2MjYQdW5pMDYzNjA2MjYuZmluYQt1bmkwNjM2MDZDQxB1bmkwNjQ2MDY0OS5maW5hEHVuaTA2NDYwNjRBLmZpbmEQdW5pMDY0NjA2MjYuZmluYRB1bmkwNjQ2MDZDQy5maW5hEHVuaTA2NEEwNjRBLmZpbmEQdW5pMDY0QTA2Q0MuZmluYRB1bmkwNjI2MDY0OS5maW5hEHVuaTA2MjYwNjRBLmZpbmEQdW5pMDYyNjA2MjYuZmluYRB1bmkwNjI2MDZDQy5maW5hEHVuaTA2Q0MwNkNDLmZpbmEHdW5pRkRGMgd1bmkwNjZCB3VuaTA2NkMHdW5pMDY2MAd1bmkwNjYxB3VuaTA2NjIHdW5pMDY2Mwd1bmkwNjY0B3VuaTA2NjUHdW5pMDY2Ngd1bmkwNjY3B3VuaTA2NjgHdW5pMDY2OQd1bmkwNkYwB3VuaTA2RjEHdW5pMDZGMgd1bmkwNkYzB3VuaTA2RjQHdW5pMDZGNQd1bmkwNkY2B3VuaTA2RjcHdW5pMDZGOAd1bmkwNkY5DHVuaTA2RjQudXJkdQx1bmkwNkY3LnVyZHUHdW5pMzAwMAd1bmkyMDVGB3VuaTIwMEUHdW5pMjAwRgd1bmkyMDBEB3VuaTIwMEMHdW5pMjAwMQd1bmkyMDAzB3VuaTIwMDAHdW5pMjAwMgd1bmkyMDA1B3VuaTIwMEEHdW5pMjAyRgd1bmkyMDA2B3VuaTIwMDkHdW5pMjAwNAd1bmkyMDBCB3VuaTA2RDQHdW5pMDYwQwd1bmkwNjFCB3VuaTA2MUYHdW5pMDY2RAd1bmlGRDNFB3VuaUZEM0YHdW5pRkRGQwd1bmkwNjZBB3VuaTA2MTUKZG90YWJvdmVhcgpkb3RiZWxvd2FyC2RvdGNlbnRlcmFyFnR3b2RvdHN2ZXJ0aWNhbGFib3ZlYXIWdHdvZG90c3ZlcnRpY2FsYmVsb3dhchh0d29kb3RzaG9yaXpvbnRhbGFib3ZlYXIYdHdvZG90c2hvcml6b250YWxiZWxvd2FyFHRocmVlZG90c2Rvd25hYm92ZWFyFHRocmVlZG90c2Rvd25iZWxvd2FyEnRocmVlZG90c3VwYWJvdmVhchJ0aHJlZWRvdHN1cGJlbG93YXIHd2FzbGFhcgttaW5pS2VoZWhhchFnYWZzYXJrYXNoYWJvdmVhchVnYWZzYXJrYXNoYWJvdmVhci5hbHQSZ2Fmc2Fya2FzaGNlbnRlcmFyB3VuaTA2NzAHdW5pMDY1Ngd1bmkwNjU0B3VuaTA2NTUHdW5pMDY0Qgd1bmkwNjRDB3VuaTA2NEQHdW5pMDY0RQd1bmkwNjRGB3VuaTA2NTAHdW5pMDY1MQt1bmkwNjUxMDY0Qgt1bmkwNjUxMDY0Qwt1bmkwNjUxMDY0RAt1bmkwNjUxMDY0RQt1bmkwNjUxMDY0Rgt1bmkwNjUxMDY1MAt1bmkwNjUxMDY3MAd1bmkwNjUyB3VuaTA2NTMIc2FyZXlhYXIRc2V2ZW5zYW1sbC5ib3R0b20Qc2V2ZW5zbWFsbC5hYm92ZQ55ZWhzYW1sLmJvdHRvbQ15ZWhzbWFsLmFib3ZlB3VuaTAzMDgHdW5pMDMwNwlncmF2ZWNvbWIJYWN1dGVjb21iB3VuaTAzMEIHdW5pMDMwMgd1bmkwMzBDB3VuaTAzMDYHdW5pMDMwQQl0aWxkZWNvbWIHdW5pMDMwNAd1bmkwMzEyB3VuaTAzMjYHdW5pMDMyNwd1bmkwMzI4DHVuaTA2Y2UuZmluYQx1bmkwNmNlLmluaXQMdW5pMDZjZS5tZWRpDHVuaTA2ZDUuZmluYQAAAQACAA4AAAAAAAAANgACAAYAgwCEAAMBNQIbAAECHAJjAAICmAK8AAMCwgLQAAMC0gLVAAEAAQACAAAADAAAABgAAQAEAqoCrAKvArIAAQAVAIMAhAKYAqQCpQKpAqsCrQKuArACsQKzArQCtQK2ArcCuAK5AroCuwK8AAEAAAAKAH4AugADREZMVAAUYXJhYgAYbGF0bgAuAFQAAAAKAAFVUkQgAFAAAP//AAMAAAADAAQALgAHQVpFIAA6Q1JUIAA6S0FaIAA6TU9MIAA6Uk9NIAA6VEFUIAA6VFJLIAA6AAD//wADAAEAAgAEAAD//wADAAAAAgAEAAVrZXJuACBrZXJuACBtYXJrACptYXJrACpta21rADQAAAADAAAAAQACAAAAAwADAAQABQAAAAIABgAHAAgAEgXyFvgZmhpOJ5Qx8DJsAAIACAACAAoEKgABAEQABAAAAB0C5ALkAIIAggLyAIgAtgEYARgBJgGAAYoB/AIKAnwC1gLWAuQC5ALyAvIDCAMOAxwD6gPwBAYEEAQWAAEAHQBCAEMARABFAEYASABLAFEAUgBYAFkAWgBcAF0AXgBhAGMAZABlAGgAaQB3AHgAeQCBAIICcAJ2AncAAQAZ//gACwAE/+gADf/7ABcADQAdAAUAIP/xACH/7wAi//EAJP/yACz/8QAu/+8AMP/1ABgABP/eAAb/8AAK/+0ADf/0ABL/7QAU/+0AHv/gACD/2wAh/9sAIv/bACT/3QAq/+kAK//pACz/2wAt/+kALv/bAC//6QAw/+AAMv/rADP/7wA0//AANv/uADf/6gBLAAAAAwBL/78AVP/3AFf/7wAWAAb/8QAK//AAEv/wABT/8AAe//AAIP/rACH/7AAi/+sAI//zACcAHAAq//EAK//xACz/6wAt//EALv/sAC//8QAw//MAMv/wADP/8wA0/+4ANv/zAFr/8gACAFwABABfAAQAHAAEAAoABv/6AAr/9wAS//cAFP/3ABYABQAe//wAIP/0ACH/9gAi//QAIwAFACcAGwAqAAsAKwALACz/9AAtAAsALv/2AC8ACwAwAAsAMQAJADL/+QAz//sANP/3ADUACQA2//oANwAIAFgABABa//gAAwBZ//IAXP/4AF//7wAcAAQACwAG//UACv/wABL/8AAU//AAFgAFAB7/9gAg/+oAIf/rACL/6gAj//gAJwALACoADQArAA0ALP/qAC0ADQAu/+sALwANADAADQAx//wAMv/zADP/8gA0//EANQAJADb/8QA3AAoAWAAEAFr/7wAWAAb/6AAK/+YAEv/mABT/5gAW//MAF//JABj/5AAZ/9IAGv/cABz/uAAg//MAIv/zACP/8AAs//MAMf/uADP/7AA0//AANv/rAFH/tQBS/7UAYf+8AGP/vAADAEv/tgBU/+gAV//tAAMAGf/eACP/9AAz/+8ABQAZ/+wAG//kACP/9gAz//kANf/tAAEAKf+7AAMAF//rABkABAAc/+cAMwAE//sABf/5AAb/9gAH//kACP/5AAn/+QAK//QAC//5AAz/+QANAAYADv/5AA//+QAQ//kAEf/5ABL/9AAT//kAFP/0ABX/+QAW//0AF//PABj/8wAZ/+QAGv/rABv/+AAc/80AHf/6AB7/8wAf//QAIP/vACH/7wAi/+8AI//wACX/9AAm//QAJ//0ACj/9AAp//QAKv/0ACv/9AAs/+8ALf/0AC7/7wAv//QAMP/yADH/8AAy//EAM//sADT/7wA1//QANv/pADf/8wABABn/+QAFABn/6wAb/+4AI//zADMABAA1/+0AAgJ3AAACeAAAAAECcP+PAAICcAAAAnj/tQACAMgABAAAAOIBBAAEABcAAP/U/94AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD/y/+8AAUABf/4/+cAEf+O//X/9f/sAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA/8v/wwAAAAAAAP/zAAD/y//6AAT/+AAF//X/8v/xAAT/2wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP/KAAAAAAAAAAD/6P/5AAAAAAAAAAD/9/+P//b/+gACAAEACwBCAEMARABFAEYAUQBSAGcAaABpAHEAAgAFAEIAQwABAEYARgACAFEAUgADAGcAaQACAHEAcQACAAIAHQAEAAQADAAGAAYAAwAKAAoABAANAA0ADQASABIABAAUABQABAAWABYADgAXABcAAQAYABgABQAaABoABgAcABwAAgAdAB0ADwAeAB4AEAAgACAAEgAhACEAFAAiACIAEgAkACQAFQAsACwAEgAuAC4AFAAwADAAFgAxADEACQA0ADQACgA2ADYACwA3ADcAEQBCAEMAEwBGAEYABwBRAFIACABnAGkABwBxAHEABwACAAgAAgAKCAAAAQB0AAQAAAA1AJwAxgEIARYBPAFGAdwCMAIwAe4B9AICAjACMAKkAjYCpALGAtwC8gMQAxoDxAPOBDgEWgRoBaoEigSgBMoFLAVWBToFUAVWBVYFfAWqBjIF2AX2BiAGMgZUBs4G8Ac6B1gHcgeEB8oH2AACAAYABAAgAAAAIgAlAB0AKAA3ACEAVABUADEAVwBXADIAagBrADMACgAZ/7IAI//3ADP/9ABI/+kAUP/3AFwACgBe/9gAXwALAGr/5wBr//IAEAAE//kADQAJABcACQAZ//gAGgABABv/9gAc/+sAJP/6ADMAAgA0AAIANQACADYAAgBQAAQAXAAKAF7/6wBf//gAAwAj//wAMwAAAGsABgAJABn/9wAb/+8ANQABAEv/7QBQAAQAWf/yAFz/+wBe/+kAX//yAAIAIwABADMABQAlAAT/8QAGAAUACgAFAA3//gASAAUAFAAFABYABQAbAAIAHv/4ACD/8AAh/+8AIv/wACP//AAk/+sAKv/xACv/8QAs//AALf/xAC7/7wAv//EAMP/xADEABAAy//UAMwAFADT//gA1AAIANv//ADf/+wBC/9kAQ//ZAEb/9QBL/9YAZP/ZAGX/2QBo//UAaf/1AHb/2QAEABn/+QAj//oAM//8AF7/8wABACP/+AADACP/8QAz//MAawAFAAsAGf/LACP/9gAz/+YASP+8AFAABgBcAAUAXv+3AF8ABwBq/7sAa//NAHcAGwABACP/9gAbAAT/8wAN//8AGf/4ABv/7wAc/+wAHQAEAB7/+wAgAAIAIQACACIAAgAkAAIALAACAC4AAgBC/80AQ//NAEYABABL/9kAWf/zAFz/+wBe//AAX//4AGT/zQBl/80AaAAEAGkABAB2/80AgQAEAAgAGf/3ABv/8ABL/+4AUAAEAFn/7wBc//oAXv/oAF//8AAFABn/+AAb//YAXAAIAF7/7QBfAAgABQAZ//kAG//7ACP/9gAz//wANf/5AAcAI//wADP/2AA1/9oAS//QAFT/9gBX//sAawAEAAIAI//4AEv/6wAqAAT/5gAG//gACv/3AA3//gAS//cAFP/3ABb/+AAe/+sAIP/kACH/5gAi/+QAI//3ACT/5gAq/+0AK//tACz/5AAt/+0ALv/mAC//7QAw/+sAMv/yADP/+wA0//gANf/6ADb/+wA3//IAQv/eAEP/3gBE//gARf/4AEb/7ABL/9kAVP/1AFf/9ABk/94AZf/eAGj/7ABp/+wAawAEAHb/3gCB/+oAgv/5AAIAS//iAFcAAwAaAAb/8QAK//AAEv/wABT/8AAe//gAIP/kACH/6wAi/+QAI//1ACT/6gAq//gAK//4ACz/5AAt//gALv/rAC//+AAx//UAMv/sADP/7AA0/+kANv/rAEb/4wBo/+MAaf/jAGsABACB//AACAAj/+cAM//j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AKP/nAABALUCywABAKv/mwABAPQCyAABALL/nAABALoC1AABAbL/nAABAbUDFgABAcv/nAABAbMDFgABALf/nAABALoDUQABALIDbgABAKz/nAABAQMDaQABAKL/nAABALwDXwABAYsDJAABAZ8DIwABALsDWQABAIkDZAABARD+XAABAOcCNwABAOL+WwABAOUCNAABAUz+mgABAL4CIQABAU3+qAABAMYCIQABAPD+WQABAN0CNQABAOz+VQABAN4CGgABAT/+BwABANECHAABAT3+AgABAMkCGwABAPX+SgABANkCNAABAPD+QgABANgCNAABAQf/nAABALwCIQABAPL/nAABALcCIQABALz+WwABANwDJAABANr+WgABAN0DQgABALv/nAABAMcDGQABALb/nAABAMUDIAABAQz/jQABATAChAABAR3/kQABAU0ClwABAQ//lAABAQoDRwABAP3/jQABAU8DYwABATkD6AABAWoECgABAIr+ywABAN8B2AABAHn+0wABALEB2wABAHP+wwABAPYB1AABAKv+7gABALIB5AABAKP+4QABAOkCtQABAKj+3gABAPUCuQABAKL+/QABALMCswABAJf+0gABALgCqAABAOQDQwABAPgDTQABAJz9aAABAJ/9ZwABAJ3+yQABAOcDSAABAJX+4gABAK4DSAABAKj+4gABAPcDSQABAJz+7QABAKgDSAABA0L/nAABA0sB2gABA1//mwABA1MBzQABAWr/nAABAYcB3AABAX7/nAABAYcB3gABA0n/nAABAzgDRQABA03/nAABAzUDOAABAYT/nAABAWgDRAABAXb/nAABAWgDRgABA4n/nAABA+ECAgABA4//nAABA9oB+QABAcP/nAABAhsCAAABAhcCBwABA4P/nAABA9kC5wABA5T/nAABA90C4gABAar/nAABAh4C3QABAbz/nAABAiMC1QABAV3/nAABAisB9gABAWH/nAABAiwB+QABAR3/nAABAf0B5wABAR7/nAABAfsB8AABAUD/nAABAeACzgABAVb/nAABAecCzgABAUj/nAABAb0C0QABATT/nAABAcIC1QABARr99wABARwCHAABAPz+BQABATACKgABASn/nAABASkCKQABAPD/nQABAOwCPwABAMf+GwABASgC9gABANX+FwABATEC6QABASL/nAABASIC/QABAPIC+AABAnkDlAABArYDAAABAOwDCQABAPoDoQABAaL/nAABAmgEJQABAZD/nAABAscDhwABAPv/nAABAPYDgwABALn/nAABAPQEJAABAa//mAABAnICvQABAZz/mAABAssCLAABAPT/nAABAPwCJAABAP0CsAABAV3+tgABAdICBwABAVD+sgABAdECAQABAT7+uwABAdIC0AABAT7+uQABAdYCwAABAPX/nAABAPkC8gABAM3/nAABAOQDhAABAcIC1gABAcoC0gABAK8DCwABAKsDDgABAaX/mQABAgECvQABAg8CrgABAiD/nAABASYCFAABAbj/mQABAg4CsgABAiL/nAABARICBAABANn/mQABAKADEgABAVL/mwABAH8CpgABAMr/mgABAKMDAwABAJf/mgABAJQDAgABATD/nAABAJMCxAABAav/mAABAeYDPAABAbr/mAABAd8DRQABAi7/nAABAPQCnwABAc//mAABAeQDPQABAfX/nAABAN8CnAABAM3/mQABAH4DgAABAX//nAABAFQDAgABAHv/mQABAGEDYAABAH//mQABAIQDbwABAS//nAABAF4DHwABAW3+3gABASUBlwABAWP+5AABASUBnwABAKf/nAABAKoDFgABAIb/nAABAJsDIwABAQ4CMQABASEBxQABALUEPQABAJ4ETgABAYr/tgABAVICAAABAb//nAABAXIB8gABARn/nAABARsB+AABARb/nAABARoCBQABAWv+2gABAWMCRwABAVD+5wABAWgCSgABAL7/nAABAMkCngABAJD/nAABAMsCxwABAWz+1AABAWcBvQABAWv+0AABAWcB0gABAQD/mgABAPkCTAABAO3/zgABAPACcwABAQX+8wABAQcB6wABATACdQABAOkD8QABANcEBgABAPH/nAABANwCUQABARD/yQABATUBvAABAQz+ygABAQ8BlwABAIr97wABAJoB/gABAOYD3AABAP8D1AABAVH/nAABAR8CdAABAUT+lQABATACAgABAY//mgABAVgCVwABAUn/nAABAVwCbQABAPD/nAABAOkDKAABAP7/zgABAPMDcgABAQT/nAABAQIDMQABART/vQABAS0ChwABAPX+xQABAPkB/QABAP7+wwABAPgCDgABAPUDcwABAQ8DiAABAP8DTwABAP4DQwABAPMDfwABAPADnAABAWj+vAABAMUBnwABAWX+lwABAXcBLAABAXj+DAABANABlwABAXL96AABAV8BJwABAUT9yQABAUEA+AABALf+twABALIB3gABAKj+uAABALYB8wABANn+owABAMEB8QABAMf+oQABALoBzwABAM8DKwABAPcDHQABAOMCdgABAL//nAABAM8DegABAJP/nAABAKcDzQABAK//nAABALcDhAABALACxAABAXT+ygABAMoBrwABAWj+mAABAYwBJwABAU7+iwABASoBCQABAL3+qAABAMkB3QABAKP+rAABALQCCAABAN7+oQABAL0B6AABALf+pQABAMwB4wABATYCLAABATYA7wABAWcDegABAWgDiwABAFn/nAABAFMBQAAFAAAAAQAIAAEADAAoAAIAMgCYAAIABACDAIQAAAKYApgAAgKkAqUAAwKpArwABQACAAECHAJiAAAAGQABC2wAAQtsAAELeAABC3gAAQt4AAELeAAACmYAAQt4AAAKZgABC3gAAQtyAAAKZgABC3gAAQt4AAAKZgABC3gAAQt4AAELeAABC3gAAQt4AAELeAABC3gAAQt4AAELeAABC3gARwCQALIA1AD2ARgBOgFcAX4BoAHCAeQCBgIoAkoCbAKOArAC0gLuAxADMgNUA3YDmAO6A9wD/gQgBEIEZASGBKIExATgBQIFJAVGBWIFhAWmBcgF6gYMBi4GSgZsBogGpAbABtwG+AcaBzYHWAd6B5wHvgfgCAIIJAhGCGgIigisCM4I8AkSCTQJVgl4CZoAAgAKABAAFgAcAAEBmf+1AAEBwwNIAAEAd/90AAEAagLXAAIACgAQABYAHAABAar/sAABAdcDIgABAHL/fAABAG4C0QACAAoAEAAWABwAAQGZ/7kAAQHVAy4AAQBn/4MAAQCKBBsAAgAKABAAFgAcAAEB0f+yAAEB3QNDAAEAlv+CAAEAkgQ6AAIACgAQABYAHAABAdH/pwABAc0DKAABAMP+NQABAH0CwwACAAoAEAAWABwAAQH//5wAAQHUAzcAAQDi/icAAQB7As8AAgAKABAAFgAcAAEByP/KAAEB+gM/AAEAkv9yAAEApwOdAAIACgAQABYAHAABAcz/sQABAfADQAABAJr/bQABALEDoAACAAoAEAAWABwAAQGt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AAMBiwGKAYkAAwGPAY4BjQADAZMBkgGRAAMBlwGWAZUAAwGbAZoBmQADAZ8BngGdAAMBowGiAaEAAwGnAaYBpQADAasBqgGpAAMBrwGuAa0AAwGzAbIBsQABAbUAAwG5AbgBtwAFAb0BvAG7AcABvwAFAcUBwwHBAcABvwABAcAAAQHCAAEBxAACAccBxgABAccABQHPAc0BywHKAckAAQHMAAEBzgACAdEB0AADAdUB1AHTAAMB2QHYAdcAAwHdAdwB2wADAeEB4AHfAAEB4wADAecB5gHlAAEB6QADAe0B7AHrAAEB7wADAfMB8gHxAAEB9QABAfcAAQH5AAEB+wABAgEAAwIGAgUCAwABAgQAAgIIAgcAAwINAgwCCgABAgsAAQIOAAMC0wLUAtIAAwIUAhMCEQABAhIAAgIWAhUAAQIYAAECGgABAh0AAQIfAAECIQABAiMAAQIrAAECOQABAjsAAQI9AAECQQABAkMAAQJFAAECSQABAksAAQJNAAECUgABAlQAAQJWAAECegABAmwAAQJ7AAEAbQAmAMMAyAEcASEBNgE4AToBPAE+AUABRwFKAUwBTwFSAVUBWAFbAV4BYgFmAWoBbgFyAXQBdgF4AXoBfAF9AYABggGEAYYBiAGMAZABlAGYAZwBoAGkAagBrAGwAbQBtgG6AbsBvAG9Ab4BvwHBAcMBxQHGAcgBywHNAc8B0gHWAdoB3gHiAeQB6AHqAe4B8AH0AfYB+AH6AgACAgIDAgYCCQIKAg0CDwIQAhECFAIXAhkCHAIeAiACIgIkAjgCOgI8AkACQgJEAkgCSgJMAlECUwJVAnQCdgJ3AAYAAAACAAoAHAADAAAAAQisAAEALgABAAAADgADAAAAAQiaAAIAFAAcAAEAAAAOAAEAAgLPAtAAAgABAsICzQAAAAQAAAABAAgAAQCWAAgAFgAgACoANAA+AEgAUgBcAAEABAK6AAICswABAAQCtAACArMAAQAEArUAAgKzAAEABAK2AAICswABAAQCtwACArMAAQAEArgAAgKzAAEABAK5AAICswAHABAAFgAcACIAKAAuADQCugACAqkCtAACAq0CtQACAq4CtgACAq8CtwACArACuAACArECuQACArIAAgACAqkCqQAAAq0CswABAAEAAAABAAgAAQe+ANkAAQAAAAEACAABAAYAAQABAAQAwwDIARwBIQABAAAAAQAIAAIADAADAnoCbAJ7AAEAAwJ0AnYCdwABAAAAAQAIAAIApAAkAUMBSgFPAVUBWwFhAWUBaQFtAXEBiwGPAZMBlwGbAZ8BowGnAasBrwGzAbkBvQHFAc8B1QHZAd0B4QHnAe0B8wIGAg0C0wIUAAEAAAABAAgAAgBOACQBQgFJAU4BVAFaAWABZAFoAWwBcAGKAY4BkgGWAZoBngGiAaYBqgGuAbIBuAG8AcMBzQHUAdgB3AHgAeYB7AHyAgUCDALUAhMAAQAkAUABRwFMAVIBWAFeAWIBZgFqAW4BiAGMAZABlAGYAZwBoAGkAagBrAGwAbYBugG+AcgB0gHWAdoB3gHkAeoB8AICAgkCDwIQAAEAAAABAAgAAgCgAE0BNwE5ATsBPQE/AUEBSAFNAVMBWQFfAWMBZwFrAW8BcwF1AXcBegF9AYEBgwGGAYkBjQGRAZUBmQGdAaEBpQGpAa0BsQG1AbcBuwHBAcsB0wHXAdsB3wHjAeUB6QHrAe8B8QH1AfcB+QH7AgECAwIKAtICEQIYAhoCHQIfAiECIwIrAjkCOwI9AkECQwJFAkkCSwJNAlICVAJWAAEATQE2ATgBOgE8AT4BQAFHAUwBUgFYAV4BYgFmAWoBbgFyAXQBdgF4AXwBgAGCAYQBiAGMAZABlAGYAZwBoAGkAagBrAGwAbQBtgG6Ab4ByAHSAdYB2gHeAeIB5AHoAeoB7gHwAfQB9gH4AfoCAAICAgkCDwIQAhcCGQIcAh4CIAIiAiQCOAI6AjwCQAJCAkQCSAJKAkwCUQJTAlUABAAIAAEACAABAGAAAwCaAAwANgAFAAwAEgAYAB4AJAIdAAIBNwIfAAIBOQIhAAIBOwIjAAIBPQIrAAIBPwAFAAwAEgAYAB4AJAIcAAIBNwIeAAIBOQIgAAIBOwIiAAIBPQIkAAIBPwABAAMBNgHUAdUABAAJAAEACAABAh4AEQAoADYAWAB6AJwAvgDgAQIBJAFGAWgBigGkAcYB6AHyAhQAAQAEAmMABAHVAdQB5QAEAAoAEAAWABwCJwACAgECKAACAgMCKQACAgoCKgACAhEABAAKABAAFgAcAiwAAgIBAi0AAgIDAi4AAgIKAi8AAgIRAAQACgAQABYAHAIwAAICAQIxAAICAwIyAAICCgIzAAICEQAEAAoAEAAWABwCNAACAgECNQACAgMCNgACAgoCNwACAhEABAAKABAAFgAcAjkAAgIBAjsAAgIDAj0AAgIKAj8AAgIRAAQACgAQABYAHAI4AAICAQI6AAICAwI8AAICCgI+AAICEQAEAAoAEAAWABwCQQACAgECQwACAgMCRQACAgoCRwACAhEABAAKABAAFgAcAkAAAgIBAkIAAgIDAkQAAgIKAkYAAgIRAAQACgAQABYAHAJJAAICAQJLAAICAwJNAAICCgJPAAICEQAEAAoAEAAWABwCSAACAgECSgACAgMCTAACAgoCTgACAhEAAwAIAA4AFAJSAAICAQJUAAICAwJWAAICCgAEAAoAEAAWABwCUQACAgECUwACAgMCVQACAgoCVwACAhEABAAKABAAFgAcAlgAAgIBAlkAAgIDAloAAgIKAlsAAgIRAAEABAJdAAICEQAEAAoAEAAWABwCXgACAgECXwACAgMCYAACAgoCYQACAhEAAQAEAmIAAgIRAAEAEQE2AUkBTgFUAVoBigGLAY4BjwGSAZMBlgGXAeACBQIMAhMAAQAJAAEACAACACgAEQHAAcIBxAHHAcABwAHCAcQBxwHHAcoBzAHOAdECBAILAhIAAQARAboBuwG8Ab0BvgG/AcEBwwHFAcYByAHLAc0BzwIDAgoCEQABAAkAAQAIAAIAIgAOAcABwgHEAccBwAHAAcIBxAHHAccBygHMAc4B0QABAA4BugG7AbwBvQG+Ab8BwQHDAcUBxgHIAcsBzQHPAAYACQAKABoAPABWAHIAmAC+AQABIgFgAZoAAwABABIAAQHsAAAAAQAAAA8AAgACAXgBfwAAAYQBhwAIAAMAAAABAfAAAQASAAEAAAAQAAEAAgGGAYcAAwAAAAEB1gABABIAAQAAABEAAQADAVQBWgIMAAMAAAABABIAAQAcAAEAAAARAAEAAwFPAgYCFAABAAMBTgIFAhMAAwABABIAAQGUAAAAAQAAABIAAQAIATwBPQE+AT8CIgIjAiQCKwADAAAAAQB2AAEAEgABAAAAEgABABYBNgE4AToBPAE+AUoBSwFPAVEBVQFWAVsBXAHhAfgB+QIGAggCDQIOAhQCFgADAAAAAQA0AAEAEgABAAAAEgABAAYBeAF5AXwBfwGEAYUAAwAAAAEAEgABACIAAQAAABIAAQAGAXgBegF8AX0BhAGGAAEADAFiAWYBagFuAaABpAG2Ad4CAAICAgkCEAADAAEAEgABAC4AAAABAAAAEgACAAQBNgE/AAABhAGHAAoCHAIkAA4CKwIrABcAAQAEAb4BxQHIAc8AAwABABIAAQA0AAAAAQAAABIAAgAFATYBPwAAAXwBfwAKAYQBhwAOAhwCJAASAisCKwAbAAEAAgG6Ab0AAQAAAAEACAABAAYA1QABAAEAJgABAAkAAQAIAAIAFAAHAUsBUQFWAVwCCAIOAhYAAQAHAUoBTwFVAVsCBgINAhQAAQAJAAEACAACAAwAAwFXAV0CDgABAAMBVQFbAg0AAQAJAAEACAABAAYAAQABAAYBTwFVAVsCBgINAhQAAQAJAAEACAACACQADwFXAV0BeQF7AX8BfgGFAYcBvwHGAb8BxgHJAdACDgABAA8BVQFbAXgBegF8AX0BhAGGAboBvQG+AcUByAHPAg0AAAAAAAEAAAAA
) format("truetype");
    font-weight: 700; font-style: normal; font-display: swap;
}
* { font-family: "PeydaReport", "Peyda", "IRANSans", "Tahoma", "Arial", sans-serif !important; box-sizing: border-box; }
:root{
  --accent:#16509D; --accent-dark:#0e3a73; --accent-light:#5b85bc; --accent-lighter:#a9c2de;
  --border:#e3e6ea; --muted:#666; --zebra:#f5f5f5; --bg:#f4f6f9;
}
html,body{ margin:0; padding:0; background:var(--bg); color:#000; font-size:14px; direction:rtl; }
#reportRoot{ max-width:1400px; margin:0 auto; padding:18px; }
/* تمام‌صفحه = CSS-only (نه Fullscreen API واقعی) — تأییدشدهٔ زندهٔ 1405/05/26: روی موبایل (Android
   Chrome، و/یا داخل iframe پنل Teamyar که ممکن است allow="fullscreen" نداشته باشد) دکمهٔ «تمام صفحه»
   واقعی مرورگر باز می‌شد ولی محتوا اسکرول نمی‌شد — راه‌حل قابل‌اتکاتر و مستقل از پلتفرم/iframe: به‌جای
   Element.requestFullscreen()، فقط یک کلاس CSS اضافه/حذف می‌شود که عنصر را با position:fixed تمام صفحه
   می‌کند؛ اسکرول از طریق overflow-y:auto معمولی خودِ صفحه کار می‌کند، نه رفتار ویژهٔ حالت Fullscreen. */
#reportRoot.pseudo-fullscreen{
  position:fixed; inset:0; z-index:9999; overflow-y:auto; background:var(--bg); max-width:100%; margin:0;
}
.toolbar{ display:flex; justify-content:flex-end; gap:8px; margin-bottom:12px; flex-wrap:wrap; }
.btn-toolbar{ background:var(--accent); color:#fff; border:none; border-radius:8px; padding:9px 18px; font-size:14px; font-weight:bold; cursor:pointer; }
.btn-toolbar:hover{ filter:brightness(0.9); }
.btn-toolbar.secondary{ background:#fff; color:var(--accent); border:1.5px solid var(--accent); }
header.hero{ position:relative; background:linear-gradient(135deg,var(--accent),var(--accent-dark)); color:#fff; border-radius:14px; padding:22px 26px; margin-bottom:16px; }
header.hero h1{ margin:0 0 6px; font-size:19px; max-width:calc(100% - 90px); }
header.hero .sub{ margin:0; font-size:14px; opacity:.92; max-width:calc(100% - 90px); }
header.hero .brand140-logo{ position:absolute; top:18px; left:22px; height:34px; width:auto; }
@media(max-width:600px){ header.hero .brand140-logo{ position:static; display:block; margin-bottom:10px; } header.hero h1, header.hero .sub{ max-width:100%; } }
.filter-bar{ background:#fff; border:1px solid var(--border); border-radius:12px; padding:14px 18px; margin-bottom:16px; display:flex; gap:12px; flex-wrap:wrap; align-items:flex-end; }
.channel-tabs{ display:flex; gap:8px; width:100%; margin-bottom:6px; flex-wrap:wrap; }
.channel-tab{ background:var(--zebra); color:#000; border:1.5px solid transparent; border-radius:20px; padding:8px 18px; font-size:14px; font-weight:bold; cursor:pointer; }
.channel-tab:hover{ border-color:var(--accent-lighter); }
.channel-tab.active{ background:var(--accent); color:#fff; }
.channel-tab.minor{ font-weight:normal; opacity:.7; padding:8px 14px; }
.channel-tab.minor.active{ background:#888; opacity:1; }
.filter-field{ display:flex; flex-direction:column; gap:4px; min-width:150px; }
.filter-field label{ font-size:14px; color:var(--muted); }
.filter-field input, .filter-field select{ font-size:14px; padding:8px 10px; border:1px solid var(--border); border-radius:8px; background:#fff; }
.filter-actions{ display:flex; gap:8px; }
.btn-primary{ background:var(--accent); color:#fff; border:none; border-radius:8px; padding:9px 20px; font-size:14px; font-weight:bold; cursor:pointer; }
.btn-secondary{ background:#fff; color:var(--accent); border:1.5px solid var(--accent); border-radius:8px; padding:9px 20px; font-size:14px; font-weight:bold; cursor:pointer; }
.kpi-grid{ display:grid; grid-template-columns:repeat(auto-fit,minmax(190px,1fr)); gap:12px; margin-bottom:18px; }
.kpi-card{ background:#fff; border:1px solid var(--border); border-radius:12px; padding:14px 16px; }
.kpi-card .label{ font-size:14px; color:var(--muted); margin-bottom:6px; }
.kpi-card .value{ font-size:22px; font-weight:bold; color:var(--accent); }
.kpi-card .sub{ font-size:14px; color:var(--muted); margin-top:4px; }
.kpi-card.warn .value{ color:#a33; }
.kpi-card.clickable{ cursor:pointer; transition:box-shadow .15s,transform .15s; }
.kpi-card.clickable:hover{ box-shadow:0 2px 10px rgba(22,80,157,.18); transform:translateY(-1px); border-color:var(--accent); }
.section{ background:#fff; border:1px solid var(--border); border-radius:14px; padding:18px; margin-bottom:16px; }
.section-head{ margin-bottom:12px; }
.section-head h2{ font-size:15px; font-weight:bold; margin:0 0 4px; display:flex; align-items:center; gap:8px; }
.section-head h2 .num{ background:var(--accent); color:#fff; border-radius:50%; width:24px; height:24px; display:inline-flex; align-items:center; justify-content:center; font-size:14px; }
.section-head p{ margin:0; font-size:14px; color:var(--muted); }
.grid-2{ display:grid; grid-template-columns:1fr 1fr; gap:16px; }
@media(max-width:900px){ .grid-2{ grid-template-columns:1fr; } }
.card{ border:1px solid var(--border); border-radius:12px; padding:14px; background:#fff; }
.card h3{ font-size:15px; font-weight:bold; margin:0 0 4px; }
.card .desc{ font-size:14px; color:var(--muted); margin-bottom:10px; }
.chart-box{ position:relative; width:100%; }
.minmax-grid{ display:grid; grid-template-columns:repeat(auto-fit,minmax(210px,1fr)); gap:12px; }
.minmax-card{ border:1px solid var(--border); border-radius:10px; padding:12px 14px; background:var(--zebra); }
.minmax-card .t{ font-size:14px; color:var(--muted); margin-bottom:6px; }
.minmax-card .n{ font-size:15px; font-weight:bold; }
.minmax-card .v{ font-size:14px; color:var(--accent); font-weight:bold; }
table.data-table{ width:auto; min-width:100%; border-collapse:collapse; }
table.data-table th, table.data-table td{ padding:8px 10px; border-bottom:1px solid var(--border); text-align:right; font-size:14px; white-space:nowrap; width:1%; }
table.data-table thead th{ background:var(--zebra); font-weight:bold; font-size:15px; cursor:pointer; user-select:none; position:sticky; top:0; }
table.data-table thead th:hover{ background:var(--accent-lighter); }
table.data-table thead th.sort-asc::after{ content:" ▲"; }
table.data-table thead th.sort-desc::after{ content:" ▼"; }
table.data-table tbody tr:nth-child(even){ background:var(--zebra); }
table.data-table tbody tr.clickable{ cursor:pointer; }
table.data-table tbody tr.clickable:hover{ background:var(--accent-lighter); }
.table-scroll{ overflow-x:auto; }
.badge{ display:inline-block; background:var(--accent); color:#fff; border-radius:6px; padding:2px 8px; font-size:14px; }
.badge.gray{ background:#eee; color:#000; }
.pill{ display:inline-block; border:1px solid var(--border); border-radius:20px; padding:4px 12px; font-size:14px; margin-left:6px; background:#fff; }
a.link{ color:var(--accent); text-decoration:none; font-weight:bold; }
a.link:hover{ text-decoration:underline; }
.search-box{ margin-bottom:10px; }
.search-box input{ width:100%; max-width:320px; padding:8px 10px; border:1px solid var(--border); border-radius:8px; font-size:14px; }
.drill-panel{ border:1.5px solid var(--accent); border-radius:12px; padding:14px; margin-top:14px; background:#fbfcfe; }
.drill-panel .head{ display:flex; justify-content:space-between; align-items:center; margin-bottom:10px; flex-wrap:wrap; gap:8px; }
.drill-panel .head h4{ margin:0; font-size:15px; font-weight:bold; }
.close-btn{ background:none; border:1px solid var(--border); border-radius:8px; padding:5px 12px; cursor:pointer; font-size:14px; }
.pager{ display:flex; gap:8px; align-items:center; margin-top:10px; font-size:14px; }
.pager button{ background:var(--accent); color:#fff; border:none; border-radius:6px; padding:6px 14px; cursor:pointer; font-size:14px; }
.pager button:disabled{ background:#ccc; cursor:not-allowed; }
.loading-row{ text-align:center; color:var(--muted); padding:16px; }
.empty-row{ text-align:center; color:var(--muted); padding:16px; }
.error-row{ text-align:center; color:#a33; padding:16px; }
.tooltip-box{ position:fixed; background:#000; color:#fff; font-size:14px; padding:6px 10px; border-radius:6px; pointer-events:none; z-index:9999; display:none; white-space:nowrap; }
footer{ text-align:center; font-size:14px; color:var(--muted); padding:16px 0; }
.modal{ display:none; position:fixed; inset:0; background:rgba(0,0,0,.45); z-index:10000; align-items:center; justify-content:center; }
.modal.active{ display:flex; }
.modal-content{ background:#fff; border-radius:14px; max-width:640px; width:92%; max-height:82vh; overflow-y:auto; padding:0; }
.modal-header{ display:flex; justify-content:space-between; align-items:center; padding:16px 20px; border-bottom:1px solid var(--border); }
.modal-header h3{ margin:0; font-size:15px; font-weight:bold; }
.modal-close{ background:none; border:none; font-size:20px; cursor:pointer; color:var(--muted); }
.modal-body{ padding:16px 20px; font-size:14px; line-height:1.9; }
.modal-body h4{ font-size:15px; font-weight:bold; margin:14px 0 6px; }
.modal-body ul{ margin:6px 0; padding-inline-start:20px; }
.barlist{ display:flex; flex-direction:column; gap:8px; max-height:520px; overflow-y:auto; }
.bar-row, .combo-row{ display:grid; grid-template-columns:110px 1fr 110px; align-items:center; gap:8px; cursor:pointer; padding:2px 0; }
.combo-row{ grid-template-columns:110px 1fr; }
.bar-label{ font-size:14px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.bar-track{ background:var(--zebra); border-radius:6px; height:16px; overflow:hidden; }
.bar-track.thin{ height:10px; margin-bottom:3px; }
.bar-fill{ height:100%; border-radius:6px; transition:width .3s; }
.bar-value{ font-size:14px; text-align:left; }
.combo-tracks{ display:flex; flex-direction:column; justify-content:center; }
.combo-legend{ display:flex; gap:16px; margin-bottom:10px; font-size:14px; }
.combo-legend .sw, .donut-legend .sw{ display:inline-block; width:12px; height:12px; border-radius:3px; margin-inline-end:6px; vertical-align:middle; }
.donut-wrap{ display:flex; align-items:center; gap:18px; flex-wrap:wrap; justify-content:center; }
.donut{ width:180px; height:180px; border-radius:50%; position:relative; flex:none; }
.donut-hole{ position:absolute; inset:32px; background:#fff; border-radius:50%; }
.donut-legend{ display:flex; flex-direction:column; gap:6px; max-height:220px; overflow-y:auto; }
.donut-legend .legend-row{ display:flex; align-items:center; gap:6px; font-size:14px; cursor:pointer; padding:2px 4px; border-radius:6px; }
.donut-legend .legend-row:hover{ background:var(--zebra); }
.donut-legend .ln{ flex:1; }
.donut-legend .lv{ font-weight:bold; color:var(--accent); }
</style>
]]

-- ============================================================
-- RENDER: KPI CARDS
-- ============================================================

-- کارت‌های KPI بالای صفحه Clickable هستند (طبق درخواست کاربر v02) — کلیک هرکدام به بخش مرتبط
-- (جدول استان‌ها یا فهرست شهرها) Scroll می‌کند؛ برای کارت‌های شهر، فهرست کامل شهرها هم باز می‌شود.
local function render_kpi_cards(crm_kpi, sales_kpi, coverage)
    local html = {}
    local function card(label, value, sub, target, expand_cities)
        local onclick = target and (' onclick="scrollToKpiTarget(\'' .. target .. '\',' .. (expand_cities and 'true' or 'false') .. ')"') or ''
        local cls = target and 'kpi-card clickable' or 'kpi-card'
        table.insert(html, '<div class="' .. cls .. '"' .. onclick .. '><div class="label">' ..
            escape_html(label) .. '</div><div class="value">' .. value .. '</div>' ..
            (sub and ('<div class="sub">' .. sub .. '</div>') or '') .. '</div>')
    end
    card("تعداد کل مشتریان CRM", fmt_num(crm_kpi.total_crm_customers), nil, "stateSection", false)
    card("تعداد مشتریان خریدار", fmt_num(sales_kpi.buyer_customers),
        fmt_dec1(fmt_pct(sales_kpi.buyer_customers, crm_kpi.total_crm_customers)) .. "٪ از کل مشتریان", "stateSection", false)
    card("تعداد کل فاکتورهای فروش", fmt_num(sales_kpi.total_valid_invoices), nil, "stateSection", false)
    card("مبلغ کل فروش", fmt_num(sales_kpi.total_sales_amount) .. " ریال", nil, "chartsSection", false)
    card("استان‌های دارای مشتری", fmt_num(crm_kpi.states_with_customers), nil, "stateSection", false)
    card("استان‌های دارای فروش", fmt_num(sales_kpi.states_with_sales), nil, "stateSection", false)
    card("شهرهای دارای مشتری", fmt_num(crm_kpi.cities_with_customers), nil, "citySection", true)
    card("شهرهای دارای فروش", fmt_num(sales_kpi.cities_with_sales), nil, "citySection", true)
    card("پوشش جغرافیایی فروش", fmt_dec1(coverage.pct) .. "٪",
        fmt_num(coverage.cities_with_sales) .. " از " .. fmt_num(coverage.total_cities) .. " شهر مرجع", "citySection", true)
    return table.concat(html)
end

-- کارت‌های کیفیت داده Clickable‌اند و فهرست واقعی مشتری/فاکتور مربوطه را در یک Modal باز می‌کنند
-- (Lazy AJAX — action=dq_customers/dq_invoices، طبق درخواست کاربر v02)
local function render_data_quality_cards(crm_kpi, sales_kpi)
    local html = {}
    local function card(label, value, onclick)
        table.insert(html, '<div class="kpi-card warn clickable" onclick="' .. onclick .. '"><div class="label">' .. escape_html(label) ..
            '</div><div class="value">' .. value .. '</div></div>')
    end
    card("مشتریان بدون استان", fmt_num(crm_kpi.customers_without_state), "openDataQualityCustomers('state',0)")
    card("مشتریان بدون شهر", fmt_num(crm_kpi.customers_without_city), "openDataQualityCustomers('city',0)")
    card("فاکتورهای بدون نگاشت جغرافیایی", fmt_num(sales_kpi.invoices_without_geo_mapping), "openDataQualityInvoices(0)")
    return table.concat(html)
end

-- کارت‌های «مشتریان جدید» (v04) — تعداد مشتریانی که اولین فاکتورشان در این بازه/دسته افتاده + مجموع خرید و اقلام آن‌ها
local function render_new_customers_cards(stats)
    if stats == nil then return "" end
    local html = {}
    local function card(label, value)
        table.insert(html, '<div class="kpi-card"><div class="label">' .. escape_html(label) ..
            '</div><div class="value">' .. value .. '</div></div>')
    end
    card("مشتریان جدید در این بازه", fmt_num(stats.new_customer_count))
    card("مجموع خرید مشتریان جدید", fmt_num(stats.new_customer_amount) .. " ریال")
    card("تعداد اقلام خریداری‌شده (جدید)", fmt_num(stats.new_customer_qty))
    return table.concat(html)
end

-- جدول ۱۰ مشتری برتر (v04) — هر تب دستهٔ خودش را نشان می‌دهد
local function render_top_customers_rows(list)
    local html = {}
    for i, c in ipairs(list) do
        table.insert(html, '<tr class="clickable" data-crmid="' .. c.crm_id .. '" onclick="openInvoiceDrill(' .. c.crm_id .. ')"><td>' ..
            i .. '</td><td>' .. escape_html(c.customer_name) .. '</td><td>' .. escape_html(safe_str(c.state_name, "—")) ..
            '</td><td>' .. escape_html(safe_str(c.city_name, "—")) .. '</td><td>' .. fmt_num(c.invoice_count) .. '</td><td>' ..
            fmt_num(c.total_purchase_amount) .. '</td></tr>')
    end
    return table.concat(html)
end

-- جدول مقایسهٔ مراکز درآمد خام (v04) — فقط در تب «همه»
local function render_center_comparison_rows(list)
    local html = {}
    local total = 0
    for _, c in ipairs(list) do total = total + c.total_amount end
    for _, c in ipairs(list) do
        table.insert(html, '<tr><td>' .. escape_html(c.center_name) .. '</td><td>' .. fmt_num(c.invoice_count) ..
            '</td><td>' .. fmt_num(c.customer_count) .. '</td><td>' .. fmt_num(c.total_amount) .. '</td><td>' ..
            fmt_dec1(fmt_pct(c.total_amount, total)) .. '٪</td></tr>')
    end
    return table.concat(html)
end

local function render_minmax_cards(mm)
    if mm == nil then return "" end
    local html = {}
    local function card(title, s, valuefmt)
        if s == nil then
            table.insert(html, '<div class="minmax-card"><div class="t">' .. escape_html(title) ..
                '</div><div class="n">—</div></div>')
        else
            table.insert(html, '<div class="minmax-card"><div class="t">' .. escape_html(title) ..
                '</div><div class="n">' .. escape_html(s.state_name) .. '</div><div class="v">' .. valuefmt(s) .. '</div></div>')
        end
    end
    card("استان با بیشترین مبلغ فروش", mm.max_sales, function(s) return fmt_num(s.total_sales_amount) .. " ریال" end)
    card("استان با کمترین مبلغ فروش (در میان استان‌های دارای فروش)", mm.min_sales, function(s) return fmt_num(s.total_sales_amount) .. " ریال" end)
    card("استان با بیشترین تعداد فاکتور", mm.max_invoices, function(s) return fmt_num(s.invoice_count) .. " فاکتور" end)
    card("استان با کمترین تعداد فاکتور (در میان استان‌های دارای فروش)", mm.min_invoices, function(s) return fmt_num(s.invoice_count) .. " فاکتور" end)
    card("استان با بیشترین مشتری خریدار", mm.max_buyers, function(s) return fmt_num(s.buyer_count) .. " مشتری" end)
    card("استان با کمترین مشتری خریدار (در میان استان‌های دارای فروش)", mm.min_buyers, function(s) return fmt_num(s.buyer_count) .. " مشتری" end)
    table.insert(html, '<div class="minmax-card"><div class="t">استان‌های بدون هیچ فروش</div><div class="n">' ..
        fmt_num(mm.states_without_sales_count) .. ' استان</div></div>')
    return table.concat(html)
end

-- ============================================================
-- RENDER: TABLES
-- ============================================================

local function render_state_table_rows(states)
    local html = {}
    for _, s in ipairs(states) do
        table.insert(html, '<tr class="clickable" data-state="' .. escape_html(s.state_name) .. '"><td>' ..
            escape_html(s.state_name) .. '</td><td>' .. fmt_num(s.unique_customer_count) .. '</td><td>' ..
            fmt_num(s.buyer_count) .. '</td><td>' .. fmt_num(s.invoice_count) .. '</td><td>' ..
            fmt_num(s.total_sales_amount) .. '</td><td>' .. fmt_num(s.avg_invoice_amount) .. '</td><td>' ..
            fmt_num(s.avg_sales_per_buyer) .. '</td><td>' .. fmt_num(s.city_count_with_customers) .. '</td><td>' ..
            fmt_num(s.city_count_with_sales) .. '</td><td>' .. fmt_dec1(s.sales_share_pct) .. '٪</td><td>' ..
            fmt_dec1(s.customer_share_pct) .. '٪</td></tr>')
    end
    return table.concat(html)
end

local function render_city_table_rows(cities, limit)
    local html = {}
    for i, c in ipairs(cities) do
        if limit ~= nil and i > limit then break end
        table.insert(html, '<tr class="clickable" data-state="' .. escape_html(c.state_name) .. '" data-city="' ..
            escape_html(c.city_name) .. '"><td>' .. escape_html(c.state_name) .. '</td><td>' ..
            escape_html(c.city_name) .. '</td><td>' .. fmt_num(c.unique_customer_count) .. '</td><td>' ..
            fmt_num(c.buyer_count) .. '</td><td>' .. fmt_num(c.invoice_count) .. '</td><td>' ..
            fmt_num(c.total_sales_amount) .. '</td><td>' .. fmt_num(c.avg_invoice_amount) .. '</td><td>' ..
            fmt_dec1(c.sales_share_pct) .. '٪</td></tr>')
    end
    return table.concat(html)
end

-- ============================================================
-- RENDER: FILTER BAR
-- ============================================================

-- تفکیک B2B/B2C (v03) — طبق درخواست کاربر: کل داشبورد را بین «همه»/B2B/B2C جابه‌جا می‌کند؛ «سایر» هم
-- (مراکز درآمدی که نه «همکار»‌اند نه «مصرف‌کننده» — حجم ناچیز، ر.ک. یادداشت CHANNEL_* در CONFIG) به‌جای
-- حذف‌شدن، به‌صورت یک گزینهٔ کم‌رنگ‌تر در دسترس می‌ماند.
local function render_channel_tabs(filters)
    local html = { '<div class="channel-tabs">' }
    local function tab(value, label, extra_class)
        local active = (filters.channel == value) or (value == "" and filters.channel == nil)
        html[#html + 1] = '<button type="button" class="channel-tab' .. (active and ' active' or '') ..
            (extra_class or '') .. '" data-channel="' .. escape_html(value) .. '" onclick="setActiveChannel(this)">' ..
            escape_html(label) .. '</button>'
    end
    tab("", "همه")
    tab("b2b", "B2B (همکار)")
    tab("b2c", "B2C (مصرف‌کننده)")
    tab("other", "سایر", " minor")
    html[#html + 1] = '</div>'
    return table.concat(html)
end

local function render_filter_bar(filters, default_date_from, default_date_to, state_options, user_type_options)
    local html = {}
    table.insert(html, '<form id="filterForm" class="filter-bar">')
    table.insert(html, '<input type="hidden" name="channel" id="channelInput" value="' .. escape_html(filters.channel or "") .. '">')
    table.insert(html, render_channel_tabs(filters))
    table.insert(html, '<div class="filter-field"><label>تاریخ از (شمسی)</label><input type="text" name="date_from" id="dateFromInput" placeholder="1405/01/01" value="' ..
        escape_html(filters.date_from_text or default_date_from) .. '"></div>')
    table.insert(html, '<div class="filter-field"><label>تاریخ تا (شمسی)</label><input type="text" name="date_to" id="dateToInput" placeholder="' ..
        escape_html(default_date_to) .. '" value="' .. escape_html(filters.date_to_text or "") .. '"></div>')
    table.insert(html, '<div class="filter-field"><label>استان</label><select name="state" id="stateFilterInput"><option value="">همه استان‌ها</option>')
    for _, st in ipairs(state_options) do
        local sel = (filters.state == st) and ' selected' or ''
        table.insert(html, '<option value="' .. escape_html(st) .. '"' .. sel .. '>' .. escape_html(st) .. '</option>')
    end
    table.insert(html, '</select></div>')
    table.insert(html, '<div class="filter-field"><label>شهر</label><input type="text" name="city" id="cityFilterInput" placeholder="نام شهر" value="' ..
        escape_html(filters.city or "") .. '"></div>')
    table.insert(html, '<div class="filter-field"><label>نوع مشتری</label><select name="user_type"><option value="">همه</option>')
    for _, ut in ipairs(user_type_options) do
        local sel = (filters.user_type == ut) and ' selected' or ''
        table.insert(html, '<option value="' .. escape_html(ut) .. '"' .. sel .. '>' .. escape_html(user_type_label(ut)) .. '</option>')
    end
    table.insert(html, '</select></div>')
    table.insert(html, '<div class="filter-actions"><button type="submit" class="btn-primary" id="filterSubmitBtn">اعمال فیلتر</button>' ..
        '<button type="button" class="btn-secondary" onclick="resetFilters()">پاک‌سازی</button></div>')
    table.insert(html, '</form>')
    return table.concat(html)
end

-- ============================================================
-- RENDER: FOOTER / ERROR
-- ============================================================

local function render_footer_html(generated_jdate)
    return 'تولید شده در ' .. escape_html(generated_jdate or "") .. ' — داشبورد جغرافیایی CRM و فروش'
end

local function render_error_html(message)
    return '<!DOCTYPE html>\n<html dir="rtl" lang="fa">\n<head>\n<meta charset="UTF-8">\n<title>داشبورد جغرافیایی فروش - خطا</title>\n' ..
        REPORT_CSS ..
        '</head>\n<body>\n<div id="reportRoot" style="max-width:640px;">' ..
        '<div class="section" style="border-color:#e00;text-align:center;margin-top:60px;">' ..
        '<h3 style="color:#c00;">خطا در تولید داشبورد</h3><p>' .. escape_html(message) .. '</p></div>' ..
        '</div>\n</body>\n</html>'
end

-- رفع باگ v04 (طبق گزارش زندهٔ کاربر: «فیلتر می‌زنم ارور JSON می‌دهد»): بخش «Dashboard اصلی» هم برای
-- بار اول صفحه (HTML کامل) و هم برای Refresh با AJAX (format=json، هنگام تغییر فیلتر/تب) استفاده می‌شود؛
-- ولی همهٔ مسیرهای خطای آن قبلاً همیشه HTML برمی‌گرداندند (render_error_html)، حتی وقتی خودِ کلاینت
-- format=json خواسته بود — یعنی هر خطای واقعی SQL (که پیام فارسی دقیق داشت) به‌جای JSON قابل‌Parse به
-- شکل یک صفحهٔ HTML به دست fetch().then(res.json()) می‌رسید و خطای عمومی و بی‌فایدهٔ مرورگر
-- «Unexpected token '<'» را ایجاد می‌کرد — پیام واقعی خطا هرگز به کاربر/کنسول نمی‌رسید. این تابع جایگزین
-- همهٔ فراخوانی‌های render_error_html داخل بخش Dashboard اصلی شد تا خروجی همیشه با نوع درخواست‌شده یکی باشد.
local function write_dashboard_error(input, message)
    if input ~= nil and input["format"] == "json" then
        teamyar.write_result(json.encode({ ok = false, error = message }))
    else
        teamyar.write_result(render_error_html(message))
    end
end

-- ============================================================
-- JS
-- ============================================================

-- رفع باگ v04.1 (کشف‌شده حین دیباگ زندهٔ کاربر — بات ۶۰۴ در پنل بی‌نهایت «Loading» می‌ماند و پنل Teamyar
-- خودش را در یک Loop از فراخوانی مکرر Endpoint های داخلی‌اش (view/info/exist/acltypes/active_session)
-- گیر می‌انداخت، بدون هیچ خطای مشخص سمت بات؛ با DevTools Network تأیید شد که خروجی خودِ بات همیشه سریع و
-- 200 برمی‌گشت — یعنی مشکل از کوئری‌های DB نبود). این بلوک اسکریپت قبلاً بدون IIFE بود، یعنی هر var/function
-- سطح بالای آن (DASH, STATE_MAP, CHANNEL_CACHE, ACTIVE_CHANNEL, setActiveChannel, applyDashboardUpdate, ...
-- ده‌ها اسم دیگر) مستقیم روی window (Scope سراسری صفحه) قرار می‌گرفت. صفحهٔ ما داخل همان DOM پنل Teamyar
-- Render می‌شود (نه یک iframe مجزا)، پس این نام‌های سراسری می‌توانستند با متغیر/تابع داخلی خودِ پنل Teamyar
-- (که چرخهٔ Loading/Session/ACL را مدیریت می‌کند) تصادفی هم‌نام شوند و آن را بشکنند — دقیقاً هم‌خانواده با
-- الگوی Namespace-Pollution که علت این‌طور Symptom های عجیب (نه خطای مستقیم، فقط یک Loop بی‌پایان در چیزی
-- کاملاً بی‌ربط) است. رفع شد: کل اسکریپت داخل یک IIFE پیچیده شد تا هیچ نامی نشتی به window نداشته باشد؛ فقط
-- توابعی که HTML این بات مستقیم با onclick="..." صدا می‌زند (این‌ها ذاتاً باید Global باشند چون Attribute
-- inline در Global Scope اجرا می‌شود) صریحاً در انتهای اسکریپت روی window Export شده‌اند — ر.ک. لیست کامل
-- window.X = X در همان‌جا.
local REPORT_JS = [[
<script>
(function(){
'use strict';
function fmtNum(v){
  var n = Math.round(Number(v) || 0);
  var sign = n < 0 ? '-' : ''; n = Math.abs(n);
  var s = String(n);
  var out = '';
  while (s.length > 3) { out = ',' + s.slice(-3) + out; s = s.slice(0, -3); }
  out = s + out;
  return sign + out;
}
function fmtDec1(v){ return (Math.round((Number(v)||0)*10)/10).toFixed(1); }
/* بازهٔ تاریخ فعال (پیش‌فرض سال مالی جاری) را از جعبهٔ فیلتر بالای صفحه می‌خواند تا همهٔ Drill-down های
   Lazy با همان بازهٔ Dashboard اصلی هم‌خوان بمانند (طبق درخواست کاربر، مشابه بات ۶۰۰). */
function getActiveDateFrom(){
  var el = document.getElementById('dateFromInput');
  var v = el && el.value ? el.value.trim() : '';
  return v || (DASH && DASH.default_date_from) || '';
}
function getActiveDateTo(){
  var el = document.getElementById('dateToInput');
  var v = el && el.value ? el.value.trim() : '';
  return v || (DASH && DASH.default_date_to) || '';
}
/* دستهٔ کسب‌وکار فعال (b2b/b2c/other/''=همه) — برای هماهنگی همهٔ Drill-down های Lazy با تب فعال. */
function getActiveChannel(){
  var el = document.getElementById('channelInput');
  return el ? el.value : '';
}
function setActiveChannel(btn){
  var channel = btn.getAttribute('data-channel');
  var el = document.getElementById('channelInput');
  if (el) el.value = channel;
  document.querySelectorAll('.channel-tab').forEach(function(b){ b.classList.remove('active'); });
  btn.classList.add('active');
  /* v04.1: اگر این تب قبلاً در پس‌زمینه Prefetch شده (prefetchOtherChannels)، سوییچ آنی و بدون fetch است.
     اگر کاربر خیلی زود کلیک کرده (Prefetch هنوز تمام نشده)، فقط همین یک تب را می‌گیرد — نه هر ۴ تا. */
  var cached = CHANNEL_CACHE && CHANNEL_CACHE[channel];
  if (cached) {
    applyDashboardUpdate(cached);
    return;
  }
  fetchChannelView(channel)
    .then(function(view){ CHANNEL_CACHE[channel] = view; applyDashboardUpdate(view); })
    .catch(function(err){ alert('خطا در بارگذاری این تب: ' + err.message); });
}
function escapeHtml(v){
  if (v === null || v === undefined) return '';
  /* امپرسند با String.fromCharCode(38) در زمان اجرا ساخته می‌شود، نه به‌صورت رشته Entity کامل
     در سورس: وقتی رشته‌های Entity کامل و پیوسته عینا داخل بلاک اسکریپت بات ذخیره می‌شوند، یک لایه
     در مسیر ذخیره/نمایش تیم‌یار آنها را decode می‌کند و جاوااسکریپت را می‌شکند (طبق قانون CLAUDE.md
     درباره این Quirk شناخته‌شده تیم‌یار؛ این باگ دقیقا نمونه زنده‌اش بود: escapeHtml کل اسکریپت
     صفحه را با خطای نحوی می‌شکست و هم نمودارها هم دکمه تمام‌صفحه از کار می‌افتادند). با این روش
     دیگر رشته پیوسته Entity در سورس ذخیره‌شده وجود ندارد که آن لایه بخواهد decode کند. */
  var AMP = String.fromCharCode(38);
  return String(v).split('&').join(AMP + 'amp;').split('<').join(AMP + 'lt;').split('>').join(AMP + 'gt;').split('"').join(AMP + 'quot;').split("'").join(AMP + '#39;');
}

/* ---------------- Tooltip ---------------- */
var tipEl = null;
function ensureTip(){
  if (!tipEl) { tipEl = document.createElement('div'); tipEl.className = 'tooltip-box'; document.body.appendChild(tipEl); }
  return tipEl;
}
function showTip(evt, text){
  var t = ensureTip();
  t.textContent = text;
  t.style.display = 'block';
  t.style.left = (evt.clientX + 14) + 'px';
  t.style.top = (evt.clientY + 14) + 'px';
}
function hideTip(){ if (tipEl) tipEl.style.display = 'none'; }

/* ---------------- Bar chart (div-based, RTL-friendly, no external lib) ---------------- */
function renderBarChart(containerId, items, opts){
  opts = opts || {};
  var valueKey = opts.valueKey || 'value';
  var labelKey = opts.labelKey || 'label';
  var color = opts.color || 'var(--accent)';
  var suffix = opts.suffix || '';
  var onClick = opts.onClick;
  var el = document.getElementById(containerId);
  if (!el) return;
  var max = 0;
  for (var i = 0; i < items.length; i++) { if (items[i][valueKey] > max) max = items[i][valueKey]; }
  if (max <= 0) max = 1;
  var html = ['<div class="barlist">'];
  for (var j = 0; j < items.length; j++) {
    var it = items[j];
    var pct = (it[valueKey] / max) * 100;
    html.push('<div class="bar-row" data-idx="' + j + '">' +
      '<div class="bar-label">' + escapeHtml(it[labelKey]) + '</div>' +
      '<div class="bar-track"><div class="bar-fill" style="width:' + pct.toFixed(1) + '%;background:' + color + '"></div></div>' +
      '<div class="bar-value">' + fmtNum(it[valueKey]) + suffix + '</div>' +
      '</div>');
  }
  html.push('</div>');
  el.innerHTML = html.join('');
  var rows = el.querySelectorAll('.bar-row');
  rows.forEach(function(row){
    var idx = Number(row.getAttribute('data-idx'));
    var it = items[idx];
    row.addEventListener('mousemove', function(e){ showTip(e, it[labelKey] + ': ' + fmtNum(it[valueKey]) + suffix); });
    row.addEventListener('mouseleave', hideTip);
    if (onClick) row.addEventListener('click', function(){ onClick(it); });
  });
}

/* ---------------- Combo chart: دو معیار در کنار هم برای هر استان ---------------- */
function renderComboChart(containerId, items, optsA, optsB){
  var el = document.getElementById(containerId);
  if (!el) return;
  var maxA = 0, maxB = 0;
  for (var i = 0; i < items.length; i++) {
    if (items[i][optsA.key] > maxA) maxA = items[i][optsA.key];
    if (items[i][optsB.key] > maxB) maxB = items[i][optsB.key];
  }
  if (maxA <= 0) maxA = 1; if (maxB <= 0) maxB = 1;
  var html = ['<div class="combo-legend"><span><i class="sw" style="background:var(--accent)"></i>' + escapeHtml(optsA.label) +
    '</span><span><i class="sw" style="background:var(--accent-light)"></i>' + escapeHtml(optsB.label) + '</span></div>'];
  html.push('<div class="barlist">');
  for (var j = 0; j < items.length; j++) {
    var it = items[j];
    var pctA = (it[optsA.key] / maxA) * 100;
    var pctB = (it[optsB.key] / maxB) * 100;
    html.push('<div class="combo-row" data-idx="' + j + '">' +
      '<div class="bar-label">' + escapeHtml(it.state_name) + '</div>' +
      '<div class="combo-tracks">' +
      '<div class="bar-track thin"><div class="bar-fill" style="width:' + pctA.toFixed(1) + '%;background:var(--accent)"></div></div>' +
      '<div class="bar-track thin"><div class="bar-fill" style="width:' + pctB.toFixed(1) + '%;background:var(--accent-light)"></div></div>' +
      '</div></div>');
  }
  html.push('</div>');
  el.innerHTML = html.join('');
  var rows = el.querySelectorAll('.combo-row');
  rows.forEach(function(row){
    var idx = Number(row.getAttribute('data-idx'));
    var it = items[idx];
    row.addEventListener('mousemove', function(e){
      showTip(e, it.state_name + ' — ' + optsA.label + ': ' + fmtNum(it[optsA.key]) + ' | ' + optsB.label + ': ' + fmtNum(it[optsB.key]));
    });
    row.addEventListener('mouseleave', hideTip);
  });
}

/* ---------------- Donut chart (conic-gradient، بدون کتابخانه خارجی) ---------------- */
function renderDonutChart(containerId, slices, onClick){
  var el = document.getElementById(containerId);
  if (!el) return;
  var shades = ['#16509D', '#3068AE', '#4a7fbe', '#5b85bc', '#7d9dcb', '#a9c2de', '#c7d7ea'];
  var total = 0;
  for (var i = 0; i < slices.length; i++) total += slices[i].value;
  if (total <= 0) total = 1;
  var stops = []; var acc = 0;
  for (var j = 0; j < slices.length; j++) {
    var s = slices[j];
    var color = (s.name === 'سایر') ? '#bbb' : shades[j % shades.length];
    var from = (acc / total) * 100;
    acc += s.value;
    var to = (acc / total) * 100;
    stops.push(color + ' ' + from.toFixed(2) + '% ' + to.toFixed(2) + '%');
  }
  var gradient = 'conic-gradient(' + stops.join(',') + ')';
  var html = '<div class="donut-wrap"><div class="donut" style="background:' + gradient + '"><div class="donut-hole"></div></div>' +
    '<div class="donut-legend">';
  for (var k = 0; k < slices.length; k++) {
    var sl = slices[k];
    var color2 = (sl.name === 'سایر') ? '#bbb' : shades[k % shades.length];
    html += '<div class="legend-row" data-idx="' + k + '"><i class="sw" style="background:' + color2 + '"></i>' +
      '<span class="ln">' + escapeHtml(sl.name) + '</span><span class="lv">' + fmtDec1(sl.pct) + '٪</span></div>';
  }
  html += '</div></div>';
  el.innerHTML = html;
  var rows = el.querySelectorAll('.legend-row');
  rows.forEach(function(row){
    var idx = Number(row.getAttribute('data-idx'));
    var sl = slices[idx];
    row.addEventListener('mousemove', function(e){ showTip(e, sl.name + ': ' + fmtNum(sl.value) + ' ریال (' + fmtDec1(sl.pct) + '٪)'); });
    row.addEventListener('mouseleave', hideTip);
    if (onClick && sl.name !== 'سایر') row.addEventListener('click', function(){ onClick(sl.name); });
  });
}

/* ---------------- Sortable tables ---------------- */
function getCellSortValue(cell){
  var text = cell ? cell.innerText.trim() : '';
  var n = text.replace(/[,%٪]/g,'').trim();
  if (n !== '' && /^-?\d+(\.\d+)?$/.test(n)) return parseFloat(n);
  return text;
}
function sortTableByColumn(table, colIndex, dir){
  var tbody = table.querySelector('tbody');
  var rows = Array.prototype.slice.call(tbody.querySelectorAll('tr'));
  rows.sort(function(ra, rb){
    var a = getCellSortValue(ra.children[colIndex]), b = getCellSortValue(rb.children[colIndex]), cmp;
    if (typeof a === 'number' && typeof b === 'number') cmp = a - b; else cmp = String(a).localeCompare(String(b), 'fa');
    return dir === 'asc' ? cmp : -cmp;
  });
  rows.forEach(function(row){ tbody.appendChild(row); });
}
function initSortableTables(root){
  (root || document).querySelectorAll('table.data-table').forEach(function(table){
    var headers = table.querySelectorAll('thead th');
    headers.forEach(function(th, colIndex){
      if (th.getAttribute('data-sortable-bound')) return;
      th.setAttribute('data-sortable-bound', '1');
      th.addEventListener('click', function(){
        var dir = th.classList.contains('sort-asc') ? 'desc' : 'asc';
        headers.forEach(function(h){ h.classList.remove('sort-asc', 'sort-desc'); });
        th.classList.add(dir === 'asc' ? 'sort-asc' : 'sort-desc');
        sortTableByColumn(table, colIndex, dir);
      });
    });
  });
}

/* ---------------- Toolbar: fullscreen / excel / help ---------------- */
function toggleFullScreen(){
  var root = document.getElementById('reportRoot');
  root.classList.toggle('pseudo-fullscreen');
  window.scrollTo(0, 0);
}
function openHelp(){ document.getElementById('helpModal').classList.add('active'); }
function closeHelp(){ document.getElementById('helpModal').classList.remove('active'); }
function closeInvoiceModal(){ document.getElementById('invoiceModal').classList.remove('active'); }
function closeDqModal(){ document.getElementById('dqModal').classList.remove('active'); }
window.addEventListener('click', function(e){
  if (e.target === document.getElementById('helpModal')) closeHelp();
  if (e.target === document.getElementById('invoiceModal')) closeInvoiceModal();
  if (e.target === document.getElementById('dqModal')) closeDqModal();
});
document.addEventListener('keydown', function(e){ if (e.key === 'Escape') { closeHelp(); closeInvoiceModal(); closeDqModal(); } });

/* ---------------- Drill-down از کارت‌های KPI بالای صفحه (Scroll) و کارت‌های کیفیت داده (Modal، Lazy AJAX) ---------------- */
function scrollToKpiTarget(sectionId, expandCities){
  if (expandCities) {
    var box = document.getElementById('fullCityListBox');
    if (box && (box.style.display === 'none' || !box.style.display)) toggleFullCityList();
  }
  var el = document.getElementById(sectionId);
  if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' });
}

function openDataQualityCustomers(field, offset){
  var modal = document.getElementById('dqModal');
  var body = document.getElementById('dqModalBody');
  document.getElementById('dqModalTitle').textContent = field === 'city' ? 'مشتریان بدون شهر' : 'مشتریان بدون استان';
  body.innerHTML = '<div class="loading-row">در حال بارگذاری...</div>';
  modal.classList.add('active');
  var fd = new FormData();
  fd.append('action', 'dq_customers');
  fd.append('field', field);
  fd.append('offset', String(offset || 0));
  fetch(window.location.href, { method: 'POST', body: fd })
    .then(function(res){ return res.json(); })
    .then(function(payload){
      if (!payload.ok) throw new Error(payload.error || 'خطای ناشناخته');
      var rows = payload.rows || [];
      var rowsHtml = rows.length === 0 ? '<tr><td colspan="4" class="empty-row">موردی یافت نشد</td></tr>' : rows.map(function(c){
        var crmUrl = ']] .. CONFIG.CRM_EDIT_URL_PREFIX .. [[' + c.crm_id + ']] .. CONFIG.CRM_EDIT_URL_SUFFIX .. [[';
        return '<tr><td>' + c.crm_id + '</td><td>' + escapeHtml(c.customer_name) + '</td><td>' + escapeHtml(c.state_name || '—') +
          '</td><td>' + escapeHtml(c.city_name || '—') + '</td><td><a class="link" target="_blank" href="' + crmUrl + '">مشاهده CRM</a></td></tr>';
      }).join('');
      var totalPages = Math.max(1, Math.ceil(payload.total / payload.limit));
      var curPage = Math.floor(payload.offset / payload.limit) + 1;
      body.innerHTML = '<div>' + fmtNum(payload.total) + ' مشتری</div>' +
        '<div class="table-scroll"><table class="data-table"><thead><tr><th>شناسه</th><th>نام مشتری</th><th>استان</th><th>شهر</th><th>CRM</th></tr></thead><tbody>' + rowsHtml + '</tbody></table></div>' +
        '<div class="pager"><button ' + (curPage <= 1 ? 'disabled' : '') + ' onclick="openDataQualityCustomers(\'' + field + '\',' + (payload.offset - payload.limit) + ')">قبلی</button>' +
        '<span>صفحه ' + curPage + ' از ' + totalPages + '</span>' +
        '<button ' + (curPage >= totalPages ? 'disabled' : '') + ' onclick="openDataQualityCustomers(\'' + field + '\',' + (payload.offset + payload.limit) + ')">بعدی</button></div>';
      initSortableTables(body);
    })
    .catch(function(err){ body.innerHTML = '<div class="error-row">خطا: ' + escapeHtml(err.message) + '</div>'; });
}

function openDataQualityInvoices(offset){
  var modal = document.getElementById('dqModal');
  var body = document.getElementById('dqModalBody');
  document.getElementById('dqModalTitle').textContent = 'فاکتورهای بدون نگاشت جغرافیایی';
  body.innerHTML = '<div class="loading-row">در حال بارگذاری...</div>';
  modal.classList.add('active');
  var fd = new FormData();
  fd.append('action', 'dq_invoices');
  fd.append('date_from', getActiveDateFrom());
  fd.append('channel', getActiveChannel());
  fd.append('date_to', getActiveDateTo());
  fd.append('offset', String(offset || 0));
  fetch(window.location.href, { method: 'POST', body: fd })
    .then(function(res){ return res.json(); })
    .then(function(payload){
      if (!payload.ok) throw new Error(payload.error || 'خطای ناشناخته');
      var rows = payload.rows || [];
      var rowsHtml = rows.length === 0 ? '<tr><td colspan="5" class="empty-row">موردی یافت نشد</td></tr>' : rows.map(function(inv){
        var invUrl = ']] .. CONFIG.INVOICE_VIEW_URL_PREFIX .. [[' + inv.invoice_id;
        var crmUrl = ']] .. CONFIG.CRM_EDIT_URL_PREFIX .. [[' + inv.crm_id + ']] .. CONFIG.CRM_EDIT_URL_SUFFIX .. [[';
        return '<tr><td><a class="link" target="_blank" href="' + invUrl + '">' + inv.invoice_id + '</a></td><td>' + escapeHtml(inv.invoice_code) +
          '</td><td>' + escapeHtml(inv.run_jdate || '—') + '</td><td>' + fmtNum(inv.invoice_amount) + '</td><td>' + escapeHtml(inv.customer_name) +
          ' — <a class="link" target="_blank" href="' + crmUrl + '">CRM</a></td></tr>';
      }).join('');
      var totalPages = Math.max(1, Math.ceil(payload.total / payload.limit));
      var curPage = Math.floor(payload.offset / payload.limit) + 1;
      body.innerHTML = '<div>' + fmtNum(payload.total) + ' فاکتور</div>' +
        '<div class="table-scroll"><table class="data-table"><thead><tr><th>شناسه فاکتور</th><th>کد فاکتور</th><th>تاریخ</th><th>مبلغ</th><th>مشتری</th></tr></thead><tbody>' + rowsHtml + '</tbody></table></div>' +
        '<div class="pager"><button ' + (curPage <= 1 ? 'disabled' : '') + ' onclick="openDataQualityInvoices(' + (payload.offset - payload.limit) + ')">قبلی</button>' +
        '<span>صفحه ' + curPage + ' از ' + totalPages + '</span>' +
        '<button ' + (curPage >= totalPages ? 'disabled' : '') + ' onclick="openDataQualityInvoices(' + (payload.offset + payload.limit) + ')">بعدی</button></div>';
      initSortableTables(body);
    })
    .catch(function(err){ body.innerHTML = '<div class="error-row">خطا: ' + escapeHtml(err.message) + '</div>'; });
}

function csvCell(t){ t = (t == null ? '' : String(t)).replace(/\s+/g,' ').trim(); if (t.indexOf(',') !== -1 || t.indexOf('"') !== -1) t = '"' + t.replace(/"/g,'""') + '"'; return t; }
function downloadCsv(lines, fileName){
  var blob = new Blob(['﻿' + lines.join('\r\n')], { type: 'text/csv;charset=utf-8;' });
  var url = URL.createObjectURL(blob); var link = document.createElement('a');
  link.href = url; link.download = fileName; document.body.appendChild(link); link.click(); document.body.removeChild(link); URL.revokeObjectURL(url);
}
function exportToExcel(){
  var table = document.getElementById('stateTable'); if (!table) return;
  var lines = []; var heads = table.querySelectorAll('thead th'); var hl = [];
  for (var h = 0; h < heads.length; h++) hl.push(csvCell(heads[h].innerText));
  lines.push(hl.join(','));
  var rows = table.querySelectorAll('tbody tr');
  for (var i = 0; i < rows.length; i++) {
    var cells = rows[i].querySelectorAll('td'); var line = [];
    for (var c = 0; c < cells.length; c++) line.push(csvCell(cells[c].innerText));
    lines.push(line.join(','));
  }
  downloadCsv(lines, 'گزارش-جغرافیایی-فروش-استان‌ها.csv');
}

/* ---------------- داده تعبیه‌شده (Executive KPI + State/City Aggregation) ---------------- */
/* رفع v04.1 (خطای JSON زندهٔ کاربر بعد از v04: سرور با محاسبهٔ هر ۴ تب در یک درخواست به Timeout پلتفرم
   می‌خورد): صفحه فقط داده تب فعال را Embed می‌کند؛ سه تب دیگر با درخواست‌های جدا در پس‌زمینه (پایین همین
   فایل: prefetchOtherChannels، بعد از initCharts) پر می‌شوند — نه در همان درخواست اول صفحه. */
var ACTIVE_CHANNEL = JSON.parse(document.getElementById('activeChannelKey').textContent);
var CHANNEL_CACHE = {};
CHANNEL_CACHE[ACTIVE_CHANNEL] = JSON.parse(document.getElementById('activeChannelView').textContent);
var DASH = CHANNEL_CACHE[ACTIVE_CHANNEL].dash_data;
var STATE_MAP = {};
DASH.states.forEach(function(s){ STATE_MAP[s.state_name] = s; });

function citiesOfState(stateName){
  return DASH.cities.filter(function(c){ return c.state_name === stateName; });
}

/* ---------------- Drill-down سطح استان (کاملاً از داده تعبیه‌شده، بدون Query) ---------------- */
function openStateDrill(stateName){
  var s = STATE_MAP[stateName];
  if (!s) return;
  var panel = document.getElementById('stateDrillPanel');
  var cities = citiesOfState(stateName).slice().sort(function(a,b){ return b.total_sales_amount - a.total_sales_amount; });
  var rows = cities.map(function(c){
    var sharePct = s.total_sales_amount > 0 ? (c.total_sales_amount / s.total_sales_amount * 100) : 0;
    return '<tr class="clickable" data-state="' + escapeHtml(stateName) + '" data-city="' + escapeHtml(c.city_name) + '" onclick="openCustomerDrillFromRow(this)"><td>' +
      escapeHtml(c.city_name) + '</td><td>' + fmtNum(c.unique_customer_count) + '</td><td>' + fmtNum(c.buyer_count) +
      '</td><td>' + fmtNum(c.invoice_count) + '</td><td>' + fmtNum(c.total_sales_amount) + '</td><td>' + fmtDec1(sharePct) + '٪</td></tr>';
  }).join('');
  panel.innerHTML =
    '<div class="head"><h4>جزئیات استان: ' + escapeHtml(stateName) + '</h4><button class="close-btn" onclick="closeStateDrill()">بستن ✕</button></div>' +
    '<div class="kpi-grid">' +
      '<div class="kpi-card"><div class="label">مبلغ کل فروش</div><div class="value">' + fmtNum(s.total_sales_amount) + '</div></div>' +
      '<div class="kpi-card"><div class="label">تعداد فاکتور</div><div class="value">' + fmtNum(s.invoice_count) + '</div></div>' +
      '<div class="kpi-card"><div class="label">تعداد مشتری</div><div class="value">' + fmtNum(s.unique_customer_count) + '</div></div>' +
      '<div class="kpi-card"><div class="label">تعداد مشتری خریدار</div><div class="value">' + fmtNum(s.buyer_count) + '</div></div>' +
      '<div class="kpi-card"><div class="label">تعداد شهر فعال</div><div class="value">' + fmtNum(s.city_count_with_sales) + '</div></div>' +
      '<div class="kpi-card"><div class="label">سهم از کل فروش</div><div class="value">' + fmtDec1(s.sales_share_pct) + '٪</div></div>' +
      '<div class="kpi-card"><div class="label">میانگین مبلغ فاکتور</div><div class="value">' + fmtNum(s.avg_invoice_amount) + '</div></div>' +
    '</div>' +
    '<div class="table-scroll"><table class="data-table"><thead><tr><th>شهر</th><th>تعداد مشتری</th><th>تعداد مشتری خریدار</th><th>تعداد فاکتور</th><th>مبلغ فروش</th><th>سهم از فروش استان</th></tr></thead>' +
    '<tbody>' + (rows || '<tr><td colspan="6" class="empty-row">شهری با آدرس معتبر برای این استان یافت نشد</td></tr>') + '</tbody></table></div>' +
    '<div id="customerDrillPanel"></div>';
  panel.style.display = 'block';
  initSortableTables(panel);
  panel.scrollIntoView({ behavior: 'smooth', block: 'start' });
}
function closeStateDrill(){ document.getElementById('stateDrillPanel').style.display = 'none'; document.getElementById('stateDrillPanel').innerHTML = ''; }
function openCustomerDrillFromRow(tr){
  openCustomerDrill(tr.getAttribute('data-state'), tr.getAttribute('data-city'), 0);
}

/* ---------------- Drill-down سطح شهر → مشتری (Lazy — AJAX هنگام کلیک) ---------------- */
var custDrillState = { state: null, city: null, offset: 0, limit: 50, total: 0 };

function openCustomerDrill(stateName, cityName, offset){
  var host = document.getElementById('customerDrillPanel');
  if (!host) {
    // اگر از جدول Top شهرها (خارج از پنل استان) کلیک شده، پنل مستقل خودش را بساز
    var mainPanel = document.getElementById('stateDrillPanel');
    if (!mainPanel) return;
    openStateDrill(stateName);
    host = document.getElementById('customerDrillPanel');
  }
  custDrillState.state = stateName; custDrillState.city = cityName; custDrillState.offset = offset || 0;
  host.innerHTML = '<div class="drill-panel"><div class="head"><h4>مشتریان شهر: ' + escapeHtml(cityName) + ' (' + escapeHtml(stateName) + ')</h4>' +
    '<button class="close-btn" onclick="closeCustomerDrill()">بستن ✕</button></div>' +
    '<div class="loading-row">در حال بارگذاری...</div></div>';
  var fd = new FormData();
  fd.append('action', 'customers');
  fd.append('state', stateName);
  fd.append('city', cityName);
  fd.append('date_from', getActiveDateFrom());
  fd.append('channel', getActiveChannel());
  fd.append('date_to', getActiveDateTo());
  fd.append('offset', String(custDrillState.offset));
  var utSel = document.querySelector('select[name="user_type"]');
  if (utSel && utSel.value) fd.append('user_type', utSel.value);
  fetch(window.location.href, { method: 'POST', body: fd })
    .then(function(res){ return res.json(); })
    .then(function(payload){
      if (!payload.ok) throw new Error(payload.error || 'خطای ناشناخته');
      custDrillState.total = payload.total;
      renderCustomerDrill(payload);
    })
    .catch(function(err){
      host.querySelector('.drill-panel').innerHTML =
        '<div class="head"><h4>مشتریان شهر: ' + escapeHtml(cityName) + '</h4><button class="close-btn" onclick="closeCustomerDrill()">بستن ✕</button></div>' +
        '<div class="error-row">خطا در دریافت اطلاعات مشتریان: ' + escapeHtml(err.message) + ' — <a href="#" onclick="openCustomerDrill(\'' + stateName.replace(/'/g,"\\'") + '\',\'' + cityName.replace(/'/g,"\\'") + '\',0);return false;">تلاش مجدد</a></div>';
    });
}
function renderCustomerDrill(payload){
  var host = document.getElementById('customerDrillPanel');
  if (!host) return;
  var rows = payload.rows || [];
  var body = rows.length === 0 ? '<tr><td colspan="6" class="empty-row">مشتری‌ای یافت نشد</td></tr>' : rows.map(function(c){
    var crmUrl = ']] .. CONFIG.CRM_EDIT_URL_PREFIX .. [[' + c.crm_id + ']] .. CONFIG.CRM_EDIT_URL_SUFFIX .. [[';
    return '<tr class="clickable" data-crmid="' + c.crm_id + '" onclick="openInvoiceDrill(' + c.crm_id + ')"><td>' + escapeHtml(c.customer_name) +
      '</td><td>' + fmtNum(c.invoice_count) + '</td><td>' + fmtNum(c.total_purchase_amount) + '</td><td>' +
      escapeHtml(c.last_purchase_jdate || '—') + '</td><td onclick="event.stopPropagation();"><a class="link" target="_blank" href="' + crmUrl + '">مشاهده CRM</a></td></tr>';
  }).join('');
  var totalPages = Math.max(1, Math.ceil(custDrillState.total / custDrillState.limit));
  var curPage = Math.floor(custDrillState.offset / custDrillState.limit) + 1;
  host.innerHTML = '<div class="drill-panel"><div class="head"><h4>مشتریان شهر: ' + escapeHtml(custDrillState.city) +
    ' (' + escapeHtml(custDrillState.state) + ') — ' + fmtNum(custDrillState.total) + ' مشتری</h4>' +
    '<button class="close-btn" onclick="closeCustomerDrill()">بستن ✕</button></div>' +
    '<div class="table-scroll"><table class="data-table"><thead><tr><th>نام مشتری</th><th>تعداد فاکتور</th><th>مبلغ کل خرید</th><th>آخرین تاریخ خرید</th><th>CRM</th></tr></thead>' +
    '<tbody>' + body + '</tbody></table></div>' +
    '<div class="pager"><button ' + (curPage <= 1 ? 'disabled' : '') + ' onclick="openCustomerDrill(\'' + custDrillState.state.replace(/'/g,"\\'") + '\',\'' + custDrillState.city.replace(/'/g,"\\'") + '\',' + (custDrillState.offset - custDrillState.limit) + ')">قبلی</button>' +
    '<span>صفحه ' + curPage + ' از ' + totalPages + '</span>' +
    '<button ' + (curPage >= totalPages ? 'disabled' : '') + ' onclick="openCustomerDrill(\'' + custDrillState.state.replace(/'/g,"\\'") + '\',\'' + custDrillState.city.replace(/'/g,"\\'") + '\',' + (custDrillState.offset + custDrillState.limit) + ')">بعدی</button></div>' +
    '</div>';
}
function closeCustomerDrill(){ var host = document.getElementById('customerDrillPanel'); if (host) host.innerHTML = ''; }

/* ---------------- Drill-down سطح مشتری → فاکتور (Lazy — AJAX هنگام کلیک، در Modal) ---------------- */
function openInvoiceDrill(crmId){
  var modal = document.getElementById('invoiceModal');
  var body = document.getElementById('invoiceModalBody');
  body.innerHTML = '<div class="loading-row">در حال بارگذاری...</div>';
  modal.classList.add('active');
  var fd = new FormData();
  fd.append('action', 'invoices');
  fd.append('crm_id', String(crmId));
  fd.append('date_from', getActiveDateFrom());
  fd.append('channel', getActiveChannel());
  fd.append('date_to', getActiveDateTo());
  fetch(window.location.href, { method: 'POST', body: fd })
    .then(function(res){ return res.json(); })
    .then(function(payload){
      if (!payload.ok) throw new Error(payload.error || 'خطای ناشناخته');
      var rows = payload.rows || [];
      var rowsHtml = rows.length === 0 ? '<tr><td colspan="4" class="empty-row">فاکتوری یافت نشد</td></tr>' : rows.map(function(inv){
        var url = ']] .. CONFIG.INVOICE_VIEW_URL_PREFIX .. [[' + inv.invoice_id;
        return '<tr><td><a class="link" target="_blank" href="' + url + '">' + inv.invoice_id + '</a></td><td>' +
          escapeHtml(inv.invoice_code) + '</td><td>' + escapeHtml(inv.run_jdate || '—') + '</td><td>' + fmtNum(inv.invoice_amount) + '</td></tr>';
      }).join('');
      var cust = payload.customer || {};
      document.getElementById('invoiceModalTitle').textContent = 'فاکتورهای ' + (cust.customer_name || '');
      body.innerHTML = '<div class="table-scroll"><table class="data-table"><thead><tr><th>شناسه فاکتور</th><th>کد فاکتور</th><th>تاریخ</th><th>مبلغ</th></tr></thead><tbody>' + rowsHtml + '</tbody></table></div>';
      initSortableTables(body);
    })
    .catch(function(err){ body.innerHTML = '<div class="error-row">خطا در دریافت فاکتورها: ' + escapeHtml(err.message) + '</div>'; });
}

/* ---------------- فهرست کامل شهرها (Toggle + جستجوی سمت کلاینت، از داده تعبیه‌شده) ---------------- */
function toggleFullCityList(){
  var box = document.getElementById('fullCityListBox');
  var btn = document.getElementById('toggleCityListBtn');
  if (box.style.display === 'none' || !box.style.display) {
    box.style.display = 'block';
    if (!box.getAttribute('data-rendered')) {
      renderFullCityTable(DASH.cities);
      box.setAttribute('data-rendered', '1');
    }
    btn.textContent = 'بستن فهرست کامل شهرها';
  } else {
    box.style.display = 'none';
    btn.textContent = 'نمایش تمام شهرها';
  }
}
function renderFullCityTable(cities){
  var rows = cities.map(function(c){
    return '<tr class="clickable" data-state="' + escapeHtml(c.state_name) + '" data-city="' + escapeHtml(c.city_name) +
      '" onclick="openCustomerDrillFromFullList(this)"><td>' + escapeHtml(c.state_name) + '</td><td>' + escapeHtml(c.city_name) +
      '</td><td>' + fmtNum(c.unique_customer_count) + '</td><td>' + fmtNum(c.buyer_count) + '</td><td>' + fmtNum(c.invoice_count) +
      '</td><td>' + fmtNum(c.total_sales_amount) + '</td><td>' + fmtNum(c.avg_invoice_amount) + '</td></tr>';
  }).join('');
  document.getElementById('fullCityTbody').innerHTML = rows;
  initSortableTables(document.getElementById('fullCityListBox'));
}
function openCustomerDrillFromFullList(tr){
  var stateName = tr.getAttribute('data-state'), cityName = tr.getAttribute('data-city');
  openStateDrill(stateName);
  openCustomerDrill(stateName, cityName, 0);
  document.getElementById('stateDrillPanel').scrollIntoView({ behavior: 'smooth' });
}
document.addEventListener('input', function(e){
  if (e.target && e.target.id === 'citySearchInput') {
    var q = e.target.value.trim();
    var filtered = q === '' ? DASH.cities : DASH.cities.filter(function(c){
      return c.city_name.indexOf(q) !== -1 || c.state_name.indexOf(q) !== -1;
    });
    renderFullCityTable(filtered);
  }
});

/* ---------------- فیلتر: fetch با format=json + جایگزینی درجای بخش‌های داشبورد (بدون Navigate/iframe) ----------------
   طبق تجربهٔ ثبت‌شدهٔ سایر بات‌های این پروژه: document.write کل صفحه یا iframe تودرتو هر دو داخل شِل/Iframe
   واقعی Teamyar شکست می‌خورند؛ روش سالم fetch همین آدرس + جایگزینی innerHTML بخش‌هاست. */
var filterFormEl = document.getElementById('filterForm');
var filterRequestInFlight = false;
/* رفع باگ v03 (تأییدشده زنده): filterFormEl.requestSubmit()/dispatchEvent(new Event('submit')) در محیط
   Embedded پنل Teamyar گاهی علاوه بر فراخوانی این Listener، یک Submit بومی GET هم به همان آدرس شلیک
   می‌کرد (با DevTools Network دیده شد) — چون <form> نه method دارد نه action صریح، آن GET به‌جای JSON،
   کل صفحهٔ HTML را برمی‌گرداند و fetch().then(res=>res.json()) با خطای
   «Unexpected token '<', "<!DOCTYPE"» می‌شکست. راه‌حل: منطق اعمال فیلتر یک تابع مستقل شد
   (submitFilterForm) که مستقیم صدا زده می‌شود — نه از طریق Submit بومی/شبیه‌سازی‌شدهٔ Form. */
/* یک تب مشخص را از سرور می‌گیرد (همان فیلترهای تاریخ/استان/شهر/نوع مشتری فعلی فرم + channel داده‌شده) —
   رفع v04.1: هر فراخوانی فقط یک تب حساب می‌کند (نه هر ۴تا با هم) تا به Timeout سرور نخوریم. */
function fetchChannelView(channel){
  var formData = new FormData(filterFormEl);
  formData.set('format', 'json');
  formData.set('channel', channel);
  return fetch(window.location.href, { method: 'POST', body: formData })
    .then(function(res){ if (!res.ok) throw new Error('HTTP ' + res.status); return res.json(); })
    .then(function(payload){
      if (!payload.ok) throw new Error(payload.error || 'خطای ناشناخته سمت سرور');
      return payload.view;
    });
}
/* سه تب غیرفعال را یکی‌یکی و در پس‌زمینه (بدون قفل‌کردن UI) می‌گیرد تا سوییچ بعدی بین تب‌ها دیگر fetch
   نزند — بعد از رندر تب فعال صدا زده می‌شود (بار اول صفحه، یا بعد از هر «اعمال فیلتر»/«بازنشانی»، چون آن
   فیلترها روی هر ۴ تب اثر می‌گذارند و کش‌های قبلی را نامعتبر می‌کنند). خطای پس‌زمینه بی‌صدا نادیده گرفته
   می‌شود — اگر کاربر همان تب را دستی کلیک کند، setActiveChannel به‌صورت Fallback خودش یک fetch مستقل می‌زند. */
function prefetchOtherChannels(){
  var ALL_CHANNELS = ['', 'b2b', 'b2c', 'other'];
  var active = getActiveChannel();
  ALL_CHANNELS.forEach(function(ch){
    if (ch === active || CHANNEL_CACHE[ch]) return;
    fetchChannelView(ch).then(function(view){ CHANNEL_CACHE[ch] = view; }).catch(function(){ /* پس‌زمینه — نادیده */ });
  });
}
function submitFilterForm(){
  if (filterRequestInFlight) return;
  filterRequestInFlight = true;
  var btn = document.getElementById('filterSubmitBtn');
  var originalText = btn ? btn.textContent : '';
  if (btn) { btn.disabled = true; btn.textContent = 'در حال بارگذاری...'; }
  var channel = getActiveChannel();
  CHANNEL_CACHE = {}; // فیلترها عوض شدند؛ کش هر ۴ تب نامعتبر است
  fetchChannelView(channel)
    .then(function(view){
      CHANNEL_CACHE[channel] = view;
      applyDashboardUpdate(view);
      prefetchOtherChannels(); // تب فعال سریع رندر شد؛ بقیه در پس‌زمینه
    })
    .catch(function(err){ alert('خطا در اعمال فیلتر: ' + err.message); })
    .finally(function(){ filterRequestInFlight = false; if (btn) { btn.disabled = false; btn.textContent = originalText; } });
}
if (filterFormEl) {
  filterFormEl.addEventListener('submit', function(e){
    e.preventDefault();
    submitFilterForm();
  });
}
function resetFilters(){
  document.getElementById('dateFromInput').value = DASH.default_date_from;
  document.getElementById('dateToInput').value = DASH.default_date_to;
  document.querySelector('select[name="state"]').value = '';
  document.querySelector('input[name="city"]').value = '';
  document.querySelector('select[name="user_type"]').value = '';
  document.getElementById('channelInput').value = '';
  document.querySelectorAll('.channel-tab').forEach(function(b){ b.classList.toggle('active', b.getAttribute('data-channel') === ''); });
  submitFilterForm();
}
function applyDashboardUpdate(payload){
  DASH = payload.dash_data;
  STATE_MAP = {};
  DASH.states.forEach(function(s){ STATE_MAP[s.state_name] = s; });
  document.getElementById('kpiGrid').innerHTML = payload.kpi_cards_html;
  document.getElementById('dataQualityGrid').innerHTML = payload.data_quality_html;
  document.getElementById('newCustomersGrid').innerHTML = payload.new_customers_html;
  document.getElementById('topCustomersTbody').innerHTML = payload.top_customers_html;
  document.getElementById('centerComparisonTbody').innerHTML = payload.center_rows_html;
  document.getElementById('centerComparisonSection').style.display = payload.show_center_comparison ? '' : 'none';
  document.getElementById('minmaxGrid').innerHTML = payload.minmax_html;
  document.getElementById('stateTbody').innerHTML = payload.state_rows_html;
  document.getElementById('topCityTbody').innerHTML = payload.top_city_rows_html;
  document.getElementById('footerText').textContent = payload.footer_text;
  if (payload.header_sub_text) document.getElementById('headerSubText').textContent = payload.header_sub_text;
  document.getElementById('fullCityListBox').style.display = 'none';
  document.getElementById('fullCityListBox').removeAttribute('data-rendered');
  document.getElementById('toggleCityListBtn').textContent = 'نمایش تمام شهرها';
  closeStateDrill();
  initCharts();
  initSortableTables();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

/* ---------------- راه‌اندازی اولیه ---------------- */
function initCharts(){
  var byStateSales = DASH.states.slice();
  renderBarChart('salesByStateChart', byStateSales, { valueKey: 'total_sales_amount', labelKey: 'state_name', color: 'var(--accent)', onClick: function(it){ openStateDrill(it.state_name); } });

  var byStateBuyers = DASH.states.slice().sort(function(a,b){ return b.buyer_count - a.buyer_count; });
  renderBarChart('buyersByStateChart', byStateBuyers, { valueKey: 'buyer_count', labelKey: 'state_name', color: 'var(--accent-light)', onClick: function(it){ openStateDrill(it.state_name); } });

  renderComboChart('comboChart', DASH.states, { key: 'invoice_count', label: 'تعداد فاکتور' }, { key: 'total_sales_amount', label: 'مبلغ فروش' });

  renderDonutChart('salesDonutChart', DASH.pie_slices, function(stateName){ openStateDrill(stateName); });
}
initCharts();
initSortableTables();
prefetchOtherChannels(); /* سه تب دیگر را در پس‌زمینه Preload کن تا سوییچ بعدی تب بدون fetch باشد (v04.1) */

/* Export صریح — فقط توابعی که HTML این بات با onclick="..." صدا می‌زند (inline attribute در Global Scope
   اجرا می‌شود، پس باید روی window باشد)؛ بقیهٔ نام‌های این اسکریپت (DASH, CHANNEL_CACHE, applyDashboardUpdate،
   fetchChannelView، ...) عمداً داخل IIFE محبوس می‌مانند و به window نشت نمی‌کنند. */
window.scrollToKpiTarget = scrollToKpiTarget;
window.setActiveChannel = setActiveChannel;
window.resetFilters = resetFilters;
window.openDataQualityCustomers = openDataQualityCustomers;
window.openDataQualityInvoices = openDataQualityInvoices;
window.openCustomerDrillFromRow = openCustomerDrillFromRow;
window.closeStateDrill = closeStateDrill;
window.closeCustomerDrill = closeCustomerDrill;
window.openCustomerDrill = openCustomerDrill;
window.openInvoiceDrill = openInvoiceDrill;
window.openCustomerDrillFromFullList = openCustomerDrillFromFullList;
window.toggleFullScreen = toggleFullScreen;
window.exportToExcel = exportToExcel;
window.openHelp = openHelp;
window.toggleFullCityList = toggleFullCityList;
window.closeHelp = closeHelp;
window.closeInvoiceModal = closeInvoiceModal;
window.closeDqModal = closeDqModal;
})();
</script>
]]

-- ============================================================
-- DASH DATA BUILDER
-- ============================================================

local function build_dash_data(states, cities, default_date_from, default_date_to)
    return {
        states = states,
        cities = cities,
        pie_slices = build_pie_slices(states),
        default_date_from = default_date_from,
        default_date_to = default_date_to,
    }
end

-- ============================================================
-- HTML TEMPLATE — اسکلت کامل صفحه
-- ============================================================

local function render_html(args)
    -- v04.1: فقط تب فعال هنگام رندر صفحه Embed می‌شود (نه هر ۴ تب — ر.ک. یادداشت Performance/Timeout در
    -- main()). سه تب دیگر با درخواست‌های جداگانهٔ پس‌زمینه (prefetchOtherChannels در REPORT_JS) پر می‌شوند.
    local active_channel_json = json.encode(args.active_channel)
    local active_view_json = json.encode(args.active_view):gsub("</", "<\\/")

    local html = {}
    table.insert(html, '<!DOCTYPE html>\n<html dir="rtl" lang="fa">\n<head>\n<meta charset="UTF-8">\n')
    table.insert(html, '<meta name="viewport" content="width=device-width, initial-scale=1.0">\n')
    table.insert(html, '<title>داشبورد جغرافیایی مشتریان و فروش</title>\n')
    table.insert(html, REPORT_CSS)
    table.insert(html, '</head>\n<body>\n<div id="reportRoot">\n')

    table.insert(html, '<div class="toolbar">' ..
        '<button type="button" class="btn-toolbar" onclick="toggleFullScreen()">تمام صفحه</button>' ..
        '<button type="button" class="btn-toolbar" onclick="exportToExcel()">خروجی Excel</button>' ..
        '<button type="button" class="btn-toolbar secondary" onclick="openHelp()">راهنما</button></div>\n')

    table.insert(html, '<header class="hero"><img class="brand140-logo" alt="140" ' ..
        'src="data:image/png;base64,' .. CONFIG.LOGO140_WHITE_B64 .. '">' ..
        '<h1>داشبورد مدیریتی توزیع جغرافیایی مشتریان و فروش</h1>' ..
        '<p class="sub" id="headerSubText">بازه: از ' .. escape_html(args.date_from_label) .. ' تا ' ..
        escape_html(args.date_to_label) .. ' — دسته: ' .. escape_html(args.channel_label) .. ' — تولید در ' ..
        escape_html(args.generated_jdate) .. '</p></header>\n')

    table.insert(html, args.filter_bar_html)

    table.insert(html, '<div class="kpi-grid" id="kpiGrid">' .. args.kpi_cards_html .. '</div>\n')

    table.insert(html, [[
<div class="section">
  <div class="section-head"><h2><span class="num">۱</span>کیفیت دادهٔ جغرافیایی</h2><p>مشتریان/فاکتورهایی که آدرس یا نگاشت جغرافیایی معتبر ندارند — حذف خاموش نشده‌اند</p></div>
  <div class="kpi-grid" id="dataQualityGrid">]] .. args.data_quality_html .. [[</div>
</div>

<div class="section">
  <div class="section-head"><h2><span class="num">۲</span>مشتریان جدید در این بازه</h2><p>مشتریانی که اولین فاکتور معتبرشان (در دستهٔ فعال) در همین بازهٔ تاریخ ثبت شده است</p></div>
  <div class="kpi-grid" id="newCustomersGrid">]] .. args.new_customers_html .. [[</div>
</div>

<div class="section">
  <div class="section-head"><h2><span class="num">۳</span>۱۰ مشتری برتر</h2><p>بر اساس مبلغ خرید در بازهٔ تاریخ و دستهٔ فعال — مستقل از استان/شهر</p></div>
  <div class="table-scroll"><table class="data-table" id="topCustomersTable"><thead><tr>
    <th>#</th><th>نام مشتری</th><th>استان</th><th>شهر</th><th>تعداد فاکتور</th><th>مبلغ خرید</th>
  </tr></thead><tbody id="topCustomersTbody">]] .. args.top_customers_html .. [[</tbody></table></div>
</div>

<div class="section" id="centerComparisonSection" style="]] .. (args.show_center_comparison and "" or "display:none;") .. [[">
  <div class="section-head"><h2><span class="num">۴</span>مقایسهٔ مراکز درآمد</h2><p>فقط در تب «همه» — تعداد فاکتور، مشتری و مبلغ به تفکیک مرکز درآمد واقعی فاکتور (نه فقط B2B/B2C)</p></div>
  <div class="table-scroll"><table class="data-table"><thead><tr>
    <th>مرکز درآمد</th><th>تعداد فاکتور</th><th>تعداد مشتری</th><th>مبلغ فروش</th><th>سهم</th>
  </tr></thead><tbody id="centerComparisonTbody">]] .. args.center_rows_html .. [[</tbody></table></div>
</div>

<div class="section" id="chartsSection">
  <div class="section-head"><h2><span class="num">۵</span>نمودارهای استانی</h2><p>روی هر ردیف/بخش کلیک کنید تا جزئیات همان استان باز شود</p></div>
  <div class="grid-2">
    <div class="card"><h3>مبلغ فروش به تفکیک استان</h3><div class="desc">مرتب‌شده نزولی بر اساس مبلغ فروش</div><div class="chart-box" id="salesByStateChart"></div></div>
    <div class="card"><h3>تعداد مشتری خریدار به تفکیک استان</h3><div class="desc">مقایسهٔ تعداد مشتری فعال هر استان</div><div class="chart-box" id="buyersByStateChart"></div></div>
  </div>
  <div class="grid-2" style="margin-top:16px;">
    <div class="card"><h3>مقایسه تعداد فاکتور و مبلغ فروش</h3><div class="desc">استانی با فاکتور زیاد لزوماً مبلغ بالا ندارد و برعکس</div><div class="chart-box" id="comboChart"></div></div>
    <div class="card"><h3>سهم استان‌ها از کل فروش</h3><div class="desc">استان‌های کوچک زیر ]] .. fmt_dec1(CONFIG.OTHER_SLICE_THRESHOLD_PCT) .. [[٪ در «سایر» گروه شده‌اند — دادهٔ خام همچنان در جدول کامل استان‌ها موجود است</div><div class="chart-box" id="salesDonutChart"></div></div>
  </div>
</div>

<div class="section">
  <div class="section-head"><h2><span class="num">۶</span>بیشترین و کمترین</h2><p>کمترین‌ها فقط در میان استان‌های دارای حداقل یک فروش محاسبه شده‌اند</p></div>
  <div class="minmax-grid" id="minmaxGrid">]] .. args.minmax_html .. [[</div>
</div>

<div class="section" id="stateSection">
  <div class="section-head"><h2><span class="num">۷</span>جدول کامل استان‌ها</h2><p>روی هدر ستون‌ها کلیک کنید تا مرتب شود؛ روی هر ردیف کلیک کنید تا جزئیات استان باز شود</p></div>
  <div class="table-scroll"><table class="data-table" id="stateTable"><thead><tr>
    <th>استان</th><th>تعداد مشتری</th><th>تعداد مشتری خریدار</th><th>تعداد فاکتور</th><th>مبلغ فروش</th>
    <th>میانگین فاکتور</th><th>میانگین فروش/خریدار</th><th>تعداد شهر (مشتری)</th><th>تعداد شهر (فروش)</th>
    <th>سهم از فروش</th><th>سهم از مشتری</th>
  </tr></thead><tbody id="stateTbody">]] .. args.state_rows_html .. [[</tbody></table></div>
</div>

<div class="section" id="citySection">
  <div class="section-head"><h2><span class="num">۸</span>شهرهای برتر بر اساس فروش</h2><p>]] .. fmt_num(CONFIG.TOP_CITIES_ON_DASHBOARD) .. [[ شهر برتر — برای فهرست کامل، «نمایش تمام شهرها» را بزنید</p></div>
  <div class="table-scroll"><table class="data-table" id="topCityTable"><thead><tr>
    <th>استان</th><th>شهر</th><th>تعداد مشتری</th><th>تعداد مشتری خریدار</th><th>تعداد فاکتور</th><th>مبلغ فروش</th><th>میانگین فاکتور</th><th>سهم از فروش استان</th>
  </tr></thead><tbody id="topCityTbody">]] .. args.top_city_rows_html .. [[</tbody></table></div>
  <div style="margin-top:10px;"><button type="button" class="btn-secondary" id="toggleCityListBtn" onclick="toggleFullCityList()">نمایش تمام شهرها</button></div>
  <div id="fullCityListBox" style="display:none;margin-top:14px;">
    <div class="search-box"><input type="text" id="citySearchInput" placeholder="جستجوی شهر یا استان..."></div>
    <div class="table-scroll"><table class="data-table" id="fullCityTable"><thead><tr>
      <th>استان</th><th>شهر</th><th>تعداد مشتری</th><th>تعداد مشتری خریدار</th><th>تعداد فاکتور</th><th>مبلغ فروش</th><th>میانگین فاکتور</th>
    </tr></thead><tbody id="fullCityTbody"></tbody></table></div>
  </div>
</div>

<div id="stateDrillPanel" class="drill-panel" style="display:none;"></div>

<footer id="footerText">]] .. escape_html(args.footer_text) .. [[</footer>
]])

    table.insert(html, [[
<div id="helpModal" class="modal"><div class="modal-content">
  <div class="modal-header"><h3>راهنمای داشبورد</h3><button class="modal-close" onclick="closeHelp()">×</button></div>
  <div class="modal-body">
    <p>این داشبورد توزیع جغرافیایی مشتریان CRM و فروش سازمان را بر پایهٔ دادهٔ زندهٔ Teamyar نشان می‌دهد.</p>
    <h4>KPIهای بالای صفحه</h4>
    <ul>
      <li><b>پوشش جغرافیایی فروش:</b> تعداد شهرهای دارای حداقل یک فروش معتبر، تقسیم بر ]] .. fmt_num(CONFIG.TOTAL_CITIES_IRAN) .. [[ (آمار رسمی شهرهای ایران، سال ۱۴۰۴).</li>
      <li><b>کیفیت دادهٔ جغرافیایی:</b> مشتریان/فاکتورهایی که آدرس معتبر ندارند حذف نشده‌اند، جداگانه شمرده شده‌اند تا کیفیت دادهٔ CRM شفاف بماند.</li>
    </ul>
    <h4>دستهٔ کسب‌وکار (B2B/B2C)</h4>
    <ul>
      <li>تب‌های «همه / B2B (همکار) / B2C (مصرف‌کننده) / سایر» بر اساس مرکز درآمد فاکتور (فروش همکار یا فروش همکار آفلاین = B2B، فروش مصرف کننده = B2C) کل داشبورد را فیلتر می‌کنند — همهٔ KPIها، نمودارها، جدول‌ها و Drill-downهای مرتبط با فروش.</li>
      <li>«سایر» شامل مراکز درآمدی است که نه B2B‌اند نه B2C (حجم بسیار کم، حذف نشده تا شفاف بماند).</li>
      <li>تعداد کل مشتریان CRM و شهر/استان‌های دارای مشتری (نه فروش) مستقل از این تب هستند — چون خودِ مشتری ذاتاً B2B/B2C نیست، فقط خریدهای او دسته دارند.</li>
    </ul>
    <h4>تعامل‌ها</h4>
    <ul>
      <li>فیلترهای بالای صفحه (تاریخ از، استان، شهر، نوع مشتری) کل داشبورد را بر اساس فاکتورهای همان بازه/محدوده فیلتر می‌کنند.</li>
      <li>روی هر ردیف نمودار میله‌ای یا جدول استان‌ها کلیک کنید تا پنل جزئیات همان استان باز شود.</li>
      <li>در پنل استان، روی هر شهر کلیک کنید تا فهرست مشتریان همان شهر (با صفحه‌بندی) بارگذاری شود.</li>
      <li>روی هر مشتری کلیک کنید تا فهرست فاکتورهای او در یک پنجره باز شود؛ لینک «مشاهده CRM» صفحهٔ مشتری را در تب جدید Teamyar باز می‌کند.</li>
      <li>روی هدر هر جدول کلیک کنید تا صعودی/نزولی مرتب شود؛ «نمایش تمام شهرها» فهرست کامل با جستجو را باز می‌کند.</li>
      <li>تمام‌صفحه / خروجی Excel (از جدول کامل استان‌ها) از نوار ابزار بالا در دسترس است.</li>
    </ul>
    <h4>محدودیت شناخته‌شده (v03)</h4>
    <ul>
      <li>هیچ جدول مرجع رسمی «شهرهای ایران» در دیتابیس Teamyar پیدا نشد؛ مخرج KPI پوشش جغرافیایی عددی ثابت و مستند است، نه Query زنده.</li>
      <li>تفکیک B2B/B2C بر اساس نام مرکز درآمد فاکتور (LIKE «همکار»/«مصرف») است، نه یک فیلد دسته‌بندی مستقل — اگر مرکز درآمد جدیدی با نام‌گذاری متفاوت اضافه شود، ممکن است در «سایر» قرار گیرد.</li>
    </ul>
  </div>
</div></div>
<div id="invoiceModal" class="modal"><div class="modal-content">
  <div class="modal-header"><h3 id="invoiceModalTitle">فاکتورها</h3><button class="modal-close" onclick="closeInvoiceModal()">×</button></div>
  <div class="modal-body" id="invoiceModalBody"></div>
</div></div>
<div id="dqModal" class="modal"><div class="modal-content" style="max-width:820px;">
  <div class="modal-header"><h3 id="dqModalTitle">جزئیات کیفیت داده</h3><button class="modal-close" onclick="closeDqModal()">×</button></div>
  <div class="modal-body" id="dqModalBody"></div>
</div></div>
]])

    table.insert(html, '<script id="activeChannelKey" type="application/json">' .. active_channel_json .. '</script>\n')
    table.insert(html, '<script id="activeChannelView" type="application/json">' .. active_view_json .. '</script>\n')
    table.insert(html, REPORT_JS)
    table.insert(html, '</div>\n</body>\n</html>')

    return table.concat(html)
end

-- ============================================================
-- CHANNEL VIEW
-- ============================================================
-- کلید کانال سمت کلاینت هم "" (همه) است (ر.ک. hidden input #channelInput در render_filter_bar) — همان مقدار
-- اینجا هم برای هماهنگی مستقیم (بدون نگاشت جداگانه در JS) استفاده می‌شود. چهار مقدار ممکن ("", "b2b",
-- "b2c", "other") سمت کلاینت در آرایهٔ ALL_CHANNELS در REPORT_JS تکرار شده‌اند (ر.ک. یادداشت v04.1 پایین‌تر
-- در main() دربارهٔ این‌که چرا هر ۴ تب دیگر در یک درخواست واحد سمت سرور محاسبه نمی‌شوند).
local function channel_key_to_filter_value(key)
    if key == "" then return nil end
    return key
end

-- محاسبهٔ کامل یک تب — هر بار فراخوانی این تابع دقیقاً یک تب (channel_key) را محاسبه می‌کند. main() این را
-- فقط برای تب فعال درخواست صدا می‌زند؛ سه تب دیگر با درخواست‌های جداگانهٔ سمت کلاینت (fetchChannelView در
-- REPORT_JS) پر می‌شوند — نه در همین یک درخواست (ر.ک. یادداشت v04.1 در main() برای چرایی این تصمیم).
-- base_filters باید فاقد کلید channel باشد (channel اینجا از channel_key ساخته می‌شود).
local function build_channel_view(date_from_key, date_to_key, date_from_label, date_to_label, generated_jdate, date_warning, base_filters, channel_key)
    local filters = {}
    for k, v in pairs(base_filters) do filters[k] = v end
    filters.channel = channel_key_to_filter_value(channel_key)

    local crm_kpi, crm_err = fetch_crm_kpi(filters)
    if crm_kpi == nil then return nil, "خطا در محاسبهٔ KPI مشتریان: " .. tostring(crm_err) end

    local sales_kpi, sales_err = fetch_sales_kpi(date_from_key, date_to_key, filters)
    if sales_kpi == nil then return nil, "خطا در محاسبهٔ KPI فروش: " .. tostring(sales_err) end

    local states, states_err = fetch_state_aggregation(date_from_key, date_to_key, filters)
    if states == nil then return nil, "خطا در تجمیع استان‌ها: " .. tostring(states_err) end

    local cities, cities_err = fetch_city_aggregation(date_from_key, date_to_key, filters)
    if cities == nil then return nil, "خطا در تجمیع شهرها: " .. tostring(cities_err) end

    local top_customers, tc_err = fetch_top_customers(date_from_key, date_to_key, filters, 10)
    if top_customers == nil then return nil, "خطا در محاسبهٔ مشتریان برتر: " .. tostring(tc_err) end

    local new_stats, nc_err = fetch_new_customers_stats(date_from_key, date_to_key, filters)
    if new_stats == nil then return nil, "خطا در محاسبهٔ مشتریان جدید: " .. tostring(nc_err) end

    local show_center_comparison = (filters.channel == nil)
    local center_rows_html = ""
    if show_center_comparison then
        local centers, cc_err = fetch_center_comparison(date_from_key, date_to_key)
        if centers == nil then return nil, "خطا در مقایسهٔ مراکز درآمد: " .. tostring(cc_err) end
        center_rows_html = render_center_comparison_rows(centers)
    end

    local state_totals_by_name = {}
    for _, s in ipairs(states) do state_totals_by_name[s.state_name] = s end
    enrich_state_list(states, sales_kpi)
    enrich_city_list(cities, state_totals_by_name)
    table.sort(cities, function(a, b) return a.total_sales_amount > b.total_sales_amount end)

    local coverage = {
        cities_with_sales = sales_kpi.cities_with_sales,
        total_cities = CONFIG.TOTAL_CITIES_IRAN,
        pct = fmt_pct(sales_kpi.cities_with_sales, CONFIG.TOTAL_CITIES_IRAN),
    }

    local state_options = {}
    for _, s in ipairs(states) do table.insert(state_options, s.state_name) end

    local footer_text = "تولید شده — " .. fmt_num(#states) .. " استان و " .. fmt_num(#cities) .. " شهر دارای مشتری" ..
        (date_warning and (" — هشدار: " .. date_warning) or "")
    local header_sub_text = "بازه: از " .. tostring(date_from_label) .. " تا " .. tostring(date_to_label) .. " — دسته: " ..
        (CONFIG.CHANNEL_LABELS[filters.channel] or "همه") .. " — تولید در " .. tostring(generated_jdate)

    return {
        dash_data = build_dash_data(states, cities, date_from_label, date_to_label),
        channel_label = CONFIG.CHANNEL_LABELS[filters.channel] or "همه",
        state_options = state_options,
        kpi_cards_html = render_kpi_cards(crm_kpi, sales_kpi, coverage),
        data_quality_html = render_data_quality_cards(crm_kpi, sales_kpi),
        new_customers_html = render_new_customers_cards(new_stats),
        top_customers_html = render_top_customers_rows(top_customers),
        center_rows_html = center_rows_html,
        show_center_comparison = show_center_comparison,
        minmax_html = render_minmax_cards(compute_minmax(states)),
        state_rows_html = render_state_table_rows(states),
        top_city_rows_html = render_city_table_rows(cities, CONFIG.TOP_CITIES_ON_DASHBOARD),
        footer_text = footer_text,
        header_sub_text = header_sub_text,
    }, nil
end

-- ============================================================
-- MAIN
-- ============================================================

local function main()
    local input = teamyar.get_input() or {}

    -- ------------- Drill-down: مشتریان یک شهر (Lazy، پارامتری، مستقل از Dashboard اصلی) -------------
    -- طبق درخواست کاربر: با همان بازهٔ تاریخ فعال (پیش‌فرض سال مالی جاری، مشابه بات ۶۰۰) محاسبه می‌شود.
    if input["action"] == "customers" then
        local state = input["state"]
        local city = input["city"]
        if state == nil or state == "" or city == nil or city == "" then
            teamyar.write_result(json.encode({ ok = false, error = "استان یا شهر مشخص نشده است" }))
            return
        end
        local date_from_key = resolve_active_date_from_key(input)
        if date_from_key == nil then
            teamyar.write_result(json.encode({ ok = false, error = "تعیین بازهٔ زمانی گزارش ممکن نشد" }))
            return
        end
        local date_to_key = resolve_active_date_to_key(input)
        local filters = parse_filters(input)
        local offset = tonumber(input["offset"]) or 0
        if offset < 0 then offset = 0 end
        local limit = CONFIG.CUSTOMER_PAGE_SIZE
        local total, cnt_err = fetch_customers_count(state, city, filters)
        local rows, err = fetch_customers(state, city, filters, date_from_key, date_to_key, limit, offset)
        if rows == nil then
            teamyar.write_result(json.encode({ ok = false, error = "خطا در دریافت فهرست مشتریان: " .. tostring(err or cnt_err) }))
            return
        end
        teamyar.write_result(json.encode({ ok = true, rows = rows, total = total, offset = offset, limit = limit }))
        return
    end

    -- ------------- Drill-down: فاکتورهای یک مشتری (Lazy) -------------
    if input["action"] == "invoices" then
        local crm_id = tonumber(input["crm_id"])
        if crm_id == nil then
            teamyar.write_result(json.encode({ ok = false, error = "شناسه مشتری نامعتبر است" }))
            return
        end
        local date_from_key = resolve_active_date_from_key(input)
        if date_from_key == nil then
            teamyar.write_result(json.encode({ ok = false, error = "تعیین بازهٔ زمانی گزارش ممکن نشد" }))
            return
        end
        local date_to_key = resolve_active_date_to_key(input)
        local filters = parse_filters(input)
        local customer = fetch_customer_header(crm_id)
        local rows, err = fetch_invoices(crm_id, date_from_key, date_to_key, filters)
        if rows == nil then
            teamyar.write_result(json.encode({ ok = false, error = "خطا در دریافت فاکتورها: " .. tostring(err) }))
            return
        end
        teamyar.write_result(json.encode({ ok = true, rows = rows, customer = customer }))
        return
    end

    -- ------------- Drill-down: مشتریان بدون استان/شهر (کارت‌های کیفیت داده) -------------
    if input["action"] == "dq_customers" then
        local field = input["field"]
        if field ~= "city" then field = "state" end
        local offset = tonumber(input["offset"]) or 0
        if offset < 0 then offset = 0 end
        local limit = CONFIG.CUSTOMER_PAGE_SIZE
        local total, cnt_err = fetch_customers_missing_geo_count(field)
        local rows, err = fetch_customers_missing_geo(field, limit, offset)
        if rows == nil then
            teamyar.write_result(json.encode({ ok = false, error = "خطا در دریافت فهرست: " .. tostring(err or cnt_err) }))
            return
        end
        teamyar.write_result(json.encode({ ok = true, rows = rows, total = total, offset = offset, limit = limit, field = field }))
        return
    end

    -- ------------- Drill-down: فاکتورهای بدون نگاشت جغرافیایی (کارت کیفیت داده) -------------
    -- طبق درخواست کاربر: با همان بازهٔ تاریخ فعال محاسبه می‌شود تا با KPI بالای صفحه یکی باشد.
    if input["action"] == "dq_invoices" then
        local date_from_key = resolve_active_date_from_key(input)
        if date_from_key == nil then
            teamyar.write_result(json.encode({ ok = false, error = "تعیین بازهٔ زمانی گزارش ممکن نشد" }))
            return
        end
        local date_to_key = resolve_active_date_to_key(input)
        local filters = parse_filters(input)
        local offset = tonumber(input["offset"]) or 0
        if offset < 0 then offset = 0 end
        local limit = CONFIG.CUSTOMER_PAGE_SIZE
        local total, cnt_err = fetch_invoices_missing_geo_count(date_from_key, date_to_key, filters)
        local rows, err = fetch_invoices_missing_geo(date_from_key, date_to_key, filters, limit, offset)
        if rows == nil then
            teamyar.write_result(json.encode({ ok = false, error = "خطا در دریافت فهرست: " .. tostring(err or cnt_err) }))
            return
        end
        teamyar.write_result(json.encode({ ok = true, rows = rows, total = total, offset = offset, limit = limit }))
        return
    end

    -- ------------- Dashboard اصلی (KPI + State/City Aggregation) -------------
    local filters = parse_filters(input)

    local now_raw, now_err = fetch_now_raw()
    local fy_key, fy_jndate = resolve_fiscal_year_start(now_raw)

    local date_from_key = nil
    local date_from_label = filters.date_from_text
    if filters.date_from_text ~= nil then
        date_from_key = resolve_date_from_text(filters.date_from_text)
    end
    local date_warning = nil
    if date_from_key == nil then
        if filters.date_from_text ~= nil then
            date_warning = "تاریخ واردشده («" .. filters.date_from_text .. "») در تقویم سیستم یافت نشد؛ به ابتدای سال مالی جاری بازگردانده شد."
        end
        date_from_key = fy_key
        date_from_label = fy_jndate
    end
    if date_from_key == nil then
        write_dashboard_error(input, "امکان تعیین بازهٔ زمانی گزارش وجود ندارد (خطا در report_dimdate): " .. tostring(now_err))
        return
    end

    local date_to_key, date_to_label = resolve_active_date_to_key(input)
    if date_to_key == nil then
        write_dashboard_error(input, "امکان تعیین انتهای بازهٔ زمانی گزارش وجود ندارد (خطا در report_dimdate).")
        return
    end

    local generated_jdate = fy_jndate -- برچسب مرجع؛ برای «امروز» دقیق کافی نیست، صرفاً نمایشی است

    -- رفع باگ v04.1 (گزارش زندهٔ کاربر، بعد از دیپلوی: کلیک روی تب باز هم «ارور JSON» می‌داد): نسخهٔ اول
    -- Preload هر ۴ تب را در یک درخواست واحد محاسبه می‌کرد (۴× حجم Query، شامل ۴ بار اجرای Subquery سنگین
    -- بدون فیلتر تاریخ INVOICE_AMOUNT_JOIN که خودش قبلاً به‌عنوان ریسک Performance مستند شده بود) — این به
    -- محدودیت max_execute_time سرور Teamyar می‌خورد و پلتفرم به‌جای پاسخ Lua یک صفحهٔ خطای HTML برمی‌گرداند؛
    -- write_dashboard_error این نوع خطای سطح پلتفرم (نه خطای Lua) را اصلاً نمی‌بیند، پس نمی‌توانست کمکی کند.
    -- رفع شد: هر درخواست فقط تب فعال را (مثل قبل از v04) محاسبه می‌کند — سریع، هم‌سنگین قبل. Preload سه تب
    -- دیگر اکنون سمت کلاینت و در پس‌زمینه (fetchChannelView/prefetchOtherChannels در REPORT_JS، هرکدام یک
    -- درخواست جدا بعد از رندر تب فعال) انجام می‌شود — نه در همان درخواست اول، هم Timeout حل شد هم «سوییچ تب
    -- بدون Round-trip» (بعد از این‌که پیش‌بارگذاری پس‌زمینه تمام شد) حفظ ماند.
    local active_channel_key = filters.channel or ""
    local base_filters = {}
    for k, v in pairs(filters) do
        if k ~= "channel" then base_filters[k] = v end
    end
    local active_view, verr = build_channel_view(date_from_key, date_to_key, date_from_label, date_to_label,
        generated_jdate, date_warning, base_filters, active_channel_key)
    if active_view == nil then
        write_dashboard_error(input, verr)
        return
    end

    local state_options = active_view.state_options
    local user_type_options = { 3, 4 }

    if input["format"] == "json" then
        teamyar.write_result(json.encode({
            ok = true,
            active_channel = active_channel_key,
            view = active_view,
        }))
        return
    end

    local filter_bar_html = render_filter_bar(filters, date_from_label, date_to_label, state_options, user_type_options)

    local html = render_html({
        active_channel = active_channel_key,
        active_view = active_view,
        date_from_label = date_from_label,
        date_to_label = date_to_label,
        channel_label = active_view.channel_label,
        generated_jdate = generated_jdate,
        filter_bar_html = filter_bar_html,
        kpi_cards_html = active_view.kpi_cards_html,
        data_quality_html = active_view.data_quality_html,
        new_customers_html = active_view.new_customers_html,
        top_customers_html = active_view.top_customers_html,
        center_rows_html = active_view.center_rows_html,
        show_center_comparison = active_view.show_center_comparison,
        minmax_html = active_view.minmax_html,
        state_rows_html = active_view.state_rows_html,
        top_city_rows_html = active_view.top_city_rows_html,
        footer_text = active_view.footer_text,
    })
    teamyar.write_result(html)
end

local ok, err = pcall(main)
if not ok then
    -- طبق همان اصل write_dashboard_error: اگر خطای پیش‌بینی‌نشده (Runtime، نه یکی از چک‌های صریح بالا) هنگام
    -- یک درخواست format=json رخ دهد، باز هم باید JSON قابل‌Parse برگردد، نه یک صفحهٔ HTML که «Unexpected
    -- token '<'» ایجاد می‌کند. چون در این نقطه دیگر داخل main() نیستیم و به متغیر input آن دسترسی نداریم،
    -- ورودی را مجدداً (با pcall، چون get_input هم می‌تواند خودش خطا بدهد) می‌خوانیم.
    local ok2, input_for_error = pcall(teamyar.get_input)
    if ok2 and input_for_error ~= nil and input_for_error["format"] == "json" then
        teamyar.write_result(json.encode({ ok = false, error = tostring(err) }))
    else
        teamyar.write_result(render_error_html(tostring(err)))
    end
end

