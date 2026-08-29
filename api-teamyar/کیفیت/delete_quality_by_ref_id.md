# حذف کیفیت

حذف موقت کیفیت از طریق شناسه مرجع

## آدرس

```
/api/delete_quality_by_ref_id
```

## درخواست

```json
{
  "ref_id*": 0,
  "ref_type": 0,
  "module_id*": 0,
  "delete_type": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `ref_id*` | integer (int64) | شناسه مرجع |
| `ref_type` | integer (int32) | نوع مرجع |
| `module_id*` | integer (int64) | شناسه ماژول |
| `delete_type` | integer (int32) | نوع حذف |

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
