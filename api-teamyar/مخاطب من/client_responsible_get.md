# دریافت مسئولین مشتری

دریافت لیست کاربران مسئول شده بر روی مشتری

## آدرس

```
/api/client/responsible/get
```

## درخواست

```json
{
  "id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) | شناسه مشتری |

## پاسخ

```json
{
  "data": {
    "id": 0,
    "responsibles": [
      {
        "id": 0,
        "name": ""
      }
    ]
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
| `data.id` | integer (int64) | شناسه مشتری |
| `data.responsibles[]` | array | لیست مسئولین |
| `data.responsibles[].id` | integer (int64) | شناسه کاربر |
| `data.responsibles[].name` | string | نام کاربر |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
