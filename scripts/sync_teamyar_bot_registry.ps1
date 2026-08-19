#Requires -Version 5.1
<#
.SYNOPSIS
  Fetch Teamyar bot metadata + command from /bot/command/view and update live registry.

.PARAMETER BotId
  Teamyar bot_command.ID (e.g. 933)

.PARAMETER CatId
  Optional category id for Referer (default 69)

.PARAMETER Sid
  Session cookie. Default: $env:TEAMYAR_SID

.PARAMETER PullSource
  Write command to src/{slug}_bot.lua when local file missing or -ForcePull

.PARAMETER ForcePull
  Overwrite local src even if file exists

.EXAMPLE
  $env:TEAMYAR_SID = '...'
  .\scripts\sync_teamyar_bot_registry.ps1 -BotId 933 -CatId 69 -PullSource
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [int]$BotId,

    [int]$CatId = 69,

    [string]$Sid = $env:TEAMYAR_SID,

    [switch]$PullSource,

    [switch]$ForcePull
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$registryPath = Join-Path $repoRoot 'docs\context\TeamyarBotsLiveRegistry.json'

function Parse-RunPath {
    param([string]$RunPath)
    if ($RunPath -match '^(\d+)/(.+)$') {
        return @{
            run_id = $Matches[1]
            run_slug = $Matches[2]
        }
    }
    return @{
        run_id = '258'
        run_slug = ($RunPath -replace '\\', '/')
    }
}

function Parse-ViewJson {
    param([string]$Html)
    if ($Html -notmatch 'botCommandViewFunc\((\{.*\})\);') {
        throw 'Could not parse botCommandViewFunc JSON from view response'
    }
    return $Matches[1] | ConvertFrom-Json
}

function Read-Registry {
    if (-not (Test-Path -LiteralPath $registryPath)) {
        return @{ bots = @() }
    }
    $raw = Get-Content -LiteralPath $registryPath -Raw -Encoding UTF8
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return @{ bots = @() }
    }
    return $raw | ConvertFrom-Json
}

function Save-Registry {
    param($Registry)
    $json = $Registry | ConvertTo-Json -Depth 20
    Set-Content -LiteralPath $registryPath -Value $json -Encoding UTF8
}

if (-not $Sid) {
    throw 'SID is required. Set $env:TEAMYAR_SID or pass -Sid.'
}

$baseUrl = 'https://erp.bimehland.com'
$viewUrl = "$baseUrl/bot/command/view?id=$BotId&cat_id=$CatId"
$referer = "$baseUrl/?page=/bot/command/view&id=$BotId&cat_id=$CatId&tab=0"

$html = curl.exe --silent --ssl-no-revoke `
    -H "Cookie: SID=$Sid" `
    -H "X-Requested-With: XMLHttpRequest" `
    -H "Referer: $referer" `
    $viewUrl

if ($LASTEXITCODE -ne 0) {
    throw "Failed to fetch bot view (exit $LASTEXITCODE)"
}

$view = Parse-ViewJson -Html $html
$runParts = Parse-RunPath -RunPath ([string]$view.run_path)
$runSlug = $runParts.run_slug
$runId = $runParts.run_id

$formSetting = $null
if ($view.form_setting) {
    try { $formSetting = $view.form_setting | ConvertFrom-Json } catch { }
}

$inputFields = @()
if ($formSetting -and $formSetting.info) {
    foreach ($field in $formSetting.info) {
        if ($field.name) { $inputFields += [string]$field.name }
    }
}

$defaultInput = @{}
if ($formSetting -and $formSetting.default_value) {
    $formSetting.default_value.PSObject.Properties | ForEach-Object {
        $defaultInput[$_.Name] = $_.Value
    }
}

$localSrcMap = @{
    933 = 'src/bot_commands_json_bot.lua'
    942 = 'src/service_receipt_cost_json_bot.lua'
    565 = 'src/bot_analyzer_report_bot.lua'
    599 = 'src/bot_module_performance_report_bot.lua'
}

$localSrc = if ($localSrcMap.ContainsKey($BotId)) {
    $localSrcMap[$BotId]
} else {
    "src/${runSlug}_bot.lua"
}
$localPath = Join-Path $repoRoot ($localSrc -replace '/', '\')

$entry = [ordered]@{
    id = [int]$view.id
    cat_id = [int]$view.cat_id
    name = [string]$view.name
    description = [string]$view.description
    run_path = [string]$view.run_path
    run_id = $runId
    run_slug = $runSlug
    run_url = "$baseUrl/bot/run/$runId/${runSlug}?ver=0"
    view_url = $referer
    result_type = [int]$view.result_type
    run_count = [int]($view.run_count)
    categories = [string]$view.categories
    local_src = $localSrc
    input_fields = $inputFields
    default_input = $defaultInput
    command_bytes = ([string]$view.command).Length
    synced_at = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
}

$registry = Read-Registry
$list = @()
if ($registry.bots) {
    $list = @($registry.bots)
}
$list = @($list | Where-Object { [int]$_.id -ne $BotId })
$list += ,$entry
$registry = [ordered]@{ bots = ($list | Sort-Object { [int]$_.id }) }
Save-Registry -Registry $registry

if ($PullSource -or $ForcePull) {
    $command = [string]$view.command
    if ([string]::IsNullOrWhiteSpace($command)) {
        throw "Bot $BotId has empty command on server"
    }
    if ($ForcePull -or -not (Test-Path -LiteralPath $localPath)) {
        $dir = Split-Path -Parent $localPath
        if (-not (Test-Path -LiteralPath $dir)) {
            New-Item -ItemType Directory -Path $dir | Out-Null
        }
        Set-Content -LiteralPath $localPath -Value $command -Encoding UTF8
        Write-Host "Pulled source -> $localSrc ($($command.Length) bytes)"
    } else {
        Write-Host "Local source exists, skipped pull: $localSrc (use -ForcePull to overwrite)"
    }
}

Write-Host "Synced bot $($view.id): $($view.name)"
Write-Host "  run_url: $($entry.run_url)"
Write-Host "  local_src: $localSrc"
Write-Host "  registry: $registryPath"
