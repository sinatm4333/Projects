# دربافت مقدار بدهکار و بستانکار و مانده یک حساب

با استفاده از شناسه و نوع حساب مقدار بدهکار و بستانکار و مانده یک حساب دریافت میشود

## آدرس

```
/api/account_info/get
```

## درخواست

```json
{
  "id": 0,
  "type": 0,
  "org_id": 0,
  "end_date": 0,
  "symbol_id": 0,
  "start_date": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) | شناسه حساب |
| `type` | integer (int32) | نوع حساب |
| `org_id` | integer (int64) | شناسه سازمان |
| `end_date` | integer (int64) | تاریخ انتهای که مانده حساب بر اساس ان محاسبه میشود |
| `symbol_id` | integer (int64) | ارزی که مانده حساب بر اساس ان محاسبه میشود |
| `start_date` | integer (int64) | تاریخ شروع که مانده حساب بر اساس ان محاسبه میشود |

## پاسخ

```json
{
  "data": {
    "total_crd": "",
    "total_deb": "",
    "total_remain": ""
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
| `data.total_crd` | string | جمع مبلغ بستانکار |
| `data.total_deb` | string | جمع مبلغ بدهکار |
| `data.total_remain` | string | مانده حساب |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
