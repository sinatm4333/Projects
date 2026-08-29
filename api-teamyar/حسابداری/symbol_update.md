# ویرایش نرخ برابری ارز

با وارد کردن شناسه ارز و شناسه شعبه و نرخ برابری ، نرخ برابری ارز ویرایش میشود.

## آدرس

```
/api/symbol/update
```

## درخواست

```json
{
  "id": 0,
  "org_id": 0,
  "symbol_rate": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) | شناسه ارز |
| `org_id` | integer (int64) | شناسه شعبه |
| `symbol_rate` | number (double) | نرخ برابری |

## پاسخ

```json
{
  "data": {
    "error_data": ""
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
| `data` | object | پارامترها |
| `data.error_data` | string | خطا های سمت سرور |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | true : موفقfalse : ناموفق |
