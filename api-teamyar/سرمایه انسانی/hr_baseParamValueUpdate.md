# /api/hr/baseParamValueUpdate

درخواست

## آدرس

```
/api/hr/baseParamValueUpdate
```

## درخواست

```json
{
  "value": "",
  "org_id": 0,
  "date_to": {
    "day": 0,
    "year": 0,
    "month": 0,
    "date_int64": 0
  },
  "param_id": 0,
  "date_from": {
    "day": 0,
    "year": 0,
    "month": 0,
    "date_int64": 0
  },
  "personnel_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `value` | string |  |
| `org_id` | integer (int64) |  |
| `date_to` | object |  |
| `date_to.day` | integer (int32) |  |
| `date_to.year` | integer (int32) |  |
| `date_to.month` | integer (int32) |  |
| `date_to.date_int64` | integer (int64) |  |
| `param_id` | integer (int64) |  |
| `date_from` | object |  |
| `date_from.day` | integer (int32) |  |
| `date_from.year` | integer (int32) |  |
| `date_from.month` | integer (int32) |  |
| `date_from.date_int64` | integer (int64) |  |
| `personnel_id` | integer (int64) |  |

## پاسخ

```json
{
  "data": {
    "id": 0
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
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
