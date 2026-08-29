# چک پسورد کاربر

بررسی صحت رمز عبور کاربر.

## آدرس

```
/api/user/password/check
```

## درخواست

```json
{
  "password": "",
  "user_name": ""
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `user_name` | string | نام کاربری |
| `password` | string | رمز عبور |

## پاسخ

```json
{
  "password": "",
  "user_name": ""
}
```

پاسخ همان ساختار درخواست را بازمی‌گرداند (echo).

## مرتبط

- [تغییر رمز کاربر](user_password_change.md)
- [لاگین کردن در پورتال](user_login.md)
