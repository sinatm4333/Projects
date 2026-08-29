# /api/pm/update_service

درخواست

## آدرس

```
/api/pm/update_service
```

## درخواست

```json
{
  "id": 0,
  "title": "",
  "org_id": 0,
  "wh_service": {
    "device_id": 0,
    "attribute_id": 0
  },
  "priority_id": 0,
  "service_type": 0,
  "work_type_id": 0,
  "deleted_service_details": "",
  "updated_service_details": [
    {
      "id": 0,
      "score": 0,
      "pieces": [
        {
          "device_id": 0,
          "attribute_id": 0
        }
      ],
      "product": {
        "device_id": 0,
        "attribute_id": 0
      },
      "duration": 0,
      "row_index": 0,
      "personnels": ""
    }
  ]
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) |  |
| `title` | string |  |
| `org_id` | integer (int64) |  |
| `wh_service` | object |  |
| `wh_service.device_id` | integer (int64) |  |
| `wh_service.attribute_id` | integer (int64) |  |
| `priority_id` | integer (int64) |  |
| `service_type` | integer (int32) |  |
| `work_type_id` | integer (int64) |  |
| `deleted_service_details` | string |  |
| `updated_service_details[]` | array |  |
| `updated_service_details[].id` | integer (int64) |  |
| `updated_service_details[].score` | integer (int64) |  |
| `updated_service_details[].pieces[]` | array |  |
| `updated_service_details[].pieces[].device_id` | integer (int64) |  |
| `updated_service_details[].pieces[].attribute_id` | integer (int64) |  |
| `updated_service_details[].product` | object |  |
| `updated_service_details[].product.device_id` | integer (int64) |  |
| `updated_service_details[].product.attribute_id` | integer (int64) |  |
| `updated_service_details[].duration` | integer (int64) |  |
| `updated_service_details[].row_index` | integer (int64) |  |
| `updated_service_details[].personnels` | string |  |

## پاسخ

```json
{
  "data": {
    "id": 0,
    "message": "",
    "form_err": "",
    "error_ref_id": 0
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
| `data.id` | integer (int64) |  |
| `data.message` | string |  |
| `data.form_err` | string |  |
| `data.error_ref_id` | integer (int64) |  |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
