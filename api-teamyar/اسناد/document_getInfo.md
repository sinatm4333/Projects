# گرفتن اطلاعات یک سند

دریافت اطلاعات کامل یک سند بر اساس شناسه.

## آدرس

```
/api/document/getInfo
```

## درخواست

```json
{
  "id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | number | شناسه سند |

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
  "error": { "status": 0, "message": "" },
  "success": 0
}
```

### سطح بالا

| فیلد | نوع | توضیح |
|------|-----|-------|
| `data.owner_id` | number | شناسه مالک |
| `data.document_profile_id` | number | شناسه پروفایل سند |
| `data.client_folder_setting_id` | number | شناسه تنظیمات پوشه مشتری |

### فایل — `data.file_info`

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | number | شناسه فایل |
| `filename` | string | نام فایل |
| `filetype` | number | نوع فایل |
| `mime_type` | string | نوع MIME |
| `size` | number | حجم فایل |
| `type` | number | نوع |
| `version` | number | نسخه |
| `flags` | number | فلگ‌ها |
| `underline` | number | زیرخط |

### مکان — `data.file_info`

| فیلد | نوع | توضیح |
|------|-----|-------|
| `parent_id` | number | شناسه پوشه والد |
| `root_folder_id` | number | شناسه پوشه ریشه |
| `module_id` | number | شناسه ماژول |
| `record_id` | number | شناسه رکورد |
| `record_type` | number | نوع رکورد |

### ایجاد و ویرایش — `data.file_info`

| فیلد | نوع | توضیح |
|------|-----|-------|
| `author_id` | number | شناسه ایجادکننده |
| `date_create` | number | تاریخ ایجاد |
| `modifier_id` | number | شناسه آخرین ویرایش‌کننده |
| `date_modify` | number | تاریخ آخرین ویرایش |

### وضعیت پاسخ

| فیلد | نوع | توضیح |
|------|-----|-------|
| `error.status` | number | کد خطا |
| `error.message` | string | پیام خطا |
| `success` | number | نتیجه اجرا |

## مرتبط

- [فهرست اسناد](document_list.md)
- [گرفتن سند از طریق متادیتا](document_getByMetadata.md)
