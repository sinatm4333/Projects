# TeamyarBots SVC — Project Rules

## Project Stack

- **Primary Language**: Lua (Teamyar bot scripts)
- **Platform**: Teamyar ERP/Portal (`erp.bimehland.com`)
- **Database**: MySQL (schema `0000000`, 1655+ tables)
- **Deployment**: PowerShell scripts via curl to Teamyar API
- **Secondary**: .NET 9 / C# 13 / Blazor Server / MudBlazor (referenced architecture)

## Domain Rule (mandatory)

- The Teamyar portal domain is **`erp.bimehland.com`**. The old domain **`team.tsco.ir`** is retired.
- Never write, generate, or reintroduce `team.tsco.ir` — in Lua bots (`receipt_url`, links, etc.), PowerShell scripts (`$baseUrl`, `Origin`/`Referer` headers), docs, JSON registries, or examples. Always use `erp.bimehland.com`.
- If `team.tsco.ir` is found anywhere in the repo (new file, pasted snippet, synced registry data), replace it with `erp.bimehland.com` as part of the change.

---

# Code Generation Rules

Before writing code:

1. Understand the requirement.
2. Check existing implementation.
3. Review related documentation.
4. Check database schema.
5. Check relationships.
6. Check business rules.
7. Implement with proper tests.

---

# Clean Code Rules

Follow:

- SOLID principles.
- Separation of concerns.
- Single responsibility.
- DRY / KISS / YAGNI.

Avoid:

- Large files (>300 lines when possible).
- Duplicate logic across files.
- Hard-coded values (use constants).
- Hidden business rules.

---

# Naming Rules

Use meaningful names.

Lua conventions:
- `snake_case` for variables, functions, locals.
- `PascalCase` for constants (e.g. `MONEY_SCALE`).
- Prefix private helpers with descriptive names, not underscores.

Avoid:

```lua
var x;
var data;
var result;
```

---

# Architecture

Layers (when applicable):

```
Presentation (HTML templates)
    ↓
Application (bot logic, input parsing)
    ↓
Domain (business rules, calculations)
    ↓
Infrastructure (db.query, teamyar API)
    ↓
Database (MySQL)
```

- Repositories must never contain business logic.
- Business logic belongs to Application layer.
- DTO ← Mapper ← Entity pattern where applicable.
- No circular dependency.
- Use MediatR pattern (.NET side).
- Use CQRS where applicable (.NET side).
- Prefer Specification Pattern for complex filtering (.NET side).

---

# Teamyar Bots — Mandatory Workflow

When the user asks to create, edit, or fix a **Teamyar Lua bot** (`src/*_bot.lua`):

## Step 1 — Read catalog

Open and follow `docs/context/TeamyarBotsCatalog.md`.
If user references a **Teamyar bot by id/URL** (e.g. `id=933`), read `docs/context/TeamyarBotsLiveRegistry.json` and sync if missing:

```powershell
.\scripts\sync_teamyar_bot_registry.ps1 -BotId {id} -CatId {cat_id}
```

Then read the bot's `local_src` as the primary pattern (**"similar to bot X"**).

## Step 2 — Read closest example in src/

Pick one file by task type, then **read it fully** before writing code:

| Task | Read first |
|------|------------|
| Simple JSON list | `src/bot_commands_json_bot.lua` |
| Bot usage analytics | `src/bot_analytics_json_bot.lua` |
| PM replaced products | `src/service_replaced_products_json_bot.lua` |
| Schema / metadata | `src/db_schema_json_bot.lua` |
| Tasks + steps aggregate | `src/open_tasks_steps_json_bot.lua` |
| Single task detail | `src/task_steps_json_bot.lua` |
| HTML timing report | `src/timing_report_bot.lua` |
| HTML pivot | `src/tat_pivot_report_bot.lua` or `tat_pivot_report_3day_bot.lua` |

Copy structure, naming, error handling, and helpers from that file.

## Step 3 — Schema

- Bot tables: `docs/context/BotSchema.md`
- Other tables: `db_schema_json_bot.lua` at runtime
- Never load `docs/context/DatabaseSchema.md` (~3 MB)

## Code rules

- **Required header**: first line of every `src/*_bot.lua` must be exactly:
  ```lua
  -- تحلیل و ایجاد توسط سینا مقدم 09121011778
  ```
- **Edit timestamp (required on every change)**: immediately after the header, add the Shamsi date/time of the edit (Iran timezone). Update this line on every edit:
  ```lua
  -- Last Edit = 1405/04/25 14:41
  ```
  Fixed format: `YYYY/MM/DD HH:MM` Shamsi. If multiple edits in one session, just replace this line with the latest time.
- **Version bump (required on every deploy)**: every bot source carries a `-- version= X.Y (...)` line.
  **Bump it on every single deploy** — never redeploy under the same version number, even for a one-line
  fix. Which part to bump:
  | What the deploy is | Bump | Example |
  |---|---|---|
  | Fix / edit of existing behavior | **minor** | `1.4` → `1.5` → `1.6` |
  | New feature or a new request on a new date | **major** | `1.6` → `2.0` |
  Keep a one-line Persian note of what changed in that version next to the number, and update
  `-- Last Edit` in the same edit. The version is how a live bot is matched back to a source revision —
  without it there is no way to tell whether the deployed copy is the fixed one.
- Parameterized SQL only; always `db.query_free()`
- JSON: `{ ok, error? }` with Persian messages
- Reuse `fmt_jalali_datetime`, `format_duration`, `fetch_rows` — do not rewrite
- New files: `{domain}_{purpose}_{json|report}_bot.lua`
- After creating a bot, add one row to `TeamyarBotsCatalog.md`

## HTML report styling rules (mandatory for all `result_type=HTML` bots)

- **Color palette — mandatory, no other hues.** Only these four:
  | Role | Value |
  |------|-------|
  | Accent (headers, buttons, links, alerts/flags) | `#16509D` |
  | Surface / text-on-accent | `white` |
  | Borders, muted text, zebra rows | gray (`#f5f5f5` … `#666`) |
  | Primary text | `black` |
  No pink/magenta, green, amber, or other accent colors. Status/alert differentiation comes from
  `#16509D` fill vs. gray fill vs. white — not from new hues.
  (Old accent, retired: `#E5006E`.)
- **Every table: sortable AND filterable (قانون کاربر، ۱۴۰۵/۰۶/۱۲).** Every table any bot renders — main lists, tab
  tables, detail tables — must have click-to-sort on every column header and a filter (at least a text filter above the
  table that narrows the visible rows client-side; server-side sort/filter where the table is paginated). No exceptions
  for "small" tables. Reference: `enhanceTable()` in `src/crm_customer_ui_606_attachments/app.js` (auto-applied to every
  `table.grid` through a `MutationObserver`).
- **Every UI is mobile-first (قانون کاربر، ۱۴۰۵/۰۶/۱۲).** Design for a ~375px phone first, then widen: single-column
  layouts under 700px, tables switch to a card-per-row view with `data-label` headers (see `.cardable` in
  `app.css`), touch targets ≥ 36px, toolbars wrap, side panels collapse by default on narrow screens and get an
  equivalent compact control (e.g. a dropdown instead of a tree). Verify in the browser at the mobile preset before
  deploying, not only on desktop.
