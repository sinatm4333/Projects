# به روز رسانی پوشه مشتریان

## آدرس

```
/api/client/updateFolderId
```

## درخواست

```json
{
  "client_id*": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `client_id*` | integer (int64) | شناسه مشتری |

## پاسخ

```json
{
  "data": {
    "folder_id": 0
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
| `data` | object | داده |
| `data.folder_id` | integer (int64) | شناسه پوشه |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
