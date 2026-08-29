# نمایش تنظیمات الگوی کیفیت

با این API می‌توان لیستی از تنظیمات الگوی کیفیت را دریافت کرد.

## آدرس

```
/api/get_qc_template_settings
```

## درخواست

```json
{
  "from": 0,
  "count": 0,
  "org_id": 0,
  "search": "",
  "module_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `from` | integer (int32) | پارامتر "از" |
| `count` | integer (int32) | پارامتر "تا" |
| `org_id` | integer (int64) | شناسه شعبه |
| `search` | string | عبارت جستجو |
| `module_id` | integer (int32) | شناسه ماژول |

## پاسخ

```json
{
  "data": [
    {
      "id": 0,
      "title": "",
      "org_id": 0,
      "module_id": 0,
      "description": ""
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
| `data[]` | array | دیتای خروجی |
| `data[].id` | integer (int64) | شناسه تنظیمات |
| `data[].title` | string | عنوان تنظیمات |
| `data[].org_id` | integer (int64) | شناسه شعبه |
| `data[].module_id` | integer (int32) | شناسه ماژول |
| `data[].description` | string | توضیحات |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
