# دریافت اطلاعات مرحله جریان کار

دریافت اطلاعات یک مرحله از جریان کار با شناسه مرحله

## آدرس

```
/api/todo/step/get
```

## درخواست

```json
{
  "id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) | شناسه مرحله |

## پاسخ

```json
{
  "data": {
    "id": 0,
    "wf_id": 0,
    "width": 0,
    "height": 0,
    "status": 0,
    "file_id": 0,
    "form_id": 0,
    "pos_top": "",
    "all_edit": 0,
    "disabled": 0,
    "duration": 0,
    "pos_left": "",
    "ty_state": 0,
    "beginning": 0,
    "condition": 0,
    "module_id": 0,
    "source_id": 0,
    "step_name": "",
    "target_id": 0,
    "time_unit": 0,
    "bpms_wf_id": 0,
    "bpms_resp_id": 0,
    "desc_file_id": 0,
    "group_assign": 0,
    "bpms_topic_id": 0,
    "step_progress": 0,
    "show_in_portal": 0,
    "bpms_section_id": 0,
    "bpms_category_id": 0,
    "top_comment_author": 0,
    "responsible_task_author": 0
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
| `data.id` | integer (int64) | شناسه مرحله |
| `data.wf_id` | integer (int64) | شناسه جریان کار |
| `data.width` | integer (int32) | عرض |
| `data.height` | integer (int32) | ارتفاع |
| `data.status` | integer (int32) | نوع نماد مرحله STEP_STATUS_START =1, STEP_STATUS_END =2, STEP_STATUS_STARTEND =3, STEP_STATUS_PARALLEL =4, STEP_STATUS_EXCLUSIVE =8, STEP_STATUS_ACTIVITY =16, STEP_STATUS_SELECTIVE =32, STEP_STATUS_INCLUSIVE =64, STEP_STATUS_SMS =128, STEP_STATUS_EMAIL =256 |
| `data.file_id` | integer (int64) | شناسه فایلی که تمپلیت در ان ذخیره میشود |
| `data.form_id` | integer (int64) | شناسه فرم مرحله |
| `data.pos_top` | string | پوزیشن نسبت به بالای صفحه |
| `data.all_edit` | integer (int64) | در صورتی که این فیلد مقدار 1 داشته باشد به تمام افراد مسئول دسترسی تغییر مسئول مرحله در اقدام را دارند |
| `data.disabled` | integer (int32) | فعال و غیر فعال بودن جریان کار |
| `data.duration` | integer (int64) | مدت مرحله |
| `data.pos_left` | string | پوزیشن نسبت به سمت چپ صفحه |
| `data.ty_state` | integer (int32) | وضعیت 4مرحله ای اقدام میباشد که با فعال شدن هر مرحله، اقدام تغییر وضعیت پیدا میکند TODO_TASK_TY_STATE_DRAFT=0, TODO_TASK_TY_STATE_CHECK=1, TODO_TASK_TY_STATE_DO=2, TODO_TASK_TY_STATE_DONE=3 |
| `data.beginning` | integer (int32) | در صورتی که بخواهیم یکی از مراحل به عنوان مرحله ی شروع جریان کارمان باشد این فیلد مقدار 1 میگیرد |
| `data.condition` | integer (int64) | شرط ارتباط بین مراحل |
| `data.module_id` | integer (int64) | شناسه ماژول |
| `data.source_id` | integer (int64) | شناسه مرحله ای که به عنوان منبع انتخاب شده است |
| `data.step_name` | string | عنوان مرحله |
| `data.target_id` | integer (int64) | شناسه مرحله ای که به عنوان مقصد انتخاب شده است |
| `data.time_unit` | integer (int32) | واحد زمانی |
| `data.bpms_wf_id` | integer (int64) | شناسه ی جریان کار bpmn بین رده ایsource table name : `0000000`.todo_workflow \| column name: ID |
| `data.bpms_resp_id` | integer (int64) | مسئول پیش فرض مرحله اقدام در زمان انتخاب پایان واسط پیوستی و جدید |
| `data.desc_file_id` | integer (int64) | در صورتی که مرحله شامل متن توضیحات باشد این توضیحات در فایلی که شناسه ی ان در این فیلد ذخیره میشود قرار میگیرد |
| `data.group_assign` | integer (int64) | در صورتی که این فیلد مقدار 1 داشته باشد با افزوده شدن مرحله تمام افراد مسئول درا قدام به صورت گروهی اساین میشوند |
| `data.bpms_topic_id` | integer (int64) | شناسه ی موضوع که برای پایان واسط جدید و پایان واسط پیوستی استفاده میشود |
| `data.step_progress` | integer (int32) | مقدار پیشرفت مرحله ی جریان کار |
| `data.show_in_portal` | integer (int32) | نمایش در پورتالدر صورتی که این فیلد مقدار 1 داشته باشد مرحله در پورتال نمایش داده میشود |
| `data.bpms_section_id` | integer (int64) | شناسه ی بخش bpmn بین رده ایsource table name : `0000000`.todo_section \| column name: ID |
| `data.bpms_category_id` | integer (int64) | شناسه ی رده ی bpmnبین رده ایsource table name : `0000000`.todo_category \| column name: ID |
| `data.top_comment_author` | integer (int64) | ایجاد کننده توضیح اصلی اقدام کاربر باشد یا سیستمی(تیم یار) |
| `data.responsible_task_author` | integer (int64) | در صورتی که بخواهیم مسئول یکی از مراحل اقدام ایجاد کننده ی اقدام باشد این فیلد مقدار 1 میگیرد |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
