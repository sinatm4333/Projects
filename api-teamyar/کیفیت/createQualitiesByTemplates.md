# ایجاد کیفیت با الگو

ایجاد کیفیت با انتخاب الگو

## آدرس

```
/api/createQualitiesByTemplates
```

## درخواست

```json
{
  "qcs": [
    {
      "title": "",
      "module_id": 0,
      "product_id": 0,
      "description": "",
      "refrence_id": 0,
      "template_id*": 0,
      "evaluator_ids": [
        0
      ],
      "refrence_type": 0,
      "evaluator_type": 0,
      "qc_sample_num_str": "",
      "reference_detail_id": 0
    }
  ]
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `qcs[]` | array | کنترل کیفیت |
| `qcs[].title` | string | عنوان |
| `qcs[].module_id` | integer (int64) | شناسه ماژول (شناسه ی جدول HOME_MODULE_LIST) |
| `qcs[].product_id` | integer (int64) | شناسه کالا از جدول "wh_product" |
| `qcs[].description` | string | توضیحات |
| `qcs[].refrence_id` | integer (int64) | منبع فراخوانی تست پلن چون ممکن است این تست پلن توسط یک بخش دیگر ایجاد شده باشد(مثلا توسط یک فاکتور در ماژول انبار یا ماژول تولید)(شناسه جدول WH_OPERATION) |
| `qcs[].template_id*` | integer (int64) | شناسه الگو |
| `qcs[].evaluator_ids[]` | array | ارزیابی کنندگان |
| `qcs[].refrence_type` | integer (int32) | نوع سند فراخوانی |
| `qcs[].evaluator_type` | integer (int32) | نوع ارزیابی کننده |
| `qcs[].qc_sample_num_str` | string | تعداد نمونه (فقط برای نوع ارزیابی شونده ، کنترل کیفیت کالا) |
| `qcs[].reference_detail_id` | integer (int64) | شناسه رکورد سند فراخوانی |

## پاسخ

```json
{
  "error": {
    "status": 0,
    "message": ""
  },
  "success": false
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
