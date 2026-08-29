# /api/organization/conf_tpl/data/get

درخواست

## آدرس

```
/api/organization/conf_tpl/data/get
```

## درخواست

```json
{
  "org_id": 0,
  "ref_id": 0,
  "ref_type": 0,
  "module_id": 0,
  "process_type": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `org_id` | integer (int64) |  |
| `ref_id` | integer (int64) |  |
| `ref_type` | integer (int64) |  |
| `module_id` | integer (int64) |  |
| `process_type` | integer (int64) |  |

## پاسخ

```json
{
  "data": [
    {
      "user_id": 0,
      "user_verification": 0
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
| `data[].user_id` | integer (int64) |  |
| `data[].user_verification` | integer (int32) |  |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
