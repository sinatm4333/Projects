# دریافت حکم فعال در تاریخ مشخص

دریافت حکم فعال کارمند در یک تاریخ مشخص

## آدرس

```
/api/hr/orderInDateGet
```

## درخواست

```json
{
  "date": 0,
  "org_id": 0,
  "personnel_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `date` | integer (int64) | تاریخ مورد درخواست |
| `org_id` | integer (int64) |  |
| `personnel_id` | integer (int64) | شناسه کارمند مورد درخواست |

## پاسخ

```json
{
  "data": {
    "id": 0,
    "type": 0,
    "roles": [
      0
    ],
    "org_id": 0,
    "date_to": 0,
    "taxable": 0,
    "unit_id": 0,
    "position": 0,
    "date_from": 0,
    "insurable": 0,
    "project_id": 0,
    "sick_leave": 0,
    "supervisor": 0,
    "take_leave": 0,
    "calendar_id": 0,
    "floating_id": 0,
    "item_values": [
      {
        "value": 0,
        "item_id": 0
      }
    ],
    "compact_rows": [
      0
    ],
    "personnel_id": 0,
    "holiday_leave": 0,
    "working_hours": 0,
    "marriage_leave": 0,
    "other_postions": "",
    "leave_per_month": 0,
    "max_delay_month": 0,
    "other_calendars": [
      0
    ],
    "salary_group_id": 0,
    "floating_enabled": 0,
    "max_hourly_leave": 0,
    "min_hourly_leave": 0,
    "overtime_confirm": 0,
    "rest_during_work": 0,
    "telework_request": 0,
    "overtime_disabled": 0,
    "cal_daily_vacation": 0,
    "over_floating_hour": 0,
    "break_calculate_type": 0,
    "leave_transfer_total": 0,
    "pre_overtime_confirm": 0,
    "pre_overtime_disabled": 0,
    "unemployment_insurance_exemption": 0
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
| `data` | object | داده های نتیجه اجرای API |
| `data.id` | integer (int64) | شناسه حکم |
| `data.type` | integer (int64) | نوع حکم |
| `data.roles[]` | array | نقش ها |
| `data.org_id` | integer (int64) | شعبه |
| `data.date_to` | integer (int64) | تاریخ انقضاء حکم (تاریخ پایان) |
| `data.taxable` | integer (int32) | مشمول مالیات |
| `data.unit_id` | integer (int64) | واحد سازمانی |
| `data.position` | integer (int64) | شغل |
| `data.date_from` | integer (int64) | تاریخ شروع |
| `data.insurable` | integer (int32) | مشمول بیمه |
| `data.project_id` | integer (int64) | پروژه |
| `data.sick_leave` | integer (int64) | کل مرخصی استعلاجی |
| `data.supervisor` | integer (int64) | سرپرست |
| `data.take_leave` | integer (int64) | نحوه گرفتن مرخصی |
| `data.calendar_id` | integer (int64) | تقویم کاری |
| `data.floating_id` | integer (int64) | شناور |
| `data.item_values[]` | array | پارامترهای حقوقی حکم |
| `data.item_values[].value` | integer (int64) | مقدار پارامتر |
| `data.item_values[].item_id` | integer (int64) | شناسه پارامتر حقوقی |
| `data.compact_rows[]` | array | ردیف های پیمان |
| `data.personnel_id` | integer (int64) | شناسه کارمند |
| `data.holiday_leave` | integer (int64) | کل مرخصی روز تعطیل |
| `data.working_hours` | integer (int64) | ساعت کاری |
| `data.marriage_leave` | integer (int64) | کل مرخصی قانونی |
| `data.other_postions` | string | شناسه های سایر مشاغل |
| `data.leave_per_month` | integer (int64) | مرخصی استحقاقی در ماه |
| `data.max_delay_month` | integer (int64) | سقف تأخیر مجاز ماهانه |
| `data.other_calendars[]` | array | سایر تقویم ها |
| `data.salary_group_id` | integer (int64) | گروه استخدامی |
| `data.floating_enabled` | integer (int32) | شناوری فعال/غیر فعال |
| `data.max_hourly_leave` | integer (int64) | سقف مرخصی ساعتی |
| `data.min_hourly_leave` | integer (int64) | حداقل مرخصی ساعتی |
| `data.overtime_confirm` | integer (int32) | نیازه به تأیید اضافه کاری دارد/ندارد |
| `data.rest_during_work` | integer (int64) | استراحت حین کار |
| `data.telework_request` | integer (int32) | درخواست دورکاری فعال/غیر فعال |
| `data.overtime_disabled` | integer (int32) | اضافه کار فعال/غیر فعال |
| `data.cal_daily_vacation` | integer (int32) | محاسبه مرخصی و مأموریت روزانه |
| `data.over_floating_hour` | integer (int64) | اضافه کار منعطف |
| `data.break_calculate_type` | integer (int32) | محاسبه زمان استراحت |
| `data.leave_transfer_total` | integer (int64) | انتقال مرخصی |
| `data.pre_overtime_confirm` | integer (int32) | نیاز به تأیید اضافه کار ابتدای کار دارد/ندارد |
| `data.pre_overtime_disabled` | integer (int32) | اضافه کار ابتدای کار فعال/غیر فعال |
| `data.unemployment_insurance_exemption` | integer (int32) | معافیت بیمه بیکاری دارد/ندارد |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
