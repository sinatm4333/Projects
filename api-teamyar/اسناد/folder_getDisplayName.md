# گرفتن نام فولدر

## آدرس

```
/api/folder/getDisplayName
```

## درخواست

```json
{
  "folder_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `folder_id` | integer (int64) | شناسه پوشه |

## پاسخ

```json
{
  "data": {
    "folder_name": ""
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
| `data` | object | data |
| `data.folder_name` | string | نام پوشه |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
