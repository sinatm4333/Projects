# دریافت پیامک

## آدرس

```
/api/sms/receive
```

## درخواست

```json
{
  "to": "",
  "from": "",
  "content": ""
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `to` | string | شماره ی دریافت کننده |
| `from` | string | شماره ی ارسال کننده |
| `content` | string | محتوای پیامک |

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
