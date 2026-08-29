# دریافت لیست شناسه مشتریان در مرحله پروژه

دریافت لیست شناسه مشتریان در مرحله پروژه با شناسه مرحله

## آدرس

```
/api/project/getProjectStageCRMs
```

## درخواست

```json
{
  "id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) | شناسه مرحله |

## پاسخ

```json
{
  "data": {
    "crms": [
      0
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
| `data.crms[]` | array | لیست شناسه مشتریان |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
