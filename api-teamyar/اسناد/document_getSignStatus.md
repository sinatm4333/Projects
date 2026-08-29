# دریافت وضعیت سند

دریافت وضعیت سند (مطلع، تایید، مسئول و امضا) با داشتن ID سند

## آدرس

```
/api/document/getSignStatus
```

## درخواست

```json
{
  "document_id*": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `document_id*` | integer (int64) | شناسه سندوارد کردن این مقدار اجباری می باشد |

## پاسخ

```json
{
  "data": {
    "sign": [
      {
        "date": 0,
        "status": 0,
        "user_id": 0
      }
    ],
    "assign": [
      {
        "date": 0,
        "status": 0,
        "user_id": 0
      }
    ],
    "confirm": [
      {
        "date": 0,
        "status": 0,
        "user_id": 0
      }
    ],
    "document_id": 0,
    "responsible": [
      {
        "date": 0,
        "status": 0,
        "user_id": 0
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
| `data` | object | آبجکتی که شامل اطلاعات سند می باشد |
| `data.sign[]` | array | آرایه ای از آبجکت هایی که اطلاعات مربوط به امضا سند را شامل می شود |
| `data.sign[].date` | integer (int64) | تاریخ |
| `data.sign[].status` | integer (int32) | وضعیت0 : درحال بررسی 1 : تایید 2 : رد |
| `data.sign[].user_id` | integer (int64) | شناسه ی فرد امضا کننده |
| `data.assign[]` | array | آرایه ای از آبجکت هایی که اطلاعات مربوط به افراد مطلع روی سند را شامل می شود |
| `data.assign[].date` | integer (int64) | تاریخ |
| `data.assign[].status` | integer (int32) | وضعیت مطلع بودن0 : دیده نشده 1 : دیده شده |
| `data.assign[].user_id` | integer (int64) | شناسه ی فرد مطلع |
| `data.confirm[]` | array | آرایه ای از آبجکت هایی که اطلاعات مربوط به تایید سند را شامل می شود |
| `data.confirm[].date` | integer (int64) | تاریخ |
| `data.confirm[].status` | integer (int32) | وضعیت0 : درحال بررسی 1 : تایید 2 : رد |
| `data.confirm[].user_id` | integer (int64) | شناسه ی فرد تایید کننده |
| `data.document_id` | integer (int64) | شناسه سند |
| `data.responsible[]` | array | آرایه ای از آبجکت هایی که اطلاعات مربوط به مسئول بودن روی سند را شامل می شود |
| `data.responsible[].date` | integer (int64) | تاریخ |
| `data.responsible[].status` | integer (int32) | وضعیت0 : درحال بررسی 1 : تایید 2 : رد |
| `data.responsible[].user_id` | integer (int64) | شناسه فرد مسئول |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
