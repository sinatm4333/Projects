#Requires -Version 5.1
<#
.SYNOPSIS
  Update an existing Teamyar bot by echoing its OWN live metadata back verbatim,
  changing only what you explicitly ask for (attachments and/or status).

  Unlike scripts\deploy_teamyar_bot.ps1 this script:
    * reads every field from the live edit form (GET /bot/command?cat_id=..&id=..)
      so nothing is silently reset - categories, bot_config, form_setting, command,
      icon/color, flags - all replayed exactly as the server has them;
    * supports real attachment replacement (attachments_deleted + attachments=@file),
      which deploy_teamyar_bot.ps1 hardcodes to empty.

  Written for bot 304 (res_v2), which has 27 categories and 45 attachments and is
  depended on by 42 live bots - a partial echo there wipes real configuration.

.PARAMETER BotId
  Bot id to update.

.PARAMETER CatId
  cat_id used for the edit-form GET + Referer (URL echo only).

.PARAMETER UploadFile
  One or more local files to upload as attachments (replaces by name when the
  matching old id is passed via -DeleteAttachmentId).

.PARAMETER DeleteAttachmentId
  Attachment ids to delete in the same POST. Required to REPLACE rather than
  duplicate an attachment of the same name.

.PARAMETER Status
  Override status (1 = enabled, 0 = disabled). Omit to keep the live value.

.PARAMETER CommandPath
  Local .lua file to use as the new `command` instead of echoing the live value verbatim.
  Must be UTF-8 without BOM.

.PARAMETER WhatIf
  Print the resolved echo values and planned changes, then stop without posting.

.NOTES
  * Bots with src_command_id > 0 pointing at a foreign domain return 502 on save.
    Detach first (see src\temp_detach_bot_src_link_bot.lua). This script refuses
    to post in that state unless -AllowSrcLinked is given.
  * run_path is submitted as a bare slug (the prefix is not client-submittable) and
    can silently drift to 443/<slug>. ALWAYS re-verify after a successful save.
  * All text form fields are written as UTF-8 WITHOUT BOM - a BOM corrupts values.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][int]$BotId,
    [int]$CatId = 59,
    [string]$Sid = $env:TEAMYAR_SID,
    [string[]]$UploadFile = @(),
    [int[]]$DeleteAttachmentId = @(),
    [int]$Status = -1,
    [string]$CommandPath = '',
    [string]$BotConfigPath = '',
    [switch]$AllowSrcLinked,
    [switch]$WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $Sid) { throw 'SID required: set $env:TEAMYAR_SID or pass -Sid.' }

$baseUrl = 'https://erp.bimehland.com'
# Must match the proven-working shape from deploy_teamyar_bot.ps1 exactly - an update
# POST to /bot/command/update?id=X with no cat_id, or a Referer of .../view instead of
# the bare /bot/command page, both 400 (confirmed live on bot 632, 1405/06/09).
$referer = "$baseUrl/?page=/bot/command&cat_id=$CatId&id=$BotId"

# ---------------------------------------------------------------- read live state
# -join: PowerShell hands back native stdout as a string[], and -match on an array
# filters elements instead of setting $Matches - which silently breaks the parse.
$rawForm = (curl.exe --silent --ssl-no-revoke `
    -H "Cookie: SID=$Sid" -H 'X-Requested-With: XMLHttpRequest' -H "Referer: $referer" `
    "$baseUrl/bot/command?cat_id=$CatId&id=$BotId") -join "`n"
if ($LASTEXITCODE -ne 0) { throw "Failed to read edit form (curl exit $LASTEXITCODE)" }
if ($rawForm -notmatch 'botCommandFunc\((\{[\s\S]*\})\);') { throw 'Could not parse botCommandFunc JSON' }
$live = $Matches[1] | ConvertFrom-Json

if ([int]$live.src_command_id -gt 0 -and -not $AllowSrcLinked) {
    throw ("Bot $BotId is src-linked (src_command_id=$($live.src_command_id), src_domain='$($live.src_domain)'). " +
           'Saving will 502 and write nothing. Detach first via src\temp_detach_bot_src_link_bot.lua, ' +
           'or pass -AllowSrcLinked to try anyway.')
}

