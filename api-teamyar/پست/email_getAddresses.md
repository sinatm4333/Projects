# گرفتن ایمیل آدرس ها

## آدرس

```
/api/email/getAddresses
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
  "data": [
    {
      "id": 0,
      "flag": 0,
      "address": "",
      "group_id": 0,
      "user_name": "",
      "message_id": 0
    }
  ],
  "error": {
    "status": 0,
    "message": ""
  },
  "success": false
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data[]` | array | ایمیل آدرس ها |
| `data[].id` | integer (int64) | شناسه آدرس |
| `data[].flag` | integer (int32) | نوع ادرس ایمیل EMAIL_ADDRESS_TO =1, EMAIL_ADDRESS_CC =2, EMAIL_ADDRESS_BCC =3, EMAIL_ADDRESS_FROM =4 |
| `data[].address` | string | آدرس ایمیل |
| `data[].group_id` | integer (int64) | شناسه گروه |
| `data[].user_name` | string | اسم کاربری که ایمیلش دریافت شده |
| `data[].message_id` | integer (int64) | شناسه پیام |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
