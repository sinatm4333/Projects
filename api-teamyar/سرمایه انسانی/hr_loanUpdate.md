# /api/hr/loanUpdate

درخواست

## آدرس

```
/api/hr/loanUpdate
```

## درخواست

```json
{
  "id": 0,
  "type": 0,
  "amount": 0,
  "org_id": 0,
  "custom_form": "",
  "own_confirm": 0,
  "date_request": {
    "day": 0,
    "year": 0,
    "month": 0,
    "date_int64": 0
  },
  "installments": [
    {
      "date": {
        "day": 0,
        "year": 0,
        "month": 0,
        "date_int64": 0
      },
      "amount": 0
    }
  ],
  "personnel_id": 0,
  "ignore_order_range": 0,
  "date_advance_installment": {
    "day": 0,
    "year": 0,
    "month": 0,
    "date_int64": 0
  }
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) |  |
| `type` | integer (int64) |  |
| `amount` | integer (int64) |  |
| `org_id` | integer (int64) |  |
| `custom_form` | string |  |
| `own_confirm` | integer (int32) |  |
| `date_request` | object |  |
| `date_request.day` | integer (int32) |  |
| `date_request.year` | integer (int32) |  |
| `date_request.month` | integer (int32) |  |
| `date_request.date_int64` | integer (int64) |  |
| `installments[]` | array |  |
| `installments[].date` | object |  |
| `installments[].date.day` | integer (int32) |  |
| `installments[].date.year` | integer (int32) |  |
| `installments[].date.month` | integer (int32) |  |
| `installments[].date.date_int64` | integer (int64) |  |
| `installments[].amount` | integer (int64) |  |
| `personnel_id` | integer (int64) |  |
| `ignore_order_range` | integer (int32) |  |
| `date_advance_installment` | object |  |
| `date_advance_installment.day` | integer (int32) |  |
| `date_advance_installment.year` | integer (int32) |  |
| `date_advance_installment.month` | integer (int32) |  |
| `date_advance_installment.date_int64` | integer (int64) |  |

## پاسخ

```json
{
  "data": {
    "message": ""
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
| `data.message` | string |  |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
