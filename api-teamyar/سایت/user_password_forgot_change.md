# فراموشی رمز عبور

فراموشی رمز عبور این api فقط یکی از دوحالت ایمیل یا شماره تلفن را دریافت میکند.

## آدرس

```
/api/user/password/forgot/change
```

## درخواست

```json
{
  "portal_id": 0,
  "mobile_email": "",
  "new_password": "",
  "security_code": "",
  "confirm_password": ""
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `portal_id` | integer (int64) | شناسه پورتال |
| `mobile_email` | string | شماره موبایل یا ایمیل |
| `new_password` | string | پسورد جدید |
| `security_code` | string | کد امنیتی |
| `confirm_password` | string | تایید پسورد |

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
