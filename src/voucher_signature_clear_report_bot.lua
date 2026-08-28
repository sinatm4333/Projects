-- تحلیل و ایجاد توسط سینا مقدم 09121011778
-- Last Edit = 1405/06/04 19:45

-- Bot: Voucher Signature Clear (پاک‌سازی امضای سند حسابداری فاکتور فروش)
-- botName = voucher_signature_clear_report
-- version = v04
--
-- تغییرات v04 (بعد از گزارش زندهٔ کاربر: «HTML لود شد، پاپ‌آپ بسته شد، لودینگ فراخوانی آمد ولی
-- چیزی لود نکرد» + پیشنهاد صریح کاربر: «از رویهٔ بات ۶۱۲ و دستورات res_v2 برای فراخوانی استفاده کن»):
--   علت: مقصد XHR روی `window.location.href` بود. ولی صفحه‌ای که کاربر می‌بیند صفحهٔ **پنلِ** بات است
--   (`?page=/bot/command/view&id=617&cat_id=79&tab=0` — در رجیستری همان `view_url`)، نه آدرس اجرای بات
--   (`/bot/run/443/VoucherSignatureClear` — همان `run_url`). پس POST روی صفحهٔ پنل می‌نشست و چیزی که
--   برمی‌گشت قطعهٔ گزارش نبود؛ چون کد کورکورانه innerHTML می‌کرد، نتیجه «هیچی» دیده می‌شد.
--   رفع (دقیقاً همان قراردادی که کاربر گفت — `{{_bot_path}}` در res_v2، و همان کاری که بات
--   signed_invoices از اول می‌کرد):
--     ۱) آدرس اجرا سمت سرور از `teamyar.self().run_path` ساخته و به JS تزریق می‌شود
--        (`TYVSC_BOT_URL`)؛ `window.location.href` فقط fallback است.
--     ۲) هر دو فراخوانی (پیش‌نمایش و اجرا) با `credentials: 'same-origin'` به همان آدرس می‌روند.
--     ۳) دیگر هیچ پاسخی کورکورانه رندر نمی‌شود: قطعهٔ پیش‌نمایش نشانهٔ `tyvsc-fragment` دارد و اگر
--        نبود، خطای روشن با آدرس مقصد و ابتدای پاسخ نشان داده می‌شود؛ مسیر اجرا هم پاسخ غیر-JSON را
--        به‌جای شکست خاموش، با متن واقعی گزارش می‌کند. سکوت دیگر ممکن نیست.
--     ۴) مسیر فراخوانی در خود گزارش (زیر «فیلتر دامنه») نمایش داده می‌شود تا اگر باز هم اشتباه بود،
--        بدون کنسول مرورگر قابل تشخیص باشد.
--     ۵) تفکیک عملیات با `?type=N` روی Query String هم فرستاده می‌شود (نه فقط فیلد `action` در بدنه) —
--        عیناً الگوی بات ۶۱۳ «Factor Settlement By Selection» که کاربر معرفی کرد: در `data.js` آن،
--        `sendSettleRequest` به `report[reportPath].botPath + "?type=201"` پست می‌کند، نه به آدرس صفحه.
--        پارامترهای فیلتر هم در هر دو کانال (Query و بدنه) می‌روند، تا اگر لایهٔ get_input فیلدهای
--        multipart بدنه را نچیند، درخواست باز هم درست مسیردهی شود. سمت سرور `type=101` (پیش‌نمایش) و
--        `type=201` (اجرا) به‌عنوان جایگزین `action` پذیرفته می‌شوند.
--   یادداشت دربارهٔ پیشنهاد res_v2: بازنویسی کامل بات روی چارچوب RES عمداً انجام **نشد** — طبق قاعدهٔ
--   خود CLAUDE.md («ترجیح بده اشکال را جراحی‌وار رفع کنی، نه بازنویسی کامل روی RES») و چون رندر RES از
--   طریق `$.Teamyar.table` است و کل طراحی ایمنی این بات (پیش‌نمایش/تأیید/سقف/بازرسی یکپارچگی) را
--   می‌ریزد. آنچه از res_v2 لازم بود، همین قرارداد آدرس‌دهی `{{_bot_path}}` بود که اعمال شد.
--
-- تغییرات v03 (بعد از گزارش زندهٔ کاربر: «پاپ‌آپ راهنما بسته نمی‌شود» + «تمام صفحه کار نمی‌کند»):
--   ریشهٔ هر دو باگ یکی بود: CSS این بات **بدون دامنه** نوشته شده بود. کلاس‌های کاملاً عمومی
--   (`.modal`، `.toolbar`، `.section`، `.btn-primary`، `.chip`، `.notice`، `header.hero`) و حتی
--   `html,body` و `*` مستقیم روی صفحهٔ پرتال Teamyar می‌نشستند. پرتال خودش برای همین نام‌ها CSS
--   دارد، پس برخورد دوطرفه بود: قواعد پرتال قواعد ما را می‌شکست و قواعد ما هم صفحهٔ پرتال را.
--   مدرک قطعی در اسکرین‌شات کاربر: لوگوی ۱۴۰ به‌جای `height:34px` در اندازهٔ طبیعی (۲۴۱×۱۰۰) رندر
--   شده و روی نوار هشدار افتاده بود — یعنی قاعدهٔ پرتال بر قاعدهٔ ما غالب شده بود. همان اتفاق برای
--   `.modal` یعنی پاپ‌آپ با کلاس بسته نمی‌شد، و برای `.pseudo-fullscreen` یعنی تمام‌صفحه بی‌اثر بود.
--   رفع:
--     ۱) همهٔ سلکتورها با «#tyvscRoot » دامنه‌بندی شدند (ویژگی 1,1,0 در برابر 0,1,0 پرتال، پس
--        مستقل از ترتیب بارگذاری استایل‌شیت‌ها برنده‌اند). `html,body` حذف شد و قانون فونت
--        CLAUDE.md به ریشهٔ گزارش محدود شد — هدفش (تک‌فونت بودن گزارش) حفظ است ولی دیگر کل پرتال
--        را بازنویسی نمی‌کند.
--     ۲) پاپ‌آپ راهنما به داخل ریشه منتقل شد (بیرون از ریشه هیچ استایلی نمی‌گرفت) و باز/بسته شدنش
--        با Style درون‌خطیِ important کنترل می‌شود، نه با کلاس — تا هیچ CSS بیرونی نتواند بازش نگه دارد.
--     ۳) تمام‌صفحه علاوه بر کلاس، Style درون‌خطی هم می‌گذارد (و متن دکمه را به «خروج از تمام صفحه»
--        عوض می‌کند تا برگشت هم واضح باشد).
--     ۴) همهٔ رویدادها به واگذاری (delegation) روی document منتقل شدند و onclick درون‌خطی حذف شد.
--        دو دلیل: اگر HTML بات بعد از بارگذاری پرتال تزریق شود DOMContentLoaded قبلاً شلیک شده و
--        اتصال‌های داخلش هرگز برقرار نمی‌شوند؛ و `#resultBox` با هر پیش‌نمایش بازسازی می‌شود و
--        اتصال مستقیم به دکمه‌های داخلش می‌پرد. هر عملیات ریشهٔ خودش را با closest پیدا می‌کند.
--
-- تغییر v02 (بعد از گزارش زندهٔ کاربر: «بعد از فیلتر یک صفحهٔ سفید ظاهر می‌شود»):
--   v01 فرم فیلتر را با `method="get"` می‌فرستاد، یعنی ناوبری بومی مرورگر. داخل شِل/iframe واقعی
--   Teamyar این ناوبری آدرس اجرای بات را از دست می‌دهد و نتیجه صفحهٔ سفید است — دقیقاً همان چیزی که
--   در `sales_revenue_center_dashboard_report_bot.lua` هم ثبت شده بود («document.write کل صفحه یا
--   iframe تودرتو هر دو داخل شِل/Iframe واقعی Teamyar شکست می‌خورند؛ روش سالم fetch همین آدرس +
--   جایگزینی innerHTML بخش‌هاست»). این قانون به v01 اعمال نشده بود.
--   حالا: ارسال بومی فرم غیرفعال است، فیلتر با `action=preview` قطعهٔ نتیجه را fetch می‌کند و جای
--   `#resultBox` می‌گذارد. چون دکمه‌های داخل آن قطعه با هر پیش‌نمایش دوباره ساخته می‌شوند، کلیک
--   «شروع پاک‌سازی» هم از اتصال مستقیم به واگذاری رویداد (delegation) روی `#tyvscRoot` منتقل شد.
--
-- ============================================================================
-- خواستهٔ کاربر (نقل مستقیم)
-- ============================================================================
-- «در اصل باید کسی با دسترسی که امکان امضا دارد برود سند حسابداری متصل به فاکتور را امضا کند، بعد سند را
--  ویرایش کند — مثلاً با افزودن یک اسپیس در توضیحات — و بعدش امضاها حذف می‌شود. این مورد در اصل در ماژول
--  حسابداری باید اتفاق بیفتد.»
-- دامنهٔ خواسته‌شده: «دسته‌ای بر اساس فیلتر».
--
-- یعنی این بات همان کارِ دستیِ اپراتور را دسته‌ای انجام می‌دهد: سند حسابداریِ متصل به هر فاکتورِ داخل فیلتر
-- را از طریق **ماژول حسابداری (module_id=10)** ویرایش می‌کند تا پلتفرم خودش امضاها را باطل کند.
--
-- ============================================================================
-- ⚠ سه نکتهٔ صادقانه که قبل از اولین اجرای واقعی باید بدانید
-- ============================================================================
-- ۱) «حذف امضا با ویرایش سند» یک **عارضهٔ جانبی پلتفرم** است، نه یک API مستند. در پورتال API تیم‌یار،
--    ماژول حسابداری ۲۴ endpoint دارد و **هیچ‌کدام «امضا» یا «حذف امضا» نیست** (ر.ک. جدول کامل در
--    docs/context/TeamyarInternalApiReference.md). آنچه اینجا استفاده می‌شود `voucher/records_update`
--    (#۱۰، «آپدیت شرح رکورد حسابداری، گروهی») است — همان «ویرایش توضیحات» که شما دستی انجام می‌دهید.
--    اینکه مسیر API هم همان منطقِ باطل‌کنندهٔ امضا را در پلتفرم فعال کند **تأیید نشده است**.
--    ➜ به همین دلیل این بات بعد از هر سند، `pa_voucher_signs` را دوباره می‌خواند و **تعداد واقعی امضای
--      حذف‌شده** را گزارش می‌کند. اولین اجرای واقعی، خودش آزمونِ این فرضیه است. اگر پلتفرم امضا را باطل
--      نکند، بات آن را «بی‌اثر» گزارش می‌کند و ادامه نمی‌دهد — هیچ ادعای موفقیت جعلی داده نمی‌شود.
--
-- ۲) گام «اول امضا کن» از کار دستیِ شما **قابل خودکارسازی نیست** — چون API امضا وجود ندارد. اگر سندی
--    برای ویرایش‌شدن نیاز به امضای شما داشته باشد، آن گام باید دستی در پنل انجام شود. برای همین ستون‌های
--    `LOCK_VOUCHER` / `STATUS` / `CHANGED_FLAG` در پیش‌نمایش نشان داده می‌شوند تا اسناد قفل/بسته را قبل از
--    اجرا ببینید.
--
-- ۳) این عملیات **برگشت‌ناپذیر** است: امضای باطل‌شده با اجرای دوباره برنمی‌گردد. به همین دلیل:
--      • حالت پیش‌فرض «پیش‌نمایش» است و **هیچ نوشتنی** انجام نمی‌دهد.
--      • اجرا نیاز به تایپ عبارت تأیید صریح دارد (CONFIRM_PHRASE).
--      • سقف پیش‌فرض هر اجرا **۱ سند** است (حالت آزمون). بالا بردن آن آگاهانه با خودِ کاربر است.
--      • پیش از هر نوشتن، تصویرِ قبلیِ رکورد در لاگ ثبت می‌شود تا بازگردانی دستی ممکن باشد.
--
-- ============================================================================
-- طراحی نوشتن — چرا Payload حداقلی
-- ============================================================================
-- schema مستندِ «Voucher record» حدود ۴۰ فیلد دارد که نگاشت چند تای آن به ستون‌های واقعی
-- `pa_voucher_record` قطعی نیست (`row_index`, `number_sort`, `cost_rate`, `fee_rate`, `symbol_rate`, ...).
-- فرستادن یک Payload کاملِ حدسی می‌تواند فیلدهای سالم (DEB/CRD/ACCOUNT_ID) را با مقدار غلط بازنویسی کند —
-- یعنی خرابیِ دادهٔ مالی. پس پیش‌فرض `PAYLOAD_MODE = "minimal"` است: فقط `id`, `org_id`, `voucher_id`,
-- `content`. اگر API فیلد بیشتری لازم داشته باشد، در اجرای آزمونِ تک‌سندی خطا می‌دهد و آن‌وقت آگاهانه
-- `full` انتخاب می‌شود — نه اینکه از اول کورکورانه همه‌چیز فرستاده شود.
--
-- و مهم‌تر: بعد از هر نوشتن، رکورد دوباره از دیتابیس خوانده و با تصویرِ قبلی مقایسه می‌شود. اگر هر ستونی
-- جز CONTENT تغییر کرده باشد، کل اجرا **فوراً متوقف** می‌شود (ABORT) و گزارش داده می‌شود.
--
-- ============================================================================
-- تغییر متن توضیحات — چرا «یک فاصله در انتها»
-- ============================================================================
-- همان کاری که کاربر دستی می‌کند. Toggle است: اگر CONTENT به فاصله ختم شود، فاصله برداشته می‌شود؛ وگرنه
-- یک فاصله اضافه می‌شود. پس معنای شرح هرگز عوض نمی‌شود و اجرای دوباره هم متن را باد نمی‌کند.
--
-- ============================================================================
-- مسیر دسترسی (کارایی) — عیناً از منطق بات signed_invoices
-- ============================================================================
-- `pa_voucher_record` روی نصب بیمه‌لند حدود ۱۴٫۸ میلیون ردیف و `pa_voucher_signs` حدود ۱۷٫۵ میلیون ردیف
-- دارد. پس هیچ‌جا روی جدول اسناد جمع‌بندی بی‌کران زده نمی‌شود. ترتیب همیشه «اول فاکتور، بعد سند»:
--   ۱) صفحهٔ فاکتورها فقط از sales_invoice        -> IDX2(RUN_DATE)
--   ۲) اسناد فقط برای شناسه‌های همان صفحه         -> IDX14(REFFERE_ID, TOOLS_ID, R_TYPE)
--   ۳) امضاها فقط برای اسناد همان صفحه            -> PRIMARY(VOUCHER_ID, ORG_ID, USER_ID)
--   ۴) جمع‌بندی در Lua، نه در SQL
--
-- REFFERE_ID یک ارجاع چندریختی است؛ بدون فیلتر R_TYPE شناسهٔ فاکتور فروش با اسناد حقوق/خرید/انبار برخورد
-- می‌کند. مقادیر معتبر فاکتور فروش (از teamyar_sdk/Interfaces/IPro_Accounting.h):
--   VOUCHER_TYPE_SALES_INVOICE_TYPE   = 14  (فاکتور فروش)
--   VOUCHER_TYPE_SALES_RETURN_INVOICE = 22  (برگشت از فروش)
--
-- وضعیت امضا (pa_voucher_signs.SIGN): 0 = تعیین‌شده ولی امضا نکرده، 1 = امضا کرده، 2 = رد کرده.

-- ============================================================
-- CONFIG
-- ============================================================

local CONFIG = {
    -- انواع مرجع سند برای فاکتور فروش — literal، هرگز از ورودی کاربر نمی‌آید
    R_TYPES = "14,22",

    -- سقف‌های ایمنی
    PREVIEW_INVOICE_LIMIT = 500,   -- سقف فاکتور در پیش‌نمایش (فقط خواندنی)
    EXECUTE_CAP_DEFAULT   = 1,     -- سقف پیش‌فرض سند در هر اجرا = حالت آزمون تک‌سندی
    EXECUTE_CAP_MAX       = 200,   -- سقف مطلق؛ بالاتر از این پذیرفته نمی‌شود
    SIGN_CHUNK            = 40,    -- اندازهٔ دستهٔ خواندن امضاها

    -- عبارت تأییدی که کاربر باید عیناً تایپ کند تا اجرا شروع شود
    CONFIRM_PHRASE = "حذف امضا",

    -- حالت ساخت Payload برای voucher/records_update: "minimal" یا "full" (ر.ک. یادداشت بالای فایل)
    PAYLOAD_MODE_DEFAULT = "minimal",

    ACCOUNTING_MODULE_ID = 10,
    RECORDS_UPDATE_PATH  = "/api/voucher/records_update",

    INVOICE_VIEW_URL_PREFIX = "/?page=/sales/invoice/view_invoice/",

    -- لوگو «۱۴۰» (الزام CLAUDE.md برای بات‌های HTML جدید) — نسخهٔ White چون روی نوار Accent هدر می‌نشیند
    -- (assets/brand140/logo140-mark-white.b64.txt — طبق قانون Background-pairing گایدلاین برند ۱۴۰)
    LOGO140_WHITE_B64 = "iVBORw0KGgoAAAANSUhEUgAAAPEAAABkCAYAAABXYNb5AAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAA9rSURBVHhe7Z15bFz7VccLtGUp/FWBRKFiK2YpuAVUtrKoLAVURAWqVCGWqkWIklZlEUJQeK7aB61KaYHqvZe+vCx2Fu8erzPet/E+seM13mI78ZI8O44d746370HnvpnUOR47HnvuGc/M+UhfOZKde8/vN7/PeGZ87++8CcAogEcu5z6AHgCZAP4awDvfFCMA5IepTyN/KWvRAMA/AViIQV6WtWgA4ANhaol25gHcA9AM4OsAPgTg22UtagBYJmUArAK4BCBF1uM2AOplPRoA+KSsRQMAX5C1aADguqxFAwC/L2vRAMAdAP8YE5n5WUUWpAWAdQD/IGtyEwBVsg4N+BWIrEUDAJ+TtSiRLmvRAMAHZSGaAOgD8H5Zl6vEUuIQAC7KutzCJFYjKSVmAOwC+LiszTXOgsQMgGuyNjcwidVIWolDADgn63OFsyIxo/E+yiRWI+klZgB8WtYYdc6SxAx/gi1rjCYmsRomcRAAn5F1RpWzJjEDIFvWGS1MYjVM4n0A+HtZa9Q4ixIzAHJkrdHAJFbDJBbwn6BkvVHhrErMAMgjom+RNZ8Gk1gNkzgMfPGNrPnUnGWJGQAFRPStsu6TYhKrYRIfAoB/lnWfirMuMQPAEy2RTWI1TOKj+RdZ+4mJB4kZAEVE9G2y/kgxidUwiZ8DgH+V9Z+IeJGYAVBMRG+WY4iEJJT487IWJUziYwDg3+QYIiaeJGYAlJ5GZJNYDZP4mAB4QY4jIuJNYgaAl4jeIsdyHExiNUziCOC3PXIsxyYeJWYA+IjorXI8z8MkVsMkjhB+rOR4jkW8SswAqIj0/k2TWA2T+AQAeFGO6bnEs8QMgMpIRDaJ1TCJTwiA/5TjOpJ4l5gBUE1E3yHHFg6TWA2T+BQA+JIc26EkgsQMgFoA3ynHJzGJ1TCJTwmAL8vxhSVRJGYA1BHRd8kx7sckVsMkjgIAviLHeIBEkjhIw1Eim8RqmMRRAsBX5TifIQEl5kE3AnibHCtjEqthEkcRAF+TY31KIkrMAGgiou8OM16TWAeTOMoA+F85XodElZgJbu79PWK8fI+yOjGU+EVZixImsQvwZvVyzAktcRB+j/z0Ek0AX5Q/oIFJrEOiS8wc+LArCSTmQV/YN94Py+9rYBLrkAwSMwD+Yv+g1+QPJCLc3iM43rdzGxn5fbcB8LH9i02LWL0nBpAha9GAezHJWhIRACsAvj806ECwj4xqVlfXtlZW12h5ZdW1bG4+2T/o/tDuILyb5jMzosCjxaV/v5DhScnI8jrJ4ni8KR5vdYq32p9S7e9I6ejoSenpGUwZHBxPmZl5mLK8vJzC/apOmRcB9AIYD5OJQ3L3kHATMZnJQ3IRwLu0s7u7+1G51jSys7M7tbLC69m9Nc2+7OzsPF1TAM47EvNuGbHIleuFA5l55XTleqFL8dDVrGIqq2igyakHoUF/MCjx+/b5pUJTaxfOX8zeu3zN4yQjs2gvM7dsL7+ocq/UV79XXduy19zSudfZ1b83ODS2Nzn1YG9hcWlve3tnD8Bpwh0p37fvsX5zMPv/LfOWQ/LWcOFr18Pk08F2JtqplGtNI9dzy957NauE0jOLw6zF6CUzt4zq/R3Ok0Wwl9n37X8losqljPz+6zleunS1wLVczMin85ey6ZXXsmhi0hH56fs03qReiuYmzW236NXLuZR+o8jJtewSys73kaekhrwVfqpraKe29m7q7hmkkdG7NHN/jpaWVwmQR4ocAHMA3vPsI+Au3AVS1qEBgBpZiwYX0vPezY/r5euFB9ZhNPNaeh69fCHTEXp9Y4vH+wlZixqXr3kGbuT66PI1j+u5mFFA6ZklNDQycYefNfn8wffG03IRuEVTaxedv5j9tKaMzCLnWTW/qJJKffVUXdtCzS2d1NnVT4NDY86rh4XFJdrZ2ZWHOhEAFkO/kTUA8LeyBg34OgBZiwbpmcWpGfxbmEUOswajHf6FUFbRRPPzi652TDkS919OPxseeG5hxfbCwsLTBuf824mbRsuF4AaxlpgB8BjALz77SLhDskmcmVmcyi+nHZHDrD83cjW7lMqrm3tkLWpcyy4ZyC2qcl5WauR6TinleCqotKLxmUUM4OcAPJKLIdqcBYmDLAH4pf1z4AZJJ3GeLzUzz0s3cssOrD23kp1fTll53hlZixo5Bb6BYm8d5RT4VJLrKacSXwMP/HdkLUT0Xrf/Xn6GJGZY5F+R8xBNkk3ivOKaVH4s8worDqw9t+IpqaacfN+8rEWNwtLqgYrqFioqrVFJcVktVda2Uomv0fmEWhJ8af1QLopoccYk5sW+DOBX5TxEi2STuNjnT+XHscRbd2DtuRVvRSMVllbHTuKKqsaBhqabVF7lV0lFdRP5mzupsrY5rMQMgJ/lT3LlwogGZ01iJnjBwPvlPESDZJO4pqYttaq2hSprmg+sPbdSU9/GX2MncX1j+0BHoJcaGttV0ujvoEBnPzU23zxUYgbAzwCYlYvjtJxFiRm+eg3Ar8t5OC3JJrG/rSu1qfkm+ZsCB9aeW2lp6+avsZO4vb1noLdvhNo7elTCTxj9A3fo5s3+IyVmALwbwOtygZyGsyoxw5feAvgNOQ+nIdkk7urqS73Z1U+Bzj5qD/So5FbPIK/t2Enc2zc0cGdsivr6hlXS3z9C4+PT1N8/+lyJGQA/DeCNS72iwFmWmAmK/JtyHk5Kskk8PDyeevv2HRoYGD2w9tzK8PAE9fYNxU7isbF7Aw9ef0Rj45MqGZ+Yotm5BZqYmDyWxAyAn+LLFuVCOQlnXWImeBnfB+Q8nIRkk3h8fDr13uQDmrg7fWDtuZWp6VkaG5uMncSzs/MDq2ubNDv3SCVzDxecy9Tm5h4dW2KGiH4SwIxcLJESDxIzADYA/Jach0hJNokXFxdTHy0s0cP5xQNrz608Xlql2dn52Em8vr4xwJcFr29sqmQjeEfT5uZmRBIzwbuBTnWJZrxIzADYJKIDf0+PhGSTeGtrK3V7e4eePNmiDV5vCtnd3aP19c3YSQxgQD4AGoTuZIoUAD8OYEoe77jEk8QMiwzgd+U8HJdkkxhAqqxFA75ISdaiRrxJzATvWZ2UxzwO8SYxA+DJSecrJDEAtTB7e3smsRbxKDED4Mf4Znh53OcRjxIzALZCu6JEwsrK+jn+/3yjvFZY45WVNZNYi3iVmCGiH+WdLuSxjyJeJWaCIv+BnIejmHkwd27zya5zX7RWVtee0MyDOZNYi3iWmAHwI7zFjTz+YcSzxAyAbQAfkvNwGKOjd889nF9yNjjQyoPXF2hk5K5JrEW8S8wQ0Q8DGJPnCEe8S8wA2AHwh3IewtHbO3ju3r3XqbvntlrGxqepp+e2SaxFIkjMAPgh3ihNnkeSCBIzQZH/SM6DpK3t1rnBoQlqbbullr6BO9Ta3m0Sa5EoEjMA3glgVJ5rP4kiMRPckO7Dch72U9fQdq6ze4hq69vU0nGzn+oa201iLRJJYgbADwIYkecLkUgSM8GdNP9YzkMIX6X/XHNbD3krGtTS0NRJvspGk1iLRJOYAfADAIblORl/gknMBEX+EzkPTEFJzadq6jvIU1yllsqaVr5J3iTWIhElZgC8A8CQPG9L2y165WJWQknM4A0+Iuchu6D8b8oqm3gPKLXw9ks5+T6TWItElZjh9hpyfAODd5z9ghNNYiacyL5K/0c8pbXOBv5XM3WSX1RD17NLTGIt5CLXQkNiBsD3AvCHzsstOJzNvzPyE05iJijyb4fG//jx2s8X++qdzc6vBJ+43E52QSWlXy80ibVIdIkZbokC4L9D5x4amaCXXr3hdKZINIkZ3vo31OQLwNvG707Np98opgtX8g4I50ZMYmUA9MmClPg1WYvbAPgJ7hLI+1mN37tPnrJ6yi2spsKyOvJWNlFNQ4ezX9Kt7iEaGp6gyalZWlhcoe2dPVn7mQdAwb5xe2YfLjobnfNbiW9cynE6F7iVazle+sblHN+zs68DX1Mv50IDR2Ii+gXeTDwGOfYli9EEwGfC1OJ2eM8ubjLGn15/dPzu9FeKvHUFWXnexvyiqo5Sb32gqrY50NTcGejs7AvcHrwTuDd5P/Bo4XFga2uHu1aeNB2rq2szC4vLzs3q7mTBecXA99KG2N7edrbCDfWCXl1bp67u21RR0+y86igt5zREPdX17VRV29IRZv418mf715kWjsS8ban8hhF9APyVfPbW4MLlnM9mF1bTa+n5LiXPeXvAHTZa2m85dxIByONzc98rAINyLozoEZJYpRdRshOr7nVXrhW8kFtUe6C7XrTDMr/0aiYVe+v5dkDedO/tfH4AvyfnwogeIYldbV9ivAGAj0vBNLhyzZOWV1x74EMgt/Lya1nU1NbDzbCf3vEE4KtyPozoYBIrEjOJbxSl5ZfUHeio52Y8pfXUGuj97P46uDe0nBPj9JjEisRK4htZJWklvka+CEItRd4Gyiksf0XWAuCKnBfjdJjEisRK4hxPRVpFTSvlFpSrpbyqhb+my1oYAJfk3BgnxyRWJFYSl5TVpdU3dTldIbVS579JRWW1YSVmAFyU82OcDJNYkVhJXFHTnNYe6He6QmqltaOPKqr8h0rMALgg58iIHJNYkVhJ7PcH0nr6RqnB36GW7t5havC3HykxA+BVOU9GZJjEisRK4kCgJ230zhR1BLgzpE5GRu9x177nSswAOC/nyjg+JrEisZK4r284beb+vNMVUivT03PU1z98LIkZAK/I+TKOh0msSKwkHpuYSlta3nC6Qmpl8fEajY9PHVtiBsBLcs6M52MSKxIriWcfPkrb3SOnK6RWdnZBsw/nI5KYAfB1OW/G0ZjEisRK4o2NJ2l8/s3NJ2oJni9iiRkA/yfnzjgck1iRWEkMwJE4BpxIYgbA/8iDGeExiRUxiSMDwNfkAY2DmMSKmMSRs39rIyM8JrEiJvHJAPBf8sDGNzGJFTGJTw6AL8uDG29gEitiEp8OAF+SJzBMYlVM4tMD4IvyJMmOSayISRwdAPyHPFEyYxIrYhJHDwBfkCdLVkxiRUzi6ALg8/KEyYhJrIhJHH0AfE6eNNkwiRUxid0BwAvyxMmESayISeweAD4FIH46z0URk1gRk9hdAPwygDZZRKITkvibnbAM1wDwSbnwNIjVRRKhfkzaAPhTAHUAtmVNiQj7y4O+CqDI4nqeNuDWhLswAigOU4+b4fP9naxFEwDvAvDnfMkmgBthakyUXJVjNwzDMAzDMAzDMAzDMAzDMAzDMAzDMAzDMAzDMNzi/wF4AZG1vKLsrgAAAABJRU5ErkJggg==",
}

local INV_TYPE_TEXT = {
    [1] = "فاکتور فروش",
    [2] = "پیش‌فاکتور",
    [3] = "برگشت از فروش",
    [4] = "فاکتور فروشگاهی",
    [5] = "سفارش فروش",
    [6] = "حواله فروش",
    [7] = "قرارداد",
}

-- دامنهٔ انتخاب سند بر اساس وضعیت امضای آن
local SCOPE_STATES = {
    signed = "اسنادی که حداقل یک امضا دارند",
    full   = "اسنادی که همهٔ امضاکنندگانشان امضا کرده‌اند",
    any    = "همهٔ اسناد فاکتورهای فیلتر (حتی بدون امضا)",
}

local PAYLOAD_MODES = { minimal = true, full = true }

-- ============================================================
-- HELPERS
-- ============================================================

-- پیاده‌سازی مرجع escape_html (طبق CLAUDE.md، الزامی — هر Entity با Concatenation ساخته می‌شود، نه
-- Literal؛ رشتهٔ Entity پیوستهٔ Literal هنگام ذخیرهٔ command توسط Teamyar بی‌صدا Decode می‌شود و کامپایل
-- را می‌شکند — تأیید زندهٔ 1405/05/23).
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

-- برای مقادیری که داخل رشتهٔ تک‌کوتیشنی JS می‌نشینند. escape_html اینجا غلط است: داخل <script>
-- موجودیت‌های HTML رمزگشایی نمی‌شوند، پس «&#39;» عیناً در رشته می‌ماند.
local function escape_js_string(value)
    if value == nil then return "" end
    return tostring(value)
        :gsub("\\", "\\\\")
        :gsub("'", "\\'")
        :gsub("\r", "")
        :gsub("\n", "")
        :gsub("<", "\\x3C")
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

local function trim(value)
    if type(value) ~= "string" then return "" end
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- ارقام فارسی/عربی -> لاتین (کاربر ممکن است ۱۴۰۵/۰۶/۰۱ تایپ کند)
local DIGIT_MAP = {
    ["۰"] = "0", ["۱"] = "1", ["۲"] = "2", ["۳"] = "3", ["۴"] = "4",
    ["۵"] = "5", ["۶"] = "6", ["۷"] = "7", ["۸"] = "8", ["۹"] = "9",
    ["٠"] = "0", ["١"] = "1", ["٢"] = "2", ["٣"] = "3", ["٤"] = "4",
    ["٥"] = "5", ["٦"] = "6", ["٧"] = "7", ["٨"] = "8", ["٩"] = "9",
}

local function latin_digits(value)
    if type(value) ~= "string" then return "" end
    return (value:gsub("[\216-\219][\128-\191]", function(ch) return DIGIT_MAP[ch] or ch end))
end

local function placeholders(count)
    local parts = {}
    for i = 1, count do parts[i] = "?" end
    return table.concat(parts, ", ")
end

-- خروجی time.get_shamsi_str به شکل "1405.6.4 14:05:09" است
local function fmt_jalali_datetime(value, with_time)
    local n = tonumber(value) or 0
    if n <= 0 then return "—" end
    local ok, text = pcall(time.get_shamsi_str, n)
    if not ok or type(text) ~= "string" then return "—" end
    local y, mo, d, hh, mi = text:match("^(%d+)%.(%d+)%.(%d+)%s+(%d+):(%d+)")
    if not y then return text end
    local out = string.format("%04d/%02d/%02d", tonumber(y), tonumber(mo), tonumber(d))
    if with_time then out = out .. " " .. hh .. ":" .. mi end
    return out
