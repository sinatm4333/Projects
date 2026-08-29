# چک وجود انبار در ماژول اقدام

بررسی وابستگی انبار به اقدام پیش از حذف.

## آدرس

```
/api/todo/delcheck/stock
```

## درخواست

```json
{
  "id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | number | شناسه |

## پاسخ

```json
{
  "data": { "err": "" },
  "error": { "status": 0, "message": "" },
  "success": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data.err` | string | پیام بررسی |
| `error.status` | number | کد خطا |
| `error.message` | string | پیام خطا |
| `success` | number | نتیجه اجرا |
