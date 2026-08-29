# تغییر رمز کاربر

تغییر رمز عبور کاربر جاری.

## آدرس

```
/api/user/password/change
```

## درخواست

```json
{
  "new_password": "",
  "old_password": "",
  "confirm_password": ""
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `old_password` | string | رمز عبور فعلی |
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

- [لاگین کردن در پورتال](user_login.md)
