# دریافت لیست اقداماتی که یک مشتری در آن اقدام اساین شده است

دریافت لیست اقداماتی که یک مشتری در آن اقدام اساین شده است

## آدرس

```
/api/todo/task/list/crm/get
```

## درخواست

```json
{
  "from": 0,
  "count": 0,
  "client_id": 0,
  "archive_db": 0,
  "category_id": 0,
  "task_status": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `from` | integer (int32) | از (شروع لیست) |
| `count` | integer (int32) | تعداد اقدام |
| `client_id` | integer (int64) | شناسه مشتری |
| `archive_db` | integer (int32) | 1: لیست اقدامات آرشیو شده، 0 : لیست اقدامات معمولی |
| `category_id` | integer (int64) | شناسه رده |
| `task_status` | integer (int32) | وضعیت اقدام، `TASK_STATUS_OPEN=1`، `TASK_STATUS_CLOSE=2`، `TASK_STATUS_SUSPEND=3` |

## پاسخ

```json
{
  "data": {
    "tasks": [
      {
        "id": 0,
        "perm": 0,
        "type": 0,
        "color": "",
        "wf_id": 0,
        "status": 0,
        "bpmn_id": 0,
        "bpms_id": 0,
        "favorite": 0,
        "owner_id": 0,
        "progress": 0,
        "topic_id": 0,
        "ty_state": 0,
        "author_id": 0,
        "folder_id": 0,
        "module_id": 0,
        "view_date": 0,
        "perm_close": 0,
        "profile_id": 0,
        "t_deadline": 0,
        "t_priority": 0,
        "task_count": 0,
        "task_title": "",
        "author_name": "",
        "category_id": 0,
        "portal_show": 0,
        "repeat_type": 0,
        "archive_flag": 0,
        "bpmn_step_id": 0,
        "last_step_id": 0,
        "reference_id": 0,
        "repeat_count": 0,
        "t_start_date": 0,
        "last_modifier": 0,
        "t_modify_date": 0,
        "t_return_date": 0,
        "parent_task_id": 0,
        "t_real_end_date": 0,
        "last_responsible": 0,
        "t_auto_close_date": 0
      }
    ],
    "total": 0
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
| `data` | object | آبجکتی از آرایه هایی که شامل اطلاعات اقدام می باشد |
| `data.tasks[]` | array | آرایه ای از اطلاعات اقدام |
| `data.tasks[].id` | integer (int64) | شناسه اقدام |
| `data.tasks[].perm` | integer (int32) | مقدار دسترسی (در هر ماژول بستگی به نوع دسترسی مقادیر متفاوت است) |
| `data.tasks[].type` | integer (int32) | نوع اقدام، `TASK_TYPE_NORMAL=1`، `TASK_TYPE_PERIODICALLY=2`، `TASK_TYPE_PUBLIC=3`، `TASK_TYPE_PORTAL=4` |
| `data.tasks[].color` | string | رنگ اقدام |
| `data.tasks[].wf_id` | integer (int64) | شناسه جریان کار اقدام |
| `data.tasks[].status` | integer (int32) | وضعیت اقدام، `TASK_STATUS_OPEN=1`، `TASK_STATUS_CLOSE=2`، `TASK_STATUS_SUSPEND=3` |
| `data.tasks[].bpmn_id` | integer (int64) | شناسه ی bpmn بین رده ای، source table name : `0000000`.todo_workflow \| column name: ID |
| `data.tasks[].bpms_id` | integer (int64) | شناسه ی unique برای bpmnبین رده ای ایجاد شده در یک سری |
| `data.tasks[].favorite` | integer (int64) | برگزیده |
| `data.tasks[].owner_id` | integer (int64) | شناسه ی مالک اقدام |
| `data.tasks[].progress` | integer (int32) | مقدار پیشرفت اقدام |
| `data.tasks[].topic_id` | integer (int64) | شناسه موضوع |
| `data.tasks[].ty_state` | integer (int32) | وضعیت 4 مرحله ای اقدام، TODO_TASK_TY_STATE_DRAFT=0 پیش نویش، TODO_TASK_TY_STATE_CHECK=1 بررسی، TODO_TASK_TY_STATE_DO=2 اجرا، TODO_TASK_TY_STATE_DONE=3 کامل |
| `data.tasks[].author_id` | integer (int64) | ایجاد کننده (جدول Profile_Main) |
| `data.tasks[].folder_id` | integer (int64) | فولدر ذخیره سازی فایل ها |
| `data.tasks[].module_id` | integer (int64) | شناسه ماژول |
| `data.tasks[].view_date` | integer (int64) | تاریخ اخرین مشاهده |
| `data.tasks[].perm_close` | integer (int32) | دسترسی بستن اقدام |
| `data.tasks[].profile_id` | integer (int64) | شناسه پروفایل کاربر پابلیک که اقدام را ایجاد کرده است |
| `data.tasks[].t_deadline` | integer (int64) | تاریخ مهلت |
| `data.tasks[].t_priority` | integer (int32) | اولویت اقدام |
| `data.tasks[].task_count` | integer (int64) | تعداد اقدام های افزوده شده |
| `data.tasks[].task_title` | string | عنوان اقدام |
| `data.tasks[].author_name` | string | نام ایجاد کننده، که این فیلد برای اقدام های عمومی استفاده میشود |
| `data.tasks[].category_id` | integer (int64) | شناسه رده |
| `data.tasks[].portal_show` | integer (int32) | نمایش اقدام در پورتال، در صورتی که بخواهیم اقدامی که پورتال نیست در پورتال نمایش داده شود از این فیلد استفاده میکنیم، show task in the portal. 0=no setting; 1=view all steps; 2=view first step |
| `data.tasks[].repeat_type` | integer (int32) | نوع تکرار، EVERY_DAY: 1، EVERY_WEEK:2، EVERY_MONTH:3، EVERY_YEAR:4 |
| `data.tasks[].archive_flag` | integer (int32) | در صورتی که این فیلد مقدار 1 داشته باشد در فرایند ارشیو به دیتابیس ارشیو منتقل میشود |
| `data.tasks[].bpmn_step_id` | integer (int64) | شناسه ی مرحله ی bpmnبین رده ای، source table name : `0000000`.todo_step \| column name: ID |
| `data.tasks[].last_step_id` | integer (int64) | حذف شده |
| `data.tasks[].reference_id` | integer (int64) | شناسه مرجع |
| `data.tasks[].repeat_count` | integer (int32) | تعداد تسک دوره ای که کاربر میخواهد اد کند |
| `data.tasks[].t_start_date` | integer (int64) | تاریخ شروع |
| `data.tasks[].last_modifier` | integer (int64) | اخرین تغییر دهنده |
| `data.tasks[].t_modify_date` | integer (int64) | تاریخ اخرین تغییر |
| `data.tasks[].t_return_date` | integer (int64) | تاریخ بازگرداندن، در صورتی که اقدام موکول شده باشد در این تاریخ بازگردانده میشود |
| `data.tasks[].parent_task_id` | integer (int64) | شناسه تسک والد |
| `data.tasks[].t_real_end_date` | integer (int64) | تاریخ پایان اقدام |
| `data.tasks[].last_responsible` | integer (int64) | اخرین مسئول مرحله |
| `data.tasks[].t_auto_close_date` | integer (int64) | تاریخ پایان اتوماتیک، در صورتی که این فیلد مقداردهی شود در این تاریخ به صورت اتوماتیک تسک بسته میشود |
| `data.total` | integer (int32) | تعداد کل |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
