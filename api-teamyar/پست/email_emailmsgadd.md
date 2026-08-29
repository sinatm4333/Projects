# ایجاد ایمیل

ارسال ایمیل جدید

## آدرس

```
/api/email/emailmsgadd
```

## درخواست

```json
{
  "box_id": 0,
  "address": "",
  "extra_header": "",
  "email_content": "",
  "email_subject": "",
  "extra_header_value": ""
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `box_id` | integer (int64) | شناسه صندوق پیامکی که میخواهیم از ان ارسال داشته باشیمدر صورتی که این فیلد را مقدار دهی نکنیم یا مقدار آن را صفر بگداریم صندوق پیش فرض در نظر گرفته میشود |
| `address` | string | لیست ادرس هایی که به انها میخواهیم ایمیل ارسال کنیم و جدا کننده "," استپر کردن این فیلد اجباری است |
| `extra_header` | string |  |
| `email_content` | string | در این فیلد مقدار محتوای ایمیل ارسالی مقدار دهی میشودپر کردن این فیلد اجباری است |
| `email_subject` | string | موضوع ایمیلدر صورتی که خالی باشد SUBJECT_EMPTY به جای موضوع قرار میگیرد |
| `extra_header_value` | string |  |

## پاسخ

```json
{
  "data": {
    "email_message_id": 0
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
| `data.email_message_id` | integer (int64) | id ایمیلی که ارسال شده است |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | وضعیت فراخوانی Api |
| `error.message` | string | در صورتی که Api موفق به ارسال ایمیل نشود متن خطای ارسالی نمایش داده میشود |
| `success` | boolean | موفق بودن اجرای Api را نشان میدهددر صورتی که api با موفقیت اجرا شود مقدار true دارد در غیر این صورت false |
