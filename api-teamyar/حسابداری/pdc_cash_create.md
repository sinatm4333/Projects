# /api/pdc/cash/create

درخواست

## آدرس

```
/api/pdc/cash/create
```

## درخواست

```json
{
  "cashes": [
    {
      "kind": 0,
      "note": "",
      "type": 0,
      "amount": 0,
      "pos_id": 0,
      "ref_id": 0,
      "receiver": {
        "center_id": 0,
        "client_id": 0,
        "account_id": 0,
        "project_id": 0,
        "floating_id": 0,
        "force_client": 0,
        "force_project": 0,
        "force_floating": 0,
        "force_cost_center": 0,
        "force_revenue_center": 0
      },
      "ref_type": 0,
      "requests": [
        0
      ],
      "center_id": 0,
      "client_id": 0,
      "symbol_id": 0,
      "invoice_id": 0,
      "project_id": 0,
      "date_create": 0,
      "floating_id": 0,
      "symbol_rate": 0,
      "amount_symbol": 0,
      "serial_number": "",
      "bank_account_id": 0
    }
  ],
  "org_id": 0,
  "unit_id": 0,
  "pdc_type": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `cashes[]` | array |  |
| `cashes[].kind` | integer (int32) |  |
| `cashes[].note` | string |  |
| `cashes[].type` | integer (int32) |  |
| `cashes[].amount` | integer (int64) |  |
| `cashes[].pos_id` | integer (int64) |  |
| `cashes[].ref_id` | integer (int64) |  |
| `cashes[].receiver` | object |  |
| `cashes[].receiver.center_id` | integer (int64) |  |
| `cashes[].receiver.client_id` | integer (int64) |  |
| `cashes[].receiver.account_id` | integer (int64) |  |
| `cashes[].receiver.project_id` | integer (int64) |  |
| `cashes[].receiver.floating_id` | integer (int64) |  |
| `cashes[].receiver.force_client` | integer (int32) |  |
| `cashes[].receiver.force_project` | integer (int32) |  |
| `cashes[].receiver.force_floating` | integer (int32) |  |
| `cashes[].receiver.force_cost_center` | integer (int32) |  |
| `cashes[].receiver.force_revenue_center` | integer (int32) |  |
| `cashes[].ref_type` | integer (int32) |  |
| `cashes[].requests[]` | array |  |
| `cashes[].center_id` | integer (int64) |  |
| `cashes[].client_id` | integer (int64) |  |
| `cashes[].symbol_id` | integer (int64) |  |
| `cashes[].invoice_id` | integer (int64) |  |
| `cashes[].project_id` | integer (int64) |  |
| `cashes[].date_create` | integer (int64) |  |
| `cashes[].floating_id` | integer (int64) |  |
| `cashes[].symbol_rate` | integer (int64) |  |
| `cashes[].amount_symbol` | integer (int64) |  |
| `cashes[].serial_number` | string |  |
| `cashes[].bank_account_id` | integer (int64) |  |
| `org_id` | integer (int64) |  |
| `unit_id` | integer (int64) |  |
| `pdc_type` | integer (int32) |  |

## پاسخ

```json
{
  "data": {
    "cashes": [
      0
    ],
    "errors": [
      {
        "index": 0,
        "message": ""
      }
    ]
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
| `data.cashes[]` | array |  |
| `data.errors[]` | array |  |
| `data.errors[].index` | integer (int32) |  |
| `data.errors[].message` | string |  |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
