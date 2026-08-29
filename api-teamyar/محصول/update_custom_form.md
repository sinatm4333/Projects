# تغییر api opc برای شعبه

اعمال تغییرات ، اطلاعات کاستوم فرم نیز در API در opc

## آدرس

```
/api/update_custom_form
```

## درخواست

```json
{
  "data": "",
  "type": 0,
  "org_id": 0,
  "entity_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data` | string | دیتا |
| `type` | integer (int32) | نوع عملیات |
| `org_id` | integer (int64) | شناسه شعبه |
| `entity_id` | integer (int64) | شناسه انبار، کالا، درخواست کالا، رسید، حواله، مجوز خروج |

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
