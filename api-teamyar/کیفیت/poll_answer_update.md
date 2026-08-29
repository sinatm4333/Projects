# /api/poll/answer/update

درخواست

## آدرس

```
/api/poll/answer/update
```

## درخواست

```json
{
  "answers": [
    {
      "files": [
        {
          "mime": "",
          "name": "",
          "size": 0,
          "content_base64": ""
        }
      ],
      "option_ids": [
        0
      ],
      "description": "",
      "question_id*": 0
    }
  ],
  "user_id": 0,
  "assessee_id": 0,
  "questionnaire_id*": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `answers[]` | array |  |
| `answers[].files[]` | array |  |
| `answers[].files[].mime` | string |  |
| `answers[].files[].name` | string |  |
| `answers[].files[].size` | integer (int64) |  |
| `answers[].files[].content_base64` | string |  |
| `answers[].option_ids[]` | array |  |
| `answers[].description` | string |  |
| `answers[].question_id*` | integer (int64) |  |
| `user_id` | integer (int64) |  |
| `assessee_id` | integer (int64) |  |
| `questionnaire_id*` | integer (int64) |  |

## پاسخ

```json
{
  "data": {
    "total_mark": 0,
    "result_status": 0
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
| `data.total_mark` | integer (int64) |  |
| `data.result_status` | integer (int64) |  |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
