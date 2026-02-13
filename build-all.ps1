# NeXtv Multi-Platform Build Script
# Usage:
#   .\build-all.ps1                       - Build ALL platforms (release)
#   .\build-all.ps1 -Platforms windows    - Build Windows only
#   .\build-all.ps1 -Platforms android,windows -Mode debug
#   .\build-all.ps1 -SkipClean            - Skip flutter clean step
#
# Platforms: android, windows, web, webos, ios (macOS only)

param(
    [string[]]$Platforms = @("android", "windows", "web", "webos"),
    [ValidateSet("debug", "release", "profile")]
    [string]$Mode = "release",
    [switch]$SkipClean,
    [switch]$SkipAnalyze
)

$FlutterPath = "C:\src\flutter\bin\flutter.bat"
$WebOSDir = "webos"
$StartTime = Get-Date
$Results = @{}

function Log-Info($msg) { Write-Host "  [INFO] $msg" -ForegroundColor Cyan }
function Log-Ok($msg) { Write-Host "  [OK]   $msg" -ForegroundColor Green }
function Log-Warn($msg) { Write-Host "  [WARN] $msg" -ForegroundColor Yellow }
function Log-Err($msg) { Write-Host "  [FAIL] $msg" -ForegroundColor Red }
function Log-Step($n, $total, $msg) { Write-Host "`n--- [$n/$total] $msg ---" -ForegroundColor Cyan }

Write-Host ""
Write-Host "============================================" -ForegroundColor Magenta
Write-Host "  NeXtv Multi-Platform Build" -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Magenta
Write-Host "  Platforms : $($Platforms -join ', ')" -ForegroundColor Cyan
Write-Host "  Mode      : $Mode" -ForegroundColor Cyan
Write-Host "  Time      : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host ""

# Preflight
if (-not (Test-Path $FlutterPath)) {
    Log-Err "Flutter not found at $FlutterPath"
    exit 1
}

if ($Platforms -contains "ios" -and $env:OS -eq "Windows_NT") {
    Log-Warn "iOS builds require macOS + Xcode - skipping ios"
    $Platforms = $Platforms | Where-Object { $_ -ne "ios" }
}

$totalSteps = 1 + $Platforms.Count
if (-not $SkipClean) { $totalSteps++ }
if (-not $SkipAnalyze) { $totalSteps++ }
$step = 0

# STEP: Clean
if (-not $SkipClean) {
    $step++
    Log-Step $step $totalSteps "Cleaning previous builds"
    & $FlutterPath clean 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { Log-Err "Clean failed"; exit 1 }
    Log-Ok "Clean complete"
}

# STEP: Dependencies
$step++
Log-Step $step $totalSteps "Getting dependencies"
& $FlutterPath pub get
if ($LASTEXITCODE -ne 0) { Log-Err "pub get failed"; exit 1 }
Log-Ok "Dependencies resolved"

# STEP: Analyze
if (-not $SkipAnalyze) {
    $step++
    Log-Step $step $totalSteps "Running flutter analyze"
    $analyzeOut = & $FlutterPath analyze 2>&1
    $errCount = ($analyzeOut | Select-String "error -" | Measure-Object).Count
    if ($errCount -gt 0) {
        Log-Warn "$errCount error(s) found"
        $analyzeOut | Select-String "error -" | ForEach-Object { Write-Host "    $_" -ForegroundColor Yellow }
    }
    else {
        Log-Ok "No errors"
    }
}

