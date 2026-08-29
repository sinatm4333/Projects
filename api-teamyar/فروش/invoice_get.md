# گرفتن اطلاعات فاکتور

خروجی همانند برون ریزی فاکتور فروش می باشد.

## آدرس

```
/api/invoice/get
```

## درخواست

```json
{
  "org_id": 0,
  "invoice_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `org_id` | integer (int64) | شناسه شعبه |
| `invoice_id` | integer (int64) | شناسه فاکتور |

## پاسخ

```json
{
  "data": {
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
| `data` | object | اطلاعات خروجی |
| `data.invoice` | object | مشخصات فاکتور |
| `data.invoice.note` | string | توضیحات |
| `data.invoice.type` | integer (int32) | نوع عملیات فروش |
| `data.invoice.title` | string | عنوان |
| `data.invoice.org_id` | integer (int64) | شناسه شعبه |
| `data.invoice.portal` | integer (int32) | نشانگر پورتال |
| `data.invoice.tag_ids[]` | array | آرایه ای از شناسه برچسب ها |
| `data.invoice.run_date` | integer (int64) | تاریخ فاکتور |
| `data.invoice.bill_type` | integer (int32) | نوع صورتحساب |
| `data.invoice.import_id` | integer (int64) | شناسه عملیاتی که درون ریزی شده است |
| `data.invoice.user_type` | integer (int32) | نوع مشتری (برای ایجاد عملیات استفاده می شود) |
| `data.invoice.invoice_id` | integer (int64) | شماره فاکتور |
| `data.invoice.client_code` | string | کد مشتری |
| `data.invoice.symbol_name` | string | نام ارز |
| `data.invoice.user_create` | integer (int64) | شناسه کاربر ایجاد کننده |
| `data.invoice.payment_type` | integer (int32) | نوع پرداخت |
| `data.invoice.project_code` | string | کد پروژه |
| `data.invoice.bill_template` | integer (int32) | الگوی صورتحساب |
| `data.invoice.client_mobile` | string | شماره موبایل مشتری |
| `data.invoice.client_parent` | string | کد گروه حسابداری اشخاص |
| `data.invoice.delivery_date` | integer (int64) | تاریخ تحویل |
| `data.invoice.floating_code` | string | کد شناور |
| `data.invoice.crm_section_id` | integer (int64) | شناسه رده مشتری |
| `data.invoice.sales_agent_code` | string | کد عامل فروش |
| `data.invoice.sales_center_code` | string | کد مرکز فروش |
| `data.invoice.client_national_code` | string | کد ملی مشتری |
| `data.invoice.solary_delivery_date` | string | تاریخ تحویل شمسی |
| `data.setting` | object | تنظیمات برای ثبت عملیات |
| `data.setting.setting_v_added` | integer (int32) | ثبت ارزش افزوده سیسستمی در صورت مقدار غیر صفر |
| `data.products[]` | array | مشخصات کالاها |
| `data.products[].fee` | string | فی |
| `data.products[].note` | string | توضیحات |
| `data.products[].unit_id` | integer (int64) | شناسه واحد |
| `data.products[].discount` | string | تخفیف |
| `data.products[].quantity` | string | مقدار |
| `data.products[].stock_code` | string | کد انبار |
| `data.products[].symbol_rate` | string | نرخ برابری |
| `data.products[].value_added` | string | ارزش افزوده |
| `data.products[].attribute_id` | integer (int64) | شناسه ویژگی |
| `data.products[].product_code` | string | کد کالا |
| `data.products[].date_delivery` | integer (int64) | تاریخ تحویل |
| `data.products[].manual_weight` | string | وزن دستی |
| `data.products[].manual_unit_id` | integer (int64) | شناسه واحد دستی |
| `data.products[].quantity_confirmed` | string | مقدار تایید شده |
| `data.products[].solary_date_delivery` | string | تاریخ تحویل شمسی |
| `data.additions[]` | array | مشخصات اضافات و کسورات |
| `data.additions[].title` | string | عنوان |
| `data.additions[].effect` | integer (int32) | تاثیر |
| `data.additions[].quantity` | string | مقدار |
| `data.additions[].center_code` | string | کد مرکز |
| `data.additions[].client_code` | string | کد شخص |
| `data.additions[].account_code` | string | کد حساب |
| `data.additions[].project_code` | string | کد پروژه |
| `data.additions[].floating_code` | string | کد شناور |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
