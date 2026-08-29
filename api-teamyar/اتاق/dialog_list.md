# /api/dialog/list

درخواست

## آدرس

```
/api/dialog/list
```

## درخواست

```json
{
  "from": 0,
  "type": 0,
  "count": 0,
  "status": 0,
  "group_id": 0,
  "end_date_to": 0,
  "end_date_from": 0,
  "start_date_to": 0,
  "start_date_from": 0,
  "last_modified_to": 0,
  "filter_topic_name": "",
  "last_modified_from": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `from` | integer (int32) |  |
| `type` | integer (int32) |  |
| `count` | integer (int32) |  |
| `status` | integer (int32) |  |
| `group_id` | integer (int64) |  |
| `end_date_to` | integer (int64) |  |
| `end_date_from` | integer (int64) |  |
| `start_date_to` | integer (int64) |  |
| `start_date_from` | integer (int64) |  |
| `last_modified_to` | integer (int64) |  |
| `filter_topic_name` | string |  |
| `last_modified_from` | integer (int64) |  |

## پاسخ

```json
{
  "data": [
    {
      "id": 0,
      "type": 0,
      "topic": "",
      "status": 0,
      "favorite": 0,
      "group_id": 0,
      "author_id": 0,
      "view_time": 0,
      "topic_name": "",
      "author_name": "",
      "date_create": 0,
      "unread_count": 0,
      "last_modified": 0,
      "dialog_author_name": ""
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
| `data[].favorite` | integer (int32) |  |
| `data[].group_id` | integer (int64) |  |
| `data[].author_id` | integer (int64) |  |
| `data[].view_time` | integer (int64) |  |
| `data[].topic_name` | string |  |
| `data[].author_name` | string |  |
| `data[].date_create` | integer (date) |  |
| `data[].unread_count` | integer (int32) |  |
| `data[].last_modified` | integer (date) |  |
| `data[].dialog_author_name` | string |  |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
