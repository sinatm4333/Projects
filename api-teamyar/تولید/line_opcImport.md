# درون ریزی opc

درون ریزی نمودار فرایند عملیات در مرحله انجام از bom فعال -در صورت داشتن نسخه opc نسخه جدید ایجاد خواهد کرد

## آدرس

```
/api/line/opcImport
```

## درخواست

```json
{
  "opc_id": 0,
  "line_id": 0,
  "product_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `opc_id` | integer (int64) | شناسه نمودار فرایند عملیات |
| `line_id` | integer (int64) | شناسه خط تولید |
| `product_id` | integer (int64) | شناسه سیستمی کالا |

## پاسخ

```json
{
  "data": {
    "err": ""
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
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | وضعیت:پیشنویسبررسیانجامکاملباطل |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
