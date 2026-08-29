# گرفتن لیست اسناد

## آدرس

```
/api/document/list
```

## درخواست

```json
{
  "from": 0,
  "type": 0,
  "count": 0,
  "search": "",
  "deleted": 0,
  "meta_id": [
    0
  ],
  "parent_id": 0,
  "check_perm": false,
  "system_flag": 0,
  "search_flags": 0,
  "end_date_modified": 0,
  "start_date_modified": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `from` | integer (int32) | از |
| `type` | integer (int32) | پوشه برابر با 1 و فایل برابر با 2 است. |
| `count` | integer (int32) | تعداد |
| `search` | string | جستجوی این عبارت در نام مربوط به اسناد |
| `deleted` | integer (int32) | آیا اسناد حذف شده نمایش داده شوند یا خیر |
| `meta_id[]` | array | متادیتا |
| `parent_id` | integer (int64) | فرزندان این پوشه نمایش داده خواهد شد |
| `check_perm` | boolean | پرمیشن چک شود یا خیر |
| `system_flag` | integer (int32) | آیا اسناد سیستمی نمایش داده شوند یا خیر |
| `search_flags` | integer (int32) | نوع جستجو به چه شکل باشد، مقدار 0 = likeمقدار 1 = REGEXPمقدار 2 = binary D.NAME LIKEمقدار 4 = D.NAME LIKE ? or d.Id LIKE ? مقدار 8 = D.NAME LIKE ? or d.Id LIKE ? or h.keywords like |
| `end_date_modified` | integer (date) | اسنادی که تاریخ بروزرسانی آنها از این تاریخ به قبل باشد |
| `start_date_modified` | integer (date) | اسنادی که تاریخ برزورسانی آنها از این تاریخ به بعد باشد |

## پاسخ

```json
{
  "data": {
    "docs": [
      {
        "id": 0,
        "name": "",
        "size": 0,
        "type": 0,
        "deleted": false,
        "version": 0,
        "filename": "",
        "filetype": 0,
        "keywords": "",
        "owner_id": 0,
        "lock_flag": 0,
        "mime_type": "",
        "meta_value": [
          {
            "id": 0,
            "value": ""
          }
        ],
        "date_create": 0,
        "description": "",
        "folder_size": 0,
        "h_mime_type": "",
        "file_autonum": 0,
        "folder_depth": 0,
        "force_naming": 0,
        "never_delete": 0,
        "folder_autonum": 0,
        "folder_version": 0,
        "file_entity_path": 0,
        "file_entity_type": 0,
        "file_autonum_text": "",
        "file_duration_end": 0,
        "document_profile_id": 0,
        "file_duration_start": 0,
        "folder_autonum_text": "",
        "client_folder_setting_id": 0,
        "client_folder_setting_id_perm": 0
      }
    ],
    "total": 0
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
| `data` | object | داده |
| `data.docs[]` | array | آرایه ای از لیست اسناد |
| `data.docs[].id` | integer (int64) | شناسه سند |
| `data.docs[].name` | string | نام سند |
| `data.docs[].size` | integer (int64) | اندازه سند |
| `data.docs[].type` | integer (int32) | پوشه برابر با 1 و فایل برابر با 2 است. |
| `data.docs[].deleted` | boolean | 0 : به حذف شده ها منتقل شده است.1 : حذف نشده است. |
| `data.docs[].version` | integer (int32) | ورژن سند |
| `data.docs[].filename` | string | نام سند |
| `data.docs[].filetype` | integer (int32) | نوع سند |
| `data.docs[].keywords` | string | کلمه کلیدی سند |
| `data.docs[].owner_id` | integer (int64) | شناسه مولف سند |
| `data.docs[].lock_flag` | integer (int32) | 0 : قفل امضا ندارد1 : قفل امضا دارد |
| `data.docs[].mime_type` | string | نوع سند به صورت text مثل (text/xml) |
| `data.docs[].meta_value[]` | array | آرایه ای از متا دیتا های تعریف شده |
| `data.docs[].meta_value[].id` | integer (int64) | شناسه متا دیتا |
| `data.docs[].meta_value[].value` | string | محتویات متا دیتا |
| `data.docs[].date_create` | integer (date) | تاریخ ایجاد سند |
| `data.docs[].description` | string | توضیحات سند |
| `data.docs[].folder_size` | integer (int64) | اندازه پوشه |
| `data.docs[].h_mime_type` | string | نوع فایل در تنظیمات هوشمند |
| `data.docs[].file_autonum` | integer (int64) | عدد شمارنده برگه در الگوی شماره گذاری خودکار (برای فولدر) |
| `data.docs[].folder_depth` | integer (int64) | عمق پوشه |
| `data.docs[].force_naming` | integer (int32) | تیک نامگذاری خودکار |
| `data.docs[].never_delete` | integer (int32) | 0 : امکان حذف وجود دارد1: امکان حذف وجود ندارد |
| `data.docs[].folder_autonum` | integer (int64) | عدد شمارنده نامه در الگوی شماره گذاری خودکار (برای فولدر) |
| `data.docs[].folder_version` | integer (int64) | شناسه پوشه مجازی یک سند |
| `data.docs[].file_entity_path` | integer (int64) | جهت - ماهیت |
| `data.docs[].file_entity_type` | integer (int64) | نوع - ماهیت |
| `data.docs[].file_autonum_text` | string | شماره گذاری خودکار برگه |
| `data.docs[].file_duration_end` | integer (int64) | زمان پایان |
| `data.docs[].document_profile_id` | integer (int64) | شناسه کاربر |
| `data.docs[].file_duration_start` | integer (int64) | زمان شروع |
| `data.docs[].folder_autonum_text` | string | شماره گذاری خودکار نلمه |
| `data.docs[].client_folder_setting_id` | integer (int64) | شناسه تنظیمات زیرپوشه های خودکار (شناسه ی جدول DOCUMENTS_TY_DOCUMENT ) |
| `data.docs[].client_folder_setting_id_perm` | integer (int64) |  |
| `data.total` | integer (int32) | تعداد کل لیست اسناد |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
