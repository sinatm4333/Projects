# جستجو در پیغام های گفتگو

## آدرس

```
/api/message/search
```

## درخواست

```json
{
  "search": "",
  "dialog_id": 0,
  "begin_message_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `search` | string | متن جستجو |
| `dialog_id` | integer (int64) | شناسه گفتگو |
| `begin_message_id` | integer (int64) | شناسه اولین پیغام. در صورت ارسال پیغام های قبل از این شناسه جستجو می شوند |

## پاسخ

```json
{
  "data": {
    "messages": [
      {
        "id": 0,
        "content": "",
        "user_id": 0,
        "user_name": "",
        "create_date": 0
      }
    ],
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
| `data.messages[].content` | string | متن پیام |
| `data.messages[].user_id` | integer (int64) | شناسه کاربر |
| `data.messages[].user_name` | string | نام کاربر |
| `data.messages[].create_date` | integer (date) | تاریخ ایجاد |
| `data.begin_message_id` | integer (int64) |  |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
