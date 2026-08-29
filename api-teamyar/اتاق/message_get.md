# دریافت پیغام های گفتگو

## آدرس

```
/api/message/get
```

## درخواست

```json
{
  "dialog_id*": 0,
  "end_message_id": 0,
  "begin_message_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `dialog_id*` | integer (int64) | شناسه گفتگو |
| `end_message_id` | integer (int64) | شناسه آخرین پیام برای دریافت پیام های جدید. در صورت 0 بودن 50 پیام اخیر برگردانده می شود |
| `begin_message_id` | integer (int64) | شناسه اولین پیام برای دریافت پیام های پیشین |

## پاسخ

```json
{
  "data": {
    "messages": [
      {
        "id": 0,
        "type": 0,
        "content": "",
        "user_id": 0,
        "reply_id": 0,
        "is_public": 0,
        "user_name": "",
        "forward_id": 0,
        "reply_name": "",
        "reply_type": 0,
        "attachments": [
          {
            "id": 0,
            "mime": "",
            "name": "",
            "size": 0,
            "type": 0,
            "flags": 0,
            "version": 0
          }
        ],
        "create_date": 0,
        "modifier_id": 0,
        "modify_date": 0,
        "reply_content": "",
        "related_user_id": 0
      }
    ],
    "end_message_id": 0,
    "is_bbb_running": false,
    "begin_message_id": 0
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
| `data.messages[]` | array | پیغام ها |
| `data.messages[].id` | integer (int64) | شناسه |
| `data.messages[].type` | integer (int32) | نوع پیام |
| `data.messages[].content` | string | متن پیام |
| `data.messages[].user_id` | integer (int64) | کاربر ایجاد کننده |
| `data.messages[].reply_id` | integer (int64) | شناسه پیغام پاسخ داده شده |
| `data.messages[].is_public` | integer (int32) | عمومی |
| `data.messages[].user_name` | string | نام کاربر |
| `data.messages[].forward_id` | integer (int64) | شناسه پیام باز ارسال شده |
| `data.messages[].reply_name` | string | نام پیام پاسخ داده شده |
| `data.messages[].reply_type` | integer (int32) | نوع پیام پاسخ داده شده |
| `data.messages[].attachments[]` | array | فایل های پیوست |
| `data.messages[].attachments[].id` | integer (int64) | شناسه فایل |
| `data.messages[].attachments[].mime` | string | نوع فایل |
| `data.messages[].attachments[].name` | string | نام فایل |
| `data.messages[].attachments[].size` | integer (int32) | اندازه فایل |
| `data.messages[].attachments[].type` | integer (int32) | نوع فایل |
| `data.messages[].attachments[].flags` | integer (int32) | فلگ |
| `data.messages[].attachments[].version` | integer (int32) | ورژن |
| `data.messages[].create_date` | integer (date) | تاریخ ایجاد |
| `data.messages[].modifier_id` | integer (int64) | شناسه تغییر دهنده |
| `data.messages[].modify_date` | integer (date) | تاریخ تغییر |
| `data.messages[].reply_content` | string | متن پیام پاسخ داده شده |
| `data.messages[].related_user_id` | integer (int64) | کاربر مرتبط |
| `data.end_message_id` | integer (int64) | شناسه آخرین پیام |
| `data.is_bbb_running` | boolean | اجرا بودن BigBlueButton |
| `data.begin_message_id` | integer (int64) | شناسه اولین پیام |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
