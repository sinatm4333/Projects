# دریافت وضعیت مرحله اقدام

دریافت وضعیت مرحله اقدام

## آدرس

```
/api/todo/taskstep/status/get
```

## درخواست

```json
{
  "step_id": 0,
  "task_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `step_id` | integer (int64) | شناسه مرحله جریان کار |
| `task_id` | integer (int64) | شناسه اقدام |

## پاسخ

```json
{
  "data": {
    "status": 0
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
| `data` | object | آبجکت نمایش وضعیت اقدام |
| `data.status` | integer (int32) | وضعیت اقدام، `TASK_STATUS_OPEN=1`، `TASK_STATUS_CLOSE=2`، `TASK_STATUS_SUSPEND=3` |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
