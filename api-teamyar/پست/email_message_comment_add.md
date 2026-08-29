# /api/email/message/comment/add

درخواست

## آدرس

```
/api/email/message/comment/add
```

## درخواست

```json
{
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
  "content": "",
  "message_id": 0,
  "src_module_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `files[]` | array |  |
| `files[].id` | integer (int64) |  |
| `files[].size` | integer (int64) |  |
| `files[].type` | integer (int32) |  |
| `files[].filename` | string |  |
| `files[].filepath` | string |  |
| `files[].author_id` | integer (int64) |  |
| `files[].mime_type` | string |  |
| `files[].base64_content` | string |  |
| `content` | string |  |
| `message_id` | integer (int64) |  |
| `src_module_id` | integer (int64) |  |

## پاسخ

```json
{
  "data": {
    "content": ""
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
| `data.content` | string |  |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
