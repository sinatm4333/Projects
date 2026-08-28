-- ═══════════════════════════════════════════════════════════════════════════
-- کوئری‌های راستی‌آزمایی پنل پرسنلی «همراه ۱۴۰» (hr_companion_report_bot.lua)
-- تهیه: ۱۴۰۵/۰۶/۰۶ — سینا مقدم 09121011778
--
-- هدف: حذف تمام فرض‌های تاییدنشدهٔ باقی‌مانده در بات. هر کوئری یک فرض مشخص را
-- می‌سنجد و در توضیح بالای آن نوشته شده «الان بات چه فرضی دارد» و «اگر نتیجه چه
-- بود یعنی فرض غلط است».
--
-- ▸ همهٔ کوئری‌ها فقط SELECT هستند، LIMIT دارند و روی ستون ایندکس‌دار فیلتر می‌کنند.
--   هیچ‌کدام روی داده تغییری نمی‌دهد.
-- ▸ schema: 0000000
-- ▸ فقط کافی است خروجی هر کدام را (حتی چند ردیف اول) برگردانید.
-- ═══════════════════════════════════════════════════════════════════════════


-- ───────────────────────────────────────────────────────────────────────────
-- Q1 — واحدِ ستون‌های مدت‌زمان  ★ مهم‌ترین کوئری این فهرست
-- ───────────────────────────────────────────────────────────────────────────
-- فرض فعلی بات: همهٔ مدت‌ها بر حسب tick (۱۰۰ نانوثانیه) ذخیره می‌شوند، یعنی
--   دقیقه = مقدار / 10000000 / 60
-- این فرض بر «کارکرد خالص»، «اضافه‌کاری»، «تاخیر»، «مرخصی»، «ماموریت» و «مانده
-- مرخصی» اثر مستقیم دارد. اگر غلط باشد، همهٔ اعداد پنل غلط‌اند.
--
-- چطور بخوانیم: ستون as_hours_if_ticks باید عددی منطقی بدهد (کارکرد یک روز کاری
-- حدود ۷ تا ۹ ساعت). اگر مثلاً ۰٫۰۰۰۱ یا ۵۰۰۰۰۰ درآمد، فرض tick غلط است و ستون
-- raw_value مقیاس درست را نشان می‌دهد.

SELECT
  'hr_work_time.TOTAL_WORK'                       AS column_name,
  w.TOTAL_WORK                                    AS raw_value,
  ROUND(w.TOTAL_WORK / 10000000 / 3600, 3)        AS as_hours_if_ticks,
  COALESCE(REPORT_FN_JDATE(w.WORK_DATE, '/'), '') AS on_date
FROM hr_work_time w
WHERE w.TOTAL_WORK > 0
ORDER BY w.WORK_DATE DESC
LIMIT 5;

SELECT
  'hr_vacation.TOTAL_TIME'                            AS column_name,
  v.TOTAL_TIME                                        AS raw_value,
  ROUND(v.TOTAL_TIME / 10000000 / 3600, 3)            AS as_hours_if_ticks,
  v.KIND                                              AS kind_code,
  COALESCE(REPORT_FN_JDATE(v.DATE_VACATOIN, '/'), '') AS on_date
FROM hr_vacation v
WHERE v.TOTAL_TIME > 0
ORDER BY v.DATE_VACATOIN DESC
LIMIT 5;

SELECT
  'hr_personnel_order.WORKING_HOURS'                AS column_name,
  o.WORKING_HOURS                                   AS raw_value,
  ROUND(o.WORKING_HOURS / 10000000 / 3600, 3)       AS as_hours_if_ticks,
  o.LEAVE_PER_MONTH                                 AS leave_per_month_raw,
  ROUND(o.LEAVE_PER_MONTH / 10000000 / 3600, 3)     AS leave_hours_if_ticks,
  o.MAX_DELAY_MONTH                                 AS max_delay_raw,
  ROUND(o.MAX_DELAY_MONTH / 10000000 / 60, 2)       AS delay_minutes_if_ticks
FROM hr_personnel_order o
WHERE o.WORKING_HOURS > 0
ORDER BY o.ID DESC
LIMIT 5;