end

-- "1405/06/01" یا "1405-6-1" یا با ارقام فارسی -> FILETIME
local function parse_jalali_date(text, end_of_day)
    text = trim(latin_digits(text))
    if text == "" then return nil end
    local y, m, d = text:match("^(%d%d%d%d)%D(%d%d?)%D(%d%d?)$")
    if not y then return nil end
    y, m, d = tonumber(y), tonumber(m), tonumber(d)
    if m < 1 or m > 12 or d < 1 or d > 31 then return nil end
    local parts = { year = y, month = m, day = d, hour = 0, minute = 0, second = 0 }
    if end_of_day then parts.hour, parts.minute, parts.second = 23, 59, 59 end
    local ok, filetime = pcall(time.get_shamsi_filetime, parts)
    if not ok or type(filetime) ~= "number" or filetime <= 0 then return nil end
    return filetime
end

-- ============================================================
-- DATABASE HELPERS
-- ============================================================

-- ردیف‌ها را با نام ستون برمی‌گرداند. نام ستون‌ها صریح پاس داده می‌شود (نه SELECT *) تا اندیس عددی
-- در کد پخش نشود — روی جدولی با ۳۳ ستون، اندیس عددی منبع اشتباه است.
local function fetch_rows(query, params, column_names)
    pcall(function() db.use_db("0000000") end)

    local ok, err = pcall(function()
        db.query({ query = query, params = params or {} })
    end)
    if not ok then return nil, tostring(err) end

    local rows = {}
    local record = {}
    while db.query_fetch(record) do
        local row = {}
        for i = 1, #record do
            row[i] = record[i]
            if column_names and column_names[i] then row[column_names[i]] = record[i] end
        end
        table.insert(rows, row)
    end
    db.query_free()
    return rows
end

local function log_line(text)
    pcall(function() teamyar.write_log("voucher_signature_clear | " .. tostring(text)) end)
end

-- ============================================================
-- ACCESS GUARD
-- ============================================================
-- این بات با SQL خام روی دادهٔ مالی همهٔ سازمان‌ها کار می‌کند و **می‌نویسد**. لایهٔ دسترسی ماژول‌ها را
-- دور می‌زند، پس Public access باید خاموش بماند و اسکریپت خودش هم آن را رد می‌کند.

local function resolve_actor()
    local ok_self, self_info = pcall(teamyar.self)
    if ok_self and type(self_info) == "table" and tonumber(self_info.is_public) == 1 then
        return nil, "این بات نباید عمومی (public) باشد؛ روی دادهٔ مالی همهٔ سازمان‌ها می‌نویسد. " ..
                    "لطفاً «دسترسی عمومی» را در تنظیمات بات خاموش کنید."
    end

    local ok_user, user_info = pcall(teamyar.get_user_info)
    if not ok_user or type(user_info) ~= "table" then
        return nil, "کاربر شناسایی نشد. این بات فقط برای کاربران واردشده قابل اجراست."
    end

    local user_id = tonumber(user_info.id) or 0
    if user_id <= 0 then
        return nil, "کاربر شناسایی نشد. این بات فقط برای کاربران واردشده قابل اجراست."
    end

    return { id = user_id, name = tostring(user_info.fullname or user_info.name or "") }, nil
end

-- ============================================================
-- INPUT
-- ============================================================

local function read_filters(input)
    input = input or {}

    local function param(name)
        local value = input[name]
        if value == nil then return "" end
        return trim(tostring(value))
    end

    local filters = { warnings = {} }

    filters.org = tonumber(latin_digits(param("org"))) or 0
    if filters.org < 0 then filters.org = 0 end

    filters.invoice_type = tonumber(latin_digits(param("itype"))) or 0
    if not INV_TYPE_TEXT[filters.invoice_type] then filters.invoice_type = 0 end

    filters.scope = param("scope")
    if not SCOPE_STATES[filters.scope] then filters.scope = "signed" end

    filters.payload_mode = param("payload_mode")
    if not PAYLOAD_MODES[filters.payload_mode] then filters.payload_mode = CONFIG.PAYLOAD_MODE_DEFAULT end

    -- شناسهٔ یک فاکتور مشخص — راه امن برای آزمون اولیه روی دقیقاً یک فاکتور
    filters.invoice_id = tonumber(latin_digits(param("invoice_id"))) or 0
    if filters.invoice_id < 0 then filters.invoice_id = 0 end

    filters.date_from_text = param("date_from")
    filters.date_to_text   = param("date_to")
    filters.date_from = parse_jalali_date(filters.date_from_text, false)
    filters.date_to   = parse_jalali_date(filters.date_to_text, true)

    if filters.date_from_text ~= "" and not filters.date_from then
        table.insert(filters.warnings, "تاریخ «از» نامعتبر بود و نادیده گرفته شد (قالب درست: ۱۴۰۵/۰۱/۳۱).")
    end
    if filters.date_to_text ~= "" and not filters.date_to then
        table.insert(filters.warnings, "تاریخ «تا» نامعتبر بود و نادیده گرفته شد (قالب درست: ۱۴۰۵/۰۱/۳۱).")
    end
    if filters.date_from and filters.date_to and filters.date_from > filters.date_to then
        table.insert(filters.warnings, "تاریخ «از» بعد از «تا» بود؛ جای دو تاریخ عوض شد.")
        filters.date_from, filters.date_to = filters.date_to, filters.date_from
        filters.date_from_text, filters.date_to_text = filters.date_to_text, filters.date_from_text
    end

    -- بدون هیچ فیلتری، دامنه یعنی «کل تاریخچهٔ فروش». برای یک عملیات برگشت‌ناپذیر این پذیرفته نیست.
    filters.has_scope = (filters.invoice_id > 0) or (filters.date_from ~= nil) or (filters.date_to ~= nil)

    filters.execute_cap = tonumber(latin_digits(param("cap"))) or CONFIG.EXECUTE_CAP_DEFAULT
    if filters.execute_cap < 1 then filters.execute_cap = 1 end
    if filters.execute_cap > CONFIG.EXECUTE_CAP_MAX then
        filters.execute_cap = CONFIG.EXECUTE_CAP_MAX
    end

    filters.confirm = param("confirm")

    return filters
end

-- ============================================================
-- QUERY LAYER — خواندن دامنه
-- ============================================================

-- شرط‌های ارزان: فقط ستون‌های sales_invoice. هیچ مقدار ورودی داخل رشتهٔ SQL نمی‌رود.
local function build_invoice_where(filters)
    local clauses = { "COALESCE(si.DELETED, 0) = 0", "COALESCE(si.CANCELED, 0) = 0" }
    local params = {}

    if filters.invoice_id > 0 then
        table.insert(clauses, "si.ID = ?")
        table.insert(params, filters.invoice_id)
    end
    if filters.org > 0 then
        table.insert(clauses, "si.ORG_ID = ?")
        table.insert(params, filters.org)
    end
    if filters.invoice_type > 0 then
        table.insert(clauses, "si.TYPE = ?")
        table.insert(params, filters.invoice_type)
    end
    if filters.date_from then
        table.insert(clauses, "si.RUN_DATE >= ?")
        table.insert(params, filters.date_from)
    end
    if filters.date_to then
        table.insert(clauses, "si.RUN_DATE <= ?")
        table.insert(params, filters.date_to)
    end

    return " WHERE " .. table.concat(clauses, "\n  AND "), params
end

local INVOICE_COLUMNS = { "invoice_row", "org_id", "invoice_no", "invoice_code", "invoice_title",
                          "invoice_type", "invoice_date", "client_name", "org_name" }

local function fetch_invoices(filters)
    local where_sql, params = build_invoice_where(filters)

    local query =
        "SELECT si.ID, si.ORG_ID, si.INVOICE_ID, si.invoice_code, si.TITLE," ..
        " si.TYPE, si.RUN_DATE, cl.NAME, oi.NAME" ..
        " FROM sales_invoice si" ..
        "\nLEFT JOIN pa_client cl ON cl.ID = si.CLIENT_ID AND cl.ORG_ID = si.ORG_ID" ..
        "\nLEFT JOIN org_info oi ON oi.ID = si.ORG_ID" ..
        where_sql ..
        "\nORDER BY si.RUN_DATE DESC, si.ID DESC" ..
        "\nLIMIT " .. tostring(CONFIG.PREVIEW_INVOICE_LIMIT)

    return fetch_rows(query, params, INVOICE_COLUMNS)
end

local VOUCHER_COLUMNS = { "invoice_row", "org_id", "voucher_id", "voucher_no", "voucher_title",
                          "voucher_content", "voucher_status", "voucher_locked", "voucher_changed",
                          "voucher_date" }

