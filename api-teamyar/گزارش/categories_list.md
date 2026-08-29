# دریافت نام رده ها

دریافت نام رده های ایجاد شده در ماژول گزارش بر اساس سرور

## آدرس

```
/api/categories/list
```

## درخواست

```json
{
  "server_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `server_id` | integer (int64) | شناسه سرور |

## پاسخ

```json
{
  "data": [
    {
      "id": 0,
      "name": ""
    }
  ],
  "error": {
    "status": 0,
    "message": ""
  },
  "success": false
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data[]` | array | لیست رده ها |
| `data[].id` | integer (int64) | شناسه رده |
| `data[].name` | string | نام رده |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
