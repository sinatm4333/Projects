# ایجاد سند

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
  "crm_ids": [
    0
  ],
  "filepath": "",
  "file_type": 0,
  "mime_type": "",
  "mt_values": [
    {
      "mt_id": 0,
      "value": ""
    }
  ],
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

| فیلد | نوع | توضیح |
|------|-----|-------|
| `mode` | integer (int32) | enum class EnMode {NORMAL = 0, ///< if a same name file is found, do nothing and return errorVERSIONING = 1, ///< if a same name file is found, add new file as a version of old fileREPLACE = 2 ///< if a same name file is found, delete old file and add new file (replace)}; |
| `name` | string | عنوان سند |
| `size` | integer (int64) | سایز فایل ها با واحد byte |
| `crm_ids[]` | array | شناسه های مشتریان |
| `filepath` | string | مسیر کامل هر سند |
| `file_type` | integer (int32) | نوع فایل |
| `mime_type` | string | نوع فایل ذخیره شده |
| `mt_values[]` | array | متادیتا ها |
| `mt_values[].mt_id` | integer (int64) | شناسه متادیتا |
| `mt_values[].value` | string | مقدار متادیتا |
| `parent_id` | integer (int64) | شناسه ی پوشه ی سطح بالاتر از سند فعلی |
| `document_id` | integer (int64) | شناسه سند |
| `auto_name_id` | integer (int64) | نامگذاری خودکار |
| `dst_location` | string | مسیر مقصد |
| `src_module_id` | integer (int32) | در صورت ارسال فایل، شناسه ماژولی می باشد که فایل در آن ماژول آپلود شده |
| `temp_document_id` | integer (int64) | ظاهرا استفاده ای نشده |
| `content_base64_str` | string | متن مربوطه که برای ایجاد فایل میبایست encode شده ی base64 باشد |
| `perm_inherent_flag` | integer (int32) | سند به ارث برده شده، اگر سندی تیک ارث بری داشته باشد. |
| `embedded_files_folder_id` | integer (int64) | شناسه پوشه فایل های embedded |

## پاسخ

```json
{
  "data": {
    "warnings": "",
    "file_type": 0,
    "document_name": "",
    "final_document_id": 0
  },
  "error": {
    "status": 0,
    "message": ""
  },
  "success": false
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data` | object |  |
| `data.warnings` | string | پیغام خطا |
| `data.file_type` | integer (int32) | این عدد مشخص کننده نوع فایل است، نوع فایل ها در فایل mimes.ini در مسیر teamyar\data\0000000\config تعریف شده است |
| `data.document_name` | string | عنوان سند |
| `data.final_document_id` | integer (int64) | شناسه سند ایجاد شده |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
