# ارسال کد امنیتی

## آدرس

```
/api/user/password/forgot/sendSecurityCode
```

## درخواست

```json
{
  "lang_id": 0,
  "portal_id": 0,
  "mobile_email": ""
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `lang_id` | integer (int32) | زبان |
| `portal_id` | integer (int64) | شناشه پورتال |
| `mobile_email` | string | شماره تلفن یا ایمیل |

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
