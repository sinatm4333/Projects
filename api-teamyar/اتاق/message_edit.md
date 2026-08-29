# /api/message/edit

درخواست

## آدرس

```
/api/message/edit
```

## درخواست

```json
{
  "mention": "",
  "message": "",
  "reply_id": 0,
  "dialog_id*": 0,
  "message_id*": 0,
  "attachments": [
    {
      "size": 0,
      "filename": "",
      "filepath": "",
      "mime_type": "",
      "data_base64": "",
      "src_module_id": 0
    }
  ],
  "deleted_files": ""
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `mention` | string |  |
| `message` | string |  |
| `reply_id` | integer (int64) |  |
| `dialog_id*` | integer (int64) |  |
| `message_id*` | integer (int64) |  |
| `attachments[]` | array |  |
| `attachments[].size` | integer (int64) |  |
| `attachments[].filename` | string |  |
| `attachments[].filepath` | string |  |
| `attachments[].mime_type` | string |  |
| `attachments[].data_base64` | string |  |
| `attachments[].src_module_id` | integer (int32) |  |
| `deleted_files` | string |  |

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
