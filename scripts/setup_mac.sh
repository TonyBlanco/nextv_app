#!/bin/zsh

# NeXtv Environment Setup for Mac
# Usage: source scripts/setup_mac.sh

echo "🚀 Setting up NeXtv environment for macOS..."

# Flutter SDK
export FLUTTER_ROOT="/Users/luisblancofontela/.gemini/antigravity/scratch/flutter_sdk"
export PATH="$PATH:$FLUTTER_ROOT/bin"

# Homebrew & Tools
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

# Homebrew Ruby (v4.0.1) & CocoaPods
# Fixes compatibility issues with macOS system Ruby
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
export PATH="/opt/homebrew/lib/ruby/gems/4.0.0/bin:$PATH"

# Use Safari for web development (Chrome not installed)
export CHROME_EXECUTABLE="/Applications/Safari.app/Contents/MacOS/Safari"

echo "✅ Flutter and Ruby Gems added to PATH"
echo "🌐 Using Safari for web development"
echo ""
flutter --version