- **Font size never below 14px.**
- Titles (report title, column headers `thead th`, summary-strip labels like «تعداد تعویض») → `font-size: 15px; font-weight: bold;`
- Everything else (body text, table cells, buttons, footer, meta lines) → `font-size: 14px;`
- Table cells never wrap content; column width follows content length (`white-space: nowrap`, `table { width: auto }`, `td/th { width: 1%% }`).
- Column headers (`thead th`) must be sortable (click to sort asc/desc) — see `initSortableTables()` pattern.
- All elements must use a single embedded font (`@font-face` + `* { font-family: ... !important; }`) — never let a stray class (like `.mono`) fall back to a different font.
- **Default font = Peyda** (changed 1405/05/19 — was YekanBakh/IRANSans), **truly embedded as base64 data URI** (not `local()` — Teamyar bots render on arbitrary machines that don't have Peyda installed). Two `@font-face` blocks under one `font-family: "PeydaReport"`: `font-weight: 400` → `Peyda-Regular.ttf`, `font-weight: 700` → `Peyda-Bold.ttf` (plain `Peyda`, not `PeydaFaNum` — FaNum remaps ASCII digits to Persian numeral glyphs, which breaks the comma-grouped Western-numeral counts `fmt_num` produces). `* { font-family: "PeydaReport", "Peyda", "IRANSans", "Tahoma", "Arial", sans-serif !important; }`. Adds ~200KB (base64) to the bot's Lua source per bot — no shared static-asset hosting exists on this platform, so each report bot embeds its own copy. Encode via `base64 -w0 Peyda-Regular.ttf` (do this through a script/tool call, never paste the base64 blob inline in a written response). Applies to all new/edited HTML report bots going forward; old bots keep their existing font until next edit.
- **Mandatory «راهنما» (help) button**: every `result_type=HTML` bot must have a toolbar button that opens a popup/modal explaining the report — what it shows, what each column/tab means, and how the interactive features (row click, sort, receipt links, Excel export) work.
- **Toolbar position**: «تمام صفحه» (fullscreen), «خروجی Excel» (Excel export), and «راهنما» (help) buttons always sit top-left of the report (`.toolbar { justify-content: flex-end }` in an RTL page — `flex-end` = left).
- **Mandatory logo «140» (added 1405/05/23, corrected 1405/05/23) — new `result_type=HTML` bots only.** Every
  new HTML report must show the برند ۱۴۰ logo in the report header, embedded as a base64 `<img>` data URI (same
  reasoning as the Peyda font: no shared static hosting on this platform, each bot carries its own copy).
  **Bare «140» icon mark only — never the «Mobile140» / «موبایل ۱۴۰» wordmark lockup.** Assets already resized +
  base64'd: `assets/brand140/` (`logo140-mark-color.png` / `logo140-mark-white.png` + matching `.b64.txt` — see
  `assets/brand140/README.md`). Source originals: `Y:\Management\Hamed-Sina\HR\Mobile140\Logo\`. Guideline PDF:
  `Y:\Management\Hamed-Sina\سیستم آقا حامد - دستکتاپ\برندبوک\Guide line\Mobile140-Visual Guideline-1402-08-8.pdf`
  (page 13, cases A–E).
  **Background-pairing rule — get this right, it's a hard misuse rule in the guideline, not a suggestion:**
  | Background the logo sits on | Variant |
  |---|---|
  | White / light gray (page background, white cards, table zebra rows) | **Color** (`logo140-mark-color.png`) |
  | The `#16509D` accent band (header, toolbar, `thead th`), dark surfaces, or black | **White** (`logo140-mark-white.png`) |
  Never the color gradient mark on the accent color or any dark/colored panel — low contrast and an explicit
  "misuse" example in the guideline. Palette reference (do **not** use these to replace the mandatory `#16509D`
  report accent — brand-140 colors are for the logo mark itself only): gradient `#00AEEF`→`#192F7C`, spot
  `#192F7C` (Pantone 2756C).
  **Scope: new bots only**, same as the `escape_html` rule above — do not retrofit into existing/already-working
  HTML bots.

## Calling another bot from a bot's own menu/sidebar (mandatory pattern)

Established live on bot 598 (`2/moadian_index_m_1`) on 1405/06/09 after two failed approaches.
When a bot's page must open **another** bot inside itself (sidebar/menu item), use an **iframe**:

| Target bot | iframe `src` | Why |
|---|---|---|
| Depends on the portal (RES bots, `$.Teamyar`, jQuery, platform CSS) — e.g. 574 `send_group_moadian_m`, 572 `tax_client_st_m` | **the bot's portal page**: `/?page=/bot/run/<run_path>` | renders exactly as when opened from the portal menu |
| Self-contained (own `<!DOCTYPE html>`, embedded font, no jQuery/`$.Teamyar`) — e.g. 627 `443/vat_quarterly_dashboard` | **the raw fragment**: `/bot/run/<run_path>` | no nested portal chrome at all |

Rules:
- Lazy-load: set `src` from `data-src` on first click, never on page load.
- Same-origin (`X-Frame-Options: SAMEORIGIN`), so for the portal-page variant you may hide the nested
  portal chrome after `load`: poll `frame.contentDocument` for `[id^="widget-report-"], #myDiv,
  section[data-name]`, then walk up to `<body>` hiding every sibling and clearing each ancestor's
  background/border/shadow/padding. **If the target never appears, leave the page untouched** — the
  fallback must be "cluttered", never "blank".
- Always give each embed view an «باز کردن در تب جدید» link plus a per-frame `data-timeout` note.
- The target does **not** need to be in `related`/«دستورات مرتبط» for iframing (that list only gates
  `teamyar.run_command`).

**Two approaches that DO NOT work — do not retry them:**
1. `<iframe src="/bot/run/<run_path>">` for a portal-dependent bot → blank page. That response is only
   an HTML fragment; outside the shell there is no jQuery/`$.Teamyar`/platform CSS.
2. `teamyar.run_command("<run_path>", {})` server-side → returning `{ok=true, html=...}` → injecting it
   with `innerHTML` and re-creating the `<script>` tags. The call itself works and returns correct HTML,
   and even a fully sequential script loader did not bring a RES bot up: it depends on its own page
   context, not merely on its scripts existing in the right order.

**Still true for any HTML injection on this platform:** scripts inserted via `innerHTML` are inert and
must be re-created **sequentially** — each `src` script awaited (`onload`/`onerror`) before the next
runs. `s.async = false` alone is NOT enough: it only orders external scripts relative to each other,
not relative to inline ones, so inline scripts run before the libraries they depend on and die with
`ReferenceError`.

## Step 4 — Deploy to Teamyar (mandatory on "build bot")

Base domain: **`erp.bimehland.com`** (see Domain Rule above — never `team.tsco.ir`).

When the user asks to **create/build a bot** and the Lua code is **final**:

1. Choose **Persian `name`** from the topic.
2. Choose **`run_path`** from the filename — lowercase, underscores, **no spaces**.
3. Run `scripts/deploy_teamyar_bot.ps1` with `-BotId 0`.
4. **Success** = HTTP **200** + body = integer (bot ID).
5. **Failure** = anything else → error; do not report success.
6. Session: `$env:TEAMYAR_SID` (Cookie `SID=...`).
7. **Defaults (mandatory unless user specifies otherwise):**
   - **`cat_id=79`** (changed 1405/05/19 — new bots go in category 79; old bots created under `cat_id=69` stay there, only new creations use 79)
   - **Output type = HTML** — `result_type=1` (JSON = `0`) / `-ResultFormat html`. Verified on live data: HTML bots (e.g. 945) have `result_type=1`; JSON bots (e.g. 942) have `result_type=0`.
   - **When editing a bot, always set output type = HTML** — never change to JSON

