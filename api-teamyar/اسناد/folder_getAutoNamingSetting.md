# گرفتن نام خودکار سند

دریافت تنظیمات نام‌گذاری خودکار یک پوشه.

## آدرس

```
/api/folder/getAutoNamingSetting
```

## درخواست

```json
{
  "id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | number | شناسه پوشه |

## پاسخ

```json
{
  "data": {
    "id": 0,
    "flags": 0,
    "mt_id": 0,
    "document_id": 0,
    "entity_path": 0,
    "entity_type": 0
  },
  "error": { "status": 0, "message": "" },
  "success": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data.id` | number | شناسه تنظیمات |
| `data.document_id` | number | شناسه سند |
| `data.mt_id` | number | شناسه فیلد متادیتا |
| `data.entity_type` | number | نوع موجودیت |
| `data.entity_path` | number | مسیر موجودیت |
| `data.flags` | number | فلگ‌ها |
| `error.status` | number | کد خطا |
| `error.message` | string | پیام خطا |
| `success` | number | نتیجه اجرا |

## مرتبط

- [ایجاد سند](createDocumentFile.md) — فیلد `auto_name_id` در ورودی آن.
- [فهرست اسناد](document_list.md) — فیلدهای `file_autonum` و `folder_autonum` در خروجی آن.
