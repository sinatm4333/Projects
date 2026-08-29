# رد سند

رد سند به همراه وارد کردن کامنت

## آدرس

```
/api/document/refuseSignStatus
```

## درخواست

```json
{
  "content": "",
  "is_private": 0,
  "assign_type": 0,
  "document_id*": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `content` | string | کامنت رد سند |
| `is_private` | integer (int32) | محرمانه بودن یا نبودن کامنت رد سند1 : محرمانه0 : غیر محرمانه |
| `assign_type` | integer (int32) | نوع رد کردن سند2 : امضا16 : تایید32 : مسئول |
| `document_id*` | integer (int64) | شناسه سندوارد کردن این مقدار اجباری است |

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
