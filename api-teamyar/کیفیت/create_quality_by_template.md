# ایجاد کیفیت از طریق الگو

## آدرس

```
/api/create_quality_by_template
```

## درخواست

```json
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
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `title` | string | عنوانی که به اسم الگو اضافه میگردد |
| `module_id` | integer (int64) | شناسه ماژول |
| `product_id` | integer (int64) | شناسه کالا |
| `description` | string | توضیحات کیفیت |
| `refrence_id` | integer (int64) | شناسه مرجع(شناسه عملیات مورد نظر در ماژول مربوطه) |
| `template_id*` | integer (int64) | شناسه الگویی که میخواهیم از روی آن کیفیت ایجاد شود. |
| `evaluator_ids[]` | array | شناسه ارزیابی کنندگان |
| `refrence_type` | integer (int32) | نوع مرجع |
| `evaluator_type` | integer (int32) | نوع ارزیابی کننده :POLL_EVALUATOR_TYPE_PROFILE =0,POLL_EVALUATOR_TYPE_HR =1,POLL_EVALUATOR_TYPE_CRM =2 |
| `qc_sample_num_str` | string | تعداد نمونه |
| `reference_detail_id` | integer (int64) | شناسه جزئیات مرجع (شناسه سطر های عملیات مورد نظر در ماژول مربوطه) |

## پاسخ

```json
{
  "data": {
    "id": 0
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
| `data.id` | integer (int64) | شناسه کیفیت ایجاد شده |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
