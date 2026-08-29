# دریافت اطلاعات پروفایل

دریافت اطلاعات کامل پروفایل یک کاربر

## آدرس

```
/api/profile/getProfile
```

## درخواست

```json
{
  "id": 0,
  "type": 0,
  "module_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) | شناسه پروفایل |
| `type` | integer (int32) | نوع پروفایل1=کاربر 2=گروه |
| `module_id` | integer (int32) | شناسه ماژول |

## پاسخ

```json
{
  "data": {
    "id": 0,
    "name": "",
    "type": 0,
    "email": [
      {
        "id": 0,
        "email": "",
        "verified": 0
      }
    ],
    "phone": [
      {
        "id": 0,
        "type": 0,
        "phone": "",
        "extensions": "",
        "country_code": 0
      }
    ],
    "gender": 0,
    "mobile": [
      {
        "id": 0,
        "mobile": "",
        "country_code": 0
      }
    ],
    "status": 0,
    "address": {
      "home": {
        "x": 0,
        "y": 0,
        "city": "",
        "state": "",
        "address": "",
        "postal_code": "",
        "country_code": 0
      },
      "work": {
        "x": 0,
        "y": 0,
        "city": "",
        "state": "",
        "address": "",
        "postal_code": "",
        "country_code": 0
      }
    },
    "is_role": 0,
    "surname": "",
    "birthday": 0,
    "fullname": "",
    "photo_id": 0,
    "folder_id": 0,
    "user_type": 0,
    "birthplace": "",
    "manager_id": 0,
    "patronymic": "",
    "public_key": "",
    "identity_no": "",
    "nationality": "",
    "passport_no": "",
    "signature_id": 0,
    "date_of_issue": 0,
    "master_module": 0,
    "national_code": [
      {
        "id": 0,
        "branch_code": 0,
        "country_code": 0,
        "national_code": ""
      }
    ],
    "place_of_issue": "",
    "small_photo_id": 0,
    "social_network": [
      {
        "id": 0,
        "type": 0,
        "value": ""
      }
    ],
    "identity_serial_no": "",
    "last_modified_photo": "",
    "change_password_time": 0
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
| `data.id` | integer (int64) | شناسه پروفایل |
| `data.name` | string | نام |
| `data.type` | integer (int32) | نوع پروفایل |
| `data.email[]` | array | لیست ایمیل ها |
| `data.email[].id` | integer (int64) | شناسه ایمیل |
| `data.email[].email` | string | ایمیل |
| `data.email[].verified` | integer (int32) | نشان میدهد ایمیل به تایید شده است یا خیر |
| `data.phone[]` | array | لیست شماره تلفن ها |
| `data.phone[].id` | integer (int64) | شناسه شماره تلفن |
| `data.phone[].type` | integer (int32) | نوع شماره PHONE_TYPE_HOME = 2, PHONE_TYPE_WORK = 3, PHONE_TYPE_FAX = 4 |
| `data.phone[].phone` | string | شماره تلفن |
| `data.phone[].extensions` | string | داخلی |
| `data.phone[].country_code` | integer (int32) | کد کشور |
| `data.gender` | integer (int32) | جنسیت |
| `data.mobile[]` | array | لیست شماره موبایل |
| `data.mobile[].id` | integer (int64) | شناسه شماره موبایل |
| `data.mobile[].mobile` | string | شماره موبایل |
| `data.mobile[].country_code` | integer (int32) | کد کشور |
| `data.status` | integer (int32) | وضعیت پروفایل در ماژول(module_id در ورودی ارسال شده) |
| `data.address` | object | آدرس ها |
| `data.address.home` | object | آدرس منزل |
| `data.address.home.x` | number (double) | عرض جغرافیایی |
| `data.address.home.y` | number (double) | طول جغرافیایی |
| `data.address.home.city` | string | شهر |
| `data.address.home.state` | string | استان |
| `data.address.home.address` | string | آدرس |
| `data.address.home.postal_code` | string | کد پستی |
| `data.address.home.country_code` | integer (int32) | کد کشور |
| `data.address.work` | object | آدرس محل کار |
| `data.address.work.x` | number (double) | عرض جغرافیایی |
| `data.address.work.y` | number (double) | طول جغرافیایی |
| `data.address.work.city` | string | شهر |
| `data.address.work.state` | string | استان |
| `data.address.work.address` | string | آدرس |
| `data.address.work.postal_code` | string | کد پستی |
| `data.address.work.country_code` | integer (int32) | کد کشور |
| `data.is_role` | integer (int32) | نقش |
| `data.surname` | string | نام خانوادگی |
| `data.birthday` | integer (date) | تاریخ تولد |
| `data.fullname` | string | نام کامل |
| `data.photo_id` | integer (int64) | شناسه تصویر پروفایل |
| `data.folder_id` | integer (int64) | شناسه پوشه پروفایل |
| `data.user_type` | integer (int32) | نوع کاربر3 = حقیقی4 = حقوقی |
| `data.birthplace` | string | محل تولد |
| `data.manager_id` | integer (int64) |  |
| `data.patronymic` | string | نام پدر |
| `data.public_key` | string | کلید عمومی |
| `data.identity_no` | string | شماره شناسنامه |
| `data.nationality` | string | ملیت |
| `data.passport_no` | string | شماره پاسپورت |
| `data.signature_id` | integer (int64) | شناسه امضا |
| `data.date_of_issue` | integer (int64) | تاریخ صدور شناسنامه |
| `data.master_module` | integer (int64) | ماژول ایجاد کننده پروفایل |
| `data.national_code[]` | array | کد ملی |
| `data.national_code[].id` | integer (int64) | شناسه کد ملی |
| `data.national_code[].branch_code` | integer (int32) |  |
| `data.national_code[].country_code` | integer (int32) | کد کشور |
| `data.national_code[].national_code` | string | کد ملی |
| `data.place_of_issue` | string | محل صدور شناسنامه |
| `data.small_photo_id` | integer (int64) | شناسه تصویر پروفایل (سایز کوچک) |
| `data.social_network[]` | array | لیست حساب شبکه های اجتماعی |
| `data.social_network[].id` | integer (int64) | شناسه |
| `data.social_network[].type` | integer (int32) | نوع شبکه اجتماعی SOCIALNETWORK_TYPE_WEBSITE = 1, SOCIALNETWORK_TYPE_WHATSAPP = 2, SOCIALNETWORK_TYPE_LINKEDIN = 3, SOCIALNETWORK_TYPE_INSTAGRAM = 4, SOCIALNETWORK_TYPE_TELEGRAM = 5, SOCIALNETWORK_TYPE_SKYPE = 6, SOCIALNETWORK_TYPE_YAHOO = 7, SOCIALNETWORK_TYPE_TWITTER = 8 |
| `data.social_network[].value` | string | حساب شبکه اجتماعی |
| `data.identity_serial_no` | string | سریال شناسنامه |
| `data.last_modified_photo` | string | زمان ویرایش تصویر |
| `data.change_password_time` | integer (int64) | زمان تغییر پسورد |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
