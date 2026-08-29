#Requires -Version 5.1
<#
  Deploy a Lua source to one of the RFM bots, preserving that bot's OWN live settings,
  then verify the request shape that used to crash. Rolls back on verification failure.

  Every setting below must be passed explicitly per bot - the two bots differ
  (bot 501: categories 55_45 "Crm", max_execute_time 100;
   bot 600: categories 79_1 "آنالیزور بات", max_execute_time 18000).

  Category encoding is "<cat_id>_<sec_id>", resolved from /bot/command?cat_id=N:
     55_45 = Crm / Teamyar          79_1 = آنالیزور بات / 140
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Sid,
    [Parameter(Mandatory = $true)][int]$BotId,
    [Parameter(Mandatory = $true)][string]$RunPath,
    [Parameter(Mandatory = $true)][string]$LuaFile,
    [Parameter(Mandatory = $true)][string]$BotConfigFile,
    [Parameter(Mandatory = $true)][string]$Categories,
    [Parameter(Mandatory = $true)][int]$MaxExecuteTime,
    [string]$RollbackLuaFile = '',
    [string]$Name = 'RFM CRM',
    [int]$CatId = 79
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$env:https_proxy = ''; $env:HTTPS_PROXY = ''; $env:http_proxy = ''; $env:HTTP_PROXY = ''

$here      = $PSScriptRoot
$luaPath   = Join-Path $here $LuaFile
$cfgPath   = Join-Path $here $BotConfigFile
$baseUrl   = 'https://erp.bimehland.com'
$emptyForm = '{"layout":{"width_title":3,"col":"COL-2","seperator":""},"info":[],"schema":{},"default_value":{}}'

foreach ($f in @($luaPath, $cfgPath)) {
    if (-not (Test-Path -LiteralPath $f)) { throw "Missing file: $f" }
}

function Publish-Bot {
    param([string]$LuaPath, [string]$Label)
    $lua = ($LuaPath -replace '\\', '/'); $cfg = ($cfgPath -replace '\\', '/')
    $out = Join-Path $env:TEMP "rfm_deploy_$BotId.txt"
    $a = @('--silent','--show-error','--location','--ssl-no-revoke','--max-time','120',
        '--output',$out,'--write-out','%{http_code}',
        "$baseUrl/bot/command/update?cat_id=$CatId&id=$BotId",
        '--header',"Cookie: SID=$Sid",'--header',"Origin: $baseUrl",
        '--header',"Referer: $baseUrl/?page=/bot/command&cat_id=$CatId&id=$BotId",
        '--header','X-Requested-With: XMLHttpRequest',
        '--form','status=1','--form',"name=$Name",'--form','subsystem_value=','--form','subsystem=',
        '--form',"run_path=$RunPath",'--form','not_showing_in_iframe=1','--form','icon=','--form','color=',
        '--form','db_prefix=','--form','async_run=0','--form','async_deadline_run=0',
        '--form',"max_execute_time=$MaxExecuteTime",'--form','cache_time_status=0','--form','cache_time=0',
        '--form','show_in_portal_menu=1','--form','public_access=1','--form','show_in_widget=1',
        '--form','open_source=1','--form',"categories=$Categories",'--form','deleted_details=',
        '--form',"bot_customform=$emptyForm",'--form','attachments_deleted=',
        '--form',"bot_config=<$cfg",'--form','ver=0','--form','active_version=','--form','new_version=0',
        '--form','result_type=1','--form','description=','--form',"command=<$lua",
        '--form','temp_folder_id=0','--form','document_content=','--form','temp_folder_id_2=0','--form','help_content=')
    Write-Host "[$Label] bot $BotId <- $(Split-Path -Leaf $LuaPath) ..." -NoNewline
    $code = & curl.exe @a
    $body = if (Test-Path $out) { (Get-Content $out -Raw).Trim() } else { '' }
    if ($code -ne '200' -or $body -notmatch '^\d+$') { Write-Host ' FAILED'; throw "[$Label] HTTP $code body=$body" }
    Write-Host " OK (id=$body)"
}

function Test-Case {
    param([string]$Label, [string]$Json)
    $f = Join-Path $env:TEMP "rfm_req_$BotId.json"
    $b = Join-Path $env:TEMP "rfm_resp_$BotId.txt"
    $h = Join-Path $env:TEMP "rfm_hdr_$BotId.txt"
    [System.IO.File]::WriteAllText($f, $Json, (New-Object System.Text.UTF8Encoding($false)))
    $sw = [Diagnostics.Stopwatch]::StartNew()
    & curl.exe --silent --ssl-no-revoke --max-time 200 --dump-header $h --output $b `
        -X POST "$baseUrl/bot/run/$RunPath`?ver=0" `
        -H "Cookie: SID=$Sid" -H "Origin: $baseUrl" -H "Referer: $baseUrl/" `
        -H 'X-Requested-With: XMLHttpRequest' -H 'Content-Type: application/json' `
        --data-binary "@$f" | Out-Null
    $sw.Stop()
    $status = (Get-Content $h | Select-Object -First 1).Trim()
    $len = (Get-Item $b).Length
    $pass = ($status -match ' 200 ') -and ($len -gt 1000)
    Write-Host ('  {0} {1,-40} {2,-24} {3,5}s {4,8} bytes' -f $(if ($pass) { '[PASS]' } else { '[FAIL]' }), $Label, $status, [math]::Round($sw.Elapsed.TotalSeconds, 1), $len)
    return $pass
}

$from = (Get-Date).AddMonths(-1).ToFileTimeUtc()
$to   = (Get-Date).ToFileTimeUtc()

Publish-Bot -LuaPath $luaPath -Label 'DEPLOY'

Write-Host "`n--- verification (bot $BotId / $RunPath) ---"
$allPass = $true
if (-not (Test-Case 'bare: filter fields MISSING' '{"type":100,"page":0}')) { $allPass = $false }
if (-not (Test-Case 'fields present, empty strings' ('{"type":100,"page":0,"org":"","cat":"","ctype":"","crm":"","center":"","sort_key":"","sort_dir":"","monetary_min":"","monetary_max":"","datef":' + $from + ',"datet":' + $to + '}'))) { $allPass = $false }
if (-not (Test-Case 'fields present, empty arrays' ('{"type":100,"page":0,"org":[],"cat":[],"ctype":[],"crm":[],"center":[],"sort_key":"","sort_dir":"","monetary_min":0,"monetary_max":0,"datef":' + $from + ',"datet":' + $to + '}'))) { $allPass = $false }
if (-not (Test-Case 'shell render (no type)' '{}')) { $allPass = $false }

if (-not $allPass) {
    if ($RollbackLuaFile) {
        Write-Host "`n*** VERIFICATION FAILED - rolling back ***" -ForegroundColor Red
        Publish-Bot -LuaPath (Join-Path $here $RollbackLuaFile) -Label 'ROLLBACK'
    }
    throw "Verification failed for bot $BotId."
}
Write-Host "`nAll checks passed - bot $BotId is running the deployed source." -ForegroundColor Green
