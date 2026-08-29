# گرفتن نام خودکار سند

گرفتن نام خودکار سند از طریق شناسه

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
| `id` | integer (int64) | شناسه سند |

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
  "error": {
    "status": 0,
    "message": ""
  },
  "success": false
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data` | object | data |
| `data.id` | integer (int64) | شناسه سند |
| `data.flags` | integer (int64) | NAMING_SETTING_FLAG_PORTAL = 1 , پورتالNAMING_SETTING_FLAG_ESSENTIAL = 2 , الزامیNAMING_SETTING_FLAG_MANUAL_NAME = 4 , نام دستی NAMING_SETTING_FLAG_COUNTER = 8 , شمارنده |
| `data.mt_id` | integer (int64) | شناسه متادیتا (شناسه جدول DOCUMENTS_META_DATA) |
| `data.document_id` | integer (int64) | شناسه سند |
| `data.entity_path` | integer (int64) | مقدار ماهیت-جهت |
| `data.entity_type` | integer (int64) | مقدار ماهیت-نوع |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
