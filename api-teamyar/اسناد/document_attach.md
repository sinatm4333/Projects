# منگنه کردن فایل

منگنه کردن یک یا چند فایل به فایل دیگر

## آدرس

```
/api/document/attach
```

## درخواست

```json
{
  "attach_ids*": [
    0
  ],
  "document_id*": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `attach_ids*[]` | array | لیست فایل هایی که قرار است منگنه شوند |
| `document_id*` | integer (int64) | شناسه فایلی که فایل ها به آن منگنه می شوند |

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
