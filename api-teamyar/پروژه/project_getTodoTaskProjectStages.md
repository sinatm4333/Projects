# دریافت شناسه پروژه ها و شناسه مراحلی که به اقدام لینک هستند

دریافت شناسه پروژه ها و شناسه مراحلی که به اقدام لینک هستند با شناسه اقدام

## آدرس

```
/api/project/getTodoTaskProjectStages
```

## درخواست

```json
{
  "task_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `task_id` | integer (int64) | شناسه اقدام |

## پاسخ

```json
{
  "data": [
    {
      "stage_ids": [
        0
      ],
      "project_id": 0
    }
  ],
  "error": {
    "status": 0,
    "message": ""
  },
  "success": false
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data[]` | array | لیست نتایج |
| `data[].stage_ids[]` | array | لیست شناسه مراحل لینک شده |
| `data[].project_id` | integer (int64) | شناسه پروژه |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
