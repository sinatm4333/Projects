# گرفتن تعداد کیفیت هایی که یک شرکت کننده پاسخ داده است

## آدرس

```
/api/getQualityListCountForVoterUser
```

## درخواست

```json
{
  "user_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `user_id` | integer (int64) | شناسه کاربر |

## پاسخ

```json
{
  "data": {
    "count": 0
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
| `data` | object | آبجکت اصلی |
| `data.count` | integer (int32) | مقدار |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
