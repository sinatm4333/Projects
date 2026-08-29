# دریافت پروفایل‌ها

دریافت اطلاعات پروفایل برای فهرستی از شناسه‌ها.

## آدرس

```
/api/profile/getInfo
```

## درخواست

```json
{
  "ids": [0]
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `ids` | array\<number\> | شناسه پروفایل‌های موردنظر |

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
  "error": { "status": 0, "message": "" },
  "success": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data[].id` | number | شناسه پروفایل |
| `data[].fullname` | string | نام کامل |
| `data[].type` | number | نوع |
| `data[].user_type` | number | نوع کاربر |
| `data[].status` | number | وضعیت |
| `data[].is_role` | number | نقش بودن |
| `data[].folder_id` | number | شناسه پوشه |
| `data[].small_photo_id` | number | شناسه تصویر کوچک |
| `error.status` | number | کد خطا |
| `error.message` | string | پیام خطا |
| `success` | number | نتیجه اجرا |
