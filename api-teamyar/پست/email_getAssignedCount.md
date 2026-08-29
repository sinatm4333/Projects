# تعداد مطلعین

## آدرس

```
/api/email/getAssignedCount
```

## درخواست

```json
{
  "message_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `message_id` | integer (int64) | شناسه پیام |

## پاسخ

```json
{
  "data": {
    "count": 0
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
| `data` | object |  |
| `data.count` | integer (int32) | تعداد |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
