# گرفتن شناسه پوشه مشتری

دریافت شناسه پوشه اسناد متعلق به یک مشتری.

## آدرس

```
/api/client/getFolderId
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

- [فهرست اسناد](document_list.md) — `folder_id` به‌عنوان `parent_id` قابل استفاده است.
