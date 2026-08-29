# افزودن opc

برای اعمال opc

## آدرس

```
/api/get_opc_detail_by_detail_id
```

## درخواست

```json
{
  "org_id": 0,
  "detail_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `org_id` | integer (int64) | شناسه شعبه |
| `detail_id` | integer (int64) | جزییات شناسه |

## پاسخ

```json
{
  "data": {
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
| `data` | object | موضوع |
| `data.id` | integer (int64) | شناسه |
| `data.type` | integer (int32) | نوع |
| `data.force` | integer (int32) |  |
| `data.opc_id` | integer (int64) | شناسه poc |
| `data.weight` | integer (int32) | وزن |
| `data.quantity` | integer (int64) | مقدار |
| `data.description` | string | توضیحات |
| `data.detail_title` | string | رشته |
| `data.op_setting_id` | integer (int64) | عملیات تولیدی |
| `data.qc_setting_id` | integer (int64) | کنترل کیفیت |
| `data.custom_form_setting` | string | تنظیمات فرم سفارشی |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | کد خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
