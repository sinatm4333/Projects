# درج سند حسابداری

## آدرس

```
/api/voucher/create
```

## درخواست

```json
{
  "org_id": 0,
  "module_id": 0,
  "reffer_name": "",
  "voucher_date": 0,
  "voucher_records": [
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
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `org_id` | integer (int64) | شناسه شعبه |
| `module_id` | integer (int32) | شناسه ماژول |
| `reffer_name` | string | شماره عملیات مازول های دیگر |
| `voucher_date` | integer (int64) | تاریخ سند |
| `voucher_records[]` | array | رکوردهای سند |
| `voucher_records[].id` | integer (int64) | شناسه |
| `voucher_records[].pdc` | integer (int32) | چک |
| `voucher_records[].cash` | integer (int32) | نقد |
| `voucher_records[].date` | integer (int64) | تاریخ |
| `voucher_records[].type` | integer (int32) | نوع سند |
| `voucher_records[].action` | integer (int32) | شناسه ارز اولیه در رکوردهای سند تسعیر ارز |
| `voucher_records[].debtor` | integer (int64) | بدهکار |
| `voucher_records[].org_id` | integer (int64) | شناسه شعبه |
| `voucher_records[].pdc_id` | integer (int64) | شناسه چک |
| `voucher_records[].rel_id` | integer (int64) | شناسه سند مرتبط (pa_pettycash) |
| `voucher_records[].cash_id` | integer (int64) | شناسه نقد |
| `voucher_records[].content` | string | شرح رکورد |
| `voucher_records[].deleted` | integer (int32) | حذف شده |
| `voucher_records[].creditor` | integer (int64) | بستانکار |
| `voucher_records[].fee_rate` | integer (int64) | نرخ ارز |
| `voucher_records[].rel_type` | integer (int32) | نوع سند مرتبط |
| `voucher_records[].tools_id` | integer (int64) | شناسه سطر عملیات مازول های دیگر |
| `voucher_records[].center_id` | integer (int64) | شناسه مرکز |
| `voucher_records[].client_id` | integer (int64) | شناسه شخص |
| `voucher_records[].cost_rate` | integer (int64) | نرخ |
| `voucher_records[].fx_debtor` | integer (int64) | بدهکار ارزی |
| `voucher_records[].row_index` | integer (int64) | ردیف |
| `voucher_records[].symbol_id` | integer (int64) | شناسه ارز |
| `voucher_records[].account_id` | integer (int64) | شناسه حساب |
| `voucher_records[].project_id` | integer (int64) | شناسه پروژه |
| `voucher_records[].voucher_id` | integer (int64) | شناسه سند |
| `voucher_records[].date_create` | integer (int64) | تاریخ ایجاد |
| `voucher_records[].date_modify` | integer (int64) | تاریخ ویرایش |
| `voucher_records[].floating_id` | integer (int64) | شناسه شناور |
| `voucher_records[].fx_creditor` | integer (int64) | بستانکار ارزی |
| `voucher_records[].number_sort` | integer (int64) | شناسه مرتب سازی |
| `voucher_records[].symbol_rate` | integer (int64) | نرخ ارز |
| `voucher_records[].reference_id` | integer (int64) | شناسه سند منبع رکورد |
| `voucher_records[].voucher_code` | integer (int64) | کد سند |
| `voucher_records[].voucher_date` | integer (int64) | تاریخ سند |
| `voucher_records[].voucher_type` | integer (int32) | نوع سند |
| `voucher_records[].manual_ref_id` | integer (int64) | manul number of refrence id |
| `voucher_records[].rel_record_id` | integer (int64) | شناسه رکورد سند مرتبط (pa_pettycash_detail) |
| `voucher_records[].reference_type` | integer (int32) | نوع عملیات مازول های دیگر |
| `voucher_records[].voucher_status` | integer (int32) | وضعیت سند |
| `voucher_records[].voucher_deleted` | integer (int32) | سند حذف شده |

## پاسخ

```json
{
  "data": {
    "error_data": ""
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
| `data` | object | پارامترها |
| `data.error_data` | string | رکورد دارای خطا برگردانده میشود. |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
