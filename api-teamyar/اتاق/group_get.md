# دریافت اطلاعات گروه

## آدرس

```
/api/group/get
```

## درخواست

```json
{
  "id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) | شناسه گروه |

## پاسخ

```json
{
  "data": {
    "id": 0,
    "name": "",
    "status": 0,
    "topics": [
      {
        "id": 0,
        "title": "",
        "password": "",
        "channel_id": 0,
        "channel_topic": ""
      }
    ],
    "keywords": [
      ""
    ],
    "public_name": ""
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
| `data.id` | integer (int64) | شناسه گروه |
| `data.name` | string | نام گروه |
| `data.status` | integer (int32) | وضعیت گروه |
| `data.topics[]` | array | موضوعات |
| `data.topics[].id` | integer (int64) | شناسه موضوع |
| `data.topics[].title` | string | عنوان موضوع |
| `data.topics[].password` | string | کلمه عبور |
| `data.topics[].channel_id` | integer (int64) | شناسه کانال |
| `data.topics[].channel_topic` | string | عنوان کانال |
| `data.keywords[]` | array | کلمات کلیدی |
| `data.public_name` | string | نام عمومی |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
