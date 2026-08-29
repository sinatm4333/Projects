# آپدیت روزهای تعطیل در تقویم

بروزرسانی وضعیت تعطیل/غیر تعطیل در روزهای مشخصی از یک تقویم

## آدرس

```
/api/hr/calendarDaysUpdate
```

## درخواست

```json
{
  "days": [
    {
      "date": 0,
      "holiday": 0
    }
  ],
  "calendar_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `days[]` | array | روزهای تقویم |
| `days[].date` | integer (int64) | تاریخ |
| `days[].holiday` | integer (int32) | تعطیل هست(1) یا خیر(0) |
| `calendar_id` | integer (int64) | شناسه تقویم مربوطه برای تغییر روزهای تعطیل |

## پاسخ

```json
{
  "data": {
    "message": ""
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
| `data` | object | داده های پاسخ اجرای API |
| `data.message` | string | پیغام اطلاعات |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