**Response contract:** `200` + integer ID = OK | otherwise = ERR

### Update existing bot (fix / redeploy)

1. Query param **`id`** = bot ID from create response
2. **Body** = same fields as create (name, run_path, form, `result_type=1` for HTML)
3. **Only `command` changes** — new Lua from `src/*.lua`
4. Run `scripts/deploy_teamyar_bot.ps1` with `-BotId {saved_id}`

```powershell
$env:TEAMYAR_SID = 'YOUR_SID'
# Create
.\scripts\deploy_teamyar_bot.ps1 `
  -ScriptPath 'src\example_report_bot.lua' `
  -Name 'عنوان فارسی بات' `
  -RunPath 'example_report' `
  -BotId 0

# Update
.\scripts\deploy_teamyar_bot.ps1 `
  -ScriptPath 'src\example_report_bot.lua' `
  -Name 'عنوان فارسی بات' `
  -RunPath 'example_report' `
  -BotId 941
```

## بات‌های نویسندهٔ مالی (حسابداری/فروش) — قانون «اول تکی، بعد گروهی» (mandatory)

هر باتی که در ماژول حسابداری یا فروش **چیزی ثبت می‌کند** (تسویه، سند، فاکتور، ابطال...) —
نه گزارش‌گیر صرف — باید همیشه با همین ترتیب ساخته و تحویل شود:

1. **اجرای آزمایشی (`_DRY_RUN`)**: صف/داده را می‌سازد و مبلغ‌ها را گزارش می‌دهد، ولی هیچ چیزی ثبت نمی‌کند.
2. **تست روی یک رکورد**: با یک ثابت مثل `_ONLY_INVOICE_IDS = { <id> }` فقط یک مورد واقعی ثبت می‌شود،
   و **نتیجه از روی دیتابیس تأیید می‌شود** (ردیف ساخته‌شده، مبلغ، حساب، نوع) — نه فقط از روی پیام موفقیت UI.
3. **بعد از تأیید کاربر**، حالت گروهی ساخته می‌شود: انتخاب چندتایی + دکمهٔ تکی هر ردیف + دکمهٔ کل لیست،
   با ستون وضعیت هر رکورد، شمارندهٔ موفق/ناموفق، و دکمهٔ توقف.

قانون کاربر (۱۴۰۵/۰۶/۱۲): «برای بات‌های سمت حسابداری و فروش همیشه از همین روش استفاده کن — تست یک عددی
بزنیم، وقتی موفق شد گروهی بساز.» دلیلش این است که یک اشتباه در این بات‌ها سند مالی واقعی می‌سازد و
برگرداندنش دستی و پرهزینه است.

**ولیدیشن مهم‌تر از سرعت است (قانون کاربر، ۱۴۰۵/۰۶/۱۲):** «در عملیات حسابداری، عملیات با ولیدیشن بیشتر
خیلی بهتر از تسویهٔ فاکتور است.» یعنی در این بات‌ها هزینهٔ کندی قابل قبول است، ولی هزینهٔ یک ثبت اشتباه نه.
حداقل‌های الزامی برای هر بات نویسندهٔ مالی:

- **محافظ ثبت دوباره، دولایه:** (۱) کوئری صف رکوردهایی را که قبلاً سند دارند نیاورد؛ (۲) **مهم‌تر** —
  درست قبل از نوشتن، روی خودِ صفحه/داده‌ی زنده دوباره کنترل شود که سند از قبل وجود ندارد و مانده صفر
  نیست. لایهٔ دوم لازم است چون ممکن است بین ساخت لیست و لحظهٔ اجرا، کاربر دیگری همان رکورد را ثبت کرده باشد.
  رکورد ردشده باید با وضعیت روشن («رد شد» + دلیل) گزارش شود، نه بی‌صدا.
- **پنل کنترل سلامت بالای صفحه**، که قبل از هر اجرا وضعیت واقعی دیتابیس را نشان دهد — دست‌کم
  «رکوردهای دارای بیش از یک سند» و «رکوردهایی که جمع اسناد با مبلغ سند مبنا نمی‌خواند». نمونه: بات ۶۴۲
  که همین دو کنترل را روی `sales_invoice_settlement` اجرا می‌کند و مورد واقعی «فاکتور ۱۳۸۷۲۰ با دو تسویهٔ
  یکسان» را نشان داد.
- هر رکورد قبل از ثبت باید **تک‌تک فیلدهایش کنترل شود**؛ اگر حتی یک فیلد ناقص بود، آن رکورد **اصلاً ثبت
  نشود** (نه ثبت ناقص).

**هرگز ردیف مالی را مستقیم در دیتابیس INSERT نکنید.** تسویه/سند فقط ردیف در `sales_invoice_settlement`
نیست؛ سند حسابداری و اثر کیف پول/انبار را خود تیم‌یار می‌سازد و اثر فاکتور برگشت از فروش برعکس فاکتور
فروش است. اگر API مسیر لازم را نداشت، از فرم خود پرتال استفاده کنید (الگوی بات ۶۴۲ پایین‌تر).

### وقتی API مسیر لازم را ندارد: راندن رابط کاربری در iframe (الگوی بات ۶۴۲)

`/api/sales/create_settlement` فقط فاکتور فروش (`TYPE=1`) را می‌پذیرد و برای برگشت از فروش (`TYPE=3`)
همیشه «نوع/وضعیت عملیات نامعتبر است.» می‌دهد (آزمایش زندهٔ ۱۴۰۵/۰۶/۱۱). راه‌حل تأییدشده: بات صفحهٔ خود
فاکتور را در **iframe هم‌مبدأ** باز می‌کند (`/?page=/sales/Invoice/return_invoice_new/{id}`)، ردیف را پر
می‌کند و دکمهٔ ذخیرهٔ همان صفحه را می‌زند. نکات تأییدشده روی داده زنده:

- **تاریخ‌گزین مقدار را FILETIME عددی می‌گیرد** (`$.Teamyar.DateTimePicker.set(el,'value',<int>)` با
  `parseInt`)؛ رشتهٔ شمسی → `NaN/NaN/NaN`.
- **تاریخ تسویه باید بعد از تاریخ فاکتور باشد** (ما +۵ دقیقه می‌گذاریم). تاریخ برابر ⇒ کرش سمت سرور و
  `502 Bad Gateway` روی `/sales/invoice/update_settlement/{id}`.
- **مبلغ باید با جداکنندهٔ هزارگان ست شود**؛ بدون کاما ویجت یک رقم آخر را می‌خورد.
- **`editTable` مقادیر را از مدل داخلی خودش سریالایز می‌کند، نه از input مخفی** — نوشتن مستقیم روی
  `#<table>_<row>_<col>` بی‌اثر است. فیلدهای معمولی فرم (مثل `total_amount_settlement`) اما مستقیم قابل ست‌اند.
- **خانهٔ «حساب» هر شکلی بدهیم فقط شناسه را سریالایز می‌کند**، در حالی که سرور آبجکت کامل
  (`{account_id,force_client,force_floating,force_cost_center,force_revenue_center,force_project,name_value}`)
  می‌خواهد. راه‌حل نهایی: **هوک `XMLHttpRequest.prototype.send` داخل iframe** و جایگزینی فقط همان فیلد
  (`settlement_0`) درست قبل از ارسال — بقیهٔ فرم دست‌نخورده و ساختهٔ خود صفحه می‌ماند. همین هوک، پاسخ سرور
  را هم ثبت می‌کند تا موفق/ناموفق بودن هر رکورد بدون بارگذاری دوباره معلوم شود.
