# دیلیت کردن کاربر از لیست مدعوین

## آدرس

```
/api/event/deleteInvitedUser
```

## درخواست

```json
{
  "user_id": 0,
  "event_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `user_id` | integer (int64) | شناسه کاربر |
| `event_id` | integer (int64) | شناسه ایونت |

## پاسخ

```json
{
  "error": {
    "status": 0,
    "message": ""
  },
  "success": false
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
