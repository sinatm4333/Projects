# /api/change_request_product_status

درخواست

## آدرس

```
/api/change_request_product_status
```

## درخواست

```json
{
  "status": 0,
  "request_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `status` | integer (int32) |  |
| `request_id` | integer (int64) |  |

## پاسخ

```json
{
  "error": {
    "status": 0,
    "message": ""
  },
  "success": false
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
