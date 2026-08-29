# فراموشی رمز عبور

تعیین رمز عبور جدید در فرایند بازیابی رمز، با کد امنیتی ارسال‌شده به موبایل یا ایمیل.

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
| `portal_id` | number | شناسه پورتال |
| `mobile_email` | string | موبایل یا ایمیل کاربر |
| `security_code` | string | کد امنیتی |
| `new_password` | string | رمز عبور جدید |
| `confirm_password` | string | تکرار رمز عبور جدید |

## پاسخ

```json
{
  "error": { "status": 0, "message": "" },
  "success": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `error.status` | number | کد خطا |
| `error.message` | string | پیام خطا |
| `success` | number | نتیجه اجرا |

## مرتبط

- [تغییر رمز کاربر](user_password_change.md) — تغییر رمز با داشتن رمز فعلی.
