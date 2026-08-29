# تغییر وضعیت افراد در جلسه

تغییر وضعیت افراد در جلسه (رد میکنم/تایید میکنم ..) نکته:دقت شود که ایونت حتما در حالت بررسی باشد.

## آدرس

```
/api/event/changeUserInviteStatus
```

## درخواست

```json
{
  "user_id*": 0,
  "event_id*": 0,
  "cur_user_id*": 0,
  "user_event_invite_status*": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `user_id*` | integer (int64) | شناسه کاربر |
| `event_id*` | integer (int64) | شناسه مناسبت |
| `cur_user_id*` | integer (int64) | شناسه کاربر حال(شناسه کاربری که از سیستم استفاده میکند را وارد کنید) |
| `user_event_invite_status*` | integer (int32) | تعیین وضعیت2=accept3=decline |

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
| `data.concurrent[]` | array | هم زمانی |
| `data.concurrent[].cal_id` | integer (int64) | شناسه تقویم |
| `data.concurrent[].status` | integer (int32) | وضعیت |
| `data.concurrent[].user_id` | integer (int64) | شناسه کاربر |
| `data.concurrent[].cal_name` | string | نام تقویم |
| `data.concurrent[].event_id` | integer (int64) | شناسه مناسبت |
| `data.concurrent[].user_name` | string | نام کاربر |
| `data.concurrent[].event_name` | string | نام مناسبت |
| `data.concurrent[].creator_name` | string | نام ایجاد کننده |
| `data.concurrent[].invite_user_status` | integer (int32) | وضعیت 2=شرکت میکنم 3=رد میکنم |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
