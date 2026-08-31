#Requires -Version 5.1
<#
.SYNOPSIS
  Diagnose /bot/command/update 502s by trying no-op update variants (echoed live values,
  live command) with different field subsets. Read-only in effect: every variant that
  succeeds writes exactly the live values back.

.PARAMETER BotId
  Bot to diagnose.

.PARAMETER Variants
  Which variants to run (default: all). Names:
    baseline        - full preserve-style field set
    no_subsystem    - subsystem/subsystem_value posted empty
    omit_subsystem  - subsystem fields not posted at all
    no_run_path     - run_path not posted
    omit_editors    - document_content/help_content/temp folders not posted
    omit_custform   - bot_customform not posted
    omit_config     - bot_config not posted
    minimal         - only status/name/run_path/categories/result_type/command/ver/new_version

.PARAMETER Sid
  Session cookie. Default: $env:TEAMYAR_SID
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][int]$BotId,
    [string[]]$Variants = @('no_subsystem','omit_subsystem','no_run_path','omit_editors','omit_custform','omit_config','minimal'),
    [string]$Sid = $env:TEAMYAR_SID
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $Sid) { throw 'SID is required.' }

$baseUrl = 'https://erp.bimehland.com'

function Get-BotEdit {
    param([int]$Id)
    $html = (curl.exe --silent --ssl-no-revoke `
        -H "Cookie: SID=$Sid" -H "X-Requested-With: XMLHttpRequest" `
        -H "Referer: $baseUrl/?page=/bot/command&cat_id=69&id=$Id" `
        "$baseUrl/bot/command?cat_id=69&id=$Id") -join "`n"
    if ($html -notmatch '(?s)botCommandFunc\((\{.*\})\);') { throw "parse fail bot $Id" }
    return $Matches[1] | ConvertFrom-Json
}
function Get-BotView {
    param([int]$Id)
    $html = (curl.exe --silent --ssl-no-revoke `
        -H "Cookie: SID=$Sid" -H "X-Requested-With: XMLHttpRequest" `
        "$baseUrl/bot/command/view?id=$Id&cat_id=69") -join "`n"
    if ($html -notmatch '(?s)botCommandViewFunc\((\{.*\})\);') { throw "view parse fail bot $Id" }
    return $Matches[1] | ConvertFrom-Json
}

$edit = Get-BotEdit -Id $BotId
$view = Get-BotView -Id $BotId
$catRows = @($edit.categories)
$catId = [int]$catRows[0].id
$categories = ($catRows | ForEach-Object { "$([int]$_.id)_$([int]$_.is_default)" }) -join ','
$subsystemRows = @()
if ($null -ne $edit.subsystem) { $subsystemRows = @($edit.subsystem) }
$subVal = ''; $subName = ''
if ($subsystemRows.Count -gt 0) { $subVal = [string]$subsystemRows[0].id; $subName = [string]$subsystemRows[0].name }

$enc = New-Object System.Text.UTF8Encoding($false)
$tmp = [System.IO.Path]::GetTempPath()
$cmdFile = Join-Path $tmp "diag_cmd_$BotId.lua"
[System.IO.File]::WriteAllText($cmdFile, [string]$view.command, $enc)
$nameFile = Join-Path $tmp "diag_name_$BotId.txt"
[System.IO.File]::WriteAllText($nameFile, [string]$edit.name, $enc)
$cfgFile = Join-Path $tmp "diag_cfg_$BotId.json"
$emptyForm = '{"layout":{"width_title":3,"col":"COL-2","seperator":""},"info":[],"schema":{},"default_value":{}}'
$cfgVal = [string]$edit.bot_config; if (-not $cfgVal) { $cfgVal = $emptyForm }
[System.IO.File]::WriteAllText($cfgFile, $cfgVal, $enc)
$formVal = [string]$edit.form_setting; if (-not $formVal) { $formVal = $emptyForm }
$formFile = Join-Path $tmp "diag_form_$BotId.json"
[System.IO.File]::WriteAllText($formFile, $formVal, $enc)

$statusValue = if ("$($edit.status)" -match '^(True|1)$') { '1' } else { '0' }

function Invoke-Variant {
    param([string]$Name)
    $fields = [System.Collections.Generic.List[string]]::new()
    function AddF([string]$kv) { $fields.Add('--form') | Out-Null; $fields.Add($kv) | Out-Null }

    $isMin = ($Name -eq 'minimal')
    AddF 'status=1'
    AddF "name=<$($nameFile -replace '\\','/')"
    if (-not $isMin) {
        switch ($Name) {
            'no_subsystem'   { AddF 'subsystem_value='; AddF 'subsystem=' }
            'omit_subsystem' { }
            default          { AddF "subsystem_value=$subVal"; AddF "subsystem=$subName" }
        }
    }
    if ($Name -ne 'no_run_path') { AddF "run_path=$([string]$edit.run_path)" }
    AddF "categories=$categories"
    AddF "result_type=$([int]$edit.result_type)"
    if (-not $isMin) {
        AddF 'not_showing_in_iframe=0'; AddF 'icon='; AddF 'color='; AddF 'db_prefix='
        AddF 'async_run=0'; AddF 'async_deadline_run=0'
        AddF "max_execute_time=$([int]$edit.max_execute_time)"
        AddF 'cache_time_status=0'; AddF 'cache_time=0'
        AddF "show_in_portal_menu=$([int]$edit.show_in_portal_menu)"
        AddF "public_access=$([int]$edit.public_access)"
        AddF "show_in_widget=$([int]$edit.show_in_widget)"
        AddF "open_source=$([int]$edit.open_source)"
        AddF 'deleted_details='; AddF 'attachments_deleted='
        AddF 'description='
        if ($Name -ne 'omit_custform') { AddF "bot_customform=<$($formFile -replace '\\','/')" }
        if ($Name -ne 'omit_config')   { AddF "bot_config=<$($cfgFile -replace '\\','/')" }
        if ($Name -ne 'omit_editors') {
            AddF 'document_content='; AddF 'temp_folder_id=0'
            AddF 'help_content=';     AddF 'temp_folder_id_2=0'
        }
        AddF 'active_version='
    }
    AddF 'ver=0'
    AddF 'new_version=0'
    AddF "command=<$($cmdFile -replace '\\','/')"

    $curlArgs = @(
        '--silent','--show-error','--location','--ssl-no-revoke',
        '--write-out',"`n%{http_code}",'--output','-',
        "$baseUrl/bot/command/update?cat_id=$catId&id=$BotId",
        '--header',"Cookie: SID=$Sid",
        '--header',"Origin: $baseUrl",
        '--header',"Referer: $baseUrl/?page=/bot/command&cat_id=$catId&id=$BotId",
        '--header','X-Requested-With: XMLHttpRequest'
    ) + $fields
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $raw = & curl.exe @curlArgs 2>&1
    $sw.Stop()
    $lines = @(("$raw" -split "`n") | Where-Object { $_.Trim() -ne '' })
    $code = $lines[-1].Trim()
    $body = if ($lines.Count -gt 1) { ($lines[0..($lines.Count-2)] -join ' ').Trim() } else { '' }
    $short = if ($body.Length -gt 60) { $body.Substring(0,60) } else { $body }
    "{0,-16} HTTP {1}  {2,5:0.0}s  {3}" -f $Name, $code, $sw.Elapsed.TotalSeconds, $short
}

foreach ($vn in $Variants) {
    Invoke-Variant -Name $vn
}