SELECT
  'hr_leave_remained_records.LEAVE_REMAINED'            AS column_name,
  r.LEAVE_REMAINED                                      AS raw_value,
  ROUND(r.LEAVE_REMAINED / 10000000 / 3600, 3)          AS as_hours_if_ticks,
  ROUND(r.LEAVE_REMAINED / 10000000 / 3600 / 8, 3)      AS as_days_if_ticks_8h,
  r.PAID_LEAVE_REMAINED                                 AS paid_raw
FROM hr_leave_remained_records r
WHERE r.LEAVE_REMAINED <> 0
LIMIT 5;


-- ───────────────────────────────────────────────────────────────────────────
-- Q2 — کدهای وضعیت درخواست مرخصی/ماموریت
-- ───────────────────────────────────────────────────────────────────────────
-- فرض فعلی بات: 0=در انتظار تایید، 1=تایید شده، 2=رد شده، 3=لغو شده
-- این برچسب‌ها مستقیماً به کارمند نشان داده می‌شوند؛ اگر جابه‌جا باشند، کارمند
-- یک مرخصیِ ردشده را «تایید شده» می‌بیند.
--
-- چطور بخوانیم: ستون sample_description و نسبت تعدادها معمولاً معنی هر کد را
-- روشن می‌کند. اگر ممکن است، یکی از رکوردها را در پنل رسمی هم باز کنید و بگویید
-- آن رکورد با کدام کد، در پنل چه وضعیتی نشان می‌دهد.

SELECT
  v.STATUS                                    AS status_code,
  COUNT(*)                                    AS row_count,
  MIN(COALESCE(v.DESCRIPTION, ''))            AS sample_description,
  MAX(COALESCE(REPORT_FN_JDATE(v.DATE_VACATOIN, '/'), '')) AS latest_date
FROM hr_vacation v
GROUP BY v.STATUS
ORDER BY row_count DESC;


-- ───────────────────────────────────────────────────────────────────────────
-- Q3 — نوع مرخصی/ماموریت: hr_vacation.TYPE به کدام ستون hr_vacation_type وصل است؟
-- ───────────────────────────────────────────────────────────────────────────
-- فرض فعلی بات: نمی‌داند، برای همین هر دو حالت را LEFT JOIN می‌کند و اولین نام
-- غیرخالی را برمی‌دارد. این کار درست است ولی اضافی؛ با جواب این کوئری یکی حذف می‌شود.
--
-- چطور بخوانیم: هر کدام از دو ستون name_via_TYPE یا name_via_ID که پر است، همان
-- رابطهٔ درست است.

SELECT ID, TYPE, NAME FROM hr_vacation_type ORDER BY ID;

SELECT
  v.TYPE                     AS vacation_type_value,
  COUNT(*)                   AS row_count,
  MIN(vt_by_type.NAME)       AS name_via_TYPE,
  MIN(vt_by_id.NAME)         AS name_via_ID
FROM hr_vacation v
LEFT JOIN hr_vacation_type vt_by_type ON vt_by_type.TYPE = v.TYPE
LEFT JOIN hr_vacation_type vt_by_id   ON vt_by_id.ID     = v.TYPE
GROUP BY v.TYPE
ORDER BY row_count DESC;


-- ───────────────────────────────────────────────────────────────────────────
-- Q4 — معنی hr_vacation.KIND (روزانه در برابر ساعتی)
-- ───────────────────────────────────────────────────────────────────────────
-- فرض فعلی بات: هیچ فرضی ندارد — عمداً از KIND استفاده نمی‌کند و مدت را از
-- TOTAL_TIME می‌گیرد. با جواب این کوئری می‌شود ستون «روزانه/ساعتی» را هم اضافه کرد.
--
-- چطور بخوانیم: اگر avg_hours برای یک KIND حدود ۸ و برای دیگری کمتر از ۴ باشد،
-- اولی روزانه و دومی ساعتی است.

SELECT
  v.KIND                                        AS kind_code,
  COUNT(*)                                      AS row_count,
  ROUND(AVG(v.TOTAL_TIME) / 10000000 / 3600, 2) AS avg_hours_if_ticks,
  MIN(vt.NAME)                                  AS sample_type_name
