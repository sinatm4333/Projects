# بروز رسانی اطلاعات بخش

بروز رسانی اطلاعات بخش

## آدرس

```
/api/todo/section/update
```

## درخواست

```json
{
  "id": 0,
  "order": 0,
  "author_id": 0,
  "date_create": 0,
  "section_name": "",
  "section_description": ""
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) | شناسه بخش |
| `order` | integer (int32) | تقدم بخش |
| `author_id` | integer (int64) | ایجاد کننده (جدول profile_main) |
| `date_create` | integer (int64) | تاریخ ایجاد |
| `section_name` | string | نام بخش |
| `section_description` | string | توضیحات بخش |

## پاسخ

```json
{
  "data": {
    "id": 0,
    "err": ""
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
| `data` | object |  |
| `data.id` | integer (int64) | شناسه بخش |
| `data.err` | string | در صورت وجود پیام خطا در back end، پیام نمایش داده میشود |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
