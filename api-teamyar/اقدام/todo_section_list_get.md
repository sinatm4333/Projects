# دریافت لیست بخش‌های اقدام

دریافت فهرست بخش‌های (section) ماژول اقدام.

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
| `id` | number | شناسه |

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
  "error": { "status": 0, "message": "" },
  "success": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data[].id` | number | شناسه بخش |
| `data[].section_name` | string | نام بخش |
| `data[].section_description` | string | توضیحات بخش |
| `data[].order` | number | ترتیب |
| `data[].author_id` | number | شناسه ایجادکننده |
| `data[].date_create` | number | تاریخ ایجاد |
| `error.status` | number | کد خطا |
| `error.message` | string | پیام خطا |
| `success` | number | نتیجه اجرا |

## مرتبط

- [دریافت اطلاعات بخش](todo_section_get.md) — همان فیلدها برای یک بخش.
- [دریافت لیست رده‌های یک بخش](todo_category_list_get.md)
