# وضعیت کیفیت های یک مرجع

وضعیت کیفیت های یک مرجع به صورت کلی

## آدرس

```
/api/get_quality_result_status_by_ref
```

## درخواست

```json
{
  "ref_id*": 0,
  "ref_type": 0,
  "module_id*": 0,
  "ref_detail_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `ref_id*` | integer (int64) | شناسه مرجع |
| `ref_type` | integer (int32) | نوع مرجع |
| `module_id*` | integer (int64) | شناسه ماژول |
| `ref_detail_id` | integer (int64) | شناسه سطر عملیات مرجع |

## پاسخ

```json
{
  "data": {
    "status": 0
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
| `data` | object | داده |
| `data.status` | integer (int32) | وضعیت کیفیت های یک مرجع به صورت کلی |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
