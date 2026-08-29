# بازکردن منگنه

بازکردن فایل از حالت منگنه

## آدرس

```
/api/document/detach
```

## درخواست

```json
{
  "detach_ids*": [
    0
  ]
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `detach_ids*[]` | array | شناسه فایل هایی که قرار است از حالت منگنه خارج شوند |

## پاسخ

```json
{
  "data": {
    "detached_ids*": [
      0
    ]
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
| `data` | object |  |
| `data.detached_ids*[]` | array | شناسه فایل هایی که از حالت منگنه خارج شدند |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
