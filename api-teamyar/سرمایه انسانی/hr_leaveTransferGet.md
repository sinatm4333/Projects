# دریافت مقدار مانده مرخصی

محاسبه مانده مرخصی به ازای پرسنل بر اساس آخرین حکم یا تاریخ ورودی

## آدرس

```
/api/hr/leaveTransferGet
```

## درخواست

```json
{
  "id": 0,
  "org_id": 0,
  "date_to": 0,
  "personnel_ids": [
    0
  ]
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) | شناسه حکم پرسنل (برای یک پرسنل) -> اجباری نیست |
| `org_id` | integer (int64) |  |
| `date_to` | integer (int64) | بررسی مانده مرخصی تا تاریخ وارد شده (اجباری نیست) |
| `personnel_ids[]` | array | لیست شناسه های پرسنلی که مانده مرخصی آن ها درخواست می شود |

## پاسخ

```json
{
  "data": [
    {
      "value": 0,
      "personnel_id": 0
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
| `data[]` | array | لیست مانده مرخصی ها برای پرسنل درخواست شده |
| `data[].value` | integer (int64) | مقدار مانده مرخصی محاسبه شده |
| `data[].personnel_id` | integer (int64) | شناسه پرسنل برای مانده مرخصی محاسبه شده |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
