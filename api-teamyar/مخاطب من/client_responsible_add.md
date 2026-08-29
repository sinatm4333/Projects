# اضافه کردن مسئول به مشتری

اضافه کردن مسئول به مشتری با داشتن شناسه مشتری و شناسه کاربر

## آدرس

```
/api/client/responsible/add
```

## درخواست

```json
{
  "id": 0,
  "responsibles": [
    0
  ]
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) | شناسه مشتری |
| `responsibles[]` | array | لیست مسئولین |

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
