# اضافه کردن گروه

## آدرس

```
/api/group/add
```

## درخواست

```json
{
  "name*": "",
  "status": 0,
  "keywords": [
    ""
  ],
  "public_name": ""
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `name*` | string | نام گروه |
| `status` | integer (int32) | وضعیت گروه1 = فعال |
| `keywords[]` | array | کلمات کلیدی |
| `public_name` | string | نام عمومی |

## پاسخ

```json
{
  "data": {
    "id": 0
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
| `data.id` | integer (int64) | شناسه گروه ایجاد شده |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
