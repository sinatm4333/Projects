# گرفتن زیرپوشه‌های پوشه مشتری

دریافت شناسه زیرپوشه یک مشتری بر اساس پوشه الگو.

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
| `client_id` | number | شناسه مشتری |
| `template_folder_id` | number | شناسه پوشه الگو |

## پاسخ

```json
{
  "data": { "sub_folder_id": 0 },
  "error": { "status": 0, "message": "" },
  "success": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data.sub_folder_id` | number | شناسه زیرپوشه |
| `error.status` | number | کد خطا |
| `error.message` | string | پیام خطا |
| `success` | number | نتیجه اجرا |

## مرتبط

- [گرفتن پوشه‌ی مشتریان](client_getRootId.md) — پوشه ریشه مشتریان.
- [گرفتن شناسه پوشه مشتری](client_getFolderId.md) — پوشه یک مشتری خاص.
- [فهرست اسناد](document_list.md) — `sub_folder_id` به‌عنوان `parent_id` قابل استفاده است.