FROM hr_vacation v
LEFT JOIN hr_vacation_type vt ON vt.TYPE = v.TYPE
GROUP BY v.KIND
ORDER BY row_count DESC;


-- ───────────────────────────────────────────────────────────────────────────
-- Q5 — کدهای نوع رویداد تردد (hr_ext_time.TYPE)
-- ───────────────────────────────────────────────────────────────────────────
-- فرض فعلی بات: 0=تردد عادی، 1=مرخصی، 2=ماموریت، 3=ثبت دستی
-- این برچسب‌ها در تب «رویدادهای تردد» نمایش داده می‌شوند.
--
-- چطور بخوانیم: اگر کدی بیرون از این چهارتا زیاد تکرار شده، برچسبش را لازم داریم.

SELECT
  e.TYPE                                          AS ext_type_code,
  COUNT(*)                                        AS row_count,
  ROUND(AVG(GREATEST(e.TIME_TO - e.TIME_FROM, 0)) / 10000000 / 3600, 2) AS avg_hours,
  SUM(CASE WHEN e.ENABLE = 1 THEN 1 ELSE 0 END)   AS enabled_rows,
  MIN(COALESCE(e.COMMENT, ''))                    AS sample_comment
FROM hr_ext_time e
GROUP BY e.TYPE
ORDER BY row_count DESC
LIMIT 15;


-- ───────────────────────────────────────────────────────────────────────────
-- Q6 — شیفت و موظفی روز: آیا جمع کردن ردیف‌های hr_day_details دوباره‌شماری دارد؟
-- ───────────────────────────────────────────────────────────────────────────
-- فرض فعلی بات: موظفی هر روز = مجموع مدت همهٔ ردیف‌های hr_day_details آن روز، و
-- بازهٔ شیفت = از کمترین TIME_FROM تا بیشترین TIME_TO.
-- اگر ردیف‌های «استراحت» هم در همین جدول باشند (با TYPE متفاوت)، این جمع، موظفی
-- را بیشتر از واقع نشان می‌دهد و در نتیجه «کسری کار» غلط محاسبه می‌شود.
--
-- چطور بخوانیم: اگر برای یک روز بیش از یک ردیف با TYPEهای مختلف برگشت، بگویید هر
-- TYPE یعنی چه (کار / استراحت / شناور / ...).

SELECT
  d.CALENDAR_ID,
  COALESCE(REPORT_FN_JDATE(d.DAY_DATE, '/'), '')       AS on_date,
  d.TYPE                                               AS detail_type,
  d.kind                                               AS detail_kind,
  TIME_FORMAT(SEC_TO_TIME(MOD(d.TIME_FROM, 864000000000) / 10000000), '%H:%i') AS from_time,
  TIME_FORMAT(SEC_TO_TIME(MOD(d.TIME_TO,   864000000000) / 10000000), '%H:%i') AS to_time,
  ROUND((d.TIME_TO - d.TIME_FROM) / 10000000 / 3600, 2) AS hours,
  COALESCE(d.DESCRIPTION, '')                          AS description
FROM hr_day_details d
WHERE d.DAY_DATE = (
    SELECT MAX(d2.DAY_DATE) FROM hr_day_details d2 WHERE d2.CALENDAR_ID = d.CALENDAR_ID
  )
ORDER BY d.CALENDAR_ID, d.TIME_FROM
LIMIT 30;

-- تعداد ردیف در هر روز، برای دیدن اینکه اصلاً چند ردیفی هست یا نه:
SELECT rows_per_day, COUNT(*) AS how_many_days FROM (
  SELECT CALENDAR_ID, DAY_DATE, COUNT(*) AS rows_per_day
  FROM hr_day_details
  GROUP BY CALENDAR_ID, DAY_DATE
) t
GROUP BY rows_per_day
ORDER BY rows_per_day;


