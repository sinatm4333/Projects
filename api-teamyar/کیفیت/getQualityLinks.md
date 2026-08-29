# /api/getQualityLinks

درخواست

## آدرس

```
/api/getQualityLinks
```

## درخواست

```json
{
  "quality_id": 0,
  "evaluator_ids": [
    0
  ]
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `quality_id` | integer (int64) |  |
| `evaluator_ids[]` | array |  |

## پاسخ

```json
{
  "data": {
    "links": [
      {
        "link": "",
        "evaluator_id": 0
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
| `data.links[]` | array |  |
| `data.links[].link` | string |  |
| `data.links[].evaluator_id` | integer (int64) |  |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
