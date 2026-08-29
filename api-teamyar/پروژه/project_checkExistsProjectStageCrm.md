# بررسی وجود مشتری در مرحله پروژه

## آدرس

```
/api/project/checkExistsProjectStageCrm
```

## درخواست

```json
{
  "task_id": 0,
  "user_id": 0,
  "stage_id": 0,
  "project_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `task_id` | integer (int64) | شناسه اقدام |
| `user_id` | integer (int64) | شناسه مشتری |
| `stage_id` | integer (int64) | شناسه مرحله |
| `project_id` | integer (int64) | شناسه پروژه |

## پاسخ

```json
{
  "data": {
    "result": false
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
| `data.result` | boolean | true : در صورت وجود مشتریfalse : در صورت عدم وجود مشتری |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
