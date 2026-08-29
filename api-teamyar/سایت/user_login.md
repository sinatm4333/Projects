# لاگین کردن در پورتال

از این api می توان برای لاگین کردن کاربر در پورتال توسط بات استفاده کرد. کاربرد این api تنها در طراحی فرم های ساین آپ توسط بات می باشد

## آدرس

```
/api/user/login
```

## درخواست

```json
{
  "login": "",
  "token": "",
  "lang_id": 0,
  "link_id": 0,
  "password": "",
  "portal_id": 0,
  "login_type": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `login` | string | نام کاربری پورتال که شماره موبایل یا ایمیل می باشد |
| `token` | string | توکن برای لاگین بدون پسورد |
| `lang_id` | integer (int32) | شناسه زبان کاربر |
| `link_id` | integer (int64) | شناسه کاربر مرتبط جهت لاگین در پورتال به عنوان رابط آن کاربر |
| `password` | string | کلمه عبور |
| `portal_id` | integer (int64) | شناسه پورتال |
| `login_type` | integer (int32) | نوع احراز هویت |

## پاسخ

```json
{
  "data": {
    "links": [
      {
        "id": 0,
        "name": ""
      }
    ],
    "headers": [
      {
        "value": "",
        "header": ""
      }
    ],
    "message": "",
    "block_time": 0,
    "result_type": 0
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
| `data` | object | دیتا |
| `data.links[]` | array | لیستی از کاربران مرتبطاگر هنگام لاگین کاربر مرتبط وجود داشته باشد باید برای لاگین انتخاب شود. در صورت انتخاب نشدن لیستی از کاربران مرتبط ارسال میشود |
| `data.links[].id` | integer (int64) | شناسه کاربر |
| `data.links[].name` | string | نام کاربر |
| `data.headers[]` | array | لیستی از هدر های لازم جهت لاگین کاربر که باید توسط بات هنگام پاسخ در هدر نوشته شود |
| `data.headers[].value` | string | مقدار هدر |
| `data.headers[].header` | string | نام هدر |
| `data.message` | string | پیام |
| `data.block_time` | integer (int64) | تایم بلاک |
| `data.result_type` | integer (int32) | 0: ok1: not found2: block ip3: block account4: guest user5: invalid group6: invalid ip7: access denied with browser8: access denied with mobile9: has link10: full online users11: invalid_link12: invalid_module13: gps off14: need confirm15: invalid session16: send email failed17: send sms failed18: invalid code19: signup120: default group not set21: exist user22: update user failed23: invalid mobile/email24: forget_password25: ok fast signup |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
