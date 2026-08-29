# اساین کردن کاربران در اقدام

تخصیص (assign) کاربران به یک یا چند اقدام.

## آدرس

```
/api/todo/task/assignadd
```

## درخواست

```json
{
  "task_ids": "",
  "assign_ids": ""
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `task_ids` | string | شناسه اقدام‌ها |
| `assign_ids` | string | شناسه کاربرانی که تخصیص داده می‌شوند |

هر دو فیلد از نوع **string** هستند، نه آرایه — برخلاف سایر APIها که شناسه‌های چندتایی
را به‌صورت `array<number>` می‌گیرند.

## پاسخ

```json
{
  "error": { "status": 0, "message": "" },
  "success": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `error.status` | number | کد خطا |
| `error.message` | string | پیام خطا |
| `success` | number | نتیجه اجرا |

## مرتبط

- [ایجاد اقدام](todo_taskadd.md) — `task_id` از خروجی آن گرفته می‌شود.
