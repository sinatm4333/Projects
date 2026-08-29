# گرفتن اطلاعات یک کیفیت

## آدرس

```
/api/get_quality
```

## درخواست

```json
{
  "id*": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id*` | integer (int64) | شناسه کیفیت |

## پاسخ

```json
{
  "data": {
    "quality": {
      "id": 0,
      "name": "",
      "action": 0,
      "cat_id": 0,
      "org_id": 0,
      "status": 0,
      "hideKey": "",
      "end_date": 0,
      "author_id": 0,
      "folder_id": 0,
      "site_type": 0,
      "chart_type": 0,
      "start_date": 0,
      "voter_type": 0,
      "date_create": 0,
      "date_modify": 0,
      "description": "",
      "flag_notify": 0,
      "ideal_score": 0,
      "modifier_id": 0,
      "payroll_use": 0,
      "portal_view": 0,
      "sms_content": "",
      "template_id": 0,
      "total_score": 0,
      "flag_deleted": 0,
      "message_show": 0,
      "reference_id": 0,
      "visible_date": 0,
      "editable_time": 0,
      "end_date_unit": 0,
      "qc_sample_num": 0,
      "result_status": 0,
      "reference_type": 0,
      "closing_message": "",
      "send_sms_status": 0,
      "welcome_message": "",
      "editable_options": 0,
      "show_as_template": 0,
      "show_result_time": 0,
      "qc_passable_total": 0,
      "answering_duration": 0,
      "custom_score_label": "",
      "refrence_detail_id": 0,
      "end_date_unit_count": 0,
      "show_result_time_type": 0
    }
  },
  "error": {
    "status": 0,
    "message": ""
  },
  "success": false
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data` | object | آبجکت اصلی |
| `data.quality` | object | کیفیت |
| `data.quality.id` | integer (int64) | شناسه کیفیت |
| `data.quality.name` | string | عنوان کیفیت |
| `data.quality.action` | integer (int32) | اگر 1 باشد این تست پلن قابل تغییر نیست. زمانی که مرجع این تست پلن وارد مرحله بعد می شود این فیلد 1 می شود. |
| `data.quality.cat_id` | integer (int64) | شناسه رده |
| `data.quality.org_id` | integer (int64) | شناسه سازمان |
| `data.quality.status` | integer (int32) | وضعیت(فعال(1)،بسته(2)) |
| `data.quality.hideKey` | string | کلید رندوم مربوط به نظرسنجی برای دسترسی از طریق پورتال و بدون لاگین |
| `data.quality.end_date` | integer (int64) | زمان تمام شدن آزمون(مهلت) |
| `data.quality.author_id` | integer (int64) | ایجاد کننده (شناسه کاربر در جدول PROFILE_MAIN) |
| `data.quality.folder_id` | integer (int64) | شناسه فولدری که فایلهای مربوط به پرسشنامه در آن قرار دارد (شناسه جدول POLL_TY_DOCUMENT) |
| `data.quality.site_type` | integer (int32) | اگر یک باشد آزمون در سایت نمایش داده میشود |
| `data.quality.chart_type` | integer (int32) | استفاده نشده |
| `data.quality.start_date` | integer (int64) | استفاده نشده |
| `data.quality.voter_type` | integer (int64) | استفاده نشده |
| `data.quality.date_create` | integer (int64) | تاریخ ایجاد |
| `data.quality.date_modify` | integer (int64) | تاریخ ویرایش |
| `data.quality.description` | string | توضیحات |
| `data.quality.flag_notify` | integer (int32) | ارسال اعلان به ایجاد کننده کیفیت |
| `data.quality.ideal_score` | integer (int64) | نمره ایدآل آزمون |
| `data.quality.modifier_id` | integer (int64) | تغییر دهنده (شناسه کاربر در جدول PROFILE_MAIN) |
| `data.quality.payroll_use` | integer (int32) | استفاده در لیست حقوقی: فعال کردن این فیلد به این معناست که نتایج حاصل از ارزیابی در محاسبات حقوق و دستمزد پرسنل مؤثر می باشد. |
| `data.quality.portal_view` | integer (int32) | اگر 1 باشد پرسشنامه در پورتال نمایش داده میشود |
| `data.quality.sms_content` | string | محتوای پیامک |
| `data.quality.template_id` | integer (int64) | شناسه الگو |
| `data.quality.total_score` | integer (int64) | جمع امتیازات یا بارم های سوالات |
| `data.quality.flag_deleted` | integer (int32) | اگر حذف شده باشد این فلگ 1 میشود و در تب حذف شده ها قرار میگیرد |
| `data.quality.message_show` | integer (int32) | تنظیمات خوشامدگویی اگر تیک خورده باشد برابر یک میشود |
| `data.quality.reference_id` | integer (int64) | منبع فراخوانی تست پلن چون ممکن است این تست پلن توسط یک بخش دیگر ایجاد شده باشد(مثلا توسط یک فاکتور در ماژول انبار یا ماژول تولید)(شناسه جدول WH_OPERATION) |
| `data.quality.visible_date` | integer (int64) | تاریخ و زمان نمایش پرسشنامه به شرکت کنندگان در پرسشنامه های دوره ای |
| `data.quality.editable_time` | integer (int64) | استفاده نشده |
| `data.quality.end_date_unit` | integer (int32) | واحد مهلت :[1, $.Teamyar.lang("DAY")],[2, $.Teamyar.lang("HOUR")],[3, $.Teamyar.lang("MINUTE")] |
| `data.quality.qc_sample_num` | integer (int64) | تعداد نمونه (فقط برای نوع ارزیابی شونده ، کنترل کیفیت کالا) |
| `data.quality.result_status` | integer (int64) | enum EnQcStatus { POLL_QC_STATUS_UNKNOWN = 0, POLL_QC_STATUS_OK = 1, رد POLL_QC_STATUS_NOT_OK = 2, قبول POLL_QC_STATUS_AGREE_LICENSE = 3, مجوز ارفاقی قبولی براساس تایید POLL_QC_STATUS_FINAL_REJECT = 4, رد نهایی}; |
| `data.quality.reference_type` | integer (int32) | نوع سند فراخوانی (استفاده نشده ) |
| `data.quality.closing_message` | string | متن تشکر |
| `data.quality.send_sms_status` | integer (int32) | وضعیت ارسال پیامک |
| `data.quality.welcome_message` | string | متن خوش آمد |
| `data.quality.editable_options` | integer (int32) | امکان ویرایش پاسخها توسط شرکت کننده(نحوه پاسخگویی)enum EnEditableOption { POLL_EDITABLE_OPTION_ONCE = 1, یکبار POLL_EDITABLE_OPTION_UNTIL_EXPIRED = 2, تا زمانی که آزمون تمام نشده POLL_EDITABLE_OPTION_UNTIL_TWENTY_FOUR = 3 تا 24 ساعت}; |
| `data.quality.show_as_template` | integer (int32) | استفاده به عنوان الگو |
| `data.quality.show_result_time` | integer (int64) | زمان نمایش نتایج آزمون |
| `data.quality.qc_passable_total` | integer (int64) | درصد کل قابل قبول(فقط برای نوع ارزیابی شونده ، کنترل کیفیت کالا) |
| `data.quality.answering_duration` | integer (int64) | مدت زمان پاسخ دهی |
| `data.quality.custom_score_label` | string | برچسب سفارشی امتیاز |
| `data.quality.refrence_detail_id` | integer (int64) | شناسه رکورد سند فراخوانی |
| `data.quality.end_date_unit_count` | integer (int64) | تعداد مهلت بر اساس واحد تعریف شده |
| `data.quality.show_result_time_type` | integer (int32) | نحوه نمایش نتایج به شرکت کننده enum EnShowResultTimeType{ SHOW_RESULT_TIME_TYPE_NEVER = 1, هیچگاه SHOW_RESULT_TIME_TYPE_AFTER_REPLY = 2, بعد از ثبت جواب SHOW_RESULT_TIME_TYPE_AFTER_EXPIRED = 3 بعد از زمان اتمام آزمون}; |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
