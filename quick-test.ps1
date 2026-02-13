# NeXtv Quick Test Script
# Fast testing workflow: analyze + run on BlueStacks
# Usage: .\quick-test.ps1

# Colors
$InfoColor = "Cyan"
$SuccessColor = "Green"
$ErrorColor = "Red"

Write-Host "`n========================================" -ForegroundColor $InfoColor
Write-Host "  NeXtv Quick Test" -ForegroundColor $InfoColor
Write-Host "========================================`n" -ForegroundColor $InfoColor

# Step 1: Analyze
Write-Host "[1/2] Running code analysis..." -ForegroundColor $InfoColor
& .\analyze.ps1

if ($LASTEXITCODE -ne 0) {
    Write-Host "`nWARNING: Analysis found issues, but continuing..." -ForegroundColor $ErrorColor
}

# Step 2: Run on BlueStacks
Write-Host "`n[2/2] Running on BlueStacks..." -ForegroundColor $InfoColor
& .\test.ps1 bluestacks

Write-Host "`n========================================" -ForegroundColor $SuccessColor
Write-Host "  Quick Test Complete!" -ForegroundColor $SuccessColor
Write-Host "========================================`n" -ForegroundColor $SuccessColor
