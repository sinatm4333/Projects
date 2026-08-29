# حذف دسترسی‌های پوشه‌ای که برای پورتال انتخاب شده است

حذف دسترسی‌های یک کاربر روی سند/پوشه.

## آدرس

```
/api/document/deletePermission
```

## درخواست

```json
{
  "user_id": 0,
  "perm_type": 0,
  "document_id": 0,
  "permissions": [0]
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `document_id` | number | شناسه سند/پوشه |
| `user_id` | number | شناسه کاربر |
| `perm_type` | number | نوع دسترسی |
| `permissions` | array\<number\> | شناسه دسترسی‌هایی که حذف می‌شوند |

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

- [گرفتن اطلاعات یک سند](document_getInfo.md)
- [فهرست اسناد](document_list.md) — فیلد `check_perm` در ورودی آن.
