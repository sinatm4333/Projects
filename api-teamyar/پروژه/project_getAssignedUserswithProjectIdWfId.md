# دریافت کاربران مطلع روی پروژه

دریافت کاربران مطلع روی پروژه با شناسه پروژه و جریان کار

## آدرس

```
/api/project/getAssignedUserswithProjectIdWfId
```

## درخواست

```json
{
  "wf_id": 0,
  "project_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `wf_id` | integer (int64) | شناسه جریان کار |
| `project_id` | integer (int64) | شناسه پروژه |

## پاسخ

```json
{
  "data": {
    "assigned": [
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
| `data.assigned[]` | array | آرایه ای از کاربران مطلع |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
