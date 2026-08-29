# دریافت نام سند

دریافت نام یک سند بر اساس شناسه.

## آدرس

```
/api/document/getName
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
  "data": { "name": "" },
  "error": { "status": 0, "message": "" },
  "success": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data.name` | string | نام سند |
| `error.status` | number | کد خطا |
| `error.message` | string | پیام خطا |
| `success` | number | نتیجه اجرا |

## مرتبط

- [گرفتن اطلاعات یک سند](document_getInfo.md) — اطلاعات کامل سند.
