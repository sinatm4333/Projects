# ثبت یک سطر در لیست قیمت فروش

یک سطر در لیست قیمت ثبت می کند

## آدرس

```
/api/sales/pricelist/update
```

## درخواست

```json
{
  "fee": "",
  "title": "",
  "org_id": 0,
  "products": [
    {
      "unit_id": 0,
      "decimal_num": 0,
      "attribute_id": 0,
      "product_code": ""
    }
  ],
  "symbol_id": 0,
  "fee_status": 0,
  "setting_id": 0,
  "quantity_to": "",
  "payment_type": 0,
  "quantity_from": "",
  "return_invoice": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `fee` | string | فی |
| `title` | string | عنوان |
| `org_id` | integer (int64) | شناسه شعبه |
| `products[]` | array | کالاها |
| `products[].unit_id` | integer (int64) | شناسه واحد |
| `products[].decimal_num` | integer (int64) | دسیمال |
| `products[].attribute_id` | integer (int64) | شناسه ویژگی |
| `products[].product_code` | string | کد کالا |
| `symbol_id` | integer (int64) | شناسه ارز |
| `fee_status` | integer (int32) | نوع قیمت (ثابت یا متغیر) |
| `setting_id` | integer (int64) | شناسه تنظیمات لیست قیمت/تخفیف/پورسانت |
| `quantity_to` | string | تا مقدار |
| `payment_type` | integer (int32) | نوع پرداخت |
| `quantity_from` | string | از مقدار |
| `return_invoice` | integer (int32) | نشانگر نمایش در برگشت از فروش |

## پاسخ

```json
{
  "data": {
    "id": 0
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
| `data` | object | داده خروجی |
| `data.id` | integer (int64) | شناسه سطر ثبت شده |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
