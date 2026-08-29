# گرفتن مشخصات گفتگو

گرفتن مشخصات گفتگو از طریق شناسه گفتگو

## آدرس

```
/api/dialog/get
```

## درخواست

```json
{
  "cur_user*": 0,
  "dialog_id*": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `cur_user*` | integer (int64) | شناسه کاربر فعلی |
| `dialog_id*` | integer (int64) | شناسه گفتگو |

## پاسخ

```json
{
  "data": {
    "id": 0,
    "name": "",
    "type": 0,
    "image": ""
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
| `data.id` | integer (int64) | شناسه گفتگو |
| `data.name` | string | عنوان گفتگو |
| `data.type` | integer (int32) | نوع گفتگوCHAT_TYPE_GROUP = 0,CHAT_TYPE_PRIVATE = 1,CHAT_TYPE_CHANNEL = 2, |
| `data.image` | string | آیکون گفتگو |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | وضعیت فراخوانی Api |
| `error.message` | string | در صورتی که Api موفق اجرا نشود در این پارامتر Error برگردانده شده نمایش داده میشود |
| `success` | boolean | موفق بودن اجرای Api را نشان میدهددر صورتی که api با موفقیت اجرا شود مقدار true دارد در غیر این صورت false |
