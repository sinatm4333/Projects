# حذف دسترسی های پوشه ای که برای پورتال انتخاب شده است

حذف دسترسی های پوشه ای که برای پورتال انتخاب شده است(تنظیمات پوررتال)

## آدرس

```
/api/document/deletePermission
```

## درخواست

```json
{
  "user_id": 0,
  "perm_type": 0,
  "document_id": 0,
  "permissions": [
    0
  ]
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `user_id` | integer (int64) | شناسه مشتری یا گروه مشتریان |
| `perm_type` | integer (int32) | 2 : دسترسی های پوشه ای که برای پورتال انتخاب شده است |
| `document_id` | integer (int64) | شناسه سندی که برای پورتال انتخاب شده است |
| `permissions[]` | array | دسترسی هایی که می خواهیم حذف شود |

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
