# محاسبه کاردکس کالا

با این API می توان محاسبه کاردکس کالا را دریافت کرد.

## آدرس

```
/api/get_cardindex
```

## درخواست

```json
{
  "org_id": 0,
  "end_date": 0,
  "stock_id": "",
  "product_id": 0,
  "start_date": 0,
  "attribute_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `org_id` | integer (int64) | شناسه شعبه |
| `end_date` | integer (int64) | تاریخ پایان |
| `stock_id` | string | کد انبار |
| `product_id` | integer (int64) | کد کالا |
| `start_date` | integer (int64) | تاریخ شروع |
| `attribute_id` | integer (int64) | شناسه ویژگی |

## پاسخ

```json
{
  "data": {
    "cost": 0,
    "quantity": 0,
    "total_cost": 0
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
| `data.cost` | number (double) | مبلغ |
| `data.quantity` | number (double) | مقدار |
| `data.total_cost` | number (double) | قیمت تمام شده |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