$liveStatus = if ($live.status) { 1 } else { 0 }
$effStatus = if ($Status -ge 0) { $Status } else { $liveStatus }
$categories = ($live.categories | ForEach-Object { "$($_.id)_$($_.is_default)" }) -join ','
if ($categories -notmatch '_1(,|$)') { throw "No default category in echo string: $categories" }

$subsystemValue = ''
$subsystemName = ''
if ($live.subsystem) {
    if ($live.subsystem.PSObject.Properties.Name -contains 'id') { $subsystemValue = [string]$live.subsystem.id }
    if ($live.subsystem.PSObject.Properties.Name -contains 'name') { $subsystemName = [string]$live.subsystem.name }
}

# ------------------------------------------------------- spill text fields to disk
# curl --form field=<file avoids shell/URL-glob mangling of { } [ ] and keeps UTF-8.
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$tempFiles = @()
function New-FieldFile {
    param([string]$Content)
    $p = [System.IO.Path]::GetTempFileName()
    [System.IO.File]::WriteAllText($p, [string]$Content, $utf8NoBom)
    $script:tempFiles += $p
    return ($p -replace '\\', '/')
}

$commandContent = [string]$live.command
if ($CommandPath) {
    if (-not (Test-Path -LiteralPath $CommandPath)) { throw "CommandPath not found: $CommandPath" }
    $cmdBytes = [System.IO.File]::ReadAllBytes($CommandPath)
    if ($cmdBytes.Length -ge 3 -and $cmdBytes[0] -eq 0xEF -and $cmdBytes[1] -eq 0xBB -and $cmdBytes[2] -eq 0xBF) {
        throw "CommandPath has a UTF-8 BOM (corrupts Teamyar values): $CommandPath"
    }
    $commandContent = [System.IO.File]::ReadAllText($CommandPath, [System.Text.Encoding]::UTF8)
}
$commandFile = New-FieldFile $commandContent
$customFormFile = New-FieldFile ([string]$live.form_setting)

# Only spill non-empty values to a file. curl's `field=<emptyfile` is not equivalent to
# `field=` here - the server rejected the whole POST with a generic 400 (seen on bot 632).
function Get-FieldArg {
    param([string]$Name, [string]$Value)
    if ([string]::IsNullOrEmpty($Value)) { return "$Name=" }
    return "$Name=<$(New-FieldFile $Value)"
}
$botConfigContent = [string]$live.bot_config
if ($BotConfigPath) {
    if (-not (Test-Path -LiteralPath $BotConfigPath)) { throw "BotConfigPath not found: $BotConfigPath" }
    $bcBytes = [System.IO.File]::ReadAllBytes($BotConfigPath)
    if ($bcBytes.Length -ge 3 -and $bcBytes[0] -eq 0xEF -and $bcBytes[1] -eq 0xBB -and $bcBytes[2] -eq 0xBF) {
        throw "BotConfigPath has a UTF-8 BOM (corrupts Teamyar values): $BotConfigPath"
    }
    $botConfigContent = [System.IO.File]::ReadAllText($BotConfigPath, [System.Text.Encoding]::UTF8)
}
$botConfigArg = Get-FieldArg -Name 'bot_config' -Value $botConfigContent
$helpArg = Get-FieldArg -Name 'help_content' -Value ([string]$live.help_content)
$documentArg = Get-FieldArg -Name 'document_content' -Value ([string]$live.document_content)

$deletedIds = ($DeleteAttachmentId | ForEach-Object { [string]$_ }) -join ','

