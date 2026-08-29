# /api/dialog/assign

درخواست

## آدرس

```
/api/dialog/assign
```

## درخواست

```json
{
  "topic": "",
  "assigned": [
    0
  ],
  "dialog_id*": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `topic` | string |  |
| `assigned[]` | array |  |
| `dialog_id*` | integer (int64) |  |

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
