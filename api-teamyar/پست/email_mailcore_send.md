# /api/email/mailcore/send

درخواست

## آدرس

```
/api/email/mailcore/send
```

## درخواست

```json
{
  "message": {
    "id": 0,
    "perm": 0,
    "u_id": "",
    "files": [
      {
        "id": 0,
        "size": 0,
        "type": 0,
        "filename": "",
        "filepath": "",
        "author_id": 0,
        "mime_type": "",
        "base64_content": ""
      }
    ],
    "box_id": 0,
    "content": "",
    "file_id": 0,
    "step_id": 0,
    "subject": "",
    "task_id": 0,
    "category": 0,
    "favorite": 0,
    "author_id": 0,
    "date_sent": 0,
    "filter_id": 0,
    "folder_id": 0,
    "module_id": 0,
    "parent_id": 0,
    "send_flag": 0,
    "auto_reply": 0,
    "content_id": 0,
    "filter_ids": 0,
    "date_create": 0,
    "date_modify": 0,
    "is_archived": false,
    "is_notified": 0,
    "task_status": 0,
    "archive_flag": 0,
    "old_category": 0,
    "reference_id": 0,
    "header_msg_id": ""
  },
  "file_ids": [
    0
  ],
  "addresses": [
    {
      "id": 0,
      "flag": 0,
      "address": "",
      "group_id": 0,
      "user_name": "",
      "message_id": 0
    }
  ],
  "extra_header": "",
  "extra_content_file": "",
  "extra_header_value": "",
  "extra_content_file_name": "",
  "extra_content_file_mime_type": ""
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `message` | object |  |
| `message.id` | integer (int64) |  |
| `message.perm` | integer (int32) |  |
| `message.u_id` | string |  |
| `message.files[]` | array |  |
| `message.files[].id` | integer (int64) |  |
| `message.files[].size` | integer (int64) |  |
| `message.files[].type` | integer (int32) |  |
| `message.files[].filename` | string |  |
| `message.files[].filepath` | string |  |
| `message.files[].author_id` | integer (int64) |  |
| `message.files[].mime_type` | string |  |
| `message.files[].base64_content` | string |  |
| `message.box_id` | integer (int64) |  |
| `message.content` | string |  |
| `message.file_id` | integer (int64) |  |
| `message.step_id` | integer (int64) |  |
| `message.subject` | string |  |
| `message.task_id` | integer (int64) |  |
| `message.category` | integer (int32) |  |
| `message.favorite` | integer (int32) |  |
| `message.author_id` | integer (int64) |  |
| `message.date_sent` | integer (int64) |  |
| `message.filter_id` | integer (int64) |  |
| `message.folder_id` | integer (int64) |  |
| `message.module_id` | integer (int64) |  |
| `message.parent_id` | integer (int64) |  |
| `message.send_flag` | integer (int32) |  |
| `message.auto_reply` | integer (int32) |  |
| `message.content_id` | integer (int64) |  |
| `message.filter_ids` | integer (int64) |  |
| `message.date_create` | integer (int64) |  |
| `message.date_modify` | integer (int64) |  |
| `message.is_archived` | boolean |  |
| `message.is_notified` | integer (int32) |  |
| `message.task_status` | integer (int32) |  |
| `message.archive_flag` | integer (int32) |  |
| `message.old_category` | integer (int32) |  |
| `message.reference_id` | integer (int64) |  |
| `message.header_msg_id` | string |  |
| `file_ids[]` | array |  |
| `addresses[]` | array |  |
| `addresses[].id` | integer (int64) |  |
| `addresses[].flag` | integer (int32) |  |
| `addresses[].address` | string |  |
| `addresses[].group_id` | integer (int64) |  |
| `addresses[].user_name` | string |  |
| `addresses[].message_id` | integer (int64) |  |
| `extra_header` | string |  |
| `extra_content_file` | string |  |
| `extra_header_value` | string |  |
| `extra_content_file_name` | string |  |
| `extra_content_file_mime_type` | string |  |

## پاسخ

```json
{
  "data": {
    "message_id": 0
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
| `data.message_id` | integer (int64) |  |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
