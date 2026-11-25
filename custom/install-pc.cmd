@echo off
setlocal
rem Double-click to install PhoneBox on this PC with the same screen layout as at home. Needs nothing else: it
rem downloads custom/install.ps1 from charus99/phonebox at a fixed commit and runs it only if its SHA-256 matches;
rem install.ps1 then checks setup.ps1 and layout.json the same way.
rem Options are passed on, for example: install-pc.cmd -NoPhone   install-pc.cmd -DryRun   install-pc.cmd -LayoutOnly
rem After a new layout (custom/export-layout.ps1): update install.ps1, commit, then change COMMIT and SHA256 here.
set "COMMIT=6b54b66230c34ebd89133f50dfb254690c0c2860"
set "SHA256=EE83F41CC3486041134D2ECFA9A380719D764F08E2ADCC87009022247D42CB42"
rem started from PowerShell 7 the inherited module path hides Windows PowerShell's own modules
set "PSModulePath="
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol=[Net.ServicePointManager]::SecurityProtocol -bor 'Tls12'; $f=Join-Path $env:TEMP 'phonebox-install.ps1'; Invoke-WebRequest -UseBasicParsing ('https://raw.githubusercontent.com/charus99/phonebox/' + $env:COMMIT + '/custom/install.ps1') -OutFile $f; if ((Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash -ne $env:SHA256) { Remove-Item $f; throw 'The downloaded install.ps1 does not match the expected SHA-256, so it was not run.' }; & $f -Commit $env:COMMIT" %*
set "CODE=%ERRORLEVEL%"
echo.
pause
exit /b %CODE%