Write-Host "Bot $BotId : $($live.name)"
Write-Host "  run_path submitted : $($live.run_path)   (live prefix_path: $($live.prefix_path))"
Write-Host "  status             : $effStatus (live $liveStatus)"
Write-Host "  result_type        : $($live.result_type)"
Write-Host "  categories         : $categories"
Write-Host "  command bytes      : $($commandContent.Length)$(if ($CommandPath) { " (from $CommandPath)" })"
Write-Host "  bot_config bytes   : $($botConfigContent.Length)$(if ($BotConfigPath) { " (from $BotConfigPath)" })"
Write-Host "  form_setting bytes : $(([string]$live.form_setting).Length)"
Write-Host "  attachments_deleted: $(if ($deletedIds) { $deletedIds } else { '(none)' })"
foreach ($f in $UploadFile) {
    if (-not (Test-Path -LiteralPath $f)) { throw "Upload file not found: $f" }
    $b = [System.IO.File]::ReadAllBytes($f)
    if ($b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF) {
        throw "Upload file has a UTF-8 BOM (corrupts Teamyar values): $f"
    }
    Write-Host ("  upload             : {0} ({1:N0} bytes)" -f (Split-Path -Leaf $f), $b.Length)
}

if ($WhatIf) {
    Write-Host ''
    Write-Host 'WhatIf: nothing posted.'
    foreach ($p in $tempFiles) { Remove-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue }
    return
}

# ------------------------------------------------------------------------- post
$curlArgs = @(
    '--silent', '--show-error', '--location', '--ssl-no-revoke',
    '--write-out', "`n%{http_code}", '--output', '-',
    "$baseUrl/bot/command/update?cat_id=$CatId&id=$BotId",
    '--header', "Cookie: SID=$Sid",
    '--header', "Origin: $baseUrl",
    '--header', "Referer: $referer",
    '--header', 'X-Requested-With: XMLHttpRequest',
    '--form', "status=$effStatus",
    '--form', "name=$($live.name)",
    '--form', "subsystem_value=$subsystemValue",
    '--form', "subsystem=$subsystemName",
    '--form', "run_path=$($live.run_path)",
    '--form', "not_showing_in_iframe=$($live.not_showing_in_iframe)",
    '--form', "icon=$($live.icon)",
    '--form', "color=$($live.color)",
    '--form', "db_prefix=$($live.db_prefix)",
    '--form', "async_run=$($live.async_run)",
    '--form', "async_deadline_run=$($live.async_deadline_run)",
    '--form', "max_execute_time=$($live.max_execute_time)",
    '--form', 'cache_time_status=0',
    '--form', "cache_time=$($live.cache_time)",
    '--form', "show_in_portal_menu=$($live.show_in_portal_menu)",
    '--form', "public_access=$($live.public_access)",
    '--form', "show_in_widget=$($live.show_in_widget)",
    '--form', "open_source=$($live.open_source)",
    '--form', "categories=$categories",
    '--form', 'deleted_details=',
    '--form', "bot_customform=<$customFormFile",
    '--form', "attachments_deleted=$deletedIds",
    '--form', $botConfigArg,
    '--form', 'ver=0',
    '--form', 'active_version=',
    '--form', 'new_version=0',
    '--form', "result_type=$($live.result_type)",
    '--form', "description=$($live.description)",
    '--form', "command=<$commandFile",
    '--form', 'temp_folder_id=0',
    '--form', $documentArg,
    '--form', 'temp_folder_id_2=0',
    '--form', $helpArg
)
foreach ($f in $UploadFile) {
    $curlArgs += '--form'
    $curlArgs += "attachments=@$($f -replace '\\', '/')"
}

try {
    $raw = & curl.exe @curlArgs 2>&1
} finally {
    foreach ($p in $tempFiles) { Remove-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue }
}
if ($LASTEXITCODE -ne 0) { throw "curl failed (exit $LASTEXITCODE): $raw" }

$lines = @($raw -split "`n" | Where-Object { $_ -ne '' })
if ($lines.Count -lt 1) { throw 'Empty response from server' }
$httpCode = $lines[-1].Trim()
$body = if ($lines.Count -gt 1) { ($lines[0..($lines.Count - 2)] -join "`n").Trim() } else { '' }

Write-Host ''
Write-Host "HTTP $httpCode"
if ($body) { Write-Host "Body: $body" }
if ($httpCode -ne '200') { throw "ERR: expected HTTP 200, got $httpCode" }
Write-Host 'OK'
