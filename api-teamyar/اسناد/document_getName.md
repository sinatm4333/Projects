# دریافت نام سند

با شناسه سند نام سند را دریافت می کنیم

## آدرس

```
/api/document/getName
```

## درخواست

```json
{
  "document_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `document_id` | integer (int64) | شناسه سند |

## پاسخ

```json
{
  "data": {
    "name": ""
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
| `data` | object | آبجکتی از نام اسناد |
| `data.name` | string | نام سند |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
