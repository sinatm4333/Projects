# دریافت سرپرست مربوط به کاربر در یک شعبه

دریافت اطلاعات سرپرست تعیین شده در حکم فعال مربوط به کاربر در شعبه مربوطه برای زمان حاضر

## آدرس

```
/api/hr/profileSupervisorGet
```

## درخواست

```json
{
  "org_id": 0,
  "profile_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `org_id` | integer (int64) | شعبه مورد درخواست |
| `profile_id` | integer (int64) | پروفایل مورد درخواست |

## پاسخ

```json
{
  "data": {
    "id": 0,
    "name": ""
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
| `data.id` | integer (int64) | شناسه سرپرست |
| `data.name` | string | نام سرپرست |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
