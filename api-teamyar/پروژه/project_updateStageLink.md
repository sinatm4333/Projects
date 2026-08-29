# بروزرسانی لینک مرحله پروژه

## آدرس

```
/api/project/updateStageLink
```

## درخواست

```json
{
  "title": "",
  "link_id": 0,
  "stage_id": 0,
  "link_type": 0,
  "module_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `title` | string | عنوان مرحله |
| `link_id` | integer (int64) | شناسه لینک |
| `stage_id` | integer (int64) | شناسه مرحله |
| `link_type` | integer (int32) | نوع لینک که با توجه به ENTITY های داخل هر ماژول تعیین می شود. STAGE_LINK_TYPE_TODO_TASK = 3, STAGE_LINK_TYPE_DOCUMENT = 1, STAGE_LINK_TYPE_EMAIL = 1, STAGE_LINK_TYPE_SMS = 1 |
| `module_id` | integer (int64) | شناسه ی ماژول لینک شده به مرحله |

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
