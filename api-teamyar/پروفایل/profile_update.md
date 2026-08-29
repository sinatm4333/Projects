# آپدیت پروفایل

بروزرسانی اطلاعات پروفایل

## آدرس

```
/api/profile/update
```

## درخواست

```json
{
  "id": 0,
  "name": "",
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
  "photo_id": 0,
  "folder_id": 0,
  "user_type": 0,
  "birthplace": "",
  "manager_id": 0,
  "patronymic": "",
  "public_key": "",
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
  "signature_id": 0,
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
      "branch_code": 0,
      "country_code": 0,
      "national_code": ""
    }
  ],
  "deleted_mobile": [
    0
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
  "change_password_time": 0,
  "deleted_national_code": [
    0
  ],
  "deleted_social_network": [
    0
  ]
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) | شناسه پروفایل |
| `name` | string | نام |
| `email[]` | array | لیست ایمیل ها |
| `email[].id` | integer (int64) | شناسه ایمیل |
| `email[].email` | string | ایمیل |
| `email[].verified` | integer (int32) | ایمیل تایید شده |
| `phone[]` | array | لیست تلفن ها |
| `phone[].id` | integer (int64) | شناسه تلفن |
| `phone[].type` | integer (int32) | نوع شماره PHONE_TYPE_HOME = 2, PHONE_TYPE_WORK = 3, PHONE_TYPE_FAX = 4 |
| `phone[].phone` | string | شماره تلفن |
| `phone[].extensions` | string | شماره داخلی |
| `phone[].country_code` | integer (int32) | کد کشور |
| `gender` | integer (int32) | جنسیت |
| `mobile[]` | array | لیست شماره موبایل |
| `mobile[].id` | integer (int64) | شناسه شماره موبایل |
| `mobile[].mobile` | string | شماره موبایل |
| `mobile[].country_code` | integer (int32) | کد کشور |
| `status` | integer (int32) | وضعیت فعال و غیر فعال بودن |
| `address` | object | آدرس ها |
| `address.home` | object | آدرس خانه |
| `address.home.x` | number (double) | عرض جغرافیایی |
| `address.home.y` | number (double) | طول جغرافیایی |
| `address.home.city` | string | شهر |
| `address.home.state` | string | استان |
| `address.home.address` | string | آدرس |
| `address.home.postal_code` | string | کد پستی |
| `address.home.country_code` | integer (int32) | کد کشور |
| `address.work` | object | آدرس محل کار |
| `address.work.x` | number (double) | عرض جغرافیایی |
| `address.work.y` | number (double) | طول جغرافیایی |
| `address.work.city` | string | شهر |
| `address.work.state` | string | استان |
| `address.work.address` | string | آدرس |
| `address.work.postal_code` | string | کد پستی |
| `address.work.country_code` | integer (int32) | کد کشور |
| `is_role` | integer (int32) | نقش |
| `surname` | string | نام خانوادگی |
| `birthday` | integer (date) | تاریخ تولد |
| `photo_id` | integer (int64) | شناسه تصویر |
| `folder_id` | integer (int64) | شناسه پوشه |
| `user_type` | integer (int32) | نوع کاربر3 = حقیقی4 = حقوقی |
| `birthplace` | string | محل تولد |
| `manager_id` | integer (int64) |  |
| `patronymic` | string | نام پدر |
| `public_key` | string | کلید عمومی |
| `identity_no` | string | شماره شناسنامه |
| `large_photo` | object | اطلاعات فایل برای آپدیت تصویر بزرگاین اطلاعات در بات از تابع teamyar.get_file بدست می آید |
| `large_photo.size` | integer (int64) | سایز فایل |
| `large_photo.filename` | string | نام فایل |
| `large_photo.filepath` | string | مسیر فایل |
| `large_photo.mime_type` | string | نوع فایل |
| `large_photo.data_base64` | string | اطلاعات فایل به صورت کد شده |
| `large_photo.src_module_id` | integer (int32) | شناسه ماژول که فایل در آن آپلود شده |
| `nationality` | string | ملیت |
| `passport_no` | string | شماره پاسپورت |
| `small_photo` | object | اطلاعات فایل برای آپدیت تصویر کوچکاین اطلاعات در بات از تابع teamyar.get_file بدست می آید |
| `small_photo.size` | integer (int64) | سایز فایل |
| `small_photo.filename` | string | نام فایل |
| `small_photo.filepath` | string | مسیر فایل |
| `small_photo.mime_type` | string | نوع فایل |
| `small_photo.data_base64` | string | اطلاعات فایل به صورت کد شده |
| `small_photo.src_module_id` | integer (int32) | شناسه فایل که در آن آپلود شده |
| `signature_id` | integer (int64) | شناسه امضا |
| `date_of_issue` | integer (int64) | تاریخ صدور شناسنامه |
| `deleted_email[]` | array | لیست شناسه های ایمیل برای حذف |
| `deleted_phone[]` | array | لیست شناسه های تلفن برای خذف |
| `national_code[]` | array | لیست کد ملی |
| `national_code[].id` | integer (int64) | شناسه کد ملی |
| `national_code[].branch_code` | integer (int32) |  |
| `national_code[].country_code` | integer (int32) | کد کشور |
| `national_code[].national_code` | string | کد ملی |
| `deleted_mobile[]` | array | لیست شناسه های شماره موبایل برای حذف |
| `place_of_issue` | string | محل صدور شناسنامه |
| `small_photo_id` | integer (int64) | شناسه تصویر پروفایل با سایز کوچک |
| `social_network[]` | array | لیست حساب ها در شبکه های اجتماعی |
| `social_network[].id` | integer (int64) | شناسه حساب |
| `social_network[].type` | integer (int32) | نوع شبکه اجتماعی SOCIALNETWORK_TYPE_WEBSITE = 1, SOCIALNETWORK_TYPE_WHATSAPP = 2, SOCIALNETWORK_TYPE_LINKEDIN = 3, SOCIALNETWORK_TYPE_INSTAGRAM = 4, SOCIALNETWORK_TYPE_TELEGRAM = 5, SOCIALNETWORK_TYPE_SKYPE = 6, SOCIALNETWORK_TYPE_YAHOO = 7, SOCIALNETWORK_TYPE_TWITTER = 8 |
| `social_network[].value` | string | حساب |
| `identity_serial_no` | string | شماره سریال شناسنامه |
| `last_modified_photo` | string |  |
| `change_password_time` | integer (int64) |  |
| `deleted_national_code[]` | array | لیست شناسه کد ملی برای حذف |
| `deleted_social_network[]` | array | لیست شناسه حساب شبکه اجتماعی برای حذف |

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
