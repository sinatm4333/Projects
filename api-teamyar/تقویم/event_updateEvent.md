# بروزرسانی مناسبت

این APIرا میتوان جهت آپدیت کردن مناسبت ها استفاده کرد.

## آدرس

```
/api/event/updateEvent
```

## درخواست

```json
{
  "event*": {
    "id*": 0,
    "uid": "",
    "name": "",
    "tzid": 0,
    "color": "",
    "place": "",
    "status": 0,
    "chat_id": 0,
    "place_id": 0,
    "folder_id": 0,
    "module_id": 0,
    "parent_id": 0,
    "tzid_flag": 0,
    "alarm_type": 0,
    "creator_id": 0,
    "date_alarm": 0,
    "date_start": 0,
    "calendar_id*": 0,
    "date_create": 0,
    "date_finish": 0,
    "date_modify": 0,
    "description": "",
    "modifier_id": 0,
    "period_type": 0,
    "end_of_month": 0,
    "period_until": 0,
    "bot_alarm_type": 0,
    "bot_date_alarm": 0,
    "invite_user_id": 0,
    "online_meeting": 0,
    "sms_alarm_type": 0,
    "sms_date_alarm": 0,
    "period_interval": 0,
    "concurrent_place": 0,
    "invite_user_status": 0
  },
  "user_ids*": [
    0
  ]
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `event*` | object | مناسبت |
| `event*.id*` | integer (int64) | شناسه |
| `event*.uid` | string | uid |
| `event*.name` | string | name |
| `event*.tzid` | integer (int64) | tzid |
| `event*.color` | string | color |
| `event*.place` | string | place |
| `event*.status` | integer (int32) | status |
| `event*.chat_id` | integer (int64) | chat_id |
| `event*.place_id` | integer (int64) | place_id |
| `event*.folder_id` | integer (int64) | folder_id |
| `event*.module_id` | integer (int64) | module_id |
| `event*.parent_id` | integer (int64) | parent_id |
| `event*.tzid_flag` | integer (int64) | tzid_flag |
| `event*.alarm_type` | integer (int32) | alarm_type |
| `event*.creator_id` | integer (int64) | creator_id |
| `event*.date_alarm` | integer (date) | date_alarm |
| `event*.date_start` | integer (date) | date_start |
| `event*.calendar_id*` | integer (int64) | calendar_id |
| `event*.date_create` | integer (date) | date_create |
| `event*.date_finish` | integer (date) | date_finish |
| `event*.date_modify` | integer (date) | date_modify |
| `event*.description` | string | description |
| `event*.modifier_id` | integer (int64) | modifier_id |
| `event*.period_type` | integer (int32) | period_type |
| `event*.end_of_month` | integer (int32) | end_of_month |
| `event*.period_until` | integer (int64) | period_until |
| `event*.bot_alarm_type` | integer (int32) | bot_alarm_type |
| `event*.bot_date_alarm` | integer (date) | bot_date_alarm |
| `event*.invite_user_id` | integer (int64) | invite_user_id |
| `event*.online_meeting` | integer (int32) | online_meeting |
| `event*.sms_alarm_type` | integer (int32) | sms_alarm_type |
| `event*.sms_date_alarm` | integer (date) | sms_date_alarm |
| `event*.period_interval` | integer (int64) | period_interval |
| `event*.concurrent_place` | integer (int32) | concurrent_place |
| `event*.invite_user_status` | integer (int32) | invite_user_status |
| `user_ids*[]` | array | user_ids* |

## پاسخ

```json
{
  "data": {
    "id": 0,
    "err": "",
    "status": 0
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
| `data` | object | data |
| `data.id` | integer (int64) | id |
| `data.err` | string | err |
| `data.status` | integer (int32) | status |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
