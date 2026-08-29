# تغییر وضعیت مودیان برای فاکتور

این API نمایش وضعیت فاکتور در مودیان را تغییر می دهد

## آدرس

```
/api/sales/update_moadian_status
```

## درخواست

```json
{
  "org_id": 0,
  "invoice_id": 0,
  "moadian_status": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `org_id` | integer (int64) | شناسه شعبه |
| `invoice_id` | integer (int64) | شناسه عملیات |
| `moadian_status` | integer (int32) | وضعیت فاکتور در سامانه مودیان |

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
