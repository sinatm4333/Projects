# ایجاد لینک بین ماژول‌ها

ایجاد پیوند (link) میان دو رکورد در دو ماژول مبدأ و مقصد.

## آدرس

```
/api/add_linkmodule
```

## درخواست

```json
{
  "dst_type": 0,
  "src_type": 0,
  "dst_link_id": 0,
  "src_link_id": 0,
  "dst_module_id": 0,
  "src_module_id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `src_module_id` | number | شناسه ماژول مبدأ |
| `src_link_id` | number | شناسه رکورد مبدأ |
| `src_type` | number | نوع مبدأ |
| `dst_module_id` | number | شناسه ماژول مقصد |
| `dst_link_id` | number | شناسه رکورد مقصد |
| `dst_type` | number | نوع مقصد |

## پاسخ

```json
{
  "error": { "status": 0, "message": "" },
  "success": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `error.status` | number | کد خطا |
| `error.message` | string | پیام خطا |
| `success` | number | نتیجه اجرا |
