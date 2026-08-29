# گرفتن پوشه‌ی مشتریان

دریافت شناسه پوشه ریشه مشتریان.

## آدرس

```
/api/client/getRootId
```

## درخواست

```json
{}
```

بدون پارامتر.

## پاسخ

```json
{
  "data": { "root_id": 0 },
  "error": { "status": 0, "message": "" },
  "success": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data.root_id` | number | شناسه پوشه ریشه مشتریان |
| `error.status` | number | کد خطا |
| `error.message` | string | پیام خطا |
| `success` | number | نتیجه اجرا |

## مرتبط

- [گرفتن شناسه پوشه مشتری](client_getFolderId.md) — پوشه یک مشتری خاص.
- [فهرست اسناد](document_list.md) — `root_id` به‌عنوان `parent_id` قابل استفاده است.
