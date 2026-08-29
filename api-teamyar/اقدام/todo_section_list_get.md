# دریافت لیست بخش های اقدام

## آدرس

```
/api/todo/section/list/get
```

## درخواست

```json
{
  "id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) | شناسه کتگوری |

## پاسخ

```json
{
  "data": [
    {
      "id": 0,
      "order": 0,
      "author_id": 0,
      "date_create": 0,
      "section_name": "",
      "section_description": ""
    }
  ],
  "error": {
    "status": 0,
    "message": ""
  },
  "success": false
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data[]` | array | آرایه ای از بخش ها |
| `data[].id` | integer (int64) | شناسه بخش |
| `data[].order` | integer (int32) | تقدم بخش |
| `data[].author_id` | integer (int64) | ایجاد کننده (جدول profile_main) |
| `data[].date_create` | integer (int64) | تاریخ ایجاد |
| `data[].section_name` | string | نام بخش |
| `data[].section_description` | string | توضیحات بخش |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
