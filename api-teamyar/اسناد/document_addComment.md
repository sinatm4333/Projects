# اضافه کردن کامنت

## آدرس

```
/api/document/addComment
```

## درخواست

```json
{
  "content*": "",
  "is_portal": false,
  "document_id*": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `content*` | string | محتوای کامنت |
| `is_portal` | boolean | اگر پورتال باشد 1در غیر این صورت 0 |
| `document_id*` | integer (int64) | شناسه سند |

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
