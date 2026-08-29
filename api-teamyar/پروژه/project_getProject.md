# دریافت اطلاعات پروژه

دریافت اطلاعات پروژه با شناسه پروژه

## آدرس

```
/api/project/getProject
```

## درخواست

```json
{
  "id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) | شناسه پروژه |

## پاسخ

```json
{
  "data": {
    "id": 0,
    "title": "",
    "event_id": 0,
    "date_start": 0,
    "todo_wf_id": 0,
    "description": "",
    "perm_portal": 0,
    "todo_topic_id": 0,
    "assigned_count": 0,
    "link_stage_sync": 0,
    "show_user_tasks": 0,
    "todo_section_id": 0,
    "todo_category_id": 0,
    "todo_default_wf_id": 0,
    "todo_responsible_id": 0,
    "show_amount_col_portal": 0,
    "show_first_step_to_all": 0,
    "show_progress_col_portal": 0,
    "show_amount_sum_col_portal": 0,
    "show_participation_col_portal": 0,
    "show_stage_description_portal": 0,
    "show_project_description_portal": 0
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
| `data.id` | integer (int64) | شناسه پروژه |
| `data.title` | string | عنوان پروژه |
| `data.event_id` | integer (int64) | شناسه ی رویداد متصل شدهsource table name : `0000000`.cal_event\| column name: ID |
| `data.date_start` | integer (int64) | تاریخ شروع |
| `data.todo_wf_id` | integer (int64) | شناسه ی جریان کار اقدام source table name : `0000000`.todo_workflow\| column name: ID |
| `data.description` | string | توضیحات پروژه |
| `data.perm_portal` | integer (int32) | دسترسی اضافه کردن تسک در پورتال |
| `data.todo_topic_id` | integer (int64) | شناسه ی موضوع اقدام source table name : `0000000`.todo_topic\| column name: ID |
| `data.assigned_count` | integer (int32) | تعداد کاربران مطلع |
| `data.link_stage_sync` | integer (int32) | حذف شده |
| `data.show_user_tasks` | integer (int32) | نمایش / عدم نمایش همه ی اقدام ها به کاربر در پورتال |
| `data.todo_section_id` | integer (int64) | شناسه ی بخش اقدام متصل شده source table name : `0000000`.todo_section\| column name: ID |
| `data.todo_category_id` | integer (int64) | شناسه ی رده ی اقدام متصل شدهsource table name : `0000000`.todo_category\| column name: ID |
| `data.todo_default_wf_id` | integer (int64) | شناسه جریان کار اقدام (داخلی) |
| `data.todo_responsible_id` | integer (int64) | شناسه ی مسئول اقدامsource table name : `0000000`.profile_main\| column name: ID |
| `data.show_amount_col_portal` | integer (int32) | نمایش / عدم نمایش ستون هزینه در پورتال |
| `data.show_first_step_to_all` | integer (int32) | نمایش / عدم نمایش مرحله ی اول به همه ی کاربران در پورتال |
| `data.show_progress_col_portal` | integer (int32) | نمایش / عدم نمایش ستون پیشرفت پروژه در پورتال |
| `data.show_amount_sum_col_portal` | integer (int32) | نمایش / عدم نمایش ستون مجموع مشارکت ها در پورتال |
| `data.show_participation_col_portal` | integer (int32) | نمایش / عدم نمایش ستون مشارکت من در پورتال |
| `data.show_stage_description_portal` | integer (int32) | نمایش / عدم نمایش توضیحات مرحله پروژه در پورتال |
| `data.show_project_description_portal` | integer (int32) | نمایش / عدم نمایش توضیحات پروژه در پورتال |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
