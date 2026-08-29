# گرفتن نوع زیرپوشه مشتریان

دریافت نوع کاربر مرتبط با یک پوشه الگو.

## آدرس

```
/api/setting/template/folder/getUserType
```

## درخواست

```json
{
  "template_folder_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `template_folder_id` | number | شناسه پوشه الگو |

## پاسخ

```json
{
  "data": { "user_type": 0 },
  "error": { "status": 0, "message": "" },
  "success": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data.user_type` | number | نوع کاربر |
| `error.status` | number | کد خطا |
| `error.message` | string | پیام خطا |
| `success` | number | نتیجه اجرا |

## مرتبط

- [گرفتن زیرپوشه‌های پوشه مشتری](client_getSubfolderId.md) — همان `template_folder_id` در ورودی آن.
