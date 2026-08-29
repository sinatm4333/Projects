# ابطال و حذف عملیات فروش

برای ابطال و یا حذف قطعی عملیاتهای فروش مورد استفاده قرار می گیرد

## آدرس

```
/api/sales/cancel_delete_invoice
```

## درخواست

```json
{
  "org_id": 0,
  "be_cancel": 0,
  "be_delete": 0,
  "invoice_id": 0,
  "keep_reference": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `org_id` | integer (int64) | شناسه شعبه |
| `be_cancel` | integer (int32) | در صورت مقدار غیر صفر فاکتور باطل شود |
| `be_delete` | integer (int32) | در صورت مقدار غیر صفر فاکتور باطل و حذف شود |
| `invoice_id` | integer (int64) | شناسه فاکتور |
| `keep_reference` | integer (int32) | حفظ حواله تعدادی عطف به فاکتور در صورت مقدار غیر صفر و حذف حواله تعدادی در صورت صفر بودننکته : سند مبنای از سمت خدمات همیشه حفظ خواهد شد. |

## پاسخ

```json
{
  "data": {
    "error": ""
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
| `data` | object | داده ها |
| `data.error` | string | خطا |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
