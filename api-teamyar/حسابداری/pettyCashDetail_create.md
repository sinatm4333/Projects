# /api/pettyCashDetail/create

درخواست

## آدرس

```
/api/pettyCashDetail/create
```

## درخواست

```json
{
  "note": "",
  "org_id": 0,
  "records": [
    {
      "note": "",
      "radif": 0,
      "amount": 0,
      "org_id": 0,
      "invoice_id": 0,
      "description": ""
    }
  ],
  "p_cash_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `note` | string |  |
| `org_id` | integer (int64) |  |
| `records[]` | array |  |
| `records[].note` | string |  |
| `records[].radif` | integer (int32) |  |
| `records[].amount` | integer (int64) |  |
| `records[].org_id` | integer (int64) |  |
| `records[].invoice_id` | integer (int64) |  |
| `records[].description` | string |  |
| `p_cash_id` | integer (int64) |  |

## پاسخ

```json
{
  "data": {
    "id": 0
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
| `data` | object |  |
| `data.id` | integer (int64) |  |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
