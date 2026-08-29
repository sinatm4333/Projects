# /api/checkReceiptConcluded

درخواست

## آدرس

```
/api/checkReceiptConcluded
```

## درخواست

```json
{
  "product_operation_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `product_operation_id` | integer (int64) |  |

## پاسخ

```json
{
  "data": {
    "can_register": false
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
| `data.can_register` | boolean |  |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
