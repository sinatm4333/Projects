# سر برگ و پاورقی (برای قرارداد خرید)

سر برگ و پاورقی را برای قرارداد خرید درج می‌کند.

## آدرس

```
/api/invoice/update/header_footer
```

## درخواست

```json
{
  "footer": "",
  "header": "",
  "invoice_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `footer` | string | پاورقی |
| `header` | string | سربرگ |
| `invoice_id` | integer (int64) | شناسه عملیات |

## پاسخ

```json
{
  "data": {
    "error": "",
    "invoice_id": 0
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
| `data.error` | string | جزئیات خطای اجرای API |
| `data.invoice_id` | integer (int64) | شناسه عملیات |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
