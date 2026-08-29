#Requires -Version 5.1
<#
  Deploy ONLY the Lua `command` of bot 501 (RFM CRM), preserving every other live setting.

  The generic scripts/deploy_teamyar_bot.ps1 cannot be used here: it hardcodes
  show_in_widget=0 / show_in_portal_menu=0 / public_access=0 / open_source=0 /
  not_showing_in_iframe=0 and sends an EMPTY bot_config — which would drop bot 501
  out of the CRM dashboard and wipe its RFM weight + SMS-text config schema.

  Every value below was read from the live GET /bot/command/view?id=501&cat_id=79.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Sid,
    [string]$ScriptPath = 'src\crm_rfm_bot.lua'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Remove-Item Env:\https_proxy, Env:\HTTPS_PROXY, Env:\http_proxy, Env:\HTTP_PROXY -ErrorAction SilentlyContinue

$repoRoot = Split-Path -Parent $PSScriptRoot
$resolved = (Resolve-Path -LiteralPath $ScriptPath).Path
$luaBytes = (Get-Item -LiteralPath $resolved).Length
if ($luaBytes -le 0) { throw "Lua file is empty: $resolved" }

$baseUrl = 'https://erp.bimehland.com'
$botId = 501
$catId = 79
$url = "$baseUrl/bot/command/update?cat_id=$catId&id=$botId"
$referer = "$baseUrl/?page=/bot/command&cat_id=$catId&id=$botId"

# --- live values, preserved verbatim ---------------------------------------
$liveBotConfig = Join-Path $PSScriptRoot 'bot501_bot_config.json'
if (-not (Test-Path -LiteralPath $liveBotConfig)) { throw "Missing preserved bot_config: $liveBotConfig" }
$liveFormSetting = '{"layout":{"width_title":3,"col":"COL-2","seperator":""},"info":[],"schema":{},"default_value":{}}'

$scriptForCurl = ($resolved -replace '\\', '/')
$botConfigForCurl = ($liveBotConfig -replace '\\', '/')

$curlArgs = @(
    '--silent', '--show-error', '--location', '--ssl-no-revoke',
    '--write-out', "`n%{http_code}", '--output', '-',
    $url,
    '--header', "Cookie: SID=$Sid",
    '--header', "Origin: $baseUrl",
    '--header', "Referer: $referer",
    '--header', 'X-Requested-With: XMLHttpRequest',
    '--form', 'status=1',
    '--form', 'name=RFM CRM',
    '--form', 'subsystem_value=',
    '--form', 'subsystem=',
    '--form', 'run_path=2/crm_rfm',
    '--form', 'not_showing_in_iframe=1',   # live: 1  (generic script would send 0)
    '--form', 'icon=',
    '--form', 'color=',
    '--form', 'db_prefix=',
    '--form', 'async_run=0',
    '--form', 'async_deadline_run=0',
    '--form', 'max_execute_time=100',
    '--form', 'cache_time_status=0',
    '--form', 'cache_time=0',
    '--form', 'show_in_portal_menu=1',     # live: 1  (generic script would send 0)
    '--form', 'public_access=1',           # live: 1  (generic script would send 0)
    '--form', 'show_in_widget=1',          # live: 1  -> keeps it on the CRM dashboard
    '--form', 'open_source=1',             # live: 1  (generic script would send 0)
    '--form', 'categories=79_1',           # cat_id 79 / sec_id 1 == live "Crm"
    '--form', 'deleted_details=',
    '--form', "bot_customform=$liveFormSetting",
    '--form', 'attachments_deleted=',      # empty -> keeps data.txt / data.js / query_list_invoice.txt
    '--form', "bot_config=<$botConfigForCurl",
    '--form', 'ver=0',
    '--form', 'active_version=',
    '--form', 'new_version=0',
    '--form', 'result_type=1',
    '--form', 'description=',              # live description is empty
    '--form', "command=<$scriptForCurl",
    '--form', 'temp_folder_id=0',
    '--form', 'document_content=',
    '--form', 'temp_folder_id_2=0',
    '--form', 'help_content='
)

Write-Host "Updating bot $botId (RFM CRM) - command only"
Write-Host "  lua:   $resolved ($luaBytes bytes)"
Write-Host "  keeps: show_in_widget=1, show_in_portal_menu=1, public_access=1, open_source=1, bot_config schema"

$raw = & curl.exe @curlArgs 2>&1
if ($LASTEXITCODE -ne 0) { throw "curl failed (exit $LASTEXITCODE): $raw" }

$lines = @($raw -split "`n" | Where-Object { $_ -ne '' })
if ($lines.Count -lt 1) { throw 'Empty response from server' }
$httpCode = $lines[-1].Trim()
$body = ($lines[0..($lines.Count - 2)] -join "`n").Trim()

if ($httpCode -ne '200') { throw "ERR: expected HTTP 200, got $httpCode. Body: $body" }
if ($body.Trim() -notmatch '^\d+$') { throw "ERR: expected integer bot id, got body: $body" }

Write-Host "OK: HTTP 200, bot id=$($body.Trim())"
