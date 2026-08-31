# بازیابی بات ۲۵۷ (`2/res_bot`) و اصلاح بات ۲۴۳ («کارهای من»)

تاریخ تشخیص: ۱۴۰۵/۰۶/۰۹ (2026-08-31)

## مسئله

ویجت «کارهای من» (بات ۲۴۳، `2/tasks_my_tasks`) روی داشبورد با HTTP 500 و بدنهٔ خالی رندر نمی‌شود.
علت در خودِ ۲۴۳ نیست — سورس و بایت‌کدش سالم است (`COMMAND=4366`, `BYTECODE=11060`). علت این است که
۲۴۳ در زمان اجرا `teamyar.run_command("2/res_bot")` صدا می‌زند، و **بات زیرساختی ۲۵۷ (`2/res_bot`)
روی سرور کاملاً خالی شده** (`COMMAND=0`, `BYTECODE=0`, صفر پیوست). اجرای مستقیم `2/res_bot` مقدار
`BYTECODE_COMMAND_IS_EMPTY` برمی‌گرداند.

`2/res_bot` قالب مشترک RES برای **همهٔ** ویجت‌های قدیمی است، پس هر باتی که آن را صدا می‌زند (۲۴۳،
۳۸۷ «یادداشت‌های من»، و اکثر بات‌های `live_bots/`) با هم ۵۰۰ می‌دهند. بات‌های مبتنی بر `res_v2`
(۵۰۱/۶۰۰) سالم‌اند چون از ۲۵۷ عبور نمی‌کنند.

## چرا نمی‌توان ۲۵۷ را با API/پنل معمولی ذخیره کرد

بات ۲۵۷ یک بات **لینک‌شده به مبدأ** است: `SRC_COMMAND_ID=178`, `SRC_DOMAIN='demo2.teamyar.com'`.
هر بار ذخیرهٔ یک `command` که با موفقیت **کامپایل** شود، بک‌اند تلاش می‌کند با دامنهٔ مبدأ همگام شود؛
`demo2.teamyar.com` از این سرور در دسترس نیست و درخواست با **502 Bad Gateway** می‌میرد و چیزی نوشته
نمی‌شود. (فقط سورسِ دارای خطای کامپایل نوشته می‌شود — بی‌فایده.) این روی بات‌های غیرلینک (`src=0`)
رخ نمی‌دهد: ساخت بات آزمایشی ۶۲۹ با موفقیت انجام شد.

## راه‌حل تمیز (قطع لینک مبدأ، سپس ذخیرهٔ عادی)

فایل‌های بازیابی سالم (بایت‌به‌بایت از کپی سالم بات ۱۷۲ = `2/res_bot_1`) در مخزن آماده‌اند:

- سورس: [`src/res_bot_1_bot.lua`](../../src/res_bot_1_bot.lua)
- ۱۱ پیوست: [`src/res_bot_257_attachments/`](../../src/res_bot_257_attachments/)
  (`xlsx.full.min.js`, `progress_control.css`, `progress_control.js`, `template_html.js`,
  `template_table.js`, `main.css`, `template_chart.js`, `Persian.js`, `main.js`, `main.html`,
  `English.js`)

### گام ۱ — قطع لینک مبدأ (SQL، در schema `0000000`)

> بک‌آپ مقادیر فعلی برای بازگشت: `257 → SRC_COMMAND_ID=178, SRC_DOMAIN='demo2.teamyar.com'`

```sql
UPDATE bot_command SET SRC_COMMAND_ID = 0, SRC_DOMAIN = '' WHERE ID = 257;
```

### گام ۲ — ذخیرهٔ سورس + پیوست‌ها (حالا که غیرلینک است، ۵۰۲ نمی‌دهد)

```powershell
$env:TEAMYAR_SID = '<SID>'
.\scripts\update_bot_preserve.ps1 `
  -BotId 257 `
  -ScriptPath 'src\res_bot_1_bot.lua' `
  -AttachDir 'src\res_bot_257_attachments'
