# دریافت اطلاعات درخواست خزانه داری

دریافت اطلاعات درخواست و رکوردهای درخواست خزانه داری در حسابداری

## آدرس

```
/api/request/get
```

## درخواست

```json
{
  "org_id": 0,
  "module_id": 0,
  "invoice_id": 0,
  "request_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `org_id` | integer (int64) | شناسه شعبه |
| `module_id` | integer (int64) | شناسه ماژول |
| `invoice_id` | integer (int64) | شناسه فاکتور |
| `request_id` | integer (int64) | شناسه درخواست |

## پاسخ

```json
{
  "data": {
    "id": 0,
    "note": "",
    "org_id": 0,
    "status": 0,
    "canceled": 0,
    "folder_id": 0,
    "symbol_id": 0,
    "date_create": 0,
    "user_create": 0,
    "request_date": 0,
    "request_type": 0,
    "requester_id": 0,
    "from_api_flag": 0,
    "request_number": 0,
    "request_records": [
      {
        "id": 0,
        "amount": 0,
        "org_id": 0,
        "folder_id": 0,
        "module_id": 0,
        "symbol_id": 0,
        "invoice_id": 0,
        "related_id": 0,
        "request_id": 0,
        "symbol_rate": 0,
        "amount_input": 0,
        "related_type": 0,
        "settlement_id": 0,
        "request_number": 0
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
| `data` | object | دیتا |
| `data.id` | integer (int64) | شناسه |
| `data.note` | string | توضیحات |
| `data.org_id` | integer (int64) | شناسه شعبه |
| `data.status` | integer (int32) | وضعیت |
| `data.canceled` | integer (int32) | باطل شده؟ |
| `data.folder_id` | integer (int64) | شناسه فولدر |
| `data.symbol_id` | integer (int64) | شناسه ارز |
| `data.date_create` | integer (int64) | تاریخ ایجاد |
| `data.user_create` | integer (int64) | شناسه کاربر ایجادکننده |
| `data.request_date` | integer (int64) | تاریخ درخواست |
| `data.request_type` | integer (int32) | نوع درخواست |
| `data.requester_id` | integer (int64) | شناسه درخواست کننده |
| `data.from_api_flag` | integer (int32) | فلگ فراخوانی از طریق api |
| `data.request_number` | integer (int64) | شناسه درخواست کننده(مرکز) |
| `data.request_records[]` | array | رکوردهای درخواست |
| `data.request_records[].id` | integer (int64) | شناسه |
| `data.request_records[].amount` | integer (int64) | مبلغ به ارز پایه |
| `data.request_records[].org_id` | integer (int64) | شناسه شعبه |
| `data.request_records[].folder_id` | integer (int64) | شناسه فولدر |
| `data.request_records[].module_id` | integer (int64) | شناسه ماژول (ستون نوع ) |
| `data.request_records[].symbol_id` | integer (int64) | شناسه ارز |
| `data.request_records[].invoice_id` | integer (int64) | شناسه فاکتور |
| `data.request_records[].related_id` | integer (int64) | -- |
| `data.request_records[].request_id` | integer (int64) | شناسه درخواست |
| `data.request_records[].symbol_rate` | integer (int64) | نرخ ارز |
| `data.request_records[].amount_input` | integer (int64) | مبلغ به ارز انتخاب شده |
| `data.request_records[].related_type` | integer (int32) | -- |
| `data.request_records[].settlement_id` | integer (int64) | -- |
| `data.request_records[].request_number` | integer (int64) | شماره درخواست |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
