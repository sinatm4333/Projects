# ایجاد مشتری جدید

## آدرس

```
/api/client/create
```

## درخواست

```json
{
  "profile": {
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
  "profile_id": 0,
  "section_id": 0,
  "site_password": ""
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `profile` | object | اطلاعات پروفایل |
| `profile.name` | string | نام |
| `profile.email[]` | array | لیست ایمیل |
| `profile.email[].id` | integer (int64) | شناسه ایمیل |
| `profile.email[].value` | string | ایمیل |
| `profile.phone[]` | array | لیست شماره تلفن |
| `profile.phone[].id` | integer (int64) | شناسه شماره تلفن |
| `profile.phone[].ext` | string | شماره داخلی |
| `profile.phone[].type` | integer (int32) | نوع تلفنenum EnPhoneType { PHONE_TYPE_HOME = 2, PHONE_TYPE_WORK = 3, PHONE_TYPE_FAX = 4}; |
| `profile.phone[].value` | string | شماره تلفن |
| `profile.phone[].country` | integer (int32) | کد کشور (مثلا ایران 364) از روی فایل country_list.ini در config تیم یار |
| `profile.gender` | integer (int32) | جنسیتenum EnUserSex{ USER_SEX_MALE = 1, USER_SEX_FEMALE = 2}; |
| `profile.mobile[]` | array | لیست شماره موبایل |
| `profile.mobile[].id` | integer (int64) | شناسه موبایل |
| `profile.mobile[].value` | string | شماره موبایل |
| `profile.mobile[].country` | integer (int32) | کد کشور |
| `profile.address` | object | آدرس |
| `profile.address.home` | object | آدرس خانه |
| `profile.address.home.city` | string | شهر |
| `profile.address.home.loc_x` | number (double) | موقعیت طول جغرافیایی |
| `profile.address.home.loc_y` | number (double) | موقعیت عرض جغرافیایی |
| `profile.address.home.state` | string | استان |
| `profile.address.home.address` | string | آدرس |
| `profile.address.home.zip_code` | string | کد پستی |
| `profile.address.home.country_code` | integer (int32) | کد کشور |
| `profile.address.work` | object | آدرس محل کار |
| `profile.address.work.city` | string | شهر |
| `profile.address.work.loc_x` | number (double) | موقعیت طول جغرافیایی |
| `profile.address.work.loc_y` | number (double) | موقعیت عرض جغرافیایی |
| `profile.address.work.state` | string | استان |
| `profile.address.work.address` | string | آدرس |
| `profile.address.work.zip_code` | string | کد پستی |
| `profile.address.work.country_code` | integer (int32) | کد کشور |
| `profile.last_name` | string | نام خانوادگی |
| `profile.user_type` | integer (int32) | نوع کاربرenum EnUserTypes { USER_TYPE_NATURAL = 3, USER_TYPE_LEGAL = 4}; |
| `profile.birth_date` | integer (date) | تاریخ تولد |
| `profile.patronymic` | string | نام پدر |
| `profile.birth_place` | string | محل تولد |
| `profile.identity_no` | string | شماره شناسنامه |
| `profile.nationality` | string | ملیت |
| `profile.passport_no` | string | شماره گذرنامه |
| `profile.date_of_issue` | integer (date) | تاریخ صدور شناسنامه |
| `profile.national_code[]` | array | لیست کد ملی |
| `profile.national_code[].id` | integer (int64) | شناسه کد ملی |
| `profile.national_code[].value` | string | کد ملی |
| `profile.national_code[].country` | integer (int32) | کد کشور |
| `profile.place_of_issue` | string | محل صدور شناسنامه |
| `profile.identity_serial_no` | string | سریال شناسنامه |
| `profile_id` | integer (int64) | شناسه پروفایل |
| `section_id` | integer (int64) | شناسه بخش |
| `site_password` | string | پسورد سایت |

## پاسخ

```json
{
  "data": {
    "profile_id": 0
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
| `data.profile_id` | integer (int64) | شناسه مشتری |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
