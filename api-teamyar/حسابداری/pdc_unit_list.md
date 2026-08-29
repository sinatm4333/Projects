# /api/pdc/unit/list

درخواست

## آدرس

```
/api/pdc/unit/list
```

## درخواست

```json
{
  "org_id": 0,
  "pdc_type": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `org_id` | integer (int64) |  |
| `pdc_type` | integer (int32) |  |

## پاسخ

```json
{
  "data": [
    {
      "id": 0,
      "name": ""
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
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
