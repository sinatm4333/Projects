# بازکردن منگنه

برداشتن پیوست (منگنه) فایل‌ها از سند — عملیات معکوس `document/attach`.

## آدرس

```
/api/document/detach
```

## درخواست

```json
{
  "detach_ids": [0]
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `detach_ids` | array\<number\> | شناسه فایل‌هایی که منگنه‌شان باز می‌شود |

## پاسخ

```json
{
  "data": { "detached_ids": [0] },
  "error": { "status": 0, "message": "" },
  "success": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data.detached_ids` | array\<number\> | شناسه فایل‌هایی که منگنه‌شان باز شد |
| `error.status` | number | کد خطا |
| `error.message` | string | پیام خطا |
| `success` | number | نتیجه اجرا |

## مرتبط

- [منگنه کردن فایل](document_attach.md) — عملیات معکوس.
