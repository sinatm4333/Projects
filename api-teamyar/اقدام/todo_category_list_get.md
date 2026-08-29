# دریافت لیست رده‌های یک بخش

دریافت فهرست رده‌های (category) متعلق به یک بخش.

## آدرس

```
/api/todo/category/list/get
```

## درخواست

```json
{
  "id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | number | شناسه بخش |

## پاسخ

```json
{
  "data": [
    {
      "id": 0,
      "order": 0,
      "author_id": 0,
      "folder_id": 0,
      "public_cat": 0,
      "section_id": 0,
      "date_create": 0,
      "workflow_flag": 0,
      "category_title": "",
      "category_description": "",
      "add_task_showing_fields": 0
    }
  ],
  "error": { "status": 0, "message": "" },
  "success": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data[].id` | number | شناسه رده |
| `data[].category_title` | string | عنوان رده |
| `data[].category_description` | string | توضیحات رده |
| `data[].section_id` | number | شناسه بخش |
| `data[].folder_id` | number | شناسه پوشه |
| `data[].order` | number | ترتیب |
| `data[].public_cat` | number | عمومی بودن رده |
| `data[].workflow_flag` | number | فلگ گردش کار |
| `data[].add_task_showing_fields` | number | فیلدهای نمایشی هنگام افزودن اقدام |
| `data[].author_id` | number | شناسه ایجادکننده |
| `data[].date_create` | number | تاریخ ایجاد |
| `error.status` | number | کد خطا |
| `error.message` | string | پیام خطا |
| `success` | number | نتیجه اجرا |

## مرتبط

- [ویرایش اقدام](todo_taskedit.md) — فیلد `category_id` در ورودی آن.
