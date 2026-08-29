# بروزرسانی مرحله پروژه

## آدرس

```
/api/project/updateStage
```

## درخواست

```json
{
  "id": 0,
  "color": "",
  "flags": 0,
  "title": "",
  "users": [
    0
  ],
  "amount": 0,
  "offset": 0,
  "link_id": 0,
  "perm_id": 0,
  "removed": 0,
  "deadline": 0,
  "duration": 0,
  "position": 0,
  "progress": 0,
  "author_id": 0,
  "calendars": [
    0
  ],
  "errorCode": 0,
  "link_type": 0,
  "parent_id": 0,
  "perm_type": 0,
  "task_type": 0,
  "time_unit": 0,
  "date_limit": 0,
  "date_start": 0,
  "offset_end": 0,
  "project_id": 0,
  "task_color": "",
  "category_id": 0,
  "date_create": 0,
  "date_modify": 0,
  "description": "",
  "geted_title": false,
  "modifier_id": 0,
  "task_status": 0,
  "stage_weight": 0,
  "date_complete": 0,
  "from_template": 0,
  "task_deadline": 0,
  "task_priority": 0,
  "link_module_id": 0,
  "stage_priority": 0,
  "link_stage_sync": 0,
  "planning_duration": 0,
  "planning_date_limit": 0,
  "planning_date_start": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) | شناسه مرحله |
| `color` | string | رنگ اختصاص داده شده به هر مرحله |
| `flags` | integer (int32) | STATUS_FLAG_ACTIVE = 0, باز بودن مرحله STATUS_FLAG_CLOSED = 1, بسته بودن مرحله |
| `title` | string | عنوان مرحله |
| `users[]` | array | لیست مشتریان |
| `amount` | integer (int64) | هزینه |
| `offset` | integer (int64) | حذف شده |
| `link_id` | integer (int64) | شناسه ی بخش لینک شده به مرحله (اقدام یا پروژه یا تقویم و اسناد و ...) |
| `perm_id` | integer (int64) | مقدار شناسه ی دسترسی که یا ID خود مرحله است یا ID پرنت آن. اطلاعات دسترسی هر مرحله با این شناسه از جدول دسترسی ها خوانده می شود.source table name : `0000000`.project_ty_permission \| column name: ID |
| `removed` | integer (int32) | حذف شده |
| `deadline` | integer (int32) | مهلت |
| `duration` | integer (int64) | مدت |
| `position` | integer (int32) | محل قرار گیری مرحله |
| `progress` | integer (int32) | درصد پیشرفت مرحله |
| `author_id` | integer (int64) | شناسه ی سازنده ی مرحله شناسه ی سازنده ی پروژه source table name : `0000000`.profile_main\| column name: ID |
| `calendars[]` | array | شناسه تقویم هایی که در پروژه استفاده شده |
| `errorCode` | integer (int32) | کد خطا |
| `link_type` | integer (int32) | نوع لینک که با توجه به ENTITY های داخل هر ماژول تعیین می شود. STAGE_LINK_TYPE_TODO_TASK = 3, STAGE_LINK_TYPE_DOCUMENT = 1, STAGE_LINK_TYPE_EMAIL = 1, STAGE_LINK_TYPE_SMS = 1 |
| `parent_id` | integer (int64) | شناسه ی پرنت مرحله source table name : `0000000`.project_stage\| column name: ID |
| `perm_type` | integer (int32) | نوع دسترسی که برای مرحله همیشه 4 تعریف می شود با enum : PROJECT_STAGE_PERMISSION |
| `task_type` | integer (int32) | نوع تسک |
| `time_unit` | integer (int32) | واحد زمانی |
| `date_limit` | integer (int64) | تاریخ پایان هر مرحله که با اضافه کردن مدت به تاریخ شروع محاسبه و ثبت می شود و در UI نمایش داده نمی شود. (قابل تعریف مستقیم نیست) |
| `date_start` | integer (int64) | تاریخ شروع مرحله |
| `offset_end` | integer (int64) | حذف شده |
| `project_id` | integer (int64) | شناسه ی پروژهsource table name : `0000000`.project_project\| column name: ID |
| `task_color` | string | رنگ اقدامی که لینک است |
| `category_id` | integer (int32) | شناسه بخش |
| `date_create` | integer (int64) | تاریخ ساخت مرحله |
| `date_modify` | integer (int64) | تاریخ آخرین تغییر مرحله |
| `description` | string | توضیحات |
| `geted_title` | boolean | عنوان مرحله |
| `modifier_id` | integer (int64) | شناسه ی آخرین تغییر دهنده ی اطلاعات مرحلهsource table name : `0000000`.profile_main\| column name: ID |
| `task_status` | integer (int32) | وضعیت اقدام |
| `stage_weight` | integer (int32) | وزن مرحله |
| `date_complete` | integer (int64) | تاریخ کامل شدن هر مرحله که با بستن آن ثبت می شود. |
| `from_template` | integer (int32) | حذف شده |
| `task_deadline` | integer (int64) | مهلت اقدامی که لینک شده |
| `task_priority` | integer (int32) | اولویت اقدامی که لینک شده |
| `link_module_id` | integer (int64) | شناسه ی ماژول لینک شده به مرحله |
| `stage_priority` | integer (int32) | فعال بودن یا نبودن گزینه ی اولویت در مراحل (0/1) |
| `link_stage_sync` | integer (int32) | سینک مرحله - حذف شده |
| `planning_duration` | integer (int64) | مدت برنامه ریزی شده ی مرحله |
| `planning_date_limit` | integer (int64) | مهلت برنامه ریزی شده / محاسبه از زمان شروع و مهلت (در ui نمایش داده نمی شود) |
| `planning_date_start` | integer (int64) | تاریخ شروع برنامه ریزی شده ی مرحله |

## پاسخ

```json
{
  "error": {
    "status": 0,
    "message": ""
  },
  "success": false
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
