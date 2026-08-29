# اضافه کردن فیلد وزن تسهیم بهای تمام شده

با این API امکان اضافه کردن فیلد وزن تسهیم بهای تمام شده در شناسنامه کالا

## آدرس

```
/api/update_product
```

## درخواست

```json
{
  "org_id": 0,
  "input_data": [
    {
      "code": "",
      "name": "",
      "depth": "",
      "width": "",
      "height": "",
      "pic_id": 0,
      "weight": "",
      "barcode": "",
      "tx_code": "",
      "location": "",
      "barcode_2": "",
      "barcode_3": "",
      "center_id": 0,
      "client_id": 0,
      "gift_type": 0,
      "account_id": 0,
      "customform": "",
      "is_service": 0,
      "product_id": 0,
      "project_id": 0,
      "setting_id": 0,
      "capacity_id": 0,
      "description": "",
      "floating_id": 0,
      "availability": 0,
      "supply_method": 0,
      "main_custom_id": 0,
      "pricing_method": 0,
      "product_type_id": 0,
      "tc_sharing_value": ""
    }
  ]
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `org_id` | integer (int64) | کد شعبه |
| `input_data[]` | array | ورودی داد |
| `input_data[].code` | string |  |
| `input_data[].name` | string |  |
| `input_data[].depth` | string |  |
| `input_data[].width` | string |  |
| `input_data[].height` | string |  |
| `input_data[].pic_id` | integer (int64) |  |
| `input_data[].weight` | string |  |
| `input_data[].barcode` | string |  |
| `input_data[].tx_code` | string |  |
| `input_data[].location` | string |  |
| `input_data[].barcode_2` | string |  |
| `input_data[].barcode_3` | string |  |
| `input_data[].center_id` | integer (int64) |  |
| `input_data[].client_id` | integer (int64) |  |
| `input_data[].gift_type` | integer (int32) |  |
| `input_data[].account_id` | integer (int64) |  |
| `input_data[].customform` | string |  |
| `input_data[].is_service` | integer (int32) |  |
| `input_data[].product_id` | integer (int64) | شناسه کالا |
| `input_data[].project_id` | integer (int64) |  |
| `input_data[].setting_id` | integer (int64) |  |
| `input_data[].capacity_id` | integer (int64) |  |
| `input_data[].description` | string |  |
| `input_data[].floating_id` | integer (int64) |  |
| `input_data[].availability` | integer (int32) | دسترس‌پذیری |
| `input_data[].supply_method` | integer (int32) |  |
| `input_data[].main_custom_id` | integer (int64) |  |
| `input_data[].pricing_method` | integer (int32) |  |
| `input_data[].product_type_id` | integer (int32) |  |
| `input_data[].tc_sharing_value` | string | وزن تسهیم بهای تمام شده |

## پاسخ

```json
{
  "data": {
    "results": [
      {
        "result": "",
        "product_id": 0
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
| `data` | object | دیتای خروجی |
| `data.results[]` | array | نتیجه آرایه |
| `data.results[].result` | string | نتیجه پیغام |
| `data.results[].product_id` | integer (int64) | شناسه کالا |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
