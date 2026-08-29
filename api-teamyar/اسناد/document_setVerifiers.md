# تغییر در افراد مطلع، تایید کننده، مسئول و امضا کننده

تعیین فهرست کاربران یک نقش مشخص روی سند.

## آدرس

```
/api/document/setVerifiers
```

## درخواست

```json
{
  "type": 0,
  "users": [0],
  "document_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `document_id` | number | شناسه سند |
| `users` | array\<number\> | شناسه کاربران |
| `type` | number | نوع نقش — مطلع، تأییدکننده، مسئول، امضاکننده |

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

- [دریافت وضعیت سند](document_getSignStatus.md) — آرایه‌های `sign`، `confirm`، `assign` و `responsible` در خروجی آن.
