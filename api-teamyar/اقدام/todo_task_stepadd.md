# افزودن مرحله در اقدام

افزودن یک یا چند مرحله (step) به اقدام.

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
| `task_id` | number | شناسه اقدام |
| `step_ids` | string | شناسه مراحل |
| `task_step_id` | number | شناسه مرحله اقدام |

`step_ids` از نوع **string** است، نه آرایه — مانند `todo/task/assignadd`.

## پاسخ

```json
{
  "data": { "task_id": 0 },
  "error": { "status": 0, "message": "" },
  "success": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data.task_id` | number | شناسه اقدام |
| `error.status` | number | کد خطا |
| `error.message` | string | پیام خطا |
| `success` | number | نتیجه اجرا |

## مرتبط

- [ایجاد اقدام](todo_taskadd.md) — `task_id` از خروجی آن گرفته می‌شود.
- [اساین کردن کاربران در اقدام](todo_task_assignadd.md)
