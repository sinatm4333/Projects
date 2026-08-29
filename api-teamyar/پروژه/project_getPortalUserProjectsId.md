# بررسی فعال بودن پروژه در پورتال

بررسی فعال بودن پروژه در پورتال با شناسه پروژه

## آدرس

```
/api/project/getPortalUserProjectsId
```

## درخواست

```json
{
  "id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) | شناسه پروژه |

## پاسخ

```json
{
  "data": {
    "has_result": false
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
| `data.has_result` | boolean | true : در پورتال فعال استfalse : در پورتال فعال نیست |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
