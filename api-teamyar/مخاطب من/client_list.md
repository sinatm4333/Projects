# /api/client/list

درخواست

## آدرس

```
/api/client/list
```

## درخواست

```json
{
  "from": 0,
  "count": 0,
  "section_id": 0,
  "category_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `from` | integer (int32) |  |
| `count` | integer (int32) |  |
| `section_id` | integer (int64) |  |
| `category_id` | integer (int64) |  |

## پاسخ

```json
{
  "data": {
    "total": 0,
    "clients": [
      {
        "id": 0,
        "name": "",
        "company": "",
        "confirm": 0,
        "deleted": 0,
        "create_date": 0,
        "modified_date": 0,
        "personality_type": 0
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
| `data.total` | integer (int32) |  |
| `data.clients[]` | array |  |
| `data.clients[].id` | integer (int64) |  |
| `data.clients[].name` | string |  |
| `data.clients[].company` | string |  |
| `data.clients[].confirm` | integer (int32) |  |
| `data.clients[].deleted` | integer (int32) |  |
| `data.clients[].create_date` | integer (int64) |  |
| `data.clients[].modified_date` | integer (int64) |  |
| `data.clients[].personality_type` | integer (int32) |  |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
