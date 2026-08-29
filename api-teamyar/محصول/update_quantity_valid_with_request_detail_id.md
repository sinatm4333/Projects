# /api/update_quantity_valid_with_request_detail_id

درخواست

## آدرس

```
/api/update_quantity_valid_with_request_detail_id
```

## درخواست

```json
{
  "items": [
    {
      "id": 0,
      "quantity_valid": ""
    }
  ],
  "request_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) |  |
| `quantity_valid` | string |  |
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
