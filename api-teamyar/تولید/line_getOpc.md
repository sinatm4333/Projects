# دریافت اطلاعات یک OPC

با ارسال شناسه تمامی اطلاعات OPC قابل دریافت است

## آدرس

```
/api/line/getOpc
```

## درخواست

```json
{
  "opc_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `opc_id` | integer (int64) | شناسه نمودار فرآیند تولید |

## پاسخ

```json
{
  "data": {
    "bom": [
      {
        "id": 0,
        "name": ""
      }
    ],
    "code": 0,
    "title": "",
    "opc_id": 0,
    "org_id": 0,
    "line_id": 0,
    "product": [
      {
        "id": 0,
        "name": "",
        "group_id": 0
      }
    ],
    "opc_dets": [
      {
        "id": 0,
        "tools": [
          {
            "id": 0,
            "name": "",
            "capacity": 0,
            "product_id": 0,
            "attribute_id": 0
          }
        ],
        "dep_type": 0,
        "duration": 0,
        "operation": [
          {
            "id": 0,
            "name": ""
          }
        ],
        "qc_setting": [
          {
            "id": 0,
            "name": ""
          }
        ],
        "description": "",
        "work_center": [
          {
            "id": 0,
            "name": ""
          }
        ],
        "qc_mandatory": 0,
        "waste_percent": 0,
        "operator_count": 0,
        "produced_product": [
          {
            "id": 0,
            "name": "",
            "group_id": 0
          }
        ],
        "completion_percent": 0,
        "consuming_materials": [
          {
            "id": 0,
            "name": "",
            "group_id": 0
          }
        ]
      }
    ],
    "bench_stock": [
      {
        "id": 0,
        "name": ""
      }
    ],
    "description": "",
    "default_step": 0,
    "half_made_Stock": [
      {
        "id": 0,
        "name": ""
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
| `data` | object | آبجکت اصلی |
| `data.bom[]` | array | اطلاعات BOM |
| `data.bom[].id` | integer (int64) | شناسه BOM |
| `data.bom[].name` | string | عنوان BOM |
| `data.code` | integer (int64) | شناسه OPC |
| `data.title` | string | عنوان |
| `data.opc_id` | integer (int64) | شناسه سیستمی OPC |
| `data.org_id` | integer (int64) | شناسه سازمان |
| `data.line_id` | integer (int64) | شناسه خط تولید |
| `data.product[]` | array | اطلاعات محصولی که برای opc انتخاب شده است |
| `data.product[].id` | integer (int64) | شناسه سیستمی محصول اصلی OPC |
| `data.product[].name` | string | نام محصول OPC |
| `data.product[].group_id` | integer (int64) | شناسه گروه کالا |
| `data.opc_dets[]` | array | جزئیات OPC |
| `data.opc_dets[].id` | integer (int64) | شناسه جزئیات OPC |
| `data.opc_dets[].tools[]` | array | ابزار مصرفی |
| `data.opc_dets[].tools[].id` | integer (int64) | شناسه ابزار مصرفی |
| `data.opc_dets[].tools[].name` | string | عنوان ابزار مصرفی |
| `data.opc_dets[].tools[].capacity` | integer (int64) | ظرفیت ابزار مصرفی |
| `data.opc_dets[].tools[].product_id` | integer (int64) | شناسه کالای ابزار مصرفی |
| `data.opc_dets[].tools[].attribute_id` | integer (int64) | شناسه ویژگی ابزار مصرفی |
| `data.opc_dets[].dep_type` | integer (int64) | نوع وابستگی |
| `data.opc_dets[].duration` | integer (int64) | مدت زمان انجام عملیات به میلی ثانیه |
| `data.opc_dets[].operation[]` | array | عملیات تولیدی |
| `data.opc_dets[].operation[].id` | integer (int64) | شناسه عملیات تولیدی |
| `data.opc_dets[].operation[].name` | string | نام عملیات تولیدی |
| `data.opc_dets[].qc_setting[]` | array | کنترل کیفیت |
| `data.opc_dets[].qc_setting[].id` | integer (int64) | شناسه کنترل کیفیت |
| `data.opc_dets[].qc_setting[].name` | string | نام کنترل کیفیت |
| `data.opc_dets[].description` | string | توضیحات |
| `data.opc_dets[].work_center[]` | array | مرکز کاری |
| `data.opc_dets[].work_center[].id` | integer (int64) | شناسه مرکز کاری |
| `data.opc_dets[].work_center[].name` | string | نام مرکز کاری |
| `data.opc_dets[].qc_mandatory` | integer (int32) | کیفیت اجبار |
| `data.opc_dets[].waste_percent` | integer (int64) | در صورت ضایعات عملیاتی |
| `data.opc_dets[].operator_count` | integer (int64) | تعداد اپراتور |
| `data.opc_dets[].produced_product[]` | array | محصول تولید شده |
| `data.opc_dets[].produced_product[].id` | integer (int64) | شناسه |
| `data.opc_dets[].produced_product[].name` | string | نام کالا |
| `data.opc_dets[].produced_product[].group_id` | integer (int64) | شناسه گروه کالا |
| `data.opc_dets[].completion_percent` | integer (int64) | درصد تکمیل |
| `data.opc_dets[].consuming_materials[]` | array | مواد مصرفی |
| `data.opc_dets[].consuming_materials[].id` | integer (int64) | شناسه |
| `data.opc_dets[].consuming_materials[].name` | string | نام کالا (مواد اولیه مصرفی) |
| `data.opc_dets[].consuming_materials[].group_id` | integer (int64) | شناسه گروه کالا |
| `data.bench_stock[]` | array | انبار پای کار |
| `data.bench_stock[].id` | integer (int64) | شناسه انبار |
| `data.bench_stock[].name` | string | نام انبار |
| `data.description` | string | توضیحات |
| `data.default_step` | integer (int32) | مرحله پیش فرض |
| `data.half_made_Stock[]` | array | انبار نیمه ساخته |
| `data.half_made_Stock[].id` | integer (int64) | شناسه انبار |
| `data.half_made_Stock[].name` | string | نام انبار |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | int32وضعیت:پیشنویسبررسیانجامکاملباطل |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
