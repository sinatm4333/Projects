# رزرو مربوط به شناسه ی عملیات سمت تولید

با این Api،اطلاعات رزرو مربوط به شناسه ی عملیات سمت ماژول تولید رو می توان برگردوند.

## آدرس

```
/api/get_reserve_by_ref
```

## درخواست

```json
{
  "id": 0,
  "type": 0,
  "reference_id": 0,
  "reference_detail_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) | شناسه |
| `type` | integer (int32) | نوع عملیات |
| `reference_id` | integer (int64) | شناسه مرجعی |
| `reference_detail_id` | integer (int64) | جزئیات شناسه مرجوعی |

## پاسخ

```json
{
  "data": [
    {
      "id": 0,
      "type": 0,
      "org_id": 0,
      "quantity": 0,
      "stock_id": 0,
      "module_id": 0,
      "product_id": 0,
      "receipt_id": 0,
      "attribute_id": 0,
      "reference_id": 0,
      "reserve_date": 0,
      "receipt_detail_id": 0,
      "reference_detail_id": 0
    }
  ],
  "error": {
    "status": 0,
    "message": ""
  },
  "success": false
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data[]` | array | آرایه دیتا |
| `data[].id` | integer (int64) | شناسه |
| `data[].type` | integer (int32) | نوع |
| `data[].org_id` | integer (int64) | شناسه شعبه |
| `data[].quantity` | integer (int64) | مقدار |
| `data[].stock_id` | integer (int64) | شناسه انبار |
| `data[].module_id` | integer (int64) | شناسه ماژول |
| `data[].product_id` | integer (int64) | کد کالا |
| `data[].receipt_id` | integer (int64) | شناسه رسید |
| `data[].attribute_id` | integer (int64) | شناسه ویژگی |
| `data[].reference_id` | integer (int64) | کد مرجوعی |
| `data[].reserve_date` | integer (int64) | کد رزرو |
| `data[].receipt_detail_id` | integer (int64) | شناسه سطر رسید |
| `data[].reference_detail_id` | integer (int64) | شناسه سطر مرجوعی |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
