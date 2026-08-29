# دریافت وضعیت سند

دریافت وضعیت امضا، تأیید، ارجاع و مسئولیت یک سند.

## آدرس

```
/api/document/getSignStatus
```

## درخواست

```json
{
  "document_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `document_id` | number | شناسه سند |

## پاسخ

```json
{
  "data": {
    "sign": [{ "date": 0, "status": 0, "user_id": 0 }],
    "assign": [{ "date": 0, "status": 0, "user_id": 0 }],
    "confirm": [{ "date": 0, "status": 0, "user_id": 0 }],
    "document_id": 0,
    "responsible": [{ "date": 0, "status": 0, "user_id": 0 }]
  },
  "error": { "status": 0, "message": "" },
  "success": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data.document_id` | number | شناسه سند |
| `data.sign[]` | array | امضاکنندگان |
| `data.confirm[]` | array | تأییدکنندگان |
| `data.assign[]` | array | ارجاع‌شوندگان |
| `data.responsible[]` | array | مسئولان |
| `error.status` | number | کد خطا |
| `error.message` | string | پیام خطا |
| `success` | number | نتیجه اجرا |

هر چهار آرایه (`sign`، `confirm`، `assign`، `responsible`) ساختار یکسان دارند:

| فیلد | نوع | توضیح |
|------|-----|-------|
| `user_id` | number | شناسه کاربر |
| `status` | number | وضعیت |
| `date` | number | تاریخ |

## مرتبط

- [گرفتن اطلاعات یک سند](document_getInfo.md)
