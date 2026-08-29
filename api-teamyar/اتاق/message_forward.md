# /api/message/forward

درخواست

## آدرس

```
/api/message/forward
```

## درخواست

```json
{
  "message_id*": 0,
  "dst_dialog_id*": 0,
  "src_dialog_id*": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `message_id*` | integer (int64) |  |
| `dst_dialog_id*` | integer (int64) |  |
| `src_dialog_id*` | integer (int64) |  |

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
