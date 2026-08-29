# بروزرسانی مرحله پروژه

## آدرس

```
/api/project/updateProjectStage
```

## درخواست

```json
{
  "flag": 0,
  "type": 0,
  "progress": 0,
  "module_id": 0,
  "reffere_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `flag` | integer (int32) | STATUS_FLAG_ACTIVE = 0, باز بودن مرحله STATUS_FLAG_CLOSED = 1, بسته بودن مرحله |
| `type` | integer (int32) | نوع لینک که با توجه به ENTITY های داخل هر ماژول تعیین می شود. STAGE_LINK_TYPE_TODO_TASK = 3, STAGE_LINK_TYPE_DOCUMENT = 1, STAGE_LINK_TYPE_EMAIL = 1, STAGE_LINK_TYPE_SMS = 1 |
| `progress` | integer (int32) | درصد پیشرفت مرحله |
| `module_id` | integer (int64) | شناسه ماژول لینک شده |
| `reffere_id` | integer (int64) | شناسه مرجع |

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
