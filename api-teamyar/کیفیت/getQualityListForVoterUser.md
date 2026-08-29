# گرفتن کیفیت هایی که یک شرکت کننده پاسخ داده است

به همراه from و count

## آدرس

```
/api/getQualityListForVoterUser
```

## درخواست

```json
{
  "from": 0,
  "count": 0,
  "user_id*": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `from` | integer (int32) | از |
| `count` | integer (int32) | مقدار |
| `user_id*` | integer (int64) | شناسه کاربر |

## پاسخ

```json
{
  "data": {
    "qualities": [
      {
        "id": 0,
        "name": "",
        "status": 0,
        "end_date": 0
      }
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
| `data` | object | آبجکت اصلی |
| `data.qualities[]` | array | کیفیت ها |
| `data.qualities[].id` | integer (int64) | شناسه |
| `data.qualities[].name` | string | عنوان |
| `data.qualities[].status` | integer (int32) | وضعیت |
| `data.qualities[].end_date` | integer (int64) | تاریخ پایان (مهلت) |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
