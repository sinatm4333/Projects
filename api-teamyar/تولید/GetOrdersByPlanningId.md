# دستور با برنامه ریزی تولید

ایجاد دستور تولید با برنامه ریزی تولید

## آدرس

```
/api/GetOrdersByPlanningId
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
    "orders": [
      {
        "id": 0,
        "code": 0,
        "title": "",
        "mps_id": 0,
        "opc_id": 0,
        "org_id": 0,
        "status": 0,
        "quantity": 0,
        "author_id": 0,
        "folder_id": 0,
        "need_date": 0,
        "start_date": 0,
        "description": "",
        "operation_id": 0,
        "prod_line_id": 0,
        "todo_step_id": 0,
        "todo_task_id": 0,
        "creation_date": 0,
        "order_group_id": 0,
        "work_center_id": 0,
        "line_product_id": 0,
        "planning_det_id": 0,
        "prod_planning_id": 0,
        "modification_date": 0,
        "order_subgroup_id": 0,
        "modification_user_id": 0
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
| `data.orders[]` | array | دستور |
| `data.orders[].id` | integer (int64) | شناسه اصلی (سیستمی) |
| `data.orders[].code` | integer (int64) | شناسه، چیزی که کاربر هم میتواند ویرایش کند |
| `data.orders[].title` | string | عنوان |
| `data.orders[].mps_id` | integer (int64) | شناسه درخواست تولید از جدول "prod_mps" |
| `data.orders[].opc_id` | integer (int64) | شناسه نمودار فرآیند عملیات تولید |
| `data.orders[].org_id` | integer (int64) | شناسه سازمان |
| `data.orders[].status` | integer (int32) | وضیعت عمیلیات:0: پیشنویس1: بررسی2: انجام3. کامل4. باطل5. لغو شد |
| `data.orders[].quantity` | integer (int64) | تعداد/مقدار |
| `data.orders[].author_id` | integer (int64) | شناسه ایجاد کننده |
| `data.orders[].folder_id` | integer (int64) | ذخیره تصاویر مربوط به کامنت ها |
| `data.orders[].need_date` | integer (int64) | تاریخ نیاز |
| `data.orders[].start_date` | integer (int64) | تاریخ شروع |
| `data.orders[].description` | string | توضیحات |
| `data.orders[].operation_id` | integer (int64) | شناسه عملیات. جدول "prod_operation" |
| `data.orders[].prod_line_id` | integer (int64) | شناسه خط تولید. جدول "prod_line" |
| `data.orders[].todo_step_id` | integer (int64) | شناسه اقدام. جدول "todo_task" |
| `data.orders[].todo_task_id` | integer (int64) | شناسه اقدام. جدول "todo_task" |
| `data.orders[].creation_date` | integer (int64) | تاریخ ایجاد |
| `data.orders[].order_group_id` | integer (int64) | شناسه گروه. جدول "PROD_ORDER_GROUP" |
| `data.orders[].work_center_id` | integer (int64) | شناسه مرکز کاری. جدول "prod_work_center" |
| `data.orders[].line_product_id` | integer (int64) | شناسه کالای ثبت شده در خط تولید. از جدول "prod_line_product" |
| `data.orders[].planning_det_id` | integer (int64) | شناسه جزئیات برنامه ریزی. جدول "prod_planning_det" |
| `data.orders[].prod_planning_id` | integer (int64) | شناسه برنامه ریزی تولید. جدول "prod_planning" |
| `data.orders[].modification_date` | integer (int64) | تاریخ تغییر |
| `data.orders[].order_subgroup_id` | integer (int64) | شناسه جدول "PROD_ORDER_GROUP" . به منظور نگهداری ارتباط میان دستورات تولید |
| `data.orders[].modification_user_id` | integer (int64) | شناسه فرد تغییر دهنده |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
