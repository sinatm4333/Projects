# /api/pdc/cheque/delete

درخواست

## آدرس

```
/api/pdc/cheque/delete
```

## درخواست

```json
{
  "id*": 0,
  "org_id*": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id*` | integer (int64) |  |
| `org_id*` | integer (int64) |  |

## پاسخ

```json
{
  "data": {
    "error_data": ""
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
| `data.error_data` | string |  |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
