# لیست opc ایجاد شده

فراخوانی لیست opc ایجاد شده

## آدرس

```
/api/get_opc_list
```

## درخواست

```json
{
  "from": 0,
  "count": 0,
  "org_id": 0,
  "search": ""
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `from` | integer (int64) | لیست opc |
| `count` | integer (int64) | شمارنده |
| `org_id` | integer (int64) | شناسه شعبه |
| `search` | string | جستجو |

## پاسخ

```json
{
  "data": [
    {
      "id": 0,
      "ref": 0,
      "title": "",
      "org_id": 0,
      "version": 0,
      "author_id": 0,
      "is_current": 0,
      "date_create": 0
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
| `data[]` | array | آرایه |
| `data[].id` | integer (int64) | شناسه |
| `data[].ref` | integer (int64) | شناسه نسخه اصلاحی |
| `data[].title` | string | عنوان |
| `data[].org_id` | integer (int64) | شناسه شعبه |
| `data[].version` | integer (int64) | نسخه |
| `data[].author_id` | integer (int64) | پیش نویس |
| `data[].is_current` | integer (int32) | اجرا |
| `data[].date_create` | integer (int64) | تاریخ ایجاد |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
