# دریافت لیست موضوعات رده اقدام

دریافت شناسه و عنوان موضوعات رده اقدام با استفاده از شناسه رده

## آدرس

```
/api/todo/topic/list/get
```

## درخواست

```json
{
  "id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) | شناسه رده اقدام |

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
| `data[]` | array | آرایه |
| `data[].id` | integer (int64) | شناسه موضوع |
| `data[].name` | string | عنوان موضوع |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
