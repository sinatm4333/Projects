# ایجاد کالا/خدمت جدید

با این APIامکان می توان کالا/خدمت جدید ایجاد کرد.

## آدرس

```
/api/add_product
```

## درخواست

```json
{
  "code": "",
  "name": "",
  "depth": "",
  "width": "",
  "height": "",
  "org_id": 0,
  "serial": 0,
  "weight": "",
  "barcode": "",
  "tx_code": "",
  "unit_id": 0,
  "location": "",
  "barcode_2": "",
  "barcode_3": "",
  "gift_type": 0,
  "is_service": 0,
  "setting_id": 0,
  "description": "",
  "parent_code": "",
  "account_info": {
    "client_code": "",
    "account_code": "",
    "project_code": "",
    "floating_code": "",
    "cost_center_code": "",
    "revenue_center_code": ""
  },
  "availability": 0,
  "quantity_seri": 0,
  "supply_method": 0,
  "voucher_allow": 0,
  "main_custom_id": 0,
  "pricing_method": 0,
  "product_type_id": 0,
  "tc_sharing_value": "",
  "construction_seri": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `code` | string | کد |
| `name` | string | نام |
| `depth` | string |  |
| `width` | string |  |
| `height` | string |  |
| `org_id` | integer (int64) | شناسه شعبه |
| `serial` | integer (int32) | سریال |
| `weight` | string |  |
| `barcode` | string |  |
| `tx_code` | string |  |
| `unit_id` | integer (int64) | شناسه واحد |
| `location` | string |  |
| `barcode_2` | string |  |
| `barcode_3` | string |  |
| `gift_type` | integer (int32) |  |
| `is_service` | integer (int32) |  |
| `setting_id` | integer (int64) | شناسه تنظیمات |
| `description` | string |  |
| `parent_code` | string | کد کالا |
| `account_info` | object | اطلاعات حساب |
| `account_info.client_code` | string | کد مشتری |
| `account_info.account_code` | string | شناسه حساب |
| `account_info.project_code` | string | شناسه پروژه |
| `account_info.floating_code` | string | کد شناور |
| `account_info.cost_center_code` | string | شناسه مرکز هزینه |
| `account_info.revenue_center_code` | string | شناسه مرکز درآمد اجباری |
| `availability` | integer (int32) |  |
| `quantity_seri` | integer (int64) | تعداد سری ساخت |
| `supply_method` | integer (int64) |  |
| `voucher_allow` | integer (int32) | آخرین سطح |
| `main_custom_id` | integer (int64) |  |
| `pricing_method` | integer (int32) | روش قیمت گذاری |
| `product_type_id` | integer (int32) | شناسه ماهیت کالا |
| `tc_sharing_value` | string |  |
| `construction_seri` | integer (int32) | سری ساخت |

## پاسخ

```json
{
  "data": {
    "id": 0
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
| `data` | object | نتایج داده |
| `data.id` | integer (int64) | شناسه |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