- **بعد از ست‌کردن `iframe.src` هنوز صفحهٔ قبلی داخل قاب است.** اگر همان را بپذیرید، در اجرای گروهی
  رکوردها **یک‌درمیان** با خطای ساختاری رد می‌شوند. قبل از هر بارگذاری `src='about:blank'` بگذارید و
  بعد منتظر بمانید تا `location.href` واقعاً شامل شناسهٔ همین رکورد باشد **و** ساختارهای صفحه
  (`ty__main[step].COLUMN_RECEP` و ردیف خالی جدول) آماده باشند — نه فقط وجود فرم.
- بین دو ثبت پشت‌سرهم چند ثانیه فاصله بگذارید تا سرور سند قبلی را کامل ثبت کند.
- روش عیب‌یابی که جواب داد: **مقایسهٔ «Copy as cURL» درخواست موفق دستی با درخواست ناموفق بات** و رفع
  فیلدها یکی‌یکی. اگر بات کار نکرد و کاربر دستی موفق شد، اول همین دو درخواست را بگیرید.

## RES-framework bots (`readyCodes`/`install_res`) — pattern & pitfalls

Some legacy bots (e.g. RFM CRM, id 501/600, `2/crm_rfm*`) bootstrap via a shared RES bot (`2/res_v2`):

```lua
local _BAT_RES_PATH = "2/res_v2";
function readyCodes()
  local data = teamyar.get_input();
  data["res_type"] = "codes"
  data["config"] = json.decode(teamyar.get_attachment("data.txt"))
  local responseRes = teamyar.run_command(_BAT_RES_PATH , data);
  ...loads returned Lua functions (getInput, install_res, queryTools, translateWord, etc.) into scope...
end
readyCodes();
```

`data.txt` (attachment) declares the input **form** (`inputs`) that RES auto-renders — including Teamyar ACL-search filter widgets (`org`, `ctype`, `cat`, ...). This is the "Teamyar filters" mechanism the user prefers over hand-built `bot_customform` UIs, because RES/ACL widgets are easier to configure from the panel than sending native form JSON via the deploy script.

**When the user says "use RES / Teamyar filters like bot X, don't rebuild it natively":** prefer a **surgical fix** on the existing RES-based bot (fix the specific bug in `getData()`/the SQL attachment) over a full rewrite to a self-contained `bot_customform` bot. Full rewrites drop RES's form UI, which the user then has to reconstruct by hand in the panel — that's the friction they're avoiding.

**`queryTools.where`/`{{whereInvoice}}` scoping — do not misuse:**
```lua
local where_str=" 1=1 "
dataQuery.query , dataQuery.params  = queryTools.where:init({where_str})
  -- :addIn("ORG_ID", org)   -- Lua ignores newlines/comments; this whole block is ONE
.run( dataQuery.query, dataQuery.params, "{{whereInvoice}}");  -- chained expression
```
This `{{whereInvoice}}` placeholder sits on the **outermost/final aggregated** SELECT (after all CTEs, joined/grouped away) — columns from earlier CTEs (`s.ORG_ID`, `ui.USER_TYPE`, raw invoice/join-level columns) are **not in scope** there. Do not try to route per-invoice filters (org/customer-type/classification) through `queryTools.where` — they must be applied **inside the relevant CTE** (e.g. `crm_factor`), via the same `{{where_x}}`-placeholder-substitution mechanism already used for dates, with `tonumber()`-validated values (safe: never raw string concatenation of unvalidated input).

**Rendering caveat:** these bots render through `install_res.resReport(...)`/`resTable(...)`/`resExcel(...)`/`resPrint(...)` — a generic table renderer supplied by `2/res_v2` at runtime, **not** HTML/CSS written in the bot's own file. Confirmed by reading `2/res_v2`'s actual source (out_report.lua, out_table.lua, template_report.html, template_table.html): the **table itself** renders via `$.Teamyar.table(...)` — a core Teamyar **platform** JS widget shared site-wide, not anything in res_v2's own attachments — so click-to-sort headers etc. are **not achievable** without touching Teamyar core (out of scope, never do this).

**Per-bot styling hook that *is* safe (no res_v2/res_v3 fork needed):** `template_report.html` (rendered by `install_res.resReport`) unconditionally emits:
```html
<link href="{{_bot_path}}/data.css" rel="stylesheet" />
...
<script src="{{_bot_path}}/data.js"></script>
```
`{{_bot_path}}` resolves to the **calling bot's own run path** (e.g. `/bot/run/2/crm_rfm_1` for bot 600) — so any RES-based bot can carry its **own** `data.css`/`data.js` attachment for restyling/adding UI (mandatory Peyda font + `#16509D` palette, a راهنما button via JS-injected modal since RES's own toolbar has no help concept), fully isolated from every other bot on the shared `res_v2`/`res_v3`. `data.js` is optional — a missing one 404s silently, every `report[botName].xxx` call in `template_report.html` is guarded with `typeof x !== "undefined"`. Scope all selectors under `section[data-name="<run_path_slug>"]` (the bot's own `_bot_name`) so nothing leaks to other RES bots sharing the same page context. The toolbar (`.core_navbar`) is built by an inline script that runs *after* `data.js` loads, so injecting a help button needs a `MutationObserver` on the bot's root section, not a synchronous `querySelector` at load time. Example: `crm_rfm_1_bot.lua` (bot 600) → `data.css`/`data.js` written for it, not for `res_v2`/`res_v3`.

**Check for a custom `getFilters()`/`getFiltersGroups()` in the bot's own `data.js` FIRST**, before touching `data.txt`'s `searcher_id`/`aclId` mechanism at all. `template_report.html` picks the filter source in this priority order: `report[botName].getFilters(...)` → `report[botName].getFiltersGroups(...)` → the generic `reportbotSearchers` (built from `data.txt` via `readySearcherInputs()`). A bot with its own `getFilters()` in `data.js` **completely bypasses** `data.txt`'s `inputs`/`searcher_*`/`aclId` schema for rendering — that schema only matters for bots using the generic fallback. Found this the hard way on bot 501: its real, live, working filter form (date range with time/seconds via `$.Teamyar.DateTimePicker`, ACL dropdowns via `$.Teamyar.acl` with a **hardcoded** `ongetdata: ['GetDataACL', N]` type number — not `aclId` from `data.txt` at all — and a rich-text `$.Teamyar.editor` for SMS/email composition) lives entirely in its own `data.js`, hand-written, with zero relation to the generic searcher mechanism. Copying `data.js` verbatim (with any hardcoded `bot/run/<run_id>/<old_slug>` URLs inside SMS-send handlers updated to the new bot's own run_path) is the correct way to replicate a RES bot's filter UI 1:1 — not reconstructing it via `data.txt` fields.

