# گرفتن لیست الگو ها

## آدرس

```
/api/get_templates
```

## درخواست

```json
{
  "from": 0,
  "count": 0,
  "cat_id": 0,
  "org_id": 0,
  "search": "",
  "module_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `from` | integer (int32) | از |
| `count` | integer (int32) | تعداد |
| `cat_id` | integer (int64) | شناسه رده |
| `org_id` | integer (int64) | شناسه سازمان |
| `search` | string | عبارت مورد جستجو |
| `module_id` | integer (int64) | شناسه ماژول |

## پاسخ

```json
{
  "data": {
    "templates": [
      {
        "id": 0,
        "name": ""
      }
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
| `data.templates[]` | array | الگو ها |
| `data.templates[].id` | integer (int64) | شناسه الگو |
| `data.templates[].name` | string | عنوان الگو |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
