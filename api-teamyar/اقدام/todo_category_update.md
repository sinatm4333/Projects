# بروزرسانی رده

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
| `id` | integer (int64) | شناسه رده |
| `order` | integer (int32) | تقدم رده |
| `author_id` | integer (int64) | ایجاد کننده (جدول profile_main) |
| `folder_id` | integer (int64) | فولدر ذخیره سازی فایل ها |
| `public_cat` | integer (int32) | عمومی بودن رده با یک بودن این فیلد مشخص می شود |
| `section_id` | integer (int64) | شناسه بخشsource table name : `0000000`.todo_section \| column name: ID |
| `date_create` | integer (int64) | تاریخ ایجاد |
| `workflow_flag` | integer (int32) | در صورت یک بودن مقدار این فیلد انتخاب جریان کار در افزودن اقدام برای این رده اجباری میشود |
| `category_title` | string | عنوان رده |
| `category_description` | string | توضیحات رده |
| `add_task_showing_fields` | integer (int64) | این فیلد جهت نمایش کنترل های مربوط به ذخیره ی کالا، پروژه و مشتری در افزودن اقدام های این رده کاربرد دارد crm=1product=2project = 4 |

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
| `data` | object | آبجکت پاسخ |
| `data.id` | integer (int64) | شناسه رده |
| `data.err` | string | خطایی که از سمت back end برگردانده می شود |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
