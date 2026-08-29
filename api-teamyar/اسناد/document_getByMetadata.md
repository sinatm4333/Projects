# گرفتن سند از طریق متادیتا

جستجوی اسناد بر اساس یک فیلد متادیتا و مقدار آن.

## آدرس

```
/api/document/getByMetadata
```

## درخواست

```json
{
  "meta_id": 0,
  "meta_value": ""
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `meta_id` | number | شناسه فیلد متادیتا |
| `meta_value` | string | مقدار موردجستجو |

## پاسخ

```json
{
  "data": [
    {
      "id": 0,
      "size": 0,
      "type": 0,
      "deleted": 0,
      "version": 0,
      "filename": "",
      "filetype": 0,
      "mime_type": "",
      "date_create": 0
    }
  ],
  "error": { "status": 0, "message": "" },
  "success": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data[].id` | number | شناسه سند |
| `data[].filename` | string | نام فایل |
| `data[].filetype` | number | نوع فایل |
| `data[].mime_type` | string | نوع MIME |
| `data[].size` | number | حجم فایل |
| `data[].type` | number | نوع |
| `data[].version` | number | نسخه |
| `data[].deleted` | number | حذف‌شده |
| `data[].date_create` | number | تاریخ ایجاد |
| `error.status` | number | کد خطا |
| `error.message` | string | پیام خطا |
| `success` | number | نتیجه اجرا |

## مرتبط

- [فهرست اسناد](document_list.md) — فیلدهای `meta_id` و `meta_value` در ورودی و خروجی آن.
