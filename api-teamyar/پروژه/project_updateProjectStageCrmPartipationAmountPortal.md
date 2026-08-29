# بروزرسانی مقدار مشارکت مشتری در مرحله پروژه

## آدرس

```
/api/project/updateProjectStageCrmPartipationAmountPortal
```

## درخواست

```json
{
  "amount": 0,
  "crm_id": 0,
  "stage_id": 0,
  "project_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `amount` | integer (int64) | میزان مشارکت |
| `crm_id` | integer (int64) | شناسه مشتری |
| `stage_id` | integer (int64) | شناسه مرحله |
| `project_id` | integer (int64) | شناسه پروژه |

## پاسخ

```json
{
  "error": {
    "status": 0,
    "message": ""
  },
  "success": false
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
