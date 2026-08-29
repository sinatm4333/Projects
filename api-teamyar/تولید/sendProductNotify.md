# /api/sendProductNotify

درخواست

## آدرس

```
/api/sendProductNotify
```

## درخواست

```json
{
  "products": [
    {
      "product_id": 0,
      "attribute_id": 0
    }
  ]
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `products[]` | array |  |
| `products[].product_id` | integer (int64) |  |
| `products[].attribute_id` | integer (int64) |  |

## پاسخ

```json
{
  "data": {
    "error": ""
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
| `data.error` | string | جزئیات خطای اجرای API |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
