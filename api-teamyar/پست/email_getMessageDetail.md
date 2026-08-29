# /api/email/getMessageDetail

درخواست

## آدرس

```
/api/email/getMessageDetail
```

## درخواست

```json
{
  "message_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `message_id` | integer (int64) |  |

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
