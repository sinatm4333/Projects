# فراخوانی فرم ماژول‌های دیگر در اقدام

ثبت و فراخوانی فرم متعلق به ماژول دیگر در اقدام.

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
| `form_id` | number | شناسه فرم |
| `form_title` | string | عنوان فرم |
| `form_path` | string | مسیر فرم |
| `module_id` | number | شناسه ماژول |
| `other_module_form_id` | number | شناسه فرم در ماژول دیگر |

## پاسخ

```json
{
  "data": { "err": "" },
  "error": { "status": 0, "message": "" },
  "success": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data.err` | string | خطای فراخوانی فرم |
| `error.status` | number | کد خطا |
| `error.message` | string | پیام خطا |
| `success` | number | نتیجه اجرا |

## مرتبط

- [دریافت فرم سفارشی](todo_customform_get.md)
- [به‌روزرسانی فرم سفارشی](todo_customform_update.md)
