# اختصاص ویژگی به کالاها

از طریق این API، می‌توان به کالاها ویژگی اختصاص داد.

## آدرس

```
/api/add_product_attribute
```

## درخواست

```json
{
  "items": [
    {
      "content": "",
      "field_id": 0,
      "field_list_id": 0
    }
  ],
  "org_id": 0,
  "barcode": "",
  "barcode_2": "",
  "barcode_3": "",
  "product_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `content` | string | برای تعریف رشته، عدد و تاریخ |
| `field_id` | integer (int64) | شناسه |
| `field_list_id` | integer (int64) | خصوصیت از ویژگی ها |
| `org_id` | integer (int64) | شناسه شعبه |
| `barcode` | string | بارکد |
| `barcode_2` | string | بارکد2 |
| `barcode_3` | string | بارکد3 |
| `product_id` | integer (int64) | شناسه کالا |

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
