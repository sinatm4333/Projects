# ماشین آلات در opc

ماشین آلات در نمودار فرایند عملیات

## آدرس

```
/api/GetOpcDetByMachineOpcOp
```

## درخواست

```json
{
  "opc_id": 0,
  "machine_id": 0,
  "operation_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `opc_id` | integer (int64) | شناسه نمودار فرایند عملیات |
| `machine_id` | integer (int64) | شناسه دارایی - asset_asset |
| `operation_id` | integer (int64) | شناسه عملیات تولیدی |

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
| `data` | object | آبجکت اصلی |
| `data.id` | integer (int64) | شناسه اصلی (سیستمی) |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
