# /api/section/list

درخواست

## آدرس

```
/api/section/list
```

## درخواست

بدون پارامتر.

## پاسخ

```json
{
  "data": {
    "sections": [
      {
        "id": 0,
        "name": "",
        "flags": 0,
        "order": 0,
        "categories": [
          {
            "id": 0,
            "name": "",
            "flags": 0,
            "full_name": "",
            "profile_id": 0,
            "section_id": 0
          }
        ]
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
| `data.sections[]` | array |  |
| `data.sections[].id` | integer (int64) |  |
| `data.sections[].name` | string |  |
| `data.sections[].flags` | integer (int32) |  |
| `data.sections[].order` | integer (int32) |  |
| `data.sections[].categories[]` | array |  |
| `data.sections[].categories[].id` | integer (int64) |  |
| `data.sections[].categories[].name` | string |  |
| `data.sections[].categories[].flags` | integer (int32) |  |
| `data.sections[].categories[].full_name` | string |  |
| `data.sections[].categories[].profile_id` | integer (int64) |  |
| `data.sections[].categories[].section_id` | integer (int64) |  |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
