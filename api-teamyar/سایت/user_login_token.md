# ایجاد توکن جهت لاگین در پورتال

اگر بخواهیم بدون پسورد کاربری که قبلا احراز هویت شده را لاگین کنیم، از این api برای تولید توکن لاگین استفاده میکنیم

## آدرس

```
/api/user/login/token
```

## درخواست

```json
{
  "user_id*": 0,
  "portal_id*": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `user_id*` | integer (int64) | شناسه کاربر |
| `portal_id*` | integer (int64) | شناسه پورتال |

## پاسخ

```json
{
  "data": {
    "token": ""
  },
  "error": {
    "status": 0,
    "message": ""
  },
  "success": false
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data` | object |  |
| `data.token` | string | رشته توکن ایجاد شده |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
