# چک پسورد کاربر

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
| `password` | string | رمز |
| `user_name` | string | نام کاربر |

## پاسخ

```json
{
  "data": {
    "valid_password": false
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
| `data` | object | چک رمز |
| `data.valid_password` | boolean | بولین برای تایید پسورد |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
