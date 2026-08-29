# تعییر ستون تاریخ سفارش

با این (API) ،به ازای هر تغییری، لاگ (در شناسنامه کالا) درج خواهد شد.

## آدرس

```
/api/update_product_stocks
```

## درخواست

```json
{
  "stock_id": 0,
  "max_point": "",
  "min_point": "",
  "product_id": 0,
  "attribute_id": 0,
  "optimum_order": "",
  "reorder_point": "",
  "reorder_point_date": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `stock_id` | integer (int64) | شناسه انبار |
| `max_point` | string | بیشتر تعداد نقطه سفارش در حداکثر موجودی است. |
| `min_point` | string | کمترین تعداد نقطه سفارش در حداقل موجودی است. |
| `product_id` | integer (int64) | شناسه کالا |
| `attribute_id` | integer (int64) | شناسه ویژگی |
| `optimum_order` | string | سفارش بهینه |
| `reorder_point` | string | نقطه سفارش |
| `reorder_point_date` | integer (int64) | تاریخ رسیدن به نقطه سفارش |

## پاسخ

```json
{
  "error": {
    "status": 0,
    "message": ""
  },
  "success": false
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
