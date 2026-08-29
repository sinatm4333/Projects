# /api/fiscalYear/list

درخواست

## آدرس

```
/api/fiscalYear/list
```

## درخواست

```json
{
  "org_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `org_id` | integer (int64) |  |

## پاسخ

```json
{
  "data": [
    {
      "id": 0,
      "name": "",
      "type": 0,
      "org_id": 0,
      "end_date": 0,
      "folder_id": 0,
      "start_date": 0,
      "aggrigation": 0,
      "check_balance": 0
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
| `data[].type` | integer (int64) |  |
| `data[].org_id` | integer (int64) |  |
| `data[].end_date` | integer (int64) |  |
| `data[].folder_id` | integer (int64) |  |
| `data[].start_date` | integer (int64) |  |
| `data[].aggrigation` | integer (int32) |  |
| `data[].check_balance` | integer (int32) |  |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
