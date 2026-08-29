# /api/dialog/favorite

درخواست

## آدرس

```
/api/dialog/favorite
```

## درخواست

```json
{
  "dialog_id*": 0,
  "is_favorite": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `dialog_id*` | integer (int64) |  |
| `is_favorite` | integer (int32) |  |

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
