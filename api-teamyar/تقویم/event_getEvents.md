# دریافت چندین مناسبت با تایپ های مختلف

این API جهت گرفتن مناسبت ها برای کاربر می باشد و میتوان نوع آن را تعیین کرد

## آدرس

```
/api/event/getEvents
```

## درخواست

```json
{
  "type": 0,
  "module_id": 0,
  "creator_id*": 0,
  "cur_user_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `type` | integer (int32) | در صورتی که تایپ را اعدادی مختلف دهیم مناسب های مختلفی را نسبت به دسترسی خواهیم گرفت:1:تایپ =1 : ایونت هایی را برمیگرداند که کاربر روی آن مطلع می باشد.2:تایپ =2 : ایونت هایی را برمیگرداند که کاربر روی آن دعوت می باشد.3:تایپ =4 : ایونت هایی را برمیگرداند که کاربر ایجاد کننده آن می باشد.4:تایپ =0 : شامل تمامی موارد بالا می باشددر صورتی که این فیلد وارد نشود مقدار 0را به صورت پیش فرض در نظر میگیرد |
| `module_id` | integer (int64) | آیدی ماژول |
| `creator_id*` | integer (int64) | ایدی ایجاد کننده |
| `cur_user_id` | integer (int64) | ایدی یوزر فعلی |

## پاسخ

```json
{
  "data": [
    {
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
| `data[]` | array | data |
| `data[].id*` | integer (int64) | id |
| `data[].uid` | string | uid |
| `data[].name` | string | name |
| `data[].tzid` | integer (int64) | tzid |
| `data[].color` | string | color |
| `data[].place` | string | place |
| `data[].status` | integer (int32) | status |
| `data[].chat_id` | integer (int64) | chat_id |
| `data[].place_id` | integer (int64) | place_id |
| `data[].folder_id` | integer (int64) | folder_id |
| `data[].module_id` | integer (int64) | module_id |
| `data[].parent_id` | integer (int64) | parent_id |
| `data[].tzid_flag` | integer (int64) | tzid_flag |
| `data[].alarm_type` | integer (int32) | alarm_type |
| `data[].creator_id` | integer (int64) | creator_id |
| `data[].date_alarm` | integer (date) | date_alarm |
| `data[].date_start` | integer (date) | date_start |
| `data[].calendar_id*` | integer (int64) | calendar_id |
| `data[].date_create` | integer (date) | date_create |
| `data[].date_finish` | integer (date) | date_finish |
| `data[].date_modify` | integer (date) | date_modify |
| `data[].description` | string | description |
| `data[].modifier_id` | integer (int64) | modifier_id |
| `data[].period_type` | integer (int32) | period_type |
| `data[].end_of_month` | integer (int32) | end_of_month |
| `data[].period_until` | integer (int64) | period_until |
| `data[].bot_alarm_type` | integer (int32) | bot_alarm_type |
| `data[].bot_date_alarm` | integer (date) | bot_date_alarm |
| `data[].invite_user_id` | integer (int64) | invite_user_id |
| `data[].online_meeting` | integer (int32) | online_meeting |
| `data[].sms_alarm_type` | integer (int32) | sms_alarm_type |
| `data[].sms_date_alarm` | integer (date) | sms_date_alarm |
| `data[].period_interval` | integer (int64) | period_interval |
| `data[].concurrent_place` | integer (int32) | concurrent_place |
| `data[].invite_user_status` | integer (int32) | invite_user_status |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
