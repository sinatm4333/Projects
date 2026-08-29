# ایجاد Popup

نمایش یک پیام popup برای کاربر یا کاربران مشخص.

## آدرس

```
/api/show_popup
```

## درخواست

```json
{
  "title": "",
  "status": 0,
  "content": "",
  "timeout": 0,
  "user_ids": [0]
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `title` | string | عنوان popup |
| `status` | number | وضعیت / نوع نمایش |
| `content` | string | متن محتوای popup |
| `timeout` | number | مدت زمان نمایش |
| `user_ids` | array\<number\> | شناسه کاربران دریافت‌کننده |

## پاسخ

```json
{
  "data": { "popup_id": 0 },
  "error": { "status": 0, "message": "" },
  "success": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data.popup_id` | number | شناسه popup ایجادشده |
| `error.status` | number | کد خطا |
| `error.message` | string | پیام خطا |
| `success` | number | نتیجه اجرا |
