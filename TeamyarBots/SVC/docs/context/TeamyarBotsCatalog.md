# Teamyar Bot Catalog

Index only â€” source code lives in `src/`. Read the matching file before writing a new bot.

## Reference Bots

| File | Type | Input | Use when |
|------|------|-------|----------|
| `bot_commands_json_bot.lua` | JSON | none | Simple list + JOIN |
| `bot_analytics_json_bot.lua` | HTML report | `limit`, `days`, `include_disabled`, `bot_ids`, `workflow_ids`, `action_type_ids` (multi) | Bot analytics + live search for action types (category/workflow/topic) |
| `service_replaced_products_json_bot.lua` | HTML/JSON | `from_date`, `to_date`, `product_code`, `receipt_no`, `format=json` | PM replaced products + warranty/sales/cost matrix (HTML default) |
| `service_replaced_products_report_bot.lua` | HTML/JSON | same as json bot | Same bot â€” costs: declared, replacement value, parts |
| `warranty_branch_expense_detail_report_bot.lua` | HTML/JSON | `from_date`, `to_date`, `center_code`, `account_code`, `org_id` | Warranty branch expense detail ledger; **requires** `center_code` or `account_code`; default date range = fiscal year start to today |
| `db_schema_json_bot.lua` | JSON | `table`, `schema` | INFORMATION_SCHEMA |
| `open_tasks_steps_json_bot.lua` | JSON | none | CTE, nested grouping, Jalali |
| `task_steps_json_bot.lua` | JSON | `task_id` | Input validation, rich helpers |
| `chat_dialog_messages_json_bot.lua` | JSON | `dialog_id` | Extract chat dialog messages, senders, participants |
| `service_receipt_cost_json_bot.lua` | JSON | `receipt_no` | Receipt cost breakdown: consumed parts, replacement, refund (COGS) |
| `service_receipt_cost_period_json_bot.lua` | HTML/JSON | `startDate`, `end_date`, `org_id`, `format=json` | Period receipt cost matrix (HTML default); grouping by product, month, productÃ—month |
| `sales_accessory_volume_performance_report_bot.lua` | HTML/JSON | `startDate`, `end_date`, `org_id` (default 2), `format=json` | Sales unit performance by quantity volume for mobile accessories |
| `sales_invoice_title_duplicates_report_bot.lua` | HTML | `org_id` (default: 2) | Duplicate sales invoice TITLE groups (count > 1); dates are always current fiscal year; excludes DELETED and empty/null titles |
| `user_activity_stats_report_bot.lua` | HTML/JSON | `user_name` (required), `org_id` (default 2), `format=json` | User activity in current fiscal year: dialogs (DATE_CREATE), steps, warehouse, invoices, vouchers |
| `timing_report_bot.lua` | HTML | `startDate` | Parameterized HTML report |
| `service_receipt_summary_report_bot.lua` | HTML | `startDate`, `end_date`, `org_id`, `product_code` | Service receipt summary dashboard: KPIs, status distribution, top products, monthly trends, technician performance, recent activity feed |
| `tat_pivot_report_bot.lua` | HTML | â€” | Monthly pivot |
| `tat_pivot_report_3day_bot.lua` | HTML | â€” | Pivot variant |

## Runtime API

```lua
local input = teamyar.get_input() or {}
db.query({ query = "...", params = {} })
while db.query_fetch(record) do end
db.query_free()
teamyar.write_result(json.encode({ ok = true }))
```

## Output

JSON: `{ ok, error?, ... }` with Persian errors.
HTML: `myArray` + `string.format(Res_chart, json.encode(myArray))`.

## Helpers (copy from existing bots)

- `fmt_jalali_datetime(col)` â€” `open_tasks_steps_json_bot.lua`
- `format_duration(filetime_diff)` â€” same file
- `fetch_rows(query, params)` â€” `task_steps_json_bot.lua`

## Schema

Bot tables: `docs/context/BotSchema.md`.
Other tables: `db_schema_json_bot.lua` â€” never load `DatabaseSchema.md`.

## Live Registry (Teamyar production bots)

`docs/context/TeamyarBotsLiveRegistry.json` â€” synced from `/bot/command/view?id={id}`.

Use when user says **Â«Ø´Ø¨ÛŒÙ‡ Ø¨Ø§Øª X Ø¨Ø³Ø§Ø²Â»** or gives a view URL:

1. Read registry entry by `id` (or sync first)
2. Open `local_src` and copy structure/patterns
3. Deploy new bot with `scripts/deploy_teamyar_bot.ps1`

