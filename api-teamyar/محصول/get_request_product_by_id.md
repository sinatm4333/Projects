# /api/get_request_product_by_id

درخواست

## آدرس

```
/api/get_request_product_by_id
```

## درخواست

```json
{
  "id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) |  |

## پاسخ

```json
{
  "data": {
    "id": 0,
    "code": "",
    "org_id": 0,
    "ref_id": 0,
    "status": 0,
    "deleted": 0,
    "details": [
      {
        "id": 0,
        "code": "",
        "status": 0,
        "reserve": 0,
        "unit_id": 0,
        "stock_id": 0,
        "unit_name": "",
        "product_id": 0,
        "stock_name": "",
        "date_demand": 0,
        "attribute_id": 0,
        "date_confirm": 0,
        "main_unit_id": 0,
        "product_name": "",
        "quantity_valid": 0,
        "quantity_demand": 0,
        "quantity_valid_main": 0,
        "quantity_demand_main": 0
      }
    ],
    "step_id": 0,
    "task_id": 0,
    "ref_type": 0,
    "stock_id": 0,
    "author_id": 0,
    "module_id": 0,
    "code_number": 0,
    "date_create": 0,
    "description": "",
    "modified_id": 0,
    "date_confirm": 0,
    "date_request": 0,
    "request_type": 0,
    "requesting_unit": 0,
    "consumption_unit": 0
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
| `data.code` | string |  |
| `data.org_id` | integer (int64) |  |
| `data.ref_id` | integer (int64) |  |
| `data.status` | integer (int32) |  |
| `data.deleted` | integer (int32) |  |
| `data.details[]` | array |  |
| `data.details[].id` | integer (int64) |  |
| `data.details[].code` | string |  |
| `data.details[].status` | integer (int32) |  |
| `data.details[].reserve` | integer (int32) |  |
| `data.details[].unit_id` | integer (int64) |  |
| `data.details[].stock_id` | integer (int64) |  |
| `data.details[].unit_name` | string |  |
| `data.details[].product_id` | integer (int64) |  |
| `data.details[].stock_name` | string |  |
| `data.details[].date_demand` | integer (int64) |  |
| `data.details[].attribute_id` | integer (int64) |  |
| `data.details[].date_confirm` | integer (int64) |  |
| `data.details[].main_unit_id` | integer (int64) |  |
| `data.details[].product_name` | string |  |
| `data.details[].quantity_valid` | integer (int64) |  |
| `data.details[].quantity_demand` | integer (int64) |  |
| `data.details[].quantity_valid_main` | integer (int64) |  |
| `data.details[].quantity_demand_main` | integer (int64) |  |
| `data.step_id` | integer (int64) |  |
| `data.task_id` | integer (int64) |  |
| `data.ref_type` | integer (int32) |  |
| `data.stock_id` | integer (int64) |  |
| `data.author_id` | integer (int64) |  |
| `data.module_id` | integer (int64) |  |
| `data.code_number` | integer (int64) |  |
| `data.date_create` | integer (int64) |  |
| `data.description` | string |  |
| `data.modified_id` | integer (int64) |  |
| `data.date_confirm` | integer (int64) |  |
| `data.date_request` | integer (int64) |  |
| `data.request_type` | integer (int32) |  |
| `data.requesting_unit` | integer (int64) |  |
| `data.consumption_unit` | integer (int64) |  |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
