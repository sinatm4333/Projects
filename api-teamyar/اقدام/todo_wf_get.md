# دریافت اطلاعات جریان کار

دریافت اطلاعات جریان کار با شناسه جریان کار

## آدرس

```
/api/todo/wf/get
```

## درخواست

```json
{
  "id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) | شناسه جریان کار |

## پاسخ

```json
{
  "data": {
    "id": 0,
    "kind": 0,
    "name": "",
    "type": 0,
    "token": "",
    "cat_id": 0,
    "form_id": 0,
    "disabled": 0,
    "author_id": 0,
    "folder_id": 0,
    "section_id": 0,
    "date_create": 0,
    "form_id_request": 0,
    "step_top_comment_author": 0,
    "add_task_mandatory_fields": 0
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
| `data` | object | آبجکت اطلاعات |
| `data.id` | integer (int64) | شناسه جریان کار |
| `data.kind` | integer (int32) | نوع جریان کار، WORK_FLOW_KIND_WORKFLOW =1, جریان کار، WORK_FLOW_KIND_BPMN =2, bpmb، WORK_FLOW_KIND_BPMS =3, bpmn بین رده ای |
| `data.name` | string | عنوان جریان کار |
| `data.type` | integer (int32) | نوع جریان کار، `WORK_FLOW_TYPE_SEQUENTIAL=0`، `WORK_FLOW_TYPE_FLOATING=1` |
| `data.token` | string | توکن جریان کار که برای ایجاد اقدام عمومی استفاده میشود |
| `data.cat_id` | integer (int64) | شناسه رده، source table name : `0000000`.todo_category \| column name: ID |
| `data.form_id` | integer (int64) | شناسه فرم، source table name : `0000000`.todo_form \| column name: ID |
| `data.disabled` | integer (int32) | این فیلد جهت غیر فعال کردن جریان کار استفاده میشود درصورتی که 1 باشد جریان کار غیر فعال است و با مقدار صفر جریان کار فعال است |
| `data.author_id` | integer (int64) | ایجاد کننده (جدول Profile_main) |
| `data.folder_id` | integer (int64) | فولدر ذخیره سازی فایل ها |
| `data.section_id` | integer (int64) | شناسه بخش، source table name : `0000000`.todo_section \| column name: ID |
| `data.date_create` | integer (int64) | تاریخ ایجاد |
| `data.form_id_request` | integer (int64) | شناسه فرمی که میخواهیم در زمان ایجاد اقدام از طریق پورتال به کاربر نمایش داده شود و پر شود، source table name : `0000000`.todo_form \| column name: ID |
| `data.step_top_comment_author` | integer (int32) | در صورتی که این فیلد 1 باشد ایجاد کننده ی top comment سیستمی با شناسه ی 3 ایجاد میشود و با عنوان TeamYar نمایش داده میشود |
| `data.add_task_mandatory_fields` | integer (int64) | جهت افزودن اقدام در حاضر میتوانیم 3 فیلد را اجباری تعیین کنیم , 2 به توان n در دیتا بیس دخیره میشود، `TODO_TASK_EXTRA_FIELD_PRODUCT=2`، `TODO_TASK_EXTRA_FIELD_CRM=1`، `TODO_TASK_EXTRA_FIELD_PROJECT=4` |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
