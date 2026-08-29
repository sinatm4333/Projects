# دریافت فرم سفارشی توضیحات

دریافت چند فرم سفارشی به‌صورت یکجا.

## آدرس

```
/api/todo/customform/multi_get
```

## درخواست

```json
{
  "type": 0,
  "form_ids": ""
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `form_ids` | string | شناسه فرم‌ها |
| `type` | number | نوع |

`form_ids` از نوع **string** است، نه آرایه — مانند `todo/task/assignadd` و `todo/task/stepadd`.

## پاسخ

```json
{
  "data": [
    {
      "form_id": 0,
      "form_data": "",
      "form_title": ""
    }
  ],
  "error": { "status": 0, "message": "" },
  "success": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data[].form_id` | number | شناسه فرم |
| `data[].form_title` | string | عنوان فرم |
| `data[].form_data` | string | اطلاعات فرم |
| `error.status` | number | کد خطا |
| `error.message` | string | پیام خطا |
| `success` | number | نتیجه اجرا |

## مرتبط

- [دریافت فرم سفارشی](todo_customform_get.md) — دریافت تکی.
