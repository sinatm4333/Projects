# /api/get_budget_amount

درخواست

## آدرس

```
/api/get_budget_amount
```

## درخواست

```json
{
  "org_id": 0,
  "budget_id": 0,
  "center_id": 0,
  "period_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `org_id` | integer (int64) |  |
| `budget_id` | integer (int64) |  |
| `center_id` | integer (int64) |  |
| `period_id` | integer (int64) |  |

## پاسخ

```json
{
  "data": [
    {
      "amount": ""
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
| `data[]` | array |  |
| `data[].amount` | string |  |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
