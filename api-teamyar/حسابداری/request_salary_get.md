# گرفتن جزئیات درخواست

برای حقوق و دستمزد استفاده میشود

## آدرس

```
/api/request/salary/get
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
| `org_id` | integer (int64) | شناسه سازمان |
| `module_id` | integer (int64) | شناسه ماژول |
| `invoice_id` | integer (int64) | شناسه فاکتور |
| `request_id` | integer (int64) | شناسه درخواست |

## پاسخ

```json
{
  "data": [
    {
      "id": 0,
      "amount": 0,
      "org_id": 0,
      "center_id": 0,
      "client_id": 0,
      "account_id": 0,
      "project_id": 0,
      "request_id": 0,
      "floating_id": 0,
      "record_invoice_id": 0,
      "request_record_id": 0
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
| `data[]` | array | پارامترها |
| `data[].id` | integer (int64) | شناسه رکورد |
| `data[].amount` | integer (int64) | مبلغ درخواست |
| `data[].org_id` | integer (int64) | شناسه سازمان |
| `data[].center_id` | integer (int64) | شناسه مرکز |
| `data[].client_id` | integer (int64) | شناسه شخص |
| `data[].account_id` | integer (int64) | شناسه حساب |
| `data[].project_id` | integer (int64) | شناسه پروژه |
| `data[].request_id` | integer (int64) | شناسه درخواست |
| `data[].floating_id` | integer (int64) | شناسه شناور |
| `data[].record_invoice_id` | integer (int64) | شناسه عملیات |
| `data[].request_record_id` | integer (int64) | شناسه رکورد حسابداری |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
