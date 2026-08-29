# درخواست تولید

ایجاد درخواست تولید

## آدرس

```
/api/GetMps
```

## درخواست

```json
{
  "id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) | شناسه اصلی (سیستمی) |

## پاسخ

```json
{
  "data": {
    "id": 0,
    "code": 0,
    "date": 0,
    "step": 0,
    "title": "",
    "org_id": 0,
    "status": 0,
    "unit_id": 0,
    "deadline": 0,
    "quantity": 0,
    "author_id": 0,
    "folder_id": 0,
    "product_id": 0,
    "description": "",
    "attribute_id": 0,
    "todo_step_id": 0,
    "todo_task_id": 0,
    "creation_date": 0,
    "parent_mps_id": 0,
    "sales_invoice_id": 0,
    "modification_date": 0,
    "modification_user_id": 0
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
| `data.date` | integer (int64) | تاریخ |
| `data.step` | integer (int32) | شماره مرحله‌ی درخواست تولید0: درخواست1: برنامه ریزی مواد2: تایید3: دستور4 گزارش |
| `data.title` | string | عنوان |
| `data.org_id` | integer (int64) | شناسه سازمان |
| `data.status` | integer (int32) | وضیعت عمیلیات:0: پیشنویس1: بررسی2: انجامکاملباطللغو شده |
| `data.unit_id` | integer (int64) | شناسه واحد کالای درخواستی (از جدول "wh_stock_capacity") |
| `data.deadline` | integer (int64) | مهلت |
| `data.quantity` | integer (int64) | مقدار/تعداد |
| `data.author_id` | integer (int64) | شناسه ایجاد کننده |
| `data.folder_id` | integer (int64) | ذخیره تصاویر مربوط به کامنت ها |
| `data.product_id` | integer (int64) | شناسه کالا از جدول "wh_product" |
| `data.description` | string | توضیحات |
| `data.attribute_id` | integer (int64) | شناسه ویژگی از جدول "WH_PRODUCT_ATTRIBUTE" |
| `data.todo_step_id` | integer (int64) | شناسه مرحله در ماژول اقدام. جدول "todo_step" |
| `data.todo_task_id` | integer (int64) | شناسه اقدام. جدول "todo_task" |
| `data.creation_date` | integer (int64) | تاریخ ایجاد |
| `data.parent_mps_id` | integer (int64) | شناسه خود جدولدر واقع شناسه درخواست تولیدی را نگه میدارد که ایجاد کننده این درخواست تولید است. (در صورتی که نیمه ساخته باشد) |
| `data.sales_invoice_id` | integer (int64) | شناسه درخواست خزید (از جدول "PURCHASE_INVOICE") |
| `data.modification_date` | integer (int64) | تاریخ تغییر |
| `data.modification_user_id` | integer (int64) | شناسه فرد تغییر دهنده |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
