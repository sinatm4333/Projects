# دریافت لیست پروژه هایی که از یک موضوع اقدام استفاده کرده اند

## آدرس

```
/api/project/getProjectTopicProjects
```

## درخواست

```json
{
  "topic_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `topic_id` | integer (int64) | شناسه موضوع اقدام |

## پاسخ

```json
{
  "data": [
    {
      "title": "",
      "file_id": 0,
      "project_id": 0
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
| `data[]` | array | لیست پروژه ها |
| `data[].title` | string | عنوان پروژه |
| `data[].file_id` | integer (int64) | شناسه ی فایل ضمیمه شده . کلید خارجی نیست. |
| `data[].project_id` | integer (int64) | شناسه پروژه |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
