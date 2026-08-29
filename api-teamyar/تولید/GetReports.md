# ثبت عملکرد

اطلاعات ثبت عملکرد

## آدرس

```
/api/GetReports
```

## درخواست

```json
{
  "from": 0,
  "count": 0,
  "org_id": 0,
  "search": ""
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `from` | integer (int64) | از |
| `count` | integer (int32) | مقدار |
| `org_id` | integer (int64) | شناسه سازمان |
| `search` | string | جستجو |

## پاسخ

```json
{
  "data": {
    "reports": [
      {
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
      }
    ]
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
| `data.reports[]` | array | ثبت عملکرد |
| `data.reports[].id` | integer (int64) | شناسه اصلی (سیستمی) |
| `data.reports[].code` | integer (int64) | شناسه، چیزی که کاربر هم میتواند ویرایش کند |
| `data.reports[].title` | string | عنوان |
| `data.reports[].bom_id` | integer (int64) | شناسه BOM از جدول "wh_bom_main" |
| `data.reports[].org_id` | integer (int64) | شناسه سازمان |
| `data.reports[].status` | integer (int32) | وضیعت عمیلیات:0: پیشنویس1: بررسی2: انجامکاملباطللغو شده |
| `data.reports[].duration` | integer (int64) | مدت زمان انجام ثبت عملکرد |
| `data.reports[].quantity` | integer (int64) | تعداد |
| `data.reports[].author_id` | integer (int64) | شناسه ایجاد کننده |
| `data.reports[].folder_id` | integer (int64) | ذخیره تصاویر مربوط به کامنت ها |
| `data.reports[].deficit_id` | integer (int64) | شناسه عملیات کسر مصرف(از جدول "wh_operation") |
| `data.reports[].project_id` | integer (int64) | شناسه حساب پروژه |
| `data.reports[].reciept_id` | integer (int64) | شناسه عملیات رسید (از جدول "wh_operation") |
| `data.reports[].surplus_id` | integer (int64) | شناسه عملیات مازاد مصرف(از جدول "wh_operation") |
| `data.reports[].bench_stock` | integer (int64) | انبار پای کار |
| `data.reports[].description` | string | توضیحات |
| `data.reports[].transfer_id` | integer (int64) | شناسه عملیات حواله‌ی انتقال (از جدول "wh_operation") |
| `data.reports[].operation_id` | integer (int64) | شناسه عملیات تولیدی |
| `data.reports[].prod_line_id` | integer (int64) | شناسه خط تولید. جدول "prod_line" |
| `data.reports[].receipt_date` | integer (int64) | تاریخ ثبت رسید |
| `data.reports[].creation_date` | integer (int64) | تاریخ ایجاد |
| `data.reports[].prod_order_id` | integer (int64) | شناسه دستور تولید در ثبت عملکرد |
| `data.reports[].expense_center` | integer (int64) | مرکز هزینه |
| `data.reports[].operation_date` | integer (int64) | تاریخ عملیات |
| `data.reports[].work_center_id` | integer (int64) | شناسه مرکز کاری |
| `data.reports[].direct_overhead` | integer (int64) | سربار مستقیم |
| `data.reports[].half_made_stock` | integer (int64) | انبار نیمه ساخته |
| `data.reports[].line_product_id` | integer (int64) | شناسه محصول در خط تولید |
| `data.reports[].transference_id` | integer (int64) | تاریخ ثبت حواله |
| `data.reports[].unmatched_stock` | integer (int64) | انبار نامنطبق |
| `data.reports[].indirect_overhead` | integer (int64) | سربار غیرمستقیم |
| `data.reports[].material_waste_id` | integer (int64) | شناسه عملیات ضایعات مواد اولیه |
| `data.reports[].modification_date` | integer (int64) | تاریخ تغییر |
| `data.reports[].transference_date` | integer (int64) | تاریخ ثبت حواله |
| `data.reports[].unmatched_quantity` | integer (int64) | تعداد نامنطبق |
| `data.reports[].modification_user_id` | integer (int64) | شناسه فرد تغییر دهنده |
| `data.reports[].unmatched_receipt_id` | integer (int64) | شناسه عملیات نامنطبق (از جدول "wh_operation") |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
