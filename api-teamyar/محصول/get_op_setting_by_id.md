# اضافه شدن تنظیمات opc

با این api،تنظیمات مربوط به opc ست می شود

## آدرس

```
/api/get_op_setting_by_id
```

## درخواست

```json
{
  "id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) | شناسه |

## پاسخ

```json
{
  "data": {
    "id": 0,
    "title": "",
    "org_id": 0,
    "unit_id": 0,
    "unit_name": "",
    "decimal_num": 0
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
| `data.id` | integer (int64) | شناسه |
| `data.title` | string | عنوان |
| `data.org_id` | integer (int64) | شناسه شعبه |
| `data.unit_id` | integer (int64) | شناسه واحد |
| `data.unit_name` | string | نام واحد |
| `data.decimal_num` | integer (int32) | عدد اعشاری |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
