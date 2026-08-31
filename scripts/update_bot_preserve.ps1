#Requires -Version 5.1
<#
.SYNOPSIS
  ⚠️ DO NOT USE — این اسکریپت روی erp.bimehland.com همیشه 502 Bad Gateway می‌گیرد
  (تست ایزوله ۱۴۰۵/۰۶/۰۹: حتی no-op روی بات سادهٔ تازه‌ساختهٔ 630 هم 502 داد؛ همان بات با
  deploy_teamyar_bot.ps1 با HTTP 200 آپدیت شد — مشکل از شکل POST این اسکریپت است، نه فیلدها).
  به‌جای آن deploy_teamyar_bot.ps1 را با پارامترهای echo بزن:
  -Categories/-SubsystemValue/-SubsystemName/-PublicAccess/-ShowInWidget/-OpenSource/-BotConfigJson
  (دستورالعمل کامل: CLAUDE.md بخش «Update existing bot»)

  Original purpose: Update ONLY the command (Lua source) of an existing Teamyar bot, echoing
  every other field back from the live /bot/command/view response.

.DESCRIPTION
  scripts/deploy_teamyar_bot.ps1 is unsafe for widget/RES bots: it hardcodes
  show_in_widget=0, public_access=0, open_source=0, empty bot_config, cat "N_1", ...
  This script reads the bot's live metadata first and re-sends it verbatim, so a
  command-only update cannot silently drop the bot out of dashboards or wipe config.

.PARAMETER BotId
  Existing bot_command.ID (create is NOT supported here).

.PARAMETER ScriptPath
  Path to the .lua file whose content becomes the new command.

.PARAMETER Sid
  Session cookie. Default: $env:TEAMYAR_SID
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [int]$BotId,

    [Parameter(Mandatory = $true)]
    [string]$ScriptPath,

    [string]$Sid = $env:TEAMYAR_SID
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $Sid) { throw 'SID is required. Set $env:TEAMYAR_SID or pass -Sid.' }
if (-not (Test-Path -LiteralPath $ScriptPath)) { throw "Script file not found: $ScriptPath" }
$resolvedScript = (Resolve-Path -LiteralPath $ScriptPath).Path

$baseUrl = 'https://erp.bimehland.com'

function Get-BotEdit {
    # the EDIT form data (botCommandFunc) carries the real categories array
    # (id/sec/cat/is_default) plus every field the update POST must echo.
    param([int]$Id)
    $editUrl = "$baseUrl/bot/command?cat_id=69&id=$Id"
    $referer = "$baseUrl/?page=/bot/command&cat_id=69&id=$Id"
    $html = (curl.exe --silent --ssl-no-revoke `
        -H "Cookie: SID=$Sid" `
        -H "X-Requested-With: XMLHttpRequest" `
        -H "Referer: $referer" `
        $editUrl) -join "`n"
    if ($LASTEXITCODE -ne 0) { throw "Failed to fetch bot edit form (exit $LASTEXITCODE)" }
    if ($html -notmatch '(?s)botCommandFunc\((\{.*\})\);') {
        throw "Could not parse botCommandFunc JSON for bot $Id"
    }
    return $Matches[1] | ConvertFrom-Json
}

$view = Get-BotEdit -Id $BotId
if (-not $view.id -or [int]$view.id -ne $BotId) { throw "Edit form returned wrong bot (got '$($view.id)')" }

# subsystem_value must echo the live subsystem's id (edit form "subsystem" list carries
# {id,name}); always posting '' for a bot that HAS a subsystem (e.g. 478 = SALES_VIEW/23_2)
# makes the save die with a 502 from the backend.
$subsystemName = ''
$subsystemValue = ''
if ($view.PSObject.Properties.Name -contains 'subsystem' -and $null -ne $view.subsystem) {
    $subsystemRows = @($view.subsystem)
    if ($subsystemRows.Count -gt 0 -and $subsystemRows[0].PSObject.Properties.Name -contains 'id') {
        $subsystemValue = [string]$subsystemRows[0].id
        $subsystemName = [string]$subsystemRows[0].name
    }
}

$catId = [int]$view.cat_id

# categories POST format (from bot.js beforSubmit): "<categoryId>_<isDefault>" joined by
# commas; the server rejects the save with NOT_EXIST_CATEGORY_DEFAULT unless exactly one
# entry carries _1. NOT cat_sec as previously believed.
$catRows = @($view.categories)
if ($catRows.Count -eq 0) { throw "Bot $BotId has no category rows" }
$hasDefault = @($catRows | Where-Object { [int]$_.is_default -eq 1 }).Count -gt 0
$parts = @()
for ($ri = 0; $ri -lt $catRows.Count; $ri++) {
    $row = $catRows[$ri]
    $isDef = [int]$row.is_default
    if (-not $hasDefault -and $ri -eq 0) { $isDef = 1 }  # promote first row so the save is accepted
    $parts += "$([int]$row.id)_$isDef"
}
$categories = $parts -join ','
# the update URL's cat_id must be the bot's real (default) category, not the browsing context
$catId = [int]$catRows[0].id

function New-TempValueFile {
    param([string]$Value)
    $f = [System.IO.Path]::GetTempFileName()
    # UTF8 بدون BOM — BOM اول فایل وارد مقدار فرم می‌شود
    [System.IO.File]::WriteAllText($f, $Value, (New-Object System.Text.UTF8Encoding($false)))
    return $f
}

function Get-FieldOrEmpty {
    param($Object, [string]$Name)
    if ($Object.PSObject.Properties.Name -contains $Name -and $null -ne $Object.$Name) {
        return [string]$Object.$Name
    }
    return ''
}

