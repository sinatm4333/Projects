# لاگین کردن در پورتال

احراز هویت کاربر و ورود به پورتال.

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
| `login` | string | نام کاربری |
| `password` | string | رمز عبور |
| `token` | string | توکن |
| `login_type` | number | نوع ورود |
| `portal_id` | number | شناسه پورتال |
| `lang_id` | number | شناسه زبان |
| `link_id` | number | شناسه لینک |

## پاسخ

```json
{
  "data": {
    "links": [{ "id": 0, "name": "" }],
    "headers": [{ "value": "", "header": "" }],
    "message": "",
    "block_time": 0,
    "result_type": 0
  },
  "error": { "status": 0, "message": "" },
  "success": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data.links` | array | فهرست لینک‌ها — هر آیتم `id` و `name` |
| `data.headers` | array | هدرهای بازگشتی — هر آیتم `header` و `value` |
| `data.message` | string | پیام |
| `data.block_time` | number | زمان مسدودی |
| `data.result_type` | number | نوع نتیجه |
| `error.status` | number | کد خطا |
| `error.message` | string | پیام خطا |
| `success` | number | نتیجه اجرا |
