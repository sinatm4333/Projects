# /api/dialog/members

درخواست

## آدرس

```
/api/dialog/members
```

## درخواست

```json
{
  "dialog_id*": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `dialog_id*` | integer (int64) |  |

## پاسخ

```json
{
  "data": {
    "members": [
      {
        "name": "",
        "user_id": 0
      }
    ]
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
| `data.members[]` | array |  |
| `data.members[].name` | string |  |
| `data.members[].user_id` | integer (int64) |  |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
