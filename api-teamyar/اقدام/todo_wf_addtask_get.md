# دریافت اطلاعات جریان کار اقدام *

دریافت اطلاعات جریان کار اقدام

## آدرس

```
/api/todo/wf/addtask/get
```

## درخواست

```json
{
  "id": 0
}
```

| فیلد | نوع | توضیح |
|------|-----|-------|
| `id` | integer (int64) | شناسه جریان کار |

## پاسخ

```json
{
  "data": {
    "id": 0,
    "kind": 0,
    "name": "",
    "type": 0,
    "cat_id": 0,
    "name_bpmn": "",
    "name_step": "",
    "bpms_wf_id": 0,
    "section_id": 0
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
| `data.id` | integer (int64) | شناسه جریان کار |
| `data.kind` | integer (int32) | نوع جریان کارWORK_FLOW_KIND_WORKFLOW =1, جریان کار WORK_FLOW_KIND_BPMN =2, bpmb WORK_FLOW_KIND_BPMS =3, bpmn بین رده ای |
| `data.name` | string | عنوان جریان کار |
| `data.type` | integer (int32) | نوع جریان کارWORK_FLOW_TYPE_SEQUENTIAL =0,WORK_FLOW_TYPE_FLOATING =1, |
| `data.cat_id` | integer (int64) | شناسه ردهsource table name : `0000000`.todo_category \| column name: ID |
| `data.name_bpmn` | string | عنوان جریان کار بین رده ای |
| `data.name_step` | string | عنوان مرحله شروع |
| `data.bpms_wf_id` | integer (int64) | شناسه جریان کار بین رده ای |
| `data.section_id` | integer (int64) | شناسه بخشsource table name : `0000000`.todo_section \| column name: ID |
| `error` | object | جزئیات خطای اجرای API |
| `error.status` | integer (int32) | کد خطا |
| `error.message` | string | پیغام خطا |
| `success` | boolean | نشان دهنده وضعیت اجرای API، مقدار true در صورت موفقیت و مقدار false در صورت مواجه شدن با خطا |
