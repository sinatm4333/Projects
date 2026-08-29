# دریافت عنوان پروژه ها ***

دریافت عنوان پروژه ها (امکان انتخاب باز و بسته بودن پروژه ها وجود دارد)

## آدرس

```
/api/project/getTitleProjects
```

## درخواست

```json
{
  "just_open_project": false
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `just_open_project` | boolean | 1 : جستجو فقط در پروژه های باز0 : جستجو در تمام پروژه ها |

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
| `data[]` | array | آرایه لیست پروژه ها |
| `data[].title` | string | عنوان پروژه |
| `data[].project_id` | integer (int64) | شناسه پروژه |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
