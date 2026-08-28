# Teamyar Internal API Reference (`teamyar.call_api`)

Catalog of Teamyar internal APIs usable from Lua bots via:

```lua
local res = teamyar.call_api(module_id, url, params)
```

`res` comes back already as a Lua table — pass straight to `json.encode(res)` for a JSON bot response, no
manual `Cookie`/`SID`/API-key needed (runs in-process inside the Teamyar engine, authenticated implicitly by
`module_id` + the bot's own execution context). See also `docs/context/CrmCustomerUiDiscovery.md` for the
`module_id=14` CRM/client APIs (separately discovered).

Response envelope is consistently `{ success, error: {status, message}, data: {...} }` (Lua field names are
`snake_case`, matching the rest of this project's SQL-result-to-JSON convention).

**Source**: official API doc portal at `https://client.teamyar.com/?page=/apidoc/index_portal` (لاگین با اکانت
Teamyar؛ فهرست ماژول‌ها → هر ماژول یک `module_id` دارد، هر endpoint یک صفحهٔ `?page=/apidoc/info/&id=N` با تب
«درخواست» (request schema کامل، فیلد به فیلد با قوانین اعتبارسنجی) و تب «پاسخ» (response schema)). این سند
یک زیرمجموعهٔ دستی از اون پورتال است — برای APIهای مستندنشده، مستقیماً پورتال رو چک کنید.

---

## Module ID Registry (`HOME_MODULE_LIST`) — canonical

قانون: مرجع رسمی و ثابت شناسهٔ ماژول‌های Teamyar. از این جدول برای هر `module_id` جدید در بات‌ها (`teamyar.call_api(module_id, ...)`)، مستندات، و `src_module_id`/`dst_module_id` استفاده شود — منبع دیگری برای این map نگه نداریم.

| module_id | نام ماژول | نوع |
|---|---|---|
| 0 | core | سیستمی |
| 1 | خانه | سیستمی |
| 3 | مدیر سیستم | سیستمی |
| 5 | پروفایل | سیستمی |
| 7 | اسناد | |
| 8 | اقدام | |
| 9 | گفتگو | |
| 10 | حسابداری | |
| 12 | اوتلوک | |
| 13 | پرسنلی | |
| 14 | CRM | |
| 15 | تماس | |
| 16 | SMS | |
| 17 | محصول | |
| 18 | اخبار | |
| 19 | تقویم | |
| 20 | پروژه | |
| 23 | فروش | |
| 24 | اموال | |
| 26 | باتی | |
| 27 | خرید | |
| 32 | گزارش | |
| 39 | events | سیستمی |

---

## `/api/show_popup` — module_id `1`

Show a popup notification to one or more Teamyar users.

**Request:**
```json
{"title":"","status":0,"content":"","timeout":0,"user_ids":[0]}
```

**Response:**
```json
{"data":{"popup_id":0},"error":{"status":0,"message":""},"success":0}
```

**Example:**
```lua
teamyar.call_api(1, "api/show_popup", {
    title = "test",
    content = "test",
    timeout = 30,
    user_ids = {10001, 10002, 10003, 10004, 10005, 2}
})
```

---

## Link two records — module_id unknown (endpoint path not given)

Generic src/dst record-linking API — fields suggest linking two entities across modules (e.g. attaching a
document to a task). Endpoint path and `module_id` weren't specified when this was documented; confirm both
before using (check the portal's module list for a "لینک"/link-sounding endpoint).

**Request:**
```json
{"dst_type":0,"src_type":0,"dst_link_id":0,"src_link_id":0,"dst_module_id":0,"src_module_id":0}
```

**Response:**
```json
{"error":{"status":0,"message":""},"success":0}
```

---

## ماژول «اقدام» (Todo) — module_id `8`

Full module has **36 endpoints** (portal: `?page=/apidoc/index&module_id=8`). Documented below: the 11 most
commonly used. For the rest, open the module list and pick from: `task/assignadd`, `task/stepadd`,
`customform/get`, `customform/multi_get`, `customform/update`, `registerform` (+ `registerform/delete`),
`category/list/get`, `category/update`, `delcheck/stock`, `section/get`, `section/list/get`, `section/update`,
`task/crm/add`, `task/event/add`, `task/list/crm/get`, `task/list/link/get`, `task/permcheck/view`,
`taskstep/status/get`, `topic/get`, `topic/list/get`, `wf/addtasklist/get`, `wf/list/get`,
`task/taskstep/responsible/set`, `taskstep/change/perm/check`.

### `/api/todo/taskadd` — ایجاد اقدام

**Request fields:**
| Field | Type | Notes |
|---|---|---|
| `wf_id` | int64 | **الزامی.** شناسهٔ جریان کار؛ باید معتبر باشد و مرحلهٔ شروع داشته باشد، وگرنه `error` |
| `topic_id` | int64 | **الزامی.** شناسهٔ موضوع؛ باید معتبر باشد وگرنه `error` |
| `crm_id` | int64 | اختیاری — لینک مشتری؛ نامعتبر بودن مانع ایجاد اقدام نمی‌شود |
| `comment` | string | اختیاری — کامنت مرحلهٔ اول؛ حداکثر ۵۰٬۰۰۰ کاراکتر (بیشتر → `error`) |
| `deadline` | int64 | اختیاری — قبل از امروز یا خالی → پیش‌فرض ۷ روز بعد |
| `task_type` | int32 | `1`=نرمال (پیش‌فرض)، `4`=پورتال |
| `project_id` | int64 | اختیاری — اقدام به stageهای این پروژه اضافه می‌شود |
| `task_title` | string | توصیه‌شده؛ خالی → عنوان پیش‌فرض جریان کار، وگرنه `empty title` |
| `parent_step_id` / `parent_task_id` | int64 | شناسهٔ مرحله/اقدام والد |

**قانون مهم:** جریان کار (`wf_id`) و موضوع (`topic_id`) حتماً باید از یک **رده** باشند وگرنه `error`. برای
BPMN بین‌رده‌ای، مرحلهٔ شروعِ جریان کار باید با موضوع هم‌رده باشد.

**Example:**
```lua
req_param = {wf_id=30, topic_id=46, task_title="task from api", comment="comment content", deadline="", project_id=6, crm_id=10005, task_type=1};
res = teamyar.call_api(8, "/api/todo/taskadd", req_param);
teamyar.write_result(json.encode(res))
```
Success: `{"success":true,"data":{"task_id":142}}`
Failure: `{"success":false,"error":{"status":-8,"message":"موضوع مورد نظر وجود ندارد"}}`

---

### `/api/todo/taskedit` — ویرایش اقدام (۹۱٪ تکمیل در پورتال)

همهٔ فیلدها به‌جز `task_id` اختیاری‌اند؛ مقداردهی‌نشده = مقدار قبلی حفظ می‌شود.

| Field | Type | Notes |
|---|---|---|
| `task_id` | int64 | **الزامی.** نامعتبر → `error` |
| `color` | string | مثال: `#ff0000`, `#0000ff`, `#ffa500`, `#ffff00` |
| `wf_id` | int64 | تغییر جریان کار (جریان کار بعدی به تسک اضافه می‌شود)؛ مقدار غلط → `error` |
| `deadline` | int64 | |
| `owner_id` | int64 | |
| `priority` | int32 | |
| `topic_id` | int64 | مقدار غلط → `error` |
| `task_title` | string | |
| `category_id` | int64 | مقدار غلط → بی‌اثر (نه error) |
| `portal_show` | int32 | |

**Example:**
```lua
req_param = {color="#ff0000", wf_id=479, task_id=29578, deadline=0, owner_id=22818, priority=0, topic_id=0, task_title="111111", category_id=0};
res = teamyar.call_api(8, "/api/todo/taskedit", req_param);
teamyar.write_result(json.encode(res))
```
Success: `{"success":true,"data":{"task_id":29578}}`
Failure: `{"success":false,"error":{"status":-8,"message":"ERR_WRONG_TOPIC_CATEGORY"}}`

---

### `/api/todo/step/get` — دریافت اطلاعات مرحله جریان کار

**Request:** `{"id": 0}` (شناسه مرحله)

**Response:**
```json
{
  "data": {
    "id":0,"wf_id":0,"width":0,"height":0,"status":0,"file_id":0,"form_id":0,
    "pos_top":"","all_edit":0,"disabled":0,"duration":0,"pos_left":"","ty_state":0,
    "beginning":0,"condition":0,"module_id":0,"source_id":0,"step_name":"","target_id":0,
    "time_unit":0,"bpms_wf_id":0,"bpms_resp_id":0,"desc_file_id":0,"group_assign":0,
    "bpms_topic_id":0,"step_progress":0,"show_in_portal":0,"bpms_section_id":0,
    "bpms_category_id":0,"top_comment_author":0,"responsible_task_author":0
  },
  "error": {"status":0,"message":""},
  "success":0
}
```
`duration` + `time_unit` = همان جفت تعریف SLA که در بقیهٔ پروژه استفاده می‌شود (مثلاً `EghdamBazAnalyze_bot.lua`؛ `time_unit`: 1=دقیقه, 2=ساعت, 3=روز).

---

### `/api/todo/task/get` — دریافت اطلاعات اقدام

**Request:** `{"task_id": 0}`

---

### `/api/todo/task/list/get` — دریافت اطلاعات چند اقدام

**Request:**
```json
{"task_ids": [0]}
```
`task_ids` آرایه‌ای از `int64`.

---

### `/api/todo/task/status/set` — تغییر وضعیت اقدام (باز/بسته/موکول)

**Request:**
| Field | Type | Notes |
|---|---|---|
| `task_id` | int64 | |
| `status` | int32 | `1`=TASK_STATUS_OPEN, `2`=TASK_STATUS_CLOSE, `3`=TASK_STATUS_SUSPEND |

---

### `/api/todo/taskstep/status/set` — تغییر وضعیت مرحله اقدام

**Request:**
| Field | Type | Notes |
|---|---|---|
| `task_id` | int64 | |
| `step_id` | int64 | |
| `status` | int32 | `0`=Note, `1`=Completed, `2`=Confirmed, `3`=Rejected |

---

### `/api/todo/wf/addtask/get` — دریافت اطلاعات جریان کار اقدام

**Request:** `{"id": 0}` (شناسه جریان کار)

---

### `/api/todo/wf/get` — دریافت اطلاعات جریان کار

**Request:** `{"id": 0}` (شناسه جریان کار)

---

### `/api/todo/task/comment/add` — افزودن کامنت به مرحله اقدام

**Request:**
| Field | Type | Notes |
|---|---|---|
| `task_id` | int64 | |
| `task_step_id` | int64 | شناسهٔ مرحلهٔ اقدام |
| `comment_content` | string | |
| `type` | int32 | `1`=top comment، `0`=کامنت معمولی |
| `author_id` | int64 | جدول `profile_main` |
| `src_module_id` | int32 | شناسه ماژول مبدأ لینک (جدول `HOME_MODULE_LIST`) |
| `files` | array\<object\> | هرکدام: `{id, size(byte), type(1=FOLDER,2=FILE), filename, filepath, author_id, mime_type}` |

---

### `/api/todo/taskstep/update` — افزودن مرحله با مسئول و مهلت در اقدام

**Request:**
| Field | Type | Notes |
|---|---|---|
| `task_id` | int64 | |
| `task_step_id` | int64 | شناسهٔ مرحله‌ای که این API از آن فراخوانی می‌شود |
| `steps` | array\<object\> | هرکدام: `{step_id, end_date, responsible_id}` |

---

## ماژول «مخاطب من» / CRM — module_id `14`

Full module has **20+ endpoints** on page 1 alone (portal: `?page=/apidoc/index&module_id=14`; a page 2 exists,
not yet crawled). Documented below: 12 core CRUD/relationship endpoints. Not yet documented from page 1:
`portal/add` (ایجاد کاربر پورتال), `assign/add`+`assign/del`+`assign/get` (مطلع), `responsible/add`+`responsible/del`+`responsible/get` (مسئول), `notify/add`. See also `docs/context/CrmCustomerUiDiscovery.md` (module_id=14 confirmed there independently).

### Shared «Profile» object (used by `create` and `update`)

Both endpoints share (almost) the same nested `profile` object. Top-level fields:

| Field | Type | Notes |
|---|---|---|
| `name` / `last_name` | string | |
| `gender` | int32 | enum `EnUserSex`: `1`=MALE, `2`=FEMALE |
| `user_type` | int32 | enum `EnUserTypes`: `3`=NATURAL (حقیقی), `4`=LEGAL (حقوقی) |
| `email` | array\<{id, value}\> | |
| `phone` | array\<{id, ext, type, value, country}\> | `type` enum `EnPhoneType`: `2`=HOME, `3`=WORK, `4`=FAX |
| `mobile` | array\<{id, value, country}\> | `country` = کد کشور از `country_list.ini` (ایران=۳۶۴) |
| `national_code` | array\<{id, value, country}\> | |
| `address` | object `{home: {...}, work: {...}}` | هرکدام: `city, state, address, zip_code, country_code, loc_x, loc_y` |
| `birth_date` / `date_of_issue` | int64 (date) | |
| `patronymic` | string | نام پدر |
| `birth_place` / `identity_no` / `identity_serial_no` / `place_of_issue` | string | |
| `nationality` / `passport_no` | string | |
| `large_photo` / `small_photo` | object | `{size, filename, filepath, mime_type, data_base64, src_module_id}` (فقط در `update`) |

`update` علاوه‌بر این، سطح بالاتر (بیرون از `profile`) فیلدهای زیادی برای شرکت/آدرس/کارت/حساب دارد — رده‌بندی
اصلی:

| Field | Type | Notes |
|---|---|---|
| `id` | int64 | **شناسه مشتری (الزامی در `update`)** |
| `profile` | object | همان Profile object بالا |
| `contact` | array\<object\> | لیست رابط‌ها — schema مشترک با `contact/add` (پایین) |
| `address` | array\<object\> | آدرس‌های ماژول مشتری (جدا از `profile.address`): `{id, title, address, city, province, country, zip_code, home_phone, work_phone, mobile_phone, fax, latitude, longitude, comment}` |
| `card_info` | array\<object\> | کارت‌های اعتباری: `{id, iban, bank_name, card_type, card_holder, card_number, expiry_date, deposit_type, security_code, currency:{id,org_id}, comment}` |
| `account_info` | array\<object\> | حساب‌های بانکی: `{id, bank_name, account_number, iban, shaba, swift_code, routing, fedwire, bank_address, city, state, branch, country, currency:{id,org_id}, comment}` |
| `classify_persons` | array\<int64\> | رده‌های مشتری |
| `custom_field` | array\<{id, value}\> | فیلدهای سفارشی |
| `custom_form` | object `{data(json string), section_id}` | فرم سفارشی بخش |
| `company` / `job` / `website` / `station` / `reg_number` / `industry` / `number_personnel` / `personality_type` | — | فیلدهای «مشتری حقوقی» |
| `kpp` | string | مشتری حقیقی: شماره پاسپورت؛ مشتری حقوقی: کد ملی مدیرعامل |
| `tin` | string | کد اقتصادی |
| `deleted_email` / `deleted_phone` / `deleted_mobile` / `deleted_national_code` / `deleted_card` / `deleted_account` / `deleted_address` | array\<int64\> | شناسه‌هایی که باید حذف شوند (فقط `update`) |
| `section_id` / `profile_id` / `site_password` | — | فقط `create` |

### `/api/client/create` — ایجاد مشتری جدید

**Request:** `{profile: {...}, profile_id, section_id, site_password}` — بدنهٔ اصلی همان Profile object بالاست؛
`profile_id` برای لینک به یک پروفایل موجود، `section_id` بخش مقصد.

### `/api/client/update` — ویرایش اطلاعات مشتری (۹۲٪ تکمیل در پورتال)

**Request:** `id` (الزامی) + هر ترکیبی از فیلدهای «سطح بالا» و `profile` که در جدول بالا آمد. فیلدهای
`deleted_*` برای حذف موردی از آرایه‌ها (نه جایگزینی کل آرایه).

### `/api/client/get` — دریافت اطلاعات مشتری (۹۹٪ تکمیل در پورتال)

**Request:** `{"id": 0}` — پاسخ، تصویر آینه‌ای همان ساختار `update` است.

### `/api/client/list` — لیست مشتریان (۰٪ — بدون توضیح در پورتال)

**Request:**
```json
{"from": 0, "count": 0, "section_id": 0, "category_id": 0}
```
`from`/`count` = صفحه‌بندی. بدون توضیح رسمی در پورتال — قبل از استفاده در بات production تست کنید.

### `/api/client/check` — چک کردن وجود مشتری

با موبایل/ایمیل/کد ملی، وجود مشتری یا پروفایل مطابق را بررسی می‌کند.

**Request:**
```json
{"email":[{"value":""}], "mobile":[{"value":"","country":0}], "national_code":[{"value":"","country":0}]}
```
(فیلد `id` داخل هر آیتم آرایه در این درخواست کاربرد ندارد.)

### `/api/client/delete` — حذف دائم مشتری

**Request:** `{"id": 0}`

### `/api/client/moveToTrash` — حذف موقت مشتری (انتقال به حذف‌شده‌ها)

**Request:** `{"id": 0}`

### `/api/client/category/add` / `/api/client/category/del` — افزودن/حذف مشتری به/از رده

**Request:** `{"id": 0, "category_id": 0, "category_profile_id": 0}`
`category_id` = شناسه رده؛ `category_profile_id` = شناسه رده در پروفایل (شناسه گروه). در `category/add`: اگر
رده به بخشی تعلق دارد که مشتری از قبل در آن بخش عضو است، از رده فعلیِ آن بخش خارج و به رده جدید منتقل می‌شود.

### `/api/client/contact/add` / `/api/client/contact/del` — افزودن/حذف رابط مشتری

**Request:** `{"id": 0, "contact": [{...}]}`

هر آیتم `contact`:
| Field | Type | Notes |
|---|---|---|
| `type` | int32 | `1`=CONTACT_TYPE_CRM (مشتری تیمیار، دوطرفه ثبت می‌شود), `2`=CONTACT_TYPE_TEXT (غیر تیمیار), `3`=CONTACT_TYPE_REFERER (معرف، یک‌طرفه) |
| `contact_id` | int64 | شناسهٔ رابط (شناسه مشتری) |
| `contact_text` | string | عنوان رابط برای غیر-تیمیاری‌ها |
| `contact_phone` / `contact_comment` / `contact_position` | string | (در `contact/del` بی‌اثر) |
| `force_sign` / `login_portal` / `along_with_sign` | — | **استفاده نشده** (legacy fields) |

### `/api/client/add/comment` — ثبت توضیحات جدید برای مشتری

**Request:** `{"id": 0, "comment": "", "section_id": 0}`

---

## ماژول «تقویم» (Calendar/Events) — module_id `19`

فقط **۱۱ endpoint** — کل ماژول کرال شد (portal: `?page=/apidoc/index&module_id=19`). نکته: برخلاف `todo`/`client`،
مسیرها پیشوند یکسان ماژول ندارند — بعضی `/api/event/...`، بعضی مستقیم `/api/getCalendarEvents` هستند؛ دقیقاً
همان‌طور که در پورتال آمده استفاده شود. فیلدهای علامت‌دار با `*` در پورتال یعنی **الزامی**.

### `/api/getCalendarEvents` — دریافت مناسبت‌های یک تقویم

**Request:**
| Field | Type | Notes |
|---|---|---|
| `day` | int32 | بالای ۳۱ قبول نمی‌شود |
| `month` | int32 | بالای ۱۲ قبول نمی‌شود |
| `calendar_type` | int32 | `0`=میلادی, `1`=شمسی, `2`=قمری |
| `is_customform` | int32 | `true` برای گرفتن/تغییر تنظیمات کاستوم‌فرم |

### `/api/importCalendarEvents` — ثبت مناسبت برای روزهای سال

**Request:** آرایه‌ای از:
```json
[{"day":0, "month":0, "calendar_type":0, "events":[{"holiday":false, "description":"", "custom_form_data":""}]}]
```
`calendar_type`: `0`=میلادی, `1`=شمسی, `2`=قمری. برای **حذف** مناسبت یک روز، `events` را خالی بگذارید.

### `/api/calendar/getUserCalendars` — دریافت تقویم‌های کاربر

**Request:** `{"user_id": 0}`

### `/api/event/changeUserInviteStatus` — تغییر وضعیت افراد در جلسه (۹۴٪ تکمیل در پورتال)

**Request (همه الزامی):**
| Field | Type | Notes |
|---|---|---|
| `user_id`* | int64 | شناسه کاربر |
| `event_id`* | int64 | شناسه مناسبت |
| `cur_user_id`* | int64 | شناسه کاربری که از سیستم استفاده می‌کند |
| `user_event_invite_status`* | int32 | `2`=accept, `3`=decline |

⚠️ ایونت باید در حالت «بررسی» باشد.

### `/api/event/checkConcurrent` — چک همزمانی جلسات (۹۳٪ تکمیل در پورتال)

مشخصات جلساتی که تداخل دارند را برمی‌گرداند.

**Request:** `{"eve_id"*: 0, "user_id"*: 0, "cur_user_id"*: 0}`

### `/api/event/getEvent` — دریافت یک مناسبت

**Request:** `{"id"*: 0}`

### `/api/event/getEvents` — دریافت چندین مناسبت با تایپ‌های مختلف

**Request:**
| Field | Type | Notes |
|---|---|---|
| `type` | int32 | `1`=مطلع، `2`=دعوت‌شده، `4`=ایجادکننده، `0`(پیش‌فرض)=همه |
| `module_id` | int64 | آیدی ماژول |
| `creator_id`* | int64 | |
| `cur_user_id` | int64 | |

### `/api/event/updateEvent` — بروزرسانی مناسبت

**Request:** `{"event"*: {...}, "user_ids"*: [int64]}`

`event` (فقط `id`* و `calendar_id`* الزامی‌اند؛ بقیه بدون توضیح در پورتال، فقط نام فیلد):
`uid, name, tzid, color, place, status, chat_id, place_id, folder_id, module_id, parent_id, tzid_flag,
alarm_type, creator_id, date_alarm, date_start, date_create, date_finish, date_modify, description,
modifier_id, period_type, end_of_month, period_until, bot_alarm_type, bot_date_alarm, invite_user_id,
online_meeting, sms_alarm_type, sms_date_alarm, period_interval, concurrent_place, invite_user_status`.

### `/api/event/addInvitedUser` / `/api/event/deleteInvitedUser` — افزودن/حذف کاربر از لیست مدعوین

**Request:** `{"user_id": 0, "event_id": 0}`

### `/api/event/addComment` — افزودن توضیحات به مناسبت

**Request:** `{"user_id": 0, "event_id": 0, "description": ""}`

---

## ماژول «پیامک» (SMS) — module_id `16`

فقط **۳ endpoint** — کل ماژول کرال شد (portal: `?page=/apidoc/index&module_id=16`).

### `/api/sms/send` — ارسال پیامک (تکی و گروهی)

**Request:**
| Field | Type | Notes |
|---|---|---|
| `box_id` | int64 | شناسه صندوق |
| `is_bulk` | int32 | بالک هست یا خیر |
| `module_id` | int32 | شناسه ماژولی که پیامک از سمت آن ارسال می‌شود |
| `todo_step_id` | int64 | در صورت ارسال از یک مرحلهٔ اقدام |
| `todo_task_id` | int64 | برای لینک پیامک به یک اقدام |
| `messages` | array\<object\> | لیست پیامک‌ها — هرکدام: `{content, send_to: {profile_ids: [int64], mobile_numbers: [{value, country}]}}` |

`send_to.profile_ids`: پیامک به **تمام** شماره موبایل‌های ثبت‌شده برای آن پروفایل ارسال می‌شود.

### `/api/sms/receive` — دریافت پیامک

**Request:** `{"to": "", "from": "", "content": ""}`

### `/api/sms/getMessageIdByTaskIdAndStepID` — گرفتن شناسه پیامک با شناسه اقدام و گام

**Request:** `{"task_id": 0, "step_id": 0}`

---

## ماژول «پست» (Email/Outlook) — module_id `12`

**۱۳ endpoint** — کل ماژول کرال شد (portal: `?page=/apidoc/index&module_id=12`).

### `/api/email/emailmsgadd` — ایجاد/ارسال ایمیل (۷۳٪ تکمیل در پورتال)

**Request:**
| Field | Type | Notes |
|---|---|---|
| `address` | string | **الزامی.** لیست گیرندگان جدا‌شده با `,` |
| `email_content` | string | **الزامی.** |
| `email_subject` | string | خالی → `SUBJECT_EMPTY` |
| `box_id` | int64 | خالی/۰ → صندوق پیش‌فرض |
| `extra_header` / `extra_header_value` | string | |

⚠️ **مثال پورتال از امضای متفاوتی استفاده می‌کند** (`teamyar.call_api(context, req_param, api_param)` با
`api_param={module_id, path}`) — این با امضای استانداردِ تأییدشده در بقیهٔ این سند (`teamyar.call_api(module_id,
url, params)`) فرق دارد و احتمالاً یک نمونهٔ قدیمی/منسوخ است (تاریخ تغییر ۱۴۰۲/۰۷/۰۸، پایین‌ترین پیشرفت این
ماژول). قبل از استفاده در بات production با امضای استاندارد تست کنید.

Success: `{"success":true,"data":{"email_message_id":4281}}`
Failure: `{"success":false,"error":{"status":-8,"message":"ERR_INVALID_BOX"}}` یا پیام «فیلد ادرس خالی میباشد»

### `/api/email/getAddresses` / `getAddressesCount` / `getAssignedCount` / `getMessage` / `getMessageDetail` — بر اساس شناسه پیام

**Request (همه):** `{"message_id": 0}`
(`getMessage` ۷۸٪ تکمیل، `getMessageDetail` ۰٪/بدون توضیح در پورتال.)

### `/api/email/getAssigned` — گرفتن مطلعین

**Request:** `{"message_id": 0, "count": 0}`

### `/api/email/getMessagesByLinkId` — گرفتن ایمیل‌ها با استفاده از لینک (۸۱٪ تکمیل در پورتال)

**Request:** `{"from": 0, "count": 0, "link_id": 0, "link_type": 0, "module_id": 0}`
`from`/`count` = صفحه‌بندی؛ `link_id`+`link_type`+`module_id` = مشخص‌کنندهٔ رکورد لینک‌شده (همان الگوی
`src_link_id`/`src_type`/`src_module_id` که در سایر APIهای لینک این سند دیده می‌شود).

### `/api/email/getMessagesCountByLinkId` / `getMessagesTotalCountByLinkId` — تعداد ایمیل‌های یک لینک

**Request:** `{"link_id": 0, "link_type": 0, "module_id": 0}` (`getMessagesCountByLinkId` علاوه‌بر این `from`/`count` هم می‌گیرد برای شمارش بازه‌ای)

### `/api/email/send` — ارسال ایمیل (۹۱٪ تکمیل در پورتال) / `/api/email/mailcore/send` (۰٪، schema یکسان)

**Request:** `{message: {...}, file_ids: [int64], addresses: [{...}], extra_header, extra_content_file, extra_header_value, extra_content_file_name, extra_content_file_mime_type}`

مهم‌ترین فیلدهای `message`:
| Field | Type | Notes |
|---|---|---|
| `box_id` / `content` / `subject` | — | صندوق، محتوا، موضوع |
| `task_id` / `step_id` | int64 | لینک به اقدام/مرحله |
| `module_id` | int64 | |
| `send_flag` | int32 | `1`=EMAIL_STATUS_SEND, `2`=SAVE, `4`=NOT_SEND, `5`=IN_SEND_QUEUE, `6`=IN_SENDING |
| `task_status` | int32 | `1`=OPEN, `2`=CLOSE, `3`=SUSPEND (همون enum توی ماژول اقدام) |
| `files` | array\<object\> | `{id, size, type(1=FOLDER,2=FILE), filename, filepath, author_id, mime_type, base64_content}` |
| `is_archived` | boolean | |
| `auto_reply` | int32 | `1` یعنی پاسخ خودکار |

`addresses` (هرکدام): `{id, flag, address, group_id, user_name, message_id}` — `flag`: `1`=TO, `2`=CC, `3`=BCC,
`4`=FROM.

### `/api/email/message/comment/add` — افزودن کامنت به ایمیل (۰٪، بدون توضیح در پورتال)

**Request:** `{"message_id": 0, "content": "", "src_module_id": 0, "files": [{...}]}` (فرمت `files` مشابه بالا)

---

## ماژول «فروش» (Sales) — module_id `23`

ماژول کلاً **۱۰ endpoint** دارد. مستندشده در ادامه: ۵ تای درخواستی (۱، ۲، ۷، ۸، ۱۰). باقی‌مانده (مستندنشده):
`sales/pricelist/update` (#3), `sales/get_custom_form` (#4), `sales/get_sales_agents` (#5),
`sales/update_invoice_history` (#6), `sales/back_status` (#9).

### `/api/invoice/create` — ایجاد فاکتور فروش پیش‌نویس

معادل درون‌ریزی فاکتور فروش، در تب پیش‌نویس ثبت می‌شود.

**Request:** `{invoice: {...}, setting: {setting_v_added}, products: [{...}], additions: [{...}]}`

`invoice` (مهم‌ترین‌ها؛ همه بر اساس **کد**، نه شناسهٔ عددی مستقیم — یعنی `client_code`, `sales_agent_code` و
مشابه، الگوی کدمحورِ همین API است، برخلاف بقیهٔ APIهای این سند که عمدتاً شناسهٔ عددی می‌گیرند):
| Field | Type | Notes |
|---|---|---|
| `org_id` | int64 | شناسه شعبه |
| `invoice_id` | int64 | شماره فاکتور؛ `0` = شماره سیستمی |
| `type` | int32 | نوع عملیات فروش |
| `run_date` / `delivery_date` | int64 | تاریخ فاکتور / تحویل |
| `solary_delivery_date` | string | تاریخ تحویل شمسی |
| `user_type` | int32 | `3`=حقیقی, `4`=حقوقی |
| `client_code` / `client_mobile` / `client_national_code` / `client_parent` | string | مشخصات مشتری (کد گروه حسابداری اشخاص برای `client_parent`) |
| `sales_agent_code` / `sales_center_code` | string | عامل/مرکز فروش |
| `crm_section_id` | int64 | شناسه رده مشتری |
| `bill_type` / `bill_template` / `payment_type` | int32 | |
| `symbol_name` | string | نام ارز |
| `project_code` / `floating_code` | string | |
| `portal` | int32 | نشانگر سفارش پورتال |
| `tag_ids` | array\<int64\> | برچسب‌ها |
| `import_id` | int64 | شناسه عملیات درون‌ریزی‌شده (در صورت import) |

`products` (هر آیتم): `{product_code, quantity, fee, discount, value_added, unit_id, manual_unit_id, manual_weight, attribute_id, stock_code, symbol_rate, date_delivery, solary_date_delivery, quantity_confirmed, note}`
`additions` (اضافات/کسورات؛ هر آیتم): `{title, effect, quantity, account_code, center_code, client_code, project_code, floating_code}`

### `/api/invoice/get` — گرفتن اطلاعات فاکتور (۹۶٪ تکمیل در پورتال)

خروجی معادل برون‌ریزی فاکتور فروش.

**Request:** `{"org_id": 0, "invoice_id": 0}`

### `/api/sales/update_moadian_status` — تغییر وضعیت مودیان برای فاکتور

**Request:** `{"org_id": 0, "invoice_id": 0, "moadian_status": 0}`

### `/api/sales/cancel_delete_invoice` — ابطال و حذف عملیات فروش

**Request:**
| Field | Type | Notes |
|---|---|---|
| `org_id` | int64 | |
| `invoice_id` | int64 | |
| `be_cancel` | int32 | غیرصفر → فاکتور باطل شود |
| `be_delete` | int32 | غیرصفر → فاکتور باطل **و** حذف شود |
| `keep_reference` | int32 | غیرصفر → حواله تعدادی عطف به فاکتور حفظ شود، صفر → حذف شود (سند مبنا از سمت خدمات همیشه حفظ می‌شود) |

### `/api/sales/create_settlement` — ایجاد تسویه برای فاکتور فروش (تب اجرا)

**Request:** `{"org_id": 0, "invoice_id": 0, "settlements": [{...}]}`

هر آیتم `settlements`: `{date, type(4=نقدی، 5=حسابها), price, account_code, center_code, client_code, project_code, floating_code, symbol_name, symbol_rate}`

---

## ماژول «پروژه» (Project) — module_id `20`

ماژول کلاً **۳۸ endpoint** دارد (۲ صفحه). مستندشده در ادامه: ۵ تای درخواستی (#3، #4، #5، #15، #18).

### `/api/project/AddProject` — ایجاد پروژه جدید (#3)

**Request:**
| Field | Type | Notes |
|---|---|---|
| `title` | string | **الزامی** |
| `category_id` | int32 | **الزامی** — رده‌ای که پروژه در آن ثبت می‌شود |
| `date_start` / `date_limit` | int64 | تاریخ شروع/پایان واقعی؛ نامعتبر یا خالی → به‌ترتیب امروز / امروز+۷ |
| `planning_date_start` / `planning_date_limit` | int64 | همان منطق برای برنامه‌ریزی |
| `description` | string | |
| `link_stage_sync` | int32 | همگام‌سازی مراحل لینک‌شده |
| `show_user_tasks` / `portal_perm_export` / `portal_perm_add_task` | int32 | نمایش/دسترسی‌های پورتال |
| `show_amount_col_portal` / `show_amount_sum_col_portal` / `show_participation_col_portal` / `show_progress_col_portal` / `show_stage_description_portal` / `show_project_description_portal` / `show_first_step_to_all` | int32 | نمایش ستون‌های مختلف در پورتال |

همهٔ فیلدهای `int32` بالا (به‌جز `category_id`) فقط ۰/۱ می‌پذیرند؛ هر مقدار غیر از ۱ = صفر در نظر گرفته می‌شود.

**Example:**
```lua
req_param = {title="salam", description="377", category_id=11, date_start=133437283800000000, date_limit=133442467800000000, planning_date_start=133437283800000000, planning_date_limit=133442467800000000, show_user_tasks=1, show_first_step_to_all=1, show_amount_col_portal=1, show_amount_sum_col_portal=1, show_participation_col_portal=1, show_project_description_portal=1, show_progress_col_portal=1, portal_perm_add_task=1, portal_perm_export=1, link_stage_sync=1};
res = teamyar.call_api(20, "/api/project/AddProject", req_param);
teamyar.write_result(json.encode(res))
```
Success: `{"success":true,"data":{"project_id":261}}`
Failure: `{"success":false,"error":{"status":-8,"message":""}}`

### `/api/project/gettopicprojects` — گرفتن نام/شناسه پروژه با شناسه موضوع (#4)

**Request:** `{"topic_id": 0}` (الزامی)

### `/api/project/checkExistHRCalendarsInProject` — بررسی وجود تقویم کاری پرسنلی در پروژه (#5)

**Request:** `{"id": 0}` (شناسه پروژه)

### `/api/project/getProject` — دریافت اطلاعات پروژه با شناسه پروژه (#15)

**Request:** `{"id": 0}` (شناسه پروژه)

### `/api/project/getProjectStageDescription` — دریافت توضیحات مرحله و هزینه پروژه (#18)

**Request:** `{"id": 0}` (شناسه **مرحله**، نه پروژه)

---

## ماژول «حسابداری» (Accounting) — module_id `10`

ماژول کلاً **۲۴ endpoint** دارد (۲ صفحه؛ کل ماژول شماره‌گذاری شد). مستندشده در ادامه: ۱۳ تای درخواستی
(#۵، ۷، ۹، ۱۰، ۱۱، ۱۷، ۱۸، ۱۹، ۲۰، ۲۱، ۲۲، ۲۳، ۲۴). نگاشت کامل شمارهٔ پورتال → مسیر (برای مرجع آینده):

| # | مسیر | # | مسیر |
|---|---|---|---|
| 1 | `symbol/update` | 13 | `fiscalYear/list` |
| 2 | `symbol/currencyFee/get` | 14 | `organization/get` |
| 3 | `symbol/currencyFeeList/get` | 15 | `organization/list` |
| 4 | `symbol/get` | 16 | `pettyCashDetail/create` |
| **5** | **`request/delete`** | **17** | **`newClient/create`** |
| 6 | `request/get` | **18** | **`pdc/cheque/create`** |
| **7** | **`voucher/create`** | **19** | **`pdc/cash/create`** |
| 8 | `currency/convert/get` | **20** | **`pdc/unit/list`** |
| **9** | **`request/salary/get`** | **21** | **`pdc/cash/delete`** |
| **10** | **`voucher/records_update`** | **22** | **`pdc/cheque/delete`** |
| **11** | **`account_info/get`** | **23** | **`request/create`** |
| 12 | `fiscalYear/get` | **24** | **`request/update`** |

### Shared «Account holder» object (استفاده در `pdc/cheque/create`, `pdc/cash/create`)

هرجا `transactor` / `receiver` / `account` دیده می‌شود، این ساختار است:
```json
{"center_id":0, "client_id":0, "account_id":0, "project_id":0, "floating_id":0, "force_client":0, "force_project":0, "force_floating":0, "force_cost_center":0, "force_revenue_center":0}
```
`force_*` = آیا این بُعد برای این حساب اجباری است (۰/۱).

### Shared «Voucher record» object (استفاده در `voucher/create` و `voucher/records_update`)

هر رکورد سند: `{id, pdc, cash, date, type, action, debtor, org_id, pdc_id, rel_id, cash_id, content, deleted, creditor, fee_rate, rel_type, tools_id, center_id, client_id, cost_rate, fx_debtor, row_index, symbol_id, account_id, project_id, voucher_id, date_create, date_modify, floating_id, fx_creditor, number_sort, symbol_rate, reference_id, voucher_code, voucher_date, voucher_type, manual_ref_id, rel_record_id, reference_type, voucher_status, voucher_deleted}`.
`pdc`: `0`=normal, `1`=pdc(چک), `2`=bill, `3`=pos, `4`=cash.

### `/api/request/delete` — حذف درخواست خزانه‌داری (#5)

**Request:** `{"org_id": 0, "module_id": 0, "invoice_id": 0, "request_id": 0}`

### `/api/voucher/create` — درج سند حسابداری (#7)

**Request:** `{"org_id": 0, "module_id": 0, "reffer_name": "", "voucher_date": 0, "voucher_records": [<Voucher record>, ...]}`
(در `voucher_records` برای ایجاد معمولاً فقط زیرمجموعهٔ کوچکی از فیلدها لازم است — نمونهٔ زیر.)

⚠️ **مثال پورتال از یک الگوی OOP سفارشی (`apiBase:init():setModuleId():setPath():setParams().run()`) و امضای
`teamyar.call_api(context, dataParams, dataApi)` استفاده می‌کند** — این با امضای استانداردِ تأییدشده در بقیهٔ
این سند (`teamyar.call_api(module_id, url, params)`) فرق دارد؛ مثل نمونهٔ `emailmsgadd`، احتمالاً الگوی
قدیمی/محلیِ همون تیم است، نه یک قرارداد جایگزین رسمی. با امضای استاندارد امتحان کنید مگر خلافش تأیید شود.

**Example (پورتال، بازنویسی‌شده با تمرکز روی دادهٔ واقعی — نه فراخوانی):**
```lua
req_param = {
  org_id = 1, module_id = 10, reffer_name = "TeamYar", voucher_date = 133405794000000000,
  voucher_records = {
    {debtor = 1200000, org_id = 1, account_id = 932, center_id = 5, symbol_id = 4, fx_debtor = 2},
    {creditor = 1200000, org_id = 1, account_id = 693, floating_id = 4, symbol_id = 4, fx_creditor = 2},
  },
};
res = teamyar.call_api(10, "/api/voucher/create", req_param);
```
پاسخ شامل `data.error_data` (یک JSON دیگر، باید دوباره decode شود) با `record.voucher_id` است — طبق نمونهٔ
پورتال: `json.decode(json.decode(res.data.error_data).record.voucher_id)`. **این ساختار پاسخ عجیب (موفقیت در
`error_data`) تأییدنشده با روش استاندارد است** — قبل از اتکا در بات production حتماً تست کنید.

### `/api/request/salary/get` — گرفتن جزئیات درخواست حقوق و دستمزد (#9)

**Request:** `{"org_id": 0, "module_id": 0, "invoice_id": 0, "request_id": 0}`

### `/api/voucher/records_update` — آپدیت شرح رکورد حسابداری، گروهی (#10)

**Request:** آرایه‌ای از `<Voucher record>` (همان schema بالا؛ `id` برای مشخص‌کردن رکورد هدف لازم است).

### `/api/account_info/get` — دریافت بدهکار/بستانکار/ماندهٔ یک حساب (#11)

**Request:** `{"id": 0, "type": 0, "org_id": 0, "symbol_id": 0, "start_date": 0, "end_date": 0}`

### `/api/newClient/create` — ایجاد حساب (Account، نه CRM) (#17)

⚠️ این یک entity «حساب» جداگانه است، مرتبط با `dic_id` (=user_id) — **نه** `module_id=14` CRM. توضیح کامل در
`docs/context/CrmCustomerUiDiscovery.md`.

**Request:** `{"name": "", "note": "", "dic_id": 0, "org_id": 0, "parent_id": 0, "account_type": 0, "status_account": 0, "perm_parent_allow": 0}`

### `/api/pdc/cheque/create` — ثبت چک دریافتنی/پرداختنی (#18)

**Request:** `{"org_id": 0, "status": 0, "cheques": [{...}]}`
`status`: `0`=پیش‌فرض، `1`=نزد صندوق(دریافتنی)/پاس‌نشده(پرداختنی).

هر آیتم `cheques`:
| Field | Type | Notes |
|---|---|---|
| `pdc_type` | int32 | `1`=پرداختنی, `2`=دریافتنی |
| `amount` / `note` / `serial` / `holder` / `pay_to` / `branch` | string | |
| `bank_name` / `branch_code` / `account_number` / `shaba_number` / `national_code` / `sayyad_number` / `back_number` / `cheque_serie` | string | |
| `issue_date` / `export_date` | int64 | تاریخ سررسید / صدور |
| `transactor` | object | **Account holder** (بالا) — دریافت‌کننده/پرداخت‌کننده |
| `invoices` | array\<{id, amount, invoice_id, account:\<Account holder\>}\> | تسویه با فاکتور |
| `requests` | array\<int64\> | شناسهٔ درخواست‌ها |
| `commercial_type` | int32 | `1`=تجاری, `2`=غیرتجاری |
| `is_opening` | int32 | چک افتتاحیه |
| `unit_id` / `cheque_book` / `pdc_bank_id` / `bank_account_id` / `client_id` / `floating_id` / `decimal_number` / `guarantee_type` / `pdc_category` / `sayyad_register` | — | |

### `/api/pdc/cash/create` — ثبت نقد/فیش/کارت‌خوان (#19، ۰٪ — بدون توضیح در پورتال)

**Request:** `{"org_id": 0, "unit_id": 0, "pdc_type": 0, "cashes": [{...}]}`

هر آیتم `cashes`: `{kind, note, type, amount, pos_id, ref_id, ref_type, center_id, client_id, symbol_id, invoice_id, project_id, date_create, floating_id, symbol_rate, amount_symbol, serial_number, bank_account_id, receiver:<Account holder>, requests: [int64]}`

### `/api/pdc/unit/list` — لیست واحدهای PDC (#20، ۰٪)

**Request:** `{"org_id": 0, "pdc_type": 0}`

### `/api/pdc/cash/delete` / `/api/pdc/cheque/delete` — حذف نقد/چک (#21، #22، هردو ۰٪)

**Request (هردو، همه الزامی):** `{"id"*: 0, "org_id"*: 0}`

### `/api/request/create` — ایجاد درخواست خزانه‌داری (#23، ۰٪)

**Request:**
| Field | Type | Notes |
|---|---|---|
| `org_id`* | int64 | **الزامی** |
| `request_date`* | int64 | **الزامی** |
| `request_type`* | int32 | **الزامی** |
| `note` / `requester_id` / `request_number` | — | |
| `task_id` / `step_id` | int64 | لینک به اقدام/مرحله |
| `symbol_id` | int64 | |
| `records` | array\<object\> | هرکدام: `{id, amount, module_id, symbol_id, invoice_id, symbol_rate, amount_input, details: [{id, type, amount, description, center_id, client_id, account_id, project_id, floating_id, symbol_id, symbol_rate, currency_amount}]}` |

### `/api/request/update` — ویرایش درخواست خزانه‌داری (#24، ۰٪)

**Request:** همان schema بالا + `id`* (الزامی) و دو فیلد اضافه برای حذف موردی: `deleted_detail_ids: [int64]`, `deleted_record_ids: [int64]`. (در این endpoint هیچ‌کدام از `request_date`/`request_type` الزامی علامت‌گذاری نشده‌اند.)

---

## ماژول «پرسنلی» (HR) — module_id `13` — **کرال‌نشده، schema موجود نیست**

کاربر (۱۴۰۵/۰۶/۰۶) از فهرست apidoc پورتال اسکرین‌شات فرستاد. **مسیر و عنوان** این ۱۱ endpoint از
آن اسکرین‌شات ثبت شده، ولی **هیچ‌کدام schema درخواست/پاسخ ندارند** — ماژول ۱۳ هنوز مثل ماژول‌های
۸/۱۴/۱۹ کرال نشده است. قبل از استفاده از هرکدام در یک بات، باید صفحهٔ
`?page=/apidoc/index&module_id=13` باز و فیلدهای هرکدام ثبت شود.

| مسیر | عنوان (از پورتال) | تکمیل | آخرین تغییر | وضعیت schema |
|---|---|---|---|---|
| `/api/hr/personneladd` | افزودن اطلاعات پرونده کارمندان (ایجاد یا ویرایش پرسنل) | ۹۴٪ | ۱۴۰۴/۱۲/۰۴ | ❌ ندارد |
| `/api/hr/calendarDaysUpdate` | آپدیت روزهای تعطیل در تقویم (تعطیل/غیرتعطیل کردن روزها) | ۱۰۰٪ | ۱۴۰۴/۱۲/۰۴ | ❌ ندارد |
| `/api/hr/hiringGroupsGet` | لیست گروه استخدام‌ها در تنظیمات احکام | ۱۰۰٪ | ۱۴۰۲/۱۲/۱۴ | ❌ ندارد |
| `/api/hr/orderTypesGet` | انواع حکم در تنظیمات حکم | ۱۰۰٪ | ۱۴۰۲/۱۲/۱۴ | ❌ ندارد |
| `/api/hr/ordersAdd` | ایجاد احکام به صورت گروهی | ۱۰۰٪ | ۱۴۰۴/۱۲/۰۴ | ❌ ندارد |
| `/api/hr/leaveTransferGet` | دریافت مقدار مانده مرخصی (بر اساس آخرین حکم یا تاریخ ورودی) | ۸۸٪ | ۱۴۰۳/۱۱/۰۷ | **✅ schema ثبت شد — پایین را ببینید** |
| `/api/hr/vacation_update` | ایجاد یا ویرایش مرخصی/مأموریت | ۱۰۰٪ | ۱۴۰۴/۰۸/۰۳ | ❌ ندارد |
| `/api/hr/orderInDateGet` | دریافت حکم فعال کارمند در یک تاریخ مشخص | ۹۸٪ | ۱۴۰۴/۱۲/۰۴ | **✅ schema ثبت شد — پایین را ببینید** |
| `/api/hr/profileSupervisorGet` | دریافت سرپرست تعیین‌شده در حکم فعال کاربر در شعبهٔ مربوطه | ۱۰۰٪ | ۱۴۰۴/۱۲/۰۴ | ❌ ندارد |
| `/api/hr/loanUpdate` | — (بدون توضیح در پورتال) | ۰٪ | — | ❌ ندارد |
| `/api/hr/baseParamValueUpdate` | — (بدون توضیح در پورتال) | ۰٪ | — | ❌ ندارد |

**نکتهٔ مهم برای `hr_companion_report_bot.lua`:** سه مورد از این‌ها مستقیماً جایگزین کوئری/فرضی هستند
که آن بات الان دارد و باید بعد از گرفتن schema به آن‌ها مهاجرت کند:
- `leaveTransferGet` → «مانده مرخصی» (الان از `hr_leave_remained_records` خوانده می‌شود و واحدش
  فرضِ tick است — این API عدد رسمی را می‌دهد و آن فرض را حذف می‌کند)
- `orderInDateGet` → حکم فعال در تاریخ (الان با SELECT روی `hr_personnel_order` گرفته می‌شود)
- `profileSupervisorGet` → سرپرست مستقیم (الان از `hr_personnel_order.SUPERVISOR` گرفته می‌شود)

---

## ماژول «گفتگو» (Chat) — module_id `9` — **کرال‌نشده، schema موجود نیست**

کاربر این سه endpoint را برای ساخت «گفتگوی تبریک تولد» نام برد. **هیچ‌کدام schema ثبت‌شده ندارند**؛
`hr_companion_report_bot.lua` فعلاً payload آن‌ها را بر پایهٔ ستون‌های تاییدشدهٔ جدول‌های
`chat_dialogs` / `chat_dialog_view` می‌سازد و پاسخ خام API را در خروجی JSON برمی‌گرداند تا در اولین
اجرای واقعی اصلاح شود.

| مسیر | نقش در جریان کار | payload فعلی بات (حدسی) |
|---|---|---|
| `/api/group/get` | گرفتن گروه گفتگو برای `chat_dialogs.GROUP_ID` | `{}` |
| `/api/dialog/add` | ساخت گفتگوی گروهی با عنوان قطعی | `{topic, group_id, type=1, author_id, status=0}` |
| `/api/assign/add` | افزودن («جوین» کردن) کاربر به گفتگو | `{dialog_id, user_id, user_ids}` |

⚠️ `assign/add` در فهرست ماژول CRM (۱۴) هم دیده شده (`/api/client/assign/add`، «مطلع» مشتری) —
آن یک endpoint دیگر است، نه همین. اگر ماژول گفتگو مسیر خودش را دارد، همان باید استفاده شود.

**هنوز نداریم و لازم است:** مسیر «باز کردن یک گفتگوی مشخص در رابط کاربری» (deep link). به همین دلیل
دکمهٔ «باز کردن گفتگو» عمداً از بات حذف شد تا لینک اشتباه ساخته نشود.

### `/api/hr/leaveTransferGet` — دریافت مقدار مانده مرخصی

schema از پورتال گرفته شد (۱۴۰۵/۰۶/۰۶، اسکرین‌شات کاربر — تب «درخواست» و «پاسخ»).
توضیح پورتال: «محاسبه مانده مرخصی به ازای هر پرسنل بر اساس آخرین حکم یا تاریخ ورودی».

**Request:** `{"id":0,"org_id":0,"date_to":0,"personnel_ids":[0]}`

| Field | Type | Format | Notes |
|---|---|---|---|
| `id` | integer | int64 | شناسهٔ **حکم** پرسنل (برای یک پرسنل) — اجباری نیست |
| `org_id` | integer | int64 | بدون توضیح در پورتال |
| `date_to` | integer | int64 | بررسی مانده مرخصی تا تاریخ واردشده — اجباری نیست |
| `personnel_ids` | array\<integer int64\> | | لیست شناسه‌های پرسنلی که مانده مرخصی آن‌ها درخواست می‌شود |

**Response:** `{"data":[{"value":0,"personnel_id":0}],"error":{"status":0,"message":""},"success":0}`

| Field | Type | Format | Notes |
|---|---|---|---|
| `data` | array | | لیست مانده مرخصی‌ها برای پرسنل درخواست‌شده |
| `data[].value` | integer | int64 | مقدار مانده مرخصی محاسبه‌شده |
| `data[].personnel_id` | integer | int64 | شناسهٔ پرسنل همان ردیف |
| `error.status` | integer | int32 | کد خطا |
| `error.message` | string | | پیام خطا |
| `success` | boolean | | جدول پورتال نوع را boolean اعلام کرده ولی **نمونهٔ خود پورتال `"success":0` است** |

⚠️ **دو نکتهٔ عملی (هر دو در `hr_companion_report_bot.lua` رعایت شده‌اند):**
1. `success` را هم `false` و هم عدد `0` باید «ناموفق» شمرد. در Lua مقایسهٔ `x == false` برای مقدار
   `0` غلط است، پس چک باید هر دو حالت را بگیرد (تابع `api_failed`).
2. **واحد `value` در پورتال اعلام نشده.** مثل بقیهٔ مدت‌های این اسکیما tick (۱۰۰ نانوثانیه) در نظر
   گرفته شده. مقدار خام در خروجی `format=json` بات نگه داشته می‌شود (`leave_balance_raw`) تا در
   اولین اجرای واقعی با عدد پنل رسمی مقایسه و در صورت نیاز ضریب اصلاح شود.

### `/api/hr/orderInDateGet` — دریافت حکم فعال کارمند در یک تاریخ مشخص

schema از پورتال گرفته شد (۱۴۰۵/۰۶/۰۶، اسکرین‌شات کاربر — تب «درخواست» و «پاسخ»).

**Request:** `{"date":0,"org_id":0,"personnel_id":0}`

| Field | Type | Format | Notes |
|---|---|---|---|
| `date` | integer | int64 | تاریخ مورد درخواست |
| `org_id` | integer | int64 | بدون توضیح در پورتال |
| `personnel_id` | integer | int64 | شناسهٔ کارمند مورد درخواست |

**Response:** `data` یک **object** است (نه آرایه)، شامل کل رکورد حکم:

```json
{"data":{"id":0,"type":0,"roles":[0],"org_id":0,"date_to":0,"taxable":0,"unit_id":0,"position":0,
"date_from":0,"insurable":0,"project_id":0,"sick_leave":0,"supervisor":0,"take_leave":0,
"calendar_id":0,"floating_id":0,"item_values":[{"value":0,"item_id":0}],"compact_rows":[0],
"personnel_id":0,"holiday_leave":0,"working_hours":0,"marriage_leave":0,"other_postions":"",
"leave_per_month":0,"max_delay_month":0,"other_calendars":[0],"salary_group_id":0,
"floating_enabled":0,"max_hourly_leave":0,"min_hourly_leave":0,"overtime_confirm":0,
"rest_during_work":0,"telework_request":0,"overtime_disabled":0,"cal_daily_vacation":0,
"over_floating_hour":0,"break_calculate_type":0,"leave_transfer_total":0,"pre_overtime_confirm":0,
"pre_overtime_disabled":0,"unemployment_insurance_exemption":0},
"error":{"status":0,"message":""},"success":0}
```

| گروه | فیلدها | توضیح |
|---|---|---|
| شناسه‌ها | `id` (شناسهٔ حکم)، `type` (نوع حکم)، `personnel_id`، `org_id` (شعبه)، `unit_id` (واحد سازمانی)، `position` (شغل)، `other_postions` (string، شناسهٔ سایر مشاغل)، `project_id`، `salary_group_id` (گروه استخدامی)، `supervisor` (سرپرست)، `calendar_id` (تقویم کاری)، `other_calendars[]`، `floating_id` (شناور)، `roles[]`، `compact_rows[]` (ردیف‌های پیمان) | همه int64 — API فقط **شناسه** می‌دهد، نه نام. برای نام باید به `org_units` / `hr_calendar` / `profile_main` join زد. |
| تاریخ | `date_from` (تاریخ شروع)، `date_to` (تاریخ انقضاء حکم) | int64 |
| مدت‌ها | `working_hours` (ساعت کاری)، `leave_per_month` (مرخصی استحقاقی در ماه)، `max_delay_month` (سقف تأخیر مجاز ماهانه)، `rest_during_work` (استراحت حین کار)، `max_hourly_leave`، `min_hourly_leave`، `over_floating_hour` (اضافه‌کار منعطف)، `sick_leave`، `holiday_leave`، `marriage_leave`، `leave_transfer_total` (انتقال مرخصی) | همه int64. **واحد هیچ‌کدام در پورتال اعلام نشده** — همان ابهامی که در `leaveTransferGet.value` هم هست. |
| پرچم‌ها (int32) | `taxable`، `insurable`، `floating_enabled`، `overtime_confirm`، `overtime_disabled`، `pre_overtime_confirm`، `pre_overtime_disabled`، `telework_request`، `cal_daily_vacation`، `break_calculate_type`، `take_leave`، `unemployment_insurance_exemption` | مقادیر ۰/۱ — بدون ابهام واحد، مستقیماً قابل نمایش. |
| پارامترهای حقوقی | `item_values[] = {value, item_id}` | مقدار هر پارامتر حقوقی حکم |

**استفادهٔ فعلی در `hr_companion_report_bot.lua`:** این API منبع اول «حکم فعال» است (واحد، تقویم،
سرپرست، بازهٔ حکم) و پرچم‌هایش کارت «تنظیمات حکم من» را می‌سازند. چون API فقط شناسه می‌دهد، نام‌ها با
یک کوئری کوچک resolve می‌شوند. اگر API خطا داد یا `id` معتبر برنگرداند، fallback به SELECT روی
`hr_personnel_order` است و منبعِ استفاده‌شده در `employment_source` و در کارت «منبع اطلاعات این صفحه»
نوشته می‌شود. فیلدهای دستهٔ «مدت‌ها» عمداً فقط در `format=json` هستند (به‌صورت `*_raw`) و در رابط
کاربری نمایش داده نمی‌شوند تا واحدشان روی دادهٔ زنده تایید شود.
