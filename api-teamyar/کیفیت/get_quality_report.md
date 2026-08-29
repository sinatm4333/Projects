# گرفتن نتایج کیفیت

گرفتن نتایج یک کیفیت

## آدرس

```
/api/get_quality_report
```

## درخواست

```json
{
  "id*": 0,
  "samples": [
    0
  ],
  "assessee_ids": [
    0
  ],
  "question_ids": [
    0
  ],
  "assessee_type": 0,
  "evaluator_ids": [
    0
  ]
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id*` | integer (int64) | شناسه کیفیت |
| `samples[]` | array | نمونه ها |
| `assessee_ids[]` | array | شناسه ارزیابی شونده ها |
| `question_ids[]` | array | شناسه سوال ها |
| `assessee_type` | integer (int32) | نوع ارزیابی شونده |
| `evaluator_ids[]` | array | ارزیابی کننده ها |

## پاسخ

```json
{
  "data": [
    {
      "files": [
        {
          "id": 0,
          "mime": "",
          "name": "",
          "size": 0,
          "type": 0
        }
      ],
      "org_id": 0,
      "org_name": "",
      "folder_id": 0,
      "option_id": 0,
      "result_id": 0,
      "quality_id": 0,
      "assessee_id": 0,
      "option_text": "",
      "question_id": 0,
      "evaluator_id": 0,
      "option_score": "",
      "quality_name": "",
      "assessee_name": "",
      "question_text": "",
      "evaluator_name": "",
      "other_option_text": ""
    }
  ],
  "error": {
    "status": 0,
    "message": ""
  },
  "success": false
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data[]` | array | داده |
| `data[].files[]` | array | فایل ها |
| `data[].files[].id` | integer (int64) | شناسه فایل |
| `data[].files[].mime` | string | mimetype برای فایل ها |
| `data[].files[].name` | string | عنوان فایل |
| `data[].files[].size` | integer (int64) | سایز فایل |
| `data[].files[].type` | integer (int32) | enum EnDocumentType { DOCUMENT_FOLDER = 1, DOCUMENT_FILE = 2 }; |
| `data[].org_id` | integer (int64) | شناسه سازمان |
| `data[].org_name` | string | نام سازمان |
| `data[].folder_id` | integer (int64) | شناسه پوشه |
| `data[].option_id` | integer (int64) | شناسه گزینه انتخابی |
| `data[].result_id` | integer (int64) | شناسه جواب |
| `data[].quality_id` | integer (int64) | شناسه کیفیت |
| `data[].assessee_id` | integer (int64) | شناسه ارزیابی شونده |
| `data[].option_text` | string | عنوان گزینه |
| `data[].question_id` | integer (int64) | شناسه سوال |
| `data[].evaluator_id` | integer (int64) | شناسه ارزیابی کننده |
| `data[].option_score` | string | امتیاز گزینه |
| `data[].quality_name` | string | عنوان کیفیت |
| `data[].assessee_name` | string | عنوان ارزیابی شونده |
| `data[].question_text` | string | عنوان سوال |
| `data[].evaluator_name` | string | عنوان ارزیابی کننده |
| `data[].other_option_text` | string | توضیحات به عنوان جواب |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
