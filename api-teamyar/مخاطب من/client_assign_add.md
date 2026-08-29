# اضافه کردن مطلع به مشتری

اضافه کردن مطلع به مشتری با داشتن شناسه مشتری و شناسه کاربر

## آدرس

```
/api/client/assign/add
```

## درخواست

```json
{
  "id": 0,
  "assigns": [
    0
  ]
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) | شناسه مشتری |
| `assigns[]` | array | لیست مطلعین |

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
