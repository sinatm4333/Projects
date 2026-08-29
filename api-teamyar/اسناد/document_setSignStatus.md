# تایید سند

ثبت وضعیت امضا/تأیید سند.

## آدرس

```
/api/document/setSignStatus
```

## درخواست

```json
{
  "assign_type": 0,
  "document_id": 0,
  "sign_status": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `document_id` | number | شناسه سند |
| `sign_status` | number | وضعیت امضا/تأیید |
| `assign_type` | number | نوع ارجاع |

## پاسخ

```json
{
  "error": { "status": 0, "message": "" },
  "success": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `error.status` | number | کد خطا |
| `error.message` | string | پیام خطا |
| `success` | number | نتیجه اجرا |

## مرتبط

- [دریافت وضعیت سند](document_getSignStatus.md) — خواندن وضعیت.
- [رد سند](document_refuseSignStatus.md) — عملیات مقابل.
