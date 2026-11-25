<#
.SYNOPSIS
  Copies this PC's PhoneBox screen layout into custom/layout.json, for install-pc.cmd to put on other PCs.

.DESCRIPTION
  Only these sections of config.json are exported: pages, shortcuts, display, night, weather.
  Everything else (Wi-Fi token, calendar addresses, Discord / Steam / Immich keys, AI settings ...) stays on this PC.
  This repository is public: read the URL list printed at the end before you commit layout.json.
#>
param([string]$ConfigPath = (Join-Path $env:APPDATA 'PhoneBox\config.json'))

$ErrorActionPreference = 'Stop'
$Sections = 'pages', 'shortcuts', 'display', 'night', 'weather'

$config = Get-Content -LiteralPath $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
$layout = [ordered]@{}
foreach ($s in $Sections) {
    if ($null -eq $config.$s) { throw "config.json has no '$s' section: $ConfigPath" }
    $layout[$s] = $config.$s
}
$json = ConvertTo-Json -InputObject $layout -Depth 100
$out = Join-Path $PSScriptRoot 'layout.json'
[IO.File]::WriteAllText($out, ($json -replace "`r`n", "`n") + "`n", [Text.UTF8Encoding]::new($false))

$hash = (Get-FileHash -LiteralPath $out -Algorithm SHA256).Hash
Write-Host "Wrote $out"
Write-Host "  pages: $(@($config.pages).Count), shortcuts: $(@($config.shortcuts).Count), SHA-256: $hash"
$hosts = [regex]::Matches($json, 'https?://[^"\\\s]+') | ForEach-Object { ([uri]$_.Value).Host } | Sort-Object -Unique
if ($hosts) { Write-Warning "layout.json contains web addresses; make sure none is private before committing: $($hosts -join ', ')" }
else { Write-Host '  no web addresses in the layout' }
