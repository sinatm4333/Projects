# ثبت مناسبت برای روز های سال

از این Api می توان برای ثبت مناسبت ها و تعطیل بودن روز برای انواع تقویم در تیم یار استفاده کرد

## آدرس

```
/api/importCalendarEvents
```

## درخواست

```json
[
  {
    "day": 0,
    "month": 0,
    "events": [
      {
        "holiday": false,
        "description": "",
        "custom_form_data": ""
      }
    ],
    "calendar_type": 0
  }
]
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `day` | integer (int32) | روز |
| `month` | integer (int32) | ماه |
| `events[]` | array | مناسبت های ثبت شده برای آن روزبرای حذف مناسبت این پارامتر پر نشود |
| `events[].holiday` | boolean | مشخص می کند آیا این روز تعطیل رسمی هست یا خیر |
| `events[].description` | string | توضیحات مناسبت |
| `events[].custom_form_data` | string | دیتای فرم سفارشی |
| `calendar_type` | integer (int32) | نوع تقویم در تیمیار0 = میلادی1 = شمسی2 = قمری |

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
