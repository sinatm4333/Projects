# اضافه کردن گفتگوی عمومی

## آدرس

```
/api/dialog/public/add
```

## درخواست

```json
{
  "topic*": "",
  "bot_id": 0,
  "group_id": 0,
  "author_name": "",
  "author_mobile": {
    "mobile": "",
    "country_code": 0
  },
  "topic_password": ""
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `topic*` | string | عنوان گفتگو |
| `bot_id` | integer (int64) | شناسه بات (طبق تنظیمات بات) |
| `group_id` | integer (int64) | شناسه گروه |
| `author_name` | string | نام ایجاد کننده |
| `author_mobile` | object | شماره موبایل ایجاد کننده |
| `author_mobile.mobile` | string | شماره موبایل |
| `author_mobile.country_code` | integer (int32) | کد کشور |
| `topic_password` | string | کلمه عبور |

## پاسخ

```json
{
  "data": {
    "dialog_id": 0,
    "dialog_session": "",
    "welcome_message": "",
    "topic_channel_id": 0
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
| `data.dialog_id` | integer (int64) | شناسه گفتگوی ایجاد شده |
| `data.dialog_session` | string | مقدار سشن اختصاص داده شده به گروه عمومیاز این مقدار برای ارسال و دریافت پیغام در گفتگوی عمومی استفاده می شود |
| `data.welcome_message` | string | متن پیام خوش آمد گویی |
| `data.topic_channel_id` | integer (int64) | شناسه کانال |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
