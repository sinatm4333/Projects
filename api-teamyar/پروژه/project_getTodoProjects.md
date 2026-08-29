# دریافت عنوان و شناسه پروژه با شناسه اقدامی که لینک به مرحله شده است

## آدرس

```
/api/project/getTodoProjects
```

## درخواست

```json
{
  "todo_ids": [
    0
  ]
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `todo_ids[]` | array | لیست شناسه اقدام |

## پاسخ

```json
{
  "data": [
    {
      "id": 0,
      "title": "",
      "task_id": 0
    }
  ],
  "error": {
    "status": 0,
    "message": ""
  },
  "success": false
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data[]` | array | لیست نتایج |
| `data[].id` | integer (int64) | شناسه پروژه |
| `data[].title` | string | عنوان پروژه |
| `data[].task_id` | integer (int64) | شناسه اقدام |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
