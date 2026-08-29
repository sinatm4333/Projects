# اضافه کردن رابط به مشتری

## آدرس

```
/api/client/contact/add
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
