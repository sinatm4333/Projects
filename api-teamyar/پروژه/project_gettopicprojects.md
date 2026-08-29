# API گرفتن نام پروژه با شناسه موضوع

با شناسه موضوع میتوان عنوان و شناسه پروژه هایی که آن موضوع در آنها استفاده شده است را داشته باشیم

## آدرس

```
/api/project/gettopicprojects
```

## درخواست

```json
{
  "topic_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `topic_id` | integer (int64) | فیلد شناسه موضوعاین فیلد اجباری می باشد. |

## پاسخ

```json
{
  "data": [
    {
      "title": "",
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
| `data[]` | array | دیتا |
| `data[].title` | string | عنوان پروژه |
| `data[].project_id` | integer (int64) | شناسه پروژه |
| `error` | object | جزئیات خطای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
