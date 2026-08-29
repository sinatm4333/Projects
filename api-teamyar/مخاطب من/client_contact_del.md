# حذف کردن رابط از مشتری

## آدرس

```
/api/client/contact/del
```

## درخواست

```json
{
  "id": 0,
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
  ]
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) | شناسه مشتری |
| `contact[]` | array | رابط ها |
| `contact[].type` | integer (int32) | نوع رابطCONTACT_TYPE_CRM =1 (مشتری تیمیار باشد، به صورت دو طرفه ثبت می شود)CONTACT_TYPE_TEXT =2 (مشتری تیمیار نباشد)CONTACT_TYPE_REFERER =3 (مشتری تیمیار. برای ثبت معرف از این نوع استفاده می شود. به صورت یک طرفه) |
| `contact[].contact_id` | integer (int64) | شناسه ی رابط |
| `contact[].force_sign` | integer (int32) | در این درخواست استفاده ندارد |
| `contact[].contact_text` | string | عنوان رابط برای رابطینی که مشتری تیم یار نیستند |
| `contact[].login_portal[]` | array | در این درخواست استفاده ندارد |
| `contact[].contact_phone` | string | در این درخواست استفاده ندارد |
| `contact[].along_with_sign` | integer (int32) | در این درخواست استفاده ندارد |
| `contact[].contact_comment` | string | در این درخواست استفاده ندارد |
| `contact[].contact_position` | string | در این درخواست استفاده ندارد |

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
