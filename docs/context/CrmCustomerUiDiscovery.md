# CRM Customer Module — UI Redesign Discovery Log

Working document for the `crm_customer_ui_bot` project. Discovery-first: no Route/Table/ID is
used in production code until it appears in this file as CONFIRMED.

Status legend: `CONFIRMED` (verified from a real screenshot/URL or existing repo bot code) ·
`CANDIDATE` (name pattern guess, needs `SHOW COLUMNS`/`INFORMATION_SCHEMA` check) · `UNKNOWN`.

---

## 1. Customer ID — CONFIRMED (see round-5 correction further down for the accurate version)

~~Single ID used across every `crm/history/*` route: `pa_client.ID`.~~ **SUPERSEDED — see the
"⚠️ SUPERSEDING CORRECTION (round 5)" section below.** Short version: the URL id is actually
`profile_user_info.ID` (= `pa_client.REFFERE_ID`), and `pa_client.ID` is a separate internal PK
reachable only via `SELECT ID FROM pa_client WHERE REFFERE_ID = {url_id}`. Kept the original
(wrong) reasoning below for the record, since it explains how the mistake happened.

Evidence: list screenshot shows column «شماره مشتری» = `36841` for «امیر امیری»; every
`crm/history/show_*` URL below uses `36841` as the path segment; `crm_rfm_bot.lua:320` already
queries `pa_client` with `id, name, org_id`.

No separate `CRM_ID` was observed in any screenshot so far — do not introduce one until a route
or column proves it exists.

**Update (bot 559 evidence)**: `pa_client.ID` is very likely just the platform-wide
`profile_id`/`USER_ID` — the same identity space used by `hr_personnels.profile_id`,
`profile_user_info.id`, `profile_nationalcode.USER_ID`. `/api/client/create`'s response returns
the new id as `data.profile_id`. Still need `SHOW COLUMNS pa_client` to see the literal column
name, but "one unified ID, no separate CRM_ID" is now a well-evidenced conclusion, not a guess.

---

## ⚠️ SUPERSEDING CORRECTION (2026-08-12, round 5) — the ID mapping above was WRONG

User caught this by sending two `/crm/client/edit/{ID}` screenshots side by side:
`edit/58211` → «مجتبی بقایی», `edit/36841` → «امیر امیری» — **two different, both-valid
people**, same route pattern, different IDs. This proved the "36841 renamed itself" theory from
round 3/4 was wrong — I had been silently assuming the ID in every URL was `pa_client.ID`. It
is not. Re-verified directly:

```sql
SELECT ID, NAME, SURNAME FROM profile_user_info WHERE ID=36841;
-- → 36841, "امیر", "امیری"   ✅ matches every screenshot exactly

SELECT ID, REFFERE_ID, NAME FROM pa_client WHERE REFFERE_ID=36841;
-- → pa_client.ID = 61622, REFFERE_ID=36841, NAME="امیر امیری"

SELECT ID, CLIENT_ID, CRM_ID, TITLE FROM sales_invoice WHERE CLIENT_ID=61622;
-- → invoice for "شماره سفارش 152686 - تحویل شده"  ✅ matches the فروش tab screenshot exactly, CRM_ID=0 on this row (not reliably populated)
```

**The real, corrected picture** — the earlier "pa_client.ID=36841 → مجتبی بقایی" finding was
real but was a *different, unrelated* record that happens to share the number 36841 in a
*different table's ID space*. No data was edited; I was matching the wrong column the whole
time.

```
Every URL you use — /crm/history/{action}/{ID}, /crm/client/edit/{ID}, list's «شماره مشتری» —
carries:

    profile_user_info.ID   ← THE public "Customer ID" (what humans see and click)
                            = pa_client.REFFERE_ID  (pa_client points TO this, not the reverse)

pa_client.ID  is a SEPARATE, INTERNAL bigint PK, only discoverable by reverse lookup:

    SELECT ID FROM pa_client WHERE REFFERE_ID = {url_id}

...and THAT internal pa_client.ID is what every CLIENT_ID foreign key on other tables
(sales_invoice.CLIENT_ID, purchase_invoice.CLIENT_ID, crm_favorite.CLIENT_ID, crm_notify.CLIENT_ID,
project_project_client.CLIENT_ID, crm_contacts.CLIENT_ID, crm_address.CLIENT_ID,
crm_history.CLIENT_ID, ...) actually points to — NOT the URL id directly.
```