| id | name | local_src | run_url |
|----|------|-----------|---------|
| 933 | Ø¨Ø§Øª Ù‡Ø§ | `bot_commands_json_bot.lua` | `/bot/run/258/getallbots` |
| 942 | Ù‡Ø²ÛŒÙ†Ù‡ Ø±Ø³ÛŒØ¯ Ø®Ø¯Ù…Ø§Øª | `service_receipt_cost_json_bot.lua` | `/bot/run/258/service_receipt_cost` |
| 943 | Ú¯Ø²Ø§Ø±Ø´ ØªØ¬Ù…ÛŒØ¹ÛŒ Ù‡Ø²ÛŒÙ†Ù‡ Ø±Ø³ÛŒØ¯Ù‡Ø§ | `service_receipt_cost_period_json_bot.lua` | `/bot/run/258/service_receipt_cost_period` |
| 944 | Ø§Ø±Ø²ÛŒØ§Ø¨ÛŒ Ø¹Ù…Ù„Ú©Ø±Ø¯ ÙØ±ÙˆØ´ Ø§Ú©Ø³Ø³ÙˆØ±ÛŒ Ù…ÙˆØ¨Ø§ÛŒÙ„ | `sales_accessory_volume_performance_report_bot.lua` | `/bot/run/258/sales_accessory_volume_performance` |
| 945 | Ø¹Ù†Ø§ÙˆÛŒÙ† ØªÚ©Ø±Ø§Ø±ÛŒ ÙØ§Ú©ØªÙˆØ± ÙØ±ÙˆØ´ | `sales_invoice_title_duplicates_report_bot.lua` | `/bot/run/258/sales_invoice_title_duplicates` |

```powershell
# Sync bot metadata + optional source pull
$env:TEAMYAR_SID = '...'
.\scripts\sync_teamyar_bot_registry.ps1 -BotId 933 -CatId 69
.\scripts\sync_teamyar_bot_registry.ps1 -BotId 942 -CatId 100
.\scripts\sync_teamyar_bot_registry.ps1 -BotId 943 -CatId 100
.\scripts\sync_teamyar_bot_registry.ps1 -BotId 944 -CatId 100
.\scripts\sync_teamyar_bot_registry.ps1 -BotId 945 -CatId 100

# Run bot with input
  .\scripts\run_teamyar_bot.ps1 -BotId 942 -FormInputJson '{"receipt_no":"250250"}'
  .\scripts\run_teamyar_bot.ps1 -BotId 943 -FormInputJson '{"startDate":"1405-01-01","end_date":"1405-03-31","org_id":"2"}'
  .\scripts\run_teamyar_bot.ps1 -BotId 944 -FormInputJson '{"startDate":"1405-01-01","end_date":"1405-03-31","org_id":"2"}'
  .\scripts\run_teamyar_bot.ps1 -BotId 945
```

View API: `GET https://team.tsco.ir/bot/command/view?id={id}&cat_id={cat_id}` â†’ JSON in `botCommandViewFunc(...)`.

## Create / Update Bot (curl)

Endpoint: `POST https://team.tsco.ir/bot/command/update?cat_id={cat_id}&id={id}`

### Create vs Update

| | Create | Update |
|---|--------|--------|
| Query `id` | `0` | Ù‡Ù…Ø§Ù† ID Ø¨Ø±Ú¯Ø´ØªÛŒ Ø§Ø² create (Ù…Ø«Ù„Ø§Ù‹ `941`) |
| Referer `id` | `0` | Ù‡Ù…Ø§Ù† ID |
| Body | Ù‡Ù…Ù‡ ÙÛŒÙ„Ø¯Ù‡Ø§ | **Ù‡Ù…Ø§Ù† body** â€” Ø·Ø¨Ù‚ Ø±ÙˆØ§Ù„ create |
| Ú†Ù‡ Ú†ÛŒØ²ÛŒ Ø¹ÙˆØ¶ Ù…ÛŒâ€ŒØ´ÙˆØ¯ | `name`, `run_path`, `command`, ... | **ÙÙ‚Ø· `command`** (Ú©Ø¯ Lua Ø¬Ø¯ÛŒØ¯) |

