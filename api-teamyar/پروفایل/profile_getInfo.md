# دریافت پروفایل ها

دریافت اطلاعات مختصر پروفایل لیستی از کاربرها

## آدرس

```
/api/profile/getInfo
```

## درخواست

```json
{
  "ids": [
    0
  ]
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `ids[]` | array | لیست شناسه پروفایل |

## پاسخ

```json
{
  "data": [
    {
      "id": 0,
      "type": 0,
      "status": 0,
      "is_role": 0,
      "fullname": "",
      "folder_id": 0,
      "user_type": 0,
      "small_photo_id": 0
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
| `data[]` | array | لیست اطلاعات پروفایل |
| `data[].id` | integer (int64) | شناسه پروفایل |
| `data[].type` | integer (int32) | نوع پروفایلUSER_TYPE_USER = 1,USER_TYPE_GROUP = 2,USER_TYPE_ROLE = 4 |
| `data[].status` | integer (int32) | وضعیت در ماژول پروفایل USER_STATUS_ACTIVE = 1, USER_STATUS_DISABLED = 3, USER_STATUS_DELETED = 4 |
| `data[].is_role` | integer (int32) | نقش |
| `data[].fullname` | string | نام کامل |
| `data[].folder_id` | integer (int64) | شناسه پوشه |
| `data[].user_type` | integer (int32) | نوع کاربر USER_TYPE_NATURAL = 3, USER_TYPE_LEGAL = 4 |
| `data[].small_photo_id` | integer (int64) | شناسه تصویر |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
