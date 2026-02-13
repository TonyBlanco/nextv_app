# NeXtv Build Script
# Usage: .\build.ps1 [platform] [mode]
# Examples:
#   .\build.ps1 android debug
#   .\build.ps1 android release
#   .\build.ps1 web release
#   .\build.ps1 windows release

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('android', 'web', 'windows', 'ios')]
    [string]$Platform = 'android',
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('debug', 'release', 'profile')]
    [string]$Mode = 'debug'
)

# Colors for output
$ErrorColor = "Red"
$SuccessColor = "Green"
$InfoColor = "Cyan"
$WarningColor = "Yellow"

# Flutter SDK path
$FlutterPath = "C:\src\flutter\bin\flutter.bat"

Write-Host "`n========================================" -ForegroundColor $InfoColor
Write-Host "  NeXtv Build Script" -ForegroundColor $InfoColor
Write-Host "========================================" -ForegroundColor $InfoColor
Write-Host "Platform: $Platform" -ForegroundColor $InfoColor
Write-Host "Mode: $Mode" -ForegroundColor $InfoColor
Write-Host "========================================`n" -ForegroundColor $InfoColor

# Check if Flutter is available
if (-not (Test-Path $FlutterPath)) {
    Write-Host "ERROR: Flutter not found at $FlutterPath" -ForegroundColor $ErrorColor
    Write-Host "Please update the FlutterPath variable in this script." -ForegroundColor $WarningColor
    exit 1
}

# Clean previous builds
Write-Host "[1/4] Cleaning previous builds..." -ForegroundColor $InfoColor
& $FlutterPath clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Flutter clean failed" -ForegroundColor $ErrorColor
    exit 1
}

# Get dependencies
Write-Host "`n[2/4] Getting dependencies..." -ForegroundColor $InfoColor
& $FlutterPath pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Flutter pub get failed" -ForegroundColor $ErrorColor
    exit 1
}

# Build based on platform and mode
Write-Host "`n[3/4] Building $Platform ($Mode)..." -ForegroundColor $InfoColor

switch ($Platform) {
    'android' {
        if ($Mode -eq 'release') {
            & $FlutterPath build apk --release
            $OutputPath = "build\app\outputs\flutter-apk\app-release.apk"
        } else {
            & $FlutterPath build apk --debug
            $OutputPath = "build\app\outputs\flutter-apk\app-debug.apk"
        }
    }
    'web' {
        if ($Mode -eq 'release') {
            & $FlutterPath build web --release
        } else {
            & $FlutterPath build web --debug
        }
        $OutputPath = "build\web"
    }
    'windows' {
        if ($Mode -eq 'release') {
            & $FlutterPath build windows --release
        } else {
            & $FlutterPath build windows --debug
        }
        $OutputPath = "build\windows\runner\Release"
    }
    'ios' {
        Write-Host "iOS builds require macOS" -ForegroundColor $WarningColor
        exit 1
    }
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Build failed" -ForegroundColor $ErrorColor
    exit 1
}

# Success message
Write-Host "`n[4/4] Build completed successfully!" -ForegroundColor $SuccessColor
Write-Host "========================================" -ForegroundColor $SuccessColor

if ($OutputPath) {
    Write-Host "Output: $OutputPath" -ForegroundColor $SuccessColor
    
    # Show file size for APK
    if ($Platform -eq 'android' -and (Test-Path $OutputPath)) {
        $FileSize = (Get-Item $OutputPath).Length / 1MB
        Write-Host "Size: $([math]::Round($FileSize, 2)) MB" -ForegroundColor $SuccessColor
    }
}

Write-Host "========================================`n" -ForegroundColor $SuccessColor
