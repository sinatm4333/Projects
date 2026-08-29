# دریافت نام گزارش

دریافت نام گزارش بر اساس شناسه گزارش یا شناسه یکتای گزارش (UUID)

## آدرس

```
/api/reports/name
```

## درخواست

```json
[
  {
    "id": 0,
    "uuid": ""
  }
]
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) | شناسه گزارش |
| `uuid` | string | شناسه یکتای گزارش (UUID) |

## پاسخ

```json
{
  "data": [
    {
      "id": 0,
      "name": "",
      "uuid": ""
    }
  ],
  "error": {
    "status": 0,
    "message": ""
  },
  "success": false
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data[]` | array | لیست گزارش ها |
| `data[].id` | integer (int64) | شناسه گزارش |
| `data[].name` | string | نام گزارش |
| `data[].uuid` | string | شناسه یکتای گزارش (UUID) |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
