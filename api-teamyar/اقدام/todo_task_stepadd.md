# افزودن مرحله در اقدام

فعال کردن مراحل داخل جریان کار خود تسک در اقدام

## آدرس

```
/api/todo/task/stepadd
```

## درخواست

```json
{
  "task_id": 0,
  "step_ids": "",
  "task_step_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `task_id` | integer (int64) | شناسه اقداماین فیلد اجباری می باشد. |
| `step_ids` | string | شناسه مراحل جریان کارِ اقدام مورد نظراز مراحلی که درون جریان کاری که اقدام با آن ایجاد شده است میتوان انتخاب کرد که با اجرا شدن بات فعال شوند. |
| `task_step_id` | integer (int64) | مرحله ای که فعال می باشد |

## پاسخ

```json
{
  "data": {
    "task_id": 0
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
| `data` | object | دیتا |
| `data.task_id` | integer (int64) | شناسه اقدام |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
