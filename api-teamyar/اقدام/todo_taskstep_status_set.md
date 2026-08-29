# تغییر وضعیت مرحله اقدام

تغییر وضعیت مرحله اقدام

## آدرس

```
/api/todo/taskstep/status/set
```

## درخواست

```json
{
  "status": 0,
  "step_id": 0,
  "task_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `status` | integer (int32) | Step Current Status. 0=Note; 1=Completed; 2=Confirmed; 3=Rejected |
| `step_id` | integer (int64) | شناسه مرحله |
| `task_id` | integer (int64) | شناسه اقدام |

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
| `data` | object | آبجکت |
| `data.err` | string | در صورت وجود پیام خطا در back end، پیام نمایش داده میشود |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
