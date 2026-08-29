# ارسال کد امنیتی

ارسال کد امنیتی به موبایل یا ایمیل کاربر در فرایند بازیابی رمز عبور.

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
| `portal_id` | number | شناسه پورتال |
| `mobile_email` | string | موبایل یا ایمیل کاربر |
| `lang_id` | number | شناسه زبان |

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

- [فراموشی رمز عبور](user_password_forgot_change.md) — کد ارسال‌شده در فیلد `security_code` آن استفاده می‌شود.
