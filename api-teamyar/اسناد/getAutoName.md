# ساخت نام خودکار سند

تولید نام خودکار برای سند بر اساس تنظیمات نام‌گذاری.

## آدرس

```
/api/getAutoName
```

## درخواست

```json
{
  "client_ids": [0],
  "manual_name": "",
  "naming_setting": {
    "id": 0,
    "flags": 0,
    "mt_id": 0,
    "document_id": 0,
    "entity_path": 0,
    "entity_type": 0
  }
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `client_ids` | array\<number\> | شناسه مشتریان |
| `manual_name` | string | نام دستی |
| `naming_setting` | object | تنظیمات نام‌گذاری (ساختار زیر) |

`naming_setting` — همان ساختار خروجی [گرفتن نام خودکار سند](folder_getAutoNamingSetting.md):

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | number | شناسه تنظیمات |
| `document_id` | number | شناسه سند |
| `mt_id` | number | شناسه فیلد متادیتا |
| `entity_type` | number | نوع موجودیت |
| `entity_path` | number | مسیر موجودیت |
| `flags` | number | فلگ‌ها |

## پاسخ

```json
{
  "data": { "autoname": "" },
  "error": { "status": 0, "message": "" },
  "success": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data.autoname` | string | نام تولیدشده |
| `error.status` | number | کد خطا |
| `error.message` | string | پیام خطا |
| `success` | number | نتیجه اجرا |

## مرتبط

- [گرفتن نام خودکار سند](folder_getAutoNamingSetting.md) — خروجی آن به‌عنوان `naming_setting` استفاده می‌شود.
- [ایجاد سند](createDocumentFile.md)
