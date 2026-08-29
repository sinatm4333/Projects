# گرفتن پوشه ی مشتریان

## آدرس

```
/api/client/getRootId
```

## درخواست

بدون پارامتر.

## پاسخ

```json
{
  "data": {
    "root_id": 0
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
| `data.root_id` | integer (int64) | شناسه پوشه مشتریان |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
