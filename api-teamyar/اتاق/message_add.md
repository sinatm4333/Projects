# اضافه کردن پیام به یک گفتگو

## آدرس

```
/api/message/add
```

## درخواست

```json
{
  "mention": "",
  "message": "",
  "reply_id": 0,
  "author_id*": 0,
  "dialog_id*": 0,
  "attachments": [
    {
      "size": 0,
      "filename": "",
      "filepath": "",
      "mime_type": "",
      "data_base64": "",
      "src_module_id": 0
    }
  ]
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `mention` | string |  |
| `message` | string | متن پیام |
| `reply_id` | integer (int64) |  |
| `author_id*` | integer (int64) | شناسه کاربر ایجاد کننده پیام |
| `dialog_id*` | integer (int64) | شناسه گفتگویی که میخواهیم پیام را به آن اضافه کنیم |
| `attachments[]` | array | فایل های پیوست |
| `attachments[].size` | integer (int64) | اندازه فایل |
| `attachments[].filename` | string | نام فایل |
| `attachments[].filepath` | string | نام فیزیکی فایل در صورت آپلود شدن در ارسال فرم |
| `attachments[].mime_type` | string | نوع فایل |
| `attachments[].data_base64` | string | اطلاعات فایل در صورت ارسال به صورت base64 |
| `attachments[].src_module_id` | integer (int32) | شناسه ماژول مبدا در صورت آپلود شدن فایل در فرم |

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
| `data.message_id` | integer (int64) | شناسه پیام ایجاد شده |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | وضعیت فراخوانی Api |
| `error.message` | string | در صورتی که Api موفق اجرا نشود در این پارامتر Error برگردانده شده نمایش داده میشود |
| `success` | boolean | موفق بودن اجرای Api را نشان میدهددر صورتی که api با موفقیت اجرا شود مقدار true دارد در غیر این صورت false |
