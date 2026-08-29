# تعداد پروژه هایی که لینک هستند

## آدرس

```
/api/project/getProjectsWithLinkCount
```

## درخواست

```json
{
  "link_id": 0,
  "link_type": 0,
  "link_module_id": 0,
  "just_open_project": false
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `link_id` | integer (int64) | شناسه ی بخش لینک شده به مرحله (اقدام یا پروژه یا تقویم و اسناد و ...) |
| `link_type` | integer (int32) | نوع لینک که با توجه به ENTITY های داخل هر ماژول تعیین می شود. STAGE_LINK_TYPE_TODO_TASK = 3, STAGE_LINK_TYPE_DOCUMENT = 1, STAGE_LINK_TYPE_EMAIL = 1, STAGE_LINK_TYPE_SMS = 1, |
| `link_module_id` | integer (int32) | شناسه ی ماژول لینک شده به مرحله |
| `just_open_project` | boolean | 1 : جستجو فقط در پروژه های باز0 : جستجو در تمام پروژه ها |

## پاسخ

```json
{
  "data": {
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
| `data` | object | آبجکت نتیجه |
| `data.total` | integer (int64) | تعداد پروژه هایی که لینک هستند |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
