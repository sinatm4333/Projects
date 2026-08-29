# ایجاد لینک بین ماژول ها

## آدرس

```
/api/add_linkmodule
```

## درخواست

```json
{
  "dst_type": 0,
  "src_type": 0,
  "dst_link_id*": 0,
  "src_link_id*": 0,
  "dst_module_id*": 0,
  "src_module_id*": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `dst_type` | integer (int32) | نوع آیتم مقصد که میخواهیم لینک شود |
| `src_type` | integer (int32) | نوع آیتم مبدا که میخواهیم لینک شود |
| `dst_link_id*` | integer (int64) | شناسه آیتم مقصد که میخواهیم لینک شود |
| `src_link_id*` | integer (int64) | شناسه آیتم مبدا که میخواهیم لینک شود |
| `dst_module_id*` | integer (int32) | شناسه ماژول مقصد |
| `src_module_id*` | integer (int32) | شناسه ماژول مبدا |

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
