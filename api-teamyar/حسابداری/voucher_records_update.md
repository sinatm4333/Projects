# آپدیت شرح رکورد حسابداری

برای استفاده باتی که بتوانند به صورت گروهی شرح رکورد حسابداری را تغییر دهند

## آدرس

```
/api/voucher/records_update
```

## درخواست

```json
[
  {
    "id": 0,
    "pdc": 0,
    "cash": 0,
    "date": 0,
    "type": 0,
    "action": 0,
    "debtor": 0,
    "org_id": 0,
    "pdc_id": 0,
    "rel_id": 0,
    "cash_id": 0,
    "content": "",
    "deleted": 0,
    "creditor": 0,
    "fee_rate": 0,
    "rel_type": 0,
    "tools_id": 0,
    "center_id": 0,
    "client_id": 0,
    "cost_rate": 0,
    "fx_debtor": 0,
    "row_index": 0,
    "symbol_id": 0,
    "account_id": 0,
    "project_id": 0,
    "voucher_id": 0,
    "date_create": 0,
    "date_modify": 0,
    "floating_id": 0,
    "fx_creditor": 0,
    "number_sort": 0,
    "symbol_rate": 0,
    "reference_id": 0,
    "voucher_code": 0,
    "voucher_date": 0,
    "voucher_type": 0,
    "manual_ref_id": 0,
    "rel_record_id": 0,
    "reference_type": 0,
    "voucher_status": 0,
    "voucher_deleted": 0
  }
]
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) | شناسه رکورد حسابداری |
| `pdc` | integer (int32) | related to pdces and cashes records 0:normal 1:pdc 2:bill 3:pos 4:cash |
| `cash` | integer (int32) | برای رکوردهای نقد، نوع نقد، فیش و کارت خوان رو مشخص میکند |
| `date` | integer (int64) | تاریخ ثبت رکورد |
| `type` | integer (int32) | نوع رکورد |
| `action` | integer (int32) | شناسه ارز اولیه در رکوردهای سند تسعیر ارز |
| `debtor` | integer (int64) | مقدار بدهکار |
| `org_id` | integer (int64) | شناسه سازمان |
| `pdc_id` | integer (int64) | شناسه چک |
| `rel_id` | integer (int64) | شناسه سند مرتبط (pa_pettycash) |
| `cash_id` | integer (int64) | شناسه نقد |
| `content` | string | شرح رکورد حسابداری |
| `deleted` | integer (int32) | حذف شده :1 |
| `creditor` | integer (int64) | مقدار بستانکار |
| `fee_rate` | integer (int64) | نرخ اعشار ارز پایه |
| `rel_type` | integer (int32) | نوع سند مرتبط |
| `tools_id` | integer (int64) | شناسه سطر عملیات ماژول های دیگر |
| `center_id` | integer (int64) | شناسه مرکز |
| `client_id` | integer (int64) | شناسه شخص |
| `cost_rate` | integer (int64) | نرخ ارز |
| `fx_debtor` | integer (int64) | مقدار بدهکار ارزی |
| `row_index` | integer (int64) | ایندکس دیتای سمت کلاینت |
| `symbol_id` | integer (int64) | شناسه ارز |
| `account_id` | integer (int64) | شناسه حساب |
| `project_id` | integer (int64) | شناسه پروژه |
| `voucher_id` | integer (int64) | شناسه سند |
| `date_create` | integer (int64) | تاریخ ایجاد رکورد |
| `date_modify` | integer (int64) | تاریخ ویرایش رکورد |
| `floating_id` | integer (int64) | شناسه شناور |
| `fx_creditor` | integer (int64) | مقدار بستانکار ارزی |
| `number_sort` | integer (int64) | شماره سورت رکورد |
| `symbol_rate` | integer (int64) | نرخ ارز |
| `reference_id` | integer (int64) | شناسه سند منبع رکورد |
| `voucher_code` | integer (int64) | کد سند |
| `voucher_date` | integer (int64) | تاریخ سند |
| `voucher_type` | integer (int32) | نوع سند |
| `manual_ref_id` | integer (int64) | شماره عملیات منبع |
| `rel_record_id` | integer (int64) | شناسه رکورد سند مرتبط (pa_pettycash_detail) |
| `reference_type` | integer (int32) | نوع عملیات مبدا |
| `voucher_status` | integer (int32) | وضعیت سند |
| `voucher_deleted` | integer (int32) | وضعیت حذف سند |

## پاسخ

```json
{
  "data": [
    {
      "error_data": ""
    }
  ],
  "error": {
    "status": 0,
    "message": ""
  },
  "success": false
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data[]` | array | آیتم های ارور |
| `data[].error_data` | string | ارور های سمت سرور |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
