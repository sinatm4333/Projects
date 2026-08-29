# حذف ورژن های فایل

حذف ورژن های قدیمی فایل و نگهداری تعداد مشخص از آخرین ورژن ها

## آدرس

```
/api/document/deleteAdditionalVersions
```

## درخواست

```json
[
  {
    "document_id*": 0,
    "max_version_count*": 0
  }
]
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `document_id*` | integer (int64) | شناسه فایل |
| `max_version_count*` | integer (int32) | تعداد ورژن هایی که باید باقی بماند |

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