# BUILD EACH PLATFORM
foreach ($plat in $Platforms) {
    $step++
    $t0 = Get-Date

    if ($plat -eq "android") {
        Log-Step $step $totalSteps "Building Android APK ($Mode)"
        if ($Mode -eq "release") {
            & $FlutterPath build apk --release
            $outPath = "build\app\outputs\flutter-apk\app-release.apk"
        }
        else {
            & $FlutterPath build apk --$Mode
            $outPath = "build\app\outputs\flutter-apk\app-$Mode.apk"
        }
        if ($LASTEXITCODE -eq 0) {
            $Results["android"] = "OK"
            if (Test-Path $outPath) {
                $sz = [math]::Round((Get-Item $outPath).Length / 1MB, 2)
                Log-Ok "Android APK: $outPath ($sz MB)"
            }
            else {
                Log-Ok "Android APK built"
            }
        }
        else {
            $Results["android"] = "FAILED"
            Log-Err "Android build failed"
        }
    }
    elseif ($plat -eq "windows") {
        Log-Step $step $totalSteps "Building Windows ($Mode)"
        & $FlutterPath build windows --$Mode
        if ($Mode -eq "release") {
            $outPath = "build\windows\x64\runner\Release"
        }
        else {
            $outPath = "build\windows\x64\runner\Debug"
        }
        if ($LASTEXITCODE -eq 0) {
            $Results["windows"] = "OK"
            Log-Ok "Windows: $outPath"
        }
        else {
            $Results["windows"] = "FAILED"
            Log-Err "Windows build failed"
        }
    }
    elseif ($plat -eq "web") {
        Log-Step $step $totalSteps "Building Web ($Mode)"
        if ($Mode -eq "release") {
            & $FlutterPath build web --release --web-renderer canvaskit
        }
        else {
            & $FlutterPath build web --$Mode
        }
        if ($LASTEXITCODE -eq 0) {
            $Results["web"] = "OK"
            Log-Ok "Web: build\web"
        }
        else {
            $Results["web"] = "FAILED"
            Log-Err "Web build failed"
        }
    }
    elseif ($plat -eq "webos") {
        Log-Step $step $totalSteps "Building webOS (Flutter web + packaging)"

        # Build web first
        & $FlutterPath build web --release --web-renderer canvaskit
        if ($LASTEXITCODE -ne 0) {
            $Results["webos"] = "FAILED (web)"
            Log-Err "webOS: web build step failed"
            continue
        }

        # Copy web output into webos dir (preserving appinfo.json, icons)
        $webBuild = "build\web"
        Log-Info "Copying web build to $WebOSDir..."
        Get-ChildItem $webBuild -Recurse | ForEach-Object {
            $dest = $_.FullName.Replace((Resolve-Path $webBuild).Path, (Resolve-Path $WebOSDir).Path)
            if ($_.PSIsContainer) {
                New-Item -ItemType Directory -Path $dest -Force | Out-Null
            }
            else {
                Copy-Item $_.FullName -Destination $dest -Force
            }
        }

        # Try IPK packaging if ares-package is available
        $ares = Get-Command "ares-package" -ErrorAction SilentlyContinue
        if ($ares) {
            Log-Info "Packaging with ares-package..."
            $ipkDir = "build\webos"
            New-Item -ItemType Directory -Path $ipkDir -Force | Out-Null
            & ares-package $WebOSDir -o $ipkDir
            if ($LASTEXITCODE -eq 0) {
                $ipk = Get-ChildItem $ipkDir -Filter "*.ipk" | Select-Object -First 1
                $Results["webos"] = "OK (IPK)"
                Log-Ok "webOS IPK: $($ipk.FullName)"
            }
            else {
                $Results["webos"] = "OK (no IPK)"
                Log-Warn "ares-package failed, but web files are in $WebOSDir"
            }
        }
        else {
            $Results["webos"] = "OK (no IPK)"
            Log-Warn "ares-package not found - install webOS CLI for IPK packaging"
            Log-Ok "webOS web files: $WebOSDir (sideload manually)"
        }
    }
    elseif ($plat -eq "ios") {
        Log-Step $step $totalSteps "Building iOS ($Mode)"
        if ($Mode -eq "release") {
            & $FlutterPath build ios --release --no-codesign
        }
        else {
            & $FlutterPath build ios --$Mode --no-codesign
        }
        if ($LASTEXITCODE -eq 0) {
            $Results["ios"] = "OK"
            Log-Ok "iOS build complete"
        }
        else {
            $Results["ios"] = "FAILED"
            Log-Err "iOS build failed"
        }
    }

    $secs = [math]::Round(((Get-Date) - $t0).TotalSeconds, 1)
    Write-Host "  Time: ${secs}s" -ForegroundColor Cyan
}

# SUMMARY
$totalSecs = [math]::Round(((Get-Date) - $StartTime).TotalSeconds, 1)

Write-Host ""
Write-Host "============================================" -ForegroundColor Magenta
Write-Host "  Build Summary" -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Magenta

foreach ($key in $Results.Keys | Sort-Object) {
    $status = $Results[$key]
    if ($status -match "OK") {
        Write-Host "  [OK]   $($key.ToUpper())" -ForegroundColor Green
    }
    else {
        Write-Host "  [FAIL] $($key.ToUpper()) - $status" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "  Total time: ${totalSecs}s" -ForegroundColor Cyan
Write-Host ""

$failCount = ($Results.Values | Where-Object { $_ -match "FAILED" } | Measure-Object).Count
if ($failCount -gt 0) { exit 1 } else { exit 0 }
