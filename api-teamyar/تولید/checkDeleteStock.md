# حذف انبار

بررسی حذف انبارها

## آدرس

```
/api/checkDeleteStock
```

## درخواست

```json
{
  "org_id": 0,
  "stock_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `org_id` | integer (int64) | شناسه سازمان |
| `stock_id` | integer (int64) | شناسه انبار از جدول «wh_stock» |

## پاسخ

```json
{
  "data": {
    "err": "",
    "is_used": false
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
| `data` | object | آبجکت اصلی |
| `data.err` | string | خطا |
| `data.is_used` | boolean | استفاده میشود |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | وضعیت:پیشنویسبررسیانجامکاملباطل |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
