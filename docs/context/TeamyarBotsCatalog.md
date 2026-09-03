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
| `finance_activity_discovery_json_bot.lua` | JSON | `mode` (`all`/`group_members`/`sales_probe`/`purchase_probe`/`accounting_probe`/`dimdate_probe`/`rawp`), `group_id` (default 36390), `from_jdate`/`to_jdate` or `from_raw`/`to_raw` | Discovery-only probe for the finance-unit activity dashboard: group membership (`profile_group_member`+`profile_main`+`admin_user`), sales (`sales_invoice`+`sales_history`), purchase (`purchase_invoice`+`purchase_history`), accounting (`pa_voucher`+`pa_voucher_signs`) — counts + real CONTENT/NOTE samples to prove TYPE/STATUS/SIGN meaning; no ACTIVE/DISABLE user-status column exists on `admin_user`/`profile_main` (confirmed absent, not guessed) |
| `finance_activity_dashboard_v01_bot.lua` (بات ۶۴۴، `run/443/finance_activity_dashboard_v01`، cat_id=79، نسخهٔ ۱.۰) | HTML/JSON | `group_id` (default 36390), `date_from`/`date_to` (Jalali, default fiscal-year-start→today), `format=json` | Finance-unit (group 36390) activity dashboard: per-user×module (sales/purchase/accounting) counts of proven-only operations (create/edit via `USER_CREATE`+`USER_MODIFIED`/`DATE_CREATE`+`DATE_MODIFIED`; cancel/delete/reject via each table's own flag column; accounting confirm via `pa_voucher_signs.SIGN=1`, confirmed against live discovery data — `SIGN=0` is a pending-assignment state, not an event) from one 14-branch `UNION ALL` dataset (`sales_invoice`, `purchase_invoice`, `pa_voucher`, `pa_voucher_signs`), GROUP BY user/module/operation — no per-user query loop. Charts: total-ops bar, per-user stacked bar (sales/purchase/accounting), module-share donut, daily trend bar, operation-type breakdown bar. Drill-down is internal only (date/operation/module/doc no/description) — no external document links (URLs not proven, not guessed). Excludes any active/inactive employee badge — `admin_user.EXPIRATION` was confirmed (by the project user) to be password-expiry, not account status, so it's not used for that. Excludes `sales_history`/`purchase_history.TYPE` breakdowns — confirmed empty for this group's members on live data, not a viable path. Group's own self-membership row in `profile_group_member` (`USER_ID=GROUP_ID`, blank `admin_user.USERNAME`) is filtered out. Persistent banner: activity count ≠ productivity/performance judgment. **استقرار و تأیید زنده (1405/06/12):** ساخته شد با HTTP 200 → شناسهٔ ۶۴۴؛ هر دو مسیر خروجی روی دادهٔ واقعی تست شد — JSON (۷۱۵KB) و HTML (۹۵۶KB، فونت Peyda + دکمهٔ راهنما رندر شد)، بدون خطای Lua و بدون نیاز به ردیف دستی `bot_command_config`. شمارش زندهٔ بازهٔ ۱۴۰۵/۰۱/۰۱ تا ۱۴۰۵/۰۶/۱۲: ۲۰ عضو گروه، حسابداری ۱۲٬۱۹۷ (۷۲.۷٪)، فروش ۳٬۱۵۲ (۱۸.۸٪)، خرید ۱٬۴۳۸ (۸.۶٪). `max_execute_time=300` تنظیم شد چون کوئری `UNION ALL` چهارده‌شاخه است. **دو اصلاح قبل از استقرار:** توالی بایتی «بک‌اسلش+اسلش» در `gsub("</", ...)` با `string.char(92)` جایگزین شد (عامل تأییدشدهٔ HTTP 502 هنگام ذخیره — حافظهٔ `teamyar-escaped-slash-regex-breaks-save`)، و رنگ قرمز صفحهٔ خطا به `#16509D` تغییر کرد طبق پالت اجباری |
| `user_activity_stats_report_bot.lua` | HTML/JSON | `user_name` (required), `org_id` (default 2), `format=json` | User activity in current fiscal year: dialogs (DATE_CREATE), steps, warehouse, invoices, vouchers |
| `timing_report_bot.lua` | HTML | `startDate` | Parameterized HTML report |
| `service_receipt_summary_report_bot.lua` | HTML | `startDate`, `end_date`, `org_id`, `product_code` | Service receipt summary dashboard: KPIs, status distribution, top products, monthly trends, technician performance, recent activity feed |
| `tat_pivot_report_bot.lua` | HTML | â€” | Monthly pivot |
| `tat_pivot_report_3day_bot.lua` | HTML | â€” | Pivot variant |
| `action_count_by_category_report_bot.lua` (bot 586, cat_id=79) | HTML/JSON | `format=json`, `drill_category_id=<id>&format=json` (فهرست اقدام‌های باز یک رده) | تعداد کل اقدام‌ها (`todo_task`) به تفکیک رده (`todo_category` via `tt.CATEGORY_ID`)؛ ستون‌های تعداد کل/باز/بسته + سهم از کل؛ کلیک روی «N باز ▾» فهرست تک‌تک اقدام‌های باز آن رده را زیر همان ردیف باز می‌کند (عنوان/مرحله/مسئول)؛ کلیک روی عنوان هر اقدام، جزئیات آن را از بات «خلاصه اقدام با آی دی» (id=927, `run/258/EghdamPerId`, `task_id`) در تب جدید باز می‌کند؛ بدون فیلتر تاریخ |
| `sales_settlement_group_auto_report_bot.lua` (bot 588, cat_id=79) | HTML | RES-framework (`install_res`/`res_v2`), no `bot_customform` | **کپی بات ۵۶۹** («تسویه گروهی» / `Factor Seteelment By Selection`) با نام «تسویه اتوماتیک گروهی». فهرست فاکتورهای قابل‌تسویه + تسویه تکی/گروهی واقعی روی فاکتورها (`/api/sales/create_settlement`) — بات مالی نویسنده، نه صرفاً گزارشی. وابسته به ۴ پیوست (`src/sales_settlement_group_auto_attachments/`: `mySqlQuery.txt`, `data.txt`, `data.js`, `data.css`) که باید دستی از پنل بات آپلود شوند (endpoint آپلود attachment ناشناخته) + یک نمونه‌ی «پیکربندی» (کد حساب تسویه=۱۰۱۰۰۱۰۰۴، نوع تسویه=نقد، کپی از «تسویه پیش‌فرض» بات ۵۶۹) که باید از تب «پیکربندی» بات ساخته شود |
| `sales_return_settlement_backfill_queue_bot.lua` (bot 639, cat_id=79) | HTML (متن خلاصه) | بدون فرم؛ ثابت‌های بالای فایل: `_INVOICE_TYPE=3`, `_DRY_RUN`, `_ONLY_INVOICE_IDS`, `_FISCAL_YEARS_BACK`, `_AMOUNT_SIGN`, `_SETTLEMENT_KIND` + تب «پیکربندی» (همان اسکیمای بات ۶۲۰) | **کپی بات ۶۲۰** (`sales_settlement_backfill_queue`) برای فاکتورهای **برگشت از فروش** (`sales_invoice.TYPE=3`). بات ۶۲۰ دست‌نخورده ماند. کوئری مبلغ، حلقهٔ زمان‌محور، ادامهٔ خودکار صف و جدول `sales_settlement_permanent_skip` عیناً از ۶۲۰ (همان جدول مشترک — شناسهٔ فاکتور بین همهٔ TYPEها یکتاست). **تفاوت‌های تأییدشده روی دادهٔ زنده (۱۴۰۵/۰۶/۱۱، سازمان ۸):** «نوع تسویه» = **۵ (حساب)** نه ۴ (نقد) — در `sales_invoice_settlement` هر ۱۵۱٬۸۲۳ ردیف `INVOICE_TYPE=1` مقدار `TYPE=4` دارند و هر ۱۳ ردیف `INVOICE_TYPE=3` مقدار `TYPE=5`؛ مبلغ **مثبت** است و کوئری این بات برای هر ۱۳ فاکتور برگشتیِ قبلاً تسویه‌شده دقیقاً همان `PRICEAFTER_DISCOUNT` را می‌دهد (۱۳ از ۱۳). `price` با `string.format("%.0f")` فرستاده می‌شود (نه `tostring` که «157989996.0» می‌داد). فاکتور با مبلغ صفر/نامشخص به API فرستاده نمی‌شود. حالت `_DRY_RUN` و `_ONLY_INVOICE_IDS` برای تست کنترل‌شده + گزارش تشخیصی «چرا این فاکتور در صف نیست». کانفیگ «زرین ۴۰۴» (کد حساب ۱۰۱۰۰۱۰۰۴ = «کیف پول»، شعبه ۸) با `scripts/save_teamyar_bot_config.ps1` ساخته شد. **مسدودکنندهٔ تأییدشدهٔ پلتفرم (۱۴۰۵/۰۶/۱۱): `/api/sales/create_settlement` فاکتور `TYPE=3` را نمی‌پذیرد** و همیشه «نوع/وضعیت عملیات نامعتبر است.» می‌دهد. ماتریس آزمایش با بات موقت ۶۴۱ (`temp_settlement_api_probe`، همه با کد حساب عمداً نامعتبر پس هیچ سندی ثبت نشد): فاکتور ۱۳۸۳۳۳ (TYPE=3) با نوع تسویه ۴ و ۵ → همان خطای نوع/وضعیت؛ فاکتور ۲۷۲۶۵۶ (TYPE=1) با نوع تسویه ۴ و ۵ → «مقادیر وارد شده نامعتبر است - حساب در تسویه». یعنی اعتبارسنجی نوع فاکتور قبل از اعتبارسنجی حساب اجرا می‌شود و فقط TYPE=1 رد می‌شود — ربطی به نوع تسویه، وضعیت (هر ۱۳ فاکتور برگشتیِ تسویه‌شده هم STATUS=2 هستند) یا کانفیگ ندارد. خود پرتال هم برای فاکتور برگشتیِ STATUS=2 فرم صفحه را روی `‎/sales/invoice/update_settlement/{id}` سابمیت می‌کند (نه endpoint خانوادهٔ `/api/…`)، و ماژول فروش (module_id 23) در کل ۱۰ endpoint دارد که هیچ‌کدام تسویهٔ برگشتی نیست. بات فعلاً در `_DRY_RUN=true` قفل است؛ برای فعال شدن یا تیم‌یار باید TYPE=3 را در همین API مجاز کند، یا مسیر سمت مرورگر (سابمیت همان فرم پرتال با نشست خود کاربر) پیاده شود |
| `moadian_invoices_dashboard_report_bot.lua` (bot 595, cat_id=80) | HTML/JSON | `from_date`, `to_date` (شمسی، پیش‌فرض سال مالی فعال)، `org_id` (**پیش‌فرض 8** — نه 2؛ طبق دادهٔ زنده تمام فاکتورهای `moadian_status>0` زیر org_id=8 هستند)، `limit` (پیش‌فرض 500)، `type=1\|2\|3` (AJAX داخلی سه تب)، `type=4`+`fid`+`referenceNumber` (AJAX استعلام یک فاکتور)، `format=json` | داشبورد فاکتورهای ارسالی به سامانهٔ مودیان — سه تب (ارسالی/ابطالی/اصلاحی)، بازنویسی کامل بات ۵۷۸ («صفحه اصلی مودیان[Module]»، cat_id=80) با معماری استاندارد این ریپو (پالت #16509D، فونت Peyda، هدر مرتب‌سازی‌پذیر، تمام‌صفحه/Excel/راهنما). باگ‌های بات مبدأ که اصلاح شدند: تب «اصلاحی» (type=3) در بات مبدأ به‌خاطر `elseif intype==2` تکراری هرگز کوئری درستی نمی‌گرفت؛ شرط وضعیت اصلاحی `moadian_status<20` بود (باید `<320` باشد، الگوی دو تب دیگر). وابستگی به پیوست‌های دستی querySend/queryDelete/queryEdite.txt و به تب «پیکربندی» بات حذف شد — یک کوئری مشترک پارامتری (`build_data_query`/`build_count_query`) جایگزین شد. کدهای `moadian_status` دیده‌شده در دادهٔ زنده که در نگاشت برچسب مستند نیستند (۱۲۰، ۴۰۰) به‌جای «ارسال نشده» به‌صورت «نامشخص (کد N)» نمایش داده می‌شوند و در هیچ‌کدام از سه تب نمی‌آیند — نیاز به تعریف کسب‌وکاری از صاحب فرآیند مودیان دارد |
| `crm_rfm_bot.lua` (بات ۵۰۱ "RFM CRM"، `run/2/crm_rfm`، RES-framework، توسعهٔ زنده روی سرور — همیشه قبل از هر تغییری از live pull/rebase کنید) | HTML | فرم RES: `datef`, `datet`, `org`(6), `crm`(7), `cat`(9), `ctype`(8), `center`(12), `product_cat`(13، جدید)، `sort_key`, `sort_dir`, `monetary_min`, `monetary_max` | تحلیل RFM مشتریان. **۱۴۰۵/۰۶/۱۰: فیلتر «دسته‌بندی محصول» + دکمهٔ «تمام صفحه» اضافه شد.** بررسی زندهٔ schema نشان داد `wh_product` ستون BRAND/CATEGORY ندارد و جداول attribute/descriptive-category تیم‌یار روی این پایگاه‌داده صفر ردیف دارند — تنها دسته‌بندی واقعی، ریشهٔ LEVEL=1 درخت خودِ `wh_product` است (۷ گره؛ به‌طور عملی ۹۹٪ کاتالوگ زیر یک گره «محصول نهایی» است، پس این فیلتر تفکیک‌کنندگی محدودی دارد — کاربر آگاهانه پذیرفت). «برند» طبق تصمیم کاربر اضافه **نشد** (فقط متن آزاد داخل NAME محصول است، نرمال‌سازی‌نشده). فیلتر با همان الگوی org/cat/ctype/center پیاده شد: ACL type=13 جدید + `productCategoryAcl(data)` که `wh_product where LEVEL=1` را کوئری می‌کند، اعمال روی alias `pr` که پیوست `query_list_invoice.txt` از قبل جوین کرده. دکمهٔ «تمام صفحه» طبق قانون این ریپو (toggle کلاس CSS، نه Fullscreen API) در `data.js`/`data.css` این بات پیاده شد. **دیپلوی زنده تأیید شد**: بات `src_command_id` (لینک به `erp.teamyar.com`) داشت که قبل از Save باید detach می‌شد (`src/temp_detach_bot_src_link_bot.lua`، بات موقت ۶۳۶، بعد از استفاده غیرفعال شد)؛ اولین Save باعث drift شناخته‌شدهٔ `run_path` از `2/crm_rfm` به `443/crm_rfm` شد که با همان ابزار (`set_run_path`) فوراً رفع شد. تأیید نهایی روی دادهٔ زنده: ACL دسته‌بندی ۷ ردیف برمی‌گرداند، `type=100` گزارش واقعی اجرا می‌شود، و کوئری SQL فیلترشده روی `pr.PARENT`/EXISTS تست شد (دسته «محصول نهایی» = همان ۷۲۰۷۵ مشتری کل؛ دسته‌های کوچک‌تر مثل «موبایل» عملاً هیچ فروش واقعی زیرشان ثبت نشده). سورس پیوست‌ها در `src/crm_rfm_501_attachments/` نگهداری می‌شود. **۱۴۰۵/۰۶/۱۰ (همان روز، دور دوم): پیش‌فرض `datef` (بدون فیلتر تاریخ کاربر) از «فقط امروز» به «ابتدای سال شمسی جاری تا الان» تغییر کرد** («سبک‌تر» شدن پیش‌فرض طبق درخواست کاربر — نه کل تاریخچه، نه فقط یک روز)؛ تبدیل شمسی/میلادی پویا (`gregorian_to_jalali`/`jalali_to_gregorian`، پورت‌شده از `action_management_dashboard_report_bot.lua`) بالای فایل، داخل `pcall` با fallback ایمن. **کشف جانبی + رفع همان روز:** بات مشترک `2/res_v2` (بات ۳۰۴، پایهٔ RES مشترک ده‌ها بات) یک باگ ساختاری دارد — `install_res.readyParams()` مقدار hardcode ثابت `"443/res_v2"` برمی‌گرداند برای رندر جدول/گزارش، در حالی که همهٔ بات‌های این ریپو (ازجمله همین بات) بوت‌استرپ را روی `"2/res_v2"` صدا می‌زنند؛ چون بات ۳۰۴ فقط یک run_path زنده دارد، این دو هرگز همزمان درست نمی‌شدند — `type=100/101/102` HTTP 500 بدنه‌خالی می‌دادند. کاربر تأیید فیکس مستقیم بات ۳۰۴ را نداد («فعلاً نه، فقط همین دو بات رو رفع کن») — به‌جایش بلافاصله بعد از `readyCodes()` در همین بات (و بات ۶۰۰) تابع `install_res.readyParams` override شد تا همیشه `"2/res_v2"` برگرداند، بدون هیچ تغییری در بات ۳۰۴ (چون `install_res` بعد از `load()` صرفاً یک global جدول داخل محیط Lua خودِ این بات است). تأیید زنده: `type=100` حالا HTML/JS واقعی `$.Teamyar.table()` برمی‌گرداند (نه 500). جزئیات کامل در حافظهٔ session (`teamyar-res-v2-hardcoded-render-path-bug`). **۱۴۰۵/۰۶/۱۰ (دور آخر): فیلتر «دسته‌بندی محصول» بازنویسی شد + فیلتر «برند» اضافه شد.** فیلتر قبلی روی درخت `wh_product` (`pr.PARENT`) بود که بی‌فایده بود (۹۹٪ کاتالوگ زیر یک گره). حالا هر دو روی متن `pr.NAME` کار می‌کنند، با دو فهرست ثابتِ اعتبارسنجی‌شده در خود Lua (`_PRODUCT_CATEGORIES` ۱۷ دسته، `_BRANDS` ۹ برند) که از طریق ACL برگردانده می‌شوند (`type=13` دسته، `type=14` برند) — همان الگوی فهرست ثابت `ctypeAcl`، بدون کوئری به دیتابیس. پوشش: ۸٬۵۶۴ از ۱۲٬۲۳۵ (~۷۰٪). تأیید زنده: بدون فیلتر ۲۷٬۶۵۵ / گوشی موبایل ۱۳٬۷۱۱ / ساعت هوشمند ۱٬۱۱۲ / سامسونگ ۸٬۵۷۱ / اپل ۷۰۰ / گوشی موبایل+سامسونگ ۷٬۴۱۶ (منطق AND درست). **سه تلهٔ مهم:** ۱) الگوی کوتاه فارسی `'%رم%'` کلمات گرم/نرم/فرم را می‌گرفت و شمارش را از ۳۰۲ به ۲۶۶۷ باد می‌کرد — هر الگو قبل از افزودن روی داده شمرده شد؛ ۲) `%` در رشتهٔ **جایگزینِ** `string.gsub` در Lua معنای خاص دارد و `invalid use of '%'` می‌دهد — برای این دو clause از **فرم تابعی** gsub استفاده شد؛ ۳) مقدار `search` ویجت ACL با متن فهرست تطابق نمی‌دهد (حتی تطابق دقیق خالی برمی‌گرداند)، پس اگر فیلتر نتیجه‌ای نداشت کل فهرست برگردانده می‌شود تا دراپ‌داون هرگز خالی نشود. |
**باگ دوم و مهم‌تر، همان روز، بعد از گزارش کاربر «تو لود می‌ماند» حتی بعد از فیکس بالا:** نسخهٔ زندهٔ این بات `acl_selection()` را نداشت (در یکی از دورهای ادیت مستقیم روی سرور گم شده بود) — یعنی هر شش فیلتر ACL (سازمان/رده/نوع مشتری/مرکز درآمد/دسته‌بندی محصول/crm) وقتی کاربر پرشان نمی‌کرد (تقریباً همیشه، خصوصاً همان لحظهٔ اول باز کردن صفحه)، `getData()` را با خطای اجرای بی‌صدا «attempt to index a userdata value» می‌شکستند — همان باگ معروف مستندشده در CLAUDE.md. تشخیص با یک دیسپچ-تایپ دیباگ موقت (`type=997`, حذف‌شده بعد از تأیید). رفع شد با بازگرداندن `acl_selection()` و نرمال‌سازی هر شش فیلد بلافاصله بعد از `getInput()`. **بات ۶۰۰ این باگ را نداشت** (نسخهٔ زندهٔ آن `acl_selection()` دست‌نخورده داشت) |
| `crm_rfm_1_bot.lua` (بات ۶۰۰ "RFM CRM"، کپی زندهٔ بات ۵۰۱، `run/2/crm_rfm_1`، RES-framework) | HTML | همان فرم RES بات ۵۰۱ (`data.txt`): `datef`, `datet`, `org`, `ctype`, `cat` (+ ACL type=6/7/8/9)، `type=100` گزارش / `101` اکسل / `102` پرینت / `10`\|`11` ارسال پیامک تکی/گروهی | تحلیل RFM مشتریان (Recency/Frequency/Monetary/ntile) — **نسخهٔ فعال روی Teamyar**؛ اصلاح جراحی‌شدهٔ `getData()` بات ۵۰۱ (نه بازنویسی کامل — کاربر خواست معماری RES/`queryTools.where` و ظاهر بات مبدأ حفظ شود). پیوست `query_list_invoice.txt` هم باید دستی با نسخهٔ اصلاح‌شده (`scratchpad/query_list_invoice_fixed.txt` در این ریپو) جایگزین شود. **باگ‌های رفع‌شده:** ۱) `datef`/`datet` که نبودنشان بی‌صدا به ۰ (تاریخ صفر سیستم) سقوط می‌کرد و Monetary/اکسل کل تاریخچه را حساب می‌کردند — طبق درخواست کاربر بدون منطق سال مالی، پیش‌فرض ناموجود اکنون «امروز» است (بازهٔ خالی/تقریباً خالی، سیگنال واضح، نه کل تاریخچهٔ گمراه‌کننده)؛ ۲) `f_nummber`/`m_nummber` هر دو از `cdata.rnumber` می‌خواندند (کپی/پیست) — وزن F/M همیشه نادیده گرفته می‌شد، اصلاح شد هرکدام فیلد خودش؛ ۳) فیلتر `cat` به alias نامعتبر `c.id` ارجاع می‌داد (کد مرده، با خطا می‌شکست) — اصلاح به `p.id`؛ ۴) فیلتر `ctype` به `ui.USER_TYPE` ارجاع می‌داد بدون join به `profile_user_info` (کد مرده) — `LEFT JOIN profile_user_info ui ON ui.id = p.REFFERE_ID` اضافه شد؛ ۵) ورودی/فیلتر تکراری `crm` (کپی دقیق `ctype`، در `data.txt` هم تعریف نشده بود) حذف شد. `queryTools.where`/`{{whereInvoice}}` عمداً دست‌نخورده ماند: آن placeholder روی نتیجهٔ نهایی تجمیع‌شده اعمال می‌شود که ستون‌های `ORG_ID`/`USER_TYPE` در آن دید نیستند — org/ctype/cat باید داخل CTE `crm_factor` فیلتر شوند (همان‌جایی که بات مبدأ برای `org` هم درست همین کار را می‌کرد). رنگ سبز/آبی/قرمز/خاکستری برچسب‌های سگمنت در پیوست SQL هنوز طبق پالت الزامی این ریپو (#16509D) اصلاح نشده — تغییر جداگانه لازم است. یک بازنویسی کامل جایگزین (بدون RES/attachment، native `bot_customform`) هم در `crm_rfm_report_bot.lua` هست ولی مستقر نشده — کاربر معماری RES را ترجیح داد. **ظاهر:** پیوست‌های اختصاصی `data.css`/`data.js` (در `scratchpad/data_css_bot600.css` و `scratchpad/data_js_bot600.js` این ریپو، هنوز آپلود نشده) — فونت Peyda + پالت #16509D + دکمه راهنما، اسکوپ‌شده به `section[data-name="crm_rfm_1"]`؛ جدول واقعی از ویجت هسته‌ای پلتفرم `$.Teamyar.table()` می‌آید که قابل ری‌استایل نیست (نه مرتب‌سازی ستون‌ها). **۱۴۰۵/۰۶/۱۰: رفع باگ res_v2 (بدون دست‌زدن به بات ۳۰۴)** — همان override که در بات ۵۰۱ توضیح داده شد (`install_res.readyParams` بعد از `readyCodes()` به `"2/res_v2"` ثابت شد)، عیناً اینجا هم اضافه شد؛ `type=100` تأیید شد HTML/JS واقعی برمی‌گرداند نه HTTP 500. جزئیات در `teamyar-res-v2-hardcoded-render-path-bug` (حافظهٔ session) |
| `trial_balance_report_bot.lua` (bot 1023) | HTML/JSON | `from_date`, `to_date`, `org_id` (default 2), `account_code`, `show_zero=1`, `drill_account_id` (+format=json), `format=json` | تراز آزمایشی چهارستونی: گردش بدهکار/بستانکار دوره + مانده بدهکار/بستانکار. پیش‌فرض بازه = سال مالی جاری تا امروز. **مانده به بازه سال مالیِ حاویِ `to_date` محدود می‌شود** (نه کل تاریخچه دفاتر) چون هر سال با سند افتتاحیه باز می‌شود؛ کوئری از سمت `pa_voucher` رانده می‌شود (ایندکس `IDX6(ORG_ID,DELETED,RUN_DATE,STATUS,TYPE)`) نه `pa_voucher_record` (۱۵ میلیون ردیف بدون ایندکس تاریخ) — تغییر ندهید بدون تست کارایی. برای حساب‌های کنترلی بدون زیرحساب pa_account (FORCE_CLIENT/FORCE_FLOATING=1، مثل «حسابهای دریافتنی تجاری») دکمه «تفصیلی ▾» یک سطح پایین‌تر (ریز مشتریان via CLIENT_ID) را با `drill_account_id` (drill-down مشابه sales_price_list) نشان می‌دهد؛ کلیک روی کد حساب هم زیرمجموعه‌های واقعی pa_account (بر اساس پیشوند کد) را فیلتر می‌کند |
| `hr_dashboard_report_bot.lua` (جدید، هنوز مستقر نشده) | HTML/JSON | `org_id` (اختیاری)، `from_date`/`to_date`/`months` (FILETIME عددی، پیش‌فرض ۶ ماه اخیر)، `format=json` | داشبورد تجمیعی منابع انسانی: KPIهای نیروی فعال/استخدام جدید/متوسط سابقه/خروج تخمینی، ترکیب سازمانی، روند ماهانهٔ استخدام/حضور و تاخیر/اضافه‌کاری/حقوق و دستمزد، و هشدار تولد/قطع بیمهٔ فرزندان. کوئری‌های آن مستقیماً روی جداول HR نوشته شده (نه فراخوانی بات‌های دیگر) و الگوی هر بخش از کوئری واقعی یکی از ۱۱ بات جدول زیر کپی/تایید شده. **محدودیت شناخته‌شده:** ترکیب جنسیتی/تحصیلات/تاهل (که در بات ۳۸۲ دیده می‌شود) عمداً اضافه نشده چون ستون منبع واقعی‌اش هنگام استخراج truncate و تایید نشد — نیازمند بررسی db_schema قبل از افزودن |
| `sales_revenue_center_dashboard_report_bot.lua` (بات ۶۰۹، `run/443/sales_revenue_center_dashboard`) | HTML/JSON | `channel` (`""`\|`b2b`\|`b2c`\|`other`)، `date_from`/`date_to` (شمسی، پیش‌فرض بازه = ابتدای سال مالی جاری تا امروز — **هر دو سر بازه از فیلتر کاربر خوانده و همیشه اعمال می‌شوند**، برخلاف `crm_geo_sales_dashboard_bot.lua`)، `center` (نام مرکز درآمد، اختیاری)، `format=json`؛ AJAX داخلی: `action=product_invoices`+`product_code`، `action=customer_invoices`+`crm_id` | داشبورد فروش محور (نه CRM/جغرافیا) به تفکیک **مرکز درآمد** فاکتور (`sales_invoice.SALES_CENTER` → `pa_center.NAME`) — خواهر `crm_geo_sales_dashboard_bot.lua`: فرمول مبلغ فاکتور (`INVOICE_AMOUNT_JOIN`) و Rule تفکیک B2B/B2C (LIKE «همکار»/«مصرف» روی نام مرکز درآمد) عیناً از آن به ارث رسیده تا اعداد دو بات ناسازگار نشوند. شامل: KPI فروش، نمودار میله‌ای/Donut/Combo فروش به تفکیک مرکز درآمد (کلیک = فیلتر داشبورد به آن مرکز)، نمودار میله‌ای قابل‌کلیک پرفروش‌ترین/کم‌فروش‌ترین کالا (کلیک = فهرست فاکتورهای همان کالا در Modal)، و ۱۰ مشتری برتر B2B و ۱۰ مشتری برتر B2C در دو جدول کنار هم — یعنی مشتریانی که بیشترین مبلغ فروش را در بازهٔ تاریخ فعال داشته‌اند (همیشه هر دو جدول نمایش داده می‌شوند، مستقل از تب B2B/B2C فعال — فقط بازهٔ تاریخ/مرکز درآمد روی آن‌ها اثر دارد). تب‌های «کل فروش/B2B/B2C/سایر» طبق الگوی `render_channel_tabs` همان بات خواهر. لوگو ۱۴۰ (نسخهٔ White) + فونت Peyda + پالت #16509D طبق الزام CLAUDE.md برای بات‌های HTML جدید. **دیپلوی و روی دادهٔ زنده تأیید شد (1405/05/26)**: مبلغ کل فروش/تعداد فاکتور/تعداد مشتری/۴ مرکز درآمد فعال/پرفروش‌ترین کالا/جدول‌های ۱۰ مشتری برتر همگی با دادهٔ واقعی رندر شدند. **باگ بحرانی کشف و رفع شد حین تست همین بات (ر.ک. یادداشت `build_channel_clause` در سورس و بخش «محدودیت پلتفرم» در CLAUDE.md): پارامتری‌کردن `LIKE ?` در لایهٔ `db.query` این پلتفرم بی‌صدا شکست می‌خورد** (پارامتر رسیده نادیده گرفته می‌شود، «sql error» عمومی برمی‌گردد) — با تست ایزوله روی بات ۵۸۹ (schema_probe_v2) تأیید شد: `WHERE col = ?` کار می‌کند، `WHERE col LIKE ?` نه. در این بات با Literal کردن دو ثابت Hardcode (`CHANNEL_B2B_LIKE`/`CHANNEL_B2C_LIKE`، هرگز از ورودی کاربر نیستند — بدون ریسک Injection) به‌جای Parameter رفع شد. **آپدیت (1405/05/26 شب، بعد از گزارش کاربر روی بات ۶۰۴): `crm_geo_sales_dashboard_bot.lua` واقعاً همین باگ را داشت** (کاربر حین تست تب B2B با `sql error` مواجه شد — دقیقاً طبق پیش‌بینی) — با همان تکنیک (Literal به‌جای Param) در همان فایل رفع و مجدداً روی بات ۶۰۴ دیپلوی و با `channel=b2b` زنده تأیید شد. حین همین رفع، دو مشکل دیگر هم روی بات ۶۰۴ کشف/رفع شد (و پیشگیرانه در این بات هم اعمال شد، چون هر دو الگوی مشترک بین دو بات خواهرند): ۱) **لینک «مشاهده CRM» روی سرور خراب شده بود** — رشتهٔ Literal `"&section=2"` هنگام ذخیرهٔ command توسط Teamyar به `"§ion=2"` تبدیل شده بود (Decode حریصانهٔ `&sect` به Entity `§`، همان خانوادهٔ Quirk escape_html) — رفع با Concatenation (`"&" .. "section=2"`)؛ ۲) **دکمهٔ «تمام صفحه» روی موبایل/iframe اسکرول نمی‌شد** — چون متکی به `Element.requestFullscreen()` واقعی مرورگر بود که رفتارش روی Android Chrome/iframe غیرقابل‌اتکا است؛ با یک toggle کلاس CSS خالص (`position:fixed` + `overflow-y:auto`، بدون Fullscreen API) جایگزین شد. هر دو در این بات هم پیشگیرانه اعمال شدند. |
| `warehouse_issue_bulk_signoff_report_bot.lua` (بات ۶۴۰، `run/443/wh_issue_bulk_signoff`) | HTML/JSON | `org_id` (پیش‌فرض **8** — تمام حواله‌های پیش‌نویس فروش روی دادهٔ زنده زیر همین شعبه‌اند)، `date_from`/`date_to` (شمسی، پیش‌فرض = ابتدای سال مالی جاری تا امروز، از `report_dimdate`)، `stage` (`0`=پیش‌نویس پیش‌فرض | `1`=ثبت تعدادی | `all`)، `search`، `format=json` | **بات نویسنده روی انبار — نه گزارشی.** حواله‌های خروج (`wh_operation.OPERATION_TYPE=2`, `MODULE_ID=23`) متصل به فاکتور فروش را که در مرحلهٔ «پیش‌نویس» یا «ثبت تعدادی» مانده‌اند فهرست می‌کند و دو عملیات گروهی می‌دهد: **ثبت تعدادی** (status ۰→۱) و **ثبت حسابداری/ریالی** (۱→۲). چرخهٔ وضعیت از سورس زندهٔ صفحهٔ `/warehouse/add_operation/view/<op_id>` استخراج شد (کامنت‌های خود Teamyar): `0`=پیش‌نویس، `1`=ثبت تعدادی، `2`=ثبت حسابداری، `3`=تثبیت. موجودی انبار در `status>=1` کسر می‌شود؛ `2` لایهٔ سند حسابداری است. **معماری: اجرا سمت کلاینت.** هیچ endpoint از خانوادهٔ `/api/...` برای این دو عمل وجود ندارد (کل ۱۰ endpoint ماژول فروش + هر ۳۶۲ بات زندهٔ این نصب بررسی شد — هیچ‌کدام روی انبار نمی‌نویسد)؛ تنها مسیر واقعی همان دو URL پرتالی است که خود صفحهٔ حواله صدا می‌زند: `GET /warehouse/operation/change_status/?operation_id=N&status=1` و `GET /warehouse/operation/sign_riali/?operation_id=N&json=1&flag_check=1|0`. JS همین صفحه (هم‌مبدأ، با نشست خود کاربر) آن‌ها را ترتیبی صدا می‌زند، پس مجوزهای واقعی کاربر (`perm_sign_number`/`perm_admin`) توسط پلتفرم اعمال و عملیات به نام همان کاربر ثبت می‌شود — نه با SID جاسازی‌شده. **قرارداد پاسخ (عیناً منطق پرتال):** بدنهٔ خالی=موفق؛ برای `sign_riali` آرایهٔ JSON غیرخالی = تداخل کسر انباری ⇒ تکرار با `flag_check=0`؛ هر متن غیرخالی دیگر = پیام خطا. **`ignore_temp_serial` عمداً فرستاده نمی‌شود** — در پرتال این پرچم فقط بعد از دیالوگ صریح «سریال‌های موقت حذف خواهند شد» ست می‌شود، پس چنین حواله‌ای «نیازمند بررسی دستی» علامت می‌خورد به‌جای حذف خودکار سریال. سقف فهرست `MAX_ROWS=5000` (هرگز بی‌صدا — در نوار هشدار گزارش می‌شود). لوگو ۱۴۰ White + فونت Peyda + پالت #16509D + هدر مرتب‌سازی‌پذیر + تمام‌صفحه (toggle کلاس CSS) + Excel + راهنما. الگوی ادعای ریشه (`data-wb-bound`) و event delegation طبق `teamyar-bot-widget-multi-instance`. **تأیید زنده (1405/06/11):** JSON در ۳.۳ ثانیه، HTML در ۲.۵ ثانیه با ۴۰۱۷ ردیف؛ شمارش زنده: پیش‌نویس ۴٬۰۱۷ / ثبت‌تعدادی‌شده ۳۸٬۷۸۳ (سال مالی جاری). رفتار UI (مرتب‌سازی، راهنما، تمام‌صفحه، فیلتر واجدشرایطی، حلقهٔ ترتیبی، مسیر دومرحله‌ای `flag_check`) با fetch شبیه‌سازی‌شده در مرورگر واقعی تست شد. **تست زندهٔ نیمه‌کامل (1405/06/11):** سه فراخوان واقعی `change_status?status=1` اجرا شد. حوالهٔ ۲۷۴۵۴۰ (۱۴۰۵/۰۶/۰۲) → «تاریخ عملیات در بازه سال مالی نمیباشد»؛ حوالهٔ ۲۷۱۴۹۴ (۱۴۰۴/۰۱/۱۹) → «لطفا موجودی کالا را چک نمایید.&lt;br&gt;01000011 _ ...». **هر دو مورد در DB تأیید شد که هیچ تغییری ندادند** (`OPERATION_STATUS` و `MODIFY_DATE` دست‌نخورده) — یعنی endpoint/پارامترها/قرارداد پاسخ درست است و مسیر خطا با پیام واقعی پلتفرم کار می‌کند؛ **مسیر موفقیت هنوز تأیید نشده.** دو یافتهٔ مهم از همین تست: (۱) **پیام‌های خطا HTML-escape شده برمی‌گردند** (`&lt;br&gt;` نه `<br>`) — همان کاری که خود پرتال با `replaceAll("&lt;br&gt;","<br>")` می‌کند؛ `cleanMessage` با یک `decodeEntities` (textarea) اصلاح شد و با همان رشته‌های واقعی زنده تست شد. (۲) رد شدن روی تاریخ ۱۴۰۵ ولی عبور روی ۱۴۰۴ نشان می‌دهد بررسی سال مالی به **دورهٔ مالی فعال نشست** گره خورده، نه به داده — روی داده، حوالهٔ ۱۴۰۵/۰۶/۰۲ داخل سال مالی شعبه ۸ (۱۴۰۴/۱۲/۲۹ تا ۱۴۰۵/۱۲/۲۹) است و ۶۹۹ حوالهٔ ۱۴۰۵/۰۶ همین حالا در وضعیت ۱ هستند. هر دو کلاس خطا در «راهنما»ی بات مستند شد. **نسخهٔ ۲ (1405/06/11 شب) — بعد از گزارش کاربر «همه ناموفق»:** کاربر روی ۶۶ ردیف اجرا کرد و ۰ موفق گرفت. علت **باگ بات نبود**: تیم‌یار موجودی را **در تاریخ خودِ حواله** می‌سنجد، نه امروز (تأیید ایزوله: حوالهٔ ۲۷۱۴۹۴ موجودی امروزش ۱۲ بود ولی در تاریخ خودش ۰ — و پلتفرم دقیقاً همان را رد کرد؛ حوالهٔ ۲۷۳۴۱۶: امروز ۱۵۹۴، در تاریخ خودش ۱۱۳). با همان فرمول روی دادهٔ زنده: **۹۵ از ۱۰۰ حوالهٔ پیش‌نویس اخیر در تاریخ خودشان کسری موجودی دارند**. تغییرات v2: (۱) **تقویم شمسی خوداتکا** برای هر دو فیلد تاریخ (فیلد readonly، بدون وابستگی به `$.Teamyar.DateTimePicker` چون بات ممکن است بیرون از شل پرتال رندر شود) — تبدیل شمسی/میلادی روی ۷ ماه آزمون شامل اسفند کبیسه/غیرکبیسه با تقویم Persian خودِ مرورگر (`Intl`) تطبیق داده شد، طول ماه و آفست ستون شنبه‌محور هر ۷ مورد منطبق؛ (۲) **ستون «پیش‌بررسی موجودی»** با همان منطق تاریخ‌محورِ پلتفرم + تیک «رد کردن ردیف‌های دارای کسری موجودی» (پیش‌فرض روشن) تا حلقه وقتش را روی ردیف‌های محکوم‌به‌شکست تلف نکند؛ کوئری‌اش همبسته و گران است (~۱۹ ثانیه/۱۰۰ ردیف) پس فقط روی idهای همان صفحه و بالای ۱۰۰ ردیف خودکار خاموش می‌شود (گزارش‌شده در نوار هشدار)؛ (۳) **صفحه‌بندی سمت سرور** (پیش‌فرض ۵۰، سقف ۵۰۰) — حجم صفحه از ۲.۱۸MB به ۲۷۵KB رسید؛ (۴) **جدول خلاصهٔ دلایل ناموفقی** بعد از هر اجرا (گروه‌بندی پیام‌های پلتفرم با تعداد) — بدون آن «۰ موفق از ۶۶» هیچ اطلاعاتی نمی‌داد. **سه باگ که فقط با تست مرورگر واقعی پیدا شدند و رفع شدند:** الف) کلیک روی فلش ماه تقویم را می‌بست — `draw()` دکمه را از DOM برمی‌داشت و در لیسنر سراسری `contains(e.target)` دیگر false می‌شد؛ رفع با یک `stopPropagation` روی خودِ ظرف تقویم (نه فرزندها). ب) تقویم با `position:absolute` + آفست صفحه در صفحهٔ RTL دارای اسکرول افقی کاملاً بیرون از دید می‌افتاد (اندازه‌گیری: top=984,left=-208 در برابر فیلد top=246,left=871)؛ رفع با `position:fixed` + مختصات مستقیم `getBoundingClientRect` و محدودسازی به لبه‌های viewport. ج) **دیپلوی با HTTP 502 شکست می‌خورد** — علت: یک regex با اسلشِ escape‌شده (`/`) در سورس؛ با `split(/)` جایگزین شد و همان حجم بلافاصله ۲۰۰ گرفت. آن ۵۰۲ تمیز نیست: طول COMMAND عوض شده بود ولی BYTECODE بازتولید نشده بود، یعنی بات نسخهٔ قبلی را اجرا می‌کرد — بعد از هر ۵۰۲ حتماً رفتار زنده را تست کنید (جزئیات در حافظهٔ `teamyar-escaped-slash-regex-breaks-save`). **نسخهٔ ۳ (1405/06/12) — قاعدهٔ موجودی اصلاح شد + واژگان با پرتال یکی شد:** (۱) پیش‌بررسی موجودی v2 **غلط بود** — کاربر ۱۸ حوالهٔ ۱۴۰۴ را اجرا کرد، ۴ تا درست رد شدند ولی ۱۴ تای دیگر «موجودی کافی» نشان داده و همه رد شدند. قاعدهٔ واقعی پلتفرم **«ماندهٔ در تاریخ حواله» نیست**، بلکه: یک خروجِ تاریخ‌گذشته فقط وقتی پذیرفته می‌شود که **ماندهٔ در گردش در هیچ نقطه‌ای از تاریخ حواله به بعد منفی نشود** — یعنی `need <= LEAST(ماندهٔ درست قبل از تاریخ حواله, کمینهٔ ماندهٔ در گردش از آن تاریخ به بعد)`. شواهد: برای هر پنج کالای نام‌برده در پیام‌های خطا (01004267/01001094/01000346/01000448/01004233) کمینهٔ ماندهٔ در گردش دقیقاً **۰** است، در حالی که ماندهٔ در تاریخ و ماندهٔ امروزشان مثبت بود (۱۲۷۳۰: ۱۱۳ و ۱۵۹۴). با قاعدهٔ اصلاح‌شده هر پنج خطا بازتولید می‌شوند و از کل صف **۱۹۸** حواله قابل ثبت است (نه ۳۲۷). پیاده‌سازی با window function (`FEASIBILITY_CTE`: running balance + suffix-min) — کل صف ~۲۶ ثانیه، یک صفحه چند ثانیه. فرضیه‌های ردشده (تست‌شده روی داده): ATTRIBUTE_ID (صفر در تمام ۶۰۳ هزار ردیف)، سریال (`wh_product_serial` برای این کالاها خالی)، `wh_product_stocks.LAST_QUANTITY` (همه صفر)، IS_BACK، وضعیت جزئیات، و همهٔ گونه‌های مانده‌گیری ساده (۳۸ تا ۱۴۷ — هیچ‌کدام منفی). (۲) فیلتر جدید **«فقط ردیف‌های قابل ثبت»** (پیش‌فرض خاموش، چون کل صف را می‌سنجد). (۳) **واژگان مراحل با تب‌های خود پرتال یکی شد** — کاربر گزارش داد «حواله‌های مرحلهٔ بررسی را باید لود کنیم» و معلوم شد بات همان‌ها را لود می‌کرد ولی «ثبت تعدادی (۱)» صدایشان می‌زد. تأیید زنده: تب «بررسی» پرتال = `OPERATION_STATUS=1` (بازهٔ ۱۴۰۴/۰۷/۰۱–۱۴۰۴/۰۹/۰۱ → ۳۲٬۴۳۲ ردیف، دقیقاً منطبق با KPI بات). نگاشت نهایی: ۰=پیش‌نویس، ۱=بررسی، ۲=اجرا، ۳=کامل (همان enum سراسری پلتفرم). (۴) برای مرحلهٔ «بررسی» پیش‌بررسی موجودی و رد کردن خودکار **غیرفعال** است — موجودی هنگام ثبت تعدادی کسر شده و گام ۱←۲ فقط حسابداری است. تأیید زنده: stage=1 در ۲.۶ ثانیه ۳۲٬۴۳۲ را می‌شمارد و صفحه را می‌دهد؛ `feasible_only=1` روی ۱۸ حوالهٔ ۱۴۰۴ درست **صفر** ردیف برمی‌گرداند. **✅ مسیر موفقیت تأیید شد (1405/06/12، توسط کاربر روی پرتال):** عملکرد «ثبت حسابداری گروهی» (بررسی ← اجرا) روی داده زنده کار کرد. تأیید مستقل از دیتابیس: وضعیت ۱ از ۱۳۲٬۹۲۴ به ۱۳۱٬۸۳۴ (−۱٬۰۹۰) و وضعیت ۲ از ۶۵٬۰۸۵ به ۶۶٬۱۷۵ (+۱٬۰۹۰) — تراز کامل، بدون ردیف گم‌شده؛ وضعیت ۰ دست‌نخورده روی ۴٬۰۳۵ (سازگار با قاعدهٔ موجودی). یعنی حلقهٔ ترتیبی، تشخیص موفق/ناموفق و قرارداد پاسخ همگی روی حجم واقعی درست کار می‌کنند. **آنچه هنوز تأیید نشده:** مسیر موفقیتِ «ثبت تعدادی» (۰←۱) — تا امروز هر تلاش روی قاعدهٔ موجودی رد شده و فقط ۱۹۸ حواله از ۴٬۰۳۵ نامزد واقعی‌اند. |
| `bank_satna_payment_order_form_bot.lua` (بات ۶۴۳، `run/443/bank_satna_payment_order_form`) | HTML | `mode=todo` + `todo_id` (فراخوانی AJAX داخلی، خروجی JSON)؛ بدون ورودی = صفحهٔ فرم | **بات چاپ روی فرم کاغذی — نه گزارشی.** فرم «دستور پرداخت الکترونیکی بین بانکی (ساتنا/پایا/پل)» سه بانک (اقتصاد نوین، رفاه کارگران، پارسیان). فرم چاپ **نمی‌شود**؛ فرم کاغذی خود بانک داخل پرینتر گذاشته می‌شود و بات فقط مقادیر را روی جای خالی‌ها چاپ می‌کند. هر بانک یک برگهٔ مجازی با اندازهٔ واقعی دارد (**رفاه A4 ۲۱۰×۲۹۷؛ اقتصاد نوین و پارسیان A5 ۱۴۸×۲۱۰**) و هر فیلد یک مختصات میلی‌متری از گوشهٔ بالا-چپ؛ `@page size` و ابعاد برگه با انتخاب بانک عوض می‌شوند و چاپ با `margin:0` انجام می‌شود (کاربر باید در پنجرهٔ چاپ حاشیه=None و مقیاس=۱۰۰٪ بگذارد). روی صفحه همان مختصات‌ها باکس ورودی‌اند (WYSIWYG)؛ در چاپ فقط متن می‌ماند. **جانمایی (Calibration):** مختصات اولیه از روی اسکن فرم‌ها تخمین زده شده و **هنوز روی کاغذ واقعی کالیبره نشده** — بات «حالت جانمایی» دارد (کشیدن با ماوس، جهت=۰٫۵mm، Shift+جهت=۰٫۱mm، Ctrl+چپ/راست=عرض)، افست کلی X/Y، «چاپ آزمایشی» (کادر+شبکهٔ ۱۰mm)، بارگذاری تصویر اسکن به‌عنوان پس‌زمینهٔ راهنما (فقط محلی، هرگز چاپ/آپلود نمی‌شود)، ذخیره در `localStorage` و «خروجی جانمایی» به‌صورت JSON برای ثابت‌کردن در سورس. **فراخوانی حساب مقصد از ماژول اقدام:** با وارد کردن شمارهٔ اقدام، مقادیر فرم سفارشی همان اقدام خوانده و درج می‌شوند. **مسیر داده (تأییدشده زنده روی اقدام ۱۳۵۱۷، 1405/06/12):** مقادیر در `todo_custom_form(ID=<task_id>, TYPE=5).FORM_DATA` به‌صورت JSON با کلیدهای **انگلیسی** کنترل‌ها (`Owner`/`Sheba`/`Amount`/`Bank`/`Branch`/`CardNumber`/`Comments`/`TotalContractAmount`)؛ **برچسب فارسی و ترتیب فیلدها** در `todo_custom_form(ID=todo_task.WORK_FLOW_ID, TYPE=4).FORM_DATA` زیر کلید `info[]` (`{name,title,...}`) — اقدام ۱۳۵۱۷ → `WORK_FLOW_ID=224` → ردیف `(224,4)`. مسیر جایگزین برای فرم‌های قدیمیِ کنترل‌محور (`todo_form_data` + `todo_form_controls` روی `TASK_ID`) هم پیاده شده ولی روی این نصب داده نداشت. **دو تلهٔ واقعی:** (۱) فیلد پرنشده به‌جای خالی‌بودن **متن راهنمای خودش** را نگه می‌دارد («لطفا نام بانک را وارد بفرمایید») — با `is_placeholder` (پیشوند «لطفا») فیلتر می‌شود، وگرنه متن راهنما روی فرم بانک چاپ می‌شد؛ (۲) run_path هنگام دیپلوی با `cat_id=79` پیشوند **`443/`** گرفت، پس ثابت `_RUN_URL` در سورس باید `/bot/run/443/...` باشد وگرنه فراخوانی AJAX اقدام کار نمی‌کند. نگاشت خودکار: `Sheba`→شبای مقصد، `Owner`→نام دارندهٔ حساب مقصد، `Amount`→مبلغ به عدد، `Bank`→بانک مقصد، `CardNumber`→شماره حساب مقصد؛ `Branch`/`Comments`/`TotalContractAmount` عمداً نگاشت نشده‌اند (جای متناظر روی فرم بانک ندارند) و در جدول زیر نوار با دکمهٔ «کپی مقدار» دیده می‌شوند. «بابت» از عنوان خود اقدام پر می‌شود و **«مبلغ به حروف» خودکار از روی مبلغ ساخته می‌شود** (`amountToWords`، تا «هزار میلیارد»؛ ۱۴٬۴۰۰٬۰۰۰٬۰۰۰ → «چهارده میلیارد و چهارصد میلیون» — منطبق با خود فرم اقدام). **انحراف عمدی از قانون ۱۴px پروژه:** روی فرم‌های A5 جای خالی‌ها کوچک‌اند، پس «کوچک‌کردن خودکار متن» (تا ۹px) پیش‌فرض روشن است و اگر باز هم جا نشد باکس روی صفحه پررنگ و قبل از چاپ هشدار داده می‌شود — بریده‌شدن شمارهٔ حساب روی دستور پرداخت بدتر از متن کوچک‌تر است. مقادیر ثابت متقاضی (گروه زرین صنعت ارتباط هوشمند / ۱۴۰۱۲۳۹۹۲۸۰ / خیابان بهشتی پلاک ۲۰۶) و شماره حساب‌های مبدأ به تفکیک بانک (دراپ‌داون) در ثابت‌های بالای فایل. **تاریخ بالای فرم و «در تاریخ» خودکار با تاریخ روزِ سیستم (سرور) به شمسی پر می‌شوند** — از `report_dimdate.JNDATE` سمت Lua، نه ساعت مرورگر (تأییدشده زنده: سرور ۱۴۰۵/۰۶/۱۱ در حالی که مرورگر ۱۴۰۵/۰۶/۱۲ می‌داد؛ تاریخ روی دستور پرداخت باید تاریخ سیستم باشد). ساعت مرورگر فقط پشتیبان است و **شعبهٔ حساب مبدأ به تفکیک بانک** از ثابت `BANK_BRANCHES` (اقتصاد نوین=۱۰۸؛ رفاه و پارسیان هنوز اعلام نشده). دکمهٔ **«پیش‌نمایش چاپ»** کادرها/برچسب‌ها/شبکه را از صفحه برمی‌دارد تا دقیقاً خروجی کاغذ دیده شود — کادرها فقط راهنمای روی صفحه‌اند و در چاپ عادی هرگز نمی‌آیند (تنها استثنا «چاپ آزمایشی» که عمداً کادر و شبکه را چاپ می‌کند). **باگ رفع‌شده (1405/06/11، گزارش کاربر «موقع پرینت کادر دور نوشته‌ها هست»):** کلاس `body.testprint` بعد از یک «چاپ آزمایشی» می‌ماند اگر رویداد `afterprint` شلیک نشود (چاپ در PDF، لغو کردن، بعضی مرورگرها) و آن‌وقت هر چاپ بعدی — از جمله Ctrl+P — کادرها را هم چاپ می‌کرد. **رفع نهایی (بار دوم، بعد از تکرار گزارش روی موبایل):** پاک‌کردن همگام بعد از `window.print()` روی موبایل کار نمی‌کند چون آنجا `print()` بلوکه نمی‌شود و دیالوگ ناهمگام باز می‌شود. الگوی نهایی: پرچم `state.testing` + پاک‌شدن با `afterprint` + پاک‌شدن با اولین `pointerdown`/`keydown` بعد از ۸۰۰ms (پوشش حالتی که `afterprint` هرگز شلیک نمی‌شود — چاپ در PDF اندروید یا لغو کردن) + محافظ روی `beforeprint`. دکمه هم به «چاپ الگوی تنظیم (کادردار)» تغییر نام داد، از نوار اصلی به پنل ابزارها منتقل شد و confirm گرفت — گزارش کاربر در واقع از زدن همین دکمه بود، نه از باگ چاپ عادی. هر ۶ سناریو تست شد. ضمناً فونت Peyda صریحاً داخل `@media print` هم روی `input`/`select` تحمیل شد (کنترل‌های فرم font-family را به‌ارث نمی‌برند). **فونت = فقط Peyda.** یک نسخه با فونت دست‌نویس فارسی (Farsi Simple Normal) ساخته و روی همین بات دیپلوی شد ولی کاربر ردش کرد («اصلا خوب نیست») و به Peyda برگشت — فونت و asset حذف شدند. یافتهٔ ماندگار آن آزمایش (۱۲ فونت کاندید روی متن واقعی فرم): **بیشتر فونت‌های دست‌نویس/تزئینی عربی ارقام ASCII را به گلیف عربی‌ـهندی نگاشت می‌کنند** — روی یک دستور پرداخت بانکی خطرناک است؛ اگر روزی فونت غیرPeyda مطرح شد، حتماً ارقام باید جدا و با Peyda بمانند. **بازطراحی رابط (1405/06/11، بازخورد کاربر «UX جالب نیست» + «ریسپانس موبایل ایراد دارد»):** سه نوار شلوغ دکمه به یک نوار اصلی (بانک / شمارهٔ اقدام+فراخوانی / چاپ) به‌علاوهٔ پنل بستهٔ «ابزارها» تبدیل شد؛ کنترل‌ها حداقل ۴۰px ارتفاع (هدف لمسی)، برچسب بالای هر فیلد، حالت focus مشخص، و دکمه‌های toggle با نشانگر ●/○. **موبایل:** گزینهٔ بزرگ‌نمایی «اندازهٔ صفحه» (پیش‌فرض) برگه را با عرض واقعی دستگاه مقیاس می‌دهد — بدون آن برگهٔ A4 (۷۹۴px) از صفحهٔ گوشی بیرون می‌زد؛ تأیید عددی: در ظرف ۳۶۰px، A4 → scale 0.45 و A5 → 0.64، هر دو بدون سرریز افقی. مقیاس فقط نمایشی است (transform در @media print صفر می‌شود). لوگو ۱۴۰ White + پالت #16509D + تمام‌صفحه (toggle کلاس CSS) + Excel + راهنما. **جانمایی از روی اسکن واقعی (1405/06/11):** کاربر هر سه فرم را با اسکنر تخت گرفت (`assets/satna_forms/`، ≈۴۰۰dpi؛ نسبت هر سه ≈√۲). خانه‌های رقم و مربع‌های تیک **اقتصاد نوین** با پردازش تصویر در canvas اندازه‌گیری شدند — عرض خانه، فاصلهٔ داخل گروه، فاصلهٔ بین گروه‌ها و اندازهٔ مربع تیک (۴٫۱mm)؛ خطای بازتولید زیر ۰٫۲mm. به همین دلیل مدل فیلد `digits` از «گام یکنواخت» به **گروه‌بندی** (`groups`/`cw`/`gap`/`ggap`) تغییر کرد: شانهٔ شبا بین گروه‌ها خط تیره دارد و گام یکنواخت به‌مرور از خانه‌های چاپی بیرون می‌زد (اقتصاد نوین ۲،۴،۴،۴،۴،۴،۲ و شناسهٔ پرداخت ۲+۷×۴). مربع تیک هم فیلد اندازه (`s`) گرفت. فیلدهای متنی هر سه فرم با ابزار `tools/satna_calibration/` (اسکن + کادرهای بات + خط‌کش میلی‌متری، بریده و بزرگ‌شده) جانمایی شدند؛ قاعدهٔ جای عمودی: `box_y = rule_y - 4.3` — کادر ۶ میلی‌متری است و خط پایهٔ متن حدود `y + 4.3` می‌افتد، پس متن روی خط چاپی می‌نشیند. **فرم پارسیان با پردازش تصویر اندازه‌گیری‌پذیر نبود** — خانه‌ها و مربع‌هایش گوشه‌گرد و با خط نازک نارنجی چاپ شده‌اند و ستون تیرهٔ ممتد ندارند، پس آشکارساز لبهٔ عمودی جواب نمی‌دهد؛ چشمی جانمایی شد. همچنین آشکارساز خط نقطه‌چین روی متن فارسی مثبت کاذب می‌دهد، پس خروجی‌اش همیشه باید روی خود اسکن رسم و چشمی تأیید شود. **وضعیت:** دیپلوی شد و مسیر دادهٔ اقدام روی دادهٔ زنده تأیید شد؛ **جانمایی مختصات و شماره حساب‌های خوانده‌شده از دست‌نویس هنوز تأیید نشده‌اند.** |

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
| 620 (cat_id=79) | تسویهٔ انبوه **فاکتور فروش** (`TYPE=1`) — بک‌فیل زمان‌محور. **v2.0 (۱۴۰۵/۰۶/۱۲):** صف فقط فاکتورهای «تسویه‌نشده **و** امضانشده» را می‌آورد (شرط امضا: وجود ردیف `pa_voucher_signs.SIGN=1` روی سندی که از راه `pa_voucher_record.REFFERE_ID = sales_invoice.id` به فاکتور وصل است) و درست قبل از هر ثبت، دوباره از دیتابیس می‌پرسد که فاکتور هنوز تسویه ندارد. اندازه‌گیری زنده: صف از ۶۲٬۸۱۹ به ۶۰٬۷۹۰ رسید، یعنی ۲٬۰۲۹ فاکتور با سند امضاشده دیگر بی‌خود امتحان نمی‌شوند. سورس تا این تاریخ فقط در `live_bots/620.lua` بود؛ حالا `src/` مرجع است | `sales_settlement_backfill_queue_bot.lua` | `/bot/run/443/sales_settlement_backfill_queue` |
| 642 (cat_id=79) | **راهبر تسویه برگشت از فروش (v2.0 — کارِ اصلی؛ بات ۶۳۹ به‌خاطر محدودیت API عملاً بلااستفاده است).** صفحهٔ خود فاکتور را در iframe هم‌مبدأ باز می‌کند، ردیف تسویه را پر می‌کند و دکمهٔ ذخیرهٔ همان صفحه را می‌زند (نوع تسویه «حسابها»، حساب از پیکربندی، مبلغ کل فاکتور، تاریخ = تاریخ فاکتور + ۵ دقیقه). سه حالت اجرا: دکمهٔ «تسویه» هر ردیف، «تسویه انتخاب‌شده‌ها»، «تسویه کل لیست» + ستون وضعیت، شمارندهٔ موفق/ناموفق، دکمهٔ توقف، و حالت گام‌به‌گام برای عیب‌یابی. **اولین تسویهٔ موفق بات: ردیف ۲۳۳۸۶۲ روی فاکتور ۱۴۳۷۴۳ (۱۴۰۵/۰۶/۱۲).** کلید حل مسئله: هوک `XMLHttpRequest.send` داخل iframe و جایگزینی فقط فیلد `settlement_0` با آبجکت کامل حساب — جزئیات و تله‌ها در `CLAUDE.md` بخش «بات‌های نویسندهٔ مالی». سورس با placeholder پیوست‌ها در `src/` است و با `scripts/build_bot_with_assets.js` به `build/` ساخته و از آنجا دیپلوی می‌شود | `sales_return_settlement_ui_driver_report_bot.lua` | `/bot/run/443/sales_return_settlement_ui_driver` |
| 639 (cat_id=79) | تسویه فاکتورهای برگشت از فروش (کپی بات ۶۲۰ برای `sales_invoice.TYPE=3`، نوع تسویه «حساب») | `sales_return_settlement_backfill_queue_bot.lua` | `/bot/run/443/sales_return_settlement_backfill_queue` |
| 589 (cat_id=79) | کاوش ساختار جدول (v2) — کپی جدید از بات ۹۶۶ چون بات ۹۶۶ زیر این SID دیگر در دسترس نبود (view endpoint خروجی خالی/«[جدید]» می‌داد). نسخهٔ فعلی نسبت به بات ۹۶۶ دو Mode اضافه دارد: `mode=rawp` (Query پارامتری با `q`+`params` JSON) و `mode=simulate` (تست دقیق الگوی now_raw→Lua arithmetic→Query که برای پیدا کردن باگ فضای خالی گمشده در بات ۵۹۲ استفاده شد) | `src/schema_probe_json_bot.lua` (دیپلوی‌شده از نسخهٔ patch‌شده در Scratchpad، نه از فایل src بدون تغییر) | `/bot/run/443/schema_probe_v2` |
| 592 (cat_id=79) | داشبورد مدیریتی اقدام‌ها (v01) | `action_management_dashboard_report_bot.lua` | `/bot/run/443/action_mgmt_dashboard` |
| 595 (cat_id=80) | داشبورد فاکتورهای مودیان (بازنویسی بات ۵۷۸ با UI/معماری استاندارد این ریپو؛ رفع باگ تب اصلاحی و پارامتری‌سازی کامل) | `moadian_invoices_dashboard_report_bot.lua` | `/bot/run/443/moadian_invoices_dashboard` |
| 598 (cat_id=80) | صفحه اصلی مودیان[Module] — بازطراحی کامل بات ۵۷۸ (v4، ۱۴۰۵/۰۵/۲۰). **دیگر از get_config/get_attachment/پیوست دستی استفاده نمی‌کند** — بعد از این‌که بارها تأیید شد «پیکربندی» بات هرگز مقدار واقعی ذخیره‌شده ندارد (چه ۵۹۵ چه ۵۹۸) و همین باعث کرش HTTP 500 (روی `count_day` خالی) و عدم بارگذاری تب «ارسالی» می‌شد، کوئری کاملاً خودکفا در Lua جاسازی شد؛ ورودی org_id (پیش‌فرض ۸) / from_date / to_date (شمسی، پیش‌فرض ۳۶۵ روز اخیر) / limit (پیش‌فرض ۵۰۰). کوئری بر مبنای پیوست `query_list_invoice.txt` **بات مرجع فعال ۵۷۴** («ارسال گروهی به سامانه مودیان[Module]») بازسازی شد — نه اتچمنت‌های قدیمی بات ۵۷۸ — با دو اصلاح واقعی که از مقایسه با ۵۷۴ به دست آمد: فیلتر `i.type IN (1,3)` (در اتچمنت‌های ۵۷۸ نبود) و نگاشت وضعیت کامل‌تر شامل کدهای ۱۱۹/۱۲۰/۲۱۹/۲۲۰/۳۱۹/۳۲۰/۴۰۰ (کران بالای هر بازه هم اکنون شامل خود عدد است: `<=120/220/320` نه `<120/220/320`). ظاهر: پالت #16509D + فونت Peyda self-contained، جعبه جستجوی آنی هر تب، کارت‌های KPI (تعداد کل ارسالی/ابطالی/اصلاحی از کوئری COUNT سبک، جدا از کوئری ردیف‌ها)، هدر مرتب‌سازی‌پذیر، Excel فقط روی ردیف‌های فیلترشده. AJAX هر تب (type=1/2/3/4/5): فقط fetch خام؛ **v5 (1405/06/09، دیپلوی‌شده): مهلت ۲۰ ثانیه‌ای سمت کلاینت حذف شد** (قطع زودهنگام فقط خطای کاذب می‌ساخت). **صفحه‌بندی سمت سرور**: پیش‌فرض ۵۰ ردیف در صفحه (`page`/`per_page`، سقف ۵۰۰) + نوار پیجر الگوی تیم‌یار (مجموع | «‹ صفحه [n] از N › » | سلکت اندازه). **موتور کوئری دومرحله‌ای**: مرحله ۱ فقط ردیف‌های صفحه از sales_invoice (EXISTS به‌جای JOIN+DISTINCT)، مرحله ۲ CTEهای مبلغ + اسکن‌های LIKE سِیلز-هیستوری فقط برای idهای همان صفحه (inline امن — id های tonumber شدهٔ برگشتی از DB) — زمان هر صفحه از ~۲۱ ثانیه به ~۳.۸ ثانیه رسید (اندازه‌گیری زنده). بازطراحی کامل طبق آخرین گاید ۱۴۰ (الگوی بات ۶۰۳ hr_dashboard — سایدبار سرمه‌ای #0e3c73 تمام‌قد با لوگوی سفید ۱۴۰، topbar عنوان+متا+دکمه‌ها، کارت‌های KPI سفید) + ریسپانسیو موبایل کامل (سایدبار → منوی ۲×۲، KPIهای فشرده، پیجر وسط‌چین). فونت Peyda واقعاً base64 جاسازی شد (placeholder خالی بود)، «تمام صفحه» از Fullscreen API به toggle کلاس CSS تغییر کرد. منوی سایدبار: بات‌های ۵۷۴ (ارسال/اصلاح/ابطال فاکتور) و ۵۷۲ (وضعیت مودی) در **iframe روی آدرس صفحهٔ خود بات داخل پرتال** اجرا می‌شوند: `/?page=/bot/run/2/send_group_moadian_m` و `/?page=/bot/run/2/tax_client_st_m` — یعنی دقیقاً همان صفحه‌ای که با باز کردن بات از منوی پرتال رندر می‌شود. چون هم‌مبدأ است، بعد از `load` با `isolateBotContent` محتوای خود بات (`[id^="widget-report-"] / #myDiv / section[data-name]`) پیدا و بقیهٔ خواهرزاده‌ها تا `body` مخفی می‌شوند تا منو/هدر تکراری پرتال داخل قاب دیده نشود؛ اگر پیدا نشد صفحه دست‌نخورده می‌ماند (بدترین حالت: شلوغ، نه خالی) + دکمهٔ «باز کردن در تب جدید». **دو روش قبلی که شکست خوردند — تکرار نشوند:** (۱) iframe روی `/bot/run/2/<slug>` خام → خالی، چون آن پاسخ فقط fragment است و بیرون از شل پرتال jQuery/`$.Teamyar`/CSS پلتفرم نیست؛ (۲) گرفتن HTML با `run_command` و تزریق در همین صفحه → حتی با اجرای کاملاً ترتیبی اسکریپت‌ها هم بالا نیامد (بات RES به بافت صفحهٔ خودش وابسته است، نه فقط به حضور اسکریپت‌ها). **درس جانبی که هنوز معتبر است (برای هر تزریق HTML روی این پلتفرم):** اسکریپت‌های تزریق‌شده باید ترتیبی اجرا شوند (هر `src` تا `onload`/`onerror` بلاک شود)؛ `async=false` به‌تنهایی کافی نیست چون فقط ترتیب خارجی‌ها نسبت به هم را حفظ می‌کند نه نسبت به inlineها (اثبات‌شده با هارنس محلی: `toolsInit is not a function` در روش یکجا). «وضعیت فاکتور» (بات ۵۷۹) چون ماژول API خالص است (GET خالی → HTTP 500) پنل استعلام داخلی دارد: ورودی شماره فاکتور → `type=5` → lookup در sales_invoice → `run_command("2/fact_st_m")`. هر سه بات + سوابق فاکتور/استعلام/res_v2 در «دستورات مرتبط» بات ثبت‌اند (کاربر از پنل اضافه کرد، 1405/06/09). **بازهٔ پیش‌فرض: سال مالی جاری سازمان (`pa_fiscal_year`، FILETIME خام — بدون REPORT_FN_JDATE که وجود ندارد)**، fallback ۳۶۵ روز اخیر اگر سال مالی فعال ثبت نشده باشد. تأییدشده روی داده زنده (سال مالی جاری): ارسالی=38,822، ابطالی=2,427، اصلاحی=۰ | `moadian_factor_tabs_report_bot.lua` | `/bot/run/2/moadian_index_m_1` |
| 627 (cat_id=79) | داشبورد مودیان ۱۴۰۴ (ارزش افزودهٔ فصلی، v02) — CSV صورتحساب‌های فروش/خرید سامانهٔ مودیان را در هر اجرا مستقیماً از «اسناد» تیم‌یار می‌خواند (`teamyar.create_file_manager(7, id)` + `fm:readFile(id)`)؛ ۸ اسلات فروش/خرید × فصل ۱ تا ۴ با ورودی `sale_q1..sale_q4` / `purchase_q1..purchase_q4` در Query String (هر کدام اختیاری و مستقل، پیش‌فرض هاردکد). شامل KPI و نمودار فصلی، تسویهٔ ارزش افزوده، جدول‌های فیلتر/مرتب‌سازی/صفحه‌بندی‌شونده (۲۰۰ ردیف در صفحه)، Drill-down هر ردیف روی همهٔ ۳۹ ستون، خروجی اکسل. **اصلاحات v02 (1405/06/09 — دیپلوی و اندازه‌گیری‌شده روی داده زنده):** (۱) حجم خروجی از **۱۱۷ مگابایت / ۲۷ ثانیه به ۸.۴ مگابایت / ۲ ثانیه** رسید — v01 خروجی `csv_to_json` را عیناً جاسازی می‌کرد و نام هر ۳۹ ستون فارسیِ بلند را برای هر ۴۷٬۲۲۸ ردیف تکرار می‌کرد؛ حالا `encode_csv_packed` خودِ CSV را در Lua پارس می‌کند (بررسی زندهٔ کل ردیف‌ها نشان داد هیچ مقداری کاما/کوتیشن/newline ندارد، پس split سادهٔ خطی امن است و رشتهٔ JSON ۶۸ مگابایتی اصلاً ساخته نمی‌شود — نه حافظه‌اش مصرف می‌شود نه `json.decode` سنگین لازم است) و ساختار `{cols,dict,rows}` می‌فرستد که کلاینت با `unpackTable` دقیقاً به همان آرایهٔ آبجکت قبلی برمی‌گرداند؛ هیچ ستونی حذف نشده پس Drill-down/فیلتر/اکسل دست‌نخورده‌اند (تأیید: ۳۰۳۷ ردیف نمونه، صفر اختلاف؛ ۳۹→۳۹ ستون). (۲) **Chart.js و SheetJS از `cdn.jsdelivr.net` لود می‌شدند و CSP پرتال آن‌ها را بلاک می‌کرد** (فقط `'self'`/`data:`/`blob:`/google-analytics مجاز است) — یعنی نمودارها و خروجی اکسل اصلاً کار نمی‌کردند؛ حالا از `/bot/run/2/res_v2/chart.umd.min.js` و `/bot/run/2/res_bot/xlsx.full.min.js` (هر دو تست‌شده، HTTP 200). (۳) ردیف جعلی انتهای هر فایل که `csv_to_json` از newline پایانی می‌ساخت و به‌صورت یک فاکتور خالی در جدول‌ها دیده می‌شد حذف شد. `max_execute_time=300`. در سایدبار بات ۵۹۸ به‌صورت iframe مستقیم روی fragment خودش لود می‌شود (خودکفاست: بدون jQuery/`$.Teamyar`) | `vat_quarterly_dashboard_report_bot.lua` | `/bot/run/443/vat_quarterly_dashboard` |
| 565 (cat_id=79) | آنالیزور بات (اصلی — بدون تغییر). **1405/05/20: یک بازنویسی آزمایشی با ظاهر بات ۵۹۴ روی این بات deploy و سپس توسط کاربر رد شد** («این مربوط به آنلیز بات‌هاست، من داده ماژول اقدام ندادم») و به همین نسخهٔ اصلی برگردانده شد — به‌جایش بات جدید ۵۹۹ ساخته شد (ردیف بعدی). این بات دیگر نباید تغییر ظاهری بگیرد مگر کاربر صریحاً بخواهد | `bot_analyzer_report_bot.lua` | `/bot/run/443/AnalysBot` |
| 599 (cat_id=79) | عملکرد ماژول باتی — ظاهر یک‌به‌یک کپی از بات ۵۹۴ «مرکز فرماندهی باتی» (**استثنای مصوب کاربر از قانون پالت‌رنگ/فونت/Peyda در CLAUDE.md — نگاه کنید به هدر فایل**)؛ دادهٔ بات 565 (آمار اجرا/میانگین‌زمان/هرگز-اجرا-نشده) و بات 594 (دسته/بخش، روند روزانه/ساعتی، جریان رویدادها، drawer) با هم تلفیق شده — **بدون هیچ دادهٔ ماژول اقدام (todo_task)**، فقط bot_command/bot_command_run/bot_history. لینک‌ها طبق الگوی صریح کاربر: `/?page=/bot/index&cat_id=X` (رده)، `/?page=/bot/command/view&id=X&cat_id=Y&tab=0` (بات)، `/bot/run/{run_path}` (اجرا). پرفورمنس: تمام آمار bot_history از یک fetch خام در یک پاس Lua (~2.7 ثانیه؛ نگاه کنید به یادداشت فنی در هدر فایل برای چرایی) | `bot_module_performance_report_bot.lua` | `/bot/run/443/bot_module_performance` |
| 596 (cat_id=79) | ارسال پیامک پیشگام رایان — کپی الگوی بات ۳۹۷ (MeliPayamak Panel SMS Send) با `teamyar.call_url` روی API پیشگام رایان (`POST https://smsapi.pishgamrayan.com/Messages/Send`، مستندات `Guidance-WebService-Pishgamrayan.pdf` v2.2). ورودی‌های اجرا: `to` (شماره یا فهرست جدا با کاما/فاصله)، `text`، `from` (اختیاری - پیش‌فرض از پیکربندی)، `send_date` (اختیاری، ارسال زمان‌بندی‌شده، فرمت شمسی `YYYY/MM/DD HH:MM:SS`). پیکربندی بات (تب «پیکربندی»، الزامی قبل از استفاده): `token` (مقدار هدر `Authorization`)، `sender_number` (شماره فرستنده پیش‌فرض). موفقیت = `statusCode` برابر ۱ یا ۲ (طبق نمونهٔ مستندات)؛ پاسخ خام API هم در خروجی برگردانده می‌شود | `pishgam_sms_send_bot.lua` | `/bot/run/443/pishgam_sms_send` |
| 633 (cat_id=79) | ماژول اقدام — بازطراحی ماژول «اقدام» (BPMN/گردش‌کار سازمانی) با گایدلاین ظاهری ریپو (پالت #16509D، فونت Peyda جاسازی‌شده، لوگو ۱۴۰، هدر مرتب‌سازی‌پذیر، تمام‌صفحه/Excel/راهنما). بات HTML یکپارچه با ساید‌بار داخلی؛ صفحه اول = داشبورد اقدام‌های کاربرِ اجراکننده. ساخته‌شده روی برنچ `claude/actions-module-redesign-hmks50` (سشن دیگر) و فایلش به‌تنهایی وارد master شد (خود برنچ بیس قدیمی داشت و checkout کاملش master را عقب می‌برد). دیپلوی ۱۴۰۵/۰۶/۰۹، تأیید زنده: HTTP 200 در ~۰.۱ ثانیه. v2 (1405/06/09 22:15): رفع sql error فهرست (باگ حذف newline بعد از `[[` — `where_sql` به `ORDER BY` می‌چسبید؛ COUNT سالم بود و فقط SELECT فهرست می‌شکست)، endpoint جدید `action=detail&task_id=N` (مشخصات + مراحل گردش کار + یادداشت‌های غیرخصوصی strip-HTML شده)، پاپ‌آپ جزئیات با کلیک روی هر سطر جدول (لینک شناسه/عنوان همچنان تب جدید)، و تقویم شمسی خودکفا (الگوریتم jalaali، بدون وابستگی خارجی) برای هر سه کادر تاریخ (از/تا تاریخ فیلتر + مهلت فرم ایجاد — readonly، فقط انتخاب از تقویم) | `action_module_report_bot.lua` | `/bot/run/443/action_module` | v3 (1405/06/09 23:10): فرم «ایجاد اقدام» به‌جای دو combo تخت (رده/جریان کار — روی داده زنده ۴۴ رده و ۱۵ بخش، برای کاربر پردسترسی غیرقابل‌استفاده) از **درختوارهٔ بخش ← رده ← جریان کار** استفاده می‌کند؛ کاملاً کلاینت‌ساید از همان `BOOT.options` (بدون کوئری اضافه)، با جستجوی هم‌زمان در هر سه سطح (شاخه‌های مطابق خودکار باز می‌شوند) و حذف شاخه‌هایی که به جریان کار ختم نمی‌شوند. انتخاب جریان کار، موضوع‌های همان رده را فیلتر می‌کند و `wf_id` از state درخت به API می‌رود. همچنین شناسه‌ها دیگر جداکنندهٔ هزارگان نمی‌گیرند (`idText` به‌جای `fa` — «۱۲۹۳۶» نه «۱۲,۹۳۶»). v4 (1405/06/09 23:55) — رفع «دکمه‌های مرده در نمای کارت بات»، دو ریشهٔ مستقل: (الف) **ادغام فیکس برنچ `claude/actions-module-redesign-hmks50` (کامیت 32105f0)**: فیلد `action` در POST ممکن است توسط پلتفرم بی‌صدا حذف شود و بات وقت آن کل صفحهٔ ۳۰۰KB را به یک فراخوانی AJAX برمی‌گرداند (= پاشیدن صفحه). حالا action از سه مسیر می‌رود (`customform` + فیلد مستقیم + `am_action` روی query string)، سمت Lua هر سه خوانده می‌شود (`resolve_action`)، و گارد `looks_like_ajax` هرگز اجازه نمی‌دهد پاسخ یک AJAX، HTML باشد؛ کلاینت هم پاسخ غیرJSON را تزریق نمی‌کند. (ب) **حالت چندنمونه‌ای**: در نمای کارت بات ممکن است بیش از یک نسخهٔ ویجت در DOM باشد و `getElementById` همیشه نسخهٔ *اول* را برمی‌گرداند — علامتش دقیقاً همان چیزی بود که کاربر دید: «راهنما» کار می‌کرد (مودال overlay در هر صورت دیده می‌شود) ولی KPI/فیلترها/تمام‌صفحه بی‌اثر بودند. حالا هر نمونه اولین `#amRoot` ادعانشده را با `data-am-bound` برمی‌دارد، همهٔ جستجوها داخل همان ریشه است، و هر ۳۵ `onclick`/`onchange` سراسری به رویداد delegated روی ریشه (`data-am-act`) تبدیل شد. تمام‌صفحه هم موقتاً ریشه را به `body` منتقل می‌کند (position:fixed داخل والدِ transform نسبت به viewport محاسبه نمی‌شود). برچسب «من» غیرتعاملی شد تا کلیک به سطر برسد. تست آفلاین با jsdom در حالت دو-نمونه: کلیک روی نمونهٔ دوم فقط همان را عوض می‌کند و نمونهٔ اول دست‌نخورده می‌ماند. v5 (1405/06/10 00:40): **دکمهٔ «تمام صفحه» حذف شد — استثنای آگاهانه از قانون نوار ابزار CLAUDE.md** (سه پیاده‌سازی روی نمای کارت بات شکست خورد: Fullscreen API، toggle کلاس با position:fixed، و انتقال ریشه به body که کارت را خالی می‌کرد؛ آن نما از بیرون قابل بازتولید نیست پس حدس چهارم زده نشد). Excel و راهنما نگه داشته شدند (هر دو الزام CLAUDE.md و راهنما هم‌زمان به‌روز شد). دو ردیف فیلتر فهرست برچسب گرفتند («نقش من:» و «وضعیت:») — بدون آن‌ها هر دو ردیف یک «همه» داشتند و کاربر فیلتر «عضو هستم» را «مپ‌شده به همه» گزارش کرد؛ تست jsdom نشان داد سیم‌کشی درست بوده و ابهام صرفاً بصری بود (تب scope واقعاً روی member می‌رود). سطرهای جدول `title` راهنما گرفتند. **پیتفال دیپلوی (تاییدشدهٔ زنده):** `deploy_teamyar_bot.ps1` پرچم‌های `public_access`/`show_in_portal_menu`/`show_in_widget` را هر بار با پیش‌فرض `0` می‌فرستد، پس هر دیپلوی آن‌ها را خاموش می‌کند — روی همین بات «دسترسی عمومی» و «نمایش در منوی پورتال» صفر شده بودند و با `-PublicAccess 1 -ShowInPortalMenu 1` برگردانده و روی فرم زنده تأیید شدند. هر دیپلوی بعدی این بات باید همین دو سوییچ را پاس بدهد.
| 637 (cat_id=80) | ارسال/ابطال/اصلاح گروهی به سامانه مودیان[Module] — **جانشین بات ۵۷۴** (کاربر دیگر پنل، 1405/06/10، بات ۵۷۴ را حذف و این بات را با همان `run_path` ساخت؛ لینک‌های iframe بات ۵۹۸ چون بر پایهٔ run_path هستند سالم ماندند). نسخهٔ جدید وندور (سینک از `erp.teamyar.com` src=2181) + دو قابلیت جدید type=19/20 (فاکتور برگشت/returnInvoice). **رفع خرابی 1405/06/10 (این سشن):** (۱) `_BAT_RES_PATH` نسخهٔ وندور `"443/res_v2"` بود → پچ به `"2/res_v2"`؛ (۲) attachment `install_res.lua` بات ۳۰۴ هم توسط سینک وندور به `return dataRes, "443/res_v2"` برگشته بود → با نسخهٔ mirror (`src/res_v2_304_attachments/install_res.lua`) جایگزین شد — این خرابی همهٔ ~۳۵ بات RES را می‌شکست؛ (۳) بات تازه‌ساز هیچ ردیف `bot_command_config` نداشت → `config.data` صفحهٔ nil ایندکس می‌شد و 500 فوری می‌داد → ردیف `{"bot_send_id":"576","bot_del_id":"575","bot_edit_id":"571"}` (بات‌های tax_gov خانوادهٔ [Module]) درج شد. تأیید زنده: HTTP 200 / ~۴۲۰KB | `send_group_moadian_m_bot.lua` | `/bot/run/2/send_group_moadian_m` |
| 640 (cat_id=79) | ثبت تعدادی و ثبت حسابداری گروهی حواله‌های فروش — بات نویسندهٔ انبار؛ جزئیات کامل در جدول بالا | `warehouse_issue_bulk_signoff_report_bot.lua` | `/bot/run/443/wh_issue_bulk_signoff` |
| 568 (cat_id=59) | ارسال گروهی به سامانه مودیان (غیرماژول) — همان باگ `443/res_v2` نسخهٔ وندور (src=1956) را داشت؛ 1405/06/10 detach + پچ `_BAT_RES_PATH` به `2/res_v2` + رفع drift مسیر. تأیید زنده HTTP 200 | `send_group_moadian_bot.lua` | `/bot/run/2/send_group_moadian` |
| 632 (cat_id=79) | ابزار موقت مدیریت bot_command — modeها: `detach_src` / `reattach_src` / `set_run_path` / `run_probe` (اجرای `teamyar.run_command` با pcall و برگرداندن خطای واقعی؛ target باید در «دستورات مرتبط» خود ۶۳۲ باشد — با `add_related` اضافه کنید) / `add_related` (درج در `bot_related_command`) / `del_attachment_row` (حذف ردیف `bot_command_files` — برای پاک کردن attachment تکراری هم‌نام وقتی `attachments_deleted` حذف نکرده) / `insert_config` (درج ردیف `bot_command_config` با `config_json`+`title`). بعد از استفاده غیرفعال شود | `temp_detach_bot_src_link_bot.lua` | `/bot/run/443/temp_bot_command_admin` |
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

