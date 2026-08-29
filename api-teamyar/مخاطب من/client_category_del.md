# حذف کردن مشتری از رده

حذف کردن مشتری از رده بر اساس شناسه رده یا شناسه رده در پروفایل

## آدرس

```
/api/client/category/del
```

## درخواست

```json
{
  "id": 0,
  "category_id": 0,
  "category_profile_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) | شناسه مشتری |
| `category_id` | integer (int64) | شناسه رده |
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
