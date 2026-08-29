# تایید سند

تایید سند (تایید، مسئول و امضا)

## آدرس

```
/api/document/setSignStatus
```

## درخواست

```json
{
  "assign_type": 0,
  "document_id*": 0,
  "sign_status": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `assign_type` | integer (int32) | نوع رد کردن سند2 : امضا16 : تایید32 : مسئول |
| `document_id*` | integer (int64) | شناسه ی سندوارد کردن این مقدار اجباری میباشد |
| `sign_status` | integer (int32) | وضعیت سند2 : رد شده |

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
