# حذف گفتگو

حذف گفتگو با شناسه

## آدرس

```
/api/dialog/delete
```

## درخواست

```json
{
  "dialog_id*": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `dialog_id*` | integer (int64) | شناسه گفتگویی که میخواهیم حذف شود |

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
| `error.status` | integer (int32) | وضعیت فراخوانی Api |
| `error.message` | string | در صورتی که Api موفق اجرا نشود در این پارامتر Error برگردانده شده نمایش داده میشود |
| `success` | boolean | موفق بودن اجرای Api را نشان میدهددر صورتی که api با موفقیت اجرا شود مقدار true دارد در غیر این صورت false |
