# چک کردن وجود مشتری

با ارسال موبایل، ایمیل یا کد ملی می توان وجود مشتری یا پروفایل مطابق با اطلاعات ارسالی را بررسی کرد

## آدرس

```
/api/client/check
```

## درخواست

```json
{
  "email": [
    {
      "id": 0,
      "value": ""
    }
  ],
  "mobile": [
    {
      "id": 0,
      "value": "",
      "country": 0
    }
  ],
  "national_code": [
    {
      "id": 0,
      "value": "",
      "country": 0
    }
  ]
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `email[]` | array | لیست ایمیل |
| `email[].id` | integer (int64) | در این درخواست کاربرد ندارد |
| `email[].value` | string | ایمیل |
| `mobile[]` | array | لیست شماره موبایل |
| `mobile[].id` | integer (int64) | در این درخواست کاربرد ندارد |
| `mobile[].value` | string | شماره موبایل |
| `mobile[].country` | integer (int32) | کد کشور |
| `national_code[]` | array | لیست کد ملی |
| `national_code[].id` | integer (int64) | در این درخواست کاربرد ندارد |
| `national_code[].value` | string | کد ملی |
| `national_code[].country` | integer (int32) | کد کشور |

## پاسخ

```json
{
  "data": {
    "list": [
      {
        "exist": "",
        "profile": {
          "id": 0,
          "name": "",
          "email": [
            {
              "id": 0,
              "value": ""
            }
          ],
          "phone": [
            {
              "id": 0,
              "ext": "",
              "type": 0,
              "value": "",
              "country": 0
            }
          ],
          "gender": 0,
          "mobile": [
            {
              "id": 0,
              "value": "",
              "country": 0
            }
          ],
          "address": {
            "home": {
              "city": "",
              "loc_x": 0,
              "loc_y": 0,
              "state": "",
              "address": "",
              "zip_code": "",
              "country_code": 0
            },
            "work": {
              "city": "",
              "loc_x": 0,
              "loc_y": 0,
              "state": "",
              "address": "",
              "zip_code": "",
              "country_code": 0
            }
          },
          "last_name": "",
          "user_type": 0,
          "birth_date": 0,
          "patronymic": "",
          "birth_place": "",
          "identity_no": "",
          "nationality": "",
          "passport_no": "",
          "date_of_issue": 0,
          "national_code": [
            {
              "id": 0,
              "value": "",
              "country": 0
            }
          ],
          "place_of_issue": "",
          "identity_serial_no": ""
        },
        "exist_in": ""
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
| `data.list[]` | array | لیست پروفایل های پیدا شده |
| `data.list[].exist` | string | نشان می دهد کدام مقدار برای این پروفایل وجود داردمثال: اگر هر سه مقدار وجود داشته باشد مقدار آن به صورت زیر استnational_code,mobile,email |
| `data.list[].profile` | object | اطلاعات پروفایل |
| `data.list[].profile.id` | integer (int64) | شناسه مشتری یا پروفایل |
| `data.list[].profile.name` | string | نام |
| `data.list[].profile.email[]` | array | لیست ایمیل |
| `data.list[].profile.email[].id` | integer (int64) | شناسه ایمیل |
| `data.list[].profile.email[].value` | string | ایمیل |
| `data.list[].profile.phone[]` | array | لیست شماره تلفن |
| `data.list[].profile.phone[].id` | integer (int64) | شناسه شماره تلفن |
| `data.list[].profile.phone[].ext` | string | شماره داخلی |
| `data.list[].profile.phone[].type` | integer (int32) | نوع تلفنenum EnPhoneType { PHONE_TYPE_HOME = 2, PHONE_TYPE_WORK = 3, PHONE_TYPE_FAX = 4}; |
| `data.list[].profile.phone[].value` | string | شماره تلفن |
| `data.list[].profile.phone[].country` | integer (int32) | کد کشور |
| `data.list[].profile.gender` | integer (int32) | جنسیتenum EnUserSex{ USER_SEX_MALE = 1, USER_SEX_FEMALE = 2}; |
| `data.list[].profile.mobile[]` | array | لیست شماره موبایل |
| `data.list[].profile.mobile[].id` | integer (int64) | شناسه موبایل |
| `data.list[].profile.mobile[].value` | string | شماره موبایل |
| `data.list[].profile.mobile[].country` | integer (int32) | کد کشور |
| `data.list[].profile.address` | object | آدرس |
| `data.list[].profile.address.home` | object | آدرس خانه |
| `data.list[].profile.address.home.city` | string | شهر |
| `data.list[].profile.address.home.loc_x` | number (double) | موقعیت طول جغرافیایی |
| `data.list[].profile.address.home.loc_y` | number (double) | موقعیت عرض جغرافیایی |
| `data.list[].profile.address.home.state` | string | استان |
| `data.list[].profile.address.home.address` | string | آدرس |
| `data.list[].profile.address.home.zip_code` | string | کد پستی |
| `data.list[].profile.address.home.country_code` | integer (int32) | کد کشور |
| `data.list[].profile.address.work` | object | آدرس محل کار |
| `data.list[].profile.address.work.city` | string | شهر |
| `data.list[].profile.address.work.loc_x` | number (double) | موقعیت طول جغرافیایی |
| `data.list[].profile.address.work.loc_y` | number (double) | موقعیت عرض جغرافیایی |
| `data.list[].profile.address.work.state` | string | استان |
| `data.list[].profile.address.work.address` | string | آدرس |
| `data.list[].profile.address.work.zip_code` | string | کد پستی |
| `data.list[].profile.address.work.country_code` | integer (int32) | کد کشور |
| `data.list[].profile.last_name` | string | نام خانوادگی |
| `data.list[].profile.user_type` | integer (int32) | نوع کاربرenum EnUserTypes { USER_TYPE_NATURAL = 3, USER_TYPE_LEGAL = 4}; |
| `data.list[].profile.birth_date` | integer (date) | تاریخ تولد |
| `data.list[].profile.patronymic` | string | نام پدر |
| `data.list[].profile.birth_place` | string | محل تولد |
| `data.list[].profile.identity_no` | string | شماره شناسنامه |
| `data.list[].profile.nationality` | string | ملیت |
| `data.list[].profile.passport_no` | string | شماره گذرنامه |
| `data.list[].profile.date_of_issue` | integer (date) | تاریخ صدور شناسنامه |
| `data.list[].profile.national_code[]` | array | لیست کد ملی |
| `data.list[].profile.national_code[].id` | integer (int64) | شناسه کد ملی |
| `data.list[].profile.national_code[].value` | string | کد ملی |
| `data.list[].profile.national_code[].country` | integer (int32) | کد کشور |
| `data.list[].profile.place_of_issue` | string | محل صدور شناسنامه |
| `data.list[].profile.identity_serial_no` | string | سریال شناسنامه |
| `data.list[].exist_in` | string | اگر در مشتری وجود داشته باشد مقدار "CRM" و اگر در پروفایل باشد مقدار "PROFILE" را دارد |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
