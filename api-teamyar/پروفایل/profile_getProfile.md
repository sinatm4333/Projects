# دریافت اطلاعات پروفایل

دریافت اطلاعات کامل یک پروفایل.

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
| `id` | number | شناسه پروفایل |
| `type` | number | نوع |
| `module_id` | number | شناسه ماژول |

## پاسخ

```json
{
  "data": {
    "id": 0,
    "name": "",
    "type": 0,
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
    "national_code": [{ "id": 0, "branch_code": 0, "country_code": 0, "national_code": "" }],
    "place_of_issue": "",
    "small_photo_id": 0,
    "social_network": [{ "id": 0, "type": 0, "value": "" }],
    "identity_serial_no": "",
    "last_modified_photo": "",
    "change_password_time": 0
  },
  "error": { "status": 0, "message": "" },
  "success": 0
}
```

### اطلاعات هویتی

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data.id` | number | شناسه پروفایل |
| `data.name` | string | نام |
| `data.surname` | string | نام خانوادگی |
| `data.patronymic` | string | نام پدر |
| `data.fullname` | string | نام کامل |
| `data.gender` | number | جنسیت |
| `data.birthday` | number | تاریخ تولد |
| `data.birthplace` | string | محل تولد |
| `data.nationality` | string | ملیت |

### وضعیت و نوع

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data.type` | number | نوع |
| `data.user_type` | number | نوع کاربر |
| `data.status` | number | وضعیت |
| `data.is_role` | number | نقش بودن |
| `data.folder_id` | number | شناسه پوشه |
| `data.manager_id` | number | شناسه مدیر |
| `data.master_module` | number | ماژول اصلی |

### راه‌های ارتباطی

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data.email[]` | array | ایمیل‌ها — `id`، `email`، `verified` |
| `data.phone[]` | array | تلفن‌ها — `id`، `type`، `phone`، `extensions`، `country_code` |
| `data.mobile[]` | array | موبایل‌ها — `id`، `mobile`، `country_code` |
| `data.social_network[]` | array | شبکه‌های اجتماعی — `id`، `type`، `value` |

### آدرس

`data.address` شامل دو کلید `home` (منزل) و `work` (محل کار) با ساختار یکسان:

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
| `data.identity_no` | string | شماره شناسنامه |
| `data.identity_serial_no` | string | سریال شناسنامه |
| `data.date_of_issue` | number | تاریخ صدور |
| `data.place_of_issue` | string | محل صدور |
| `data.passport_no` | string | شماره گذرنامه |
| `data.national_code[]` | array | کد ملی — `id`، `national_code`، `branch_code`، `country_code` |

### تصویر و امضا

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data.photo_id` | number | شناسه تصویر |
| `data.small_photo_id` | number | شناسه تصویر کوچک |
| `data.last_modified_photo` | string | آخرین تغییر تصویر |
| `data.signature_id` | number | شناسه امضا |

### سایر

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data.public_key` | string | کلید عمومی |
| `data.change_password_time` | number | زمان تغییر رمز عبور |
| `error.status` | number | کد خطا |
| `error.message` | string | پیام خطا |
| `success` | number | نتیجه اجرا |

## مرتبط

- [دریافت پروفایل‌ها](profile_getInfo.md) — اطلاعات خلاصه برای فهرستی از شناسه‌ها.