-- ───────────────────────────────────────────────────────────────────────────
-- Q7 — قرارداد مقدار -1 در ستون‌های FINAL_*
-- ───────────────────────────────────────────────────────────────────────────
-- فرض فعلی بات: اگر FINAL_ABSENCE (یا FINAL_OVER_TIME) برابر -1 باشد یعنی «مقدار
-- نهایی ثبت نشده»، پس مقدار خام ABSENCE / OVER_TIME استفاده می‌شود. این الگو از
-- hr_dashboard_report_bot.lua گرفته شده که برای تاخیر تایید شده بود، ولی برای
-- اضافه‌کاری تایید نشده.
--
-- چطور بخوانیم: اگر مقدار -1 در FINAL_OVER_TIME وجود دارد، فرض درست است. اگر
-- به‌جایش 0 یا NULL دیده می‌شود، منطق اضافه‌کاری باید عوض شود.

SELECT
  SUM(CASE WHEN w.FINAL_ABSENCE   = -1 THEN 1 ELSE 0 END) AS final_absence_minus1,
  SUM(CASE WHEN w.FINAL_ABSENCE IS NULL THEN 1 ELSE 0 END) AS final_absence_null,
  SUM(CASE WHEN w.FINAL_OVER_TIME = -1 THEN 1 ELSE 0 END) AS final_overtime_minus1,
  SUM(CASE WHEN w.FINAL_OVER_TIME IS NULL THEN 1 ELSE 0 END) AS final_overtime_null,
  SUM(CASE WHEN w.FINAL_OVER_TIME > 0 THEN 1 ELSE 0 END)  AS final_overtime_positive,
  SUM(CASE WHEN w.OVER_TIME > 0 THEN 1 ELSE 0 END)        AS raw_overtime_positive,
  COUNT(*)                                                AS total_rows
FROM hr_work_time w
WHERE w.WORK_DATE > (UNIX_TIMESTAMP() + 11644473600) * 10000000 - (180 * 864000000000);


-- ───────────────────────────────────────────────────────────────────────────
-- Q8 — ستون ABSENT در برابر absent
-- ───────────────────────────────────────────────────────────────────────────
-- فرض فعلی بات: از ستون ABSENT استفاده می‌کند (۱ = غیبت).
-- توجه: hr_dashboard_report_bot.lua در این ریپو از `hwt.absent` (حروف کوچک)
-- استفاده کرده، ولی در اسکیما ستون ABSENT است. اگر MySQL این سرور
-- case-sensitive باشد، یکی از این دو بات دارد ستون اشتباه می‌خواند.
--
-- چطور بخوانیم: اگر این کوئری بدون خطا اجرا شد و اعداد منطقی داد، ABSENT درست است.

SELECT
  w.ABSENT                       AS absent_flag,
  COUNT(*)                       AS row_count,
  ROUND(AVG(w.TOTAL_WORK) / 10000000 / 3600, 2) AS avg_work_hours
FROM hr_work_time w
GROUP BY w.ABSENT
ORDER BY row_count DESC
LIMIT 10;


-- ───────────────────────────────────────────────────────────────────────────
-- Q9 — گروه گفتگو برای «گفتگوی تبریک تولد»
-- ───────────────────────────────────────────────────────────────────────────
-- فرض فعلی بات: اگر celebration_group_id تنظیم نشده باشد، اولین گروهی که
-- /api/group/get برمی‌گرداند استفاده می‌شود. بهتر است گروه را خودتان انتخاب کنید.
--
-- چطور بخوانیم: شناسهٔ گروه مناسب را بردارید و در bot_config بگذارید:
--   { "celebration_group_id": <همان عدد> }

SELECT
  g.ID                                          AS group_id,
  g.NAME                                        AS group_name,
  g.PUBLIC_NAME                                 AS public_name,
  g.STATUS                                      AS status,
  COALESCE(REPORT_FN_JDATE(g.DATE_CREATE, '/'), '') AS created_on,
  (SELECT COUNT(*) FROM chat_dialogs d WHERE d.GROUP_ID = g.ID) AS dialog_count
FROM chat_group g
ORDER BY dialog_count DESC
LIMIT 20;


-- ───────────────────────────────────────────────────────────────────────────
-- Q10 — نمونهٔ یک گفتگوی گروهیِ موجود (برای فهمیدن مقادیر واقعی هنگام ساخت گفتگو)
-- ───────────────────────────────────────────────────────────────────────────
-- فرض فعلی بات: TYPE = 1 یعنی «گروهی» و STATUS = 0 یعنی «باز».
-- چون schema درخواست /api/dialog/add را نداریم، دیدن مقادیر واقعی یک گفتگوی
-- گروهیِ سالم کمک می‌کند payload درست ساخته شود.

