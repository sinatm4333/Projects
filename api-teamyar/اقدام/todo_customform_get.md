# دریافت فرم سفارشی

دریافت اطلاعات فرم سفارشی (custom form) یک اقدام.

## آدرس

```
/api/todo/customform/get
```

## درخواست

```json
{
  "id": 0,
  "type": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | number | شناسه |
| `type` | number | نوع |

## پاسخ

```json
{
  "data": { "form_data": "" },
  "error": { "status": 0, "message": "" },
  "success": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data.form_data` | string | اطلاعات فرم |
| `error.status` | number | کد خطا |
| `error.message` | string | پیام خطا |
| `success` | number | نتیجه اجرا |

## مرتبط

- [ایجاد اقدام](todo_taskadd.md)
