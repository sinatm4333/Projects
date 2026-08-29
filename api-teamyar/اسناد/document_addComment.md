# اضافه کردن کامنت

ثبت یک یادداشت/کامنت روی سند.

## آدرس

```
/api/document/addComment
```

## درخواست

```json
{
  "content": "",
  "is_portal": 0,
  "document_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `document_id` | number | شناسه سند |
| `content` | string | متن کامنت |
| `is_portal` | number | ثبت از سمت پورتال |

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

- [گرفتن اطلاعات یک سند](document_getInfo.md)
