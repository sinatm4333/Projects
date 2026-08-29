# دریافت مراحل پروژه

## آدرس

```
/api/project/getStages
```

## درخواست

```json
{
  "from": 0,
  "count": 0,
  "order_type": 0,
  "project_id": 0,
  "pagenamerato_count": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `from` | integer (int32) | از |
| `count` | integer (int32) | تعداد نتایج |
| `order_type` | integer (int32) | نوع مرتب سازی |
| `project_id` | integer (int64) | شناسه پروژه |
| `pagenamerato_count` | integer (int32) | تعداد مراحلی که در یک صفحه جستجو نمایش می دهد |

## پاسخ

```json
{
  "data": {
    "stages": [
      {
        "id": 0,
        "flags": 0,
        "title": "",
        "amount": 0,
        "link_id": 0,
        "removed": 0,
        "duration": 0,
        "position": 0,
        "progress": 0,
        "author_id": 0,
        "crm_count": 0,
        "link_type": 0,
        "parent_id": 0,
        "time_unit": 0,
        "date_limit": 0,
        "date_start": 0,
        "project_id": 0,
        "date_create": 0,
        "date_modify": 0,
        "description": "",
        "modifier_id": 0,
        "date_complete": 0,
        "link_module_id": 0,
        "stage_priority": 0,
        "stage_crm_exists": false,
        "planning_duration": 0,
        "planning_date_start": 0,
        "participation_amount": 0,
        "participation_amount_sum": 0
      }
    ],
    "page_count": 0
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
| `data.stages[]` | array | آرایه استیج های پروژه |
| `data.stages[].id` | integer (int64) | شناسه مرحله |
| `data.stages[].flags` | integer (int32) | STATUS_FLAG_ACTIVE = 0, باز بودن مرحله STATUS_FLAG_CLOSED = 1, بسته بودن مرحله |
| `data.stages[].title` | string | عنوان مرحله |
| `data.stages[].amount` | integer (int64) | هزینه |
| `data.stages[].link_id` | integer (int64) | شناسه ی بخش لینک شده به مرحله (اقدام یا پروژه یا تقویم و اسناد و ...) |
| `data.stages[].removed` | integer (int32) | حذف شده |
| `data.stages[].duration` | integer (int64) | مدت |
| `data.stages[].position` | integer (int32) | محل قرارگیری مرحله |
| `data.stages[].progress` | integer (int32) | درصد پیشرفت مرحله |
| `data.stages[].author_id` | integer (int64) | شناسه ی سازنده ی مرحله شناسه ی سازنده ی پروژهsource table name : `0000000`.profile_main\| column name: ID |
| `data.stages[].crm_count` | integer (int64) | تعداد مشتریان |
| `data.stages[].link_type` | integer (int64) | نوع لینک که با توجه به ENTITY های داخل هر ماژول تعیین می شود. STAGE_LINK_TYPE_TODO_TASK = 3, STAGE_LINK_TYPE_DOCUMENT = 1, STAGE_LINK_TYPE_EMAIL = 1, STAGE_LINK_TYPE_SMS = 1, |
| `data.stages[].parent_id` | integer (int64) | شناسه ی پرنت مرحلهsource table name : `0000000`.project_stage\| column name: ID |
| `data.stages[].time_unit` | integer (int32) | واحد زمانی |
| `data.stages[].date_limit` | integer (int64) | تاریخ پایان هر مرحله که با اضافه کردن مدت به تاریخ شروع محاسبه و ثبت می شود و در UI نمایش داده نمی شود. (قابل تعریف مستقیم نیست) |
| `data.stages[].date_start` | integer (int64) | تاریخ شروع مرحله |
| `data.stages[].project_id` | integer (int64) | شناسه ی پروژهsource table name : `0000000`.project_project\| column name: ID |
| `data.stages[].date_create` | integer (int64) | تاریخ ساخت مرحله |
| `data.stages[].date_modify` | integer (int64) | تاریخ آخرین تغییر مرحله |
| `data.stages[].description` | string | توضیحات |
| `data.stages[].modifier_id` | integer (int64) | شناسه ی آخرین تغییر دهنده ی اطلاعات مرحلهsource table name : `0000000`.profile_main\| column name: ID |
| `data.stages[].date_complete` | integer (int64) | تاریخ کامل شدن هر مرحله که با بستن آن ثبت می شود. |
| `data.stages[].link_module_id` | integer (int64) | شناسه ی ماژول لینک شده به مرحله |
| `data.stages[].stage_priority` | integer (int32) | فعال بودن یا نبودن گزینه ی اولویت در مراحل (0/1) |
| `data.stages[].stage_crm_exists` | boolean |  |
| `data.stages[].planning_duration` | integer (int64) | مدت برنامه ریزی شده ی مرحله |
| `data.stages[].planning_date_start` | integer (int64) | تاریخ شروع برنامه ریزی شده ی مرحله |
| `data.stages[].participation_amount` | integer (int64) | میزان مشارکت |
| `data.stages[].participation_amount_sum` | integer (int64) | مجموع هزینه ها |
| `data.page_count` | integer (int32) |  |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
