# Fortnite Monitor Setup Script
# This script downloads the executable and sets it up to run at startup

param(
    [string]$RepoUrl = "https://github.com/rsclip/kfn/releases/download/download/fnblock.exe",
    [string]$InstallPath = "$env:LOCALAPPDATA\FortniteMonitor"
)

Write-Host "Setting up" -ForegroundColor Green

try {
    # Create installation directory
    if (-not (Test-Path $InstallPath)) {
        New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
        Write-Host "Created installation directory: $InstallPath" -ForegroundColor Yellow
    }

    # Download the executable
    $ExePath = Join-Path $InstallPath "fortnite_monitor.exe"
    Write-Host "Downloading executable..." -ForegroundColor Yellow
    
    # Use TLS 1.2 for secure downloads
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    Invoke-WebRequest -Uri $RepoUrl -OutFile $ExePath -UseBasicParsing
    Write-Host "Downloaded to: $ExePath" -ForegroundColor Green

    # Verify the file was downloaded
    if (-not (Test-Path $ExePath)) {
        throw "Failed to download the executable"
    }

    # Create startup registry entry (runs for current user only)
    $RegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    $AppName = "FortniteMonitor"
    
    # Set registry value to run at startup
    Set-ItemProperty -Path $RegPath -Name $AppName -Value "`"$ExePath`"" -Force
    Write-Host "Added to startup registry" -ForegroundColor Green

    # Create an uninstall script
    $UninstallScript = @"
# Fortnite Monitor Uninstaller
Write-Host "Removing Fortnite Monitor..." -ForegroundColor Yellow

# Stop the process if running
Get-Process -Name "fortnite_monitor" -ErrorAction SilentlyContinue | Stop-Process -Force

# Remove from startup
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "FortniteMonitor" -ErrorAction SilentlyContinue

# Remove installation directory
Remove-Item -Path "$InstallPath" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Fortnite Monitor has been removed." -ForegroundColor Green
"@
    
    $UninstallPath = Join-Path $InstallPath "uninstall.ps1"
    $UninstallScript | Out-File -FilePath $UninstallPath -Encoding UTF8
    Write-Host "Created uninstaller: $UninstallPath" -ForegroundColor Yellow

    # Start the monitor immediately (hidden)
    Write-Host "Starting Fortnite Monitor..." -ForegroundColor Yellow
    Start-Process -FilePath $ExePath -WindowStyle Hidden

    Write-Host "`n✅ Setup completed successfully!" -ForegroundColor Green
    Write-Host "Fortnite Monitor is now running and will start automatically with Windows." -ForegroundColor Cyan

} catch {
    Write-Host "❌ Setup failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please try running PowerShell as Administrator if the error persists." -ForegroundColor Yellow
    exit 1
}