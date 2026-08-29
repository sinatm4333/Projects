# /api/bom/delete

درخواست

## آدرس

```
/api/bom/delete
```

## درخواست

```json
{
  "ids": [
    0
  ],
  "org_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `ids[]` | array |  |
| `org_id` | integer (int64) |  |

## پاسخ

```json
{
  "data": {
    "result": [
      0
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
| `data.result[]` | array |  |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
