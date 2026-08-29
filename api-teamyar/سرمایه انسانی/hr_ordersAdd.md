# ایجاد گروهی حکم

ایجاد احکام به صورت گروهی

## آدرس

```
/api/hr/ordersAdd
```

## درخواست

```json
{
  "orders_list": [
    {
      "orders": [
        {
          "type": 0,
          "roles": [
            0
          ],
          "org_id": 0,
          "taxable": 0,
          "unit_id": 0,
          "position": 0,
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
        }
      ],
      "date_to": 0,
      "date_from": 0
    }
  ]
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `orders_list[]` | array | لیست حکم ها |
| `orders_list[].orders[]` | array | لیست احکام |
| `orders_list[].orders[].type` | integer (int64) | نوع حکم که از جدول hr_order_type گرفته می شود. |
| `orders_list[].orders[].roles[]` | array | نقش ها |
| `orders_list[].orders[].org_id` | integer (int64) | شناسه شعبه |
| `orders_list[].orders[].taxable` | integer (int32) | مالیات پذیر |
| `orders_list[].orders[].unit_id` | integer (int64) | شناسه واحد |
| `orders_list[].orders[].position` | integer (int64) | شناسه سمت |
| `orders_list[].orders[].insurable` | integer (int32) | بیمه پذیر |
| `orders_list[].orders[].project_id` | integer (int64) | شناسه پروژه |
| `orders_list[].orders[].sick_leave` | integer (int64) | میزان مرخصی استعلاجی |
| `orders_list[].orders[].supervisor` | integer (int64) | سرپرست |
| `orders_list[].orders[].take_leave` | integer (int64) | نحوه گرفتن مرخصیenum EnTakeLeave{ HR_TAKELEAVE_DEFAULT = 0, HR_TAKELEAVE_UNTIL_NOW = 1, HR_TAKELEAVE_END_OF_ORDER = 2, HR_TAKELEAVE_OVER_ORDER = 3, HR_TAKELEAVE_END_OF_MONTH = 4}; |
| `orders_list[].orders[].calendar_id` | integer (int64) | شناسه تقویم از جدول HR_CALENDAR |
| `orders_list[].orders[].floating_id` | integer (int64) | شناسه نام شناور |
| `orders_list[].orders[].item_values[]` | array | پارامتر های ثابت |
| `orders_list[].orders[].item_values[].value` | integer (int64) | مقدار |
| `orders_list[].orders[].item_values[].item_id` | integer (int64) | شناسه پارامتر |
| `orders_list[].orders[].compact_rows[]` | array | لیست ردیف پیمان ها |
| `orders_list[].orders[].personnel_id` | integer (int64) | شناسه پرسنل |
| `orders_list[].orders[].holiday_leave` | integer (int64) | کل مرخصی روز تعطیل |
| `orders_list[].orders[].working_hours` | integer (int64) | ساعت کاری |
| `orders_list[].orders[].marriage_leave` | integer (int64) | کل مرخصی قانونی |
| `orders_list[].orders[].other_postions` | string | سایر مشاغل |
| `orders_list[].orders[].leave_per_month` | integer (int64) | مرخصی استحقاقی در ماه |
| `orders_list[].orders[].max_delay_month` | integer (int64) | سقف تاخیر مجاز ماهیانه |
| `orders_list[].orders[].other_calendars[]` | array | سایر تقویم ها |
| `orders_list[].orders[].salary_group_id` | integer (int64) | شناسه گروه استخدام |
| `orders_list[].orders[].floating_enabled` | integer (int32) | شناوری فعال |
| `orders_list[].orders[].max_hourly_leave` | integer (int64) | حداکثر مرخصی ساعتی |
| `orders_list[].orders[].min_hourly_leave` | integer (int64) | حداقل مرخصی ساعتی |
| `orders_list[].orders[].overtime_confirm` | integer (int32) | اضافه کار فعال |
| `orders_list[].orders[].rest_during_work` | integer (int64) | میزان استراحت حین کار |
| `orders_list[].orders[].telework_request` | integer (int32) | درخواست دورکاری |
| `orders_list[].orders[].overtime_disabled` | integer (int32) | اضافه کار فعال |
| `orders_list[].orders[].cal_daily_vacation` | integer (int32) | محاسبه مرخصی و ماموریت روزانه |
| `orders_list[].orders[].over_floating_hour` | integer (int64) | اضافه کار منعطف |
| `orders_list[].orders[].break_calculate_type` | integer (int32) | نحوه محاسبه زمان استراحت |
| `orders_list[].orders[].leave_transfer_total` | integer (int64) | انتقال مرخصی |
| `orders_list[].orders[].pre_overtime_confirm` | integer (int32) | تایید اضافه کار ابتدای کار |
| `orders_list[].orders[].pre_overtime_disabled` | integer (int32) | اضافه کار ابتدای کار فعال |
| `orders_list[].orders[].unemployment_insurance_exemption` | integer (int32) | معافیت بیمه بیکاری |
| `orders_list[].date_to` | integer (int64) | بازه پایان |
| `orders_list[].date_from` | integer (int64) | بازه شروع |

## پاسخ

```json
{
  "data": {
    "message": ""
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
| `data` | object | داده های مربوط به پاسخ اجرای API |
| `data.message` | string | پیغام اطلاعات |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
