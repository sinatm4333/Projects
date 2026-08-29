# گرفتن عنوان کیفیت ها

## آدرس

```
/api/getQualitiesName
```

## درخواست

```json
{
  "ids": [
    0
  ],
  "count": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `ids[]` | array | شناسه ها |
| `count` | integer (int32) | مقدار |

## پاسخ

```json
{
  "data": {
    "qualities": [
      {
        "id": 0,
        "name": ""
      }
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
| `data` | object | آبجکت اصلی |
| `data.qualities[]` | array | کیفیت ها |
| `data.qualities[].id` | integer (int64) | شناسه |
| `data.qualities[].name` | string | عنوان |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
