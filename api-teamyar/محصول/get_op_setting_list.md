# عملیات تولیدی

برای اعمال تعییرات جدید

## آدرس

```
/api/get_op_setting_list
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
| `from` | integer (int32) | فرم |
| `count` | integer (int32) | واحد شمارش |
| `org_id` | integer (int64) | شناسه شعبه |
| `search` | string | انتخاب واحد شمارش |

## پاسخ

```json
{
  "data": [
    {
      "id": 0,
      "title": "",
      "org_id": 0,
      "unit_id": 0,
      "unit_name": "",
      "decimal_num": 0
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
| `data[]` | array | آرایه |
| `data[].id` | integer (int64) | شناسه |
| `data[].title` | string | عنوان |
| `data[].org_id` | integer (int64) | شناسه شعبه |
| `data[].unit_id` | integer (int64) | شناسه واحد |
| `data[].unit_name` | string | عنوان عملیات |
| `data[].decimal_num` | integer (int32) | واحد شمارش |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
