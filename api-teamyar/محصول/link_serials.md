# API لینک سریال به عملیات

این API، سریال‌ها را به یک سطر از عملیات متصل می‌کند.

## آدرس

```
/api/link_serials
```

## درخواست

```json
{
  "serials": [
    ""
  ],
  "operation_id": 0,
  "operation_detail_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `serials[]` | array | آرایه سریال‌ها |
| `operation_id` | integer (int64) | شناسه عملیات (از جدول WH_OPERATION) |
| `operation_detail_id` | integer (int64) | شناسه سطر عملیات (از جدول WH_OPERATION_DETAILS) |

## پاسخ

```json
{
  "data": {
    "result": ""
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
| `data` | object | دیتای خروجی |
| `data.result` | string | نتیجه انجام یا عدم انجام عملیات |
| `error` | object | در صورت وجود خطا این مقدار برگردانده می شود. |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
