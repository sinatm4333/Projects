# ثبت لاگ برای عملیات های فروش

برای عملیاتهای فروش می توان تاریخچه ایجاد کرد.

## آدرس

```
/api/sales/update_invoice_history
```

## درخواست

```json
{
  "org_id": 0,
  "history": "",
  "invoice_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `org_id` | integer (int64) | شناسه شعبه |
| `history` | string | تاریخچه |
| `invoice_id` | integer (int64) | شناسه عملیات |

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
