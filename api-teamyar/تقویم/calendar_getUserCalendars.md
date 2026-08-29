# دریافت تقویم های کاربر

از این API میتوان برای گرفتن تقویم های کاربر استفاده کرد

## آدرس

```
/api/calendar/getUserCalendars
```

## درخواست

```json
{
  "user_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `user_id` | integer (int64) | آیدی یوزری که تقویم هایش را میخواهید در این قسمت قرار میگیرد. |

## پاسخ

```json
{
  "data": {
    "total": 0,
    "calendar": [
      {
        "id": 0,
        "name": "",
        "b_order": 0,
        "folder_id": 0,
        "creator_id": 0,
        "bot_command": "",
        "date_create": 0,
        "date_modify": 0,
        "description": "",
        "modifier_id": 0
      }
    ]
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
| `data` | object | دیتا |
| `data.total` | integer (int64) | تعداد کل |
| `data.calendar[]` | array | تقویم ها |
| `data.calendar[].id` | integer (int64) | شناسه |
| `data.calendar[].name` | string | نام تقویم |
| `data.calendar[].b_order` | integer (int64) | متغیر تقویم |
| `data.calendar[].folder_id` | integer (int64) | شناسه فولدر |
| `data.calendar[].creator_id` | integer (int64) | شناسه ایجاد کننده |
| `data.calendar[].bot_command` | string | کامند بات |
| `data.calendar[].date_create` | integer (date) | روز ایجاد |
| `data.calendar[].date_modify` | integer (date) | تاریخ اصلاح |
| `data.calendar[].description` | string | توضیحات |
| `data.calendar[].modifier_id` | integer (int64) | شناسه اصلاح کننده |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
