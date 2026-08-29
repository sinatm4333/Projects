# گرفتن تعداد ایمیل ها با استفاده از لینک

## آدرس

```
/api/email/getMessagesCountByLinkId
```

## درخواست

```json
{
  "from": 0,
  "count": 0,
  "link_id": 0,
  "link_type": 0,
  "module_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `from` | integer (int64) | از |
| `count` | integer (int64) | تا |
| `link_id` | integer (int64) | شناسه لینک |
| `link_type` | integer (int32) | نوع لینک |
| `module_id` | integer (int32) | شناسه ماژول |

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
| `data` | object |  |
| `data.count` | integer (int32) | تعداد |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
