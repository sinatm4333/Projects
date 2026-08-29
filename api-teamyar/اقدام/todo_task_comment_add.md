# افزودن کامنت به مرحله اقدام

افزودن کامنت به مرحله اقدام

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
      "type": {
        "filename": "",
        "filepath": "",
        "author_id": 0,
        "mime_type": ""
      }
    }
  ]
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `type` | integer (int32) | مقدار این فیلد برای top comment یک است و در کامنت های معمولی صفر میباشد |
| `files[]` | array | آرایه ی فایل ها |
| `files[].id` | integer (int64) | شناسه همتای فایل یا پوشه |
| `files[].size` | integer (int64) | سایز فایل ها با واحد byte |
| `files[].type` | integer (int32) | enum EnDocumentType |
| `files[].type.filename` | string | نام فایل یا پوشه |
| `files[].type.filepath` | string | مسیر فایل یا پوشه |
| `files[].type.author_id` | integer (int64) | شناسه کاربر ایجاد کننده فایل یا پوشه، شناسه Id از جدول profile_main |
| `files[].type.mime_type` | string | mimetype برای فایل ها |
| `files[].task_id` | integer (int64) | شناسه اقدام |
| `files[].author_id` | integer (int64) | ایجاد کننده (جدول profile_main) |
| `files[].task_step_id` | integer (int64) | شناسه ی مرحله ی اقدام |
| `files[].src_module_id` | integer (int32) | شناسه ماژول مبدا لینک (جدول HOME_MODULE_LIST) |
| `files[].comment_content` | string | محتوای کامنت |

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
