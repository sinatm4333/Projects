# /api/dialog/mute

درخواست

## آدرس

```
/api/dialog/mute
```

## درخواست

```json
{
  "dialog_id*": 0,
  "mute_type": 0,
  "mute_end_date": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `dialog_id*` | integer (int64) |  |
| `mute_type` | integer (int32) |  |
| `mute_end_date` | integer (int64) |  |

## پاسخ

```json
{
  "data": {
    "mute_end_date": 0
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
| `data.mute_end_date` | integer (int64) |  |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
