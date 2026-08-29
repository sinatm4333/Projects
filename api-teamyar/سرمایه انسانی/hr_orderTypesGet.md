# نوع حکم

انواع حکم در تنظیمات حکم

## آدرس

```
/api/hr/orderTypesGet
```

## درخواست

```json
{
  "from": 0,
  "count": 0,
  "org_id": 0,
  "search": ""
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `from` | integer (int64) | از شماره |
| `count` | integer (int64) | تعداد |
| `org_id` | integer (int64) | شناسه شعبه |
| `search` | string | جستجو بر اساس نام |

## پاسخ

```json
{
  "data": [
    {
      "id": 0,
      "name": "",
      "hiring_time": 0
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
| `data[]` | array | لیست انواع حکم |
| `data[].id` | integer (int64) | شناسه نوع حکم |
| `data[].name` | string | نام نوع حکم |
| `data[].hiring_time` | integer (int64) | زمان صدور نوع حکم |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
