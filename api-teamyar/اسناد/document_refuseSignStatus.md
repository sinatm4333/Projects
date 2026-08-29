# رد سند

رد کردن سند در فرایند امضا/تأیید، به همراه ثبت دلیل.

## آدرس

```
/api/document/refuseSignStatus
```

## درخواست

```json
{
  "content": "",
  "is_private": 0,
  "assign_type": 0,
  "document_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `document_id` | number | شناسه سند |
| `content` | string | متن دلیل رد |
| `assign_type` | number | نوع ارجاع |
| `is_private` | number | خصوصی بودن |

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

- [دریافت وضعیت سند](document_getSignStatus.md) — وضعیت امضا/تأیید/ارجاع سند.
