# تبدیل نرخ ارز

تبدیل مبلغ وارد شده از ارز پایه به یک ارز خاص یا تمام ارزها

## آدرس

```
/api/currency/convert/get
```

## درخواست

```json
{
  "amount": 0,
  "org_id": 0,
  "symbol_id": 0,
  "currency_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `amount` | integer (int64) | مبلغ |
| `org_id` | integer (int64) | شناسه شعبه |
| `symbol_id` | integer (int64) | شناسه ارز مبدا |
| `currency_id` | integer (int64) | شناسه ارز مقصد |

## پاسخ

```json
{
  "data": [
    {
      "code": "",
      "name": "",
      "org_id": 0,
      "max_rate": 0,
      "min_rate": 0,
      "symbol_id": 0,
      "symbol_rate": 0,
      "convert_rate": "",
      "decimal_count": 0,
      "converted_amount": ""
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
| `data[].code` | string | کد |
| `data[].name` | string | نام ارز |
| `data[].org_id` | integer (int64) | شناسه شعبه |
| `data[].max_rate` | integer (int64) | بیشترین نرخ ارز |
| `data[].min_rate` | integer (int64) | کمترین نرخ ارز |
| `data[].symbol_id` | integer (int64) | شناسه ارز |
| `data[].symbol_rate` | integer (int64) | نرخ برابری |
| `data[].convert_rate` | string | نرخ تبدیل |
| `data[].decimal_count` | integer (int64) | تعداد ارقام اعشار |
| `data[].converted_amount` | string | مبلغ تبدیل شده به ارز مقصد |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
