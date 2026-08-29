# عملیات تولیدی

ایجاد عملیات تولیدی

## آدرس

```
/api/GetOperation
```

## درخواست

```json
{
  "id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) | شناسه اصلی (سیستمی) |

## پاسخ

```json
{
  "data": {
    "id": 0,
    "code": 0,
    "title": "",
    "org_id": 0,
    "author_id": 0,
    "description": "",
    "creation_date": 0,
    "modification_date": 0,
    "modification_user_id": 0
  },
  "error": {
    "status": 0,
    "message": ""
  },
  "success": false
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data` | object | آبجکت اصلی |
| `data.id` | integer (int64) | شناسه اصلی (سیستمی) |
| `data.code` | integer (int64) | شناسه، چیزی که کاربر هم میتواند ویرایش کند |
| `data.title` | string | عنوان |
| `data.org_id` | integer (int64) | شناسه سازمان |
| `data.author_id` | integer (int64) | شناسه ایجاد کننده |
| `data.description` | string | توضیحات |
| `data.creation_date` | integer (int64) | تاریخ ایجاد |
| `data.modification_date` | integer (int64) | تاریخ تغییر |
| `data.modification_user_id` | integer (int64) | شناسه فرد تغییر دهنده |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
