# /api/organization/unitsGet

درخواست

## آدرس

```
/api/organization/unitsGet
```

## درخواست

```json
{
  "org_id": 0,
  "search": ""
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `org_id` | integer (int64) |  |
| `search` | string |  |

## پاسخ

```json
{
  "data": [
    {
      "id": 0,
      "name": "",
      "org_id": 0,
      "org_unit_id": 0
    }
  ],
  "error": {
    "status": 0,
    "message": ""
  },
  "success": false
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data[]` | array |  |
| `data[].id` | integer (int64) |  |
| `data[].name` | string |  |
| `data[].org_id` | integer (int64) |  |
| `data[].org_unit_id` | integer (int64) |  |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
