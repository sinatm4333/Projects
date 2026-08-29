# حذف ورژن‌های فایل

حذف نسخه‌های اضافی اسناد و نگه‌داشتن حداکثر تعداد مشخص‌شده.

## آدرس

```
/api/document/deleteAdditionalVersions
```

## درخواست

بدنه درخواست یک **آرایه** است (نه آبجکت) — امکان پردازش چند سند در یک فراخوانی:

```json
[
  {
    "document_id": 0,
    "max_version_count": 0
  }
]
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `[].document_id` | number | شناسه سند |
| `[].max_version_count` | number | حداکثر تعداد نسخه‌ای که نگه داشته می‌شود |

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

- [فهرست اسناد](document_list.md) — فیلد `version` هر سند.
- [حذف سند به همراه چک](deleteDocumentWithCheck.md)