**Practical consequence — every "READY" row in the Feature Matrix below needs a 2-step resolve,
not a direct filter**:
```sql
-- Step 1 (once per profile, cache it):
SELECT ID FROM pa_client WHERE REFFERE_ID = {url_id};   -- may return >1 row (e.g. multi-org clients) — don't assume exactly one

-- Step 2:
SELECT ... FROM sales_invoice WHERE CLIENT_ID IN (<step 1 ids>);
-- (same pattern for purchase_invoice, project_project_client, crm_contacts, crm_address,
--  crm_favorite, crm_notify, crm_history, crm_update_client_folder, ...)
```
`sales_invoice.CRM_ID` (and possibly other tables' `CRM_ID`) is **not reliably populated** — the
one real invoice found for client 36841 had `CRM_ID=0`. Do not use `CRM_ID` as a shortcut to
skip the two-step resolve; always go through `pa_client.REFFERE_ID → pa_client.ID → CLIENT_ID`.

This also means the earlier "ویرایش uses REFFERE_ID space, history uses pa_client.ID space"
conclusion (end of round 4) was **also wrong** — both route families use the **same** id
(`profile_user_info.ID` = `pa_client.REFFERE_ID`). Route Map table below corrected accordingly.

## 2. Route Map — CONFIRMED (from live screenshots, base URL `erp.bimehland.com`)

Base pattern: `https://erp.bimehland.com/?page=/crm/history/{action}/{CLIENT_ID}&section=2[&extra params]`

| Feature (Tab) | action segment | Full example URL | Extra params seen |
|---|---|---|---|
| اسناد | `show_documents` | `?page=/crm/history/show_documents/36841&section=2` | — |
| ایمیل | `show_emails` | `?page=/crm/history/show_emails/36841&section=2` | — |
| پروژه | `show_project` | `?page=/crm/history/show_project/36841&section=2` | — |
| گفتگو | `show_chats` | `?page=/crm/history/show_chats/36841&section=2` | — |
| رویدادها | `show_events` | `?page=/crm/history/show_events/36841&section=2` | — |
| پیامک | `show_sms` | `?page=/crm/history/show_sms/36841&section=2` | — |
| فروش | `show_sales` | `?page=/crm/history/show_sales/36841&section=2` | sub-tabs: سفارش فروش/پیش‌فاکتور/حواله/جواب/قرارداد/فاکتور فروش/برگشت از فروش |
| خرید | `show_purchase` | `?page=/crm/history/show_purchase/36841&section=2` | — |
| نظرسنجی | `show_poll` | `?page=/crm/history/show_poll/36841&section=2` | — |
| فایل‌های صوتی | `audio_files` | `?page=/crm/history/audio_files/36841&section=2&tab=3&type=audio&call_id=0` | `tab`, `type`, `call_id` |
| توضیحات | `show_comments` | `?page=/crm/history/show_comments/36841&section=2&tab=2&type=comment` | `tab`, `type`; page has inline "توضیحات جدید" create box (write-capable) |

| اقدام | `show_todo` | `?page=/crm/history/show_todo/36841&section=2` | strongly corroborates `todo_task*` (repo-confirmed elsewhere) as the backing table family |
| لیست مشتری | (index, not history) | `?page=/crm/index/all/&category=5` | `category=5` = «مشتریان سایت / Mobile140» segment — CANDIDATE join to `crm_classify_person`/`crm_section` (see `crm_rfm_bot.lua:308-316`), not yet confirmed by column |

### Still missing (asked user, 2026-08-12, still open)
- بررسی — is this a separate route, or is it the base landing view shown when a row is clicked (no URL change)? URL needed if it's a real route.
- ویرایش — URL needed (the "اطلاعات عمومی" form screenshot might be this one or بررسی — ambiguous, still need user to confirm which one that screenshot was and send the other one)
- ابزارها — no screenshot yet, URL needed

## 3.5 Internal REST API — CONFIRMED (client entity CRUD)

User supplied a screenshot of TeamYar's own API docs for the client entity. Base path
`/api/client/*` on the same domain (`erp.bimehland.com`), method not fully specified per
endpoint yet (docs screenshot only gave path + description).

| Endpoint | Purpose | Feature Matrix row it unlocks |
|---|---|---|
| `POST /api/client/create` | ایجاد مشتری جدید | ویرایش/ایجاد |
| `POST /api/client/update` | ویرایش اطلاعات مشتری | ویرایش |
| `GET/POST /api/client/get` | دریافت اطلاعات مشتری | بررسی / پروفایل |
| `POST /api/client/check` | چک وجود مشتری (موبایل/کدملی/شناسه پروفایل) | ویرایش/ایجاد (duplicate guard) |
| `POST /api/client/add/comment` | ثبت توضیحات جدید | توضیحات — matches the write-capable box already seen in `show_comments` screenshot |
| `POST /api/client/category/add` | افزودن مشتری به رده | رده/بخش (profile header table) |
| `POST /api/client/category/del` | حذف مشتری از رده | رده/بخش |
| `POST /api/client/contact/add` | افزودن رابط به مشتری | رابط section |
| `POST /api/client/contact/del` | حذف رابط از مشتری | رابط section |
| `POST /api/client/portal/add` | ایجاد کاربر پرتال برای مشتری | ابزارها (candidate) |
| `POST /api/client/assign/add` | افزودن «مطلع» به مشتری | **حل می‌کند: فیلتر «مطلع» در لیست واقعاً یک relation است، نه یک ستون ساده** |
| `POST /api/client/assign/del` | حذف «مطلع» از مشتری | همان |
| `GET/POST /api/client/assign/get` | دریافت لیست مطلعین | همان — می‌تواند به‌جای Query مستقیم DB برای «مطلع» استفاده شود |
| `POST /api/client/notify/add` | ارسال نوتیفای به کاربر درباره مشتری | رویدادها/اقدام (candidate) |
| `POST /api/client/responsible/add` | افزودن مسئول به مشتری | بررسی (Responsible field) |
| `POST /api/client/responsible/del` | حذف مسئول از مشتری | همان |

### `/api/client/add/comment` — CONFIRMED schema (2026-08-12, from user screenshot)

Request:
```json
{ "id": 0, "comment": "", "section_id": 0 }
```
- `id` (int64) — شناسه مشتری = **`pa_client.ID`** (same unified ID confirmed in section 1)
- `comment` (string) — متن توضیحات
- `section_id` (int64) — شناسه بخشی که توضیحات باید در آن بخش ثبت شود

**Candidate hypothesis (NOT confirmed)**: every `crm/history/*` URL carries `&section=2`. `section_id`
here may be the *same* concept as that `section` query param (both call it «بخش»). Needs a real
test call (or a second data point with a client in a different بخش) before treating as fact —
do not hardcode `section_id` from the URL param without verifying they're the same field.

Response schema (تب «پاسخ») not captured yet — asked user for it, plus schema for `client/get`
(needed to decide whether «بررسی» tab reads via this API vs. direct DB query).

### How to call it from a Lua bot — CONFIRMED (2026-08-12, from live bot 296 "Call Api", `cat_id=59`)

**Wrong guess corrected**: it is NOT `teamyar.call_url` (that's for *external* HTTP, confirmed
by `meli_sms_bot.lua` calling `rest.payamak-panel.com`). Internal `/api/*` calls use a
dedicated primitive:

```lua
local res = teamyar.call_api(module_id, url, params)
```

- `module_id` (int) — identifies which module the API belongs to. Bot 296's example uses
  `module_id = 17` for `/api/update_product_can_accept_serial` (a warehouse/product API, NOT
  CRM) — **the module_id for `/api/client/*` is still UNKNOWN, asked user**.
- `url` (string) — the API path, e.g. `/api/client/add/comment`.
- `params` (Lua table, passed directly — not `json.encode`'d first) — the request body fields.
- `res` — returned already as a Lua table; bot 296 just does `teamyar.write_result(json.encode(res))`.

**Auth question resolved**: `teamyar.call_api` needs no manual `Cookie`/`SID`/API-key — it runs
in-process inside the Teamyar engine and is authenticated implicitly by the module_id + the
bot's own execution context. (Bot 296's `secret_key`/`X-secret-key` header check is that
specific bot's *own* extra guard for exposing itself publicly to outside callers — not part of
the `teamyar.call_api` contract itself, and not something our bot needs to replicate since we
call `teamyar.call_api` directly, we don't go through bot 296.)

Full bot 296 source (`local_src: src/call_api_bot.lua`, pulled 2026-08-12):
```lua
local module_id = 17
local url = "/api/update_product_can_accept_serial"
local secret_key_fixed = "Tt@123456" --secret_key
---------------------------------------------------------------------------
local params = teamyar.get_input();
local header_secret_key = ""
local content_type = teamyar.get_http_header('secret-key');
if content_type ~= nil and #content_type > 0 then
 header_secret_key= content_type
end
if  secret_key_fixed == header_secret_key then
  local res =  teamyar.call_api(module_id,  url, params);
      teamyar.write_result(json.encode(res))
else
  teamyar.write_result("Key Is Invalid..!!")
end
```

Bot 559 — **obtained directly from user as a `.tybot` export** (`crm_by_api_2_2`, pulled into
[src/crm_by_api_2_2_bot.lua](../../src/crm_by_api_2_2_bot.lua)). This resolves almost every open
API question at once:

### `module_id` — CONFIRMED = 14 for the client/CRM module
```lua
teamyar.call_api(14, "/api/client/update", crm_info)
teamyar.call_api(14, "/api/client/create", info_new_crm)
teamyar.call_api(14, "/api/client/contact/add", payload)
```
(module_id `10` is a **different, related** module — `/api/newClient/create`, an "Account"
/حساب entity linked via `dic_id = user_id`, used for accounting/ledger — not the CRM client
itself. Don't conflate the two.)

### `/api/client/create` + `/api/client/update` — CONFIRMED request schema (from `build_payload`)
```lua
{
  id = 0,                          -- 0 = create, existing profile_id = update
  comment = "شناسه سایت:...",
  import_id = 0,                   -- external system's own id, optional/import-tracking use
  profile = {
    name = "...", last_name = "...",
    user_type = 3,                 -- 3=حقیقی (natural), 4=حقوقی (legal) — CONFIRMS ctypeAcl() in crm_rfm_bot.lua
    gender = 0,                    -- 0/1
    email = { { value = "..." } },
    mobile = { { value = "...", country = 364 } },
    national_code = { { value = "0012345678", country = 364 } },  -- always 10-digit zero-padded string
    address = {
      home = { city="", state="", address="", zip_code="", loc_x=0, loc_y=0, country_code=364 },
      work = { city="", state="", address="", zip_code="", loc_x=0, loc_y=0, country_code=364 }
    }
  },
  city_code = { name = "..." },
  state_code = { name = "..." },
  section_id = 0                   -- see «section_id vs section=2» note below
}
```
`create` response: `{ success = true, data = { profile_id = <new id> } }` — **CONFIRMS the new
client's ID field is literally called `profile_id`**, strong evidence `pa_client.ID` = the
platform-wide `profile_id`/`USER_ID` space (same one `hr_personnels.profile_id` and
`profile_user_info.id` use) — not a separate CRM-only sequence. Still want `SHOW COLUMNS
pa_client` to nail the exact column name, but this is no longer a blind guess.

### `section_id` vs URL `section=2` — CORRECTED, was wrong before
Bot config literally labels its `cat_id` field **"شناسه رده مشتری"** (customer's رده id) and
passes it straight into the API as `section_id` — so `section_id` = «رده» (category/segment),
matching the list page's `category=5` (Mobile140) concept.

**But this contradicts the earlier hypothesis**: this client (36841, «امیر امیری») sits under
«مشتریان سایت / Mobile140», which is `category=5` on the list URL — yet every one of their
`crm/history/*` URLs carries **`section=2`**, not `5`. So `section=2` is *not* this client's
رده/category — it's something else (possibly a fixed constant meaning "CRM module context" on
that route, unrelated to the client's own segment). **Correcting the earlier note**: do not
treat URL `section` and API `section_id` as the same field without a real test.

### Real DB tables — newly CONFIRMED (used directly in bot 559's `queryResult` calls)
| Table | Confirmed columns | Notes |
|---|---|---|
| `profile_nationalcode` | `USER_ID`, `NATIONAL_CODE` | |
| `profile_mobile` | `user_id` | |
| `profile_user_info` | `id`, `USER_TYPE` | `id` = same profile/user id space |
| `hr_personnels` | `profile_id` | used to skip CRM-update if the profile is actually an employee — **business rule: don't let CRM writes touch HR personnel profiles** |

Join pattern used to resolve an existing client by کد ملی:
```sql
SELECT DISTINCT n.USER_ID
FROM profile_nationalcode n
INNER JOIN profile_mobile m ON m.user_id = n.user_id
INNER JOIN profile_user_info p ON p.id = n.user_id
WHERE NATIONAL_CODE = ? AND p.USER_TYPE = ?
```

### Third HTTP mechanism spotted (not for our use, documented for completeness)
`teamyar.create_curl()` — a curl-object style API (`:connect / :sendRequest / :getResponse /
:getStatus / :disconnect / :release`) used in bot 559 to call an **external**, non-Teamyar API
(`ApiKey` header auth) for pulling source customer data. Irrelevant to calling
`erp.bimehland.com/api/client/*` — that's `teamyar.call_api`, per above — but worth knowing it
exists as a 3rd primitive alongside `call_url` (external, low-level) and `call_api` (internal).

Decision for Phase 1 vs Phase 2 (per project's own Read-vs-Write rule): **Phase 1 stays Read +
outbound links to the existing `crm/history/*` pages** (no API calls yet). Once Phase 1 is
`Stable`, Phase 2 wires the specific write actions above (توضیحات create first, since its
`show_comments` page already proves the workflow) through `teamyar.call_url` — after the auth
question is resolved and tested against a **non-production-affecting** call first (e.g.
`client/get`, read-only).

## 3. Feature Matrix (updated)

| Feature | Route | DB Table (backing the route) | Status |
|---|---|---|---|
| لیست مشتری | UNKNOWN | `pa_client` (CONFIRMED cols: `id`,`name`,`org_id`; more cols per list screenshot: ملی کد، موبایل، ایمیل، رده/بخش، برگزیده، مطلع، تاریخ ایجاد/تغییر، ایجادکننده) | PARTIAL |
| بررسی | UNKNOWN | UNKNOWN | UNKNOWN |
| ویرایش | UNKNOWN | UNKNOWN | UNKNOWN |
| اقدام | UNKNOWN (route) | `todo_task*` CONFIRMED to exist repo-wide, link to `pa_client` still UNKNOWN | PARTIAL |
| اسناد | CONFIRMED | UNKNOWN table | PARTIAL |
| ایمیل | CONFIRMED | UNKNOWN table | PARTIAL |
| پروژه | CONFIRMED | UNKNOWN table (this client has 0 rows) | PARTIAL |
| گفتگو | CONFIRMED | `chat_dialogs`/`chat_message` CONFIRMED to exist, link to `pa_client` still UNKNOWN | PARTIAL |
| رویدادها | CONFIRMED | UNKNOWN table | PARTIAL |
| پیامک | CONFIRMED | UNKNOWN table | PARTIAL |
| فروش | CONFIRMED | `sales_invoice*` CONFIRMED to exist, link to `pa_client` still UNKNOWN | PARTIAL |
| خرید | CONFIRMED | UNKNOWN table | PARTIAL |
| نظرسنجی | CONFIRMED | UNKNOWN table | PARTIAL |
| فایل‌های صوتی | CONFIRMED | UNKNOWN table | PARTIAL |
| توضیحات | CONFIRMED (write-capable page) | UNKNOWN table | PARTIAL |
| ابزارها | UNKNOWN | UNKNOWN | UNKNOWN |

Nothing is `READY` yet — DB table discovery (Section 4) is the next step for every row.

## 4. List page — confirmed UI facts (from screenshot, no URL yet)

- Filters (right side): همه / حقیقی / حقوقی / برگزیده / مطلع — confirms `برگزیده` (favorite) and
  `مطلع` (aware) are real, first-class filters on the current system.
  - چند مقدار برگزیده/مطلع نگه در pa_client به فرم ستون هست (CANDIDATE column names — TBD via `SHOW COLUMNS pa_client`).
- Search box placeholder: «شناسه، نام، تلفن همراه» → confirms search fields = ID, name, mobile.
  رابط/کد ملی از UI فعلی تأیید نشده — باید بررسی شود آیا در Advanced Search هست.
- Org/segment tree (left): «همه» → «بدون رده» / «مشتریان سایت» → «Mobile140» / «BimehLand» / ...
  → همان مفهوم «رده» / «بخش» که در فرم پروفایل (جدول رده/بخش با ستون‌های جریان/بخش) هم دیده شد.
- List columns spotted: نام کامل، شماره مشتری، نام خانوادگی، رابط، ایجاد کننده، تاریخ ایجاد،
  تاریخ تغییر، مطلع، مطلوب، تاریخ، کد اقتصادی، مدیر عامل، شماره پاسپورت مدیر عامل، کد ملی،
  تلفن همراه، ایمیل، فکس، وب سایت، کشور، استان، شهر، کد پستی، آدرس، تعداد پرسنل، شماره پستی،
  شماره پروژه کسب، شرکت/سایت، رده.
- Total count shown: ۶۰۹۴۱ ردیف — list MUST be paginated/server-searched (confirms Performance rule).

## 5. Open questions sent to user (2026-08-12)

Resolved: لیست مشتریان URL ✅ (`/crm/index/all/&category=5`), اقدام URL ✅ (`show_todo`).

Resolved (2026-08-12, round 2): module_id=14 ✅, auth mechanism ✅ (`teamyar.call_api` needs
no manual cookie), `client/create`+`client/update` request schema ✅, real profile/HR table
facts ✅.

Still open:
1. کدام اسکرین‌شات «بررسی» و کدام «ویرایش» است؟ + URL هرکدام (هنوز یکی از دوتا معلوم نیست)
2. اسکرین‌شات + URL «ابزارها»
3. Test whether `section_id` (API) and URL `section=` are really unrelated (see correction
   above) — need one more data point, e.g. a client from a *different* رده/category, or just
   confirm from you directly if you know what `section=2` means on the history routes.
4. `SHOW COLUMNS pa_client` — still not run (network to `/bot/run/*` blocked from this sandbox,
   see section 6) — needed to pin down the literal ID/favorite/aware column names.
5. Response schema for `client/add/comment` and `client/get` (request+response) — lower
   priority now since Phase 1 is read-only, but useful whenever convenient.

## 6. DB Discovery — DONE (2026-08-12, round 3)

### Correction: bot 966 does not exist / was stale
The registry entry for id=966 (`db_schema_json`) was stale — live site has no such bot at that
id anymore (user confirmed; id 966 currently resolves to an unrelated bot named «مشتری»). Do
not trust old `TeamyarBotsLiveRegistry.json` entries without re-verifying.

**Fix applied**: deployed a fresh copy of `schema_probe_json_bot.lua` as a brand-new bot —
**id 601**, `run_path=443/schema_discovery_tool_v2`, `cat_id=79`, `result_type=0` (JSON). This
is now the live, working schema-discovery tool for this project. Local source:
[src/schema_discovery_tool_v2_bot.lua](../../src/schema_discovery_tool_v2_bot.lua).

**Network note for this sandbox**: `curl.exe` (used by `run_teamyar_bot.ps1` /
`deploy_teamyar_bot.ps1` / `sync_teamyar_bot_registry.ps1`) fails TLS through this sandbox's
default `https_proxy` env var. Fix: `Remove-Item Env:\https_proxy,Env:\HTTPS_PROXY,Env:\http_proxy,Env:\HTTP_PROXY -ErrorAction SilentlyContinue`
before each script call (env vars don't persist across tool calls, so this must be repeated
every time). Confirmed working after that fix.

### Customer ID Mapping — now CONFIRMED with real data, not guessed

```
pa_client.ID           = Customer Master ID (bigint) — used as {CLIENT_ID} path segment in
                          every crm/history/* route, and as CLIENT_ID FK on most related tables.
pa_client.REFFERE_ID    = points to profile_user_info.ID (bigint) — the underlying person/legal
                          profile record (NAME, SURNAME, national code, birth info, etc.)
```

Verified end-to-end on the test client used throughout the screenshots (id 36841):
```sql
SELECT ID, REFFERE_ID, TYPE, NAME, ORG_ID FROM pa_client WHERE ID=36841;
-- → 36841, 58211, 1, "مجتبی بقایی", 8

SELECT ID, NAME, SURNAME, USER_TYPE FROM profile_user_info WHERE ID=58211;
-- → 58211, "مجتبی", "بقایی", 3   (USER_TYPE 3 = حقیقی, matches CRM_USER_TYPE_NATURAL)

SELECT ID, CLIENT_ID, CRM_ID, TITLE FROM sales_invoice WHERE CRM_ID=36841 OR CLIENT_ID=36841 LIMIT 5;
-- → 73958, CLIENT_ID=36841, CRM_ID=58211, "فاکتور موبایل 140 شماره سفارش 72858 - ارسال شده"
```
This nails down the pattern seen across many tables: **`CLIENT_ID` (FK) = `pa_client.ID`**,
**`CRM_ID` (FK) = `pa_client.REFFERE_ID` = `profile_user_info.ID`**. Two genuinely different IDs
exist, exactly as the original brief warned — confirmed by data, not assumed.

⚠️ **Open discrepancy, flagging honestly, not glossing over it**: the screenshots you sent
earlier all show client id **36841 named «امیر امیری»** (list row, profile header, every
`crm/history/*` tab). The live DB query just now shows `pa_client.ID=36841` → **«مجتبی بقایی»**.
Same ID, different name than what was in your screenshots. Most likely explanation: the record
was edited on the live system between when you took those screenshots and now (plausible if
36841 is a shared/reused test customer). I have **not** assumed these are the same person or
silently reconciled it — flagging so you can confirm, since Customer ID Mapping is the most
ID-sensitive part of this whole project.

### Full Feature Matrix — Route + Table + Join Key (updated with real schema)

| Feature | Route | Table(s) | Join Key | Status |
|---|---|---|---|---|
| لیست مشتری | `?page=/crm/index/all/&category=5` | `pa_client` (id,status,type,deleted,parent,level,reffere_id,org_id,code,account_code,name,note,balance) | `ID` | READY (list query), display name still needs `REFFERE_ID → profile_user_info` join per discrepancy above |
| برگزیده (favorite filter) | — | `crm_favorite` (CLIENT_ID, USER_ID, FLAG) | `CLIENT_ID`=`pa_client.ID`, per-user flag | READY |
| مطلع (aware filter) | — | `crm_notify` (CLIENT_ID, USER_ID) | same | READY |
| «مسئول» (candidate — API had `/api/client/responsible/*`) | — | `crm_assign` (CLIENT_ID, USER_ID) | same | PARTIAL — table found, not yet confirmed this is "مسئول" vs "مطلع" (two similar-shaped tables `crm_assign`/`crm_notify`; API also separately had `assign` AND `notify` AND `responsible` endpoints — 3 concepts, only 2 tables found so far) |
| رده/بخش (segment tree) | `category=` param | `crm_classify_person` (`PROFILE_ID`,`section_id`,`name`) + `crm_section` (`id`,`SECTION_NAME`) — confirmed earlier from `crm_rfm_bot.lua` | `crm_classify_person.section_id → crm_section.id` | READY |
| بررسی | **CONFIRMED, same route as ویرایش**: `?page=/crm/client/edit/{ID}` with no `tab=` (or `tab=0`) | same as ویرایش row below | `profile_user_info.ID` = URL id directly | READY (route), field-level mapping still to do |
| ویرایش | **CONFIRMED**: `?page=/crm/client/edit/{ID}&tab=1` (own route namespace, `/crm/client/*` not `/crm/history/*`; also seen with `&section=2&category=5`) | `profile_user_info` (+ `pa_client` for the CRM wrapper fields, via reverse lookup); write via `/api/client/update` (module_id=14) | **`{ID}` = `profile_user_info.ID` = `pa_client.REFFERE_ID`** — same id space as every other route (see round-5 correction above), NOT a separate space | READY (route+ID space), field-level form mapping still to do |
| اقدام | `show_todo&section=0` (CONFIRMED URL, CONFIRMED correct behavior — user tested live) | `todo_task*` — no CLIENT_ID/CRM_ID/PROFILE_ID FK found; assignment ("مطلع"/"مشتری" fields shown on the task) lives in an **EAV/JSON custom-form system** (`todo_custom_form`, `todo_form_data*`), not a rigid column. `todo_notify(TASK_ID,USER_ID,VIEW_DATE)` checked and ruled out (it's a read-receipt log, not the assignment list) | UNKNOWN (JSON field path not reverse-engineered) | **Phase 1: link-only** (route proven correct; skip inline query for this tab, revisit in Phase 2) |
| اسناد | `show_documents` (CONFIRMED URL) | `crm_update_client_folder` (CLIENT_ID, FOLDER_ID) → likely joins to generic `documents_main`/`documents_history` (platform-wide document module) via FOLDER_ID | `CLIENT_ID` | PARTIAL — folder link confirmed, join to documents_main not yet verified |
| ایمیل | `show_emails` (CONFIRMED URL) | Candidates: `email_message`, `email_history`, `email_box`, `email_addresses` — none confirmed to carry CLIENT_ID yet (not in the CLIENT_ID/CRM_ID scan) | UNKNOWN | PARTIAL |
| پروژه | `show_project` (CONFIRMED URL) | `project_project_client` (PROJECT_ID, CLIENT_ID) | `CLIENT_ID` | READY |
| گفتگو | `show_chats` (CONFIRMED URL) | `chat_dialogs`/`chat_message` (repo-confirmed) — link column still unknown (not in CLIENT_ID/CRM_ID scan, may relate via `crm_history.CALL_ID`/generic log, or phone-number matching) | UNKNOWN | PARTIAL |
| رویدادها | `show_events&section=0` (CONFIRMED URL — note `section=0`, not `2`) | **`cal_invite_user` JOIN `cal_event` ON `cal_event.ID=cal_invite_user.EVENT_ID`** — Calendar module, confirmed with real matching data (61 events, titles match screenshot exactly) | `cal_invite_user.USER_ID = profile_user_info.ID` (URL id **directly**, no `pa_client` bridge — the one exception found so far) | READY |
| پیامک | `show_sms` (CONFIRMED URL) | Candidates: `sms_message`, `sms_histories`, `sms_box`, `sms_phone_book` — none confirmed with CLIENT_ID; likely resolved via mobile-number matching, not a direct FK | UNKNOWN | PARTIAL |
| فروش | `show_sales` (CONFIRMED URL) | `sales_invoice` (has **both** CLIENT_ID and CRM_ID columns, verified different values on same row — see Customer ID Mapping) + `sales_invoice_product`, `sales_invoice_status`, etc. | `CLIENT_ID`=`pa_client.ID` **and separately** `CRM_ID`=`REFFERE_ID` — **DO NOT** treat these as interchangeable | READY |
| خرید | `show_purchase` (CONFIRMED URL) | `purchase_invoice` (CLIENT_ID, ORG_ID, TITLE, TYPE, STATUS, DATE_CREATE, RUN_DATE, ...) | `CLIENT_ID` | READY |
| نظرسنجی | `show_poll` (CONFIRMED URL) | Huge `poll_*` module (`poll_questionnaire`, `poll_result`, `poll_assign`, `poll_notify`, `poll_related`, `poll_favorite`, ...) — which table carries the client link not yet isolated | UNKNOWN | PARTIAL |
| فایل‌های صوتی | `audio_files` (CONFIRMED URL) | `crm_calllog` (ID, PROFILE_SRC_ID, PROFILE_DST_ID, CID, RECORDINGFILE, CALL_DURATION, COST, DATE, TYPE, STATUS, CUSTOMER_ID) — matches on-screen columns (شناسه تماس/تاریخ/مدت/هزینه) almost exactly; link likely via `crm_history.CALL_ID → crm_calllog.ID` rather than a direct client column on calllog itself | `crm_history.CALL_ID` bridge (candidate) | PARTIAL |
| توضیحات | `show_comments` (CONFIRMED URL, write-capable) | `crm_history` (NOTE/CONTENT fields) and/or `pa_standard_note` (candidate, name suggests generic notes) — write path CONFIRMED via `/api/client/add/comment` (module 14) | `CLIENT_ID` (crm_history) | PARTIAL |
| ابزارها | n/a — user: no data link needed | n/a | — | READY (static settings entry only, confirmed by user, no discovery needed) |

### Round 4 (2026-08-12) — resolved by self-directed follow-up queries

1. **ID uniqueness re-check (user's point 1)**: re-ran `SELECT ... FROM pa_client WHERE ID=36841`
   verbatim — still returns «مجتبی بقایی», `DELETED=0`. Not a query mistake on my side; IDs are
   confirmed unique (per user), so the only explanation is the record was edited on the live
   system between screenshot time and now. **Not fixed further — flagged, needs user's own
   confirmation, not something DB discovery alone can resolve.**

2. **ویرایش route — CONFIRMED (user's point 2)**:
   `?page=/crm/client/edit/{ID}&section=2&tab=1` — a **different route namespace** than
   `/crm/history/*` (`/crm/client/edit/` vs `/crm/history/`).
   **Critical: the `{ID}` here is NOT `pa_client.ID`.** User's example URL used `98916`; verified:
   ```sql
   SELECT * FROM pa_client WHERE ID=98916;              -- 0 rows, doesn't exist
   SELECT * FROM profile_user_info WHERE ID=98916;       -- 1 row: «صادق اسمعیل زائی»
   ```
   So **`/crm/client/edit/{ID}` uses the `profile_user_info.ID` space = `pa_client.REFFERE_ID`**,
   while every `/crm/history/{action}/{ID}` route uses `pa_client.ID` directly. Two different ID
   spaces in two different route families — exactly the trap the original brief warned about.
   Route Map updated accordingly (see table below).

3. **اقدام (todo_task) link — investigated, still not nailed down**. `todo_task` has no
   CLIENT_ID/CRM_ID column; only close candidate was `PROFILE_ID`. Tested directly against the
   one task visible in the screenshot (id 12583, `TASK_TITLE="_فاکتور-_1405/05/01_امیر امیری"`
   — title literally has the old client name baked in as free text, corroborating point 1 above
   that the client really was named «امیر امیری» at 1405/05/01):
   ```sql
   SELECT ID, PROFILE_ID, FOLDER_ID, AUTHOR_ID, OWNER_ID FROM todo_task WHERE ID=12583;
   -- → PROFILE_ID=0, FOLDER_ID=70461, AUTHOR_ID=36499, OWNER_ID=0
   ```
   `PROFILE_ID=0` (unset) rules out the profile-id theory for this row. Tried the `FOLDER_ID`
   bridge next (`crm_update_client_folder.FOLDER_ID` per client) — came back **empty** for
   `CLIENT_ID=36841`, so that bridge doesn't hold either (at least not for this client). **Still
   UNKNOWN** — likely resolved through `crm_history` (a `TYPE` code whose rows reference
   `todo_task.ID`, similar to how `CALL_ID` bridges to `crm_calllog`), but not proven. Not
   worth more blind querying — will ask you directly if this becomes a blocker for Phase 1.

4. **crm_assign vs crm_notify — resolved with real row counts, not naming guesses**:
   ```sql
   SELECT COUNT(*) FROM crm_assign;   -- 0  (empty table — unused/legacy on this system)
   SELECT COUNT(*) FROM crm_notify;   -- 306,580 (heavily used)
   SELECT COUNT(*) FROM crm_favorite; -- 157
   ```
   **`crm_notify` is the real, actively-used table** — almost certainly backs the list's «مطلع»
   filter (its scale fits a per-client-per-staff attribute across the whole customer base).
   `crm_assign` exists in the schema (matching the `/api/client/assign/*` API name) but has
   **zero rows** — either unused in practice or a separate, not-yet-populated feature. Neither
   table is distinguishable as «مسئول» yet — no `crm_responsible` table exists in the schema at
   all, so «مسئول» may not be a separate persisted relation, or it may live somewhere not yet
   found. Flagging as open rather than guessing further.

5. **گفتگو (chat) — link column identified, not yet proven**: `chat_dialogs` has no CLIENT_ID
   either, but has `AUTHOR_MOBILE` (free-text phone) and `RELATED_ID` (bigint, unlabeled).
   `chat_message` has `USER_ID`/`RELATED_USER_ID`. Candidate: match `AUTHOR_MOBILE` against the
   client's mobile number (denormalized, not a real FK) — consistent with چت/پیامک/ایمیل all
   being **person-identity-matched** rather than CRM-FK-linked, unlike Sales/Purchase/Project
   which have real FK columns. Not proven with a query yet.

6. **پیامک (SMS) — same pattern confirmed structurally**: `sms_message.NUMBER_ID` →
   `sms_phone_book.ID`, and `sms_phone_book.PHONE_NUMBER` (+ `user_id`) — again phone-number
   based, no CLIENT_ID anywhere in the sms_* tables.

7. **ایمیل — same pattern**: `email_message`/`email_history`/`email_addresses` have no
   CLIENT_ID/CRM_ID; `email_addresses.ADDRESS` (varchar) is the raw email string — matched
   against the client's email field, not FK-linked.

8. **نظرسنجی (poll) — not resolved**. None of `poll_assign`/`poll_related`/`poll_notify`/
   `poll_favorite` carry CLIENT_ID/CRM_ID. `poll_related.related_type` breakdown on live data:
   `1→2074, 2→2, 3→1` — dominant type 1 gives no obvious client signal. Still UNKNOWN.

9. `crm_history.TYPE` code meaning (1/3/4/5/8/9) — not resolved, no lookup table found in schema.

### Round 4 items — INVALIDATED and redone with the correct pa_client.ID (round 5)
The round-4 `todo_task`/`crm_update_client_folder`/`crm_assign` checks against client 36841 were
silently using the *wrong person's* `pa_client.ID` (36841 = «مجتبی بقایی», not «امیر امیری» —
see round-5 correction). Redone with امیر امیری's real `pa_client.ID=61622`:
```sql
SELECT * FROM crm_update_client_folder WHERE CLIENT_ID=61622;  -- still 0 rows (genuinely empty, not a false negative)
SELECT COUNT(*) FROM crm_history WHERE CLIENT_ID=61622;        -- 3 rows
SELECT COUNT(*) FROM crm_notify WHERE CLIENT_ID=61622;         -- 4 rows
```
`crm_history` only has 3 rows for this client, but the رویدادها screenshot showed ~21 events —
so `crm_history` is **probably not** the (only) backing table for رویدادها after all. Still
open. `todo_task` link mechanism: not re-tested yet with id 61622 (no PROFILE_ID match expected
either way since round-4 already showed PROFILE_ID=0 on the one real task row) — still UNKNOWN.

### Round 6 (2026-08-12) — user answers, resolved

**بررسی — CONFIRMED same route as ویرایش**: user gave `?page=/crm/client/edit/99020` (no `tab=`
param) vs earlier ویرایش example `?page=/crm/client/edit/36841&tab=1`. So **بررسی and ویرایش are
the same underlying page** (`/crm/client/edit/{ID}`), just a different default `tab` — `tab`
absent (or presumably `tab=0`) = بررسی, `tab=1` = ویرایش. One route, one form, tab-switched —
simplifies the UI plan a lot (no separate summary-vs-form dichotomy to build).

**رویدادها — CONFIRMED, and it's NOT `crm_history`**: user explained «رویدادها مواردی هست که در
ماژول تقویم اساین شده به مشتری» (events assigned to the customer in the Calendar module), with
URL `?page=/crm/history/show_events/99020&section=0` — note **`section=0` here vs `section=2`**
on the other tabs, another data point confirming `section` is a per-route context constant, not
a client attribute. Found the Calendar module tables (`cal_*`) and the actual join:

```sql
SELECT ce.ID, ce.NAME, ce.DATE_START, ce.DATE_FINISH, ciu.STATUS
FROM cal_invite_user ciu
JOIN cal_event ce ON ce.ID = ciu.EVENT_ID
WHERE ciu.USER_ID = {url_id}          -- NOTE: url_id directly, no pa_client bridge needed here!
ORDER BY ce.DATE_START DESC;
```
Verified against client 36841 (امیر امیری): returned 61 rows, with real event titles matching
the screenshot's style exactly («جلسه واحد شوروم و Crm در خصوص مرجوعی», «کلاس آموزشی واحد
بازرگانی», «ششمین جلسه مدیران محترم دپارتمان‌ها...»). `cal_invite_user.USER_ID` uses the
**`profile_user_info.ID` space directly** — unlike sales/purchase/project/favorite/notify/etc.
which all need the `pa_client.REFFERE_ID → pa_client.ID` reverse-lookup first, Calendar
skips that bridge entirely. (Tried the sibling table `cal_assign(EVENT_ID,USER_ID)` first — 0
rows for both id spaces on this client — so `cal_assign` is a different, still-unidentified
relation, not the one رویدادها uses. Don't use it for this feature.)

`crm_history` (only 3 rows for this client, all `TYPE=1`, `CALL_ID=0`, `FOLDER_ID=0`,
`AUTHOR_ID=3`, `section_id=0`) looks like a low-level generic audit-log entry, not tab content —
demoted from "likely رویدادها backing table" to "probably an internal audit trail, not directly
user-facing in any tab investigated so far."

**Internal `/api/client/*` APIs (module_id=14)** — user re-confirmed: use these for any page that
needs to *build* pages or *insert* data in this module, where available, rather than raw SQL
writes. Already the documented Phase-2 plan (see section 3.5) — no change, just reconfirmed as
the mandatory approach once Phase 1 is Stable.

### Round 7 (2026-08-12) — ابزارها resolved, اقدام link mechanism investigated further

**ابزارها — CONFIRMED, no discovery needed**: user: «ابزار نیازی به لینک کردن نداره جز setting
است» (Tools tab needs no data link, just a settings entry). Feature Matrix row closed — no
route/table needed, just a static settings/config link in the new UI.

**اقدام — route re-confirmed working, but the exact DB join is genuinely EAV/JSON-based, not a
simple FK.** User proved `?page=/crm/history/show_todo/{ID}&section=0` correctly returns "tasks
this client is assigned to" (screenshot: client 98784 → exactly task #12710, matching the raw
task page `?page=/todo/report/12710` 1:1). Traced the task record itself:
```sql
SELECT ID, PROFILE_ID, AUTHOR_ID, TASK_TITLE FROM todo_task WHERE ID=12710;
-- → PROFILE_ID=0, AUTHOR_ID=26215, "لغو سفارش 202596"   (PROFILE_ID still unused, as before)
```
Task screenshot shows a «مطلع» field with 3 names incl. «آریان پورابراهیمی» = profile **98784**
(confirmed: `profile_user_info WHERE ID=98784` → «آریان پورابراهیمی» exactly). Tried the obvious
candidate table `todo_notify(TASK_ID, USER_ID, VIEW_DATE)` — for TASK_ID=12710 it returned 5
*different* user ids (10053, 26215, 28673, 36348, 36446), **not including 98784** — so
`todo_notify` is a read/seen-receipt log (`VIEW_DATE` column confirms this), not the persistent
«مطلع» assignment list shown in the UI.

Checked `todo_custom_form(ID, TYPE, FORM_DATA json)` and the wider `todo_form_data*` family —
these are a **generic EAV/custom-form system** (per task category/topic, JSON payload), which is
almost certainly where the «مشتری»/«مطلع» fields actually live (as dynamic custom-form field
values), not as rigid columns. Reverse-engineering the exact JSON path per category is a much
deeper reverse-engineering task than a column scan can solve, and isn't worth more blind
querying.

**Recommendation for Phase 1 (اقدام tab specifically)**: since the route itself is proven to work
correctly when visited directly, Phase 1 can treat اقدام the same as the rest — **link out to the
confirmed `show_todo` route** rather than trying to mirror TeamYar's own custom-form-based
assignment logic in our bot's SQL. A live inline count/preview for this one tab may have to wait
for Phase 2 (or a data dump from you of the actual JSON field name TeamYar's UI uses for
«مطلع»/«مشتری» on a task, if you have it handy from the admin/form-builder side).

### Round 8 (2026-08-12) — user decisions
1. **اقدام = link-only for Phase 1, confirmed by user.** No further chasing of the JSON
   custom-form schema for this tab right now.
2. **`crm_history.TYPE` codes — user doesn't know either.** Dropped from the open-question list;
   not a blocker (the table turned out not to back a specific tab anyway, see round 6).

### Still open — need you directly, not more blind querying
1. Whether «مسئول» is even a real, separate feature on your deployment, or the same list as «مطلع» (`crm_assign` is empty/unused, `cal_assign` also came back empty for this client — increasingly looks like «مسئول» isn't actively used data, but not 100% certain)
2. گفتگو/پیامک/ایمیل/نظرسنجی links — still genuinely unresolved (same EAV/phone-matching suspicion as اقدام). **Proposed**: treat these the same as اقدام — link-only for Phase 1, since their routes are already confirmed working — pending user confirmation.

## 6b. DB Discovery — original blocked-network note (superseded by 6 above, kept for record)

Tried running bot 966 (`db_schema_json`) with the live SID via this session's sandbox: the
`GET /bot/command/view` call works (after bypassing the sandbox's local HTTPS proxy with
`--noproxy '*'`, which otherwise fails TLS handshake — proxy is `172.20.10.12:10808`), but the
`POST /bot/run/258/db_schema_json` call consistently returns **HTTP 302** with this bare
`Cookie: SID=...` value, even with matching `Referer`/`Origin`/`X-Requested-With` headers copied
from `run_teamyar_bot.ps1`. Likely cause: the run/execute route needs a second CSRF-style cookie
that a real logged-in browser session carries alongside `SID`, which isn't present when just
pasting the SID value alone. Not guessing further / not hammering prod with more attempts.

**Action needed from user**: either run the prepared Discovery SQL queries yourself (they're
listed in the chat log, e.g. via `.\scripts\run_teamyar_bot.ps1 -BotId 966 -FormInputJson '...'`
in your own terminal — that path has worked for this project before) and paste back the JSON
results, or tell me if there's a second cookie/header the run endpoint needs.

No `$env:TEAMYAR_SID` available in this session. Ready-to-run queries against bot 966
(`258/db_schema_json`, live copy of `schema_probe_json_bot.lua`) are queued — see chat log —
covering: `pa_client` full columns, `todo_task` columns, `sales_invoice` columns, `chat_dialogs`
columns, and `%doc%/%mail%/%project%/%event%/%sms%/%survey%/%voice%/%comment%/%note%` table
search, plus a global scan for columns named `CLIENT_ID`/`REFFERE_ID`/`CRM_ID`/`PA_CLIENT_ID`.

## ⚠️ Round 9 (1405/06/12 = 2026-09-03) — v2 rebuild: the CLIENT_ID mapping for crm_* tables was WRONG

Verified with 100% join counts on live data (`crm_notify` 415,265/415,265, `crm_favorite` 157/157, `crm_history`
537,725/537,816, `crm_contacts` 1,123/1,156, `crm_address` 187/187, `crm_cross` 81,074/81,074 join to `crm_info.ID`;
only 58–64% join to `pa_client.ID`): **every `crm_*` table's `CLIENT_ID` is `crm_info.ID` = `profile_main.ID` =
the URL id** — NOT `pa_client.ID`. Only `sales_invoice`/`purchase_invoice`.`CLIENT_ID` use `pa_client.ID`
(bridge: `pa_client.REFFERE_ID` = customer id). The round-5 "two-step resolve for every crm table" is superseded.

Other facts established for the v2 bot (see `src/crm_customer_ui_bot.lua` header for the full map):
- Customer master = `crm_info` (81,057 live, `DELETED` 0/1, `CONFIRM`), name from `profile_main.FULLNAME`,
  حقیقی/حقوقی from `profile_user_info.USER_TYPE` (3/4). Native list total for Mobile140 (77,727) = `crm_cross`
  members with `DELETED=0` — matches exactly.
- رده/بخش: `crm_section` (2 rows) → `crm_classify_person` (7 rows, `PROFILE_ID` is the id used in `crm_cross.REFERE_ID`
  and in the native `category=` URL param; `crm_classify_person.ID` is what `/api/client/category/add` wants as
  `category_id`, with `category_profile_id` = `PROFILE_ID`).
- Cross-module links = `crm_ty_links(SRC_MODULE_ID=14, SRC_LINK_ID=customer) → DST_MODULE_ID` 8 todo, 12 email,
  7 documents, 20 project, 19 calendar, 23 sales. Todo links can dangle (task deleted) — always join `todo_task`.
- «توضیحات» = `crm_history.TYPE=1` rows whose `NOTE` is plain text (system audit rows share TYPE=1 but their NOTE is
  HTML `<table`/`<span`, AUTHOR_ID=3 «TeamYar»). Legacy comments are `.tyhtm` documents linked via module 7
  (`/crm/history/comment/show_file/?client_id=&file_id=`). `/api/client/add/comment` needs a real `section_id`
  (0 → `SECTION_ID_NOT_FOUND`) and records the author as user **10001**, not the calling user.
- «مطلع» (assign) and «مسئول» (responsible) live in no queryable table (`crm_assign` is empty; `crm_notify` is the
  per-category notification list). Read via `/api/client/assign/get` (`data.assigns[]`) and
  `/api/client/responsible/get` (`data.responsibles[]`). `/api/client/assign/add` works; `assign/del` and
  `responsible/add|del` return success but do nothing. The native POST `/crm/client/assign/`
  (`client_id, type, users=JSON [{id}]`) is replace-semantics: `type=0` مطلع, `type=2` مسئول.
- Native GET actions reused as-is from the browser: `/crm/index/set_favorite/?id&favorite`, `/crm/index/change/?id`
  (to trash), `/crm/index/restore/?id&type=restor`, `/crm/index/confirm/?id&type=confirm`, `/crm/index/delete/?id`.
  Native list JSON: `/crm/index/<all|person|business|favorite|assign|events>/?json=1&from&count&left_id&search`.
- `/api/client/create` ignores top-level fields (comment/job/company…) — the bot follows up with `update`.
- Test record created during the single-record write tests: customer **116151** («تست بات ۶۰۶ قابل حذف»).
