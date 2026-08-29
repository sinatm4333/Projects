# افزودن opc

با اینapi،می توان opc ایجاد کرد

## آدرس

```
/api/get_opc_details_by_opc_id
```

## درخواست

```json
{
  "id": 0,
  "org_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) | شناسه |
| `org_id` | integer (int64) | شناسه شعبه |

## پاسخ

```json
{
  "data": [
    {
      "id": 0,
      "type": 0,
      "force": 0,
      "opc_id": 0,
      "weight": 0,
      "quantity": 0,
      "description": "",
      "detail_title": "",
      "op_setting_id": 0,
      "qc_setting_id": 0,
      "custom_form_setting": ""
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
| `data[]` | array | آرایه |
| `data[].id` | integer (int64) | شناسه |
| `data[].type` | integer (int32) | نوع |
| `data[].force` | integer (int32) |  |
| `data[].opc_id` | integer (int64) | عملیات تولیدی |
| `data[].weight` | integer (int32) | وزن |
| `data[].quantity` | integer (int64) | کنترل کیفیت |
| `data[].description` | string | توضیحات |
| `data[].detail_title` | string | رشته |
| `data[].op_setting_id` | integer (int64) | عملیات تولیدی |
| `data[].qc_setting_id` | integer (int64) | کنترل کیفیت |
| `data[].custom_form_setting` | string | تنظیمات فرم سفارشی |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
