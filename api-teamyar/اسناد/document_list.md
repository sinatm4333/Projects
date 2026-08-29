# فهرست اسناد

دریافت فهرست اسناد با فیلتر و صفحه‌بندی.

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
  "meta_id": [0],
  "parent_id": 0,
  "check_perm": 0,
  "system_flag": 0,
  "search_flags": 0,
  "end_date_modified": 0,
  "start_date_modified": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `parent_id` | number | شناسه پوشه/سند والد |
| `type` | number | نوع |
| `meta_id` | array\<number\> | شناسه متادیتاها |
| `search` | string | عبارت جستجو |
| `search_flags` | number | فلگ‌های جستجو |
| `system_flag` | number | فلگ سیستمی |
| `deleted` | number | حذف‌شده‌ها |
| `check_perm` | number | بررسی دسترسی |
| `start_date_modified` | number | ابتدای بازه تاریخ ویرایش |
| `end_date_modified` | number | انتهای بازه تاریخ ویرایش |
| `from` | number | شروع صفحه‌بندی |
| `count` | number | تعداد رکورد |

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
        "deleted": 0,
        "version": 0,
        "filename": "",
        "filetype": 0,
        "keywords": "",
        "owner_id": 0,
        "lock_flag": 0,
        "mime_type": "",
        "meta_value": [{ "id": 0, "value": "" }],
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
  "error": { "status": 0, "message": "" },
  "success": 0
}
```

### شناسه و نام

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data.docs[].id` | number | شناسه سند |
| `data.docs[].name` | string | نام |
| `data.docs[].description` | string | توضیحات |
| `data.docs[].keywords` | string | کلیدواژه‌ها |
| `data.docs[].owner_id` | number | شناسه مالک |
| `data.docs[].date_create` | number | تاریخ ایجاد |
| `data.total` | number | تعداد کل رکوردها |

### فایل

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data.docs[].filename` | string | نام فایل |
| `data.docs[].filetype` | number | نوع فایل |
| `data.docs[].mime_type` | string | نوع MIME |
| `data.docs[].h_mime_type` | string | نوع MIME (نمایشی) |
| `data.docs[].size` | number | حجم فایل |
| `data.docs[].file_entity_type` | number | نوع موجودیت فایل |
| `data.docs[].file_entity_path` | number | مسیر موجودیت فایل |
| `data.docs[].file_duration_start` | number | شروع مدت‌زمان فایل |
| `data.docs[].file_duration_end` | number | پایان مدت‌زمان فایل |

### پوشه

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data.docs[].folder_size` | number | حجم پوشه |
| `data.docs[].folder_depth` | number | عمق پوشه |
| `data.docs[].folder_version` | number | نسخه پوشه |
| `data.docs[].client_folder_setting_id` | number | شناسه تنظیمات پوشه |
| `data.docs[].client_folder_setting_id_perm` | number | شناسه تنظیمات دسترسی پوشه |

### شماره‌گذاری خودکار

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data.docs[].file_autonum` | number | شماره خودکار فایل |
| `data.docs[].file_autonum_text` | string | متن شماره خودکار فایل |
| `data.docs[].folder_autonum` | number | شماره خودکار پوشه |
| `data.docs[].folder_autonum_text` | string | متن شماره خودکار پوشه |
| `data.docs[].force_naming` | number | اجبار نام‌گذاری |

### وضعیت

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data.docs[].type` | number | نوع |
| `data.docs[].version` | number | نسخه |
| `data.docs[].deleted` | number | حذف‌شده |
| `data.docs[].lock_flag` | number | قفل |
| `data.docs[].never_delete` | number | غیرقابل حذف |

### سایر

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data.docs[].meta_value[]` | array | مقادیر متادیتا — `id`، `value` |
| `data.docs[].document_profile_id` | number | شناسه پروفایل سند |
| `error.status` | number | کد خطا |
| `error.message` | string | پیام خطا |
| `success` | number | نتیجه اجرا |
