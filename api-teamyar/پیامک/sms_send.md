# ارسال پیامک

ارسال پیامک تکی و گروهی

## آدرس

```
/api/sms/send
```

## درخواست

```json
{
  "box_id": 0,
  "is_bulk": 0,
  "messages": [
    {
      "content": "",
      "send_to": {
        "profile_ids": [
          0
        ],
        "mobile_numbers": [
          {
            "value": "",
            "country": 0
          }
        ]
      }
    }
  ],
  "module_id": 0,
  "todo_step_id": 0,
  "todo_task_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `box_id` | integer (int64) | شناسه صندوق |
| `is_bulk` | integer (int32) | بالک هست یا خیر |
| `messages[]` | array | لیست پیامک هایی باید ارسال شوند |
| `messages[].content` | string | متن پیامک |
| `messages[].send_to` | object | دریافت کنندگان پیامک که یا با شناسه پروفایل و یا با شماره موبایل تعیین می شوند |
| `messages[].send_to.profile_ids[]` | array | لیست پروفایل هایی که باید پیامک برایشان ارسال شود.، پیامک به تمام شماره موبایل هایی که برای آن شناسه پروفایل تعریف شده ارسال خواهد شد |
| `messages[].send_to.mobile_numbers[]` | array | لیست شماره موبایل های دریافت کننده پیامک |
| `messages[].send_to.mobile_numbers[].value` | string | شماره موبایل |
| `messages[].send_to.mobile_numbers[].country` | integer (int32) | کد کشور |
| `module_id` | integer (int32) | شناسه ماژولی که پیامک از سمت آن ارسال می شود |
| `todo_step_id` | integer (int64) | شناسه مرحله ای از اقدام که پیامک از آن مرحله ارسال شده است |
| `todo_task_id` | integer (int64) | شماره اقدام در صورتی که ارسال کننده پیامک اقدام باشد و پیامک باید به اقدام لینک شود |

## پاسخ

```json
{
  "data": {
    "message_ids": [
      0
    ]
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
| `data` | object | آبجکتی از آرایه های شناسه های پیامک |
| `data.message_ids[]` | array | شناسه های پیامک های ایجاد شده |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
