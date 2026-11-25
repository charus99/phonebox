<#
.SYNOPSIS
  Installs PhoneBox and puts this repository's screen layout (custom/layout.json) on this PC. Started by install-pc.cmd.

.DESCRIPTION
  1. Downloads setup.ps1 and custom/layout.json from charus99/phonebox at -Commit and checks their SHA-256.
  2. Runs setup.ps1 (skipped with -LayoutOnly).
  3. Puts the layout's pages, shortcuts, display, night and weather settings on the running agent through its
     settings API. A PC that already had PhoneBox settings is asked first, and config.json is backed up next to itself.
  Calendar addresses are not in the layout (the repository is public): add them in PhoneBox's settings.

  The SHA-256 values below belong to the files at the commit install-pc.cmd names. After export-layout.ps1 changes
  layout.json (or setup.ps1 changes), update them, commit, and point install-pc.cmd at the new commit.
#>
param(
    [Parameter(Mandatory = $true)][string]$Commit,
    [switch]$LayoutOnly,   # PhoneBox is installed already: only put the layout on
    [int]$Port = 8765,
    [string]$ConfigPath = (Join-Path $env:APPDATA 'PhoneBox\config.json'),
    # passed on to setup.ps1
    [switch]$Yes, [switch]$NoPhone, [string]$Serial, [switch]$NoAutostart, [switch]$NoStart, [string]$Version, [switch]$DryRun
)

$SetupSha256 = '0956D763E2B680AA09925FFDC77A9366B306BCF023556054DFF636911900366B'
$LayoutSha256 = '1B3A4E587E5C11C6236634ED398CCCD9C1EF8E8BECE70F1D0D513438CE0411EF'
$Sections = 'pages', 'shortcuts', 'display', 'night', 'weather'

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
$Raw = "https://raw.githubusercontent.com/charus99/phonebox/$Commit"
$Base = "http://127.0.0.1:$Port"

function Get-CheckedFile([string]$Path, [string]$Sha256) {
    $file = Join-Path $env:TEMP ('phonebox-' + (Split-Path $Path -Leaf))
    Invoke-WebRequest -UseBasicParsing "$Raw/$Path" -OutFile $file
    if ((Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -ne $Sha256) {
        Remove-Item -LiteralPath $file
        throw "$Path at $Commit does not match its expected SHA-256; nothing was changed by this step."
    }
    $file
}

# the leading comma returns the byte array as one object; unrolled, -Body would send "123 34 ..." as text
function ConvertTo-Utf8Json($Value) { , [Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject $Value -Depth 100 -Compress)) }

function Get-Settings {
    $response = Invoke-WebRequest -UseBasicParsing "$Base/api/settings"
    # decoded by hand: Windows PowerShell 5.1 may not read the body as UTF-8 (Thai text in widgets)
    $text = [Text.Encoding]::UTF8.GetString($response.RawContentStream.ToArray())
    [pscustomobject]@{ Version = "$($response.Headers['X-Config-Version'])"; Config = ($text | ConvertFrom-Json) }
}

function Test-SameLayout($Config, $Layout) {
    foreach ($s in $Sections) {
        if ((ConvertTo-Json -InputObject $Config.$s -Depth 100 -Compress) -ne (ConvertTo-Json -InputObject $Layout.$s -Depth 100 -Compress)) { return $false }
    }
    $true
}

$hadConfig = Test-Path -LiteralPath $ConfigPath
# downloaded before setup runs, so a bad download stops everything before anything is installed
$layoutFile = Get-CheckedFile 'custom/layout.json' $LayoutSha256
$layout = Get-Content -LiteralPath $layoutFile -Raw -Encoding UTF8 | ConvertFrom-Json

if (-not $LayoutOnly) {
    $setup = Get-CheckedFile 'setup.ps1' $SetupSha256
    $forward = @{}
    foreach ($name in 'Yes', 'NoPhone', 'NoAutostart', 'NoStart', 'DryRun') { if ($PSBoundParameters[$name]) { $forward[$name] = $true } }
    foreach ($name in 'Serial', 'Version') { if ($PSBoundParameters[$name]) { $forward[$name] = $PSBoundParameters[$name] } }
    & $setup @forward
    if ($DryRun) { Write-Host ''; Write-Host 'Dry run: the layout was not put on.'; return }
    if ($NoStart) { Write-Host ''; Write-Host 'PhoneBox was not started (-NoStart). Start it, then run: install-pc.cmd -LayoutOnly'; return }
}

Write-Host ''
Write-Host '==> Screen layout' -ForegroundColor Cyan
$up = $false
for ($i = 0; $i -lt 40 -and -not $up; $i++) {
    try { Invoke-RestMethod -UseBasicParsing "$Base/api/info" -TimeoutSec 2 | Out-Null; $up = $true } catch { Start-Sleep -Milliseconds 750 }
}
if (-not $up) { throw "PhoneBox is not running at $Base, so the layout was not put on. Start PhoneBox, then run: install-pc.cmd -LayoutOnly" }

$current = Get-Settings
if (Test-SameLayout $current.Config $layout) { Write-Host '    OK  This PC already has the layout.' -ForegroundColor Green; return }

if ($hadConfig) {
    Write-Host '    This PC already had PhoneBox settings. The layout replaces its pages, shortcuts, display, night and'
    Write-Host '    weather settings (a backup of config.json is kept).'
    $answer = if ($Yes) { 'n' } else { "$(Read-Host '    Replace them? [y/N]')".Trim().ToLowerInvariant() }
    if ($answer -ne 'y' -and $answer -ne 'yes') { Write-Host '    Kept this PC''s own layout.'; return }
    $backup = "$ConfigPath.before-layout-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item -LiteralPath $ConfigPath -Destination $backup
    Write-Host "    Backup: $backup"
}

foreach ($s in $Sections) { $current.Config | Add-Member -NotePropertyName $s -NotePropertyValue $layout.$s -Force }
try {
    Invoke-WebRequest -UseBasicParsing "$Base/api/settings" -Method Put -ContentType 'application/json; charset=utf-8' `
        -Headers @{ 'X-Config-Version' = $current.Version } -Body (ConvertTo-Utf8Json $current.Config) | Out-Null
} catch {
    $why = $_.Exception.Message
    if ($_.Exception.Response) { try { $why += ' ' + (New-Object IO.StreamReader($_.Exception.Response.GetResponseStream())).ReadToEnd() } catch { } }
    throw "PhoneBox refused the layout, nothing was changed: $why"
}

if (-not (Test-SameLayout (Get-Settings).Config $layout)) { throw 'The agent accepted the layout but does not show it; check its log in %LOCALAPPDATA%\PhoneBox\agent.log.' }
Write-Host "    OK  Layout put on: $(@($layout.pages).Count) pages, $(@($layout.shortcuts).Count) shortcuts. The phone picks it up by itself." -ForegroundColor Green
Write-Host '    Calendars are not part of the layout: add your calendar address in PhoneBox settings > General.'
