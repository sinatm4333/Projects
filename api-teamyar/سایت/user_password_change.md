# تغییر رمز کاربر

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
| `new_password` | string | پسورد جدید |
| `old_password` | string | پسورد |
| `confirm_password` | string | تایید رمز جدید |

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
