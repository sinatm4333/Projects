# دریافت لیست پروژه هایی که در پورتال نمایش داده میشوند

## آدرس

```
/api/project/getPortalUserProjects
```

## درخواست

بدون پارامتر.

## پاسخ

```json
{
  "data": [
    {
      "title": "",
      "project_id": 0
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
| `data[]` | array | آرایه ای از پروژه های فال در پورتال |
| `data[].title` | string | عنوان پروژه |
| `data[].project_id` | integer (int64) | شناسه پروژه |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
