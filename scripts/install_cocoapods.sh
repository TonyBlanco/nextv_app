#!/bin/zsh

# NeXtv - CocoaPods Installation Fix
# Solves the Ruby version incompatibility issue

set -e

echo "🔧 NeXtv - Instalación de CocoaPods (Fix Ruby)"
echo "=============================================="
echo ""

# Step 1: Install Homebrew if not present
if ! command -v brew &> /dev/null; then
    echo "📦 Paso 1/4: Instalando Homebrew..."
    echo "   (Esto puede tardar varios minutos)"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ $(uname -m) == 'arm64' ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    
    echo "   ✅ Homebrew instalado"
else
    echo "✅ Homebrew ya está instalado"
fi
echo ""

# Step 2: Install Ruby via Homebrew
echo "📦 Paso 2/4: Instalando Ruby moderno..."
echo "   (Versión actual: $(ruby -v))"
brew install ruby

# Add Homebrew Ruby to PATH
if [[ $(uname -m) == 'arm64' ]]; then
    export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
    export PATH="/opt/homebrew/lib/ruby/gems/3.3.0/bin:$PATH"
else
    export PATH="/usr/local/opt/ruby/bin:$PATH"
    export PATH="/usr/local/lib/ruby/gems/3.3.0/bin:$PATH"
fi

echo "   ✅ Ruby instalado: $(ruby -v)"
echo ""

# Step 3: Install CocoaPods
echo "📦 Paso 3/4: Instalando CocoaPods..."
gem install cocoapods

echo "   ✅ CocoaPods instalado: $(pod --version)"
echo ""

# Step 4: Setup CocoaPods
echo "📦 Paso 4/4: Configurando CocoaPods..."
pod setup

echo "   ✅ CocoaPods configurado"
echo ""

# Verify Flutter
echo "🔍 Verificando Flutter..."
export FLUTTER_ROOT="/Users/luisblancofontela/.gemini/antigravity/scratch/flutter_sdk"
export PATH="$PATH:$FLUTTER_ROOT/bin"
flutter doctor

echo ""
echo "=============================================="
echo "✨ Instalación completada!"
echo "=============================================="
echo ""
echo "IMPORTANTE: Agrega estas líneas a tu ~/.zshrc para que persistan:"
echo ""
if [[ $(uname -m) == 'arm64' ]]; then
    echo 'export PATH="/opt/homebrew/opt/ruby/bin:$PATH"'
    echo 'export PATH="/opt/homebrew/lib/ruby/gems/3.3.0/bin:$PATH"'
else
    echo 'export PATH="/usr/local/opt/ruby/bin:$PATH"'
    echo 'export PATH="/usr/local/lib/ruby/gems/3.3.0/bin:$PATH"'
fi
echo ""
echo "Ahora puedes ejecutar: flutter run -d macos"
echo ""
