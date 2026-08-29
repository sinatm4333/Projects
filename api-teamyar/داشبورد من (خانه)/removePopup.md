# حذف پاپ آپ

حذف پاپ آپ برای کاربر (ها)

## آدرس

```
/api/removePopup
```

## درخواست

```json
{
  "popup_id*": 0,
  "user_ids": [
    0
  ]
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `popup_id*` | integer (int64) | شناسه پاپ آپ |
| `user_ids[]` | array | انتخاب کاربر برای حذف پاپ آپ. درصورتی که فرستاده نشود پاپ آپ برای همه حذف می شود |

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
