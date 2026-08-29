# تغییر نام پوشه مشتری

به‌روزرسانی نام پوشه اسناد یک مشتری.

## آدرس

```
/api/client/updateFolderName
```

## درخواست

```json
{
  "client_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `client_id` | number | شناسه مشتری |

## پاسخ

```json
{
  "error": { "status": 0, "message": "" },
  "success": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `error.status` | number | کد خطا |
| `error.message` | string | پیام خطا |
| `success` | number | نتیجه اجرا |

## مرتبط

- [به‌روزرسانی پوشه مشتریان](client_updateFolderId.md)
- [گرفتن شناسه پوشه مشتری](client_getFolderId.md)
