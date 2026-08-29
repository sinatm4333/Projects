# گرفتن تعداد کیفیت با شماره مرجع و سازمان و شناسه ماژول

## آدرس

```
/api/getQualityByRefAndOrgCount
```

## درخواست

```json
{
  "org_id*": 0,
  "ref_id": 0,
  "ref_type": 0,
  "module_id*": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `org_id*` | integer (int64) | شناسه سازمان |
| `ref_id` | integer (int64) | شناسه مرجع |
| `ref_type` | integer (int32) | نوع مرجع |
| `module_id*` | integer (int64) | شناسه ماژول |

## پاسخ

```json
{
  "data": {
    "count": 0
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
| `data` | object | آبجکت اصلی |
| `data.count` | integer (int32) | مقدار |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
