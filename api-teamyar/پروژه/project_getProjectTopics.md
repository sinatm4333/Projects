# دریافت لیست موضوعات اقدام استفاده شده در پروژه ها

## آدرس

```
/api/project/getProjectTopics
```

## درخواست

بدون پارامتر.

## پاسخ

```json
{
  "data": {
    "topics": [
      0
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
| `data` | object |  |
| `data.topics[]` | array | لیست موضوعات استفاده شده در پروژه ها |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
