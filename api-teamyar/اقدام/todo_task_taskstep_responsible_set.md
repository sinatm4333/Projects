# تغییر مسئول مرحله در اقدام

## آدرس

```
/api/todo/task/taskstep/responsible/set
```

## درخواست

```json
{
  "step_id": 0,
  "task_id": 0,
  "user_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `step_id` | integer (int64) | شناسه مرحله ی جریان کار |
| `task_id` | integer (int64) | شناسه اقدام |
| `user_id` | integer (int64) | شناسه کاربری که باید مسئول مرحله باشد |

## پاسخ

```json
{
  "data": {
    "err": ""
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
| `data.err` | string |  |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
