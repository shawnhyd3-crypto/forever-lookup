# Installs the optional Forever Lookup Helper for the current Windows user:
# adds a Startup shortcut and starts the helper now. No admin rights needed.
# Undo with Uninstall-Helper.ps1.

$ErrorActionPreference = 'Stop'
$script = Join-Path $PSScriptRoot 'ForeverLookupHelper.ps1'
if (-not (Test-Path $script)) { throw "ForeverLookupHelper.ps1 not found next to this installer." }

# Files downloaded from the internet are marked as blocked; clear that for the helper only.
Unblock-File -Path $script -ErrorAction SilentlyContinue

$ps = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$psArgs = "-NoProfile -STA -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$script`""

$lnk = Join-Path ([Environment]::GetFolderPath('Startup')) 'Forever Lookup Helper.lnk'
$ws = New-Object -ComObject WScript.Shell
$s = $ws.CreateShortcut($lnk)
$s.TargetPath = $ps
$s.Arguments = $psArgs
$s.WindowStyle = 7
$s.Description = 'Opens Forever Lookup links from the clipboard in your browser'
$s.Save()

Start-Process -FilePath $ps -ArgumentList $psArgs -WindowStyle Hidden
Write-Host "Forever Lookup Helper installed and running."
Write-Host "Look for the blue 'i' in your system tray. Right-click it to pause or exit."
Write-Host "Startup shortcut: $lnk"
Start-Sleep -Seconds 4
