# گرفتن عنوان یک کیفیت

## آدرس

```
/api/getQualityName
```

## درخواست

```json
{
  "id*": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id*` | integer (int64) | شناسه |

## پاسخ

```json
{
  "data": {
    "id": 0,
    "name": ""
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
| `data.id` | integer (int64) | شناسه |
| `data.name` | string | عنوان |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
