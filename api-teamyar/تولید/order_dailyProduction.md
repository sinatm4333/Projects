# ایجاد ثبت عملکرد روزانه

ایجاد ثبت عملکرد با بات

## آدرس

```
/api/order/dailyProduction
```

## درخواست

```json
{
  "details": [
    {
      "line_id": 0,
      "quantity": "",
      "product_id": 0,
      "operator_id": 0,
      "attribute_id": 0
    }
  ],
  "receipt_date": 0,
  "operation_date": 0,
  "transference_date": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `details[]` | array | جزئیات |
| `details[].line_id` | integer (int64) | شناسه خط تولید |
| `details[].quantity` | string | مقدار/تعداد |
| `details[].product_id` | integer (int64) | شناسه سیستمی کالا |
| `details[].operator_id` | integer (int64) | شناسه اپراتور |
| `details[].attribute_id` | integer (int64) | شناسه ویژگی کالا |
| `receipt_date` | integer (int64) | تاریخ رسید |
| `operation_date` | integer (int64) | تاریخ عملیات |
| `transference_date` | integer (int64) | تاریخ عملیات |

## پاسخ

```json
{
  "data": {
    "err": ""
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
| `data.err` | string | خطا |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
