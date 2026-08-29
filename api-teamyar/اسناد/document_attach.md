# منگنه کردن فایل

پیوست (منگنه) کردن یک یا چند فایل به یک سند.

## آدرس

```
/api/document/attach
```

## درخواست

```json
{
  "attach_ids": [0],
  "document_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `document_id` | number | شناسه سند مقصد |
| `attach_ids` | array\<number\> | شناسه فایل‌هایی که منگنه می‌شوند |

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

- [فهرست اسناد](document_list.md)
