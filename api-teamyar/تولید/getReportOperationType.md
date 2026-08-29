# /api/getReportOperationType

درخواست

## آدرس

```
/api/getReportOperationType
```

## درخواست

```json
{
  "report_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `report_id` | integer (int64) |  |

## پاسخ

```json
{
  "data": {
    "report_type": 0
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
| `data.report_type` | integer (int32) |  |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
