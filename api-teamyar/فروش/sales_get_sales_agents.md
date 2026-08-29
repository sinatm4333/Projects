# دریافت لیست عوامل فروش

گرفتن لیست عوامل فروش

## آدرس

```
/api/sales/get_sales_agents
```

## درخواست

```json
{
  "from": 0,
  "count": 0,
  "org_id": 0,
  "w_search": ""
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `from` | integer (int64) | شروع شماره از |
| `count` | integer (int32) | حداکثر تعداد خروجی |
| `org_id` | integer (int64) | شناسه شعبه |
| `w_search` | string | عبارت جستجو |

## پاسخ

```json
{
  "data": {
    "sales_agent": [
      {
        "id": 0,
        "name": "",
        "type": 0,
        "reffere_id": 0
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
| `data` | object | اطلاعات خروجی |
| `data.sales_agent[]` | array | آرایه عوامل فروش |
| `data.sales_agent[].id` | integer (int64) | شناسه شخص (client_id) |
| `data.sales_agent[].name` | string | نام |
| `data.sales_agent[].type` | integer (int32) | نشانگر یک فرد = 1 |
| `data.sales_agent[].reffere_id` | integer (int64) | شناسه مشتری (crm_id) |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