$tempFiles = @()
function Add-FormFromValue {
    param([System.Collections.Generic.List[string]]$Args, [string]$Field, [string]$Value)
    $f = New-TempValueFile -Value $Value
    $script:tempFiles += $f
    $Args.Add('--form') | Out-Null
    $Args.Add("$Field=<$($f -replace '\\', '/')") | Out-Null
}

$url = "$baseUrl/bot/command/update?cat_id=$catId&id=$BotId"
$referer = "$baseUrl/?page=/bot/command&cat_id=$catId&id=$BotId"

$curlArgs = [System.Collections.Generic.List[string]]::new()
@(
    '--silent', '--show-error', '--location', '--ssl-no-revoke',
    '--write-out', "`n%{http_code}",
    '--output', '-',
    $url,
    '--header', "Cookie: SID=$Sid",
    '--header', "Origin: $baseUrl",
    '--header', "Referer: $referer",
    '--header', 'X-Requested-With: XMLHttpRequest'
) | ForEach-Object { $curlArgs.Add($_) | Out-Null }

$statusValue = if ("$($view.status)" -match '^(True|1)$') { '1' } else { '0' }

# مقادیر ساده — عیناً از view
$simple = [ordered]@{
    'status'                = $statusValue
    'subsystem_value'       = $subsystemValue
    'subsystem'             = $subsystemName
    'not_showing_in_iframe' = [string]([int]$view.not_showing_in_iframe)
    'icon'                  = Get-FieldOrEmpty $view 'icon'
    'color'                 = Get-FieldOrEmpty $view 'color'
    'db_prefix'             = Get-FieldOrEmpty $view 'db_prefix'
    'async_run'             = [string]([int]$view.async_run)
    'async_deadline_run'    = [string]([int]$view.async_deadline_run)
    'max_execute_time'      = [string]([int]$view.max_execute_time)
    'cache_time_status'     = if ([int]$view.cache_time -gt 0) { '1' } else { '0' }
    'cache_time'            = [string]([int]$view.cache_time)
    'show_in_portal_menu'   = [string]([int]$view.show_in_portal_menu)
    'public_access'         = [string]([int]$view.public_access)
    'show_in_widget'        = [string]([int]$view.show_in_widget)
    'open_source'           = [string]([int]$view.open_source)
    'categories'            = $categories
    'deleted_details'       = ''
    'attachments_deleted'   = ''
    'ver'                   = [string]([int]$view.version)
    'active_version'        = ''
    'new_version'           = '0'
    'result_type'           = [string]([int]$view.result_type)
    'temp_folder_id'        = '0'
    'temp_folder_id_2'      = '0'
}
# src-linked bots (src_command_id>0, e.g. installed from the Teamyar bot store): the
# editor renders run_path DISABLED, so it is never submitted; posting it makes the
# backend contact the src domain and the save dies with 502. Omit it for those bots.
$srcCommandId = 0
if ($view.PSObject.Properties.Name -contains 'src_command_id' -and $view.src_command_id) {
    $srcCommandId = [int]$view.src_command_id
}
if ($srcCommandId -eq 0) {
    $simple['run_path'] = [string]$view.run_path
}

foreach ($k in $simple.Keys) {
    $curlArgs.Add('--form') | Out-Null
    $curlArgs.Add("$k=$($simple[$k])") | Out-Null
}

# مقادیر متنی/JSON — از فایل، تا curl آکولاد/براکت را glob نکند و یونیکد سالم بماند
$emptyFormJson = '{"layout":{"width_title":3,"col":"COL-2","seperator":""},"info":[],"schema":{},"default_value":{}}'
$formSetting = Get-FieldOrEmpty $view 'form_setting'
if (-not $formSetting) { $formSetting = $emptyFormJson }
$botConfig = Get-FieldOrEmpty $view 'bot_config'
if (-not $botConfig) { $botConfig = $emptyFormJson }

Add-FormFromValue $curlArgs 'name' ([string]$view.name)
Add-FormFromValue $curlArgs 'description' (Get-FieldOrEmpty $view 'description')
Add-FormFromValue $curlArgs 'bot_customform' $formSetting
Add-FormFromValue $curlArgs 'bot_config' $botConfig
Add-FormFromValue $curlArgs 'document_content' (Get-FieldOrEmpty $view 'document_content')
Add-FormFromValue $curlArgs 'help_content' (Get-FieldOrEmpty $view 'help_content')

$curlArgs.Add('--form') | Out-Null
$curlArgs.Add("command=<$($resolvedScript -replace '\\', '/')") | Out-Null

Write-Host "Updating bot $BotId ($($view.name)) — command-only, metadata echoed from live"
Write-Host "  run_path: $($view.run_path)  cat: $categories  result_type: $($view.result_type)  show_in_widget: $($view.show_in_widget)"
$scriptBytes = (Get-Item -LiteralPath $resolvedScript).Length
Write-Host "  script: $resolvedScript / $scriptBytes bytes"

try {
    $raw = & curl.exe @curlArgs 2>&1
} finally {
    foreach ($f in $tempFiles) {
        if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue }
    }
}
if ($LASTEXITCODE -ne 0) { throw "curl failed (exit $LASTEXITCODE): $raw" }

$lines = @("$raw" -split "`n" | Where-Object { $_ -ne '' })
$httpCode = $lines[-1].Trim()
$body = if ($lines.Count -gt 1) { ($lines[0..($lines.Count - 2)] -join "`n").Trim() } else { '' }

if ($httpCode -ne '200' -or $body -notmatch '^\d+$') {
    throw "ERR: expected HTTP 200 + integer bot ID, got HTTP $httpCode. Body: $body"
}
Write-Host "OK: HTTP 200, bot id=$body"
return [int]$body
