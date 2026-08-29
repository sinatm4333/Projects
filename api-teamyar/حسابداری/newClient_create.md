# /api/newClient/create

درخواست

## آدرس

```
/api/newClient/create
```

## درخواست

```json
{
  "name": "",
  "note": "",
  "dic_id": 0,
  "org_id": 0,
  "parent_id": 0,
  "account_type": 0,
  "status_account": 0,
  "perm_parent_allow": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `name` | string | نام حساب |
| `note` | string | توضیحات |
| `dic_id` | integer (int64) | شناسه مشتری |
| `org_id` | integer (int64) | شناسه شعبه |
| `parent_id` | integer (int64) | آیدی پرنت حساب |
| `account_type` | integer (int32) | نوع حساب |
| `status_account` | integer (int32) | وضعیت |
| `perm_parent_allow` | integer (int32) | استفاده از دسترسی های پرنت |

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
| `data` | object |  |
| `data.id` | integer (int64) |  |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