- `id` Ø¯Ø± URL = Ø´Ù†Ø§Ø³Ù‡ Ø¨Ø§ØªØ› Ø¯Ø± create ØµÙØ±ØŒ Ø¯Ø± update Ù‡Ù…Ø§Ù† Ø¹Ø¯Ø¯ÛŒ Ú©Ù‡ Ù¾Ø§Ø³Ø® create Ø¨Ø±Ú¯Ø±Ø¯Ø§Ù†Ø¯
- Body Ø¯Ø± update Ø¹ÛŒÙ† create Ø§Ø³ØªØ› nameØŒ run_pathØŒ form Ùˆ Ø¨Ù‚ÛŒÙ‡ Ø«Ø§Ø¨Øª Ù…ÛŒâ€ŒÙ…Ø§Ù†Ù†Ø¯
- Ø¯Ø± update ÙÙ‚Ø· Ù…Ø­ØªÙˆØ§ÛŒ `command` (Ø§Ø³Ú©Ø±ÛŒÙ¾Øª `.lua`) Ø¹ÙˆØ¶ Ù…ÛŒâ€ŒØ´ÙˆØ¯
- Replace `SID` cookie with your active session
- `command` â†’ bot Lua source (inline, not a file path)
- `run_path` â†’ bot identifier/slug (e.g. `my_curl_bot`) â€” **no spaces**
- `result_type` â†’ `0` = HTML/text
- `bot_customform` / `bot_config` â†’ JSON form schema for input parameters
- **Success** = HTTP **200** + body = integer (bot ID). **Failure** = anything else

### Response contract (create & update)

```
OK  â†’ HTTP 200  +  body = integer  (Ù‡Ù…Ø§Ù† bot ID)
ERR â†’ Ù‡Ø± Ú†ÛŒØ² Ø¯ÛŒÚ¯Ø± (Ú©Ø¯ ØºÛŒØ± 200ØŒ body Ø®Ø§Ù„ÛŒØŒ JSONØŒ Ù…ØªÙ†ØŒ ...)
```

- Create: body = **ID Ø¨Ø§Øª Ø³Ø§Ø®ØªÙ‡â€ŒØ´Ø¯Ù‡** â€” Ø°Ø®ÛŒØ±Ù‡ Ú©Ù†ÛŒØ¯
- Update: body = **Ù‡Ù…Ø§Ù† bot ID** (Ù…Ø«Ù„Ø§Ù‹ `941`)
- Ø¯Ø± ØºÛŒØ± Ø§ÛŒÙ† ØµÙˆØ±Øª = **Ø®Ø·Ø§** â€” Ø¨Ø§Øª Ø³Ø§Ø®ØªÙ‡/Ø¢Ù¾Ø¯ÛŒØª Ù†Ø´Ø¯Ù‡ ÙØ±Ø¶ Ú©Ù†ÛŒØ¯

Minimal example (create bot in category **69**, **نوع خروجی = HTML** / `result_type=0`):

```bash
curl --location 'https://team.tsco.ir/bot/command/update?cat_id=69&id=0' \
--header 'Cookie: SID=28653|I2D95A626013634680B518F53CD0FF9A1' \
--header 'Origin: https://team.tsco.ir' \
--header 'Referer: https://team.tsco.ir/?page=/bot/command&cat_id=69&id=0' \
--header 'X-Requested-With: XMLHttpRequest' \
--form 'status="1"' \
--form 'name="bot created by curl"' \
--form 'subsystem_value=""' \
--form 'subsystem=""' \
--form 'run_path="my_curl_bot"' \
--form 'not_showing_in_iframe="0"' \
--form 'icon=""' \
--form 'color=""' \
--form 'db_prefix=""' \
--form 'async_run="0"' \
--form 'async_deadline_run="0"' \
--form 'max_execute_time="100"' \
--form 'cache_time_status="0"' \
--form 'cache_time="0"' \
--form 'show_in_portal_menu="0"' \
--form 'public_access="0"' \
--form 'show_in_widget="0"' \
--form 'open_source="0"' \
--form 'categories="69_1"' \
--form 'deleted_details=""' \
--form 'bot_customform="{\"layout\":{\"width_title\":3,\"col\":\"COL-2\",\"seperator\":\"\"},\"info\":[],\"schema\":{},\"default_value\":{}}"' \
--form 'attachments_deleted=""' \
--form 'bot_config="{\"layout\":{\"width_title\":3,\"col\":\"COL-2\",\"seperator\":\"\"},\"info\":[],\"schema\":{},\"default_value\":{}}"' \
--form 'ver="0"' \
--form 'active_version=""' \
--form 'new_version="0"' \
--form 'result_type="0"' \
--form 'description="created via curl"' \
--form 'command="command=write_result(get_input(\"name\"))"' \
--form 'temp_folder_id="0"' \
--form 'document_content=""' \
--form 'temp_folder_id_2="0"' \
--form 'help_content=""'
```

Update example (existing bot `id=941` in category **69**, نوع خروجی **HTML**):

