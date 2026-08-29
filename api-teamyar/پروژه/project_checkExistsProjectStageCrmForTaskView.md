# بررسی وجود مشتری و میزان مشارکت آن در مرحله پروژه

## آدرس

```
/api/project/checkExistsProjectStageCrmForTaskView
```

## درخواست

```json
{
  "user_id": 0,
  "stage_id": 0,
  "project_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `user_id` | integer (int64) | شناسه مشتری |
| `stage_id` | integer (int64) | شناسه مرحله |
| `project_id` | integer (int64) | شناسه پروژه |

## پاسخ

```json
{
  "data": {
    "result": false,
    "crm_count": 0,
    "participation_amount": 0,
    "participation_amount_sum": 0
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
| `data.result` | boolean | true : در صورت وجود مشتریfalse : در صورت عدم وجود مشتری |
| `data.crm_count` | integer (int64) | تعداد مشتری |
| `data.participation_amount` | integer (int64) | میزان مشارکت |
| `data.participation_amount_sum` | integer (int64) | مجموع مشارکت ها |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
