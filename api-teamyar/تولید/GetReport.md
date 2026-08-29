# ثبت عملکرد

ایجاد ثبت عملکرد

## آدرس

```
/api/GetReport
```

## درخواست

```json
{
  "id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) | شناسه سیستمی |

## پاسخ

```json
{
  "data": {
    "id": 0,
    "code": 0,
    "title": "",
    "bom_id": 0,
    "org_id": 0,
    "status": 0,
    "duration": 0,
    "quantity": 0,
    "author_id": 0,
    "folder_id": 0,
    "deficit_id": 0,
    "project_id": 0,
    "reciept_id": 0,
    "surplus_id": 0,
    "bench_stock": 0,
    "description": "",
    "transfer_id": 0,
    "operation_id": 0,
    "prod_line_id": 0,
    "receipt_date": 0,
    "creation_date": 0,
    "prod_order_id": 0,
    "expense_center": 0,
    "operation_date": 0,
    "work_center_id": 0,
    "direct_overhead": 0,
    "half_made_stock": 0,
    "line_product_id": 0,
    "transference_id": 0,
    "unmatched_stock": 0,
    "indirect_overhead": 0,
    "material_waste_id": 0,
    "modification_date": 0,
    "transference_date": 0,
    "unmatched_quantity": 0,
    "modification_user_id": 0,
    "unmatched_receipt_id": 0
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
| `data.id` | integer (int64) | شناسه اصلی (سیستمی) |
| `data.code` | integer (int64) | شناسه، چیزی که کاربر هم میتواند ویرایش کند |
| `data.title` | string | عنوان |
| `data.bom_id` | integer (int64) | شناسه BOM از جدول "wh_bom_main" |
| `data.org_id` | integer (int64) | شناسه سازمان |
| `data.status` | integer (int32) | وضیعت عمیلیات:0: پیشنویس1: بررسی2: انجامکاملباطللغو شده |
| `data.duration` | integer (int64) | مدت زمان انجام ثبت عملکرد |
| `data.quantity` | integer (int64) | مقدار |
| `data.author_id` | integer (int64) | شناسه ایجاد کننده |
| `data.folder_id` | integer (int64) | ذخیره تصاویر مربوط به کامنت ها |
| `data.deficit_id` | integer (int64) | شناسه عملیات کسر مصرف(از جدول "wh_operation") |
| `data.project_id` | integer (int64) | شناسه حساب پروژه |
| `data.reciept_id` | integer (int64) | شناسه عملیات رسید (از جدول "wh_operation") |
| `data.surplus_id` | integer (int64) | شناسه عملیات مازاد مصرف(از جدول "wh_operation") |
| `data.bench_stock` | integer (int64) | انبار پای کار |
| `data.description` | string | توضیحات |
| `data.transfer_id` | integer (int64) | شناسه عملیات حواله‌ی انتقال (از جدول "wh_operation") |
| `data.operation_id` | integer (int64) | شناسه عملیات تولیدی |
| `data.prod_line_id` | integer (int64) | شناسه خط تولید. جدول "prod_line" |
| `data.receipt_date` | integer (int64) | تاریخ ثبت رسید |
| `data.creation_date` | integer (int64) | تاریخ ایجاد |
| `data.prod_order_id` | integer (int64) | شناسه دستور تولید |
| `data.expense_center` | integer (int64) | مرکز هزینه |
| `data.operation_date` | integer (int64) | تاریخ عملیات |
| `data.work_center_id` | integer (int64) | شناسه مرکز کاری |
| `data.direct_overhead` | integer (int64) | سربار مستقیم |
| `data.half_made_stock` | integer (int64) | انبار نیمه ساخته |
| `data.line_product_id` | integer (int64) | خط تولید کالا |
| `data.transference_id` | integer (int64) | شناسه عملیات حواله‌ی انتقال (از جدول "wh_operation") |
| `data.unmatched_stock` | integer (int64) | انبار نامنطبق |
| `data.indirect_overhead` | integer (int64) | سربار غیرمستقیم |
| `data.material_waste_id` | integer (int64) | شناسه عملیات ضایعات مواد اولیه |
| `data.modification_date` | integer (int64) | تاریخ تغییر |
| `data.transference_date` | integer (int64) | تاریخ ثبت حواله |
| `data.unmatched_quantity` | integer (int64) | تعداد نامنطبق |
| `data.modification_user_id` | integer (int64) | شناسه فرد تغییر دهنده |
| `data.unmatched_receipt_id` | integer (int64) | شناسه عملیات نامنطبق (از جدول "wh_operation") |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
