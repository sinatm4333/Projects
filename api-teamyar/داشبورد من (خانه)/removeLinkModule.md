# حذف لینک تیمیاری (بین دو ماژول)

حذف پیوند (link) میان دو رکورد در ماژول مبدأ و مقصد — عملیات معکوس `add_linkmodule`.

## آدرس

```
/api/removeLinkModule
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
  "dst_type": 0,
  "src_type": 0,
  "dst_link_id": 0,
  "src_link_id": 0,
  "dst_module_id": 0,
  "src_module_id": 0
}
```

پاسخ همان ساختار درخواست را بازمی‌گرداند (echo).

## مرتبط

- [ایجاد لینک بین ماژول‌ها](add_linkmodule.md) — همان فیلدها، عملیات معکوس.
- [حذف لینک تیمیاری](deleteLinks.md) — حذف لینک یک رکورد (تک‌طرفه)، نه جفت مبدأ/مقصد.
