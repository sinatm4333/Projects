# گرفتن اطلاعات یک سند

## آدرس

```
/api/document/getInfo
```

## درخواست

```json
{
  "id*": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id*` | integer (int64) | شناسه سند |

## پاسخ

```json
{
  "data": {
    "owner_id": 0,
    "file_info": {
      "id": 0,
      "size": 0,
      "type": 0,
      "flags": 0,
      "version": 0,
      "filename": "",
      "filetype": 0,
      "author_id": 0,
      "mime_type": "",
      "module_id": 0,
      "parent_id": 0,
      "record_id": 0,
      "underline": 0,
      "date_create": 0,
      "date_modify": 0,
      "modifier_id": 0,
      "record_type": 0,
      "root_folder_id": 0
    },
    "document_profile_id": 0,
    "client_folder_setting_id": 0
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
| `data` | object | data |
| `data.owner_id` | integer (int64) | شناسه مالک سند |
| `data.file_info` | object |  |
| `data.file_info.id` | integer (int64) | شناسه سند |
| `data.file_info.size` | integer (int64) | سایز سند |
| `data.file_info.type` | integer (int32) | پوشه برابر با 1 و فایل برابر با 2 است. |
| `data.file_info.flags` | integer (int32) | INHERENT_SETTING = 1 ,DISABLED = 8 ,PROFILE_NAME = 16 ,DICTIONARY_NAME = 32 ,INHERENT = 64 ,DELETED = 128 ,SYSTEM = 256 |
| `data.file_info.version` | integer (int32) | آخرین نسخه سند |
| `data.file_info.filename` | string | نام سند |
| `data.file_info.filetype` | integer (int32) | نوع سند |
| `data.file_info.author_id` | integer (int64) | کاربری که سند توسط آن ثبت شده است. اسنادی هستند که با موارد زیر ثبت شده استUSER_BUILTIN_ADMIN = 10001,USER_BUILTIN_EVERYONE = 1,USER_BUILTIN_ADMINISTRATION = 2,USER_BUILTIN_TEAMYAR = 3,USER_BUILTIN_PUBLIC = 4 |
| `data.file_info.mime_type` | string | نوع فایل ذخیره شده |
| `data.file_info.module_id` | integer (int32) | شناسه ماژول |
| `data.file_info.parent_id` | integer (int64) | شناسه ی پوشه ی سطح بالاتر از سند فعلی |
| `data.file_info.record_id` | integer (int64) | MY_DOCUMENT=1024 ,USER_FOLDER = 8192 ,CLIENT_FOLDER = 16384 ,CLIENTS_ROOT = 32768 ,DOCUMENT_PORTAL_VIEW = 4096 ,DOCUMENT_PORTAL_EDIT = 131072 |
| `data.file_info.underline` | integer (int32) | این فیلد بصورت سیستمی مقداردهی میشود و برای چک صحت عملیات آپدیت فایل است |
| `data.file_info.date_create` | integer (date) | تاریخ ایجاد سند |
| `data.file_info.date_modify` | integer (date) | تاریخ ویرایش سند |
| `data.file_info.modifier_id` | integer (int64) | شناسه کاربر ویرایش کننده سند |
| `data.file_info.record_type` | integer (int32) | برای فایل enum FILe_RECORD_TYPE{ FILE_TEMPLATE = 1, FILE_ATTACHMENT = 2};برای فولدر نیز نمایش عمق واقعی پوشه (یعنی چند تا زیرپوشه دارد ) |
| `data.file_info.root_folder_id` | integer (int64) | پوشه ای که اسناد در آن ذخیره می شوند |
| `data.document_profile_id` | integer (int64) | شناسه کاربر |
| `data.client_folder_setting_id` | integer (int64) | شناسه تنظیمات زیرپوشه های خودکار (شناسه ی جدول DOCUMENTS_TY_DOCUMENT ) |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
