# مرجع بات‌های فروش موجود (سازنده: Mozhgan Rajabali) — تحلیل‌شده 1405/05/24

منبع: ۶ فایل `.tybot` (export کامل بات از پنل Teamyar، شامل `command` + attachments base64) که کاربر
برای بررسی ارائه داد:

| فایل | id | نام | run_path | نوع |
|---|---|---|---|---|
| command_387.tybot | 387 | sales dashbord Notes | `2/sd_n` | ویجت یادداشت شخصی (RES `res_bot`) — کم‌ربط به این پروژه |
| command_388.tybot | 388 | sales dashbord CRM Remainder | `2/sd_rem_crm` | یادآور مشتریانی که ۷ روز تماس نداشته‌اند — کم‌ربط |
| command_389.tybot | 389 | Monthly Gross Profit | `2/gross_profit` | گزارش سود ناخالص ماهانه، معماری RES v2 (`readyCodes`/`install_res`) |
| command_390.tybot | 390 | [report]گزارش جامع فروش با جزئیات | `2/comprehensive_sales_with_details_2` | نسخهٔ تفصیلی گزارش جامع فروش، RES v2 |
| command_433.tybot | 433 | **[report]گزارش جامع فروش نسخه اصلی** | `2/comprehensive_sales_2` | **نسخهٔ اصلی/مرجع** گزارش جامع فروش — شامل ۷ Query نمودار (روزانه/ماهانه/فصلی/سالانه/انبار/مرکز فروش) |
| command_440.tybot | 440 | گزارش فروش به تفکیک فاکتور | `2/sales_report_by_invoice` | گزارش سطح فاکتور، مشابه معماری ۴۳۳ |

همه (به‌جز ۳۸۷/۳۸۸) از معماری **RES v2** استفاده می‌کنند: `readyCodes()` → `teamyar.run_command("2/res_v2", data)`
→ کد Lua/JS برگشتی load می‌شود؛ فیلترها از `data.txt` (`inputs`/`searcher_*`/ACL) خوانده می‌شوند؛ Queryهای SQL در
attachmentهای جدا (`query_*.txt`) با Placeholder جایگزین‌شونده (`{{where_condition}}`, `{{select}}`,
`{{slicePageNumber}}`) نگه‌داری می‌شوند. جدول در سمت کلاینت با ویجت هستهٔ پلتفرم `$.Teamyar.table`/Highcharts رندر
می‌شود (نه HTML/CSS دست‌نویس مثل بات‌های cat_id=79 این ریپو).

## یافتهٔ ۱ (تأییدشده، نه حدس) — `profile_user_info.USER_TYPE`

هم `command_390` (`data.txt`) و هم `command_440` (`query_sales_report_by_invoice.txt`) مستقل از هم همین نگاشت را دارند:

```
USER_TYPE = 3  →  filter_natural   →  «حقیقی» (Individual)
USER_TYPE = 4  →  filter_legal     →  «حقوقی» (Legal / Corporate)
```

نمونه SQL (۴۴۰): `(case (pui.USER_TYPE) when 3 then 'filter_natural' when 4 then 'filter_legal' end) user_type`

⇒ در بات داشبورد جغرافیایی این پروژه (`crm_geo_sales_dashboard_bot.lua`)، به‌جای برچسب موقت «نوع ۳»/«نوع ۴»،
باید «حقیقی»/«حقوقی» نمایش داده شود. **این تغییر اعمال شد.**

## یافتهٔ ۲ (تأییدشده) — الگوی Join جغرافیایی مرجع (production، در ۴۳۳/۳۹۰/۴۳۳-چارت‌ها تکرار شده)

```sql
join profile_user_address pua
     on (pui.ID = pua.USER_ID) and (pua.TYPE = 3 or pua.TYPE = 2 or pua.TYPE = 1)
join report_country rc on pua.COUNTRY_CODE = rc.ID
inner join pa_client cl on cl.REFFERE_ID = pua.USER_ID
where pua.CITY is not null and pua.STATE is not null and pua.CITY <> '' and pua.STATE <> ''
```

نکته: این‌جا هر سه `TYPE` (۱/۲/۳) مجاز است، ولی یکتایی/عدم Duplicate از طریق فیلتر انتهایی
`CITY <> '' AND STATE <> ''` تضمین می‌شود (نه از طریق محدودکردن به یک TYPE ثابت). در دادهٔ زندهٔ همین دیتابیس
(طبق Discovery خودمان روی این بات) `TYPE=2` همیشه خالی است و `TYPE=3` اصلاً وجود ندارد — پس این فیلتر production
عملاً هم‌ارز با Rule خودمان (`addr.TYPE = 1`) است، فقط با یک مکانیزم دفاعی‌تر (فیلتر بر مبنای «دارای مقدار واقعی»
به‌جای کد ثابت). Rule فعلی این پروژه (`addr.TYPE=1`, تست‌شده و Validate‌شده روی داده زنده — تعداد/مبلغ فاکتور قبل
و بعد از Join دقیقاً برابر) **تغییر داده نشد**، چون قبلاً به‌صورت مستقل تأیید شده و برای این دیتابیس درست است؛
صرفاً این یافته به‌عنوان مرجع/تأیید موازی مستند شد.

