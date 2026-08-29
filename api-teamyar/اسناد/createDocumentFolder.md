# ایجاد پوشه

ایجاد پوشه جدید در ساختار اسناد.

## آدرس

```
/api/createDocumentFolder
```

## درخواست

```json
{
  "mode": 0,
  "name": "",
  "parent_id": 0,
  "document_id": 0,
  "perm_inherent_flag": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `name` | string | نام پوشه |
| `parent_id` | number | شناسه پوشه والد |
| `document_id` | number | شناسه سند |
| `mode` | number | حالت ایجاد |
| `perm_inherent_flag` | number | ارث‌بری دسترسی |

## پاسخ

```json
{
  "data": { "document_id": 0 },
  "error": { "status": 0, "message": "" },
  "success": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data.document_id` | number | شناسه پوشه ایجادشده |
| `error.status` | number | کد خطا |
| `error.message` | string | پیام خطا |
| `success` | number | نتیجه اجرا |

## مرتبط

- [ایجاد سند](createDocumentFile.md) — ایجاد فایل به‌جای پوشه.
- [فهرست اسناد](document_list.md)
