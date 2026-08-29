# امتیازات برای ارزیابی شونده

## آدرس

```
/api/getScoresForAssesseeInDateRange
```

## درخواست

```json
{
  "ids": [
    0
  ],
  "count": 0,
  "date_to": 0,
  "date_from": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `ids[]` | array | شناسه ها |
| `count` | integer (int32) | مقدار |
| `date_to` | integer (int64) | تا تاریخ |
| `date_from` | integer (int64) | از تاریخ |

## پاسخ

```json
{
  "data": {
    "scores": [
      {
        "assessee_id": 0,
        "total_score": 0,
        "evaluation_score": 0
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
| `data.scores[]` | array | امتیازها |
| `data.scores[].assessee_id` | integer (int64) | شناسه ارزیابی شونده |
| `data.scores[].total_score` | integer (int32) | مجموع امتیازها |
| `data.scores[].evaluation_score` | integer (int64) | امتیاز ارزیابی کننده ها |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
