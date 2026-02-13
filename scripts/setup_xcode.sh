#!/bin/zsh

# NeXtv - Post Xcode Installation Setup
# Run this AFTER installing Xcode from the App Store

set -e  # Exit on error

echo "🔧 NeXtv - Configuración Post-Instalación de Xcode"
echo "=================================================="
echo ""

# Check if Xcode is installed
if [ ! -d "/Applications/Xcode.app" ]; then
    echo "❌ ERROR: Xcode no está instalado en /Applications/Xcode.app"
    echo ""
    echo "Por favor instala Xcode desde la App Store primero:"
    echo "1. Abre App Store"
    echo "2. Busca 'Xcode'"
    echo "3. Haz clic en 'Obtener' o 'Descargar'"
    echo "4. Espera a que termine la instalación"
    echo "5. Vuelve a ejecutar este script"
    exit 1
fi

echo "✅ Xcode encontrado en /Applications/Xcode.app"
echo ""

# Step 1: Select Xcode command line tools
echo "📍 Paso 1/5: Configurando Xcode Command Line Tools..."
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

if [ $? -eq 0 ]; then
    echo "   ✅ Command Line Tools configurados"
else
    echo "   ❌ Error configurando Command Line Tools"
    exit 1
fi
echo ""

# Step 2: Accept Xcode license
echo "📍 Paso 2/5: Aceptando licencia de Xcode..."
echo "   (Esto puede pedir tu contraseña)"
sudo xcodebuild -license accept

if [ $? -eq 0 ]; then
    echo "   ✅ Licencia aceptada"
else
    echo "   ⚠️  Puede que necesites aceptar manualmente"
fi
echo ""

# Step 3: Run first launch
echo "📍 Paso 3/5: Ejecutando primera configuración de Xcode..."
echo "   (Esto puede tardar varios minutos)"
sudo xcodebuild -runFirstLaunch

if [ $? -eq 0 ]; then
    echo "   ✅ Primera configuración completada"
else
    echo "   ⚠️  Hubo un problema, pero continuamos..."
fi
echo ""

# Step 4: Install CocoaPods
echo "📍 Paso 4/5: Instalando CocoaPods..."
echo "   (Esto puede tardar unos minutos)"

# Try with sudo first (system-wide installation)
sudo gem install cocoapods

if [ $? -eq 0 ]; then
    echo "   ✅ CocoaPods instalado correctamente"
    pod --version
else
    echo "   ⚠️  Error instalando CocoaPods"
    echo "   Puedes intentar manualmente: sudo gem install cocoapods"
fi
echo ""

# Step 5: Verify Flutter setup
echo "📍 Paso 5/5: Verificando configuración de Flutter..."
echo ""

# Make sure Flutter is in PATH
export FLUTTER_ROOT="/Users/luisblancofontela/.gemini/antigravity/scratch/flutter_sdk"
export PATH="$PATH:$FLUTTER_ROOT/bin"

flutter doctor -v

echo ""
echo "=================================================="
echo "✨ Configuración completada!"
echo "=================================================="
echo ""
echo "Próximos pasos:"
echo "1. Revisa el output de 'flutter doctor' arriba"
echo "2. Si todo está ✓, ya puedes compilar para iOS y macOS"
echo "3. Prueba: flutter run -d macos"
echo ""
