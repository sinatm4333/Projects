# ارسال ایمیل

## آدرس

```
/api/email/send
```

## درخواست

```json
{
  "message": {
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
  "file_ids": [
    0
  ],
  "addresses": [
    {
      "id": 0,
      "flag": 0,
      "address": "",
      "group_id": 0,
      "user_name": "",
      "message_id": 0
    }
  ],
  "extra_header": "",
  "extra_content_file": "",
  "extra_header_value": "",
  "extra_content_file_name": "",
  "extra_content_file_mime_type": ""
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `message` | object |  |
| `message.id` | integer (int64) | شناسه |
| `message.perm` | integer (int32) | مقدار دسترسی (در هر ماژول بستگی به نوع دسترسی مقادیر متفاوت است) |
| `message.u_id` | string | شناسه یونیک در سرور |
| `message.files[]` | array | آرایه ای از فایل های ضمیمه |
| `message.files[].id` | integer (int64) | شناسه فایل |
| `message.files[].size` | integer (int64) | اندازه فایل |
| `message.files[].type` | integer (int32) | enum EnDocumentType{ DOCUMENT_FOLDER = 1, DOCUMENT_FILE = 2}; |
| `message.files[].filename` | string | نام فایل |
| `message.files[].filepath` | string | مسیر فایل |
| `message.files[].author_id` | integer (int64) | شناسه کاربر ایجاد کننده فایل یا پوشهشناسه Id از جدول profile_main |
| `message.files[].mime_type` | string | mimetype برای فایل ها |
| `message.files[].base64_content` | string | کدینگ محتوای فایل |
| `message.box_id` | integer (int64) | شناسه صندوق |
| `message.content` | string | محتوای ایمیل |
| `message.file_id` | integer (int64) | شناسه فایل content ایمیل |
| `message.step_id` | integer (int64) | شناسه ی مرحله ی اقدام |
| `message.subject` | string | موضوع ایمیل |
| `message.task_id` | integer (int64) | شناسه اقدام |
| `message.category` | integer (int32) | شناسه رده ی ایمیل |
| `message.favorite` | integer (int32) | انتخاب به عنوان برگزیده |
| `message.author_id` | integer (int64) | شناسه ایجاد کننده |
| `message.date_sent` | integer (int64) | تاریخ ارسال |
| `message.filter_id` | integer (int64) | شناسه ی فیلتر |
| `message.folder_id` | integer (int64) | شناسه ی فولدری که فایل های ضمیمه در ان ذخیره میشود |
| `message.module_id` | integer (int64) | شناسه ی ماژول |
| `message.parent_id` | integer (int64) | شناسه ی والد |
| `message.send_flag` | integer (int32) | این فیلد وضعیت ارسال ایمیل را مشخص میکند EMAIL_STATUS_SAVE = 2, EMAIL_STATUS_SEND = 1, EMAIL_STATUS_NOT_SEND = 4, EMAIL_STATUS_IN_SEND_QUEUE = 5, EMAIL_STATUS_IN_SENDING = 6, |
| `message.auto_reply` | integer (int32) | در صورتی که ایمیل ارسال شده به عنوان پاسخ خودکار ارسال شده باشد این فیلد مقدار 1 میگیرد |
| `message.content_id` | integer (int64) | شناسه ی محتوای ایمیل |
| `message.filter_ids` | integer (int64) | شناسه های فیلتر |
| `message.date_create` | integer (int64) | تاریخ ایجاد |
| `message.date_modify` | integer (int64) | تاریخ ویرایش |
| `message.is_archived` | boolean | در صورتی که ایمیل ارسال شده بایگانی شده باشد این فیلد مقدار 1 میگیرد |
| `message.is_notified` | integer (int32) | وضعیت ارسال اعلان(نوتیفای) |
| `message.task_status` | integer (int32) | وضعیت اقدام TASK_STATUS_OPEN =1, TASK_STATUS_CLOSE =2, TASK_STATUS_SUSPEND =3 |
| `message.archive_flag` | integer (int32) | در صورتی که این فیلد 1 باشد در صورت فول بک اپ گرفتن تیم یار این ایمیل به ارشیو منتقل میشود |
| `message.old_category` | integer (int32) | رده ی قبلی ایمیل |
| `message.reference_id` | integer (int64) | شناسه مرجع |
| `message.header_msg_id` | string | شناسه ایمیل در هدر |
| `file_ids[]` | array | شناسه فایل ها |
| `addresses[]` | array | آدرس ایمیل ها |
| `addresses[].id` | integer (int64) | شناسه آدرس |
| `addresses[].flag` | integer (int32) | نوع ادرس ایمیل EMAIL_ADDRESS_TO =1, EMAIL_ADDRESS_CC =2, EMAIL_ADDRESS_BCC =3, EMAIL_ADDRESS_FROM =4 |
| `addresses[].address` | string | آدرس ایمیل |
| `addresses[].group_id` | integer (int64) | شناسه گروه |
| `addresses[].user_name` | string | اسم کاربری که ایمیلش دریافت شده |
| `addresses[].message_id` | integer (int64) | شناسه پیام |
| `extra_header` | string |  |
| `extra_content_file` | string |  |
| `extra_header_value` | string |  |
| `extra_content_file_name` | string |  |
| `extra_content_file_mime_type` | string |  |

## پاسخ

```json
{
  "data": {
    "message_id": 0
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
| `data.message_id` | integer (int64) | شناسه ایمیل |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
