# حذف محصول

بررسی حذف محصول

## آدرس

```
/api/checkDeleteProduct
```

## درخواست

```json
{
  "org_id": 0,
  "product_id": 0,
  "attribute_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `org_id` | integer (int64) | شناسه سازمان |
| `product_id` | integer (int64) | شناسه کالا از جدول "wh_product" |
| `attribute_id` | integer (int64) | شناسه ویژگی از جدول "WH_PRODUCT_ATTRIBUTE" |

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
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
