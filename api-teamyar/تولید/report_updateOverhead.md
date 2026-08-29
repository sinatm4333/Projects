# آپدیت سربارهای تولید

این تابع به منظور آپدیت سربارهای تولید در زمان محاسبه بهای تمام شده نوشته شده است

## آدرس

```
/api/report/updateOverhead
```

## درخواست

```json
{
  "org_id": 0,
  "date_to": 0,
  "date_from": 0,
  "overheads": [
    {
      "product_id": 0,
      "attribute_id": 0,
      "direct_overhead": 0,
      "indirect_overhead": 0
    }
  ],
  "expense_center": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `org_id` | integer (int64) | شناسه سازمان |
| `date_to` | integer (int64) | بازه تاریخی تاثیر گذار (تا تاریخِ) |
| `date_from` | integer (int64) | بازه تاریخی تاثیر گذار (تا تاریخِ) |
| `overheads[]` | array | سربار محاسبه شده به ازای هر کالا |
| `overheads[].product_id` | integer (int64) | شناسه کالا |
| `overheads[].attribute_id` | integer (int64) | شناسه ویژگی |
| `overheads[].direct_overhead` | integer (int64) | مقدار سربار مستقیم به ازای یک واحد کالا |
| `overheads[].indirect_overhead` | integer (int64) | مقدار سربار غیر مستقیم به ازای یک واحد کالا |
| `expense_center` | integer (int64) | مرکز هزینه |

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
