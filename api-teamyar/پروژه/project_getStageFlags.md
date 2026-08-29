# دریافت وضعیت مرحله پروژه

دریافت وضعیت مرحله پروژه(باز یا بسته بودن)

## آدرس

```
/api/project/getStageFlags
```

## درخواست

```json
{
  "id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) | شناسه مرحله |

## پاسخ

```json
{
  "data": {
    "flags": 0
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
| `data` | object | آبجکت نتیجه |
| `data.flags` | integer (int32) | STATUS_FLAG_ACTIVE = 0, باز بودن مرحله STATUS_FLAG_CLOSED = 1, بسته بودن مرحله |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
