# گرفتن زیر پوشه های پوشه مشتری

## آدرس

```
/api/client/getSubfolderId
```

## درخواست

```json
{
  "client_id": 0,
  "template_folder_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `client_id` | integer (int64) | شناسه مشتری |
| `template_folder_id` | integer (int64) | زیر پوشه خودکار پوشه مشتری |

## پاسخ

```json
{
  "data": {
    "sub_folder_id": 0
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
| `data.sub_folder_id` | integer (int64) | زیر پوشه خودکار پوشه مشتری |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
