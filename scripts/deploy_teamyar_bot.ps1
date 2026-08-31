#Requires -Version 5.1
<#
.SYNOPSIS
  Create or update a Teamyar bot via POST /bot/command/update

.DESCRIPTION
  Uploads Lua source from src/*.lua to Teamyar.
  Create: query id=0, full body (name, run_path, command, ...).
  Update: query id=bot ID from create; same body; only command (lua file) changes.
  Success: HTTP 200 + body = integer (bot ID). Anything else = error.
  Create: returned ID is the new bot. Update: returned ID is the same bot ID.

.PARAMETER ScriptPath
  Path to the .lua bot file (e.g. src\my_bot.lua)

.PARAMETER Name
  Persian display name for the bot (required for create)

.PARAMETER RunPath
  Bot slug - no spaces. Default: derived from filename (without _bot.lua)

.PARAMETER CatId
  Category id (default 69)

.PARAMETER BotId
  Query param id: 0 = create; >0 = update (same ID returned from create).
  On update, body matches create; only command field gets new lua content.

.PARAMETER Sid
  Session cookie value. Default: $env:TEAMYAR_SID

.PARAMETER ResultFormat
  Output format for new/update bot. Default: html (نوع خروجی = HTML → result_type=1; JSON = 0)

.PARAMETER Description
  Optional Persian/English description

.PARAMETER MaxExecuteTime
  Max execution time in seconds (Teamyar max_execute_time). Default: 100

.PARAMETER HelpContent
  Optional help/documentation text stored in the bot's help_content field
  (shown in Teamyar's bot editor "راهنما" tab). Default: unchanged/empty.

.PARAMETER BotConfigJson
  Optional raw bot_config JSON (per-bot admin config schema, e.g. account_code/
  center_code fields shown in the "پیکربندی" tab). Default: empty schema
  (same as bot_customform default) — pass the source bot's bot_config JSON
  when cloning a config-driven bot (e.g. RES-framework settlement bots).

.EXAMPLE
  $env:TEAMYAR_SID = '28653|...'
  .\scripts\deploy_teamyar_bot.ps1 `
    -ScriptPath 'src\warranty_branch_expense_detail_report_bot.lua' `
    -Name 'گزارش ریز هزینه شعبات گارانتی' `
    -RunPath 'warranty_branch_expense_detail_report'

.EXAMPLE
  # Update existing bot id 941
  .\scripts\deploy_teamyar_bot.ps1 `
    -ScriptPath 'src\warranty_branch_expense_detail_report_bot.lua' `
    -Name 'گزارش ریز هزینه شعبات گارانتی' `
    -RunPath 'warranty_branch_expense_detail_report' `
    -BotId 941
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ScriptPath,

    [Parameter(Mandatory = $true)]
    [string]$Name,

    [string]$RunPath,

    [int]$CatId = 69,

    [int]$BotId = 0,

    [string]$Sid = $env:TEAMYAR_SID,

    [ValidateSet('html')]
    [string]$ResultFormat = 'html',

    [int]$ResultTypeValue = -1,

    [string]$Description = '',

    [int]$MaxExecuteTime = 100,

    [string]$HelpContent = '',

    [string]$BotConfigJson = '',

    # پرچم‌های نمایشی/دسترسی — پیش‌فرض همان رفتار قبلی اسکریپت (0/خالی). برای بات‌های ویجتی
    # (مثل res_bot و ویجت‌های داشبورد) هنگام Update باید مقادیر زندهٔ فعلی بات عیناً پاس داده شوند،
    # وگرنه دیپلوی آن‌ها را صفر می‌کند و بات از فهرست ویجت‌ها می‌افتد.
    [int]$ShowInWidget = 0,

    [int]$ShowInPortalMenu = 0,

    [int]$PublicAccess = 0,

    [int]$OpenSource = 0,

    [int]$NotShowingInIframe = 0,

    [string]$Icon = '',

    [string]$Color = '',

    # فرمت طبق bot.js beforSubmit: "<categoryId>_<isDefault>" با کاما، دقیقاً یک عضو باید _1 باشد
    # (مثلاً '59_1' برای دستهٔ Sale). خالی = رفتار قبلی "${CatId}_1".
    [string]$Categories = '',

    # زیرسیستم بات — هنگام Update بات‌هایی مثل 478 (SALES_VIEW/23_2) باید عیناً echo شود؛
    # مقدار id از فهرست subsystem فرم ویرایش (/bot/command?cat_id=N&id=M) خوانده می‌شود.
    [string]$SubsystemValue = '',

    [string]$SubsystemName = '',

    # 1 = فعال (پیش‌فرض)، 0 = غیرفعال‌کردن بات (مثلاً بات‌های آزمایشی/تکراری)
    [int]$Status = 1
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-ScriptPath {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Script file not found: $Path"
    }
    return (Resolve-Path -LiteralPath $Path).Path
}

function Get-DefaultRunPath {
    param([string]$FilePath)
    $base = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
    if ($base -match '_bot$') {
        $base = $base -replace '_bot$', ''
    }
    $slug = ($base -replace '\s+', '_').ToLowerInvariant()
    if ($slug -match '\s') {
        throw "run_path must not contain spaces: $slug"
    }
    return $slug
}

function Get-EmptyFormJson {
    return '{"layout":{"width_title":3,"col":"COL-2","seperator":""},"info":[],"schema":{},"default_value":{}}'
}

function Test-BotIdResponse {
    param([string]$Body)
    $trimmed = $Body.Trim()
    if ($trimmed -match '^\d+$') {
        return [int]$trimmed
    }
    return $null
}

$resolvedScript = Resolve-ScriptPath -Path $ScriptPath
if (-not $RunPath) {
    $RunPath = Get-DefaultRunPath -FilePath $resolvedScript
}
if ($RunPath -match '\s') {
    throw "run_path must not contain spaces: $RunPath"
}
if (-not $Sid) {
    throw 'SID is required. Set $env:TEAMYAR_SID or pass -Sid.'
}
if (-not $Description -and -not $PSBoundParameters.ContainsKey('Description')) {
    # فقط وقتی پارامتر اصلاً پاس نشده default بگذار؛ -Description '' یعنی «توضیح خالی را حفظ کن»
    $Description = "Deployed from $([System.IO.Path]::GetFileName($resolvedScript))"
}

$baseUrl = 'https://erp.bimehland.com'
$url = "$baseUrl/bot/command/update?cat_id=$CatId&id=$BotId"
$referer = "$baseUrl/?page=/bot/command&cat_id=$CatId&id=$BotId"
$formJson = Get-EmptyFormJson
$categories = if ($Categories) { $Categories } else { "${CatId}_1" }
# نوع خروجی = HTML (Teamyar UI) → result_type=1 (پیش‌فرض)؛ JSON = 0. با -ResultTypeValue قابل بازنویسی است
# (تأییدشده روی داده زنده: بات‌های HTML مثل 945 مقدار 1 دارند، بات‌های JSON مثل 942 مقدار 0)
$resultTypeValue = if ($ResultTypeValue -ge 0) { [string]$ResultTypeValue } else { '1' }

$commandContent = Get-Content -LiteralPath $resolvedScript -Raw -Encoding UTF8
if ([string]::IsNullOrWhiteSpace($commandContent)) {
    throw "Command script is empty: $resolvedScript"
}

$scriptPathForCurl = ($resolvedScript -replace '\\', '/')

$helpContentArg = 'help_content='
$tempHelpFile = $null
if ($HelpContent) {
    $tempHelpFile = [System.IO.Path]::GetTempFileName()
    # UTF8 بدون BOM — Encoding.UTF8 با BOM می‌نویسد و BOM اول مقدار فرم وارد می‌شود
    [System.IO.File]::WriteAllText($tempHelpFile, $HelpContent, (New-Object System.Text.UTF8Encoding($false)))
    $helpContentArg = "help_content=<$($tempHelpFile -replace '\\', '/')"
}

# bot_config با آرایه (مثل "info":[...]) را از فایل می‌خوانیم، نه به‌صورت inline در --form —
# چون curl مقدار حاوی { } / [ ] را در برخی نسخه‌ها URL-glob تفسیر می‌کند و با خطای
# "unmatched close brace/bracket" یا "Malformed input to a URL function" رد می‌شود.
$tempBotConfigFile = $null
if ($BotConfigJson) {
    $tempBotConfigFile = [System.IO.Path]::GetTempFileName()
    [System.IO.File]::WriteAllText($tempBotConfigFile, $BotConfigJson, (New-Object System.Text.UTF8Encoding($false)))
    $botConfigArg = "bot_config=<$($tempBotConfigFile -replace '\\', '/')"
} else {
    $botConfigArg = "bot_config=$formJson"
}

$curlArgs = @(
    '--silent', '--show-error', '--location',
    '--ssl-no-revoke',
    '--write-out', "`n%{http_code}",
    '--output', '-',
    $url,
    '--header', "Cookie: SID=$Sid",
    '--header', "Origin: $baseUrl",
    '--header', "Referer: $referer",
    '--header', 'X-Requested-With: XMLHttpRequest',
    '--form', "status=$Status",
    '--form', "name=$Name",
    '--form', "subsystem_value=$SubsystemValue",
    '--form', "subsystem=$SubsystemName",
    '--form', "run_path=$RunPath",
    '--form', "not_showing_in_iframe=$NotShowingInIframe",
    '--form', "icon=$Icon",
    '--form', "color=$Color",
    '--form', 'db_prefix=',
    '--form', 'async_run=0',
    '--form', 'async_deadline_run=0',
    '--form', "max_execute_time=$MaxExecuteTime",
    '--form', 'cache_time_status=0',
    '--form', 'cache_time=0',
    '--form', "show_in_portal_menu=$ShowInPortalMenu",
    '--form', "public_access=$PublicAccess",
    '--form', "show_in_widget=$ShowInWidget",
    '--form', "open_source=$OpenSource",
    '--form', "categories=$categories",
    '--form', 'deleted_details=',
    "--form", "bot_customform=$formJson",
    '--form', 'attachments_deleted=',
    "--form", $botConfigArg,
    '--form', 'ver=0',
    '--form', 'active_version=',
    '--form', 'new_version=0',
    "--form", "result_type=$resultTypeValue",
    "--form", "description=$Description",
    "--form", "command=<$scriptPathForCurl",
    '--form', 'temp_folder_id=0',
    '--form', 'document_content=',
    '--form', 'temp_folder_id_2=0',
    '--form', $helpContentArg
)

Write-Host "Deploying: $Name"
Write-Host "  script:   $resolvedScript"
Write-Host "  bytes:    $($commandContent.Length)"
Write-Host "  run_path: $RunPath"
Write-Host "  cat_id:   $CatId  bot_id: $BotId"
Write-Host "  output:   HTML (result_type=$resultTypeValue)"
Write-Host "  max_execute_time: $MaxExecuteTime"

try {
    $raw = & curl.exe @curlArgs 2>&1
} finally {
    if ($tempHelpFile -and (Test-Path -LiteralPath $tempHelpFile)) {
        Remove-Item -LiteralPath $tempHelpFile -Force -ErrorAction SilentlyContinue
    }
    if ($tempBotConfigFile -and (Test-Path -LiteralPath $tempBotConfigFile)) {
        Remove-Item -LiteralPath $tempBotConfigFile -Force -ErrorAction SilentlyContinue
    }
}
if ($LASTEXITCODE -ne 0) {
    throw "curl failed (exit $LASTEXITCODE): $raw"
}

$lines = @($raw -split "`n" | Where-Object { $_ -ne '' })
if ($lines.Count -lt 1) {
    throw "Empty response from server"
}

$httpCode = $lines[-1].Trim()
$body = ($lines[0..($lines.Count - 2)] -join "`n").Trim()

if ($httpCode -ne '200') {
    throw "ERR: expected HTTP 200 + bot ID, got HTTP $httpCode. Body: $body"
}

$newBotId = Test-BotIdResponse -Body $body
if ($null -eq $newBotId) {
    throw "ERR: expected HTTP 200 + integer bot ID, got HTTP 200 with body: $body"
}

Write-Host "OK: HTTP 200, bot id=$newBotId"
return $newBotId
