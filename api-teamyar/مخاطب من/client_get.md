# دریافت اطلاعات مشتری

## آدرس

```
/api/client/get
```

## درخواست

```json
{
  "id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) | شناسه مشتری |

## پاسخ

```json
{
  "data": {
    "id": 0,
    "job": "",
    "kpp": "",
    "tin": "",
    "date": 0,
    "label": "",
    "domain": "",
    "account": "",
    "address": [
      {
        "id": 0,
        "fax": "",
        "city": "",
        "title": "",
        "address": "",
        "comment": "",
        "country": 0,
        "latitude": 0,
        "province": "",
        "longitude": 0,
        "home_phone": "",
        "work_phone": "",
        "postal_code": "",
        "mobile_phone": ""
      }
    ],
    "comment": "",
    "company": "",
    "contact": [
      {
        "type": 0,
        "contact_id": 0,
        "force_sign": 0,
        "contact_text": "",
        "login_portal": [
          0
        ],
        "contact_phone": "",
        "along_with_sign": 0,
        "contact_comment": "",
        "contact_position": ""
      }
    ],
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
    "station": "",
    "website": "",
    "industry": 0,
    "language": "",
    "card_info": [
      {
        "id": 0,
        "iban": "",
        "comment": "",
        "currency": {
          "id": 0,
          "org_id": 0
        },
        "bank_name": "",
        "card_type": 0,
        "card_holder": "",
        "card_number": "",
        "expiry_date": 0,
        "deposit_type": 0,
        "security_code": ""
      }
    ],
    "city_code": {
      "id": "",
      "name": ""
    },
    "import_id": 0,
    "time_zone": 0,
    "reg_number": "",
    "state_code": {
      "id": "",
      "name": ""
    },
    "create_date": 0,
    "account_info": [
      {
        "id": 0,
        "city": "",
        "iban": "",
        "shaba": "",
        "state": "",
        "branch": "",
        "comment": "",
        "country": 0,
        "fedwire": "",
        "routing": "",
        "currency": {
          "id": 0,
          "org_id": 0
        },
        "bank_name": "",
        "swift_code": "",
        "bank_address": "",
        "account_number": ""
      }
    ],
    "custom_field": [
      {
        "id": 0,
        "value": ""
      }
    ],
    "property_code": "",
    "property_date": 0,
    "issue_activity": "",
    "classify_persons": [
      0
    ],
    "number_personnel": 0,
    "personality_type": 0
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
| `data.id` | integer (int64) | شناسه مشتری |
| `data.job` | string | شغل (مشتری حقیقی) |
| `data.kpp` | string | شماره پاسپورت (مشتری حقیقی)کد ملی مدیر عامل (مشتری حقوقی) |
| `data.tin` | string | کد اقتصادی |
| `data.date` | integer (int64) | تاریخ |
| `data.label` | string | برچسب |
| `data.domain` | string | دامنه |
| `data.account` | string | مدیر عامل |
| `data.address[]` | array | لیست آدرس ها در ماژول مشتری |
| `data.address[].id` | integer (int64) | شناسه |
| `data.address[].fax` | string | فکس |
| `data.address[].city` | string | شهر |
| `data.address[].title` | string | عنوان آدرس |
| `data.address[].address` | string | آدرس |
| `data.address[].comment` | string | توضیحات |
| `data.address[].country` | integer (int32) | کد کشور |
| `data.address[].latitude` | number (double) | عرض جغرافیایی |
| `data.address[].province` | string | استان |
| `data.address[].longitude` | number (double) | طول جغرافیایی |
| `data.address[].home_phone` | string | تلفن منزل |
| `data.address[].work_phone` | string | تلفن محل کار |
| `data.address[].postal_code` | string | کدپستی |
| `data.address[].mobile_phone` | string | تلفن همراه |
| `data.comment` | string | توضیحات |
| `data.company` | string | شرکت (مشتری حقیقی) |
| `data.contact[]` | array | لیست رابط ها |
| `data.contact[].type` | integer (int32) | نوع رابطCONTACT_TYPE_CRM =1 (مشتری تیمیار باشد، به صورت دو طرفه ثبت می شود)CONTACT_TYPE_TEXT =2 (مشتری تیمیار نباشد)CONTACT_TYPE_REFERER =3 (مشتری تیمیار. برای ثبت معرف از این نوع استفاده می شود. به صورت یک طرفه) |
| `data.contact[].contact_id` | integer (int64) | شناسه ی رابط (شناسه مشتری) |
| `data.contact[].force_sign` | integer (int32) | استفاده نشده |
| `data.contact[].contact_text` | string | عنوان رابط برای رابطینی که مشتری تیم یار نیستند |
| `data.contact[].login_portal[]` | array | استفاده نشده |
| `data.contact[].contact_phone` | string | شماره تماس |
| `data.contact[].along_with_sign` | integer (int32) | استفاده نشده |
| `data.contact[].contact_comment` | string | توضیحات |
| `data.contact[].contact_position` | string | سمت |
| `data.profile` | object | اطلاعات پروفایل |
| `data.profile.id` | integer (int64) | شناسه پروفایل |
| `data.profile.name` | string | نام |
| `data.profile.email[]` | array | لیست ایمیل |
| `data.profile.email[].id` | integer (int64) | شناسه ایمیل |
| `data.profile.email[].value` | string | ایمیل |
| `data.profile.phone[]` | array | لیست شماره تلفن |
| `data.profile.phone[].id` | integer (int64) | شناسه شماره تلفن |
| `data.profile.phone[].ext` | string | شماره داخلی |
| `data.profile.phone[].type` | integer (int32) | نوع تلفنenum EnPhoneType { PHONE_TYPE_HOME = 2, PHONE_TYPE_WORK = 3, PHONE_TYPE_FAX = 4}; |
| `data.profile.phone[].value` | string | شماره تلفن |
| `data.profile.phone[].country` | integer (int32) | کد کشور |
| `data.profile.gender` | integer (int32) | جنسیتenum EnUserSex{ USER_SEX_MALE = 1, USER_SEX_FEMALE = 2}; |
| `data.profile.mobile[]` | array | لیست شماره موبایل |
| `data.profile.mobile[].id` | integer (int64) | شناسه موبایل |
| `data.profile.mobile[].value` | string | شماره موبایل |
| `data.profile.mobile[].country` | integer (int32) | کد کشور |
| `data.profile.address` | object | آدرس |
| `data.profile.address.home` | object | آدرس خانه |
| `data.profile.address.home.city` | string | شهر |
| `data.profile.address.home.loc_x` | number (double) | موقعیت طول جغرافیایی |
| `data.profile.address.home.loc_y` | number (double) | موقعیت عرض جغرافیایی |
| `data.profile.address.home.state` | string | استان |
| `data.profile.address.home.address` | string | آدرس |
| `data.profile.address.home.zip_code` | string | کد پستی |
| `data.profile.address.home.country_code` | integer (int32) | کد کشور |
| `data.profile.address.work` | object | آدرس محل کار |
| `data.profile.address.work.city` | string | شهر |
| `data.profile.address.work.loc_x` | number (double) | موقعیت طول جغرافیایی |
| `data.profile.address.work.loc_y` | number (double) | موقعیت عرض جغرافیایی |
| `data.profile.address.work.state` | string | استان |
| `data.profile.address.work.address` | string | آدرس |
| `data.profile.address.work.zip_code` | string | کد پستی |
| `data.profile.address.work.country_code` | integer (int32) | کد کشور |
| `data.profile.last_name` | string | نام خانوادگی |
| `data.profile.user_type` | integer (int32) | نوع کاربرenum EnUserTypes { USER_TYPE_NATURAL = 3, USER_TYPE_LEGAL = 4}; |
| `data.profile.birth_date` | integer (date) | تاریخ تولد |
| `data.profile.patronymic` | string | نام پدر |
| `data.profile.birth_place` | string | محل تولد |
| `data.profile.identity_no` | string | شماره شناسنامه |
| `data.profile.nationality` | string | ملیت |
| `data.profile.passport_no` | string | شماره گذرنامه |
| `data.profile.date_of_issue` | integer (date) | تاریخ صدور شناسنامه |
| `data.profile.national_code[]` | array | لیست کد ملی |
| `data.profile.national_code[].id` | integer (int64) | شناسه کد ملی |
| `data.profile.national_code[].value` | string | کد ملی |
| `data.profile.national_code[].country` | integer (int32) | کد کشور |
| `data.profile.place_of_issue` | string | محل صدور شناسنامه |
| `data.profile.identity_serial_no` | string | سریال شناسنامه |
| `data.station` | string | محل ثبت (مشتری حقوقی) |
| `data.website` | string | وب سایت |
| `data.industry` | integer (int32) | پیشه (مشتری حقوقی) |
| `data.language` | string | زبان (مشتری حقیقی) |
| `data.card_info[]` | array | لیست کارت ها اعتبازی |
| `data.card_info[].id` | integer (int64) | شناسه |
| `data.card_info[].iban` | string |  |
| `data.card_info[].comment` | string | توضیحات |
| `data.card_info[].currency` | object | نوع ارز - شناسه از جدول crm_setting با type 15 |
| `data.card_info[].currency.id` | integer (int64) | شناسه ارز |
| `data.card_info[].currency.org_id` | integer (int64) | شناسه شعبه |
| `data.card_info[].bank_name` | string | نام بانک |
| `data.card_info[].card_type` | integer (int32) | نوع کارت - شناسه از جدول crm_setting با type 14 |
| `data.card_info[].card_holder` | string | صاحب کارت |
| `data.card_info[].card_number` | string | شماره کارت |
| `data.card_info[].expiry_date` | integer (int64) | تاریخ انقضا |
| `data.card_info[].deposit_type` | integer (int32) | نوع سپرده |
| `data.card_info[].security_code` | string | کد امنیتی |
| `data.city_code` | object | کد شهر |
| `data.city_code.id` | string | کد شهر |
| `data.city_code.name` | string | نام شهر |
| `data.import_id` | integer (int64) | شناسه ایمپورت مشتری |
| `data.time_zone` | integer (int64) | شناسه منطقه زمانی |
| `data.reg_number` | string | شماره ثبت (مشتری حقوقی) |
| `data.state_code` | object | کد استان |
| `data.state_code.id` | string | کد استان |
| `data.state_code.name` | string | نام استان |
| `data.create_date` | integer (date) | زمان به وجود آمدن مشتری |
| `data.account_info[]` | array | لیست اطلاعات حساب ها |
| `data.account_info[].id` | integer (int64) | شناسه |
| `data.account_info[].city` | string | شهر |
| `data.account_info[].iban` | string | آی بن |
| `data.account_info[].shaba` | string | شناسه شبا |
| `data.account_info[].state` | string | استان |
| `data.account_info[].branch` | string | شعبه |
| `data.account_info[].comment` | string | توضیحات |
| `data.account_info[].country` | integer (int32) | کد کشور |
| `data.account_info[].fedwire` | string | فد وایر |
| `data.account_info[].routing` | string | روتینگ |
| `data.account_info[].currency` | object | نوع ارز |
| `data.account_info[].currency.id` | integer (int64) | شناسه ارز |
| `data.account_info[].currency.org_id` | integer (int64) | شناسه شعبه |
| `data.account_info[].bank_name` | string | نام بانک |
| `data.account_info[].swift_code` | string | کد سوئیفت |
| `data.account_info[].bank_address` | string | آدرس بانک |
| `data.account_info[].account_number` | string | شماره حساب |
| `data.custom_field[]` | array | فیلد های سفارشی |
| `data.custom_field[].id` | integer (int32) | شناسه فیلد |
| `data.custom_field[].value` | string | مقدار فیلد |
| `data.property_code` | string | شماره پروانه کسب |
| `data.property_date` | integer (int64) | تاریخ ثبت (مشتری حقوقی) |
| `data.issue_activity` | string | موضوع/حوزه فعالیت |
| `data.classify_persons[]` | array | رده های مشتری |
| `data.number_personnel` | integer (int64) | تعداد پرسنل |
| `data.personality_type` | integer (int32) | نوع شخصیت حقوقی (مشتری حقوقی) |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
