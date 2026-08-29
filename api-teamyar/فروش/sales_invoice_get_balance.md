# مبلغ و مانده فاکتور

محاسبه ی مبلغ کل فاکتور و مانده فاکتور فروش

## آدرس

```
/api/sales/invoice/get_balance
```

## درخواست

```json
{
  "org_id": 0,
  "invoice_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `org_id` | integer (int64) | شناسه شعبه |
| `invoice_id` | integer (int64) | شناسه عملیات |

## پاسخ

```json
{
  "data": {
    "total_amount": "",
    "remaining_amount": ""
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
| `data` | object | داده خروجی |
| `data.total_amount` | string | مبلغ کل فاکتور |
| `data.remaining_amount` | string | مبلغ مانده فاکتور |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
