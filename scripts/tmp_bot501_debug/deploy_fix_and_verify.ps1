#Requires -Version 5.1
<#
  Deploy bot501_FIXED.lua to bot 501 and verify both request shapes.
  Rolls back to bot501_live_command_backup.lua automatically if verification fails.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Sid,
    [string]$LuaFile = 'bot501_FIXED.lua'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Remove-Item Env:\https_proxy, Env:\HTTPS_PROXY, Env:\http_proxy, Env:\HTTP_PROXY -ErrorAction SilentlyContinue

$here      = $PSScriptRoot
$fixedLua  = Join-Path $here $LuaFile
$origLua   = Join-Path $here 'bot501_live_command_backup.lua'
$botConfig = Join-Path $here 'bot501_bot_config.json'
$baseUrl   = 'https://erp.bimehland.com'
$emptyForm = '{"layout":{"width_title":3,"col":"COL-2","seperator":""},"info":[],"schema":{},"default_value":{}}'

function Publish-Bot501 {
    param([string]$LuaPath, [string]$Label)
    $lua = ($LuaPath -replace '\\', '/'); $cfg = ($botConfig -replace '\\', '/')
    $out = Join-Path $env:TEMP 'b501_deploy.txt'
    $a = @('--silent','--show-error','--location','--ssl-no-revoke','--max-time','120',
        '--output',$out,'--write-out','%{http_code}',
        "$baseUrl/bot/command/update?cat_id=79&id=501",
        '--header',"Cookie: SID=$Sid",'--header',"Origin: $baseUrl",
        '--header',"Referer: $baseUrl/?page=/bot/command&cat_id=79&id=501",
        '--header','X-Requested-With: XMLHttpRequest',
        '--form','status=1','--form','name=RFM CRM','--form','subsystem_value=','--form','subsystem=',
        '--form','run_path=2/crm_rfm','--form','not_showing_in_iframe=1','--form','icon=','--form','color=',
        '--form','db_prefix=','--form','async_run=0','--form','async_deadline_run=0',
        '--form','max_execute_time=100','--form','cache_time_status=0','--form','cache_time=0',
        '--form','show_in_portal_menu=1','--form','public_access=1','--form','show_in_widget=1',
        '--form','open_source=1','--form','categories=79_1','--form','deleted_details=',
        '--form',"bot_customform=$emptyForm",'--form','attachments_deleted=',
        '--form',"bot_config=<$cfg",'--form','ver=0','--form','active_version=','--form','new_version=0',
        '--form','result_type=1','--form','description=','--form',"command=<$lua",
        '--form','temp_folder_id=0','--form','document_content=','--form','temp_folder_id_2=0','--form','help_content=')
    Write-Host "[$Label] uploading $(Split-Path -Leaf $LuaPath) ..." -NoNewline
    $code = & curl.exe @a
    $body = if (Test-Path $out) { (Get-Content $out -Raw).Trim() } else { '' }
    if ($code -ne '200' -or $body -notmatch '^\d+$') { Write-Host ' FAILED'; throw "[$Label] HTTP $code body=$body" }
    Write-Host " OK (id=$body)"
}

function Invoke-Case {
    param([string]$Label, [string]$Json)
    $f = Join-Path $env:TEMP 'b501_req.json'; $b = Join-Path $env:TEMP 'b501_resp.txt'; $h = Join-Path $env:TEMP 'b501_hdr.txt'
    [System.IO.File]::WriteAllText($f, $Json, (New-Object System.Text.UTF8Encoding($false)))
    $sw = [Diagnostics.Stopwatch]::StartNew()
    & curl.exe --silent --ssl-no-revoke --max-time 200 --dump-header $h --output $b `
        -X POST "$baseUrl/bot/run/2/crm_rfm?ver=0" `
        -H "Cookie: SID=$Sid" -H "Origin: $baseUrl" -H "Referer: $baseUrl/" `
        -H 'X-Requested-With: XMLHttpRequest' -H 'Content-Type: application/json' `
        --data-binary "@$f" | Out-Null
    $sw.Stop()
    $status = (Get-Content $h | Select-Object -First 1).Trim()
    $len = (Get-Item $b).Length
    $ok = ($status -match '\s200\s') -and ($len -gt 1000)
    '{0} {1,-42} {2,-22} {3,5}s {4,8} bytes' -f $(if ($ok) { '[PASS]' } else { '[FAIL]' }), $Label, $status, [math]::Round($sw.Elapsed.TotalSeconds, 1), $len
    return $ok
}

$from = (Get-Date).AddMonths(-1).ToFileTimeUtc()
$to   = (Get-Date).ToFileTimeUtc()

Publish-Bot501 -LuaPath $fixedLua -Label 'FIX'
Write-Host "`n--- verification ---"
$results = @()
$results += Invoke-Case 'bare: filter fields MISSING (the bug)' '{"type":100,"page":0}'
$results += Invoke-Case 'fields present as empty strings'       ('{"type":100,"page":0,"org":"","cat":"","ctype":"","crm":"","center":"","sort_key":"","sort_dir":"","monetary_min":"","monetary_max":"","datef":' + $from + ',"datet":' + $to + '}')
$results += Invoke-Case 'fields present as empty arrays'        ('{"type":100,"page":0,"org":[],"cat":[],"ctype":[],"crm":[],"center":[],"sort_key":"","sort_dir":"","monetary_min":0,"monetary_max":0,"datef":' + $from + ',"datet":' + $to + '}')
$results += Invoke-Case 'shell render (no type)'                '{}'

if ($results -contains $false) {
    Write-Host "`n*** VERIFICATION FAILED - rolling back ***" -ForegroundColor Red
    Publish-Bot501 -LuaPath $origLua -Label 'ROLLBACK'
    throw 'Fix did not verify; bot 501 restored to its previous source.'
}
Write-Host "`nAll checks passed. bot 501 is now running the fixed source." -ForegroundColor Green
