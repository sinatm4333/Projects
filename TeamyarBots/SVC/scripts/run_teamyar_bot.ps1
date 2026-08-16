#Requires -Version 5.1
<#
.SYNOPSIS
  Run a Teamyar bot via POST /bot/run/{run_id}/{run_slug}?ver=0

.PARAMETER BotId
  bot_command.ID — used in Referer and to load run_url from registry

.PARAMETER CatId
  Category id for Referer when not in registry

.PARAMETER FormInputJson
  JSON object for form fields, e.g. '{"receipt_no":"250250"}'

.PARAMETER Sid
  Session cookie. Default: $env:TEAMYAR_SID

.EXAMPLE
  .\scripts\run_teamyar_bot.ps1 -BotId 942 -FormInputJson '{"receipt_no":"250250"}'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [int]$BotId,

    [int]$CatId = 0,

    [string]$FormInputJson = '',

    [string]$Sid = $env:TEAMYAR_SID
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$registryPath = Join-Path $repoRoot 'docs\context\TeamyarBotsLiveRegistry.json'

if (-not $Sid) {
    throw 'SID is required. Set $env:TEAMYAR_SID or pass -Sid.'
}

$entry = $null
if (Test-Path -LiteralPath $registryPath) {
    $registry = Get-Content -LiteralPath $registryPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $entry = $registry.bots | Where-Object { [int]$_.id -eq $BotId } | Select-Object -First 1
}

if (-not $entry) {
    throw "Bot $BotId not in registry. Run: .\scripts\sync_teamyar_bot_registry.ps1 -BotId $BotId -CatId $CatId"
}

$cat = if ($CatId -gt 0) { $CatId } else { [int]$entry.cat_id }
$runUrl = [string]$entry.run_url
$referer = [string]$entry.view_url
if (-not $referer) {
    $referer = "https://team.tsco.ir/?page=/bot/command/view&id=$BotId&cat_id=$cat&tab=0"
}

$curlArgs = @(
    '--silent', '--show-error', '--ssl-no-revoke',
    '--write-out', "`nHTTP:%{http_code}",
    '-X', 'POST',
    $runUrl,
    '-H', "Cookie: SID=$Sid",
    '-H', 'Origin: https://team.tsco.ir',
    '-H', "Referer: $referer",
    '-H', 'X-Requested-With: XMLHttpRequest'
)

$FormInput = @{}
if ($FormInputJson -ne '') {
    $parsed = $FormInputJson | ConvertFrom-Json
    $parsed.PSObject.Properties | ForEach-Object {
        $FormInput[$_.Name] = $_.Value
    }
}

if ($FormInput.Count -eq 0 -and $entry.default_input) {
    $entry.default_input.PSObject.Properties | ForEach-Object {
        $FormInput[$_.Name] = $_.Value
    }
}

foreach ($key in $FormInput.Keys) {
    $curlArgs += '--form'
    $curlArgs += "$key=$($FormInput[$key])"
}

Write-Host "Running bot $BotId ($($entry.name))"
Write-Host "  url: $runUrl"

$raw = & curl.exe @curlArgs 2>&1
if ($LASTEXITCODE -ne 0) {
    throw "curl failed (exit $LASTEXITCODE): $raw"
}

$text = ($raw | Out-String).Trim()
$m = [regex]::Match($text, 'HTTP:(\d+)\s*$')
if (-not $m.Success) {
    throw "Unexpected curl output: $($text.Substring(0, [Math]::Min(300, $text.Length)))"
}
$httpCode = $m.Groups[1].Value
$body = [regex]::Replace($text, 'HTTP:\d+\s*$', '').Trim()

Write-Host "HTTP: $httpCode"
if ($httpCode -ne '200') {
    throw "Run failed - HTTP $httpCode. Body: $($body.Substring(0, [Math]::Min(500, $body.Length)))"
}

if ($body.Length -gt 2000) {
    Write-Host ($body.Substring(0, 2000) + '...')
    Write-Host "($($body.Length) bytes total)"
} else {
    Write-Host $body
}

return $body
