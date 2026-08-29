# گرفتن اطلاعات تنظیمات الگوی کیفیت با شناسه (ID)

با این API می‌توان اطلاعات تنظیمات الگوی کیفیت یک شناسه به‌خصوص را دریافت کرد.

## آدرس

```
/api/get_qc_template_setting_by_id
```

## درخواست

```json
{
  "id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) | شناسه تنظیمات |

## پاسخ

```json
{
  "data": {
    "id": 0,
    "title": "",
    "org_id": 0,
    "module_id": 0,
    "description": ""
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
| `data.id` | integer (int64) | شناسه تنظیمات |
| `data.title` | string | عنوان |
| `data.org_id` | integer (int64) | شناسه شعبه |
| `data.module_id` | integer (int32) | شناسه ماژول |
| `data.description` | string | توضیحات |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
