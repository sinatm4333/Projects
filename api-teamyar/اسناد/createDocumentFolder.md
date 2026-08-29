# ایجاد پوشه

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
| `mode` | integer (int32) | enum class EnMode {NORMAL = 0, ///< if a same name file is found, do nothing and return errorVERSIONING = 1, ///< if a same name file is found, add new file as a version of old fileREPLACE = 2 ///< if a same name file is found, delete old file and add new file (replace)}; |
| `name` | string | نام پوشه جدید |
| `parent_id` | integer (int64) | شناسه پوشه پدر |
| `document_id` | integer (int64) | شناسه سند |
| `perm_inherent_flag` | integer (int32) | سند به ارث برده شده، اگر سندی تیک ارث بری داشته باشد. |

## پاسخ

```json
{
  "data": {
    "document_id": 0
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
| `data.document_id` | integer (int64) | شناسه پوشه ایجاد شده |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
