# حذف پاپ‌آپ

حذف یک popup ایجادشده برای کاربر یا کاربران مشخص.

## آدرس

```
/api/removePopup
```

## درخواست

```json
{
  "popup_id": 0,
  "user_ids": [0]
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `popup_id` | number | شناسه popup که باید حذف شود (خروجی `/api/show_popup`) |
| `user_ids` | array\<number\> | شناسه کاربرانی که popup از آن‌ها حذف می‌شود |

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

- [ایجاد popup](show_popup.md) — `popup_id` از پاسخ آن گرفته می‌شود.
