# حذف لینک تیمیاری

حذف پیوند (link) یک رکورد در ماژول مشخص.

## آدرس

```
/api/deleteLinks
```

## درخواست

```json
{
  "type": 0,
  "link_id": 0,
  "db_prefix": "",
  "module_id": 0,
  "is_archive": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `module_id` | number | شناسه ماژول |
| `link_id` | number | شناسه لینک/رکورد |
| `type` | number | نوع |
| `db_prefix` | string | پیشوند دیتابیس |
| `is_archive` | number | آرشیو |

## پاسخ

```json
{
  "type": 0,
  "link_id": 0,
  "db_prefix": "",
  "module_id": 0,
  "is_archive": 0
}
```

پاسخ همان ساختار درخواست را بازمی‌گرداند (echo) — برخلاف بقیه APIها که `error`/`success` برمی‌گردانند.

## مرتبط

- [ایجاد لینک بین ماژول‌ها](add_linkmodule.md)
