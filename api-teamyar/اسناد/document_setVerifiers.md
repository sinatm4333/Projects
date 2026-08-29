# تغییر در افراد مطلع، تایید کننده، مسئول و امضا کننده

اضافه و حذف افراد در صفحه جزئیات سند

## آدرس

```
/api/document/setVerifiers
```

## درخواست

```json
{
  "type*": 0,
  "users": [
    0
  ],
  "document_id*": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `type*` | integer (int32) | نوع تغییرمطلع : 1تایید کننده : 16مسئول : 32امضا کننده : 2 |
| `users[]` | array | آرایه ای از شناسه افراد |
| `document_id*` | integer (int64) | شناسه سند |

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
