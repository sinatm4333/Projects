# /api/pdc/cash/unconfirm

درخواست

## آدرس

```
/api/pdc/cash/unconfirm
```

## درخواست

```json
{
  "org_id": 0,
  "cash_ids": [
    0
  ]
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `org_id` | integer (int64) |  |
| `cash_ids[]` | array |  |

## پاسخ

```json
{
  "data": {
    "errors": [
      {
        "id": 0,
        "message": ""
      }
    ]
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
| `data.errors[]` | array |  |
| `data.errors[].id` | integer (int64) |  |
| `data.errors[].message` | string |  |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
