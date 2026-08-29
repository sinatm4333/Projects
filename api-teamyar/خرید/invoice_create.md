# ایجاد عملیات پیش نویس خرید

درخواست و یا سفارش خرید پیش نویس ایجاد می کند.

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
    "Costs": [
      {
        "amount": "",
        "cost_id": 0,
        "center_code": "",
        "client_code": "",
        "symbol_name": "",
        "symbol_rate": "",
        "account_code": "",
        "project_code": "",
        "floating_code": ""
      }
    ],
    "title": "",
    "step_id": 0,
    "tag_ids": [
      0
    ],
    "task_id": 0,
    "pre_read": 0,
    "run_date": 0,
    "import_id": 0,
    "module_id": 0,
    "unit_code": "",
    "invoice_id": 0,
    "invoice_num": "",
    "symbol_name": "",
    "user_create": 0,
    "payment_type": 0,
    "project_code": "",
    "floating_code": "",
    "provider_code": "",
    "pre_invoice_id": 0,
    "production_type": 0,
    "solary_run_date": "",
    "production_ref_id": 0,
    "purchase_agent_id": 0
  },
  "products": [
    {
      "fee": "",
      "note": "",
      "Costs": [
        {
          "amount": "",
          "cost_id": 0,
          "center_code": "",
          "client_code": "",
          "symbol_name": "",
          "symbol_rate": "",
          "account_code": "",
          "project_code": "",
          "floating_code": ""
        }
      ],
      "unit_id": 0,
      "discount": "",
      "quantity": "",
      "fee_sales": "",
      "stock_code": "",
      "center_code": "",
      "client_code": "",
      "symbol_rate": "",
      "value_added": "",
      "account_code": "",
      "attribute_id": 0,
      "product_code": "",
      "project_code": "",
      "date_delivery": 0,
      "floating_code": "",
      "manual_weight": "",
      "manual_unit_id": 0,
      "cost_percentage": "",
      "link_operation_id": 0,
      "purchase_deadline": 0,
      "link_operation_type": 0,
      "solary_date_delivery": "",
      "link_operation_detail_id": 0,
      "solary_purchase_deadline": ""
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
| `invoice` | object | عملیات |
| `invoice.note` | string | توضیحات |
| `invoice.type` | integer (int32) | نوع عملیاتدرخواست : 2 ، سفارش : 3 |
| `invoice.Costs[]` | array | هزینه (تسهیم) فاکتور |
| `invoice.Costs[].amount` | string | مبلغ |
| `invoice.Costs[].cost_id` | integer (int64) | شناسه حسابداری هزینه |
| `invoice.Costs[].center_code` | string | کد مرکز |
| `invoice.Costs[].client_code` | string | کد شخص |
| `invoice.Costs[].symbol_name` | string | نام ارز |
| `invoice.Costs[].symbol_rate` | string | نرخ برابری |
| `invoice.Costs[].account_code` | string | کد حساب |
| `invoice.Costs[].project_code` | string | کد پروژه |
| `invoice.Costs[].floating_code` | string | کد شناور |
| `invoice.title` | string | موضوع |
| `invoice.step_id` | integer (int64) | شناسه مرحله اقدام |
| `invoice.tag_ids[]` | array | برچسب ها |
| `invoice.task_id` | integer (int64) | شناسه اقدام |
| `invoice.pre_read` | integer (int32) | نوع عملیات سند مبنا (1: عملیاتهای خرید 2: عملیات های انبار) |
| `invoice.run_date` | integer (int64) | تاریخ عملیات |
| `invoice.import_id` | integer (int64) | شناسه عملیاتی که درون ریزی شده است |
| `invoice.module_id` | integer (int64) | شناسه ماژول مبدا |
| `invoice.unit_code` | string | واحد درخواست کننده |
| `invoice.invoice_id` | integer (int64) | شماره عملیات |
| `invoice.invoice_num` | string | شماره فاکتور در فاکتور خرید |
| `invoice.symbol_name` | string | نام ارز |
| `invoice.user_create` | integer (int64) | ایجاد کننده |
| `invoice.payment_type` | integer (int32) | نوع پرداخت |
| `invoice.project_code` | string | کد پروژه |
| `invoice.floating_code` | string | کد شناور |
| `invoice.provider_code` | string | کد تامین کننده |
| `invoice.pre_invoice_id` | integer (int64) | شناسه عملیات سند مبنا |
| `invoice.production_type` | integer (int32) | نوع عملیات تولید |
| `invoice.solary_run_date` | string | تاریخ شمسی عملیات |
| `invoice.production_ref_id` | integer (int64) | شناسه با مرجعیت تولید |
| `invoice.purchase_agent_id` | integer (int64) | شناسه عامل خرید |
| `products[]` | array | کالاها |
| `products[].fee` | string | فی |
| `products[].note` | string | توضیحات |
| `products[].Costs[]` | array | هرینه سطری |
| `products[].Costs[].amount` | string | مبلغ |
| `products[].Costs[].cost_id` | integer (int64) | شناسه حسابداری هزینه |
| `products[].Costs[].center_code` | string | کد مرکز |
| `products[].Costs[].client_code` | string | کد شخص |
| `products[].Costs[].symbol_name` | string | نام ارز |
| `products[].Costs[].symbol_rate` | string | نرخ برابری |
| `products[].Costs[].account_code` | string | کد حساب |
| `products[].Costs[].project_code` | string | کد پروژه |
| `products[].Costs[].floating_code` | string | کد شناور |
| `products[].unit_id` | integer (int64) | شناسه واحد |
| `products[].discount` | string | تخفیف |
| `products[].quantity` | string | مقدار |
| `products[].fee_sales` | string | قیمت فروش |
| `products[].stock_code` | string | کد انبار |
| `products[].center_code` | string | کد مرکز |
| `products[].client_code` | string | کد شخص |
| `products[].symbol_rate` | string | نرخ برابری |
| `products[].value_added` | string | ارزش افزوده |
| `products[].account_code` | string | کد حساب |
| `products[].attribute_id` | integer (int64) | شناسه ویژگی |
| `products[].product_code` | string | کد کالا |
| `products[].project_code` | string | کد پروژه |
| `products[].date_delivery` | integer (int64) | تاریخ تحویل |
| `products[].floating_code` | string | کد شناور |
| `products[].manual_weight` | string | وزن دستی |
| `products[].manual_unit_id` | integer (int64) | شناسه واحد دستی |
| `products[].cost_percentage` | string | درصد تسهیم |
| `products[].link_operation_id` | integer (int64) | شناسه عملیات سند مبنا |
| `products[].purchase_deadline` | integer (int64) | مهلت خرید |
| `products[].link_operation_type` | integer (int32) | نوع عملیات مبدا |
| `products[].solary_date_delivery` | string | تاریخ شمسی تحویل |
| `products[].link_operation_detail_id` | integer (int64) | شناسه سطر سند مبنا |
| `products[].solary_purchase_deadline` | string | تاریخ شمسی مهلت خرید |
| `additions[]` | array | لیست اضافات و کسورات |
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
| `data.invoice_id` | integer (int64) | شناسه عملیات |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
