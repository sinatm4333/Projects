# فراخوانی فرم ماژول های دیگر در اقدام

فراخوانی فرم ماژول های دیگر در اقدام (مثلا خرید)

## آدرس

```
/api/todo/registerform
```

## درخواست

```json
{
  "form_id": 0,
  "form_path": "",
  "module_id": 0,
  "form_title": "",
  "other_module_form_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `form_id` | integer (int64) | شناسه فرم |
| `form_path` | string | urlی که فرم را لود میکند |
| `module_id` | integer (int64) | شناسه ی ماژول |
| `form_title` | string | عنوان فرم |
| `other_module_form_id` | integer (int64) | شناسه ی ایجاد کننده فرم ماژول |

## پاسخ

```json
{
  "data": {
    "err": ""
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
| `data` | object | آبجکت پاسخ |
| `data.err` | string | در صورت وجود پیام خطا در back end، پیام نمایش داده میشود |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
