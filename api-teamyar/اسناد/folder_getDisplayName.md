# گرفتن نام فولدر

دریافت نام نمایشی یک پوشه بر اساس شناسه.

## آدرس

```
/api/folder/getDisplayName
```

## درخواست

```json
{
  "folder_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `folder_id` | number | شناسه پوشه |

## پاسخ

```json
{
  "data": { "folder_name": "" },
  "error": { "status": 0, "message": "" },
  "success": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data.folder_name` | string | نام نمایشی پوشه |
| `error.status` | number | کد خطا |
| `error.message` | string | پیام خطا |
| `success` | number | نتیجه اجرا |

## مرتبط

- [دریافت نام سند](document_getName.md) — معادل آن برای سند.
- [ایجاد پوشه](createDocumentFolder.md)
