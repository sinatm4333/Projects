# Teamyar Bot Catalog

Index only â€” source code lives in `src/`. Read the matching file before writing a new bot.

## Reference Bots

| File | Type | Input | Use when |
|------|------|-------|----------|
| `bot_commands_json_bot.lua` | JSON | none | Simple list + JOIN |
| `bot_analytics_json_bot.lua` | HTML report | `limit`, `days`, `include_disabled`, `bot_ids`, `workflow_ids`, `action_type_ids` (multi) | Bot analytics + live search for action types (category/workflow/topic) |
| `service_replaced_products_json_bot.lua` | HTML/JSON | `from_date`, `to_date`, `product_code`, `receipt_no`, `format=json` | PM replaced products + warranty/sales/cost matrix (HTML default) |
| `service_replaced_products_report_bot.lua` | HTML/JSON | same as json bot | Same bot â€” costs: declared, replacement value, parts |
| `warranty_branch_expense_detail_report_bot.lua` | HTML/JSON | `from_date`, `to_date`, `center_code`, `account_code`, `org_id` | Warranty branch expense detail ledger; **requires** `center_code` or `account_code`; default date range = fiscal year start to today |
| `db_schema_json_bot.lua` | JSON | `table`, `schema` | INFORMATION_SCHEMA |
| `open_tasks_steps_json_bot.lua` | JSON | none | CTE, nested grouping, Jalali |
| `task_steps_json_bot.lua` | JSON | `task_id` | Input validation, rich helpers |
| `EghdamPerId_bot.lua` (bot 927) | HTML/JSON | `task_id`, `format=json` | Single action/task workflow-step timeline: status, responsible, gaps, per-step comments modal (HTML default) |
| `chat_dialog_messages_json_bot.lua` | JSON | `dialog_id` | Extract chat dialog messages, senders, participants |
| `service_receipt_cost_json_bot.lua` | JSON | `receipt_no` | Receipt cost breakdown: consumed parts, replacement, refund (COGS) |
| `service_receipt_cost_period_json_bot.lua` | HTML/JSON | `startDate`, `end_date`, `org_id`, `format=json` | Period receipt cost matrix (HTML default); grouping by product, month, productÃ—month |
| `sales_accessory_volume_performance_report_bot.lua` | HTML/JSON | `startDate`, `end_date`, `org_id` (default 2), `format=json` | Sales unit performance by quantity volume for mobile accessories |
| `sales_invoice_title_duplicates_report_bot.lua` | HTML | `org_id` (default: 2) | Duplicate sales invoice TITLE groups (count > 1); dates are always current fiscal year; excludes DELETED and empty/null titles |
| `sales_price_list_report_bot.lua` | HTML/JSON | `org_id`, `title`, `format=json` | Sales price list catalog from `sales_price_setting` with center/client link counts + per-list product prices via **drill-down** (row click / per-list Excel `fetch` the bot with `list_id`), single search box (list name instant + product name/code via server `product` search). Params: `list_id`, `product`, `org_id`, `title`, `format=json`. Prices join: `sales_setting ss ON ss.SETTING_ID=sps.ID` (ss.QUANTITY_INT=price) → `sales_discount_ext e ON e.SETTING_ID=ss.ID AND e.SETTING_TYPE=3` (e.REFERE_ID=product) → `wh_product` |
| `EghdamBazAnalyze_bot.lua` (bot 928) | HTML | none | Analyze only open actions — not closed with success or failure (`T_REAL_END_DATE IS NULL/0`) — one row per action: current step, responsible, unit, wait time, **SLA breach flag** (بله/خیر + `#E5006E` row highlight; SLA = `todo_step.duration` × `time_unit`, `—` when undefined), overdue amount, total step count. Breached rows sort to top; sortable, Excel export, help modal, workflow-distribution modal (summary cards stay numeric — never inline a long list there) |
| `schema_probe_json_bot.lua` (bot 966) | JSON | `table`, `schema`, `mode` | Runtime schema/data probe: `mode=cols` (columns by table LIKE), `mode=tables`, `mode=raw` (ad-hoc query in `q`). Robust variant with `db.use_db`+`pcall` |
| `user_activity_stats_report_bot.lua` | HTML/JSON | `user_name` (required), `org_id` (default 2), `format=json` | User activity in current fiscal year: dialogs (DATE_CREATE), steps, warehouse, invoices, vouchers |
| `timing_report_bot.lua` | HTML | `startDate` | Parameterized HTML report |
| `service_receipt_summary_report_bot.lua` | HTML | `startDate`, `end_date`, `org_id`, `product_code` | Service receipt summary dashboard: KPIs, status distribution, top products, monthly trends, technician performance, recent activity feed |
| `tat_pivot_report_bot.lua` | HTML | â€” | Monthly pivot |
| `tat_pivot_report_3day_bot.lua` | HTML | â€” | Pivot variant |
| `action_count_by_category_report_bot.lua` (bot 586, cat_id=79) | HTML/JSON | `format=json`, `drill_category_id=<id>&format=json` (فهرست اقدام‌های باز یک رده) | تعداد کل اقدام‌ها (`todo_task`) به تفکیک رده (`todo_category` via `tt.CATEGORY_ID`)؛ ستون‌های تعداد کل/باز/بسته + سهم از کل؛ کلیک روی «N باز ▾» فهرست تک‌تک اقدام‌های باز آن رده را زیر همان ردیف باز می‌کند (عنوان/مرحله/مسئول)؛ کلیک روی عنوان هر اقدام، جزئیات آن را از بات «خلاصه اقدام با آی دی» (id=927, `run/258/EghdamPerId`, `task_id`) در تب جدید باز می‌کند؛ بدون فیلتر تاریخ |
| `sales_settlement_group_auto_report_bot.lua` (bot 588, cat_id=79) | HTML | RES-framework (`install_res`/`res_v2`), no `bot_customform` | **کپی بات ۵۶۹** («تسویه گروهی» / `Factor Seteelment By Selection`) با نام «تسویه اتوماتیک گروهی». فهرست فاکتورهای قابل‌تسویه + تسویه تکی/گروهی واقعی روی فاکتورها (`/api/sales/create_settlement`) — بات مالی نویسنده، نه صرفاً گزارشی. وابسته به ۴ پیوست (`src/sales_settlement_group_auto_attachments/`: `mySqlQuery.txt`, `data.txt`, `data.js`, `data.css`) که باید دستی از پنل بات آپلود شوند (endpoint آپلود attachment ناشناخته) + یک نمونه‌ی «پیکربندی» (کد حساب تسویه=۱۰۱۰۰۱۰۰۴، نوع تسویه=نقد، کپی از «تسویه پیش‌فرض» بات ۵۶۹) که باید از تب «پیکربندی» بات ساخته شود |
| `moadian_invoices_dashboard_report_bot.lua` (bot 595, cat_id=80) | HTML/JSON | `from_date`, `to_date` (شمسی، پیش‌فرض سال مالی فعال)، `org_id` (**پیش‌فرض 8** — نه 2؛ طبق دادهٔ زنده تمام فاکتورهای `moadian_status>0` زیر org_id=8 هستند)، `limit` (پیش‌فرض 500)، `type=1\|2\|3` (AJAX داخلی سه تب)، `type=4`+`fid`+`referenceNumber` (AJAX استعلام یک فاکتور)، `format=json` | داشبورد فاکتورهای ارسالی به سامانهٔ مودیان — سه تب (ارسالی/ابطالی/اصلاحی)، بازنویسی کامل بات ۵۷۸ («صفحه اصلی مودیان[Module]»، cat_id=80) با معماری استاندارد این ریپو (پالت #16509D، فونت Peyda، هدر مرتب‌سازی‌پذیر، تمام‌صفحه/Excel/راهنما). باگ‌های بات مبدأ که اصلاح شدند: تب «اصلاحی» (type=3) در بات مبدأ به‌خاطر `elseif intype==2` تکراری هرگز کوئری درستی نمی‌گرفت؛ شرط وضعیت اصلاحی `moadian_status<20` بود (باید `<320` باشد، الگوی دو تب دیگر). وابستگی به پیوست‌های دستی querySend/queryDelete/queryEdite.txt و به تب «پیکربندی» بات حذف شد — یک کوئری مشترک پارامتری (`build_data_query`/`build_count_query`) جایگزین شد. کدهای `moadian_status` دیده‌شده در دادهٔ زنده که در نگاشت برچسب مستند نیستند (۱۲۰، ۴۰۰) به‌جای «ارسال نشده» به‌صورت «نامشخص (کد N)» نمایش داده می‌شوند و در هیچ‌کدام از سه تب نمی‌آیند — نیاز به تعریف کسب‌وکاری از صاحب فرآیند مودیان دارد |
| `crm_rfm_1_bot.lua` (بات ۶۰۰ "RFM CRM"، کپی زندهٔ بات ۵۰۱، `run/2/crm_rfm_1`، RES-framework) | HTML | همان فرم RES بات ۵۰۱ (`data.txt`): `datef`, `datet`, `org`, `ctype`, `cat` (+ ACL type=6/7/8/9)، `type=100` گزارش / `101` اکسل / `102` پرینت / `10`\|`11` ارسال پیامک تکی/گروهی | تحلیل RFM مشتریان (Recency/Frequency/Monetary/ntile) — **نسخهٔ فعال روی Teamyar**؛ اصلاح جراحی‌شدهٔ `getData()` بات ۵۰۱ (نه بازنویسی کامل — کاربر خواست معماری RES/`queryTools.where` و ظاهر بات مبدأ حفظ شود). پیوست `query_list_invoice.txt` هم باید دستی با نسخهٔ اصلاح‌شده (`scratchpad/query_list_invoice_fixed.txt` در این ریپو) جایگزین شود. **باگ‌های رفع‌شده:** ۱) `datef`/`datet` که نبودنشان بی‌صدا به ۰ (تاریخ صفر سیستم) سقوط می‌کرد و Monetary/اکسل کل تاریخچه را حساب می‌کردند — طبق درخواست کاربر بدون منطق سال مالی، پیش‌فرض ناموجود اکنون «امروز» است (بازهٔ خالی/تقریباً خالی، سیگنال واضح، نه کل تاریخچهٔ گمراه‌کننده)؛ ۲) `f_nummber`/`m_nummber` هر دو از `cdata.rnumber` می‌خواندند (کپی/پیست) — وزن F/M همیشه نادیده گرفته می‌شد، اصلاح شد هرکدام فیلد خودش؛ ۳) فیلتر `cat` به alias نامعتبر `c.id` ارجاع می‌داد (کد مرده، با خطا می‌شکست) — اصلاح به `p.id`؛ ۴) فیلتر `ctype` به `ui.USER_TYPE` ارجاع می‌داد بدون join به `profile_user_info` (کد مرده) — `LEFT JOIN profile_user_info ui ON ui.id = p.REFFERE_ID` اضافه شد؛ ۵) ورودی/فیلتر تکراری `crm` (کپی دقیق `ctype`، در `data.txt` هم تعریف نشده بود) حذف شد. `queryTools.where`/`{{whereInvoice}}` عمداً دست‌نخورده ماند: آن placeholder روی نتیجهٔ نهایی تجمیع‌شده اعمال می‌شود که ستون‌های `ORG_ID`/`USER_TYPE` در آن دید نیستند — org/ctype/cat باید داخل CTE `crm_factor` فیلتر شوند (همان‌جایی که بات مبدأ برای `org` هم درست همین کار را می‌کرد). رنگ سبز/آبی/قرمز/خاکستری برچسب‌های سگمنت در پیوست SQL هنوز طبق پالت الزامی این ریپو (#16509D) اصلاح نشده — تغییر جداگانه لازم است. یک بازنویسی کامل جایگزین (بدون RES/attachment، native `bot_customform`) هم در `crm_rfm_report_bot.lua` هست ولی مستقر نشده — کاربر معماری RES را ترجیح داد. **ظاهر:** پیوست‌های اختصاصی `data.css`/`data.js` (در `scratchpad/data_css_bot600.css` و `scratchpad/data_js_bot600.js` این ریپو، هنوز آپلود نشده) — فونت Peyda + پالت #16509D + دکمه راهنما، اسکوپ‌شده به `section[data-name="crm_rfm_1"]`؛ جدول واقعی از ویجت هسته‌ای پلتفرم `$.Teamyar.table()` می‌آید که قابل ری‌استایل نیست (نه مرتب‌سازی ستون‌ها) |
| `trial_balance_report_bot.lua` (bot 1023) | HTML/JSON | `from_date`, `to_date`, `org_id` (default 2), `account_code`, `show_zero=1`, `drill_account_id` (+format=json), `format=json` | تراز آزمایشی چهارستونی: گردش بدهکار/بستانکار دوره + مانده بدهکار/بستانکار. پیش‌فرض بازه = سال مالی جاری تا امروز. **مانده به بازه سال مالیِ حاویِ `to_date` محدود می‌شود** (نه کل تاریخچه دفاتر) چون هر سال با سند افتتاحیه باز می‌شود؛ کوئری از سمت `pa_voucher` رانده می‌شود (ایندکس `IDX6(ORG_ID,DELETED,RUN_DATE,STATUS,TYPE)`) نه `pa_voucher_record` (۱۵ میلیون ردیف بدون ایندکس تاریخ) — تغییر ندهید بدون تست کارایی. برای حساب‌های کنترلی بدون زیرحساب pa_account (FORCE_CLIENT/FORCE_FLOATING=1، مثل «حسابهای دریافتنی تجاری») دکمه «تفصیلی ▾» یک سطح پایین‌تر (ریز مشتریان via CLIENT_ID) را با `drill_account_id` (drill-down مشابه sales_price_list) نشان می‌دهد؛ کلیک روی کد حساب هم زیرمجموعه‌های واقعی pa_account (بر اساس پیشوند کد) را فیلتر می‌کند |
| `hr_dashboard_report_bot.lua` (جدید، هنوز مستقر نشده) | HTML/JSON | `org_id` (اختیاری)، `from_date`/`to_date`/`months` (FILETIME عددی، پیش‌فرض ۶ ماه اخیر)، `format=json` | داشبورد تجمیعی منابع انسانی: KPIهای نیروی فعال/استخدام جدید/متوسط سابقه/خروج تخمینی، ترکیب سازمانی، روند ماهانهٔ استخدام/حضور و تاخیر/اضافه‌کاری/حقوق و دستمزد، و هشدار تولد/قطع بیمهٔ فرزندان. کوئری‌های آن مستقیماً روی جداول HR نوشته شده (نه فراخوانی بات‌های دیگر) و الگوی هر بخش از کوئری واقعی یکی از ۱۱ بات جدول زیر کپی/تایید شده. **محدودیت شناخته‌شده:** ترکیب جنسیتی/تحصیلات/تاهل (که در بات ۳۸۲ دیده می‌شود) عمداً اضافه نشده چون ستون منبع واقعی‌اش هنگام استخراج truncate و تایید نشد — نیازمند بررسی db_schema قبل از افزودن |
| `sales_revenue_center_dashboard_report_bot.lua` (بات ۶۰۹، `run/443/sales_revenue_center_dashboard`) | HTML/JSON | `channel` (`""`\|`b2b`\|`b2c`\|`other`)، `date_from`/`date_to` (شمسی، پیش‌فرض بازه = ابتدای سال مالی جاری تا امروز — **هر دو سر بازه از فیلتر کاربر خوانده و همیشه اعمال می‌شوند**، برخلاف `crm_geo_sales_dashboard_bot.lua`)، `center` (نام مرکز درآمد، اختیاری)، `format=json`؛ AJAX داخلی: `action=product_invoices`+`product_code`، `action=customer_invoices`+`crm_id` | داشبورد فروش محور (نه CRM/جغرافیا) به تفکیک **مرکز درآمد** فاکتور (`sales_invoice.SALES_CENTER` → `pa_center.NAME`) — خواهر `crm_geo_sales_dashboard_bot.lua`: فرمول مبلغ فاکتور (`INVOICE_AMOUNT_JOIN`) و Rule تفکیک B2B/B2C (LIKE «همکار»/«مصرف» روی نام مرکز درآمد) عیناً از آن به ارث رسیده تا اعداد دو بات ناسازگار نشوند. شامل: KPI فروش، نمودار میله‌ای/Donut/Combo فروش به تفکیک مرکز درآمد (کلیک = فیلتر داشبورد به آن مرکز)، نمودار میله‌ای قابل‌کلیک پرفروش‌ترین/کم‌فروش‌ترین کالا (کلیک = فهرست فاکتورهای همان کالا در Modal)، و ۱۰ مشتری برتر B2B و ۱۰ مشتری برتر B2C در دو جدول کنار هم — یعنی مشتریانی که بیشترین مبلغ فروش را در بازهٔ تاریخ فعال داشته‌اند (همیشه هر دو جدول نمایش داده می‌شوند، مستقل از تب B2B/B2C فعال — فقط بازهٔ تاریخ/مرکز درآمد روی آن‌ها اثر دارد). تب‌های «کل فروش/B2B/B2C/سایر» طبق الگوی `render_channel_tabs` همان بات خواهر. لوگو ۱۴۰ (نسخهٔ White) + فونت Peyda + پالت #16509D طبق الزام CLAUDE.md برای بات‌های HTML جدید. **دیپلوی و روی دادهٔ زنده تأیید شد (1405/05/26)**: مبلغ کل فروش/تعداد فاکتور/تعداد مشتری/۴ مرکز درآمد فعال/پرفروش‌ترین کالا/جدول‌های ۱۰ مشتری برتر همگی با دادهٔ واقعی رندر شدند. **باگ بحرانی کشف و رفع شد حین تست همین بات (ر.ک. یادداشت `build_channel_clause` در سورس و بخش «محدودیت پلتفرم» در CLAUDE.md): پارامتری‌کردن `LIKE ?` در لایهٔ `db.query` این پلتفرم بی‌صدا شکست می‌خورد** (پارامتر رسیده نادیده گرفته می‌شود، «sql error» عمومی برمی‌گردد) — با تست ایزوله روی بات ۵۸۹ (schema_probe_v2) تأیید شد: `WHERE col = ?` کار می‌کند، `WHERE col LIKE ?` نه. در این بات با Literal کردن دو ثابت Hardcode (`CHANNEL_B2B_LIKE`/`CHANNEL_B2C_LIKE`، هرگز از ورودی کاربر نیستند — بدون ریسک Injection) به‌جای Parameter رفع شد. **آپدیت (1405/05/26 شب، بعد از گزارش کاربر روی بات ۶۰۴): `crm_geo_sales_dashboard_bot.lua` واقعاً همین باگ را داشت** (کاربر حین تست تب B2B با `sql error` مواجه شد — دقیقاً طبق پیش‌بینی) — با همان تکنیک (Literal به‌جای Param) در همان فایل رفع و مجدداً روی بات ۶۰۴ دیپلوی و با `channel=b2b` زنده تأیید شد. حین همین رفع، دو مشکل دیگر هم روی بات ۶۰۴ کشف/رفع شد (و پیشگیرانه در این بات هم اعمال شد، چون هر دو الگوی مشترک بین دو بات خواهرند): ۱) **لینک «مشاهده CRM» روی سرور خراب شده بود** — رشتهٔ Literal `"&section=2"` هنگام ذخیرهٔ command توسط Teamyar به `"§ion=2"` تبدیل شده بود (Decode حریصانهٔ `&sect` به Entity `§`، همان خانوادهٔ Quirk escape_html) — رفع با Concatenation (`"&" .. "section=2"`)؛ ۲) **دکمهٔ «تمام صفحه» روی موبایل/iframe اسکرول نمی‌شد** — چون متکی به `Element.requestFullscreen()` واقعی مرورگر بود که رفتارش روی Android Chrome/iframe غیرقابل‌اتکا است؛ با یک toggle کلاس CSS خالص (`position:fixed` + `overflow-y:auto`، بدون Fullscreen API) جایگزین شد. هر دو در این بات هم پیشگیرانه اعمال شدند. |

## بات‌های منابع انسانی (cat_id=57)

منبع: فایل‌های `.tybot` که کاربر مستقیماً از پنل Teamyar export و ارسال کرد (نه سینک زنده — این بات‌ها در `TeamyarBotsLiveRegistry.json` ثبت نشده‌اند چون آن فایل مخصوص خروجی `sync_teamyar_bot_registry.ps1` است). سورس کامل/دقیق هرکدام روی دیسک این ریپو نیست؛ منبع صادق فعلی همان فایل‌های اصلی `command_<id>.tybot` کاربر است.

| ID | نام | run_path | خلاصه |
|----|-----|----------|-------|
| 379 | Bot Personel Daily Request OverTime | `2/hr_daily_request` | فرم/گزارش درخواست‌های اضافه‌کاری پرسنل (`hr_overtime_request`)؛ وضعیت پیش‌نویس/تایید/رد |
| 380 | Personnel Mission With Floating Shift | `2/mission_float_shift` | مقایسهٔ ساعت ماموریت سیستمی (`hr_work_time.MISSION_*`) با ساعت ثبت‌شدهٔ دستی (`hr_ext_time` type=3) برای شیفت‌های شناور |
| 382 | SammaryOfInfoPersonnel | `2/sammary_of_info_personnel` | خلاصهٔ کامل اطلاعات پرسنلی (دموگرافیک/تماس/تحصیلات/بیمه/تاریخ استخدام) — کوئری منبع هنگام استخراج truncate شد، ستون‌های دقیق تایید نشده |
| 384 | Sum Workdays And Sales Params (v1، پارامتر هاردکد) | `2/workdays_params_salary` | تجمیع پرداختی فیش حقوقی (`hr_payslip`+`hr_payslip_payment_detail`) به تفکیک پرسنل/واحد/گروه استخدام؛ نام پارامترها هاردکد در کد |
| 385 | Sum Workdays And Sales Params (v2، config‌پذیر) | `2/workdays_params_salary_2` | همان ۳۸۴ ولی نام پارامترها از `bot_config` خوانده می‌شود |
| 444 | Hr Birthday And History | `2/hr_birthday_history` | تولد (`profile_user_info.BIRTHDAY` + `report_dimdate.JTMONTH`) و سابقهٔ کار پرسنل |
| 474 | [report] گزارش مجموع تاخیر پرسنل (TotalPersonnelCompensation) | `2/total_personnel_compensation` | مجموع تاخیر (`hr_work_time.ABSENCE`/`FINAL_ABSENCE`) به تفکیک پرسنل/واحد در بازهٔ زمانی |
| 476 | گزارش جامع حضور و غیاب (ComprehensiveAttendanceReport) | `2/comprehensive_attendance_report` | جامع‌ترین گزارش حضور: حاضر/غایب/مرخصی تایید‌شده-نشده/ماموریت تایید‌شده-نشده/ورود قبل-راس-بعد از ساعت ۸ |
| 504 | Bot Total Salary | `2/total_salary_2` | حقوق کل هر پرسنل (خالص/اضافات/کسورات) با drill-down به پارامترهای فردی هر فیش |
| 505 | بات بررسی فرزندان تحت تکفل (InsuranceReport) | `2/insurance_bot` | هشدار فرزندان دختر تحت تکفل (`CRM_PERSON_FAMILY`) که به سن قطع بیمهٔ تکمیلی (۱۸ سال) نزدیک می‌شوند |
| 557 | [report]حقوق و دستمزد (SalariesAndWagesTotal) | `2/salaries_and_wages_total` | جمع حقوق و دستمزد ماهانه به تفکیک واحد/گروه استخدام (منبع اصلی SQL بخش حقوق در `hr_dashboard_report_bot.lua`) |

**هشدار staleness مهم:** `docs/context/TeamyarAllBotsIndex.json` (سینک ۱۴۰۵/۰۵/۰۳) برای همین شناسه‌ها (۳۸۲، ۳۸۵، ۴۴۴، ۵۰۵) نام‌های کاملاً متفاوت و نامرتبط با فروش/موجودی نشان می‌دهد (مثلاً ۳۸۲=«فروش کلی به ازای مراکز فروش»، ۵۰۵=«فروش به ازای برترین مشتریان»). یعنی این شناسه‌ها روی سرور دوباره تخصیص/بازسازی شده‌اند و آن ایندکس محلی برای این بازه شناسه دیگر قابل‌اعتماد نیست — قبل از تکیه به `TeamyarAllBotsIndex.json` برای هر بات با id بین ۲۰۰ تا ۶۰۰، حتماً یک‌بار دیگر از سرور سینک شود.

## Runtime API

```lua
local input = teamyar.get_input() or {}
db.query({ query = "...", params = {} })
while db.query_fetch(record) do end
db.query_free()
teamyar.write_result(json.encode({ ok = true }))
```

## Output

JSON: `{ ok, error?, ... }` with Persian errors.
HTML: `myArray` + `string.format(Res_chart, json.encode(myArray))`.

## Helpers (copy from existing bots)

- `fmt_jalali_datetime(col)` â€” `open_tasks_steps_json_bot.lua`
- `format_duration(filetime_diff)` â€” same file
- `fetch_rows(query, params)` â€” `task_steps_json_bot.lua`

## Schema

Bot tables: `docs/context/BotSchema.md`.
Other tables: `db_schema_json_bot.lua` â€” never load `DatabaseSchema.md`.

## Live Registry (Teamyar production bots)

`docs/context/TeamyarBotsLiveRegistry.json` â€” synced from `/bot/command/view?id={id}`.

Use when user says **Â«Ø´Ø¨ÛŒÙ‡ Ø¨Ø§Øª X Ø¨Ø³Ø§Ø²Â»** or gives a view URL:

1. Read registry entry by `id` (or sync first)
2. Open `local_src` and copy structure/patterns
3. Deploy new bot with `scripts/deploy_teamyar_bot.ps1`

| id | name | local_src | run_url |
|----|------|-----------|---------|
| 933 | Ø¨Ø§Øª Ù‡Ø§ | `bot_commands_json_bot.lua` | `/bot/run/258/getallbots` |
| 942 | Ù‡Ø²ÛŒÙ†Ù‡ Ø±Ø³ÛŒØ¯ Ø®Ø¯Ù…Ø§Øª | `service_receipt_cost_json_bot.lua` | `/bot/run/258/service_receipt_cost` |
| 943 | Ú¯Ø²Ø§Ø±Ø´ ØªØ¬Ù…ÛŒØ¹ÛŒ Ù‡Ø²ÛŒÙ†Ù‡ Ø±Ø³ÛŒØ¯Ù‡Ø§ | `service_receipt_cost_period_json_bot.lua` | `/bot/run/258/service_receipt_cost_period` |
| 944 | Ø§Ø±Ø²ÛŒØ§Ø¨ÛŒ Ø¹Ù…Ù„Ú©Ø±Ø¯ ÙØ±ÙˆØ´ Ø§Ú©Ø³Ø³ÙˆØ±ÛŒ Ù…ÙˆØ¨Ø§ÛŒÙ„ | `sales_accessory_volume_performance_report_bot.lua` | `/bot/run/258/sales_accessory_volume_performance` |
| 945 | عناوین تکراری فاکتور فروش | `sales_invoice_title_duplicates_report_bot.lua` | `/bot/run/258/sales_invoice_title_duplicates` |
| 965 | فهرست لیست‌های قیمت فروش | `sales_price_list_report_bot.lua` | `/bot/run/258/sales_price_list_report` |
| 927 | خلاصه اقدام با آی دی | `EghdamPerId_bot.lua` | `/bot/run/258/EghdamPerId` |
| 928 | آنالیز مراحل اقدام های باز | `EghdamBazAnalyze_bot.lua` | `/bot/run/258/EghdamBazAnalyze` |
| 1023 | تراز آزمایشی چهارستونی | `trial_balance_report_bot.lua` | `/bot/run/258/trial_balance_report` |
| 585 (cat_id=79) | DBSchema | `DBSchema_bot.lua` | `/bot/run/443/DBSchema` |
| 586 (cat_id=79) | تعداد اقدام‌ها به تفکیک رده | `action_count_by_category_report_bot.lua` | `/bot/run/443/action_count_by_category_report` |
| 587 (cat_id=79) | getallbots — فهرست کامل بات‌ها (id/name/description/source_code/run_count/disabled/open_source/source_version)، رده «آنالیزور بات»، خروجی JSON | `getallbots_bot.lua` | `/bot/run/443/getallbots` |
| 569 (cat_id=79) | Factor Seteelment By Selection (تسویه گروهی، منبع اصلی) | `set_by_select_bot.lua` | `/bot/run/2/set_by_select` |
| 588 (cat_id=79) | تسویه اتوماتیک گروهی (کپی بات ۵۶۹ — پیوست/کانفیگ هنوز دستی نصب نشده) | `sales_settlement_group_auto_report_bot.lua` | `/bot/run/443/sales_settlement_group_auto` |
| 582 | تسویه خودکار (بدون UI/پیوست، بر اساس کانفیگ بات؛ `max_execute_time` نامشخص، منبع اصلی — دست‌نخورده نگه داشته شود، بات ۶۱۲ کپی این بات **نیست**) | (سورس محلی نداریم — کد از کاربر دریافت شد، فایل محلی مربوطه ساخته نشده تا 582 دست‌نخورده بماند) | نامشخص |
| 612 | تسویه گروهی — نسخه صف‌بندی‌شده (کپی بات ۵۶۹/۵۸۸، نه ۵۸۲؛ ۱۴۰۵/۰۵/۳۱ — اصلاح یک برداشت اشتباه قبلی که ۶۱۲ را کپی ۵۸۲ فرض کرده بود). `command.lua`/`data.txt`/`mySqlQuery.txt` عیناً از بات ۵۶۹ (export زنده `command_569.tybot` تأیید شد؛ `max_execute_time=100` ثانیه در آن export) — فیلتر/کوئری دست‌نخورده. تنها `data.js`+`data.css` تغییر کرده: (۱) صف انتخاب چندصفحه‌ای — نسخه‌ی قبلی چک‌باکس‌ها را فقط از DOM صفحه‌ی جاری می‌خواند و با ورق‌زدن صفحه (هر صفحه ۲۰ ردیف) پاک می‌شد؛ حالا یک `Set` سراسری (`selectedIds`) انتخاب را بین صفحات حفظ می‌کند و نشان «صف تسویه: N فاکتور» بالای جدول به‌روز می‌ماند. (۲) «تسویه گروهی» دیگر کل صف را یک‌جا نمی‌فرستد؛ صف را به دسته‌های ۲۰تایی (`SETTLE_BATCH_SIZE`) می‌شکند و پشت‌سرهم به همان endpoint موجود (`type=201`) می‌فرستد — بدون تغییر Lua، چون پاسخ `type=201` از قبل `{ok, fail, details}` برمی‌گرداند. نوار پیشرفت («دسته X از Y») + پاپ‌آپ گزارش پایان کار (موفق/ناموفق/شناسه‌های ناموفق) اضافه شد. **هنوز روی پنل Teamyar دیپلوی نشده — کاربر دستی دیپلوی می‌کند؛ کانفیگ باید دستی مثل ۵۶۹/۵۸۸ ست شود.** | `sales_settlement_selection_queue_report_bot.lua` + `sales_settlement_selection_queue_attachments/` | نامشخص (بعد از دیپلوی دستی تکمیل شود) |
| 589 (cat_id=79) | کاوش ساختار جدول (v2) — کپی جدید از بات ۹۶۶ چون بات ۹۶۶ زیر این SID دیگر در دسترس نبود (view endpoint خروجی خالی/«[جدید]» می‌داد). نسخهٔ فعلی نسبت به بات ۹۶۶ دو Mode اضافه دارد: `mode=rawp` (Query پارامتری با `q`+`params` JSON) و `mode=simulate` (تست دقیق الگوی now_raw→Lua arithmetic→Query که برای پیدا کردن باگ فضای خالی گمشده در بات ۵۹۲ استفاده شد) | `src/schema_probe_json_bot.lua` (دیپلوی‌شده از نسخهٔ patch‌شده در Scratchpad، نه از فایل src بدون تغییر) | `/bot/run/443/schema_probe_v2` |
| 592 (cat_id=79) | داشبورد مدیریتی اقدام‌ها (v01) | `action_management_dashboard_report_bot.lua` | `/bot/run/443/action_mgmt_dashboard` |
| 595 (cat_id=80) | داشبورد فاکتورهای مودیان (بازنویسی بات ۵۷۸ با UI/معماری استاندارد این ریپو؛ رفع باگ تب اصلاحی و پارامتری‌سازی کامل) | `moadian_invoices_dashboard_report_bot.lua` | `/bot/run/443/moadian_invoices_dashboard` |
| 598 (cat_id=80) | صفحه اصلی مودیان[Module] — بازطراحی کامل بات ۵۷۸ (v4، ۱۴۰۵/۰۵/۲۰). **دیگر از get_config/get_attachment/پیوست دستی استفاده نمی‌کند** — بعد از این‌که بارها تأیید شد «پیکربندی» بات هرگز مقدار واقعی ذخیره‌شده ندارد (چه ۵۹۵ چه ۵۹۸) و همین باعث کرش HTTP 500 (روی `count_day` خالی) و عدم بارگذاری تب «ارسالی» می‌شد، کوئری کاملاً خودکفا در Lua جاسازی شد؛ ورودی org_id (پیش‌فرض ۸) / from_date / to_date (شمسی، پیش‌فرض ۳۶۵ روز اخیر) / limit (پیش‌فرض ۵۰۰). کوئری بر مبنای پیوست `query_list_invoice.txt` **بات مرجع فعال ۵۷۴** («ارسال گروهی به سامانه مودیان[Module]») بازسازی شد — نه اتچمنت‌های قدیمی بات ۵۷۸ — با دو اصلاح واقعی که از مقایسه با ۵۷۴ به دست آمد: فیلتر `i.type IN (1,3)` (در اتچمنت‌های ۵۷۸ نبود) و نگاشت وضعیت کامل‌تر شامل کدهای ۱۱۹/۱۲۰/۲۱۹/۲۲۰/۳۱۹/۳۲۰/۴۰۰ (کران بالای هر بازه هم اکنون شامل خود عدد است: `<=120/220/320` نه `<120/220/320`). ظاهر: پالت #16509D + فونت Peyda self-contained، جعبه جستجوی آنی هر تب، کارت‌های KPI (تعداد کل ارسالی/ابطالی/اصلاحی از کوئری COUNT سبک، جدا از کوئری ردیف‌ها)، هدر مرتب‌سازی‌پذیر، Excel فقط روی ردیف‌های فیلترشده. AJAX هر تب (type=1/2/3/4): هم‌زمان $.Teamyar.ajax (۶ ثانیه مهلت) و fetch خام امتحان می‌شوند — کدام‌یک در محیط استقرار واقعی جواب می‌دهد از بیرون قابل پیش‌بینی نبود؛ اگر تا ۲۰ ثانیه هیچ‌کدام جواب ندهند خطا+لینک «تلاش مجدد» (نه گیرکردن دائمی). تأییدشده روی داده زنده: ارسالی=74,238، ابطالی=2,449، اصلاحی=۰ | `moadian_factor_tabs_report_bot.lua` | `/bot/run/2/moadian_index_m_1` |
| 565 (cat_id=79) | آنالیزور بات (اصلی — بدون تغییر). **1405/05/20: یک بازنویسی آزمایشی با ظاهر بات ۵۹۴ روی این بات deploy و سپس توسط کاربر رد شد** («این مربوط به آنلیز بات‌هاست، من داده ماژول اقدام ندادم») و به همین نسخهٔ اصلی برگردانده شد — به‌جایش بات جدید ۵۹۹ ساخته شد (ردیف بعدی). این بات دیگر نباید تغییر ظاهری بگیرد مگر کاربر صریحاً بخواهد | `bot_analyzer_report_bot.lua` | `/bot/run/443/AnalysBot` |
| 599 (cat_id=79) | عملکرد ماژول باتی — ظاهر یک‌به‌یک کپی از بات ۵۹۴ «مرکز فرماندهی باتی» (**استثنای مصوب کاربر از قانون پالت‌رنگ/فونت/Peyda در CLAUDE.md — نگاه کنید به هدر فایل**)؛ دادهٔ بات 565 (آمار اجرا/میانگین‌زمان/هرگز-اجرا-نشده) و بات 594 (دسته/بخش، روند روزانه/ساعتی، جریان رویدادها، drawer) با هم تلفیق شده — **بدون هیچ دادهٔ ماژول اقدام (todo_task)**، فقط bot_command/bot_command_run/bot_history. لینک‌ها طبق الگوی صریح کاربر: `/?page=/bot/index&cat_id=X` (رده)، `/?page=/bot/command/view&id=X&cat_id=Y&tab=0` (بات)، `/bot/run/{run_path}` (اجرا). پرفورمنس: تمام آمار bot_history از یک fetch خام در یک پاس Lua (~2.7 ثانیه؛ نگاه کنید به یادداشت فنی در هدر فایل برای چرایی) | `bot_module_performance_report_bot.lua` | `/bot/run/443/bot_module_performance` |
| 596 (cat_id=79) | ارسال پیامک پیشگام رایان — کپی الگوی بات ۳۹۷ (MeliPayamak Panel SMS Send) با `teamyar.call_url` روی API پیشگام رایان (`POST https://smsapi.pishgamrayan.com/Messages/Send`، مستندات `Guidance-WebService-Pishgamrayan.pdf` v2.2). ورودی‌های اجرا: `to` (شماره یا فهرست جدا با کاما/فاصله)، `text`، `from` (اختیاری - پیش‌فرض از پیکربندی)، `send_date` (اختیاری، ارسال زمان‌بندی‌شده، فرمت شمسی `YYYY/MM/DD HH:MM:SS`). پیکربندی بات (تب «پیکربندی»، الزامی قبل از استفاده): `token` (مقدار هدر `Authorization`)، `sender_number` (شماره فرستنده پیش‌فرض). موفقیت = `statusCode` برابر ۱ یا ۲ (طبق نمونهٔ مستندات)؛ پاسخ خام API هم در خروجی برگردانده می‌شود | `pishgam_sms_send_bot.lua` | `/bot/run/443/pishgam_sms_send` |
| 597 (cat_id=79) | دریافت پیامک پیشگام رایان — کپی الگوی بات ۵۷۰ (SMS API Caller [api])، pull-based با `teamyar.call_url` روی `POST https://smsapi.pishgamrayan.com/Messages/GetMessage` (مستندات همان API؛ سرویس callback/webhook مستند نشده، فقط واکشی صف ورودی). ورودی‌های اجرا: `date_from`، `date_to` (هر دو الزامی، فرمت شمسی `YYYY/MM/DD HH:MM:SS`)، `private_number` (اختیاری - پیش‌فرض از پیکربندی)، `mark_as_read` (اختیاری، پیش‌فرض `true` طبق مستندات). پیکربندی بات: `token` (هدر `Authorization`)، `private_number` (شماره اختصاصی پیش‌فرض). موفقیت = `statusCode==0` | `pishgam_sms_receive_bot.lua` | `/bot/run/443/pishgam_sms_receive` |

```powershell
# Sync bot metadata + optional source pull
$env:TEAMYAR_SID = '...'
.\scripts\sync_teamyar_bot_registry.ps1 -BotId 933 -CatId 69
.\scripts\sync_teamyar_bot_registry.ps1 -BotId 942 -CatId 100
.\scripts\sync_teamyar_bot_registry.ps1 -BotId 943 -CatId 100
.\scripts\sync_teamyar_bot_registry.ps1 -BotId 944 -CatId 100
.\scripts\sync_teamyar_bot_registry.ps1 -BotId 945 -CatId 100

# Run bot with input
  .\scripts\run_teamyar_bot.ps1 -BotId 942 -FormInputJson '{"receipt_no":"250250"}'
  .\scripts\run_teamyar_bot.ps1 -BotId 943 -FormInputJson '{"startDate":"1405-01-01","end_date":"1405-03-31","org_id":"2"}'
  .\scripts\run_teamyar_bot.ps1 -BotId 944 -FormInputJson '{"startDate":"1405-01-01","end_date":"1405-03-31","org_id":"2"}'
  .\scripts\run_teamyar_bot.ps1 -BotId 945
```

View API: `GET https://erp.bimehland.com/bot/command/view?id={id}&cat_id={cat_id}` â†’ JSON in `botCommandViewFunc(...)`.

## Create / Update Bot (curl)

Endpoint: `POST https://erp.bimehland.com/bot/command/update?cat_id={cat_id}&id={id}`

### Create vs Update

| | Create | Update |
|---|--------|--------|
| Query `id` | `0` | Ù‡Ù…Ø§Ù† ID Ø¨Ø±Ú¯Ø´ØªÛŒ Ø§Ø² create (Ù…Ø«Ù„Ø§Ù‹ `941`) |
| Referer `id` | `0` | Ù‡Ù…Ø§Ù† ID |
| Body | Ù‡Ù…Ù‡ ÙÛŒÙ„Ø¯Ù‡Ø§ | **Ù‡Ù…Ø§Ù† body** â€” Ø·Ø¨Ù‚ Ø±ÙˆØ§Ù„ create |
| Ú†Ù‡ Ú†ÛŒØ²ÛŒ Ø¹ÙˆØ¶ Ù…ÛŒâ€ŒØ´ÙˆØ¯ | `name`, `run_path`, `command`, ... | **ÙÙ‚Ø· `command`** (Ú©Ø¯ Lua Ø¬Ø¯ÛŒØ¯) |

- `id` Ø¯Ø± URL = Ø´Ù†Ø§Ø³Ù‡ Ø¨Ø§ØªØ› Ø¯Ø± create ØµÙØ±ØŒ Ø¯Ø± update Ù‡Ù…Ø§Ù† Ø¹Ø¯Ø¯ÛŒ Ú©Ù‡ Ù¾Ø§Ø³Ø® create Ø¨Ø±Ú¯Ø±Ø¯Ø§Ù†Ø¯
- Body Ø¯Ø± update Ø¹ÛŒÙ† create Ø§Ø³ØªØ› nameØŒ run_pathØŒ form Ùˆ Ø¨Ù‚ÛŒÙ‡ Ø«Ø§Ø¨Øª Ù…ÛŒâ€ŒÙ…Ø§Ù†Ù†Ø¯
- Ø¯Ø± update ÙÙ‚Ø· Ù…Ø­ØªÙˆØ§ÛŒ `command` (Ø§Ø³Ú©Ø±ÛŒÙ¾Øª `.lua`) Ø¹ÙˆØ¶ Ù…ÛŒâ€ŒØ´ÙˆØ¯
- Replace `SID` cookie with your active session
- `command` â†’ bot Lua source (inline, not a file path)
- `run_path` â†’ bot identifier/slug (e.g. `my_curl_bot`) â€” **no spaces**
- `result_type` â†’ `1` = HTML | `0` = JSON/text (verified: HTML bots like 945 = 1, JSON bots like 942 = 0)
- `bot_customform` / `bot_config` â†’ JSON form schema for input parameters
- **Success** = HTTP **200** + body = integer (bot ID). **Failure** = anything else

### Response contract (create & update)

```
OK  â†’ HTTP 200  +  body = integer  (Ù‡Ù…Ø§Ù† bot ID)
ERR â†’ Ù‡Ø± Ú†ÛŒØ² Ø¯ÛŒÚ¯Ø± (Ú©Ø¯ ØºÛŒØ± 200ØŒ body Ø®Ø§Ù„ÛŒØŒ JSONØŒ Ù…ØªÙ†ØŒ ...)
```

- Create: body = **ID Ø¨Ø§Øª Ø³Ø§Ø®ØªÙ‡â€ŒØ´Ø¯Ù‡** â€” Ø°Ø®ÛŒØ±Ù‡ Ú©Ù†ÛŒØ¯
- Update: body = **Ù‡Ù…Ø§Ù† bot ID** (Ù…Ø«Ù„Ø§Ù‹ `941`)
- Ø¯Ø± ØºÛŒØ± Ø§ÛŒÙ† ØµÙˆØ±Øª = **Ø®Ø·Ø§** â€” Ø¨Ø§Øª Ø³Ø§Ø®ØªÙ‡/Ø¢Ù¾Ø¯ÛŒØª Ù†Ø´Ø¯Ù‡ ÙØ±Ø¶ Ú©Ù†ÛŒØ¯

Minimal example (create bot in category **69**; note `result_type="1"` = HTML, `"0"` = JSON — the example below uses `0`/JSON, set `1` for an HTML report):

```bash
curl --location 'https://erp.bimehland.com/bot/command/update?cat_id=69&id=0' \
--header 'Cookie: SID=$env:TEAMYAR_SID' \
--header 'Origin: https://erp.bimehland.com' \
--header 'Referer: https://erp.bimehland.com/?page=/bot/command&cat_id=69&id=0' \
--header 'X-Requested-With: XMLHttpRequest' \
--form 'status="1"' \
--form 'name="bot created by curl"' \
--form 'subsystem_value=""' \
--form 'subsystem=""' \
--form 'run_path="my_curl_bot"' \
--form 'not_showing_in_iframe="0"' \
--form 'icon=""' \
--form 'color=""' \
--form 'db_prefix=""' \
--form 'async_run="0"' \
--form 'async_deadline_run="0"' \
--form 'max_execute_time="100"' \
--form 'cache_time_status="0"' \
--form 'cache_time="0"' \
--form 'show_in_portal_menu="0"' \
--form 'public_access="0"' \
--form 'show_in_widget="0"' \
--form 'open_source="0"' \
--form 'categories="69_1"' \
--form 'deleted_details=""' \
--form 'bot_customform="{\"layout\":{\"width_title\":3,\"col\":\"COL-2\",\"seperator\":\"\"},\"info\":[],\"schema\":{},\"default_value\":{}}"' \
--form 'attachments_deleted=""' \
--form 'bot_config="{\"layout\":{\"width_title\":3,\"col\":\"COL-2\",\"seperator\":\"\"},\"info\":[],\"schema\":{},\"default_value\":{}}"' \
--form 'ver="0"' \
--form 'active_version=""' \
--form 'new_version="0"' \
--form 'result_type="0"' \
--form 'description="created via curl"' \
--form 'command="command=write_result(get_input(\"name\"))"' \
--form 'temp_folder_id="0"' \
--form 'document_content=""' \
--form 'temp_folder_id_2="0"' \
--form 'help_content=""'
```

Update example (existing bot `id=941` in category **69**, نوع خروجی **HTML**):

```bash
curl --location 'https://erp.bimehland.com/bot/command/update?cat_id=69&id=941' \
--header 'Cookie: SID=$env:TEAMYAR_SID' \
--header 'Origin: https://erp.bimehland.com' \
--header 'Referer: https://erp.bimehland.com/?page=/bot/command&cat_id=69&id=941' \
--header 'X-Requested-With: XMLHttpRequest' \
--form 'status="1"' \
--form 'name="bot created by curl"' \
--form 'subsystem_value=""' \
--form 'subsystem=""' \
--form 'run_path="my_curl_bot"' \
--form 'not_showing_in_iframe="0"' \
--form 'icon=""' \
--form 'color=""' \
--form 'db_prefix=""' \
--form 'async_run="0"' \
--form 'async_deadline_run="0"' \
--form 'max_execute_time="100"' \
--form 'cache_time_status="0"' \
--form 'cache_time="0"' \
--form 'show_in_portal_menu="0"' \
--form 'public_access="0"' \
--form 'show_in_widget="0"' \
--form 'open_source="0"' \
--form 'categories="69_1"' \
--form 'deleted_details=""' \
--form 'bot_customform="{\"layout\":{\"width_title\":3,\"col\":\"COL-2\",\"seperator\":\"\"},\"info\":[],\"schema\":{},\"default_value\":{}}"' \
--form 'attachments_deleted=""' \
--form 'bot_config="{\"layout\":{\"width_title\":3,\"col\":\"COL-2\",\"seperator\":\"\"},\"info\":[],\"schema\":{},\"default_value\":{}}"' \
--form 'ver="0"' \
--form 'active_version=""' \
--form 'new_version="0"' \
--form 'result_type="0"' \
--form 'description="created via curl"' \
--form 'command="write_result(\"hello from claude tes\")"' \
--form 'temp_folder_id="0"' \
--form 'document_content=""' \
--form 'temp_folder_id_2="0"' \
--form 'help_content=""'
```

| Action | Query `id` | Referer `id` | Body change |
|--------|------------|--------------|-------------|
| Create | `0` | `0` | Ù‡Ù…Ù‡ ÙÛŒÙ„Ø¯Ù‡Ø§ (name, run_path, command, ...) |
| Update | ID Ø§Ø² create (e.g. `941`) | same | **ÙÙ‚Ø· `command`** |

To deploy a bot from `src/*.lua`, put file contents in `command` (create: full deploy; update: same body, new command only).

**Deploy script:** `scripts/deploy_teamyar_bot.ps1` sends `command=<path` (curl reads file **content** into field â€” not `@path` file upload).

**Note:** The minimal `command` example uses `get_input("name")` / `write_result(...)` (Teamyar shorthand). Full bots in `src/` use `teamyar.get_input()` and `teamyar.write_result(...)`.

## Run Bot (curl)

Endpoint: `POST https://erp.bimehland.com/bot/run/{run_id}/{run_path}?ver=0`

Ø§Ø¬Ø±Ø§ÛŒ Ø¨Ø§Øª â€” Ø¨Ø¯ÙˆÙ† bodyØ› ÙÙ‚Ø· header. **Bot ID** Ø¯Ø± Referer Ù…ÛŒâ€ŒØ¢ÛŒØ¯:

- Referer: `...?page=/bot/command/view&id={bot_id}&cat_id={cat_id}&tab=0`
- URL path: `{run_path}` Ù‡Ù…Ø§Ù† slug Ø¨Ø§Øª (Ù…Ø«Ù„Ø§Ù‹ `botanalytics`)
- `{run_id}` â€” Ø´Ù†Ø§Ø³Ù‡ Ø¯Ø± Ù…Ø³ÛŒØ± URL (Ù…Ø«Ù„Ø§Ù‹ `258` Ø¯Ø± Ù†Ù…ÙˆÙ†Ù‡ Ø²ÛŒØ±)

```bash
curl --location --request POST 'https://erp.bimehland.com/bot/run/258/botanalytics?ver=0' \
--header 'Cookie: SID=$env:TEAMYAR_SID' \
--header 'Origin: https://erp.bimehland.com' \
--header 'Referer: https://erp.bimehland.com/?page=/bot/command/view&id=934&cat_id=69&tab=0' \
--header 'X-Requested-With: XMLHttpRequest'
```

| Part | Example | Meaning |
|------|---------|---------|
| Referer `id` | `934` | bot command ID |
| Referer `cat_id` | `69` | category |
| URL `run_path` | `botanalytics` | `run_path` from bot settings |
| URL `{run_id}` | `258` | path segment before run_path |
| `ver` | `0` | bot version |

Replace `SID` cookie with your active session.

### Response contract (run)

```
OK  â†’ HTTP 200  +  body = Ø®Ø±ÙˆØ¬ÛŒ Ø¨Ø§Øª (Ù‡Ù…Ø§Ù† Ù†ÙˆØ¹ÛŒ Ú©Ù‡ Ø¯Ø± create ØªÙ†Ø¸ÛŒÙ… Ø´Ø¯: HTML / JSON / text)
ERR â†’ Ù‡Ø± Ú†ÛŒØ² Ø¯ÛŒÚ¯Ø± (Ú©Ø¯ ØºÛŒØ± 200ØŒ Ø®Ø·Ø§ÛŒ compileØŒ abortedØŒ ...)
```

- `result_type` Ø¯Ø± create ØªØ¹ÛŒÛŒÙ† Ù…ÛŒâ€ŒÚ©Ù†Ø¯ body Ú†Ù‡ Ø´Ú©Ù„ÛŒ Ø¨Ø§Ø´Ø¯ (`1` = HTML, `0` = JSON/text)
- body Ù¾Ø§Ø³Ø® Ø¨Ø§ÛŒØ¯ Ù‡Ù…Ø§Ù† Ø®Ø±ÙˆØ¬ÛŒ `teamyar.write_result(...)` Ø¨Ø§Øª Ø¨Ø§Ø´Ø¯
- Ø¯Ø± ØºÛŒØ± Ø§ÛŒÙ† ØµÙˆØ±Øª = **Ø®Ø·Ø§**

## Deploy workflow (agent)

### Create (Ø¨Ø³Ø§Ø² Ø¨Ø§Øª)

When the user asks to **create/build a bot** and Lua is final:

1. Write `src/{domain}_{purpose}_{json|report}_bot.lua`
2. Add catalog row
3. Deploy with `-BotId 0` â€” set `name` (Persian), `run_path` (no spaces), `command` (full `.lua`)
4. Save returned **bot ID** from response (HTTP 200 + integer)

```powershell
$env:TEAMYAR_SID = '28653|...'
.\scripts\deploy_teamyar_bot.ps1 `
  -ScriptPath 'src\warranty_branch_expense_detail_report_bot.lua' `
  -Name 'Ú¯Ø²Ø§Ø±Ø´ Ø±ÛŒØ² Ù‡Ø²ÛŒÙ†Ù‡ Ø´Ø¹Ø¨Ø§Øª Ú¯Ø§Ø±Ø§Ù†ØªÛŒ' `
  -RunPath 'warranty_branch_expense_detail_report' `
  -BotId 0
```

### Update (Ø§ØµÙ„Ø§Ø­/Ø¢Ù¾Ø¯ÛŒØª Ø¨Ø§Øª Ù…ÙˆØ¬ÙˆØ¯)

When fixing or updating an **existing** bot:

1. Edit `src/*.lua` locally
2. Deploy with `-BotId {id}` â€” Ù‡Ù…Ø§Ù† ID Ø¯Ø±ÛŒØ§ÙØªÛŒ Ø§Ø² create
3. Body Ù…Ø«Ù„ createØ› **ÙÙ‚Ø· `command`** (Ú©Ø¯ Ø¬Ø¯ÛŒØ¯) Ø¹ÙˆØ¶ Ù…ÛŒâ€ŒØ´ÙˆØ¯ â€” name Ùˆ run_path Ø«Ø§Ø¨Øª
4. Success = HTTP 200 + integer (same bot ID)

```powershell
.\scripts\deploy_teamyar_bot.ps1 `
  -ScriptPath 'src\warranty_branch_expense_detail_report_bot.lua' `
  -Name 'Ú¯Ø²Ø§Ø±Ø´ Ø±ÛŒØ² Ù‡Ø²ÛŒÙ†Ù‡ Ø´Ø¹Ø¨Ø§Øª Ú¯Ø§Ø±Ø§Ù†ØªÛŒ' `
  -RunPath 'warranty_branch_expense_detail_report' `
  -BotId 941
```

| Field | Create | Update |
|-------|--------|--------|
| Query `id` | `0` | saved bot ID |
| `name` | Persian, new | unchanged |
| `run_path` | slug, no spaces | unchanged |
| `command` | full Lua | **new Lua only** |
| Success | HTTP **200** + integer = bot ID | HTTP **200** + integer = same bot ID |
| Failure | Ù‡Ø± Ú†ÛŒØ² Ø¯ÛŒÚ¯Ø± = Ø®Ø·Ø§ | Ù‡Ø± Ú†ÛŒØ² Ø¯ÛŒÚ¯Ø± = Ø®Ø·Ø§ |

