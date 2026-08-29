# /api/prod/mps/opc_detail_quantity/update

درخواست

## آدرس

```
/api/prod/mps/opc_detail_quantity/update
```

## درخواست

```json
{
  "id": 0,
  "quantity": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) |  |
| `quantity` | integer (int64) |  |

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
| `data` | object |  |
| `data.result` | string |  |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
