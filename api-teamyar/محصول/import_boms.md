# درون ریزی BOM

ورودی این API شناسه سازمان و آرایه آبجکتی از BOMها است.

## آدرس

```
/api/import_boms
```

## درخواست

```json
{
  "boms": [
    {
      "details": [
        {
          "product_id": 0,
          "waste_type": 0,
          "description": "",
          "waste_value": 0,
          "attribute_id": 0,
          "product_code": "",
          "multiple_type": 0,
          "multiple_value": 0,
          "attribute_barcode": "",
          "replacement_products": [
            {
              "replace_product_id": 0,
              "replace_attribute_id": 0,
              "replace_product_code": "",
              "replace_attribute_barcode": ""
            }
          ]
        }
      ],
      "product_id": 0,
      "attribute_id": 0,
      "product_code": "",
      "attribute_barcode": ""
    }
  ],
  "org_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `boms[]` | array | آرایه bom ها |
| `boms[].details[]` | array | جزییات آرایه |
| `boms[].details[].product_id` | integer (int64) | کد کالا |
| `boms[].details[].waste_type` | integer (int32) | نوع ضایعات |
| `boms[].details[].description` | string | توضیحات |
| `boms[].details[].waste_value` | integer (int32) | میزان ضایعات |
| `boms[].details[].attribute_id` | integer (int64) | شناسه ویژگی |
| `boms[].details[].product_code` | string | کد کالا |
| `boms[].details[].multiple_type` | integer (int32) | نوع ضریب |
| `boms[].details[].multiple_value` | number (double) | ضریب تفکیک |
| `boms[].details[].attribute_barcode` | string | بارکد ویژگی |
| `boms[].details[].replacement_products[]` | array | کالاهای آستانه تعویض |
| `boms[].details[].replacement_products[].replace_product_id` | integer (int64) | شناسه کالای جایگزین |
| `boms[].details[].replacement_products[].replace_attribute_id` | integer (int64) | شناسه ویژگی جایگزین |
| `boms[].details[].replacement_products[].replace_product_code` | string | کد کالای جایگزین |
| `boms[].details[].replacement_products[].replace_attribute_barcode` | string | بارکد ویژگی جایگزین |
| `boms[].product_id` | integer (int64) | کد کالا |
| `boms[].attribute_id` | integer (int64) | شناسه ویژگی |
| `boms[].product_code` | string | کد کالا |
| `boms[].attribute_barcode` | string | بارکد ویژگی |
| `org_id` | integer (int64) | شناسه شعبه |

## پاسخ

```json
{
  "data": {
    "result": [
      0
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
| `data` | object | آیتم های دیتا |
| `data.result[]` | array | نتیجه آرایه ها |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
