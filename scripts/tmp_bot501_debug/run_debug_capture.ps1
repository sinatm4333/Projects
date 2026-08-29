#Requires -Version 5.1
<#
  One-shot diagnosis for bot 501 (RFM CRM).

    1. deploys a DEBUG build (live source + one extra `type=199` branch, nothing else changed)
    2. calls type=199 to capture the real Lua error from getData()
    3. ALWAYS restores the original live source afterwards (even if step 2 fails)

  Every other live setting is preserved: show_in_widget=1, show_in_portal_menu=1,
  public_access=1, open_source=1, not_showing_in_iframe=1, and the full bot_config
  schema (RFM weights + SMS texts). The generic scripts/deploy_teamyar_bot.ps1 would
  wipe all of those, which is why this exists.

  Usage:
    .\run_debug_capture.ps1 -Sid 'YOUR_SID_HERE'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Sid,
    [string]$LuaFile = 'bot501_DEBUG.lua',
    [int]$ProbeType = 199
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Remove-Item Env:\https_proxy, Env:\HTTPS_PROXY, Env:\http_proxy, Env:\HTTP_PROXY -ErrorAction SilentlyContinue

$here      = $PSScriptRoot
$debugLua  = Join-Path $here $LuaFile
$origLua   = Join-Path $here 'bot501_live_command_backup.lua'
$botConfig = Join-Path $here 'bot501_bot_config.json'

foreach ($f in @($debugLua, $origLua, $botConfig)) {
    if (-not (Test-Path -LiteralPath $f)) { throw "Missing required file: $f" }
}

$baseUrl = 'https://erp.bimehland.com'
$emptyForm = '{"layout":{"width_title":3,"col":"COL-2","seperator":""},"info":[],"schema":{},"default_value":{}}'

function Publish-Bot501 {
    param([string]$LuaPath, [string]$Label)

    $lua = ($LuaPath  -replace '\\', '/')
    $cfg = ($botConfig -replace '\\', '/')
    $out = Join-Path $env:TEMP 'bot501_deploy_resp.txt'

    $curlArgs = @(
        '--silent', '--show-error', '--location', '--ssl-no-revoke', '--max-time', '120',
        '--output', $out, '--write-out', '%{http_code}',
        "$baseUrl/bot/command/update?cat_id=79&id=501",
        '--header', "Cookie: SID=$Sid",
        '--header', "Origin: $baseUrl",
        '--header', "Referer: $baseUrl/?page=/bot/command&cat_id=79&id=501",
        '--header', 'X-Requested-With: XMLHttpRequest',
        '--form', 'status=1',
        '--form', 'name=RFM CRM',
        '--form', 'subsystem_value=',
        '--form', 'subsystem=',
        '--form', 'run_path=2/crm_rfm',
        '--form', 'not_showing_in_iframe=1',
        '--form', 'icon=',
        '--form', 'color=',
        '--form', 'db_prefix=',
        '--form', 'async_run=0',
        '--form', 'async_deadline_run=0',
        '--form', 'max_execute_time=100',
        '--form', 'cache_time_status=0',
        '--form', 'cache_time=0',
        '--form', 'show_in_portal_menu=1',
        '--form', 'public_access=1',
        '--form', 'show_in_widget=1',
        '--form', 'open_source=1',
        '--form', 'categories=79_1',
        '--form', 'deleted_details=',
        '--form', "bot_customform=$emptyForm",
        '--form', 'attachments_deleted=',
        '--form', "bot_config=<$cfg",
        '--form', 'ver=0',
        '--form', 'active_version=',
        '--form', 'new_version=0',
        '--form', 'result_type=1',
        '--form', 'description=',
        '--form', "command=<$lua",
        '--form', 'temp_folder_id=0',
        '--form', 'document_content=',
        '--form', 'temp_folder_id_2=0',
        '--form', 'help_content='
    )

    Write-Host "[$Label] uploading $(Split-Path -Leaf $LuaPath) ..." -NoNewline
    $code = & curl.exe @curlArgs
    $body = if (Test-Path $out) { (Get-Content $out -Raw).Trim() } else { '' }

    if ($code -ne '200' -or $body -notmatch '^\d+$') {
        Write-Host " FAILED"
        throw "[$Label] expected HTTP 200 + integer bot id; got HTTP $code, body: $body"
    }
    Write-Host " OK (bot id=$body)"
}

$deployedDebug = $false
try {
    Publish-Bot501 -LuaPath $debugLua -Label 'DEBUG'
    $deployedDebug = $true

    $reqFile  = Join-Path $env:TEMP 'bot501_dbg_req.json'
    $respFile = Join-Path $env:TEMP 'bot501_dbg_resp.txt'
    [System.IO.File]::WriteAllText($reqFile, ('{"type":' + $ProbeType + ',"page":0}'), (New-Object System.Text.UTF8Encoding($false)))

    Write-Host "`n[RUN] calling type=199 to capture the Lua error ..."
    & curl.exe --silent --show-error --ssl-no-revoke --max-time 200 `
        --output $respFile `
        -X POST "$baseUrl/bot/run/2/crm_rfm?ver=0" `
        -H "Cookie: SID=$Sid" `
        -H "Origin: $baseUrl" `
        -H "Referer: $baseUrl/" `
        -H 'X-Requested-With: XMLHttpRequest' `
        -H 'Content-Type: application/json' `
        --data-binary "@$reqFile" | Out-Null

    Write-Host "`n================ COPY EVERYTHING BELOW ================`n"
    if ((Test-Path $respFile) -and (Get-Item $respFile).Length -gt 0) {
        Get-Content $respFile -Raw
    } else {
        Write-Host '<empty response>'
    }
    Write-Host "`n================ COPY EVERYTHING ABOVE ================"
}
finally {
    if ($deployedDebug) {
        Write-Host "`n[RESTORE] putting the original source back ..."
        try {
            Publish-Bot501 -LuaPath $origLua -Label 'RESTORE'
            Write-Host "[RESTORE] done - bot 501 is back to its original state."
        } catch {
            Write-Host "[RESTORE] *** FAILED *** - bot 501 is still running the DEBUG build!" -ForegroundColor Red
            Write-Host "Re-run manually:" -ForegroundColor Red
            Write-Host "  .\run_debug_capture.ps1 is not needed - instead restore with the deploy script:" -ForegroundColor Red
            Write-Host "  bot501_live_command_backup.lua must be uploaded to bot 501." -ForegroundColor Red
            throw
        }
    }
}

