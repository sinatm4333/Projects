# دریافت توضیحات مرحله و هزینه پروژه

دریافت توضیحات مرحله و هزینه پروژه با شناسه مرحله

## آدرس

```
/api/project/getProjectStageDescription
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
    "amount": 0,
    "description": ""
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
| `data.amount` | integer (int64) | هزینه پروژه |
| `data.description` | string | توضیحات مرحله |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
