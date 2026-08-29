# ثبت توضیحات جدید برای مشتری

## آدرس

```
/api/client/add/comment
```

## درخواست

```json
{
  "id": 0,
  "comment": "",
  "section_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) | شناسه مشتری |
| `comment` | string | متن توضیحات |
| `section_id` | integer (int64) | شناسه بخشی که توضیحات در آن بخش باید ثبت شود |

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
