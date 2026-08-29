# ایجاد کاربر پورتال برای مشتری

## آدرس

```
/api/client/portal/add
```

## درخواست

```json
{
  "id": 0,
  "lang_id": 0,
  "password": "",
  "portal_id": 0,
  "category_id": 0,
  "related_contact": [
    0
  ],
  "category_profile_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) | شناسه مشتری |
| `lang_id` | integer (int32) | شناسه زبان کاربر |
| `password` | string | کلمه عبور |
| `portal_id` | integer (int64) | شناسه پورتال |
| `category_id` | integer (int64) | شناسه رده |
| `related_contact[]` | array | لیست کاربران مرتبط |
| `category_profile_id` | integer (int64) | شناسه رده در پروفایل |

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
