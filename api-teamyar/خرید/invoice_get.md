# گرفتن اطلاعات عملیات

شامل اطلاعات بالای فاکتور، کالاها، اضافات و کسورات ، هزینه یا تسهیم

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
| `invoice_id` | integer (int64) | شناسه عملیات |

## پاسخ

```json
{
  "data": {
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
| `data` | object | داده |
| `data.invoice` | object | اطلاعات عملیات |
| `data.invoice.note` | string | توضیحات |
| `data.invoice.type` | integer (int32) | نوع عملیات |
| `data.invoice.Costs[]` | array | هزینه (تسهیم) فاکتور |
| `data.invoice.Costs[].amount` | string | مبلغ |
| `data.invoice.Costs[].cost_id` | integer (int64) | شناسه حسابداری هزینه |
| `data.invoice.Costs[].center_code` | string | کد مرکز |
| `data.invoice.Costs[].client_code` | string | کد شخص |
| `data.invoice.Costs[].symbol_name` | string | نام ارز |
| `data.invoice.Costs[].symbol_rate` | string | نرخ برابری |
| `data.invoice.Costs[].account_code` | string | کد حساب |
| `data.invoice.Costs[].project_code` | string | کد پروژه |
| `data.invoice.Costs[].floating_code` | string | کد شناور |
| `data.invoice.title` | string | عنوان |
| `data.invoice.step_id` | integer (int64) | شناسه مرحله |
| `data.invoice.tag_ids[]` | array | برچسب ها |
| `data.invoice.task_id` | integer (int64) | شناسه اقدام |
| `data.invoice.pre_read` | integer (int32) | نوع عملیات سند مبنا |
| `data.invoice.run_date` | integer (int64) | تاریخ عملیات |
| `data.invoice.import_id` | integer (int64) | شناسه عملیاتی که درون ریزی شده است. |
| `data.invoice.module_id` | integer (int64) | شناسه ماژول مبدا |
| `data.invoice.unit_code` | string | کد واحد درخواست کننده |
| `data.invoice.invoice_id` | integer (int64) | شماره عملیات |
| `data.invoice.invoice_num` | string | شماره فاکتور (در فاکتور خرید) |
| `data.invoice.symbol_name` | string | نام ارز |
| `data.invoice.user_create` | integer (int64) | کاربر ایجاد کننده |
| `data.invoice.payment_type` | integer (int32) | نوع پرداخت |
| `data.invoice.project_code` | string | کد پروژه |
| `data.invoice.floating_code` | string | کد شناور |
| `data.invoice.provider_code` | string | کد تامین کننده |
| `data.invoice.pre_invoice_id` | integer (int64) | شناسه سند مبنا |
| `data.invoice.production_type` | integer (int32) | نوع عملیات تولید |
| `data.invoice.solary_run_date` | string | تاریخ شمسی عملیات |
| `data.invoice.production_ref_id` | integer (int64) | شناسه با مرجعیت تولید |
| `data.invoice.purchase_agent_id` | integer (int64) | شناسه عامل خرید |
| `data.products[]` | array | اطلاعات کالاها |
| `data.products[].fee` | string | فی |
| `data.products[].note` | string | توضیحات |
| `data.products[].Costs[]` | array | هزینه سطری |
| `data.products[].Costs[].amount` | string | مبلغ |
| `data.products[].Costs[].cost_id` | integer (int64) | شناسه حسابداری هزینه |
| `data.products[].Costs[].center_code` | string | کد مرکز |
| `data.products[].Costs[].client_code` | string | کد مشتری |
| `data.products[].Costs[].symbol_name` | string | نام ارز |
| `data.products[].Costs[].symbol_rate` | string | نرخ برابری |
| `data.products[].Costs[].account_code` | string | کد حساب |
| `data.products[].Costs[].project_code` | string | کد پروژه |
| `data.products[].Costs[].floating_code` | string | کد شناور |
| `data.products[].unit_id` | integer (int64) | شناسه واحد |
| `data.products[].discount` | string | تخفیف |
| `data.products[].quantity` | string | مقدار |
| `data.products[].fee_sales` | string | قیمت فروش |
| `data.products[].stock_code` | string | کد انبار |
| `data.products[].center_code` | string | کد مرکز |
| `data.products[].client_code` | string | کد شخص |
| `data.products[].symbol_rate` | string | نرخ برابری |
| `data.products[].value_added` | string | ارزش افزوده |
| `data.products[].account_code` | string | کد حساب در فاکتور خدمت |
| `data.products[].attribute_id` | integer (int64) | شناسه ویژگی |
| `data.products[].product_code` | string | کد کالا |
| `data.products[].project_code` | string | کد پروژه در فاکتور خدمت |
| `data.products[].date_delivery` | integer (int64) | تاریخ تحویل |
| `data.products[].floating_code` | string | کد شناور در فاکتور خدمت |
| `data.products[].manual_weight` | string | وزن دستی |
| `data.products[].manual_unit_id` | integer (int64) | شناسه واحد دستی |
| `data.products[].cost_percentage` | string | درصد تسهیم |
| `data.products[].link_operation_id` | integer (int64) | شناسه سند مبنا |
| `data.products[].purchase_deadline` | integer (int64) | مهلت خرید |
| `data.products[].link_operation_type` | integer (int32) | نوع عملیات سند مبنا |
| `data.products[].solary_date_delivery` | string | تاریخ شمسی تحویل |
| `data.products[].link_operation_detail_id` | integer (int64) | شناسه سطر سند مبنا |
| `data.products[].solary_purchase_deadline` | string | تاریخ شمسی مهلت خرید |
| `data.additions[]` | array | اضافات و کسورات |
| `data.additions[].title` | string | عنوان |
| `data.additions[].effect` | integer (int32) | تاثیر |
| `data.additions[].quantity` | string | مقدار/مبلغ |
| `data.additions[].center_code` | string | کد مرکز |
| `data.additions[].client_code` | string | کد مشتری |
| `data.additions[].account_code` | string | کد حساب |
| `data.additions[].project_code` | string | کد پروژه |
| `data.additions[].floating_code` | string | کد شناور |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
