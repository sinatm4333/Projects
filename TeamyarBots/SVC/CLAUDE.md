# TeamyarBots SVC — Project Rules

## Project Stack

- **Primary Language**: Lua (Teamyar bot scripts)
- **Platform**: Teamyar ERP/Portal (`team.tsco.ir`)
- **Database**: MySQL (schema `0000000`, 1655+ tables)
- **Deployment**: PowerShell scripts via curl to Teamyar API
- **Secondary**: .NET 9 / C# 13 / Blazor Server / MudBlazor (referenced architecture)

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
  -- تحلیل و ایجاد توسط مهدی جهانی 09125632329
  ```
- **Edit timestamp (required on every change)**: immediately after the header, add the Shamsi date/time of the edit (Iran timezone). Update this line on every edit:
  ```lua
  -- Last Edit = 1405/04/25 14:41
  ```
  Fixed format: `YYYY/MM/DD HH:MM` Shamsi. If multiple edits in one session, just replace this line with the latest time.
- Parameterized SQL only; always `db.query_free()`
- JSON: `{ ok, error? }` with Persian messages
- Reuse `fmt_jalali_datetime`, `format_duration`, `fetch_rows` — do not rewrite
- New files: `{domain}_{purpose}_{json|report}_bot.lua`
- After creating a bot, add one row to `TeamyarBotsCatalog.md`

## HTML report styling rules (mandatory for all `result_type=HTML` bots)

- **Font size never below 14px.**
- Titles (report title, column headers `thead th`, summary-strip labels like «تعداد تعویض») → `font-size: 15px; font-weight: bold;`
- Everything else (body text, table cells, buttons, footer, meta lines) → `font-size: 14px;`
- Table cells never wrap content; column width follows content length (`white-space: nowrap`, `table { width: auto }`, `td/th { width: 1%% }`).
- Column headers (`thead th`) must be sortable (click to sort asc/desc) — see `initSortableTables()` pattern.
- All elements must use a single embedded font (`@font-face` + `* { font-family: ... !important; }`) — never let a stray class (like `.mono`) fall back to a different font.
- **Mandatory «راهنما» (help) button**: every `result_type=HTML` bot must have a toolbar button that opens a popup/modal explaining the report — what it shows, what each column/tab means, and how the interactive features (row click, sort, receipt links, Excel export) work.
- **Toolbar position**: «تمام صفحه» (fullscreen), «خروجی Excel» (Excel export), and «راهنما» (help) buttons always sit top-left of the report (`.toolbar { justify-content: flex-end }` in an RTL page — `flex-end` = left).

## Step 4 — Deploy to Teamyar (mandatory on "build bot")

When the user asks to **create/build a bot** and the Lua code is **final**:

1. Choose **Persian `name`** from the topic.
2. Choose **`run_path`** from the filename — lowercase, underscores, **no spaces**.
3. Run `scripts/deploy_teamyar_bot.ps1` with `-BotId 0`.
4. **Success** = HTTP **200** + body = integer (bot ID).
5. **Failure** = anything else → error; do not report success.
6. Session: `$env:TEAMYAR_SID` (Cookie `SID=...`).
7. **Defaults (mandatory unless user specifies otherwise):**
   - **`cat_id=69`**
   - **Output type = HTML** — `result_type=0` / `-ResultFormat html`
   - **When editing a bot, always set output type = HTML** — never change to JSON

**Response contract:** `200` + integer ID = OK | otherwise = ERR

### Update existing bot (fix / redeploy)

1. Query param **`id`** = bot ID from create response
2. **Body** = same fields as create (name, run_path, form, `result_type=0`)
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

## Sales query — DO NOT BREAK

When editing warranty/COGS/costs in the replaced-products bots:

- **Never** change `fetch_sales_by_product_code` / `sales_invoice_filter_sql` without testing `product_code=32030020282` (expect `sales_quantity_total` ≈ 108646).
- Sales filter: `DELETED/CANCELED/REJECT=0` + `TYPE NOT IN (1, 5)` — **never** `PRE_INVOICE`, **never** `TYPE=4` only.
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
