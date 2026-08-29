# ایجاد popup

## آدرس

```
/api/show_popup
```

## درخواست

```json
{
  "title*": "",
  "status": 0,
  "content*": "",
  "timeout": 0,
  "user_ids*": [
    0
  ]
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `title*` | string | عنوان پاپ آپ |
| `status` | integer (int32) | enum EnPopupFlag { POPUP_FLAG_NORMAL = 0, POPUP_FLAG_WITHOUT_CLOSE = 1, POPUP_FLAG_UPDATE = 2, POPUP_FLAG_BACKGROUND = 4, POPUP_FLAG_HTML = 8}; |
| `content*` | string | محتوای پاپ آپ |
| `timeout` | integer (int32) | زمان نمایش پاپ آپ بر حسب ثانیه |
| `user_ids*[]` | array | شناسه کاربران یا گروه هایی که میخواهیم برای آنها پاپ آپ ارسال شود |

## پاسخ

```json
{
  "data": {
    "popup_id": 0
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
| `data.popup_id` | integer (int64) | شناسه پاپ آپ ایجاد شده |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | وضعیت فراخوانی Api |
| `error.message` | string | در صورتی که Api موفق اجرا نشود در این پارامتر Error برگردانده شده نمایش داده میشود |
| `success` | boolean | موفق بودن اجرای Api را نشان میدهددر صورتی که api با موفقیت اجرا شود مقدار true دارد در غیر این صورت false |
