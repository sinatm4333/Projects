# لیست تسک های لینک شده

## آدرس

```
/api/todo/task/list/link/get
```

## درخواست

```json
{
  "from": 0,
  "type": 0,
  "count": 0,
  "link_id": 0,
  "module_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `from` | integer (int32) | از |
| `type` | integer (int32) | نوع اقدام TASK_TYPE_NORMAL =1, TASK_TYPE_PERIODICALLY =2, TASK_TYPE_PUBLIC =3, TASK_TYPE_PORTAL =4, |
| `count` | integer (int32) | تعداد نتایج |
| `link_id` | integer (int64) | شناسه لینک |
| `module_id` | integer (int64) | شناسه ماژول لینک شده |

## پاسخ

```json
{
  "data": [
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
  "error": {
    "status": 0,
    "message": ""
  },
  "success": false
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data[]` | array | لیست اقدامات |
| `data[].id` | integer (int64) | شناسه اقدام |
| `data[].perm` | integer (int32) | مقدار دسترسی (در هر ماژول بستگی به نوع دسترسی مقادیر متفاوت است) |
| `data[].type` | integer (int32) | نوع اقدام TASK_TYPE_NORMAL =1, TASK_TYPE_PERIODICALLY =2, TASK_TYPE_PUBLIC =3, TASK_TYPE_PORTAL =4, |
| `data[].color` | string | رنگ اقدام |
| `data[].wf_id` | integer (int64) | شناسه جریان کار اقدام |
| `data[].status` | integer (int32) | وضعیت اقدام TASK_STATUS_OPEN =1, TASK_STATUS_CLOSE =2, TASK_STATUS_SUSPEND =3 |
| `data[].bpmn_id` | integer (int64) | شناسه ی bpmn بین رده ایsource table name : `0000000`.todo_workflow \| column name: ID |
| `data[].bpms_id` | integer (int64) | شناسه ی unique برای bpmnبین رده ای ایجاد شده در یک سری |
| `data[].favorite` | integer (int64) | برگزیده |
| `data[].owner_id` | integer (int64) | شناسه ی مالک اقدام |
| `data[].progress` | integer (int32) | مقدار پیشرفت اقدام |
| `data[].topic_id` | integer (int64) | شناسه موضوع |
| `data[].ty_state` | integer (int32) | وضعیت 4 مرحله ای اقدام TODO_TASK_TY_STATE_DRAFT=0 پیش نویش TODO_TASK_TY_STATE_CHECK=1 بررسی TODO_TASK_TY_STATE_DO=2 اجرا TODO_TASK_TY_STATE_DONE=3 کامل |
| `data[].author_id` | integer (int64) | ایجاد کننده (جدول Profile_Main) |
| `data[].folder_id` | integer (int64) | فولدر ذخیره سازی فایل ها |
| `data[].module_id` | integer (int64) | شناسه ماژول |
| `data[].view_date` | integer (int64) | تاریخ اخرین مشاهده |
| `data[].perm_close` | integer (int32) | دسترسی بستن اقدام |
| `data[].profile_id` | integer (int64) | شناسه پروفایل کاربر پابلیک که اقدام را ایجاد کرده است |
| `data[].t_deadline` | integer (int64) | تاریخ مهلت |
| `data[].t_priority` | integer (int32) | اولویت اقدام |
| `data[].task_count` | integer (int64) | تعداد اقدام های افزوده شده |
| `data[].task_title` | string | عنوان اقدام |
| `data[].author_name` | string | نام ایجاد کنندهکه این فیلد برای اقدام های عمومی استفاده میشود |
| `data[].category_id` | integer (int64) | شناسه رده |
| `data[].portal_show` | integer (int32) | نمایش اقدام در پورتالدر صورتی که بخواهیم اقدامی که پورتال نیست در پورتال نمایش داده شود از این فیلد استفاده میکنیمshow task in the portal. 0=no setting; 1=view all steps; 2=view first step |
| `data[].repeat_type` | integer (int32) | نوع تکرارEVERY_DAY: 1EVERY_WEEK:2EVERY_MONTH:3EVERY_YEAR:4 |
| `data[].archive_flag` | integer (int32) | در صورتی که این فیلد مقدار 1 داشته باشد در فرایند ارشیو به دیتابیس ارشیو منتقل میشود |
| `data[].bpmn_step_id` | integer (int64) | شناسه ی مرحله ی bpmnبین رده ایsource table name : `0000000`.todo_step \| column name: ID |
| `data[].last_step_id` | integer (int64) | حذف شده |
| `data[].reference_id` | integer (int64) | شناسه مرجع |
| `data[].repeat_count` | integer (int32) | تعداد تسک دوره ای که کاربر میخواهد اد کند |
| `data[].t_start_date` | integer (int64) | تاریخ شروع |
| `data[].last_modifier` | integer (int64) | اخرین تغییر دهنده |
| `data[].t_modify_date` | integer (int64) | تاریخ اخرین تغییر |
| `data[].t_return_date` | integer (int64) | تاریخ بازگرداندندر صورتی که اقدام موکول شده باشد در این تاریخ بازگردانده میشود |
| `data[].parent_task_id` | integer (int64) | شناسه تسک والد |
| `data[].t_real_end_date` | integer (int64) | تاریخ پایان اقدام |
| `data[].last_responsible` | integer (int64) | اخرین مسئول مرحله |
| `data[].t_auto_close_date` | integer (int64) | تاریخ پایان اتوماتیکدر صورتی که این فیلد مقداردهی شود در این تاریخ به صورت اتوماتیک تسک بسته میشود |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
