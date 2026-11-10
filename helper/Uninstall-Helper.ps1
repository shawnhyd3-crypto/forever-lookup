# Removes the optional Forever Lookup Helper: stops it and deletes the Startup shortcut.

$lnk = Join-Path ([Environment]::GetFolderPath('Startup')) 'Forever Lookup Helper.lnk'
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
    Where-Object { $_.CommandLine -like '*ForeverLookupHelper.ps1*' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
if (Test-Path $lnk) { Remove-Item $lnk }
Write-Host "Forever Lookup Helper stopped and removed from startup."
Start-Sleep -Seconds 3