```

این ذخیره، `COMMAND` را می‌نویسد، پلتفرم `BYTECODE_COMMAND` را تولید می‌کند، و ۱۱ پیوست را
به‌عنوان فیلدهای multipart `attachments` بارگذاری می‌کند.

### گام ۳ — (اختیاری) بازگرداندن لینک مبدأ ۲۵۷

اگر لازم است ۲۵۷ همچنان «قابل‌به‌روزرسانی از مبدأ» بماند:

```sql
UPDATE bot_command SET SRC_COMMAND_ID = 178, SRC_DOMAIN = 'demo2.teamyar.com' WHERE ID = 257;
```

### گام ۴ — راستی‌آزمایی

- `GET /bot/run/2/res_bot` باید دیگر `BYTECODE_COMMAND_IS_EMPTY` ندهد.
- `GET /bot/run/2/tasks_my_tasks` (بات ۲۴۳) باید ۲۰۰ + قالب جدول رندر کند.

## اصلاح خود بات ۲۴۳ («کارهای من») — بعد از سالم‌شدن ۲۵۷

سورس بازنویسی‌شده و استایل‌دهی‌شدهٔ طبق گایدلاین آماده است:

- سورس: [`src/tasks_my_tasks_bot.lua`](../../src/tasks_my_tasks_bot.lua) — رفع کرش TITLE تهی،
  ورودی‌های نامطمئن (userdata NULL)، درج FILETIME با `%.0f` (نه نماد علمی)، `pcall` + پیام خطای
  فارسی، ساخت قالب فقط در باز شدن ویجت (نه در هر درخواست داده)، id ویجت مشتق از زمان.
- پیوست استایل: [`src/tasks_my_tasks_attachments/main.css`](../../src/tasks_my_tasks_attachments/main.css)
  — پالت `#16509D`/سفید/خاکستری/مشکی، فونت Peyda embedded، حداقل ۱۴px، scope زیر
  `.bot_holder[id^="tasks_my_tasks"]`.

**اما ۲۴۳ هم لینک‌شده است** (`src=189, demo2.teamyar.com`) → ذخیرهٔ API آن هم ۵۰۲ می‌دهد. برای
اعمال سورس/استایل جدید، ابتدا مثل ۲۵۷ لینکش را قطع کنید:

```sql
-- بک‌آپ: 243 → SRC_COMMAND_ID=189, SRC_DOMAIN='demo2.teamyar.com'
UPDATE bot_command SET SRC_COMMAND_ID = 0, SRC_DOMAIN = '' WHERE ID = 243;
```

سپس:

```powershell
.\scripts\update_bot_preserve.ps1 -BotId 243 `
  -ScriptPath 'src\tasks_my_tasks_bot.lua' `
  -AttachDir 'src\tasks_my_tasks_attachments'
```

> توجه: `update_bot_preserve.ps1` پیوست‌های جدید را **اضافه** می‌کند. اگر `main.css` قبلی روی ۲۴۳
> وجود دارد (در حال حاضر ندارد — پیوست‌های ۲۴۳ فقط `query.txt`, `main.js`, `English.js`, `Persian.js`
> هستند) باید نسخهٔ تکراری را از پنل حذف کرد. برای ۲۴۳ فقط `main.css` جدید افزوده می‌شود، تداخلی نیست.

## پاک‌سازی بدهی‌های این بررسی

- **بات ۵۱۱ (`2/tasks_my_tasks_1`، کلون بلااستفاده، ۰ اجرا)** در جریان تست، `command`اش با یک BOM
  آلوده شد (`HEX(SUBSTRING(COMMAND,1,3))='EFBBBF'` → خطای کامپایل). چون لینک‌شده است، فقط از طریق DB
  قابل ترمیم است:
  ```sql
  -- حذف BOM از ابتدای دستور (۳ بایت اول)
  UPDATE bot_command SET COMMAND = SUBSTRING(COMMAND, 4) WHERE ID = 511 AND HEX(SUBSTRING(COMMAND,1,3)) = 'EFBBBF';
  ```
  یا لینکش را قطع و سورس تمیز `live_bots/511.lua` را دوباره ذخیره کنید. یک نسخهٔ `version=1`
  غیرفعال هم روی ۵۱۱ ساخته شد که بی‌ضرر است.
- **بات آزمایشی ۶۲۹ (`443/probe_tasks_my_tasks_temp`، cat 79)** را پس از اتمام حذف کنید (پنل، یا
  API حذف بات).
