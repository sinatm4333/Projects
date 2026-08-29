# حذف سند به همراه چک

## آدرس

```
/api/deleteDocumentWithCheck
```

## درخواست

```json
{
  "id*": 0,
  "move_to_trash": false
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id*` | integer (int64) | شناسه سند |
| `move_to_trash` | boolean | چک حذف موقت |

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
