# ساخت نام خوکار سند

## آدرس

```
/api/getAutoName
```

## درخواست

```json
{
  "client_ids": [
    0
  ],
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
| `client_ids[]` | array | آرایه ای از شناسه های مشتری و پرسنلی |
| `manual_name` | string | نام دستی |
| `naming_setting` | object | آبجکت تنظیمات نام خودکار |
| `naming_setting.id` | integer (int64) | بلا استفاده ولی باید حتما مقداری داشته باشد |
| `naming_setting.flags` | integer (int64) | NAMING_SETTING_FLAG_PORTAL = 1 , پورتالNAMING_SETTING_FLAG_ESSENTIAL = 2 , الزامیNAMING_SETTING_FLAG_MANUAL_NAME = 4 , نام دستی NAMING_SETTING_FLAG_COUNTER = 8 , شمارنده |
| `naming_setting.mt_id` | integer (int64) | شناسه متا دیتا |
| `naming_setting.document_id` | integer (int64) | شناسه سند |
| `naming_setting.entity_path` | integer (int64) | مقدار ماهیت-جهت |
| `naming_setting.entity_type` | integer (int64) | مقدار ماهیت-نوع |

## پاسخ

```json
{
  "data": {
    "autoname": ""
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
| `data.autoname` | string | نام خودکار سند |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
