# ثبت چک

ثبت چک دریافتنی یا پرداختنی

## آدرس

```
/api/pdc/cheque/create
```

## درخواست

```json
{
  "org_id": 0,
  "status": 0,
  "cheques": [
    {
      "note": "",
      "amount": "",
      "branch": "",
      "holder": "",
      "pay_to": "",
      "ref_id": 0,
      "serial": "",
      "invoices": [
        {
          "id": 0,
          "amount": "",
          "account": {
            "center_id": 0,
            "client_id": 0,
            "account_id": 0,
            "project_id": 0,
            "floating_id": 0,
            "force_client": 0,
            "force_project": 0,
            "force_floating": 0,
            "force_cost_center": 0,
            "force_revenue_center": 0
          },
          "invoice_id": 0
        }
      ],
      "ref_type": 0,
      "requests": [
        0
      ],
      "bank_name": "",
      "issue_date": 0,
      "transactor": {
        "center_id": 0,
        "client_id": 0,
        "account_id": 0,
        "project_id": 0,
        "floating_id": 0,
        "force_client": 0,
        "force_project": 0,
        "force_floating": 0,
        "force_cost_center": 0,
        "force_revenue_center": 0
      },
      "back_number": "",
      "branch_code": "",
      "cheque_book": 0,
      "export_date": 0,
      "pdc_bank_id": 0,
      "cheque_serie": "",
      "pdc_category": 0,
      "shaba_number": "",
      "national_code": "",
      "sayyad_number": "",
      "account_number": "",
      "decimal_number": 0,
      "guarantee_type": 0,
      "bank_account_id": 0,
      "commercial_type": 0,
      "sayyad_register": 0
    }
  ],
  "unit_id": 0,
  "pdc_type": 0,
  "client_id": 0,
  "is_opening": 0,
  "floating_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `org_id` | integer (int64) | شناسه سازمان |
| `status` | integer (int32) | وضعیت چک0 = پیش فرض1 = نزد صندوق (دریافتنی) / پاس نشده (پرداختنی) |
| `cheques[]` | array | لیست چک ها |
| `cheques[].note` | string | شرح |
| `cheques[].amount` | string | مبلغ |
| `cheques[].branch` | string | شعبه |
| `cheques[].holder` | string | صاحب حساب |
| `cheques[].pay_to` | string | در وجه |
| `cheques[].ref_id` | integer (int64) |  |
| `cheques[].serial` | string | سریال |
| `cheques[].invoices[]` | array | لیست فاکتور ها |
| `cheques[].invoices[].id` | integer (int64) | شناسه |
| `cheques[].invoices[].amount` | string | مبلغ تسویه با چک |
| `cheques[].invoices[].account` | object | حساب دریافتی یا پرداختنی |
| `cheques[].invoices[].account.center_id` | integer (int64) | شناسه مرکز |
| `cheques[].invoices[].account.client_id` | integer (int64) | شناسه شخص |
| `cheques[].invoices[].account.account_id` | integer (int64) | شناسه حساب |
| `cheques[].invoices[].account.project_id` | integer (int64) | شناسه پروژه |
| `cheques[].invoices[].account.floating_id` | integer (int64) | شناسه شناور |
| `cheques[].invoices[].account.force_client` | integer (int32) | شخص اجبار |
| `cheques[].invoices[].account.force_project` | integer (int32) | پروژه اجبار |
| `cheques[].invoices[].account.force_floating` | integer (int32) | شناور اجبار |
| `cheques[].invoices[].account.force_cost_center` | integer (int32) | مرکز هزینه اجبار |
| `cheques[].invoices[].account.force_revenue_center` | integer (int32) | مرکز درآمد اجبار |
| `cheques[].invoices[].invoice_id` | integer (int64) | شناسه فاکتور |
| `cheques[].ref_type` | integer (int32) |  |
| `cheques[].requests[]` | array | لیست درخواست ها |
| `cheques[].bank_name` | string | نام بانک |
| `cheques[].issue_date` | integer (int64) | تاریخ سر رسید |
| `cheques[].transactor` | object | دریافت کننده / پرداخت کننده |
| `cheques[].transactor.center_id` | integer (int64) | شناسه مرکز |
| `cheques[].transactor.client_id` | integer (int64) | شناسه شخص |
| `cheques[].transactor.account_id` | integer (int64) | شناسه حساب |
| `cheques[].transactor.project_id` | integer (int64) | شناسه پروژه |
| `cheques[].transactor.floating_id` | integer (int64) | شناسه شناور |
| `cheques[].transactor.force_client` | integer (int32) | شخص اجبار |
| `cheques[].transactor.force_project` | integer (int32) | پروژه اجبار |
| `cheques[].transactor.force_floating` | integer (int32) | شناور اجبار |
| `cheques[].transactor.force_cost_center` | integer (int32) | مرکز هزینه اجبار |
| `cheques[].transactor.force_revenue_center` | integer (int32) | مرکز درآمد اجبار |
| `cheques[].back_number` | string | پشت نمره |
| `cheques[].branch_code` | string | کد شعبه |
| `cheques[].cheque_book` | integer (int64) | شناسه دسته چک |
| `cheques[].export_date` | integer (int64) | تاریخ صدور |
| `cheques[].pdc_bank_id` | integer (int64) |  |
| `cheques[].cheque_serie` | string | سری چک |
| `cheques[].pdc_category` | integer (int32) |  |
| `cheques[].shaba_number` | string | شماره شبا |
| `cheques[].national_code` | string | کد ملی |
| `cheques[].sayyad_number` | string | شماره صیادی |
| `cheques[].account_number` | string | شماره حساب |
| `cheques[].decimal_number` | integer (int32) | رقم اعشار |
| `cheques[].guarantee_type` | integer (int32) |  |
| `cheques[].bank_account_id` | integer (int64) | شناسه حساب بانک |
| `cheques[].commercial_type` | integer (int32) | 1 = تجاری2 = غیر تجاری |
| `cheques[].sayyad_register` | integer (int32) | ثبت صیادی |
| `unit_id` | integer (int64) | شناسه واحد |
| `pdc_type` | integer (int32) | نوع چک1 = پرداختنی2 = دریافتنی |
| `client_id` | integer (int64) |  |
| `is_opening` | integer (int32) | چک افتتاحیه |
| `floating_id` | integer (int64) |  |

## پاسخ

```json
{
  "data": {
    "cheques": [
      0
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
| `data` | object |  |
| `data.cheques[]` | array |  |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
