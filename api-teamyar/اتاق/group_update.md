# بروزرسانی اطلاعات گروه

## آدرس

```
/api/group/update
```

## درخواست

```json
{
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
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) | شناسه گروه |
| `name` | string | نام گروه |
| `status` | integer (int32) | وضعیت گروه |
| `topics[]` | array | موضوعات |
| `topics[].id` | integer (int64) | شناسه موضوع |
| `topics[].title` | string | عنوان موضوع |
| `topics[].password` | string | کلمه عبور |
| `topics[].channel_id` | integer (int64) | شناسه کانال |
| `topics[].channel_topic` | string | عنوان کانال |
| `keywords[]` | array | کلمات کلیدی |
| `public_name` | string | نام عمومی |

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
