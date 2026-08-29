# تعییر وضعیت bom

با این APIمی توان وضعیت BOMها را تغییر داد

## آدرس

```
/api/change_status_boms
```

## درخواست

```json
{
  "ids": [
    0
  ],
  "org_id": 0,
  "status": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `ids[]` | array | آرایه شناسه ها |
| `org_id` | integer (int64) | شناسه شعبه |
| `status` | integer (int32) | وضعیت |

## پاسخ

```json
{
  "data": {
    "result": [
      0
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
| `data` | object | نتیجه دیتا |
| `data.result[]` | array | نتیجه آرایه |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
