# /api/get_identify_inventory

درخواست

## آدرس

```
/api/get_identify_inventory
```

## درخواست

```json
{
  "org_id": 0,
  "date_to": 0,
  "date_from": 0,
  "product_name": "",
  "field_filters": [
    {
      "field_id": 0,
      "field_value": ""
    }
  ],
  "fiscal_year_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `org_id` | integer (int64) |  |
| `date_to` | integer (int64) |  |
| `date_from` | integer (int64) |  |
| `product_name` | string |  |
| `field_filters[]` | array |  |
| `field_filters[].field_id` | integer (int64) |  |
| `field_filters[].field_value` | string |  |
| `fiscal_year_id` | integer (int64) |  |

## پاسخ

```json
{
  "data": [
    {
      "stock_id": 0,
      "product_id": 0,
      "receipt_id": 0,
      "stock_code": "",
      "stock_name": "",
      "attribute_id": 0,
      "product_code": "",
      "product_name": "",
      "receipt_code": "",
      "receipt_cost": 0,
      "receipt_date": 0,
      "dynamic_fields": [
        {
          "value": "",
          "field_id": 0,
          "field_name": "",
          "field_type": 0
        }
      ],
      "remain_quantity": 0,
      "receipt_quantity": 0,
      "receipt_detail_id": 0
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
| `data[].stock_id` | integer (int64) |  |
| `data[].product_id` | integer (int64) |  |
| `data[].receipt_id` | integer (int64) |  |
| `data[].stock_code` | string |  |
| `data[].stock_name` | string |  |
| `data[].attribute_id` | integer (int64) |  |
| `data[].product_code` | string |  |
| `data[].product_name` | string |  |
| `data[].receipt_code` | string |  |
| `data[].receipt_cost` | integer (int64) |  |
| `data[].receipt_date` | integer (int64) |  |
| `data[].dynamic_fields[]` | array |  |
| `data[].dynamic_fields[].value` | string |  |
| `data[].dynamic_fields[].field_id` | integer (int64) |  |
| `data[].dynamic_fields[].field_name` | string |  |
| `data[].dynamic_fields[].field_type` | integer (int64) |  |
| `data[].remain_quantity` | integer (int64) |  |
| `data[].receipt_quantity` | integer (int64) |  |
| `data[].receipt_detail_id` | integer (int64) |  |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
