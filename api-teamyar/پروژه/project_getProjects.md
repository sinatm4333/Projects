# جستجو در عنوان پروژه

دریافت پروژه هایی که عنوان آن ها در جستجو وجود دارد

## آدرس

```
/api/project/getProjects
```

## درخواست

```json
{
  "from": 0,
  "count": 0,
  "search": "",
  "just_open_project": false
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `from` | integer (int32) | از |
| `count` | integer (int32) | تعداد نتیجه ها |
| `search` | string | عنوان برای جستجو |
| `just_open_project` | boolean | 1 : جستجو فقط در پروژه های باز0 : جستجو در تمام پروژه ها |

## پاسخ

```json
{
  "data": [
    {
      "title": "",
      "status": 0,
      "progress": 0,
      "author_id": 0,
      "edit_perm": false,
      "folder_id": 0,
      "module_id": 0,
      "time_unit": 0,
      "admin_perm": false,
      "date_limit": 0,
      "date_start": 0,
      "project_id": 0,
      "category_id": 0,
      "date_create": 0,
      "date_modify": 0,
      "description": "",
      "is_templete": 0,
      "modifier_id": 0,
      "date_complete": 0,
      "executive_perm": false,
      "planning_date_limit": 0,
      "planning_date_start": 0
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
| `data[]` | array |  |
| `data[].title` | string | عنوان پروژه |
| `data[].status` | integer (int32) | وضعیت باز یا بسته بودن پروژه active = 0 archived/closed = 1 |
| `data[].progress` | integer (int32) | درصد پیشرفت پروژه |
| `data[].author_id` | integer (int64) | شناسه ی سازنده ی پروژهsource table name : `0000000`.profile_main\| column name: ID |
| `data[].edit_perm` | boolean | دسترسی ویرایش |
| `data[].folder_id` | integer (int64) | شناسه ی فولدر در صورت ضمیمه ی فایل کلید خارجی نیست |
| `data[].module_id` | integer (int64) | شناسه ی ماژول لینک شده از طریق کلیپ بورد |
| `data[].time_unit` | integer (int32) | واحد زمانی |
| `data[].admin_perm` | boolean | دسترسی ادمین ماژول |
| `data[].date_limit` | integer (int64) | تاریخ مهلت |
| `data[].date_start` | integer (int64) | تاریخ شروع |
| `data[].project_id` | integer (int64) | شناسه پروژه |
| `data[].category_id` | integer (int32) | شناسه ی رده ی پروژهsource table name : `0000000`.project_category\| column name: ID |
| `data[].date_create` | integer (int64) | تاریخ ساخت پروژه |
| `data[].date_modify` | integer (int64) | تاریخ تغییر پروژه |
| `data[].description` | string | توضیحات پروژه |
| `data[].is_templete` | integer (int32) | تعیین الگو بودن یا نبودن پروژه (مقدار 1 --> الگو هست) |
| `data[].modifier_id` | integer (int64) | شناسه ی تغییر دهنده ی پروژهsource table name : `0000000`.profile_main\| column name: ID |
| `data[].date_complete` | integer (int64) | تاریخ کامل شدن (بسته شدن) پروژه |
| `data[].executive_perm` | boolean | دسترسی |
| `data[].planning_date_limit` | integer (int64) | مهلت برنامه ریزی شده |
| `data[].planning_date_start` | integer (int64) | تاریخ شروع برنامه ریزی شده |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
