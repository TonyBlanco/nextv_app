# NeXtv Test Script
# Usage: .\test.ps1 [device]
# Examples:
#   .\test.ps1              # Run on default device
#   .\test.ps1 bluestacks   # Run on BlueStacks
#   .\test.ps1 web          # Run on web

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('bluestacks', 'web', 'windows', 'default')]
    [string]$Device = 'default'
)

# Colors
$InfoColor = "Cyan"
$SuccessColor = "Green"
$ErrorColor = "Red"
$WarningColor = "Yellow"

# Paths
$FlutterPath = "C:\src\flutter\bin\flutter.bat"
$AdbPath = "C:\platform-tools\adb.exe"
$BlueStacksIP = "127.0.0.1:5555"

Write-Host "`n========================================" -ForegroundColor $InfoColor
Write-Host "  NeXtv Test Runner" -ForegroundColor $InfoColor
Write-Host "========================================" -ForegroundColor $InfoColor
Write-Host "Device: $Device" -ForegroundColor $InfoColor
Write-Host "========================================`n" -ForegroundColor $InfoColor

# Check Flutter
if (-not (Test-Path $FlutterPath)) {
    Write-Host "ERROR: Flutter not found at $FlutterPath" -ForegroundColor $ErrorColor
    exit 1
}

# Connect to BlueStacks if needed
if ($Device -eq 'bluestacks') {
    Write-Host "[1/3] Connecting to BlueStacks..." -ForegroundColor $InfoColor
    
    if (-not (Test-Path $AdbPath)) {
        Write-Host "ERROR: ADB not found at $AdbPath" -ForegroundColor $ErrorColor
        exit 1
    }
    
    & $AdbPath connect $BlueStacksIP
    Start-Sleep -Seconds 2
    
    # Verify connection
    $devices = & $AdbPath devices
    if ($devices -notmatch $BlueStacksIP) {
        Write-Host "ERROR: Could not connect to BlueStacks" -ForegroundColor $ErrorColor
        Write-Host "Make sure BlueStacks is running" -ForegroundColor $WarningColor
        exit 1
    }
    
    Write-Host "Connected to BlueStacks successfully!" -ForegroundColor $SuccessColor
}

# Get dependencies
Write-Host "`n[2/3] Getting dependencies..." -ForegroundColor $InfoColor
& $FlutterPath pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Flutter pub get failed" -ForegroundColor $ErrorColor
    exit 1
}

# Run the app
Write-Host "`n[3/3] Running NeXtv..." -ForegroundColor $InfoColor

switch ($Device) {
    'web' {
        Write-Host "Starting web server..." -ForegroundColor $InfoColor
        & $FlutterPath run -d chrome
    }
    'windows' {
        Write-Host "Starting Windows app..." -ForegroundColor $InfoColor
        & $FlutterPath run -d windows
    }
    'bluestacks' {
        Write-Host "Deploying to BlueStacks..." -ForegroundColor $InfoColor
        & $FlutterPath run -d $BlueStacksIP
    }
    default {
        Write-Host "Starting on default device..." -ForegroundColor $InfoColor
        & $FlutterPath run
    }
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "`nERROR: Failed to run app" -ForegroundColor $ErrorColor
    exit 1
}

Write-Host "`n========================================" -ForegroundColor $SuccessColor
Write-Host "  App is running!" -ForegroundColor $SuccessColor
Write-Host "========================================`n" -ForegroundColor $SuccessColor
