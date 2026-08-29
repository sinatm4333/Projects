# ارسال نوتیفای به کاربر

ارسال نوتیفای به کاربر در مورد مشتری

## آدرس

```
/api/client/notify/add
```

## درخواست

```json
{
  "title": "",
  "user_ids": [
    0
  ],
  "client_id": 0,
  "section_id": 0,
  "notify_status": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `title` | string | عنوان نوتیفای |
| `user_ids[]` | array | لیست کاربران دریافت کننده |
| `client_id` | integer (int64) | شناسه مشتری |
| `section_id` | integer (int64) | شناسه بخش |
| `notify_status` | integer (int32) | وضعیت نوتیفای. میتواند مجموع چند وضعیت باشدenum NotifyStatus{ NOTIFY_STATUS_ADD = 1, NOTIFY_STATUS_EDIT = 2, NOTIFY_STATUS_DELETE = 4, NOTIFY_STATUS_RESPONSIBLE = 8, NOTIFY_STATUS_ASSIGN = 16, NOTIFY_STATUS_DEADLINE = 32, NOTIFY_STATUS_COMMENT = 64, NOTIFY_STATUS_CLOSE = 128, NOTIFY_STATUS_RETURN = 256, NOTIFY_STATUS_IMPORTANT = 512, NOTIFY_STATUS_IMMEDIATE = 1024, NOTIFY_STATUS_SUSPEND = 2048, NOTIFY_STATUS_SIGN = 4096, NOTIFY_STATUS_CONFIRM = 8192, NOTIFY_STATUS_REJECT = 16384, NOTIFY_STATUS_WARNING = 32768, NOTIFY_STATUS_MENTION = 65536}; |

## پاسخ

```json
{
  "error": {
    "status": 0,
    "message": ""
  },
  "success": false
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
