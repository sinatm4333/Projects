# افزودن مشتری به اقدام

## آدرس

```
/api/todo/task/crm/add
```

## درخواست

```json
{
  "crm_ids": [
    0
  ],
  "task_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `crm_ids[]` | array | آرایه ای از شناسه مشتریان |
| `task_id` | integer (int64) | شناسه اقدام |

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
| `data.err` | string | در صورت وجود پیام خطا در back end، پیام نمایش داده میشود |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
