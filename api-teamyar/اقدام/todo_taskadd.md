# ایجاد اقدام

ایجاد یک اقدام (task) جدید.

## آدرس

```
/api/todo/taskadd
```

## درخواست

```json
{
  "wf_id": 0,
  "crm_id": 0,
  "comment": "",
  "deadline": 0,
  "topic_id": 0,
  "task_type": 0,
  "project_id": 0,
  "task_title": "",
  "parent_step_id": 0,
  "parent_task_id": 0
}
```

### محتوا

| فیلد | نوع | توضیح |
|------|-----|-------|
| `task_title` | string | عنوان اقدام |
| `comment` | string | توضیحات |
| `task_type` | number | نوع اقدام |
| `deadline` | number | مهلت انجام |

### ارتباطات

| فیلد | نوع | توضیح |
|------|-----|-------|
| `project_id` | number | شناسه پروژه |
| `topic_id` | number | شناسه موضوع |
| `crm_id` | number | شناسه CRM |
| `wf_id` | number | شناسه گردش کار |
| `parent_task_id` | number | شناسه اقدام والد |
| `parent_step_id` | number | شناسه گام والد |

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
| `data.task_id` | number | شناسه اقدام ایجادشده |
| `error.status` | number | کد خطا |
| `error.message` | string | پیام خطا |
| `success` | number | نتیجه اجرا |
