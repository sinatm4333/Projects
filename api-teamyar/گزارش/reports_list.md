# دریافت نام گزارش ها

دریافت نام گزارش های ایجاد شده در ماژول گزارش بر اساس رده

## آدرس

```
/api/reports/list
```

## درخواست

```json
{
  "from": 0,
  "count": 0,
  "search": "",
  "category_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `from` | integer (int32) | دریافت لیست از |
| `count` | integer (int32) | دریافت لیست به تعداد |
| `search` | string | جستجوی عبارت |
| `category_id` | integer (int64) | شناسه رده گزارش |

## پاسخ

```json
{
  "data": [
    {
      "id": 0,
      "name": "",
      "uuid": ""
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
| `data[]` | array | لیست گزارش ها |
| `data[].id` | integer (int64) | شناسه گزارش |
| `data[].name` | string | نام گزارش |
| `data[].uuid` | string | شناسه یکتای گزارش (UUID) |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
