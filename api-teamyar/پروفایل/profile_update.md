# آپدیت پروفایل

به‌روزرسانی اطلاعات یک پروفایل.

## آدرس

```
/api/profile/update
```

## درخواست

```json
{
  "id": 0,
  "name": "",
  "email": [{ "id": 0, "email": "", "verified": 0 }],
  "phone": [{ "id": 0, "type": 0, "phone": "", "extensions": "", "country_code": 0 }],
  "gender": 0,
  "mobile": [{ "id": 0, "mobile": "", "country_code": 0 }],
  "status": 0,
  "address": {
    "home": { "x": 0, "y": 0, "city": "", "state": "", "address": "", "postal_code": "", "country_code": 0 },
    "work": { "x": 0, "y": 0, "city": "", "state": "", "address": "", "postal_code": "", "country_code": 0 }
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
  "large_photo": { "size": 0, "filename": "", "filepath": "", "mime_type": "", "data_base64": "", "src_module_id": 0 },
  "nationality": "",
  "passport_no": "",
  "small_photo": { "size": 0, "filename": "", "filepath": "", "mime_type": "", "data_base64": "", "src_module_id": 0 },
  "signature_id": 0,
  "date_of_issue": 0,
  "deleted_email": [0],
  "deleted_phone": [0],
  "national_code": [{ "id": 0, "branch_code": 0, "country_code": 0, "national_code": "" }],
  "deleted_mobile": [0],
  "place_of_issue": "",
  "small_photo_id": 0,
  "social_network": [{ "id": 0, "type": 0, "value": "" }],
  "identity_serial_no": "",
  "last_modified_photo": "",
  "change_password_time": 0,
  "deleted_national_code": [0],
  "deleted_social_network": [0]
}
```

### اطلاعات هویتی

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | number | شناسه پروفایل |
| `name` | string | نام |
| `surname` | string | نام خانوادگی |
| `patronymic` | string | نام پدر |
| `gender` | number | جنسیت |
| `birthday` | number | تاریخ تولد |
| `birthplace` | string | محل تولد |
| `nationality` | string | ملیت |

### وضعیت و نوع

| فیلد | نوع | توضیح |
|------|-----|-------|
| `user_type` | number | نوع کاربر |
| `status` | number | وضعیت |
| `is_role` | number | نقش بودن |
| `folder_id` | number | شناسه پوشه |
| `manager_id` | number | شناسه مدیر |

### راه‌های ارتباطی

| فیلد | نوع | توضیح |
|------|-----|-------|
| `email[]` | array | ایمیل‌ها — `id`، `email`، `verified` |
| `phone[]` | array | تلفن‌ها — `id`، `type`، `phone`، `extensions`، `country_code` |
| `mobile[]` | array | موبایل‌ها — `id`، `mobile`، `country_code` |
| `social_network[]` | array | شبکه‌های اجتماعی — `id`، `type`، `value` |

### آدرس

`address` شامل دو کلید `home` (منزل) و `work` (محل کار) با ساختار یکسان:

| فیلد | نوع | توضیح |
|------|-----|-------|
| `address` | string | نشانی |
| `city` | string | شهر |
| `state` | string | استان |
| `postal_code` | string | کد پستی |
| `country_code` | number | کد کشور |
| `x` | number | مختصات جغرافیایی |
| `y` | number | مختصات جغرافیایی |

### مدارک

| فیلد | نوع | توضیح |
|------|-----|-------|
| `identity_no` | string | شماره شناسنامه |
| `identity_serial_no` | string | سریال شناسنامه |
| `date_of_issue` | number | تاریخ صدور |
| `place_of_issue` | string | محل صدور |
| `passport_no` | string | شماره گذرنامه |
| `national_code[]` | array | کد ملی — `id`، `national_code`، `branch_code`، `country_code` |

### تصویر و امضا

| فیلد | نوع | توضیح |
|------|-----|-------|
| `photo_id` | number | شناسه تصویر |
| `small_photo_id` | number | شناسه تصویر کوچک |
| `last_modified_photo` | string | آخرین تغییر تصویر |
| `signature_id` | number | شناسه امضا |
| `large_photo` | object | آپلود تصویر بزرگ (ساختار زیر) |
| `small_photo` | object | آپلود تصویر کوچک (ساختار زیر) |

`large_photo` و `small_photo` ساختار یکسان دارند:

| فیلد | نوع | توضیح |
|------|-----|-------|
| `filename` | string | نام فایل |
| `filepath` | string | مسیر فایل |
| `mime_type` | string | نوع MIME |
| `data_base64` | string | محتوای فایل به‌صورت base64 |
| `size` | number | حجم فایل |
| `src_module_id` | number | شناسه ماژول مبدأ |

### حذف آیتم‌ها

آرایه‌هایی از شناسه‌ها که باید حذف شوند:

| فیلد | نوع | توضیح |
|------|-----|-------|
| `deleted_email` | array\<number\> | شناسه ایمیل‌های حذف‌شده |
| `deleted_phone` | array\<number\> | شناسه تلفن‌های حذف‌شده |
| `deleted_mobile` | array\<number\> | شناسه موبایل‌های حذف‌شده |
| `deleted_national_code` | array\<number\> | شناسه کدهای ملی حذف‌شده |
| `deleted_social_network` | array\<number\> | شناسه شبکه‌های اجتماعی حذف‌شده |

### سایر

| فیلد | نوع | توضیح |
|------|-----|-------|
| `public_key` | string | کلید عمومی |
| `change_password_time` | number | زمان تغییر رمز عبور |

## پاسخ

```json
{
  "error": { "status": 0, "message": "" },
  "success": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `error.status` | number | کد خطا |
| `error.message` | string | پیام خطا |
| `success` | number | نتیجه اجرا |

## مرتبط

- [دریافت اطلاعات پروفایل](profile_getProfile.md) — همان فیلدها در خروجی.
