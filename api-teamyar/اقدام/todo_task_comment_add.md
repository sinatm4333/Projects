# افزودن کامنت به مرحله اقدام

## آدرس

```
/api/todo/task/comment/add
```

## درخواست

```json
{
  "type": 0,
  "files": [
    {
      "id": 0,
      "size": 0,
      "type": 0,
      "filename": "",
      "filepath": "",
      "author_id": 0,
      "mime_type": ""
    }
  ],
  "task_id": 0,
  "author_id": 0,
  "task_step_id": 0,
  "src_module_id": 0,
  "comment_content": ""
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `type` | integer (int32) | مقدار این فیلد برای top comment یک است و در کامنت های معمولی صفر میباشد |
| `files[]` | array | آرایه ی فایل ها |
| `files[].id` | integer (int64) | شناسه همتای فایل یا پوشه |
| `files[].size` | integer (int64) | سایز فایل ها با واحد byte |
| `files[].type` | integer (int32) | enum EnDocumentType{ DOCUMENT_FOLDER = 1, DOCUMENT_FILE = 2}; |
| `files[].filename` | string | نام فایل یا پوشه |
| `files[].filepath` | string | مسیر فایل یا پوشه |
| `files[].author_id` | integer (int64) | شناسه کاربر ایجاد کننده فایل یا پوشهشناسه Id از جدول profile_main |
| `files[].mime_type` | string | mimetype برای فایل ها |
| `task_id` | integer (int64) | شناسه اقدام |
| `author_id` | integer (int64) | ایجاد کننده (جدول profile_main) |
| `task_step_id` | integer (int64) | شناسه ی مرحله ی اقدام |
| `src_module_id` | integer (int32) | شناسه ماژول مبدا لینک (جدول HOME_MODULE_LIST) |
| `comment_content` | string | محتوای کامنت |

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
| `data` | object | آبجکت پاسخ |
| `data.err` | string | پیام خطا |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
