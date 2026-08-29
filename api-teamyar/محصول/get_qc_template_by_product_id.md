# گرفتن الگوی کیفیت کالا با شناسه کالا

این API، لیست الگوهای کیفیت کالا را برمی‌گرداند.

## آدرس

```
/api/get_qc_template_by_product_id
```

## درخواست

```json
{
  "module_id": 0,
  "product_id": 0,
  "setting_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `module_id` | integer (int64) | شناسه ماژول |
| `product_id` | integer (int64) | شناسه کالا |
| `setting_id` | integer (int64) | شناسه تنظیمات الگوی کیفیت |

## پاسخ

```json
{
  "data": [
    {
      "id": 0,
      "status": 0,
      "percentage": 0,
      "product_id": 0,
      "sample_num": 0,
      "setting_id": 0,
      "description": "",
      "template_id": 0,
      "source_product_id": 0
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
| `data[]` | array | آرایه دیتای خروجی |
| `data[].id` | integer (int64) | شناسه جدول |
| `data[].status` | integer (int32) | وضعیت فعال یا غیرفعال بودن |
| `data[].percentage` | number (double) | مقدار درصد |
| `data[].product_id` | integer (int64) | شناسه کالا |
| `data[].sample_num` | number (double) | تعداد نمونه |
| `data[].setting_id` | integer (int64) | شناسه تنظیمات الگوی کیفیت |
| `data[].description` | string | توضیحات |
| `data[].template_id` | integer (int64) | شناسه الگوی کیفیت (ماژول کیفیت) |
| `data[].source_product_id` | integer (int64) | شناسه کالای اصلی (مثلا پرنت) |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
