# افزودن اطلاعات پرونده های کارمندان

ایجاد پرسنل یا ویرایش اطلاعات موجود در پرونده کارمندان

## آدرس

```
/api/hr/personneladd
```

## درخواست

```json
{
  "org_id": 0,
  "persennels": [
    {
      "city": "",
      "name": "",
      "email": [
        {
          "value": ""
        }
      ],
      "gender": 0,
      "address": "",
      "surname": "",
      "families": [
        {
          "job": "",
          "phone": "",
          "gender": 0,
          "address": "",
          "relation": 0,
          "education": 0,
          "last_name": "",
          "birth_date": {
            "day": 0,
            "year": 0,
            "month": 0,
            "date_int64": 0
          },
          "first_name": "",
          "birth_place": "",
          "is_dependant": 0,
          "national_code": "",
          "additional_insurance_id": 0
        }
      ],
      "religion": "",
      "birth_date": {
        "day": 0,
        "year": 0,
        "month": 0,
        "date_int64": 0
      },
      "educations": [
        {
          "kind": 0,
          "grade": 0,
          "major": "",
          "score": 0,
          "degree": 0,
          "average": "",
          "comment": "",
          "end_date": {
            "day": 0,
            "year": 0,
            "month": 0,
            "date_int64": 0
          },
          "education": 0,
          "start_date": {
            "day": 0,
            "year": 0,
            "month": 0,
            "date_int64": 0
          },
          "university": ""
        }
      ],
      "home_phone": [
        {
          "type": 0,
          "value": "",
          "country": 0,
          "extensions": ""
        }
      ],
      "profile_id": 0,
      "birth_place": "",
      "father_name": "",
      "national_id": [
        {
          "value": "",
          "country": 0
        }
      ],
      "postal_code": "",
      "personnel_id": 0,
      "custom_fields": [
        {
          "id": 0,
          "value": ""
        }
      ],
      "delete_family": [
        0
      ],
      "account_number": "",
      "force_rollcall": 0,
      "marital_status": 0,
      "mobile_numbers": [
        {
          "value": "",
          "country": 0
        }
      ],
      "personnel_code": 0,
      "personnel_type": 0,
      "work_histories": [
        {
          "type": 0,
          "phone": "",
          "score": 0,
          "salary": 0,
          "address": "",
          "company": "",
          "to_date": {
            "day": 0,
            "year": 0,
            "month": 0,
            "date_int64": 0
          },
          "position": "",
          "from_date": {
            "day": 0,
            "year": 0,
            "month": 0,
            "date_int64": 0
          },
          "insurance": 0,
          "end_reason": ""
        }
      ],
      "accounting_type": 0,
      "delete_email_id": [
        0
      ],
      "delete_education": [
        0
      ],
      "delete_mobile_id": [
        0
      ],
      "delete_national_id": [
        0
      ],
      "delete_work_history": [
        0
      ],
      "delete_home_phone_id": [
        0
      ],
      "identity_card_number": "",
      "collaborate_start_date": {
        "day": 0,
        "year": 0,
        "month": 0,
        "date_int64": 0
      },
      "additional_insurance_id": 0,
      "military_service_status": 0
    }
  ]
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `org_id` | integer (int64) | شعبه پرونده ها (در صورت عدم ورود، شعبه فعال کاربر در نظر گرفته می شود) |
| `persennels[]` | array | لیست اطلاعات پرونده های کارمندان |
| `persennels[].city` | string | شهر |
| `persennels[].name` | string | نام کارمند |
| `persennels[].email[]` | array | لیست ایمیل ها |
| `persennels[].email[].value` | string | آدرس ایمیل |
| `persennels[].gender` | integer (int64) | جنسیت |
| `persennels[].address` | string | آدرس |
| `persennels[].surname` | string | نام خانوادگی کارمند |
| `persennels[].families[]` | array | لیست اطلاعات خانوار |
| `persennels[].families[].job` | string | شغل |
| `persennels[].families[].phone` | string | تلفن |
| `persennels[].families[].gender` | integer (int32) | جنسیت |
| `persennels[].families[].address` | string | آدرس |
| `persennels[].families[].relation` | integer (int32) | نسبت خانوادگی با کارمند |
| `persennels[].families[].education` | integer (int32) | میزان تحصیلات |
| `persennels[].families[].last_name` | string | نام خانوادگی |
| `persennels[].families[].birth_date` | object | تاریخ تولد |
| `persennels[].families[].birth_date.day` | integer (int32) | روز |
| `persennels[].families[].birth_date.year` | integer (int32) | سال |
| `persennels[].families[].birth_date.month` | integer (int32) | ماه |
| `persennels[].families[].birth_date.date_int64` | integer (int64) |  |
| `persennels[].families[].first_name` | string | نام |
| `persennels[].families[].birth_place` | string | محل تولد |
| `persennels[].families[].is_dependant` | integer (int32) | تحت تکفل هست/نیست |
| `persennels[].families[].national_code` | string | کد ملی |
| `persennels[].families[].additional_insurance_id` | integer (int64) | نوع بیمه تکمیلی |
| `persennels[].religion` | string | دین |
| `persennels[].birth_date` | object | تاریخ تولد |
| `persennels[].birth_date.day` | integer (int32) | روز |
| `persennels[].birth_date.year` | integer (int32) | سال |
| `persennels[].birth_date.month` | integer (int32) | ماه |
| `persennels[].birth_date.date_int64` | integer (int64) |  |
| `persennels[].educations[]` | array | اطلاعات تحصیلات/مهارت کارمند |
| `persennels[].educations[].kind` | integer (int32) | نوع مهارت(1) یا تحصیل(2) |
| `persennels[].educations[].grade` | integer (int64) | درجه در مهارت |
| `persennels[].educations[].major` | string | رشته |
| `persennels[].educations[].score` | integer (int64) | امتیاز (ورود دو رقم اضافه برای اعشار) |
| `persennels[].educations[].degree` | integer (int32) | مدرک دارد/ندارد |
| `persennels[].educations[].average` | string | معدل/میزان تسلط |
| `persennels[].educations[].comment` | string | توضیح |
| `persennels[].educations[].end_date` | object | تاریخ پایان |
| `persennels[].educations[].end_date.day` | integer (int32) | روز |
| `persennels[].educations[].end_date.year` | integer (int32) | سال |
| `persennels[].educations[].end_date.month` | integer (int32) | ماه |
| `persennels[].educations[].end_date.date_int64` | integer (int64) |  |
| `persennels[].educations[].education` | integer (int64) | نوع تحصیلات/ مهارت |
| `persennels[].educations[].start_date` | object | تاریخ شروع |
| `persennels[].educations[].start_date.day` | integer (int32) | روز |
| `persennels[].educations[].start_date.year` | integer (int32) | سال |
| `persennels[].educations[].start_date.month` | integer (int32) | ماه |
| `persennels[].educations[].start_date.date_int64` | integer (int64) |  |
| `persennels[].educations[].university` | string | دانشگاه/مؤسسه |
| `persennels[].home_phone[]` | array | لیست اطلاعات تلفن های کارمند |
| `persennels[].home_phone[].type` | integer (int32) | نوع تلفن تماس (خانه، محل کار) |
| `persennels[].home_phone[].value` | string | تلفن |
| `persennels[].home_phone[].country` | integer (int32) | شناسه مربوط به کد کشور |
| `persennels[].home_phone[].extensions` | string | کد داخلی تلفن |
| `persennels[].profile_id` | integer (int64) | شناسه پروفایل کارمند (در صورتی که از پروفایل از قبل موجود بوده) |
| `persennels[].birth_place` | string | محل تولد |
| `persennels[].father_name` | string | نام پدر |
| `persennels[].national_id[]` | array | لیست کدهای شناسایی ملی (کد ملی) |
| `persennels[].national_id[].value` | string | کد ملی |
| `persennels[].national_id[].country` | integer (int32) | شناسه مربوط به کد کشور |
| `persennels[].postal_code` | string | کد پستی |
| `persennels[].personnel_id` | integer (int64) | شناسه کارمند (در صورتی که پرونده در شعبه از قبل موجود بوده) |
| `persennels[].custom_fields[]` | array | لیست اطلاعات فیلدهای سفارشی |
| `persennels[].custom_fields[].id` | integer (int64) | شناسه فیلد سفارشی |
| `persennels[].custom_fields[].value` | string | مقدار فیلد در پرونده کارمند |
| `persennels[].delete_family[]` | array | لیست اعضای خانواری که حذف می شوند |
| `persennels[].account_number` | string | شماره حساب |
| `persennels[].force_rollcall` | integer (int32) | حضور و غیاب اجباری هست/نیست |
| `persennels[].marital_status` | integer (int32) | وضعیت تأهل |
| `persennels[].mobile_numbers[]` | array | لیست اطلاعات شماره های موبایل کارمند |
| `persennels[].mobile_numbers[].value` | string | شماره موبایل |
| `persennels[].mobile_numbers[].country` | integer (int32) | شناسه مربوط به کد کشور |
| `persennels[].personnel_code` | integer (int64) | کد پرسنلی (در صورت وارد نکردن، به صورت سیستمی در نظر گرفته می شود) |
| `persennels[].personnel_type` | integer (int32) | وضعیت کارمند |
| `persennels[].work_histories[]` | array | لیست اطلاعات سوابق کاری کارمند |
| `persennels[].work_histories[].type` | integer (int32) | نوع سابقه |
| `persennels[].work_histories[].phone` | string | تلفن |
| `persennels[].work_histories[].score` | integer (int64) | امتیاز |
| `persennels[].work_histories[].salary` | integer (int64) | حقوق دریافتی |
| `persennels[].work_histories[].address` | string | آدرس |
| `persennels[].work_histories[].company` | string | نام شرکت |
| `persennels[].work_histories[].to_date` | object | تاریخ خاتمه |
| `persennels[].work_histories[].to_date.day` | integer (int32) | روز |
| `persennels[].work_histories[].to_date.year` | integer (int32) | سال |
| `persennels[].work_histories[].to_date.month` | integer (int32) | ماه |
| `persennels[].work_histories[].to_date.date_int64` | integer (int64) |  |
| `persennels[].work_histories[].position` | string | شغل |
| `persennels[].work_histories[].from_date` | object | تاریخ شروع |
| `persennels[].work_histories[].from_date.day` | integer (int32) | روز |
| `persennels[].work_histories[].from_date.year` | integer (int32) | سال |
| `persennels[].work_histories[].from_date.month` | integer (int32) | ماه |
| `persennels[].work_histories[].from_date.date_int64` | integer (int64) |  |
| `persennels[].work_histories[].insurance` | integer (int32) | سابقه بیمه دارد/ندارد |
| `persennels[].work_histories[].end_reason` | string | علت خاتمه همکاری |
| `persennels[].accounting_type` | integer (int32) | نوع حساب |
| `persennels[].delete_email_id[]` | array | لیست ایمیل هایی که حذف می شوند |
| `persennels[].delete_education[]` | array | لیست تحصیلات/مهارت هایی که حذف می شوند |
| `persennels[].delete_mobile_id[]` | array | لیست شماره موبایل هایی که حذف می شوند |
| `persennels[].delete_national_id[]` | array | لیست کد ملی هایی که حذف می شوند. |
| `persennels[].delete_work_history[]` | array | لیست سوابق کاری که حذف می شوند |
| `persennels[].delete_home_phone_id[]` | array | لیست تلفن هایی که حذف می شوند. |
| `persennels[].identity_card_number` | string | شماره شناسنامه |
| `persennels[].collaborate_start_date` | object | تاریخ شروع همکاری |
| `persennels[].collaborate_start_date.day` | integer (int32) | روز |
| `persennels[].collaborate_start_date.year` | integer (int32) | سال |
| `persennels[].collaborate_start_date.month` | integer (int32) | ماه |
| `persennels[].collaborate_start_date.date_int64` | integer (int64) |  |
| `persennels[].additional_insurance_id` | integer (int64) | شناسه نوع بیمه تکمیلی کارمند |
| `persennels[].military_service_status` | integer (int32) | وضعیت نظام وظیفه |

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
| `data` | object | داده های نتیجه اجرای API |
| `data.message` | string | پیغام مربوط به نتیجه اجرای API |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