SELECT
  d.ID            AS dialog_id,
  d.GROUP_ID      AS group_id,
  d.TYPE          AS type_code,
  d.STATUS        AS status_code,
  d.SHOW_IN_PORTAL,
  d.one_way_channel,
  COALESCE(d.deleted, 0) AS deleted,
  LEFT(COALESCE(d.TOPIC, ''), 60) AS topic_sample,
  (SELECT COUNT(*) FROM chat_dialog_view v WHERE v.DIALOG_ID = d.ID) AS member_count,
  (SELECT COUNT(*) FROM chat_message m WHERE m.DIALOG_ID = d.ID)     AS message_count
FROM chat_dialogs d
WHERE d.TYPE = 1 AND COALESCE(d.deleted, 0) = 0
ORDER BY d.ID DESC
LIMIT 10;


-- ───────────────────────────────────────────────────────────────────────────
-- Q11 — سلامت دادهٔ تولدها
-- ───────────────────────────────────────────────────────────────────────────
-- فرض فعلی بات: تولد فقط برای پرسنل شاغل (HIRING_STATUS = 2) با BIRTHDAY > 0 و
-- در همان سازمانِ کاربر نمایش داده می‌شود.
--
-- چطور بخوانیم: اگر عدد with_birthday خیلی کمتر از active_personnel باشد، بخش
-- تولدها برای بیشتر همکاران خالی می‌ماند و باید دلیلش را بررسی کنیم.

SELECT
  h.ORG_ID                                                  AS org_id,
  COUNT(*)                                                  AS active_personnel,
  SUM(CASE WHEN uf.BIRTHDAY > 0 THEN 1 ELSE 0 END)          AS with_birthday,
  SUM(CASE WHEN uf.BIRTHDAY IS NULL OR uf.BIRTHDAY <= 0 THEN 1 ELSE 0 END) AS without_birthday
FROM hr_personnels h
JOIN profile_main p ON p.id = h.PROFILE_ID
LEFT JOIN profile_user_info uf ON uf.id = p.id
WHERE h.HIRING_STATUS = 2
GROUP BY h.ORG_ID
ORDER BY active_personnel DESC
LIMIT 20;


-- ───────────────────────────────────────────────────────────────────────────
-- Q12 — تست نهایی روی یک نفر واقعی (اختیاری ولی خیلی مفید)
-- ───────────────────────────────────────────────────────────────────────────
-- شناسهٔ پرسنلی خودتان را جای <PERSONNEL_ID> بگذارید. خروجی این کوئری باید دقیقاً
-- با چیزی که پنل در تب «تردد و کارکرد» نشان می‌دهد یکی باشد. اگر یکی نبود، همان
-- ردیف اختلاف را بفرستید.

-- SELECT
--   COALESCE(REPORT_FN_JDATE(w.WORK_DATE, '/'), '') AS on_date,
--   TIME_FORMAT(SEC_TO_TIME(MOD(w.FIRST_IN, 864000000000) / 10000000), '%H:%i') AS first_in,
--   TIME_FORMAT(SEC_TO_TIME(MOD(w.LAST_OUT, 864000000000) / 10000000), '%H:%i') AS last_out,
--   ROUND(w.TOTAL_WORK / 10000000 / 60) AS work_minutes,
--   ROUND(CASE WHEN w.FINAL_OVER_TIME = -1 THEN w.OVER_TIME ELSE w.FINAL_OVER_TIME END / 10000000 / 60) AS overtime_minutes,
--   ROUND(CASE WHEN w.FINAL_ABSENCE   = -1 THEN w.ABSENCE   ELSE w.FINAL_ABSENCE   END / 10000000 / 60) AS delay_minutes,
--   ROUND(w.TOTAL_LEAVE / 10000000 / 60) AS leave_minutes,
--   w.ABSENT AS absent_flag
-- FROM hr_work_time w
-- WHERE w.PERSONNEL_ID = <PERSONNEL_ID>
-- ORDER BY w.WORK_DATE DESC
-- LIMIT 31;
