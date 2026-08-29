# /api/organization/list

درخواست

## آدرس

```
/api/organization/list
```

## درخواست

بدون پارامتر.

## پاسخ

```json
{
  "data": [
    {
      "id": 0,
      "name": "",
      "org_code": "",
      "folder_id": 0,
      "parent_id": 0,
      "register_id": "",
      "date_setting": 0,
      "user_setting": 0,
      "base_currency": 0,
      "action_setting": 0,
      "action_module_setting": 0,
      "identical_action_setting": 0
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
| `data[]` | array |  |
| `data[].id` | integer (int64) |  |
| `data[].name` | string |  |
| `data[].org_code` | string |  |
| `data[].folder_id` | integer (int64) |  |
| `data[].parent_id` | integer (int64) |  |
| `data[].register_id` | string |  |
| `data[].date_setting` | integer (int32) |  |
| `data[].user_setting` | integer (int32) |  |
| `data[].base_currency` | integer (int64) |  |
| `data[].action_setting` | integer (int32) |  |
| `data[].action_module_setting` | integer (int32) |  |
| `data[].identical_action_setting` | integer (int32) |  |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
