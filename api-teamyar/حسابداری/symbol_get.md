# دریافت لیست ارز در حسابداری

امکان دریافت لیست ارز در حسابداری با وارد نمودن شناسه شعبه

## آدرس

```
/api/symbol/get
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
      "id": 0,
      "code": "",
      "date": 0,
      "name": "",
      "note": "",
      "rate": "",
      "order": 0,
      "org_id": 0,
      "spread": 0,
      "status": 0,
      "decimal": 0,
      "percent": 0,
      "max_rate": "",
      "min_rate": "",
      "main_rate": 0,
      "short_name": "",
      "auto_update": 0,
      "fee_decimal": 0,
      "main_max_rate": 0,
      "main_min_rate": 0
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
| `data[].id` | integer (int64) | شناسه |
| `data[].code` | string | کد نماد |
| `data[].date` | integer (int64) | تاریخ ایجاد |
| `data[].name` | string | نام ارز |
| `data[].note` | string | توضیحات |
| `data[].rate` | string | نرخ |
| `data[].order` | integer (int64) | ترتیب |
| `data[].org_id` | integer (int64) | شناسه شعبه |
| `data[].spread` | integer (int64) | تفاوت |
| `data[].status` | integer (int64) | وضعیت |
| `data[].decimal` | integer (int64) | تعداد رقم اعشار |
| `data[].percent` | integer (int64) | درصد |
| `data[].max_rate` | string | بیشترین نرخ |
| `data[].min_rate` | string | کمترین نرخ |
| `data[].main_rate` | integer (int64) | نرخ برابری بدون تبدیل |
| `data[].short_name` | string | نام اختصاری |
| `data[].auto_update` | integer (int64) | امکان آپدیت نرخ از طریق API |
| `data[].fee_decimal` | integer (int64) | تعداد ارقام اعشار نرخ |
| `data[].main_max_rate` | integer (int64) | بیشترین نرخ بدون تبدیل |
| `data[].main_min_rate` | integer (int64) | کمترین نرخ بدون تبدیل |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
