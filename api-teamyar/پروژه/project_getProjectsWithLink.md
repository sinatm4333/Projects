# لیست پروژه های لینک شده

## آدرس

```
/api/project/getProjectsWithLink
```

## درخواست

```json
{
  "from": 0,
  "count": 0,
  "total": 0,
  "link_id": 0,
  "link_type": 0,
  "link_module_id": 0,
  "just_open_project": false
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `from` | integer (int32) | از |
| `count` | integer (int32) | تعداد نتایج |
| `total` | integer (int64) | کل نتایج |
| `link_id` | integer (int64) | شناسه ی بخش لینک شده به مرحله (اقدام یا پروژه یا تقویم و اسناد و ...) |
| `link_type` | integer (int32) | نوع لینک که با توجه به ENTITY های داخل هر ماژول تعیین می شود. STAGE_LINK_TYPE_TODO_TASK = 3, STAGE_LINK_TYPE_DOCUMENT = 1, STAGE_LINK_TYPE_EMAIL = 1, STAGE_LINK_TYPE_SMS = 1 |
| `link_module_id` | integer (int32) | شناسه ی ماژول لینک شده به مرحله |
| `just_open_project` | boolean | 1 : جستجو فقط در پروژه های باز0 : جستجو در تمام پروژه ها |

## پاسخ

```json
{
  "data": [
    {
      "id": 0,
      "title": "",
      "status": 0,
      "progress": 0,
      "author_id": 0,
      "date_limit": 0,
      "date_start": 0,
      "date_create": 0,
      "date_modify": 0
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
| `data[]` | array | آرایه پروژه های لینک شده |
| `data[].id` | integer (int64) | شناسه پروژه |
| `data[].title` | string | عنوان پروژه |
| `data[].status` | integer (int32) | وضعیت باز یا بسته بودن پروژه active = 0 archived/closed = 1 |
| `data[].progress` | integer (int32) | درصد پیشرفت پروژه |
| `data[].author_id` | integer (int64) | شناسه ی سازنده ی پروژهsource table name : `0000000`.profile_main\| column name: ID |
| `data[].date_limit` | integer (int64) | تاریخ مهلت |
| `data[].date_start` | integer (int64) | تاریخ شروع |
| `data[].date_create` | integer (int64) | تاریخ ساخت پروژه |
| `data[].date_modify` | integer (int64) | تاریخ تغییر پروژه |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
