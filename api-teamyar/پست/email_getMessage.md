# گرفتن اطلاعات ایمیل

## آدرس

```
/api/email/getMessage
```

## درخواست

```json
{
  "message_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `message_id` | integer (int64) | شناسه پیام |

## پاسخ

```json
{
  "data": {
    "id": 0,
    "perm": 0,
    "u_id": "",
    "files": [
      {
        "id": 0,
        "size": 0,
        "type": 0,
        "filename": "",
        "filepath": "",
        "author_id": 0,
        "mime_type": "",
        "base64_content": ""
      }
    ],
    "box_id": 0,
    "content": "",
    "file_id": 0,
    "step_id": 0,
    "subject": "",
    "task_id": 0,
    "category": 0,
    "favorite": 0,
    "author_id": 0,
    "date_sent": 0,
    "filter_id": 0,
    "folder_id": 0,
    "module_id": 0,
    "parent_id": 0,
    "send_flag": 0,
    "auto_reply": 0,
    "content_id": 0,
    "filter_ids": 0,
    "date_create": 0,
    "date_modify": 0,
    "is_archived": false,
    "is_notified": 0,
    "task_status": 0,
    "archive_flag": 0,
    "old_category": 0,
    "reference_id": 0,
    "header_msg_id": ""
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
| `data` | object |  |
| `data.id` | integer (int64) | شناسه |
| `data.perm` | integer (int32) | مقدار دسترسی (در هر ماژول بستگی به نوع دسترسی مقادیر متفاوت است) |
| `data.u_id` | string | شناسه یونیک در سرور |
| `data.files[]` | array |  |
| `data.files[].id` | integer (int64) | شناسه |
| `data.files[].size` | integer (int64) |  |
| `data.files[].type` | integer (int32) |  |
| `data.files[].filename` | string |  |
| `data.files[].filepath` | string |  |
| `data.files[].author_id` | integer (int64) | شناسه ایجاد کننده |
| `data.files[].mime_type` | string |  |
| `data.files[].base64_content` | string |  |
| `data.box_id` | integer (int64) | شناسه صندوق |
| `data.content` | string | محتوای ایمیل |
| `data.file_id` | integer (int64) | شناسه فایل content ایمیل |
| `data.step_id` | integer (int64) | شناسه ی مرحله ی اقدام |
| `data.subject` | string | موضوع ایمیل |
| `data.task_id` | integer (int64) | شناسه اقدام |
| `data.category` | integer (int32) | شناسه رده ی ایمیل |
| `data.favorite` | integer (int32) | در صورتی که ایمیل ارسال شده به عنوان برگزیده انتخاب شده باشد این فیلد مقدار 1 میگیرد |
| `data.author_id` | integer (int64) | شناسه ایجاد کننده |
| `data.date_sent` | integer (int64) | تاریخ ارسال |
| `data.filter_id` | integer (int64) | شناسه ی فیلتر |
| `data.folder_id` | integer (int64) | شناسه ی فولدری که فایل های ضمیمه در ان ذخیره میشود |
| `data.module_id` | integer (int64) | شناسه ی ماژول |
| `data.parent_id` | integer (int64) | شناسه ی والد |
| `data.send_flag` | integer (int32) | این فیلد وضعیت ارسال ایمیل را مشخص میکند EMAIL_STATUS_SAVE = 2, EMAIL_STATUS_SEND = 1, EMAIL_STATUS_NOT_SEND = 4, EMAIL_STATUS_IN_SEND_QUEUE = 5, EMAIL_STATUS_IN_SENDING = 6, |
| `data.auto_reply` | integer (int32) | در صورتی که ایمیل ارسال شده به عنوان پاسخ خودکار ارسال شده باشد این فیلد مقدار 1 میگیرد |
| `data.content_id` | integer (int64) | شناسه ی محتوای ایمیل |
| `data.filter_ids` | integer (int64) | شناسه های فیلتر |
| `data.date_create` | integer (int64) | تاریخ ایجاد |
| `data.date_modify` | integer (int64) | تاریخ ویرایش |
| `data.is_archived` | boolean | در صورتی که ایمیل ارسال شده بایگانی شده باشد این فیلد مقدار 1 میگیرد |
| `data.is_notified` | integer (int32) | وضعیت ارسال اعلان(نوتیفای) |
| `data.task_status` | integer (int32) | وضعیت اقدام TASK_STATUS_OPEN =1, TASK_STATUS_CLOSE =2, TASK_STATUS_SUSPEND =3 |
| `data.archive_flag` | integer (int32) | در صورتی که این فیلد 1 باشد در صورت فول بک اپ گرفتن تیم یار این ایمیل به ارشیو منتقل میشود |
| `data.old_category` | integer (int32) | رده ی قبلی ایمیل |
| `data.reference_id` | integer (int64) | شناسه مرجع |
| `data.header_msg_id` | string | شناسه ایمیل در هدر |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