```bash
curl --location 'https://team.tsco.ir/bot/command/update?cat_id=69&id=941' \
--header 'Cookie: SID=28653|I2D95A626013634680B518F53CD0FF9A1' \
--header 'Origin: https://team.tsco.ir' \
--header 'Referer: https://team.tsco.ir/?page=/bot/command&cat_id=69&id=941' \
--header 'X-Requested-With: XMLHttpRequest' \
--form 'status="1"' \
--form 'name="bot created by curl"' \
--form 'subsystem_value=""' \
--form 'subsystem=""' \
--form 'run_path="my_curl_bot"' \
--form 'not_showing_in_iframe="0"' \
--form 'icon=""' \
--form 'color=""' \
--form 'db_prefix=""' \
--form 'async_run="0"' \
--form 'async_deadline_run="0"' \
--form 'max_execute_time="100"' \
--form 'cache_time_status="0"' \
--form 'cache_time="0"' \
--form 'show_in_portal_menu="0"' \
--form 'public_access="0"' \
--form 'show_in_widget="0"' \
--form 'open_source="0"' \
--form 'categories="69_1"' \
--form 'deleted_details=""' \
--form 'bot_customform="{\"layout\":{\"width_title\":3,\"col\":\"COL-2\",\"seperator\":\"\"},\"info\":[],\"schema\":{},\"default_value\":{}}"' \
--form 'attachments_deleted=""' \
--form 'bot_config="{\"layout\":{\"width_title\":3,\"col\":\"COL-2\",\"seperator\":\"\"},\"info\":[],\"schema\":{},\"default_value\":{}}"' \
--form 'ver="0"' \
--form 'active_version=""' \
--form 'new_version="0"' \
--form 'result_type="0"' \
--form 'description="created via curl"' \
--form 'command="write_result(\"hello from claude tes\")"' \
--form 'temp_folder_id="0"' \
--form 'document_content=""' \
--form 'temp_folder_id_2="0"' \
--form 'help_content=""'
```

| Action | Query `id` | Referer `id` | Body change |
|--------|------------|--------------|-------------|
| Create | `0` | `0` | Ù‡Ù…Ù‡ ÙÛŒÙ„Ø¯Ù‡Ø§ (name, run_path, command, ...) |
| Update | ID Ø§Ø² create (e.g. `941`) | same | **ÙÙ‚Ø· `command`** |

To deploy a bot from `src/*.lua`, put file contents in `command` (create: full deploy; update: same body, new command only).

**Deploy script:** `scripts/deploy_teamyar_bot.ps1` sends `command=<path` (curl reads file **content** into field â€” not `@path` file upload).

**Note:** The minimal `command` example uses `get_input("name")` / `write_result(...)` (Teamyar shorthand). Full bots in `src/` use `teamyar.get_input()` and `teamyar.write_result(...)`.

## Run Bot (curl)

Endpoint: `POST https://team.tsco.ir/bot/run/{run_id}/{run_path}?ver=0`

Ø§Ø¬Ø±Ø§ÛŒ Ø¨Ø§Øª â€” Ø¨Ø¯ÙˆÙ† bodyØ› ÙÙ‚Ø· header. **Bot ID** Ø¯Ø± Referer Ù…ÛŒâ€ŒØ¢ÛŒØ¯:

- Referer: `...?page=/bot/command/view&id={bot_id}&cat_id={cat_id}&tab=0`
- URL path: `{run_path}` Ù‡Ù…Ø§Ù† slug Ø¨Ø§Øª (Ù…Ø«Ù„Ø§Ù‹ `botanalytics`)
- `{run_id}` â€” Ø´Ù†Ø§Ø³Ù‡ Ø¯Ø± Ù…Ø³ÛŒØ± URL (Ù…Ø«Ù„Ø§Ù‹ `258` Ø¯Ø± Ù†Ù…ÙˆÙ†Ù‡ Ø²ÛŒØ±)

```bash
curl --location --request POST 'https://team.tsco.ir/bot/run/258/botanalytics?ver=0' \
--header 'Cookie: SID=28653|I2D95A626013634680B518F53CD0FF9A1' \
--header 'Origin: https://team.tsco.ir' \
--header 'Referer: https://team.tsco.ir/?page=/bot/command/view&id=934&cat_id=69&tab=0' \
--header 'X-Requested-With: XMLHttpRequest'
```

| Part | Example | Meaning |
|------|---------|---------|
| Referer `id` | `934` | bot command ID |
| Referer `cat_id` | `69` | category |
| URL `run_path` | `botanalytics` | `run_path` from bot settings |
| URL `{run_id}` | `258` | path segment before run_path |
| `ver` | `0` | bot version |

Replace `SID` cookie with your active session.

