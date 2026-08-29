# /api/dialog/typing

درخواست

## آدرس

```
/api/dialog/typing
```

## درخواست

```json
{
  "dialog_id*": 0,
  "typing_chars": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `dialog_id*` | integer (int64) |  |
| `typing_chars` | integer (int32) |  |

## پاسخ

```json
{
  "error": {
    "status": 0,
    "message": ""
  },
  "success": false
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
