# دریافت لیست نرخ تبدیل ارزها

دریافت لیست نرخ تبدیل ارزها در حسابداری با وارد نمودن شناسه شعبه

## آدرس

```
/api/symbol/currencyFeeList/get
```

## درخواست

```json
{
  "org_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `org_id` | integer (int64) | شناسه شعبه |

## پاسخ

```json
{
  "data": [
    {
      "rate": "",
      "org_id": 0,
      "symbol_id": 0,
      "currency_id": 0
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
| `data[]` | array | پارامترها |
| `data[].rate` | string | نرخ برابری |
| `data[].org_id` | integer (int64) | شناسه شعبه |
| `data[].symbol_id` | integer (int64) | ارز مبدا |
| `data[].currency_id` | integer (int64) | ارز مقصد |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
