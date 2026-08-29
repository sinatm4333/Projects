# سریال پذیر کالا از طریق API

با این API می توان کالاهایی را که تاکنون سریال پذیر نبوده اند، سریال پذیر کرد.

## آدرس

```
/api/update_product_can_accept_serial
```

## درخواست

```json
{
  "org_id": 0,
  "product_codes": [
    ""
  ]
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `org_id` | integer (int64) | شناسه شعبه |
| `product_codes[]` | array | آرایه کد کالا |

## پاسخ

```json
{
  "data": [
    {
      "id": 0,
      "name": "",
      "result": ""
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
| `data[]` | array | آرایه نتایج |
| `data[].id` | integer (int64) | شناسه کالا |
| `data[].name` | string | نام کالا |
| `data[].result` | string | نتیجه‌ی عملیات (موفق یا ناموفق به همراه ارور مربوطه) |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
