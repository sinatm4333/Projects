# بروزرسانی رده

به‌روزرسانی اطلاعات یک رده (category).

## آدرس

```
/api/todo/category/update
```

## درخواست

```json
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
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | number | شناسه رده |
| `category_title` | string | عنوان رده |
| `category_description` | string | توضیحات رده |
| `section_id` | number | شناسه بخش |
| `folder_id` | number | شناسه پوشه |
| `order` | number | ترتیب |
| `public_cat` | number | عمومی بودن رده |
| `workflow_flag` | number | فلگ گردش کار |
| `add_task_showing_fields` | number | فیلدهای نمایشی هنگام افزودن اقدام |
| `author_id` | number | شناسه ایجادکننده |
| `date_create` | number | تاریخ ایجاد |

## پاسخ

```json
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
```

پاسخ همان ساختار درخواست را بازمی‌گرداند (echo) — بدون `error`/`success`.

## مرتبط

- [دریافت لیست رده‌های یک بخش](todo_category_list_get.md) — همان فیلدها در خروجی.
