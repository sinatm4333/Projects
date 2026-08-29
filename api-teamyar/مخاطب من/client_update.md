# ویرایش اطلاعات مشتری

## آدرس

```
/api/client/update
```

## درخواست

```json
{
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
    "large_photo": {
      "size": 0,
      "filename": "",
      "filepath": "",
      "mime_type": "",
      "data_base64": "",
      "src_module_id": 0
    },
    "nationality": "",
    "passport_no": "",
    "small_photo": {
      "size": 0,
      "filename": "",
      "filepath": "",
      "mime_type": "",
      "data_base64": "",
      "src_module_id": 0
    },
    "date_of_issue": 0,
    "deleted_email": [
      0
    ],
    "deleted_phone": [
      0
    ],
    "national_code": [
      {
        "id": 0,
        "value": "",
        "country": 0
      }
    ],
    "deleted_mobile": [
      0
    ],
    "place_of_issue": "",
    "identity_serial_no": "",
    "deleted_national_code": [
      0
    ]
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
  "custom_form": {
    "data": "",
    "section_id": 0
  },
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
  "deleted_card": [
    0
  ],
  "property_code": "",
  "property_date": 0,
  "issue_activity": "",
  "deleted_account": [
    0
  ],
  "deleted_address": [
    0
  ],
  "classify_persons": [
    0
  ],
  "number_personnel": 0,
  "personality_type": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) | شناسه مشتری |
| `job` | string | شغل (مشتری حقیقی) |
| `kpp` | string | شماره پاسپورت (مشتری حقیقی)کد ملی مدیر عامل (مشتری حقوقی) |
| `tin` | string | کد اقتصادی |
| `date` | integer (int64) | تاریخ |
| `label` | string | برچسب |
| `domain` | string | دامنه |
| `account` | string | مدیر عامل |
| `address[]` | array | لیست آدرس ها در ماژول مشتری |
| `address[].id` | integer (int64) | شناسه |
| `address[].fax` | string | فکس |
| `address[].city` | string | شهر |
| `address[].title` | string | عنوان آدرس |
| `address[].address` | string | آدرس |
| `address[].comment` | string | توضیحات |
| `address[].country` | integer (int32) | کد کشور |
| `address[].latitude` | number (double) | عرض جغرافیایی |
| `address[].province` | string | استان |
| `address[].longitude` | number (double) | طول جغرافیایی |
| `address[].home_phone` | string | تلفن منزل |
| `address[].work_phone` | string | تلفن محل کار |
| `address[].postal_code` | string | کدپستی |
| `address[].mobile_phone` | string | تلفن همراه |
| `comment` | string | توضیحات |
| `company` | string | شرکت (مشتری حقیقی) |
| `contact[]` | array | لیست رابط ها |
| `contact[].type` | integer (int32) | نوع رابطCONTACT_TYPE_CRM =1 (مشتری تیمیار باشد، به صورت دو طرفه ثبت می شود)CONTACT_TYPE_TEXT =2 (مشتری تیمیار نباشد)CONTACT_TYPE_REFERER =3 (مشتری تیمیار. برای ثبت معرف از این نوع استفاده می شود. به صورت یک طرفه) |
| `contact[].contact_id` | integer (int64) | شناسه ی رابط (شناسه مشتری) |
| `contact[].force_sign` | integer (int32) | استفاده نشده |
| `contact[].contact_text` | string | عنوان رابط برای رابطینی که مشتری تیم یار نیستند |
| `contact[].login_portal[]` | array | استفاده نشده |
| `contact[].contact_phone` | string | شماره تماس |
| `contact[].along_with_sign` | integer (int32) | استفاده نشده |
| `contact[].contact_comment` | string | توضیحات |
| `contact[].contact_position` | string | سمت |
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
| `profile.phone[].country` | integer (int32) | کد کشور |
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
| `profile.user_type` | integer (int32) | نوع کاربرenum EnUserTypes { |
| `profile.birth_date` | integer (date) | تاریخ تولد |
| `profile.patronymic` | string | نام پدر |
| `profile.birth_place` | string | محل تولد |
| `profile.identity_no` | string | شماره شناسنامه |
| `profile.large_photo` | object |  |
| `profile.large_photo.size` | integer (int64) |  |
| `profile.large_photo.filename` | string |  |
| `profile.large_photo.filepath` | string |  |
| `profile.large_photo.mime_type` | string |  |
| `profile.large_photo.data_base64` | string |  |
| `profile.large_photo.src_module_id` | integer (int32) |  |
| `profile.nationality` | string | ملیت |
| `profile.passport_no` | string | شماره گذرنامه |
| `profile.small_photo` | object |  |
| `profile.small_photo.size` | integer (int64) |  |
| `profile.small_photo.filename` | string |  |
| `profile.small_photo.filepath` | string |  |
| `profile.small_photo.mime_type` | string |  |
| `profile.small_photo.data_base64` | string |  |
| `profile.small_photo.src_module_id` | integer (int32) |  |
| `profile.date_of_issue` | integer (date) | تاریخ صدور شناسنامه |
| `profile.deleted_email[]` | array | لیست شناسه ایمیل برای حذف |
| `profile.deleted_phone[]` | array | لیست شناسه تلفن برای حذف |
| `profile.national_code[]` | array | لیست کد ملی |
| `profile.national_code[].id` | integer (int64) | شناسه کد ملی |
| `profile.national_code[].value` | string | کد ملی |
| `profile.national_code[].country` | integer (int32) | کد کشور |
| `profile.deleted_mobile[]` | array | لیست شناسه موبایل برای حذف |
| `profile.place_of_issue` | string | محل صدور شناسنامه |
| `profile.identity_serial_no` | string | سریال شناسنامه |
| `profile.deleted_national_code[]` | array | لیست شناسه کد ملی برای حذف |
| `station` | string | محل ثبت (مشتری حقوقی) |
| `website` | string | وب سایت |
| `industry` | integer (int32) | پیشه (مشتری حقوقی) |
| `language` | string | زبان (مشتری حقیقی) |
| `card_info[]` | array | لیست کارت ها اعتبازی |
| `card_info[].id` | integer (int64) | شناسه |
| `card_info[].iban` | string |  |
| `card_info[].comment` | string | توضیحات |
| `card_info[].currency` | object | نوع ارز - شناسه از جدول crm_setting |
| `card_info[].currency.id` | integer (int64) | شناسه ارز |
| `card_info[].currency.org_id` | integer (int64) | شناسه شعبه |
| `card_info[].bank_name` | string | نام بانک |
| `card_info[].card_type` | integer (int32) | نوع کارت - شناسه از جدول crm_setting با type 14 |
| `card_info[].card_holder` | string | صاحب کارت |
| `card_info[].card_number` | string | شماره کارت |
| `card_info[].expiry_date` | integer (int64) | تاریخ انقضا |
| `card_info[].deposit_type` | integer (int32) | نوع سپرده |
| `card_info[].security_code` | string | کد امنیتی |
| `city_code` | object | کد شهر |
| `city_code.id` | string | کد شهر |
| `city_code.name` | string | نام شهر |
| `import_id` | integer (int64) | شناسه ایمپورت مشتری |
| `time_zone` | integer (int64) | شناسه منطقه زمانی |
| `reg_number` | string | شماره ثبت (مشتری حقوقی) |
| `state_code` | object | کد استان |
| `state_code.id` | string | کد استان |
| `state_code.name` | string | نام استان |
| `create_date` | integer (date) | زمان به وجود آمدن مشتری |
| `custom_form` | object | اطلاعات فرم سفارشی بخش |
| `custom_form.data` | string | اطلاعات فرم سفارسی به صورت json string |
| `custom_form.section_id` | integer (int64) | شناسه بخش |
| `account_info[]` | array | لیست اطلاعات حساب ها |
| `account_info[].id` | integer (int64) | شناسه |
| `account_info[].city` | string | شهر |
| `account_info[].iban` | string | آی بن |
| `account_info[].shaba` | string | شناسه شبا |
| `account_info[].state` | string | استان |
| `account_info[].branch` | string | شعبه |
| `account_info[].comment` | string | توضیحات |
| `account_info[].country` | integer (int32) | کد کشور |
| `account_info[].fedwire` | string | فد وایر |
| `account_info[].routing` | string | روتینگ |
| `account_info[].currency` | object | نوع ارز |
| `account_info[].currency.id` | integer (int64) | شناسه ارز |
| `account_info[].currency.org_id` | integer (int64) | شناسه شعبه |
| `account_info[].bank_name` | string | نام بانک |
| `account_info[].swift_code` | string | کد سوئیفت |
| `account_info[].bank_address` | string | آدرس بانک |
| `account_info[].account_number` | string | شماره حساب |
| `custom_field[]` | array | فیلد های سفارشی |
| `custom_field[].id` | integer (int32) | شناسه فیلد |
| `custom_field[].value` | string | مقدار فیلد |
| `deleted_card[]` | array | لیست شناسه کارت برای حذف |
| `property_code` | string | شماره پروانه کسب |
| `property_date` | integer (int64) | تاریخ ثبت (مشتری حقوقی) |
| `issue_activity` | string | موضوع/حوزه فعالیت |
| `deleted_account[]` | array | لیست شناسه حساب برای حذف |
| `deleted_address[]` | array | لیست شناسه آدرس برای حذف |
| `classify_persons[]` | array | رده های مشتری |
| `number_personnel` | integer (int64) | تعداد پرسنل |
| `personality_type` | integer (int32) | نوع شخصیت حقوقی (مشتری حقوقی) |

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
