# گرفتن شناسه پیامک

گرفتن شناسه پیامک با استفاده از شناسه اقدام و گام

## آدرس

```
/api/sms/getMessageIdByTaskIdAndStepID
```

## درخواست

```json
{
  "step_id": 0,
  "task_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `step_id` | integer (int64) | شناسه گام |
| `task_id` | integer (int64) | شناسه اقدام |

## پاسخ

```json
{
  "data": {
    "message_id": 0
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
| `data.message_id` | integer (int64) | شناسه پیامک |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
