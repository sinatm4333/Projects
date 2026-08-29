# گرفتن نوع زیرپوشه مشتریان

حقیقی 3 USER_TYPE_NATURAL حقوقی 4 USER_TYPE_LEGAL

## آدرس

```
/api/setting/template/folder/getUserType
```

## درخواست

```json
{
  "template_folder_id*": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `template_folder_id*` | integer (int64) | زیر پوشه خودکار پوشه مشتری |

## پاسخ

```json
{
  "data": {
    "user_type": 0
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
| `data.user_type` | integer (int32) | حقیقی 3 USER_TYPE_NATURAL حقوقی 4 USER_TYPE_LEGAL |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
