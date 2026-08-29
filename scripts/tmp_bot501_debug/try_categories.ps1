#Requires -Version 5.1
<#
  Probe the accepted encoding of the `categories` form field on /bot/command/update.
  Sends the CURRENT (already-fixed) Lua each time, so a successful attempt is a no-op
  for the bot's code and only moves it back to the intended category.

  Known: "79_1" is accepted and resolves to  cat 79 (آنالیزور بات) / sec 1 (140).
  Wanted: bot 501's original category  cat 55 (Crm) / sec 45 (Teamyar).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Sid,
    [int]$BotId = 501,
    [string]$RunPath = '2/crm_rfm',
    [string]$LuaFile = 'bot501_FIXED.lua',
    [string]$BotConfigFile = 'bot501_bot_config.json',
    [int]$MaxExecuteTime = 100
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'
$env:https_proxy = ''; $env:HTTPS_PROXY = ''; $env:http_proxy = ''; $env:HTTP_PROXY = ''

$here      = $PSScriptRoot
$lua       = ((Join-Path $here $LuaFile) -replace '\\', '/')
$cfg       = ((Join-Path $here $BotConfigFile) -replace '\\', '/')
$baseUrl   = 'https://erp.bimehland.com'
$emptyForm = '{"layout":{"width_title":3,"col":"COL-2","seperator":""},"info":[],"schema":{},"default_value":{}}'

# candidate encodings, paired with the cat_id used in the URL context
$attempts = @(
    @{ cat = 55; value = '55_45'      },
    @{ cat = 55; value = '55_45_1'    },
    @{ cat = 79; value = '55_45_1'    },
    @{ cat = 55; value = '55_45|1'    },
    @{ cat = 55; value = '55'         },
    @{ cat = 55; value = '45_55'      },
    @{ cat = 79; value = '55_45,79_1' },
    @{ cat = 55; value = '55_45,79_1' }
)

foreach ($a in $attempts) {
    $out = Join-Path $env:TEMP 'trycat.txt'
    $args = @('--silent','--show-error','--location','--ssl-no-revoke','--max-time','90',
        '--output',$out,'--write-out','%{http_code}',
        "$baseUrl/bot/command/update?cat_id=$($a.cat)&id=$BotId",
        '--header',"Cookie: SID=$Sid",'--header',"Origin: $baseUrl",
        '--header',"Referer: $baseUrl/?page=/bot/command&cat_id=$($a.cat)&id=$BotId",
        '--header','X-Requested-With: XMLHttpRequest',
        '--form','status=1','--form','name=RFM CRM','--form','subsystem_value=','--form','subsystem=',
        '--form',"run_path=$RunPath",'--form','not_showing_in_iframe=1','--form','icon=','--form','color=',
        '--form','db_prefix=','--form','async_run=0','--form','async_deadline_run=0',
        '--form',"max_execute_time=$MaxExecuteTime",'--form','cache_time_status=0','--form','cache_time=0',
        '--form','show_in_portal_menu=1','--form','public_access=1','--form','show_in_widget=1',
        '--form','open_source=1','--form',"categories=$($a.value)",'--form','deleted_details=',
        '--form',"bot_customform=$emptyForm",'--form','attachments_deleted=',
        '--form',"bot_config=<$cfg",'--form','ver=0','--form','active_version=','--form','new_version=0',
        '--form','result_type=1','--form','description=','--form',"command=<$lua",
        '--form','temp_folder_id=0','--form','document_content=','--form','temp_folder_id_2=0','--form','help_content=')

    $code = & curl.exe @args
    $body = if (Test-Path $out) { (Get-Content $out -Raw) } else { '' }
    $short = ($body -split '<')[0].Trim()
    if ($short.Length -gt 60) { $short = $short.Substring(0, 60) }
    $mark = if ($code -eq '200' -and $short -match '^\d+$') { 'SUCCESS' } else { 'fail   ' }
    '{0}  cat_id={1,-3} categories={2,-14} http={3} {4}' -f $mark, $a.cat, $a.value, $code, $short

    if ($mark -eq 'SUCCESS') {
        Write-Host "`nAccepted encoding found: categories=$($a.value) with cat_id=$($a.cat)" -ForegroundColor Green
        break
    }
}
