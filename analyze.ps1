# NeXtv Code Analysis Script
# Usage: .\analyze.ps1

# Colors
$InfoColor = "Cyan"
$SuccessColor = "Green"
$ErrorColor = "Red"
$WarningColor = "Yellow"

# Flutter path
$FlutterPath = "C:\src\flutter\bin\flutter.bat"

Write-Host "`n========================================" -ForegroundColor $InfoColor
Write-Host "  NeXtv Code Analyzer" -ForegroundColor $InfoColor
Write-Host "========================================`n" -ForegroundColor $InfoColor

# Check Flutter
if (-not (Test-Path $FlutterPath)) {
    Write-Host "ERROR: Flutter not found at $FlutterPath" -ForegroundColor $ErrorColor
    exit 1
}

# Run analysis
Write-Host "[1/2] Running Flutter analyze..." -ForegroundColor $InfoColor
& $FlutterPath analyze

$analyzeResult = $LASTEXITCODE

# Run format check
Write-Host "`n[2/2] Checking code formatting..." -ForegroundColor $InfoColor
& $FlutterPath format --set-exit-if-changed --dry-run lib/

$formatResult = $LASTEXITCODE

# Summary
Write-Host "`n========================================" -ForegroundColor $InfoColor
Write-Host "  Analysis Summary" -ForegroundColor $InfoColor
Write-Host "========================================" -ForegroundColor $InfoColor

if ($analyzeResult -eq 0) {
    Write-Host "✓ Analysis: PASSED" -ForegroundColor $SuccessColor
} else {
    Write-Host "✗ Analysis: FAILED" -ForegroundColor $ErrorColor
}

if ($formatResult -eq 0) {
    Write-Host "✓ Formatting: PASSED" -ForegroundColor $SuccessColor
} else {
    Write-Host "✗ Formatting: NEEDS FIXING" -ForegroundColor $WarningColor
    Write-Host "  Run: flutter format lib/" -ForegroundColor $WarningColor
}

Write-Host "========================================`n" -ForegroundColor $InfoColor

if ($analyzeResult -ne 0 -or $formatResult -ne 0) {
    exit 1
}
