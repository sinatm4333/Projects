#Requires -Version 5.1
<#
.SYNOPSIS
  Fallback deploy path for this environment: scripts/deploy_teamyar_bot.ps1 (curl.exe) fails here with
  "curl: (35) schannel: failed to receive handshake" against erp.bimehland.com, while native .NET HTTP
  (Invoke-WebRequest -UseBasicParsing) reaches it fine — almost certainly a corporate TLS-inspection
  proxy whose root CA is trusted via the Windows certificate store (used by .NET/WinHTTP) but not by
  curl.exe's own bundled CA bundle. This script performs the same POST /bot/command/update multipart
  request as deploy_teamyar_bot.ps1, using System.Net.Http.HttpClient instead of curl.exe.
#>
param(
    [Parameter(Mandatory = $true)][string]$ScriptPath,
    [Parameter(Mandatory = $true)][string]$Name,
    [string]$RunPath,
    [int]$CatId = 79,
    [int]$BotId = 0,
    [string]$Sid,
    [string]$Description = ''
)

Add-Type -AssemblyName System.Net.Http

$resolvedScript = (Resolve-Path -LiteralPath $ScriptPath).Path
if (-not $RunPath) {
    $base = [System.IO.Path]::GetFileNameWithoutExtension($resolvedScript) -replace '_bot$', ''
    $RunPath = ($base -replace '\s+', '_').ToLowerInvariant()
}
if (-not $Description) { $Description = "Deployed from $([System.IO.Path]::GetFileName($resolvedScript))" }

$baseUrl = 'https://erp.bimehland.com'
$url = "$baseUrl/bot/command/update?cat_id=$CatId&id=$BotId"
$referer = "$baseUrl/?page=/bot/command&cat_id=$CatId&id=$BotId"
$formJson = '{"layout":{"width_title":3,"col":"COL-2","seperator":""},"info":[],"schema":{},"default_value":{}}'
$categories = "${CatId}_1"
$commandContent = [System.IO.File]::ReadAllText($resolvedScript, [System.Text.Encoding]::UTF8)

$handler = New-Object System.Net.Http.HttpClientHandler
$client = New-Object System.Net.Http.HttpClient($handler)
$client.DefaultRequestHeaders.Add("Cookie", "SID=$Sid")
$client.DefaultRequestHeaders.Add("Origin", $baseUrl)
$client.DefaultRequestHeaders.Add("Referer", $referer)
$client.DefaultRequestHeaders.Add("X-Requested-With", "XMLHttpRequest")
$client.Timeout = [TimeSpan]::FromSeconds(60)

$content = New-Object System.Net.Http.MultipartFormDataContent

function Add-Field($name, $value) {
    $sc = New-Object System.Net.Http.StringContent($value, [System.Text.Encoding]::UTF8)
    $content.Add($sc, $name)
}

Add-Field 'status' '1'
Add-Field 'name' $Name
Add-Field 'subsystem_value' ''
Add-Field 'subsystem' ''
Add-Field 'run_path' $RunPath
Add-Field 'not_showing_in_iframe' '0'
Add-Field 'icon' ''
Add-Field 'color' ''
Add-Field 'db_prefix' ''
Add-Field 'async_run' '0'
Add-Field 'async_deadline_run' '0'
Add-Field 'max_execute_time' '100'
Add-Field 'cache_time_status' '0'
Add-Field 'cache_time' '0'
Add-Field 'show_in_portal_menu' '0'
Add-Field 'public_access' '0'
Add-Field 'show_in_widget' '0'
Add-Field 'open_source' '0'
Add-Field 'categories' $categories
Add-Field 'deleted_details' ''
Add-Field 'bot_customform' $formJson
Add-Field 'attachments_deleted' ''
Add-Field 'bot_config' $formJson
Add-Field 'ver' '0'
Add-Field 'active_version' ''
Add-Field 'new_version' '0'
Add-Field 'result_type' '1'
Add-Field 'description' $Description
Add-Field 'command' $commandContent
Add-Field 'temp_folder_id' '0'
Add-Field 'document_content' ''
Add-Field 'temp_folder_id_2' '0'
Add-Field 'help_content' ''

Write-Host "Deploying: $Name"
Write-Host "  script:   $resolvedScript ($($commandContent.Length) chars)"
Write-Host "  run_path: $RunPath   cat_id: $CatId   bot_id: $BotId"

try {
    $resp = $client.PostAsync($url, $content).GetAwaiter().GetResult()
    $body = $resp.Content.ReadAsStringAsync().GetAwaiter().GetResult()
    Write-Host "HTTP: $([int]$resp.StatusCode)"
    Write-Host "BODY: $body"
} catch {
    Write-Host "REQUEST FAILED: $($_.Exception.Message)"
    if ($_.Exception.InnerException) { Write-Host "INNER: $($_.Exception.InnerException.Message)" }
} finally {
    $client.Dispose()
}
