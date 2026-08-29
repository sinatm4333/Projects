# به‌روزرسانی فرم سفارشی

به‌روزرسانی اطلاعات فرم سفارشی (custom form).

## آدرس

```
/api/todo/customform/update
```

## درخواست

```json
{
  "id": 0,
  "type": 0,
  "form_data": ""
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | number | شناسه |
| `type` | number | نوع |
| `form_data` | string | اطلاعات فرم |

## پاسخ

```json
{
  "error": { "status": 0, "message": "" },
  "success": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `error.status` | number | کد خطا |
| `error.message` | string | پیام خطا |
| `success` | number | نتیجه اجرا |

## مرتبط

- [دریافت فرم سفارشی](todo_customform_get.md) — همان `id`/`type` در ورودی.
- [دریافت فرم سفارشی توضیحات](todo_customform_multi_get.md)