-- اسناد فقط برای شناسه‌های همین صفحه. ORG_ID عمداً در IN نیست تا IDX14(REFFERE_ID) قابل استفاده بماند؛
-- تطبیق سازمان در Lua انجام می‌شود.
local function fetch_vouchers_for_invoices(invoice_rows)
    if #invoice_rows == 0 then return {} end

    local ids, seen = {}, {}
    for _, row in ipairs(invoice_rows) do
        local id = tonumber(row.invoice_row) or 0
        if id > 0 and not seen[id] then
            seen[id] = true
            table.insert(ids, id)
        end
    end
    if #ids == 0 then return {} end

    local query =
        "SELECT DISTINCT pvr.REFFERE_ID, pvr.ORG_ID, pv.ID, pv.VOUCHER_ID, pv.TITLE," ..
        " pv.CONTENT, pv.STATUS, pv.LOCK_VOUCHER, pv.CHANGED_FLAG, pv.RUN_DATE" ..
        " FROM pa_voucher_record pvr" ..
        "\nINNER JOIN pa_voucher pv ON pv.ID = pvr.VOUCHER_ID AND pv.ORG_ID = pvr.ORG_ID" ..
        "\n   AND COALESCE(pv.DELETED, 0) = 0" ..
        "\nWHERE pvr.R_TYPE IN (" .. CONFIG.R_TYPES .. ")" ..
        "\n  AND COALESCE(pvr.DELETED, 0) = 0" ..
        "\n  AND pvr.REFFERE_ID IN (" .. placeholders(#ids) .. ")" ..
        -- ترتیب قطعی لازم است: پیش‌نمایش می‌گوید «این n سندِ اول پردازش می‌شوند» و اجرا باید دقیقاً
        -- همان‌ها را بردارد. بدون ORDER BY، ترتیب بین دو درخواست تضمینی نیست.
        "\nORDER BY pv.ID ASC"

    return fetch_rows(query, ids, VOUCHER_COLUMNS)
end

local SIGN_COLUMNS = { "voucher_id", "org_id", "user_id", "user_name", "sign_state", "sign_date" }

-- امضاها فقط برای اسناد همین صفحه، با PRIMARY(VOUCHER_ID, ORG_ID, USER_ID). هر سند می‌تواند ده‌ها
-- امضاکننده داشته باشد، پس در دسته‌های کوچک خوانده می‌شود.
local function fetch_signs(voucher_ids)
    local out = {}
    if #voucher_ids == 0 then return out end

    local index = 1
    while index <= #voucher_ids do
        local chunk = {}
        for j = index, math.min(index + CONFIG.SIGN_CHUNK - 1, #voucher_ids) do
            table.insert(chunk, voucher_ids[j])
        end

        local query =
            "SELECT pvs.VOUCHER_ID, pvs.ORG_ID, pvs.USER_ID," ..
            " COALESCE(NULLIF(pm.FULLNAME, ''), CONCAT('کاربر ', pvs.USER_ID)), pvs.`SIGN`, pvs.DATE_SIGN" ..
            " FROM pa_voucher_signs pvs" ..
            "\nLEFT JOIN profile_main pm ON pm.ID = pvs.USER_ID" ..
            "\nWHERE pvs.VOUCHER_ID IN (" .. placeholders(#chunk) .. ")"

        local rows = fetch_rows(query, chunk, SIGN_COLUMNS)
        if rows then
            for _, row in ipairs(rows) do table.insert(out, row) end
        end

        index = index + CONFIG.SIGN_CHUNK
    end

    return out
end

-- تعداد امضاهای یک سند مشخص — برای تأیید «قبل/بعد» دور هر نوشتن
local function count_signs(voucher_id, org_id)
    local rows = fetch_rows(
        "SELECT COUNT(*), SUM(CASE WHEN pvs.`SIGN` = 1 THEN 1 ELSE 0 END)" ..
        " FROM pa_voucher_signs pvs WHERE pvs.VOUCHER_ID = ? AND pvs.ORG_ID = ?",
        { voucher_id, org_id }, { "total_rows", "signed_rows" })

    if rows == nil or #rows == 0 then return nil, nil end
    return tonumber(rows[1].total_rows) or 0, tonumber(rows[1].signed_rows) or 0
end

-- ============================================================
-- SCOPE BUILDER — فاکتور -> سند -> امضا، همه در Lua جمع‌بندی می‌شود
-- ============================================================

local function build_scope(filters)
    local invoice_rows, invoice_err = fetch_invoices(filters)
    if invoice_rows == nil then
        return nil, "خطا در خواندن فاکتورها: " .. tostring(invoice_err)
    end

    local voucher_rows, voucher_err = fetch_vouchers_for_invoices(invoice_rows)
    if voucher_rows == nil then
        return nil, "خطا در خواندن اسناد حسابداری: " .. tostring(voucher_err)
    end

    local invoice_by_key = {}
    for _, row in ipairs(invoice_rows) do
        invoice_by_key[tostring(row.invoice_row) .. "|" .. tostring(row.org_id)] = row
    end

    -- یک سند دسته‌ای می‌تواند بین چند فاکتور مشترک باشد. کلید یکتا = سند، نه فاکتور — وگرنه یک سند
    -- چند بار ویرایش می‌شود.
    local vouchers, voucher_order = {}, {}
    for _, row in ipairs(voucher_rows) do
        local invoice = invoice_by_key[tostring(row.invoice_row) .. "|" .. tostring(row.org_id)]
        if invoice then
            local key = tostring(row.voucher_id) .. "|" .. tostring(row.org_id)
            local entry = vouchers[key]
            if not entry then
                entry = {
                    key = key,
                    voucher_id = tonumber(row.voucher_id) or 0,
                    org_id = tonumber(row.org_id) or 0,
                    voucher_no = row.voucher_no,
                    title = row.voucher_title,
                    content = row.voucher_content,
                    status = tonumber(row.voucher_status) or 0,
                    locked = tonumber(row.voucher_locked) or 0,
                    changed = tonumber(row.voucher_changed) or 0,
                    voucher_date = row.voucher_date,
                    invoices = {},
                    signers = {},
                    signed_count = 0,
                    pending_count = 0,
                    rejected_count = 0,
                }
                vouchers[key] = entry
                table.insert(voucher_order, entry)
            end
            table.insert(entry.invoices, invoice)
        end
    end

    local voucher_ids = {}
    for _, entry in ipairs(voucher_order) do
        if entry.voucher_id > 0 then table.insert(voucher_ids, entry.voucher_id) end
    end

    for _, sign in ipairs(fetch_signs(voucher_ids)) do
        local entry = vouchers[tostring(sign.voucher_id) .. "|" .. tostring(sign.org_id)]
        if entry then
            local state = tonumber(sign.sign_state) or 0
            table.insert(entry.signers, {
                name = sign.user_name,
                state = state,
                -- DATE_SIGN فقط وقتی SIGN=1 است معنا دارد؛ در حالت «منتظر» زمانِ ایجاد ردیف است
                date = (state == 1) and (tonumber(sign.sign_date) or 0) or 0,
            })
            if state == 1 then entry.signed_count = entry.signed_count + 1
            elseif state == 2 then entry.rejected_count = entry.rejected_count + 1
            else entry.pending_count = entry.pending_count + 1 end
        end
    end

    -- فیلتر دامنه بر اساس وضعیت امضا
    local selected = {}
    for _, entry in ipairs(voucher_order) do
        local include = false
        if filters.scope == "any" then
            include = true
        elseif filters.scope == "signed" then
            include = (entry.signed_count > 0)
        elseif filters.scope == "full" then
            include = (entry.signed_count > 0) and (entry.pending_count == 0)
        end
        if include then table.insert(selected, entry) end
    end

    return {
        invoice_count = #invoice_rows,
        invoice_truncated = (#invoice_rows >= CONFIG.PREVIEW_INVOICE_LIMIT),
        voucher_total = #voucher_order,
        vouchers = selected,
    }
end

-- ============================================================
-- WRITE LAYER — ویرایش سند از طریق ماژول حسابداری
-- ============================================================

-- تصویر کامل رکورد سند. همهٔ ستون‌ها صریح لیست شده‌اند (نه SELECT *) تا مقایسهٔ «قبل/بعد» قطعی باشد.
local RECORD_COLUMNS = {
    "id", "org_id", "voucher_id", "run_date", "date_modify", "date_create",
    "pdc", "pdc_id", "record_sort", "action", "fx", "content",
    "account_id", "floating_account_id", "client_id", "center_id", "project_id",
    "type", "deleted", "reffere_id", "manual_ref_id", "r_type", "tools_id",
    "symbol_id", "fx_crd", "fx_deb", "crd", "deb",
    "rel_type", "rel_id", "rel_record_id",
}

local RECORD_SELECT_SQL =
    "SELECT pvr.ID, pvr.ORG_ID, pvr.VOUCHER_ID, pvr.RUN_DATE, pvr.DATE_MODIFY, pvr.DATE_CREATE," ..
    " pvr.PDC, pvr.PDC_ID, pvr.RECORD_SORT, pvr.ACTION, pvr.FX, pvr.CONTENT," ..
    " pvr.ACCOUNT_ID, pvr.FLOATING_ACCOUNT_ID, pvr.CLIENT_ID, pvr.CENTER_ID, pvr.PROJECT_ID," ..
    " pvr.TYPE, pvr.DELETED, pvr.REFFERE_ID, pvr.MANUAL_REF_ID, pvr.R_TYPE, pvr.TOOLS_ID," ..
    " pvr.SYMBOL_ID, pvr.FX_CRD, pvr.FX_DEB, pvr.CRD, pvr.DEB," ..
    " pvr.REL_TYPE, pvr.REL_ID, pvr.REL_RECORD_ID" ..
    " FROM pa_voucher_record pvr"

-- رکوردی که ویرایش می‌شود: اولین ردیفِ حذف‌نشدهٔ سند. کدام ردیف باشد فرقی نمی‌کند — چیزی که امضا را
-- باطل می‌کند «ویرایش شدنِ سند» است، نه محتوای خاصِ یک ردیف.
local function fetch_target_record(voucher_id, org_id)
    local rows, err = fetch_rows(
        RECORD_SELECT_SQL ..
        " WHERE pvr.VOUCHER_ID = ? AND pvr.ORG_ID = ? AND COALESCE(pvr.DELETED, 0) = 0" ..
        " ORDER BY pvr.RECORD_SORT ASC, pvr.ID ASC LIMIT 1",
        { voucher_id, org_id }, RECORD_COLUMNS)

    if rows == nil then return nil, tostring(err) end
    if #rows == 0 then return nil, "سند هیچ ردیف حذف‌نشده‌ای ندارد" end
    return rows[1], nil
end

local function fetch_record_by_id(record_id, org_id)
    local rows, err = fetch_rows(
        RECORD_SELECT_SQL .. " WHERE pvr.ID = ? AND pvr.ORG_ID = ? LIMIT 1",
        { record_id, org_id }, RECORD_COLUMNS)

    if rows == nil then return nil, tostring(err) end
    if #rows == 0 then return nil, "رکورد بعد از نوشتن پیدا نشد" end
    return rows[1], nil
end

-- طول بر حسب کاراکتر UTF-8، نه بایت. `#text` در Lua بایت می‌شمارد و متن فارسی دوبایتی است؛ سقف
-- ستون CONTENT در MySQL بر حسب کاراکتر است (varchar(500))، پس مقایسه باید کاراکتری باشد.
local function utf8_length(text)
    local count = 0
    for index = 1, #text do
        local byte = text:byte(index)
        -- بایت‌های ادامه (10xxxxxx) شمرده نمی‌شوند
        if byte < 128 or byte >= 192 then count = count + 1 end
    end
    return count
end

-- Toggle یک فاصلهٔ انتهایی — همان «افزودن یک اسپیس در توضیحات» که کاربر دستی انجام می‌دهد.
-- Toggle است تا اجرای دوباره متن را باد نکند و معنای شرح هرگز عوض نشود.
-- خروجی: متن جدید، یا nil به همراه دلیل اگر تغییرِ بی‌ضرر ممکن نباشد.
local function toggle_trailing_space(content)
    local text = tostring(content or "")

    -- حالت ساده: فاصلهٔ انتهایی هست، برمی‌داریم. همیشه بی‌خطر است.
    if text:sub(-1) == " " then return text:sub(1, -2), nil end

    -- CONTENT ستون varchar(500) است. اگر جا نباشد، افزودن فاصله باعث بریده‌شدن متن توسط دیتابیس
    -- می‌شود — یعنی از دست رفتن شرح. در این حالت سند رد می‌شود، نه اینکه متن قربانی شود.
    if utf8_length(text) >= 500 then
        return nil, "شرح ردیف سند به سقف ۵۰۰ کاراکتر رسیده و افزودن فاصله باعث بریده‌شدن متن می‌شود؛ " ..
                    "این سند باید دستی ویرایش شود."
    end

    return text .. " ", nil
end

-- ستون‌هایی که مقایسهٔ یکپارچگی روی آنها انجام **نمی‌شود**: خودِ متنی که عمداً عوض کرده‌ایم، و مُهر
-- زمانی ویرایش که طبیعتاً باید عوض شود.
local INTEGRITY_SKIP = { content = true, date_modify = true }

-- اگر هر ستونی جز این دو تغییر کرده باشد، یعنی Payload ما به رکورد مالی آسیب زده است.
local function diff_record(before, after)
    local changed = {}
    for _, column in ipairs(RECORD_COLUMNS) do
        if not INTEGRITY_SKIP[column] then
            local old_value = tostring(before[column])
            local new_value = tostring(after[column])
            if old_value ~= new_value then
                table.insert(changed, column .. ": " .. old_value .. " -> " .. new_value)
            end
        end
    end
    return changed
end

-- Payload برای voucher/records_update.
--   minimal (پیش‌فرض) — فقط چیزی که برای شناسایی رکورد و تغییر شرح لازم است. امن‌ترین حالت.
--   full            — نگاشت کاملِ فیلدهایی که با اطمینان به ستون دیتابیس نگاشت می‌شوند. فیلدهای مستندی
--                     که نگاشتشان قطعی نیست (row_index, number_sort, cost_rate, fee_rate, symbol_rate,
--                     cash, cash_id) عمداً فرستاده نمی‌شوند — حدس زدنشان یعنی ریسک خرابی دادهٔ مالی.
local function build_record_payload(record, new_content, payload_mode)
    local payload = {
        id = tonumber(record.id) or 0,
        org_id = tonumber(record.org_id) or 0,
        voucher_id = tonumber(record.voucher_id) or 0,
        content = new_content,
    }

    if payload_mode ~= "full" then return payload end

    payload.pdc = tonumber(record.pdc) or 0
    payload.pdc_id = tonumber(record.pdc_id) or 0
    payload.date = tonumber(record.run_date) or 0
    payload.type = tonumber(record.type) or 0
    payload.action = tonumber(record.action) or 0
    payload.debtor = tonumber(record.deb) or 0
    payload.creditor = tonumber(record.crd) or 0
    payload.fx_debtor = tonumber(record.fx_deb) or 0
    payload.fx_creditor = tonumber(record.fx_crd) or 0
    payload.deleted = tonumber(record.deleted) or 0
    payload.account_id = tonumber(record.account_id) or 0
    payload.floating_id = tonumber(record.floating_account_id) or 0
    payload.client_id = tonumber(record.client_id) or 0
    payload.center_id = tonumber(record.center_id) or 0
    payload.project_id = tonumber(record.project_id) or 0
    payload.symbol_id = tonumber(record.symbol_id) or 0
    payload.tools_id = tonumber(record.tools_id) or 0
    payload.rel_type = tonumber(record.rel_type) or 0
    payload.rel_id = tonumber(record.rel_id) or 0
    payload.rel_record_id = tonumber(record.rel_record_id) or 0
    payload.reference_id = tonumber(record.reffere_id) or 0
    payload.reference_type = tonumber(record.r_type) or 0
    payload.manual_ref_id = tonumber(record.manual_ref_id) or 0
    payload.date_create = tonumber(record.date_create) or 0

    return payload
end

local function describe_api_error(response)
    if type(response) ~= "table" then return "پاسخ API قابل خواندن نبود" end
    if type(response.error) == "table" then
        local message = tostring(response.error.message or "")
        local status = tostring(response.error.status or "")
        if message ~= "" or status ~= "" then
            return "API خطا داد (status=" .. status .. "): " .. message
        end
    end
    local ok_encode, encoded = pcall(json.encode, response)
    if ok_encode then return "API موفق نبود: " .. tostring(encoded) end
    return "API موفق نبود"
end

-- یک سند را ویرایش می‌کند و **واقعاً بررسی می‌کند** که چند امضا حذف شد.
-- خروجی: جدول نتیجه با یکی از وضعیت‌های:
--   cleared     — امضاها کم شدند (مکانیزم کار کرد)
--   skipped     — سند بدون نوشتن رد شد (شرح به سقف ۵۰۰ کاراکتر رسیده)
--   no_write    — API موفق گفت ولی شرح در دیتابیس عوض نشد (مشکل Payload/endpoint، نه مکانیزم امضا)
--   no_effect   — ویرایش واقعاً نوشته شد ولی هیچ امضایی حذف نشد (مکانیزم از مسیر API فعال نمی‌شود)
--   api_failed  — خودِ فراخوانی API موفق نبود
--   read_failed — رکورد/شمارش خوانده نشد
--   integrity   — رکورد مالی آسیب دید ➜ کل اجرا باید متوقف شود
local function clear_voucher_signatures(entry, payload_mode, actor)
    local result = {
        voucher_id = entry.voucher_id,
        org_id = entry.org_id,
        voucher_no = entry.voucher_no,
        signs_before = 0,
        signs_after = 0,
        removed = 0,
        status = "read_failed",
        message = "",
    }

    local record, record_err = fetch_target_record(entry.voucher_id, entry.org_id)
    if record == nil then
        result.message = "خواندن ردیف سند ممکن نشد: " .. tostring(record_err)
        return result
    end

    local signs_before, signed_before = count_signs(entry.voucher_id, entry.org_id)
    if signs_before == nil then
        result.message = "شمارش امضاهای قبل از ویرایش ممکن نشد"
        return result
    end
    result.signs_before = signs_before
    result.signed_before = signed_before

    local new_content, content_err = toggle_trailing_space(record.content)
    if new_content == nil then
        result.status = "skipped"
        result.message = tostring(content_err)
        return result
    end

    local payload = build_record_payload(record, new_content, payload_mode)

    -- تصویر قبلی در لاگ می‌ماند تا اگر لازم شد بازگردانی دستی ممکن باشد
    local ok_before_json, before_json = pcall(json.encode, record)
    log_line("PRE-IMAGE | actor=" .. tostring(actor.id) ..
             " | voucher=" .. tostring(entry.voucher_id) .. "/" .. tostring(entry.org_id) ..
             " | record=" .. tostring(record.id) ..
             " | signs_before=" .. tostring(signs_before) ..
             " | row=" .. (ok_before_json and tostring(before_json) or "encode_failed"))

    -- API آرایه‌ای از رکوردها می‌گیرد (schema #۱۰: «گروهی»)
    local ok_call, response = pcall(teamyar.call_api,
        CONFIG.ACCOUNTING_MODULE_ID, CONFIG.RECORDS_UPDATE_PATH, { payload })

    if not ok_call then
        result.status = "api_failed"
        result.message = "فراخوانی API خطا داد: " .. tostring(response)
        log_line("API-THROW | voucher=" .. tostring(entry.voucher_id) .. " | " .. tostring(response))
        return result
    end

    local ok_response_json, response_json = pcall(json.encode, response)
    log_line("API-RESULT | voucher=" .. tostring(entry.voucher_id) ..
             " | " .. (ok_response_json and tostring(response_json) or "encode_failed"))

    if type(response) ~= "table" or response.success ~= true then
        result.status = "api_failed"
        result.message = describe_api_error(response)
        return result
    end

    -- یکپارچگی: هیچ ستونی جز CONTENT/DATE_MODIFY نباید عوض شده باشد
    local after_record, after_err = fetch_record_by_id(record.id, record.org_id)
    if after_record == nil then
        result.status = "integrity"
        result.message = "بعد از نوشتن، رکورد قابل خواندن نبود (" .. tostring(after_err) ..
                         "). برای احتیاط اجرا متوقف شد."
        return result
    end

    -- تفکیک مهم برای اجرای آزمون: اگر API «موفق» گفته ولی شرح در دیتابیس اصلاً عوض نشده، مشکل از
    -- Payload/endpoint است، نه از مکانیزم باطل‌کنندهٔ امضا. این دو را نباید با هم قاطی کرد.
    if tostring(after_record.content) == tostring(record.content) then
        result.status = "no_write"
        result.message = "API پاسخ موفق داد ولی شرح ردیف سند در دیتابیس عوض نشد — یعنی " ..
                         "voucher/records_update با این Payload چیزی ننوشت. اگر حالت Payload روی " ..
                         "«حداقلی» است، یک بار با «کامل» امتحان کنید."
        log_line("NO-WRITE | voucher=" .. tostring(entry.voucher_id) ..
                 " | payload_mode=" .. tostring(payload_mode))
        return result
    end

    local changed = diff_record(record, after_record)
    if #changed > 0 then
        result.status = "integrity"
        result.message = "رکورد مالی جز شرح تغییر کرد: " .. table.concat(changed, " | ") ..
                         " — اجرا فوراً متوقف شد. تصویر قبلی در لاگ بات ثبت است."
        log_line("INTEGRITY-ABORT | voucher=" .. tostring(entry.voucher_id) ..
                 " | changed=" .. table.concat(changed, " | "))
        return result
    end

    local signs_after, signed_after = count_signs(entry.voucher_id, entry.org_id)
    if signs_after == nil then
        result.status = "read_failed"
        result.message = "شمارش امضاهای بعد از ویرایش ممکن نشد"
        return result
    end

    result.signs_after = signs_after
    result.signed_after = signed_after
    result.removed = signs_before - signs_after

    if result.removed > 0 then
        result.status = "cleared"
        result.message = "امضاها باطل شد"
    elseif (signed_before or 0) > (signed_after or 0) then
        -- ردیف امضا باقی مانده ولی وضعیتش از «امضا شده» برگشته — این هم یعنی مکانیزم کار کرده
        result.status = "cleared"
        result.removed = (signed_before or 0) - (signed_after or 0)
        result.message = "وضعیت امضاها به «امضانشده» برگشت"
    else
        result.status = "no_effect"
        result.message = "ویرایش سند موفق بود ولی هیچ امضایی حذف/باطل نشد — یعنی مکانیزم پلتفرم از مسیر " ..
                         "API فعال نمی‌شود و این کار باید دستی در ماژول حسابداری انجام شود."
    end

    log_line("RESULT | voucher=" .. tostring(entry.voucher_id) ..
             " | status=" .. result.status ..
             " | before=" .. tostring(signs_before) .. " after=" .. tostring(signs_after))

    return result
end

-- اجرای دسته‌ای. با اولین سندِ «بی‌اثر» یا «آسیب یکپارچگی» متوقف می‌شود — ادامه دادن روی مکانیزمی که
-- ثابت نشده کار می‌کند، فقط سند خراب می‌کند بدون اینکه امضایی پاک شود.
local function execute_batch(scope, filters, actor)
    local results = {}
    local summary = { cleared = 0, skipped = 0, no_write = 0, no_effect = 0, api_failed = 0,
                      read_failed = 0, integrity = 0, removed_total = 0, processed = 0, written = 0,
                      aborted = false, abort_reason = "" }

    log_line("BATCH-START | actor=" .. tostring(actor.id) .. " (" .. tostring(actor.name) .. ")" ..
             " | scope=" .. tostring(filters.scope) ..
             " | payload_mode=" .. tostring(filters.payload_mode) ..
             " | cap=" .. tostring(filters.execute_cap) ..
             " | candidates=" .. tostring(#scope.vouchers))

    for _, entry in ipairs(scope.vouchers) do
        -- سقف روی «سندهایی که واقعاً نوشته شدند» است، نه سندهایی که بی‌نوشتن رد شدند
        if summary.written >= filters.execute_cap then break end

        local result = clear_voucher_signatures(entry, filters.payload_mode, actor)
        table.insert(results, result)
        summary.processed = summary.processed + 1
        summary[result.status] = (summary[result.status] or 0) + 1
        if result.status ~= "skipped" then summary.written = summary.written + 1 end
        if result.removed > 0 then summary.removed_total = summary.removed_total + result.removed end

        if result.status == "integrity" then
            summary.aborted = true
            summary.abort_reason = "یکپارچگی رکورد مالی نقض شد. " .. result.message
            break
        end
        if result.status == "no_effect" then
            summary.aborted = true
            summary.abort_reason = "ویرایش از مسیر API امضا را باطل نکرد؛ ادامهٔ دسته متوقف شد تا اسناد " ..
                                   "دیگر بی‌دلیل ویرایش نشوند."
            break
        end
        if result.status == "no_write" then
            summary.aborted = true
            summary.abort_reason = "API چیزی ننوشت؛ ادامهٔ دسته بی‌فایده است. " .. result.message
            break
        end
        if result.status == "api_failed" then
            summary.aborted = true
            summary.abort_reason = "فراخوانی API ناموفق بود؛ ادامهٔ دسته متوقف شد. " .. result.message
            break
        end
    end

    log_line("BATCH-END | processed=" .. tostring(summary.processed) ..
             " | cleared=" .. tostring(summary.cleared) ..
             " | removed_total=" .. tostring(summary.removed_total) ..
             " | aborted=" .. tostring(summary.aborted))

    return results, summary
end

-- ============================================================
-- CSS
-- ============================================================
-- پالت طبق CLAUDE.md: فقط #16509D (Accent)، سفید، خاکستری، مشکی. هیچ رنگ دیگری — تفکیک هشدار از
-- «پر بودن با Accent» می‌آید، نه از یک رنگ جدید. فونت Peyda به‌صورت base64 تعبیه شده (Regular + Bold).

local REPORT_CSS = [[
<style>
@font-face {
    font-family: "PeydaReport";
    src: url(data:font/truetype;charset=utf-8;base64,AAEAAAAOAIAAAwBgRFNJRwAAAAEAASFUAAAACEdERUYrBC3XAADcNAAAAHxHUE9TKUGIwAAA3LAAADTIR1NVQk+rAWsAARF4AAAP2k9TLzJ2gVbcAAABaAAAAGBjbWFwh/GYyAAADSAAAAeaZ2x5ZmvrPHUAABpsAACfzmhlYWQnUViOAAAA7AAAADZoaGVhCDcSFgAAASQAAAAkaG10eD9fZe0AAAHIAAALWGxvY2EviwdzAAAUvAAABa5tYXhwA1MBBAAAAUgAAAAgbmFtZXvHsAoAALo8AAAFPnBvc3RoWZoTAAC/fAAAHLcAAQAAAAMAAGLmoqxfDzz1AAMD6AAAAADflRqKAAAAAOO0+jP/S/3XBaMFFgAAAAcAAgAAAAAAAAABAAADRv5wAAASx/9L/ggFowABAAAAAAAAAAAAAAAAAAAC1gABAAAC1gBhAAcAgQAGAAEAAgAeAAYAAABkAAAAAwADAAQCZAGQAAUACAKKAlgAAABLAooCWAAAAV4AMgEsAAAAAAAAAAAAAAAAAAAgAQAAAAAAAAAIAAAAAEtIRE0AwAAN/vwD6P4MAAAEsAH0AAAAQAAAAAABaQK/AAAAIAAEAiwASwJYAAACWAAAAIMAAAJnABgCaABTAh4AOgKCAFMCLgBUAgwAVAJgADYCogBTAP4AUwE3ABMCVwBTAc8AUwNJAFMCjQBTAqgANQJTAFMCqAA1AosAUwIuADACJAAPApYATgJnABgDkwAdAjQAEwI1ABMCFQAoAdkAJwIYAEkBsAAwAhgALwIHAC8BdwAeAe0AMAIpAEkA6gBJANkAAQINAEkA6wBKA08ASQIpAEkCFAAwAhgASAIYADABcgBJAbkALgFvAB4CKQBAAeQAGAK0ABgB0QAYAcsAGAHFACgCOgApAaIAMwI6AEMCLAA1AjoAKAI1AEECNwAxAhsASgIxACwCNwAxARAAWAEKAEEBEQBYAREAQwG+AEkCVgBJAh4ANAIYACgByQAYAZUASAHtACgCRQBJAe4AKADYADsB2wAxANwAQwGNAEMC9ABhBAkASQJEAEkCqwAlAukAQwFZAEYBWQAyAcEAVwEWAF8BxABUAVsASAGXADEBWwAvAREALAD4ACgB7AArAecAKwDZAEIB1wAoAaUAhAI+AEkChgBJBHoASQKQAEYCogBGAqIARgJbAEkB8ABJAigASQKdAEYCQABJAlcASQI1AEkB8gBJARYAXwLuAE0A8ABNAPAARAH6AEoBuABGAdAASgKQAEYCGgBiAiwARgIuAEYCtwBmAacATAGnADgAAP94AAD/eAJnABgCZwAYAmcAGAJnABgCZwAYAmcAGAJnABgCZwAYAmcAGAN/ABgCHgA6Ah4AOgIeADoCHgA6AtQAUgKCAFMC1ABSAi4AVAIuAFQCLgBUAi4AVAIuAFQCLgBUAi4AVAIuAFQCdAAsAmAANgJgADYCYAA2Ap4ANQD+AFMA/v/ZAP4AGwD+AFMA/v+9AP7/8QD+//ICVwBTAc8AUwHP/9cBzwBTAd0ADAKNAFMCjQBTAo0AUwJ6AFMCjQBTAqgANQKoADUCqAA1AqgANQKoADUCqAA1AqcANQKoADUD+gA1AlgAUwKLAFMCiwBTAosAUwIuADACLgAwAi4AMAIuADACZABKAlAAJQIkAA8CJAAPAiQADwKWAE4ClgBOApYATgKWAE4ClgBOApYATgKWAE4ClgBOA5MAHQOTAB0DkwAdA5MAHQI1ABMCNQATAjUAEwI1ABMCFQAoAhUAKAIVACgB2QAnAdkAJwHZACcB2QAnAdkAJwHZACcB2QAnAdkAJwHZACcDHgAnAbAAMAGwADABsAAwAbAAMAI9ADECGAAvAhgALwIMAC8CBwAvAgwALwH7AC8CBwAvAfsALwIHAC8CBwAvAgcAKgHtADAB7QAwAe0AMAIpACMA6gBJAPsASQEB/9AA+gAVAOgARwDpAAAA5//mAOr/6AINAEkA6wBKAOv/ywDrADUA6//tAikASQIpAEkCKQBJAisASQIpAEkCFAAwAhQAMAIUADACFAAwAhQAMAIUADACFAAwAhQAMANoADACGABIAXIASQFyAA4BcgA7AbkALgG5AC4BuQAuAbkALgJoAEgBbwAeAW//8QFvAB4BbwAeAikAQAIpAEACKQBAAikAQAIpAEACKQBAAikAQAIpAEACtAAYArQAGAK0ABgCtAAYAcsAGAHLABgBywAYAcUAKAHFACgBxQAoAdgAQQDRAEcBCABIAM3/5QEO/+4A3P/wAQsAAAD//+8BKf/vAUH/1QE3/8kDUgBHA3oARwFe//IBM//yAUv/8gGT//IB3f/yA1IARwN6AEcBXv/yATP/8gGT//IDUgBHA3oARwFe//IBS//yAZP/8gHd//IDUgBHA3oARwFe//IBS//yAZP/8gG///IDUgBHA3oARwFe//IBS//yAZP/8gGW//IDUgBHA3oARwFe//IBM//yApsASAKzAEgCrf/yAp3/8gKhAEgCsQBIAq3/8gKd//ICkgBIArMASAKt//ICmP/yApsASAKzAEgCrf/yAp3/8gIlAEgCRgBIAiUASAJGAEgCJQBIAkYASAFE/9gBAv/eAWf/2AEk/94BRP/YAWf/2AEk/94BAv/eAUT/2AFn/9gBRP/YAWf/2AFE/9gBAv/eAbP/2AEk/94EhQBHBLwASAL5//ICx//yBIUARwS8AEgC+f/yAsf/8gTHAEcE9QBHAzH/8gME//IExwBHBPUARwMx//IDBP/yAt0ASQMLAEkCzP/yAp7/8gLdAEkDCwBJAsz/8gKe//ICMABJAlkASQJS//IB2f/yAjAASQJZAEkCUv/yAdn/8gNTAEkDnwBJAcP/8gHH//IDUwBJA58ASQHD//IBx//yA1MASQOfAEkBw//yAcf/8gK7AEkC3ABJArsASQLcAEkBw//yAcf/8gNSAEkDegBJAgD/8gGH//IDaQBHA2oARwRRAEkD4ABHBIQASQIA//IDJP/yAYf/8gGH//IC8v/yA2kARwNoAEcEUQBJA+AARwSEAEkCAP/yAyT/8QGH//IBg//yAvL/8QK5AEgC8QBIAU3/8gEK//MCugBIAvEASAFN//IBCv/zAo8ARwLkAEcCMP/yAgb/8gK3AEcC5gBHAV7/8gEz//ICtwBHAuYARwHnAEcCBABJAm7/8gKw//IB5wBHAgQASQHnAEcCKwA7AkX/8gEz//IB5wBHAgQASQKw//ICVQBBAuz/8gKw//IB5wBHAgQASQHnAEcCKwA7AeAAQQHtAEEB4QBBAewAQQHhAEEB7ABBAeEAQQHsAEEC1wBHAuEARwLXAEcC4QBHApgARwFe//IBS//yAZP/8gHT//IC2AAuAuIARwKYAEcBXv/yATP/8gGT//IC2AA8AtcARwLhAEcCmABHAV7/8gFL//IBk//yAdD/8gJsAEcCmABHArgARwLnAEcAwQAAAhAAMQJGADECEAAWAkYAFwIQADACRgAxAiIAAAJV//wCEP/ZA4kARwPRAEcDjwBHA48ARwOTAC4DjwBHAkb/2gPRAEcD0QBHA+QAUAPRAEcDjwBH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AQ0BDgEUAQ8AdAETASYBIwEkASUBLwEWATEAigDiAIYA3gCLAOMAjwDnAJIA6gCQAOgAlADsAJUA7QCcAPQAmgDyAJ0A9QCXAO8AnwD3AKEA+QCgAPgAogD6AKgBAQCpAQIApgD7AKoBAwCrAQQArQEGAKwBBQCuAQcArwEIALEBCgCwAQkAswEMALkBEgC4AREAvAEVAL4BFwDAARkAvwEYAMEBGgDDARwAwgEbAMgBIQDHASAAxgEfAM8BKADRASoAzgEnANABKQDTASwA1wEwANgA2gEyANwBNADbATMAxAEdAMkBIgLEAsUCxwLLAswCyQLDAsICygLGAsgBNQE8ATgB+gE6AgkBNgFHAfQBUgFYAWIBagFuAXIBdAF4AXwBiAGMAZABlAGYAZwBoAGkAhsBqAG2AboB0gHaAd4B5AH4AgACAgKtAq4CrwKwArECsgKzArsCvAKrAqwCqgKXAmQCZQKRAUABtAKpAT4B6AHqAe4B9gH8Af4A1QEuANIBKwDUAS0ChAKCAoUCgwKLAoYCiQKKAocCjAKBAoACfgJ/AGAAYQBkAGIAYwBlAH4AfwBmAUwBTQFPAU4BXgFfAWEBYAGtAa8BrgFmAWcBaQFoAXYBdwGEAYYBgAGBAb4BwQHFAcMByAHLAc8BzQHoAekB6gHrAe0B7AHxAfMB8gIXAhACEQIUAhMCOAI6AkACQgJIAkoCUQJTAjkCOwJBAkMCSQJLAlICVAE1ATwBPQE4ATkB+gH7AToBOwIJAgoCDQIMATYBNwFHAUgBSgFJAfQB9QFSAVMBVQFUAVgBWQFbAVoBYgFjAWUBZAFqAWsBbQFsAW4BbwFxAXABcgFzAXQBdQF4AXoBfAF9AYgBiQGLAYoBjAGNAY8BjgGQAZEBkwGSAZQBlQGXAZYBmAGZAZsBmgGcAZ0BnwGeAaABoQGjAaIBpAGlAacBpgGoAakBqwGqAbYBtwG5AbgBugG7Ab0BvAHSAdMB1QHUAdoB2wHdAdwB3gHfAeEB4AHkAeUB5wHmAfgB+QIAAgECAgIDAgYCBQIiAiMCHgIfAiACIQIcAh0AAAAAAEIAQgBCAEIAXACNALgA2gDyAQcBOQFRAV0BdAGZAakBxAHbAgMCJAJWAoYCwwLVAvMDBwMkAz8DVANqA6sD2QP8BCoEXQSHBQIFLgVABVkFfAWJBdMGAAYz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AAEACgB2AAMAAQQJAAIADgCAAAMAAQQJAAMAMACOAAMAAQQJAAQAGgC+AAMAAQQJAAUAGgDYAAMAAQQJAAYAGgDyAAMAAQQJAAcAUAEMAAMAAQQJAAgAGAFcAAMAAQQJAAkAGAFcAAMAAQQJAAoAmgF0AAMAAQQJAAsAIAIOAAMAAQQJAAwAQAIuAAMAAQQJAA0AmgF0AAMAAQQJAA4AKgJuAAMAAQQJABAACgB2AAMAAQQJABEADgCAAAMAAQQJAGQByAKYAEMAbwBwAHkAcgBpAGcAaAB0ACAAKABjACkAIAAyADAAMgAxACAAYgB5ACAAdwB3AHcALgBmAG8AbgB0AGkAcgBhAG4ALgBjAG8AbQAgAEEAbABsACAAcgBpAGcAaAB0AHMAIAByAGUAcwBlAHIAdgBlAGQALgBQAGUAeQBkAGEAUgBlAGcAdQBsAGEAcgAzAC4AMAAwADAAOwBLAEgARABNADsAUABlAHkAZABhAC0AUgBlAGcAdQBsAGEAcgBQAGUAeQBkAGEAIABSAGUAZwB1AGwAYQByAFYAZQByAHMAaQBvAG4AIAAzAC4AMAAwADAAUABlAHkAZABhAC0AUgBlAGcAdQBsAGEAcgBQAGUAeQBkAGEAIABpAHMAIABhACAAdAByAGEAZABlAG0AYQByAGsAIABvAGYAIAB3AHcAdwAuAGYAbwBuAHQAaQByAGEAbgAuAGMAbwBtAE4AYQBzAGUAcgAgAEsAaABhAGQAZQBtAFQAbwAgAHUAcwBlACAAdABoAGkAcwAgAGYAbwBuAHQALAAgAGkAdAAgAGkAcwAgAG4AZQBjAGUAcwBzAGEAcgB5ACAAdABvACAAbwBiAHQAYQBpAG4AIAB0AGgAZQAgAGwAaQBjAGUAbgBzAGUAIABmAHIAbwBtACAAdwB3AHcALgBmAG8AbgB0AGkAcgBhAG4ALgBjAG8AbQB3AHcAdwAuAGYAbwBuAHQAaQByAGEAbgAuAGMAbwBtAGgAdAB0AHAAcwA6AC8ALwBkAHIAaQBiAGIAYgBsAGUALgBjAG8AbQAvAG4AYQBzAGUAcgBrAGgAYQBkAGUAbQBmAG8AbgB0AGkAcgBhAG4ALgBjAG8AbQAvAGwAaQBjAGUAbgBzAGUAcwBlAHkASgBwAGQAaQBJADYASQBtAGQAawBNADIATQByAFMARgBNAHYAUQBWAGcAMABPAEgAcABHAGUAaQA4ADMAZQBHADkASABRAGwARQA5AFAAUwBJAHMASQBuAFoAaABiAEgAVgBsAEkAagBvAGkAYQBtADEAVQBXAFcAVgBXAFYAMAA1AHIAWgAxAEIAMQBMADAAcABhAFIAbABZADUAUwBqAGwAQwBUAG0AOQBEAFEAVgBWAHEAUwBUAFoARgBSAG4ATgBIAFUAWABwAGgAYgB6AGgAdABUAEYAbABxAGMAegAwAGkATABDAEoAdABZAFcATQBpAE8AaQBJADAAWgBXAFkAegBNAEQAZABtAFkAMgBaAGwAWQB6AEYAaQBZAFQAaABpAFkAVABZAHcATwBHAEYAbQBZAFQAQQB5AE4ARABVAHkATgBUAFYAagBNAG0AWgBtAE0AagBKAGsATgB6AGcANABZAGoARQA0AFoAagBBADIAWgBXAEYAaABNAGoAawB5AE0ARABFAHkAWQBUAFYAbABNADIAVgBtAE0ARwBRAHoASQBpAHcAaQBkAEcARgBuAEkAagBvAGkASQBuADAAPQAAAAIAAAAAAAD/nAAyAAAAAAAAAAAAAAAAAAAAAAAAAAAC1gAAAAEAAgADACQAJQAmACcAKAApACoAKwAsAC0ALgAvADAAMQAyADMANAA1ADYANwA4ADkAOgA7ADwAPQBEAEUARgBHAEgASQBKAEsATABNAE4ATwBQAFEAUgBTAFQAVQBWAFcAWABZAFoAWwBcAF0AEwAUABUAFgAXABgAGQAaABsAHAARAA8AHQAeABAADgANAEEA2QASAB8AIAAhAAQAIgAKAAUABgAjAAcACAAJAAsADABeAF8AYAA+AD8AQAC2ALcAtAC1AMQAxQCHAEIAsgCzAIwAigCLAL0AhACFAJYA7wCTAPAAuADoAKsAwwCjAKIAgwC8AIgAhgCCAMIAYQC+AL8BAgEDAMkBBADHAGIArQEFAQYAYwCuAJAA/QD/AGQBBwDpAQgBCQBlAQoAyADKAQsAywEMAQ0BDgD4AQ8BEAERAMwAzQDOAPoAzwESARMBFAEVARYBFwDiARgBGQEaAGYBGwDQANEAZwDTARwBHQCRAK8AsADtAR4BHwEgASEA5AD7ASIBIwEkASUBJgEnANQA1QBoANYBKAEpASoBKwEsAS0BLgEvAOsBMAC7ATEBMgDmATMAaQE0AGsAbABqATUBNgBuAG0AoAD+AQAAbwE3AOoBOAEBAHABOQByAHMBOgBxATsBPAE9APkBPgE/AUAA1wB0AHYAdwFBAHUBQgFDAUQBRQFGAUcA4wFIAUkBSgB4AUsAeQB7AHwAegFMAU0AoQB9ALEA7gFOAU8BUAFRAOUA/AFSAIkBUwFUAVUBVgB+AIAAgQB/AVcBWAFZAVoBWwFcAV0BXgDsAV8AugFgAOcBYQFiAWMBZAFlAWYBZwFoAWkBagFrAWwBbQFuAW8BcAFxAXIBcwF0AXUBdgF3AXgBeQF6AXsBfAF9AX4BfwGAAYEBggGDAYQBhQGGAYcBiAGJAYoBiwGMAY0BjgGPAZABkQGSAZMBlAGVAZYBlwGYAZkBmgGbAZwBnQGeAZ8BoAGhAaIBowGkAaUBpgGnAagBqQGqAasBrAGtAa4BrwGwAbEBsgGzAbQBtQG2AbcBuAG5AboBuwG8Ab0BvgG/AcABwQHCAcMBxAHFAcYBxwHIAckBygHLAcwBzQHOAc8B0AHRAdIB0wHUAdUB1gHXAdgB2QHaAdsB3AHdAd4B3wHgAeEB4gHjAeQB5QHmAecB6AHpAeoB6wHsAe0B7gHvAfAB8QHyAfMB9AH1AfYB9wH4AfkB+gH7AfwB/QH+Af8CAAIBAgICAwIEAgUCBgIHAggCCQIKAgsCDAINAg4CDwIQAhECEgITAhQCFQIWAhcCGAIZAhoCGwIcAh0CHgIfAiACIQIiAiMCJAIlAiYCJwIoAikCKgIrAiwCLQIuAi8CMAIxAjICMwI0AjUCNgI3AjgCOQI6AjsCPAI9Aj4CPwJAAkECQgJDAkQCRQJGAkcCSAJJAkoCSwJMAk0CTgJPAlACUQJSAlMCVAJVAlYCVwJYAlkCWgJbAlwCXQJeAl8CYAJhAmICYwJkAmUCZgJnAmgCaQJqAmsCbAJtAm4CbwJwAnECcgJzAnQCdQJ2AncCeAJ5AnoCewJ8An0CfgJ/AoACgQKCAoMChAKFAoYChwKIAokCigKLAowCjQKOAo8CkAKRApICkwKUApUClgKXApgCmQKaApsCnAKdAp4CnwKgAqECogKjAqQCpQKmAqcCqAKpAqoCqwKsAq0CrgKvArACsQKyArMCtAK1ArYCtwK4ArkCugK7ArwCvQK+Ar8CwACpAKoCwQLCAsMCxALFAsYCxwLIAskCygLLAswCzQLOAs8C0ALRAtIC0wLUAtUC1gLXAtgC2QLaAtsC3ALdAt4C3wLgAuEC4gLjAuQC5QLmAucC6ALpAuoC6wLsAu0C7gLvAvAC8QLyAvMC9AL1AvYC9wL4AvkC+gL7AOEC/AL9Av4C/wd1bmkwNjVBB3VuaTA2NUIGQWJyZXZlB0FtYWNyb24HQW9nb25lawpDZG90YWNjZW50BkRjYXJvbgZEY3JvYXQGRWNhcm9uCkVkb3RhY2NlbnQHRW1hY3JvbgdFb2dvbmVrB3VuaTAxOEYHdW5pMDEyMgpHZG90YWNjZW50BEhiYXIHSW1hY3JvbgdJb2dvbmVrB3VuaTAxMzYGTGFjdXRlBkxjYXJvbgd1bmkwMTNCBk5hY3V0ZQZOY2Fyb24HdW5pMDE0NQNFbmcNT2h1bmdhcnVtbGF1dAdPbWFjcm9uBlJhY3V0ZQZSY2Fyb24HdW5pMDE1NgZTYWN1dGUHdW5pMDIxOAd1bmkxRTlFBFRiYXIGVGNhcm9uB3VuaTAxNjIHdW5pMDIxQQ1VaHVuZ2FydW1sYXV0B1VtYWNyb24HVW9nb25lawVVcmluZwZXYWN1dGULV2NpcmN1bWZsZXgJV2RpZXJlc2lzBldncmF2ZQtZY2lyY3VtZmxleAZZZ3JhdmUGWmFjdXRlClpkb3RhY2NlbnQGYWJyZXZlB2FtYWNyb24HYW9nb25lawpjZG90YWNjZW50BmRjYXJvbgZlY2Fyb24KZWRvdGFjY2VudAdlbWFjcm9uB2VvZ29uZWsHdW5pMDI1OQd1bmkwMTIzCmdkb3RhY2NlbnQEaGJhcglpLmxvY2xUUksHaW1hY3Jvbgdpb2dvbmVrB3VuaTAxMzcGbGFjdXRlBmxjYXJvbgd1bmkwMTNDBm5hY3V0ZQZuY2Fyb24HdW5pMDE0NgNlbmcNb2h1bmdhcnVtbGF1dAdvbWFjcm9uBnJhY3V0ZQZyY2Fyb24HdW5pMDE1NwZzYWN1dGUHdW5pMDIxOQR0YmFyBnRjYXJvbgd1bmkwMTYzB3VuaTAyMUINdWh1bmdhcnVtbGF1dAd1bWFjcm9uB3VvZ29uZWsFdXJpbmcGd2FjdXRlC3djaXJjdW1mbGV4CXdkaWVyZXNpcwZ3Z3JhdmULeWNpcmN1bWZsZXgGemFjdXRlCnpkb3RhY2NlbnQHdW5pMDYyMQd1bmkwNjI3DHVuaTA2MjcuZmluYQd1bmkwNjIzDHVuaTA2MjMuZmluYQd1bmkwNjI1DHVuaTA2MjUuZmluYQd1bmkwNjIyDHVuaTA2MjIuZmluYQd1bmkwNjcxDHVuaTA2NzEuZmluYQd1bmkwNjZFDHVuaTA2NkUuZmluYQx1bmkwNjZFLm1lZGkMdW5pMDY2RS5pbml0EHVuaTA2NkUuaW5pdC5hbHQRdW5pMDY2RS5pbml0LmFsdDIRdW5pMDY2RS5pbml0LmFsdDMHdW5pMDYyOAx1bmkwNjI4LmZpbmEMdW5pMDYyOC5tZWRpDHVuaTA2MjguaW5pdBB1bmkwNjI4LmluaXQuYWx0B3VuaTA2N0UMdW5pMDY3RS5maW5hDHVuaTA2N0UubWVkaQx1bmkwNjdFLmluaXQQdW5pMDY3RS5pbml0LmFsdBF1bmkwNjdFLmluaXQuYWx0Mgd1bmkwNjJBDHVuaTA2MkEuZmluYQx1bmkwNjJBLm1lZGkMdW5pMDYyQS5pbml0EHVuaTA2MkEuaW5pdC5hbHQRdW5pMDYyQS5pbml0LmFsdDIHdW5pMDYyQgx1bmkwNjJCLmZpbmEMdW5pMDYyQi5tZWRpDHVuaTA2MkIuaW5pdBB1bmkwNjJCLmluaXQuYWx0EXVuaTA2MkIuaW5pdC5hbHQyB3VuaTA2NzkMdW5pMDY3OS5maW5hDHVuaTA2NzkubWVkaQx1bmkwNjc5LmluaXQHdW5pMDYyQwx1bmkwNjJDLmZpbmEMdW5pMDYyQy5tZWRpDHVuaTA2MkMuaW5pdAd1bmkwNjg2DHVuaTA2ODYuZmluYQx1bmkwNjg2Lm1lZGkMdW5pMDY4Ni5pbml0B3VuaTA2MkQMdW5pMDYyRC5maW5hDHVuaTA2MkQubWVkaQx1bmkwNjJELmluaXQHdW5pMDYyRQx1bmkwNjJFLmZpbmEMdW5pMDYyRS5tZWRpDHVuaTA2MkUuaW5pdAd1bmkwNjJGDHVuaTA2MkYuZmluYQd1bmkwNjMwDHVuaTA2MzAuZmluYQd1bmkwNjg4DHVuaTA2ODguZmluYQd1bmkwNjMxC3VuaTA2MzEuYWx0DHVuaTA2MzEuZmluYRB1bmkwNjMxLmZpbmEuYWx0B3VuaTA2MzIMdW5pMDYzMi5maW5hEHVuaTA2MzIuZmluYS5hbHQLdW5pMDYzMi5hbHQHdW5pMDY5MQx1bmkwNjkxLmZpbmEHdW5pMDY5NQx1bmkwNjk1LmZpbmEHdW5pMDY5OAt1bmkwNjk4LmFsdAx1bmkwNjk4LmZpbmEQdW5pMDY5OC5maW5hLmFsdAd1bmkwNjMzDHVuaTA2MzMuZmluYQx1bmkwNjMzLm1lZGkMdW5pMDYzMy5pbml0B3VuaTA2MzQMdW5pMDYzNC5maW5hDHVuaTA2MzQubWVkaQx1bmkwNjM0LmluaXQHdW5pMDYzNQx1bmkwNjM1LmZpbmEMdW5pMDYzNS5tZWRpDHVuaTA2MzUuaW5pdAd1bmkwNjM2DHVuaTA2MzYuZmluYQx1bmkwNjM2Lm1lZGkMdW5pMDYzNi5pbml0B3VuaTA2MzcMdW5pMDYzNy5maW5hDHVuaTA2MzcubWVkaQx1bmkwNjM3LmluaXQHdW5pMDYzOAx1bmkwNjM4LmZpbmEMdW5pMDYzOC5tZWRpDHVuaTA2MzguaW5pdAd1bmkwNjM5DHVuaTA2MzkuZmluYQx1bmkwNjM5Lm1lZGkMdW5pMDYzOS5pbml0B3VuaTA2M0EMdW5pMDYzQS5maW5hDHVuaTA2M0EubWVkaQx1bmkwNjNBLmluaXQHdW5pMDY0MQx1bmkwNjQxLmZpbmEMdW5pMDY0MS5tZWRpDHVuaTA2NDEuaW5pdAd1bmkwNkE0DHVuaTA2QTQuZmluYQx1bmkwNkE0Lm1lZGkMdW5pMDZBNC5pbml0B3VuaTA2QTEMdW5pMDZBMS5maW5hDHVuaTA2QTEubWVkaQx1bmkwNkExLmluaXQHdW5pMDY2Rgx1bmkwNjZGLmZpbmEHdW5pMDY0Mgx1bmkwNjQyLmZpbmEMdW5pMDY0Mi5tZWRpDHVuaTA2NDIuaW5pdAd1bmkwNjQzDHVuaTA2NDMuZmluYQx1bmkwNjQzLm1lZGkMdW5pMDY0My5pbml0B3VuaTA2QTkLdW5pMDZBOS5hbHQMdW5pMDZBOS5zczAxDHVuaTA2QTkuZmluYRF1bmkwNkE5LmZpbmEuc3MwMQx1bmkwNkE5Lm1lZGkRdW5pMDZBOS5tZWRpLnNzMDEMdW5pMDZBOS5pbml0EHVuaTA2QTkuaW5pdC5hbHQRdW5pMDZBOS5pbml0LnNzMDEHdW5pMDZBRgt1bmkwNkFGLmFsdAx1bmkwNkFGLnNzMDEMdW5pMDZBRi5maW5hEXVuaTA2QUYuZmluYS5zczAxDHVuaTA2QUYubWVkaRF1bmkwNkFGLm1lZGkuc3MwMQx1bmkwNkFGLmluaXQQdW5pMDZBRi5pbml0LmFsdBF1bmkwNkFGLmluaXQuc3MwMQd1bmkwNjQ0DHVuaTA2NDQuZmluYQx1bmkwNjQ0Lm1lZGkMdW5pMDY0NC5pbml0B3VuaTA2QjUMdW5pMDZCNS5maW5hDHVuaTA2QjUubWVkaQx1bmkwNkI1LmluaXQHdW5pMDY0NQx1bmkwNjQ1LmZpbmEMdW5pMDY0NS5tZWRpDHVuaTA2NDUuaW5pdAd1bmkwNjQ2DHVuaTA2NDYuZmluYQx1bmkwNjQ2Lm1lZGkMdW5pMDY0Ni5pbml0B3VuaTA2QkEMdW5pMDZCQS5maW5hB3VuaTA2NDcMdW5pMDY0Ny5maW5hDHVuaTA2NDcubWVkaQx1bmkwNjQ3LmluaXQHdW5pMDZDMAx1bmkwNkMwLmZpbmEHdW5pMDZDMQx1bmkwNkMxLmZpbmEMdW5pMDZDMS5tZWRpDHVuaTA2QzEuaW5pdAd1bmkwNkMyDHVuaTA2QzIuZmluYQd1bmkwNkJFDHVuaTA2QkUuZmluYQx1bmkwNkJFLm1lZGkMdW5pMDZCRS5pbml0B3VuaTA2MjkMdW5pMDYyOS5maW5hB3VuaTA2QzMMdW5pMDZDMy5maW5hB3VuaTA2NDgMdW5pMDY0OC5maW5hB3VuaTA2MjQMdW5pMDYyNC5maW5hB3VuaTA2QzYMdW5pMDZDNi5maW5hB3VuaTA2QzcMdW5pMDZDNy5maW5hB3VuaTA2NDkMdW5pMDY0OS5maW5hB3VuaTA2NEEMdW5pMDY0QS5maW5hEXVuaTA2NEEuZmluYS5zczAxDHVuaTA2NEEubWVkaQx1bmkwNjRBLmluaXQQdW5pMDY0QS5pbml0LmFsdBF1bmkwNjRBLmluaXQuYWx0Mgd1bmkwNjI2DHVuaTA2MjYuZmluYRF1bmkwNjI2LmZpbmEuc3MwMQx1bmkwNjI2Lm1lZGkMdW5pMDYyNi5pbml0EHVuaTA2MjYuaW5pdC5hbHQHdW5pMDZDRQd1bmkwNkNDDHVuaTA2Q0MuZmluYRF1bmkwNkNDLmZpbmEuc3MwMQx1bmkwNkNDLm1lZGkMdW5pMDZDQy5pbml0EHVuaTA2Q0MuaW5pdC5hbHQRdW5pMDZDQy5pbml0LmFsdDIHdW5pMDZEMgx1bmkwNkQyLmZpbmEHdW5pMDc2OQx1bmkwNzY5LmZpbmEHdW5pMDY0MAt1bmkwNjQ0MDYyNxB1bmkwNjQ0MDYyNy5maW5hC3VuaTA2NDQwNjIzEHVuaTA2NDQwNjIzLmZpbmELdW5pMDY0NDA2MjUQdW5pMDY0NDA2MjUuZmluYQt1bmkwNjQ0MDYyMhB1bmkwNjQ0MDYyMi5maW5hC3VuaTA2NDQwNjcxEHVuaTA2NkUwNkNDLmZpbmEVdW5pMDY2RTA2Q0MuX2ZpbmEuYWx0EHVuaTA2MjgwNjQ5LmZpbmEQdW5pMDYyODA2NEEuZmluYRB1bmkwNjI4MDYyNi5maW5hEHVuaTA2MjgwNkNDLmZpbmEQdW5pMDY0NDA2NzEuZmluYRB1bmkwNjdFMDY0OS5maW5hEHVuaTA2N0UwNjRBLmZpbmEQdW5pMDY3RTA2MjYuZmluYRB1bmkwNjdFMDZDQy5maW5hEHVuaTA2MkEwNjQ5LmZpbmEQdW5pMDYyQTA2NEEuZmluYRB1bmkwNjJBMDYyNi5maW5hEHVuaTA2MkEwNkNDLmZpbmEQdW5pMDYyQjA2NDkuZmluYRB1bmkwNjJCMDY0QS5maW5hEHVuaTA2MkIwNjI2LmZpbmEQdW5pMDYyQjA2Q0MuZmluYQt1bmkwNjMzMDY0ORB1bmkwNjMzMDY0OS5maW5hC3VuaTA2MzMwNjRBEHVuaTA2MzMwNjRBLmZpbmELdW5pMDYzMzA2MjYQdW5pMDYzMzA2MjYuZmluYQt1bmkwNjMzMDZDQxB1bmkwNjMzMDZDQy5maW5hC3VuaTA2MzQwNjQ5EHVuaTA2MzQwNjQ5LmZpbmELdW5pMDYzNDA2NEEQdW5pMDYzNDA2NEEuZmluYQt1bmkwNjM0MDYyNhB1bmkwNjM0MDYyNi5maW5hC3VuaTA2MzQwNkNDEHVuaTA2MzQwNkNDLmZpbmELdW5pMDYzNTA2NDkQdW5pMDYzNTA2NDkuZmluYQt1bmkwNjM1MDY0QRB1bmkwNjM1MDY0QS5maW5hC3VuaTA2MzUwNjI2EHVuaTA2MzUwNjI2LmZpbmELdW5pMDYzNTA2Q0MQdW5pMDYzNTA2Q0MuZmluYRp1bmkwNjM2X2ZhcnNpX3VuaTA2Q0MuZmluYQt1bmkwNjM2MDY0ORB1bmkwNjM2MDY0OS5maW5hC3VuaTA2MzYwNjRBEHVuaTA2MzYwNjRBLmZpbmELdW5pMDYzNjA2MjYQdW5pMDYzNjA2MjYuZmluYQt1bmkwNjM2MDZDQxB1bmkwNjQ2MDY0OS5maW5hEHVuaTA2NDYwNjRBLmZpbmEQdW5pMDY0NjA2MjYuZmluYRB1bmkwNjQ2MDZDQy5maW5hEHVuaTA2NEEwNjRBLmZpbmEQdW5pMDY0QTA2Q0MuZmluYRB1bmkwNjI2MDY0OS5maW5hEHVuaTA2MjYwNjRBLmZpbmEQdW5pMDYyNjA2MjYuZmluYRB1bmkwNjI2MDZDQy5maW5hEHVuaTA2Q0MwNkNDLmZpbmEHdW5pRkRGMgd1bmkwNjZCB3VuaTA2NkMHdW5pMDY2MAd1bmkwNjYxB3VuaTA2NjIHdW5pMDY2Mwd1bmkwNjY0B3VuaTA2NjUHdW5pMDY2Ngd1bmkwNjY3B3VuaTA2NjgHdW5pMDY2OQd1bmkwNkYwB3VuaTA2RjEHdW5pMDZGMgd1bmkwNkYzB3VuaTA2RjQHdW5pMDZGNQd1bmkwNkY2B3VuaTA2RjcHdW5pMDZGOAd1bmkwNkY5DHVuaTA2RjQudXJkdQx1bmkwNkY3LnVyZHUHdW5pMzAwMAd1bmkyMDVGB3VuaTIwMEUHdW5pMjAwRgd1bmkyMDBEB3VuaTIwMEMHdW5pMjAwMQd1bmkyMDAzB3VuaTIwMDAHdW5pMjAwMgd1bmkyMDA1B3VuaTIwMEEHdW5pMjAyRgd1bmkyMDA2B3VuaTIwMDkHdW5pMjAwNAd1bmkyMDBCB3VuaTA2RDQHdW5pMDYwQwd1bmkwNjFCB3VuaTA2MUYHdW5pMDY2RAd1bmlGRDNFB3VuaUZEM0YHdW5pRkRGQwd1bmkwNjZBB3VuaTA2MTUKZG90YWJvdmVhcgpkb3RiZWxvd2FyC2RvdGNlbnRlcmFyFnR3b2RvdHN2ZXJ0aWNhbGFib3ZlYXIWdHdvZG90c3ZlcnRpY2FsYmVsb3dhchh0d29kb3RzaG9yaXpvbnRhbGFib3ZlYXIYdHdvZG90c2hvcml6b250YWxiZWxvd2FyFHRocmVlZG90c2Rvd25hYm92ZWFyFHRocmVlZG90c2Rvd25iZWxvd2FyEnRocmVlZG90c3VwYWJvdmVhchJ0aHJlZWRvdHN1cGJlbG93YXIHd2FzbGFhcgttaW5pS2VoZWhhchFnYWZzYXJrYXNoYWJvdmVhchVnYWZzYXJrYXNoYWJvdmVhci5hbHQSZ2Fmc2Fya2FzaGNlbnRlcmFyB3VuaTA2NzAHdW5pMDY1Ngd1bmkwNjU0B3VuaTA2NTUHdW5pMDY0Qgd1bmkwNjRDB3VuaTA2NEQHdW5pMDY0RQd1bmkwNjRGB3VuaTA2NTAHdW5pMDY1MQt1bmkwNjUxMDY0Qgt1bmkwNjUxMDY0Qwt1bmkwNjUxMDY0RAt1bmkwNjUxMDY0RQt1bmkwNjUxMDY0Rgt1bmkwNjUxMDY1MAt1bmkwNjUxMDY3MAd1bmkwNjUyB3VuaTA2NTMIc2FyZXlhYXIRc2V2ZW5zYW1sbC5ib3R0b20Qc2V2ZW5zbWFsbC5hYm92ZQ55ZWhzYW1sLmJvdHRvbQ15ZWhzbWFsLmFib3ZlB3VuaTAzMDgHdW5pMDMwNwlncmF2ZWNvbWIJYWN1dGVjb21iB3VuaTAzMEIHdW5pMDMwMgd1bmkwMzBDB3VuaTAzMDYHdW5pMDMwQQl0aWxkZWNvbWIHdW5pMDMwNAd1bmkwMzEyB3VuaTAzMjYHdW5pMDMyNwd1bmkwMzI4DHVuaTA2Y2UuZmluYQx1bmkwNmNlLmluaXQMdW5pMDZjZS5tZWRpDHVuaTA2ZDUuZmluYQAAAQACAA4AAAAAAAAANgACAAYAgwCEAAMBNQIbAAECHAJjAAICmAK8AAMCwgLQAAMC0gLVAAEAAQACAAAADAAAABgAAQAEAqoCrAKvArIAAQAVAIMAhAKYAqQCpQKpAqsCrQKuArACsQKzArQCtQK2ArcCuAK5AroCuwK8AAEAAAAKAH4AugADREZMVAAUYXJhYgAYbGF0bgAuAFQAAAAKAAFVUkQgAFAAAP//AAMAAAADAAQALgAHQVpFIAA6Q1JUIAA6S0FaIAA6TU9MIAA6Uk9NIAA6VEFUIAA6VFJLIAA6AAD//wADAAEAAgAEAAD//wADAAAAAgAEAAVrZXJuACBrZXJuACBtYXJrACptYXJrACpta21rADQAAAADAAAAAQACAAAAAwADAAQABQAAAAIABgAHAAgAEgXyFvgZmhpOJ3wx9jJsAAIACAACAAoEKgABAEQABAAAAB0C5ALkAIIAggLyAIgAtgEYARgBJgGAAYoB/AIKAnwC1gLWAuQC5ALyAvIDCAMOAxwD6gPwBAYEEAQWAAEAHQBCAEMARABFAEYASABLAFEAUgBYAFkAWgBcAF0AXgBhAGMAZABlAGgAaQB3AHgAeQCBAIICcAJ2AncAAQAZ//MACwAE/9sADf/tABcABQAd//cAIP/wACH/7AAi//AAJP/yACz/8AAu/+wAMP/1ABgABP/WAAb/+gAK//kADf/tABL/+QAU//kAHv/qACD/3wAh/94AIv/fACT/4AAq/+wAK//sACz/3wAt/+wALv/eAC//7AAw/+UAMv/uADP/+QA0//oANv/4ADf/9wBLAAAAAwBL/8AAVP/0AFf/5QAWAAb/9AAK//MAEv/zABT/8wAe//oAIP/uACH/7QAi/+4AI//7ACcACwAq//sAK//7ACz/7gAt//sALv/tAC//+wAw//sAMv/xADP/+wA0//gANv/7AFr/9QACAFz/+gBf//oAHAAE/+8ABv/qAAr/6QAS/+kAFP/pABb/9wAe/+cAIP/hACH/4QAi/+EAI//3ACcACgAq/+wAK//sACz/4QAt/+wALv/hAC//7AAw/+4AMf/xADL/5AAz/+gANP/mADX/8wA2/+kAN//yAFj/+gBa/+4AAwBZ//UAXP/uAF//6wAcAAT/7AAG/+gACv/mABL/5gAU/+YAFv/3AB7/4wAg/9wAIf/dACL/3AAj//EAJwAEACr/6wAr/+sALP/cAC3/6wAu/90AL//rADD/6wAx/+kAMv/gADP/4gA0/+EANf/xADb/5AA3/+8AWP/6AFr/6wAWAAb/9gAK//YAEv/2ABT/9gAW//sAF//IABj/9QAZ/9MAGv/hABz/vAAg//sAIv/7ACP/+gAs//sAMf/zADP/6QA0/+8ANv/qAFH/ugBS/7oAYf+8AGP/vAADAEv/uQBU/+gAV//jAAMAGf/NACP/9QAz/98ABQAZ/+IAG//aACP/9QAz//QANf/jAAEAKf/IAAMAF//TABn/+gAc/+AAMwAE/94ABf/mAAb/5gAH/+YACP/mAAn/5gAK/+YAC//mAAz/5gAN//UADv/mAA//5gAQ/+YAEf/mABL/5gAT/+YAFP/mABX/5gAW/+cAF/+0ABj/5QAZ/9YAGv/d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ABn/4gAb//gAM//4ADX//QBQ/+0AWf/6AFz/6ABe/90AX//rAGr/8gAYAAT/5AAN/+oAF//mABv/9QAc//kAHf/3ACD/9wAh//gAIv/3ACT/+wAs//cALv/4AEL/2ABD/9gARv/YAEv/5QBX//gAZP/YAGX/2ABo/9gAaf/YAHb/2ACB/+AAgv/uAAMAGf/4ACcAEwBe//kABQAZ//gAUP/6AFz/9QBe//cAX//yAAEAd//IAAkAGf/jADP//ABI//0AUP/sAFn/+wBc/+wAXv/bAF//6gBq//AACwAZ/+AAG//rADP/9wA1//QASP/9AFD/6wBZ/+4AXP/hAF7/2gBf/9wAav/yAAsAGf/iABv/7AAz//gANf/1AEj/+ABQ/+gAWf/tAFz/4QBe/9sAX//dAGr/7wAHABv/5QBL/98AV//4AFn/+wBc/+sAXv/7AF//5QAKABn/6wAb//0AM//5ADX//QBQ//UAWf/5AFz/5wBe/+kAX//iAGr/9QAEABn/9gBc//oAXv/3AF//9wAIABn/5gAb//gAUP/1AFn/+wBc/+wAXv/pAF//6wBq//UAHgAE/+8ADf/oABf/wAAZ//gAG//nABz/2QAd//MAHv/4ACD/9wAh//gAIv/3ACT/9wAs//cALv/4ADD/+wBC/98AQ//fAEb/9ABL/+wAUP/4AFn/+wBc/+cAXv/3AF//4gBk/98AZf/fAGj/9ABp//QAdv/fAIH/9AAIABn/9wAb/+cAS//vAFD/+ABZ//gAXP/mAF7/9wBf/+EAEgAN//0AF/+8ABn/+gAc/9oAHv/9ACD/9AAh//QAIv/0ACT/9gAs//QALv/0AEb/4gBc//MAXv/5AF//8ABo/+IAaf/iAIH/5gAHABn/+AAb/+cAS//rAFD/+ABc/+oAXv/3AF//5QAGABn/8wBQ//oAXP/yAF7/9ABf/+8Aav/7AAQADf/6ABf/8wAZ//oAHP/kABEABv/6AAr/+gAS//oAFP/6ABf/2QAY//sAGf/hABr/7QAc/8sAMf/6ADP/9QA0//gANv/1AFH/0QBS/9EAYf/SAGP/0gADAAT/5QAN/+wAHf/7AAcABP/mAA3/6gAX//gAGf/6ABv/+AAc/+oAHf/1AAIHUAAEAAAHZggkACAAHQAA//r/9f/9//b/9//x/+P//f/7//X/8f/zAAAAAAAA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CE4IVAhaCGAIZghsCJYIcgh4CH4IrgiECIoIkAiWCJwIogioCK4ItAi6CMAIxgjMCNII2AkgCN4I5AjqCPAI9gj8CQIJCAkOCRQJGgkgCSYAAAksAAAJMgl6CTgJegk+CUQJSgnCCVAJVglcCWIJaAluCXQJegmACYYJjAmSCZgJngmkCaoJsAm2CbwJwgnICc4J1AnaCeAJ5gnsCfIJ+An+CgQKCgoQChYKHAoiCigKLgo0CjoKQApGCkwMegpSAAAKWAAACl4AAApkAAAKagpwCnYKfAqCCogKjgqUCpoKoAqmCqwKsgq4Cr4KxArKCtAK1grcCuIK6AruCvQK+gsACwYLfgsMAAALEgAACxgLHgskCyoLMAs2CzwLQgtIAAALTgAAC1QLWgtgC2YLbAtyC3gLfguEC4oLkAuWC5wLoguoC64LtAu6C8ALxgvMAAAL0gAAC9gAAAveAAAL5AAAC+oAAAvwC/YL/AykDAIMCAwODBQMGgwgDCYMLAwyDDgMPgxEDEoMUAxWAAAMXAAADGIAAAxoDG4MdAx6DIAMhgyMAAAMkgyYDJ4MpAyqDLAMtgy8DMIMyAzODNQM2gzgDOYAAAzsAAAM8gAADPgAAAz+DQQNCgABAP//6wABAQAB6gABAHH/nAABAGwC+gABAI//nAABAHMDAQABAGwD/QABAH4EBwABAHv+mQABAJD+mAABAJEDKAABAI8DMgABAMID0AABAKYD2QABAbr/nAABAbgBuAABAcf/nAABAb0BvAABALP/nAABALcBmwABAJP/nAABAJIBzQABAJX/nAABAJ4B0QABALABvQABAJn/nAABALkBvgABAbP+xAABAbYBwwABAbL+xgABAbABxwABAK4BoAABAGr+vwABAJABywABAH7+0AABAK0BxAABAbL+TAABAcMBxwABAcb+RwABAb8BxwABAK/+SAABALMBmwABAIT+SgABAJEBwAABALP+QwABAKcBsQABALf+gQABAL8BbgABAcD/lQABAaoB3AABAbn/lQABAaoB5QABAK7/nAABALMCaAABAI7/nAABAJgCjQABAJj/mgABALwCigABAKL/nAABAKECkAABAa7/nAABAb7/nAABAa4CmwABAKj/nAABAK0C6wABAJb/nAABAJcDDQABAJz/nAABAOEDCwABAJf/nAABAJ0DBwABAZ4CwwABAaYCwwABALIC7QABAIsDBgABASn+WAABAPICAQABAQD+VwABAPAB/wABATv+wgABAMMB7AABAT3+ygABAM0B7AABAP7+WAABANwCAQABAQv+UwABAOIBvwABATj+SgABANcB5wABATb+SAABAMgB6gABAQX+UAABAPb+TAABANACAAABAL0B7AABAOb/nAABALkB6wABAN7+WgABANUC3AABAOf+WwABANYC7AABAMn/nAABAL4CygABAMP/nAABAL8CzgABASMCRQABAR7/lwABATECUwABAQP/mAABAQ0DAQABAP//lAABAVUDHQABATADhgABAVcDqAABAHf+zgABALoBpAABAGb+0gABAJIBpAABAG7+0AABANYBoAABAIn+6AABAJcBqAABAID+5AABAM4CcgABAJL+5AABANcCdQABAH/+8gABAJcCcwABAHP+3AABAJQCbgABAMYC9wABANoC+wABAID9fgABAIH9fwABAIH+0wABAM4C7gABAHn+5wABAJYC7gABAIn+4QABANYC7wABAH7+7QABAJMC7wABAzL/nQABA0MBpAABA0n/mgABA0YBmQABAYYBoAABAXf/nAABAYYBoQABAzT/nAABAzsC5wABAzz/nAABAzkC3wABAXn/nAABAXgC5gABAXH/nAABAXkC5wABA27/nQABA8sBzgABA3v/nAABA8cByQABAbP/nAABAgMBzQABAar/nAABAgEB0AABA3P/nAABA9ACowABA3r/nAABA9ECoQABAaH/nAABAhACnQABAab/nAABAhMCmwABAhQByAABAW7/nAABAhIBygABARn/nAABAc8BwAABARv/nAABAc4BxQABAVz/nAABAeQCjAABAWL/nAABAegCjQABAUL/nAABAawCjgABATP/nAABAawCjwABAQr+DQABAQMB6wABARn+CwABASoB8wABASz/nAABASgB8QABANT/oAABAOUCCwABANL+IQABARUCsAABAOn+EQABASUCqQABASn/nAABASQCsgABALH/nAABAO4CsgABAZD/nAABAnQDPgABAr0CxgABAN7/nAABANkCygABAOQDRAABAZz/nAABAmkDpgABAZH/nAABAsUDKwABAOv/nAABAN0DKAABALn/nAABAOQDqwABAan/mAABAm4CcAABAZ3/mAABAsMB+AABAOj/nAABAOAB9AABAOoCaAABATX+uQABAc0BzQABAS7+tgABAc0BygABASX+uwABAc4ClwABASX+ugABAc8CjwABAOP/nAABAOECvgABAM3/nAABAN0DNwABAbICpwABAbgCowABALUC8QABAK4C4wABAaT/mgABAhMCkwABAhkCjAABAhz/nAABAUUB0QABAa3/mgABAhkCjgABAib/nAABAR4BzwABAMn/mQABAJ4C7AABATb/mgABAHwCdwABAKT/mwABAKQC1wABAIr/mwABAI8CzgABARr/nAABAIQCkAABAaf/mAABAgQDCQABAa7/mAABAgADDgABAjv/nAABAT0CZQABAbn/mAABAgsDBwABAhb/nAABATcCXQABAMP/mQABAH8DRgABAV//nAABAGcCvgABAH//mQABAHgDKwABAHf/mQABAIMDMQABASr/nAABAGcCzQABAWr+5QABAS8BhgABAWH+8AABATsBiwABAKH/nAABAKgC+gABAKIDAQABASoB1AABATwBnQABALYEDQABAKUEDwABAYP/qQABAUgBzQABAav/nAABAVYBxgABARz/nAABAR0ByQABARb/nAABARsB0AABAWX+5gABAV8B9QABAT3+8gABAWEB+AABAKv/nAABALMCZAABAJH/nAABAL4CgwABAWf+4QABAVkBYgABAWj+3wABAWABnwABAPr/lgABAOsCHwABAPr/zgABAQACTQABAPX+5gABAQoBvQABAQwCNAABAOUDqAABANgDxQABAPD/nAABANUCHQABAQX/ywABATIBkQABAPP+0QABAQABdQABAIP+FgABAJEB2QABAO0DhQABAPMDfwABASv/nAABAQkCLgABAVH+lgABAToBvAABAWX/lgABAUYCCAABAST/nAABAUkCJAABAPH/nAABAO0C4gABAPT/zgABAOoDGQABAP3/nAABAPgC6gABAQv/rQABAS8CTAABAPL+zQABAPIBzAABAPf+zAABAO4B1AABAPgDJAABAQMDLwABAQAC/wABAP0C+wABAPoDLQABAPkDPAABAXX+5wABAMABjQABAVwBAgABAWz+RAABAMABigABAWX+BQABAU4A/wABAVL99QABAUUAwAABAKr+0wABAK8BoQABAJL+0wABAKABvAABAKT+xgABAKkBvwABALT+xgABAL8BqwABANgDCAABAPYCygABAO0CIAABALL/nAABAL8DIgABAIb/nAABAJoDYgABAKP/nAABAKsDOwABAMACpgABAXP+7QABAMYBmQABAWT+owABAXUA/AABAU3+pAABAToAyQABAKz+ygABALsBoQABAIb+ywABAJ8ByAABAKz+xgABAJ8BuAABAKf+xwABALABtQABATYCBAABATYAvAABAWIDAQABAWMDCQABAGP/nAABAGAA5QAFAAAAAQAIAAEADAAoAAIAMgCYAAIABACDAIQAAAKYApgAAgKkAqUAAwKpArwABQACAAECHAJiAAAAGQABC4QAAQuEAAELlgABC5YAAQuWAAELigAACoQAAQuWAAAKhAABC5YAAQuQAAAKhAABC5YAAQuWAAAKhAABC5YAAQuWAAELlgABC5YAAQuWAAELlgABC5YAAQuWAAELlgABC5YARwCQALIA1AD2ARgBOgFcAX4BoAHCAeQCBgIoAkoCbAKOArAC0gL0AxYDOANaA3wDngPAA+IEBAQmBEgEagSMBKgEygTmBQgFKgVMBW4FkAWsBc4F8AYSBjQGVgZ4BpQGtgbSBvQHFgc4B1oHfAeeB8AH4ggECCYISAhqCIwIrgjQCPIJFAk2CVIJdAmWCbgAAgAKABAAFgAcAAEBlv+0AAEBtAMaAAEAiP9wAAEAewKsAAIACgAQABYAHAABAZr/qwABAb0DGAABAHz/eAABAHwCswACAAoAEAAWABwAAQGU/7gAAQG5Ax0AAQB9/5AAAQCbA+MAAgAKABAAFgAcAAEBtv+nAAEBxQMhAAEAnP+PAAEAmwQFAAIACgAQABYAHAABAbb/ogABAakDCwABAMT+UwABAIkCoQACAAoAEAAWABwAAQHd/5wAAQGzAxsAAQDc/mMAAQCFArgAAgAKABAAFgAcAAEBr/+9AAEBywM2AAEAjP92AAEAhgNfAAIACgAQABYAHAABAar/swABAdADMAABAJb/dwABAKQDYAACAAoAEAAWABwAAQGd/7QAAQHqA2AAAQCa/2IAAQCgA6QAAgAKABAAFgAcAAEC4f8sAAECgQHvAAEBWf6jAAEAvAGdAAIACgAQABYAHAABAvL/QgABAoYB5gABAV3+qwABALsBnQACAAoAEAAWABwAAQL+/s4AAQJ1AbgAAQFY/roAAQC8AVkAAgAKABAAFgAcAAEC//7VAAECnAHXAAEBZ/4WAAEAoQFzAAIACgAQABYAHAABAv7+ygABApYB4wABAWP+vAABALwC6AACAAoAEAAWABwAAQLy/tAAAQJzAb4AAQFi/r4AAQCuAVEAAgAKABAAFgAcAAEBof+xAAEB/QMsAAEAhv+DAAEA0AOuAAIACgAQABYAHAABAyj+TgABAo0B0wABAVX+vwABAK8BYAACAAoAEAAWABwAAQMm/loAAQKXAcgAAQFm/foAAQDDAU4AAgAKABAAFgAcAAEDTv48AAECowHiAAEBX/6uAAEAzALXAAIACgAQABYAHAABAy3+VgABApwBvAABAVP+ngABAJUBfQACAAoAEAAWABwAAQLI/zQAAQKHArAAAQFV/qAAAQDBAX8AAgAKABAAFgAcAAEC5/81AAECegKnAAEBeP3ZAAEAvAFoAAIACgAQABYAHAABAvb/DQABAo4CogABAUD+qAABAM4C9QACAAoAEAAWABwAAQLe/xoAAQKFApgAAQFX/pYAAQCuAYIAAgAKABAAFgAcAAEC3f8kAAECgwMdAAEBXf6XAAEAwAF2AAIACgAQABYAHAABAuP/LQABAnsDIQABAWj+CQABALsBcwACAAoAEAAWABwAAQLV/x0AAQKMAykAAQFf/pwAAQDgAwQAAgAKABAAFgAcAAEC5v85AAECfgMkAAEBXP6kAAEAuAFdAAIACgAQABYAHAABA9j/lwABA+8BqwABAWz+oAABAOMBjQACAAoAEAAWABwAAQPQ/4gAAQPgAboAAQFo/qoAAQDOAX8AAgCoAAoAEAAWAAED5gG0AAEBdP3wAAEAuQF/AAIACgAQABYAHAABA9//kQABA+UBvQABAXD98QABAMYBgwACANAACgAQABYAAQPhAbQAAQFe/qIAAQD+AtYAAgAKABAAFgAcAAED5P+jAAED4AGtAAEBYv6mAAEA9ALjAAIACgAQABYAHAABA+H/nAABA9MBugABAUz+rgABAMgBiwACAAoAEAAWABwAAQPg/5wAAQPcAbIAAQFZ/qQAAQDBAW4AAgAKABAAFgAcAAED6/+cAAEDwgLlAAEBaf6fAAEAqAFzAAIACgAQABYAHAABA/L/nAABA8cC3gABAWP+pgABALgBiQACAAoAkgAQABYAAQPi/5wAAQFz/eoAAQDJAYgAAgAKABAAFgAcAAED2/+cAAEDyQLtAAEBcf34AAEAtwF8AAIACgAQABYAHAABA93/nAABA9AC3gABAVv+nwABANMC3AACAAoAEAAWABwAAQPt/5wAAQPFAt4AAQFH/o4AAQDzAtwAAgAKABAAFgAcAAED5f+cAAEDzQLeAAEBWP6dAAEA1AF8AAIACgAQABYAHAABA9z/nAABA8kC3gABAVf+nwABAMQBfwACAAoAEAAWABwAAQP+/5wAAQRzAecAAQFf/qYAAQClAZ0AAgCGAAoAEAAWAAEEeAHnAAEBY/6gAAEAxAGAAAIACgAQABYAHAABBA3/nAABBHUB5wABAWv9/AABANsBhAACAIwACgAQABYAAQRtAeQAAQFm/f0AAQDMAXQAAgAKABAAFgAcAAEENf+cAAEESgHnAAEBUP63AAEA6gLTAAIACgAQABYAHAABBBb/nAABBHIB5wABAWD+mgABAOMCyQACAAoAEAAWABwAAQQf/5wAAQRoAecAAQFR/qIAAQC+AXwAAgAKABAAFgAcAAEEE/+cAAEEYQHnAAEBaf6jAAEAvQGCAAIACgAQABYAHAABBBf/nAABBIECpwABAWD+owABAM8BeAACAAoAEAAWABwAAQQj/5wAAQR+ArsAAQFU/psAAQDSAXMAAgAKABAAFgAcAAEEB/+cAAEEgAKsAAEBWv6VAAEAyQFsAAIACgAQABYAHAABBE//nAABBIcCwwABAYX9qQABAOkBnQACAAoAEAAWABwAAQQm/5wAAQSCAqkAAQFt/ggAAQDIAXUAAgAKABAAFgAcAAEEJP+cAAEEewKdAAEBWf66AAEA7wLLAAIACgAQABYAHAABBA//nAABBIQCqAABAVv+ugABAPUCvQACAAoAEAAWABwAAQQa/5wAAQSHAqYAAQFd/rAAAQDtAZ0AAgAKABAAFgAcAAEC1/9ZAAEChgKZAAEBWf6fAAEAsAF7AAIACgAQABYAHAABAtj/PAABAn8CmgABAXP+AAABANABYwACAAoAEAAWABwAAQLq/08AAQJ+ApsAAQFm/qEAAQC/AvwAAgAKABAAFgAcAAEC1v88AAEChwKUAAEBVf6zAAEAuwF2AAIACgAQABYAHAABAyP+1AABApoB1QABAW/+JwABAMQBeAACAAoAEAAWABwAAQMi/sUAAQKaAdEAAQFN/o4AAQDRAWQAAgBIAAoAEAAWAAECewNfAAEBXf6gAAEAwAFqAAIACgAQABYAHAABAtv/UgABAosDWQABAWv+CQABAMgBgQACAAoAEAAWABwAAQMN/2AAAQKLA2sAAQFW/o8AAQDGAs4AAgAKABAAFgAcAAEC7v9gAAECewNtAAEBXP6cAAEAvgF0AAIACgAQABYAHAABAxr+ywABAo0B1QABAVP+rgABAMwBZwAGABAAAQAKAAAAAQAMABgAAQAoAEAAAQAEAqoCrAKvArIAAQAGAqoCrAKvArICvgLAAAQAAAASAAAAEgAAABIAAAASAAEAAAAAAAYADgAUABoAIAAmACYAAQAA/yYAAQAA/ssAAQAA/t4AAQAA/2EAAQAA/vwABgAQAAEACgABAAEADAA6AAEAbgDcAAEAFQCDAIQCmAKkAqUCqQKrAq0CrgKwArECswK0ArUCtgK3ArgCuQK6ArsCvAABABgAgwCEApgCpAKlAqkCqwKtAq4CsAKxArMCtAK1ArYCtwK4ArkCugK7ArwCvQK/AsEAFQAAAFYAAABWAAAAaAAAAGgAAABoAAAAXAAAAGgAAABoAAAAYgAAAGgAAABoAAAAaAAAAGgAAABoAAAAaAAAAGgAAABoAAAAaAAAAGgAAABoAAAAaAABAAACvAABAAADCgABAAADCwABAAADCQAYADIAMgA4AD4ARABKAFAAVgBcAGIAaABuAHQAegCAAIYAjACSAJgAngCkAKoAsAC2AAEAAAO7AAEADAQcAAEAGgP6AAH/9AQ0AAEAAAPkAAEAAARYAAEAAARcAAEAAARiAAEAAAPZAAEAAARZAAEAAAPdAAEAAAUwAAEAAAU7AAEAAAU/AAEAAASpAAEAAAUvAAEAAAS/AAEAAASeAAEAAAPwAAEAAAOoAAEAAAR0AAEAAAQOAAEAAAQPAAEAAAAKAVwCIAADREZMVAAUYXJhYgAYbGF0bgBWAHAAAAAKAAFVUkQgACQAAP//AAoAAAABAAMABAAFAAYADwAQABEAEgAA//8ACgAAAAEAAgAEAAUABgAOAA8AEQASAC4AB0FaRSAARkNSVCAAYEtBWiAAek1PTCAAlFJPTSAArlRBVCAAyFRSSyAA4gAA//8ACQAAAAEAAgAEAAUABgAPABEAEgAA//8ACgAAAAEAAgAEAAUABgAHAA8AEQASAAD//wAKAAAAAQACAAQABQAGAAgADwARABIAAP//AAoAAAABAAIABAAFAAYACQAPABEAEgAA//8ACgAAAAEAAgAEAAUABgANAA8AEQASAAD//wAKAAAAAQACAAQABQAGAAwADwARABIAAP//AAoAAAABAAIABAAFAAYACgAPABEAEgAA//8ACgAAAAEAAgAEAAUABgALAA8AEQASABNhYWx0AHRjYWx0AHpjY21wAIBjY21wAIBkbGlnAIhmaW5hAI5pbml0AJRsb2NsAJpsb2NsAJpsb2NsAJpsb2NsAJpsb2NsAJpsb2NsAKBsb2NsAKBsb2NsAKZtZWRpAKxybGlnALJzYWx0ALhzczAxAL4AAAABAAAAAAABAA0AAAACAAEAAgAAAAEACgAAAAEACAAAAAEABgAAAAEAAwAAAAEABAAAAAEABQAAAAEABwAAAAEACQAAAAEACwAAAAEADAATACgERgSIBTYFRAVeBXwF0gZ0B7oILAp4Cs4LGAzuDQINMA1ODWwAAwAAAAEACAABAzgAbQDgAOQA6ADsAPAA9AD4APwBAAEEAQgBEAEYARwBJAEqATIBOAFAAUYBTgFWAV4BZgFuAXIBdgF6AYABhAGKAY4BkgGWAZwBoAGoAbABuAHAAcgB0AHYAeAB6AHwAfgB/AIEAiACJAIoAhACHAIgAiQCKAIuAjICPgJCAkYCTAJUAlwCZAJsAnACeAJ8AoQCiAKQApQCmAKcAqACpAKsArACtgK+AsICxgLOAtYC2gLgAuQC6ALsAvAC9AL4AvwDAAMEAwgDDAMQAxQDGAMcAyADJAMoAywDMAM0AAEA/wABAMQAAQDJAAEBHQABASIAAQE3AAEBOQABATsAAQE9AAEBPwADAUMBQgFBAAMBSgFJAUgAAQFLAAMBTwFOAU0AAgFRAVAAAwFVAVQBUwACAVYBVwADAVsBWgFZAAIBXAFdAAMBYQFgAV8AAwFlAWQBYwADAWkBaAFnAAMBbQFsAWsAAwFxAXABbwABAXMAAQF1AAEBdwACAXoBeQABAXsAAgF9AX8AAQF+AAEBgQABAYMAAgGGAYUAAQGHAAMBiwGKAYkAAwGPAY4BjQADAZMBkgGRAAMBlwGWAZUAAwGbAZoBmQADAZ8BngGdAAMBowGiAaEAAwGnAaYBpQADAasBqgGpAAMBrwGuAa0AAwGzAbIBsQABAbUAAwG5AbgBtwAFAb0BvAG7AcABvwAFAcUBwwHBAcABvwABAcAAAQHCAAEBxAACAccBxgABAccABQHPAc0BywHKAckAAQHMAAEBzgACAdEB0AADAdUB1AHTAAMB2QHYAdcAAwHdAdwB2wADAeEB4AHfAAEB4wADAecB5gHlAAEB6QADAe0B7AHrAAEB7wADAfMB8gHxAAEB9QABAfcAAQH5AAEB+wABAgEAAwIGAgUCAwABAgQAAgIIAgcAAwINAgwCCgABAgsAAQIOAAMC0wLUAtIAAwIUAhMCEQABAhIAAgIWAhUAAQIYAAECGgABAh0AAQIfAAECIQABAiMAAQIrAAECOQABAjsAAQI9AAECQQABAkMAAQJFAAECSQABAksAAQJNAAECUgABAlQAAQJWAAECegABAmwAAQJ7AAEAbQAmAMMAyAEcASEBNgE4AToBPAE+AUABRwFKAUwBTwFSAVUBWAFbAV4BYgFmAWoBbgFyAXQBdgF4AXoBfAF9AYABggGEAYYBiAGMAZABlAGYAZwBoAGkAagBrAGwAbQBtgG6AbsBvAG9Ab4BvwHBAcMBxQHGAcgBywHNAc8B0gHWAdoB3gHiAeQB6AHqAe4B8AH0AfYB+AH6AgACAgIDAgYCCQIKAg0CDwIQAhECFAIXAhkCHAIeAiACIgIkAjgCOgI8AkACQgJEAkgCSgJMAlECUwJVAnQCdgJ3AAYAAAACAAoAHAADAAAAAQisAAEALgABAAAADgADAAAAAQiaAAIAFAAcAAEAAAAOAAEAAgLPAtAAAgABAsICzQAAAAQAAAABAAgAAQCWAAgAFgAgACoANAA+AEgAUgBcAAEABAK6AAICswABAAQCtAACArMAAQAEArUAAgKzAAEABAK2AAICswABAAQCtwACArMAAQAEArgAAgKzAAEABAK5AAICswAHABAAFgAcACIAKAAuADQCugACAqkCtAACAq0CtQACAq4CtgACAq8CtwACArACuAACArECuQACArIAAgACAqkCqQAAAq0CswABAAEAAAABAAgAAQe+ANkAAQAAAAEACAABAAYAAQABAAQAwwDIARwBIQABAAAAAQAIAAIADAADAnoCbAJ7AAEAAwJ0AnYCdwABAAAAAQAIAAIApAAkAUMBSgFPAVUBWwFhAWUBaQFtAXEBiwGPAZMBlwGbAZ8BowGnAasBrwGzAbkBvQHFAc8B1QHZAd0B4QHnAe0B8wIGAg0C0wIUAAEAAAABAAgAAgBOACQBQgFJAU4BVAFaAWABZAFoAWwBcAGKAY4BkgGWAZoBngGiAaYBqgGuAbIBuAG8AcMBzQHUAdgB3AHgAeYB7AHyAgUCDALUAhMAAQAkAUABRwFMAVIBWAFeAWIBZgFqAW4BiAGMAZABlAGYAZwBoAGkAagBrAGwAbYBugG+AcgB0gHWAdoB3gHkAeoB8AICAgkCDwIQAAEAAAABAAgAAgCgAE0BNwE5ATsBPQE/AUEBSAFNAVMBWQFfAWMBZwFrAW8BcwF1AXcBegF9AYEBgwGGAYkBjQGRAZUBmQGdAaEBpQGpAa0BsQG1AbcBuwHBAcsB0wHXAdsB3wHjAeUB6QHrAe8B8QH1AfcB+QH7AgECAwIKAtICEQIYAhoCHQIfAiECIwIrAjkCOwI9AkECQwJFAkkCSwJNAlICVAJWAAEATQE2ATgBOgE8AT4BQAFHAUwBUgFYAV4BYgFmAWoBbgFyAXQBdgF4AXwBgAGCAYQBiAGMAZABlAGYAZwBoAGkAagBrAGwAbQBtgG6Ab4ByAHSAdYB2gHeAeIB5AHoAeoB7gHwAfQB9gH4AfoCAAICAgkCDwIQAhcCGQIcAh4CIAIiAiQCOAI6AjwCQAJCAkQCSAJKAkwCUQJTAlUABAAIAAEACAABAGAAAwCaAAwANgAFAAwAEgAYAB4AJAIdAAIBNwIfAAIBOQIhAAIBOwIjAAIBPQIrAAIBPwAFAAwAEgAYAB4AJAIcAAIBNwIeAAIBOQIgAAIBOwIiAAIBPQIkAAIBPwABAAMBNgHUAdUABAAJAAEACAABAh4AEQAoADYAWAB6AJwAvgDgAQIBJAFGAWgBigGkAcYB6AHyAhQAAQAEAmMABAHVAdQB5QAEAAoAEAAWABwCJwACAgECKAACAgMCKQACAgoCKgACAhEABAAKABAAFgAcAiwAAgIBAi0AAgIDAi4AAgIKAi8AAgIRAAQACgAQABYAHAIwAAICAQIxAAICAwIyAAICCgIzAAICEQAEAAoAEAAWABwCNAACAgECNQACAgMCNgACAgoCNwACAhEABAAKABAAFgAcAjkAAgIBAjsAAgIDAj0AAgIKAj8AAgIRAAQACgAQABYAHAI4AAICAQI6AAICAwI8AAICCgI+AAICEQAEAAoAEAAWABwCQQACAgECQwACAgMCRQACAgoCRwACAhEABAAKABAAFgAcAkAAAgIBAkIAAgIDAkQAAgIKAkYAAgIRAAQACgAQABYAHAJJAAICAQJLAAICAwJNAAICCgJPAAICEQAEAAoAEAAWABwCSAACAgECSgACAgMCTAACAgoCTgACAhEAAwAIAA4AFAJSAAICAQJUAAICAwJWAAICCgAEAAoAEAAWABwCUQACAgECUwACAgMCVQACAgoCVwACAhEABAAKABAAFgAcAlgAAgIBAlkAAgIDAloAAgIKAlsAAgIRAAEABAJdAAICEQAEAAoAEAAWABwCXgACAgECXwACAgMCYAACAgoCYQACAhEAAQAEAmIAAgIRAAEAEQE2AUkBTgFUAVoBigGLAY4BjwGSAZMBlgGXAeACBQIMAhMAAQAJAAEACAACACgAEQHAAcIBxAHHAcABwAHCAcQBxwHHAcoBzAHOAdECBAILAhIAAQARAboBuwG8Ab0BvgG/AcEBwwHFAcYByAHLAc0BzwIDAgoCEQABAAkAAQAIAAIAIgAOAcABwgHEAccBwAHAAcIBxAHHAccBygHMAc4B0QABAA4BugG7AbwBvQG+Ab8BwQHDAcUBxgHIAcsBzQHPAAYACQAKABoAPABWAHIAmAC+AQABIgFgAZoAAwABABIAAQHsAAAAAQAAAA8AAgACAXgBfwAAAYQBhwAIAAMAAAABAfAAAQASAAEAAAAQAAEAAgGGAYcAAwAAAAEB1gABABIAAQAAABEAAQADAVQBWgIMAAMAAAABABIAAQAcAAEAAAARAAEAAwFPAgYCFAABAAMBTgIFAhMAAwABABIAAQGUAAAAAQAAABIAAQAIATwBPQE+AT8CIgIjAiQCKwADAAAAAQB2AAEAEgABAAAAEgABABYBNgE4AToBPAE+AUoBSwFPAVEBVQFWAVsBXAHhAfgB+QIGAggCDQIOAhQCFgADAAAAAQA0AAEAEgABAAAAEgABAAYBeAF5AXwBfwGEAYUAAwAAAAEAEgABACIAAQAAABIAAQAGAXgBegF8AX0BhAGGAAEADAFiAWYBagFuAaABpAG2Ad4CAAICAgkCEAADAAEAEgABAC4AAAABAAAAEgACAAQBNgE/AAABhAGHAAoCHAIkAA4CKwIrABcAAQAEAb4BxQHIAc8AAwABABIAAQA0AAAAAQAAABIAAgAFATYBPwAAAXwBfwAKAYQBhwAOAhwCJAASAisCKwAbAAEAAgG6Ab0AAQAAAAEACAABAAYA1QABAAEAJgABAAkAAQAIAAIAFAAHAUsBUQFWAVwCCAIOAhYAAQAHAUoBTwFVAVsCBgINAhQAAQAJAAEACAACAAwAAwFXAV0CDgABAAMBVQFbAg0AAQAJAAEACAABAAYAAQABAAYBTwFVAVsCBgINAhQAAQAJAAEACAACACQADwFXAV0BeQF7AX8BfgGFAYcBvwHGAb8BxgHJAdACDgABAA8BVQFbAXgBegF8AX0BhAGGAboBvQG+AcUByAHPAg0AAAAAAAEAAAAAClExXk1eMEBoN0RvQHh0MnU3VWpyTUo0WDJYRUA=) format("truetype");
    font-weight: 400; font-style: normal; font-display: swap;
}
@font-face {
    font-family: "PeydaReport";
    src: url(data:font/truetype;charset=utf-8;base64,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AowAPgKMAD4CjAA+AowAPgKMAD4D5QARA+UAEQPlABED5QARAkoABwJKAAcCSgAHAkoABwIUACQCFAAkAhQAJAHsAB8B7AAfAewAHwHsAB8B7AAfAewAHwHsAB8B7AAfAewAGQMeAB8BugAgAboAGAG6ACABugAgAlUAJQIdAB8CHQAfAhEAHwIQAB8CEQAfAfEAHwIQAB8B8QAfAhAAHwIQAB8CEAAdAhoAIAIaACACGgAgAjgAGwD9ADkBEAA5ATj/zgE7ABkA9QA0ARL/+gD0/+UA/f/nAggAOQEHAD4BB/+5AQcALQEH/9kCOAA5AjgAOQI4ADkCOAA2AjgAOQIIACACCAAgAggAIAIIACACCAAgAggAIAIIACACCAAgA08AIAIdADgBmgA5AZr//AGaADABvgAgAb4AGgG+ACABvgAgAlUALAGPABoBj//ZAY8AGgGPABoCOAA1AjgANQI4ADUCOAA1AjgANQI4ADUCOAA1AjgANQMKABADCgAQAwoAEAMKABAB8wAMAfMADAHzAAwB1gAoAdYAKAHWACgB0wAxANoANAEIADUA0f/UARX/5gDq/+UBCgAGATb/7QFL/+0BS//QAUr/ywNiADQDgQA0AX7/8gFN//IBff/yAc3/8gJD//IDYgA0A4EANAF+//IBTf/yAc3/8gNiADQDgQA0AX7/8gF9//IBzf/yAkP/8gNiADQDgQA0AX7/8gF9//IBzf/yAgX/8gNiADQDgQA0AX7/8gF9//IBzf/yAfP/8gNiADQDgQA0AX7/8gFN//ICrwA2Ar4ANgKt//ICmf/yAr0ANgK+ADYCrf/yApn/8gKrADYCvgA2Aq3/8gKX//ICrwA2Ar4ANgKt//ICmf/yAjgANgJPADYCOAA2Ak8ANgI4ADYCTwA2AWj/2AEj/9oBiv/YAUX/2gFo/9gBiv/YAUX/2gEj/9oBaP/YAYr/2AFo/9gBiv/YAWj/2AEj/9oBxv/YAUX/2gSoADQE0wA2AwL/8gLh//IEqAA0BNMANgMC//IC4f/yBN8ANAUEADQDRf/yAx3/8gTfADQFBAA0A0X/8gMd//IC4gA2Aw4ANgLi//ICtv/yAuIANgMOADYC4v/yArb/8gI6ADYCdgA2Akb/8QHv//ICOgA2AnYANgJG//EB7//yA2YANgOyADYB9P/yAeP/8gNmADYDsgA2AfT/8gHj//IDZgA2A7IANgH0//IB4//yAssANgLjADYCywA2AuMANgH0//IB4//yA2MANgOBADYCAf/yAZj/8gOCADQDgwA0BGIANgPpADQEpQA2AgH/8gN2//IBmP/yAZj/8gMz//IDggA0A4QANARiADYD6QA0BKUANgIB//IDdv/NAZj/8gGY//IDM//NAskANQMCADUBVv/yAQ//8gLLADUDBAA1AVb/8gEP//ICsgA0AuAANAI1//ICEf/yAskANAL5ADQBfv/yAU3/8gLJADQC+QA0AfoANAIMADYCfv/yAwP/8gH6ADQCDAA2AfoANAI7ACoCXf/yAU3/8gH6ADQCDAA2AwP/8gJUADIDQf/yAwP/8gH6ADQCDAA2AfoANAI7ACoB9gAyAgkAMgH2ADICBgAyAfYAMgIGADIB9gAyAgYAMgLnADQC6AA0AucANALoADQCmgA0AX7/8gF9//IBzf/yAe//8gLoABYC6QA0ApoANAF+//IBTf/yAc3/8gLoABQC5wA0AugANAKaADQBfv/yAX3/8gHN//IB5v/yAmYANAKaADQCywA0AvoANAC0AAACLwAlAmwAJQIvAAgCbAAOAi8AJQJsACUCUv/7Aov/9wIv/+QDlwA0BAUANAObADQDmwA0A6AACwObADQCbP/UA/8ANAP/ADQEBAA5A/8ANAObADQDmwA0A54ANAObADQDnAA0A5wANAOcADQDnAA0BUkANAVsADQFSQA0BWwANAVJADQFbAA0BUkANAVsADQFSQA0BWwANAVJADQFbAA0BUkANAVsADQFSQA0BWwANAWLADQFrgA0BYsANAWuADQFiwA0BbAANAWLADQFrgA0Ba4ANAWLADQFrgA0BYsANAWuADQFiwA0Ba4ANAWLADQDmwA0A5cANAOXADQDlwA0BAUANAQFADQDlwA0A5cANAOXAC0DlwA0BAUANAUPADQBXwAtAQ4AKgEfADkA8wAjAi8AJwLzACcB1QAyAp4AIgItABkCZAANAmQADQIMAB4B6gA0APMAIwIvACcC8wAnAo0AJwKcACICUQAnAmQADQJkAA0CDAAeAlIAKQJkAA0COgAAB30AAAAAAAAAAAAAAAAAAAAAAAACOgAAAjoAAAJfAAACXwAAAn4AAAK3AAACYQAAAqsAAAKZAAACbAAAAwUAAAFKABkBDgAt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AGEAQgBvAGwAZAAzAC4AMAAwADAAOwBLAEgARABNADsAUABlAHkAZABhAC0AQgBvAGwAZABQAGUAeQBkAGEAIABCAG8AbABkAFYAZQByAHMAaQBvAG4AIAAzAC4AMAAwADAAUABlAHkAZABhAC0AQgBvAGwAZABQAGUAeQBkAGEAIABpAHMAIABhACAAdAByAGEAZABlAG0AYQByAGsAIABvAGYAIAB3AHcAdwAuAGYAbwBuAHQAaQByAGEAbgAuAGMAbwBtAE4AYQBzAGUAcgAgAEsAaABhAGQAZQBtAFQAbwAgAHUAcwBlACAAdABoAGkAcwAgAGYAbwBuAHQALAAgAGkAdAAgAGkAcwAgAG4AZQBjAGUAcwBzAGEAcgB5ACAAdABvACAAbwBiAHQAYQBpAG4AIAB0AGgAZQAgAGwAaQBjAGUAbgBzAGUAIABmAHIAbwBtACAAdwB3AHcALgBmAG8AbgB0AGkAcgBhAG4ALgBjAG8AbQB3AHcAdwAuAGYAbwBuAHQAaQByAGEAbgAuAGMAbwBtAGgAdAB0AHAAcwA6AC8ALwBkAHIAaQBiAGIAYgBsAGUALgBjAG8AbQAvAG4AYQBzAGUAcgBrAGgAYQBkAGUAbQBmAG8AbgB0AGkAcgBhAG4ALgBjAG8AbQAvAGwAaQBjAGUAbgBzAGUAcwAAAAIAAAAAAAD/nAAyAAAAAAAAAAAAAAAAAAAAAAAAAAAC1gAAAAEAAgADACQAJQAmACcAKAApACoAKwAsAC0ALgAvADAAMQAyADMANAA1ADYANwA4ADkAOgA7ADwAPQBEAEUARgBHAEgASQBKAEsATABNAE4ATwBQAFEAUgBTAFQAVQBWAFcAWABZAFoAWwBcAF0AEwAUABUAFgAXABgAGQAaABsAHAARAA8AHQAeABAADgANAEEA2QASAB8AIAAhAAQAIgAKAAUABgAjAAcACAAJAAsADABeAF8AYAA+AD8AQAC2ALcAtAC1AMQAxQCHAEIAsgCzAIwAigCLAL0AhACFAJYA7wCTAPAAuADoAKsAwwCjAKIAgwC8AIgAhgCCAMIAYQC+AL8BAgEDAMkBBADHAGIArQEFAQYAYwCuAJAA/QD/AGQBBwDpAQgBCQBlAQoAyADKAQsAywEMAQ0BDgD4AQ8BEAERAMwAzQDOAPoAzwESARMBFAEVARYBFwDiARgBGQEaAGYBGwDQANEAZwDTARwBHQCRAK8AsADtAR4BHwEgASEA5AD7ASIBIwEkASUBJgEnANQA1QBoANYBKAEpASoBKwEsAS0BLgEvAOsBMAC7ATEBMgDmATMAaQE0AGsAbABqATUBNgBuAG0AoAD+AQAAbwE3AOoBOAEBAHABOQByAHMBOgBxATsBPAE9APkBPgE/AUAA1wB0AHYAdwFBAHUBQgFDAUQBRQFGAUcA4wFIAUkBSgB4AUsAeQB7AHwAegFMAU0AoQB9ALEA7gFOAU8BUAFRAOUA/AFSAIkBUwFUAVUBVgB+AIAAgQB/AVcBWAFZAVoBWwFcAV0BXgDsAV8AugFgAOcBYQFiAWMBZAFlAWYBZwFoAWkBagFrAWwBbQFuAW8BcAFxAXIBcwF0AXUBdgF3AXgBeQF6AXsBfAF9AX4BfwGAAYEBggGDAYQBhQGGAYcBiAGJAYoBiwGMAY0BjgGPAZABkQGSAZMBlAGVAZYBlwGYAZkBmgGbAZwBnQGeAZ8BoAGhAaIBowGkAaUBpgGnAagBqQGqAasBrAGtAa4BrwGwAbEBsgGzAbQBtQG2AbcBuAG5AboBuwG8Ab0BvgG/AcABwQHCAcMBxAHFAcYBxwHIAckBygHLAcwBzQHOAc8B0AHRAdIB0wHUAdUB1gHXAdgB2QHaAdsB3AHdAd4B3wHgAeEB4gHjAeQB5QHmAecB6AHpAeoB6wHsAe0B7gHvAfAB8QHyAfMB9AH1AfYB9wH4AfkB+gH7AfwB/QH+Af8CAAIBAgICAwIEAgUCBgIHAggCCQIKAgsCDAINAg4CDwIQAhECEgITAhQCFQIWAhcCGAIZAhoCGwIcAh0CHgIfAiACIQIiAiMCJAIlAiYCJwIoAikCKgIrAiwCLQIuAi8CMAIxAjICMwI0AjUCNgI3AjgCOQI6AjsCPAI9Aj4CPwJAAkECQgJDAkQCRQJGAkcCSAJJAkoCSwJMAk0CTgJPAlACUQJSAlMCVAJVAlYCVwJYAlkCWgJbAlwCXQJeAl8CYAJhAmICYwJkAmUCZgJnAmgCaQJqAmsCbAJtAm4CbwJwAnECcgJzAnQCdQJ2AncCeAJ5AnoCewJ8An0CfgJ/AoACgQKCAoMChAKFAoYChwKIAokCigKLAowCjQKOAo8CkAKRApICkwKUApUClgKXApgCmQKaApsCnAKdAp4CnwKgAqECogKjAqQCpQKmAqcCqAKpAqoCqwKsAq0CrgKvArACsQKyArMCtAK1ArYCtwK4ArkCugK7ArwCvQK+Ar8CwACpAKoCwQLCAsMCxALFAsYCxwLIAskCygLLAswCzQLOAs8C0ALRAtIC0wLUAtUC1gLXAtgC2QLaAtsC3ALdAt4C3wLgAuEC4gLjAuQC5QLmAucC6ALpAuoC6wLsAu0C7gLvAvAC8QLyAvMC9AL1AvYC9wL4AvkC+gL7AOEC/AL9Av4C/wd1bmkwNjVBB3VuaTA2NUIGQWJyZXZlB0FtYWNyb24HQW9nb25lawpDZG90YWNjZW50BkRjYXJvbgZEY3JvYXQGRWNhcm9uCkVkb3RhY2NlbnQHRW1hY3JvbgdFb2dvbmVrB3VuaTAxOEYHdW5pMDEyMgpHZG90YWNjZW50BEhiYXIHSW1hY3JvbgdJb2dvbmVrB3VuaTAxMzYGTGFjdXRlBkxjYXJvbgd1bmkwMTNCBk5hY3V0ZQZOY2Fyb24HdW5pMDE0NQNFbmcNT2h1bmdhcnVtbGF1dAdPbWFjcm9uBlJhY3V0ZQZSY2Fyb24HdW5pMDE1NgZTYWN1dGUHdW5pMDIxOAd1bmkxRTlFBFRiYXIGVGNhcm9uB3VuaTAxNjIHdW5pMDIxQQ1VaHVuZ2FydW1sYXV0B1VtYWNyb24HVW9nb25lawVVcmluZwZXYWN1dGULV2NpcmN1bWZsZXgJV2RpZXJlc2lzBldncmF2ZQtZY2lyY3VtZmxleAZZZ3JhdmUGWmFjdXRlClpkb3RhY2NlbnQGYWJyZXZlB2FtYWNyb24HYW9nb25lawpjZG90YWNjZW50BmRjYXJvbgZlY2Fyb24KZWRvdGFjY2VudAdlbWFjcm9uB2VvZ29uZWsHdW5pMDI1OQd1bmkwMTIzCmdkb3RhY2NlbnQEaGJhcglpLmxvY2xUUksHaW1hY3Jvbgdpb2dvbmVrB3VuaTAxMzcGbGFjdXRlBmxjYXJvbgd1bmkwMTNDBm5hY3V0ZQZuY2Fyb24HdW5pMDE0NgNlbmcNb2h1bmdhcnVtbGF1dAdvbWFjcm9uBnJhY3V0ZQZyY2Fyb24HdW5pMDE1NwZzYWN1dGUHdW5pMDIxOQR0YmFyBnRjYXJvbgd1bmkwMTYzB3VuaTAyMUINdWh1bmdhcnVtbGF1dAd1bWFjcm9uB3VvZ29uZWsFdXJpbmcGd2FjdXRlC3djaXJjdW1mbGV4CXdkaWVyZXNpcwZ3Z3JhdmULeWNpcmN1bWZsZXgGemFjdXRlCnpkb3RhY2NlbnQHdW5pMDYyMQd1bmkwNjI3DHVuaTA2MjcuZmluYQd1bmkwNjIzDHVuaTA2MjMuZmluYQd1bmkwNjI1DHVuaTA2MjUuZmluYQd1bmkwNjIyDHVuaTA2MjIuZmluYQd1bmkwNjcxDHVuaTA2NzEuZmluYQd1bmkwNjZFDHVuaTA2NkUuZmluYQx1bmkwNjZFLm1lZGkMdW5pMDY2RS5pbml0EHVuaTA2NkUuaW5pdC5hbHQRdW5pMDY2RS5pbml0LmFsdDIRdW5pMDY2RS5pbml0LmFsdDMHdW5pMDYyOAx1bmkwNjI4LmZpbmEMdW5pMDYyOC5tZWRpDHVuaTA2MjguaW5pdBB1bmkwNjI4LmluaXQuYWx0B3VuaTA2N0UMdW5pMDY3RS5maW5hDHVuaTA2N0UubWVkaQx1bmkwNjdFLmluaXQQdW5pMDY3RS5pbml0LmFsdBF1bmkwNjdFLmluaXQuYWx0Mgd1bmkwNjJBDHVuaTA2MkEuZmluYQx1bmkwNjJBLm1lZGkMdW5pMDYyQS5pbml0EHVuaTA2MkEuaW5pdC5hbHQRdW5pMDYyQS5pbml0LmFsdDIHdW5pMDYyQgx1bmkwNjJCLmZpbmEMdW5pMDYyQi5tZWRpDHVuaTA2MkIuaW5pdBB1bmkwNjJCLmluaXQuYWx0EXVuaTA2MkIuaW5pdC5hbHQyB3VuaTA2NzkMdW5pMDY3OS5maW5hDHVuaTA2NzkubWVkaQx1bmkwNjc5LmluaXQHdW5pMDYyQwx1bmkwNjJDLmZpbmEMdW5pMDYyQy5tZWRpDHVuaTA2MkMuaW5pdAd1bmkwNjg2DHVuaTA2ODYuZmluYQx1bmkwNjg2Lm1lZGkMdW5pMDY4Ni5pbml0B3VuaTA2MkQMdW5pMDYyRC5maW5hDHVuaTA2MkQubWVkaQx1bmkwNjJELmluaXQHdW5pMDYyRQx1bmkwNjJFLmZpbmEMdW5pMDYyRS5tZWRpDHVuaTA2MkUuaW5pdAd1bmkwNjJGDHVuaTA2MkYuZmluYQd1bmkwNjMwDHVuaTA2MzAuZmluYQd1bmkwNjg4DHVuaTA2ODguZmluYQd1bmkwNjMxC3VuaTA2MzEuYWx0DHVuaTA2MzEuZmluYRB1bmkwNjMxLmZpbmEuYWx0B3VuaTA2MzIMdW5pMDYzMi5maW5hEHVuaTA2MzIuZmluYS5hbHQLdW5pMDYzMi5hbHQHdW5pMDY5MQx1bmkwNjkxLmZpbmEHdW5pMDY5NQx1bmkwNjk1LmZpbmEHdW5pMDY5OAt1bmkwNjk4LmFsdAx1bmkwNjk4LmZpbmEQdW5pMDY5OC5maW5hLmFsdAd1bmkwNjMzDHVuaTA2MzMuZmluYQx1bmkwNjMzLm1lZGkMdW5pMDYzMy5pbml0B3VuaTA2MzQMdW5pMDYzNC5maW5hDHVuaTA2MzQubWVkaQx1bmkwNjM0LmluaXQHdW5pMDYzNQx1bmkwNjM1LmZpbmEMdW5pMDYzNS5tZWRpDHVuaTA2MzUuaW5pdAd1bmkwNjM2DHVuaTA2MzYuZmluYQx1bmkwNjM2Lm1lZGkMdW5pMDYzNi5pbml0B3VuaTA2MzcMdW5pMDYzNy5maW5hDHVuaTA2MzcubWVkaQx1bmkwNjM3LmluaXQHdW5pMDYzOAx1bmkwNjM4LmZpbmEMdW5pMDYzOC5tZWRpDHVuaTA2MzguaW5pdAd1bmkwNjM5DHVuaTA2MzkuZmluYQx1bmkwNjM5Lm1lZGkMdW5pMDYzOS5pbml0B3VuaTA2M0EMdW5pMDYzQS5maW5hDHVuaTA2M0EubWVkaQx1bmkwNjNBLmluaXQHdW5pMDY0MQx1bmkwNjQxLmZpbmEMdW5pMDY0MS5tZWRpDHVuaTA2NDEuaW5pdAd1bmkwNkE0DHVuaTA2QTQuZmluYQx1bmkwNkE0Lm1lZGkMdW5pMDZBNC5pbml0B3VuaTA2QTEMdW5pMDZBMS5maW5hDHVuaTA2QTEubWVkaQx1bmkwNkExLmluaXQHdW5pMDY2Rgx1bmkwNjZGLmZpbmEHdW5pMDY0Mgx1bmkwNjQyLmZpbmEMdW5pMDY0Mi5tZWRpDHVuaTA2NDIuaW5pdAd1bmkwNjQzDHVuaTA2NDMuZmluYQx1bmkwNjQzLm1lZGkMdW5pMDY0My5pbml0B3VuaTA2QTkLdW5pMDZBOS5hbHQMdW5pMDZBOS5zczAxDHVuaTA2QTkuZmluYRF1bmkwNkE5LmZpbmEuc3MwMQx1bmkwNkE5Lm1lZGkRdW5pMDZBOS5tZWRpLnNzMDEMdW5pMDZBOS5pbml0EHVuaTA2QTkuaW5pdC5hbHQRdW5pMDZBOS5pbml0LnNzMDEHdW5pMDZBRgt1bmkwNkFGLmFsdAx1bmkwNkFGLnNzMDEMdW5pMDZBRi5maW5hEXVuaTA2QUYuZmluYS5zczAxDHVuaTA2QUYubWVkaRF1bmkwNkFGLm1lZGkuc3MwMQx1bmkwNkFGLmluaXQQdW5pMDZBRi5pbml0LmFsdBF1bmkwNkFGLmluaXQuc3MwMQd1bmkwNjQ0DHVuaTA2NDQuZmluYQx1bmkwNjQ0Lm1lZGkMdW5pMDY0NC5pbml0B3VuaTA2QjUMdW5pMDZCNS5maW5hDHVuaTA2QjUubWVkaQx1bmkwNkI1LmluaXQHdW5pMDY0NQx1bmkwNjQ1LmZpbmEMdW5pMDY0NS5tZWRpDHVuaTA2NDUuaW5pdAd1bmkwNjQ2DHVuaTA2NDYuZmluYQx1bmkwNjQ2Lm1lZGkMdW5pMDY0Ni5pbml0B3VuaTA2QkEMdW5pMDZCQS5maW5hB3VuaTA2NDcMdW5pMDY0Ny5maW5hDHVuaTA2NDcubWVkaQx1bmkwNjQ3LmluaXQHdW5pMDZDMAx1bmkwNkMwLmZpbmEHdW5pMDZDMQx1bmkwNkMxLmZpbmEMdW5pMDZDMS5tZWRpDHVuaTA2QzEuaW5pdAd1bmkwNkMyDHVuaTA2QzIuZmluYQd1bmkwNkJFDHVuaTA2QkUuZmluYQx1bmkwNkJFLm1lZGkMdW5pMDZCRS5pbml0B3VuaTA2MjkMdW5pMDYyOS5maW5hB3VuaTA2QzMMdW5pMDZDMy5maW5hB3VuaTA2NDgMdW5pMDY0OC5maW5hB3VuaTA2MjQMdW5pMDYyNC5maW5hB3VuaTA2QzYMdW5pMDZDNi5maW5hB3VuaTA2QzcMdW5pMDZDNy5maW5hB3VuaTA2NDkMdW5pMDY0OS5maW5hB3VuaTA2NEEMdW5pMDY0QS5maW5hEXVuaTA2NEEuZmluYS5zczAxDHVuaTA2NEEubWVkaQx1bmkwNjRBLmluaXQQdW5pMDY0QS5pbml0LmFsdBF1bmkwNjRBLmluaXQuYWx0Mgd1bmkwNjI2DHVuaTA2MjYuZmluYRF1bmkwNjI2LmZpbmEuc3MwMQx1bmkwNjI2Lm1lZGkMdW5pMDYyNi5pbml0EHVuaTA2MjYuaW5pdC5hbHQHdW5pMDZDRQd1bmkwNkNDDHVuaTA2Q0MuZmluYRF1bmkwNkNDLmZpbmEuc3MwMQx1bmkwNkNDLm1lZGkMdW5pMDZDQy5pbml0EHVuaTA2Q0MuaW5pdC5hbHQRdW5pMDZDQy5pbml0LmFsdDIHdW5pMDZEMgx1bmkwNkQyLmZpbmEHdW5pMDc2OQx1bmkwNzY5LmZpbmEHdW5pMDY0MAt1bmkwNjQ0MDYyNxB1bmkwNjQ0MDYyNy5maW5hC3VuaTA2NDQwNjIzEHVuaTA2NDQwNjIzLmZpbmELdW5pMDY0NDA2MjUQdW5pMDY0NDA2MjUuZmluYQt1bmkwNjQ0MDYyMhB1bmkwNjQ0MDYyMi5maW5hC3VuaTA2NDQwNjcxEHVuaTA2NkUwNkNDLmZpbmEVdW5pMDY2RTA2Q0MuX2ZpbmEuYWx0EHVuaTA2MjgwNjQ5LmZpbmEQdW5pMDYyODA2NEEuZmluYRB1bmkwNjI4MDYyNi5maW5hEHVuaTA2MjgwNkNDLmZpbmEQdW5pMDY0NDA2NzEuZmluYRB1bmkwNjdFMDY0OS5maW5hEHVuaTA2N0UwNjRBLmZpbmEQdW5pMDY3RTA2MjYuZmluYRB1bmkwNjdFMDZDQy5maW5hEHVuaTA2MkEwNjQ5LmZpbmEQdW5pMDYyQTA2NEEuZmluYRB1bmkwNjJBMDYyNi5maW5hEHVuaTA2MkEwNkNDLmZpbmEQdW5pMDYyQjA2NDkuZmluYRB1bmkwNjJCMDY0QS5maW5hEHVuaTA2MkIwNjI2LmZpbmEQdW5pMDYyQjA2Q0MuZmluYQt1bmkwNjMzMDY0ORB1bmkwNjMzMDY0OS5maW5hC3VuaTA2MzMwNjRBEHVuaTA2MzMwNjRBLmZpbmELdW5pMDYzMzA2MjYQdW5pMDYzMzA2MjYuZmluYQt1bmkwNjMzMDZDQxB1bmkwNjMzMDZDQy5maW5hC3VuaTA2MzQwNjQ5EHVuaTA2MzQwNjQ5LmZpbmELdW5pMDYzNDA2NEEQdW5pMDYzNDA2NEEuZmluYQt1bmkwNjM0MDYyNhB1bmkwNjM0MDYyNi5maW5hC3VuaTA2MzQwNkNDEHVuaTA2MzQwNkNDLmZpbmELdW5pMDYzNTA2NDkQdW5pMDYzNTA2NDkuZmluYQt1bmkwNjM1MDY0QRB1bmkwNjM1MDY0QS5maW5hC3VuaTA2MzUwNjI2EHVuaTA2MzUwNjI2LmZpbmELdW5pMDYzNTA2Q0MQdW5pMDYzNTA2Q0MuZmluYRp1bmkwNjM2X2ZhcnNpX3VuaTA2Q0MuZmluYQt1bmkwNjM2MDY0ORB1bmkwNjM2MDY0OS5maW5hC3VuaTA2MzYwNjRBEHVuaTA2MzYwNjRBLmZpbmELdW5pMDYzNjA2MjYQdW5pMDYzNjA2MjYuZmluYQt1bmkwNjM2MDZDQxB1bmkwNjQ2MDY0OS5maW5hEHVuaTA2NDYwNjRBLmZpbmEQdW5pMDY0NjA2MjYuZmluYRB1bmkwNjQ2MDZDQy5maW5hEHVuaTA2NEEwNjRBLmZpbmEQdW5pMDY0QTA2Q0MuZmluYRB1bmkwNjI2MDY0OS5maW5hEHVuaTA2MjYwNjRBLmZpbmEQdW5pMDYyNjA2MjYuZmluYRB1bmkwNjI2MDZDQy5maW5hEHVuaTA2Q0MwNkNDLmZpbmEHdW5pRkRGMgd1bmkwNjZCB3VuaTA2NkMHdW5pMDY2MAd1bmkwNjYxB3VuaTA2NjIHdW5pMDY2Mwd1bmkwNjY0B3VuaTA2NjUHdW5pMDY2Ngd1bmkwNjY3B3VuaTA2NjgHdW5pMDY2OQd1bmkwNkYwB3VuaTA2RjEHdW5pMDZGMgd1bmkwNkYzB3VuaTA2RjQHdW5pMDZGNQd1bmkwNkY2B3VuaTA2RjcHdW5pMDZGOAd1bmkwNkY5DHVuaTA2RjQudXJkdQx1bmkwNkY3LnVyZHUHdW5pMzAwMAd1bmkyMDVGB3VuaTIwMEUHdW5pMjAwRgd1bmkyMDBEB3VuaTIwMEMHdW5pMjAwMQd1bmkyMDAzB3VuaTIwMDAHdW5pMjAwMgd1bmkyMDA1B3VuaTIwMEEHdW5pMjAyRgd1bmkyMDA2B3VuaTIwMDkHdW5pMjAwNAd1bmkyMDBCB3VuaTA2RDQHdW5pMDYwQwd1bmkwNjFCB3VuaTA2MUYHdW5pMDY2RAd1bmlGRDNFB3VuaUZEM0YHdW5pRkRGQwd1bmkwNjZBB3VuaTA2MTUKZG90YWJvdmVhcgpkb3RiZWxvd2FyC2RvdGNlbnRlcmFyFnR3b2RvdHN2ZXJ0aWNhbGFib3ZlYXIWdHdvZG90c3ZlcnRpY2FsYmVsb3dhchh0d29kb3RzaG9yaXpvbnRhbGFib3ZlYXIYdHdvZG90c2hvcml6b250YWxiZWxvd2FyFHRocmVlZG90c2Rvd25hYm92ZWFyFHRocmVlZG90c2Rvd25iZWxvd2FyEnRocmVlZG90c3VwYWJvdmVhchJ0aHJlZWRvdHN1cGJlbG93YXIHd2FzbGFhcgttaW5pS2VoZWhhchFnYWZzYXJrYXNoYWJvdmVhchVnYWZzYXJrYXNoYWJvdmVhci5hbHQSZ2Fmc2Fya2FzaGNlbnRlcmFyB3VuaTA2NzAHdW5pMDY1Ngd1bmkwNjU0B3VuaTA2NTUHdW5pMDY0Qgd1bmkwNjRDB3VuaTA2NEQHdW5pMDY0RQd1bmkwNjRGB3VuaTA2NTAHdW5pMDY1MQt1bmkwNjUxMDY0Qgt1bmkwNjUxMDY0Qwt1bmkwNjUxMDY0RAt1bmkwNjUxMDY0RQt1bmkwNjUxMDY0Rgt1bmkwNjUxMDY1MAt1bmkwNjUxMDY3MAd1bmkwNjUyB3VuaTA2NTMIc2FyZXlhYXIRc2V2ZW5zYW1sbC5ib3R0b20Qc2V2ZW5zbWFsbC5hYm92ZQ55ZWhzYW1sLmJvdHRvbQ15ZWhzbWFsLmFib3ZlB3VuaTAzMDgHdW5pMDMwNwlncmF2ZWNvbWIJYWN1dGVjb21iB3VuaTAzMEIHdW5pMDMwMgd1bmkwMzBDB3VuaTAzMDYHdW5pMDMwQQl0aWxkZWNvbWIHdW5pMDMwNAd1bmkwMzEyB3VuaTAzMjYHdW5pMDMyNwd1bmkwMzI4DHVuaTA2Y2UuZmluYQx1bmkwNmNlLmluaXQMdW5pMDZjZS5tZWRpDHVuaTA2ZDUuZmluYQAAAQACAA4AAAAAAAAANgACAAYAgwCEAAMBNQIbAAECHAJjAAICmAK8AAMCwgLQAAMC0gLVAAEAAQACAAAADAAAABgAAQAEAqoCrAKvArIAAQAVAIMAhAKYAqQCpQKpAqsCrQKuArACsQKzArQCtQK2ArcCuAK5AroCuwK8AAEAAAAKAH4AugADREZMVAAUYXJhYgAYbGF0bgAuAFQAAAAKAAFVUkQgAFAAAP//AAMAAAADAAQALgAHQVpFIAA6Q1JUIAA6S0FaIAA6TU9MIAA6Uk9NIAA6VEFUIAA6VFJLIAA6AAD//wADAAEAAgAEAAD//wADAAAAAgAEAAVrZXJuACBrZXJuACBtYXJrACptYXJrACpta21rADQAAAADAAAAAQACAAAAAwADAAQABQAAAAIABgAHAAgAEgXyFvgZmhpOJ5Qx8DJsAAIACAACAAoEKgABAEQABAAAAB0C5ALkAIIAggLyAIgAtgEYARgBJgGAAYoB/AIKAnwC1gLWAuQC5ALyAvIDCAMOAxwD6gPwBAYEEAQWAAEAHQBCAEMARABFAEYASABLAFEAUgBYAFkAWgBcAF0AXgBhAGMAZABlAGgAaQB3AHgAeQCBAIICcAJ2AncAAQAZ//gACwAE/+gADf/7ABcADQAdAAUAIP/xACH/7wAi//EAJP/yACz/8QAu/+8AMP/1ABgABP/eAAb/8AAK/+0ADf/0ABL/7QAU/+0AHv/gACD/2wAh/9sAIv/bACT/3QAq/+kAK//pACz/2wAt/+kALv/bAC//6QAw/+AAMv/rADP/7wA0//AANv/uADf/6gBLAAAAAwBL/78AVP/3AFf/7wAWAAb/8QAK//AAEv/wABT/8AAe//AAIP/rACH/7AAi/+sAI//zACcAHAAq//EAK//xACz/6wAt//EALv/sAC//8QAw//MAMv/wADP/8wA0/+4ANv/zAFr/8gACAFwABABfAAQAHAAEAAoABv/6AAr/9wAS//cAFP/3ABYABQAe//wAIP/0ACH/9gAi//QAIwAFACcAGwAqAAsAKwALACz/9AAtAAsALv/2AC8ACwAwAAsAMQAJADL/+QAz//sANP/3ADUACQA2//oANwAIAFgABABa//gAAwBZ//IAXP/4AF//7wAcAAQACwAG//UACv/wABL/8AAU//AAFgAFAB7/9gAg/+oAIf/rACL/6gAj//gAJwALACoADQArAA0ALP/qAC0ADQAu/+sALwANADAADQAx//wAMv/zADP/8gA0//EANQAJADb/8QA3AAoAWAAEAFr/7wAWAAb/6AAK/+YAEv/mABT/5gAW//MAF//JABj/5AAZ/9IAGv/cABz/uAAg//MAIv/zACP/8AAs//MAMf/uADP/7AA0//AANv/rAFH/tQBS/7UAYf+8AGP/vAADAEv/tgBU/+gAV//tAAMAGf/eACP/9AAz/+8ABQAZ/+wAG//kACP/9gAz//kANf/tAAEAKf+7AAMAF//rABkABAAc/+cAMwAE//sABf/5AAb/9gAH//kACP/5AAn/+QAK//QAC//5AAz/+QANAAYADv/5AA//+QAQ//kAEf/5ABL/9AAT//kAFP/0ABX/+QAW//0AF//PABj/8wAZ/+QAGv/rABv/+AAc/80AHf/6AB7/8wAf//QAIP/vACH/7wAi/+8AI//wACX/9AAm//QAJ//0ACj/9AAp//QAKv/0ACv/9AAs/+8ALf/0AC7/7wAv//QAMP/yADH/8AAy//EAM//sADT/7wA1//QANv/pADf/8wABABn/+QAFABn/6wAb/+4AI//zADMABAA1/+0AAgJ3AAACeAAAAAECcP+PAAICcAAAAnj/tQACAMgABAAAAOIBBAAEABcAAP/U/94AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD/y/+8AAUABf/4/+cAEf+O//X/9f/sAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA/8v/wwAAAAAAAP/zAAD/y//6AAT/+AAF//X/8v/xAAT/2wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP/KAAAAAAAAAAD/6P/5AAAAAAAAAAD/9/+P//b/+gACAAEACwBCAEMARABFAEYAUQBSAGcAaABpAHEAAgAFAEIAQwABAEYARgACAFEAUgADAGcAaQACAHEAcQACAAIAHQAEAAQADAAGAAYAAwAKAAoABAANAA0ADQASABIABAAUABQABAAWABYADgAXABcAAQAYABgABQAaABoABgAcABwAAgAdAB0ADwAeAB4AEAAgACAAEgAhACEAFAAiACIAEgAkACQAFQAsACwAEgAuAC4AFAAwADAAFgAxADEACQA0ADQACgA2ADYACwA3ADcAEQBCAEMAEwBGAEYABwBRAFIACABnAGkABwBxAHEABwACAAgAAgAKCAAAAQB0AAQAAAA1AJwAxgEIARYBPAFGAdwCMAIwAe4B9AICAjACMAKkAjYCpALGAtwC8gMQAxoDxAPOBDgEWgRoBaoEigSgBMoFLAVWBToFUAVWBVYFfAWqBjIF2AX2BiAGMgZUBs4G8Ac6B1gHcgeEB8oH2AACAAYABAAgAAAAIgAlAB0AKAA3ACEAVABUADEAVwBXADIAagBrADMACgAZ/7IAI//3ADP/9ABI/+kAUP/3AFwACgBe/9gAXwALAGr/5wBr//IAEAAE//kADQAJABcACQAZ//gAGgABABv/9gAc/+sAJP/6ADMAAgA0AAIANQACADYAAgBQAAQAXAAKAF7/6wBf//gAAwAj//wAMwAAAGsABgAJABn/9wAb/+8ANQABAEv/7QBQAAQAWf/yAFz/+wBe/+kAX//yAAIAIwABADMABQAlAAT/8QAGAAUACgAFAA3//gASAAUAFAAFABYABQAbAAIAHv/4ACD/8AAh/+8AIv/wACP//AAk/+sAKv/xACv/8QAs//AALf/xAC7/7wAv//EAMP/xADEABAAy//UAMwAFADT//gA1AAIANv//ADf/+wBC/9kAQ//ZAEb/9QBL/9YAZP/ZAGX/2QBo//UAaf/1AHb/2QAEABn/+QAj//oAM//8AF7/8wABACP/+AADACP/8QAz//MAawAFAAsAGf/LACP/9gAz/+YASP+8AFAABgBcAAUAXv+3AF8ABwBq/7sAa//NAHcAGwABACP/9gAbAAT/8wAN//8AGf/4ABv/7wAc/+wAHQAEAB7/+wAgAAIAIQACACIAAgAkAAIALAACAC4AAgBC/80AQ//NAEYABABL/9kAWf/zAFz/+wBe//AAX//4AGT/zQBl/80AaAAEAGkABAB2/80AgQAEAAgAGf/3ABv/8ABL/+4AUAAEAFn/7wBc//oAXv/oAF//8AAFABn/+AAb//YAXAAIAF7/7QBfAAgABQAZ//kAG//7ACP/9gAz//wANf/5AAcAI//wADP/2AA1/9oAS//QAFT/9gBX//sAawAEAAIAI//4AEv/6wAqAAT/5gAG//gACv/3AA3//gAS//cAFP/3ABb/+AAe/+sAIP/kACH/5gAi/+QAI//3ACT/5gAq/+0AK//tACz/5AAt/+0ALv/mAC//7QAw/+sAMv/yADP/+wA0//gANf/6ADb/+wA3//IAQv/eAEP/3gBE//gARf/4AEb/7ABL/9kAVP/1AFf/9ABk/94AZf/eAGj/7ABp/+wAawAEAHb/3gCB/+oAgv/5AAIAS//iAFcAAwAaAAb/8QAK//AAEv/wABT/8AAe//gAIP/kACH/6wAi/+QAI//1ACT/6gAq//gAK//4ACz/5AAt//gALv/rAC//+AAx//UAMv/sADP/7AA0/+kANv/rAEb/4wBo/+MAaf/jAGsABACB//AACAAj/+cAM//j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AKP/nAABALUCywABAKv/mwABAPQCyAABALL/nAABALoC1AABAbL/nAABAbUDFgABAcv/nAABAbMDFgABALf/nAABALoDUQABALIDbgABAKz/nAABAQMDaQABAKL/nAABALwDXwABAYsDJAABAZ8DIwABALsDWQABAIkDZAABARD+XAABAOcCNwABAOL+WwABAOUCNAABAUz+mgABAL4CIQABAU3+qAABAMYCIQABAPD+WQABAN0CNQABAOz+VQABAN4CGgABAT/+BwABANECHAABAT3+AgABAMkCGwABAPX+SgABANkCNAABAPD+QgABANgCNAABAQf/nAABALwCIQABAPL/nAABALcCIQABALz+WwABANwDJAABANr+WgABAN0DQgABALv/nAABAMcDGQABALb/nAABAMUDIAABAQz/jQABATAChAABAR3/kQABAU0ClwABAQ//lAABAQoDRwABAP3/jQABAU8DYwABATkD6AABAWoECgABAIr+ywABAN8B2AABAHn+0wABALEB2wABAHP+wwABAPYB1AABAKv+7gABALIB5AABAKP+4QABAOkCtQABAKj+3gABAPUCuQABAKL+/QABALMCswABAJf+0gABALgCqAABAOQDQwABAPgDTQABAJz9aAABAJ/9ZwABAJ3+yQABAOcDSAABAJX+4gABAK4DSAABAKj+4gABAPcDSQABAJz+7QABAKgDSAABA0L/nAABA0sB2gABA1//mwABA1MBzQABAWr/nAABAYcB3AABAX7/nAABAYcB3gABA0n/nAABAzgDRQABA03/nAABAzUDOAABAYT/nAABAWgDRAABAXb/nAABAWgDRgABA4n/nAABA+ECAgABA4//nAABA9oB+QABAcP/nAABAhsCAAABAhcCBwABA4P/nAABA9kC5wABA5T/nAABA90C4gABAar/nAABAh4C3QABAbz/nAABAiMC1QABAV3/nAABAisB9gABAWH/nAABAiwB+QABAR3/nAABAf0B5wABAR7/nAABAfsB8AABAUD/nAABAeACzgABAVb/nAABAecCzgABAUj/nAABAb0C0QABATT/nAABAcIC1QABARr99wABARwCHAABAPz+BQABATACKgABASn/nAABASkCKQABAPD/nQABAOwCPwABAMf+GwABASgC9gABANX+FwABATEC6QABASL/nAABASIC/QABAPIC+AABAnkDlAABArYDAAABAOwDCQABAPoDoQABAaL/nAABAmgEJQABAZD/nAABAscDhwABAPv/nAABAPYDgwABALn/nAABAPQEJAABAa//mAABAnICvQABAZz/mAABAssCLAABAPT/nAABAPwCJAABAP0CsAABAV3+tgABAdICBwABAVD+sgABAdECAQABAT7+uwABAdIC0AABAT7+uQABAdYCwAABAPX/nAABAPkC8gABAM3/nAABAOQDhAABAcIC1gABAcoC0gABAK8DCwABAKsDDgABAaX/mQABAgECvQABAg8CrgABAiD/nAABASYCFAABAbj/mQABAg4CsgABAiL/nAABARICBAABANn/mQABAKADEgABAVL/mwABAH8CpgABAMr/mgABAKMDAwABAJf/mgABAJQDAgABATD/nAABAJMCxAABAav/mAABAeYDPAABAbr/mAABAd8DRQABAi7/nAABAPQCnwABAc//mAABAeQDPQABAfX/nAABAN8CnAABAM3/mQABAH4DgAABAX//nAABAFQDAgABAHv/mQABAGEDYAABAH//mQABAIQDbwABAS//nAABAF4DHwABAW3+3gABASUBlwABAWP+5AABASUBnwABAKf/nAABAKoDFgABAIb/nAABAJsDIwABAQ4CMQABASEBxQABALUEPQABAJ4ETgABAYr/tgABAVICAAABAb//nAABAXIB8gABARn/nAABARsB+AABARb/nAABARoCBQABAWv+2gABAWMCRwABAVD+5wABAWgCSgABAL7/nAABAMkCngABAJD/nAABAMsCxwABAWz+1AABAWcBvQABAWv+0AABAWcB0gABAQD/mgABAPkCTAABAO3/zgABAPACcwABAQX+8wABAQcB6wABATACdQABAOkD8QABANcEBgABAPH/nAABANwCUQABARD/yQABATUBvAABAQz+ygABAQ8BlwABAIr97wABAJoB/gABAOYD3AABAP8D1AABAVH/nAABAR8CdAABAUT+lQABATACAgABAY//mgABAVgCVwABAUn/nAABAVwCbQABAPD/nAABAOkDKAABAP7/zgABAPMDcgABAQT/nAABAQIDMQABART/vQABAS0ChwABAPX+xQABAPkB/QABAP7+wwABAPgCDgABAPUDcwABAQ8DiAABAP8DTwABAP4DQwABAPMDfwABAPADnAABAWj+vAABAMUBnwABAWX+lwABAXcBLAABAXj+DAABANABlwABAXL96AABAV8BJwABAUT9yQABAUEA+AABALf+twABALIB3gABAKj+uAABALYB8wABANn+owABAMEB8QABAMf+oQABALoBzwABAM8DKwABAPcDHQABAOMCdgABAL//nAABAM8DegABAJP/nAABAKcDzQABAK//nAABALcDhAABALACxAABAXT+ygABAMoBrwABAWj+mAABAYwBJwABAU7+iwABASoBCQABAL3+qAABAMkB3QABAKP+rAABALQCCAABAN7+oQABAL0B6AABALf+pQABAMwB4wABATYCLAABATYA7wABAWcDegABAWgDiwABAFn/nAABAFMBQAAFAAAAAQAIAAEADAAoAAIAMgCYAAIABACDAIQAAAKYApgAAgKkAqUAAwKpArwABQACAAECHAJiAAAAGQABC2wAAQtsAAELeAABC3gAAQt4AAELeAAACmYAAQt4AAAKZgABC3gAAQtyAAAKZgABC3gAAQt4AAAKZgABC3gAAQt4AAELeAABC3gAAQt4AAELeAABC3gAAQt4AAELeAABC3gARwCQALIA1AD2ARgBOgFcAX4BoAHCAeQCBgIoAkoCbAKOArAC0gLuAxADMgNUA3YDmAO6A9wD/gQgBEIEZASGBKIExATgBQIFJAVGBWIFhAWmBcgF6gYMBi4GSgZsBogGpAbABtwG+AcaBzYHWAd6B5wHvgfgCAIIJAhGCGgIigisCM4I8AkSCTQJVgl4CZoAAgAKABAAFgAcAAEBmf+1AAEBwwNIAAEAd/90AAEAagLXAAIACgAQABYAHAABAar/sAABAdcDIgABAHL/fAABAG4C0QACAAoAEAAWABwAAQGZ/7kAAQHVAy4AAQBn/4MAAQCKBBsAAgAKABAAFgAcAAEB0f+yAAEB3QNDAAEAlv+CAAEAkgQ6AAIACgAQABYAHAABAdH/pwABAc0DKAABAMP+NQABAH0CwwACAAoAEAAWABwAAQH//5wAAQHUAzcAAQDi/icAAQB7As8AAgAKABAAFgAcAAEByP/KAAEB+gM/AAEAkv9yAAEApwOdAAIACgAQABYAHAABAcz/sQABAfADQAABAJr/bQABALEDoAACAAoAEAAWABwAAQGt/7gAAQIVA4cAAQCI/2QAAQCnA/IAAgAKABAAFgAcAAEC9P8pAAECiAIFAAEBZv6pAAEAywGdAAIACgAQABYAHAABAwn/SwABApoCBQABAW/+uAABAMoBnQACAAoAEAAWABwAAQMO/rIAAQKRAeAAAQFj/q4AAQDMAXwAAgAKABAAFgAcAAEDFf65AAECpAH0AAEBc/4AAAEAtwGAAAIACgAQABYAHAABAxH+qQABAqMB+gABAWH+sgABAK8DEgACAAoAEAAWABwAAQMR/rUAAQJ9AfIAAQFr/rMAAQC7AX8AAgAKABAAFgAcAAEBvf+zAAECIwNvAAEAjv+IAAEAvwP5AAIACgAQABYAHAABA0n+FAABArEB/gABAVH+yAABALoBiwACAEgACgAQABYAAQKZAfMAAQFw/dAAAQDIAX4AAgAKABAAFgAcAAEDk/3nAAECsgH/AAEBUv63AAEA1wMRAAIACgAQABYAHAABA0v+GAABAqIB7QABAVr+ngABAI4BkAACAAoAEAAWABwAAQLY/yQAAQKdAucAAQFR/q4AAQDVAZEAAgAKABAAFgAcAAEC8v8iAAECkQLVAAEBef3NAAEAuQGIAAIACgAQABYAHAABAvz/CgABApsCzwABATb+pAABAMoDJgACAAoAEAAWABwAAQLi/wwAAQKVAtEAAQFR/pUAAQC3AZoAAgAKABAAFgAcAAEC4f8cAAECkwOCAAEBZP6UAAEAzQGNAAIACgAQABYAHAABAvT/JQABAo0DhQABAXn99AABAL8BjAACAAoAEAAWABwAAQLr/ykAAQKcA4kAAQFe/p4AAQDdAzsAAgAKABAAFgAcAAEC7f8zAAECkgOJAAEBW/6uAAEAyAGDAAIACgAQABYAHAABA9//mgABA/MB7wABAXb+nAABANcBoQACAAoAEAAWABwAAQPj/5QAAQPkAfcAAQF0/qYAAQC+AZEAAgCoAAoAEAAWAAED5wH1AAEBc/3KAAEAtgGRAAIACgAQABYAHAABA+P/mAABA+QB8QABAXT92AABALkBkwACAXQACgAQABYAAQPcAfMAAQFu/qUAAQEGAxcAAgAKABAAFgAcAAED8v+qAAED3wHlAAEBXv6tAAEBAAMyAAIACgAQABYAHAABA/j/nAABA8MB6wABAUv+vAABAMQBqgACAAoAEAAWABwAAQPu/5wAAQPSAfAAAQFS/qsAAQC4AYoAAgCMAAoAEAAWAAEDwwNEAAEBdv6bAAEAlQGMAAIACgAQABYAHAABBAz/nAABA8YDQgABAWr+qgABALQBqQACAAoAEAAWABwAAQPp/5wAAQPQA0IAAQFy/cUAAQC8AZ4AAgAKABAAFgAcAAED9P+cAAEDyANIAAEBef3kAAEAsAGkAAIACgAQABYAHAABA/X/nAABA9IDQgABAVr+qAABAOIDLQACAAoAEAAWABwAAQP6/5wAAQPLA0IAAQFD/qQAAQDrAyMAAgAKABAAFgAcAAED6v+cAAED0QNCAAEBT/6kAAEA1QGQAAIACgAQAi4AFgABA+b/nAABA8gDQgABALUBkQACAAoAEAAWABwAAQQg/5wAAQSAAhgAAQFm/rMAAQCeAZ0AAgFcAAoAEAAWAAEEiQIYAAEBbf6tAAEAwgGRAAIBhAAKABAAFgABBHwCGAABAXb94QABAMYBoAACAJwACgAQABYAAQSAAhAAAQF3/dsAAQDHAY0AAgCiAAoAEAAWAAEEWgIYAAEBUP7BAAEBAQMRAAIBUgAKABAAFgABBIYCGAABAWT+oQABAOIDDwACAAoAEAAWABwAAQQ7/5wAAQRyAhgAAQFT/qQAAQDFAZAAAgAmAAoAEAAWAAEEawIYAAEBaf6kAAEAvAGSAAIACgAQABYAHAABBDj/nAABBI4C4gABAVP+rAABAMgBjgACAAoAEAAWABwAAQQ8/5wAAQSJAuQAAQFZ/qMAAQDMAYwAAgAKABAAFgAcAAEEM/+cAAEEjwLdAAEBZ/6fAAEAxgGJAAIACgAQABYAHAABBE7/nAABBI4C5AABAYT9wQABAM4BnQACAAoAEAAWABwAAQQ+/5wAAQSQAtcAAQF0/e4AAQDJAY0AAgAKABAAFgAcAAEEPf+cAAEEkwLRAAEBY/63AAEA+QMdAAIACgAQABYAHAABBDT/nAABBJQC1gABAVz+uwABAPQDAAACAAoAEAAWABwAAQQ5/5wAAQSVAtoAAQFh/r8AAQDVAZ0AAgAKABAAFgAcAAEC8f9yAAECmQLHAAEBUv6pAAEAugGQAAIACgAQABYAHAABAuD/RAABAo8CuwABAYP96QABANMBggACAAoAEAAWABwAAQL8/08AAQKOAtUAAQFg/qsAAQC7A04AAgAKABAAFgAcAAEC8f9cAAECoQLOAAEBUf68AAEAxQGUAAIACgAQABYAHAABA07+uwABArACBgABAXT+CwABAMkBjgACAAoAEAAWABwAAQNK/rsAAQKwAf4AAQFO/qIAAQDSAYYAAgAKABAAFgAcAAEC9f9gAAECjgOfAAEBVP6eAAEAxAGJAAIACgAQABYAHAABAuX/WwABApUDkgABAXX9/QABAMkBkgACAAoAEAAWABwAAQMc/2AAAQKVA7UAAQFR/oIAAQDKAxEAAgAKABAAFgAcAAEC3v9gAAEChwOqAAEBVP6oAAEAvAGNAAIACgAQABYAHAABA0j+ugABApYB+wABAUb+xQABAMEBiAAGABAAAQAKAAAAAQAMABgAAQAoAEAAAQAEAqoCrAKvArIAAQAGAqoCrAKvArICvgLAAAQAAAASAAAAEgAAABIAAAASAAEAAAAAAAYADgAUABoAIAAmACwAAQAA/xkAAQAA/qkAAQAA/qMAAQAA/z8AAQAA/t8AAQAA/s4ABgAQAAEACgABAAEADAA6AAEAbgDWAAEAFQCDAIQCmAKkAqUCqQKrAq0CrgKwArECswK0ArUCtgK3ArgCuQK6ArsCvAABABgAgwCEApgCpAKlAqkCqwKtAq4CsAKxArMCtAK1ArYCtwK4ArkCugK7ArwCvQK/AsEAFQAAAFYAAABWAAAAYgAAAGIAAABiAAAAYgAAAGIAAABiAAAAXAAAAGIAAABiAAAAYgAAAGIAAABiAAAAYgAAAGIAAABiAAAAYgAAAGIAAABiAAAAYgABAAACvAABAAADCgABAAADCQAYADIAMgA4AD4ARABKAFAAVgBcAGIAaABuAHQAdAB6AIAAhgCMAJIAmACeAKQAqgCwAAEAAAPIAAEABQRPAAEAFAQaAAH/+wRmAAEAAAPxAAEAAAR/AAEAAQSUAAEAAASLAAEAAAP6AAEAAAR+AAEAAAQBAAEAAAWLAAEAAAWYAAEAAAT0AAEAAAV3AAEAAAUFAAEAAATjAAEAAAQYAAEAAAPKAAEAAASbAAEAAAQwAAEAAAQ8AAEAAAAKAVwCIAADREZMVAAUYXJhYgAYbGF0bgBWAHAAAAAKAAFVUkQgACQAAP//AAoAAAABAAMABAAFAAYADwAQABEAEgAA//8ACgAAAAEAAgAEAAUABgAOAA8AEQASAC4AB0FaRSAARkNSVCAAYEtBWiAAek1PTCAAlFJPTSAArlRBVCAAyFRSSyAA4gAA//8ACQAAAAEAAgAEAAUABgAPABEAEgAA//8ACgAAAAEAAgAEAAUABgAHAA8AEQASAAD//wAKAAAAAQACAAQABQAGAAgADwARABIAAP//AAoAAAABAAIABAAFAAYACQAPABEAEgAA//8ACgAAAAEAAgAEAAUABgANAA8AEQASAAD//wAKAAAAAQACAAQABQAGAAwADwARABIAAP//AAoAAAABAAIABAAFAAYACgAPABEAEgAA//8ACgAAAAEAAgAEAAUABgALAA8AEQASABNhYWx0AHRjYWx0AHpjY21wAIBjY21wAIBkbGlnAIhmaW5hAI5pbml0AJRsb2NsAJpsb2NsAJpsb2NsAJpsb2NsAJpsb2NsAJpsb2NsAKBsb2NsAKBsb2NsAKZtZWRpAKxybGlnALJzYWx0ALhzczAxAL4AAAABAAAAAAABAA0AAAACAAEAAgAAAAEACgAAAAEACAAAAAEABgAAAAEAAwAAAAEABAAAAAEABQAAAAEABwAAAAEACQAAAAEACwAAAAEADAATACgERgSIBTYFRAVeBXwF0gZ0B7oILAp4Cs4LGAzuDQINMA1ODWwAAwAAAAEACAABAzgAbQDgAOQA6ADsAPAA9AD4APwBAAEEAQgBEAEYARwBJAEqATIBOAFAAUYBTgFWAV4BZgFuAXIBdgF6AYABhAGKAY4BkgGWAZwBoAGoAbABuAHAAcgB0AHYAeAB6AHwAfgB/AIEAiACJAIoAhACHAIgAiQCKAIuAjICPgJCAkYCTAJUAlwCZAJsAnACeAJ8AoQCiAKQApQCmAKcAqACpAKsArACtgK+AsICxgLOAtYC2gLgAuQC6ALsAvAC9AL4AvwDAAMEAwgDDAMQAxQDGAMcAyADJAMoAywDMAM0AAEA/wABAMQAAQDJAAEBHQABASIAAQE3AAEBOQABATsAAQE9AAEBPwADAUMBQgFBAAMBSgFJAUgAAQFLAAMBTwFOAU0AAgFRAVAAAwFVAVQBUwACAVYBVwADAVsBWgFZAAIBXAFdAAMBYQFgAV8AAwFlAWQBYwADAWkBaAFnAAMBbQFsAWsAAwFxAXABbwABAXMAAQF1AAEBdwACAXoBeQABAXsAAgF9AX8AAQF+AAEBgQABAYMAAgGGAYUAAQGHAAMBiwGKAYkAAwGPAY4BjQADAZMBkgGRAAMBlwGWAZUAAwGbAZoBmQADAZ8BngGdAAMBowGiAaEAAwGnAaYBpQADAasBqgGpAAMBrwGuAa0AAwGzAbIBsQABAbUAAwG5AbgBtwAFAb0BvAG7AcABvwAFAcUBwwHBAcABvwABAcAAAQHCAAEBxAACAccBxgABAccABQHPAc0BywHKAckAAQHMAAEBzgACAdEB0AADAdUB1AHTAAMB2QHYAdcAAwHdAdwB2wADAeEB4AHfAAEB4wADAecB5gHlAAEB6QADAe0B7AHrAAEB7wADAfMB8gHxAAEB9QABAfcAAQH5AAEB+wABAgEAAwIGAgUCAwABAgQAAgIIAgcAAwINAgwCCgABAgsAAQIOAAMC0wLUAtIAAwIUAhMCEQABAhIAAgIWAhUAAQIYAAECGgABAh0AAQIfAAECIQABAiMAAQIrAAECOQABAjsAAQI9AAECQQABAkMAAQJFAAECSQABAksAAQJNAAECUgABAlQAAQJWAAECegABAmwAAQJ7AAEAbQAmAMMAyAEcASEBNgE4AToBPAE+AUABRwFKAUwBTwFSAVUBWAFbAV4BYgFmAWoBbgFyAXQBdgF4AXoBfAF9AYABggGEAYYBiAGMAZABlAGYAZwBoAGkAagBrAGwAbQBtgG6AbsBvAG9Ab4BvwHBAcMBxQHGAcgBywHNAc8B0gHWAdoB3gHiAeQB6AHqAe4B8AH0AfYB+AH6AgACAgIDAgYCCQIKAg0CDwIQAhECFAIXAhkCHAIeAiACIgIkAjgCOgI8AkACQgJEAkgCSgJMAlECUwJVAnQCdgJ3AAYAAAACAAoAHAADAAAAAQisAAEALgABAAAADgADAAAAAQiaAAIAFAAcAAEAAAAOAAEAAgLPAtAAAgABAsICzQAAAAQAAAABAAgAAQCWAAgAFgAgACoANAA+AEgAUgBcAAEABAK6AAICswABAAQCtAACArMAAQAEArUAAgKzAAEABAK2AAICswABAAQCtwACArMAAQAEArgAAgKzAAEABAK5AAICswAHABAAFgAcACIAKAAuADQCugACAqkCtAACAq0CtQACAq4CtgACAq8CtwACArACuAACArECuQACArIAAgACAqkCqQAAAq0CswABAAEAAAABAAgAAQe+ANkAAQAAAAEACAABAAYAAQABAAQAwwDIARwBIQABAAAAAQAIAAIADAADAnoCbAJ7AAEAAwJ0AnYCdwABAAAAAQAIAAIApAAkAUMBSgFPAVUBWwFhAWUBaQFtAXEBiwGPAZMBlwGbAZ8BowGnAasBrwGzAbkBvQHFAc8B1QHZAd0B4QHnAe0B8wIGAg0C0wIUAAEAAAABAAgAAgBOACQBQgFJAU4BVAFaAWABZAFoAWwBcAGKAY4BkgGWAZoBngGiAaYBqgGuAbIBuAG8AcMBzQHUAdgB3AHgAeYB7AHyAgUCDALUAhMAAQAkAUABRwFMAVIBWAFeAWIBZgFqAW4BiAGMAZABlAGYAZwBoAGkAagBrAGwAbYBugG+AcgB0gHWAdoB3gHkAeoB8AICAgkCDwIQAAEAAAABAAgAAgCgAE0BNwE5ATsBPQE/AUEBSAFNAVMBWQFfAWMBZwFrAW8BcwF1AXcBegF9AYEBgwGGAYkBjQGRAZUBmQGdAaEBpQGpAa0BsQG1AbcBuwHBAcsB0wHXAdsB3wHjAeUB6QHrAe8B8QH1AfcB+QH7AgECAwIKAtICEQIYAhoCHQIfAiECIwIrAjkCOwI9AkECQwJFAkkCSwJNAlICVAJWAAEATQE2ATgBOgE8AT4BQAFHAUwBUgFYAV4BYgFmAWoBbgFyAXQBdgF4AXwBgAGCAYQBiAGMAZABlAGYAZwBoAGkAagBrAGwAbQBtgG6Ab4ByAHSAdYB2gHeAeIB5AHoAeoB7gHwAfQB9gH4AfoCAAICAgkCDwIQAhcCGQIcAh4CIAIiAiQCOAI6AjwCQAJCAkQCSAJKAkwCUQJTAlUABAAIAAEACAABAGAAAwCaAAwANgAFAAwAEgAYAB4AJAIdAAIBNwIfAAIBOQIhAAIBOwIjAAIBPQIrAAIBPwAFAAwAEgAYAB4AJAIcAAIBNwIeAAIBOQIgAAIBOwIiAAIBPQIkAAIBPwABAAMBNgHUAdUABAAJAAEACAABAh4AEQAoADYAWAB6AJwAvgDgAQIBJAFGAWgBigGkAcYB6AHyAhQAAQAEAmMABAHVAdQB5QAEAAoAEAAWABwCJwACAgECKAACAgMCKQACAgoCKgACAhEABAAKABAAFgAcAiwAAgIBAi0AAgIDAi4AAgIKAi8AAgIRAAQACgAQABYAHAIwAAICAQIxAAICAwIyAAICCgIzAAICEQAEAAoAEAAWABwCNAACAgECNQACAgMCNgACAgoCNwACAhEABAAKABAAFgAcAjkAAgIBAjsAAgIDAj0AAgIKAj8AAgIRAAQACgAQABYAHAI4AAICAQI6AAICAwI8AAICCgI+AAICEQAEAAoAEAAWABwCQQACAgECQwACAgMCRQACAgoCRwACAhEABAAKABAAFgAcAkAAAgIBAkIAAgIDAkQAAgIKAkYAAgIRAAQACgAQABYAHAJJAAICAQJLAAICAwJNAAICCgJPAAICEQAEAAoAEAAWABwCSAACAgECSgACAgMCTAACAgoCTgACAhEAAwAIAA4AFAJSAAICAQJUAAICAwJWAAICCgAEAAoAEAAWABwCUQACAgECUwACAgMCVQACAgoCVwACAhEABAAKABAAFgAcAlgAAgIBAlkAAgIDAloAAgIKAlsAAgIRAAEABAJdAAICEQAEAAoAEAAWABwCXgACAgECXwACAgMCYAACAgoCYQACAhEAAQAEAmIAAgIRAAEAEQE2AUkBTgFUAVoBigGLAY4BjwGSAZMBlgGXAeACBQIMAhMAAQAJAAEACAACACgAEQHAAcIBxAHHAcABwAHCAcQBxwHHAcoBzAHOAdECBAILAhIAAQARAboBuwG8Ab0BvgG/AcEBwwHFAcYByAHLAc0BzwIDAgoCEQABAAkAAQAIAAIAIgAOAcABwgHEAccBwAHAAcIBxAHHAccBygHMAc4B0QABAA4BugG7AbwBvQG+Ab8BwQHDAcUBxgHIAcsBzQHPAAYACQAKABoAPABWAHIAmAC+AQABIgFgAZoAAwABABIAAQHsAAAAAQAAAA8AAgACAXgBfwAAAYQBhwAIAAMAAAABAfAAAQASAAEAAAAQAAEAAgGGAYcAAwAAAAEB1gABABIAAQAAABEAAQADAVQBWgIMAAMAAAABABIAAQAcAAEAAAARAAEAAwFPAgYCFAABAAMBTgIFAhMAAwABABIAAQGUAAAAAQAAABIAAQAIATwBPQE+AT8CIgIjAiQCKwADAAAAAQB2AAEAEgABAAAAEgABABYBNgE4AToBPAE+AUoBSwFPAVEBVQFWAVsBXAHhAfgB+QIGAggCDQIOAhQCFgADAAAAAQA0AAEAEgABAAAAEgABAAYBeAF5AXwBfwGEAYUAAwAAAAEAEgABACIAAQAAABIAAQAGAXgBegF8AX0BhAGGAAEADAFiAWYBagFuAaABpAG2Ad4CAAICAgkCEAADAAEAEgABAC4AAAABAAAAEgACAAQBNgE/AAABhAGHAAoCHAIkAA4CKwIrABcAAQAEAb4BxQHIAc8AAwABABIAAQA0AAAAAQAAABIAAgAFATYBPwAAAXwBfwAKAYQBhwAOAhwCJAASAisCKwAbAAEAAgG6Ab0AAQAAAAEACAABAAYA1QABAAEAJgABAAkAAQAIAAIAFAAHAUsBUQFWAVwCCAIOAhYAAQAHAUoBTwFVAVsCBgINAhQAAQAJAAEACAACAAwAAwFXAV0CDgABAAMBVQFbAg0AAQAJAAEACAABAAYAAQABAAYBTwFVAVsCBgINAhQAAQAJAAEACAACACQADwFXAV0BeQF7AX8BfgGFAYcBvwHGAb8BxgHJAdACDgABAA8BVQFbAXgBegF8AX0BhAGGAboBvQG+AcUByAHPAg0AAAAAAAEAAAAA) format("truetype");
    font-weight: 700; font-style: normal; font-display: swap;
}
/* ⚠ همهٔ قواعد زیر با «#tyvscRoot » دامنه‌بندی شده‌اند — این تغییر رفعِ باگ زندهٔ گزارش‌شده است.
   نسخهٔ قبلی سلکتورهای عمومی و بی‌دامنه داشت (`.modal`، `.toolbar`، `.section`، `.btn-primary`،
   `.chip`، `.notice`، `header.hero`، و حتی `html,body` و `*`) که مستقیم روی صفحهٔ پرتال Teamyar
   می‌نشست. پرتال خودش برای همین نام‌ها CSS دارد، پس برخورد دوطرفه رخ می‌داد:
     • `.modal` پرتال بر قاعدهٔ من غالب می‌شد ⇒ پاپ‌آپ راهنما بسته نمی‌شد
     • `.pseudo-fullscreen` اثر نمی‌کرد ⇒ «تمام صفحه» کار نمی‌کرد
     • مدرک قطعی در اسکرین‌شات کاربر: لوگوی ۱۴۰ به‌جای `height:34px` در اندازهٔ طبیعی (۲۴۱×۱۰۰)
       رندر شده و روی نوار هشدار افتاده بود — یعنی قاعدهٔ پرتال بر قاعدهٔ من غالب شده بود.
   با پیشوند id، ویژگی (specificity) سلکتورها (1,1,0) می‌شود در برابر (0,1,0) پرتال، پس بدون توجه به
   ترتیب بارگذاری استایل‌شیت‌ها برنده‌اند. نام کلاس‌ها عمداً دست‌نخورده ماند تا دامنهٔ تغییر کوچک بماند.
   قانون فونت CLAUDE.md هم به ریشهٔ گزارش محدود شد: هدفِ قانون (تک‌فونت بودن همهٔ عناصر گزارش) حفظ
   است، ولی دیگر فونت و box-sizing کل صفحهٔ پرتال را بازنویسی نمی‌کند. */
#tyvscRoot, #tyvscRoot *, #tyvscRoot *::before, #tyvscRoot *::after {
  font-family: "PeydaReport", "Peyda", "IRANSans", "Tahoma", "Arial", sans-serif !important;
  box-sizing: border-box;
}
#tyvscRoot{
  --accent:#16509D; --accent-dark:#0e3a73; --accent-light:#5b85bc; --accent-lighter:#a9c2de;
  --border:#e3e6ea; --muted:#666; --zebra:#f5f5f5; --bg:#f4f6f9;
  display:block; max-width:1400px; margin:0 auto; padding:18px;
  background:var(--bg); color:#000; font-size:14px; direction:rtl; text-align:right;
}
/* تمام‌صفحه = CSS-only (نه Fullscreen API واقعی) — طبق تأیید زندهٔ 1405/05/26 روی بات‌های خواهر:
   روی موبایل/iframe پنل Teamyar، Element.requestFullscreen() باز می‌شد ولی اسکرول نمی‌شد.
   !important لازم است چون این گره داخل صفحهٔ پرتال زندگی می‌کند. JS هم موازیِ همین کلاس، Style
   درون‌خطی می‌گذارد تا اگر حتی این قاعده هم شکست بخورد، دکمه باز هم کار کند. */
#tyvscRoot.pseudo-fullscreen{
  position:fixed !important; top:0 !important; right:0 !important; bottom:0 !important; left:0 !important;
  z-index:2147483000 !important; overflow-y:auto !important; max-width:100% !important; margin:0 !important;
}
#tyvscRoot .toolbar{ display:flex; justify-content:flex-end; gap:8px; margin-bottom:12px; flex-wrap:wrap; }
#tyvscRoot .btn-toolbar{ background:var(--accent); color:#fff; border:none; border-radius:8px; padding:9px 18px; font-size:14px; font-weight:bold; cursor:pointer; }
#tyvscRoot .btn-toolbar:hover{ filter:brightness(0.9); }
#tyvscRoot .btn-toolbar.secondary{ background:#fff; color:var(--accent); border:1.5px solid var(--accent); }
#tyvscRoot .hero{ position:relative; background:linear-gradient(135deg,var(--accent),var(--accent-dark)); color:#fff; border-radius:14px; padding:22px 26px; margin-bottom:16px; }
#tyvscRoot .hero h1{ margin:0 0 6px; font-size:19px; color:#fff; max-width:calc(100% - 90px); }
#tyvscRoot .hero .sub{ margin:0; font-size:14px; color:#fff; opacity:.92; max-width:calc(100% - 90px); }
#tyvscRoot .hero .brand140-logo{ position:absolute !important; top:18px !important; left:22px !important; height:34px !important; width:auto !important; max-width:none !important; }
@media(max-width:600px){
  #tyvscRoot .hero .brand140-logo{ position:static !important; display:block; margin-bottom:10px; }
  #tyvscRoot .hero h1, #tyvscRoot .hero .sub{ max-width:100%; }
}
#tyvscRoot .danger-band{ background:var(--accent); color:#fff; border-radius:12px; padding:16px 20px; margin-bottom:16px; }
#tyvscRoot .danger-band h2{ margin:0 0 8px; font-size:15px; font-weight:bold; color:#fff; }
#tyvscRoot .danger-band ul{ margin:0; padding-inline-start:20px; list-style:disc; }
#tyvscRoot .danger-band li{ font-size:14px; line-height:2; color:#fff; }
#tyvscRoot .notice{ background:#fff; border:1.5px solid var(--accent); border-radius:12px; padding:14px 18px; margin-bottom:16px; font-size:14px; line-height:2; }
#tyvscRoot .notice strong{ font-weight:bold; }
#tyvscRoot .warn-list{ background:var(--zebra); border:1px solid var(--border); border-radius:10px; padding:10px 20px; margin-bottom:14px; list-style:disc; }
#tyvscRoot .warn-list li{ font-size:14px; line-height:2; }
#tyvscRoot .filter-bar{ background:#fff; border:1px solid var(--border); border-radius:12px; padding:14px 18px; margin-bottom:16px; display:flex; gap:12px; flex-wrap:wrap; align-items:flex-end; }
#tyvscRoot .filter-field{ display:flex; flex-direction:column; gap:4px; min-width:150px; }
#tyvscRoot .filter-field label{ font-size:14px; color:var(--muted); display:block; }
#tyvscRoot .filter-field input, #tyvscRoot .filter-field select{ font-size:14px; padding:8px 10px; border:1px solid var(--border); border-radius:8px; background:#fff; color:#000; width:auto; height:auto; }
#tyvscRoot .filter-actions{ display:flex; gap:8px; }
#tyvscRoot .btn-primary{ background:var(--accent); color:#fff; border:none; border-radius:8px; padding:9px 20px; font-size:14px; font-weight:bold; cursor:pointer; }
#tyvscRoot .btn-secondary{ background:#fff; color:var(--accent); border:1.5px solid var(--accent); border-radius:8px; padding:9px 20px; font-size:14px; font-weight:bold; cursor:pointer; }
#tyvscRoot .btn-primary:disabled, #tyvscRoot .btn-secondary:disabled{ opacity:.45; cursor:not-allowed; }
#tyvscRoot .kpi-grid{ display:grid; grid-template-columns:repeat(auto-fit,minmax(190px,1fr)); gap:12px; margin-bottom:18px; }
#tyvscRoot .kpi-card{ background:#fff; border:1px solid var(--border); border-radius:12px; padding:14px 16px; }
#tyvscRoot .kpi-card .label{ font-size:14px; color:var(--muted); margin-bottom:6px; }
#tyvscRoot .kpi-card .value{ font-size:22px; font-weight:bold; color:var(--accent); }
#tyvscRoot .kpi-card .sub{ font-size:14px; color:var(--muted); margin-top:4px; }
#tyvscRoot .section{ background:#fff; border:1px solid var(--border); border-radius:14px; padding:18px; margin-bottom:16px; }
#tyvscRoot .section-head{ margin-bottom:12px; }
#tyvscRoot .section-head h2{ font-size:15px; font-weight:bold; margin:0 0 4px; display:flex; align-items:center; gap:8px; }
#tyvscRoot .section-head h2 .num{ background:var(--accent); color:#fff; border-radius:50%; width:24px; height:24px; display:inline-flex; align-items:center; justify-content:center; font-size:14px; flex:none; }
#tyvscRoot .section-head p{ margin:0; font-size:14px; color:var(--muted); }
#tyvscRoot table.data-table{ width:auto; min-width:100%; border-collapse:collapse; background:#fff; }
#tyvscRoot table.data-table th, #tyvscRoot table.data-table td{ padding:8px 10px; border-bottom:1px solid var(--border); text-align:right; font-size:14px; white-space:nowrap; width:1%; }
#tyvscRoot table.data-table thead th{ background:var(--zebra); font-weight:bold; font-size:15px; cursor:pointer; user-select:none; position:sticky; top:0; z-index:1; }
#tyvscRoot table.data-table thead th:hover{ background:var(--accent-lighter); }
#tyvscRoot table.data-table thead th.sort-asc::after{ content:" \25B2"; }
#tyvscRoot table.data-table thead th.sort-desc::after{ content:" \25BC"; }
#tyvscRoot table.data-table tbody tr:nth-child(even){ background:var(--zebra); }
#tyvscRoot .table-scroll{ overflow-x:auto; max-height:60vh; }
#tyvscRoot .chip{ display:inline-block; padding:2px 10px; border-radius:11px; font-size:14px; font-weight:bold; white-space:nowrap; }
#tyvscRoot .chip.on{ background:var(--accent); color:#fff; }
#tyvscRoot .chip.off{ background:var(--zebra); color:var(--muted); border:1px solid var(--border); }
#tyvscRoot .chip.line{ background:#fff; color:var(--accent); border:1.5px solid var(--accent); }
#tyvscRoot a.link{ color:var(--accent); text-decoration:none; font-weight:bold; }
#tyvscRoot a.link:hover{ text-decoration:underline; }
#tyvscRoot .empty-row{ text-align:center; color:var(--muted); padding:16px; font-size:14px; }
#tyvscRoot .confirm-box{ display:flex; gap:12px; flex-wrap:wrap; align-items:flex-end; }
#tyvscRoot .confirm-box .filter-field{ min-width:220px; }
#tyvscRoot .run-log{ margin-top:14px; }
#tyvscRoot .report-footer{ text-align:center; font-size:14px; color:var(--muted); padding:16px 0; }
/* پاپ‌آپ راهنما: نمایش/پنهان‌سازی نهایتاً با Style درون‌خطیِ JS کنترل می‌شود، نه با کلاس — تا هیچ
   CSS بیرونی نتواند آن را باز نگه دارد (همان چیزی که کاربر گزارش کرد). این قواعد فقط ظاهر می‌سازند. */
#tyvscRoot .modal{ position:fixed; top:0; right:0; bottom:0; left:0; background:rgba(0,0,0,.45); z-index:2147483001; align-items:center; justify-content:center; padding:16px; }
#tyvscRoot .modal-content{ background:#fff; border-radius:14px; max-width:760px; width:92%; max-height:82vh; overflow-y:auto; }
#tyvscRoot .modal-header{ display:flex; align-items:center; justify-content:space-between; padding:16px 20px; border-bottom:1px solid var(--border); position:sticky; top:0; background:#fff; }
#tyvscRoot .modal-header h3{ margin:0; font-size:15px; font-weight:bold; }
#tyvscRoot .modal-close{ background:none; border:none; font-size:24px; line-height:1; cursor:pointer; color:var(--muted); padding:0 8px; }
#tyvscRoot .modal-body{ padding:18px 20px; font-size:14px; line-height:2.1; }
#tyvscRoot .modal-body h4{ font-size:15px; font-weight:bold; margin:14px 0 6px; }
#tyvscRoot .modal-body p{ margin:0 0 8px; }
#tyvscRoot .modal-body ul{ padding-inline-start:20px; margin:0; list-style:disc; }
</style>
]]

-- ============================================================
-- RENDER — قطعات صفحه
-- ============================================================

local function fetch_organizations()
    local rows = fetch_rows(
        "SELECT po.ORG_ID, COALESCE(NULLIF(MAX(oi.NAME), ''), CONCAT('سازمان ', po.ORG_ID))" ..
        " FROM pa_organizations po LEFT JOIN org_info oi ON oi.ID = po.ORG_ID" ..
        " GROUP BY po.ORG_ID ORDER BY po.ORG_ID LIMIT 200", {}, { "id", "name" })
    return rows or {}
end

local function render_options(pairs_list, current)
    local out = {}
    for _, pair in ipairs(pairs_list) do
        local selected = (tostring(pair[1]) == tostring(current)) and " selected" or ""
        table.insert(out, '<option value="' .. escape_html(pair[1]) .. '"' .. selected .. '>' ..
                          escape_html(pair[2]) .. '</option>')
    end
    return table.concat(out)
end

local function render_filter_bar(filters, organizations)
    local org_pairs = { { "0", "همه سازمان‌ها" } }
    for _, org in ipairs(organizations) do
        table.insert(org_pairs, { tostring(org.id), tostring(org.name) })
    end

    local type_pairs = { { "0", "همه انواع" } }
    for index = 1, 7 do
        table.insert(type_pairs, { tostring(index), INV_TYPE_TEXT[index] })
    end

    local scope_pairs = {
        { "signed", SCOPE_STATES.signed },
        { "full", SCOPE_STATES.full },
        { "any", SCOPE_STATES.any },
    }
    local payload_pairs = {
        { "minimal", "حداقلی (پیشنهادی)" },
        { "full", "کامل (فقط اگر حداقلی خطا داد)" },
    }

    -- بدون method/action: ارسال بومی فرم عمداً غیرفعال است. طبق تجربهٔ ثبت‌شدهٔ همین پروژه
    -- (ر.ک. یادداشت «فیلتر: fetch …» در sales_revenue_center_dashboard_report_bot.lua)، ناوبری
    -- بومی داخل شِل/iframe واقعی Teamyar بات را از دست می‌دهد و صفحهٔ سفید می‌دهد. JS پایین صفحه
    -- submit را می‌گیرد و به‌جایش قطعهٔ نتیجه را با fetch می‌آورد.
    return table.concat({
        '<form class="filter-bar" id="filterForm" onsubmit="return false;">',
        '<div class="filter-field"><label>سازمان</label><select name="org">',
            render_options(org_pairs, tostring(filters.org)), '</select></div>',
        '<div class="filter-field"><label>نوع فاکتور</label><select name="itype">',
            render_options(type_pairs, tostring(filters.invoice_type)), '</select></div>',
        '<div class="filter-field"><label>از تاریخ (۱۴۰۵/۰۱/۳۱)</label>',
            '<input type="text" name="date_from" value="', escape_html(filters.date_from_text), '"></div>',
        '<div class="filter-field"><label>تا تاریخ</label>',
            '<input type="text" name="date_to" value="', escape_html(filters.date_to_text), '"></div>',
        '<div class="filter-field"><label>شناسهٔ یک فاکتور (اختیاری)</label>',
            '<input type="text" name="invoice_id" value="',
            escape_html(filters.invoice_id > 0 and tostring(filters.invoice_id) or ""), '"></div>',
        '<div class="filter-field"><label>دامنهٔ اسناد</label><select name="scope">',
            render_options(scope_pairs, filters.scope), '</select></div>',
        '<div class="filter-field"><label>سقف سند در هر اجرا</label>',
            '<input type="text" name="cap" value="', escape_html(tostring(filters.execute_cap)), '"></div>',
        '<div class="filter-field"><label>حالت Payload</label><select name="payload_mode">',
            render_options(payload_pairs, filters.payload_mode), '</select></div>',
        '<div class="filter-actions">',
        '<button type="button" class="btn-primary" id="previewButton" data-act="preview">',
        'پیش‌نمایش</button></div>',
        '</form>',
    })
end

local function render_warnings(warnings)
    if #warnings == 0 then return "" end
    local items = {}
    for _, message in ipairs(warnings) do
        table.insert(items, '<li>' .. escape_html(message) .. '</li>')
    end
    return '<ul class="warn-list">' .. table.concat(items) .. '</ul>'
end

local function render_kpis(scope)
    local sign_total, signed_total = 0, 0
    for _, entry in ipairs(scope.vouchers) do
        sign_total = sign_total + #entry.signers
        signed_total = signed_total + entry.signed_count
    end

    local function card(label, value, sub)
        return '<div class="kpi-card"><div class="label">' .. escape_html(label) ..
               '</div><div class="value">' .. escape_html(value) ..
               '</div><div class="sub">' .. escape_html(sub or "") .. '</div></div>'
    end

    return '<div class="kpi-grid">' ..
        card("فاکتور در فیلتر", fmt_num(scope.invoice_count),
             scope.invoice_truncated and ("سقف پیش‌نمایش " .. fmt_num(CONFIG.PREVIEW_INVOICE_LIMIT)) or "کل نتیجه") ..
        card("سند حسابداری متصل", fmt_num(scope.voucher_total), "قبل از فیلتر دامنه") ..
        card("سند در دامنهٔ انتخابی", fmt_num(#scope.vouchers), "کاندیدای ویرایش") ..
        card("امضای «امضا شده»", fmt_num(signed_total), "روی همین اسناد") ..
        card("کل ردیف امضا", fmt_num(sign_total), "شامل منتظر و رد") ..
        '</div>'
end

local function render_signers_text(entry)
    local names = {}
    for _, signer in ipairs(entry.signers) do
        if signer.state == 1 then table.insert(names, signer.name) end
    end
    if #names == 0 then return "—" end
    return table.concat(names, "، ")
end

local function render_invoice_links(entry)
    local links = {}
    for index, invoice in ipairs(entry.invoices) do
        if index > 4 then
            table.insert(links, "… (" .. fmt_num(#entry.invoices) .. ")")
            break
        end
        local invoice_no = tostring(invoice.invoice_no or "")
        table.insert(links,
            '<a class="link" target="_blank" href="' .. CONFIG.INVOICE_VIEW_URL_PREFIX ..
            escape_html(tostring(invoice.invoice_row)) .. '">' .. escape_html(invoice_no) .. '</a>')
    end
    return table.concat(links, "، ")
end

local function render_scope_table(scope, filters)
    if #scope.vouchers == 0 then
        return '<div class="table-scroll"><table class="data-table" id="scopeTable">' ..
               '<thead><tr><th>سند</th></tr></thead><tbody><tr><td class="empty-row">' ..
               'هیچ سندی با این فیلتر و دامنه پیدا نشد.</td></tr></tbody></table></div>'
    end

    local rows = {}
    for index, entry in ipairs(scope.vouchers) do
        local within_cap = (index <= filters.execute_cap)
        table.insert(rows, table.concat({
            '<tr>',
            '<td>', tostring(index), '</td>',
            '<td>', within_cap and '<span class="chip on">در این اجرا</span>'
                                or '<span class="chip off">خارج از سقف</span>', '</td>',
            '<td>', escape_html(tostring(entry.voucher_no or entry.voucher_id)), '</td>',
            '<td>', escape_html(tostring(entry.voucher_id)), '</td>',
            '<td>', escape_html(tostring(entry.org_id)), '</td>',
            '<td>', render_invoice_links(entry), '</td>',
            '<td>', escape_html(fmt_jalali_datetime(entry.voucher_date)), '</td>',
            '<td>', fmt_num(entry.signed_count), '</td>',
            '<td>', fmt_num(entry.pending_count), '</td>',
            '<td>', fmt_num(entry.rejected_count), '</td>',
            '<td>', (entry.locked ~= 0) and '<span class="chip line">قفل</span>'
                                         or '<span class="chip off">باز</span>', '</td>',
            '<td>', escape_html(tostring(entry.status)), '</td>',
            '<td>', escape_html(tostring(entry.changed)), '</td>',
            '<td>', escape_html(render_signers_text(entry)), '</td>',
            '</tr>',
        }))
    end

    return table.concat({
        '<div class="table-scroll"><table class="data-table" id="scopeTable"><thead><tr>',
        '<th>#</th><th>وضعیت اجرا</th><th>شمارهٔ سند</th><th>شناسهٔ سند</th><th>سازمان</th>',
        '<th>فاکتور</th><th>تاریخ سند</th><th>امضا شده</th><th>منتظر</th><th>رد شده</th>',
        '<th>قفل</th><th>وضعیت</th><th>Changed</th><th>امضاکنندگان</th>',
        '</tr></thead><tbody>', table.concat(rows), '</tbody></table></div>',
    })
end

local function render_execute_panel(scope, filters)
    local blocked_reason = nil
    if not filters.has_scope then
        blocked_reason = "برای اجرا باید دامنه محدود باشد: یا بازهٔ تاریخ بدهید یا شناسهٔ یک فاکتور. " ..
                         "اجرای بدون هیچ محدودیتی روی کل تاریخچهٔ فروش پذیرفته نمی‌شود."
    elseif #scope.vouchers == 0 then
        blocked_reason = "هیچ سندی در دامنه نیست."
    end

    if blocked_reason then
        return '<div class="section"><div class="section-head"><h2><span class="num">۳</span>' ..
               'اجرای پاک‌سازی</h2></div><div class="notice">' .. escape_html(blocked_reason) ..
               '</div></div>'
    end

    local target_count = math.min(#scope.vouchers, filters.execute_cap)

    return table.concat({
        '<div class="section"><div class="section-head">',
        '<h2><span class="num">۳</span>اجرای پاک‌سازی</h2>',
        '<p>با زدن دکمه، بات روی <b>', fmt_num(target_count), '</b> سندِ اول جدول بالا، از طریق ماژول ',
        'حسابداری، شرح ردیف سند را ویرایش می‌کند و بلافاصله بررسی می‌کند چند امضا واقعاً باطل شد.</p>',
        '</div>',
        '<div class="confirm-box">',
        '<div class="filter-field"><label>برای تأیید، عبارت «', escape_html(CONFIG.CONFIRM_PHRASE),
        '» را عیناً تایپ کنید</label>',
        '<input type="text" id="confirmInput" autocomplete="off"></div>',
        '<div class="filter-actions">',
        '<button type="button" class="btn-primary" id="runButton" data-act="run">شروع پاک‌سازی</button>',
        '</div></div>',
        '<div class="run-log" id="runLog"></div>',
        '</div>',
    })
end

local function render_help_modal()
    return table.concat({
        -- display درون‌خطی است، نه کلاس: CSS پرتال نتواند پاپ‌آپ را باز نگه دارد (باگ گزارش‌شده).
        '<div id="helpModal" class="modal" style="display:none">',
        '<div class="modal-content">',
        '<div class="modal-header"><h3>راهنمای بات پاک‌سازی امضای سند</h3>',
        '<button class="modal-close" type="button" data-act="help-close">×</button></div>',
        '<div class="modal-body">',

        '<h4>این بات چه کار می‌کند</h4>',
        '<p>همان کار دستی شما را دسته‌ای انجام می‌دهد: سند حسابداریِ متصل به فاکتورهای داخل فیلتر را ',
        'پیدا می‌کند و شرح ردیف سند را از طریق <b>ماژول حسابداری</b> ویرایش می‌کند (یک فاصله در انتهای ',
        'توضیحات، به‌صورت Toggle) تا پلتفرم خودش امضاها را باطل کند.</p>',

        '<h4>چرا ممکن است کار نکند</h4>',
        '<p>«باطل شدن امضا با ویرایش سند» یک رفتار داخلی پلتفرم است، نه یک API مستند. ماژول حسابداری ',
        'هیچ endpoint امضا/حذف امضا ندارد. بنابراین بات بعد از هر سند، جدول امضاها را دوباره می‌خواند و ',
        '<b>تعداد واقعی</b> امضای حذف‌شده را می‌گوید. اگر عدد صفر بود، یعنی این مسیر از طریق API فعال ',
        'نمی‌شود و بات همان‌جا متوقف می‌شود — ادعای موفقیت الکی نمی‌کند.</p>',

        '<h4>گام «اول امضا کن»</h4>',
        '<p>این گام خودکار نمی‌شود چون API امضا وجود ندارد. اگر سندی برای ویرایش نیاز به امضای شما ',
        'داشته باشد، باید دستی در پنل امضا شود. ستون‌های «قفل»، «وضعیت» و «Changed» در جدول برای ',
        'همین نشان داده می‌شوند.</p>',

        '<h4>ستون‌های جدول</h4>',
        '<ul>',
        '<li><b>وضعیت اجرا</b>: آیا این سند داخل سقف اجرای فعلی هست یا نه.</li>',
        '<li><b>شمارهٔ سند / شناسهٔ سند</b>: شمارهٔ نمایشی و کلید داخلی سند حسابداری.</li>',
        '<li><b>فاکتور</b>: فاکتورهای متصل به همین سند (یک سند دسته‌ای می‌تواند چند فاکتور داشته باشد ',
        '— هر سند فقط یک بار ویرایش می‌شود). قابل کلیک است.</li>',
        '<li><b>امضا شده / منتظر / رد شده</b>: تفکیک ردیف‌های جدول امضا.</li>',
        '<li><b>قفل</b>، <b>وضعیت</b>، <b>Changed</b>: مقادیر LOCK_VOUCHER، STATUS و CHANGED_FLAG سند.</li>',
        '</ul>',

        '<h4>محافظ‌ها</h4>',
        '<ul>',
        '<li>حالت پیش‌فرض «پیش‌نمایش» است و هیچ چیزی نمی‌نویسد.</li>',
        '<li>اجرا بدون تایپ عبارت تأیید شروع نمی‌شود.</li>',
        '<li>بدون بازهٔ تاریخ یا شناسهٔ فاکتور، اجرا مجاز نیست.</li>',
        '<li>سقف پیش‌فرض هر اجرا ۱ سند است (حالت آزمون). خودتان آگاهانه بالا ببرید.</li>',
        '<li>پیش از هر نوشتن، تصویر قبلی رکورد در لاگ بات ثبت می‌شود.</li>',
        '<li>بعد از هر نوشتن، رکورد دوباره خوانده و با تصویر قبلی مقایسه می‌شود؛ اگر هر ستونی جز شرح ',
        'عوض شده باشد، کل اجرا فوراً متوقف می‌شود.</li>',
        '</ul>',

        '<h4>امکانات نوار ابزار</h4>',
        '<ul>',
        '<li><b>تمام صفحه</b>: گزارش را تمام‌صفحه می‌کند (بدون Fullscreen API، تا روی موبایل اسکرول سالم بماند).</li>',
        '<li><b>خروجی Excel</b>: جدول دامنه را به CSV می‌دهد.</li>',
        '<li>سرستون‌ها با کلیک مرتب می‌شوند.</li>',
        '</ul>',

        '</div></div></div>',
    })
end

-- ============================================================
-- JS
-- ============================================================

local REPORT_JS_HEAD = [[
<script>
var TYVSC_CONFIRM_PHRASE = ']]

-- بین عبارت تأیید و بدنهٔ JS، آدرس اجرای خودِ بات تزریق می‌شود (ر.ک. یادداشت v04 بالای فایل).
local REPORT_JS_MID = [[';
var TYVSC_BOT_URL = ']]

local REPORT_JS_BODY = [[';

/* آدرس مقصدِ همهٔ فراخوانی‌ها. **هرگز window.location.href نیست** — این باگ زندهٔ گزارش‌شده بود:
   صفحه‌ای که کاربر می‌بیند `?page=/bot/command/view&id=…` است (صفحهٔ پنلِ بات)، نه آدرس اجرای بات.
   پس POST به window.location.href روی صفحهٔ پنل می‌نشست و چیزی که برمی‌گشت قطعهٔ ما نبود.
   آدرس درست از teamyar.self() سمت سرور ساخته می‌شود، دقیقاً همان قرارداد {{_bot_path}} در res_v2. */
function tyvscEndpoint(){
  return (TYVSC_BOT_URL && TYVSC_BOT_URL !== '') ? TYVSC_BOT_URL : window.location.href;
}

/* پارامترها هم در Query String می‌روند و هم در بدنهٔ POST. الگو از بات ۶۱۳
   (Factor Settlement By Selection) گرفته شده که تفکیک عملیات را با `?type=N` روی botPath می‌فرستد.
   دلیل دوبار فرستادن: اگر لایهٔ get_input فیلدهای multipart بدنه را نچیند، تفکیک عملیات از Query
   خوانده می‌شود و درخواست باز هم درست مسیردهی می‌شود — به‌جای اینکه بی‌صدا صفحهٔ کامل برگردد. */
function tyvscUrlWith(formData, action, typeCode){
  var parts = ['type=' + encodeURIComponent(typeCode), 'action=' + encodeURIComponent(action)];
  formData.forEach(function(value, key){
    if (key === 'action' || key === 'type') return;
    parts.push(encodeURIComponent(key) + '=' + encodeURIComponent(value));
  });
  var url = tyvscEndpoint();
  return url + (url.indexOf('?') === -1 ? '?' : '&') + parts.join('&');
}

/* ============================================================================
   همه‌چیز با واگذاری رویداد (delegation) روی document کار می‌کند — نه onclick درون‌خطی و نه
   addEventListener روی گره‌های مشخص. دلیل، دو باگ زندهٔ گزارش‌شده:
     ۱) DOMContentLoaded: اگر HTML بات بعد از بارگذاری صفحهٔ پرتال تزریق شود، این رویداد قبلاً شلیک
        شده و هر اتصالی که داخلش باشد هرگز برقرار نمی‌شود.
     ۲) #resultBox با هر پیش‌نمایش دوباره ساخته می‌شود، پس اتصال مستقیم به دکمه‌های داخلش می‌پرد.
   واگذاری روی document از هر دو مصون است. همچنین هر عملیات، ریشهٔ خودش را با closest از روی عنصر
   کلیک‌شده پیدا می‌کند (نه getElementById سراسری) تا اگر چند نسخه از بات در یک صفحه بود قاطی نشود.
   ============================================================================ */

function tyvscRootOf(node){
  return (node && node.closest) ? node.closest('#tyvscRoot') : null;
}

function escapeHtml(text){
  return String(text == null ? '' : text)
    .split('&').join('&' + 'amp;')
    .split('<').join('&' + 'lt;')
    .split('>').join('&' + 'gt;')
    .split('"').join('&' + 'quot;');
}

/* ---------------- پاپ‌آپ راهنما ----------------
   نمایش/پنهان‌سازی با Style درون‌خطی، نه با کلاس: CSS پرتال Teamyar کلاس عمومی .modal دارد و روی
   قاعدهٔ ما غالب می‌شد، برای همین پاپ‌آپ بسته نمی‌شد. Style درون‌خطی با اولویت important روی هر
   قاعدهٔ استایل‌شیتی — حتی important — غالب است. */
function tyvscSetModal(root, open){
  if (!root) return;
  var modal = root.querySelector('#helpModal');
  if (!modal) return;
  modal.style.setProperty('display', open ? 'flex' : 'none', 'important');
}

/* ---------------- تمام صفحه ----------------
   بدون Fullscreen API (طبق تجربهٔ ثبت‌شدهٔ بات‌های خواهر: روی موبایل/iframe باز می‌شد ولی اسکرول
   نمی‌کرد). علاوه بر کلاس، Style درون‌خطی هم گذاشته می‌شود تا اگر CSS پرتال کلاس را خنثی کرد،
   باز هم کار کند — این همان چیزی است که کاربر گزارش کرد. */
var TYVSC_FS_STYLE = {
  position: 'fixed', top: '0', right: '0', bottom: '0', left: '0',
  zIndex: '2147483000', overflowY: 'auto', maxWidth: '100%', margin: '0'
};

function tyvscToggleFullScreen(root){
  if (!root) return;
  var on = root.classList.toggle('pseudo-fullscreen');
  for (var prop in TYVSC_FS_STYLE) {
    if (!TYVSC_FS_STYLE.hasOwnProperty(prop)) continue;
    if (on) root.style[prop] = TYVSC_FS_STYLE[prop];
    else root.style[prop] = '';
  }
  var button = root.querySelector('[data-act="fullscreen"]');
  if (button) button.textContent = on ? 'خروج از تمام صفحه' : 'تمام صفحه';
  if (on) root.scrollTop = 0; else window.scrollTo(0, 0);
}

/* ---------------- مرتب‌سازی جدول ---------------- */
function tyvscCellValue(cell){
  var text = cell ? cell.innerText.trim() : '';
  var n = text.replace(/[,%٪]/g, '').trim();
  if (n !== '' && /^-?\d+(\.\d+)?$/.test(n)) return parseFloat(n);
  return text;
}

function tyvscSortBy(th){
  var table = th.closest('table.data-table');
  if (!table) return;
  var tbody = table.querySelector('tbody');
  if (!tbody) return;

  var headers = th.parentNode.children;
  var colIndex = Array.prototype.indexOf.call(headers, th);
  if (colIndex < 0) return;

  var dir = th.classList.contains('sort-asc') ? 'desc' : 'asc';
  for (var h = 0; h < headers.length; h++) {
    headers[h].classList.remove('sort-asc', 'sort-desc');
  }
  th.classList.add(dir === 'asc' ? 'sort-asc' : 'sort-desc');

  var rows = Array.prototype.slice.call(tbody.querySelectorAll('tr'));
  rows.sort(function(ra, rb){
    var a = tyvscCellValue(ra.children[colIndex]);
    var b = tyvscCellValue(rb.children[colIndex]);
    var cmp;
    if (typeof a === 'number' && typeof b === 'number') cmp = a - b;
    else cmp = String(a).localeCompare(String(b), 'fa');
    return dir === 'asc' ? cmp : -cmp;
  });
  rows.forEach(function(row){ tbody.appendChild(row); });
}

/* ---------------- خروجی Excel ---------------- */
function tyvscCsvCell(t){
  t = (t == null ? '' : String(t)).replace(/\s+/g, ' ').trim();
  if (t.indexOf(',') !== -1 || t.indexOf('"') !== -1) t = '"' + t.replace(/"/g, '""') + '"';
  return t;
}

function tyvscExportExcel(root){
  if (!root) return;
  var table = root.querySelector('#scopeTable');
  if (!table) return;

  var lines = [];
  var heads = table.querySelectorAll('thead th');
  var headLine = [];
  for (var h = 0; h < heads.length; h++) headLine.push(tyvscCsvCell(heads[h].innerText));
  lines.push(headLine.join(','));

  var rows = table.querySelectorAll('tbody tr');
  for (var i = 0; i < rows.length; i++) {
    var cells = rows[i].querySelectorAll('td');
    var line = [];
    for (var c = 0; c < cells.length; c++) line.push(tyvscCsvCell(cells[c].innerText));
    lines.push(line.join(','));
  }

  var blob = new Blob(['﻿' + lines.join('\r\n')], { type: 'text/csv;charset=utf-8;' });
  var url = URL.createObjectURL(blob);
  var link = document.createElement('a');
  link.href = url;
  link.download = 'اسناد-قابل-پاکسازی-امضا.csv';
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}

/* ---------------- پیش‌نمایش ----------------
   ارسال بومی فرم عمداً استفاده نمی‌شود: داخل شِل/iframe واقعی Teamyar ناوبری بومی آدرس اجرای بات را
   از دست می‌دهد و صفحهٔ سفید می‌دهد. */
var tyvscPreviewBusy = false;

function tyvscLoadPreview(root){
  if (!root || tyvscPreviewBusy) return;
  tyvscPreviewBusy = true;

  var button = root.querySelector('#previewButton');
  var box = root.querySelector('#resultBox');
  var form = root.querySelector('#filterForm');
  if (!box || !form) { tyvscPreviewBusy = false; return; }

  var originalText = button ? button.textContent : '';
  if (button) { button.disabled = true; button.textContent = 'در حال بارگذاری…'; }

  var data = new FormData(form);
  data.append('action', 'preview');

  fetch(tyvscUrlWith(data, 'preview', 101), { method: 'POST', body: data, credentials: 'same-origin' })
    .then(function(res){
      if (!res.ok) throw new Error('HTTP ' + res.status);
      return res.text();
    })
    .then(function(html){
      /* اگر نشانهٔ قطعه نبود، یعنی پاسخ از جای درستی نیامده. سکوت ممنوع — دقیقاً همین سکوت بود که
         کاربر دید («لودینگ آمد ولی چیزی لود نکرد»). */
      if (html.indexOf('tyvsc-fragment') === -1) {
        var head = html.replace(/\s+/g, ' ').substring(0, 300);
        box.innerHTML = '<div class="notice"><strong>پاسخ نامعتبر از سرور.</strong><br>' +
          'درخواست به این آدرس رفت: <code>' + escapeHtml(tyvscEndpoint()) + '</code><br>' +
          'ولی چیزی که برگشت قطعهٔ گزارش نیست (نشانهٔ tyvsc-fragment در آن نبود) — ' +
          'یعنی احتمالاً به‌جای آدرس اجرای بات، به صفحهٔ پنل خورده است.<br>' +
          'ابتدای پاسخ: <code>' + escapeHtml(head) + '</code></div>';
        return;
      }
      box.innerHTML = html;
    })
    .catch(function(err){
      box.innerHTML = '<div class="notice"><strong>خطا در دریافت پیش‌نمایش:</strong> ' +
        escapeHtml(String(err)) + '</div>';
    })
    .then(function(){
      tyvscPreviewBusy = false;
      if (button) { button.disabled = false; button.textContent = originalText; }
    });
}

/* ---------------- اجرای پاک‌سازی ---------------- */
var TYVSC_STATUS_LABEL = {
  cleared: 'امضا باطل شد',
  skipped: 'رد شد — بدون نوشتن',
  no_write: 'API چیزی ننوشت',
  no_effect: 'بی‌اثر — امضا حذف نشد',
  api_failed: 'خطای API',
  read_failed: 'خطای خواندن',
  integrity: 'نقض یکپارچگی — متوقف شد'
};

function tyvscRenderResults(box, payload){
  var summary = payload.summary || {};
  var results = payload.results || [];

  var head = '<div class="notice"><strong>خلاصهٔ اجرا:</strong> ' +
    'بررسی‌شده: ' + (summary.processed || 0) + ' سند — ' +
    'نوشته‌شده: ' + (summary.written || 0) + ' — ' +
    'رد‌شده بدون نوشتن: ' + (summary.skipped || 0) + ' — ' +
    'باطل‌شده: ' + (summary.cleared || 0) + ' سند — ' +
    'مجموع امضای حذف‌شده: ' + (summary.removed_total || 0);
  if (summary.aborted) {
    head += '<br><strong>اجرا متوقف شد:</strong> ' + escapeHtml(summary.abort_reason || '');
  }
  head += '</div>';

  var rowsHtml = '';
  if (results.length === 0) {
    rowsHtml = '<tr><td colspan="6" class="empty-row">هیچ سندی پردازش نشد.</td></tr>';
  } else {
    for (var i = 0; i < results.length; i++) {
      var r = results[i];
      var label = TYVSC_STATUS_LABEL[r.status] || r.status;
      var chipClass = (r.status === 'cleared') ? 'on' : 'off';
      rowsHtml += '<tr><td>' + (i + 1) + '</td>' +
        '<td>' + escapeHtml(r.voucher_id) + '</td>' +
        '<td>' + escapeHtml(r.org_id) + '</td>' +
        '<td><span class="chip ' + chipClass + '">' + escapeHtml(label) + '</span></td>' +
        '<td>' + escapeHtml(r.signs_before) + ' ← ' + escapeHtml(r.signs_after) + '</td>' +
        '<td>' + escapeHtml(r.message || '') + '</td></tr>';
    }
  }

  box.innerHTML = head +
    '<div class="table-scroll"><table class="data-table"><thead><tr>' +
    '<th>#</th><th>شناسهٔ سند</th><th>سازمان</th><th>نتیجه</th><th>امضا قبل ← بعد</th><th>توضیح</th>' +
    '</tr></thead><tbody>' + rowsHtml + '</tbody></table></div>';
}

function tyvscRunClear(root){
  if (!root) return;

  var confirmInput = root.querySelector('#confirmInput');
  var button = root.querySelector('#runButton');
  var box = root.querySelector('#runLog');
  var form = root.querySelector('#filterForm');
  if (!confirmInput || !box || !form) return;

  if (confirmInput.value.trim() !== TYVSC_CONFIRM_PHRASE) {
    box.innerHTML = '<div class="notice">برای شروع، عبارت «' + escapeHtml(TYVSC_CONFIRM_PHRASE) +
      '» را عیناً در کادر تأیید تایپ کنید.</div>';
    return;
  }

  if (!window.confirm('این عملیات برگشت‌ناپذیر است. امضاهای باطل‌شده برنمی‌گردند. ادامه می‌دهید؟')) return;

  if (button) button.disabled = true;
  box.innerHTML = '<div class="notice">در حال اجرا… این صفحه را نبندید.</div>';

  var data = new FormData(form);
  data.append('action', 'execute');
  data.append('confirm', confirmInput.value.trim());

  fetch(tyvscUrlWith(data, 'execute', 201), { method: 'POST', body: data, credentials: 'same-origin' })
    .then(function(res){
      if (!res.ok) throw new Error('HTTP ' + res.status);
      /* اجرا هرگز نباید روی پاسخ غیر-JSON کورکورانه جلو برود: اگر درخواست به صفحهٔ پنل خورده باشد،
         متن HTML برمی‌گردد و JSON.parse خطا می‌دهد — که همان را به کاربر نشان می‌دهیم. */
      return res.text().then(function(text){
        try { return JSON.parse(text); }
        catch (err) {
          throw new Error('پاسخ JSON نبود (آدرس: ' + tyvscEndpoint() + '). ابتدای پاسخ: ' +
            text.replace(/\s+/g, ' ').substring(0, 200));
        }
      });
    })
    .then(function(payload){
      if (!payload.ok) {
        box.innerHTML = '<div class="notice"><strong>اجرا انجام نشد:</strong> ' +
          escapeHtml(payload.error || 'خطای ناشناخته') + '</div>';
        return;
      }
      tyvscRenderResults(box, payload);
    })
    .catch(function(err){
      box.innerHTML = '<div class="notice"><strong>خطا در ارتباط با سرور:</strong> ' +
        escapeHtml(String(err)) + '</div>';
    })
    .then(function(){
      if (button) button.disabled = false;
    });
}

/* ---------------- اتصال‌ها ---------------- */
if (!window.__tyvscBound) {
  window.__tyvscBound = true;

  document.addEventListener('click', function(e){
    var target = e.target;
    if (!target || !target.closest) return;

    var root = tyvscRootOf(target);
    if (!root) return;

    var trigger = target.closest('[data-act]');
    if (trigger && root.contains(trigger)) {
      var act = trigger.getAttribute('data-act');
      if (act === 'fullscreen') { e.preventDefault(); tyvscToggleFullScreen(root); return; }
      if (act === 'excel')      { e.preventDefault(); tyvscExportExcel(root); return; }
      if (act === 'help')       { e.preventDefault(); tyvscSetModal(root, true); return; }
      if (act === 'help-close') { e.preventDefault(); tyvscSetModal(root, false); return; }
      if (act === 'preview')    { e.preventDefault(); tyvscLoadPreview(root); return; }
      if (act === 'run')        { e.preventDefault(); tyvscRunClear(root); return; }
    }

    /* کلیک روی خودِ پوشش تیرهٔ پاپ‌آپ (نه داخل کادر) = بستن */
    if (target.id === 'helpModal') { tyvscSetModal(root, false); return; }

    var th = target.closest('thead th');
    if (th && root.contains(th)) { tyvscSortBy(th); return; }
  }, false);

  document.addEventListener('submit', function(e){
    var form = e.target;
    if (!form || form.id !== 'filterForm') return;
    var root = tyvscRootOf(form);
    if (!root) return;
    e.preventDefault();
    tyvscLoadPreview(root);
  }, false);

  document.addEventListener('keydown', function(e){
    if (e.key !== 'Escape' && e.keyCode !== 27) return;
    var roots = document.querySelectorAll('#tyvscRoot');
    for (var i = 0; i < roots.length; i++) tyvscSetModal(roots[i], false);
  }, false);
}
</script>
]]

-- ============================================================
-- RENDER — صفحهٔ کامل
-- ============================================================

local function render_error_html(message)
    return table.concat({
        REPORT_CSS,
        '<div id="tyvscRoot"><div class="danger-band"><h2>خطا</h2><ul><li>',
        escape_html(message),
        '</li></ul></div></div>',
    })
end

-- قطعهٔ نتیجه — هرچه با عوض‌شدن فیلتر باید دوباره ساخته شود. هم در صفحهٔ کامل تعبیه می‌شود و هم
-- به‌تنهایی با `action=preview` برگردانده می‌شود تا JS آن را جای `#resultBox` بگذارد.
local FRAGMENT_MARKER = "<!-- tyvsc-fragment -->"

local function render_results_fragment(filters, scope)
    return table.concat({
        -- نشانهٔ تشخیص: اگر پاسخِ XHR این را نداشته باشد، یعنی درخواست به آدرس اشتباهی خورده
        -- (مثلاً صفحهٔ پنل به‌جای آدرس اجرای بات). آن‌وقت JS به‌جای سکوت، خطای روشن نشان می‌دهد.
        FRAGMENT_MARKER,
        render_warnings(filters.warnings),

        '<div class="section"><div class="section-head">',
        '<h2><span class="num">۲</span>پیش‌نمایش (فقط خواندنی)</h2>',
        '<p>دامنهٔ انتخابی: ', escape_html(SCOPE_STATES[filters.scope] or ""), '</p></div>',
        render_kpis(scope),
        render_scope_table(scope, filters),
        '</div>',

        render_execute_panel(scope, filters),
    })
end

-- آدرس اجرای خودِ بات. صفحه‌ای که کاربر می‌بیند «?page=/bot/command/view&id=…» است (صفحهٔ پنلِ بات)،
-- نه آدرس اجرا — پس مقصد XHR باید صریح ساخته شود، نه از window.location.href گرفته شود.
-- همان قراردادِ {{_bot_path}} در res_v2 و همان کاری که بات signed_invoices می‌کرد.
local function resolve_bot_url()
    local ok_self, self_info = pcall(teamyar.self)
    if not ok_self or type(self_info) ~= "table" then return "" end

    local run_path = tostring(self_info.run_path or "")
    if run_path == "" then return "" end

    run_path = run_path:gsub("^/+", "")
    return "/bot/run/" .. run_path
end

local function render_page(filters, scope, actor)
    local organizations = fetch_organizations()
    local bot_url = resolve_bot_url()

    return table.concat({
        REPORT_CSS,
        '<div id="tyvscRoot">',

        -- data-act به‌جای onclick درون‌خطی: onclick به تابع سراسری و به اجرای <script> وابسته است،
        -- ولی واگذاری رویداد روی document حتی وقتی HTML بات با innerHTML تزریق شود کار می‌کند.
        '<div class="toolbar">',
        '<button type="button" class="btn-toolbar" data-act="fullscreen">تمام صفحه</button>',
        '<button type="button" class="btn-toolbar" data-act="excel">خروجی Excel</button>',
        '<button type="button" class="btn-toolbar secondary" data-act="help">راهنما</button>',
        '</div>',

        '<header class="hero"><img class="brand140-logo" alt="140" src="data:image/png;base64,',
        CONFIG.LOGO140_WHITE_B64, '">',
        '<h1>پاک‌سازی امضای سند حسابداری فاکتورهای فروش</h1>',
        '<p class="sub">اجراکننده: ', escape_html(actor.name), ' (شناسه ', escape_html(tostring(actor.id)),
        ') — همهٔ عملیات با همین شناسه در لاگ بات ثبت می‌شود.</p></header>',

        '<div class="danger-band"><h2>قبل از اجرا حتماً بخوانید</h2><ul>',
        '<li>این عملیات <b>برگشت‌ناپذیر</b> است؛ امضای باطل‌شده برنمی‌گردد.</li>',
        '<li>«باطل شدن امضا با ویرایش سند» یک رفتار داخلی پلتفرم است، نه یک API مستند — ',
        'ماژول حسابداری هیچ endpoint امضا ندارد. بات بعد از هر سند، تعداد <b>واقعی</b> امضای حذف‌شده را ',
        'می‌خواند و گزارش می‌کند؛ اگر بی‌اثر بود، همان‌جا متوقف می‌شود.</li>',
        '<li>گام «اول امضا کن» خودکار نمی‌شود (API امضا وجود ندارد). اسناد قفل/بسته در جدول مشخص‌اند و ',
        'باید دستی در ماژول حسابداری رسیدگی شوند.</li>',
        '<li>سقف پیش‌فرض هر اجرا <b>۱ سند</b> است. اول همان یکی را اجرا کنید، نتیجه را ببینید، بعد سقف را ',
        'بالا ببرید.</li>',
        '</ul></div>',

        '<div class="section"><div class="section-head">',
        '<h2><span class="num">۱</span>فیلتر دامنه</h2>',
        '<p>دامنه فقط از روی همین فیلتر ساخته می‌شود — سمت سرور دوباره محاسبه می‌شود و هیچ فهرست سندی ',
        'از مرورگر پذیرفته نمی‌شود.<br>مسیر فراخوانی این بات: <b>',
        escape_html(bot_url ~= "" and bot_url or "؟ (از teamyar.self خوانده نشد)"),
        '</b></p></div>',
        render_filter_bar(filters, organizations),
        '</div>',

        '<div id="resultBox">', render_results_fragment(filters, scope), '</div>',

        '<div class="report-footer">بات پاک‌سازی امضای سند حسابداری — تحلیل و ایجاد توسط سینا مقدم</div>',

        -- پاپ‌آپ عمداً *داخل* ریشه است: همهٔ CSS با «#tyvscRoot » دامنه‌بندی شده، پس بیرون از ریشه
        -- هیچ استایلی نمی‌گرفت و دست پرتال می‌افتاد — همان چیزی که باعث می‌شد بسته نشود.
        render_help_modal(),

        '</div>',
        REPORT_JS_HEAD, escape_js_string(CONFIG.CONFIRM_PHRASE),
        REPORT_JS_MID, escape_js_string(bot_url),
        REPORT_JS_BODY,
    })
end

-- ============================================================
-- MAIN
-- ============================================================

local function main()
    local actor, denied = resolve_actor()
    if denied then
        return "html", render_error_html(denied)
    end

    local input = teamyar.get_input() or {}
    local filters = read_filters(input)

    -- تفکیک عملیات از دو کانال خوانده می‌شود: فیلد `action` و کدِ `type` در Query String.
    -- الگوی `type=N` از بات ۶۱۳ (Factor Settlement By Selection) گرفته شده — همان قرارداد بومی
    -- پلتفرم. اگر لایهٔ get_input فیلدهای multipart بدنه را نچیند، `type` از Query می‌آید و درخواست
    -- باز هم درست مسیردهی می‌شود، به‌جای اینکه بی‌صدا صفحهٔ کامل برگردد.
    local TYPE_PREVIEW, TYPE_EXECUTE = 101, 201
    local action = tostring(input["action"] or "")
    local type_code = tonumber(latin_digits(tostring(input["type"] or ""))) or 0

    if action == "" then
        if type_code == TYPE_EXECUTE then action = "execute"
        elseif type_code == TYPE_PREVIEW then action = "preview" end
    end

    if action == "execute" then
        if filters.confirm ~= CONFIG.CONFIRM_PHRASE then
            return "json", json.encode({ ok = false,
                error = "عبارت تأیید درست تایپ نشده است." })
        end
        if not filters.has_scope then
            return "json", json.encode({ ok = false,
                error = "برای اجرا باید بازهٔ تاریخ یا شناسهٔ یک فاکتور مشخص باشد." })
        end

        -- دامنه همیشه سمت سرور از روی فیلتر ساخته می‌شود؛ فهرست سند از مرورگر پذیرفته نمی‌شود
        local scope, scope_err = build_scope(filters)
        if scope == nil then
            return "json", json.encode({ ok = false, error = scope_err })
        end
        if #scope.vouchers == 0 then
            return "json", json.encode({ ok = false, error = "هیچ سندی در دامنه نیست." })
        end

        local results, summary = execute_batch(scope, filters, actor)
        return "json", json.encode({ ok = true, results = results, summary = summary })
    end

    -- قطعهٔ نتیجه برای XHR فیلتر. ناوبری بومی فرم داخل شِل Teamyar بات را از دست می‌دهد
    -- (صفحهٔ سفید)، پس فیلتر همیشه از این مسیر می‌آید.
    if action == "preview" then
        local scope, scope_err = build_scope(filters)
        if scope == nil then
            return "html", '<div class="notice"><strong>خطا:</strong> ' ..
                           escape_html(tostring(scope_err)) .. '</div>'
        end
        return "html", render_results_fragment(filters, scope)
    end

    local scope, scope_err = build_scope(filters)
    if scope == nil then
        return "html", render_error_html(scope_err)
    end

    return "html", render_page(filters, scope, actor)
end

local ok, kind, body = pcall(main)

if not ok then
    log_line("FATAL | " .. tostring(kind))
    teamyar.write_result(render_error_html(
        "خطا در اجرای بات: " .. tostring(kind) .. " — جزئیات در لاگ بات ثبت شد."))
else
    teamyar.write_result(tostring(body))
end
