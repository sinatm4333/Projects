# ایجاد تسویه برای فاکتور فروش

برای فاکتور فروش در تب اجرا تسویه از نوع نقدی و حسابها ثبت می کند

## آدرس

```
/api/sales/create_settlement
```

## درخواست

```json
{
  "org_id": 0,
  "invoice_id": 0,
  "settlements": [
    {
      "date": 0,
      "type": 0,
      "price": "",
      "center_code": "",
      "client_code": "",
      "symbol_name": "",
      "symbol_rate": "",
      "account_code": "",
      "project_code": "",
      "floating_code": ""
    }
  ]
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `org_id` | integer (int64) | شناسه شعبه |
| `invoice_id` | integer (int64) | شناسه فاکتور |
| `settlements[]` | array | لیست تسویه ها |
| `settlements[].date` | integer (int64) | تاریخ |
| `settlements[].type` | integer (int32) | نوع تسویه :نقدی 4 ، حسابها 5 |
| `settlements[].price` | string | مبلغ |
| `settlements[].center_code` | string | کد مرکز |
| `settlements[].client_code` | string | کد شخص |
| `settlements[].symbol_name` | string | نام ارز |
| `settlements[].symbol_rate` | string | نرخ برابری |
| `settlements[].account_code` | string | کد حساب |
| `settlements[].project_code` | string | کد پروژه |
| `settlements[].floating_code` | string | کد شناور |

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
