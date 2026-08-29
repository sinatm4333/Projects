# گرفتن سند از طریق متادیتا

## آدرس

```
/api/document/getByMetadata
```

## درخواست

```json
{
  "meta_id": 0,
  "meta_value": ""
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `meta_id` | integer (int64) | نام متا دیتا |
| `meta_value` | string | مقدار متا دیتا |

## پاسخ

```json
{
  "data": [
    {
      "id": 0,
      "size": 0,
      "type": 0,
      "deleted": false,
      "version": 0,
      "filename": "",
      "filetype": 0,
      "mime_type": "",
      "date_create": 0
    }
  ],
  "error": {
    "status": 0,
    "message": ""
  },
  "success": false
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data[]` | array | data |
| `data[].id` | integer (int64) | شناسه سند |
| `data[].size` | integer (int64) | سایز فایل ها با واحد byte |
| `data[].type` | integer (int32) | پوشه= 1 سند= 2 |
| `data[].deleted` | boolean | 0 : به حذف شده ها منتقل شده است.1 : حذف نشده است. |
| `data[].version` | integer (int32) | نسخه فعلی سند |
| `data[].filename` | string | نام سند |
| `data[].filetype` | integer (int32) | نوع سند |
| `data[].mime_type` | string | نوع فایل ذخیره شده |
| `data[].date_create` | integer (date) | تاریخ ایجاد سند |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
