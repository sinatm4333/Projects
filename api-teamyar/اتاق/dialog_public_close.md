# بستن گفتگوی عمومی

## آدرس

```
/api/dialog/public/close
```

## درخواست

```json
{
  "dialog_session": ""
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `dialog_session` | string | مقدار سشن گفتگوی عمومی |

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
