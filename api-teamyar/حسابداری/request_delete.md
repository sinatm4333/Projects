# حذف درخواست خزانه داری

## آدرس

```
/api/request/delete
```

## درخواست

```json
{
  "org_id": 0,
  "module_id": 0,
  "invoice_id": 0,
  "request_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `org_id` | integer (int64) | شناسه شعبه |
| `module_id` | integer (int64) | شناسه ماژول |
| `invoice_id` | integer (int64) | شناسه فاکتور |
| `request_id` | integer (int64) | شناسه درخواست |

## پاسخ

```json
{
  "data": {
    "error_data": ""
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
| `data` | object | دیتای خروجی |
| `data.error_data` | string | خطا |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
