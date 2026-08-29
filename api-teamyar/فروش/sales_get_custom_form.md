# دریافت اطلاعات فرم سفارشی

با این API می‌توان اطلاعات فرم سفارشی یک شناسه به‌خصوص را دریافت کرد.

## آدرس

```
/api/sales/get_custom_form
```

## درخواست

```json
{
  "id": 0,
  "type": 0,
  "org_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) | شناسه عملیات یا شناسه تنظیمات |
| `type` | integer (int32) | نوع فرم |
| `org_id` | integer (int64) | شناسه شعبه |

## پاسخ

```json
{
  "data": {
    "form_data": ""
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
| `data` | object | اطلاعات خروجی |
| `data.form_data` | string | اطلاعات فرم |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
