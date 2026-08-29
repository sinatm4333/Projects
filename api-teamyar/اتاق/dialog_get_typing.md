# /api/dialog/get_typing

درخواست

## آدرس

```
/api/dialog/get_typing
```

## درخواست

```json
{
  "user_id*": 0,
  "dialog_id*": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `user_id*` | integer (int64) |  |
| `dialog_id*` | integer (int64) |  |

## پاسخ

```json
{
  "data": {
    "name": ""
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
| `data.name` | string |  |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
