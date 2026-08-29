# /api/dialog/forward_list

درخواست

## آدرس

```
/api/dialog/forward_list
```

## درخواست

```json
{
  "from": 0,
  "count": 0,
  "search": ""
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `from` | integer (int32) |  |
| `count` | integer (int32) |  |
| `search` | string |  |

## پاسخ

```json
{
  "data": [
    {
      "id": 0,
      "type": 0,
      "topic": "",
      "status": 0,
      "group_id": 0,
      "author_id": 0,
      "group_name": "",
      "topic_name": "",
      "author_name": "",
      "last_modified": 0,
      "one_way_channel": 0,
      "private_user_id": 0
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
| `data[].type` | integer (int32) |  |
| `data[].topic` | string |  |
| `data[].status` | integer (int32) |  |
| `data[].group_id` | integer (int64) |  |
| `data[].author_id` | integer (int64) |  |
| `data[].group_name` | string |  |
| `data[].topic_name` | string |  |
| `data[].author_name` | string |  |
| `data[].last_modified` | integer (date) |  |
| `data[].one_way_channel` | integer (int32) |  |
| `data[].private_user_id` | integer (int64) |  |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
