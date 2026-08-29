# دریافت مناسبت های یک تقویم

دریافت تمام مناسبت های ثبت شده برای یک تقویم

## آدرس

```
/api/getCalendarEvents
```

## درخواست

```json
{
  "day": 0,
  "month": 0,
  "calendar_type": 0,
  "is_customform": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `day` | integer (int32) | روز (بالای 31 راقبول نخواهد کرد) |
| `month` | integer (int32) | ماه (بالای دوازده را قبول نخواهد کرد) |
| `calendar_type` | integer (int32) | نوع تقویم در تیمیار0 = میلادی1 = شمسی2 = قمری |
| `is_customform` | integer (int32) | در صورتی که تنظیمات کاستوم فرم را میخواهید تغییر دهید این مقدار را true کنید |

## پاسخ

```json
{
  "data": [
    {
      "day": 0,
      "month": 0,
      "events": [
        {
          "holiday": false,
          "description": "",
          "custom_form_data": ""
        }
      ]
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
| `data[]` | array | روز های سال |
| `data[].day` | integer (int32) | روز |
| `data[].month` | integer (int32) | ماه |
| `data[].events[]` | array | مناسبت های ثبت شده برای آن روز |
| `data[].events[].holiday` | boolean | مشخص می کند آیا این روز تعطیل رسمی هست یا خیر |
| `data[].events[].description` | string | توضیحات مناسبت |
| `data[].events[].custom_form_data` | string | دیتای فرم سفارشی |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