## یافتهٔ ۳ (بحرانی — نیاز به تصمیم کاربر، هنوز اعمال نشده) — فرمول واقعی «مبلغ فاکتور»

هر دو بات مرجع (`433`: `query_comprehensive_sales_final.txt`, `440`: `query_sales_report_by_invoice.txt`) مبلغ
فاکتور را **نه از `RECEPTION_AMOUNT + REMAINED_AMOUNT`**، بلکه از تجمیع ردیف‌های `sales_invoice_product` با فرمول
زیر محاسبه می‌کنند:

```sql
AMOUNT_per_product_line =
  CASE i.TYPE
    WHEN 3 THEN -1 * ( (fee * QUANTITY) - DISCOUNT + VALUE_ADDED + tax + toll )   -- برگشت از فروش: علامت منفی
    ELSE             ( (fee * QUANTITY) - DISCOUNT + VALUE_ADDED + tax + toll )
  END
-- SUM شده روی sales_invoice_product ip بر اساس ip.INVOICE_ID = i.id، به‌ازای هر فاکتور
```

با نگاشت `i.TYPE`: `1=فاکتور فروش، 2=پیش‌فاکتور فروش، 3=برگشت از فروش، 5=سفارش فروش، 6=مجوز فروش، 7=قرارداد فروش`.

**چرا این مهم است:** فاکتورهای `TYPE=3` (برگشت از فروش) در این فرمول علامت **منفی** می‌گیرند (از جمع کل کم می‌شوند).
اگر `RECEPTION_AMOUNT`/`REMAINED_AMOUNT` برای فاکتورهای برگشتی علامت منفی نداشته باشند (یعنی مقدار مثبت را برای
مبلغ برگشتی ذخیره کنند)، جمع سادهٔ `RECEPTION_AMOUNT + REMAINED_AMOUNT` روی کل `sales_invoice` (بدون فیلتر/نگاشت
TYPE) می‌تواند به‌جای «فروش خالص» یک عدد بزرگ‌تر و نادرست («فروش ناخالص + برگشتی به‌جای کسر» یا مبالغی که اصلاً
به فروش نهایی مربوط نیستند مثل سفارش/مجوز/قرارداد فروش) نشان دهد. این می‌تواند دقیقاً همان چیزی باشد که کاربر
«جمع فاکتورهای فروش درست نمایش داده نشده» گزارش کرده.

**این فرمول در بات داشبورد جغرافیایی این پروژه هنوز جایگزین نشده** — چون کاربر ابتدا صراحتاً `RECEPTION_AMOUNT +
REMAINED_AMOUNT` را در پرامپت اولیه به‌عنوان فرمول مبنا اعلام کرده بود. قبل از جایگزینی یک فرمول تجمیعی سنگین‌تر
(join به `sales_invoice_product` + `wh_stock_capacity` + `pa_symbols` برای اعشار) که روی کل داشبورد (KPI، جدول
استان، جدول شهر، Drill-down مشتری/فاکتور) اثر می‌گذارد، باید از کاربر تأیید گرفت — پرسیده شد.

## یافتهٔ ۴ — مکانیزم فیلتر استان/شهر در بات‌های RES

بات‌های ۴۳۳/۳۹۰ فیلتر state/city را نه از یک جدول مرجع ثابت، بلکه از طریق ACL پویا (`report[reportPath].getStateAcl`
/`getCityAcl`، هرکدام یک `type` عددی در همان بات که سرور را با `customform={type:13,...}`/`{type:14,...}` صدا
می‌زند و لیست را از `DISTINCT STATE`/`DISTINCT CITY` واقعیِ خودِ `profile_user_address` می‌سازد) پر می‌کنند — نه از
`crm_state_city`. این با یافتهٔ خودمان هم‌خوان است (`crm_state_city` قابل‌اتکا نیست؛ لیست واقعی State/City باید از
`profile_user_address` گرفته شود، دقیقاً همان کاری که `crm_geo_sales_dashboard_bot.lua` می‌کند).

## یافتهٔ ۵ — معماری RES v2 در مقابل معماری خودکفای این پروژه

بات‌های ۳۸۹/۳۹۰/۴۳۳/۴۴۰ کاملاً به `2/res_v2` و ویجت‌های هسته‌ای پلتفرم (`$.Teamyar.table`, `Highcharts`) وابسته‌اند —
معماری متفاوتی از بات‌های `cat_id=79` این ریپو («سینا مقدم») که HTML/CSS/JS کاملاً خودکفا (بدون RES، بدون
Highcharts خارجی) تولید می‌کنند. **این پروژه (`crm_geo_sales_dashboard_bot.lua`) به معماری RES تغییر نکرد** — فقط
یافته‌های دادهٔ بالا (USER_TYPE، فرمول AMOUNT، مکانیزم State/City) از این بات‌ها استخراج و استفاده شد.
