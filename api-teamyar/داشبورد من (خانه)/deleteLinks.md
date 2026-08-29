# حذف لینک تیمیاری

## آدرس

```
/api/deleteLinks
```

## درخواست

```json
{
  "type*": 0,
  "link_id*": 0,
  "db_prefix": "",
  "module_id*": 0,
  "is_archive": false
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `type*` | integer (int32) | نوع |
| `link_id*` | integer (int64) | شناسه لینک شده |
| `db_prefix` | string | پیشوند جدول ماژول |
| `module_id*` | integer (int32) | شناسه ماژول برای حذف لینک |
| `is_archive` | boolean | مقدار true در صورت حذف از آرشیو.در این حالت باید پارامتر db_prefix مقدار دهی شود |

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