### Response contract (run)

```
OK  â†’ HTTP 200  +  body = Ø®Ø±ÙˆØ¬ÛŒ Ø¨Ø§Øª (Ù‡Ù…Ø§Ù† Ù†ÙˆØ¹ÛŒ Ú©Ù‡ Ø¯Ø± create ØªÙ†Ø¸ÛŒÙ… Ø´Ø¯: HTML / JSON / text)
ERR â†’ Ù‡Ø± Ú†ÛŒØ² Ø¯ÛŒÚ¯Ø± (Ú©Ø¯ ØºÛŒØ± 200ØŒ Ø®Ø·Ø§ÛŒ compileØŒ abortedØŒ ...)
```

- `result_type` Ø¯Ø± create ØªØ¹ÛŒÛŒÙ† Ù…ÛŒâ€ŒÚ©Ù†Ø¯ body Ú†Ù‡ Ø´Ú©Ù„ÛŒ Ø¨Ø§Ø´Ø¯ (`0` = HTML/textØŒ ...)
- body Ù¾Ø§Ø³Ø® Ø¨Ø§ÛŒØ¯ Ù‡Ù…Ø§Ù† Ø®Ø±ÙˆØ¬ÛŒ `teamyar.write_result(...)` Ø¨Ø§Øª Ø¨Ø§Ø´Ø¯
- Ø¯Ø± ØºÛŒØ± Ø§ÛŒÙ† ØµÙˆØ±Øª = **Ø®Ø·Ø§**

## Deploy workflow (agent)

### Create (Ø¨Ø³Ø§Ø² Ø¨Ø§Øª)

When the user asks to **create/build a bot** and Lua is final:

1. Write `src/{domain}_{purpose}_{json|report}_bot.lua`
2. Add catalog row
3. Deploy with `-BotId 0` â€” set `name` (Persian), `run_path` (no spaces), `command` (full `.lua`)
4. Save returned **bot ID** from response (HTTP 200 + integer)

```powershell
$env:TEAMYAR_SID = '28653|...'
.\scripts\deploy_teamyar_bot.ps1 `
  -ScriptPath 'src\warranty_branch_expense_detail_report_bot.lua' `
  -Name 'Ú¯Ø²Ø§Ø±Ø´ Ø±ÛŒØ² Ù‡Ø²ÛŒÙ†Ù‡ Ø´Ø¹Ø¨Ø§Øª Ú¯Ø§Ø±Ø§Ù†ØªÛŒ' `
  -RunPath 'warranty_branch_expense_detail_report' `
  -BotId 0
```

### Update (Ø§ØµÙ„Ø§Ø­/Ø¢Ù¾Ø¯ÛŒØª Ø¨Ø§Øª Ù…ÙˆØ¬ÙˆØ¯)

When fixing or updating an **existing** bot:

1. Edit `src/*.lua` locally
2. Deploy with `-BotId {id}` â€” Ù‡Ù…Ø§Ù† ID Ø¯Ø±ÛŒØ§ÙØªÛŒ Ø§Ø² create
3. Body Ù…Ø«Ù„ createØ› **ÙÙ‚Ø· `command`** (Ú©Ø¯ Ø¬Ø¯ÛŒØ¯) Ø¹ÙˆØ¶ Ù…ÛŒâ€ŒØ´ÙˆØ¯ â€” name Ùˆ run_path Ø«Ø§Ø¨Øª
4. Success = HTTP 200 + integer (same bot ID)

```powershell
.\scripts\deploy_teamyar_bot.ps1 `
  -ScriptPath 'src\warranty_branch_expense_detail_report_bot.lua' `
  -Name 'Ú¯Ø²Ø§Ø±Ø´ Ø±ÛŒØ² Ù‡Ø²ÛŒÙ†Ù‡ Ø´Ø¹Ø¨Ø§Øª Ú¯Ø§Ø±Ø§Ù†ØªÛŒ' `
  -RunPath 'warranty_branch_expense_detail_report' `
  -BotId 941
```

| Field | Create | Update |
|-------|--------|--------|
| Query `id` | `0` | saved bot ID |
| `name` | Persian, new | unchanged |
| `run_path` | slug, no spaces | unchanged |
| `command` | full Lua | **new Lua only** |
| Success | HTTP **200** + integer = bot ID | HTTP **200** + integer = same bot ID |
| Failure | Ù‡Ø± Ú†ÛŒØ² Ø¯ÛŒÚ¯Ø± = Ø®Ø·Ø§ | Ù‡Ø± Ú†ÛŒØ² Ø¯ÛŒÚ¯Ø± = Ø®Ø·Ø§ |

