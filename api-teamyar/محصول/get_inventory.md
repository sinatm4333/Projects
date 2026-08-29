# امکان ایجاد تاریخ تولید کالا برای ویژگی

با این Api،ایجاد تاریخ تولید کالا برای ویژگی می توان ایجاد کرد.

## آدرس

```
/api/get_inventory
```

## درخواست

```json
{
  "org_id": 0,
  "end_date": 0,
  "stock_id": 0,
  "product_id": 0,
  "start_date": 0,
  "attribute_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `org_id` | integer (int64) | شناسه سازمان از ماژول حسابداری تنظیمات منوی شعبه (جدول ORG_INFO) |
| `end_date` | integer (int64) | تاریخ پایان |
| `stock_id` | integer (int64) | کد انبار |
| `product_id` | integer (int64) | کد کالا |
| `start_date` | integer (int64) | تاریخ شروع |
| `attribute_id` | integer (int64) | شناسه ویژگی |

## پاسخ

```json
{
  "data": {
    "remained": "",
    "unit_name": ""
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
| `data` | object | دیتا |
| `data.remained` | string | باقی مانده |
| `data.unit_name` | string | نام واحد |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