**A bot's declared form-field name in `data.js`/`getInput()` must match `data.txt`'s `inputs` key exactly, or the value is silently lost — even on values that visibly render correctly in the UI.** `setListInputs()` (`tools_params.lua`) only populates the `inputs` cache for keys present in `getListParamsStatics()` (= `data.txt`'s declared `inputs` + ~50 hardcoded system params) — **not** every key actually POSTed in the request. Found a real, currently-live instance on bot 501: its filter widget submits `name: "org"`, but `data.txt` only declares `"org_id"` — so `getInput("org")` has returned `""` unconditionally, forever, regardless of what the user picks in that dropdown. The fix is always to change `data.txt`'s key to match the actual submitted field name (never the other way — the JS widget's `name`/Lua's `getInput()` calls are usually the "real" contract; `data.txt` is what has to agree with them).

**`getParamToNumber`/`getValueFromData` (`tools_params.lua`) coerce an unparseable value to `0`, not `nil`**, whenever `data.txt` declares a field `"type": "number"`. A Lua-side check of the shape `if tonumber(x) == nil then x = <fallback> end` will **never fire** for such fields — by the time the bot's own code sees the value, a bad input has already silently become the number `0`, indistinguishable from an intentional `0`. Guard with `tonumber(x) == nil or tonumber(x) <= 0` (or whatever the real "no value" sentinel is) when the field could plausibly submit a non-numeric string (e.g. a date/time widget). Symptom when this bites a date-range filter feeding an unindexed multi-million-row join: the report visually "hangs in loading" (the query silently runs unbounded, not erroring).

**Filter form not rendering (`reportbotSearchers` empty):** `readySearcherInputs()` (`tools_translate.lua`) only turns a `data.txt` `inputs` field into a visible filter widget if that field has `searcher_id`/`searcher_type`/`searcher_title` set. Older `data.txt` files (pre-refactor, e.g. bot 501/600's, `developer.date: 1403/07/15`) only have the legacy `aclId` field and render **no filter form at all** — not an error, just an empty `reportbotSearchers` array. `searcher_type` must be one of `"date" | "input" | "acl_single" | "acl_multi"`.

**Critical:** `getConfigInputs()` (`tools_params.lua`) does `inputs[key].aclId = valInput.searcher_id` whenever `searcher_id` is set — i.e. **`searcher_id` overwrites/becomes the effective `aclId`** used by `getAclUrl()` (`template_config.html`) to route the ACL search request (`{{_bot_path}}?type=<aclId>`). So for `acl_single`/`acl_multi` fields, `searcher_id` is not just a display-order number — it **must equal** whatever `type=N` value the bot's own dispatch (`type ~= nil and type == N`) expects for that field's ACL handler, or the search-select silently calls the wrong (or no) handler. Found this exact bug on bot 501/600: `data.txt`'s `org_id` field had `aclId: 7`, which routes to `crmAcl` (a **client/customer** search) — not `getAclOrg` (`type=6`, the actual organization search). Fixed by setting `org_id`'s `searcher_id` to `6`.

Table/date-cell widgets (`$.Teamyar.table`, `$.Teamyar.DateTimePicker`, `$.Teamyar.acl`, ...) are **not** defined in any res_v2/res_v3 attachment (confirmed absent from `tools.js`) — they're core Teamyar platform JS loaded globally, so their exact submitted value formats can't be verified by reading bot-side files alone. Strong circumstantial evidence (this whole platform's `tools_date.lua`, `REPORT_FN_JDATE`, `time.get_filetime` all standardize on raw FILETIME) suggests `$.Teamyar.DateTimePicker` submits raw FILETIME too, matching what `tonumber(datef)` already expects — but this is inferred, not confirmed; verify with real data after deploying any date-searcher change.

**`queryTools.where:addIn(columnName, columnValues)`** (from `tools_query.lua`, confirmed by reading source): expects `columnValues` as an **array of `{id=...}` objects** — i.e. pass the raw ACL-select input (`org`, `cat`, `ctype`, ...) directly, not `org[1].id`. It auto-parameterizes (`IN (?,?,...)`, `?` values pushed to `queryTools.where.params`) — the safe, intended way to build dynamic `IN` filters in RES-based bots. But it only replaces `{{whereInvoice}}` (or whatever pattern is passed to `.run(query, params, pattern)`) at **whatever text position that placeholder sits in the query** — if that placeholder is on the *outer* (post-aggregation) SELECT, as in `query_list_invoice.txt`/crm_factor, `:addIn` can't reach columns that only exist inside an earlier CTE. Only use it where the placeholder is already positioned inside the CTE/scope that has the target column.

## SPA bots with attachments (الگوی بات ۶۰۶، ۱۴۰۵/۰۶/۱۲)

- A bot may keep its UI in its own **attachments** (`app.js`, `app.css`) served from `/bot/run/<run_path>/<name>` (portal
  CSP allows `'self'`); the Lua `command` then stays a thin server (action dispatch, SQL, `teamyar.call_api`, shell).
  Attachment files bypass the command save-time entity/slash mangling, and the base64 Peyda font can live in the CSS
  attachment. Deploy with `scripts/teamyar_update_bot_echo.ps1 -CommandPath ... -UploadFile ... -DeleteAttachmentId <old ids>`
  (read the ids from `GET /bot/command?cat_id=N&id=M` → `attaches[]`); bump the `?v=` asset version on every change.
  Reference implementation: `src/crm_customer_ui_bot.lua` + `src/crm_customer_ui_606_attachments/`.
- **CRM ids (verified live, supersedes older notes):** customer id = `crm_info.ID` = `profile_main.ID`; every `crm_*`
  table's `CLIENT_ID` is that id. Only `sales_invoice`/`purchase_invoice.CLIENT_ID` = `pa_client.ID`
  (`pa_client.REFFERE_ID` = customer id). «مطلع»/«مسئول» have no queryable table — read via
  `/api/client/assign/get` / `responsible/get`, write via the native POST `/crm/client/assign/` (type 0/2, replace list).
- **Testing from Git Bash mangles arguments:** Persian argv values arrive empty and `/api/...` becomes
  `C:/Program Files/Git/api/...`. Set `MSYS_NO_PATHCONV=1` and send non-ASCII values from a file (`-F field=<file`) or
  percent-encoded — before concluding the platform dropped the value.
- **Editing `TeamyarBotsCatalog.md` programmatically:** locate a row by its **row start** (`| \`file.lua\``), never by
  `includes(file)` — other rows mention file names in their text (a bot-645 row was overwritten this way and had to be
  reconstructed from the bot header).

## Sales query — DO NOT BREAK

When editing warranty/COGS/costs in the replaced-products bots:

- **Never** change `fetch_sales_by_product_code` / `sales_invoice_filter_sql` without testing `product_code=32030020282` (expect `sales_quantity_total` ≈ 108646).
- Sales filter: `DELETED/CANCELED/REJECT=0` **only**. (1405/04/30: a `TYPE NOT IN (1, 5)` clause used to be here — confirmed via direct DB test that it silently dropped the sales total for the regression code from 108646 to 4099. Removed. Do not re-add a `TYPE` restriction without re-validating against the 108646 baseline.)
- Join `wh_product` via `COALESCE(NULLIF(sip.PRODUCT_ID,0), NULLIF(sip.product_id_info,0))`.
- Sales loads in **`load_product_sales_stats`** (separate `pcall` in main) — **never** inside warranty query.

## Warranty stats — DO NOT BREAK

- **Never** use one mega-query with `product_family_sql` repeated 3× — it timeouts and warranty shows zero.
- Flow: `build_product_family_maps` → `fetch_warranty_counts_by_product_ids` + `fetch_receipt_counts_by_product_ids` → aggregate per code.
- Warranty loads in **`load_product_warranty_stats`** (separate `pcall`) — must not block sales.
- Test with `product_code=32030020282` before changing warranty logic.

---

# Database Context

Schema `0000000`. Bot workflow: see Teamyar Bots section above.

- Catalog: `docs/context/TeamyarBotsCatalog.md`
- Bot schema: `docs/context/BotSchema.md`
- Examples: `src/*_bot.lua`
- Ad-hoc schema: `db_schema_json_bot.lua`
- Internal `teamyar.call_api` endpoints (show_popup, todo/taskadd, todo/step/get, ...): `docs/context/TeamyarInternalApiReference.md`

Do not index or read `docs/context/DatabaseSchema.md`.

---

# SQL Rules

- Write production-ready SQL.
- Optimize for performance and scalability.
- Always consider execution plans.
- Avoid unnecessary database load.
- Never write queries without considering indexes.
- **Never use SELECT *** — always specify columns.
- Use parameterized queries (`params = {}`) — never concatenate user input into SQL.
- Always call `db.query_free()` after fetching results.
- Prefer CTEs for complex multi-step queries.
- Use `EXISTS` instead of `IN` for subqueries when possible.
- Lua bots target **MySQL** (schema `0000000`). The .NET/Blazor side (when applicable) targets **SQL Server** via EF Core — same principles above apply there too.
- **Confirmed live platform bug (1405/06/04, bots 501 `2/crm_rfm` + 600 `2/crm_rfm_1`) — `getInput(name)` returns a NULL *userdata*, not `nil`, for any declared field the request did not submit.** Probed directly on live bot 501 (temporary `type=198` branch): every one of `org`/`cat`/`ctype`/`crm`/`center`/`datef`/`sort_key` came back as `lua_type="userdata"`, `tostring` = `"userdata: 0000000000000000"`, and **not indexable** (`pcall(function() return v[1] end)` → `attempt to index a userdata value`). That value is **truthy in Lua**, so both of this project's usual guards pass and then crash on the very next token:
  ```lua
  if org ~= nil and org[1] ~= nil then   -- userdata ~= nil is TRUE -> org[1] -> ERROR
  ..(org and tostring(org[1] and org[1].id or "nil") or "nil")..   -- same trap in a log line
  ```
  Symptom: the bot returns HTTP **500 `script error` with an empty body in ~0.1s** (or 400 through the portal's own XHR), the RES frontend's `report[bot].responseReportMain` is therefore never defined, and the report **spins in «در حال بارگذاری» forever**. It looks like a slow query but is not — with the fields present the same report answers in ~1.4s. **This only bites when the report is loaded without the filter form being submitted** (exactly what the CRM dashboard widget does), which is why it reproduced for other users while the bot's author, who always submits filters, saw it work.
  **Mandatory guard for every `getInput()` of a `"table"`/ACL field — never index the raw value:**
  ```lua
  local function acl_selection(value)
      if value == nil then return nil end
      if _G.type(value) ~= "table" then return nil end
      if value[1] == nil then return nil end
      if _G.type(value[1]) ~= "table" then return nil end
      if tonumber(value[1].id) == nil then return nil end
      return value
  end
  local function scalar_input(value)
      if value == nil then return nil end
      local t = _G.type(value)
      if t ~= "string" and t ~= "number" then return nil end
      return value
  end
  ```
  Normalize every input immediately after reading it, **before** any use (including debug `write_log` lines). Use `_G.type` — these bots do `local type = getInput("type")` at file scope, which shadows the built-in `type()` for code below that line. **Audit every other RES/`bot_customform` bot that indexes an ACL input directly.**
- **Confirmed live platform bug (1405/05/26) — parameterized `LIKE ?` silently fails in this Teamyar `db.query` layer.** Isolated with a direct test on `schema_probe_v2` (bot 589, `mode=rawp`): `WHERE col = ?` works correctly with a bound param; the exact same call shape with `WHERE col LIKE ?` returns a generic `"sql error"` and the param the platform actually received is empty — not an issue with the surrounding query (a bare one-line query with zero joins reproduces it). **Never bind a `LIKE` pattern as a query parameter on this platform** — if the pattern is a fixed value you control (never raw user input), inline it as a SQL string literal via Lua concatenation instead (safe here specifically because it's author-controlled, not user-supplied — the general "never concatenate user input" rule above still applies to anything from `teamyar.get_input()`). Hit in production on **both** `sales_revenue_center_dashboard_report_bot.lua` (bot 609, found during our own testing) and `crm_geo_sales_dashboard_bot.lua` (bot 604, hit live by the user switching its B2B tab) — both fixed the same way (1405/05/26) and reverified against live data. Check any other bot with a `LIKE ?`-parameterized clause for the same bug.
- **Confirmed live (1405/05/26, `crm_geo_sales_dashboard_bot.lua` bot 604) — the entity-decode save-time Quirk documented above for `escape_html` is not limited to HTML-entity strings.** A plain unrelated literal `"&section=2"` (a URL query-string suffix) got silently mangled to `"§ion=2"` when Teamyar saved the bot's `command` — it greedily decoded the `&sect` prefix as the named HTML entity `§`, consuming the rest of the word. **Any literal `&` immediately followed by letters that spell (a prefix of) a named HTML entity is at risk** — not just deliberately-built entity strings. Build such literals via Lua concatenation (`"&" .. "section=2"`) instead of a contiguous literal, same defense as `escape_html`.
- **Confirmed live (1405/05/26, `crm_geo_sales_dashboard_bot.lua` bot 604) — the browser Fullscreen API (`Element.requestFullscreen()`) is unreliable for this platform's «تمام صفحه» toolbar button: content can go fullscreen but become unscrollable** (seen on Android Chrome; Teamyar bots may also render inside an iframe without `allow="fullscreen"`, which the Fullscreen API depends on). **Do not rely on `requestFullscreen()`/`:fullscreen` CSS for the mandatory fullscreen toolbar button** — instead toggle a plain CSS class on the report root (`position:fixed; inset:0; z-index:9999; overflow-y:auto`) via JS `classList.toggle(...)`. No Fullscreen API calls, no `:fullscreen`/`-webkit-full-screen` pseudo-classes — this sidesteps the platform/mobile inconsistency entirely and is the pattern now used in both `crm_geo_sales_dashboard_bot.lua` and `sales_revenue_center_dashboard_report_bot.lua`.
- **Confirmed live (1405/05/31, `sales_revenue_center_dashboard_report_bot.lua` bot 609) — a Lua language gotcha, not a platform bug, but one this project's own SQL-building idiom walks straight into: a long-bracket string `[[` immediately followed by a newline has that newline silently stripped (this is standard Lua behavior, not a quirk of Teamyar).** This project's universal pattern for splicing a dynamic WHERE-clause fragment into a query is `]] .. dynamic_clause .. [[` followed by the next SQL keyword on its own line, e.g.:
  ```lua
  WHERE ...
  ]] .. center_extra .. [[
  GROUP BY center_name
  ```
  If `center_extra` is non-empty and ends in a bare `?` (a bound-parameter placeholder — `build_center_clause`'s `= ?` clause did exactly this), the stripped leading newline means the assembled string becomes `...= ?GROUP BY center_name` — **the placeholder glued directly onto the next keyword with zero separating whitespace** — which `db.query()` rejects with the same generic `"sql error"`. Quoted-string clauses (`LIKE '%x%'`) or clauses immediately followed by `)` don't hit this (a closing quote or paren doesn't need a space before the next token), which is why this specific bug only showed up when a user picked a value from the «مرکز درآمد» filter dropdown — every other clause combination in the bot happened to end in something safe. **Confirmed by direct live isolation**: the identical query text, hand-typed with a manual space before `GROUP BY`, succeeded every time; the function-assembled version (relying on the stripped newline as its only separator) failed every time — proven by dumping the exact assembled query text from a temporary debug branch and comparing byte-for-byte. **Fix, applied project-wide going forward: any helper that builds a `WHERE`/`AND` clause fragment for this splice pattern must end its returned string with an explicit trailing space** (`build_center_clause` and `build_channel_clause` in `sales_revenue_center_dashboard_report_bot.lua` now do this) — never rely on the long-bracket string's leading newline as a separator. **Audit any other bot using the `]] .. extra_clause .. [[\nKEYWORD` splice pattern** (this idiom is used throughout `src/`) for the same silent-concatenation risk, especially wherever the spliced fragment can end in a bound placeholder `?`.
- **Performance finding (1405/05/31, `sales_revenue_center_dashboard_report_bot.lua` bot 609) — `INVOICE_AMOUNT_JOIN`'s inner derived table has no date filter of its own, so every call re-aggregates `sales_invoice_product` across the invoice's entire history (~204k rows, confirmed live: ~6.1s standalone) regardless of how narrow the outer query's date range is.** Bots that call this join only once or twice per request don't feel it much, but `sales_revenue_center_dashboard_report_bot.lua` calls it 5 times per page load (once per channel-aggregate query) — timed live at ~50-60s combined, occasionally exceeding whatever gateway/browser timeout the user was hitting (symptom: `Unexpected token '<'... not valid JSON`, i.e. an HTML error page came back instead of the bot's JSON). **Fix: `INVOICE_AMOUNT_JOIN` was turned into a function `invoice_amount_join_sql()` that adds `WHERE i2.RUN_DATE >= ? AND i2.RUN_DATE < (? + DAY_TICKS)` inside the derived table**, using the *same* date bound the outer query already filters `si.RUN_DATE` by — safe with zero correctness change (any invoice the inner filter excludes would already fail the outer query's own date filter), confirmed live: cut the same standalone query from 6.1s to 3.1s, and the bot's full default load from ~72s to ~56s (a narrower one-month window dropped to ~23s). Every call site must pass `date_range.from_key, date_range.to_key` as **two extra params positioned exactly where the join's placeholders appear in the query text** (always before the outer `WHERE`'s own date params, since the join is written earlier in the SQL) — get this placeholder-to-param ordering wrong and you're back in `"sql error"` territory.
  **Update (1405/06/12) — same fix applied to `crm_geo_sales_dashboard_bot.lua` (bot 604, v04.2).** The earlier assessment above ("original `crm_geo_sales_dashboard_bot.lua` pattern doesn't feel it much") was wrong by the time v04 landed: `build_channel_view` (the initial page load) calls `INVOICE_AMOUNT_JOIN`/`INVOICE_QUANTITY_JOIN` through **6-7 fetch_\* functions** (`fetch_sales_kpi`, `fetch_state_aggregation`, `fetch_city_aggregation`, `fetch_top_customers`, `fetch_new_customers_stats` ×2, plus `fetch_center_comparison` on the "همه" tab). The literal `INVOICE_AMOUNT_JOIN`/`INVOICE_QUANTITY_JOIN` string constants (not functions, unlike bot 609) got `AND i2.RUN_DATE >= ? AND i2.RUN_DATE < ?` / `i3.RUN_DATE ...` added directly, and all **9 call sites** were threaded with the extra date params — since every call site's join and outer `si.RUN_DATE` filter always use the *identical* `date_from_key`/`date_to_key` pair, the two duplicate values can safely be inserted at the join's text position without having to re-derive a different value, which simplified the threading. **Any other bot using this join pattern 3+ times per request should get the same audit.**
  **This v04.2 fix was real but was NOT the cause of the user's "the bot doesn't even execute" follow-up report** — see the next bullet for the actual root cause found by isolating every one of the bot's queries individually via `schema_probe_v2`, not by guessing from the code.
- **Confirmed live (1405/06/12, `crm_geo_sales_dashboard_bot.lua` bot 604, v04.3) — a correlated subquery in a `SELECT` list re-executes once per pre-`GROUP BY` row, and at this data volume that turned a query that never finished into one.** `fetch_new_customers_stats`'s "customer's real first-ever invoice date" calculation was
  `(SELECT MIN(si_all.RUN_DATE) FROM sales_invoice si_all INNER JOIN pa_client pc_all ON pc_all.ID = si_all.CLIENT_ID WHERE pc_all.REFFERE_ID = ci.ID AND ...) AS global_first_run_date`
  sitting in the `SELECT` list of a query already joining `crm_info`/`pa_client`/`sales_invoice` (tens of thousands of rows in-window) — MySQL evaluates a correlated subquery like this **per row of the surrounding join, before `GROUP BY` collapses them**, not once per group. Isolated directly on `schema_probe_v2` (not guessed): this single query alone returned **zero bytes after 100+ seconds** (`curl: (28) Operation timed out ... 0 bytes received`) — this, not the v04.2 join, was the actual cause of the user's "the bot doesn't even execute" report. Every *other* query in the bot (`fetch_state_aggregation` 6.9s, the fixed `INVOICE_AMOUNT_JOIN` alone 3.6s, etc.) was fine in isolation — the only way to find which one of 6-7 queries was the real problem was timing each independently via the probe, not reading the code and guessing.
  **Fix**: replaced the correlated subquery with a non-correlated join to a pre-aggregated derived table computed once —
  ```sql
  INNER JOIN (
      SELECT pc2.REFFERE_ID AS crm_id, MIN(si2.RUN_DATE) AS global_first_run_date
      FROM sales_invoice si2
      INNER JOIN pa_client pc2 ON pc2.ID = si2.CLIENT_ID
      WHERE si2.DELETED = 0 AND si2.CANCELED = 0 AND si2.PRE_INVOICE = 0
      GROUP BY pc2.REFFERE_ID
  ) gf ON gf.crm_id = ci.ID
  ```
  (named `GLOBAL_FIRST_INVOICE_JOIN` in the bot, alongside `INVOICE_AMOUNT_JOIN`) — semantically identical (same "first invoice ever, all-time, unbounded" definition required by the v04 new-customer bugfix), just computed once via `GROUP BY` instead of re-scanned per outer row. Confirmed live: the same query that never returned now completes in **~11s**, and the bot's full initial page load (previously: infinite hang, zero bytes) now completes in **~43s**. **Audit any other bot with a correlated subquery in a `SELECT` list (not just a `WHERE ... EXISTS`) that sits inside a multi-way join over a table with more than a few thousand rows** — the failure mode isn't "slow", it's "never returns," and it will not show up by reading the query, only by timing it in isolation.

---

# EF Core / Database Development Rules (.NET side, when applicable)

- Database access must go through Repository / Service layers — never inside UI components.
- Avoid direct `DbContext` usage inside Razor components.
- `DbContext` must be injected via DI, with **scoped** lifetime — never create it manually with `new`.
- Keep all database operations asynchronous.

---

# Security Rules

- Security must be implemented by design.
- Never trust client-side input.
- Always validate data on the server side.
- Never expose sensitive information (credentials, tokens, connection strings).
- Follow least privilege principles.
- **Escape HTML output** — use `escape_html()` consistently in all HTML templates.
- **Canonical `escape_html` implementation (mandatory, all bots — new and existing):**
  ```lua
  local function escape_html(value)
      if value == nil then return "" end
      local amp_entity = "&" .. "amp;"
      local lt_entity = "&" .. "lt;"
      local gt_entity = "&" .. "gt;"
      local quot_entity = "&" .. "quot;"
      local apos_entity = "&" .. "#39;"
      return tostring(value)
          :gsub("&", amp_entity)
          :gsub("<", lt_entity)
          :gsub(">", gt_entity)
          :gsub('"', quot_entity)
          :gsub("'", apos_entity)
  end
  ```
  **Confirmed live (1405/05/23): a literal contiguous entity string (`"&amp;"` etc. typed directly as the
  `gsub` replacement) throws an error when Teamyar saves the bot's `command`.** Build each entity via string
  concatenation (`"&" .. "amp;"`) instead — this is not a style preference, it's the only form that saves
  successfully. This supersedes the earlier "new bots only, literal form" rule from 1405/05/22 — that literal
  form is now known to be broken, not just stylistically inconsistent with older bots.
  **Retrofit rule:** existing bots using the equivalent `string.char(38) .. "amp;"` trick or a shared
  `HTML_DQ`/`AMP_ENTITY`-style constant are already safe — leave them as-is when editing those bots for
  unrelated reasons; no need to convert them to this exact form. Only bots using the broken literal form
  need fixing, and only when you're already touching that file.
  Also note: saving a bot's `command` in Teamyar has, in practice, sometimes dropped/mangled a literal
  `/` or `\` character and thrown a string error — if a save fails with a string error, suspect slash/backslash
  content first.
- Never embed raw user/database content into HTML without escaping.
- Never bypass authorization checks.
- Do not log sensitive information.

## Authentication Rules (.NET side, when applicable)
- Authentication must be handled centrally — never implement custom auth without security review.
- Never store passwords manually, plain text, or reversibly encrypted — use proper hashing (ASP.NET Core Identity).
- Use ASP.NET Core Identity, OAuth / OpenID Connect, or JWT when required.

---

# Performance Rules

- Performance must be considered during design, not after implementation.
- Avoid unnecessary database calls.
- Avoid unnecessary UI rendering.
- Prefer async operations where the platform supports it.
- Optimize for scalability.
- Use batch queries instead of N+1 patterns.
- Chunk large IN clauses (e.g. `PRODUCT_ID_BATCH_SIZE = 200`).
- Cache computed values when reused across iterations.
- Avoid deep nesting — prefer early return.

---

# Error Handling Rules

- Use `pcall()` for database operations and external calls.
- Return structured error responses: `{ ok = false, error = "message" }`.
- Use Persian error messages for user-facing output.
- Never swallow exceptions silently — always log or return the error.
- Validate inputs early and return clear error messages.
- Handle nil/empty inputs gracefully with defaults.

---

# Testing Rules

- Every important business rule must have automated tests.
- Write tests before or together with production code.
- Tests must be readable and maintainable.
- Avoid testing implementation details.
- Test business behavior and expected results.
- Test with known data (e.g. `product_code=32030020282`) for regression.
- Full test pyramid (.NET side, when applicable): Unit, Integration, Database, API, UI Component tests.

---

# Blazor Standards (when applicable)

This project references .NET 9 / Blazor Server / MudBlazor architecture:

## Component Design
- Prefer small reusable components.
- Avoid components larger than 300 lines.
- Move business logic out of Razor files.
- Use partial classes (.razor.cs) for complex components.

## State Management
- Prefer local component state.
- Use cascading parameters only when necessary.
- Avoid static/singleton state unless required.

## Dependency Injection
- Use @inject only for services.
- Never resolve services manually.
- Constructor injection is preferred in .razor.cs.

## Data Loading
- Always use async/await.
- Support CancellationToken whenever possible.
- Use OnInitializedAsync.

## Rendering
- Minimize unnecessary StateHasChanged() calls.
- Avoid expensive LINQ expressions inside markup.

## Forms
- Use MudForm + FluentValidation.
- Do not duplicate validation logic.

## Tables
- Prefer MudTable with ServerData for large datasets.
- Enable paging, sorting, filtering.
- Avoid loading all records.

## Parameters
- Use `[Parameter]` for external inputs, `[EditorRequired]` for mandatory ones.
- Validate parameter values; never mutate them directly.

## Events
- Prefer `EventCallback<T>` over `Action` delegates.
- Avoid anonymous lambdas when a reusable method exists.

## Dialogs
- Use `MudDialog`, return strongly typed results, avoid nested dialogs.

## Notifications
- Use `ISnackbar` with appropriate severity; never show raw technical exception messages.

## Error Handling
- Catch only expected exceptions; log unexpected ones; display friendly messages; never swallow silently.

## Styling
- Prefer MudBlazor components over inline styles; use CSS isolation; reuse existing theme variables.

## JavaScript Interop
- Prefer Blazor APIs; use JS only when Blazor cannot solve the problem; wrap JS interop inside services (never call JS directly from multiple components).

## Navigation
- Use `NavigationManager`; avoid hardcoded URLs; centralize route constants.

## File Structure
```
MyComponent.razor
MyComponent.razor.cs
MyComponent.razor.css
MyComponentTests.cs
```

## Rendering / Performance
- Use `@key` where appropriate; use `Virtualize` for large lists; avoid allocating objects during rendering or inside Razor expressions.

---

# C# Coding Standards (when applicable)

## Language Features
- Use modern C# features: Primary Constructors, Collection Expressions, File Scoped Namespace, Pattern Matching, string interpolation, switch expressions.

## Naming
- Classes/Methods/Properties/Constants/Enums: `PascalCase`
- Private fields: `_privateField`
- Interfaces: `IRepository`

## Async
- Prefer async/await.
- Never block using `.Result` or `.Wait()`.
- Support CancellationToken.
- Method names must end with `Async`.

## Methods
- Single responsibility.
- Stay under 40 lines when possible.
- Avoid deep nesting.
- Prefer early return.

## DTO
- Never expose EF entities directly.
- Always return DTOs.
- Separate: Entity, DTO, ViewModel, Request, Response.

## Nullable
- Nullable Reference Types are enabled; never use null when avoidable.
- Validate inputs; prefer `ArgumentNullException.ThrowIfNull()`.

## Exceptions
- Throw meaningful exceptions; never swallow them; never catch `Exception` unless required; log unexpected exceptions.

## Classes
- One responsibility per class; avoid God Objects; avoid static helper classes unless truly stateless.

## Collections
- Prefer `IReadOnlyList<T>` / `IEnumerable<T>`; only use `List<T>` when mutation is required.

## LINQ
- Prefer readable LINQ; avoid multiple enumerations, LINQ inside loops, and complex nested LINQ.

## Strings
- Use string interpolation over concatenation; use `StringBuilder` for large text generation.

## Magic Values
- Never use magic numbers or strings — use constants/enums.

## Logging
- Use `ILogger<T>`; log meaningful context; never log sensitive information.

## Formatting
- Use expression-bodied members only when readable; one blank line between methods; `var` only when the type is obvious, otherwise explicit types.

## Comments
- Write self-explanatory code.
- Avoid obvious comments.
- Comment only: business rules, algorithms, non-obvious decisions.

---

# Output Quality

Generated code must be:

- Production Ready
- Readable
- Maintainable
- Testable
- Extensible

Never generate placeholder implementations.
Never leave TODO comments unless explicitly requested.
Never omit error handling.
Never generate sample/demo code unless requested.
