<#
  NexTV - Windows Development Setup Script
  Ejecutar en PowerShell como Administrador:
    Set-ExecutionPolicy Bypass -Scope Process -Force; .\scripts\setup_windows.ps1
#>

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  NexTV - Windows Dev Environment Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# --- 1. Verificar Git ---
Write-Host "[1/6] Verificando Git..." -ForegroundColor Yellow
if (Get-Command git -ErrorAction SilentlyContinue) {
    $gitVersion = git --version
    Write-Host "  OK: $gitVersion" -ForegroundColor Green
} else {
    Write-Host "  Git no encontrado. Instalando con winget..." -ForegroundColor Red
    winget install --id Git.Git -e --source winget
    $env:Path += ";C:\Program Files\Git\cmd"
    Write-Host "  Git instalado. Reinicia la terminal despues del script." -ForegroundColor Yellow
}

# --- 2. Verificar Flutter ---
Write-Host "[2/6] Verificando Flutter..." -ForegroundColor Yellow
if (Get-Command flutter -ErrorAction SilentlyContinue) {
    $flutterVersion = flutter --version | Select-Object -First 1
    Write-Host "  OK: $flutterVersion" -ForegroundColor Green
} else {
    Write-Host "  Flutter no encontrado." -ForegroundColor Red
    Write-Host "  Opciones de instalacion:" -ForegroundColor Yellow
    Write-Host "    A) winget install --id Google.Flutter -e" -ForegroundColor White
    Write-Host "    B) Descargar de https://docs.flutter.dev/get-started/install/windows/desktop" -ForegroundColor White
    Write-Host ""

    $choice = Read-Host "  Instalar Flutter con winget? (S/N)"
    if ($choice -eq "S" -or $choice -eq "s") {
        winget install --id Google.Flutter -e --source winget
        Write-Host "  Flutter instalado. Reinicia la terminal para que este en PATH." -ForegroundColor Yellow
    }
}

# --- 3. Verificar Visual Studio Build Tools (necesario para Windows desktop) ---
Write-Host "[3/6] Verificando Visual Studio Build Tools..." -ForegroundColor Yellow
$vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vsWhere) {
    $vsInstall = & $vsWhere -latest -property displayName 2>$null
    if ($vsInstall) {
        Write-Host "  OK: $vsInstall" -ForegroundColor Green
    } else {
        Write-Host "  Visual Studio instalado pero sin workload de C++ desktop." -ForegroundColor Yellow
    }
} else {
    Write-Host "  Visual Studio Build Tools no encontrado." -ForegroundColor Red
    Write-Host "  Necesitas instalar 'Desktop development with C++'" -ForegroundColor Yellow
    Write-Host "  Ejecuta: winget install Microsoft.VisualStudio.2022.BuildTools" -ForegroundColor White
    Write-Host "  Luego abre Visual Studio Installer y agrega 'Desktop development with C++'" -ForegroundColor White

    $choice = Read-Host "  Instalar Build Tools con winget? (S/N)"
    if ($choice -eq "S" -or $choice -eq "s") {
        winget install Microsoft.VisualStudio.2022.BuildTools --override "--add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --passive"
    }
}

# --- 4. Verificar VS Code ---
Write-Host "[4/6] Verificando VS Code..." -ForegroundColor Yellow
if (Get-Command code -ErrorAction SilentlyContinue) {
    Write-Host "  OK: VS Code encontrado" -ForegroundColor Green

    # Instalar extensiones recomendadas
    Write-Host "  Instalando extensiones recomendadas..." -ForegroundColor Yellow
    $extensions = @(
        "Dart-Code.dart-code",
        "Dart-Code.flutter",
        "GitHub.copilot",
        "GitHub.copilot-chat",
        "usernamehw.errorlens",
        "pflannery.vscode-versionlens",
        "eamodio.gitlens",
        "gruntfuggly.todo-tree"
    )
    foreach ($ext in $extensions) {
        code --install-extension $ext --force 2>$null
        Write-Host "    + $ext" -ForegroundColor Gray
    }
    Write-Host "  Extensiones instaladas." -ForegroundColor Green
} else {
    Write-Host "  VS Code no encontrado. Instala desde https://code.visualstudio.com/" -ForegroundColor Red
    Write-Host "  O ejecuta: winget install Microsoft.VisualStudioCode" -ForegroundColor White
}

# --- 5. Configurar Git (misma identidad que Mac) ---
Write-Host "[5/6] Configurando Git..." -ForegroundColor Yellow
$gitUser = git config --global user.name 2>$null
$gitEmail = git config --global user.email 2>$null

if ($gitUser -and $gitEmail) {
    Write-Host "  Git configurado como: $gitUser <$gitEmail>" -ForegroundColor Green
} else {
    Write-Host "  Git no tiene usuario configurado." -ForegroundColor Yellow
    $name = Read-Host "  Tu nombre (ej: Luis Blanco)"
    $email = Read-Host "  Tu email de GitHub"
    git config --global user.name "$name"
    git config --global user.email "$email"
    Write-Host "  Git configurado." -ForegroundColor Green
}

# Configurar credential helper para GitHub
git config --global credential.helper manager
Write-Host "  Credential manager configurado (guardara tu login de GitHub)." -ForegroundColor Green

# --- 6. Clonar/configurar proyecto ---
Write-Host "[6/6] Proyecto NexTV..." -ForegroundColor Yellow
$projectPath = "$env:USERPROFILE\Development\nextv_app"

if (Test-Path "$projectPath\.git") {
    Write-Host "  Proyecto ya existe en $projectPath" -ForegroundColor Green
    Push-Location $projectPath
    git pull origin master
    Pop-Location
} else {
    Write-Host "  Clonando proyecto..." -ForegroundColor Yellow
    if (!(Test-Path "$env:USERPROFILE\Development")) {
        New-Item -ItemType Directory -Path "$env:USERPROFILE\Development" -Force | Out-Null
    }
    git clone https://github.com/TonyBlanco/nextv_app.git $projectPath
}

# Instalar dependencias Flutter
if (Get-Command flutter -ErrorAction SilentlyContinue) {
    Write-Host "  Instalando dependencias Flutter..." -ForegroundColor Yellow
    Push-Location $projectPath
    flutter pub get
    Pop-Location
    Write-Host "  Dependencias instaladas." -ForegroundColor Green
}

# --- Resumen ---
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Setup completado!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Pasos siguientes:" -ForegroundColor Yellow
Write-Host "  1. Abre VS Code:  code $projectPath" -ForegroundColor White
Write-Host "  2. VS Code te pedira login de GitHub (usa la misma cuenta)" -ForegroundColor White
Write-Host "  3. Activa Settings Sync: Ctrl+Shift+P > 'Settings Sync: Turn On'" -ForegroundColor White
Write-Host "  4. Para compilar: flutter build windows --release" -ForegroundColor White
Write-Host "  5. Para debug: F5 en VS Code (selecciona 'NexTV Windows (Debug)')" -ForegroundColor White
Write-Host ""
Write-Host "Flutter doctor:" -ForegroundColor Yellow
if (Get-Command flutter -ErrorAction SilentlyContinue) {
    flutter doctor
}
