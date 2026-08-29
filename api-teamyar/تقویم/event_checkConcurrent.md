# چک همزمانی جلسات

این API مشخصات جلساتی که باهم تداخل دارند را بر میگرداند

## آدرس

```
/api/event/checkConcurrent
```

## درخواست

```json
{
  "eve_id*": 0,
  "user_id*": 0,
  "cur_user_id*": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `eve_id*` | integer (int64) | شناسه مناسبت |
| `user_id*` | integer (int64) | شناسه کاربر مورد نظر |
| `cur_user_id*` | integer (int64) | شناسه کاربر حال |

## پاسخ

```json
{
  "data": {
    "err": "",
    "status": 0,
    "concurrent": [
      {
        "cal_id": 0,
        "status": 0,
        "user_id": 0,
        "cal_name": "",
        "event_id": 0,
        "user_name": "",
        "event_name": "",
        "creator_name": "",
        "invite_user_status": 0
      }
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
| `data.err` | string |  |
| `data.status` | integer (int32) | وضعیت |
| `data.concurrent[]` | array | ارایه همزمانی |
| `data.concurrent[].cal_id` | integer (int64) | شناسه تقویم |
| `data.concurrent[].status` | integer (int32) | وضعیت |
| `data.concurrent[].user_id` | integer (int64) | شناسه کاربر |
| `data.concurrent[].cal_name` | string | نام تقویم |
| `data.concurrent[].event_id` | integer (int64) | شناسه مناسبت |
| `data.concurrent[].user_name` | string | نام کاربر |
| `data.concurrent[].event_name` | string | نام مناسبت |
| `data.concurrent[].creator_name` | string | نام ایجاد کننده |
| `data.concurrent[].invite_user_status` | integer (int32) | وضعیت دعوت کاربر(رد یا قبول)3یا2 |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
