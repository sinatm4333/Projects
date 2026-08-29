# ایجاد فاکتور فروش پیش نویس

ایجاد فاکتور فروش در تب پیش نویس همانند درون ریزی فاکتور فروش عمل می کند.

## آدرس

```
/api/invoice/create
```

## درخواست

```json
{
  "invoice": {
    "note": "",
    "type": 0,
    "title": "",
    "org_id": 0,
    "portal": 0,
    "tag_ids": [
      0
    ],
    "run_date": 0,
    "bill_type": 0,
    "import_id": 0,
    "user_type": 0,
    "invoice_id": 0,
    "client_code": "",
    "symbol_name": "",
    "user_create": 0,
    "payment_type": 0,
    "project_code": "",
    "bill_template": 0,
    "client_mobile": "",
    "client_parent": "",
    "delivery_date": 0,
    "floating_code": "",
    "crm_section_id": 0,
    "sales_agent_code": "",
    "sales_center_code": "",
    "client_national_code": "",
    "solary_delivery_date": ""
  },
  "setting": {
    "setting_v_added": 0
  },
  "products": [
    {
      "fee": "",
      "note": "",
      "items": 0,
      "unit_id": 0,
      "discount": "",
      "quantity": "",
      "stock_code": "",
      "symbol_rate": "",
      "value_added": "",
      "attribute_id": 0,
      "product_code": "",
      "date_delivery": 0,
      "manual_weight": "",
      "manual_unit_id": 0,
      "quantity_confirmed": "",
      "solary_date_delivery": ""
    }
  ],
  "additions": [
    {
      "title": "",
      "effect": 0,
      "quantity": "",
      "center_code": "",
      "client_code": "",
      "account_code": "",
      "project_code": "",
      "floating_code": ""
    }
  ]
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `invoice` | object | مشخصات فاکتور |
| `invoice.note` | string | توضیحات |
| `invoice.type` | integer (int32) | نوع عملیات فروش |
| `invoice.title` | string | عنوان |
| `invoice.org_id` | integer (int64) | شناسه شعبه |
| `invoice.portal` | integer (int32) | نشانگر سفارش پورتال |
| `invoice.tag_ids[]` | array | برچسب ها |
| `invoice.run_date` | integer (int64) | تاریخ فاکتور |
| `invoice.bill_type` | integer (int32) | نوع صورتحساب |
| `invoice.import_id` | integer (int64) | شناسه عملیاتی که درون ریزی شده است |
| `invoice.user_type` | integer (int32) | نوع کاربر : حقیقی 3 حقوقی 4 |
| `invoice.invoice_id` | integer (int64) | شماره فاکتور (در صورتی که صفر باشد، شماره سیستمی داده می شود) |
| `invoice.client_code` | string | کد مشتری |
| `invoice.symbol_name` | string | نام ارز |
| `invoice.user_create` | integer (int64) | شناسه کاربر ایجاد کننده |
| `invoice.payment_type` | integer (int32) | نوع پرداخت |
| `invoice.project_code` | string | کد پروژه |
| `invoice.bill_template` | integer (int32) | الگوی صورتحساب |
| `invoice.client_mobile` | string | شماره موبایل مشتری |
| `invoice.client_parent` | string | کد گروه حسابداری اشخاص |
| `invoice.delivery_date` | integer (int64) | تاریخ تحویل |
| `invoice.floating_code` | string | کد شناور |
| `invoice.crm_section_id` | integer (int64) | شناسه رده مشتری |
| `invoice.sales_agent_code` | string | کد عامل فروش |
| `invoice.sales_center_code` | string | کد مرکز فروش |
| `invoice.client_national_code` | string | کد ملی مشتری |
| `invoice.solary_delivery_date` | string | تاریخ تحویل شمسی |
| `setting` | object | تنظیمات هنگام ثبت عملیات |
| `setting.setting_v_added` | integer (int32) | در این api استفاده نمی شود. در api ثبت فاکتور استفاده می شود. |
| `products[]` | array | مشخصات کالاها |
| `products[].fee` | string | فی |
| `products[].note` | string | توضیحات |
| `products[].unit_id` | integer (int64) | شناسه واحد |
| `products[].discount` | string | تخفیف |
| `products[].quantity` | string | مقدار |
| `products[].stock_code` | string | کد انبار |
| `products[].symbol_rate` | string | نرخ برابری |
| `products[].value_added` | string | ارزش افزوده |
| `products[].attribute_id` | integer (int64) | شناسه ویژگی |
| `products[].product_code` | string | کد کالا |
| `products[].date_delivery` | integer (int64) | تاریخ تحویل |
| `products[].manual_weight` | string | وزن دستی |
| `products[].manual_unit_id` | integer (int64) | شناسه واحد دستی |
| `products[].quantity_confirmed` | string | مقدار تایید شده |
| `products[].solary_date_delivery` | string | تاریخ تحویل شمسی |
| `additions[]` | array | مشخصات اضافات و کسورات |
| `additions[].title` | string | عنوان |
| `additions[].effect` | integer (int32) | تاثیر |
| `additions[].quantity` | string | مقدار |
| `additions[].center_code` | string | کد مرکز |
| `additions[].client_code` | string | کد شخص |
| `additions[].account_code` | string | کد حساب |
| `additions[].project_code` | string | کد پروژه |
| `additions[].floating_code` | string | کد شناور |

## پاسخ

```json
{
  "data": {
    "error": "",
    "invoice_id": 0
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
| `data` | object | داده خروجی |
| `data.error` | string | خطا |
| `data.invoice_id` | integer (int64) | شناسه فاکتور |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
