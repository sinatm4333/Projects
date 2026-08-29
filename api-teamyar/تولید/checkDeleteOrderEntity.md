# حذف دستور

بررسی حذف دستور تولید با شناسه سند

## آدرس

```
/api/checkDeleteOrderEntity
```

## درخواست

```json
{
  "entity_id": 0,
  "prod_entity_type": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `entity_id` | integer (int64) | شناسه سند |
| `prod_entity_type` | integer (int32) | نوع سند مبنا1 سفارش فروش2 فاکتور فروش3 برنامه ریزی4 برآورد |

## پاسخ

```json
{
  "data": {
    "err": "",
    "is_used": false
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
| `data` | object | آبجکت اصلی |
| `data.err` | string | خطا |
| `data.is_used` | boolean | استفاده میشود |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | وضعیت:پیشنویسبررسیانجامکاملباطل |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
