# تامین کنندگان کالا

با این api،می توان در شناسنامه کالا اطلاعات مربوط به تامین کنندگان را ایجاد کرد.

## آدرس

```
/api/update_product_providers
```

## درخواست

```json
{
  "org_id": 0,
  "lot_size": 0,
  "lead_time": 0,
  "product_id": 0,
  "provider_id": 0,
  "standard_deviation": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `org_id` | integer (int64) | شناسه شعبه |
| `lot_size` | integer (int64) | حجم (مقدار) سفارش |
| `lead_time` | integer (int64) | زمان انتظار / تحویل |
| `product_id` | integer (int64) | تامین‌کننده |
| `provider_id` | integer (int64) | شناسه ارائه دهنده |
| `standard_deviation` | integer (int64) | انحراف معیار |

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
