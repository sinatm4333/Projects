# /api/update_operation_detail_manual_weight_and_unit

درخواست

## آدرس

```
/api/update_operation_detail_manual_weight_and_unit
```

## درخواست

```json
{
  "operation_id": 0,
  "manual_weight": "",
  "manual_unit_id": 0,
  "operation_detail_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `operation_id` | integer (int64) |  |
| `manual_weight` | string |  |
| `manual_unit_id` | integer (int64) |  |
| `operation_detail_id` | integer (int64) |  |

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
