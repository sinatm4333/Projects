# ایجاد توکن جهت لاگین در پورتال

دریافت توکن برای استفاده در فرایند ورود به پورتال.

## آدرس

```
/api/user/login/token
```

## درخواست

بدون بدنه.

## پاسخ

```json
{
  "data": { "token": "" },
  "error": { "status": 0, "message": "" },
  "success": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data.token` | string | توکن ایجادشده |
| `error.status` | number | کد خطا |
| `error.message` | string | پیام خطا |
| `success` | number | نتیجه اجرا |

## مرتبط

- [لاگین کردن در پورتال](user_login.md) — توکن در فیلد `token` آن استفاده می‌شود.
