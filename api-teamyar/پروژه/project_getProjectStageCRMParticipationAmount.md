# دریافت میزان مشارکت کاربر پورتال در پروژه

## آدرس

```
/api/project/getProjectStageCRMParticipationAmount
```

## درخواست

```json
{
  "user_id": 0,
  "stage_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `user_id` | integer (int64) | شناسه کاربر |
| `stage_id` | integer (int64) | شناسه مرحله پروژه |

## پاسخ

```json
{
  "data": {
    "participation_amount": 0
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
| `data.participation_amount` | integer (int64) | میزان مشارکت کاربر پورتال |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
