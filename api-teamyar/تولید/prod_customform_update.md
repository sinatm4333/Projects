# /api/prod/customform/update

درخواست

## آدرس

```
/api/prod/customform/update
```

## درخواست

```json
{
  "id": 0,
  "type": 0,
  "org_id": 0,
  "customform": ""
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) |  |
| `type` | integer (int32) |  |
| `org_id` | integer (int64) |  |
| `customform` | string |  |

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
