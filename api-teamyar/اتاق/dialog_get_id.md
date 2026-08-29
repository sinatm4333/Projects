# /api/dialog/get_id

درخواست

## آدرس

```
/api/dialog/get_id
```

## درخواست

```json
{
  "type": 0,
  "box_id": 0,
  "user_id": 0,
  "portal_group_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `type` | integer (int32) |  |
| `box_id` | integer (int64) |  |
| `user_id` | integer (int64) |  |
| `portal_group_id` | integer (int64) |  |

## پاسخ

```json
{
  "data": {
    "dialog_id": 0
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
| `data.dialog_id` | integer (int64) |  |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
