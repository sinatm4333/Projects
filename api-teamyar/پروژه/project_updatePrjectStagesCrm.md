# بروزرسانی مشتریان مرحله پروژه

لیستی از مشتریان مرحله پروژه را می توان اضافه و یا حذف کرد

## آدرس

```
/api/project/updatePrjectStagesCrm
```

## درخواست

```json
{
  "task_id": 0,
  "task_title": "",
  "add_crm_ids": [
    0
  ],
  "del_crm_ids": [
    0
  ]
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `task_id` | integer (int64) | شناسه اقدام |
| `task_title` | string | عنوان اقدام |
| `add_crm_ids[]` | array | لیست شناسه های مشتریانی که اضافه می شوند |
| `del_crm_ids[]` | array | لیست مشتریانی که حذف می شوند |

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
