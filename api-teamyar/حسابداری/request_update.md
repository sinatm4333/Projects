# /api/request/update

درخواست

## آدرس

```
/api/request/update
```

## درخواست

```json
{
  "id*": 0,
  "note": "",
  "org_id*": 0,
  "records": [
    {
      "id": 0,
      "amount": 0,
      "details": [
        {
          "id": 0,
          "type": 0,
          "amount": 0,
          "center_id": 0,
          "client_id": 0,
          "symbol_id": 0,
          "account_id": 0,
          "project_id": 0,
          "description": "",
          "floating_id": 0,
          "symbol_rate": 0,
          "currency_amount": 0
        }
      ],
      "module_id": 0,
      "symbol_id": 0,
      "invoice_id": 0,
      "symbol_rate": 0,
      "amount_input": 0
    }
  ],
  "step_id": 0,
  "task_id": 0,
  "symbol_id": 0,
  "request_date": 0,
  "request_type": 0,
  "requester_id": 0,
  "request_number": 0,
  "deleted_detail_ids": [
    0
  ],
  "deleted_record_ids": [
    0
  ]
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id*` | integer (int64) |  |
| `note` | string |  |
| `org_id*` | integer (int64) |  |
| `records[]` | array |  |
| `records[].id` | integer (int64) |  |
| `records[].amount` | integer (int64) |  |
| `records[].details[]` | array |  |
| `records[].details[].id` | integer (int64) |  |
| `records[].details[].type` | integer (int32) |  |
| `records[].details[].amount` | integer (int64) |  |
| `records[].details[].center_id` | integer (int64) |  |
| `records[].details[].client_id` | integer (int64) |  |
| `records[].details[].symbol_id` | integer (int64) |  |
| `records[].details[].account_id` | integer (int64) |  |
| `records[].details[].project_id` | integer (int64) |  |
| `records[].details[].description` | string |  |
| `records[].details[].floating_id` | integer (int64) |  |
| `records[].details[].symbol_rate` | integer (int64) |  |
| `records[].details[].currency_amount` | integer (int64) |  |
| `records[].module_id` | integer (int64) |  |
| `records[].symbol_id` | integer (int64) |  |
| `records[].invoice_id` | integer (int64) |  |
| `records[].symbol_rate` | integer (int64) |  |
| `records[].amount_input` | integer (int64) |  |
| `step_id` | integer (int64) |  |
| `task_id` | integer (int64) |  |
| `symbol_id` | integer (int64) |  |
| `request_date` | integer (int64) |  |
| `request_type` | integer (int32) |  |
| `requester_id` | integer (int64) |  |
| `request_number` | integer (int64) |  |
| `deleted_detail_ids[]` | array |  |
| `deleted_record_ids[]` | array |  |

## پاسخ

```json
{
  "data": {
    "request_id": 0
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
| `data.request_id` | integer (int64) |  |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
