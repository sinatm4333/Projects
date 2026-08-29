# آپدیت ضریب واحد

ضریب واحد فرعی در شناسنامه کالا

## آدرس

```
/api/update_unit_factor
```

## درخواست

```json
{
  "info": [
    {
      "factor": "",
      "product_id": 0
    }
  ],
  "unit_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `info[]` | array | اطلاعات آرایه |
| `info[].factor` | string | عامل |
| `info[].product_id` | integer (int64) | کد کالا |
| `unit_id` | integer (int64) | شناسه واحد |

## پاسخ

```json
{
  "data": {
    "result": ""
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
| `data` | object | نتایج دیتا |
| `data.result` | string | پاسخ |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
