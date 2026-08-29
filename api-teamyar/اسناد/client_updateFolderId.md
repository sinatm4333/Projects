# به‌روزرسانی پوشه مشتریان

به‌روزرسانی پوشه اسناد یک مشتری و دریافت شناسه آن.

## آدرس

```
/api/client/updateFolderId
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
  "data": { "folder_id": 0 },
  "error": { "status": 0, "message": "" },
  "success": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data.folder_id` | number | شناسه پوشه مشتری |
| `error.status` | number | کد خطا |
| `error.message` | string | پیام خطا |
| `success` | number | نتیجه اجرا |

## مرتبط

- [گرفتن شناسه پوشه مشتری](client_getFolderId.md) — همان ورودی و خروجی، بدون به‌روزرسانی.
- [گرفتن زیرپوشه‌های پوشه مشتری](client_getSubfolderId.md)
