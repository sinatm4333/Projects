# ارسال پیغام به گفتگوی عمومی

## آدرس

```
/api/message/public/add
```

## درخواست

```json
{
  "message": "",
  "attachments": [
    {
      "size": 0,
      "filename": "",
      "filepath": "",
      "mime_type": "",
      "data_base64": "",
      "src_module_id": 0
    }
  ],
  "dialog_session": ""
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `message` | string | متن پیام |
| `attachments[]` | array | فایل های پیوست |
| `attachments[].size` | integer (int64) | اندازه فایل |
| `attachments[].filename` | string | نام فایل |
| `attachments[].filepath` | string | نام فیزیکی فایل در صورت آپلود شدن در ارسال فرم |
| `attachments[].mime_type` | string | نوع فایل |
| `attachments[].data_base64` | string | اطلاعات فایل در صورت ارسال به صورت base64 |
| `attachments[].src_module_id` | integer (int32) | شناسه ماژول مبدا در صورت آپلود شدن فایل در فرم |
| `dialog_session` | string | مقدار session گفتگو |

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
| `data.message_id` | integer (int64) | شناسه پیغام ایجاد شده |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
