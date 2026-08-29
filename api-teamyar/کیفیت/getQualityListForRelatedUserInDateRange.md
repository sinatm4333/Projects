# گرفتن کیفیت ها در یک بازه مهلت مشخص

مربطو به ماژول پرسنلی

## آدرس

```
/api/getQualityListForRelatedUserInDateRange
```

## درخواست

```json
{
  "org_id": 0,
  "date_to": 0,
  "date_from": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `org_id` | integer (int64) | شناسه سازمان |
| `date_to` | integer (int64) | تا تاریخ |
| `date_from` | integer (int64) | از تاریخ |

## پاسخ

```json
{
  "data": {
    "qualities": [
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
| `data` | object | آبجکت اصلی |
| `data.qualities[]` | array | کیفیت ها |
| `data.qualities[].id` | integer (int64) | شناسه |
| `data.qualities[].name` | string | عنوان |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
