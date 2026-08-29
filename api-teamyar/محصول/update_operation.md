# ایجاد عملیات

با این api می‌توان در محصول عملیات ایجاد کرد

## آدرس

```
/api/update_operation
```

## درخواست

```json
{
  "id": 0,
  "details": [
    {
      "unit_id": 0,
      "quantity": "",
      "stock_code": "",
      "center_code": "",
      "center_type": 0,
      "client_code": "",
      "description": "",
      "expire_date": 0,
      "symbol_rate": "",
      "account_code": "",
      "attribute_id": 0,
      "cost_of_good": "",
      "product_code": "",
      "project_code": "",
      "rp_detail_id": 0,
      "floating_code": "",
      "client_name_row": "",
      "production_date": 0,
      "destination_code": "",
      "pre_invoice_detail_id": 0
    }
  ],
  "step_id": 0,
  "task_id": 0,
  "author_id": 0,
  "import_id": 0,
  "symbol_id": "",
  "project_id": "",
  "client_name": "",
  "code_number": 0,
  "description": "",
  "floating_id": "",
  "date_operation": 0,
  "operation_type": 0,
  "project_unit_id": "",
  "requesting_unit_id": "",
  "consumption_unit_id": "",
  "client_id_accounting": ""
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) | شناسه عملیات مرجع است. به عنوان import_id در نظر گرفته می‌شود (تا از ایمپورت چندباره‌ی یک عملیات مرجع جلوگیری شود.) |
| `details[]` | array | آرایه مربوط به سطرها |
| `details[].unit_id` | integer (int64) | شناسه واحد |
| `details[].quantity` | string | مقدار کالا |
| `details[].stock_code` | string | کد انبار |
| `details[].center_code` | string | حساب هزینه (کد مرکز) |
| `details[].center_type` | integer (int32) | نوع مرکز (هزینه 1، درآمد 2) |
| `details[].client_code` | string | حساب هزینه (کد شخص) |
| `details[].description` | string | توضیحات سطر |
| `details[].expire_date` | integer (int64) | تاریخ انقضا |
| `details[].symbol_rate` | string | نرخ برابری |
| `details[].account_code` | string | حساب هزینه (کد حساب) |
| `details[].attribute_id` | integer (int64) | شناسه ویژگی کالا |
| `details[].cost_of_good` | string | فی |
| `details[].product_code` | string | کد کالا |
| `details[].project_code` | string | حساب هزینه (کد پروژه) |
| `details[].rp_detail_id` | integer (int64) |  |
| `details[].floating_code` | string | حساب هزینه (کد شناور) |
| `details[].client_name_row` | string | تحویل گیرنده (در سطر - کد شخص حسابداری) |
| `details[].production_date` | integer (int64) | تاریخ تولید |
| `details[].destination_code` | string | کد انبار مقصد (مخصوص حواله / رسید انتقال) |
| `details[].pre_invoice_detail_id` | integer (int64) |  |
| `step_id` | integer (int64) |  |
| `task_id` | integer (int64) |  |
| `author_id` | integer (int64) | شناسه ایجاد کننده عملیات |
| `import_id` | integer (int64) | 0 باشد |
| `symbol_id` | string | نام اختصاری نماد (ارز) |
| `project_id` | string | کد پروژه (ماژول حسابداری) |
| `client_name` | string | نماینده تحویل دهنده (یا گیرنده) |
| `code_number` | integer (int64) | کد عملیات |
| `description` | string | توضیحات |
| `floating_id` | string | کد شناور (ماژول حسابداری) |
| `date_operation` | integer (int64) | تاریخ عملیات |
| `operation_type` | integer (int32) | نوع عملیات، شامل:رسید خرید (1)حواله فروش (2)انتقال انبار به انبار (3)حواله مصرف مرکز (4)رسید شروع دوره سیستمی (5)رسید شروع دوره دستی یا درون‌ریزی (6)رسید برگشت از فروش (7)حواله اهدایی (8)حواله تخفیفی (9)رسید تولید انبار (10)حواله دارایی (11)حواله برگشت از خرید (12)رسید اضافی انبارگردانی (14)حواله کسری انبارگردانی (15)رسید امانی (23)حواله امانی (24)رسید تولید (25)رسید برگشت امانی (26)حواله برگشت امانی (27)حواله یادداشت (منسوخ شده) (28)رسید ضایعات (29)حواله تحویل فروش (30)حواله خدمات پس از فروش (32)حواله مازاد مصرف تولید (33)رسید کسر مصرف تولید (34)حواله مصرف پروژه (35)حواله انتقال (36)رسید انتقال (37)رسید دریافت از پروژه (38)رسید سفارش تولید (39)حواله سفارش تولید (40)رسید تفکیک (44)حواله تفکیک (43)رسید داغی (45)حواله ضایعات (47)رسید برگشت از مصرف (48) |
| `project_unit_id` | string | کد پروژه مصرف کننده (مختص رسید دریافت از پروژه / حواله مصرف پروژه) |
| `requesting_unit_id` | string | کد واحد درخواست کننده (مرکز هزینه) |
| `consumption_unit_id` | string | کد واحد مصرف کننده (مرکز هزینه) |
| `client_id_accounting` | string | کد شخص تحویل دهنده / گیرنده (حسابداری) |

## پاسخ

```json
{
  "data": {
    "id": 0,
    "result": "",
    "identifier": 0
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
| `data.result` | string |  |
| `data.identifier` | integer (int64) |  |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
