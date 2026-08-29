# افزودن مرحله با مسئول و مهلت در اقدام

افزودن مرحله با مسئول و مهلت در اقدام .

## آدرس

```
/api/todo/taskstep/update
```

## درخواست

```json
{
  "steps": [
    {
      "step_id": 0,
      "end_date": 0,
      "responsible_id": 0
    }
  ],
  "task_id": 0,
  "task_step_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `steps[]` | array | ارایه ای از مراحلی که در اقدام باید افزوده شود |
| `steps[].step_id` | integer (int64) | شناسه مرحله ی جریان کار |
| `steps[].end_date` | integer (int64) | مهلت مرحله اقدام |
| `steps[].responsible_id` | integer (int64) | مسئول مرحله اقدام |
| `task_id` | integer (int64) | شناسه اقدام |
| `task_step_id` | integer (int64) | شناسه مرحله ی اقدام که در ان این Api فراخوانی میشود |

## پاسخ

```json
{
  "data": {
    "err": ""
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
| `data.err` | string | پیام خطا |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
