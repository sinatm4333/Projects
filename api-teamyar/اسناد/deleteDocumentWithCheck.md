# حذف سند به همراه چک

حذف سند پس از بررسی شرایط حذف.

## آدرس

```
/api/deleteDocumentWithCheck
```

## درخواست

```json
{
  "id": 0,
  "move_to_trash": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | number | شناسه سند |
| `move_to_trash` | number | انتقال به سطل زباله به‌جای حذف کامل |

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

- [ایجاد سند](createDocumentFile.md)
- [فهرست اسناد](document_list.md)
