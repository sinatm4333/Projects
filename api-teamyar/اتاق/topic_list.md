# /api/topic/list

درخواست

## آدرس

```
/api/topic/list
```

## درخواست

```json
{
  "group_id*": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `group_id*` | integer (int64) |  |

## پاسخ

```json
{
  "data": [
    {
      "id": 0,
      "title": "",
      "password": "",
      "channel_id": 0
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
| `data[].title` | string |  |
| `data[].password` | string |  |
| `data[].channel_id` | integer (int64) |  |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
