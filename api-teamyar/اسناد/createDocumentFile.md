# ایجاد سند

ایجاد سند/فایل جدید و آپلود محتوای آن.

## آدرس

```
/api/createDocumentFile
```

## درخواست

```json
{
  "mode": 0,
  "name": "",
  "size": 0,
  "crm_ids": [0],
  "filepath": "",
  "file_type": 0,
  "mime_type": "",
  "mt_values": [{ "mt_id": 0, "value": "" }],
  "parent_id": 0,
  "document_id": 0,
  "auto_name_id": 0,
  "dst_location": "",
  "src_module_id": 0,
  "temp_document_id": 0,
  "content_base64_str": "",
  "perm_inherent_flag": 0,
  "embedded_files_folder_id": 0
}
```

### فایل

| فیلد | نوع | توضیح |
|------|-----|-------|
| `name` | string | نام سند |
| `filepath` | string | مسیر فایل |
| `file_type` | number | نوع فایل |
| `mime_type` | string | نوع MIME |
| `size` | number | حجم فایل |
| `content_base64_str` | string | محتوای فایل به‌صورت base64 |

### مکان و مقصد

| فیلد | نوع | توضیح |
|------|-----|-------|
| `parent_id` | number | شناسه پوشه والد |
| `dst_location` | string | مکان مقصد |
| `embedded_files_folder_id` | number | شناسه پوشه فایل‌های جاسازی‌شده |

### شناسه‌ها

| فیلد | نوع | توضیح |
|------|-----|-------|
| `document_id` | number | شناسه سند |
| `temp_document_id` | number | شناسه سند موقت |
| `auto_name_id` | number | شناسه نام‌گذاری خودکار |
| `src_module_id` | number | شناسه ماژول مبدأ |
| `crm_ids` | array\<number\> | شناسه‌های CRM مرتبط |

### تنظیمات

| فیلد | نوع | توضیح |
|------|-----|-------|
| `mode` | number | حالت ایجاد |
| `perm_inherent_flag` | number | ارث‌بری دسترسی |
| `mt_values[]` | array | مقادیر متادیتا — `mt_id`، `value` |

## پاسخ

```json
{
  "data": {
    "warnings": "",
    "file_type": 0,
    "document_name": "",
    "final_document_id": 0
  },
  "error": { "status": 0, "message": "" },
  "success": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data.final_document_id` | number | شناسه نهایی سند ایجادشده |
| `data.document_name` | string | نام سند |
| `data.file_type` | number | نوع فایل |
| `data.warnings` | string | هشدارها |
| `error.status` | number | کد خطا |
| `error.message` | string | پیام خطا |
| `success` | number | نتیجه اجرا |

## مرتبط

- [فهرست اسناد](document_list.md)
- [منگنه کردن فایل](document_attach.md)
