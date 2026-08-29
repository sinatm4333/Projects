# /api/document/getCreatedTokenForPortal

درخواست

## آدرس

```
/api/document/getCreatedTokenForPortal
```

## درخواست

```json
{
  "document_id*": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `document_id*` | integer (int64) | شناسه سندوارد کردن این مقدار اجباری است |

## پاسخ

```json
{
  "data": {
    "token": ""
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
| `data.token` | string | توکن سند |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
