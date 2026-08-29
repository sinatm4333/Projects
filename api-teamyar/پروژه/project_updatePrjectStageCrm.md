# اضافه کردن مشتری به مرحله پروژه

## آدرس

```
/api/project/updatePrjectStageCrm
```

## درخواست

```json
{
  "user_id": 0,
  "stage_id": 0,
  "project_id": 0,
  "task_title": ""
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `user_id` | integer (int64) | شناسه مشتری |
| `stage_id` | integer (int64) | شناسه مرحله |
| `project_id` | integer (int64) | شناسه پروژه |
| `task_title` | string | عنوان اقدام |

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
