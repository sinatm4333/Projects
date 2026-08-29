# ویرایش اقدام

به‌روزرسانی اطلاعات یک اقدام.

## آدرس

```
/api/todo/taskedit
```

## درخواست

```json
{
  "color": "",
  "wf_id": 0,
  "task_id": 0,
  "deadline": 0,
  "owner_id": 0,
  "priority": 0,
  "topic_id": 0,
  "task_title": "",
  "category_id": 0,
  "portal_show": 0
}
```

### محتوا

| فیلد | نوع | توضیح |
|------|-----|-------|
| `task_id` | number | شناسه اقدام |
| `task_title` | string | عنوان اقدام |
| `deadline` | number | مهلت انجام |
| `priority` | number | اولویت |
| `color` | string | رنگ |

### ارتباطات و دسته‌بندی

| فیلد | نوع | توضیح |
|------|-----|-------|
| `owner_id` | number | شناسه مالک |
| `topic_id` | number | شناسه موضوع |
| `category_id` | number | شناسه دسته‌بندی |
| `wf_id` | number | شناسه گردش کار |
| `portal_show` | number | نمایش در پورتال |

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

- [ایجاد اقدام](todo_taskadd.md)
